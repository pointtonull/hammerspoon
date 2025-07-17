local OTP = require("modules.otp")

-- PASSATA hotkeys
local PASSATA = require("lib.passata")
PASSATA:bindHotkeys({toggle = {{}, "F12", function() PASSATA:toggle() end}})

-- Clipboard utilities
local clipboard = require("modules.clipboard")
local edit_text    = clipboard.edit_text
local calc_text    = clipboard.calc_text
local summarize    = clipboard.summarize

-- Spotify control
local spotify_mod = require("modules.spotify")
local spotify_control = spotify_mod.spotify_control

-- Modifier key constants
HYPER = {"cmd"}               -- shorthand for CMD
HYPER_GLOBAL = {"ctrl", "cmd"}   -- macros independent of local app
HYPER_HYPER = {"ctrl", "cmd", "shift"} -- system-wide macros
HYPER_LOCAL = {"cmd", "alt"}    -- macros for local app
HYPER_NOPE = {"ctrl", "cmd", "alt"}  -- reserved for special hacks
HYPER_WINDOW = {"cmd", "shift"} -- window manager controls
HYPER_RESERVED = {"ctrl", "shift"} -- reserved for in-app configs
NONE = {}                      -- simple key, without modifiers

-- guard hotkey binds to prevent errors when callbacks are missing
do
    local orig_bind = HK.bind
    function HK.bind(mods, key, pressedfn, releasedfn, repeatfn)
        if type(pressedfn) ~= "function" then
            LOGGER.i(string.format("Skipping hotkey for key '%s': no function callback", key))
            return nil
        end
        return orig_bind(mods, key, pressedfn, releasedfn, repeatfn)
    end
end

-- Karabiner hacked modifiers
KARABINER = {
    left_shift   = "s",
    left_control = "c",
    left_command = "h",
    left_option  = "o",
    right_shift   = "d",
    right_control = "v",
    right_command = "j",
    right_option  = "p",
}

-- Basic hotkey bindings
HK.bind(NONE, "F1", function()
    focus_app("Firefox")
    input_pause()
    hs.eventtap.keyStroke(HYPER_RESERVED, "F1")
end)
HK.bind(NONE, "F2", function()
    focus_app("Firefox")
    input_pause()
    hs.eventtap.keyStroke(HYPER_RESERVED, "F2")
end)
HK.bind(NONE, "F3", function() focusIterm() end)
HK.bind(NONE, "F4", function()
    bring_or_hide_window(get_winger_window("Chat"))
end)
HK.bind({"shift"}, "F4", function()
    bring_or_hide_window(get_winger_window("Chat", true))
end)
HK.bind(HYPER_WINDOW, "space", function()
    align_windows()
end)

-- Tab queue modal and navigation
tabqueueModal = HK.modal.new()

local function moveTabLeft(steps)
    for i = 1, steps do
        hs.eventtap.keyStroke(HYPER_RESERVED, "pageup", 12500/2)
    end
end

local function moveTabRight(steps)
    for i = 1, steps do
        hs.eventtap.keyStroke(HYPER_RESERVED, "pagedown", 12500/2)
    end
end

local function duplicateTab()
    input_pause()
    hs.eventtap.keyStroke(HYPER, "l")
    hs.eventtap.keyStroke({"alt", "shift"}, "return")
end

tabqueueModal:bind({"control"}, "W", function()
    hs.eventtap.keyStroke(HYPER, "w")
end)
tabqueueModal:bind({"control"}, "G", function() moveTabLeft(13) end)
tabqueueModal:bind({"control"}, "C", function() moveTabLeft(7) end)
tabqueueModal:bind({"control"}, "H", function() moveTabLeft(3) end)
tabqueueModal:bind({"control"}, "L", function() moveTabRight(3) end)
tabqueueModal:bind({"control"}, "`", function() moveTabRight(7) end)
tabqueueModal:bind({"control"}, "+", function() moveTabRight(13) end)
tabqueueModal:bind({"control"}, "ç", function() moveTabRight(25) end)
tabqueueModal:bind(HYPER_RESERVED, "G", function()
    hs.eventtap.keyStroke(HYPER, "r"); moveTabLeft(13)
end)
tabqueueModal:bind(HYPER_RESERVED, "C", function()
    hs.eventtap.keyStroke(HYPER, "r"); moveTabLeft(7)
end)
tabqueueModal:bind(HYPER_RESERVED, "H", function()
    hs.eventtap.keyStroke(HYPER, "r"); moveTabLeft(3)
end)
tabqueueModal:bind(HYPER_RESERVED, "L", function()
    hs.eventtap.keyStroke(HYPER, "r"); moveTabRight(3)
end)
tabqueueModal:bind(HYPER_RESERVED, "`", function()
    hs.eventtap.keyStroke(HYPER, "r"); moveTabRight(7)
end)
tabqueueModal:bind(HYPER_RESERVED, "+", function()
    hs.eventtap.keyStroke(HYPER, "r"); moveTabRight(13)
end)
tabqueueModal:bind(HYPER_RESERVED, "ç", function()
    hs.eventtap.keyStroke(HYPER, "r"); moveTabRight(25)
end)
tabqueueModal:bind(HYPER_RESERVED, "d", duplicateTab)

