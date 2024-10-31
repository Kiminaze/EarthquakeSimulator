
fx_version "cerulean"
games { "gta5" }

author "Philipp Decker"
description "Eeeeeeeeeeeerdbeeeebeeeeeeen!"
version "1.0.0"

lua54 "yes"
use_experimental_fxv2_oal "yes"

server_scripts {
	"config.lua",
	"server/server.lua"
}

client_scripts {
	"config.lua",
	"client/client.lua"
}
