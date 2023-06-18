local export = lib.require("files.api")
local WEATHERS = lib.require("files.weather") --[[@type weathers]]
local currentWeather, currentHour, currentMinute, currentSecond
local isWeatherTransitionInProgress

---@param source? integer
---@param options? weatherTimeOptions
local function syncWeatherTime(source, options)
    TriggerClientEvent("x-weathertime:syncWeatherTime", source or -1, currentWeather, { hour = currentHour, minute = currentMinute, second = currentSecond }, options)
end

---@param weather? string | integer | number
---@param options? weatherTimeOptions
---@return boolean, string?
function export.setWeather(weather, options)
    if isWeatherTransitionInProgress then return false, "transition_in_progress" end

    local typeWeather = type(weather)

    if typeWeather ~= "string" and typeWeather ~= "number" and typeWeather ~= "nil" then return false end

    weather = WEATHERS[typeWeather == "string" and joaat(weather) or weather] --[[@as string?]]

    if not weather then return false end

    currentWeather = weather

    syncWeatherTime(-1, options)

    isWeatherTransitionInProgress = type(options?.transitionSpeed) == "number" and options?.transitionSpeed > 0 ---@diagnostic disable-line: need-check-nil

    if isWeatherTransitionInProgress then
        SetTimeout(options?.transitionSpeed, function() ---@diagnostic disable-line: need-check-nil
            isWeatherTransitionInProgress = nil
        end)
    end

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
end)

lib.callback.register("x-weathertime:setNewWeather", function(_, weather, options)
    -- TODO: Check for source permission
    return export.setWeather(weather, options)
end)

RegisterServerEvent("x-weathertime:newTime", function(timestamp)
    -- TODO: Check for source permission
    if not timestamp then return end

    timestamp = math.floor(timestamp / 1000)

    local date = os.date("%H:%M:%S", timestamp) --[[@as string?]]

    if not date then return end

    local hour, minute, second = string.match(date, "(%d+):(%d+):(%d+)")

    export.setTime(tonumber(hour), tonumber(minute), tonumber(second)) ---@diagnostic disable-line: param-type-mismatch
end)

CreateThread(function()
    local defaultWait = 2000
    local minuteAddition = defaultWait / (Config.TimeCycleSpeed * 1000) -- by default each 2000 milliseconds should add 1 minute to the time based on GTA's default. We generate the new amount based on Config.TimeCycleSpeed for shadow smoothness
    local waitSeconds = 5

    minuteAddition = minuteAddition * waitSeconds
    waitSeconds = waitSeconds * defaultWait

    while true do
        export.setTime(currentHour, currentMinute + minuteAddition, currentSecond)

        Wait(waitSeconds)
    end
end)