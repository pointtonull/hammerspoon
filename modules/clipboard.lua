-- Clipboard and editing utilities moved from init.lua
SHUTIL = require("lib.shutil")

local M = {}

--- Open the current clipboard text in editor, then restore selection
function M.edit_text()
    local original = hs.window.focusedWindow()
    hs.eventtap.keyStroke(HYPER, "a")
    hs.eventtap.keyStroke(HYPER, "c")
    input_pause()

    local function cleanup()
        original:focus()
        hs.eventtap.keyStroke(HYPER, "a")
        hs.eventtap.keyStroke(HYPER, "v")
    end

    local function ready_editor()
        local focused = hs.window.focusedWindow()
        return focused and focused:title() == "nvim"
    end

    local function on_editor()
        local window = hs.window.focusedWindow()
        window:setFrame(original:frame())
    end

    local function pbedit()
        local cmd = "/Users/carlos.cabrera/bin/pbedit"
        local task = hs.task.new(cmd, cleanup)
        task:start()
        wait_until(ready_editor, on_editor, cleanup)
    end

    pbedit()
end

--- Copy selection, evaluate as calculator expression, and replace
function M.calc_text()
    hs.eventtap.keyStroke(HYPER, "a")
    hs.eventtap.keyStroke(HYPER, "c")
    input_pause()
    local cmd = "pbpaste | bc -S 2"
    local result = SHUTIL.shellGet(cmd)
    hs.eventtap.keyStrokes(result)
end

--- Summarize selected text via external tool
function M.summarize()
    hs.alert("🧠 Reading...")
    hs.eventtap.keyStroke(HYPER, "c")
    SHUTIL.shellDo("s.say_summarize&", {py_env = "p3"})
end

return M
