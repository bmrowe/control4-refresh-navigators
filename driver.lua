-- Sends Director a bare PIP over its local c4soap port. That is the project-info
-- update Composer's File > Refresh Navigators sends, and Director rebuilds the UI
-- Configuration agent's room lists when it gets one. Run it a couple of minutes
-- after startup to fix Listen coming up empty after a restart.

DIRECTOR_BINDING = 6001
DIRECTOR_PORT = 5020
DIRECTOR_ADDRESS = "127.0.0.1"
PIP_MESSAGE = '<c4soap name="PIP" async="1"></c4soap>' .. string.char(0)

-- Give up if Director never accepts the connection.
CONNECT_TIMEOUT_MS = 10000
-- Hold the socket open briefly after sending so the message is flushed before
-- we disconnect, unless Director answers first.
SEND_GRACE_MS = 2000

g_Pending = false
g_Sent = false
g_Timer = nil

function rdbg(message)
    if (Properties['Debug Mode'] == 'On') then
        print('Refresh Navigators: ' .. tostring(message))
    end
end

function CancelTimer()
    if g_Timer then
        g_Timer:Cancel()
        g_Timer = nil
    end
end

function Finish(result)
    CancelTimer()
    C4:NetDisconnect(DIRECTOR_BINDING, DIRECTOR_PORT)
    g_Pending = false
    g_Sent = false
    rdbg("Finished: " .. result)
    C4:UpdateProperty("Last Refresh:", os.date("%Y-%m-%d %H:%M:%S") .. " (" .. result .. ")")
end

function RefreshNavigators()
    -- One refresh at a time; a second call while one is in flight is dropped.
    if g_Pending then
        rdbg("Refresh already in progress, ignoring")
        return
    end
    g_Pending = true
    g_Sent = false

    rdbg("Connecting to Director on " .. DIRECTOR_ADDRESS .. ":" .. DIRECTOR_PORT)
    C4:CreateNetworkConnection(DIRECTOR_BINDING, DIRECTOR_ADDRESS)
    C4:NetConnect(DIRECTOR_BINDING, DIRECTOR_PORT)

    g_Timer = C4:SetTimer(CONNECT_TIMEOUT_MS, function()
        g_Timer = nil
        Finish("timed out connecting")
    end)
end

function OnConnectionStatusChanged(idBinding, nPort, strStatus)
    if (idBinding ~= DIRECTOR_BINDING) or (not g_Pending) then return end
    rdbg("Connection " .. tostring(strStatus))

    if (strStatus == "ONLINE") and (not g_Sent) then
        g_Sent = true
        C4:SendToNetwork(DIRECTOR_BINDING, DIRECTOR_PORT, PIP_MESSAGE)
        rdbg("PIP sent")
        CancelTimer()
        g_Timer = C4:SetTimer(SEND_GRACE_MS, function()
            g_Timer = nil
            Finish("sent")
        end)
    elseif (strStatus == "OFFLINE") and (not g_Sent) then
        Finish("connection failed")
    end
end

function ReceivedFromNetwork(idBinding, nPort, strData)
    if (idBinding ~= DIRECTOR_BINDING) or (not g_Sent) then return end
    rdbg("Director replied: " .. tostring(strData))
    Finish("sent")
end

function ExecuteCommand(strCommand, tParams)
    rdbg("ExecuteCommand called: " .. tostring(strCommand))

    -- Handle actions from the Composer Actions tab
    if strCommand == "LUA_ACTION" then
        if tParams and tParams.ACTION == "REFRESH_NAVIGATORS" then
            RefreshNavigators()
        end
    -- Direct command support (for programming or other drivers)
    elseif strCommand == "REFRESH_NAVIGATORS" then
        RefreshNavigators()
    end
end

function OnDriverDestroyed()
    CancelTimer()
    if g_Pending then
        C4:NetDisconnect(DIRECTOR_BINDING, DIRECTOR_PORT)
    end
end
