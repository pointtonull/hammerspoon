--- === FastModal ===

local obj = {}
-- name = "FastModal",
-- version = "1.0",
-- author = "Carlos Cabrera <point.to@gmail.com>",
-- license = "MIT <https://opensource.org/licenses/MIT>",
-- homepage = "https://github.com/pointtonull/FastModal.spoon",
obj.__index = obj

--- FastModal:start() -> table
--- Method
--- Starts the selection bisect

local function get_info_logger(logger, method_name)
    logger.i(string.format("[%s]", method_name))
    return function (message, ...)
        local args = {...}
        local formatted_message = #args > 0 and string.format(message, table.unpack(args)) or message
        logger.i(string.format("  [%s] %s", method_name, formatted_message))
    end
end

local function alert(message)
    hs.alert("🎹 " .. message)
end

function starts_with(str, start)
    return str:sub(1, #start) == start
end

function deep_copy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deep_copy(orig_key)] = deep_copy(orig_value)
        end
        setmetatable(copy, deep_copy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function obj:newRange(range)
    if #self.ranges == 0 or self.ranges[#self.ranges] ~= range then
        table.insert(self.ranges, range)
        self.range_index = #self.ranges
    end
end

function obj:init()
    self.logger = hs.logger.new("FastModal", "debug")
    local info = get_info_logger(self.logger, "init")
    info("Starting FastModal spoon")

    self.keyEventTap = hs.eventtap.new(
        {hs.eventtap.event.types.keyDown},
        function (event) return self:eventHandler(event) end
    )
    self.screen = nil
    self.frame = nil
    self.canvas = nil
    self.update = false
    self.help_text = ""
    self.mappings = {}
    function draw()
        if self.update then
            self.update = false
            self:draw()
        end
    end
    self.drawTimer = hs.timer.new(0.1, draw, true)
end

function obj:draw()
    local info = get_info_logger(self.logger, "draw")
    local styled_search_string = hs.styledtext.new(self.search_string,
        {
            font = {
                name = "Monaco",
                size = 80,
            },
            strokeWidth = -3,
            strokeColor = { white = 0},
            color = { white = 1},
            paragraphStyle = {
                alignment = "center",
            },
        }
    )
    local search_string_size = self.canvas:minimumTextSize(styled_search_string)
    local styled_help = hs.styledtext.new(self.help_text,
        {
            font = {
                name = "Monaco",
                size = 60,
            },
            strokeWidth = -3,
            strokeColor = { white = 0},
            color = { white = 1},
            paragraphStyle = {
                alignment = "left",
            },
        }
    )
    local help_size = self.canvas:minimumTextSize(styled_help)
    self.canvas:replaceElements(
        {
            type = "text",
            text = styled_search_string,
            frame = {
                x=self.screen_frame._w // 2 - search_string_size.w // 2,
                y=self.screen_frame._h // 2 - search_string_size.h // 2,
                w=search_string_size.w,
                h=search_string_size.h,
            }
        },
        {
            type = "text",
            text = styled_help,
            frame = {
                x=self.screen_frame._w // 2 - help_size.w // 2,
                y=self.screen_frame._h - help_size.h,
                w=help_size.w,
                h=help_size.h,
            }
        }
    )
end

function obj:filter_matches()
    if self.search_string == "" then
        return
    end
    for key, _ in pairs(self.partial_mappings) do
        if not starts_with(key, self.search_string) then
            self.partial_mappings[key] = nil
        end
    end
end

function obj:start()
    local info = get_info_logger(self.logger, "start")
    self.search_string = ""
    self.partial_mappings = deep_copy(self.mappings)
    self:filter_matches()
    self:parse_help()
    self.screen_frame = hs.screen.mainScreen():fullFrame()
    local high = 20
    frame = {
        x = 0,
        y = 0,
        w = self.screen_frame.w,
        h = self.screen_frame.h,
    }
    self.canvas = CANVAS.new(frame)
        :behavior(hs.canvas.windowBehaviors["canJoinAllSpaces"])
        :alpha(0.75)
    self.keyEventTap:start()
    self:draw()
    self.canvas:show()
    self.drawTimer:start()
end

function obj:parse_help()
    local info = get_info_logger(self.logger, "parse_help")
    table.sort(self.partial_mappings)
    local help_text = ""
    for key, value in pairs(self.partial_mappings) do
        local name = value[1]
        info("self.partial_mappings %s: %s", key, name)
        local content = value[2]
        local help_entry = string.format("%s -> %s", key, name)
        if type(content) == "table" then
            help_entry = help_entry .. ".."
        else
            info("type not recognized: %s", type(content))
        end
        help_text = help_text .. "\n" .. help_entry
    end
    self.help_text = help_text:sub(1, -1)
end

function obj:stop()
    self.keyEventTap:stop()
    local info = get_info_logger(self.logger, "stop")
    info("stopping drawer")
    self.canvas:hide()
    hs.timer.doAfter(2, function() self.drawTimer:stop() end)
end

function obj:eventHandler(event)
    local info = get_info_logger(self.logger, "eventHandler")
    local character = event:getCharacters()
    self.search_string = self.search_string .. character
    info("search_string: %s", self.search_string)
    if self.partial_mappings[self.search_string] then
        local value = self.partial_mappings[self.search_string]
        info("Found match: %s", value)
        content = value[2]
        if type(content) == "table" then
            info("it's a table")
            self.search_string = ""
            self.partial_mappings = content
            self:parse_help()
            self.update = true
        elseif type(content) == "function" then
            info("calling handler")
            self:stop()
            content()
        else
            info("it's not a table or a function: %s", content)
            self:stop()
        end
    else
        info("Filtering matches")
        self:filter_matches()
        self:parse_help()
        if next(self.partial_mappings) == nil then
            self:stop()
            info("not found search_string: %s", self.search_string)
        end
    end
    return true
end


function obj:bindHotkeys(mapping)
    local actions = {
        addSplit = hs.fnutils.partial(self.addSplit, self)
    }
    hs.spoons.bindHotkeysToSpec(actions, mapping)
end

return obj
