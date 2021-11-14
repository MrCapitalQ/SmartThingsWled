local json = require 'dkjson'
local log = require('log')
local ws = require('websocket.client').sync({timeout = 30})

local handler

local function connect(driver, device)
    local address = string.format('ws://%s/ws', device.device_network_id)
    log.debug('Connecting to WebSocket at ' .. address .. '...')
    local is_successful, _, _, sock = ws:connect(address, '{"lv":true}')

    if is_successful then
        log.debug('Successfully connected to WebSocket at ' .. address)
        driver:register_channel_handler(sock, function()
            local payload, _, _, _, err = ws:receive()

            if err then
                log.trace('WebSocket error (' .. address .. '): ' .. err)
                connect(driver, device) -- Reconnect on error
            end

            local data, _, json_err = json.decode(payload)
            if err then
                log.trace('Deserialization error: ' .. json_err)
            else
                log.trace('Received update from ' .. device.device_network_id)
                handler(device, data.state)
            end
        end)
    else
        log.debug('Failed to connect to WebSocket at ' .. address)
    end
end

local listener = {}

function listener.start_all(driver)
    local devices = driver:get_devices()
    for _, device in pairs(devices) do
        connect(driver, device)
    end
end

function listener.start(driver, device)
    connect(driver, device)
end

listener.state_changed = function(_, handler_func)
    handler = handler_func
end

return listener
