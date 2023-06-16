fx_version "cerulean"
use_experimental_fxv2_oal "yes"
lua54 "yes"
game "gta5"

name "x-weathertime"
version "0.0.0"
repository "https://github.com/XProject/x-weathertime"
description "Project-X Weather & Time: Weather and Time management resource"

files {
    "files/*"
}

shared_scripts {
    "@ox_lib/init.lua",
    "shared/*.lua"
}

server_scripts {
    "server/*.lua"
}

client_scripts {
    "client/*.lua",
}
