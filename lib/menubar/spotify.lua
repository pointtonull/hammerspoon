local obj = {}

obj.__index = obj
obj.name = "spotify"
obj.debug = true
obj.refreshInterval = 5.0
local stext = require("hs.styledtext").new

local dbg = function(...)
  if obj.debug then
    return _G.dbg(fmt(...), false)
  else
    return ""
  end
end

local api = hs.spotify

local function spotifyRunning() return hs.application.get("Spotify") end
-- local function spotifyRunning() return hs.application.get("Spotify") and hs.application.get("Spotify"):isRunning() end

local function isPaused()
  local state = api.getPlaybackState()
  return state == api.state_paused
end

local function getCurrent()
  local artist = nil
  local album = nil
  local track = nil
  if api then
    artist = api.getCurrentArtist()
    album = api.getCurrentAlbum()
    track = api.getCurrentTrack()
  end
  return artist, album, track
end

local function updateTitle()
  local artist, album, track = getCurrent()
  local titleInfo = ""
  if artist ~= nil then
    titleInfo = artist .. " - " .. track
  else
    titleInfo = track
  end
  return titleInfo
end

play_icon = hs.image.imageFromASCII(
[[
.......1.......
...............
...............
.....a.........
...............
...............
...............
1.........c...1
...............
...............
...............
.....b.........
...............
...............
.......1.......
]],
    {
        {fillColor={alpha=0}},
        {fillColor={alpha=1}},
    }
)

pause_icon = hs.image.imageFromASCII(
[[
.......1.......
...............
...............
.....a...b.....
...............
...............
...............
1.............1
...............
...............
...............
.....a...b.....
...............
...............
.......1.......
]],
    {
        {fillColor={alpha=0}},
        {fillColor={alpha=1}},
    }
)

transition_icon = hs.image.imageFromASCII(
[[
.......1.......
...............
...............
.......2.......
...............
...............
...............
1..2.......2..1
...............
...............
...............
.......2.......
...............
...............
.......1.......
]],
    {
        {fillColor={alpha=0}},
        {fillColor={alpha=0}},
    }
)

local function setMenubarTitle()
    local title = ""

    if spotifyRunning() then
        if not obj.menubar then
            obj.menubar = hs.menubar.new()
            obj.menubar:setClickCallback(function()
                obj.menubar:setIcon(transition_icon)
                spotify_control("next")
                setMenubarTitle()
            end)
        end
        title = updateTitle()
    end

    if obj.menubar then
        obj.menubar:setTitle(title)
        if isPaused() then
            obj.menubar:setIcon(pause_icon)
        else
            obj.menubar:setIcon(play_icon)
        end
    end
end

function obj:init()
    setMenubarTitle()
    return self
end

function obj:start()
    obj.updateTimer = hs.timer.new(obj.refreshInterval, function() setMenubarTitle() end):start()
    return self
end

function obj:stop()
    if obj.menubar then obj.menubar:delete() end
    if obj.updateTimer then obj.updateTimer:stop() end
    return self
end

return obj
