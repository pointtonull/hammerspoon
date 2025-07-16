-- AWS credentials and export functions moved from init.lua
local M = {}
local OTP = require("modules.otp")

--- Retrieve AWS credentials via Okta automation
function M.get_aws_credentials()
    local focused = hs.window.focusedWindow()
    local firefox
    local status = STATUS("🔑")

    local function cleanup()
        status("🧹 cleanup")
        if hs.window.focusedWindow():title():match(" Email -- ") then
            hs.eventtap.keyStroke({"cmd"}, "w")
        end
        focused:focus()
        status:destroy()
    end

    local function onAWS()
        status("on MyAPPs")
        hs.eventtap.keyStrokes("/")
        input_pause()
        hs.eventtap.keyStrokes("fans")
        hs.eventtap.keyStroke(NONE, "Return")
        input_pause()
        hs.eventtap.keyStroke({"shift"}, "Tab")
        input_pause()
        hs.eventtap.keyStroke(NONE, "Return")
        input_pause(1)
        hs.eventtap.keyStrokes("/")
        input_pause()
        hs.eventtap.keyStrokes("write")
        hs.eventtap.keyStroke(NONE, "Return")
        input_pause()
        hs.eventtap.keyStroke(NONE, "Tab")
        input_pause()
        hs.eventtap.keyStroke(NONE, "Return")
        hs.timer.doAfter(5, cleanup)
    end

    local function onMyAPPs()
        status("on MyAPPs")
        hs.eventtap.keyStroke(HYPER, "l")
        input_pause()
        hs.eventtap.keyStrokes(
            "https://spireglobal.okta.com/home/amazon_aws_sso/0oa9asc523yi9gGC45d7/aln1ghfn5xxV7ZPbE1d8")
        hs.eventtap.keyStroke(NONE, "Return")
        hs.timer.doAfter(10, onAWS)
        wait_until(readyOkta, onOkta, cleanup, 40, 1)
    end

    local function onOTP()
        status("✅ otp")
        OTP.type_otp("OTP_OKTA")
        hs.timer.doAfter(5, onMyAPPs)
    end

    local function onSignIn()
        status("✅ sign in")
        hs.eventtap.keyStroke(NONE, "Tab")
        hs.eventtap.keyStroke(NONE, "Return")
        hs.timer.doAfter(5, onOTP)
    end

    local function onOkta()
        status("✅ loading")
        local function readySignIn()
            status("❔password")
            firefox:focus()
            FirefoxCopySource()
            local pasteboardContent = hs.pasteboard.getContents()
            if pasteboardContent:match("Sign In") or
               pasteboardContent:match("Verify with your password") then
                return true
            end
        end
        wait_until(readySignIn, function() hs.timer.doAfter(5, onSignIn) end,
                   cleanup, 30, 1)
    end

    local function onFirefox()
        status("on firefox")
        hs.eventtap.keyStroke(HYPER, "t")
        input_pause()
        hs.eventtap.keyStrokes("https://spireglobal.okta.com/app/UserHome")
        hs.eventtap.keyStroke(NONE, "Return")
        local function readyOkta()
            status("❔Sign in")
            local title = hs.window.focusedWindow():title()
            return title:match("Spire Global")
        end
        wait_until(readyOkta, onOkta, cleanup, 40, 1)
    end

    local function startFirefox()
        status("start")
        hs.application.launchOrFocus("Firefox")
        local app = hs.application.get("Firefox")
        app:activate()
        wait_until(
            function()
                firefox = hs.window.focusedWindow()
                return firefox:application():name() == "Firefox"
            end,
            onFirefox,
            cleanup
        )
    end

    startFirefox()
end

--- Export mails from Outlook Web
function M.export_mails()
    local focused = hs.window.focusedWindow()
    local mails_filename = os.getenv("HOME") .. "/Downloads/mails.html"
    local status = STATUS("📩")
    os.remove(mails_filename)

    local function cleanup_mails()
        status("🧹 cleanup")
        if hs.window.focusedWindow():title():match(" Email -- ") then
            hs.eventtap.keyStroke({"cmd"}, "w")
        end
        focused:focus()
        status:destroy()
    end

    local function onReadyMails()
        status("✅ mails")
        local pasteboardContent = hs.pasteboard.getContents()
        local file = io.open(mails_filename, "w")
        file:write(pasteboardContent)
        file:close()
        cleanup_mails()
    end

    local function onInbox()
        status("✅ loading")
        wait_until(
            function()
                status("❔ajax")
                FirefoxCopySource()
                return hs.pasteboard.getContents():match("data--convid")
            end,
            onReadyMails,
            cleanup_mails,
            30,
            1
        )
    end

    local function onFirefoxMails()
        status("on firefox")
        hs.eventtap.keyStroke(HYPER, "t")
        input_pause()
        hs.eventtap.keyStrokes("https://outlook.office365.us/mail/")
        hs.eventtap.keyStroke(NONE, "Return")
        wait_until(onInbox, cleanup_mails, 40, 1)
    end

    local function startFirefoxMails()
        status("start")
        hs.application.launchOrFocus("Firefox")
        wait_until(
            function()
                return hs.window.focusedWindow():application():name() == "Firefox"
            end,
            onFirefoxMails,
            cleanup_mails,
            30,
            1
        )
    end

    startFirefoxMails()
end

--- Export calendar from Outlook Web
function M.export_calendar()
    local focused = hs.window.focusedWindow()
    local calendar_filename = os.getenv("HOME") .. "/Downloads/calendar.html"
    local status = STATUS("🗓️")
    os.remove(calendar_filename)
    local titleReady = " Calendar "

    local function cleanup_calendar()
        status("🧹 cleanup")
        if hs.window.focusedWindow():title():match(titleReady) then
            hs.eventtap.keyStroke({"cmd"}, "w")
        end
        focused:focus()
        status:destroy()
    end

    local function onReadyCalendar()
        status("✅ calendar")
        local pasteboardContent = hs.pasteboard.getContents()
        local file = io.open(calendar_filename, "w")
        file:write(pasteboardContent)
        file:close()
        cleanup_calendar()
    end

    local function onCalendar()
        status("✅ loading")
        wait_until(
            function()
                status("❔ajax")
                FirefoxCopySource()
                local content = hs.pasteboard.getContents()
                return content:match("data-calendar-vie")
            end,
            onReadyCalendar,
            cleanup_calendar,
            30,
            1
        )
    end

    local function onFirefoxCalendar()
        status("on firefox")
        hs.eventtap.keyStroke(HYPER, "t")
        input_pause()
        hs.eventtap.keyStrokes("https://outlook.office365.us/calendar/view/day")
        hs.eventtap.keyStroke(NONE, "Return")
        wait_until(onCalendar, cleanup_calendar, 40, 1)
    end

    local function startFirefoxCalendar()
        status("start")
        hs.application.launchOrFocus("Firefox")
        wait_until(
            function()
                return hs.window.focusedWindow():application():name() == "Firefox"
            end,
            onFirefoxCalendar,
            cleanup_calendar,
            30,
            1
        )
    end

    startFirefoxCalendar()
end

return M
