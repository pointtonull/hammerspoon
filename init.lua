
require("modules.config")
require("modules.utils")

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




	require("modules.smart").init()
	require("modules.passata").init()

CONSOLE = require("lib.console")
CONSOLE:init()
CONSOLE:start()

INSTALL = hs.loadSpoon("SpoonInstall")
RB = hs.loadSpoon("RecursiveBinder")


INSTALL:andUse("ReloadConfiguration", {start = true})
INSTALL:andUse("Commander")


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




-- Viscosity authentication moved to modules/viscosity.lua
require("modules.viscosity").init()
-- window management functions moved to modules/window.lua
	require("modules.window")

	get_aws_credentials = AWS.get_aws_credentials
	export_mails = AWS.export_mails
	export_calendar = AWS.export_calendar


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
    -- Simplified to only fetch all windows directly, as spaces are not used
    local all_windows = get_all_windows()
    callback(all_windows)
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


function open_ko_bookmarks()
    local w = get_winger_window("KO")
    bring_or_hide_window(w)
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

OTP = require("modules.otp")

spoon.SpoonInstall:andUse("FastModal", {
    config = {
        mappings = {
            a = {"Anki", function() focus_app("Anki") end},
            c = {"Calendar", show_calendar},
            f = {"Firefox", RB_Firefox},
            i = {"iTerm", focusIterm},
            m = {"Spotify", function() focus_and_show("Spotify") end},
			    o = {"OTP", OTP.choose_otp},
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
