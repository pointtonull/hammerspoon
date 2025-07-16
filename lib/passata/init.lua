--- Passata Timer
--
-- Passata Timer is a highly customizable and power-user oriented fullscreen
-- timer for macOS, inspired by the Pomodoro Technique (tm). It offers an
-- enhanced timer experience with additional features to boost productivity.
--
-- Key Features:
--  * Persistence on Restart: The timer automatically resumes from the point
--    where it was interrupted when Hammerspoon is relaunched.
--  * Stats Database: Work sessions and activities are stored in an SQLite
--    database, allowing for data analysis and customization.
--  * Fullscreen Friendly: Passata displays a graphical representation of the
--    timer on the screen, eliminating the need to check the menubar.
--  * Nagging: During working hours (Monday to Friday, 7 AM to 7 PM), the timer
--    can toggle the screen to grayscale at regular intervals, providing a
--    gentle reminder to stay focused.
--  * Sound Effects: Ticking, ringing, and wind sounds provide audible feedback
--    to keep you engaged and aware of the timer's progress.
--  * Event Triggers: Customizable triggers are available for work session
--    completion, interruption, and task reminders, allowing you to integrate
--    Passata with other workflows.
--  * Distracting Hosts / Apps Blocking: With the help of triggers, you can
--    block distracting hosts or applications during focused work sessions.
--  * Activity Logging: Passata can log the title and application name of the
--    currently active window, along with the timer's state, at configurable
--    intervals for data analysis purposes.
--  * Users can disable nagging: PASSATA.nagg = false .
--
-- Future Features (planned for future updates):
--  * Customizable Nagging Function: Provide the ability to customize the
--    nagging behaviour.
--  * Activity Record Trigger: Implement a trigger that receives the current
--    activity as an argument and can prompt action based on idleness.
--
-- Example Usage:
--
--   PASSATA = require("lib.passata")
--   PASSATA:start()
--
--   -- Define a task to display the current task
--   function showTask()
--       text = "➡ "..todo:current()
--       hs.alert(text, 5)
--   end
--
--   -- Assign the showTask function to various triggers
--   -- you can assign several functions to each trigger
--   PASSATA.triggers.on_complete_work = { showTask }
--   PASSATA.triggers.on_start_work = { showTask }
--   PASSATA.triggers.on_complete_rest = { showTask }
--   PASSATA.triggers.on_task_reminder = { showTask }
--
--   -- Customize behaviour
--   PASSATA.logActivityInterval = 0  -- Disable activity logging
--   PASSATA.seconds_by_mode.working = 60 * 20  -- Set working mode duration to 20 minutes
--
--   -- Bind a hotkey to toggle the timer
--   PASSATA:bindHotkeys({toggle = {{"hyper"}, "F12"}})

WINDOWS = require("lib/passata/windows")

local obj = {}
obj.__index = obj

obj.name     = "Passata"
obj.version  = "1.0"
obj.author   = "pointtonull"
obj.homepage = "https://github.com/pointtonull/passata"
obj.license  = "MIT - https://opensource.org/licenses/MIT"

M_IDLE    = "idle"
M_WORKING = "working"
M_RESTING = "resting"


local function callAll(functions)
    for _, func in ipairs(functions) do
        local success, result = pcall(func)
        print(string.format("calling triggers: %s: %s", success, result))
    end
end

function obj:init()
    self.bar_pos = "bottom"
    self.high = 5

    self.nudge = true
    self.db = hs.sqlite3.open(os.getenv("HOME") .. "/.config/passata/data.db")
    self.mode = M_IDLE
    self.logger = hs.logger.new("Passata", "debug")

    self.age = 0
    self._report_is_fresh = false

    self.seconds_by_mode = {}
    self.seconds_by_mode[M_WORKING] = 25 * 60
    self.seconds_by_mode[M_RESTING] = 5 * 60
    self.seconds_by_mode[M_IDLE]    = 3 * 60  -- time before we start the nudgeing

    self.logActivityInterval = 60

    self.colors = {}
    self.colors[M_WORKING]           = { red   = 1.0, green = 0.0, blue = 0.0 }
    self.colors[M_RESTING]           = { red   = 0.0, green = 1.0, blue = 0.0 }
    self.colors["bar_background"]    = { alpha = 0.5, white = 0.5 }
    self.colors["report_background"] = { alpha = 0.0, white = 0.0 }
    self.colors["report_weekend"]    = { green = 0.8, blue  = 1.0 }
    self.colors["report_today"]      = { red   = 1.0, green = 0.5 }
    self.colors["report_good"]       = { green = 0.5 }
    self.colors["report_bad"]       =  { red   = 0.5 }

    local currentdir = debug.getinfo(1, 'S').source:match("@(.*/)")
    self.sounds = {
        tick  = hs.sound.getByFile(currentdir .. "tick.wav"),
        ring  = hs.sound.getByFile(currentdir .. "ring.wav"),
        wind  = hs.sound.getByFile(currentdir .. "wind.wav"),
        nudge = hs.sound.getByFile(currentdir .. "nudge.wav"),
        nagg  = hs.sound.getByFile(currentdir .. "nagg.wav"),
    }
    self.sounds.tick:loopSound(true)

    self.triggers = {
        on_complete_work      = {},
        on_complete_rest      = {},
        on_interrupt_work     = {},
        on_interrupt_rest     = {},
        on_start_work         = {},
        on_start_rest         = {},
        on_task_reminder      = {},
        on_nudge              = {},
        on_nag                = {},
        on_draw_report        = {},
    }
