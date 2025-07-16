
require("modules.config")

OOP_Test = {
    -- __name = USERDATA_TAG .. ".watcher",
    -- __type = USERDATA_TAG .. ".watcher",
    new = function()
        print("new")
        local self = setmetatable({_active = false}, Test)
        return self
    end,
    __index = {
        on = function(self)
            self._active = true
            return self
        end,

        off = function(self)
            self._active = false
            return self
        end,
        status = function(self) return self._active end,
        __gc = function(self)
            print("__gc called")
            setmetatable(self, nil)
            return nil
        end
    }
}

hologram = false
hologram_mouse = nil
hologram_brightness = 0
hologram_canvas = nil
hologram_caffeinate = nil
function blackScreen()
    local screen = hs.screen.mainScreen()
    local screen_frame = screen:fullFrame()
    if hologram then
        -- stop hologram
        hologram = false
        hs.caffeinate.set("displayIdle", hologram_caffeinate, false)
        hs.mouse.absolutePosition(hologram_mouse)
        hologram_canvas:hide()
        pcall(function() screen:setBrightness(hologram_brightness) end)
    else
        -- start hologram
        hologram = true
        hologram_caffeinate = hs.caffeinate.get("displayIdle")
        hs.caffeinate.set("displayIdle", true, false)
        hologram_brightness = screen:getBrightness()
        screen:setBrightness(0)
        hologram_mouse = hs.mouse.absolutePosition()
        hs.mouse.absolutePosition({x = screen_frame.w, y = screen_frame.h})
        if not hologram_canvas then
            hologram_canvas = CANVAS.new({
                x = 0,
                y = 0,
                w = screen_frame.w,
                h = screen_frame.h
            })
            hologram_canvas:insertElement({
                type = "rectangle",
                frame = {x = 0, y = 0, w = screen_frame.w, h = screen_frame.h},
                fillColor = {red = 0, green = 0, blue = 0, alpha = 1}
            })
        end
        hologram_canvas:show()
    end
end

function caffeinate()
    hs.caffeinate.toggle("displayIdle")
    if (hs.caffeinate.get("displayIdle")) then
        hs.alert.show("☕️")
    else
        hs.alert.show("🫥")
    end
end

function getChar()
    et = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
        print(hs.keycodes.map[event:getKeyCode()]);
        et:stop()
    end)
    et:start()
end

function get_info_logger(local_name, logfile)
    LOGGER.i(string.format("[%s]", local_name))
    return function(message, ...)
        local args = {...}
        if #args > 0 then
            message = string.format(message, table.unpack(args))
        end
        local formatted_message =
            string.format("  [%s] %s", local_name, message)
        LOGGER.i(formatted_message)
        if logfile then
            local file = io.open(logfile, "a")
            if file then
                file:write(formatted_message .. "\n")
                file:close()
            else
                local formatted_message =
                    LOGGER.e(string.format("  [%s] %s: %s", local_name,
                                           LOGGER.e("Error opening file"),
                                           logfile))
            end
        end
    end
end
INFO_TIMER = get_info_logger("timer", "/Users/carlos.cabrera/.messages")
require("modules.smart").init()

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

PASSATA = require("lib.passata")
PASSATA:init()
PASSATA.seconds_by_mode["working"] = 20 * 60
PASSATA.seconds_by_mode["resting"] = 5 * 60
PASSATA.seconds_by_mode["idle"] = 5 * 60
PASSATA.logActivityInterval = 0
-- PASSATA.nudge = WORK
PASSATA.nudge = false
PASSATA.nagg = false
PASSATA:start()

function peek_report(alpha)
    alpha = alpha or 1
    PASSATA:showReport()
    PASSATA.canvas_report:alpha(alpha)
    hs.timer.doAfter(3, function() PASSATA.canvas_report:hide(3) end)
    clock()
end

function show_notification_centre()
    -- TODO
    -- Control Centre (application) [Application]
    -- <empty description> (menu bar) [NSAccessibilityMenuExtrasMenuBar]
    -- Clock (status menu) [NSAccessibilityMockStatusBarltem]
end

function customizeReport()
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

function gray_minute(time)
    time = time or 60
    hs.screen.setForceToGray(true)
    hs.timer.doAfter(time, function() hs.screen.setForceToGray(false) end)
end
PASSATA.triggers["on_complete_work"] = {peek_report}
-- PASSATA.triggers["on_start_work"] = {
--     -- function() spoon.Split:assureFocused() end,
--     function() hs.screen.setForceToGray(false) end
-- }
-- PASSATA.triggers["on_interrupt_work"]= {hs.spotify.stop}
PASSATA.triggers["on_complete_rest"] = {peek_report}
PASSATA.triggers["on_task_reminder"] = {function() peek_report(0.25) end}
PASSATA.triggers["on_nagg"] = {gray_minute}
PASSATA.triggers["on_draw_report"] = {customizeReport}
-- PASSATA:bindHotkeys moved to modules/hotkeys.lua

CONSOLE = require("lib.console")
CONSOLE:init()
CONSOLE:start()

INSTALL = hs.loadSpoon("SpoonInstall")
RB = hs.loadSpoon("RecursiveBinder")


INSTALL:andUse("ReloadConfiguration", {start = true})
INSTALL:andUse("Commander")

function show_focused_window()
    local screen = hs.screen.mainScreen():fullFrame()
    local overlay = hs.canvas.new(screen)
    local wframe = hs.window.focusedWindow():frame()
    border = 3
    roundness = 13
    frame = {
        x = wframe._x + 1,
        y = wframe._y + 1,
        w = wframe._w - 1,
        h = wframe._h - 1
    }
    overlay:replaceElements({
        action = "stroke",
        type = "rectangle",
        frame = frame,
        strokeColor = {red = 1},
        strokeWidth = border,
        roundedRectRadii = {xRadius = roundness, yRadius = roundness}
    })
    overlay:show()

    local intervalDuration = 0.125
    local cycles = 2
    local cycled = 0
    local handler_timer

    local function handler()
        cycled = cycled + 1
        if cycled <= cycles then
            if overlay:isShowing() then
                overlay:hide()
            else
                overlay:show()
            end
        else
            overlay:hide(1)
            handler_timer:stop()
        end
    end

    handler_timer = hs.timer.doEvery(intervalDuration, handler, true)
    return true
end

