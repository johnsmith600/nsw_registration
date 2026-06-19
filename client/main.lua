-- Copyright (c) 2025 johnsmith600
-- Licensed: Free to use AS-IS (no modification, no redistribution, no resale).
-- See LICENSE file for full terms: https://github.com/johnsmith600/nsw_registration/blob/main/LICENSE

local Config = require 'shared.config'
local Locale = require 'locales.en'

-- Ensure NUI is hidden and focus is cleared on startup
CreateThread(function()
	isOpen = false
	SetNuiFocus(false, false)
	if SetNuiFocusKeepInput then SetNuiFocusKeepInput(false) end
	SendNUIMessage({ action = 'hide' })
	Wait(150)
	SendNUIMessage({ action = 'hide' })
end)

AddEventHandler('onClientResourceStart', function(res)
	if res ~= GetCurrentResourceName() then return end
	isOpen = false
	SetNuiFocus(false, false)
	if SetNuiFocusKeepInput then SetNuiFocusKeepInput(false) end
	SendNUIMessage({ action = 'hide' })
	Wait(150)
	SendNUIMessage({ action = 'hide' })
end)

local isOpen = false
local function closeNui()
	if not isOpen then return end
	SetNuiFocus(false, false)
	if SetNuiFocusKeepInput then SetNuiFocusKeepInput(false) end
	SendNUIMessage({ action = 'hide' })
	isOpen = false
	if Config.Debug then print('[NSW] NUI closed') end
end

local function openMenu()
	if isOpen then return closeNui() end
	local isMechanic = lib.callback.await('nsw_reg:isMechanic', false)
	SendNUIMessage({ action = 'show', locale = Locale, subtitle = 'Service Centre', isMechanic = isMechanic, plateStyles = Config.PlateStyles })
	SetNuiFocus(true, true)
	if SetNuiFocusKeepInput then SetNuiFocusKeepInput(false) end
	isOpen = true
	if Config.Debug then print('[NSW] NUI opened') end
end

RegisterCommand('nswregmenu', function()
	openMenu()
end)

RegisterCommand('nswreg', function(_, args)
	if not args[1] then return end
	TriggerServerEvent('nsw_reg:register', args[1])
end)

