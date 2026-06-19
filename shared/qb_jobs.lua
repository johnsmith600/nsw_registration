-- Copyright (c) 2025 johnsmith600
-- Licensed: Free to use AS-IS (no modification, no redistribution, no resale).
-- See LICENSE file for full terms: https://github.com/johnsmith600/nsw_registration/blob/main/LICENSE

-- QBCore job definitions for NSW Registration
-- Merge into qb-core/shared/jobs.lua or load via your own job loader.

QBShared = QBShared or {}
QBShared.Jobs = QBShared.Jobs or {}

QBShared.Jobs['dmv'] = {
	label = 'NSW Service',
	type = 'government',
	defaultDuty = true,
	grades = {
		['0'] = { name = 'Trainee', payment = 100 },
		['1'] = { name = 'Clerk', payment = 150 },
		['2'] = { name = 'Manager', payment = 200 },
	}
}

QBShared.Jobs['services'] = {
	label = 'Services',
	type = 'government',
	defaultDuty = true,
	grades = {
		['0'] = { name = 'Trainee', payment = 100 },
		['1'] = { name = 'Staff', payment = 150 },
		['2'] = { name = 'Supervisor', payment = 200 },
	}
}


