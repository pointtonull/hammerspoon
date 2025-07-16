--- === Split ===
local obj = {}
-- name = "Split",
-- version = "1.0",
-- author = "Evan Travers <evantravers@gmail.com>",
-- license = "MIT <https://opensource.org/licenses/MIT>",
-- homepage = "https://github.com/evantravers/split.spoon",
obj.__index = obj

--- Split:split() -> table
--- Method
--- Presents an hs.chooser to pick a window to split your monitor with

local function get_info_logger(logger, method_name)
    -- logger.i(string.format("[%s]", method_name))
    return function(message, ...)
        local args = {...}
        local formatted_message = #args > 0 and
                                      string.format(message, table.unpack(args)) or
                                      message
        -- logger.i(string.format("  [%s] %s", method_name, formatted_message))
    end
end

function obj:status(message)
    local info = get_info_logger(self.logger, "status")
    hs.alert(message, {atScreenEdge = 2})
    local message = "🪟 " .. message
    info(message)
end

function obj:alert(message)
    local info = get_info_logger(self.logger, "alert")
    local message = "🪟 " .. message
    info(message)
    hs.alert(message)
end

function obj:init()
    self.logger = hs.logger.new("Split", "debug")
    local info = get_info_logger(self.logger, "init")
    self.selected = 0

    self.db = hs.sqlite3.open(os.getenv("HOME") .. "/.config/split/data.db")
    local query = [[
            CREATE TABLE IF NOT EXISTS triplets (
                id INTEGER PRIMARY KEY,
                selected_at TEXT DEFAULT CURRENT_TIMESTAMP,
                space_id TEXT,
                focused_app TEXT,
                focused_id TEXT,
                focused_title TEXT,
                other_app TEXT,
                other_id TEXT,
                other_title TEXT
            );
    ]]
    local res = self.db:exec(query)
    if res == 0 then
        info("table initialised")
    else
        error("Initializing DB: errono: " .. res .. ", for query: `" .. query ..
                  "`")
    end

    self.splits = {}
    local query = [[
        SELECT id,
            space_id,
            focused_app,
            focused_id,
            focused_title,
            other_app,
            other_id,
            other_title
        FROM triplets
        ORDER BY selected_at DESC;
    ]]
    local seen = {}
    local to_delete = {}
    local currently_focused = safe_get_focused_window()
    function parser(_udata, cols, values, names)
        local id, space_id, focused_app, focused_id, focused_title, other_app, other_id, other_title = table.unpack(values)
        local key = table.concat({focused_id, other_id}, ", ")

        if seen[key] then
            table.insert(to_delete, id)
            return 0
        else
            seen[key] = true
        end
        space_id = tonumber(space_id)
        focused_id = tonumber(focused_id)
        other_id = tonumber(other_id)
        info("focused_app: %s, focused_id: %s, focused_title: %s", focused_app, focused_id, focused_title)
        info("other_app: %s, other_id: %s, other_title: %s", other_app, other_id, other_title)
        local split = {
            -- focused = focused,
            focused_app = focused_app,
            focused_id = focused_id,
            focused_title = focused_title,
            -- other = other,
            other_app = other_app,
            other_id = other_id,
            other_title = other_title,
            space_id = space_id
        }
        table.insert(self.splits, split)
        return 0
    end
    local res = self.db:exec(query, parser)
    if res ~= 0 then
        error("Loading triplets failed: errono: " .. res .. ", for query: `" ..
                  query .. "`")
    end

    info("to_delete: %s", hs.inspect(to_delete))
    if #to_delete > 0 then
        local query = string.format([[
            DELETE FROM triplets
            WHERE id IN (%s);
        ]], table.concat(to_delete, ", "))
        local res = self.db:exec(query)
        if res ~= 0 then
            error("Cleaning triplets failed: errono: " .. res ..
                      ", for query: `" .. query .. "`")
        end
    end

    self.chooser = hs.chooser.new(function(other)
        local info = get_info_logger(self.logger, "chooser_handler")
        info("other: %s", other)
        if other ~= nil then
            local focused = safe_get_focused_window()
            other = other.window
            split = {
                space_id = hs.spaces.focusedSpace(),
                focused = focused,
                focused_app = focused:application():name(),
                focused_id = focused:id(),
                focused_title = focused:title(),
                other = other,
                other_app = other:application():name(),
                other_id = other:id(),
                other_title = other:title()
            }
            info("new split: %s", split)
            table.insert(self.splits, split)
            self.selected = #self.splits - 1

            query = string.format([[
                    INSERT INTO triplets (space_id, focused_app, focused_id, focused_title, other_app, other_id, other_title)
                    VALUES ('%s', '%s', '%s', '%s', '%s', '%s', '%s');
                ]], split.space_id, split.focused_app, split.focused_id,
                                  split.focused_title, split.other_app,
                                  split.other_id, split.other_title)
            local res = self.db:exec(query)
            if res == 0 then
                info("triplets updated")
            else
                error("Updating triplets failed: errono: " .. res ..
                          ", for query: `" .. query .. "`")
            end
            self:restoreSplit()
        end
    end)
    self.chooser:placeholderText("Choose window for split.")
    self.chooser:searchSubText(true)
