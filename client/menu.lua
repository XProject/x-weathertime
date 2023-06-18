local export = lib.require("files.api")
local WEATHERS = lib.require("files.weather") --[[@type weathers]]
local weatherMenuId = ("%s_main_menu"):format(cache.resource)
local weatherIcon, weatherRainIcon = "fa-solid fa-temperature-half", "fa-solid fa-raindrops"
local timeIcon = "fa-solid fa-clock"
local resourceExport = exports[cache.resource]

function export.openMenu()
    if lib.progressActive() then return lib.notify({
        title = locale("weather_main_menu_title"),
        description = locale("weather_menu_not_accessible"),
        type = "error",
        duration = 5000
    }) end

    local currentHour = GetClockHours()
    local currentMinute = GetClockMinutes()

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

                    local dialogBox = lib.inputDialog(locale("weather_main_menu_weather"), {
                        { type = "select", label = locale("weather_dialog_menu_weather_label"), icon = weatherIcon, options = weatherOptions, default = joaat(resourceExport:getCurrentWeather()) },
                        { type = "slider", label = locale("weather_dialog_menu_rain_label"), icon = weatherRainIcon, default = GetRainLevel(), min = 0.0, max = 1.0, step = 0.1 },
                        { type = "checkbox", label = locale("weather_dialog_menu_blackout_label"), checked = resourceExport:isBlackout() }
                    }, {
                        allowCancel = true
                    })

                    if dialogBox then
                        local response = lib.callback.await("x-weathertime:setNewWeather", false, dialogBox[1], { rainLevel = dialogBox[2], blackout = dialogBox[3] })

                        if response then
                            lib.notify({
                                title = locale("weather_main_menu_title"),
                                description = locale("weather_menu_weather_set", WEATHERS[dialogBox[1]]),
                                type = "success",
                                duration = 5000
                            })
                        else
                            lib.notify({
                                title = locale("weather_main_menu_title"),
                                description = locale("weather_menu_weather_set_error", WEATHERS[dialogBox[1]]),
                                type = "error",
                                duration = 5000
                            })
                        end
                    end

                    Wait(100)

                    export.openMenu()
                end
            },
            {
                title = locale("weather_main_menu_time"),
                icon = timeIcon,
                description = locale("weather_main_menu_current_time", currentHour < 10 and ("0%s"):format(currentHour) or currentHour, currentMinute < 10 and ("0%s"):format(currentMinute) or currentMinute),
                onSelect = function()
                    lib.hideContext()

                    local dialogBox = lib.inputDialog(locale("weather_main_menu_time"), {
                        { type = "time", label = locale("weather_dialog_menu_time_label"), icon = timeIcon, format = "24" }
                    }, {
                        allowCancel = true
                    })

                    if dialogBox?[1] then
                        TriggerServerEvent("x-weathertime:newTime", dialogBox[1])
                    end

                    Wait(100)

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