end

function obj:setup_canvases()
    local screen_frame = hs.screen.mainScreen():fullFrame()
    local progress_bar_frame

    if self.bar_pos == "bottom" then
        progress_bar_frame = {
            x = 0,
            y = screen_frame.h - self.high,
            w = screen_frame.w,
            h = self.high,
        }
    else
        progress_bar_frame = {
            x = 0,
            y = 0,
            w = screen_frame.w,
            h = self.high,
        }
    end

    self.canvas_progress_bar = hs.canvas.new(progress_bar_frame)
        :behavior(hs.canvas.windowBehaviors["canJoinAllSpaces"])
        :show()

    self.canvas_report = hs.canvas.new(screen_frame)
        :behavior(hs.canvas.windowBehaviors["canJoinAllSpaces"])
        :alpha(0.25)

end

function obj:start()

    self:setup_canvases()
    self.ticker = hs.timer.new(1, hs.fnutils.partial(self.tick, self))

    self.max_expected = self.max_expected or (6 * 60 * 60) / (self.seconds_by_mode["working"] + self.seconds_by_mode["resting"])

    if self.nudge then
        self.nudgeer = hs.timer.new(.5, function()
            if self.canvas_report:alpha() == 0.25 then
                self.canvas_report:alpha(0.5)
            else
                self.canvas_report:alpha(0.25)
            end
        end)
    end

    self.timer_report = hs.timer.doEvery(60*60, function()
        self._report_is_fresh = false end)

    self.watcher = hs.screen.watcher.new(function()
        local frame = hs.screen.mainScreen():fullFrame()
        if self.bar_pos == "bottom" then
            self.canvas_progress_bar:topLeft({x = 0, y = frame.h - self.high})
        else
            self.canvas_progress_bar:topLeft({x = 0, y = 0})
        end
        self.canvas_report:topLeft({x = 0, y = 0})
        self.canvas_report:size({w = frame.w, h = frame.h})
        self.canvas_progress_bar:size({w = frame.w, h = self.high})
    end)
    self.watcher:start()

    -- Create necessary tables in the SQLite database
    local query = [[
        CREATE TABLE IF NOT EXISTS works (
            id INTEGER PRIMARY KEY,
            started_at TEXT DEFAULT CURRENT_TIMESTAMP,
            status TEXT DEFAULT 'new'
        );
        CREATE TABLE IF NOT EXISTS activity (
            id INTEGER PRIMARY KEY,
            logged_at TEXT DEFAULT CURRENT_TIMESTAMP,
            type TEXT,
            value TEXT
        );
    ]]
    local res = self.db:exec(query)
    if res == 0 then
        self.logger.d("table initialised")
    else
        self.logger.e("Initializing DB: errono: " .. res .. ", for query: `" .. query .. "`")
    end

    local query = [[
        SELECT
            strftime('%s', 'now') - strftime('%s', started_at) as age,
            status
        FROM
            works
        ORDER BY
            id DESC
        LIMIT 1;
    ]]


    function parser(udata, cols, values, names)
        age, status = table.unpack(values)
        self.age = tonumber(age)
        self.logger.i(string.format("parser running, age: %s (mins), status: %s", self.age / 60, status))
        if status == "new" and self.age < self.seconds_by_mode[M_WORKING] then
            self.logger.i("Hammerspoon restarted, back to `working` state")
            self.sounds.tick:play()
            self.mode = M_WORKING
            self:tick()
            return 0
        elseif status == "completed" then
            -- minus the time it took to complete
            self.age = self.age - self.seconds_by_mode[M_WORKING]
            self.logger.i(string.format("updated age to %s (mins)", self.age / 60))
            if self.age < self.seconds_by_mode[M_RESTING] then
                self.logger.i("Hammerspoon restarted, back to `resting` state")
                self.mode = M_RESTING
                self:tick()
                return 0
            end
        end

        self.logger.i("Hammerspoon restarted, back to `idle` state")
        self.mode = M_IDLE
        return 0
    end
    self.db:exec(query, parser)

    self.ticker:start()
end

