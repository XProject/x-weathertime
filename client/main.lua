local export = lib.require("files.api")
local VALID_TIME_TYPES = lib.require("files.timeTypes") --[[@type validTimeTypes]]
local WEATHERS, VALID_WEATHER_TYPES = lib.require("files.weather"), lib.require("files.weatherTypes") --[[@type weathers]] --[[@type validWeatherTypes]]
local currentWeather, currentRainLevel

---@param hour integer
---@param minute integer
---@param second integer
local function setTime(hour, minute, second)
    if second >= 60 then second = 0 minute += 1 end
    if minute >= 60 then minute = 0 hour += 1 end
    if hour >= 24 then hour = 0 end

    NetworkOverrideClockMillisecondsPerGameMinute(Config.TimeCycleSpeed * 1000)

    NetworkOverrideClockTime(hour, minute, second)
end

---@param weather string
---@param options? weatherTimeOptions
local function setWeather(weather, options)
    if weather ~= currentWeather then
        currentRainLevel = options?.rainLevel

        ClearOverrideWeather()
        ClearWeatherTypePersist()
    else
        currentRainLevel = options?.rainLevel or currentRainLevel
    end

    SetWeatherTypePersist(weather)
    SetWeatherTypeNow(weather)
    SetOverrideWeather(weather)

    local isXmas = weather == "XMAS"
    local rainLevel = currentRainLevel or (weather == "RAIN" and 0.5) or (weather == "THUNDER" and 1.0) or 0.0

    SetForceVehicleTrails(isXmas)
    SetForcePedFootstepsTracks(isXmas)
    SetRainLevel(rainLevel)

    currentWeather = weather
    currentRainLevel = rainLevel
end

---@param weather? string | integer | number
---@param time? time
---@param options? weatherTimeOptions
---@return boolean
function export.forceWeatherTime(weather, time, options)
    local typeWeather = type(weather)
    local typeTime = type(time)

    if not VALID_WEATHER_TYPES[typeWeather] or not VALID_TIME_TYPES[typeTime] then return false end

    weather = WEATHERS[typeWeather == "string" and joaat(weather) or weather or currentWeather] --[[@as string?]]
    time = time or {}

    if not weather then return false end

    time.hour = time.hour or GetClockHours()
    time.minute = time.minute or GetClockMinutes()
    time.second = time.second or GetClockSeconds()

    for k, v in pairs(time) do
        if type(v) ~= "number" then return false end
        time[k] = math.floor(v)
    end

    if time.hour < 0 then return false
    elseif time.minute < 0 then return false
    elseif time.second < 0 then return false end

    setTime(time.hour, time.minute, time.second)

    setWeather(weather, options)

    return true
end

---@return string
function export.getCurrentWeather()
    return currentWeather
end

do TriggerServerEvent("x-weathertime:requestWeatherTime") end

RegisterNetEvent("x-weathertime:syncWeatherTime", function(weather, time, options)
    export.forceWeatherTime(weather, time, options)
end)