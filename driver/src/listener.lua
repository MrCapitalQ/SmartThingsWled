local json = require 'dkjson'
local log = require('log')
local ws = require('websocket.client').sync({timeout = 30})

local handler
local connections = {}

local function connect(driver, device)
    if connections[device.device_network_id] == nil then
        connections[device.device_network_id] = {
            is_connected = false,
            failed_attempts = 0,
            sock = nil
        }
    end
    local connection_state = connections[device.device_network_id];

    if connection_state.failed_attempts >= 3 then return end

    local address = string.format('ws://%s/ws', device.device_network_id)
    log.debug('Connecting to WebSocket at ' .. address .. '...')

    local is_successful, _, _, sock = ws:connect(address, '{"lv":true}')

    if is_successful then
        log.debug('Successfully connected to WebSocket at ' .. address)
        connection_state.is_connected = true
        connection_state.failed_attempts = 0
        connection_state.sock = sock

        driver:register_channel_handler(sock, function()
            local payload, _, _, _, err = ws:receive()

            if err then
                log.trace('WebSocket error (' .. address .. '): ' .. err)
                driver:unregister_channel_handler(sock)
                connection_state.is_connected = false
                connection_state.failed_attempts = connection_state.failed_attempts + 1
                connection_state.sock = nil
                connect(driver, device)
            end

            local data, _, json_err = json.decode(payload)
            if err then
                log.trace('Deserialization error: ' .. json_err)
            else
                log.trace('Received update from ' .. device.device_network_id)
                handler(device, data.state)
            end
        end, 'WebSocket message received handler')
    else
        log.debug('Failed to connect to WebSocket at ' .. address)
        connection_state.is_connected = false
        connection_state.failed_attempts = connection_state.failed_attempts + 1
        connection_state.sock = nil
        connect(driver, device)
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

function listener.retry_all_disconnected(driver)
    local devices = driver:get_devices()
    for _, device in pairs(devices) do
        local connection_state = connections[device.device_network_id]
        if connection_state == nil or connection_state.is_connected == false then
            connect(driver, device)
        end
    end
end

function listener.stop(driver, device)
    local connection_state = connections[device.device_network_id]
    if connection_state == nil then
        return
    end

    if connection_state.sock ~= nil then
        driver:unregister_channel_handler(connection_state.sock)
        connection_state.sock.close()
    end
    connection_state.is_connected = false
    connection_state.failed_attempts = 0
    connection_state.sock = nil
    connections[device.device_network_id] = nil
end

listener.state_changed = function(_, handler_func)
    handler = handler_func
end

listener.connections = connections

return listener
