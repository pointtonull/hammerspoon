-- Spotify control moved from init.lua
local M = {}

--- Send a command to Spotify via helper
-- @param command string action to perform (play, pause, next, etc.)
function M.spotify_control(command)
    local cmd = "s.log spotify_control " .. command .. "&"
    SHUTIL.shellDo(cmd, {py_env = "p3"})
end

return M
