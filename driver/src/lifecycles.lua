local commands = require('commands')
local listener = require('listener')

local lifecycle_handler = {}

function lifecycle_handler.init(_, device)
    -- Ping schedule.
    device.thread:call_on_schedule(300, function()
        return commands.ping(nil, nil, device)
    end, 'Ping schedule')

    -- Refresh schedule
    device.thread:call_on_schedule(300, function()
        return commands.refresh(nil, device)
    end, 'Refresh schedule')
end

function lifecycle_handler.added(_, device)
    commands.refresh(nil, device)
    commands.ping(nil, nil, device)
end

function lifecycle_handler.removed(driver, device)
    listener.stop(driver, device)
    for timer in pairs(device.thread.timers) do
        device.thread:cancel_timer(timer)
    end
end

return lifecycle_handler
