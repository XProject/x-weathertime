local export = lib.require("files.api")
local WEATHERS = lib.require("files.weatherTypes") --[[@type weatherTypes]]
local weatherMenuId = ("%s_main_menu"):format(cache.resource)
local weatherIcon = "fa-solid fa-temperature-half"
local resourceExport = exports[cache.resource]

function export.openMenu()
    if lib.progressActive() then return lib.notify({
        title = locale("weather_main_menu_title"),
        description = locale("weather_menu_not_accessible"),
        type = "error",
        duration = 5000
    }) end

    lib.registerContext({
        id = weatherMenuId,
        title = locale("weather_main_menu_title"),
        canClose = true,
        options = {
            {
                title = locale("weather_main_menu_weather"),
                icon = weatherIcon,
                description = locale("weather_main_menu_current_weather", resourceExport:getCurrentWeather()),
                onSelect = function()
                    local weatherOptions, weatherCount = {}, 0

                    for hash, name in pairs(WEATHERS) do ---@diagnostic disable-line: param-type-mismatch
                        weatherCount += 1
                        weatherOptions[weatherCount] = {label = name, value = hash}
                    end

                    lib.hideContext()

                    local dialogResponse = lib.inputDialog(locale("weather_main_menu_weather"), {
                        { type = "select", label = locale("weather_dialog_menu_label"), icon = weatherIcon, options = weatherOptions, default = joaat(resourceExport:getCurrentWeather()) }
                    }, {
                        allowCancel = true
                    })

                    if dialogResponse then
                        resourceExport:forceWeatherTime(dialogResponse[1], nil, nil, function(waitTime)
                            lib.progressBar({
                                duration = waitTime,
                                label = locale("weather_menu_setting_weather", WEATHERS[dialogResponse[1]]),
                                useWhileDead = true, allowRagdoll = true, allowCuffed = true, allowFalling = true,
                                canCancel = false
                            })
                        end)
                    end

                    Wait(500)

                    export.openMenu()
                end
            }
        }
    })

    lib.showContext(weatherMenuId)
end

RegisterCommand(Config.CommandToOpenMenu, function()
    -- if true then return end -- TODO: permission check

    export.openMenu()
end, false)

lib.locale()