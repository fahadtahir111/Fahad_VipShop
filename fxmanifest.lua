fx_version 'cerulean'
game 'gta5'

author 'VIPShop Script'
description 'Advanced VIP Shop with Coins System and React UI'
version '1.0.0'

lua54 'yes'
use_experimental_fxv2_oal 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/database.lua'
}

client_scripts {
    'client/main.lua'
}

ui_page 'web/dist/index.html'

files {
    'web/dist/**/*',
    'images/**/*'
}

dependencies {
    'oxmysql',
    'ox_inventory',
    'ox_lib'
}