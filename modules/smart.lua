-- Smart devices and office lights automation
local M = {}

local OFFICE_STATUS = "unknown"

local function check_office_lights()
    local info = get_info_logger("check_office_lights", "/Users/carlos.cabrera/.messages")
    local threshold = 60 * 30 -- 30 minutes
    local hour = tonumber(os.date("%H"))
    local idleTime = hs.host.idleTime()

    local isDark = hour >= 18 or hour < 5
    local isActive = idleTime < threshold

    if isDark and isActive then
        if OFFICE_STATUS ~= "on" then
            info("turning office lights on")
            SHUTIL.shellDo("s.log meross office on&", {py_env = "p3"})
            OFFICE_STATUS = "on"
        end
    else
        if OFFICE_STATUS ~= "off" then
            info("turning office lights off")
            SHUTIL.shellDo("meross office off&", {py_env = "p3"})
            OFFICE_STATUS = "off"
        end
    end
end

function M.init()
    if hs.host.localizedName() == "macbook’s MacBook Pro" then
        local timer = hs.timer.doEvery(60 * 10, function()
            INFO_TIMER("check_office_lights")
            check_office_lights()
        end, true)
        local watcher = hs.caffeinate.watcher.new(function()
            check_office_lights()
        end):start()

        M.timer = timer
        M.watcher = watcher
    end
end

M.check_office_lights = check_office_lights

return M
