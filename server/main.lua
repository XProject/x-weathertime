RegisterServerEvent("x-weathertime:validateTime", function(timestamp)
    if not timestamp then return end

    timestamp = math.floor(timestamp / 1000)

    local date = os.date("%H:%M:%S", timestamp) --[[@as string?]]

    if not date then return end

    local hour, minute, second = string.match(date, "(%d+):(%d+):(%d+)")

    TriggerClientEvent("x-weathertime:setTime", source, { hour = tonumber(hour), minute = tonumber(minute), second = tonumber(second) })
end)
