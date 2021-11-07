local http = require("socket.http")
local json = require 'dkjson'
local ltn12 = require('ltn12')
local socket = require('socket')
local log = require('log')
local utils = require('st.utils')

local function send_request(ip_address, path, method, data)
    local url = string.format("http://%s/%s", ip_address, path)
    log.trace('Making web request to ' .. url)

    local request_body = nil
    local headers = {}
    if (data) then
        request_body = json.encode(data)
        headers = {
            ['Content-Type'] = 'application/json',
            ["Content-Length"] = string.len(request_body)
        }
        log.trace('Request body: ' .. request_body)
    end

    local response_body = {}
    local _, code = http.request({
        url = url,
        method = method or 'GET',
        source = ltn12.source.string(request_body),
        sink = ltn12.sink.table(response_body),
        headers = headers,
        -- Set timeout
        create = function()
            local sock = socket.tcp()
            sock:settimeout(5)
            return sock
        end
    })

    log.trace('Received responsee code ' .. code)
    if code == 200 then
        local device_state, _, err = json.decode(table.concat(response_body))
        if err then
            log.trace('Deserialization error: ' .. err)
            return nil
        else
            return device_state
        end
    else
        return nil
    end
end

local wled_client = {}

function wled_client.ping(ip_address)
    local code = send_request(ip_address, 'win')
    return code == 200
end

function wled_client.info(ip_address)
    local device_info = send_request(ip_address, 'json/info')

    -- Assume invalid device if device version and build is missing. There may
    -- be a better way to do this but the official app just ensures a 200 response is returned.
    if not device_info or not device_info.ver or not device_info.vid then
        return nil
    else
        return device_info
    end
end

function wled_client.state(ip_address)
    return send_request(ip_address, 'json/state')
end

function wled_client.set_power(ip_address, is_on)
    local request = {on = is_on, v = true}
    return send_request(ip_address, 'json/state', 'POST', request)
end

function wled_client.set_brightness(ip_address, brightness)
    local request = {bri = brightness, v = true}
    return send_request(ip_address, 'json/state', 'POST', request)
end

function wled_client.set_color(ip_address, r, g, b)
    local request = {
        seg = {
            [1] = {
                start = 0,
                stop = -1,
                col = {[1] = {[1] = r, [2] = g, [3] = b}}
            }
        },
        v = true
    }
    return send_request(ip_address, 'json/state', 'POST', request)
end

return wled_client
