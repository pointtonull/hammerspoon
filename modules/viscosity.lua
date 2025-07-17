-- Viscosity authentication moved from init.lua
local M = {}
local processed_viscosity = {}

local function viscosity_login(window)
    local window_id = window:id()
    if processed_viscosity[window_id] then
        return
    else
        processed_viscosity[window_id] = true
        print(window:title())
    end
    local ui = hs.axuielement.windowElement(window)
    local username = "carlos.cabrera"
    local password = SHUTIL.shellGet("s.otp OTP_VPN")
    for _, textField in pairs(ui:childrenWithRole("AXTextField")) do
        if textField["AXRoleDescription"] == "text field" then
            textField["AXValue"] = username
        elseif textField["AXRoleDescription"] == "secure text field" then
            textField["AXValue"] = password
        end
    end
    for _, button in pairs(ui:childrenWithRole("AXButton")) do
        if button["AXTitle"] == "OK" then button:doAXPress() end
    end
end

local function viscosity_click_ok(window)
    local window_id = window:id()
    local title = window:title()
    if title ~= "" then return end
    if processed_viscosity[window_id] then
        return
    else
        processed_viscosity[window_id] = true
    end
    local script = [[
        tell application "System Events"
            tell process "Viscosity"
                set frontmost to true
                click button "OK" of front window
            end tell
        end tell
    ]]
    local ok, _, _, _ = hs.osascript.applescript(script)
end

function M.init()
    local wf_login = WF.new(false):setAppFilter("Viscosity", {allowTitles = "Viscosity - "})
    local wf_error = WF.new(false):setAppFilter("Viscosity")
    wf_login:subscribe({WF.windowFocused, WF.windowCreated}, viscosity_login)
    wf_error:subscribe({WF.windowFocused, WF.windowCreated}, viscosity_click_ok)
    M.wf_login = wf_login
    M.wf_error = wf_error
end

--- Connect to configured Viscosity VPNs
function M.VPNConnect()
    hs.osascript.applescript([[
    tell application "Viscosity" to connect "lan"
    tell application "Viscosity" to connect "ect"
    ]])
end

--- Disconnect all Viscosity VPNs
function M.VPNDisconnect()
    hs.osascript.applescript([[
    tell application "Viscosity" to disconnectall
    ]])
end

return M