function obj:toggle()
    if self.mode == M_IDLE then
        -- Transition: Idle -> Start -> Working
        self:startWorking()
    elseif self.mode == M_WORKING then
        -- Transition: Working -> Interrupt -> Idle
        self:interruptWorking()
    elseif self.mode == M_RESTING then
        -- Transition: Resting -> Interrupt -> Idle
        self:interruptResting()
    end
end

function obj:tick()
    -- if hs.caffeinate.sessionProperties()["CGSSessionScreenIsLocked"] then
    --     self.ticker:setNextTrigger(60)
    -- end
    self.age = self.age + 1
    if self.logActivityInterval > 0 and (self.age % self.logActivityInterval) == 0 then
        local success, err = pcall(function() self:logActivity() end)
        if not success then
            self.logger.e(string.format("Logging activity failed: %s", err))
        end
    end
    if self.mode == M_IDLE then
        self:handleIdleMode()
    else
        self:handleActiveModes()
    end
end

function obj:startWorking()
    self.logger.i("Work session was started")
    hs.alert.show("🍅 Start")
    if self.nudge then
        self.nudgeer:stop()
        self.canvas_report:alpha(0.0)
    end
    self.mode = M_WORKING
    self.ticker:start()
    hs.screen.setForceToGray(false)
    self.sounds.wind:play()
    self.sounds.tick:play()
    self.age = 0
    self.canvas_progress_bar:show()
    self.db:exec("INSERT INTO works DEFAULT VALUES;")
    self._report_is_fresh = false
    self.canvas_report:hide()
    callAll(self.triggers.on_start_work)
end

function obj:interruptWorking()
    self.logger.i("Work session was interrupted")
    hs.alert.show("👎 interrupted")
    self.sounds.tick:stop()
    self.mode = M_IDLE
    self.canvas_progress_bar:hide()
    self.age = 0
    self.db:exec([[
        UPDATE works
        SET status = 'interrupted'
        WHERE id = (SELECT id FROM works ORDER BY id DESC LIMIT 1);
    ]])

    self:showReport(0.5)
    callAll(self.triggers.on_interrupt_work)
end

function obj:showReport(alpha)
    self.canvas_report:alpha(alpha or 0.25)
    if not self._report_is_fresh then
        self:redrawReport()
        self._report_is_fresh = true
    end
    self.canvas_report:show()
end

function obj:redrawReport()
    self.logger.i("Redrawing report")
    self.canvas_report:replaceElements(
        {
            action = "fill",
            fillColor = self.colors.report_background,
            frame = {x="0", y="0", h="1", w="1"},
            type = "rectangle",
        }
    )

    local query = [[
        WITH RECURSIVE calendar AS (
          SELECT DATE('now') AS day
          UNION ALL
          SELECT DATE(day, '-1 day')
          FROM calendar
          WHERE day > DATE('now', '-28 day')
        ),
        week_numbers AS (
          SELECT
            calendar.day,
            CAST((julianday(calendar.day) - julianday('now', 'weekday 0', '-36 day')) / 7 AS INTEGER) AS week
          FROM calendar
          GROUP BY calendar.day
        )
        SELECT
          STRFTIME('%w', calendar.day) AS day_of_week,
          week_numbers.week AS week_of_month,
          COUNT(works.id) AS count,
          CASE WHEN calendar.day = DATE('now') THEN 1 ELSE 0 END AS is_today
        FROM calendar
        LEFT JOIN week_numbers ON calendar.day = week_numbers.day
        LEFT JOIN works ON DATE(works.started_at) = calendar.day AND works.status = 'completed'
        GROUP BY calendar.day, day_of_week, week, week_numbers.day
        ORDER BY calendar.day;
    ]]

    local expected = math.min(6, self.max_expected)
    local decay = 0.3
    local increase = 0.5
    local new = true
    function parser(udata, cols, values, names)
        local day, week, done, today = table.unpack(values)
        local today = today == "1"
        local weekend = day == "0" or day == "6"
        done = tonumber(done)

        done_radius = done ^ 0.5 / 200
        expe_radius = expected ^ 0.5 / 200

        x = tostring((day + 0.5) / 7)
        y = tostring((week + 0.5) / 5)
        fillColor = (
            weekend and self.colors.report_weekend
            or today and self.colors.report_today
            or done > expected and self.colors.report_good
            or self.colors.report_bad
        )
        self.canvas_report:insertElement(
            {
                action = "fill",
                fillColor = fillColor,
                radius = tostring(done_radius),
                center = {x=x, y=y},
                type = "circle",
                withShadow = true,
            }
        )

        if done > 0 then
            new = false
            self.canvas_report:insertElement(
                {
                    action = "stroke",
                    strokeWidth = today and 2 or 1,
                    strokeColor = done > expected and { green=1 } or { red=1 },
                    radius = tostring(expe_radius),
                    center = {x=x, y=y},
                    type = "circle",
                }
            )
        end

        if not new then
            if done < expected then
                expected = expected * (1 - decay) + done * decay
            else
                expected = expected * (1 - increase) + done * increase
            end
            expected = math.min(expected, self.max_expected)
        end

        return 0
    end

    self.db:exec(query, parser)
    callAll(self.triggers.on_draw_report)