-- Enter/exit tab queue on browser focus
wf_browser = WF.new({"Firefox", "Tor Browser", "Google Chrome"})
wf_browser:subscribe(WF.windowFocused, function() tabqueueModal:enter() end)
wf_browser:subscribe(WF.windowUnfocused, function() tabqueueModal:exit() end)

-- Automatically click Keep Hammerspoon dialogs
WF.ignoreAlways["CoreServicesUIAgent"] = false
wf_notification = WF.new(false)
    :setAppFilter("CoreServicesUIAgent", {allowRoles = "AXSystemDialog"})
wf_notification:subscribe({WF.windowCreated, WF.windowFocused}, function(win)
    if win:title() == "" then
        local ui = hs.axuielement.windowElement(win)
        for _, b in ipairs(ui:childrenWithRole("AXButton")) do
            if b:attributeValue("AXTitle"):match("Keep.*Hammerspoon") then
                b:performAction("AXPress")
                return
            end
        end
    end
end)

-- Transmission modal for deleting torrents
transmissionModal = HK.modal.new()
local function deleteTorrent()
    input_pause()
    hs.eventtap.keyStroke(HYPER_LOCAL, "delete", 12500/2)
end
transmissionModal:bind({}, "delete", deleteTorrent)
transmissionModal:bind({}, "forwarddelete", deleteTorrent)
wf_transmission = WF.new({"Transmission"})
wf_transmission:subscribe(WF.windowFocused, function() transmissionModal:enter() end)
wf_transmission:subscribe(WF.windowUnfocused, function() transmissionModal:exit() end)

-- Additional hotkey bindings extracted from init.lua
HK.bind(HYPER, "h", function() hs.eventtap.keyStroke(HYPER_WINDOW, "h") end)
-- make Firefox cmd+t global
HK.bind(HYPER_GLOBAL, "t", BROWSER.new_firefox_tab)
function blackScreen()
    hs.caffeinate.lockScreen()
end
-- easy block screen
HK.bind(HYPER_GLOBAL, "-", blackScreen)

HK.bind(HYPER_LOCAL, "g", function() spoon.Queue:openBookmarks(6) end)
HK.bind(HYPER_LOCAL, "c", function() spoon.Queue:openBookmarks(3) end)
HK.bind(HYPER_LOCAL, "h", function() spoon.Queue:openBookmarks(1) end)
HK.bind(HYPER_LOCAL, "l", function() spoon.Queue:saveBookmark() end)

HK.bind(HYPER_WINDOW, "j", function() move_window("down") end)
HK.bind(HYPER_WINDOW, "k", function() move_window("up") end)
HK.bind(HYPER_WINDOW, "h", function() move_window("left") end)
HK.bind(HYPER_WINDOW, "l", function() move_window("right") end)
HK.bind(HYPER_WINDOW, "m", function() move_window("maximize") end)

-- show emojis & symbols
function show_emojis()
    local app = hs.application.frontmostApplication()
    app:selectMenuItem({"Edit", "Emoji & Symbols"})
end

HK.bind(HYPER_NOPE, KARABINER.left_control, function()
    spoon.Split:selectNextSplit()
end)
HK.bind(HYPER_NOPE, KARABINER.left_command, function()
    spoon.Split:selectNextWindow()
end)
HK.bind(HYPER_NOPE, KARABINER.left_option, function()
    spoon.Split:addSplit()
end)
HK.bind(HYPER_NOPE, KARABINER.right_shift, function()
    show_emojis()
end)

