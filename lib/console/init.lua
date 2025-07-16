local obj = {}
obj.__index = obj

obj.name = "Console"
obj.version = "1.0"
obj.author = "pointtonull"
obj.homepage = "https://github.com/pointtonull/console"
obj.license = "MIT - https://opensource.org/licenses/MIT"

function obj:init()
    self.possition = "bottom"
    self.high = 30
    self.logger = hs.logger.new("Console", "debug")
    self.seconds_to_fade = 5
    self.colors = {}
    self.colors["color"] = {red = 1.0, green = 0.0, blue = 0.0}
    self.colors["background"] = {red = 1.0, green = 0.0, blue = 0.0}
end

function obj:setup_canvas()
    local screen_frame = hs.screen.mainScreen():fullFrame()
    local console_frame

    if self.possition == "bottom" then
        console_frame = {
            x = 0,
            y = screen_frame.h - self.high,
            w = screen_frame.w,
            h = self.high
        }
    elseif self.possition == "top" then
        console_frame = {x = 0, y = 0, w = screen_frame.w, h = self.high}
    else
        self.logger:error("position setting not recognized")
    end

    self.canvas_console = hs.canvas.new(console_frame):behavior(hs.canvas
                                                                    .windowBehaviors["canJoinAllSpaces"])
                              :show()
end

function obj:start()
    self:setup_canvas()
    self.watcher = hs.screen.watcher.new(
                       hs.fnutils.partial(self.setup_canvas, self))
    self.watcher:start()
end

function obj:post(message, color)
    self.logger.i("posting new line to console")
    color = color or self.colors["color"]
    self.canvas_console:show()
end

function obj:hide()
    self.logger.i("hiding console")
    self.canvas_console:hide()
end

-- console:bindHotkeys(mapping)
-- Method
-- Binds hotkeys for Console
--
-- Parameters:
--  * mapping - A table containing hotkey modifier/key details for the following items:
--    * post - sends message to the console
function obj:bindHotkeys(mapping)
    local actions = {post = hs.fnutils.partial(self.post, self)}
    hs.spoons.bindHotkeysToSpec(actions, mapping)
end

return obj
