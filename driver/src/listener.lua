local cosock = require('cosock').socket
local socket = require('socket')
local log = require('log')
local utils = require('st.utils')

local listener = {}

function listener.start(driver)
    local udp = cosock.udp()
    driver:register_channel_handler(udp, function()
        local data, ip, port = udp:receivefrom()

        log.debug(
            'Received from ' .. (ip or '?') .. ':' .. (port or '?') .. ' ' ..
                utils.stringify_table(data))
    end)
    assert(udp:setoption('broadcast', true))
    assert(udp:settimeout(2))
    assert(udp:setsockname('*', 0))
    local _, p = udp:getsockname()
    log.debug('Listening on port ' .. p .. '...')
end

function listener.start_blocking()
    local udp = socket.udp()
    assert(udp:setoption('broadcast', true))
    assert(udp:settimeout(2))
    assert(udp:setsockname('*', 0))
    local _, p = udp:getsockname()
    log.debug('Listening on port ' .. p .. '...')

    while true do
        local data, ip, port = udp:receivefrom()

        log.debug(
            'Received from ' .. (ip or '?') .. ':' .. (port or '?') .. ' ' ..
                utils.stringify_table(data))
    end
end

return listener
