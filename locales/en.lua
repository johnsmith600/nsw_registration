-- Copyright (c) 2025 johnsmith600
-- Licensed: Free to use AS-IS (no modification, no redistribution, no resale).
-- See LICENSE file for full terms: https://github.com/johnsmith600/nsw_registration/blob/main/LICENSE

local Locale = {}

Locale.open_menu = 'Open NSW Registration'
Locale.menu_title = 'NSW Vehicle Registration'
Locale.actions = {
	register = 'Register Vehicle',
	renew = 'Renew Registration',
	transfer = 'Transfer Ownership',
	lookup = 'Lookup Plate',
	close = 'Close'
}

Locale.labels = {
	plate = 'Plate',
	owner = 'Owner',
	status = 'Status',
	expiry = 'Expiry',
	fee = 'Fee',
	new_owner_id = 'New Owner ID',
	vehicle = 'Vehicle'
}

Locale.status = {
	valid = 'Valid',
	expired = 'Expired',
	grace = 'In Grace Period'
}

Locale.notify = {
	success_register = 'Vehicle registered successfully.',
	success_renew = 'Registration renewed successfully.',
	success_transfer = 'Ownership transferred successfully.',
	insufficient_funds = 'You do not have enough funds.',
	no_vehicle = 'No nearby owned vehicle found.',
	forbidden = 'You are not authorized for this action.',
	lookup_no_result = 'No registration found for that plate.',
	invalid_input = 'Invalid input.',
	plate_taken = 'Plate is already in use.',
	plate_blacklisted = 'Plate contains forbidden letters.',
	invalid_plate = 'Invalid plate format.',
	opening_menu = 'Opening NSW registration menu...',
	starting_register = 'Submitting registration...',
	starting_renew = 'Submitting renewal...',
	starting_transfer = 'Submitting transfer...',
	lookup_success = 'Lookup success.'
}

return Locale

