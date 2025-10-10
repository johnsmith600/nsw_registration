-- Copyright (c) 2025 johnsmith600
-- Licensed: Free to use AS-IS (no modification, no redistribution, no resale).
-- See LICENSE file for full terms: https://github.com/johnsmith600/nsw_registration/blob/main/LICENSE

# NSW Registration (ESX/QBCore)

Advanced New South Wales style vehicle registration for FiveM with ESX and QBCore support.

## Requirements
- ox_lib (context/menu + notify)
- oxmysql
- One of: es_extended (v1.10+) or qb-core (latest)

## Installation
1. Drag `nsw_registration` to your `resources` directory.
2. Import SQL:
   - Run the file `nsw_registration/sql/install.sql` in your database.
3. Ensure resources in `server.cfg`:
   ```cfg
   ensure oxmysql
   ensure ox_lib
   ensure es_extended # or qb-core
   ensure nsw_registration
   ```
4. Configure `shared/config.lua` as needed.

## Usage
- Open UI: `/nswregmenu`
- Commands (fallback):
  - `/nswreg PLATE`
  - `/nswrenew PLATE`
  - `/nswtransfer PLATE NEWIDENTIFIER`
  - `/nswlookup PLATE`

## Features
- NSW style plate format and configurable fees
- Register, renew, transfer, and lookup
- Grace period and late penalties
- Job-based permissions for police checks
- Business discounts (e.g. mechanics)
- ox_lib UI with notify; command fallbacks

## Notes
- Money is charged from bank by default.
- Identifiers: uses license/citizenid on QBCore, identifier on ESX.
- Webhook logging is stubbed; add your URL in `Config.Logging.webhook`.

## Support
This resource was generated as a starting point. Adjust UI/validation and integrate with your plate generation as needed.

