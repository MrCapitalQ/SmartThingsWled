local capabilities = require('st.capabilities')
local commands = require('commands')
local discovery = require('discovery')
local driver = require('st.driver')
local lifecycles = require('lifecycles')
local listener = require('listener')
local log = require('log')


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
local ws = require('websocket.client').sync({timeout = 30})

local function ws_connect()
    log.debug('Connecting...')
    local r, code, _, sock = ws:connect('ws://192.168.68.68/ws', '{"lv":true}')
    log.debug('WS_CONNECT ' .. tostring(r) .. tostring(code))

    if r then
        wled_driver:register_channel_handler(sock, function()

            local payload, opcode, c, d, err = ws:receive()
            log.debug('Payload: ' .. tostring(payload))
            log.debug('Opcode: ' .. tostring(opcode))
            if err then
                ws_connect() -- Reconnect on error
            end
        end)
    end
end

wled_driver:call_with_delay(1, function ()
    ws_connect()
end, 'WS START TIMER')

wled_driver:run()