-- World interaction: go to DMV location and press E
CreateThread(function()
	if not (Config.DMVLocations and #Config.DMVLocations > 0) then return end
	for _, entry in ipairs(Config.DMVLocations) do
		local pos = entry.coords
		if lib and lib.points and lib.showTextUI then
			local point = lib.points.new({ coords = vec3(pos.x, pos.y, pos.z), distance = 25.0 })
			function point:onEnter()
				lib.showTextUI(('[%s] %s'):format('E', Locale.open_menu))
				if Config.Debug then print('[NSW] Entered DMV point') end
			end
			function point:onExit()
				lib.hideTextUI()
				closeNui()
				if Config.Debug then print('[NSW] Exited DMV point') end
			end
			function point:nearby()
				DrawMarker(2, pos.x, pos.y, pos.z - 0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.35, 0.35, 0.35, 0, 153, 255, 160, false, false, 2, false, nil, nil, false)
				if self.currentDistance < 2.0 and IsControlJustReleased(0, 38) then -- E
					openMenu()
					if Config.Debug then print('[NSW] E pressed at DMV point') end
				end
			end
		else
			-- Fallback without ox_lib points: simple loop
			CreateThread(function()
				while true do
					local ped = PlayerPedId()
					local p = GetEntityCoords(ped)
					local dist = #(p - vec3(pos.x, pos.y, pos.z))
					if dist < 25.0 then
						DrawMarker(2, pos.x, pos.y, pos.z - 0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.35, 0.35, 0.35, 0, 153, 255, 160, false, false, 2, false, nil, nil, false)
						if dist < 2.0 then
							BeginTextCommandDisplayHelp('STRING')
							AddTextComponentSubstringPlayerName(('Press ~INPUT_CONTEXT~ to %s'):format(Locale.open_menu))
							EndTextCommandDisplayHelp(0, false, true, -1)
							if IsControlJustReleased(0, 38) then
								openMenu()
							end
						elseif dist >= 3.0 and isOpen then
							closeNui()
						end
						Wait(0)
					else
						Wait(1000)
					end
				end
			end)
		end
	end
end)

RegisterCommand('nswrenew', function(_, args)
	if not args[1] then return end
	TriggerServerEvent('nsw_reg:renew', args[1])
end)

-- Force-close command if needed
RegisterCommand('nswclose', function()
	closeNui()
end)

RegisterCommand('nswtransfer', function(_, args)
	if not args[1] or not args[2] then return end
	TriggerServerEvent('nsw_reg:transfer', args[1], args[2])
end)

RegisterCommand('nswlookup', function(_, args)
	if not args[1] then return end
	local info = lib.callback.await('nsw_reg:getInfo', false, args[1])
	if info then
		local expiry = info.formatted_expiry or 'N/A'
		print(('[NSW] %s owner=%s expiry=%s status=%s'):format(info.plate, info.owner_identifier, expiry, info.status))
	else
		print('[NSW] Not found')
	end
end)

-- Map blips
CreateThread(function()
	if not (Config.Blip and Config.Blip.enabled) then return end
	for _, entry in ipairs(Config.DMVLocations or {}) do
		local pos = entry.coords
		local blip = AddBlipForCoord(pos.x, pos.y, pos.z)
		SetBlipSprite(blip, Config.Blip.sprite or 438)
		SetBlipDisplay(blip, 4)
		SetBlipScale(blip, Config.Blip.scale or 0.8)
		SetBlipColour(blip, Config.Blip.color or 29)
		SetBlipAsShortRange(blip, Config.Blip.shortRange ~= false)
		BeginTextCommandSetBlipName('STRING')
		AddTextComponentSubstringPlayerName(entry.label or Config.Blip.label or 'NSW Service Centre')
		EndTextCommandSetBlipName(blip)
	end
end)

-- Server feedback notifications
RegisterNetEvent('nsw_reg:registered', function(plate)
	if lib and lib.notify then
		lib.notify({ title = 'NSW', description = (Locale.notify.success_register .. ' [' .. (plate or '') .. ']'), type = 'success' })
	end
	if Config.Debug then print('[NSW] registered ' .. tostring(plate)) end
end)

RegisterNetEvent('nsw_reg:renewed', function(plate)
	if lib and lib.notify then
		lib.notify({ title = 'NSW', description = (Locale.notify.success_renew .. ' [' .. (plate or '') .. ']'), type = 'success' })
	end
	if Config.Debug then print('[NSW] renewed ' .. tostring(plate)) end
end)

RegisterNetEvent('nsw_reg:transferred', function(plate, newOwner)
	if lib and lib.notify then
		lib.notify({ title = 'NSW', description = (Locale.notify.success_transfer .. ' [' .. (plate or '') .. ']'), type = 'success' })
	end
	if Config.Debug then print('[NSW] transferred ' .. tostring(plate) .. ' -> ' .. tostring(newOwner)) end
end)

RegisterNetEvent('nsw_reg:error', function(code)
	local msg = (Locale.notify and Locale.notify[code]) or 'Error'
	if lib and lib.notify then
		lib.notify({ title = 'NSW', description = msg, type = 'error' })
	end
	if Config.Debug then print('[NSW] error ' .. tostring(code)) end
end)

-- NUI callbacks
RegisterNUICallback('nui_close', function(_, cb)
	closeNui()
	cb(1)
end)

RegisterNUICallback('nui_register', function(data, cb)
	TriggerServerEvent('nsw_reg:register', tostring(data.plate or ''), nil, tonumber(data.months) or 3, data.style)
	cb(1)
end)

RegisterNUICallback('nui_issue_pink', function(data, cb)
	TriggerServerEvent('nsw_reg:issuePinkSlip', tostring(data.plate or ''))
	cb(1)
end)

-- Ensure focus is cleared if resource stops while open
AddEventHandler('onResourceStop', function(res)
	if res ~= GetCurrentResourceName() then return end
	SetNuiFocus(false, false)
	SendNUIMessage({ action = 'hide' })
	isOpen = false
end)

-- Aggressive watchdog to ensure UI stays closed unless explicitly opened
-- Watchdog to ensure focus is cleared if UI is hidden but still has focus
CreateThread(function()
	while true do
		if not isOpen and IsNuiFocused() then
			SetNuiFocus(false, false)
			if SetNuiFocusKeepInput then SetNuiFocusKeepInput(false) end
			SendNUIMessage({ action = 'hide' })
		end
		Wait(1000)
	end
end)

-- Close if game pause menu opens
CreateThread(function()
	while true do
		if isOpen and IsPauseMenuActive() then
			closeNui()
		end
		Wait(200)
	end
end)

-- Hard reset command to re-hide UI and clear focus
RegisterCommand('nswresetui', function()
	isOpen = false
	SetNuiFocus(false, false)
	if SetNuiFocusKeepInput then SetNuiFocusKeepInput(false) end
	SendNUIMessage({ action = 'hide' })
end)

RegisterNUICallback('nui_renew', function(data, cb)
	TriggerServerEvent('nsw_reg:renew', tostring(data.plate or ''), tonumber(data.months) or 3)
	cb(1)
end)

RegisterNUICallback('nui_transfer', function(data, cb)
	TriggerServerEvent('nsw_reg:transfer', tostring(data.plate or ''), tostring(data.newOwner or ''))
	cb(1)
end)

RegisterNUICallback('nui_lookup', function(data, cb)
	local info = lib.callback.await('nsw_reg:getInfo', false, tostring(data.plate or ''))
	SendNUIMessage({ action = 'lookup_result', info = info })
	cb(1)
end)

RegisterNUICallback('nui_history', function(data, cb)
	local rows = lib.callback.await('nsw_reg:getHistory', false, tostring(data.plate or ''))
	SendNUIMessage({ action = 'history_result', rows = rows })
	cb(1)
end)

RegisterNUICallback('nui_calc', function(data, cb)
	local fees = lib.callback.await('nsw_reg:calcFees', false, tostring(data.action or 'register'), tonumber(data.lateDays) or 0)
	SendNUIMessage({ action = 'fees_result', fees = fees })
	cb(1)
end)

RegisterNUICallback('nui_check', function(data, cb)
	local result = lib.callback.await('nsw_reg:checkPlate', false, tostring(data.plate or ''))
	SendNUIMessage({ action = 'vanity_check', result = result })
	cb(1)
end)

RegisterNUICallback('nui_reserve', function(data, cb)
	local result = lib.callback.await('nsw_reg:reservePlate', false, tostring(data.plate or ''))
	if result and result.ok then
		SendNUIMessage({ action = 'vanity_reserved', result = result })
	else
		SendNUIMessage({ action = 'vanity_check', result = { available = false } })
	end
	cb(1)
end)

RegisterNUICallback('nui_print', function(data, cb)
	TriggerServerEvent('nsw_reg:printPlate', tostring(data.plate or ''))
	cb(1)
end)

-- Physical Plate Usage
exports('usePlate', function(data, slot)
	local plate = slot.metadata.plate
	if not plate then return end

	local vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), 3.0, false)
	if not vehicle then
		return lib.notify({ title = 'NSW', description = 'No vehicle nearby', type = 'error' })
	end

	local vehPlate = plateToSql(GetVehicleNumberPlateText(vehicle))
	if vehPlate ~= plateToSql(plate) then
		return lib.notify({ title = 'NSW', description = 'This plate does not match this vehicle', type = 'error' })
	end

	if lib.progressBar({
		duration = 5000,
		label = 'Attaching plate...',
		useWhileDead = false,
		canCancel = true,
		disable = { car = true, move = true },
		anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig5@', clip = 'working_look_around_workerk' },
	}) then
		lib.notify({ title = 'NSW', description = 'Plate attached successfully', type = 'success' })
		-- In a real scenario, you might want to save that it's attached or change the plate style.
	else
		lib.notify({ title = 'NSW', description = 'Cancelled', type = 'inform' })
	end
end)

function plateToSql(plate)
	if not plate then return nil end
	local s = tostring(plate):upper()
	s = s:gsub('[^A-Z0-9]', '')
	return s
end


