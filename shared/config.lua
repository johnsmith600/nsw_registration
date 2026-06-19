-- Copyright (c) 2025 johnsmith600
-- Licensed: Free to use AS-IS (no modification, no redistribution, no resale).
-- See LICENSE file for full terms: https://github.com/johnsmith600/nsw_registration/blob/main/LICENSE

Config = {}

-- auto | esx | qb | qbox
Config.Framework = 'auto'

-- Debugging
Config.Debug = true

-- General integrations
Config.UseOxLib = true
Config.Target = 'ox_target' -- optional: set to false to disable
Config.Inventory = 'ox_inventory' -- optional: set to false to disable
Config.UseDHSBanking = true -- set to true to use DHS-BankingSim instead of framework banks
-- Format uses % for digits and letters as uppercase by default. Example: NSW AB12 CD34 -> 'NSW%% %%%%'
Config.PlateFormat = 'NSW% %%%%'

Config.Registration = {
	baseFee = 450.0, -- first registration
	renewalFee = 350.0,
	transferFee = 220.0,
	vanityPlateFee = 800.0,
	printPlateFee = 50.0, -- fee to print physical plates
	replacementPlateFee = 100.0, -- fee for lost plates
	durationDays = 90,
	graceDays = 7, -- days after expiry where fines escalate
	latePenaltyPercentPerDay = 5.0, -- percentage on renewal per late day (capped below)
	latePenaltyCapPercent = 50.0,
	impoundOnExpired = false -- if true, vehicles may be impounded on police check
}

-- Pink Slip settings
Config.PinkSlip = {
	enabled = true,
	fee = 50.0, -- Fee charged by mechanics
	durationDays = 180, -- 6 months
	requiredForRegistration = true,
	requiredForRenewal = true,
	authorizedJobs = { 'mechanic', 'bennys' }
}

-- Available registration durations and fee multipliers (e.g., discounts for longer terms)
Config.RegistrationDurations = {
	[3] = { months = 3, days = 90, feeMultiplier = 1.0 },
	[6] = { months = 6, days = 180, feeMultiplier = 1.90 },
	[12] = { months = 12, days = 365, feeMultiplier = 3.60 }
}

-- NSW Plate Styles
Config.PlateStyles = {
	{ id = 'standard', label = 'Standard (Yellow/Black)', fee = 0 },
	{ id = 'white', label = 'White (White/Black)', fee = 50 },
	{ id = 'black', label = 'Black (Black/White)', fee = 50 },
	{ id = 'euro', label = 'Euro style', fee = 150 },
	{ id = 'jdm', label = 'JDM style', fee = 100 }
}

-- Plate blacklist patterns (Lua patterns), e.g. forbidden words or formats
Config.PlateBlacklist = {
	"FUK", "CUNT", "N1G", "K1LL", "^POL", "^NSW0"
}

-- Vanity reservation settings (how long a reservation is held before expiring)
Config.VanityReservationHours = 24

-- Reminder settings
Config.Reminders = {
	enabled = true,
	daysBefore = 5 -- notify when expiry within this many days
}

-- Discounts for businesses (job name -> percent discount)
Config.BusinessDiscounts = {
	mechanic = 10.0
}

-- Jobs allowed to perform special actions
Config.AuthorizedJobs = {
	dmv = { 'dmv', 'services' }, -- can register, renew, transfer on behalf
	police = { 'police', 'highway' } -- can check/flag vehicles
}

-- DMV office locations for interaction prompts (x,y,z,heading)
Config.DMVLocations = {
	{ coords = vec4(233.12, -410.58, 48.11, 340.0), label = 'NSW Service Centre' }
}

-- Logging
Config.Logging = {
	enabled = true,
	print = true,
	webhook = '' -- optional
}

-- Locale key
Config.Locale = 'en'

-- Map blip settings for DMV locations
Config.Blip = {
	enabled = true,
	sprite = 438, -- Town Hall/Services-like icon
	color = 29, -- blue
	scale = 0.8,
	shortRange = true,
	label = 'NSW Service Centre'
}

-- Opening hours (24h format). Set enabled=false to disable.
Config.OpeningHours = {
	enabled = false,
	open = 8,
	close = 18
}

-- Plate generator characters
Config.PlateCharset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'

-- Vanity cooldown (minutes) between reservations by same player
Config.VanityCooldownMinutes = 10

-- DMV staff free toggle
Config.StaffFree = true

return Config
