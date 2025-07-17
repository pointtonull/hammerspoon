-- Utility functions for logging and timing

--- get_info_logger(method_name[, log_file]) -> function
-- Returns a logging function that prefixes messages with the given method name.
-- If log_file is provided, logs are appended to that file, otherwise uses the global LOGGER.
function get_info_logger(method_name, log_file)
    local use_file = type(log_file) == "string"
    return function(message, ...)
        local formatted = (#{...} > 0) and string.format(message, ...) or message
        if use_file then
            local f, err = io.open(log_file, "a")
            if f then
                f:write(string.format("%s [%s] %s\n",
                                     os.date("%Y-%m-%d %H:%M:%S"),
                                     method_name,
                                     formatted))
                f:close()
            end
        elseif LOGGER then
            LOGGER.i(string.format("[%s] %s", method_name, formatted))
        end
    end
end

--- INFO_TIMER(method_name[, log_file])
-- Logs a timer event for the given method, recording a timestamp.
function INFO_TIMER(method_name, log_file)
    local info = get_info_logger(method_name, log_file)
    info("timer event at %s", os.date("%Y-%m-%d %H:%M:%S"))
end

--- Truncate a string to a maximum length with optional padding and ellipsis
-- @param str [string] the string to truncate
-- @param options [table] optional settings: maxLength (default 80), leftPadd (default 0), elipsis (default "..")
function truncate(str, options)
    options = options or {}
    local maxLength = options.maxLength or 80
    local leftPadd = options.leftPadd or 0
    local elipsis = options.elipsis or ".."
    if #str > maxLength then
        return str:sub(1, maxLength - #elipsis) .. elipsis
    elseif #str < leftPadd then
        return string.rep(" ", leftPadd - #str) .. str
    end
    return str
end

--- Inspect a table or userdata object, printing its contents.
-- @param obj [table|userdata] the object to inspect
-- @param options [table] optional settings: indent (default 0), recurse (default true), limit (optional), root (default "root")
function inspect(obj, options)
    options = options or {}
    local indent = options.indent or 0
    local root = options.root or "root"
    local recurse = options.recurse == nil and true or false
    local limit = options.limit
    local tmp = {}
    local objType = type(obj)
    local tbl = nil
    local function lprint(fmt, ...)
        hs.printf(string.rep(" ", indent) .. fmt, ...)
    end
    if objType == "userdata" then
        tbl = getmetatable(obj)
        objType = string.format("%s %s", objType, obj)
        recurse = false
    elseif objType == "table" then
        tbl = obj
    else
        lprint("%s: <%s> %s", root, objType, hs.inspect(obj))
        return
    end
    lprint("%s: <%s>", root, objType)
    for k, v in pairs(tbl) do
        table.insert(tmp, {key = k, value = v})
    end
    table.sort(tmp, function(a, b) return tostring(a.key) < tostring(b.key) end)
    for i, pair in ipairs(tmp) do
        if limit and i > limit then
            lprint("    ..")
            break
        end
        if recurse then
            inspect(pair.value, {indent = indent + 4, limit = limit and (limit // 2) or nil, root = pair.key})
        else
            lprint("    %s: %s", pair.key, pair.value)
        end
    end
end

--- Check approximate equality between two numbers.
-- @param a [number]
-- @param b [number]
-- @param epsilon [number] tolerance (default 0.0001)
function nearly_equal(a, b, epsilon)
    epsilon = epsilon or 0.0001
    return math.abs(a - b) < epsilon
end

--- Wait until a condition is met, then invoke callbacks.
-- @param cond_fn [function] predicate returning truthy when the condition is satisfied
-- @param on_success [function] function to call once cond_fn() is truthy
-- @param on_failure [function] optional, function to call if timeout is reached before success
-- @param timeout [number] optional timeout in seconds (default 5)
-- @param interval [number] optional polling interval in seconds (default 0.1)
function wait_until(cond_fn, on_success, on_failure, timeout, interval)
    timeout = timeout or 5
    interval = interval or 0.1
    local start = hs.timer.secondsSinceEpoch()
    local timer
    timer = hs.timer.doEvery(interval, function()
        if cond_fn() then
            timer:stop()
            if on_success then on_success() end
        elseif hs.timer.secondsSinceEpoch() - start >= timeout then
            timer:stop()
            if on_failure then on_failure() end
        end
    end)
end

return {}
