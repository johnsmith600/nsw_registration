-- Copyright (c) 2025 johnsmith600
-- Licensed: Free to use AS-IS (no modification, no redistribution, no resale).
-- See LICENSE file for full terms: https://github.com/johnsmith600/nsw_registration/blob/main/LICENSE


-- ESX job definitions for NSW Registration
-- Run this after your ESX schema is installed.

-- DMV job
INSERT IGNORE INTO `jobs` (`name`, `label`, `whitelisted`) VALUES
('dmv', 'NSW Service', 1);

INSERT IGNORE INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
('dmv', 0, 'trainee', 'Trainee', 100, '{}', '{}'),
('dmv', 1, 'clerk', 'Clerk', 150, '{}', '{}'),
('dmv', 2, 'manager', 'Manager', 200, '{}', '{}');

-- Services job (optional helper group)
INSERT IGNORE INTO `jobs` (`name`, `label`, `whitelisted`) VALUES
('services', 'Services', 1);

INSERT IGNORE INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
('services', 0, 'trainee', 'Trainee', 100, '{}', '{}'),
('services', 1, 'staff', 'Staff', 150, '{}', '{}'),
('services', 2, 'supervisor', 'Supervisor', 200, '{}', '{}');


