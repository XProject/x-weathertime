local export = lib.require("files.api")
local WEATHERS = lib.require("files.weatherTypes") --[[@type weatherTypes]]
local currentWeather, settingForceWeather


---@param weather string
---@param options? weatherTimeOptions
local function setWeather(weather, options)
    if weather ~= currentWeather then
        ClearOverrideWeather()
        ClearWeatherTypePersist()
    end

    local waitTime = options?.instantTransition and 0 or options?.transitionSpeed or 15.0

    if options?.instantTransition then
        SetWeatherTypePersist(weather)
        SetWeatherTypeNow(weather)
        SetOverrideWeather(weather)
    else
        SetWeatherTypeOvertimePersist(weather, waitTime)
    end

    Wait(waitTime * 1000)

    SetForceVehicleTrails(weather == "XMAS")
    SetForcePedFootstepsTracks(weather == "XMAS")

    currentWeather = weather
end

local function setTime(hour, minute, second)
    NetworkOverrideClockTime(hour, minute, second)
end

---@param weather? string | integer | number
---@param time? time
---@param options? weatherTimeOptions
---@return boolean
function export.forceWeatherTime(weather, time, options)
    local typeWeather = type(weather)

    if typeWeather ~= "string" and typeWeather ~= "number" and typeWeather ~= "nil" then return false end

    weather = WEATHERS[typeWeather == "string" and joaat(weather) or weather or joaat("EXTRASUNNY")] --[[@as string?]]

    if not weather then return false end

    time = {
        hour = time?.hour or 18,
        minute = time?.minute or 0,
        second = time?.second or 0
    }

    for k, v in pairs(time) do
        if type(v) ~= "number" then return false end
        time[k] = math.floor(v)
    end

    if time.hour < 0 or time.hour > 23 then return false
    elseif time.minute < 0 or time.minute > 59 then return false
    elseif time.second < 0 or time.second > 59 then return false end

    settingForceWeather = true

    setWeather(weather, options)

    setTime(time.hour, time.minute, time.second)

    settingForceWeather = false

    return true
end

CreateThread(function()
    print(export.forceWeatherTime(nil, nil, {instantTransition = true}))

    while true do
        if not settingForceWeather then
            setWeather(currentWeather)
        end

        Wait(1000)
    end
end)

RegisterCommand("weather", function(_, args)
    if not type(args?[1]) =="string" then return end

    export.forceWeatherTime(args[1])
end, false)