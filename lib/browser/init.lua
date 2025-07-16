-- Browser utility functions for global hotkeys
local M = {}

--- Open a new tab in the frontmost browser by simulating Cmd+T
function M.new_firefox_tab()
    hs.eventtap.keyStroke({"cmd"}, "t")
end

return M
