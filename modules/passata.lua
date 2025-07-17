-- Passata configuration moved from init.lua
local M = {}

local PASSATA = require("lib.passata")
local SHUTIL = require("lib.shutil")

-- Peek the Passata report for a short duration and auto-hide it
function peek_report(alpha)
    alpha = alpha or 1
    PASSATA:showReport()
    PASSATA.canvas_report:alpha(alpha)
    hs.timer.doAfter(3, function() PASSATA.canvas_report:hide(3) end)
    clock()
end
_G.peek_report = peek_report

-- Stub for grayscale reminder (on_nagg trigger)
local function gray_minute()
    -- TODO: implement grayscale reminder
end
_G.gray_minute = gray_minute

function clock()
    local screen_frame = hs.screen.mainScreen():fullFrame()

    local canvas = CANVAS.new({
        x = 0,
        y = 0,
        w = screen_frame.w,
        h = screen_frame.h
    })

    local time = SHUTIL.shellGet("date '+%y/%m/%d %H:%M'", true)
    local styled_time = hs.styledtext.new(time, {
        font = {name = "Monaco", size = 60},
        strokeWidth = -3,
        strokeColor = {white = 0},
        color = {white = 1},
        paragraphStyle = {alignment = "center"}
    })
    local timeSize = canvas:minimumTextSize(styled_time)
    local styledTimeShadow = styled_time:setStyle({
        strokeWidth = 0,
        color = {white = 0, alpha = 0.5}
    })
    canvas:insertElement({
        type = "text",
        text = styledTimeShadow,
        frame = {
            x = screen_frame._w - timeSize.w - 5 + 2 - 5,
            y = 0 + 5 + 2,
            w = timeSize.w,
            h = timeSize.h
        }
    })
    canvas:insertElement({
        type = "text",
        text = styled_time,
        frame = {
            x = screen_frame._w - timeSize.w - 5 - 5,
            y = 0 + 5,
            w = timeSize.w,
            h = timeSize.h
        }
    })

    local meetings = SHUTIL.shellGet("t.meetings_today"):gsub(":: *", "\n")
    local styled_meetings = hs.styledtext.new(meetings, {
        font = {name = "Monaco", size = 30},
        paragraphStyle = {alignment = "left"},
        strokeWidth = -3,
        strokeColor = {white = 0},
        color = {white = 1}
    })
    local meetingsSize = canvas:minimumTextSize(styled_meetings)
    local styledMeetingsShadow = styled_meetings:setStyle({
        strokeWidth = 0,
        color = {white = 0, alpha = 0.5}
    })
    canvas:insertElement({
        type = "text",
        text = styledMeetingsShadow,
        frame = {
            x = screen_frame._w - meetingsSize.w - 5 + 2 - 5,
            y = 0 + 5 + 2 + timeSize.h,
            w = meetingsSize.w,
            h = meetingsSize.h
        }
    })
    canvas:insertElement({
        type = "text",
        text = styled_meetings,
        frame = {
            x = screen_frame._w - meetingsSize.w - 5 - 5,
            y = 0 + 5 + timeSize.h,
            w = meetingsSize.w,
            h = meetingsSize.h
        }
    })

    canvas:show()
    canvas:delete(10)
end

-- Stub for custom report drawing (on_draw_report trigger)
local function customizeReport()
    local screen_frame = hs.screen.mainScreen():fullFrame()
    local task = SHUTIL.shellGet("t.current"):gsub(": *", "\n")
    local styledTask = hs.styledtext.new(task, {
        font = {name = "Monaco", size = 60},
        strokeWidth = -3,
        strokeColor = {white = 0},
        color = PASSATA.colors.report_today,
        paragraphStyle = {alignment = "center"}
    })
    local size = PASSATA.canvas_report:minimumTextSize(styledTask)
    local styledTaskShadow = styledTask:setStyle({
        strokeWidth = 0,
        color = {white = 0, alpha = 0.5}
    })
    PASSATA.canvas_report:insertElement({
        type = "text",
        text = styledTaskShadow,
        frame = {
            x = screen_frame._w // 2 - size.w // 2 + 2,
            y = screen_frame._h // 2 - size.h // 2 + 2,
            w = size.w,
            h = size.h
        }
    })
    PASSATA.canvas_report:insertElement({
        type = "text",
        text = styledTask,
        frame = {
            x = screen_frame._w // 2 - size.w // 2,
            y = screen_frame._h // 2 - size.h // 2,
            w = size.w,
            h = size.h
        }
    })
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

    PASSATA.triggers["on_complete_work"] = {peek_report}
    PASSATA.triggers["on_complete_rest"] = {peek_report}
    PASSATA.triggers["on_task_reminder"] = {function() peek_report(0.25) end}
    PASSATA.triggers["on_nagg"] = {gray_minute}
    PASSATA.triggers["on_draw_report"] = {customizeReport}
end

return M
