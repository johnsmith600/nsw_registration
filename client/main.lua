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
local openedByDMV = false

local function closeNui()
	if not isOpen then return end
	SetNuiFocus(false, false)
	if SetNuiFocusKeepInput then SetNuiFocusKeepInput(false) end
	SendNUIMessage({ action = 'hide' })
	isOpen = false
	if Config.Debug then print('[NSW] NUI closed') end
end

local function openMenu(startPage, fromDMV)
	if isOpen then return closeNui() end
	if Config.Debug then print('[NSW] Opening menu, startPage:', startPage, 'fromDMV:', fromDMV) end
	openedByDMV = fromDMV or false
	local isMechanic = lib.callback.await('nsw_reg:isMechanic', false)
	if Config.Debug then print('[NSW] isMechanic check returned:', isMechanic) end
	
	SendNUIMessage({ 
		action = 'show', 
		locale = Locale, 
		subtitle = 'Service Centre', 
		isMechanic = isMechanic, 
		plateStyles = Config.PlateStyles,
		startPage = startPage,
		config = {
			printPlateFee = Config.Registration.printPlateFee,
			pinkSlipFee = Config.PinkSlip.fee,
			vanityPlateFee = Config.Registration.vanityPlateFee
		}
	})
	
	SetNuiFocus(true, true)
	if SetNuiFocusKeepInput then SetNuiFocusKeepInput(false) end
	isOpen = true
	if Config.Debug then print('[NSW] NUI opened successfully') end
end

-- Command removed for civilians as requested. Mechanics use /nswmechanic

RegisterCommand('nswmechanic', function()
	local isMechanic = lib.callback.await('nsw_reg:isMechanic', false)
	if isMechanic then
		openMenu('mechanic', false)
	else
		if lib and lib.notify then
			lib.notify({ title = 'NSW', description = 'You are not authorized to use the Mechanic Portal', type = 'error' })
		end
	end
end)

RegisterCommand('nswreg', function(_, args)
	if not args[1] then return end
	TriggerServerEvent('nsw_reg:register', args[1])
end)

-- World interaction: go to DMV location and press E
-- Revamped to be more reliable using a single loop for markers and input
CreateThread(function()
	if not (Config.DMVLocations and #Config.DMVLocations > 0) then return end
	
	while true do
		local sleep = 1000
		local ped = PlayerPedId()
		local coords = GetEntityCoords(ped)
		local nearAny = false

		for _, entry in ipairs(Config.DMVLocations) do
			local pos = entry.coords
			local dist = #(coords - vec3(pos.x, pos.y, pos.z))

			if dist < 15.0 then
				sleep = 0
				nearAny = true
				DrawMarker(2, pos.x, pos.y, pos.z - 0.4, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 0, 153, 255, 160, false, false, 2, false, nil, nil, false)
				
				if dist < 2.0 then
					if lib and lib.showTextUI then
						lib.showTextUI(('[E] %s'):format(Locale.open_menu))
					else
						BeginTextCommandDisplayHelp('STRING')
						AddTextComponentSubstringPlayerName(('Press ~INPUT_CONTEXT~ to %s'):format(Locale.open_menu))
						EndTextCommandDisplayHelp(0, false, true, -1)
					end

					if IsControlJustPressed(0, 38) then -- E
						if Config.Debug then print('[NSW] E pressed at DMV point') end
						openMenu(nil, true)
						Wait(500) -- prevent double trigger
					end
				end
			end
		end

		if not nearAny then
			if lib and lib.hideTextUI then lib.hideTextUI() end
			-- Only auto-close if we opened it at the DMV. 
			-- If opened via command/mechanic portal, let them use it anywhere.
			if isOpen and openedByDMV then
				closeNui()
			end
		end

		Wait(sleep)
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
	local msg = (Locale.notify and Locale.notify[code]) or ('Error: ' .. tostring(code))
	if lib and lib.notify then
		lib.notify({ title = 'NSW', description = msg, type = 'error' })
	end
	if Config.Debug then print('[NSW] error ' .. tostring(code)) end
end)

RegisterNetEvent('nsw_reg:pinkSlipIssued', function(plate)
	if lib and lib.notify then
		lib.notify({ title = 'NSW', description = 'Pink Slip issued for plate ' .. tostring(plate), type = 'success' })
	end
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

RegisterNUICallback('nui_purchase_custom', function(data, cb)
	TriggerServerEvent('nsw_reg:purchaseCustomPlate', tostring(data.oldPlate or ''), tostring(data.newPlate or ''))
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
		anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
	}) then
		lib.notify({ title = 'NSW', description = 'Plate attached successfully', type = 'success' })
		-- In a real scenario, you might want to save that it's attached or change the plate style.
	else
		lib.notify({ title = 'NSW', description = 'Cancelled', type = 'inform' })
	end
end)

RegisterNetEvent('nsw_reg:updateVehiclePlate', function(oldPlate, newPlate)
	local vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), 5.0, false)
	if not vehicle then return end
	
	local currentPlate = plateToSql(GetVehicleNumberPlateText(vehicle))
	if currentPlate == plateToSql(oldPlate) then
		SetVehicleNumberPlateText(vehicle, newPlate)
		lib.notify({ title = 'NSW', description = 'Vehicle plate updated successfully', type = 'success' })
	end
end)

function plateToSql(plate)
	if not plate then return nil end
	local s = tostring(plate):upper()
	s = s:gsub('[^A-Z0-9]', '')
	return s
end


