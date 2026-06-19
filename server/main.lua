-- Copyright (c) 2025 johnsmith600
-- Licensed: Free to use AS-IS (no modification, no redistribution, no resale).
-- See LICENSE file for full terms: https://github.com/johnsmith600/nsw_registration/blob/main/LICENSE

local Config = require 'shared.config'
local Bridge = require 'shared.bridge'
local Locale = require 'locales.en'

local function log(msg)
	if not Config.Logging.enabled then return end
	if Config.Logging.print then print(('[NSW] %s'):format(msg)) end
	if Config.Debug then print(('[NSW:DEBUG] %s'):format(msg)) end
	if Config.Logging.webhook ~= '' then
		-- Add webhook integration here if desired
	end
end

local function getDiscountPercentForPlayer(player)
	local job = Bridge.getJobName(player)
	if not job then return 0.0 end
	return Config.BusinessDiscounts[job] or 0.0
end

local function calculateLatePenalty(daysLate)
	if daysLate <= 0 then return 0.0 end
	local percent = math.min(daysLate * (Config.Registration.latePenaltyPercentPerDay or 0.0), Config.Registration.latePenaltyCapPercent or 0.0)
	return percent
end

local function plateToSql(plate)
	if not plate then return nil end
	local s = tostring(plate):upper()
	-- keep only letters and numbers
	s = s:gsub('[^A-Z0-9]', '')
	if #s == 0 then return nil end
	if #s > 8 then s = s:sub(1, 8) end
	return s
end

local function now()
	return os.time()
end

local function daysFromNow(days)
	return now() + (days * 86400)
end

local function isWithinGrace(expiry)
	local grace = (Config.Registration.graceDays or 0) * 86400
	return now() > expiry and now() <= (expiry + (grace or 0))
end

