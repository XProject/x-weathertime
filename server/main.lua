local export = lib.require("files.api")
local WEATHERS = lib.require("files.weatherTypes") --[[@type weatherTypes]]
local currentWeather, currentHour, currentMinute, currentSecond

---@param source? integer
local function syncWeatherTime(source)
    TriggerClientEvent("x-weathertime:syncWeatherTime", source or -1, currentWeather, { hour = currentHour, minute = currentMinute, second = currentSecond })
end

---@param weather? string | integer | number
---@return boolean
function export.setWeather(weather)
    local typeWeather = type(weather)

    if typeWeather ~= "string" and typeWeather ~= "number" and typeWeather ~= "nil" then return false end

    weather = WEATHERS[typeWeather == "string" and joaat(weather) or weather] --[[@as string?]]

    if not weather then return false end

    currentWeather = weather

    syncWeatherTime()

    return true
end

---@param hour integer
---@param minute integer
---@param second integer
function export.setTime(hour, minute, second)
    if hour < 0 then return false
    elseif minute < 0 then return false
    elseif second < 0 then return false end

    if second >= 60 then second = 0 minute += 1 end
    if minute >= 60 then minute = 0 hour += 1 end
    if hour >= 24 then hour = 0 end

    currentHour = hour
    currentMinute = minute
    currentSecond = second

    syncWeatherTime()

    return true
end

do
    export.setWeather(Config.StartingWeather)
    export.setTime(Config.StartingTime.Hour, Config.StartingTime.Minute, Config.StartingTime.Second)
end

RegisterServerEvent("x-weathertime:requestWeatherTime", function()
    syncWeatherTime(source)

    TriggerClientEvent("x-weathertime:initialize", source)
end)

RegisterServerEvent("x-weathertime:newWeather", function(timestamp)
    if not timestamp then return end

    timestamp = math.floor(timestamp / 1000)

    local date = os.date("%H:%M:%S", timestamp) --[[@as string?]]

    if not date then return end

    local hour, minute, second = string.match(date, "(%d+):(%d+):(%d+)")

    export.setTime(tonumber(hour), tonumber(minute), tonumber(second)) ---@diagnostic disable-line: param-type-mismatch
end)

RegisterServerEvent("x-weathertime:newTime", function(timestamp)
    if not timestamp then return end

    timestamp = math.floor(timestamp / 1000)

    local date = os.date("%H:%M:%S", timestamp) --[[@as string?]]

    if not date then return end

    local hour, minute, second = string.match(date, "(%d+):(%d+):(%d+)")

    export.setTime(tonumber(hour), tonumber(minute), tonumber(second)) ---@diagnostic disable-line: param-type-mismatch
end)

CreateThread(function()
    local waitTime = Config.TimeCycleSpeed * 1000 * 4

    while true do
        export.setTime(currentHour, currentMinute + 2, currentSecond)

        Wait(waitTime)
    end
end)