end

function obj:interruptResting()
    self.logger.i("Resting session was interrupted")
    hs.alert.show("😓 rest interrupted")
    self.mode = M_IDLE
    self.canvas_progress_bar:hide()
    self.age = 0
    self.canvas_report:hide()
    callAll(self.triggers.on_interrupt_rest)
end

function obj:logActivity()
    self.logger.d("Running activity logger")
    local window = hs.window.frontmostWindow()
    local title = window:title() .. "@" .. window:application():name()
    local query = string.format([[
        INSERT INTO activity (type, value)
        VALUES ('window title', '%s::%s')
    ]], self.mode, title)
    self.db:exec(query)
end

function obj:handleIdleMode()
    local now = os.date("*t")

    -- FIXME: disabling this optimization until it's unbroken
    -- if now.wday < 2 or now.wday > 6 or now.hour <= 7 or now.hour >= 19 then
    --     local now = os.date("*t") -- Get the current time and date
    --     local targetHour = 8 -- The target hour (8 AM)
    --     local targetWday = (now.wday - 1) % 7 + 2 -- Calculate the target weekday (next working day)
    --     local remainingDays = (targetWday - now.wday) % 7
    --     -- Calculate the number of seconds until the next working day at 8 AM
    --     local remainingTime = (targetWday - now.wday) * 24 * 60 * 60 + (targetHour - now.hour) * 60 * 60 - now.min * 60 - now.sec
    --     -- Add a week if the target time has already passed for this week
    --     if remainingTime < 0 then
    --         remainingTime = remainingTime + 7 * 24 * 60 * 60
    --     end
    --     return self.ticker:setNextTrigger(remainingTime)
    -- end

    if self.nudge and self.age >= self.seconds_by_mode[M_IDLE] then
        periods = self.age // self.seconds_by_mode[M_IDLE]
        nag_every = math.max(self.seconds_by_mode[M_IDLE] - periods, 30)
        if self.age % nag_every == 0 then
            self:showReport(1/8)
            self.sounds.nudge:play()
            self.nudgeer:start()
            callAll(self.triggers.on_nudge)
            local limit = 2 ^ (self.age // nag_every)
            limit = math.max(limit, 2)
            limit = math.min(limit, 5)
            hs.timer.doAfter(limit, function() self.nudgeer:stop(); self.canvas_report:alpha(0) end)
        end
    end

end

function obj:handleActiveModes()
    if self.mode == M_WORKING then
        if self.age % self.seconds_by_mode[M_RESTING] == 0 then
            callAll(self.triggers.on_task_reminder)
        end
    end

    local complete_ratio = self.age / self.seconds_by_mode[self.mode]
    self.canvas_progress_bar:replaceElements(
        {
            action = "fill",
            fillColor = self.colors.bar_background,
            frame = { x = "0", y = "0", h = "1", w = "1" },
            type = "rectangle",
        },
        {
            action = "fill",
            fillColor = self.colors[self.mode],
            frame = { x = "0", y = "0", h = "1", w = tostring(complete_ratio) },
            type = "rectangle",
        }
    )

    if complete_ratio >= 1 then
        if self.mode == M_WORKING then
            self:handleCompleteWorkingMode()
        elseif self.mode == M_RESTING then
            self:handleCompleteRestingMode()
        end
    end
end

function obj:handleCompleteWorkingMode()
    self.mode = M_RESTING
    self.age = 0
    self.db:exec([[
        UPDATE works
        SET status = 'completed'
        WHERE id = (SELECT id FROM works ORDER BY id DESC LIMIT 1);
    ]])
    self._report_is_fresh = false
    hs.alert.show("🎉 time to rest!")
    callAll(self.triggers.on_complete_work)
    self.sounds.tick:stop()
    self.sounds.ring:play()
end

function obj:handleCompleteRestingMode()
    hs.alert.show("💪 start working again.")
    self.canvas_progress_bar:hide()
    self.sounds.ring:play()
    self.mode = M_IDLE
    self.age = 0
    callAll(self.triggers.on_complete_rest)
end

-- passata:bindHotkeys(mapping)
-- Method
-- Binds hotkeys for Passata Timer
--
-- Parameters:
--  * mapping - A table containing hotkey modifier/key details for the following items:
--    * toggle - Start/stop the timer
function obj:bindHotkeys(mapping)
  local actions = {toggle = hs.fnutils.partial(self.toggle, self)}
  hs.spoons.bindHotkeysToSpec(actions, mapping)
end

return obj
