-- Copyright (c) 2025 johnsmith600
-- Licensed: Free to use AS-IS (no modification, no redistribution, no resale).
-- See LICENSE file for full terms: https://github.com/johnsmith600/nsw_registration/blob/main/LICENSE

local Config = Config or {}

local Bridge = {
	name = 'unknown',
	obj = nil,
	isReady = false
}

local function tryGetQBCore()
	local ok, qb = pcall(function()
		if GetResourceState('qb-core') == 'started' then
			return exports['qb-core']:GetCoreObject()
		end
		return nil
	end)
	if ok and qb then return qb end
	return nil
end

local function tryGetESX()
	local ok, esx = pcall(function()
		if GetResourceState('es_extended') == 'started' then
			return exports['es_extended']:getSharedObject()
		end
		return nil
	end)
	if ok and esx then return esx end
	return nil
end

local function init()
	local mode = (Config.Framework or 'auto'):lower()
	if mode == 'qb' then
		Bridge.obj = tryGetQBCore()
		Bridge.name = Bridge.obj and 'qb' or 'unknown'
	elseif mode == 'esx' then
		Bridge.obj = tryGetESX()
		Bridge.name = Bridge.obj and 'esx' or 'unknown'
	else
		Bridge.obj = tryGetQBCore() or tryGetESX()
		Bridge.name = Bridge.obj and (Bridge.obj.Shared and 'qb' or 'esx') or 'unknown'
	end
	Bridge.isReady = Bridge.obj ~= nil
end

init()

function Bridge.getPlayer(source)
	if not Bridge.isReady then return nil end
	if Bridge.name == 'qb' then
		return Bridge.obj.Functions.GetPlayer(source)
	else
		return Bridge.obj.GetPlayerFromId(source)
	end
end

function Bridge.getIdentifier(player)
	if not player then return nil end
	if Bridge.name == 'qb' then
		return player.PlayerData.license or player.PlayerData.citizenid
	else
		return player.identifier
	end
end

function Bridge.getJobName(player)
	if not player then return nil end
	if Bridge.name == 'qb' then
		return player.PlayerData.job and player.PlayerData.job.name or nil
	else
		return player.getJob and player.getJob().name or (player.job and player.job.name)
	end
end

function Bridge.addMoney(player, account, amount)
	if not player or not amount or amount <= 0 then return false end
	account = account or 'bank'
	if Bridge.name == 'qb' then
		local ok = player.Functions.AddMoney(account, amount)
		return ok ~= false
	else
		if account == 'bank' then
			player.addAccountMoney('bank', amount)
		else
			player.addMoney(amount)
		end
		return true
	end
end

function Bridge.removeMoney(player, account, amount)
	if not player or not amount or amount <= 0 then return false end
	account = account or 'bank'
	if Bridge.name == 'qb' then
		return player.Functions.RemoveMoney(account, amount) ~= false
	else
		-- ESX remove* APIs don't return a boolean; assume success after call
		if account == 'bank' then
			player.removeAccountMoney('bank', amount)
		else
			player.removeMoney(amount)
		end
		return true
	end
end

function Bridge.getMoney(player, account)
	if not player then return 0 end
	account = account or 'bank'
	if Bridge.name == 'qb' then
		local bal = player.Functions.GetMoney(account)
		return tonumber(bal) or 0
	else
		if account == 'bank' then
			local acc = player.getAccount and player.getAccount('bank')
			return acc and tonumber(acc.money) or 0
		else
			return tonumber(player.getMoney and player.getMoney() or 0) or 0
		end
	end
end

function Bridge.hasMoney(player, account, amount)
	local bal = Bridge.getMoney(player, account)
	return bal >= (amount or 0)
end

function Bridge.notify(src, msg, type, duration)
	type = type or 'inform'
	duration = duration or 5000
	if Config.UseOxLib and lib and lib.notify then
		lib.notify(src and { id = src, title = 'NSW Registration', description = msg, type = type, duration = duration } or { title = 'NSW Registration', description = msg, type = type, duration = duration })
	else
		TriggerClientEvent('chat:addMessage', src or -1, { args = { '^2NSW', msg } })
	end
end

return Bridge

