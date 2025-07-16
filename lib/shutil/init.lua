if shutil then return end

shutil = {} -- create a table to represent the module

function shutil.shellGet(command, silent)
    silent = silent or false
    if silent then
        sh_env = "source ~/.profile; "
    else
        sh_env = "source ~/.profile; s.log "
    end
    wrapped = sh_env .. command
    handler = io.popen(wrapped)
    result = handler:read("*a")
    handler:close()
    result = string.gsub(result, '\n\n', '\n')
    result = string.gsub(result, '\r\r', '\n')
    -- result = string.gsub(result, '\r\n\r\n', '\n')
    result = result:gsub("[ \\n]*$", "")
    return result
end

function shutil.shellDo(command, options)
    options = options or {}
    local py_env = options.py_env
    local sh_env = "source ~/.profile; "
    if py_env then
        sh_env = sh_env .. "source ~/.virtualenvs/p3/bin/activate; "
    end
    wrapped = sh_env .. command
    os.execute(wrapped)
end

function shutil.log(message, app)
    local app = app or "hammerspoon"
    local sh_env = "source ~/.profile; "
    local command = 'f.messages ' .. app .. '<< "_ECHO"\n' .. message .. "\n_ECHO"
    local wrapped = sh_env .. command
    os.execute(wrapped)
end

return shutil
