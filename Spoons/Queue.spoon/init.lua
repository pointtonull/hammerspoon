--- === Queue ===

local obj = {}
-- name = "Queue",
-- version = "1.0",
-- author = "Carlos Cabrera <point.to@gmail.com>",
-- license = "MIT <https://opensource.org/licenses/MIT>",
-- homepage = "https://github.com/pointtonull/queue.spoon",
obj.__index = obj

--- Queue:queue() -> table
--- Method
--- Manages a queue database.

local function get_info_logger(logger, method_name)
    logger.i(string.format("[%s]", method_name))
    return function (message, ...)
        local args = {...}
        local formatted_message = #args > 0 and string.format(message, table.unpack(args)) or message
        logger.i(string.format("  [%s] %s", method_name, formatted_message))
    end
end

local function alert(message)
    hs.alert("⇶ " .. message)
end

function obj:init()
    self.logger = hs.logger.new("Queue", "debug")
    local info = get_info_logger(self.logger, "init")

    self.db = hs.sqlite3.open(os.getenv("HOME") .. "/.config/queue/data.db")
    local query = [[

        CREATE TABLE IF NOT EXISTS queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content_url TEXT,
            added_time DATETIME DEFAULT CURRENT_TIMESTAMP,
            priority REAL DEFAULT 0,
            FOREIGN KEY(content_url) REFERENCES content(url)
        );

        CREATE TABLE IF NOT EXISTS content (
            url TEXT PRIMARY KEY,
            title TEXT,
            app_name TEXT,
            fetch_time DATETIME DEFAULT CURRENT_TIMESTAMP,
            last_priority REAL DEFAULT 0
        );

        CREATE INDEX IF NOT EXISTS queue_priority_index ON queue (priority);

        CREATE INDEX IF NOT EXISTS queue_priority_time_index ON queue (priority DESC, added_time ASC);

    ]]
    local res = self.db:exec(query)
    if res == 0 then
        info("table initialised")
    else
        error("Initializing DB: errono: " .. res .. ", for query: `" .. query .. "`")
    end
end

function obj:openBookmarks(amount)
    local info = get_info_logger(self.logger, "openBookmarks")
    amount = amount or 5
    info("querying %d bookmarks", amount)
    local query = string.format([[
        SELECT id, content_url
        FROM queue
        ORDER BY priority DESC, added_time ASC
        LIMIT %d
        ;
    ]], amount)
    local to_delete = {}
    local to_open = {}
    function parser(_udata, cols, values, names)
        local id, content_url = table.unpack(values)
        info("url: %s", content_url)
        table.insert(to_delete, id)
        table.insert(to_open, content_url)
        return 0
    end
    local res = self.db:exec(query, parser)
    if res ~= 0 then
        error("Loading queue failed: errono: " .. res .. ", for query: `" .. query .. "`")
    end
    delete = true
    function finalizer(err)
        if err then
            alert("Error happened:", err)
        end
    end
    for _, url in ipairs(to_open) do
        local success = xpcall(function() hs.urlevent.openURL(url) end, finalizer)
        if not success then
            info("could not open url %s", url)
        end
    end
    if delete then
        info("to_delete: %s", hs.inspect(to_delete))
        local ids_str = table.concat(to_delete, ",")
        local delete_query = string.format("DELETE FROM queue WHERE id IN (%s);", ids_str)
        local res = self.db:exec(delete_query)
    else
        info("not deleting since some urls were not open")
    end
end

function obj:saveBookmark()
    local info = get_info_logger(self.logger, "saveBookmark")

    local focused_window = hs.window.focusedWindow()
    local app_name = focused_window:application():name()

    if app_name == "Firefox" then
        local title = focused_window:title()
        input_pause(0.2)
        hs.eventtap.keyStroke(HYPER, "l")
        hs.eventtap.keyStroke(HYPER, "c")
        input_pause()
        local url = hs.pasteboard.getContents()
        if url:match("^http") then
            info("app: %s, title: %s, url: %s", app_name, title, url)
            local result = self:addRecord(app_name, title, url)
            if result then
                hs.eventtap.keyStroke(HYPER, "w")
            else
                info("Failed to insert record")
            end
        else
            info("not recognized url: %s", url)
        end
    else
        info("app: %s is not a recognized browser", app_name)
    end
end

function obj:addRecord(app_name, title, url)
    local info = get_info_logger(self.logger, "addRecord")
    info("%s, %s, %s", app_name, title, url)
    local priority = 0

    local content_query = string.format([[
        INSERT OR IGNORE INTO content (url, title, app_name)
        VALUES ('%s', '%s', '%s')]], url, title, app_name)
    local content_result = self.db:execute(content_query)

    local queue_query = string.format([[
        INSERT INTO queue (content_url, priority)
        VALUES ('%s', %d)]], url, priority)
    local queue_result = self.db:execute(queue_query)
    return queue_result
end

function obj:bindHotkeys(mapping)
    local actions = {
        getBookmarks = hs.fnutils.partial(self.getBookmarks, self)
    }
    hs.spoons.bindHotkeysToSpec(actions, mapping)
end

return obj
