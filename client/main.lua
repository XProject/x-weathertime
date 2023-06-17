local export = lib.require("files.api")
local WEATHERS = lib.require("files.weatherTypes") --[[@type weatherTypes]]
local currentWeather, currentRainLevel, settingWeather, settingForceWeather
local currentHour, currentMinute, currentSecond

---@param hour integer
---@param minute integer
---@param second integer
local function setTime(hour, minute, second)
    if second >= 60 then second = 0 minute += 1 end
    if minute >= 60 then minute = 0 hour += 1 end
    if hour >= 24 then hour = 0 end

    NetworkOverrideClockTime(hour, minute, second)

    currentHour = hour
    currentMinute = minute
    currentSecond = second
end

---@param weather string
---@param options? weatherTimeOptions
---@param cb? fun(waitTime: number)
local function setWeather(weather, options, cb)
    while settingWeather do Wait(1000) end -- check to wait for the previous function call if this is an async call

    settingWeather = true

    if weather ~= currentWeather then
        currentRainLevel = options?.rainLevel

        ClearOverrideWeather()
        ClearWeatherTypePersist()
    else
        currentRainLevel = options?.rainLevel or currentRainLevel
    end

    local waitTime = type(options?.transitionSpeed) == "number" and options?.transitionSpeed or 0.0

    if waitTime > 0 then
        SetWeatherTypeOvertimePersist(weather, waitTime)
    else
        waitTime = 0.0 -- making sure the value of waitTime is not less than 0

        SetWeatherTypePersist(weather)
        SetWeatherTypeNow(weather)
        SetOverrideWeather(weather)
    end

    waitTime = waitTime * 1000

    if cb then CreateThread(function() cb(waitTime) end) end

    Wait(waitTime)

    local isXmas = weather == "XMAS"
    local rainLevel = currentRainLevel or (weather == "RAIN" and 0.5) or (weather == "THUNDER" and 1.0) or 0.0

    SetForceVehicleTrails(isXmas)
    SetForcePedFootstepsTracks(isXmas)
    SetRainLevel(rainLevel)

    currentWeather = weather
    currentRainLevel = rainLevel

    settingWeather = false
end

---@param weather? string | integer | number
---@param time? time
---@param options? weatherTimeOptions
---@param cb? fun(waitTime: number)
---@return boolean
function export.forceWeatherTime(weather, time, options, cb)
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

    if time.hour < 0 or time.hour > 24 then return false
    elseif time.minute < 0 or time.minute > 60 then return false
    elseif time.second < 0 or time.second > 60 then return false end

    while settingForceWeather do Wait(1000) end -- check to wait for the previous function call if this is an async call

    settingForceWeather = true

    setTime(time.hour, time.minute, time.second)

    setWeather(weather, options, cb)

    settingForceWeather = false

    return true
end

---@return string
function export.getCurrentWeather()
    return currentWeather
end

---@return integer | number
function export.getCurrentHour()
    return currentHour
end

---@return integer | number
function export.getCurrentMinute()
    return currentMinute
end

---@return integer | number
function export.getCurrentSecond()
    return currentSecond
end

do export.forceWeatherTime() end -- initialize weather & time

CreateThread(function()
    local waitTime = Config.TimeCycleSpeed * 1000

    NetworkOverrideClockMillisecondsPerGameMinute(waitTime)

    while true do
        if not settingForceWeather then
            setWeather(currentWeather)

            setTime(currentHour, currentMinute, currentSecond + 30)
        end

        Wait(waitTime)
    end
end)

RegisterCommand("weather", function(_, args)
    if not type(args?[1]) =="string" then return end

    export.forceWeatherTime(args[1], nil, {rainLevel = 1.0})
end, false)

RegisterNetEvent("x-weathertime:setTime", function(time)
    export.forceWeatherTime(export.getCurrentWeather(), time)
end)