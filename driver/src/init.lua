local capabilities = require('st.capabilities')
local commands = require('commands')
local discovery = require('discovery')
local driver = require('st.driver')
local lifecycles = require('lifecycles')
local listener = require('listener')

local wled_driver = driver('WLED', {
    discovery = discovery.start,
    lifecycle_handlers = lifecycles,
    supported_capabilities = {
        capabilities.switch,
        capabilities.switchLevel,
        capabilities.colorControl,
        capabilities.refresh
    },
    capability_handlers = {
        -- Switch command handler
        [capabilities.switch.ID] = {
            [capabilities.switch.commands.on.NAME] = commands.on_off,
            [capabilities.switch.commands.off.NAME] = commands.on_off
        },
        -- Switch Level command handler
        [capabilities.switchLevel.ID] = {
            [capabilities.switchLevel.commands.setLevel.NAME] = commands.set_level
        },
        -- Color Control command handler
        [capabilities.colorControl.ID] = {
            [capabilities.colorControl.commands.setColor.NAME] = commands.set_color
        },
        -- Color Temperature command handler
        [capabilities.colorTemperature.ID] = {
            [capabilities.colorTemperature.commands.setColorTemperature.NAME] = commands.set_color_temperature
        },
        -- Refresh command handler
        [capabilities.refresh.ID] = {
            [capabilities.refresh.commands.refresh.NAME] = commands.refresh
        }
    }
})

listener:state_changed(function(device, device_state)
    commands.update_device_state(device, device_state)
end)
wled_driver:call_with_delay(1,
                            function() listener.start_all(wled_driver) end,
                            'WebSocket Delayed Connect All')

wled_driver:run()