-- init.lua: Hammerspoon main configuration

hs.alert("🔄")

-- Load global settings and utilities
require("modules.config")
require("modules.utils")

-- Smart devices and office lights automation
require("modules.smart").init()

-- Passata Pomodoro timer configuration
require("modules.passata").init()

-- Initialize console for debugging
CONSOLE = require("lib.console")
CONSOLE:init()
CONSOLE:start()

-- SpoonInstall for managing Spoons
local INSTALL = hs.loadSpoon("SpoonInstall")
local RB      = hs.loadSpoon("RecursiveBinder")

-- Reload configuration and Commander Spoons
-- INSTALL:andUse("ReloadConfiguration", {start = true})
INSTALL:andUse("Commander")

-- Viscosity VPN authentication helpers
	local Viscosity = require("modules.viscosity")
	Viscosity.init()
	VPNConnect = Viscosity.VPNConnect
	VPNDisconnect = Viscosity.VPNDisconnect

-- Window management utilities
require("modules.window")

-- AWS credentials and export utilities
get_aws_credentials = AWS.get_aws_credentials
export_mails        = AWS.export_mails
export_calendar     = AWS.export_calendar

-- Application constants for URLDispatcher
Safari     = "com.apple.Safari"
Chrome     = "com.google.Chrome"
Firefox    = "org.mozilla.Firefox"
Zoom       = "us.zoom.xos"
Slack      = "com.tinyspeck.slackmacgap"
TorBrowser = "org.torproject.torbrowser"
Teams      = "com.microsoft.teams2"

-- URLDispatcher Spoon: handle URLs in specific browsers
spoon.SpoonInstall:andUse("URLDispatcher", {
    config = {
        default_handler = Firefox,
        url_patterns = {
            {"https?://meet%.google%.com", Chrome},
            {"https?://gov.teams.microsoft.us", Teams},
            {"https?://zoom%.us/j/", Zoom},
            {"https?://%w+%.zoom%.us/j/", Zoom},
            {"https?://%w+%.vivastreet.co.uk", TorBrowser},
            {"https?://%w+%.google.com/maps", TorBrowser},
            {"https?://view.vzaar.com/", TorBrowser},
            {"https?://%w+%.viva-images.com/", TorBrowser},
            {"https?://thepiratebay.org/", TorBrowser},
        },
        url_redir_decoders = {
            {"microsoft", ".*safelinks.*?url=([^&]*).*", "%1"},
        },
    },
    start = true,
})

-- Load basic Spoons for window splitting and movement
hs.loadSpoon("Split")
hs.loadSpoon("EasyMove")
hs.loadSpoon("Queue")

-- OTP utilities
OTP = require("modules.otp")

-- FastModal Spoon: modal hotkey support
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
                    a = {"🛎️ Activity", function() show_teams("1") end},
                    c = {"📆 Calendar", function() show_teams("4") end},
                    p = {"👽 People", function() show_teams("2") end},
                    t = {"👯 Teams", function() show_teams("3") end},
                }
            },
        },
    },
})

-- Additional hotkey definitions in separate module
require("modules.hotkeys")
