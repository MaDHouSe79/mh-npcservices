--[[ ===================================================== ]]--
--[[           MH NPC Services Script by MaDHouSe          ]]--
--[[ ===================================================== ]]--

fx_version 'cerulean'
game 'gta5'

description 'MH - NPC Services - a 5 in 1 npc services. NPC (Police/Ambulance/Mechanic/TowTruck/Taxi)'
author 'MaDHouSe'
version '1.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/nl.lua', -- change en to your language
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

dependencies {
    'oxmysql',
    'qb-core',
}

lua54 'yes'