local http = require("socket.http")
local json = require 'dkjson'
local ltn12 = require('ltn12')
local socket = require('socket')

local function send_request(ip_address, path, method, request_body)
    local url = string.format("http://%s/%s", ip_address, path)
    local response_body = {}
    local _, code = http.request({
        url = url,
        method = method or 'GET',
        body = request_body,
        sink = ltn12.sink.table(response_body),
        -- Set timeout
        create = function()
            local sock = socket.tcp()
            sock:settimeout(5)
            return sock
        end
    })

    return code, response_body
end

local wled_client = {}

function wled_client.ping(ip_address)
    local code = send_request(ip_address, 'win')
    return code == 200
end

function wled_client.info(ip_address)
    local code, response_body = send_request(ip_address, 'json/info')
    if code == 200 then
        local device_info, _, err = json.decode(table.concat(response_body))

        -- Assume invalid response if json decode yields an error or device version and build is missing.
        -- There may be a better way to do this but the official app just ensures a 200 response is returned.
        if err or not device_info or not device_info.ver or not device_info.vid then
            return nil
        else
            return device_info
        end
    else
        return nil
    end
end

function wled_client.state(ip_address)
    local code, response_body = send_request(ip_address, 'json/state')
    if code == 200 then
        local device_state, _, err = json.decode(table.concat(response_body))
        if err then
            return nil
        else
            return device_state
        end
    else
        return nil
    end
end

return wled_client