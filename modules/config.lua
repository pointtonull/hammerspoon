-- Global settings moved from init.lua
IPC = require("hs.ipc") -- enables hs cli
-- CONSOLE SETTINGS
CONSOLE = require("hs.console")
CONSOLE.darkMode(true)
CONSOLE.alpha(1)
CONSOLE.titleVisibility("hidden")
CONSOLE.outputBackgroundColor({red = .05, green = .025, blue = .05})
CONSOLE.consoleCommandColor({red = 0, green = 0.8, blue = 0.8})
CONSOLE.consoleResultColor({red = csc, green = 1, blue = 0.5})
CONSOLE.consolePrintColor({white = 1})
CONSOLE.windowBackgroundColor({red = .05, green = .025, blue = .05})
CONSOLE.inputBackgroundColor({red = .1, green = .05, blue = .1})

CANVAS = require("hs.canvas")
HK = require("hs.hotkey")
WF = require("hs.window.filter")
SPACES = require("hs.spaces")
LIBWINDOW = require("hs.libwindow")

SHUTIL = require("lib.shutil")
STATUS = require("lib.status")
BROWSER = require("lib.browser")

LOGGER = hs.logger.new("main", "info")

WORK = hs.host.localizedName() ~= 'Carlos’s Mac mini'

-- disable animations
hs.window.animationDuration = 0

return {}
