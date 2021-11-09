local capabilities = require('st.capabilities')
local log = require('log')
local utils = require('st.utils')
local wled_client = require('wled_client')

local function match_max_scale(input_color, output_color)
    local max_in = math.max(table.unpack(input_color))
    local max_out = math.max(table.unpack(output_color))
    local factor = 0.0
    if max_out ~= 0 then factor = max_in / max_out end
    return utils.round(output_color[1] * factor),
           utils.round(output_color[2] * factor),
           utils.round(output_color[3] * factor),
           utils.round((output_color[4] or 0) * factor)
end

local function rgbw_to_rgb(r, g, b, w)
    -- Convert an rgbw color to an rgb representation
    -- Add the white channel to the rgb channels.
    local converted_r = r + w
    local converted_g = g + w
    local converted_b = b + w

    -- Match the output maximum value to the input. This ensures the
    -- output doesn't overflow.
    return
        match_max_scale({r, g, b, w}, {converted_r, converted_g, converted_b})
end

local function rgb_to_rgbw(r, g, b)
    -- Convert an rgb color to an rgbw representation.

    -- Calculate the white channel as the minimum of input rgb channels.
    -- Subtract the white portion from the remaining rgb channels.
    local w = math.min(r, g, b)
    local converted_r = r - w
    local converted_g = g - w
    local converted_b = b - w

    -- Match the output maximum value to the input. This ensures the full
    -- channel range is used.
    return match_max_scale({r, g, b}, {r, g, b, w})
end

local function color_temperature_to_rgb(kelvin)
    local temp = kelvin / 100;

    local red
    local green
    local blue;

    if (temp <= 66) then
        red = 255;

        green = temp;
        green = 99.4708025861 * math.log(green) - 161.1195681661;

        if (temp <= 19) then
            blue = 0;
        else
            blue = temp-10;
            blue = 138.5177312231 * math.log(blue) - 305.0447927307;
        end
    else
        red = temp - 60;
        red = 329.698727446 * (red ^ -0.1332047592);

        green = temp - 60;
        green = 288.1221695283 * (green ^ -0.0755148492);

        blue = 255;
    end

    return utils.round(utils.clamp_value(red, 0, 255)),
           utils.round(utils.clamp_value(green, 0, 255)),
           utils.round(utils.clamp_value(blue, 0, 255))
end

local function update_device_state(device, device_state) -- Refresh Switch
    -- Refresh Switch
    if (device_state.on == true) then
        device:emit_event(capabilities.switch.switch.on())
    else
        device:emit_event(capabilities.switch.switch.off())
    end

    -- Refresh Switch Level
    local level = utils.round(device_state.bri / 2.55)
    device:emit_event(capabilities.switchLevel.level(level))

    -- Refresh Color Control
    local first_segment = device_state.seg[1]
    local rgbw = first_segment.col[1];
    local r, g, b = rgbw_to_rgb(rgbw[1], rgbw[2], rgbw[3], rgbw[4])
    local hue, saturation = utils.rgb_to_hsl(r, g, b)
    device:emit_event(capabilities.colorControl.hue(hue))
    device:emit_event(capabilities.colorControl.saturation(saturation))
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

    local is_on = command.command == 'on'
    local device_state = wled_client.set_power(device.device_network_id, is_on)
    if (device_state) then update_device_state(device, device_state) end
end

-- Switch Level command
function command_handler.set_level(_, device, command)
    log.trace('Handling level command')

    local brightness = utils.clamp_value(utils.round(command.args.level * 2.55), 1, 255)
    local device_state = wled_client.set_brightness(device.device_network_id, brightness)
    if (device_state) then update_device_state(device, device_state) end
end

-- Color Control command
function command_handler.set_color(_, device, command)
    log.trace('Handling color command')

    local r, g, b = utils.hsl_to_rgb(command.args.color.hue, command.args.color.saturation)
    local device_state = wled_client.set_color(device.device_network_id, r, g, b)
    if (device_state) then update_device_state(device, device_state) end
end

function command_handler.set_color_temperature(_, device, command)
    log.trace('Handling color temperature command')

    local temperature = utils.round(command.args.temperature / 50) * 50
    local r, g, b = color_temperature_to_rgb(temperature)
    local device_state = wled_client.set_color(device.device_network_id, r, g, b, 255)
    if (device_state) then update_device_state(device, device_state) end
    device:emit_event(capabilities.colorTemperature.colorTemperature(temperature))
end

return command_handler
