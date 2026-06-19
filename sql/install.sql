-- Copyright (c) 2025 johnsmith600
-- Licensed: Free to use AS-IS (no modification, no redistribution, no resale).
-- See LICENSE file for full terms: https://github.com/johnsmith600/nsw_registration/blob/main/LICENSE

CREATE TABLE IF NOT EXISTS `nsw_registrations` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `plate` VARCHAR(16) NOT NULL,
  `owner_identifier` VARCHAR(64) NOT NULL,
  `vehicle_hash` VARCHAR(64) DEFAULT NULL,
  `registered_at` INT NOT NULL,
  `expires_at` INT NOT NULL,
  `pink_slip_expires_at` INT DEFAULT 0,
  `is_printed` TINYINT NOT NULL DEFAULT 0,
  `plate_style` VARCHAR(32) DEFAULT 'standard',
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `plate_unique` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `nsw_reg_logs` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `plate` VARCHAR(16) NOT NULL,
  `actor_identifier` VARCHAR(64) NOT NULL,
  `action` ENUM('register','renew','transfer','pinkslip','print') NOT NULL,
  `fee` INT NOT NULL DEFAULT 0,
  `meta` JSON NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `by_plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `nsw_plate_reservations` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `plate` VARCHAR(16) NOT NULL UNIQUE,
  `reserved_by` VARCHAR(64) NOT NULL,
  `reserved_at` INT NOT NULL,
  `expires_at` INT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `nsw_reg_flags` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `plate` VARCHAR(16) NOT NULL,
  `reason` VARCHAR(128) NOT NULL,
  `actor_identifier` VARCHAR(64) NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `by_plate_flag` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