-- repo - repository from where the Spoon should be installed if not present in
--   the system, as defined in SpoonInstall.repos. Defaults to "default".
-- config - a table containing variables to be stored in the Spoon object to
--   configure it. For example, config = { answer = 42 } will result in
--   spoon.<LoadedSpoon>.answer being set to 42.
-- hotkeys - a table containing hotkey bindings. If provided, will be passed
--   as-is to the Spoon's bindHotkeys() method. The special string "default"
--   can be given to use the Spoons defaultHotkeys variable, if it exists.
-- fn - a function which will be called with the freshly-loaded Spoon object as
--   its first argument.
-- loglevel - if the Spoon has a variable called logger, its setLogLevel()
--   method will be called with this value.
-- start - if true, call the Spoon's start() method after configuring
--   everything else.

function truncate(str, options)
    options = options or {}
    local maxLength = options.maxLength or 80
    local leftPadd = options.leftPadd or 0
    local elipsis = options.elipsis or ".."
    if #str > maxLength then
        str = str:sub(1, maxLength - #elipsis) .. elipsis
    else
        if #str < leftPadd then
            local padding = string.rep(" ", leftPadd - #str)
            str = padding .. str
        end
    end
    return str
end

function inspect(obj, options)
    -- similar to hs.inspect, but this one goes into userdata objects
    options = options or {}
    local indent = options.indent or 0
    local root = options.root or "root"
    local recurse = options.recurse == nil and true or false
    local limit = options.limit
    local tempTable = {}
    local obj_type = type(obj)
    local function lprint(message, ...)
        hs.printf(string.rep(" ", indent) .. message, ...)
    end
    if obj_type == "userdata" then
        table_to_inspect = getmetatable(obj)
        obj_type = string.format("%s %s", obj_type, obj)
        recurse = false -- to prevent infinite recursion
    elseif obj_type == "table" then
        table_to_inspect = obj
    else
        lprint("%s: <%s> %s", root, obj_type, hs.inspect(obj))
        return
    end
    lprint("%s: <%s>", root, obj_type)
    for key, value in pairs(table_to_inspect) do
        tempTable[#tempTable + 1] = {key = key, value = value}
    end
    table.sort(tempTable,
               function(a, b) return tostring(a.key) < tostring(b.key) end)
    for pos, pair in ipairs(tempTable) do
        if limit and pos > limit then
            lprint("    ..")
            break
        end
        if recurse then
            inspect(pair.value, {
                indent = indent + 4,
                limit = limit == nil and 20 or limit // 2,
                root = pair.key
            })
        else
            lprint("    %s: %s", pair.key, pair.value)
        end
    end
end

function edit_text()
    local original = hs.window.focusedWindow()
    hs.eventtap.keyStroke(HYPER, "a")
    hs.eventtap.keyStroke(HYPER, "c")
    input_pause()
    function pbedit()
        print("pbedit()")
        cmd = "/Users/carlos.cabrera/bin/pbedit"
        task = hs.task.new(cmd, cleanup)
        task:start()
        wait_until(ready_editor, on_editor, cleanup)
    end
    function ready_editor()
        print("ready_editor()")
        local focused_window = hs.window.focusedWindow()
        if focused_window then return focused_window:title() == "nvim" end
    end
    function on_editor()
        print("on_editor()")
        local window = hs.window.focusedWindow()
        window:setFrame(original:frame())
    end
    function cleanup()
        print("cleanup()")
        original:focus()
        hs.eventtap.keyStroke(HYPER, "a")
        hs.eventtap.keyStroke(HYPER, "v")
    end
    pbedit()
end

function calc_text()
    hs.eventtap.keyStroke(HYPER, "a")
    hs.eventtap.keyStroke(HYPER, "c")
    input_pause()
    cmd = "pbpaste | bc -S 2"
    local result = SHUTIL.shellGet(cmd)
    hs.eventtap.keyStrokes(result)
end

function spotify_control(command)
    local cmd = "s.log spotify_control " .. command .. "&"
    SHUTIL.shellDo(cmd, {py_env = "p3"})
end


function nearly_equal(a, b, epsilon)
    epsilon = epsilon or 0.0001
    return math.abs(a - b) < epsilon
end

function move_window(direction)
    local window = hs.window.focusedWindow()
    local screen = window:screen()
    local app = window:application()
    local disableList = {
        ["Firefox"] = true,
        ["Tor Browser"] = true,
        ["Zen"] = true
    }
    if disableList[app:name()] then
        hs.axuielement.applicationElement(app).AXEnhancedUserInterface = false
    end
    local window_frame = window:frame()
    local screen_frame = screen:frame()
    -- print("screen_frame: " .. hs.inspect(screen_frame))
    -- print("window_frame: " .. hs.inspect(window_frame))
    local new_geometry = nil

    if direction == "maximize" then
        new_geometry = hs.geometry.rect(0, 0, 1, 1)
    elseif direction == "down" then
        new_geometry = hs.geometry.rect(0.0, 0.5, 1, 0.5)
    elseif direction == "up" then
        new_geometry = hs.geometry.rect(0.0, 0.0, 1, 0.5)
    elseif direction == "left" then
        new_geometry = hs.geometry.rect(0.0, 0.0, 0.5, 1)
    elseif direction == "right" then
        new_geometry = hs.geometry.rect(0.5, 0.0, 0.5, 1)
    else
        print("unknown direction: " .. direction)
        return
    end

    local is_tall = window_frame._h > screen_frame._h / 2
    local is_bottom = nearly_equal(window_frame._y + window_frame._h,
                                   screen_frame._h, 1)
    local is_top = window_frame._y <= 0
    local is_left = window_frame._x <= 0
    local is_right = nearly_equal(window_frame._x + window_frame._w,
                                  screen_frame._w, 2)

    if direction == "up" or direction == "down" then
        if not is_tall then
            if direction == "down" and not is_bottom then
                print("make it bottom")
            elseif direction == "up" and not is_top then
                print("make it top")
            elseif is_left and is_right then
                print("make left corner")
                new_geometry.w = 0.5
            elseif is_left then
                print("make right corner")
                new_geometry.x = 0.5
                new_geometry.w = 0.5
            elseif is_right then
                print("make wide")
            else
                print("something went wrong")
            end
        end
    elseif direction == "left" or direction == "right" then
        if not is_tall then
            print("make it tall")
        elseif direction == "left" and not is_left then
            print("make it left")
        elseif direction == "right" and not is_right then
            print("make it right")
        elseif nearly_equal(window_frame._w, screen_frame._w * 1 / 2, 1) then
            print("if it's 1/2, make it 2/3")
            new_geometry.w = 2 / 3
            new_geometry.x = new_geometry.x * 2 / 3
        elseif nearly_equal(window_frame._w, screen_frame._w * 2 / 3, 1) then
            print("if it's 2/3, make it 1/3")
            new_geometry.w = 1 / 3
            new_geometry.x = new_geometry.x * 4 / 3
        else
            print("if it's 1/3, make it 1/2")
        end
    end

    hs.layout.apply({{nil, window, screen, new_geometry}})
end

function close_spotify()
    local info = get_info_logger("close_spotify",
                                 "/Users/carlos.cabrera/.messages")
    local script = [[
        quit app "Spotify"
    ]]
    local ok, _, _, _ = hs.osascript.applescript(script)
    info("status: " .. tostring(ok))
end

-- function maybe_close_spotify()
--     local info = get_info_logger("maybe_close_spotify",
--                                  "/Users/carlos.cabrera/.messages")
--     local threshold = 60 * 60 -- 1 hour
--     if hs.spotify.isRunning() then
--         if hs.spotify.isPlaying() then
--             -- close spotify if it's playing, but user away
--             info("playing")
--             local idleTime = hs.host.idleTime()
--             local isActive = idleTime < threshold
--             info("idleTime: " .. idleTime)
--             info("isActive: " .. tostring(isActive))
--             if not isActive then close_spotify() end
--         else
--             info("not playing")
--             -- close spotify if it's not playing
--             close_spotify()
--         end
--     end
-- end
-- TIMER_MAYBE_CLOSE_SPOTIFY = hs.timer.doEvery(60 * 30, function()
--     INFO_TIMER("maybe_close_spotify")
--     maybe_close_spotify()
-- end, true)

function input_pause(seconds)
    seconds = seconds or 0.4
    local delay = seconds * 1e6
    -- this is not elegant but I could not find an easier way to way for the
    -- input client to be ready
    hs.timer.usleep(delay)
end

function paste_and_select_next()
    hs.eventtap.keyStroke(HYPER, "v")
    input_pause()
    hs.eventtap.keyStroke(HYPER_NOPE, "w")
end

function focus_app(app)
    local app_name
    if type(app) == "string" then
        app_name = app
        app = nil
    else
        app_name = app:name()
    end
    local current_space_windows = WF.new(app_name):setCurrentSpace(true)
                                      :getWindows()
    if #current_space_windows > 0 then
        result = current_space_windows[1]:focus()
        return result
    end
    if not app then app = hs.application.get(app_name) end
    if app then
        app:activate()
    else
        hs.application.launchOrFocus(app_name)
    end
    return app
end

function summarize()
    -- show_focused_window()
    hs.alert("🧠 Reading...")
    hs.eventtap.keyStroke(HYPER, "c")
    SHUTIL.shellDo("s.say_summarize&", {py_env = "p3"})
end

function focus_and_show(hint)
    -- hs.application:activate()
    focus_app(hint)
    local wf_hint = WF.new({hint})
    local window = wf_hint:getWindows()[1]
    local firstSpace = SPACES.windowSpaces(window)[1]
    SPACES.gotoSpace(firstSpace)
    focus_app(hint)
end

function focusIterm()
    focus_app("iTerm")
    SPACES.toggleAppExpose()
    input_pause()
    hs.eventtap.keyStroke(NONE, "Right")
end


-- wf_dvsa = WF.new(false):setAppFilter("Google Chrome")
-- wf_dvsa:subscribe({WF.windowTitleChanged}, function(window)
--     local licence = "SARAS902245A99NY"
--     local booking = "64318211"
--     local application = window:application()
--     local title = window:title()
--     print("Window title: " .. title)
--     local function open(address)
--         address = address or "https://driverpracticaltest.dvsa.gov.uk"
--         window:focus()
--         hs.eventtap.keyStroke({"command"}, "l")
--         input_pause()
--         hs.eventtap.keyStrokes(address)
--         input_pause()
--         hs.eventtap.keyStroke(NONE, "Return")
--     end
--     local function get_content()
--         print("Getting content")
--         hs.eventtap.keyStroke({"command"}, "a", application)
--         input_pause()
--         hs.eventtap.keyStroke({"command"}, "c", application)
--         input_pause()
--         hs.eventtap.keyStroke(NONE, "Escape", application)
--         local content = hs.pasteboard.getContents()
--         return content
--     end
--     local function get_url()
--         print("Getting url")
--         hs.eventtap.keyStroke({"command"}, "l", application)
--         input_pause()
--         hs.eventtap.keyStroke({"command"}, "c", application)
--         input_pause()
--         hs.eventtap.keyStroke(NONE, "Escape", application)
--         local url = hs.pasteboard.getContents()
--         return url
--     end
--     if title:find("driverpracticaltest.dvsa.gov.uk") then
--         print("Access denied")
--         open()
--     elseif title:find("driverpracticaltest.dvsa.gov.uk/application") then
--         window:focus()
--         print("not implemented 640")
--     elseif title:find("Access your booking") then
--         hs.eventtap.keyStrokes(",f", application)
--         input_pause()
--         hs.eventtap.keyStrokes("c", application)
--         input_pause()
--         hs.eventtap.keyStroke({"command"}, "a", application)
--         input_pause()
--         hs.eventtap.keyStrokes(licence, application)
--         hs.eventtap.keyStroke(NONE, "Tab", application)
--         hs.eventtap.keyStroke(NONE, "Tab", application)
--         hs.eventtap.keyStrokes(booking, application)
--         hs.eventtap.keyStroke(NONE, "Tab", application)
--         hs.eventtap.keyStrokes(",f", application)
--         input_pause()
--         hs.eventtap.keyStrokes("g", application)
--     elseif title:find("Book your driving test . GOV.UK") then
--         hs.eventtap.keyStrokes(",f", application)
--         input_pause()
--         hs.eventtap.keyStrokes("e", application)
--     elseif title:find("Booking details . Change booking") then
--         hs.eventtap.keyStrokes(",f", application)
--         input_pause()
--         hs.eventtap.keyStrokes("e", application)
--         input_pause()
--     elseif title:find("Change your driving test appointment") then
--         open("https://driverpracticaltest.dvsa.gov.uk/login")
--     elseif title:find("Licence details") then
--         hs.eventtap.keyStrokes(",f", application)
--         input_pause()
--         hs.eventtap.keyStrokes("c", application)
--         input_pause()
--         hs.eventtap.keyStroke({"command"}, "a", application)
--         input_pause()
--         hs.eventtap.keyStrokes(licence, application)
--         hs.eventtap.keyStroke(NONE, "Tab", application)
--         hs.eventtap.keyStrokes(",f", application)
--         input_pause()
--         hs.eventtap.keyStrokes("g", application)
--         hs.eventtap.keyStroke(NONE, "Tab", application)
--         input_pause()
--         hs.eventtap.keyStroke(NONE, "Return", application)
--     elseif title:find("HTTP Status 403") then
--         open()
--     elseif title:find("Pardon Our Interruption") then
--         open()
--     elseif title:find("Session timeout . Google Chrome") then
--         hs.eventtap.keyStrokes(",f", application)
--         input_pause()
--         hs.eventtap.keyStrokes("b", application)
--     elseif title:find("Test centre . Google Chrome") or
--         title:match("Test centre . Change booking") then
--         print("Search page, checking content")
--         input_pause(2)
--         local content = get_content()
--         if content:find("Please choose one of the test centres below") then
--             print("Automated process running")
--         elseif content:find(
--             "Search by your home postcode or by test centre name") then
--             print("Searching test centres")
--             hs.eventtap.keyStrokes(",f", application)
--             input_pause()
--             hs.eventtap.keyStrokes("b", application)
--             input_pause()
--             hs.eventtap.keyStroke({"command"}, "a", application)
--             input_pause()
--             hs.eventtap.keyStrokes("G731HG", application)
--             hs.eventtap.keyStroke(NONE, "Return", application)
--         else
--             window:focus()
--             print("not implemented 708")
--         end
--     elseif title:find("Test date . Google Chrome") then
--         print("Select dates")
--         hs.eventtap.keyStrokes(",f", application)
--         input_pause()
--         hs.eventtap.keyStrokes("b", application)
--         input_pause()
--         hs.eventtap.keyStroke(NONE, "Return", application)
--         input_pause()
--         hs.eventtap.keyStroke(NONE, "Return", application)
--     elseif title:find("choose alternate centre") then
--         hs.eventtap.keyStrokes(",f", application)
--         input_pause()
--         hs.eventtap.keyStrokes("b", application)
--     elseif title:find("Type of test") then
--         hs.eventtap.keyStrokes(",f", application)
--         input_pause()
--         hs.eventtap.keyStrokes("b", application)
--     elseif title:find("Service unavailable") then
--         print("Service unavailable, retrying in 30 minutes")
--         hs.timer.doAfter(60 * 30, open)
--     else
--         print("Window title: " .. title)
--         window:raise()
--         print("not implemented 728")
--     end
-- end)

-- Transmission modal hotkeys moved to modules/hotkeys.lua

processed_viscosity = {}

function viscosity_login(window)
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

wf_viscosity_login = WF.new(false):setAppFilter('Viscosity',
                                                {allowTitles = 'Viscosity - '})
wf_viscosity_error = WF.new(false):setAppFilter('Viscosity')
wf_viscosity_login:subscribe({WF.windowFocused, WF.windowCreated},
                             viscosity_login)

function safe_show_CopyQ()
    local currently_focused = safe_get_focused_window()
    SHUTIL.shellDo("/Applications/CopyQ.app/Contents/MacOS/CopyQ show")
    function copyq_is_minimized()
        local is_copyq = hs.application.frontmostApplication():name() == "CopyQ"
        local no_window = hs.window.focusedWindow() == nil
        return is_copyq and no_window
    end
    function focus_previous_window()
        return safeWindowFocus(currently_focused)
    end
    wait_until(copyq_is_minimized, focus_previous_window, 4 * 60 * 5, 1 / 4)
end

function wait_until(fn_predicate, fn_callback, fn_else, attempts, interval)
    args = {fn_else, attempts, interval}
    fns = {}
    numbers = {}

    for i = 1, 3 do
        arg = args[i]
        if type(arg) == "function" then
            table.insert(fns, arg)
        elseif type(arg) == "number" then
            table.insert(numbers, arg)
        elseif type(arg) ~= "nil" then
            print("Unknown argument: " .. arg)
            return 1
        end
    end

    fn_else = fns[1] or function() end
    attempts = numbers[1] or 10
    interval = numbers[2] or 1

    local counter
    local run
    counter = 0
    run = true
    timer = hs.timer.waitUntil(function() -- metapredicate to mixin timeout
        if attempts <= counter then
            run = false -- prevent callback from being called
            return true -- to stop stopwatch
        end
        counter = counter + 1
        return fn_predicate()
    end, function()
        if run then
            fn_callback()
        else
            print(fn_callback)
            print("didn't ran  because of timeout")
            print("running fn_else")
            fn_else()
        end
    end, interval)
    return timer
end

function show_calendar() hs.application.open("Calendar") end

function tickMenu(app, selector, value)
    local menu_item = app:findMenuItem(selector)
    local ticked = menu_item["ticked"]
    if ticked ~= value then local ticked = app:selectMenuItem(selector) end
end

function align_windows()
    local current_window = safe_get_focused_window()
    local current_frame = current_window:frame()
    local application = current_window:application()
    local all_windows = application:allWindows()
    for _, window in ipairs(all_windows) do window:setFrame(current_frame) end
end

function describe_window(window)
    if window == nil then window = hs.window.focusedWindow() end
    print("application: ")
    print(window:application())
    print(window:application():name())
    print("frame: ")
    print(window:frame())
    print("id: ")
    print(window:id())
    print("isApplication: ")
    print(window:isApplication())
    print("isFullScreen: ")
    print(window:isFullScreen())
    print("isMaximizable: ")
    print(window:isMaximizable())
    print("isStandard: ")
    print(window:isStandard())
    print("isVisible: ")
    print(window:isVisible())
    print("isWindow: ")
    print(window:isWindow())
    print("pid: ")
    print(window:pid())
    print("role: ")
    print(window:role())
    print("screen: ")
    print(window:screen())
    print("selectedText: ")
    print(window:selectedText())
    print("size: ")
    print(window:size())
    print("subrole: ")
    print(window:subrole())
    print("title: ")
    print(window:title())
end

function FirefoxCopySource()
    hs.eventtap.keyStroke(HYPER, "l")
    input_pause()
    hs.eventtap.keyStrokes("csc")
    hs.eventtap.keyStroke(NONE, "Return")
    input_pause()
end

function get_aws_credentials()
    local focused = hs.window.focusedWindow()
    local firefox
    status = STATUS("🔑")

    function startFirefox()
        status("start")
        hs.application.launchOrFocus("Firefox")
        local app = hs.application.get("Firefox")
        app:activate()
        local function readyFirefox()
            print("readyFirefox")
            firefox = hs.window.focusedWindow()
            local is_ready = firefox:application():name() == "Firefox"
            print("is ready:", is_ready)
            return is_ready
        end
        print("setup")
        wait_until(readyFirefox, onFirefox, cleanup)
    end

    function onFirefox()
        status("on firefox")
        hs.eventtap.keyStroke(HYPER, "t")
        input_pause()
        hs.eventtap.keyStrokes("https://spireglobal.okta.com/app/UserHome")
        hs.eventtap.keyStroke(NONE, "Return")
        local function readyOkta()
            status("❔Sign in")
            local title = hs.window.focusedWindow():title()
            return title:match("Spire Global")
        end
        wait_until(readyOkta, onOkta, cleanup, 40, 1)
    end

    function onOkta()
        status("✅ loading")
        local function readySignIn()
            status("❔password")
            firefox:focus()
            FirefoxCopySource()
            local pasteboardContent = hs.pasteboard.getContents()
            if pasteboardContent:match("Sign In") then
                print("Password form ready")
                return true
            end
            if pasteboardContent:match("Verify with your password") then
                print("Password form ready")
                return true
            end
        end
        wait_until(readySignIn, function() hs.timer.doAfter(5, onSignIn) end,
                   cleanup, 30, 1)
    end

    function onSignIn()
        status("✅ sign in")
        hs.eventtap.keyStroke(NONE, "Tab")
        hs.eventtap.keyStroke(NONE, "Return")
        hs.timer.doAfter(5, onOTP)
    end

    function onOTP()
        status("✅ otp")
        type_otp("OTP_OKTA")
        hs.timer.doAfter(5, onMyAPPs)
    end

    function onMyAPPs()
        status("on MyAPPs")
        hs.eventtap.keyStroke(HYPER, "l")
        input_pause()
        hs.eventtap.keyStrokes(
            "https://spireglobal.okta.com/home/amazon_aws_sso/0oa9asc523yi9gGC45d7/aln1ghfn5xxV7ZPbE1d8")
        hs.eventtap.keyStroke(NONE, "Return")
        hs.timer.doAfter(10, onAWS)
        wait_until(readyOkta, onOkta, cleanup, 40, 1)
    end

    function onAWS()
        status("on MyAPPs")
        hs.eventtap.keyStrokes("/")
        input_pause()
        hs.eventtap.keyStrokes("fans")
        hs.eventtap.keyStroke(NONE, "Return")
        input_pause()
        hs.eventtap.keyStroke({"shift"}, "Tab")
        input_pause()
        hs.eventtap.keyStroke(NONE, "Return")
        input_pause(1)
        hs.eventtap.keyStrokes("/")
        input_pause()
        hs.eventtap.keyStrokes("write")
        hs.eventtap.keyStroke(NONE, "Return")
        input_pause()
        hs.eventtap.keyStroke(NONE, "Tab")
        input_pause()
        hs.eventtap.keyStroke(NONE, "Return")
        input_pause(5)
        hs.eventtap.keyStrokes("/")
        input_pause()
        hs.eventtap.keyStrokes("export")
        hs.eventtap.keyStroke(NONE, "Return")
        input_pause()
        hs.eventtap.keyStroke(NONE, "Tab")
        input_pause()
        hs.eventtap.keyStroke(NONE, "Return")
        cleanup()
    end

    function cleanup()
        status("🧹 cleanup")
        local title = hs.window.focusedWindow():title()
        -- if title:match(" Email -- ") then
        --     hs.eventtap.keyStroke({"cmd"}, "w")
        -- end
        focused:focus()
        status:destroy()
    end

    startFirefox()
end

function export_mails()
    local focused = hs.window.focusedWindow()
    local mails_filename = os.getenv("HOME") .. "/Downloads/mails.html"
    status = STATUS("📩")
    os.remove(mails_filename)

    function startFirefox()
        status("start")
        hs.application.launchOrFocus("Firefox")
        local app = hs.application.get("Firefox")
        app:activate()
        local function readyFirefox()
            print("readyFirefox")
            local is_ready = hs.window.focusedWindow():application():name() ==
                                 "Firefox"
            print("is ready:", is_ready)
            return is_ready
        end
        print("setup")
        wait_until(readyFirefox, onFirefox, cleanup)
    end

    function onFirefox()
        status("on firefox")
        hs.eventtap.keyStroke(HYPER, "t")
        input_pause()
        hs.eventtap.keyStrokes("https://outlook.office365.us/mail/")
        hs.eventtap.keyStroke(NONE, "Return")
        local function readyInbox()
            status("❔Email")
            local title = hs.window.focusedWindow():title()
            return title:match(" Email -- ")
        end
        wait_until(readyInbox, onInbox, cleanup, 40, 1)
    end

    function onInbox()
        status("✅ loading")
        local function readyMails()
            status("❔ajax")
            FirefoxCopySource()
            local pasteboardContent = hs.pasteboard.getContents()
            if pasteboardContent:match("data--convid") then
                print("mails ready")
                return true
            end
        end
        wait_until(readyMails, function()
            hs.timer.doAfter(5, onReadyMails)
        end, cleanup, 30, 1)
    end

    function onReadyMails()
        status("✅ mails")
        local pasteboardContent = hs.pasteboard.getContents()
        local file = io.open(mails_filename, "w")
        file:write(pasteboardContent)
        file:close()
        cleanup()
    end

    function cleanup()
        status("🧹 cleanup")
        local title = hs.window.focusedWindow():title()
        if title:match(" Email -- ") then
            hs.eventtap.keyStroke({"cmd"}, "w")
        end
        focused:focus()
        status:destroy()
    end

    startFirefox()
end

function export_calendar()
    local focused = hs.window.focusedWindow()
    local calendar_filename = os.getenv("HOME") .. "/Downloads/calendar.html"
    status = STATUS("🗓️")
    os.remove(calendar_filename)
    local titleReady = " Calendar "

    function startFirefox()
        status("✅ start")
        hs.application.launchOrFocus("Firefox")
        local app = hs.application.get("Firefox")
        app:activate()
        local function readyFirefox()
            print("readyFirefox")
            local is_ready = hs.window.focusedWindow():application():name() ==
                                 "Firefox"
            print("is ready:", is_ready)
            return is_ready
        end
        print("setup")
        wait_until(readyFirefox, onFirefox, cleanup)
    end

    function onFirefox()
        status("✅ on firefox")
        hs.eventtap.keyStroke(HYPER, "t")
        input_pause()
        hs.eventtap.keyStrokes("https://outlook.office365.us/calendar/view/day")
        hs.eventtap.keyStroke(NONE, "Return")
        local function readyCalendar()
            status("❔calendar")
            local title = hs.window.focusedWindow():title()
            return title:match(titleReady)
        end
        wait_until(readyCalendar, onCalendar, cleanup, 40, 1)
    end

    function onCalendar()
        status("✅ calendar")
        local function readyEvents()
            status("❔ajax")
            FirefoxCopySource()
            local pasteboardContent = hs.pasteboard.getContents()
            if pasteboardContent:match("Loading your events") then
                print("loading your events")
                return false
            elseif pasteboardContent:match('<div id="loadingScreen">') then
                print('<div id="loadingScreen">')
                return false
            elseif pasteboardContent:match('ms-Spinner-circle') then
                print("ms-Spinner-circle")
                return false
            else
                return true
            end
        end
        wait_until(readyEvents,
                   function() hs.timer.doAfter(5, onReadyEvents) end, cleanup,
                   30, 1)
    end

    function onReadyEvents()
        status("✅ ajax")
        local pasteboardContent = hs.pasteboard.getContents()
        local file = io.open(calendar_filename, "w")
        file:write(pasteboardContent)
        file:close()
        cleanup()
    end

    function cleanup()
        status("🧹 cleanup")
        local title = hs.window.focusedWindow():title()
        if title:match(titleReady) then
            hs.eventtap.keyStroke({"cmd"}, "w")
        end
        focused:focus()
        status:destroy()
    end

    startFirefox()
end

function show_teams(selector)
    focus_app("Microsoft Teams")
    -- focus_and_show("Microsoft Teams")
    hs.eventtap.keyStroke(HYPER, selector)
end

function select_firefox_window(winger_str)
    hs.application.launchOrFocus("Firefox")
    hs.eventtap.keyStroke(HYPER_RESERVED, "F1")
    input_pause()
    hs.eventtap.keyStrokes(winger_str)
    hs.eventtap.keyStroke(NONE, "Return")
    hs.eventtap.keyStroke(NONE, "Escape")
end

spaces_explored = false
function explore_all_spaces(callback)
    info = get_info_logger("explore_all_spaces")
    callback = callback or function() info("spaces explored") end

    local focused_window = hs.window.focusedWindow()
    local current_space_id = SPACES.focusedSpace()
    local screen_spaces = SPACES.allSpaces()
    function cleanup()
        safeWindowFocus(focused_window)
        callback()
    end
    all_spaces = {current_space_id}
    for screen, spaces in pairs(screen_spaces) do
        for pos, space_id in pairs(spaces) do
            if space_id ~= current_space_id then
                table.insert(all_spaces, space_id)
                info("equeing space: %s", space_id)
            end
        end
    end

    function ready_space(sid)
        info("ready_space(%s)", sid)
        result = false
        for _screen, space_id in pairs(SPACES.activeSpaces()) do
            if sid == space_id then return true end
        end
        SPACES.gotoSpace(sid)
        return false
    end

    function visit_next()
        info("visit_next()")
        if #all_spaces > 0 then
            local sid = table.remove(all_spaces, #all_spaces)
            SPACES.gotoSpace(sid)
            function ready_this() return ready_space(sid) end
            wait_until(ready_this, visit_next, cleanup)
        else
            spaces_explored = true
            cleanup()
        end
    end
    visit_next()
end

function async_launch_or_focus(hint, callback)
    print("async_launch_or_focus(" .. hint .. ", " .. type(callback) .. ")")
    hs.application.launchOrFocus(hint)
    local function ready_launched()
        local is_ready = hs.window.focusedWindow():application():name() == hint
        return is_ready
    end
    wait_until(ready_launched, callback)
end

function async_get_all_windows(callback, force)
    info = get_info_logger("async_get_all_windows")
    force = force or false
    info("with callback: %s", type(callback))
    if not spaces_explored or force then
        explore_all_spaces(function() async_get_all_windows(callback) end)
    else
        local all_windows = get_all_windows()
        print("async_get_all_windows::" .. #all_windows)
        callback(all_windows)
    end
end

function async_get_window(window_id, callback, all_windows)
    info = get_info_logger("async_get_window")
    if all_windows then
        info("all_windows provided method 1")
        return callback(get_window(window_id, all_windows))
    else
        info("all_windows not provided::method 2")
        return async_get_all_windows(function(all_windows)
            async_get_window(window_id, callback, all_windows)
        end)
    end
end

function get_app_window(app, window_id)
    local windows = app:allWindows()
    local window = hs.fnutils.find(windows,
                                   function(w) return w:id() == window_id end)
    return window
end

function find_window(args, options)
    -- args can be
    --  * 'app': application object or app name
    --  * 'window_id': window_id
    --  * 'title': window title
    -- options can be
    --  * 'fuzzy': accept approximation [default: false]
    options = options or {}
    local fuzzy = options["fuzzy"] or false
    local window
    if type(args.app) == "string" then
        args.app = hs.application.get(args.app)
    end
    if args.window_id then
        if args.app then
            window = get_app_window(args.app, args.window_id)
            if window then return window end
        else
            window = hs.window(args.window_id)
            if window then return window end
        end
    end
    if args.title then
        if args.app then
            window = args.app:findWindow(args.title)
            if window then return window end
        end
    else
        window = hs.window(args.title)
        if window then return window end
    end
    if fuzzy then
        if args.title then
            local new_args = hs.fnutils.copy(args)
            new_args.title = string.sub(args.title, 1, #args.title // 2)
            window = find_window(new_args, options)
            if window then return window end
        end
        if args.app then return args.app:mainWindow() end
    end
end

function get_window(window_id, all_windows)
    local window = LIBWINDOW.get(window_id)
    if window then return window end
    local window = LIBWINDOW.windowForID(window_id)
    if window then return window end
    local all_windows = all_windows or get_all_windows()
    return hs.fnutils.find(all_windows,
                           function(w) return w:id() == window_id end)
end

function get_all_windows()
    -- you might want to ensure explore_all_spaces is called
    function filter(window)
        -- this is to prevent teams phantom window of showing
        return window:title() ~= "Microsoft Teams Notification"
    end
    input_pause()
    local all_windows = WF.new(filter):getWindows(hs.window.sortByFocusedLast)
    return all_windows
end

function choose_window(all_windows)
    if all_windows == nil then return async_get_all_windows(choose_window) end
    local chooser = hs.chooser.new(function(result)
        if result ~= nil then result.window:focus() end
    end)
    chooser:searchSubText(true)
    local windows_options = hs.fnutils.map(all_windows, function(win)
        if win ~= focused_window then
            return {
                text = win:title(),
                subText = win:application():title(),
                image = hs.image
                    .imageFromAppBundle(win:application():bundleID()),
                window = win
            }
        end
    end)
    chooser:choices(windows_options)
    chooser:show()
end

function pickle_window(window)
    return {
        id = window:id(),
        pid = window:pid(),
        application = window:application():bundleID(),
        title = window:title()
    }
end

function unpickle_window(attributes)
    local all_windows = WF.default:getWindows()
    for _, window in ipairs(all_windows) do
        if window:id() == attributes.id and window:pid() == attributes.pid then
            return window
        end
    end
    for _, window in ipairs(all_windows) do
        if window:title() == attributes.title and
            window:application():bundleID() == attributes.application then
            return window
        end
    end
end

function resizeAsCompanion(targetWindow, focusedWindow, options)
    options = options or {}
    if options.resize == nil then options.resize = true end
    focusedWindow = focusedWindow or hs.window.focusedWindow()
    local focusedFrame = focusedWindow:frame()
    local screen = focusedWindow:screen()
    local max = screen:frame()
    local minWidth = 400

    local leftSpace = focusedFrame.x
    local rightSpace = max.w - (focusedFrame.x + focusedFrame.w)

    local targetFrame
    if options.resize then
        if math.max(leftSpace, rightSpace) < minWidth then
            width = math.max(minWidth, max.w / 3)
            targetFrame = {x = max.w - width, y = 0, w = width, h = max.h}
        elseif leftSpace > rightSpace then
            targetFrame = {x = 0, y = 0, w = leftSpace, h = max.h}
        else
            targetFrame = {
                x = max.w - rightSpace,
                y = 0,
                w = rightSpace,
                h = max.h
            }
        end
    else
        width = targetWindow:frame().w
        if leftSpace > rightSpace then
            targetFrame = {x = 0, y = 0, w = width, h = max.h}
        else
            targetFrame = {x = max.w - width, y = 0, w = width, h = max.h}
        end
    end
    targetWindow:setFrame(targetFrame)
end

winger_cache = {}
function get_winger_window(winger_str, ignore_cache)
    ignore_cache = ignore_cache or false
    info = get_info_logger("get_winger_window")
    info("winger_str: " .. winger_str)
    if winger_cache[winger_str] and not ignore_cache then
        info("using cache")
        if winger_cache[winger_str]:isWindow() then
            return winger_cache[winger_str]
        end
    end
    local original_window = safe_get_focused_window()
    local original_space_id = SPACES.focusedSpace()
    select_firefox_window(winger_str)
    winger_window = safe_get_focused_window()
    SPACES.gotoSpace(original_space_id)
    safeWindowFocus(original_window)
    winger_cache[winger_str] = winger_window
    return winger_window
end

function sendBack(window)
    local windows = hs.window.orderedWindows()
    if pcall(function()
        prev = windows[2]
        prevprev = windows[3]
        prevprev:focus()
        prev:focus()
    end) then
        print("focussed orderedWindows")
    else
        target_window:sendToBack()
    end
end

function bring_or_hide_window(target_window)
    local currently_focused = safe_get_focused_window()
    local result = nil
    if currently_focused:id() == target_window:id() then
        sendBack(currently_focused)
    else
        pre_chat_window = currently_focused
        result = safeWindowFocus(target_window)
    end
    show_focused_window()
    return result
end

function bring_window(window, options)
    options = options or {}
    companion = options.companion or false
    if options.resize == nil then options.resize = true end
    local focusedWindow = hs.window.focusedWindow()
    if window ~= focusedWindow then
        if companion then
            resizeAsCompanion(window, nil, {resize = options.resize})
        end
        result = safeWindowFocus(window)
    else
        sendBack(window)
    end
    show_focused_window()
    return result
end

TODO_WINDOW = nil
function todoWindow(options)
    options = options or {}
    local set = options.set
    if set then
        TODO_WINDOW = safe_get_focused_window()
        show_focused_window()
    else
        if not TODO_WINDOW then
            hs.alert("Todo not yet set")
        else
            bring_window(TODO_WINDOW, {companion = true, resize = false})
        end
    end
end

function type_otp(name)
    otp = SHUTIL.shellGet("s.otp " .. name)
    hs.eventtap.keyStrokes(otp)
    hs.eventtap.keyStroke(NONE, "Return")
end

function split_lines(str)
    local t = {}
    for line in str:gmatch("([^\n]*)\n?") do table.insert(t, line) end
    return t
end

function get_otp_names()
    local cmd = "awk -F'[_ =]' '/OTP/{print $3}' ~/.tokens"
    local otp_names = split_lines(SHUTIL.shellGet(cmd))
    return otp_names
end

function choose_otp()
    local chooser = hs.chooser.new(function(result)
        if result ~= nil then type_otp("OTP_" .. result.text) end
    end)
    chooser:searchSubText(true)
    local names = get_otp_names()
    local options = hs.fnutils.map(names,
                                   function(name) return {text = name} end)
    chooser:choices(options)
    chooser:show()
end

local RB_Firefox = {
    [RB.singleKey('f', 'Firefox')] = function() focus_app("Firefox") end,
    [RB.singleKey('1', '1')] = function() select_firefox_window("1") end,
    [RB.singleKey('2', '2')] = function() select_firefox_window("2") end,
    [RB.singleKey('·', '3')] = function() select_firefox_window("3") end,
    [RB.singleKey('k', 'KO')] = function() select_firefox_window("KO") end,
    [RB.singleKey('m', 'Mine')] = function() select_firefox_window("mine") end,
    [RB.singleKey('c', 'Chat')] = function() select_firefox_window("Chat") end
}

function get_active_application_label()
    success, exitcode, output = hs.applescript([[
    tell application "System Events" to set activeApp to first application process whose frontmost is true
    tell activeApp to return its «class pALL»
    ]])
    -- print("output: " .. tostring(output))
    local label = output:match("Applications:([^.]+)")
    if not label then label = output:match([['dnam':'utxt'."([^"]+)]]) end
    return label
end

function click_docker_menu(selector, setto)
    local label = get_active_application_label()
    script = 'tell application "System Events"'
    script = script .. 'to tell UI element "' .. label ..
                 '" of list 1 of process "Dock"'
    script = script .. '\nperform action "AXShowMenu"'
    script = script .. '\ndelay 0.1'
    clicker = {}

    for num, step in pairs(selector) do
        line = [[menu item "]] .. step .. [[" of menu 1]]
        if num > 1 then line = line .. " of " .. clicker[num - 1] end
        table.insert(clicker, line)
    end

    chooser = {}
    last_line = clicker[#clicker]
    table.remove(clicker, #clicker)
    table.insert(chooser,
                 'set isChecked to value of attribute "AXMenuItemMarkChar" of ' ..
                     last_line)
    noop = "key code 53 -- Press Escape key"
    click = "click " .. last_line
    if setto == true then
        when_checked = noop
        when_unchecked = click
    elseif setto == false then
        when_checked = click
        when_unchecked = noop
    else
        when_checked = click
        when_unchecked = click
    end
    table.insert(chooser, 'if (isChecked = "✓") then')
    table.insert(chooser, when_checked)
    table.insert(chooser, 'else')
    table.insert(chooser, when_unchecked)
    table.insert(chooser, 'end if')
    table.insert(chooser, 'isChecked')

    for _, line in pairs(clicker) do script = script .. "\nclick " .. line end
    for _, line in pairs(chooser) do script = script .. "\n" .. line end
    script = script .. "\nend tell"
    errorno, was_checked, _ = hs.applescript(script)
    was_checked = was_checked and true or false
    return was_checked
end

-- function afloatx_toggle_float()
--     is_float = not click_docker_menu({"AfloatX", "Float Window"})
--     input_pause()
--     click_docker_menu({"AfloatX", "Outline Window", "Blue"}, is_float)
-- end

-- function afloatx_toggle_sticky()
--     is_sticky = not click_docker_menu({"AfloatX", "Sticky Window"})
--     input_pause()
--     click_docker_menu({"AfloatX", "Outline Window", "Yellow"}, is_sticky)
-- end

function appID(app)
    return hs.application.infoForBundlePath(app)['CFBundleIdentifier']
end
Safari = "com.apple.Safari"
Chrome = "com.google.Chrome"
Firefox = "org.mozilla.Firefox"
Zoom = "us.zoom.xos"
Slack = 'com.tinyspeck.slackmacgap'
TorBrowser = 'org.torproject.torbrowser'
Teams = "com.microsoft.teams2"

spoon.SpoonInstall:andUse("URLDispatcher", {
    config = {
        default_handler = Firefox,
        url_patterns = {
            {"https?://meet%.google%.com", Chrome},
            {"https?://gov.teams.microsoft.us", Teams},
            {"https?://zoom%.us/j/", Zoom}, {"https?://%w+%.zoom%.us/j/", Zoom},
            {"https?://%w+%.vivastreet.co.uk", TorBrowser},
            {"https?://%w+%.google.com/maps", TorBrowser},
            {"https?://view.vzaar.com/", TorBrowser},
            {"https?://%w+%.viva-images.com/", TorBrowser},
            {"https?://thepiratebay.org/", TorBrowser}
        },
        url_redir_decoders = {
            {"microsoft", ".*safelinks.*?url=([^&]*).*", "%1"}
        }
    },
    start = true
})

-- SPOTIFY:start()

function VPNConnect()
    hs.osascript.applescript([[
    tell application "Viscosity" to connect "lan"
    tell application "Viscosity" to connect "ect"
    ]])
end

function VPNDisconnect()
    hs.osascript.applescript([[
    tell application "Viscosity" to disconnectall
    ]])
end

function centerWindow(window)
    window = window or hs.window.focusedWindow()
    local screen = hs.screen.mainScreen()

    if screen:name() == "Built-in Retina Display" then
        width = 0.5
    else
        width = 1 / 3
    end
    local layout = hs.geometry.unitrect((1 - width) / 2, 0, width, 1)
    hs.layout.apply({{nil, window, screen, layout, 0, 0}})
end

function open_ko_bookmarks()
    get_winger_window("KO")
    SHUTIL.shellDo("ff_bookmarks open-ko&", {py_env = "p3"})
end

function retry(fn, delay, attempts)
    -- this blocks LUA, so, it only makes sense when waiting for MacOS to be ready
    -- try to use wait_until for almost everything
    delay = delay or 2e5
    attempts = attempts or 5
    local result = nil
    for attempt = 1, attempts do
        result = fn()
        if result ~= nil then return result end
        if attempt < attempts then hs.timer.usleep(delay) end
    end
    error("Function failed after maximum attempts")
end

function safe_get_focused_window()
    -- try hard to fetch the window that has the focus, or the frontmost one
    success, result = pcall(function()
        return retry(function()
            return hs.window.focusedWindow() or hs.window.frontmostWindow()
        end)
    end)
    if success then return result end
end

function safeWindowFocus(window)
    -- try hard to focus the window
    success, result = pcall(function()
        return retry(function()
            window:focus()
            return safe_get_focused_window() == window or nil
        end)
    end)
    if success then return result end
end

function safeGotoSpace(space_id)
    -- try hard to goto Space
    success, result = pcall(function()
        return retry(function()
            if SPACES.focusedSpace() ~= space_id then
                SPACES.gotoSpace(space_id)
            end
            return SPACES.focusedSpace() == space_id or nil
        end)
    end)
    if success then return result end
end

function new_firefox_tab()
    local app = hs.application.frontmostApplication()
    if app:name() ~= "Firefox" then
        async_launch_or_focus("Firefox", function()
            show_focused_window()
            new_firefox_tab()
        end)
    end
    hs.eventtap.keyStroke(HYPER, "t")
    return app
end

hs.loadSpoon("Split")
hs.loadSpoon("EasyMove")
hs.loadSpoon("Queue")

spoon.SpoonInstall:andUse("FastModal", {
    config = {
        mappings = {
            a = {"Anki", function() focus_app("Anki") end},
            c = {"Calendar", show_calendar},
            f = {"Firefox", RB_Firefox},
            i = {"iTerm", focusIterm},
            m = {"Spotify", function() focus_and_show("Spotify") end},
            o = {"OTP", choose_otp},
            s = {"Slack", function() focus_app("Slack") end},
            t = {
                "Teams", {
                    a = {"🛎️ Activity", function()
                        show_teams("1")
                    end},
                    c = {"📆 Calendar", function()
                        show_teams("4")
                    end},
                    p = {"👽 People", function()
                        show_teams("2")
                    end},
                    t = {"👯 Teams", function()
                        show_teams("3")
                    end}
                }
            }
        }
    }
})

-- disable annoying Cmd + H
-- Additional hotkeys moved to modules/hotkeys.lua
require("modules.hotkeys")