end

function obj:addSplit(all_windows)
    local info = get_info_logger(self.logger,
                                 "addSplit(" .. type(all_windows) .. ")")
    if all_windows == nil then
        info("re-running with all_windows")
        return async_get_all_windows(function(ws) self:addSplit(ws) end)
    else
        info("using existing all_windows: %s", all_windows)
    end
    local focused_window = safe_get_focused_window()
    local windows_options = hs.fnutils.map(all_windows, function(win)
        if win ~= focused_window then
            local image
            local bundle_id = win:application():bundleID()
            if bundle_id ~= nil then
                image = hs.image.imageFromAppBundle(bundle_id)
            else
                info("bundle_id is nil?: %s", type(bundle_id))
                image = nil
            end
            return {
                text = win:title(),
                subText = win:application():title(),
                image = image,
                window = win
            }
        end
    end)
    self.chooser:choices(windows_options)
    self.chooser:show()
end

function obj:completeSplit(callback, all_windows)
    local info = get_info_logger(
        self.logger,
        "completeSplit(" .. type(callback) .. ", " .. type(all_windows) .. ")"
    )
    local split = self:getCurrentSplit()
    if not (split.other and split.other:isWindow()) then
        split.other = find_window({
            app = split.other_app,
            window_id = split.other_id,
            title = split.other_title
        })
    end
    if not (split.focused and split.focused:isWindow()) then
        split.focused = find_window({
            app = split.focused_app,
            window_id = split.focused_id,
            title = split.focused_title
        })
    end
    if not (split.other and split.focused) then
        if all_windows == nil then
            return async_get_all_windows(function(ws) self:completeSplit(callback, ws) end)
        else
            split.focused = get_window(split.focused_id, all_windows)
            split.other = get_window(split.other_id, all_windows)
        end
    end
    if split.other and split.focused then
        callback(split)
    else
        self:alert("Could not recover split windows 😔")
        self:deleteCurrentSplit(true)
    end
end

function obj:selectNextSplit()
    local info = get_info_logger(self.logger, "selectNextSplit")

    -- fail if there are not splits
    if #self.splits == 0 then
        self:alert("No splits to be selected.")
        error("No splits to be selected.")
    end

    -- if currently focused window in current split rotate splits
    local cwin_id = safe_get_focused_window():id()
    local last_split = self:getCurrentSplit()
    if cwin_id == last_split.focused_id or cwin_id == last_split.other_id then
        self.selected = (self.selected + 1) % #self.splits
        info("select next split: %d", self.selected)
    end

    -- else, it'll just restore the last used split
    return self:restoreSplit()
end

function obj:getCurrentSplit()
    self.selected = self.selected % #self.splits
    local selected = self.splits[self.selected + 1]
    return selected
end

function obj:selectNextWindow()
    local info = get_info_logger(self.logger, "selectNextWindow")
    if #self.splits == 0 then
        self:alert("No splits to be selected.")
        error("No splits to be selected.")
    end

    local pair

    --  if currently focused window is in last restored split
    local current_window_id = safe_get_focused_window():id()
    info("current_window_id: %d", current_window_id)

    local selected = self:getCurrentSplit()
    local pair = (current_window_id == selected.focused_id and selected.other or
                     current_window_id == selected.other_id and selected.focused)

    -- else search for first matching selected in this space
    if not pair then
        local current_space_id = hs.spaces.focusedSpace()
        for _, _s in ipairs(self.splits) do
            if _s.space_id == current_space then
                pair = (current_window_id == _s.focused_id and _s.other or
                           current_window_id == _s.other_id and _s.focused)
                break
            end
        end
    end

    -- else search for first matching selected in any space
    if not pair then
        for _, _s in ipairs(self.splits) do
            pair = (current_window_id == _s.focused_id and _s.other or
                       current_window_id == _s.other_id and _s.focused)
            break
        end
    end

    -- try to make effective the selection
    if pair then
        info("found pair: %s", pair)
        self:status(pair:title())
        if self:safeWindowFocus(pair) then
            show_focused_window()
            return true
        end
    else
        -- else give up and just restore MRU selected
        self:restoreSplit()
    end
