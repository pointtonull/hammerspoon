defaultStyle = {
    strokeWidth = 2,
    strokeColor = {white = 1, alpha = 1},
    fillColor = {white = 0, alpha = 0.75},
    textColor = {white = 1, alpha = 1},
    textSize = 27,
    radius = 27,
    atScreenEdge = 3,
    fadeInDuration = 0,
    fadeOutDuration = 0,
    padding = 20,
}

Status = {}
Status.__index = Status

-- Constructor
function Status.new(...)
    -- local self = setmetatable({}, Status)
    local self = setmetatable(Status, {
        __call = function(_, ...) return Status:show(...) end,
        __gc = Status.destroy
    })
    self.name = nil
    self.style = defaultStyle
    self.duration = 20
    self.uuid = nil
    for i, v in ipairs(table.pack(...)) do
        if type(v) == "string" then
            self.name = v
        elseif type(v) == "number" then
            self.duration = v
        elseif type(v) == "table" then
            self.style = v
        else
            error("unexpected type " .. type(v) .. " found for argument " ..
                      tostring(i + 1), 2)
        end
    end
    print("new: " .. self.name)
    print(self)
    return self
end

-- Show method
function Status:show(message)
    if self.uuid then hs.alert.closeSpecific(self.uuid) end
    if self.name then message = self.name .. ": " .. message end
    print(message)
    self.uuid = hs.alert.show(message, self.duration, self.style)
end

function Status:destroy()
    print("destroyer has been called")
    if self.uuid then
        hs.timer.doAfter(3, function()
            hs.alert.closeSpecific(self.uuid)
        end)
    end
end

setmetatable(Status, {__call = function(_, ...) return Status.new(...) end})

-- return setmetatable(module, { __call = function(_, ...) return Status(...) end })

return Status
