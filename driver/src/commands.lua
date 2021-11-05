local capabilities = require('st.capabilities')
local log = require('log')
local utils = require('st.utils')
local wled_client = require('wled_client')

local function update_device_state(device, device_state) -- Refresh Switch
    -- Refresh Switch
    if (device_state.on == true) then
        device:emit_event(capabilities.switch.switch.on())
    else
        device:emit_event(capabilities.switch.switch.off())
    end

    -- Refresh Switch Level
    local level = math.floor(device_state.bri / 2.55)
    device:emit_event(capabilities.switchLevel.level(level))

    -- Refresh Color Control
    local first_segment = device_state.seg[1]
    local rgb = first_segment.col[1];
    local hue, saturation = utils.rgb_to_hsl(rgb[1], rgb[2], rgb[3])
    device:emit_event(capabilities.colorControl.saturation(saturation))
    device:emit_event(capabilities.colorControl.hue(hue))
end

local command_handler = {}

-- Ping command
function command_handler.ping(_, _, device)
    log.trace('Handling ping command')
    return wled_client.ping(device.device_network_id)
end

-- Refresh command
function command_handler.refresh(_, device)
    log.trace('Handling refresh command')

    local device_state = wled_client.state(device.device_network_id)

    -- Define online status on if getting the device state was successful
    if (device_state) then
        device:online()
        update_device_state(device, device_state)
    else
        device:offline()
    end
end

-- Switch command
function command_handler.on_off(_, device, command)
    log.trace('Handling switch command')
    if command.command == 'off' then
        return device:emit_event(capabilities.switch.switch.off())
    end
    return device:emit_event(capabilities.switch.switch.on())
end

-- Switch Level command
function command_handler.set_level(_, device, command)
    log.trace('Handling level command')
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
    log.trace('Handling color command')
    local red, green, blue = utils.hsl_to_rgb(command.args.color.hue, command.args.color.saturation)
    local hue, saturation = utils.rgb_to_hsl(red, green, blue)
    device:emit_event(capabilities.switch.switch.on())
    device:emit_event(capabilities.colorControl.saturation(saturation))
    device:emit_event(capabilities.colorControl.hue(hue))
end

function command_handler.set_color_temperature(_, device, command)
    log.trace('Handling color temperature command')
    device:emit_event(capabilities.colorTemperature.colorTemperature(command.args.temperature))
end

return command_handler
