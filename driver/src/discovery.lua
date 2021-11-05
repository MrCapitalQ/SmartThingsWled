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
    log.debug('Starting discovery')
    while true do
        local results = mdns.query('_http._tcp', 5)
        if (results) then
            for _, ip_address in pairs(results) do
                log.debug('Found potential device - ' .. ip_address)

                local deviceInfo = wled_client.info(ip_address)
                if deviceInfo then
                    log.debug(ip_address .. ' WLED device found! ')
                    local device = {
                        network_id = string.format("%s:80", ip_address),
                        name = deviceInfo.name,
                        manufacturer = deviceInfo.brand,
                        model = deviceInfo.arch
                    }
                    return create_device(driver, device)
                else
                    log.debug(ip_address .. ' is not a WLED device')
                end
            end
        else
            log.debug('no result')
        end
    end
end

return discovery
