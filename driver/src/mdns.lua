local socket = require('socket')

local function mdns_make_query(service)
    -- header: transaction id, flags, qdcount, ancount, nscount, nrcount
    local data = '\000\000' .. '\000\000' .. '\000\001' .. '\000\000' ..
                     '\000\000' .. '\000\000'
    -- question section: qname, qtype, qclass
    for n in service:gmatch('([^%.]+)') do
        data = data .. string.char(#n) .. n
    end
    return data .. string.char(0) .. '\000\012' .. '\000\001'
end

local mdns = {}

--- Locate MDNS services in local network
--
-- @param service   MDNS service name to search for (e.g. _ipps._tcp). A .local postfix will 
--                  be appended if needed. If this parameter is not specified, all services
--                  will be queried.
--
-- @param timeout   Number of seconds to wait for MDNS responses. The default timeout is 2 
--                  seconds if this parameter is not specified.
--
-- @return          Table of IP addresses that responded.
--
function mdns.query(service, timeout)

    -- browse all services if no service name specified
    if (not service) then service = '_services._dns-sd._udp' end

    -- append .local if needed
    if (service:sub(-6) ~= '.local') then service = service .. '.local' end

    -- default timeout: 2 seconds
    local timeout = timeout or 2.0

    -- create IPv4 socket for multicast DNS
    local ip, port, udp = '224.0.0.251', 5353, socket.udp()
    assert(udp:setsockname('*', 0))
    assert(udp:settimeout(0.1))

    -- send query
    assert(udp:sendto(mdns_make_query(service), ip, port))

    -- collect responses until timeout
    local responses = {}
    local start = os.time()
    while (os.time() - start < timeout) do
        local data, peeraddr, peerport = udp:receivefrom()

        if data and (peerport == port) then
            table.insert(responses, peeraddr)
        end
    end

    -- cleanup socket
    assert(udp:close())
    udp = nil
    return responses
end

return mdns
