-- Passata configuration moved from init.lua
local M = {}

local PASSATA = require("lib.passata")

-- Peek the Passata report for a short duration and auto-hide it
local function peek_report(alpha)
    PASSATA:showReport(alpha)
    hs.timer.doAfter(3, function() PASSATA.canvas_report:hide() end)
end
_G.peek_report = peek_report

-- Stub for grayscale reminder (on_nagg trigger)
local function gray_minute()
    -- TODO: implement grayscale reminder
end
_G.gray_minute = gray_minute

-- Stub for custom report drawing (on_draw_report trigger)
local function customizeReport()
    -- TODO: add custom elements to the report canvas
end
_G.customizeReport = customizeReport

--- Initialize Passata timer and triggers
function M.init()
    PASSATA:init()
    PASSATA.seconds_by_mode["working"] = 20 * 60
    PASSATA.seconds_by_mode["resting"] = 5 * 60
    PASSATA.seconds_by_mode["idle"] = 5 * 60
    PASSATA.logActivityInterval = 0
    PASSATA.nudge = false
    PASSATA.nagg = false
    PASSATA:start()

    PASSATA.triggers["on_complete_work"]    = {peek_report}
    PASSATA.triggers["on_complete_rest"]    = {peek_report}
    PASSATA.triggers["on_task_reminder"]   = {function() peek_report(0.25) end}
    PASSATA.triggers["on_nagg"]            = {gray_minute}
    PASSATA.triggers["on_draw_report"]     = {customizeReport}
end

return M
