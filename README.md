## Copyright (c) 2025 johnsmith600
## Licensed: Free to use AS-IS (no modification, no redistribution, no resale).
## See LICENSE file for full terms: https://github.com/johnsmith600/nsw_registration/blob/main/LICENSE

# NSW Registration (ESX/QBCore)

Advanced New South Wales style vehicle registration for FiveM with ESX and QBCore support.

## Requirements
- ox_lib (notify)
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
- ox_lib notify; command fallbacks

## Notes
- Money is charged from bank by default.
- Identifiers: uses license/citizenid on QBCore, identifier on ESX.
- Webhook logging is stubbed; add your URL in `Config.Logging.webhook`.

## screenshots
# Vanity
<img width="1009" height="736" alt="ui1" src="https://github.com/user-attachments/assets/fc4ca7b5-739e-4d6b-b98f-b3bbac1b1d7e" />
# Register
<img width="997" height="727" alt="ui2" src="https://github.com/user-attachments/assets/6e3669d5-41cf-4dce-b27f-f8cc905b7826" />
# Renew
<img width="1014" height="778" alt="ui3" src="https://github.com/user-attachments/assets/6b5d1dcb-31ed-4754-9837-784129729bdd" />
# Transfer
<img width="1066" height="734" alt="ui4" src="https://github.com/user-attachments/assets/0badd931-939a-491e-9627-40322af85cc8" />
# Lookup
<img width="1095" height="748" alt="ui5" src="https://github.com/user-attachments/assets/051b84e9-e40b-4778-b3e1-3fd40e088b15" />
# History
<img width="1060" height="731" alt="ui6" src="https://github.com/user-attachments/assets/4dd80942-95ef-4102-a531-741cebf2505b" />
# Fee Calculator
<img width="1049" height="709" alt="ui7" src="https://github.com/user-attachments/assets/f059335f-a2b4-425d-9ae8-973889855761" />
# Location
<img width="544" height="596" alt="loacation" src="https://github.com/user-attachments/assets/976ded83-d576-4942-b1f1-5db2b6da7f94" />









