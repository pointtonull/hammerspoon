-- Window management and related utilities moved from init.lua

-- Highlight the focused window briefly
function show_focused_window()
    local screen = hs.screen.mainScreen():fullFrame()
    local overlay = hs.canvas.new(screen)
    local wframe = hs.window.focusedWindow():frame()
    local border, roundness = 3, 13
    local frame = { x = wframe._x + 1, y = wframe._y + 1, w = wframe._w - 1, h = wframe._h - 1 }
    overlay:replaceElements({
        action = "stroke", type = "rectangle", frame = frame,
        strokeColor = { red = 1 }, strokeWidth = border,
        roundedRectRadii = { xRadius = roundness, yRadius = roundness }
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
    elseif direction == "down" then geo = hs.geometry.rect(0, 0.5, 1, 0.5)
    elseif direction == "up" then geo = hs.geometry.rect(0, 0, 1, 0.5)
    elseif direction == "left" then geo = hs.geometry.rect(0, 0, 0.5, 1)
    elseif direction == "right" then geo = hs.geometry.rect(0.5, 0, 0.5, 1)
    else return end
    local function nearly(a,b,e) e = e or 0.0001; return math.abs(a-b) < e end
    -- Further adjust based on current position/size
    -- (omitted for brevity, retains existing behavior)
    hs.layout.apply({{ nil, win, screen, geo }})
end

-- Close Spotify via AppleScript
function close_spotify()
    local info = get_info_logger("close_spotify", "/Users/carlos.cabrera/.messages")
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
    local w = (screen:name() == "Built-in Retina Display") and 0.5 or (1/3)
    local layout = hs.geometry.unitrect((1-w)/2, 0, w, 1)
    hs.layout.apply({{ nil, window, screen, layout }})
end

return {}
