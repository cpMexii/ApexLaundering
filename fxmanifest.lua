fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'ApexLaundering'
description 'Laundromat money laundering (QBCore / Qbox / ESX)'
version '2.0.0'

shared_script 'config.lua'
client_script 'client/main.lua'
server_scripts {
    'server/bridge.lua',
    'server/main.lua',
}
