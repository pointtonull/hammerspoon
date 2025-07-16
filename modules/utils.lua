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

return {}
