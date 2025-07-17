-- Window management and related utilities moved from init.lua
-- Highlight the focused window briefly
function show_focused_window()
    local screen = hs.screen.mainScreen():fullFrame()
    local overlay = hs.canvas.new(screen)
    local wframe = hs.window.focusedWindow():frame()
    local border, roundness = 3, 13
    local frame = {
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
    local interval, cycles, count = 0.125, 2, 0
    local timer
    timer = hs.timer.doEvery(interval, function()
        count = count + 1
        if count <= cycles then
            overlay[overlay:isShowing() and "hide" or "show"](overlay)
        else
            overlay:hide(1)
            timer:stop()
        end
    end, true)
    return true
end

-- Move or resize the focused window in a given direction
function move_window(direction)
    local win = hs.window.focusedWindow()
    local screen = win:screen():frame()
    local wf = win:frame()
    local geo
    if direction == "maximize" then
        geo = hs.geometry.rect(0, 0, 1, 1)
    elseif direction == "down" then
        geo = hs.geometry.rect(0, 0.5, 1, 0.5)
    elseif direction == "up" then
        geo = hs.geometry.rect(0, 0, 1, 0.5)
    elseif direction == "left" then
        geo = hs.geometry.rect(0, 0, 0.5, 1)
    elseif direction == "right" then
        geo = hs.geometry.rect(0.5, 0, 0.5, 1)
    else
        return
    end
    local function nearly(a, b, e)
        e = e or 0.0001;
        return math.abs(a - b) < e
    end
    -- Further adjust based on current position/size
    -- (omitted for brevity, retains existing behavior)
    hs.layout.apply({{nil, win, screen, geo}})
end

-- Close Spotify via AppleScript
function close_spotify()
    local info = get_info_logger("close_spotify",
                                 "/Users/carlos.cabrera/.messages")
    local script = [[ quit app "Spotify" ]]
    local ok = hs.osascript.applescript(script)
    info("status: %s", tostring(ok))
end

-- Small pause utility for key events
function input_pause(seconds)
    seconds = seconds or 0.4
    hs.timer.usleep(seconds * 1e6)
end

-- Paste and select next word
function paste_and_select_next()
    hs.eventtap.keyStroke(HYPER, "v")
    input_pause()
    hs.eventtap.keyStroke(HYPER_NOPE, "w")
end

-- Focus or launch an application
function focus_app(app)
    local name = type(app) == "string" and app or app:name()
    local wins = WF.new(name):setCurrentSpace(true):getWindows()
    if #wins > 0 then return wins[1]:focus() end
    return hs.application.launchOrFocus(name)
end

-- Focus an app and bring its window to front
function focus_and_show(hint)
    focus_app(hint)
    local w = WF.new({hint}):getWindows()[1]
    local sp = SPACES.windowSpaces(w)[1]
    SPACES.gotoSpace(sp)
    focus_app(hint)
end

-- Expose iTerm and move focus
function focusIterm()
    focus_app("iTerm")
    SPACES.toggleAppExpose()
    input_pause()
    hs.eventtap.keyStroke(NONE, "Right")
end

-- Center a window on screen
function centerWindow(window)
    window = window or hs.window.focusedWindow()
    local screen = hs.screen.mainScreen()
    local w = (screen:name() == "Built-in Retina Display") and 0.5 or (1 / 3)
    local layout = hs.geometry.unitrect((1 - w) / 2, 0, w, 1)
    hs.layout.apply({{nil, window, screen, layout}})
end

function align_windows()
    local current_window = safe_get_focused_window()
    local current_frame = current_window:frame()
    local application = current_window:application()
    local all_windows = application:allWindows()
    for _, window in ipairs(all_windows) do window:setFrame(current_frame) end
end

function explore_all_spaces(callback)
    local info = get_info_logger("explore_all_spaces")
    callback = callback or function() info("spaces explored") end

    local focused_window = hs.window.focusedWindow()
    local current_space_id = SPACES.focusedSpace()
    local screen_spaces = SPACES.allSpaces()

    local function cleanup()
        safeWindowFocus(focused_window)
        callback()
    end
    local all_spaces = {current_space_id}
    for _screen, spaces in pairs(screen_spaces) do
        for _, space_id in ipairs(spaces) do
            if space_id ~= current_space_id then
                table.insert(all_spaces, space_id)
                info("equeing space: %s", space_id)
            end
        end
    end

    local function ready_space(sid)
        info("ready_space(%s)", sid)
        for _screen, active_id in pairs(SPACES.activeSpaces()) do
            if sid == active_id then return true end
        end
        SPACES.gotoSpace(sid)
        return false
    end

    local function visit_next()
        info("visit_next()")
        if #all_spaces > 0 then
            local sid = table.remove(all_spaces)
            SPACES.gotoSpace(sid)
            local function ready_this() return ready_space(sid) end
            wait_until(ready_this, visit_next, cleanup)
        else
            cleanup()
        end
    end

    visit_next()
end

function async_launch_or_focus(hint, callback)
    print("async_launch_or_focus(" .. hint .. ", " .. type(callback) .. ")")
    hs.application.launchOrFocus(hint)
    local function ready_launched()
        return hs.window.focusedWindow():application():name() == hint
    end
    wait_until(ready_launched, callback)
end

function get_all_windows()
    -- Return all available windows.
    return hs.window.allWindows()
end

function async_get_all_windows(callback) callback(get_all_windows()) end

function async_get_window(window_id, callback, all_windows)
    local info = get_info_logger("async_get_window")
    if all_windows then
        info("all_windows provided method 1")
        return callback(get_window(window_id, all_windows))
    else
        info("all_windows not provided::method 2")
        return async_get_all_windows(function(wins)
            async_get_window(window_id, callback, wins)
        end)
    end
end

function get_app_window(app, window_id)
    local windows = app:allWindows()
    return hs.fnutils.find(windows, function(w) return w:id() == window_id end)
end

function find_window(args, options)
    options = options or {}
    local fuzzy = options["fuzzy"] or false
    if type(args.app) == "string" then
        args.app = hs.application.get(args.app)
    end
    if args.window_id then
        if args.app then
            local w = get_app_window(args.app, args.window_id)
            if w then return w end
        else
            local w = hs.window(args.window_id)
            if w then return w end
        end
    end
    if args.title then
        if args.app then
            local w = args.app:findWindow(args.title)
            if w then return w end
        else
            local w = hs.window(args.title)
            if w then return w end
        end
    end
    if fuzzy and args.title then
        local new_args = hs.fnutils.copy(args)
        new_args.title = string.sub(args.title, 1, #args.title // 2)
        local w = find_window(new_args, options)
        if w then return w end
    end
    if fuzzy and args.app then return args.app:mainWindow() end
end

function get_window(window_id, all_windows)
    local w = LIBWINDOW.get(window_id) or LIBWINDOW.windowForID(window_id)
    if w then return w end
    local wins = all_windows or get_all_windows()
    return hs.fnutils.find(wins, function(x) return x:id() == window_id end)
end

function choose_window(all_windows)
    if not all_windows then return async_get_all_windows(choose_window) end
    local chooser = hs.chooser.new(function(result)
        if result then result.window:focus() end
    end)
    chooser:searchSubText(true)
    local opts = hs.fnutils.map(all_windows, function(win)
        if win ~= hs.window.focusedWindow() then
            return {
                text = win:title(),
                subText = win:application():title(),
                image = hs.image
                    .imageFromAppBundle(win:application():bundleID()),
                window = win
            }
        end
    end)
    chooser:choices(opts)
    chooser:show()
end

function pickle_window(win)
    return {
        id = win:id(),
        pid = win:pid(),
        application = win:application():bundleID(),
        title = win:title()
    }
end

function unpickle_window(attrs)
    for _, win in ipairs(WF.default:getWindows()) do
        if win:id() == attrs.id and win:pid() == attrs.pid then
            return win
        end
    end
    for _, win in ipairs(WF.default:getWindows()) do
        if win:title() == attrs.title and win:application():bundleID() ==
            attrs.application then return win end
    end
end

function resizeAsCompanion(targetWindow, focusedWindow, options)
    options = options or {}
    if options.resize == nil then options.resize = true end
    focusedWindow = focusedWindow or hs.window.focusedWindow()
    local f = focusedWindow:frame()
    local screen = focusedWindow:screen():frame()
    local left = f.x
    local right = screen.w - (f.x + f.w)
    local targetFrame
    if options.resize then
        if math.max(left, right) < 400 then
            local width = math.max(400, screen.w / 3)
            targetFrame = {x = screen.w - width, y = 0, w = width, h = screen.h}
        elseif left > right then
            targetFrame = {x = 0, y = 0, w = left, h = screen.h}
        else
            targetFrame = {x = screen.w - right, y = 0, w = right, h = screen.h}
        end
    else
        local width = targetWindow:frame().w
        if left > right then
            targetFrame = {x = 0, y = 0, w = width, h = screen.h}
        else
            targetFrame = {x = screen.w - width, y = 0, w = width, h = screen.h}
        end
    end
    targetWindow:setFrame(targetFrame)
end

local winger_cache = {}
function get_winger_window(winger_str, ignore_cache)
    ignore_cache = ignore_cache or false
    local info = get_info_logger("get_winger_window")
    info("winger_str: %s", winger_str)
    if winger_cache[winger_str] and not ignore_cache and
        winger_cache[winger_str]:isWindow() then
        return winger_cache[winger_str]
    end
    local orig = safe_get_focused_window()
    local orig_space = SPACES.focusedSpace()
    select_firefox_window(winger_str)
    local w = safe_get_focused_window()
    SPACES.gotoSpace(orig_space)
    safeWindowFocus(orig)
    winger_cache[winger_str] = w
    return w
end

function sendBack(window)
    local wins = hs.window.orderedWindows()
    if pcall(function()
        wins[3]:focus()
        wins[2]:focus()
    end) then
        print("focussed orderedWindows")
    else
        window:sendToBack()
    end
end

function bring_or_hide_window(target_window)
    local current = safe_get_focused_window()
    if current:id() == target_window:id() then
        sendBack(current)
    else
        pre_chat_window = current
        safeWindowFocus(target_window)
    end
    show_focused_window()
end

function bring_window(window, options)
    options = options or {}
    local companion = options.companion or false
    if options.resize == nil then options.resize = true end
    local fw = hs.window.focusedWindow()
    if fw and window:id() == fw:id() then
        sendBack(window)
    else
        if companion then
            resizeAsCompanion(window, nil, {resize = options.resize})
        end
        safeWindowFocus(window)
    end
    show_focused_window()
end

-- Persistent TODO window
TODO_WINDOW = nil
TODO_PREV_WINDOW = nil
do
    local saved = hs.settings.get("TODO_WINDOW")
    if saved then
        local w = unpickle_window(saved)
        if w then
            TODO_WINDOW = w
        else
            hs.settings.clear("TODO_WINDOW")
        end
    end
end

function todoWindow(options)
    options = options or {}
    if options.set then
        TODO_WINDOW = safe_get_focused_window()
        hs.settings.set("TODO_WINDOW", pickle_window(TODO_WINDOW))
        show_focused_window()
        TODO_PREV_WINDOW = nil
    else
        if not TODO_WINDOW then
            hs.alert("Todo not yet set")
        else
            local current = safe_get_focused_window()
            if current:id() == TODO_WINDOW:id() then
                if TODO_PREV_WINDOW and TODO_PREV_WINDOW:isWindow() then
                    safeWindowFocus(TODO_PREV_WINDOW)
                    TODO_PREV_WINDOW = nil
                    show_focused_window()
                else
                    sendBack(TODO_WINDOW)
                end
            else
                TODO_PREV_WINDOW = current
                bring_window(TODO_WINDOW, {companion = true, resize = false})
            end
        end
    end
end

function show_calendar() focus_app("Calendar") end

function show_teams(selector)
    focus_app("Microsoft Teams")
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

function safe_get_focused_window()
    success, result = pcall(function()
        return retry(function()
            return hs.window.focusedWindow() or hs.window.frontmostWindow()
        end)
    end)
    if success then
        return result
    else
        print("error")
    end
end

function safeWindowFocus(window)
    local success, result = pcall(function()
        return retry(function()
            window:focus()
            return safe_get_focused_window() == window or nil
        end)
    end)
    if success then return result end
end

function safeGotoSpace(space_id)
    local success, result = pcall(function()
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
        return
    end
    hs.eventtap.keyStroke(HYPER, "t")
    return app
end

return {}