-- Caffeine
function caffeinate()
    hs.caffeinate.toggle("displayIdle")
end
HK.bind(HYPER_WINDOW, "c", caffeinate)

HK.bind(HYPER_WINDOW, "r", hs.reload)

HK.bind(HYPER_WINDOW, "delete", function() spoon.Split:deleteCurrentSplit(true) end)

HK.bind(HYPER_GLOBAL, "m", function() spoon.EasyMove:start() end)
HK.bind(HYPER, "m", function() spoon.EasyMove:start() end)

HK.bind(HYPER_NOPE, KARABINER.right_control, function()
    spoon.Commander.show()
end)
HK.bind(HYPER_NOPE, KARABINER.right_option, function()
    peek_report()
end)
HK.bind(HYPER_NOPE, KARABINER.left_shift, function()
    show_focused_window()
end)

-- Music controls via spotify
function music(action)
    if action == "prev" then spotify_control("prev")
    elseif action == "next" then spotify_control("next")
    elseif action == "next-playlist" then spotify_control("next-playlist")
    elseif action == "next_station" then spotify_control("next")
    elseif action == "play" then spotify_control("play")
    elseif action == "playpause" then spotify_control("play-pause")
    elseif action == "stop" then spotify_control("pause")
    elseif action == "volumen_up" then spotify_control("volume -- +5")
    elseif action == "volumen_down" then spotify_control("volume -- -11")
    else hs.alert("Action not implemented: " .. action) end
end

-- Pasteboard helpers
function paste_text()
    local types = hs.pasteboard.typesAvailable()
    if types["string"] then
        hs.eventtap.keyStrokes(hs.pasteboard.readString())
    elseif types["image"] then
        hs.shortcuts.run("copied image to text")
        input_pause()
        hs.eventtap.keyStrokes(hs.pasteboard.readString())
    else
        hs.eventtap.keyStroke(HYPER, "v")
    end
    inspect(types)
end

function setVolume(volume)
    local device = hs.audiodevice.defaultOutputDevice()
    local new_volume = device:volume() + volume
    if new_volume < 0 then new_volume = 0 end
    if new_volume > 100 then new_volume = 100 end
    device:setOutputVolume(new_volume)
end

-- Clipboard hotkeys
HK.bind(HYPER_GLOBAL, "e", function() SHUTIL.shellDo("pbedit&") end)
HK.bind(HYPER_GLOBAL, "w", paste_and_select_next)
function safe_show_CopyQ()
    SHUTIL.shellDo("copyq show&")
end
HK.bind(HYPER_GLOBAL, "v", safe_show_CopyQ)
HK.bind(HYPER_GLOBAL, "c", calc_text)
HK.bind(HYPER_LOCAL, "e", edit_text)
HK.bind({"cmd", "shift"}, "v", paste_text)
HK.bind(HYPER_GLOBAL, "r", summarize)

-- Global multimedia keys
HK.bind(HYPER_GLOBAL, "l", function() music("next") end)
HK.bind(HYPER_GLOBAL, "`", function() music("next-playlist") end)
HK.bind(HYPER_GLOBAL, "h", function() music("prev") end)

-- Global commands
HK.bind(HYPER_GLOBAL, ",", function() hs.application.open("System Settings") end)

-- Function keys
HK.bind(NONE, "F5", function() music("prev") end)
HK.bind(NONE, "F6", function() music("next") end)
HK.bind({"shift"}, "F6", function() music("next_station") end)
HK.bind(NONE, "F7", function() music("playpause") end)
HK.bind({"shift"}, "F7", function() music("play") end)
HK.bind(NONE, "F8", function() music("stop") end)
HK.bind(NONE, "F9", function() hs.spotify.setVolume(0) end)
HK.bind(NONE, "F10", function() music("volumen_down") end)
HK.bind(NONE, "F11", function() music("volumen_up") end)
HK.bind({"shift"}, "F10", function() setVolume(-5) end)
HK.bind({"shift"}, "F11", function() setVolume(2) end)
HK.bind({"shift"}, "F12", function()
    local w = get_winger_window("KO")
    bring_or_hide_window(w)
    SHUTIL.shellDo("ff_bookmarks open-ko&", {py_env = "p3"})
end)
HK.bind({"option"}, "Escape", function() spoon.FastModal:start() end)
HK.bind({"shift"}, "F13", function() todoWindow({set = true}) end)
HK.bind(NONE, "F13", todoWindow)