end

function obj:assureFocused()
    local info = get_info_logger(self.logger, "assureFocused")

    --  if focused in any split -> do nothing
    local current_window_id = safe_get_focused_window():id()
    for _, _s in ipairs(self.splits) do
        if current_window_id == _s.focused_id or current_window_id ==
            _s.other_id then return true end
    end
    --  else restore MRU split
    return self:restoreSplit()
end

function obj:restoreSplit(selected)
    local info = get_info_logger(self.logger, "restoreSplit(" .. type(selected) .. ")")
    if #self.splits == 0 then
        self:alert("No splits to be restored.")
        error("no splits to be restored")
    elseif not selected then
        return self:completeSplit(function(selected) self:restoreSplit(selected) end)
    end

    local screen = hs.screen.mainScreen()
    local vertical = screen:frame()._h > screen:frame()._w
    local width
    if screen:name() == "Built-in Retina Display" then
        width = 3 / 4
    else
        width = 1 / 2
    end

    local focused_frame = selected.focused:frame()
    local other_frame = selected.other:frame()
    local screen_frame = screen:frame()

    if vertical then
        if 0 < focused_frame._Y or focused_frame._w < screen_frame._w then
            info("Moving focused window to top")
                hs.layout.apply({
                    {
                        nil, selected.focused, screen,
                        hs.geometry.unitrect(0, 0, 1, 1/2), 0, 0
                    }
                })
        else
            selected.other:focus()
        end

        if other_frame._y + other_frame._h < screen_frame._h or other_frame._w <
            screen_frame._w then
            info("Moving other window to bottom")
            hs.layout.apply({
                {
                    nil, selected.other, screen,
                    hs.geometry.unitrect(0, 1/2, 1, 1/2), 0, 0
                }
            })
        else
            selected.focused:focus()
        end
    else
        if 0 < focused_frame._x or focused_frame._h < screen_frame._h then
            info("Moving focused window to left")
                hs.layout.apply({
                    {
                        nil, selected.focused, screen,
                        hs.geometry.unitrect(0, 0, width, 1), 0, 0
                    }
                })
        else
            selected.other:focus()
        end

        if other_frame._x + other_frame._w + 1 < screen_frame._w or other_frame._h + 1 <
            screen_frame._h then
            info("Moving other window to right")
            hs.layout.apply({
                {
                    nil, selected.other, screen,
                    hs.geometry.unitrect(1 - width, 0, width, 1), 0, 0
                }
            })
        else
            selected.focused:focus()
        end
    end

    local message = table.concat(hs.fnutils.imap(spoon.Split.splits,
                                                 function(split)
        local leftTitle = string.gmatch(split.focused_title, "[^\r\n]+")() or
                              ""
        leftTitle = truncate(leftTitle, {maxLength = 20, leftPadd = 20})
        local rightTitle = string.gmatch(split.other_title, "[^\r\n]+")() or
                               ""
        rightTitle = truncate(rightTitle, {maxLength = 20})
        local join = split == selected and " 🔸 " or " 🔹 "
        local line = leftTitle .. join .. rightTitle
        return line
    end), "\n")
    self:status(message)

    return show_focused_window()
end

function obj:deleteCurrentSplit(force)
    local info = get_info_logger(self.logger, "deleteCurrentSplit")
    force = force or false
    info("force: %s", force)

    if #self.splits == 0 then
        self:alert("No splits to be deleted.")
        info("No splits to deleted.")
        return false
    end

    if not force then
        local cwin_id = safe_get_focused_window():id()
        if cwin_id ~= self.splits[1].focused_id and cwin_id ~=
            self.splits[1].other_id then
            self:alert("No in any split")
            info("cwin_id: %s is not in current split, and force: %s", cwin_id,
                 force)
            return false
        end
    end

    self:alert("Deleting current split")
    local split = table.remove(self.splits, self.selected + 1)
    local selected = self:getCurrentSplit()
    local query = string.format([[
            DELETE FROM triplets
            WHERE space_id = '%s' AND focused_id = '%s' AND other_id = '%s';
        ]], split.space_id, split.focused_id, split.other_id)
    local res = self.db:exec(query)
    info("Query: %s, returned: %s", query, res)
    self:alert("Split deleted.")
    return res
end

function obj:safeWindowFocus(window)
    local info = get_info_logger(self.logger, "safeWindowFocus")
    info("window: %s", window)
    return safeWindowFocus(window)
end

function obj:bindHotkeys(mapping)
    local actions = {addSplit = hs.fnutils.partial(self.addSplit, self)}
    hs.spoons.bindHotkeysToSpec(actions, mapping)
end

return obj
