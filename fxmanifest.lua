-- Copyright (c) 2025 johnsmith600
-- Licensed: Free to use AS-IS (no modification, no redistribution, no resale).
-- See LICENSE file for full terms: https://github.com/johnsmith600/nsw_registration/blob/main/LICENSE

fx_version 'cerulean'
game 'gta5'

name 'nsw_registration'
description 'Advanced NSW vehicle registration for FiveM with ESX/QBCore/QBOX support'
author 'johnsmith600'
version '1.0.0'

lua54 'yes'

shared_scripts {
	'@ox_lib/init.lua',
	'shared/config.lua',
	'shared/bridge.lua',
	'locales/en.lua'
}

client_scripts {
	'client/main.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/main.lua'
}

ui_page 'web/index.html'

files {
	'web/index.html',
	'web/style.css',
	'web/app.js'
}

dependencies {
	'ox_lib',
	'oxmysql'
}

