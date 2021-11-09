local http = require("socket.http")
local json = require 'dkjson'
local ltn12 = require('ltn12')
local socket = require('socket')
local log = require('log')

local function create_tcp_socket()
    local tcp = socket.tcp()
    tcp:settimeout(2)
    return tcp
end

local function send_request(ip_address, path, method, data)
    local http_verb = method or 'GET'
    local url = string.format("http://%s/%s", ip_address, path)
    log.trace('Making ' .. http_verb .. ' request to ' .. url)

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
        create = create_tcp_socket
    })

    log.trace('Received response code ' .. code)
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
    local url = string.format("http://%s/win", ip_address)
    log.trace('Pinging url ' .. url)

    local _, code = http.request({url = url, create = create_tcp_socket})

    log.trace('Received ping response code ' .. code)
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

function wled_client.set_color(ip_address, r, g, b, w)
    local request = {
        seg = {
            [1] = {
                start = 0,
                stop = -1,
                col = {[1] = {[1] = r, [2] = g, [3] = b, [4] = (w or 0)}}
            }
        },
        v = true
    }
    return send_request(ip_address, 'json/state', 'POST', request)
end

return wled_client
