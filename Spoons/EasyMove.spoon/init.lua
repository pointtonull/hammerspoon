--- === EasyMove ===
local obj = {}
-- name = "EasyMove",
-- version = "1.0",
-- author = "Carlos Cabrera <point.to@gmail.com>",
-- license = "MIT <https://opensource.org/licenses/MIT>",
-- homepage = "https://github.com/pointtonull/EasyMove.spoon",
obj.__index = obj

--- EasyMove:start() -> table
--- Method
--- Starts the selection bisect

local function get_info_logger(logger, method_name)
    logger.i(string.format("[%s]", method_name))
    return function(message, ...)
        local args = {...}
        local formatted_message = #args > 0 and
                                      string.format(message, table.unpack(args)) or
                                      message
        logger.i(string.format("  [%s] %s", method_name, formatted_message))
    end
end

local function alert(message) hs.alert("🐀 " .. message) end

function copy_table(t)
    local copy = {}
    for k, v in pairs(t) do copy[k] = v end
    return copy
end

function obj:newRange(range)
    if #self.ranges == 0 or self.ranges[#self.ranges] ~= range then
        table.insert(self.ranges, range)
        self.range_index = #self.ranges
    end
end

function obj:init()
    self.logger = hs.logger.new("EasyMove", "debug")
    local info = get_info_logger(self.logger, "init")
    info("Starting EasyMove spoon")
    self.keyEventTap = hs.eventtap.new({hs.eventtap.event.types.keyDown},
                                       function(event)
        return self:eventHandler(event)
    end)
    self.ranges = {}
    local range = {min_x = 0, max_x = 1, min_y = 0, max_y = 1}
    self:newRange(range)
    self.screen = nil
    self.frame = nil
    self.canvas = nil
    self.update = false
    self.color = {red = 1, green = 1 / 4, blue = 1 / 4}
    function draw()
        if self.update then
            self.update = false
            self:draw()
        end
    end
    self.drawTimer = hs.timer.new(0.1, draw, true)
end

function obj:draw()
    range = self.ranges[self.range_index]
    self.canvas:topLeft({
        x = range.min_x * self.frame._w,
        y = range.min_y * self.frame._h
    })
    self.canvas:size({
        w = self.frame.w * (range.max_x - range.min_x),
        h = self.frame.h * (range.max_y - range.min_y)
    })
end

function obj:start()
    local screen = hs.mouse.getCurrentScreen()
    if screen ~= self.screen then
        self.screen = screen
        self.frame = self.screen:frame()
        self.canvas = CANVAS.new {
            x = 0,
            y = 0,
            h = self.frame._h,
            w = self.frame._w
        }
        self.canvas:replaceElements({
            action = "stroke",
            strokeColor = self.color,
            coordinates = {{x = "0", y = "0.5"}, {x = "1", y = "0.5"}},
            type = "segments",
            strokeWidth = 2
        }, {
            action = "stroke",
            strokeColor = self.color,
            coordinates = {{x = "0.5", y = "0"}, {x = "0.5", y = "1"}},
            type = "segments",
            strokeWidth = 2
        })
    end
    range = {min_x = 0, max_x = 1, min_y = 0, max_y = 1}
    self:newRange(range)
    self.keyEventTap:start()
    self:draw()
    self.canvas:show()
    self.drawTimer:start()
end

function obj:stop()
    local info = get_info_logger(self.logger, "stop")
    info("stopping drawer")
    self.keyEventTap:stop()
    self.drawTimer:stop()
    self.canvas:hide()
end

function obj:move()
    local range = self.ranges[self.range_index]
    local point = {
        x = self.frame._w * (range.min_x + range.max_x) / 2,
        y = self.frame._h * (range.min_y + range.max_y) / 2
    }
    hs.mouse.setRelativePosition(point, self.screen)
end

