local capabilities = require('st.capabilities')
local log = require('log')
local utils = require('st.utils')
local wled_client = require('wled_client')

local command_handler = {}

-- Ping command
function command_handler.ping(_, _, device)
    log.debug('Handling ping command')
    return wled_client.ping(device.device_network_id)
end

-- Refresh command
function command_handler.refresh(_, device)
    log.debug('Handling refresh command')
    -- Define online status
    device:online()

    -- Refresh Switch Level
    log.debug('Refreshing Switch Level')
    device:emit_event(capabilities.switchLevel.level(50))

    -- Refresh Switch
    log.debug('Refreshing Switch')
        device:emit_event(capabilities.switch.switch.on())

    -- Refresh Color Control
    log.debug('Refreshing Color Control')
    local calc_r = 128
    local calc_g = 128
    local calc_b = 128
    local hue, saturation = utils.rgb_to_hsl(calc_r, calc_g, calc_b)
    device:emit_event(capabilities.colorControl.saturation(saturation))
    device:emit_event(capabilities.colorControl.hue(hue))
end

-- Switch command
function command_handler.on_off(_, device, command)
    log.debug('Handling switch command')
    if command.command == 'off' then
        return device:emit_event(capabilities.switch.switch.off())
    end
    return device:emit_event(capabilities.switch.switch.on())
end

-- Switch Level command
function command_handler.set_level(_, device, command)
    log.debug('Handling level command')
    local lvl = command.args.level
    if lvl == 0 then
        device:emit_event(capabilities.switch.switch.off())
    else
        device:emit_event(capabilities.switch.switch.on())
    end
    device:emit_event(capabilities.switchLevel.level(lvl))
end

-- Color Control command
function command_handler.set_color(_, device, command)
    log.debug('Handling color command')
    local red, green, blue = utils.hsl_to_rgb(command.args.color.hue,
                                              command.args.color.saturation)
    local hue, saturation = utils.rgb_to_hsl(red, green, blue)
    device:emit_event(capabilities.switch.switch.on())
    device:emit_event(capabilities.colorControl.saturation(saturation))
    device:emit_event(capabilities.colorControl.hue(hue))
end

function command_handler.set_color_temperature(_, device, command)
    log.debug('Handling color temperature command')
    device:emit_event(capabilities.colorTemperature.colorTemperature(command.args.temperature))
end

return command_handler
