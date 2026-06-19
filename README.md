## Copyright (c) 2025 johnsmith600
## Licensed: Free to use AS-IS (no modification, no redistribution, no resale).
## See LICENSE file for full terms: https://github.com/johnsmith600/nsw_registration/blob/main/LICENSE

# NSW Registration (ESX/QBCore/Qbox)

Advanced New South Wales style vehicle registration for FiveM with ESX, QBCore, and Qbox support.

## Requirements
- ox_lib
- oxmysql
- ox_inventory (optional, for physical plates)
- One of: es_extended, qb-core, or qbox

## Installation
1. Drag `nsw_registration` to your `resources` directory.
2. Import SQL:
   - Run the file `nsw_registration/sql/install.sql` in your database.
3. Add the `nsw_plate` item to your `ox_inventory/data/items.lua`:
   ```lua
   ['nsw_plate'] = {
       label = 'NSW Vehicle Plate',
       weight = 500,
       stack = false,
       close = true,
       description = 'A physical vehicle registration plate.',
       client = {
           export = 'nsw_registration.usePlate'
       }
   },
   ```
4. Ensure resources in `server.cfg`:
   ```cfg
   ensure oxmysql
   ensure ox_lib
   ensure qbox # or es_extended / qb-core
   ensure nsw_registration
   ```
5. Configure `shared/config.lua` as needed.

## Usage
- Open UI: `/nswregmenu` or interact at DMV locations.
- Mechanic Portal: Authorized jobs can issue Pink Slips via the tablet.
- Physical Plates: Print plates at the Service Centre and use the item near your vehicle to attach it.

## Features
- **Modern UI**: Service NSW themed tablet interface.
- **Pink Slips**: Mandatory safety inspections valid for 6 months.
- **Physical Plates**: Inventory-integrated plates with immersive attachment animations.
- **Plate Styles**: Choose from Standard, White, Black, Euro, and JDM styles.
- **Framework Agnostic**: Native support for ESX, QBCore, and Qbox.
- **Automatic Migrations**: Database updates automatically for existing installations.

## Notes
- Money is charged from bank by default.
- Webhook logging is stubbed; add your URL in `Config.Logging.webhook`.

## Screenshots
![Home](https://github.com/user-attachments/assets/fc4ca7b5-739e-4d6b-b98f-b3bbac1b1d7e)
