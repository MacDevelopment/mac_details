fx_version 'cerulean'
game 'gta5'

author 'Mac Development'
description 'A FiveM script that adds to the immersion on your roleplay server. Leave, inspect, and delete details around your map.'
version '1.0.0'

shared_script 'shared/config.lua'
server_script 'server/server.lua'
client_script 'client/main.lua'

dependency 'oxmysql'
dependency 'ox_lib'

lua54 'yes'