local function ensureTable()
	-- Main registrations table
	MySQL.query([[CREATE TABLE IF NOT EXISTS nsw_registrations (
		id INT AUTO_INCREMENT PRIMARY KEY,
		plate VARCHAR(16) NOT NULL UNIQUE,
		owner_identifier VARCHAR(64) NOT NULL,
		vehicle_hash VARCHAR(64) DEFAULT NULL,
		registered_at INT NOT NULL,
		expires_at INT NOT NULL,
		pink_slip_expires_at INT DEFAULT 0,
		is_printed TINYINT NOT NULL DEFAULT 0,
		plate_style VARCHAR(32) DEFAULT 'standard',
		status TINYINT NOT NULL DEFAULT 1,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])

	-- Logs table
	MySQL.query([[CREATE TABLE IF NOT EXISTS nsw_reg_logs (
		id INT AUTO_INCREMENT PRIMARY KEY,
		plate VARCHAR(16) NOT NULL,
		actor_identifier VARCHAR(64) NOT NULL,
		action ENUM('register','renew','transfer','pinkslip','print') NOT NULL,
		fee INT NOT NULL DEFAULT 0,
		meta JSON NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		INDEX (plate)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])

	-- Reservations table
	MySQL.query([[CREATE TABLE IF NOT EXISTS nsw_plate_reservations (
		id INT AUTO_INCREMENT PRIMARY KEY,
		plate VARCHAR(16) NOT NULL UNIQUE,
		reserved_by VARCHAR(64) NOT NULL,
		reserved_at INT NOT NULL,
		expires_at INT NOT NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])

	-- Flags table
	MySQL.query([[CREATE TABLE IF NOT EXISTS nsw_reg_flags (
		id INT AUTO_INCREMENT PRIMARY KEY,
		plate VARCHAR(16) NOT NULL,
		reason VARCHAR(128) NOT NULL,
		actor_identifier VARCHAR(64) NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		INDEX (plate)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])

	-- Migrations for existing tables
	local columns = MySQL.query.await("SHOW COLUMNS FROM nsw_registrations", {})
	if columns then
		local hasPinkSlip = false
		local hasIsPrinted = false
		local hasPlateStyle = false
		for _, col in ipairs(columns) do
			if col.Field == 'pink_slip_expires_at' then hasPinkSlip = true end
			if col.Field == 'is_printed' then hasIsPrinted = true end
			if col.Field == 'plate_style' then hasPlateStyle = true end
		end
		if not hasPinkSlip then
			MySQL.query.await("ALTER TABLE nsw_registrations ADD COLUMN pink_slip_expires_at INT DEFAULT 0 AFTER expires_at")
		end
		if not hasIsPrinted then
			MySQL.query.await("ALTER TABLE nsw_registrations ADD COLUMN is_printed TINYINT NOT NULL DEFAULT 0 AFTER pink_slip_expires_at")
		end
		if not hasPlateStyle then
			MySQL.query.await("ALTER TABLE nsw_registrations ADD COLUMN plate_style VARCHAR(32) DEFAULT 'standard' AFTER is_printed")
		end
	end

	-- Update logs ENUM if it exists
	MySQL.query([[ALTER TABLE nsw_reg_logs MODIFY COLUMN action ENUM('register','renew','transfer','pinkslip','print') NOT NULL]])
end

ensureTable()

local function withinOpeningHours()
	if not (Config.OpeningHours and Config.OpeningHours.enabled) then return true end
	local h = tonumber(os.date('%H'))
	return h >= (Config.OpeningHours.open or 0) and h < (Config.OpeningHours.close or 24)
end

local function fetchRegistration(plate)
	plate = plateToSql(plate)
	if not plate then return nil end
	local ok, rows = pcall(MySQL.query.await, 'SELECT * FROM nsw_registrations WHERE plate = ? LIMIT 1', { plate })
	if not ok then
		log('Database error in fetchRegistration: ' .. tostring(rows))
		return nil
	end
	return rows and rows[1] or nil
end

local function upsertRegistration(data)
	MySQL.query.await([[INSERT INTO nsw_registrations (plate, owner_identifier, vehicle_hash, registered_at, expires_at, pink_slip_expires_at, is_printed, plate_style, status)
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)
	ON DUPLICATE KEY UPDATE owner_identifier = VALUES(owner_identifier), vehicle_hash = VALUES(vehicle_hash), registered_at = VALUES(registered_at), expires_at = VALUES(expires_at), pink_slip_expires_at = VALUES(pink_slip_expires_at), is_printed = VALUES(is_printed), plate_style = VALUES(plate_style), status = 1]],
		{ data.plate, data.owner_identifier, data.vehicle_hash, data.registered_at, data.expires_at, data.pink_slip_expires_at or 0, data.is_printed or 0, data.plate_style or 'standard' })
end

local function addLog(plate, actor, action, fee, meta)
	MySQL.query.await('INSERT INTO nsw_reg_logs (plate, actor_identifier, action, fee, meta) VALUES (?, ?, ?, ?, ?)', {
		plate, actor, action, fee or 0, meta and json.encode(meta) or nil
	})
end

local function updateOwner(plate, newIdentifier)
	MySQL.query.await('UPDATE nsw_registrations SET owner_identifier = ? WHERE plate = ?', { newIdentifier, plateToSql(plate) })
end

local function calculateFee(base, discountPercent, latePercent)
	local fee = base
	if discountPercent and discountPercent > 0 then
		fee = fee * (1 - (discountPercent / 100.0))
	end
	if latePercent and latePercent > 0 then
		fee = fee * (1 + (latePercent / 100.0))
	end
	return math.floor(fee + 0.5)
end

local function isStaffFree(player)
	if not Config.StaffFree then return false end
	local job = Bridge.getJobName(player)
	for _, j in ipairs(Config.AuthorizedJobs.dmv or {}) do
		if j == job then return true end
	end
	return false
end

local function isMechanic(player)
	local job = Bridge.getJobName(player)
	for _, j in ipairs(Config.PinkSlip.authorizedJobs or {}) do
		if j == job then return true end
	end
	return false
end

local function isPlateBlacklisted(plate)
	for _, pat in ipairs(Config.PlateBlacklist or {}) do
		if plate:find(pat) then return true end
	end
	return false
end

local function getFrameworkVehicleTable()
	if Bridge.name == 'qb' or Bridge.name == 'qbox' then
		return 'player_vehicles', 'citizenid'
	end
	return 'owned_vehicles', 'owner'
end

local function isPlateTaken(plate)
	local p = plateToSql(plate)
	-- Check NSW table
	local r1 = MySQL.query.await('SELECT 1 FROM nsw_registrations WHERE plate = ? LIMIT 1', { p })
	if r1 and r1[1] then return true end
	
	-- Check Framework table
	local tbl, col = getFrameworkVehicleTable()
	local r2 = MySQL.query.await(('SELECT 1 FROM %s WHERE plate = ? LIMIT 1'):format(tbl), { p })
	if r2 and r2[1] then return true end
	
	return false
end

local function isPlayerVehicleOwner(identifier, plate)
	local p = plateToSql(plate)
	local tbl, col = getFrameworkVehicleTable()
	local query = ('SELECT 1 FROM %s WHERE plate = ? AND %s = ? LIMIT 1'):format(tbl, col)
	local res = MySQL.query.await(query, { p, identifier })
	return res and res[1] ~= nil
end

local function cleanupReservations()
	MySQL.query('DELETE FROM nsw_plate_reservations WHERE expires_at < ?', { now() })
end

lib.callback.register('nsw_reg:isMechanic', function(source)
	local player = Bridge.getPlayer(source)
	local result = player and isMechanic(player) or false
	if Config.Debug then print(('[NSW] Callback nsw_reg:isMechanic for %s returned %s'):format(source, result)) end
	return result
end)

lib.callback.register('nsw_reg:getInfo', function(source, plate)
	local reg = fetchRegistration(plate)
	if not reg then
		-- Fallback to framework table to see if it's an unregistered vehicle
		local p = plateToSql(plate)
		local tbl, col = getFrameworkVehicleTable()
		local row = MySQL.query.await(('SELECT %s as owner_identifier FROM %s WHERE plate = ? LIMIT 1'):format(col, tbl), { p })
		if row and row[1] then
			return {
				plate = p,
				owner_identifier = row[1].owner_identifier,
				status = 'unregistered',
				pink_status = 'expired',
				formatted_pink_expiry = 'None',
				is_printed = false,
				plate_style = 'standard'
			}
		end
		return nil
	end
	local status
	if now() <= reg.expires_at then status = 'valid'
	elseif isWithinGrace(reg.expires_at) then status = 'grace'
	else status = 'expired' end

	local pink_status = 'expired'
	if reg.pink_slip_expires_at > now() then
		pink_status = 'valid'
	end

	return {
		plate = reg.plate,
		owner_identifier = reg.owner_identifier,
		expires_at = reg.expires_at,
		formatted_expiry = os.date('%Y-%m-%d', reg.expires_at),
		pink_slip_expires_at = reg.pink_slip_expires_at,
		formatted_pink_expiry = reg.pink_slip_expires_at > 0 and os.date('%Y-%m-%d', reg.pink_slip_expires_at) or 'None',
		pink_status = pink_status,
		is_printed = reg.is_printed == 1,
		plate_style = reg.plate_style,
		status = status
	}
end)

-- Police flagging commands
RegisterCommand('regflag', function(src, args)
    local player = Bridge.getPlayer(src)
    if not player then return end
    local job = Bridge.getJobName(player)
    local allowed = false
    for _, j in ipairs(Config.AuthorizedJobs.police or {}) do if j == job then allowed = true break end end
    if not allowed then return Bridge.notify(src, 'Not authorized', 'error') end
    local plate = plateToSql(args[1] or '')
    local reason = table.concat(args, ' ', 2)
    if not plate or reason == '' then return Bridge.notify(src, 'Usage: /regflag PLATE reason', 'error') end
    MySQL.query.await('INSERT INTO nsw_reg_flags (plate, reason, actor_identifier) VALUES (?, ?, ?)', { plate, Bridge.getIdentifier(player), reason })
    Bridge.notify(src, ('Flagged %s'):format(plate), 'success')
end)

RegisterCommand('regunflag', function(src, args)
    local player = Bridge.getPlayer(src)
    if not player then return end
    local job = Bridge.getJobName(player)
    local allowed = false
    for _, j in ipairs(Config.AuthorizedJobs.police or {}) do if j == job then allowed = true break end end
    if not allowed then return Bridge.notify(src, 'Not authorized', 'error') end
    local plate = plateToSql(args[1] or '')
    if not plate then return Bridge.notify(src, 'Usage: /regunflag PLATE', 'error') end
    MySQL.query.await('DELETE FROM nsw_reg_flags WHERE plate = ?', { plate })
    Bridge.notify(src, ('Unflagged %s'):format(plate), 'success')
end)

-- Exports
exports('IsPlateValid', function(plate)
    local p = plateToSql(plate)
    if not p or isPlateBlacklisted(p) then return false end
    return true
end)

exports('GetRegistration', function(plate)
    return fetchRegistration(plate)
end)

RegisterNetEvent('nsw_reg:register', function(plate, vehHash, months, style)
	local src = source
	local player = Bridge.getPlayer(src)
	if not player then return end
	if not withinOpeningHours() then return Bridge.notify(src, 'Service Centre is closed', 'error') end
	local identifier = Bridge.getIdentifier(player)
	local rawPlate = plate
	plate = plateToSql(plate)
	if not plate then
		if Config.Debug then print(('[NSW] Register failed: rawPlate="%s" -> plateToSql returned nil'):format(rawPlate)) end
		TriggerClientEvent('nsw_reg:error', src, 'invalid_input')
		return Bridge.notify(src, 'Invalid plate format', 'error')
	end
	if isPlateBlacklisted(plate) then
		TriggerClientEvent('nsw_reg:error', src, 'plate_blacklisted')
		return Bridge.notify(src, 'Plate is not allowed', 'error')
	end
	local isTaken = isPlateTaken(plate)
	local isOwner = isPlayerVehicleOwner(identifier, plate)

	if isTaken and not isOwner then
		if Config.Debug then print(('[NSW] Register failed: plate "%s" is already taken and player is not owner'):format(plate)) end
		TriggerClientEvent('nsw_reg:error', src, 'plate_taken')
		return Bridge.notify(src, 'Plate already in use', 'error')
	end

	-- Pink Slip Check
	if Config.PinkSlip.enabled and Config.PinkSlip.requiredForRegistration then
		-- We allow registration without pink slip for *new* plates? Usually in NSW new cars don't need it for first few years
		-- But for simplicity of script, lets require it if configured.
	end

	local styleFee = 0
	if style then
		for _, s in ipairs(Config.PlateStyles) do
			if s.id == style then styleFee = s.fee break end
		end
	end

	local discount = getDiscountPercentForPlayer(player)
    local base = Config.Registration.baseFee + styleFee
    local opt = Config.RegistrationDurations and Config.RegistrationDurations[tonumber(months or 3)] or Config.RegistrationDurations[3]
    local fee = calculateFee(math.floor(base * (opt.feeMultiplier or 1.0) + 0.5), discount, 0)
	if not Bridge.hasMoney(player, 'bank', fee) then
		TriggerClientEvent('nsw_reg:error', src, 'insufficient_funds')
		return Bridge.notify(src, (Locale.notify and Locale.notify.insufficient_funds) or 'Insufficient funds', 'error')
	end
	if not Bridge.removeMoney(player, 'bank', fee) then
		TriggerClientEvent('nsw_reg:error', src, 'insufficient_funds')
		return Bridge.notify(src, (Locale.notify and Locale.notify.insufficient_funds) or 'Insufficient funds', 'error')
	end
    local data = {
		plate = plate,
		owner_identifier = identifier,
		vehicle_hash = tostring(vehHash or ''),
		registered_at = now(),
        expires_at = now() + ((opt and opt.days or Config.Registration.durationDays) * 86400),
		plate_style = style or 'standard'
	}
	upsertRegistration(data)
	log(('Registered %s for %s fee=%s'):format(data.plate, identifier, fee))
	addLog(data.plate, identifier, 'register', fee, { vehicle_hash = data.vehicle_hash, plate_style = data.plate_style })
	Bridge.notify(src, (Locale.notify and Locale.notify.success_register) or 'Registered', 'success')
	TriggerClientEvent('nsw_reg:registered', src, data.plate)
end)

RegisterNetEvent('nsw_reg:renew', function(plate, months)
	local src = source
	local player = Bridge.getPlayer(src)
	if not player then return end
	if not withinOpeningHours() then return Bridge.notify(src, 'Service Centre is closed', 'error') end
	local identifier = Bridge.getIdentifier(player)
	local reg = fetchRegistration(plate)
	if not reg or reg.owner_identifier ~= identifier then
		TriggerClientEvent('nsw_reg:error', src, 'invalid_input')
		return Bridge.notify(src, (Locale.notify and Locale.notify.invalid_input) or 'Invalid', 'error')
	end

	-- Pink Slip Check for renewal
	if Config.PinkSlip.enabled and Config.PinkSlip.requiredForRenewal then
		if (reg.pink_slip_expires_at or 0) < now() then
			return Bridge.notify(src, 'A valid Pink Slip is required for renewal', 'error')
		end
	end

	local lateDays = 0
	if now() > reg.expires_at then
		lateDays = math.floor((now() - reg.expires_at) / 86400)
	end
    local discount = getDiscountPercentForPlayer(player)
    local latePercent = calculateLatePenalty(lateDays)
    local opt = Config.RegistrationDurations and Config.RegistrationDurations[tonumber(months or 3)] or Config.RegistrationDurations[3]
    local fee = calculateFee(math.floor(Config.Registration.renewalFee * (opt.feeMultiplier or 1.0) + 0.5), discount, latePercent)
	if not Bridge.hasMoney(player, 'bank', fee) then
		TriggerClientEvent('nsw_reg:error', src, 'insufficient_funds')
		return Bridge.notify(src, (Locale.notify and Locale.notify.insufficient_funds) or 'Insufficient funds', 'error')
	end
	if not Bridge.removeMoney(player, 'bank', fee) then
		TriggerClientEvent('nsw_reg:error', src, 'insufficient_funds')
		return Bridge.notify(src, (Locale.notify and Locale.notify.insufficient_funds) or 'Insufficient funds', 'error')
	end
    local addDays = (opt and opt.days) or Config.Registration.durationDays
    local newExpiry = now() > reg.expires_at and (now() + addDays * 86400) or (reg.expires_at + (addDays * 86400))
	MySQL.query.await('UPDATE nsw_registrations SET expires_at = ?, status = 1 WHERE plate = ?', { newExpiry, plateToSql(plate) })
	log(('Renewed %s for %s fee=%s lateDays=%s'):format(reg.plate, identifier, fee, lateDays))
	addLog(reg.plate, identifier, 'renew', fee, { lateDays = lateDays })
	Bridge.notify(src, (Locale.notify and Locale.notify.success_renew) or 'Renewed', 'success')
	TriggerClientEvent('nsw_reg:renewed', src, plateToSql(plate))
end)

RegisterNetEvent('nsw_reg:printPlate', function(plate)
	local src = source
	local player = Bridge.getPlayer(src)
	if not player then return end
	
	plate = plateToSql(plate)
	local reg = fetchRegistration(plate)
	if not reg or reg.owner_identifier ~= Bridge.getIdentifier(player) then
		return Bridge.notify(src, 'Vehicle not found or not owned by you', 'error')
	end

	local isReplacement = reg.is_printed == 1
	local fee = isReplacement and Config.Registration.replacementPlateFee or Config.Registration.printPlateFee

	if not Bridge.hasMoney(player, 'bank', fee) then
		return Bridge.notify(src, 'Insufficient funds to print plate', 'error')
	end

	if not Bridge.removeMoney(player, 'bank', fee) then
		return Bridge.notify(src, 'Error processing payment', 'error')
	end

	if Config.Inventory == 'ox_inventory' then
		local metadata = {
			plate = plate,
			description = ('Vehicle Plate: %s'):format(plate)
		}
		local success, response = exports.ox_inventory:AddItem(src, 'nsw_plate', 1, metadata)
		if not success then
			Bridge.addMoney(player, 'bank', fee) -- refund
			return Bridge.notify(src, 'Cannot carry plate item', 'error')
		end
	else
		-- Fallback if not using ox_inventory, just notify for now or use bridge if we add item support there
		Bridge.notify(src, 'Inventory not supported for physical plates', 'error')
		return
	end

	MySQL.query.await('UPDATE nsw_registrations SET is_printed = 1 WHERE plate = ?', { plate })
	addLog(plate, Bridge.getIdentifier(player), 'print', fee, { isReplacement = isReplacement })
	Bridge.notify(src, ('Plate %s printed successfully'):format(plate), 'success')
end)

RegisterNetEvent('nsw_reg:issuePinkSlip', function(plate)
	local src = source
	local player = Bridge.getPlayer(src)
	if not player or not isMechanic(player) then return Bridge.notify(src, 'Not authorized', 'error') end
	
	plate = plateToSql(plate)
	local reg = fetchRegistration(plate)
	if not reg then return Bridge.notify(src, 'Vehicle registration not found', 'error') end

	local expiry = now() + (Config.PinkSlip.durationDays * 86400)
	MySQL.query.await('UPDATE nsw_registrations SET pink_slip_expires_at = ? WHERE plate = ?', { expiry, plate })
	
	local fee = Config.PinkSlip.fee or 0
	-- Maybe pay mechanic or company? Stubbed for now.
	
	addLog(plate, Bridge.getIdentifier(player), 'pinkslip', fee)
	Bridge.notify(src, ('Issued Pink Slip for %s'):format(plate), 'success')
	TriggerClientEvent('nsw_reg:pinkSlipIssued', src, plate)
	
	-- Notify owner if online
	-- local owner = Bridge.getPlayerFromIdentifier(reg.owner_identifier)
	-- if owner then Bridge.notify(owner.source, ('A Pink Slip has been issued for your vehicle %s'):format(plate), 'inform') end
end)

RegisterNetEvent('nsw_reg:transfer', function(plate, newOwnerIdentifier)
	local src = source
	local player = Bridge.getPlayer(src)
	if not player then return end
	if not withinOpeningHours() then return Bridge.notify(src, 'Service Centre is closed', 'error') end
	local identifier = Bridge.getIdentifier(player)
	local reg = fetchRegistration(plate)
	if not reg or reg.owner_identifier ~= identifier then
		TriggerClientEvent('nsw_reg:error', src, 'invalid_input')
		return Bridge.notify(src, (Locale.notify and Locale.notify.invalid_input) or 'Invalid', 'error')
	end
	local fee = calculateFee(Config.Registration.transferFee, getDiscountPercentForPlayer(player), 0)
	if not Bridge.hasMoney(player, 'bank', fee) then
		TriggerClientEvent('nsw_reg:error', src, 'insufficient_funds')
		return Bridge.notify(src, (Locale.notify and Locale.notify.insufficient_funds) or 'Insufficient funds', 'error')
	end
	if not Bridge.removeMoney(player, 'bank', fee) then
		TriggerClientEvent('nsw_reg:error', src, 'insufficient_funds')
		return Bridge.notify(src, (Locale.notify and Locale.notify.insufficient_funds) or 'Insufficient funds', 'error')
	end
	updateOwner(plate, newOwnerIdentifier)
	log(('Transferred %s from %s to %s fee=%s'):format(reg.plate, identifier, newOwnerIdentifier, fee))
	addLog(reg.plate, identifier, 'transfer', fee, { newOwner = newOwnerIdentifier })
	Bridge.notify(src, (Locale.notify and Locale.notify.success_transfer) or 'Transferred', 'success')
	TriggerClientEvent('nsw_reg:transferred', src, plateToSql(plate), newOwnerIdentifier)
end)

-- Vanity reservation: check availability and reserve
lib.callback.register('nsw_reg:checkPlate', function(source, plate)
	cleanupReservations()
	plate = plateToSql(plate)
	if isPlateBlacklisted(plate) then return { available = false, reason = 'blacklisted' } end
	if isPlateTaken(plate) then return { available = false, reason = 'taken' } end
	local row = MySQL.query.await('SELECT reserved_by, expires_at FROM nsw_plate_reservations WHERE plate = ? LIMIT 1', { plate })
	if row and row[1] then
		return { available = false, reason = 'reserved', expires_at = row[1].expires_at }
	end
	return { available = true }
end)

lib.callback.register('nsw_reg:reservePlate', function(source, plate)
	cleanupReservations()
	local player = Bridge.getPlayer(source)
	if not player then return { ok = false } end
	plate = plateToSql(plate)
	if isPlateBlacklisted(plate) or isPlateTaken(plate) then return { ok = false } end
	local identifier = Bridge.getIdentifier(player)
	local expires = now() + (Config.VanityReservationHours * 3600)
	MySQL.query.await('INSERT INTO nsw_plate_reservations (plate, reserved_by, reserved_at, expires_at) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE reserved_by = VALUES(reserved_by), reserved_at = VALUES(reserved_at), expires_at = VALUES(expires_at)', { plate, identifier, now(), expires })
	return { ok = true, expires_at = expires }
end)

-- Player reminder on join
AddEventHandler('playerJoining', function()
	local src = source
	local player = Bridge.getPlayer(src)
	if not player or not (Config.Reminders and Config.Reminders.enabled) then return end
	local identifier = Bridge.getIdentifier(player)
	local rows = MySQL.query.await('SELECT plate, expires_at FROM nsw_registrations WHERE owner_identifier = ? AND expires_at BETWEEN ? AND ?', { identifier, now(), now() + (Config.Reminders.daysBefore * 86400) })
	if rows and #rows > 0 then
		for _, r in ipairs(rows) do
			Bridge.notify(src, ('Registration for %s expires on %s'):format(r.plate, os.date('%Y-%m-%d', r.expires_at)), 'inform')
		end
	end
end)

lib.callback.register('nsw_reg:getHistory', function(source, plate)
	local rows = MySQL.query.await('SELECT plate, actor_identifier, action, fee, created_at FROM nsw_reg_logs WHERE plate = ? ORDER BY id DESC LIMIT 25', { plateToSql(plate) })
	return rows or {}
end)

lib.callback.register('nsw_reg:calcFees', function(source, action, lateDays)
	local discount = 0.0
	local player = Bridge.getPlayer(source)
	if player then discount = getDiscountPercentForPlayer(player) end
	local base = 0
	if action == 'register' then base = Config.Registration.baseFee
	elseif action == 'renew' then base = Config.Registration.renewalFee
	elseif action == 'transfer' then base = Config.Registration.transferFee end
	local latePercent = calculateLatePenalty(tonumber(lateDays) or 0)
	local fee = calculateFee(base, discount, latePercent)
	return { base = base, discount = discount, latePercent = latePercent, total = fee }
end)

-- Admin/police check by job
lib.callback.register('nsw_reg:lookup', function(source, plate)
	local player = Bridge.getPlayer(source)
	if not player then return nil end
	local job = Bridge.getJobName(player)
	local allowed = false
	for _, j in ipairs(Config.AuthorizedJobs.police or {}) do
		if j == job then allowed = true break end
	end
	if not allowed then return nil end
	local reg = fetchRegistration(plate)
	if not reg then return nil end
	local flags = MySQL.query.await('SELECT reason, actor_identifier, created_at FROM nsw_reg_flags WHERE plate = ? ORDER BY id DESC LIMIT 1', { plateToSql(plate) })
	reg.flag = flags and flags[1] or nil
	if Config.Registration.impoundOnExpired and now() > reg.expires_at then
		-- Optional: trigger impound event here
		-- TriggerEvent('impound:vehicleByPlate', reg.plate)
	end
	return reg
end)


