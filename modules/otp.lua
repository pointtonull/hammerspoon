-- OTP utilities moved from init.lua
local M = {}

--- Type a one-time password for the given token name
function M.type_otp(name)
    local otp = SHUTIL.shellGet("s.otp " .. name)
    hs.eventtap.keyStrokes(otp)
    hs.eventtap.keyStroke(NONE, "Return")
end

--- Split a string into lines
function M.split_lines(str)
    local t = {}
    for line in str:gmatch("([^\\n]*)\\n?") do table.insert(t, line) end
    return t
end

--- Retrieve available OTP token names from ~/.tokens
function M.get_otp_names()
    local cmd = "awk -F'[_ =]' '/OTP/{print $3}' ~/.tokens"
    return M.split_lines(SHUTIL.shellGet(cmd))
end

--- Show a chooser to select and type an OTP token
function M.choose_otp()
    local chooser = hs.chooser.new(function(result)
        if result then M.type_otp("OTP_" .. result.text) end
    end)
    chooser:searchSubText(true)
    local names = M.get_otp_names()
    local options = hs.fnutils.map(names, function(name) return {text = name} end)
    chooser:choices(options)
    chooser:show()
end

return M
