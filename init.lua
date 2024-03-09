--- === Spacer ===
---
--- Save and reload Spaces (i.e., desktops) with the same windows containing the same files in the same position.
---

local module = {}
setmetatable(module, module)

-- Metadata
module.name = "Spacer"
module.version = "0.0.1"
module.author = " Neta Elad <elad.neta@gmail.com>"
module.homepage = "https://github.com/neta-elad/Spacer.spoon"
module.license = "MIT - https://opensource.org/licenses/MIT"

TELL_FORMATS = {
    "tell application \"%s\" to get path of document frontmost",
    "tell application \"%s\" to tell front document to get POSIX path of (its file as alias)",
}

-- Local
local function getFrontmostPath(appName)
    for _j, tellFormat in pairs(TELL_FORMATS) do
        local command = string.format(
            tellFormat,
            appName
        )
        local result, tryPath, _descriptor = hs.osascript.applescript(command)
        if result then
            return tryPath
        end
    end
    return nil
end

local function rightAlignActiveWindow()
    hs.eventtap.keyStroke({"cmd"}, "a", 0)
    hs.eventtap.keyStroke({"cmd", "ctrl"}, "left", 0)
    hs.eventtap.keyStroke({}, "left", 0)
end

local function saveSpace()
    local focusedSpace = hs.spaces.focusedSpace()
    local frontmost = hs.window.frontmostWindow()
    local savedSpace = {}
    hs.printf("saveSpace %d", focusedSpace)
    for _i, windowId in pairs(hs.spaces.windowsForSpace(focusedSpace)) do
        local window = hs.window.get(windowId)
        if window ~= nil and window:isVisible() then
            window:raise()
            local path = getFrontmostPath(window:application():name())
            if path ~= nil then
                local frame = window:frame()
                table.insert(savedSpace, {
                    app = window:application():name(),
                    path = path,
                    frame = { x = frame.x, y = frame.y, h = frame.h, w = frame.w }
                })
            end
        end
    end
    if frontmost ~= nil then
        frontmost:raise()
    end

    hs.settings.set("Spacer::space", savedSpace)
end

local function openAppWithPath(app, path)
    hs.task.new("/usr/bin/open", nil, {
        "-a", app, path
    }):start()
end

local function loadSpace()
    local savedSpace = hs.settings.get("Spacer::space")
    for _i, winInfo in pairs(savedSpace) do
        hs.printf(hs.inspect(winInfo))
        openAppWithPath(winInfo.app, winInfo.path)
        hs.timer.usleep(200 * 1000)
        local app = hs.application.find(winInfo.app)
        app:activate()
        local window = app:focusedWindow()
        window:focus()
        rightAlignActiveWindow()
        window:setFrame(winInfo.frame)
    end
end

-- Public
function module:init()
    hs.printf("Hello, Spacer!")
    self.menubar = hs.menubar.new()

    self.menubar:setIcon(hs.image.imageFromName("NSComputer"):setSize({ w = 16, h = 16 }))
    self.menubar:setTooltip("Spacer")
    self.menubar:setMenu({
        { title = "💾 Save space", fn = saveSpace },
        { title = "🖥️ Load space", fn = loadSpace },
    })

    return self
end

return module
