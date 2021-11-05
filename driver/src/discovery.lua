local log = require('log')
local mdns = require('mdns')
local wled_client = require('wled_client')

local function create_device(driver, device)
    log.debug('Attempting to create device at ' .. device.network_id)

    local metadata = {
        type = 'LAN',
        device_network_id = device.network_id,
        label = device.name,
        profile = 'WLED-RGBW.v1',
        manufacturer = device.manufacturer,
        model = device.model,
        vendor_provided_label = 'WLED'
    }
    return driver:try_create_device(metadata)
end

local discovery = {}
function discovery.start(driver, opts, cons)
    log.trace('Starting discovery...')
    while true do
        local results = mdns.query('_http._tcp', 5)
        if (results) then
            for _, ip_address in pairs(results) do
                local network_id = string.format("%s:80", ip_address)
                local device_info = wled_client.info(network_id)
                if device_info then
                    log.trace(ip_address .. ' WLED device found! ')
                    local device = {
                        network_id = network_id,
                        name = device_info.name,
                        manufacturer = device_info.brand,
                        model = device_info.arch
                    }
                    return create_device(driver, device)
                end
            end
        end
    end
end

return discovery
