local export = lib.require("files.api")
local WEATHERS = lib.require("files.weatherTypes") --[[@type weatherTypes]]
local weatherMenuId = ("%s_main_menu"):format(cache.resource)
local weatherIcon = "fa-solid fa-temperature-half"
local weatherTransitionSpeedIcon = "fa-solid fa-clock"
local weatherRainIcon = "fa-solid fa-raindrops"
local resourceExport = exports[cache.resource]

function export.openMenu()
    if lib.progressActive() then return lib.notify({
        title = locale("weather_main_menu_title"),
        description = locale("weather_menu_not_accessible"),
        type = "error",
        duration = 5000
    }) end

    local currentWeather = resourceExport:getCurrentWeather()

    lib.registerContext({
        id = weatherMenuId,
        title = locale("weather_main_menu_title"),
        canClose = true,
        options = {
            {
                title = locale("weather_main_menu_weather"),
                icon = weatherIcon,
                description = locale("weather_main_menu_current_weather", currentWeather),
                onSelect = function()
                    local weatherOptions, weatherCount = {}, 0

                    for hash, name in pairs(WEATHERS) do ---@diagnostic disable-line: param-type-mismatch
                        weatherCount += 1
                        weatherOptions[weatherCount] = {label = name, value = hash}
                    end

                    lib.hideContext()

                    local dialogBox = lib.inputDialog(locale("weather_main_menu_weather"), {
                        { type = "select", label = locale("weather_dialog_menu_weather_label"), icon = weatherIcon, options = weatherOptions, default = joaat(currentWeather) },
                        { type = "number", label = locale("weather_dialog_menu_transition_label"), icon = weatherTransitionSpeedIcon, default = 15.0, min = 0.0 },
                        { type = "slider", label = locale("weather_dialog_menu_rain_label"), icon = weatherRainIcon, default = -1, min = 0.0, max = 1.0, step = 0.1 }
                    }, {
                        allowCancel = true
                    })

                    if dialogBox then
                        dialogBox[3] = dialogBox[3] ~= -1 and dialogBox[3] or nil

                        resourceExport:forceWeatherTime(dialogBox[1], nil, {instantTransition = dialogBox[2] == 0, transitionSpeed = dialogBox[2], rainLevel = dialogBox[3]}, function(waitTime)
                            lib.progressBar({
                                duration = waitTime,
                                label = locale("weather_menu_setting_weather", WEATHERS[dialogBox[1]]),
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