function obj:click(button, point, count)
    count = count or 1
    point = point or hs.mouse.getRelativePosition()

    local clickState = hs.eventtap.event.properties.mouseEventClickState
    local delay = 0.1

    local function recursive_task(n)
        if n <= count then
            hs.eventtap.event.newMouseEvent(
                hs.eventtap.event.types["leftMouseDown"], point):setProperty(
                clickState, n):post()
            hs.eventtap.event.newMouseEvent(
                hs.eventtap.event.types["leftMouseUp"], point):setProperty(
                clickState, n):post()
            if n < count then
                hs.timer.doAfter(delay, function()
                    recursive_task(n + 1)
                end)
            end
        end
    end
    return recursive_task(1)
end

function obj:moveAndClick(button, count)
    button = button or 0
    count = count or 1
    local info = get_info_logger(self.logger, "moveAndClick")
    local range = self.ranges[self.range_index]
    local point = {
        x = self.frame._w * (range.min_x + range.max_x) / 2,
        y = self.frame._h * (range.min_y + range.max_y) / 2
    }
    if button == 0 then
        self:click(0, point, count)
    elseif button == 1 then
        hs.eventtap.middleClick(point)
    elseif button == 2 then
        hs.eventtap.rightClick(point)
    else
        info("calling otherClick(%s, %s)", point, button)
        hs.eventtap.otherClick(point, nil, button)
    end
end

function obj:eventHandler(event)
    local info = get_info_logger(self.logger, "eventHandler")
    local character = string.lower(event:getCharacters())
    local uppercase = event:getFlags()["shift"]
    if string.find("hljk", character, 1, true) then
        old_range = self.ranges[self.range_index]
        new_range = copy_table(old_range)
        if uppercase then
            info("move command: %s", character)
            local width = old_range.max_x - old_range.min_x
            local height = old_range.max_y - old_range.min_y
            if character == "h" then -- left
                new_range.min_x = math.max(old_range.min_x - width, 0)
                new_range.max_x = new_range.min_x + width
            elseif character == "l" then -- right
                new_range.max_x = math.min(old_range.max_x + width, 1)
                new_range.min_x = new_range.max_x - width
            elseif character == "j" then -- down
                new_range.max_y = math.min(old_range.max_y + height, 1)
                new_range.min_y = new_range.max_y - height
            elseif character == "k" then -- up
                new_range.min_y = math.max(old_range.min_y - height, 0)
                new_range.max_y = new_range.min_y + height
            end
        else
            info("cut command: %s", character)
            if character == "h" then -- left
                new_range.max_x = (old_range.min_x + old_range.max_x) / 2
            elseif character == "l" then -- right
                new_range.min_x = (old_range.min_x + old_range.max_x) / 2
            elseif character == "j" then -- down
                new_range.min_y = (old_range.min_y + old_range.max_y) / 2
            elseif character == "k" then -- up
                new_range.max_y = (old_range.min_y + old_range.max_y) / 2
            end
        end
        self:newRange(new_range)
        self.update = true
    elseif character == "u" then -- undo / redo
        info("undo command")
        if not uppercase then -- undo
            self.range_index = math.max(self.range_index - 1, 1)
        else -- redo
            self.range_index = math.min(self.range_index + 1, #self.ranges)
        end
        self.update = true
    elseif string.find("cmr !\"·$%", character, 1, true) then
        info("command character: %s", character)
        if not uppercase then self:stop() end
        if character == "c" then -- move and click
            self:moveAndClick(0)
        elseif character == "m" then -- move and middle click
            self:moveAndClick(1)
        elseif character == "r" then -- move and right click
            self:moveAndClick(2)
        elseif character == " " then -- move
            self:move()
        elseif character == "!" then -- move
            self:moveAndClick(0, 1)
        elseif character == "\"" then -- move
            self:moveAndClick(0, 2)
        elseif character == "·" then -- move
            self:moveAndClick(0, 3)
        elseif character == "$" then -- move
            self:moveAndClick(0, 4)
        elseif character == "%" then -- move
            self:moveAndClick(0, 5)
        end
    else
        info("character not recognized: %s", character)
        self:stop()
    end
    return true
end

function obj:bindHotkeys(mapping)
    local actions = {addSplit = hs.fnutils.partial(self.addSplit, self)}
    hs.spoons.bindHotkeysToSpec(actions, mapping)
end

return obj
