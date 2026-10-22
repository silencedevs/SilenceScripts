local shared = (type(getgenv) == "function" and getgenv()) or _G

if shared.SilenceMuscleLegendsRuntime then
    pcall(function()
        shared.SilenceMuscleLegendsRuntime:Destroy()
    end)
end

for _, descendant in ipairs(game:GetService("CoreGui"):GetDescendants()) do
    if descendant:IsA("ScreenGui") and descendant.Name == "WindUI" and not descendant:FindFirstChild("Window") then
        descendant:Destroy()
    end
end

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/silencedevs/SilenceScripts/refs/heads/main/libraries/windui/windui.luau"))()

local library = WindUI

local function enableAntiAFK()
    local player = game:GetService("Players").LocalPlayer
    local virtualUser = game:GetService("VirtualUser")
    player.Idled:Connect(function()
        virtualUser:CaptureController()
        virtualUser:ClickButton2(Vector2.new())
    end)
end

library.EnableAntiAFK = function()
    enableAntiAFK()
end

local runtime = {Alive = true, Threads = {}, Connections = {}, Cleanups = {}}
shared.SilenceMuscleLegendsRuntime = runtime

function runtime:Spawn(callback, ...)
    if not self.Alive then return end
    local thread
    thread = coroutine.create(function(...)
        local success, result = pcall(callback, ...)
        self.Threads[thread] = nil
        if not success then self.LastError = result end
    end)
    self.Threads[thread] = true
    task.spawn(thread, ...)
    return thread
end

function runtime:Connect(signal, callback)
    local connection = signal:Connect(function(...) if self.Alive then callback(...) end end)
    table.insert(self.Connections, connection)
    return connection
end

function runtime:Defer(callback, ...)
    if not self.Alive then return end
    return task.defer(callback, ...)
end

function runtime:Delay(delayTime, callback, ...)
    if not self.Alive then return end
    return task.delay(delayTime, callback, ...)
end

function runtime:AddCleanup(callback)
    table.insert(self.Cleanups, callback)
end

function runtime:Destroy()
    if not self.Alive then return end
    self.Alive = false
    for _, connection in ipairs(self.Connections) do pcall(function() connection:Disconnect() end) end
    for index = #self.Cleanups, 1, -1 do pcall(self.Cleanups[index]) end
    for thread in pairs(self.Threads) do if thread ~= coroutine.running() then pcall(task.cancel, thread) end end
    table.clear(self.Connections)
    table.clear(self.Threads)
    if shared.SilenceMuscleLegendsRuntime == self then shared.SilenceMuscleLegendsRuntime = nil end
end

local services = {
	Players = game:GetService("Players"),
	ReplicatedStorage = game:GetService("ReplicatedStorage"),
	VirtualUser = game:GetService("VirtualUser"),
	Workspace = workspace,
	Lighting = game:GetService("Lighting"),
	UserInputService = game:GetService("UserInputService"),
	VirtualInputManager = game:GetService("VirtualInputManager"),
	RunService = game:GetService("RunService"),
	CollectionService = game:GetService("CollectionService"),
	HttpService = game:GetService("HttpService"),
	StarterGui = game:GetService("StarterGui")
}


do
	local success, executorName = pcall(function()
		local identify = identifyexecutor
		if type(identify) ~= "function" then identify = getexecutorname end
		if type(identify) == "function" then return identify() end
	end)
	services.isSolara = success and type(executorName) == "string" and string.lower(executorName) == "solara"
end

local utils = {library = library}
utils.runtime = {}

utils.touchParts = function(part, hand, state)
	if type(firetouchinterest) ~= "function" or not part or not hand then return false end
	return pcall(firetouchinterest, part, hand, state)
end

utils.playerData = {
	Player = services.Players.LocalPlayer,
	DisplayName = services.Players.LocalPlayer.DisplayName,
	Character = services.Players.LocalPlayer.Character,
	Humanoid = nil,
	Camera = services.Workspace.CurrentCamera,
	Backpack = services.Players.LocalPlayer:WaitForChild("Backpack")
}

utils.playerData.Humanoid = utils.playerData.Character and utils.playerData.Character:FindFirstChildOfClass("Humanoid")

utils.remotes = {
	ChangeSpeedSize = services.ReplicatedStorage:WaitForChild("rEvents"):WaitForChild("changeSpeedSizeRemote"),
	MuscleEvent = utils.playerData.Player:WaitForChild("muscleEvent")
}

function utils.formatNumber(n)
	if n >= 1e18 then return string.format("%.1fqi", n / 1e18)
	elseif n >= 1e15 then return string.format("%.1fqa", n / 1e15)
	elseif n >= 1e12 then return string.format("%.1ft", n / 1e12)
	elseif n >= 1e9 then return string.format("%.1fb", n / 1e9)
	elseif n >= 1e6 then return string.format("%.1fm", n / 1e6)
	elseif n >= 1e3 then return string.format("%.1fk", n / 1e3)
	else return tostring(n) end
end

function utils.formatWithCommas(n, formatted, separatorCount)
	formatted = tostring(math.floor(n))
	while true do
		formatted, separatorCount = formatted:gsub("^(-?%d+)(%d%d%d)", "%1.%2")
		if separatorCount == 0 then break end
	end
	return formatted
end

function utils.greeting(hour)
	hour = hour or os.date("*t").hour
	if hour >= 6 and hour < 12 then return "Good Morning!"
	elseif hour >= 12 and hour < 13 then return "Good Noon!"
	elseif hour >= 13 and hour < 19 then return "Good Afternoon!"
	elseif hour >= 19 and hour < 22 then return "Good Evening!"
	else return "Good Night!" end
end

function utils.toggleSelection(selected, selectedList, value, label, prefix)
	if selected[value] then
		selected[value] = nil
		for index = #selectedList, 1, -1 do
			if selectedList[index] == value then table.remove(selectedList, index) end
		end
	else
		selected[value] = true
		table.insert(selectedList, value)
	end
	label.Text = prefix .. (#selectedList > 0 and table.concat(selectedList, ", ") or "None")
end

function utils.deleteAds()
	for _, portal in pairs(game:GetDescendants()) do
		if portal.Name == "RobloxForwardPortals" then
			portal:Destroy()
		end
	end
	if _G.ads then
		_G.ads:Disconnect()
	end

	_G.ads = runtime:Connect(game.DescendantAdded, function(descendant)
		if descendant.Name == "RobloxForwardPortals" then
			descendant:Destroy()
		end
	end)
end
utils.deleteAds()

local CONFIG_FOLDER = "Silence/Configs/MuscleLegends/WindUI"
local CONFIG_FILE = CONFIG_FOLDER .. "/Config.json"

local configEntries = {}
local configGetters = {}
local configSetters = {}
local saveScheduled = false

local function readConfigFile()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then
        return {}
    end
    if not isfile(CONFIG_FILE) then
        return {}
    end
    local ok, content = pcall(readfile, CONFIG_FILE)
    if not ok or type(content) ~= "string" or content == "" then
        return {}
    end
    local decodeOk, decoded = pcall(function()
        return services.HttpService:JSONDecode(content)
    end)
    if decodeOk and type(decoded) == "table" then
        return decoded
    end
    return {}
end

local function collectConfigValues()
    local values = {}
    for key, entry in pairs(configEntries) do
        local ok, value = pcall(entry.Get)
        if ok and value ~= nil then
            values[key] = value
        end
    end
    for name, getter in pairs(configGetters) do
        local ok, value = pcall(getter)
        if ok and value ~= nil then
            values[name] = value
        end
    end
    return values
end

local function writeConfigNow()
    if type(writefile) ~= "function" then
        return
    end
    pcall(function()
        if type(makefolder) == "function" then
            pcall(makefolder, "Silence")
            pcall(makefolder, "Silence/Configs")
            pcall(makefolder, "Silence/Configs/MuscleLegends")
            pcall(makefolder, CONFIG_FOLDER)
        end
        writefile(CONFIG_FILE, services.HttpService:JSONEncode(collectConfigValues()))
    end)
end

local function saveConfigDebounced()
    if saveScheduled then
        return
    end
    saveScheduled = true
    task.delay(0.5, function()
        saveScheduled = false
        writeConfigNow()
    end)
end

local function applyConfigValues(values)
    if type(values) ~= "table" then
        return
    end
    for key, value in pairs(values) do
        local entry = configEntries[key]
        if entry then
            pcall(entry.Set, value)
        end
    end
    for name, setter in pairs(configSetters) do
        if values[name] ~= nil then
            pcall(setter, values[name])
        end
    end
end

local configManager = {}
function configManager:Save()
    writeConfigNow()
    return self
end
function configManager:Load()
    applyConfigValues(readConfigFile())
    return self
end
function configManager:GetValues()
    return collectConfigValues()
end
function configManager:Apply(values)
    applyConfigValues(values)
end
function configManager:LoadStartup()
    local values = readConfigFile()
    if next(values) then
        applyConfigValues(values)
    end
end
function configManager:Register(name, getter, setter)
    if type(name) ~= "string" then
        return self
    end
    if type(getter) == "function" then
        configGetters[name] = getter
    end
    if type(setter) == "function" then
        configSetters[name] = setter
    end
    return self
end

local labelQueue = {}
local labelUpdaterStarted = false

local function startLabelUpdater()
    if labelUpdaterStarted then
        return
    end
    labelUpdaterStarted = true
    task.spawn(function()
        while true do
            task.wait(0.2)
            for label in pairs(labelQueue) do
                label:_Flush()
            end
        end
    end)
end

local function createLabel(realTab, text)
    local paragraph = realTab:Paragraph({Title = tostring(text or "")})
    local state = {
        value = tostring(text or ""),
        pendingValue = nil,
        titleLabel = nil,
        textSize = nil,
        font = nil,
    }
    local methods = {}

    local function resolveTitleLabel()
        if state.titleLabel and state.titleLabel.Parent then
            return state.titleLabel
        end
        local frame = paragraph.ElementFrame
        if not frame then
            return nil
        end
        for _, descendant in ipairs(frame:GetDescendants()) do
            if descendant:IsA("TextLabel") and descendant.Text == paragraph.Title then
                state.titleLabel = descendant
                if state.textSize then
                    descendant.TextSize = state.textSize
                end
                if state.font then
                    descendant.Font = state.font
                end
                return descendant
            end
        end
        return nil
    end

    local function applyText(value)
        state.value = value
        paragraph:SetTitle(value)
        local label = resolveTitleLabel()
        if label then
            if state.textSize then
                label.TextSize = state.textSize
            end
            if state.font then
                label.Font = state.font
            end
        end
    end

    function methods:_Flush()
        if state.pendingValue ~= nil then
            local value = state.pendingValue
            state.pendingValue = nil
            if value ~= state.value then
                applyText(value)
            end
        end
    end

    function methods:SetAttribute(name, value)
        if name == "EleriumUpdateInterval" then
            state.interval = tonumber(value) or state.interval
        end
    end

    function methods:GetAttribute(name)
        if name == "EleriumUpdateInterval" then
            return state.interval
        end
        return nil
    end

    local label
    label = setmetatable({}, {
        __index = function(_, key)
            if key == "Text" then
                return state.pendingValue or state.value
            end
            if key == "Paragraph" then
                return paragraph
            end
            return methods[key]
        end,
        __newindex = function(_, key, value)
            if key == "Text" then
                value = tostring(value)
                if value == (state.pendingValue or state.value) then
                    return
                end
                state.pendingValue = value
                labelQueue[label] = true
                startLabelUpdater()
            elseif key == "TextColor3" then
                local foundLabel = resolveTitleLabel()
                if foundLabel then
                    foundLabel.TextColor3 = value
                end
            elseif key == "TextSize" then
                state.textSize = value
                local foundLabel = resolveTitleLabel()
                if foundLabel then
                    foundLabel.TextSize = value
                end
            elseif key == "Font" then
                state.font = value
                local foundLabel = resolveTitleLabel()
                if foundLabel then
                    foundLabel.Font = value
                end
            else
                rawset(_, key, value)
            end
        end,
    })

    return label
end

local function createSwitch(realTab, text, callback, default)
    local wrapper = {_value = default == true}
    local toggle
    local initializing = true

    toggle = realTab:Toggle({
        Title = tostring(text or "Toggle"),
        Value = wrapper._value,
        Callback = function(value)
            wrapper._value = value
            if initializing then
                return
            end
            if type(callback) == "function" then
                task.spawn(function()
                    pcall(callback, value)
                end)
            end
            saveConfigDebounced()
        end,
    })
    task.defer(function()
        initializing = false
    end)

    wrapper.Raw = toggle

    function wrapper:Set(value)
        value = value == true
        if self._value == value then
            return self
        end
        self._value = value
        toggle:Set(value)
        return self
    end

    function wrapper:Get()
        return self._value
    end

    function wrapper:SetConfigKey(key)
        configEntries[key] = {
            Get = function()
                return wrapper._value
            end,
            Set = function(value)
                wrapper:Set(value == true)
            end,
        }
        return self
    end

    return wrapper
end

local function createTextBox(realTab, text, callback, options)
    options = type(options) == "table" and options or {}
    local clear = options.clear ~= false
    local input

    input = realTab:Input({
        Title = tostring(text or "Input"),
        Placeholder = tostring(text or "Input"),
        Value = tostring(options.default or ""),
        Callback = function(value)
            if type(callback) == "function" then
                task.spawn(function()
                    pcall(callback, value)
                end)
            end
            if clear then
                input:Set("")
            end
            saveConfigDebounced()
        end,
    })

    local textBox = input.ElementFrame and input.ElementFrame:FindFirstChildWhichIsA("TextBox", true)
    local methods = {}
    local value = tostring(options.default or "")

    function methods:Set(newValue)
        newValue = tostring(newValue or "")
        value = newValue
        if textBox then
            textBox.Text = newValue
        end
        return methods
    end

    function methods:GetPropertyChangedSignal(property)
        if textBox then
            return textBox:GetPropertyChangedSignal(property)
        end
        return input.ElementFrame:GetPropertyChangedSignal(property)
    end

    function methods:SetConfigKey(key)
        configEntries[key] = {
            Get = function()
                return textBox and textBox.Text or value
            end,
            Set = function(newValue)
                methods:Set(newValue)
            end,
        }
        return methods
    end

    return setmetatable({}, {
        __index = function(_, key)
            if key == "Text" then
                if textBox then
                    return textBox.Text
                end
                return value
            end
            if key == "Raw" then
                return input
            end
            return methods[key]
        end,
        __newindex = function(_, key, newValue)
            if key == "Text" then
                methods:Set(newValue)
            else
                rawset(_, key, newValue)
            end
        end,
    })
end

local function createDropdown(realTab, name, callback)
    local values = {}
    local current = nil
    local dropdown
    local methods = {}
    local refreshQueued = false

    local function flushRefresh()
        refreshQueued = false
        dropdown:Refresh(values)
    end

    local function queueRefresh()
        if refreshQueued then
            return
        end
        refreshQueued = true
        task.defer(function()
            if refreshQueued then
                flushRefresh()
            end
        end)
    end

    local initializing = true

    dropdown = realTab:Dropdown({
        Title = tostring(name or "Dropdown"),
        Values = {},
        Callback = function(value)
            if value == nil or value == "" then
                return
            end
            current = value
            if initializing then
                return
            end
            if type(callback) == "function" then
                task.spawn(function()
                    pcall(callback, value)
                end)
            end
            saveConfigDebounced()
        end,
    })
    task.defer(function()
        initializing = false
    end)

    function methods:Add(value)
        value = tostring(value)
        for _, existing in ipairs(values) do
            if existing == value then
                return methods
            end
        end
        table.insert(values, value)
        queueRefresh()
        return methods
    end

    function methods:Remove(value)
        value = tostring(value)
        for index, existing in ipairs(values) do
            if existing == value then
                table.remove(values, index)
                break
            end
        end
        queueRefresh()
        return methods
    end

    function methods:Refresh(newValues)
        values = {}
        for _, value in ipairs(newValues or {}) do
            table.insert(values, tostring(value))
        end
        flushRefresh()
        return methods
    end

    function methods:Clear()
        values = {}
        current = nil
        queueRefresh()
        return methods
    end

    function methods:SetValue(value)
        if value == nil then
            return methods
        end
        value = tostring(value)
        if not table.find(values, value) then
            table.insert(values, value)
        end
        flushRefresh()
        current = value
        dropdown:Select(value)
        return methods
    end

    function methods:Select(value)
        return methods:SetValue(value)
    end

    function methods:SetConfigKey(key)
        configEntries[key] = {
            Get = function()
                return current
            end,
            Set = function(value)
                methods:SetValue(value)
            end,
        }
        return methods
    end

    return setmetatable({}, {
        __index = function(_, key)
            if key == "Value" then
                return current
            end
            if key == "Raw" then
                return dropdown
            end
            return methods[key]
        end,
    })
end

local function wrapTab(realTab)
    local tab = {Raw = realTab}

    function tab:AddLabel(text)
        return createLabel(realTab, text)
    end

    function tab:AddHeading(text)
        return realTab:Section({
            Title = tostring(text or ""),
            Box = false,
            TextSize = 20,
            TextXAlignment = "Left",
        })
    end

    function tab:AddButton(text, callback)
        return realTab:Button({
            Title = tostring(text or "Button"),
            Callback = type(callback) == "function" and callback or function() end,
        })
    end

    function tab:AddSwitch(text, callback, default)
        return createSwitch(realTab, text, callback, default)
    end

    function tab:AddTextBox(text, callback, options)
        return createTextBox(realTab, text, callback, options)
    end

    function tab:AddDropdown(name, callback)
        return createDropdown(realTab, name, callback)
    end

    function tab:AddHorizontalAlignment()
        local group = {}
        function group:AddButton(text, callback)
            return realTab:Button({
                Title = tostring(text or "Button"),
                Callback = type(callback) == "function" and callback or function() end,
            })
        end
        return group
    end

    function tab:Show()
        realTab:Select()
    end

    function tab:Select()
        realTab:Select()
    end

    return tab
end

local desktop = services.UserInputService.KeyboardEnabled and services.UserInputService.MouseEnabled
local silence = WindUI:CreateWindow({
    Title = "Silence - Muscle Legends",
    Author = "by Henrik @xyzhenrik",
    Icon = "solar:moon-bold",
    IconSize = 26,
    Theme = "Crimson",
    NewElements = true,
    TopBarButtonIconSize = desktop and 24 or 16,
    Size = UDim2.fromOffset(600, 620),
    MinSize = Vector2.new(560, 420),
    MaxSize = Vector2.new(1000, 760),
    Resizable = true,
    Folder = "Silence/MuscleLegends/" .. tostring(services.Players.LocalPlayer.UserId),
    OpenButton = {
        Title = "Reopen Silence",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 3,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = desktop and 1.25 or 0.5,
        Color = ColorSequence.new(Color3.fromHex("880000"), Color3.fromHex("000000"))
    },
    Topbar = {Height = desktop and 56 or 44, ButtonsType = "Default"}
})
silence:OnDestroy(function() runtime:Destroy() end)
runtime:AddCleanup(function() if not silence.Destroyed then silence:Destroy() end end)
shared.SilenceMuscleLegendsWindow = silence
runtime:AddCleanup(function()
    if shared.SilenceMuscleLegendsWindow == silence then
        shared.SilenceMuscleLegendsWindow = nil
    end
end)


local ui = {}
ui.Raw = silence
setmetatable(ui, {
    __index = function(_, key)
        local raw = rawget(ui, key)
        if raw ~= nil then
            return raw
        end
        local value = silence[key]
        if type(value) == "function" then
            return function(_, ...)
                return value(silence, ...)
            end
        end
        return value
    end,
})

local mainSection = silence:Section({
    Title = "Main",
    Icon = "lucide:house",
    Opened = true
})

function ui:Tab(options)
    return wrapTab(mainSection:Tab(options))
end

function ui:RegisterConfig(name, getter, setter)
    return configManager:Register(name, getter, setter)
end

function ui:GetConfigValues()
    return collectConfigValues()
end

function ui:ApplyConfigValues(values)
    return applyConfigValues(values)
end

utils.silence = ui
utils.configManager = configManager

local tabs = {
    main = ui:Tab({Title = "Main", Icon = "lucide:house", Border = true}),
    killing = ui:Tab({Title = "Killing", Icon = "lucide:swords", Border = true}),
    specs = ui:Tab({Title = "Specs", Icon = "lucide:eye", Border = true}),
    farming = ui:Tab({Title = "Farming", Icon = "lucide:sprout", Border = true}),
    boss = ui:Tab({Title = "Boss", Icon = "lucide:skull", Border = true}),
    inventory = ui:Tab({Title = "Pets", Icon = "lucide:paw-print", Border = true}),
    boosts = ui:Tab({Title = "Boosts", Icon = "lucide:zap", Border = true}),
    teleport = ui:Tab({Title = "Teleports", Icon = "lucide:map", Border = true}),
    stats = ui:Tab({Title = "Stats", Icon = "lucide:chart-no-axes-column", Border = true})
}

local customizeTab = ui:Tab({Title = "Customize", Icon = "lucide:palette", Border = true})
local themeNames = {}
for themeName in pairs(WindUI:GetThemes()) do
    table.insert(themeNames, tostring(themeName))
end
table.sort(themeNames)
customizeTab.Raw:Dropdown({
    Title = "Theme",
    Values = themeNames,
    Value = "Crimson",
    Callback = function(themeName)
        pcall(function()
            WindUI:SetTheme(themeName)
        end)
    end,
})
customizeTab.Raw:Paragraph({
    Title = "Window Transparency",
    Desc = "Themes are applied instantly to the whole interface."
})
customizeTab.Raw:Button({
    Title = "Reopen Window",
    Callback = function()
        pcall(function()
            silence:Open()
        end)
    end
})

local configTab = ui:Tab({Title = "Configs", Icon = "lucide:settings-2", Border = true})
configTab.Raw:Paragraph({
    Title = "Configs",
    Desc = "Settings are saved automatically to " .. CONFIG_FILE
})
configTab.Raw:Button({
    Title = "Save Config",
    Callback = function()
        writeConfigNow()
    end
})
configTab.Raw:Button({
    Title = "Load Config",
    Callback = function()
        applyConfigValues(readConfigFile())
    end
})
configTab.Raw:Button({
    Title = "Delete Config",
    Callback = function()
        if type(delfile) == "function" and type(isfile) == "function" and isfile(CONFIG_FILE) then
            pcall(delfile, CONFIG_FILE)
        end
    end
})

tabs.customize = customizeTab
tabs.configs = configTab
tabs.info = ui:Tab({Title = "Info", Icon = "lucide:info", Border = true})

runtime:Spawn(function()
    while runtime.Alive do
        task.wait(60)
        pcall(function()
            silence:SetTitle("Silence - Muscle Legends")
        end)
    end
end)

tabs.main:Select()

for _, tab in pairs(tabs) do
	tab.runtime = {}
end

tabs.main:AddHeading("User Settings:")

tabs.main.Settings = {
	Size = {Value = 2, Enabled = false},
	Speed = {Value = 120, Enabled = false},
	FOV = {Value = 70, Enabled = false}
}

tabs.main:AddTextBox("Size:", function(text)
	text = string.gsub(text, "%s+", "")
	if tonumber(text) and tonumber(text) > 0 then
		tabs.main.Settings.Size.Value = tonumber(text)
	end
end, {clear = false})

tabs.main:AddSwitch("Set Size", function(bool)
	tabs.main.Settings.Size.Enabled = bool
end)

runtime:Spawn(function()
	while true do
		if tabs.main.Settings.Size.Enabled and utils.playerData.Character and utils.playerData.Humanoid then
			utils.remotes.ChangeSpeedSize:InvokeServer("changeSize", tabs.main.Settings.Size.Value)
		end
		task.wait(0.01)
	end
end)

tabs.main:AddTextBox("Speed:", function(text)
	text = string.gsub(text, "%s+", "")
	if tonumber(text) and tonumber(text) > 0 then
		tabs.main.Settings.Speed.Value = tonumber(text)
	end
end, {clear = false})

tabs.main:AddSwitch("Set Speed", function(bool)
	tabs.main.Settings.Speed.Enabled = bool
end)

runtime:Spawn(function()
	while true do
		if tabs.main.Settings.Speed.Enabled and utils.playerData.Character and utils.playerData.Humanoid then
			utils.remotes.ChangeSpeedSize:InvokeServer("changeSpeed", tabs.main.Settings.Speed.Value)
		end
		task.wait(0.01)
	end
end)

if utils.playerData.Camera then
	tabs.main:AddTextBox("FOV:", function(text)
		text = string.gsub(text, "%s+", "")
		if tonumber(text) and tonumber(text) >= 1 and tonumber(text) <= 120 then
			tabs.main.Settings.FOV.Value = tonumber(text)
		end
	end, {clear = false})

	tabs.main:AddSwitch("Set FOV", function(bool)
		tabs.main.Settings.FOV.Enabled = bool
		utils.playerData.Camera.FieldOfView = bool and tabs.main.Settings.FOV.Value or 70
	end)

	runtime:Spawn(function()
		while true do
			if tabs.main.Settings.FOV.Enabled and utils.playerData.Camera then
				utils.playerData.Camera.FieldOfView = tabs.main.Settings.FOV.Value
			end
			task.wait(0.01)
		end
	end)
end

tabs.main:AddHeading("Protection and Visuals:")

tabs.main.Protection = {
	AntiFling = {Enabled = false},
	PositionLock = {Enabled = false, Position = nil}
}

tabs.main.enableAntiFling = function()
	if not tabs.main.Protection.AntiFling.Enabled or not utils.playerData.Player.Character then return end
	if not utils.playerData.Player.Character:FindFirstChild("HumanoidRootPart") then return end
	if utils.playerData.Player.Character.HumanoidRootPart:FindFirstChild("BodyVelocity") and
	   utils.playerData.Player.Character.HumanoidRootPart.BodyVelocity.MaxForce == Vector3.new(100000, 0, 100000) then
		utils.playerData.Player.Character.HumanoidRootPart.BodyVelocity:Destroy()
	end
	tabs.main.runtime.bv = Instance.new("BodyVelocity")
	tabs.main.runtime.bv.MaxForce = Vector3.new(100000, 0, 100000)
	tabs.main.runtime.bv.Velocity = Vector3.new(0, 0, 0)
	tabs.main.runtime.bv.P = 1250
	tabs.main.runtime.bv.Parent = utils.playerData.Player.Character.HumanoidRootPart
end

tabs.main.disableAntiFling = function()
	if not utils.playerData.Player.Character or not utils.playerData.Player.Character:FindFirstChild("HumanoidRootPart") then return end
	if utils.playerData.Player.Character.HumanoidRootPart:FindFirstChild("BodyVelocity") and
	   utils.playerData.Player.Character.HumanoidRootPart.BodyVelocity.MaxForce == Vector3.new(100000, 0, 100000) then
		utils.playerData.Player.Character.HumanoidRootPart.BodyVelocity:Destroy()
	end
end

tabs.main:AddSwitch("Anti Fling", function(bool)
	tabs.main.Protection.AntiFling.Enabled = bool
	if bool then tabs.main.enableAntiFling() else tabs.main.disableAntiFling() end
end):Set(true)

runtime:Connect(utils.playerData.Player.CharacterAdded, function(newChar)
	newChar:WaitForChild("HumanoidRootPart", 5)
	if tabs.main.Protection.AntiFling.Enabled then tabs.main.enableAntiFling() end
end)

tabs.main.lockPosition = function()
	tabs.main.enableAntiFling()
	if not tabs.main.Protection.PositionLock.Enabled or not tabs.main.Protection.PositionLock.Position or not utils.playerData.Player.Character then return end
	if not utils.playerData.Player.Character:FindFirstChild("HumanoidRootPart") then return end
	if utils.playerData.Player.Character.HumanoidRootPart:FindFirstChild("PositionLocker") then
		utils.playerData.Player.Character.HumanoidRootPart.PositionLocker.Position = tabs.main.Protection.PositionLock.Position
	else
		tabs.main.disableAntiFling()
		tabs.main.runtime.bp = Instance.new("BodyPosition")
		tabs.main.runtime.bp.Name = "PositionLocker"
		tabs.main.runtime.bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		tabs.main.runtime.bp.Position = tabs.main.Protection.PositionLock.Position
		tabs.main.runtime.bp.P = 100000
		tabs.main.runtime.bp.Parent = utils.playerData.Player.Character.HumanoidRootPart
	end
end

tabs.main.unlockPosition = function()
	if utils.playerData.Player.Character and utils.playerData.Player.Character:FindFirstChild("HumanoidRootPart") then
		if utils.playerData.Player.Character.HumanoidRootPart:FindFirstChild("PositionLocker") then
			utils.playerData.Player.Character.HumanoidRootPart.PositionLocker:Destroy()
		end
	end
	tabs.main.Protection.PositionLock.Position = nil
end

tabs.main:AddSwitch("Lock Position", function(bool)
	tabs.main.Protection.PositionLock.Enabled = bool
	if bool then
		if utils.playerData.Player.Character and utils.playerData.Player.Character:FindFirstChild("HumanoidRootPart") then
			tabs.main.Protection.PositionLock.Position = utils.playerData.Player.Character.HumanoidRootPart.Position
		end
		tabs.main.lockPosition()
	else
		tabs.main.unlockPosition()
	end
end)

tabs.main.VisibilitySettings = {
	{Name = "Show Pets", GuiName = "MyPetsBase", Enabled = false},
	{Name = "Show Other Pets", GuiName = "OtherPets", Enabled = false},
	{Name = "Show PopUps", GuiName = "PopUps", Enabled = false}
}

tabs.main.syncVisibilitySetting = function(setting, success, connections)
	if not setting.OnText or not setting.OnText.Parent or not setting.Button or not setting.Button.Parent
		or setting.Pending or setting.OnText.Visible == setting.Enabled then return end
	if type(firesignal) ~= "function" or type(getconnections) ~= "function" then return end
	for _, button in ipairs({setting.Button, setting.Button:FindFirstChild(setting.OnText.Visible and "OnButton" or "OffButton")}) do
		for _, eventName in ipairs({"MouseButton1Click", "Activated"}) do
			success, connections = pcall(getconnections, button[eventName])
			if success and type(connections) == "table" then
				for _, connection in ipairs(connections) do
					if connection.Enabled ~= false then
						setting.Pending = true
						if pcall(firesignal, button[eventName]) then return end
						setting.Pending = false
					end
				end
			end
		end
	end
end

tabs.main.bindVisibilitySetting = function(setting, node, onText, button)
	node = utils.playerData.Player
	for _, childName in ipairs({"PlayerGui", "gameGui", "settingsNewMenu", "Content", "ListLayout", "ScrollingFrame", setting.GuiName}) do
		node = node:WaitForChild(childName, 10)
		if not node then return end
	end
	onText = node:WaitForChild("OnText", 10)
	button = node:WaitForChild("Switch", 10)
	if not onText or not button then return end
	if setting.OnText ~= onText or setting.Button ~= button then
		if setting.Connection then setting.Connection:Disconnect() end
		setting.OnText = onText
		setting.Button = button
		setting.Pending = false
		setting.Connection = runtime:Connect(onText:GetPropertyChangedSignal("Visible"), function()
			setting.Pending = false
			runtime:Defer(tabs.main.syncVisibilitySetting, setting)
		end)
	end
	tabs.main.syncVisibilitySetting(setting)
end

for _, setting in ipairs(tabs.main.VisibilitySettings) do
	setting.Switch = tabs.main:AddSwitch(setting.Name, function(state)
		setting.Enabled = state
		tabs.main.syncVisibilitySetting(setting)
	end)
	setting.Switch:Set(false)
	runtime:Spawn(tabs.main.bindVisibilitySetting, setting)
end
runtime:Connect(utils.playerData.Player.CharacterAdded, function()
	for _, setting in ipairs(tabs.main.VisibilitySettings) do
		runtime:Spawn(tabs.main.bindVisibilitySetting, setting)
	end
end)

tabs.main.RedactConfigPath = "Silence/MuscleLegendsMainConfig.json"
tabs.main.RedactConfig = {
	RedactName = false,
	RedactStats = false,
}

tabs.main.loadRedactConfig = function()
	if type(isfile) ~= "function" or type(readfile) ~= "function" then return end
	pcall(function()
		if not isfile(tabs.main.RedactConfigPath) then return end
		tabs.main.runtime.savedRedactConfig = services.HttpService:JSONDecode(readfile(tabs.main.RedactConfigPath))
		if typeof(tabs.main.runtime.savedRedactConfig) == "table" then
			tabs.main.RedactConfig.RedactName = tabs.main.runtime.savedRedactConfig.RedactName == true
			tabs.main.RedactConfig.RedactStats = tabs.main.runtime.savedRedactConfig.RedactStats == true
		end
	end)
end

tabs.main.saveRedactConfig = function()
	if type(writefile) ~= "function" then return end
	pcall(function()
		if type(makefolder) == "function"
			and (type(isfolder) ~= "function" or not isfolder("Silence")) then
			pcall(makefolder, "Silence")
		end
		writefile(tabs.main.RedactConfigPath, services.HttpService:JSONEncode(tabs.main.RedactConfig))
	end)
end

tabs.main.NameVisibility = {Character = nil, Connections = {}, Guis = {}, Watches = {}}

tabs.main.clearNameVisibility = function()
    local state = tabs.main.NameVisibility
    for _, connection in ipairs(state.Connections) do
        connection:Disconnect()
        runtime.Connections[connection] = nil
    end
    table.clear(state.Connections)
    for gui, connection in pairs(state.Watches) do
        connection:Disconnect()
        runtime.Connections[connection] = nil
        state.Watches[gui] = nil
    end
    for gui, wasEnabled in pairs(state.Guis) do
        if gui.Parent then gui.Enabled = wasEnabled end
    end
    table.clear(state.Guis)
    state.Character = nil
end
runtime:AddCleanup(tabs.main.clearNameVisibility)

tabs.main.applyNameVisibility = function()
    local state = tabs.main.NameVisibility
    local character = utils.playerData.Player.Character
    if state.Character ~= character then
        tabs.main.clearNameVisibility()
        state.Character = character
        if character then
            local function watchNameGui(gui)
                if not gui:IsA("BillboardGui") or gui.Name ~= "nameGui" or state.Guis[gui] ~= nil then return end
                state.Guis[gui] = gui.Enabled
                state.Watches[gui] = runtime:Connect(gui:GetPropertyChangedSignal("Enabled"), function()
                    if tabs.main.RedactConfig.RedactName and gui.Enabled then gui.Enabled = false end
                end)
                if tabs.main.RedactConfig.RedactName then gui.Enabled = false end
            end
            table.insert(state.Connections, runtime:Connect(character.DescendantAdded, watchNameGui))
            table.insert(state.Connections, runtime:Connect(character.DescendantRemoving, function(gui)
                if state.Guis[gui] ~= nil then
                    local connection = state.Watches[gui]
                    if connection then connection:Disconnect(); runtime.Connections[connection] = nil end
                    state.Watches[gui] = nil
                    gui.Enabled = state.Guis[gui]
                    state.Guis[gui] = nil
                end
            end))
            for _, gui in ipairs(character:GetDescendants()) do watchNameGui(gui) end
        end
    end
    for gui, wasEnabled in pairs(state.Guis) do
        if gui.Parent then gui.Enabled = not tabs.main.RedactConfig.RedactName and wasEnabled end
    end
end

tabs.main.applyStatsVisibility = function()
	pcall(function()
		utils.playerData.Player.PlayerGui.gameGui.hudNewMenu.Top.InfoSlots.Visible = not tabs.main.RedactConfig.RedactStats
	end)
	pcall(function() services.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, not tabs.main.RedactConfig.RedactStats) end)
end

tabs.main.loadRedactConfig()
tabs.main.HideNameSwitch = tabs.main:AddSwitch("Hide Name", function(state)
	tabs.main.RedactConfig.RedactName = state
	tabs.main.applyNameVisibility()
	tabs.main.saveRedactConfig()
end)
tabs.main.HideNameSwitch:Set(tabs.main.RedactConfig.RedactName)
tabs.main.RedactStatsSwitch = tabs.main:AddSwitch("Hide Stats", function(state)
	tabs.main.RedactConfig.RedactStats = state
	tabs.main.applyStatsVisibility()
	tabs.main.saveRedactConfig()
end)
tabs.main.RedactStatsSwitch:Set(tabs.main.RedactConfig.RedactStats)

runtime:Connect(utils.playerData.Player.CharacterAdded, function()
    runtime:Defer(tabs.main.applyStatsVisibility)
    tabs.main.applyNameVisibility()
end)

runtime:Connect(utils.playerData.Player.CharacterAdded, function(newChar)
	if tabs.main.Protection.PositionLock.Enabled and newChar:WaitForChild("HumanoidRootPart", 5) then
		tabs.main.Protection.PositionLock.Position = newChar.HumanoidRootPart.Position
		tabs.main.lockPosition()
	end
end)

runtime:Spawn(function()
	while true do
		if tabs.main.Protection.PositionLock.Enabled then tabs.main.lockPosition() end
		task.wait(0.1)
	end
end)

tabs.main.WaterParts = {
	Parts = {},
	PartSize = 2048,
	TotalDistance = 50000,
	StartPosition = Vector3.new(-2, -9.5, -2)
}

runtime:Spawn(function()
	for x = 0, math.ceil(tabs.main.WaterParts.TotalDistance / tabs.main.WaterParts.PartSize) - 1 do
		for z = 0, math.ceil(tabs.main.WaterParts.TotalDistance / tabs.main.WaterParts.PartSize) - 1 do
			for i, offset in ipairs({
				{x * tabs.main.WaterParts.PartSize, z * tabs.main.WaterParts.PartSize, "Side_" .. x .. "_" .. z},
				{-x * tabs.main.WaterParts.PartSize, z * tabs.main.WaterParts.PartSize, "LeftRight_" .. x .. "_" .. z},
				{-x * tabs.main.WaterParts.PartSize, -z * tabs.main.WaterParts.PartSize, "UpLeft_" .. x .. "_" .. z},
				{x * tabs.main.WaterParts.PartSize, -z * tabs.main.WaterParts.PartSize, "UpRight_" .. x .. "_" .. z}
			}) do
				tabs.main.runtime.part = Instance.new("Part")
				tabs.main.runtime.part.Size = Vector3.new(tabs.main.WaterParts.PartSize, 1, tabs.main.WaterParts.PartSize)
				tabs.main.runtime.part.Position = tabs.main.WaterParts.StartPosition + Vector3.new(offset[1], 0, offset[2])
				tabs.main.runtime.part.Anchored = true
				tabs.main.runtime.part.Transparency = 1
				tabs.main.runtime.part.CanCollide = true
				tabs.main.runtime.part.Name = "Part_" .. offset[3]
				tabs.main.runtime.part.Parent = services.Workspace
				table.insert(tabs.main.WaterParts.Parts, tabs.main.runtime.part)
			end
		end
	end
end)

tabs.main.WalkOnWaterSwitch = tabs.main:AddSwitch("Walk on Water", function(bool)
	for _, part in ipairs(tabs.main.WaterParts.Parts) do
		if part and part.Parent then part.CanCollide = bool end
	end
end)
tabs.main.WalkOnWaterSwitch:Set(true)

tabs.main:AddHeading("Other:")

tabs.main:AddSwitch("Infinite Jump", function(bool)
	tabs.main.InfiniteJump = bool
end)
runtime:Connect(services.UserInputService.JumpRequest, function(character, humanoid)
	character = utils.playerData.Player.Character
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if tabs.main.InfiniteJump and humanoid and humanoid.Health > 0 then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

tabs.main.FortuneWheelData = {
	Running = false,
	Generation = 0,
	Remote = services.ReplicatedStorage.rEvents:WaitForChild("openFortuneWheelRemote"),
	Chances = services.ReplicatedStorage
		:WaitForChild("shared")
		:WaitForChild("catalogs")
		:WaitForChild("fortuneWheelChances")
		:WaitForChild("Fortune Wheel")
}

tabs.main.spinFortuneWheel = function()
	pcall(function()
		tabs.main.FortuneWheelData.Remote:InvokeServer(
			"openFortuneWheel",
			tabs.main.FortuneWheelData.Chances
		)
	end)
end

tabs.main:AddSwitch("Spin Fortune Wheel", function(state)
	tabs.main.FortuneWheelData.Running = state
	tabs.main.FortuneWheelData.Generation += 1
	tabs.main.runtime.generation = tabs.main.FortuneWheelData.Generation

	if not state then return end

	runtime:Spawn(function(generation)
		while tabs.main.FortuneWheelData.Running and tabs.main.FortuneWheelData.Generation == generation do
			tabs.main.spinFortuneWheel()
			task.wait(1)
		end
	end, tabs.main.FortuneWheelData.Generation)
end)

tabs.main.TimeDropdown = tabs.main:AddDropdown("Change Time", function(selection)
	services.Lighting.ClockTime = selection == "Night" and 0 or 9
end)
tabs.main.TimeDropdown:Add("Night")
tabs.main.TimeDropdown:Add("Day")

do
    local function createShaderController()
        local Lighting = game:GetService("Lighting")
        local properties = {"Ambient", "OutdoorAmbient", "Brightness", "ClockTime", "ExposureCompensation", "ColorShift_Top", "ColorShift_Bottom", "FogColor", "FogStart", "FogEnd", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "GlobalShadows"}
        local atmosphereProperties = {"Density", "Offset", "Color", "Decay", "Glare", "Haze"}
        local original, originalEffects = {}, {}
        for _, key in ipairs(properties) do original[key] = Lighting[key] end
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") and not effect:IsA("BlurEffect") then originalEffects[effect] = effect.Enabled end
        end
        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        local ownedAtmosphere = atmosphere == nil
        if ownedAtmosphere then atmosphere = Instance.new("Atmosphere"); atmosphere.Name = "SilenceShaderAtmosphere" end
        local originalAtmosphere = {}
        for _, key in ipairs(atmosphereProperties) do originalAtmosphere[key] = atmosphere[key] end
        local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
        local presets = {
            {Name="Clean Day", Description="Clear daylight with neutral colors", Time=14, Exposure=.08, Saturation=.08, Contrast=.06, Tint=rgb(255,255,255), Density=.08, Haze=.3},
            {Name="Soft Realism", Description="Soft daylight, gentle contrast and restrained bloom", Time=14.5, Exposure=.04, Saturation=-.04, Contrast=.10, Tint=rgb(255,249,239), Density=.14, Haze=.7},
            {Name="Vibrant", Description="Bright colors and a crisp, lively image", Time=13, Exposure=.12, Saturation=.35, Contrast=.13, Tint=rgb(255,253,247), Density=.10, Haze=.2, Bloom=.32},
            {Name="Golden Hour", Description="Low golden sunlight with warm shadows", Time=17.3, Exposure=.12, Saturation=.15, Contrast=.14, Tint=rgb(255,225,181), Density=.22, Haze=1.2, Air=rgb(255,210,155), Rays=.12},
            {Name="Warm Sunset", Description="An orange-pink sunset with a soft glow", Time=17.9, Exposure=.05, Saturation=.22, Contrast=.17, Tint=rgb(255,205,177), Density=.28, Haze=1.5, Air=rgb(255,183,151), Bloom=.45},
            {Name="Tropical", Description="Warm sunshine, turquoise air and saturated greenery", Time=13.5, Exposure=.15, Saturation=.27, Contrast=.10, Tint=rgb(230,255,242), Density=.16, Haze=.7, Air=rgb(174,235,240)},
            {Name="Arctic", Description="Cold blue daylight with pale, crisp highlights", Time=12, Exposure=.12, Saturation=-.16, Contrast=.15, Tint=rgb(203,231,255), Density=.24, Haze=1.1, Air=rgb(195,225,255)},
            {Name="Cloudy", Description="Muted overcast lighting and softer shadows", Time=13, Exposure=-.03, Saturation=-.22, Contrast=-.08, Tint=rgb(229,236,243), Density=.30, Haze=1.8, Rays=0, Brightness=1.6},
            {Name="Cinematic Teal", Description="Cool shadows and warm sunlight", Time=16.5, Exposure=-.05, Saturation=-.15, Contrast=.24, Tint=rgb(199,237,239), Density=.20, Haze=1, Ambient=rgb(62,92,105), Top=rgb(255,177,98)},
            {Name="Noir", Description="Black and white with deep contrast", Time=16, Exposure=-.12, Saturation=-1, Contrast=.36, Tint=rgb(255,255,255), Density=.20, Haze=1.1, Rays=.02},
            {Name="Moonlight", Description="A readable blue night scene", Time=0.5, Exposure=.12, Saturation=-.12, Contrast=.15, Tint=rgb(180,204,255), Density=.18, Haze=.7, Ambient=rgb(70,84,122), Brightness=2, Rays=0},
            {Name="Cyberpunk", Description="Violet night lighting with bright colored highlights", Time=21, Exposure=.02, Saturation=.40, Contrast=.23, Tint=rgb(220,178,255), Density=.26, Haze=1.6, Air=rgb(161,105,224), Ambient=rgb(92,45,140), Bloom=.65, Rays=0},
            {Name="Neon Purple", Description="An exaggerated purple glow for a stylized look", Time=19.2, Exposure=.08, Saturation=.45, Contrast=.18, Tint=rgb(227,169,255), Density=.22, Haze=1.3, Air=rgb(201,145,255), Bloom=.85, Rays=.02},
            {Name="Dreamy", Description="Pink tones, low contrast and soft highlights", Time=16.7, Exposure=.18, Saturation=.08, Contrast=-.12, Tint=rgb(255,218,241), Density=.24, Haze=1.8, Air=rgb(249,207,235), Bloom=.65},
            {Name="Soft Pastel", Description="Gentle colors with a light, airy feel", Time=14, Exposure=.16, Saturation=-.24, Contrast=-.10, Tint=rgb(255,235,224), Density=.15, Haze=1, Bloom=.25},
            {Name="Retro Film", Description="Warm faded colors and lifted shadows", Time=15.7, Exposure=.02, Saturation=-.32, Contrast=-.06, Tint=rgb(255,229,185), Density=.19, Haze=1.1, Ambient=rgb(111,99,82)},
            {Name="Autumn", Description="Copper tones and warm afternoon light", Time=16.8, Exposure=.03, Saturation=.12, Contrast=.16, Tint=rgb(255,207,158), Density=.24, Haze=1.2, Air=rgb(232,186,137)},
            {Name="Desert", Description="Hot golden light with dusty atmosphere", Time=15.3, Exposure=.18, Saturation=.08, Contrast=.20, Tint=rgb(255,229,173), Density=.32, Haze=2, Air=rgb(231,203,158), Rays=.10},
            {Name="Horror", Description="Dark green fog and subdued colors", Time=23, Exposure=-.22, Saturation=-.40, Contrast=.28, Tint=rgb(185,218,187), Density=.40, Haze=2.4, Air=rgb(122,156,132), Ambient=rgb(40,62,49), Brightness=1.2, Rays=0},
            {Name="Volcanic", Description="Dark red and orange lighting with strong highlights", Time=18.5, Exposure=-.12, Saturation=.22, Contrast=.30, Tint=rgb(255,171,133), Density=.32, Haze=1.9, Air=rgb(210,104,72), Ambient=rgb(108,42,32), Bloom=.60, Rays=.02},
        }
        local correction = Instance.new("ColorCorrectionEffect")
        correction.Name = "SilenceShaderColor"
        local bloom = Instance.new("BloomEffect")
        bloom.Name = "SilenceShaderBloom"
        local rays = Instance.new("SunRaysEffect")
        rays.Name = "SilenceShaderRays"
        local depth = Instance.new("DepthOfFieldEffect")
        depth.Name = "SilenceShaderDepth"
        local effects = {correction,bloom,rays,depth}
        for _, effect in ipairs(effects) do effect.Enabled=false; effect.Parent=Lighting end
        local state={Enabled=false, Index=2, Intensity=75, Bloom=true, Rays=true, Atmosphere=true, Depth=false}
        local function restore()
            for _, effect in ipairs(effects) do effect.Enabled=false end
            for key,value in pairs(original) do Lighting[key]=value end
            for effect,enabled in pairs(originalEffects) do if effect.Parent then effect.Enabled=enabled end end
            if ownedAtmosphere then
                atmosphere.Parent=nil
            else
                for key,value in pairs(originalAtmosphere) do atmosphere[key]=value end
            end
        end
        local function mix(a,b,t)
            if typeof(a)=="Color3" then return a:Lerp(b,t) end
            return a+(b-a)*t
        end
        local function apply()
            local preset=presets[state.Index]
            if not state.Enabled or state.Intensity==0 then
                restore()
                return
            end
            local alpha=state.Intensity/100
            for effect in pairs(originalEffects) do if effect.Parent then effect.Enabled=false end end
            local targets={
                Brightness=preset.Brightness or 2.2, ExposureCompensation=preset.Exposure or 0,
                Ambient=preset.Ambient or rgb(91,97,109), OutdoorAmbient=preset.Ambient or rgb(125,133,148),
                ColorShift_Top=preset.Top or rgb(0,0,0), ColorShift_Bottom=rgb(0,0,0),
                FogColor=preset.Air or rgb(192,218,240), FogStart=0, FogEnd=100000,
                EnvironmentDiffuseScale=.8,EnvironmentSpecularScale=.7,
            }
            for key,value in pairs(targets) do Lighting[key]=mix(original[key],value,alpha) end
            local clockDelta=(preset.Time-original.ClockTime+12)%24-12
            Lighting.ClockTime=(original.ClockTime+clockDelta*alpha)%24
            Lighting.GlobalShadows=true
            correction.TintColor=mix(Color3.new(1,1,1),preset.Tint,alpha)
            correction.Contrast=(preset.Contrast or 0)*alpha
            correction.Saturation=(preset.Saturation or 0)*alpha
            correction.Brightness=0
            correction.Enabled=true
            bloom.Intensity=(preset.Bloom or .22)*alpha
            bloom.Size=28
            bloom.Threshold=1.25
            bloom.Enabled=state.Bloom
            rays.Intensity=(preset.Rays or .05)*alpha
            rays.Spread=.75
            rays.Enabled=state.Rays and rays.Intensity>0
            depth.FocusDistance=55
            depth.InFocusRadius=45
            depth.NearIntensity=.02*alpha
            depth.FarIntensity=.16*alpha
            depth.Enabled=state.Depth
            if state.Atmosphere then
                atmosphere.Density=mix(ownedAtmosphere and 0 or originalAtmosphere.Density,preset.Density or .15,alpha)
                atmosphere.Offset=0
                atmosphere.Color=mix(originalAtmosphere.Color,preset.Air or rgb(199,222,245),alpha)
                atmosphere.Decay=mix(originalAtmosphere.Decay,preset.Air or rgb(133,153,184),alpha)
                atmosphere.Glare=.15*alpha
                atmosphere.Haze=(preset.Haze or .7)*alpha
                if ownedAtmosphere then atmosphere.Parent=Lighting end
            elseif ownedAtmosphere then
                atmosphere.Parent=nil
            else
                for key,value in pairs(originalAtmosphere) do atmosphere[key]=value end
            end
        end
        local controller = {Presets = presets, Selected = "Original", Names = {"Original"}}
        for _, preset in ipairs(presets) do table.insert(controller.Names, preset.Name) end
        function controller:Select(name)
            if name == "Original" then
                state.Enabled = false
                self.Selected = name
                restore()
                return
            end
            for index, preset in ipairs(presets) do
                if preset.Name == name then
                    state.Index = index
                    state.Intensity = preset.Intensity or 75
                    state.Enabled = true
                    state.Bloom, state.Rays, state.Atmosphere, state.Depth = true, true, true, false
                    apply()
                    self.Selected = name
                    return
                end
            end
            error("Unknown shader preset: " .. tostring(name))
        end
        runtime:AddCleanup(function()
            restore()
            for _, effect in ipairs(effects) do effect:Destroy() end
            if ownedAtmosphere then atmosphere:Destroy() end
        end)
        return controller
    end
    tabs.main.Shaders = createShaderController()
    tabs.main.ShaderDropdown = tabs.main:AddDropdown("Shader", function(selection)
        tabs.main.Shaders:Select(selection)
    end)
    for _, name in ipairs(tabs.main.Shaders.Names) do tabs.main.ShaderDropdown:Add(name) end
    tabs.main.ShaderDropdown:SetValue("Original")
    tabs.main.ShaderButtons = tabs.main:AddHorizontalAlignment()
    local function stepPreset(direction)
        local names = tabs.main.Shaders.Names
        local current = table.find(names, tabs.main.Shaders.Selected) or 1
        tabs.main.ShaderDropdown:SetValue(names[(current - 1 + direction) % #names + 1])
    end
    tabs.main.ShaderButtons:AddButton("Previous", function() stepPreset(-1) end)
    tabs.main.ShaderButtons:AddButton("Next", function() stepPreset(1) end)
end

tabs.killing.getTool = function()
	if not services.Players.LocalPlayer.Character then return end
	for _, v in pairs(services.Players.LocalPlayer.Backpack:GetChildren()) do
		if v.Name == "Punch" and services.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
			services.Players.LocalPlayer.Character.Humanoid:EquipTool(v)
		end
	end
	services.Players.LocalPlayer.muscleEvent:FireServer("punch", "leftHand")
	services.Players.LocalPlayer.muscleEvent:FireServer("punch", "rightHand")
end

tabs.killing.isPlayerAlive = function(player)
	return player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and
		player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0
end

tabs.killing.isSpawnProtected = function(player)
	if not player or not player.Character then return false end
	if player.Character:FindFirstChildOfClass("ForceField")
		or player.Character:FindFirstChild("spawnProtectionHighlight") then
		return true
	end
	tabs.killing.runtime.protectedUntil = player.Character:GetAttribute("SpawnProtectedUntil")
	return typeof(tabs.killing.runtime.protectedUntil) == "number" and services.Workspace:GetServerTimeNow() < tabs.killing.runtime.protectedUntil
end

tabs.killing.getLocalCombatCharacter = function()
	tabs.killing.runtime.character_416 = services.Players.LocalPlayer.Character
	tabs.killing.runtime.humanoid_417 = tabs.killing.runtime.character_416 and tabs.killing.runtime.character_416:FindFirstChildOfClass("Humanoid")
	tabs.killing.runtime.humanoidRootPart = tabs.killing.runtime.character_416 and tabs.killing.runtime.character_416:FindFirstChild("HumanoidRootPart")
	if not tabs.killing.runtime.character_416 or not tabs.killing.runtime.humanoid_417 or tabs.killing.runtime.humanoid_417.Health <= 0 or not tabs.killing.runtime.humanoidRootPart then return end
	return tabs.killing.runtime.character_416, tabs.killing.runtime.humanoid_417, tabs.killing.runtime.humanoidRootPart
end

tabs.killing.positionNearTarget = function(target, heightOffset)
	if not tabs.killing.isPlayerAlive(target)
		or tabs.killing.isSpawnProtected(target)
		or tabs.killing.isSpawnProtected(services.Players.LocalPlayer) then
		return false
	end
	tabs.killing.runtime.discardCharacter_localRoot_429, tabs.killing.runtime.discardHumanoid_localRoot_429, tabs.killing.runtime.localRoot_429 = tabs.killing.getLocalCombatCharacter()
	tabs.killing.runtime.targetRoot_430 = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if not tabs.killing.runtime.localRoot_429 or not tabs.killing.runtime.targetRoot_430 then return false end

	tabs.killing.runtime.localRoot_429.CFrame = tabs.killing.runtime.targetRoot_430.CFrame * CFrame.new(0, heightOffset, 0)
	tabs.killing.runtime.localRoot_429.AssemblyLinearVelocity = Vector3.zero
	tabs.killing.runtime.localRoot_429.AssemblyAngularVelocity = Vector3.zero
	return true
end

tabs.killing.touchAndPunchTarget = function(target, heightOffset)
	if not tabs.killing.positionNearTarget(target, heightOffset) then return false, false end
	services.RunService.Heartbeat:Wait()
	if not tabs.killing.positionNearTarget(target, heightOffset) then return false, false end

	tabs.killing.runtime.character_444 = tabs.killing.getLocalCombatCharacter()
	tabs.killing.runtime.targetRoot_445 = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	tabs.killing.runtime.targetHumanoid_446 = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
	if not tabs.killing.runtime.character_444 or not tabs.killing.runtime.targetRoot_445 or not tabs.killing.runtime.targetHumanoid_446 or tabs.killing.isSpawnProtected(target) then return false, false end

	tabs.killing.runtime.hand = tabs.killing.runtime.character_444:FindFirstChild("LeftHand") or tabs.killing.runtime.character_444:FindFirstChild("RightHand")
	if not tabs.killing.runtime.hand then return false, false end

	tabs.killing.runtime.punchTool = tabs.killing.runtime.character_444:FindFirstChild("Punch") or services.Players.LocalPlayer.Backpack:FindFirstChild("Punch")
	tabs.killing.runtime.humanoid_453 = tabs.killing.runtime.character_444:FindFirstChildOfClass("Humanoid")
	if tabs.killing.runtime.punchTool and tabs.killing.runtime.punchTool.Parent ~= tabs.killing.runtime.character_444 and tabs.killing.runtime.humanoid_453 then
		tabs.killing.runtime.humanoid_453:EquipTool(tabs.killing.runtime.punchTool)
	end

	tabs.killing.runtime.healthBefore = tabs.killing.runtime.targetHumanoid_446.Health
	tabs.killing.runtime.attempted_459 = pcall(function()
		utils.touchParts(tabs.killing.runtime.targetRoot_445, tabs.killing.runtime.hand, 0)
		utils.touchParts(tabs.killing.runtime.targetRoot_445, tabs.killing.runtime.hand, 1)
		services.Players.LocalPlayer.muscleEvent:FireServer("punch", tabs.killing.runtime.hand.Name == "LeftHand" and "leftHand" or "rightHand")
	end)
	if not tabs.killing.runtime.attempted_459 then return false, false end

	for _ = 1, 4 do
		services.RunService.Heartbeat:Wait()
		if not tabs.killing.isPlayerAlive(target) or tabs.killing.runtime.targetHumanoid_446.Health < tabs.killing.runtime.healthBefore then
			return true, true
		end
		if tabs.killing.isSpawnProtected(target) then
			return false, false
		end
	end

	return false, true
end

tabs.killing.attackPlayerWithLimit = function(target, hitLimit, shouldContinue, heightOffset, countAttempts, hits, hitRegistered, attempted)
	hits = 0
	while hits < hitLimit and shouldContinue() and tabs.killing.isPlayerAlive(target) and not tabs.killing.isSpawnProtected(target) do
		hitRegistered, attempted = tabs.killing.touchAndPunchTarget(target, heightOffset)
		if countAttempts or hitRegistered then hits = hits + 1 end
		if not attempted and not countAttempts then break end
		if not hitRegistered then task.wait(0.05) end
	end
	return hits
end

tabs.killing.attackPlayerForDuration = function(target, duration, shouldContinue, heightOffset, startedAt, character, targetRoot, leftHand, rightHand, punchTool, humanoid)
	startedAt = os.clock()
	while os.clock() - startedAt < duration
		and shouldContinue()
		and tabs.killing.isPlayerAlive(target)
		and not tabs.killing.isSpawnProtected(target) do
		if tabs.killing.positionNearTarget(target, heightOffset) then
			character = services.Players.LocalPlayer.Character
			targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
			leftHand = character and character:FindFirstChild("LeftHand")
			rightHand = character and character:FindFirstChild("RightHand")
			punchTool = character and character:FindFirstChild("Punch") or services.Players.LocalPlayer.Backpack:FindFirstChild("Punch")
			humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if punchTool and humanoid and punchTool.Parent ~= character then humanoid:EquipTool(punchTool) end

			if targetRoot and leftHand and rightHand then
				pcall(function()
					utils.touchParts(targetRoot, leftHand, 0)
					utils.touchParts(targetRoot, leftHand, 1)
					utils.touchParts(targetRoot, rightHand, 0)
					utils.touchParts(targetRoot, rightHand, 1)
					services.Players.LocalPlayer.muscleEvent:FireServer("punch", "leftHand")
					services.Players.LocalPlayer.muscleEvent:FireServer("punch", "rightHand")
				end)
			end
		end
		services.RunService.Heartbeat:Wait()
	end
end

tabs.killing:AddHeading("Misc:")

tabs.killing.equipBestStatPets = function(priority)
    for _, folder in ipairs(services.Players.LocalPlayer.petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in ipairs(folder:GetChildren()) do
                services.ReplicatedStorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
            end
        end
    end

	task.wait(0.2)
	tabs.killing.runtime.petsByName = {}
	for _, petName in ipairs(priority) do tabs.killing.runtime.petsByName[petName] = {} end

    for _, folder in ipairs(services.Players.LocalPlayer.petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in ipairs(folder:GetChildren()) do
                if tabs.killing.runtime.petsByName[pet.Name] then
                    table.insert(tabs.killing.runtime.petsByName[pet.Name], pet)
                end
            end
        end
    end

	tabs.killing.runtime.equippedCount = 0
	for _, petName in ipairs(priority) do
		for _, pet in ipairs(tabs.killing.runtime.petsByName[petName]) do
			if tabs.killing.runtime.equippedCount >= 9 then return end
			services.ReplicatedStorage.rEvents.equipPetEvent:FireServer("equipPet", pet)
			tabs.killing.runtime.equippedCount += 1
			task.wait(0.1)
		end
	end
end

tabs.killing:AddButton("Equip Best Damage", function()
	tabs.killing.equipBestStatPets({"Wild Wizard", "Chaos Sorcerer", "Mighty Monster", "Small Fry"})
end)

tabs.killing:AddButton("Equip Best Health", function()
	tabs.killing.equipBestStatPets({"Mighty Monster", "Small Fry", "Wild Wizard", "Chaos Sorcerer"})
end)

tabs.killing:AddSwitch("Remove Attack Animations", function(bool)
	if bool then
		tabs.killing.runtime.blockedAnimations = {
			["3638729053"] = true,
			["3638767427"] = true,
			["507768375"] = true,
			["522635514"] = true,
			["522638767"] = true,
			["182393478"] = true,
			["129967390"] = true,
			["129967478"] = true
		}

		tabs.killing.runtime.shouldBlockAnimation = function(track)
			if not track or not track.Animation then return false end
			tabs.killing.runtime.animationId = tostring(track.Animation.AnimationId):match("%d+")
			tabs.killing.runtime.animationName = string.lower((track.Name or "") .. " " .. (track.Animation.Name or ""))
			return tabs.killing.runtime.blockedAnimations[tabs.killing.runtime.animationId] == true
				or string.find(tabs.killing.runtime.animationName, "punch", 1, true) ~= nil
				or string.find(tabs.killing.runtime.animationName, "attack", 1, true) ~= nil
				or string.find(tabs.killing.runtime.animationName, "right", 1, true) ~= nil
				or string.find(tabs.killing.runtime.animationName, "equip", 1, true) ~= nil
				or string.find(tabs.killing.runtime.animationName, "tool", 1, true) ~= nil
				or string.find(tabs.killing.runtime.animationName, "hold", 1, true) ~= nil
		end

		tabs.killing.runtime.isAttackTool = function(tool)
			if not tool or not tool:IsA("Tool") then return false end
			tabs.killing.runtime.name = string.lower(tool.Name)
			return string.find(tabs.killing.runtime.name, "punch", 1, true) ~= nil
				or string.find(tabs.killing.runtime.name, "attack", 1, true) ~= nil
				or string.find(tabs.killing.runtime.name, "right", 1, true) ~= nil
		end

		tabs.killing.runtime.hasAttackToolEquipped = function(character)
			if not character then return false end
			for _, child in ipairs(character:GetChildren()) do
				if tabs.killing.runtime.isAttackTool(child) then return true end
			end
			return false
		end

		tabs.killing.runtime.isMovementAnimation = function(track, character)
			tabs.killing.runtime.animation = track and track.Animation
			tabs.killing.runtime.animate = character and character:FindFirstChild("Animate")
			if not tabs.killing.runtime.animation or not tabs.killing.runtime.animate or not tabs.killing.runtime.animation:IsDescendantOf(tabs.killing.runtime.animate) then
				return false
			end

			tabs.killing.runtime.path = ""
			tabs.killing.runtime.current = tabs.killing.runtime.animation
			while tabs.killing.runtime.current and tabs.killing.runtime.current ~= tabs.killing.runtime.animate.Parent do
				tabs.killing.runtime.path = tabs.killing.runtime.path .. " " .. string.lower(tabs.killing.runtime.current.Name)
				if tabs.killing.runtime.current == tabs.killing.runtime.animate then break end
				tabs.killing.runtime.current = tabs.killing.runtime.current.Parent
			end

			if string.find(tabs.killing.runtime.path, "tool", 1, true)
				or string.find(tabs.killing.runtime.path, "punch", 1, true)
				or string.find(tabs.killing.runtime.path, "attack", 1, true)
				or string.find(tabs.killing.runtime.path, "equip", 1, true)
				or string.find(tabs.killing.runtime.path, "hold", 1, true) then
				return false
			end

			for _, movementName in ipairs({"idle", "walk", "run", "jump", "fall", "climb", "swim", "sit"}) do
				if string.find(tabs.killing.runtime.path, movementName, 1, true) then return true end
			end
			return false
		end

		tabs.killing.runtime.stopBlockedAnimations = function(character)
			tabs.killing.runtime.humanoid_603 = character and character:FindFirstChildOfClass("Humanoid")
			if not tabs.killing.runtime.humanoid_603 then return end
			for _, track in ipairs(tabs.killing.runtime.humanoid_603:GetPlayingAnimationTracks()) do
				if tabs.killing.runtime.shouldBlockAnimation(track) then track:Stop(0) end
			end
		end

		tabs.killing.runtime.stopEquipAnimations = function(character)
			tabs.killing.runtime.humanoid_611 = character and character:FindFirstChildOfClass("Humanoid")
			if not tabs.killing.runtime.humanoid_611 then return end
			for _, track in ipairs(tabs.killing.runtime.humanoid_611:GetPlayingAnimationTracks()) do
				tabs.killing.runtime.priority = track.Priority
				if tabs.killing.runtime.shouldBlockAnimation(track)
					or not tabs.killing.runtime.isMovementAnimation(track, character)
					or tabs.killing.runtime.priority == Enum.AnimationPriority.Action
					or tabs.killing.runtime.priority == Enum.AnimationPriority.Action2
					or tabs.killing.runtime.priority == Enum.AnimationPriority.Action3
					or tabs.killing.runtime.priority == Enum.AnimationPriority.Action4 then
					track:Stop(0)
				end
			end
		end

		tabs.killing.runtime.setupAnimationBlocking = function()
			tabs.killing.runtime.char_627 = services.Players.LocalPlayer.Character
			tabs.killing.runtime.humanoid_628 = tabs.killing.runtime.char_627 and tabs.killing.runtime.char_627:FindFirstChildOfClass("Humanoid")
			if not tabs.killing.runtime.humanoid_628 then return end

			tabs.killing.runtime.stopBlockedAnimations(tabs.killing.runtime.char_627)
			if _G.AnimBlockConnection then _G.AnimBlockConnection:Disconnect() end
			_G.AnimBlockConnection = runtime:Connect(tabs.killing.runtime.humanoid_628.AnimationPlayed, function(track)
				if tabs.killing.runtime.shouldBlockAnimation(track)
					or (tabs.killing.runtime.hasAttackToolEquipped(tabs.killing.runtime.char_627) and not tabs.killing.runtime.isMovementAnimation(track, tabs.killing.runtime.char_627)) then
					track:Stop(0)
				end
			end)
		end

		tabs.killing.runtime.processTool = function(tool)
			if tabs.killing.runtime.isAttackTool(tool) then
				if not tool:GetAttribute("ActivatedOverride") then
					tool:SetAttribute("ActivatedOverride", true)

					_G.ToolConnections = _G.ToolConnections or {}
					_G.ToolConnections[tool] = runtime:Connect(tool.Activated, function()
						task.wait(0.05)
						tabs.killing.runtime.stopBlockedAnimations(services.Players.LocalPlayer.Character)
					end)

					_G.ToolEquipConnections = _G.ToolEquipConnections or {}
					_G.ToolEquipConnections[tool] = runtime:Connect(tool.Equipped, function()
						for _, delayTime in ipairs({0, 0.03, 0.08, 0.15, 0.25}) do
							runtime:Delay(delayTime, function()
								tabs.killing.runtime.stopEquipAnimations(services.Players.LocalPlayer.Character)
							end)
						end
					end)
				end

				if tool.Parent == services.Players.LocalPlayer.Character then
					tabs.killing.runtime.stopEquipAnimations(services.Players.LocalPlayer.Character)
				end
			end
		end

		tabs.killing.runtime.overrideToolActivation = function()
			for _, tool in pairs(services.Players.LocalPlayer.Backpack:GetChildren()) do
				tabs.killing.runtime.processTool(tool)
			end

			tabs.killing.runtime.char_673 = services.Players.LocalPlayer.Character
			if tabs.killing.runtime.char_673 then
				for _, tool in pairs(tabs.killing.runtime.char_673:GetChildren()) do
					if tool:IsA("Tool") then
						tabs.killing.runtime.processTool(tool)
					end
				end
			end

			_G.BackpackAddedConnection = runtime:Connect(services.Players.LocalPlayer.Backpack.ChildAdded, function(child)
				if child:IsA("Tool") then
					task.wait(0.1)
					tabs.killing.runtime.processTool(child)
				end
			end)

			if tabs.killing.runtime.char_673 then
				_G.CharacterToolAddedConnection = runtime:Connect(tabs.killing.runtime.char_673.ChildAdded, function(child)
					if child:IsA("Tool") then
						task.wait(0.1)
						tabs.killing.runtime.processTool(child)
					end
				end)
			end
		end

		_G.AnimMonitorConnection = runtime:Connect(services.RunService.RenderStepped, function()
			tabs.killing.runtime.character_700 = services.Players.LocalPlayer.Character
			if tabs.killing.runtime.hasAttackToolEquipped(tabs.killing.runtime.character_700) then
				tabs.killing.runtime.stopEquipAnimations(tabs.killing.runtime.character_700)
			else
				tabs.killing.runtime.stopBlockedAnimations(tabs.killing.runtime.character_700)
			end
		end)

		_G.CharacterAddedConnection = runtime:Connect(services.Players.LocalPlayer.CharacterAdded, function(newChar)
			task.wait(1)
			tabs.killing.runtime.setupAnimationBlocking()
			tabs.killing.runtime.overrideToolActivation()

			if _G.CharacterToolAddedConnection then
				_G.CharacterToolAddedConnection:Disconnect()
			end

			_G.CharacterToolAddedConnection = runtime:Connect(newChar.ChildAdded, function(child)
				if child:IsA("Tool") then
					task.wait(0.1)
					tabs.killing.runtime.processTool(child)
				end
			end)
		end)

		tabs.killing.runtime.setupAnimationBlocking()
		tabs.killing.runtime.overrideToolActivation()
	else
		if _G.AnimBlockConnection then
			_G.AnimBlockConnection:Disconnect()
			_G.AnimBlockConnection = nil
		end

		if _G.AnimMonitorConnection then
			_G.AnimMonitorConnection:Disconnect()
			_G.AnimMonitorConnection = nil
		end

		if _G.CharacterAddedConnection then
			_G.CharacterAddedConnection:Disconnect()
			_G.CharacterAddedConnection = nil
		end

		if _G.BackpackAddedConnection then
			_G.BackpackAddedConnection:Disconnect()
			_G.BackpackAddedConnection = nil
		end

		if _G.CharacterToolAddedConnection then
			_G.CharacterToolAddedConnection:Disconnect()
			_G.CharacterToolAddedConnection = nil
		end

		if _G.ToolConnections then
			for tool, connection in pairs(_G.ToolConnections) do
				if connection then
					connection:Disconnect()
				end
				if tool and tool:GetAttribute("ActivatedOverride") then
					tool:SetAttribute("ActivatedOverride", nil)
				end
			end
			_G.ToolConnections = nil
		end

		if _G.ToolEquipConnections then
			for _, connection in pairs(_G.ToolEquipConnections) do
				if connection then connection:Disconnect() end
			end
			_G.ToolEquipConnections = nil
		end
	end
end)

tabs.killing:AddHeading("Auto Kill:")

_G.whitelistedPlayers = _G.whitelistedPlayers or {}
_G.blacklistedPlayers = _G.blacklistedPlayers or {}

for _, connectionName in ipairs({
	"killAllConnection",
	"farmBadKarmaConnection",
	"farmGoodKarmaConnection",
	"blacklistKillConnection",
	"deathRingConnection"
}) do
	tabs.killing.runtime.connection = _G[connectionName]
	if tabs.killing.runtime.connection then
		pcall(function() tabs.killing.runtime.connection:Disconnect() end)
		_G[connectionName] = nil
	end
end

_G.killAll = false
_G.killBlacklistedOnly = false
_G.farmBadKarma = false
_G.farmGoodKarma = false
_G.deathRingEnabled = false
_G.killAllGeneration = (_G.killAllGeneration or 0) + 1
_G.killListGeneration = (_G.killListGeneration or 0) + 1

tabs.killing.isWhitelisted = function(player)
	for _, name in ipairs(_G.whitelistedPlayers) do
		if name:lower() == player.Name:lower() then return true end
	end
	return false
end

tabs.killing.isBlacklisted = function(player)
	for _, name in ipairs(_G.blacklistedPlayers) do
		if name:lower() == player.Name:lower() then return true end
	end
	return false
end

tabs.killing.RemoveWhitelistDropdown = nil
tabs.killing.WhitelistDisplayNames = {}

tabs.killing.getWhitelistDisplayName = function(username)
	local cached = tabs.killing.WhitelistDisplayNames[username]
	if cached then return cached end
	local player = services.Players:FindFirstChild(username)
	if player then
		tabs.killing.WhitelistDisplayNames[username] = player.DisplayName
		return player.DisplayName
	end
	return username
end

tabs.killing.WhitelistDropdown = tabs.killing:AddDropdown("Add to Whitelist", function(selectedText)
	tabs.killing.runtime.playerName_817 = selectedText:match("| (.+)$")
	if tabs.killing.runtime.playerName_817 then
		tabs.killing.runtime.playerName_817 = tabs.killing.runtime.playerName_817:gsub("^%s*(.-)%s*$", "%1")
		local selectedPlayer = services.Players:FindFirstChild(tabs.killing.runtime.playerName_817)
		if selectedPlayer then tabs.killing.WhitelistDisplayNames[selectedPlayer.Name] = selectedPlayer.DisplayName end
		for _, name in ipairs(_G.whitelistedPlayers) do
			if name:lower() == tabs.killing.runtime.playerName_817:lower() then return end
		end
		table.insert(_G.whitelistedPlayers, tabs.killing.runtime.playerName_817)
		if tabs.killing.RemoveWhitelistDropdown then
			tabs.killing.RemoveWhitelistDropdown:Add(tabs.killing.getWhitelistDisplayName(tabs.killing.runtime.playerName_817))
		end
	end
end)

tabs.killing:AddSwitch("Kill Everyone", function(bool)
	_G.killAll = bool
	_G.killAllGeneration = (_G.killAllGeneration or 0) + 1
	tabs.killing.runtime.generation_831 = _G.killAllGeneration
	if not bool then return end

	runtime:Spawn(function(generation, foundTarget)
		while _G.killAll and _G.killAllGeneration == generation do
			foundTarget = false
			for _, player in ipairs(services.Players:GetPlayers()) do
				if not _G.killAll or _G.killAllGeneration ~= generation then break end
				if player ~= services.Players.LocalPlayer
					and not tabs.killing.isWhitelisted(player)
					and tabs.killing.isPlayerAlive(player)
					and not tabs.killing.isSpawnProtected(player) then
					foundTarget = true
					tabs.killing.attackPlayerForDuration(player, 4, function()
						return _G.killAll and _G.killAllGeneration == generation and not tabs.killing.isWhitelisted(player)
					end, 3.5)
				end
			end
			if foundTarget then
				services.RunService.Heartbeat:Wait()
			else
				task.wait(0.1)
			end
		end
	end, tabs.killing.runtime.generation_831)
end)

tabs.killing:AddSwitch("Whitelist Friends", function(bool)
	_G.whitelistFriends = bool

	if bool then
		for _, player in pairs(services.Players:GetPlayers()) do
			if player ~= services.Players.LocalPlayer and player:IsFriendsWith(services.Players.LocalPlayer.UserId) then
				if not tabs.killing.isWhitelisted(player) then
					table.insert(_G.whitelistedPlayers, player.Name)
				end
			end
		end

		_G.friendWhitelistConnection = runtime:Connect(services.Players.PlayerAdded, function(player)
			if _G.whitelistFriends and player:IsFriendsWith(services.Players.LocalPlayer.UserId) then
				if not tabs.killing.isWhitelisted(player) then
					table.insert(_G.whitelistedPlayers, player.Name)
				end
			end
		end)

		_G.friendCheckLoop = runtime:Spawn(function()
			while _G.whitelistFriends do
				task.wait(3)
				for _, player in pairs(services.Players:GetPlayers()) do
					if player ~= services.Players.LocalPlayer and player:IsFriendsWith(services.Players.LocalPlayer.UserId) then
						if not tabs.killing.isWhitelisted(player) then
							table.insert(_G.whitelistedPlayers, player.Name)
						end
					end
				end
			end
		end)
	else
		if _G.friendWhitelistConnection then
			_G.friendWhitelistConnection:Disconnect()
			_G.friendWhitelistConnection = nil
		end
		if _G.friendCheckLoop then
			task.cancel(_G.friendCheckLoop)
			_G.friendCheckLoop = nil
		end
	end
end)

tabs.killing:AddHeading("Karma Killing:")

tabs.killing.KarmaData = {FarmEvil = false, FarmGood = false, Generation = 0}

tabs.killing.matchesKarmaMode = function(player)
	tabs.killing.runtime.goodKarma = player:FindFirstChild("goodKarma")
	tabs.killing.runtime.evilKarma = player:FindFirstChild("evilKarma")
	if not tabs.killing.runtime.goodKarma or not tabs.killing.runtime.evilKarma then return false end

	tabs.killing.runtime.goodValue = tabs.killing.runtime.goodKarma.Value or 0
	tabs.killing.runtime.evilValue = tabs.killing.runtime.evilKarma.Value or 0
	if tabs.killing.runtime.goodValue + tabs.killing.runtime.evilValue < 5 then return false end
	return (tabs.killing.KarmaData.FarmEvil and tabs.killing.runtime.goodValue > tabs.killing.runtime.evilValue)
		or (tabs.killing.KarmaData.FarmGood and tabs.killing.runtime.evilValue > tabs.killing.runtime.goodValue)
end

tabs.killing.restartKarmaWorker = function()
	tabs.killing.KarmaData.Generation += 1
	tabs.killing.runtime.generation_921 = tabs.killing.KarmaData.Generation
	if not tabs.killing.KarmaData.FarmEvil and not tabs.killing.KarmaData.FarmGood then return end

	runtime:Spawn(function(generation)
		while (tabs.killing.KarmaData.FarmEvil or tabs.killing.KarmaData.FarmGood) and tabs.killing.KarmaData.Generation == generation do
			tabs.killing.runtime.foundTarget_926 = false
			for _, player in ipairs(services.Players:GetPlayers()) do
				if tabs.killing.KarmaData.Generation ~= generation then break end
				if player ~= services.Players.LocalPlayer
					and not tabs.killing.isWhitelisted(player)
					and tabs.killing.isPlayerAlive(player)
					and not tabs.killing.isSpawnProtected(player)
					and tabs.killing.matchesKarmaMode(player) then
					tabs.killing.runtime.foundTarget_926 = true
					tabs.killing.attackPlayerWithLimit(player, 4, function()
						return tabs.killing.KarmaData.Generation == generation
							and not tabs.killing.isWhitelisted(player)
							and tabs.killing.matchesKarmaMode(player)
					end, 3.5)
				end
			end
			if tabs.killing.runtime.foundTarget_926 then
				services.RunService.Heartbeat:Wait()
			else
				task.wait(0.1)
			end
		end
	end, tabs.killing.KarmaData.Generation)
end

tabs.killing:AddSwitch("Farm Evil Karma", function(state)
	tabs.killing.KarmaData.FarmEvil = state
	tabs.killing.restartKarmaWorker()
end)

tabs.killing:AddSwitch("Farm Good Karma", function(state)
	tabs.killing.KarmaData.FarmGood = state
	tabs.killing.restartKarmaWorker()
end)

tabs.killing:AddHeading("Target Killing:")

tabs.killing.RemoveKilllistDropdown = nil
tabs.killing.KilllistDisplayNames = {}

tabs.killing.getKilllistDisplayName = function(username)
	local cached = tabs.killing.KilllistDisplayNames[username]
	if cached then return cached end
	local player = services.Players:FindFirstChild(username)
	if player then
		tabs.killing.KilllistDisplayNames[username] = player.DisplayName
		return player.DisplayName
	end
	return username
end

tabs.killing.BlacklistDropdown = tabs.killing:AddDropdown("Add to Killlist", function(selectedText)
	local selectedUsername = selectedText:match("| (.+)$")
	local selectedPlayer = selectedUsername and services.Players:FindFirstChild(selectedUsername:gsub("^%s*(.-)%s*$", "%1"))
	if selectedPlayer then
		tabs.killing.runtime.playerName_967 = selectedPlayer.Name
		tabs.killing.KilllistDisplayNames[selectedPlayer.Name] = selectedPlayer.DisplayName
		if not tabs.killing.isBlacklisted({Name = tabs.killing.runtime.playerName_967}) then
			table.insert(_G.blacklistedPlayers, tabs.killing.runtime.playerName_967)
			if tabs.killing.RemoveKilllistDropdown then
				tabs.killing.RemoveKilllistDropdown:Add(selectedPlayer.DisplayName)
			end
		end
	end
end)

for _, player in ipairs(services.Players:GetPlayers()) do
	if player ~= services.Players.LocalPlayer then
		tabs.killing.WhitelistDisplayNames[player.Name] = player.DisplayName
		tabs.killing.WhitelistDropdown:Add(player.DisplayName .. " | " .. player.Name)
		tabs.killing.KilllistDisplayNames[player.Name] = player.DisplayName
		tabs.killing.BlacklistDropdown:Add(player.DisplayName .. " | " .. player.Name)
	end
end

runtime:Connect(services.Players.PlayerAdded, function(player)
	if player ~= services.Players.LocalPlayer then
		tabs.killing.WhitelistDisplayNames[player.Name] = player.DisplayName
		tabs.killing.WhitelistDropdown:Add(player.DisplayName .. " | " .. player.Name)
		tabs.killing.KilllistDisplayNames[player.Name] = player.DisplayName
		tabs.killing.BlacklistDropdown:Add(player.DisplayName .. " | " .. player.Name)
	end
end)

runtime:Connect(services.Players.PlayerRemoving, function(player)
	tabs.killing.WhitelistDropdown:Remove(player.DisplayName .. " | " .. player.Name)
	tabs.killing.BlacklistDropdown:Remove(player.DisplayName .. " | " .. player.Name)
end)

tabs.killing.TargetKillAntiGravityName = "SilenceTargetKillAntiGravity"
tabs.killing.TargetKillHeightOffset = 10
tabs.killing.TargetKillGravityState = {
	Active = false,
	OriginalGravity = nil,
	Connection = nil
}

tabs.killing.setTargetKillAntiGravity = function(enabled)
	tabs.killing.runtime.character_1000 = services.Players.LocalPlayer.Character
	tabs.killing.runtime.root = tabs.killing.runtime.character_1000 and tabs.killing.runtime.character_1000:FindFirstChild("HumanoidRootPart")
	if enabled then
		if not tabs.killing.TargetKillGravityState.Active then
			tabs.killing.TargetKillGravityState.Active = true
			tabs.killing.TargetKillGravityState.OriginalGravity = services.Workspace.Gravity
			services.Workspace.Gravity = 0

			tabs.killing.TargetKillGravityState.Connection = runtime:Connect(services.RunService.Heartbeat, function()
				services.Workspace.Gravity = 0
				tabs.killing.runtime.currentCharacter = services.Players.LocalPlayer.Character
				tabs.killing.runtime.currentRoot = tabs.killing.runtime.currentCharacter and tabs.killing.runtime.currentCharacter:FindFirstChild("HumanoidRootPart")
				if tabs.killing.runtime.currentRoot then
					tabs.killing.runtime.velocity_1013 = tabs.killing.runtime.currentRoot.AssemblyLinearVelocity
					tabs.killing.runtime.currentRoot.AssemblyLinearVelocity = Vector3.new(tabs.killing.runtime.velocity_1013.X, 0, tabs.killing.runtime.velocity_1013.Z)
				end
			end)
		end

		if tabs.killing.runtime.root then
			tabs.killing.runtime.oldAntiGravity = tabs.killing.runtime.root:FindFirstChild(tabs.killing.TargetKillAntiGravityName)
			if tabs.killing.runtime.oldAntiGravity then tabs.killing.runtime.oldAntiGravity:Destroy() end
			tabs.killing.runtime.velocity_1022 = tabs.killing.runtime.root.AssemblyLinearVelocity
			tabs.killing.runtime.root.AssemblyLinearVelocity = Vector3.new(tabs.killing.runtime.velocity_1022.X, 0, tabs.killing.runtime.velocity_1022.Z)
			tabs.killing.runtime.root.AssemblyAngularVelocity = Vector3.zero
		end
	else
		if tabs.killing.TargetKillGravityState.Connection then
			tabs.killing.TargetKillGravityState.Connection:Disconnect()
			tabs.killing.TargetKillGravityState.Connection = nil
		end
		if tabs.killing.TargetKillGravityState.Active then
			services.Workspace.Gravity = tabs.killing.TargetKillGravityState.OriginalGravity or 196.2
		end
		tabs.killing.TargetKillGravityState.Active = false
		tabs.killing.TargetKillGravityState.OriginalGravity = nil
	end
end

tabs.killing:AddSwitch("Kill List", function(bool)
	_G.killBlacklistedOnly = bool
	_G.killListGeneration = (_G.killListGeneration or 0) + 1
	tabs.killing.runtime.generation_1042 = _G.killListGeneration
	if not bool then
		tabs.killing.setTargetKillAntiGravity(false)
		return
	end
	tabs.killing.setTargetKillAntiGravity(true)

	runtime:Spawn(function(generation, target)
		while _G.killBlacklistedOnly and _G.killListGeneration == generation do
			target = nil
			for _, player in ipairs(services.Players:GetPlayers()) do
				if not _G.killBlacklistedOnly or _G.killListGeneration ~= generation then break end
				if player ~= services.Players.LocalPlayer
					and tabs.killing.isBlacklisted(player)
					and tabs.killing.isPlayerAlive(player)
					and not tabs.killing.isSpawnProtected(player) then
					target = player
					break
				end
			end

			if target then
				pcall(function()
					while _G.killBlacklistedOnly
						and _G.killListGeneration == generation
						and target.Parent == services.Players
						and tabs.killing.isBlacklisted(target)
						and tabs.killing.isPlayerAlive(target)
						and not tabs.killing.isSpawnProtected(target) do
						tabs.killing.runtime.discardHit_attempted, tabs.killing.runtime.attempted_1071 = tabs.killing.touchAndPunchTarget(target, tabs.killing.TargetKillHeightOffset)
						if not tabs.killing.runtime.attempted_1071 then task.wait(0.1) end
					end
				end)
				services.RunService.Heartbeat:Wait()
			else
				task.wait(0.1)
			end
		end
	end, tabs.killing.runtime.generation_1042)
end)

tabs.killing.SpectateData = {
	SelectedPlayer = nil,
	SelectedPlayerUserId = nil,
	Spectating = false,
	CurrentTargetConnection = nil,
	LocalPlayerRespawnConnection = nil,
	CameraMonitorLoop = nil
}

tabs.killing.SpectateState = tabs.killing.SpectateState or {
	SavedUserId = nil,
	IsSpectating = false
}

tabs.killing.stopSpectating = function()
	if tabs.killing.SpectateData.CurrentTargetConnection then
		tabs.killing.SpectateData.CurrentTargetConnection:Disconnect()
		tabs.killing.SpectateData.CurrentTargetConnection = nil
	end

	if tabs.killing.SpectateData.CameraMonitorLoop then
		tabs.killing.SpectateData.CameraMonitorLoop = false
	end

	tabs.killing.runtime.localPlayer_1110 = services.Players.LocalPlayer
	if tabs.killing.runtime.localPlayer_1110.Character then
		tabs.killing.runtime.humanoid_1112 = tabs.killing.runtime.localPlayer_1110.Character:FindFirstChildOfClass("Humanoid")
		if tabs.killing.runtime.humanoid_1112 then
			utils.playerData.Camera.CameraSubject = tabs.killing.runtime.humanoid_1112
			utils.playerData.Camera.CameraType = Enum.CameraType.Custom
		end
	end

	if utils.playerData.Humanoid then
		utils.playerData.Camera.CameraSubject = utils.playerData.Humanoid
	end
end

tabs.killing.startCameraMonitor = function()
	if tabs.killing.SpectateData.CameraMonitorLoop then
		tabs.killing.SpectateData.CameraMonitorLoop = false
		task.wait(0.3)
	end

	tabs.killing.SpectateData.CameraMonitorLoop = true

	runtime:Spawn(function()
		while tabs.killing.SpectateData.CameraMonitorLoop do
			task.wait(0.2)
			if tabs.killing.SpectateData.Spectating and tabs.killing.SpectateData.SelectedPlayer then
				tabs.killing.runtime.targetChar = tabs.killing.SpectateData.SelectedPlayer.Character
				if tabs.killing.runtime.targetChar then
					tabs.killing.runtime.targetHumanoid_1138 = tabs.killing.runtime.targetChar:FindFirstChildOfClass("Humanoid")
					if tabs.killing.runtime.targetHumanoid_1138 then
						if utils.playerData.Camera.CameraSubject ~= tabs.killing.runtime.targetHumanoid_1138 then
							utils.playerData.Camera.CameraSubject = tabs.killing.runtime.targetHumanoid_1138
						end
					end
				end
			else
				break
			end
		end
	end)
end

tabs.killing.updateSpectateTarget = function(player)
	if not player then
		if tabs.killing.SpectateData.SelectedPlayerUserId then
			for _, p in ipairs(services.Players:GetPlayers()) do
				if p.UserId == tabs.killing.SpectateData.SelectedPlayerUserId then
					player = p
					tabs.killing.SpectateData.SelectedPlayer = player
					break
				end
			end
		end

		if not player and tabs.killing.SpectateState.SavedUserId then
			for _, p in ipairs(services.Players:GetPlayers()) do
				if p.UserId == tabs.killing.SpectateState.SavedUserId then
					player = p
					tabs.killing.SpectateData.SelectedPlayer = player
					tabs.killing.SpectateData.SelectedPlayerUserId = p.UserId
					break
				end
			end
		end

		if not player then
			tabs.killing.stopSpectating()
			return
		end
	end

	tabs.killing.SpectateData.SelectedPlayerUserId = player.UserId
	tabs.killing.SpectateData.SelectedPlayer = player

	if tabs.killing.SpectateData.CurrentTargetConnection then
		tabs.killing.SpectateData.CurrentTargetConnection:Disconnect()
		tabs.killing.SpectateData.CurrentTargetConnection = nil
	end

	tabs.killing.runtime.setCamera = function(char)
		if not tabs.killing.SpectateData.Spectating or tabs.killing.SpectateData.SelectedPlayerUserId ~= player.UserId then
			return
		end
		tabs.killing.runtime.humanoid_1193 = char:WaitForChild("Humanoid", 3)
		if tabs.killing.runtime.humanoid_1193 and tabs.killing.SpectateData.Spectating and tabs.killing.SpectateData.SelectedPlayerUserId == player.UserId then
			utils.playerData.Camera.CameraSubject = tabs.killing.runtime.humanoid_1193
		end
	end

	if player.Character then
		tabs.killing.runtime.setCamera(player.Character)
	end

	tabs.killing.SpectateData.CurrentTargetConnection = runtime:Connect(player.CharacterAdded, function(newChar)
		if tabs.killing.SpectateData.Spectating and tabs.killing.SpectateData.SelectedPlayerUserId == player.UserId then
			tabs.killing.runtime.setCamera(newChar)
		end
	end)
end

tabs.killing.getPlayers = function()
	return services.Players:GetPlayers()
end

tabs.killing.SpectateDropdown = tabs.killing:AddDropdown("Choose Player", function(text)
	for _, player in ipairs(tabs.killing.getPlayers()) do
		tabs.killing.runtime.optionText = player.DisplayName .. " | " .. player.Name
		if text == tabs.killing.runtime.optionText then
			tabs.killing.SpectateData.SelectedPlayer = player
			tabs.killing.SpectateData.SelectedPlayerUserId = player.UserId
			tabs.killing.SpectateState.SavedUserId = player.UserId
			if tabs.killing.SpectateData.Spectating then
				tabs.killing.updateSpectateTarget(player)
			end
			break
		end
	end
end)

tabs.killing:AddSwitch("Spectate", function(bool)
	tabs.killing.SpectateData.Spectating = bool
	tabs.killing.SpectateState.IsSpectating = bool

	if tabs.killing.SpectateData.Spectating then
		if tabs.killing.SpectateData.SelectedPlayerUserId then
			tabs.killing.SpectateState.SavedUserId = tabs.killing.SpectateData.SelectedPlayerUserId
		end
		tabs.killing.updateSpectateTarget()
		tabs.killing.startCameraMonitor()
	else
		tabs.killing.stopSpectating()
		task.wait(0.1)
		tabs.killing.runtime.localPlayer_1242 = services.Players.LocalPlayer
		if tabs.killing.runtime.localPlayer_1242.Character then
			tabs.killing.runtime.humanoid_1244 = tabs.killing.runtime.localPlayer_1242.Character:FindFirstChildOfClass("Humanoid")
			if tabs.killing.runtime.humanoid_1244 then
				utils.playerData.Camera.CameraSubject = tabs.killing.runtime.humanoid_1244
			end
		end
		tabs.killing.SpectateState.IsSpectating = false
	end
end)

for _, player in ipairs(tabs.killing.getPlayers()) do
	tabs.killing.SpectateDropdown:Add(player.DisplayName .. " | " .. player.Name)
end

runtime:Connect(services.Players.PlayerAdded, function(player)
	tabs.killing.SpectateDropdown:Add(player.DisplayName .. " | " .. player.Name)
	if tabs.killing.SpectateState.IsSpectating and tabs.killing.SpectateState.SavedUserId == player.UserId then
		tabs.killing.SpectateData.Spectating = true
		tabs.killing.SpectateData.SelectedPlayer = player
		tabs.killing.SpectateData.SelectedPlayerUserId = player.UserId
		tabs.killing.updateSpectateTarget(player)
	end
end)

runtime:Connect(services.Players.PlayerRemoving, function(player)
	tabs.killing.SpectateDropdown:Remove(player.DisplayName .. " | " .. player.Name)
	if player.UserId == tabs.killing.SpectateData.SelectedPlayerUserId then
		if tabs.killing.SpectateData.Spectating then
			tabs.killing.stopSpectating()

			tabs.killing.SpectateData.SelectedPlayer = nil
			tabs.killing.SpectateData.CurrentTargetConnection = nil

			tabs.killing.runtime.localPlayer_1275 = services.Players.LocalPlayer
			if tabs.killing.runtime.localPlayer_1275.Character and utils.playerData.Humanoid then
				utils.playerData.Camera.CameraSubject = utils.playerData.Humanoid
			end
		end
	end
end)

if tabs.killing.SpectateData.LocalPlayerRespawnConnection then
	tabs.killing.SpectateData.LocalPlayerRespawnConnection:Disconnect()
end

tabs.killing.SpectateData.LocalPlayerRespawnConnection = runtime:Connect(services.Players.LocalPlayer.CharacterAdded, function(char)
	tabs.killing.runtime.humanoid_1288 = char:WaitForChild("Humanoid", 3)
	if tabs.killing.runtime.humanoid_1288 then
		utils.playerData.Humanoid = tabs.killing.runtime.humanoid_1288
	end

	task.wait(0.5)

	if tabs.killing.SpectateState.IsSpectating then
		tabs.killing.SpectateData.Spectating = true
		tabs.killing.updateSpectateTarget()
		tabs.killing.startCameraMonitor()
	else
		if utils.playerData.Humanoid then
			utils.playerData.Camera.CameraSubject = utils.playerData.Humanoid
		end
	end
end)

tabs.killing:AddHeading("Kill Aura:")

tabs.killing.KillAura = {
	RingPart = nil,
	RingColor = Color3.fromRGB(138, 0, 0),
	RingTransparency = 0.6,
	CenterCFrame = nil,
	Frozen = false,
	Generation = 0
}
_G.showDeathRing = false
_G.deathRingRange = 20

tabs.killing.StaleRing = services.Workspace:FindFirstChild("SilenceKillAuraRing")
if tabs.killing.StaleRing then tabs.killing.StaleRing:Destroy() end

tabs.killing:AddTextBox("Range (1-140):", function(text)
	if tonumber(text) then
		_G.deathRingRange = math.clamp(tonumber(text), 1, 140)
		if tabs.killing.KillAura.RingPart then
			tabs.killing.KillAura.RingPart.Size = Vector3.new(0.2, _G.deathRingRange * 2, _G.deathRingRange * 2)
		end
	end
end, {clear = false})

tabs.killing.RingColors = {
	{Name = "Silence", Color = Color3.fromRGB(138, 0, 0)},
	{Name = "Red", Color = Color3.fromRGB(255, 0, 0)},
	{Name = "Orange", Color = Color3.fromRGB(255, 128, 0)},
	{Name = "Yellow", Color = Color3.fromRGB(255, 230, 0)},
	{Name = "Lime", Color = Color3.fromRGB(128, 255, 0)},
	{Name = "Green", Color = Color3.fromRGB(0, 200, 70)},
	{Name = "Cyan", Color = Color3.fromRGB(0, 220, 255)},
	{Name = "Blue", Color = Color3.fromRGB(0, 100, 255)},
	{Name = "Purple", Color = Color3.fromRGB(145, 70, 255)},
	{Name = "Pink", Color = Color3.fromRGB(255, 80, 180)},
	{Name = "White", Color = Color3.fromRGB(255, 255, 255)},
	{Name = "Black", Color = Color3.fromRGB(0, 0, 0)}
}

tabs.killing.RingColorDropdown = tabs.killing:AddDropdown("Ring Color", function(selection)
	for _, colorData in ipairs(tabs.killing.RingColors) do
		if colorData.Name == selection then
			tabs.killing.KillAura.RingColor = colorData.Color
			if tabs.killing.KillAura.RingPart then tabs.killing.KillAura.RingPart.Color = colorData.Color end
			break
		end
	end
end)
for _, colorData in ipairs(tabs.killing.RingColors) do
	tabs.killing.RingColorDropdown:Add(colorData.Name)
end

tabs.killing.destroyKillAuraRing = function()
	if tabs.killing.KillAura.RingPart then
		tabs.killing.KillAura.RingPart:Destroy()
		tabs.killing.KillAura.RingPart = nil
	end
end

tabs.killing.createKillAuraRing = function()
	tabs.killing.destroyKillAuraRing()
	tabs.killing.runtime.oldRing = services.Workspace:FindFirstChild("SilenceKillAuraRing")
	if tabs.killing.runtime.oldRing then tabs.killing.runtime.oldRing:Destroy() end

	tabs.killing.KillAura.RingPart = Instance.new("Part")
	tabs.killing.KillAura.RingPart.Name = "SilenceKillAuraRing"
	tabs.killing.KillAura.RingPart.Shape = Enum.PartType.Cylinder
	tabs.killing.KillAura.RingPart.Material = Enum.Material.Neon
	tabs.killing.KillAura.RingPart.Color = tabs.killing.KillAura.RingColor
	tabs.killing.KillAura.RingPart.Transparency = tabs.killing.KillAura.RingTransparency
	tabs.killing.KillAura.RingPart.Anchored = true
	tabs.killing.KillAura.RingPart.CanCollide = false
	tabs.killing.KillAura.RingPart.CanTouch = false
	tabs.killing.KillAura.RingPart.CanQuery = false
	tabs.killing.KillAura.RingPart.CastShadow = false
	tabs.killing.KillAura.RingPart.Size = Vector3.new(0.2, _G.deathRingRange * 2, _G.deathRingRange * 2)
	if tabs.killing.KillAura.CenterCFrame then
		tabs.killing.KillAura.RingPart.CFrame = tabs.killing.KillAura.CenterCFrame * CFrame.Angles(0, 0, math.rad(90))
	end
	tabs.killing.KillAura.RingPart.Parent = services.Workspace
end

tabs.killing.ShowRingSwitch = nil
tabs.killing.ShowRingSwitch = tabs.killing:AddSwitch("Show Ring", function(bool)
	if bool and not _G.deathRingEnabled then
		_G.showDeathRing = false
		tabs.killing.ShowRingSwitch:Set(false)
		return
	end

	_G.showDeathRing = bool
	if bool then
		tabs.killing.createKillAuraRing()
	else
		tabs.killing.destroyKillAuraRing()
	end
end)

if _G.deathRingConnection then
	_G.deathRingConnection:Disconnect()
	_G.deathRingConnection = nil
end

tabs.killing.updateKillAuraRing = function()
	if tabs.killing.KillAura.RingPart and tabs.killing.KillAura.CenterCFrame then
		tabs.killing.KillAura.RingPart.CFrame = tabs.killing.KillAura.CenterCFrame * CFrame.Angles(0, 0, math.rad(90))
	end
end

tabs.killing:AddSwitch("Toggle Ring", function(bool)
	_G.deathRingEnabled = bool
	tabs.killing.KillAura.Generation += 1
	tabs.killing.runtime.generation_1419 = tabs.killing.KillAura.Generation
	tabs.killing.KillAura.Frozen = false
	if not bool then
		if tabs.killing.ShowRingSwitch and _G.showDeathRing then tabs.killing.ShowRingSwitch:Set(false) end
		return
	end

	tabs.killing.runtime.discardCharacter_initialRoot, tabs.killing.runtime.discardHumanoid_initialRoot, tabs.killing.runtime.initialRoot = tabs.killing.getLocalCombatCharacter()
	if tabs.killing.runtime.initialRoot then tabs.killing.KillAura.CenterCFrame = tabs.killing.runtime.initialRoot.CFrame end

	runtime:Spawn(function(generation)
		while _G.deathRingEnabled and tabs.killing.KillAura.Generation == generation do
			tabs.killing.runtime.discardCharacter_localRoot_1430, tabs.killing.runtime.discardHumanoid_localRoot_1430, tabs.killing.runtime.localRoot_1430 = tabs.killing.getLocalCombatCharacter()
			if tabs.killing.runtime.localRoot_1430 and not tabs.killing.KillAura.Frozen then
				tabs.killing.KillAura.CenterCFrame = tabs.killing.runtime.localRoot_1430.CFrame
			end
			tabs.killing.updateKillAuraRing()
			services.RunService.RenderStepped:Wait()
		end
	end, tabs.killing.KillAura.Generation)

	runtime:Spawn(function(generation)
		while _G.deathRingEnabled and tabs.killing.KillAura.Generation == generation do
			if tabs.killing.KillAura.Frozen or not tabs.killing.KillAura.CenterCFrame then
				task.wait(0.05)
				continue
			end

			tabs.killing.runtime.centerCFrame = tabs.killing.KillAura.CenterCFrame
			tabs.killing.runtime.attackedPlayer = false
			for _, player in ipairs(services.Players:GetPlayers()) do
				if not _G.deathRingEnabled or tabs.killing.KillAura.Generation ~= generation then break end
				tabs.killing.runtime.targetRoot_1450 = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if player ~= services.Players.LocalPlayer
					and not tabs.killing.isWhitelisted(player)
					and tabs.killing.isPlayerAlive(player)
					and not tabs.killing.isSpawnProtected(player)
					and tabs.killing.runtime.targetRoot_1450
					and (tabs.killing.runtime.centerCFrame.Position - tabs.killing.runtime.targetRoot_1450.Position).Magnitude <= _G.deathRingRange then
					tabs.killing.runtime.attackedPlayer = true
					tabs.killing.KillAura.Frozen = true
					tabs.killing.KillAura.CenterCFrame = tabs.killing.runtime.centerCFrame
					tabs.killing.updateKillAuraRing()

					tabs.killing.attackPlayerWithLimit(player, 4, function()
						tabs.killing.runtime.currentTargetRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
						return _G.deathRingEnabled
							and tabs.killing.KillAura.Generation == generation
							and not tabs.killing.isWhitelisted(player)
							and tabs.killing.runtime.currentTargetRoot
							and (tabs.killing.runtime.centerCFrame.Position - tabs.killing.runtime.currentTargetRoot.Position).Magnitude <= _G.deathRingRange
					end, 3.5)

					for _ = 1, 4 do
						if not _G.deathRingEnabled or tabs.killing.KillAura.Generation ~= generation then return end
						tabs.killing.runtime.discardCharacter_currentLocalRoot, tabs.killing.runtime.discardHumanoid_currentLocalRoot, tabs.killing.runtime.currentLocalRoot = tabs.killing.getLocalCombatCharacter()
						if tabs.killing.runtime.currentLocalRoot then
							tabs.killing.runtime.currentLocalRoot.CFrame = tabs.killing.runtime.centerCFrame
							tabs.killing.runtime.currentLocalRoot.AssemblyLinearVelocity = Vector3.zero
							tabs.killing.runtime.currentLocalRoot.AssemblyAngularVelocity = Vector3.zero
						end
						tabs.killing.KillAura.CenterCFrame = tabs.killing.runtime.centerCFrame
						tabs.killing.updateKillAuraRing()
						services.RunService.Heartbeat:Wait()
					end
					tabs.killing.KillAura.Frozen = false
				end
			end

			if not tabs.killing.runtime.attackedPlayer then task.wait(0.05) end
		end
		if tabs.killing.KillAura.Generation == generation then tabs.killing.KillAura.Frozen = false end
	end, tabs.killing.KillAura.Generation)
end)

tabs.killing.WhitelistLabel = tabs.killing:AddLabel("Whitelist: None")
tabs.killing.RemoveWhitelistDropdown = tabs.killing:AddDropdown("Remove from Whitelist", function(selectedDisplayName)
	for index = #_G.whitelistedPlayers, 1, -1 do
		if tabs.killing.getWhitelistDisplayName(_G.whitelistedPlayers[index]) == selectedDisplayName then
			table.remove(_G.whitelistedPlayers, index)
			break
		end
	end
	tabs.killing.RemoveWhitelistDropdown:Remove(selectedDisplayName)
end)

for _, playerName in ipairs(_G.whitelistedPlayers) do
	tabs.killing.RemoveWhitelistDropdown:Add(tabs.killing.getWhitelistDisplayName(playerName))
end

tabs.killing:AddButton("Clear Whitelist", function()
	_G.whitelistedPlayers = {}
	tabs.killing.RemoveWhitelistDropdown:Clear()
end)

tabs.killing.BlacklistLabel = tabs.killing:AddLabel("Killlist: None")
tabs.killing.RemoveKilllistDropdown = tabs.killing:AddDropdown("Remove from Killlist", function(selectedDisplayName)
	for index = #_G.blacklistedPlayers, 1, -1 do
		if tabs.killing.getKilllistDisplayName(_G.blacklistedPlayers[index]) == selectedDisplayName then
			table.remove(_G.blacklistedPlayers, index)
			break
		end
	end
	tabs.killing.RemoveKilllistDropdown:Remove(selectedDisplayName)
end)

for _, playerName in ipairs(_G.blacklistedPlayers) do
	tabs.killing.RemoveKilllistDropdown:Add(tabs.killing.getKilllistDisplayName(playerName))
end

tabs.killing:AddButton("Clear Killlist", function()
	_G.blacklistedPlayers = {}
	tabs.killing.RemoveKilllistDropdown:Clear()
end)

runtime:Spawn(function()
	while true do
		local displayedWhitelist = {}
		for _, username in ipairs(_G.whitelistedPlayers) do
			table.insert(displayedWhitelist, tabs.killing.getWhitelistDisplayName(username))
		end
		tabs.killing.WhitelistLabel.Text = #displayedWhitelist == 0 and "Whitelist: None" or "Whitelist: " .. table.concat(displayedWhitelist, ", ")
		local displayedKilllist = {}
		for _, username in ipairs(_G.blacklistedPlayers) do
			table.insert(displayedKilllist, tabs.killing.getKilllistDisplayName(username))
		end
		tabs.killing.BlacklistLabel.Text = #displayedKilllist == 0 and "Killlist: None" or "Killlist: " .. table.concat(displayedKilllist, ", ")
		task.wait(0.01)
	end
end)

tabs.specs:AddHeading("Player Stats:")

tabs.specs.Data = {
	PlayerToInspect = nil,
	EmojiMap = {
		["Time"] = utf8.char(0x1F55B), ["Stats"] = utf8.char(0x1F4CA), ["Strength"] = utf8.char(0x1F4AA),
		["Rebirths"] = utf8.char(0x1F504), ["Durability"] = utf8.char(0x1F6E1), ["Kills"] = utf8.char(0x1F480),
		["Agility"] = "⚡", ["Evil Karma"] = utf8.char(0x1F608), ["Good Karma"] = utf8.char(0x1F607),
		["Brawls"] = utf8.char(0x1F94A)
	},
	StatDefinitions = {
		{name = "Strength", statName = "Strength"}, {name = "Rebirths", statName = "Rebirths"},
		{name = "Durability", statName = "Durability"}, {name = "Agility", statName = "Agility"},
		{name = "Kills", statName = "Kills"}, {name = "Evil Karma", statName = "evilKarma"},
		{name = "Good Karma", statName = "goodKarma"}, {name = "Brawls", statName = "Brawls"}
	},
	StatLabels = {}
}

tabs.specs.PlayerDropdown = tabs.specs:AddDropdown("Choose Player", function(text)
	for _, player in ipairs(services.Players:GetPlayers()) do
		if text == player.DisplayName .. " | " .. player.Name then
			tabs.specs.Data.PlayerToInspect = player
			break
		end
	end
end)

for _, player in ipairs(services.Players:GetPlayers()) do
	tabs.specs.PlayerDropdown:Add(player.DisplayName .. " | " .. player.Name)
end

runtime:Connect(services.Players.PlayerAdded, function(player)
	tabs.specs.PlayerDropdown:Add(player.DisplayName .. " | " .. player.Name)
end)

runtime:Connect(services.Players.PlayerRemoving, function(player)
	tabs.specs.PlayerDropdown:Remove(player.DisplayName .. " | " .. player.Name)
	if tabs.specs.Data.PlayerToInspect == player then tabs.specs.Data.PlayerToInspect = nil end
end)

tabs.specs.PlayerNameLabel = tabs.specs:AddLabel("👤 Name: N/A")
tabs.specs.PlayerUsernameLabel = tabs.specs:AddLabel("🎫 Username: N/A")

for _, info in ipairs(tabs.specs.Data.StatDefinitions) do
	tabs.specs.Data.StatLabels[info.name] = tabs.specs:AddLabel(tabs.specs.Data.EmojiMap[info.name] .. " " .. info.name .. ": N/A")
end

tabs.specs.updateStatLabels = function(targetPlayer)
	if not targetPlayer then return end
	tabs.specs.PlayerNameLabel.Text = "👤 Name: " .. targetPlayer.DisplayName
	tabs.specs.PlayerUsernameLabel.Text = "🎫 Username: " .. targetPlayer.Name
	if not targetPlayer:FindFirstChild("leaderstats") then return end
	for _, info in ipairs(tabs.specs.Data.StatDefinitions) do
		tabs.specs.runtime.statObject = targetPlayer.leaderstats:FindFirstChild(info.statName) or targetPlayer:FindFirstChild(info.statName)
		if tabs.specs.runtime.statObject then
			tabs.specs.Data.StatLabels[info.name].Text = string.format("%s %s: %s (%s)", tabs.specs.Data.EmojiMap[info.name] or "", info.name,
				utils.formatNumber(tabs.specs.runtime.statObject.Value), utils.formatWithCommas(tabs.specs.runtime.statObject.Value))
		else
			tabs.specs.Data.StatLabels[info.name].Text = tabs.specs.Data.EmojiMap[info.name] .. " " .. info.name .. ": 0 (0)"
		end
	end
end

runtime:Spawn(function()
	while true do
		if tabs.specs.Data.PlayerToInspect then tabs.specs.updateStatLabels(tabs.specs.Data.PlayerToInspect) end
		task.wait(0.1)
	end
end)

tabs.specs:AddHeading("Advanced Stats:")

tabs.specs.AdvancedStats = {
	HealthLabel = tabs.specs:AddLabel("🛡️ Enemy Health: N/A"),
	EnemyDamageLabel = tabs.specs:AddLabel("💥 Enemy Damage: N/A"),
	PlayerHealthLabel = tabs.specs:AddLabel("🛡️ Your Health: N/A"),
	PlayerDamageLabel = tabs.specs:AddLabel("💥 Your Damage: N/A"),
	HitsToKillLabel = tabs.specs:AddLabel("👊 Hits to Kill: N/A")
}

tabs.specs.StatsCache = {
	health = 0,
	enemyDamage = 0,
	playerHealth = 0,
	playerDamage = 0,
	hitsToKill = "N/A"
}

tabs.specs.calculatePlayerHealth = function(targetPlayer)
	if not targetPlayer then return 0 end
	tabs.specs.runtime.durabilityStat = targetPlayer:FindFirstChild("Durability") or
		(targetPlayer:FindFirstChild("leaderstats") and targetPlayer.leaderstats:FindFirstChild("Durability"))
	if not tabs.specs.runtime.durabilityStat then return 0 end
	tabs.specs.runtime.totalMultiplier_1635 = 1
	if targetPlayer:FindFirstChild("ultimatesFolder") and targetPlayer.ultimatesFolder:FindFirstChild("Infernal Health") then
		tabs.specs.runtime.totalMultiplier_1635 = tabs.specs.runtime.totalMultiplier_1635 + 0.15 * (targetPlayer.ultimatesFolder["Infernal Health"].Value or 0)
	end
	if targetPlayer:FindFirstChild("equippedPets") then
		for _, petValue in ipairs(targetPlayer.equippedPets:GetChildren()) do
			if petValue:IsA("ObjectValue") and petValue.Value then
				if string.lower(petValue.Value.Name):match("mighty") and string.lower(petValue.Value.Name):match("monster") then
					tabs.specs.runtime.totalMultiplier_1635 = tabs.specs.runtime.totalMultiplier_1635 + 0.5
				end
				if string.lower(petValue.Value.Name):match("small") and string.lower(petValue.Value.Name):match("fry") then
					tabs.specs.runtime.totalMultiplier_1635 = tabs.specs.runtime.totalMultiplier_1635 + 0.25
				end
			end
		end
	end
	return tabs.specs.runtime.durabilityStat.Value * tabs.specs.runtime.totalMultiplier_1635
end

tabs.specs.calculatePlayerDamage = function(targetPlayer)
	if not targetPlayer then return 0 end
	if not targetPlayer:FindFirstChild("leaderstats") or not targetPlayer.leaderstats:FindFirstChild("Strength") then return 0 end
	tabs.specs.runtime.baseDamage = targetPlayer.leaderstats.Strength.Value * 0.066666666666666666666666666666666666666666666667
	tabs.specs.runtime.totalMultiplier_1658 = 1
	if targetPlayer:FindFirstChild("ultimatesFolder") and targetPlayer.ultimatesFolder:FindFirstChild("Demon Damage") then
		tabs.specs.runtime.totalMultiplier_1658 = tabs.specs.runtime.totalMultiplier_1658 + 0.1 * (targetPlayer.ultimatesFolder["Demon Damage"].Value or 0)
	end
	if targetPlayer:FindFirstChild("equippedPets") then
		for _, petValue in ipairs(targetPlayer.equippedPets:GetChildren()) do
			if petValue:IsA("ObjectValue") and petValue.Value then
				if string.lower(petValue.Value.Name):match("wild") and string.lower(petValue.Value.Name):match("wizard") then
					tabs.specs.runtime.totalMultiplier_1658 = tabs.specs.runtime.totalMultiplier_1658 + 0.5
				end
				if string.lower(petValue.Value.Name):match("chaos") and string.lower(petValue.Value.Name):match("sorcerer") then
					tabs.specs.runtime.totalMultiplier_1658 = tabs.specs.runtime.totalMultiplier_1658 + 0.25
				end
			end
		end
	end
	return tabs.specs.runtime.baseDamage * tabs.specs.runtime.totalMultiplier_1658
end

tabs.specs.updateAdvancedStats = function(targetPlayer)
	if not targetPlayer then
		tabs.specs.AdvancedStats.HealthLabel.Text = "🛡️ Enemy Health: N/A"
		tabs.specs.AdvancedStats.EnemyDamageLabel.Text = "💥 Enemy Damage: N/A"
		tabs.specs.AdvancedStats.PlayerHealthLabel.Text = "🛡️ Your Health: N/A"
		tabs.specs.AdvancedStats.PlayerDamageLabel.Text = "💥 Your Damage: N/A"
		tabs.specs.AdvancedStats.HitsToKillLabel.Text = "👊 Hits to Kill: N/A"
		return
	end

	tabs.specs.StatsCache.health = tabs.specs.calculatePlayerHealth(targetPlayer)
	tabs.specs.StatsCache.enemyDamage = tabs.specs.calculatePlayerDamage(targetPlayer)
	tabs.specs.StatsCache.playerHealth = tabs.specs.calculatePlayerHealth(utils.playerData.Player)
	tabs.specs.StatsCache.playerDamage = tabs.specs.calculatePlayerDamage(utils.playerData.Player)
	tabs.specs.StatsCache.hitsToKill = tabs.specs.StatsCache.playerDamage <= 0 and "∞" or (math.ceil(tabs.specs.StatsCache.health / tabs.specs.StatsCache.playerDamage) > 200 and "∞" or
		(math.ceil(tabs.specs.StatsCache.health / tabs.specs.StatsCache.playerDamage) < 1 and "instant" or math.ceil(tabs.specs.StatsCache.health / tabs.specs.StatsCache.playerDamage)))

	tabs.specs.AdvancedStats.HealthLabel.Text = string.format("🛡️ Enemy Health: %s (%s)", utils.formatNumber(tabs.specs.StatsCache.health), utils.formatWithCommas(tabs.specs.StatsCache.health))
	tabs.specs.AdvancedStats.EnemyDamageLabel.Text = string.format("💥 Enemy Damage: %s (%s)", utils.formatNumber(tabs.specs.StatsCache.enemyDamage), utils.formatWithCommas(tabs.specs.StatsCache.enemyDamage))
	tabs.specs.AdvancedStats.PlayerHealthLabel.Text = string.format("🛡️ Your Health: %s (%s)", utils.formatNumber(tabs.specs.StatsCache.playerHealth), utils.formatWithCommas(tabs.specs.StatsCache.playerHealth))
	tabs.specs.AdvancedStats.PlayerDamageLabel.Text = string.format("💥 Your Damage: %s (%s)", utils.formatNumber(tabs.specs.StatsCache.playerDamage), utils.formatWithCommas(tabs.specs.StatsCache.playerDamage))
	tabs.specs.AdvancedStats.HitsToKillLabel.Text = string.format("👊 Hits to Kill: %s", tostring(tabs.specs.StatsCache.hitsToKill))
end

runtime:Spawn(function()
	while true do
		tabs.specs.updateAdvancedStats(tabs.specs.Data.PlayerToInspect)
		task.wait(0.1)
	end
end)

tabs.farming:AddHeading("Rebirths:")

tabs.farming.RebirthData = {
	Label = tabs.farming:AddLabel("Rebirths: 0"),
	TargetLabel = tabs.farming:AddLabel("Target: None"),
	Rebirths = utils.playerData.Player.leaderstats:WaitForChild("Rebirths"),
	TargetRebirths = 0,
	IsAutoRebirthing = false,
	Generation = 0
}

tabs.farming:AddTextBox("Set Rebirth Target (Required):", function(text)
	if tonumber(text) and tonumber(text) >= 0 then tabs.farming.RebirthData.TargetRebirths = tonumber(text) end
end)

tabs.farming.RebirthData.Switch = tabs.farming:AddSwitch("Auto Rebirth", function(enabled)
	tabs.farming.RebirthData.Generation += 1
	if enabled and tabs.farming.RebirthData.TargetRebirths > 0 and tabs.farming.RebirthData.Rebirths.Value < tabs.farming.RebirthData.TargetRebirths then
		tabs.farming.RebirthData.IsAutoRebirthing = true
		runtime:Spawn(function(generation)
			while tabs.farming.RebirthData.IsAutoRebirthing
				and tabs.farming.RebirthData.Generation == generation
				and tabs.farming.RebirthData.Rebirths.Value < tabs.farming.RebirthData.TargetRebirths do
				services.ReplicatedStorage.rEvents.rebirthRemote:InvokeServer("rebirthRequest")
				task.wait(0.05)
			end
			if tabs.farming.RebirthData.Generation ~= generation then return end
			tabs.farming.RebirthData.Switch:Set(false)
		end, tabs.farming.RebirthData.Generation)
	else
		tabs.farming.RebirthData.IsAutoRebirthing = false
	end
end)

runtime:Spawn(function()
	while true do
		tabs.farming.RebirthData.Label.Text = "Rebirths: " .. utils.formatWithCommas(tabs.farming.RebirthData.Rebirths.Value)
		tabs.farming.RebirthData.TargetLabel.Text = "Target Rebirths: " .. utils.formatWithCommas(tabs.farming.RebirthData.TargetRebirths)
		task.wait(0.01)
	end
end)

tabs.farming.SizeData = {Active = false}

tabs.farming.SizeSwitch = tabs.farming:AddSwitch("Auto Size 1", function(bool) tabs.farming.SizeData.Active = bool end)
tabs.farming.SizeSwitch:Set(false)

runtime:Spawn(function()
	while true do
		if tabs.farming.SizeData.Active and utils.playerData.Character and utils.playerData.Humanoid then
			utils.remotes.ChangeSpeedSize:InvokeServer("changeSize", 1)
		end
		task.wait(0.01)
	end
end)

tabs.farming.KingData = {TargetPosition = CFrame.new(-8665.4, 17.21, -5792.9), TeleportActive = false}

tabs.farming.KingSwitch = tabs.farming:AddSwitch("Auto King", function(enabled)
	tabs.farming.KingData.TeleportActive = enabled
end)

runtime:Spawn(function()
	while true do
		if tabs.farming.KingData.TeleportActive then
			if not utils.playerData.Character or not utils.playerData.Character:FindFirstChildOfClass("Humanoid") then
				utils.playerData.Player.CharacterAdded:Wait()
				utils.playerData.Character = utils.playerData.Player.Character
				task.wait(2)
			end

			if not utils.playerData.Humanoid or utils.playerData.Humanoid.Health <= 0 then
				repeat
					task.wait(0.5)
					utils.playerData.Character = utils.playerData.Player.Character
					utils.playerData.Humanoid = utils.playerData.Character and utils.playerData.Character:FindFirstChildOfClass("Humanoid")
				until utils.playerData.Character and utils.playerData.Humanoid and utils.playerData.Humanoid.Health > 0
				task.wait(1)
			end

			if tabs.farming.KingData.TeleportActive and utils.playerData.Character and utils.playerData.Character:FindFirstChild("HumanoidRootPart") then
				if (utils.playerData.Character.HumanoidRootPart.Position - tabs.farming.KingData.TargetPosition.Position).magnitude > 5 then
					pcall(function()
						utils.playerData.Character.HumanoidRootPart.CFrame = tabs.farming.KingData.TargetPosition
					end)
				end
			end
		end
		task.wait(0.05)
	end
end)

tabs.farming:AddHeading("Auto Exercises (recommended for rebirthing):")

tabs.farming.ExerciseData = {
	SelectedTool = nil,
	AutoFarm = false,
	Generation = 0
}

tabs.farming.ToolDropdown = tabs.farming:AddDropdown("Select Exercise", function(selection)
	tabs.farming.ExerciseData.SelectedTool = selection
end)
for _, tool in ipairs({"Weight", "Pushups", "Situps", "Handstands"}) do
	tabs.farming.ToolDropdown:Add(tool)
end

tabs.farming.MachinesFolder = services.Workspace:WaitForChild("machinesFolder")
tabs.farming.SquatsByName = {}
tabs.farming.SquatMachineNames = {}
tabs.farming.LiftMachineNames = {}
tabs.farming.MachineCooldownUntil = 0
tabs.farming.MachineExerciseData = {
	Squat = {SelectedMachine = nil, ActiveMachine = nil, Running = false, Generation = 0, ReenterAt = 0, SeatPart = nil, Choices = {}},
	Lift = {SelectedMachine = nil, ActiveMachine = nil, Running = false, Generation = 0, ReenterAt = 0, SeatPart = nil, Choices = {}}
}

for _, machine in ipairs(tabs.farming.MachinesFolder:GetChildren()) do
	tabs.farming.runtime.lowerName = string.lower(machine.Name)
	if string.find(tabs.farming.runtime.lowerName, "squat", 1, true) and tabs.farming.runtime.lowerName ~= "squat rack" then
		tabs.farming.SquatsByName[machine.Name] = tabs.farming.SquatsByName[machine.Name] or {}
		table.insert(tabs.farming.SquatsByName[machine.Name], machine)
	elseif string.find(tabs.farming.runtime.lowerName, "lift", 1, true) and tabs.farming.runtime.lowerName ~= "deadlift" then
		tabs.farming.MachineExerciseData.Lift.Choices[machine.Name] = machine
		table.insert(tabs.farming.LiftMachineNames, machine.Name)
	end
end

for machineName, matchingSquats in pairs(tabs.farming.SquatsByName) do
	tabs.farming.MachineExerciseData.Squat.Choices[machineName] = matchingSquats[1]
	table.insert(tabs.farming.SquatMachineNames, machineName)
end

table.sort(tabs.farming.SquatMachineNames)
table.sort(tabs.farming.LiftMachineNames)

tabs.farming.getMachineInteractPart = function(machine)
	for _, descendant in ipairs(machine:GetDescendants()) do
		if descendant:IsA("BasePart") and string.lower(descendant.Name) == "interactseat" then
			return descendant
		end
	end
end

tabs.farming.enterExerciseMachine = function(machine, machineData, generation, character, root, humanoid, interactPart)
	if not machine or not machine.Parent or not machineData.Running or machineData.Generation ~= generation
		or os.clock() < math.max(machineData.ReenterAt, tabs.farming.MachineCooldownUntil) then return false end
	character = utils.playerData.Player.Character
	root = character and character:FindFirstChild("HumanoidRootPart")
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	interactPart = tabs.farming.getMachineInteractPart(machine)
	if not root or not humanoid or humanoid.Health <= 0 or not interactPart then return false end

	root.CFrame = interactPart.CFrame * CFrame.new(0, 3, 0)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	task.wait(0.4)
	if not machineData.Running or machineData.Generation ~= generation
		or machineData.SelectedMachine ~= machine or utils.playerData.Player.Character ~= character or humanoid.Health <= 0
		or os.clock() < tabs.farming.MachineCooldownUntil then return false end
	machineData.EnteringMachine = machine
	services.VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
	task.wait(0.1)
	services.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
	task.wait(0.4)
	return machineData.Running and machineData.Generation == generation
		and machineData.SelectedMachine == machine and machineData.SelectedMachine == machine and os.clock() >= tabs.farming.MachineCooldownUntil
		and utils.playerData.Player.Character == character and humanoid.Health > 0
end

tabs.farming.ToolExerciseSwitch = nil
tabs.farming.SquatExerciseSwitch = nil
tabs.farming.LiftExerciseSwitch = nil

tabs.farming.ToolExerciseSwitch = tabs.farming:AddSwitch("Start exercising", function(enabled)
	tabs.farming.ExerciseData.AutoFarm = enabled
	tabs.farming.ExerciseData.Generation += 1
	if enabled then
		if tabs.farming.SquatExerciseSwitch and tabs.farming.MachineExerciseData.Squat.Running then tabs.farming.SquatExerciseSwitch:Set(false) end
		if tabs.farming.LiftExerciseSwitch and tabs.farming.MachineExerciseData.Lift.Running then tabs.farming.LiftExerciseSwitch:Set(false) end
		runtime:Spawn(function(generation, character, humanoid, tool)
			while tabs.farming.ExerciseData.AutoFarm and tabs.farming.ExerciseData.Generation == generation do
				character = utils.playerData.Player.Character
				humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 and tabs.farming.ExerciseData.SelectedTool then
					tool = character:FindFirstChild(tabs.farming.ExerciseData.SelectedTool)
						or utils.playerData.Player.Backpack:FindFirstChild(tabs.farming.ExerciseData.SelectedTool)
					if tool and tool.Parent ~= character then
						humanoid:EquipTool(tool)
						task.wait(0.2)
					end
					if not tabs.farming.ExerciseData.AutoFarm or tabs.farming.ExerciseData.Generation ~= generation then return end
					if tool and tool.Parent == character and utils.playerData.Player.Character == character and humanoid.Health > 0 then
						pcall(function() utils.playerData.Player.muscleEvent:FireServer("rep") end)
						if tabs.farming.ExerciseData.SelectedTool == "Handstands" and tick() % 6 < 0.1 then
							pcall(function()
								services.VirtualUser:CaptureController()
								services.VirtualUser:ClickButton1(Vector2.new(500, 500))
							end)
						end
					end
				end
				task.wait(0.05)
			end
		end, tabs.farming.ExerciseData.Generation)
	elseif tabs.farming.ExerciseData.SelectedTool and utils.playerData.Player.Character then
		tabs.farming.runtime.equippedTool = utils.playerData.Player.Character:FindFirstChild(tabs.farming.ExerciseData.SelectedTool)
		if tabs.farming.runtime.equippedTool then tabs.farming.runtime.equippedTool.Parent = utils.playerData.Player.Backpack end
	end
end)

tabs.farming.addMachineDropdown = function(label, machineData, machineNames)
	tabs.farming.runtime.dropdown = tabs.farming:AddDropdown(label, function(selection)
		if machineData.ActiveMachine or machineData.SeatPart or machineData.EnteringMachine then
			tabs.farming.MachineCooldownUntil = math.max(tabs.farming.MachineCooldownUntil, os.clock() + 4)
			if utils.playerData.Player.Character and utils.playerData.Player.Character:FindFirstChildOfClass("Humanoid") then
				utils.playerData.Player.Character:FindFirstChildOfClass("Humanoid").Jump = true
			end
		end
		machineData.SelectedMachine = machineData.Choices[selection]
		machineData.ActiveMachine = nil
		machineData.SeatPart = nil
		machineData.ReenterAt = math.max(machineData.ReenterAt, tabs.farming.MachineCooldownUntil)
	end)

	for _, machineName in ipairs(machineNames) do
		tabs.farming.runtime.dropdown:Add(machineName)
	end
end

tabs.farming.startMachineExercise = function(machineData)
	machineData.Generation += 1
	runtime:Spawn(function(generation, lastCharacter, character, humanoid, humanoidState, jumpedOff)
		lastCharacter = utils.playerData.Player.Character
		while machineData.Running and machineData.Generation == generation do
			character = utils.playerData.Player.Character
			humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if character ~= lastCharacter then
				lastCharacter = character
				machineData.ActiveMachine = nil
				machineData.SeatPart = nil
				machineData.ReenterAt = math.max(machineData.ReenterAt, os.clock() + 4)
				tabs.farming.MachineCooldownUntil = math.max(tabs.farming.MachineCooldownUntil, machineData.ReenterAt)
			end
			if humanoid and humanoid.Health > 0 then
				humanoidState = humanoid:GetState()
				jumpedOff = machineData.ActiveMachine and (
					humanoidState == Enum.HumanoidStateType.Jumping
					or humanoidState == Enum.HumanoidStateType.Freefall
					or (machineData.SeatPart and humanoid.SeatPart ~= machineData.SeatPart)
				)
				if jumpedOff then
					machineData.ActiveMachine = nil
					machineData.SeatPart = nil
					machineData.ReenterAt = math.max(machineData.ReenterAt, os.clock() + 4)
					tabs.farming.MachineCooldownUntil = math.max(tabs.farming.MachineCooldownUntil, machineData.ReenterAt)
				end
				if machineData.SelectedMachine and not machineData.ActiveMachine
					and os.clock() >= math.max(machineData.ReenterAt, tabs.farming.MachineCooldownUntil) then
					if tabs.farming.enterExerciseMachine(machineData.SelectedMachine, machineData, generation) then
						machineData.ActiveMachine = machineData.SelectedMachine
						machineData.SeatPart = humanoid.SeatPart
					end
					if machineData.Generation == generation then machineData.EnteringMachine = nil end
				end
			elseif machineData.ActiveMachine then
				machineData.ActiveMachine = nil
				machineData.SeatPart = nil
				machineData.ReenterAt = math.max(machineData.ReenterAt, os.clock() + 4)
				tabs.farming.MachineCooldownUntil = math.max(tabs.farming.MachineCooldownUntil, machineData.ReenterAt)
			end
			task.wait(0.1)
		end
	end, machineData.Generation)
end

tabs.farming.setMachineExerciseState = function(machineData, otherMachineData, state)
	if not state and (machineData.ActiveMachine or machineData.SeatPart or machineData.EnteringMachine) then
		machineData.ReenterAt = math.max(machineData.ReenterAt, os.clock() + 4)
		tabs.farming.MachineCooldownUntil = math.max(tabs.farming.MachineCooldownUntil, machineData.ReenterAt)
	end
	machineData.Running = state
	machineData.EnteringMachine = nil
	machineData.Generation += 1
	machineData.ActiveMachine = nil
	machineData.SeatPart = nil
	machineData.ReenterAt = math.max(machineData.ReenterAt, tabs.farming.MachineCooldownUntil)

	if not state then return end
	if tabs.farming.ToolExerciseSwitch and tabs.farming.ExerciseData.AutoFarm then tabs.farming.ToolExerciseSwitch:Set(false) end
	if otherMachineData.Running then
		if machineData == tabs.farming.MachineExerciseData.Squat and tabs.farming.LiftExerciseSwitch then
			tabs.farming.LiftExerciseSwitch:Set(false)
		elseif machineData == tabs.farming.MachineExerciseData.Lift and tabs.farming.SquatExerciseSwitch then
			tabs.farming.SquatExerciseSwitch:Set(false)
		end
	end
	tabs.farming.startMachineExercise(machineData)
	runtime:Spawn(function(generation)
		while machineData.Running and machineData.Generation == generation do
			if machineData.ActiveMachine then utils.playerData.Player.muscleEvent:FireServer("rep") end
			task.wait(0.1)
		end
	end, machineData.Generation)
end

tabs.farming.addMachineDropdown("Select Squat", tabs.farming.MachineExerciseData.Squat, tabs.farming.SquatMachineNames)
tabs.farming.SquatExerciseSwitch = tabs.farming:AddSwitch("Auto Squat", function(state)
	tabs.farming.setMachineExerciseState(tabs.farming.MachineExerciseData.Squat, tabs.farming.MachineExerciseData.Lift, state)
end)

tabs.farming.addMachineDropdown("Select Lift", tabs.farming.MachineExerciseData.Lift, tabs.farming.LiftMachineNames)
tabs.farming.LiftExerciseSwitch = tabs.farming:AddSwitch("Auto Lift", function(state)
	tabs.farming.setMachineExerciseState(tabs.farming.MachineExerciseData.Lift, tabs.farming.MachineExerciseData.Squat, state)
end)

tabs.farming.AutoRepRunning = false
tabs.farming.AutoRepSwitch = tabs.farming:AddSwitch("Auto Rep", function(state)
	tabs.farming.AutoRepRunning = state
	if not state then return end
	runtime:Spawn(function()
		while tabs.farming.AutoRepRunning do
			utils.playerData.Player.muscleEvent:FireServer("rep")
			task.wait(0.1)
		end
	end)
end)

tabs.farming:AddHeading("Auto Rock:")

tabs.farming.RockData = {
	Data = {["Tiny Rock - 0 Dura"] = 0, ["Large Rock - 100 Dura"] = 100, ["Punching Rock - 10 Dura"] = 10,
		["Golden Rock - 5k Dura"] = 5000, ["Frost Rock - 150k Dura"] = 150000, ["Mythical Rock - 400k Dura"] = 400000,
		["Eternal Rock - 750k Dura"] = 750000, ["Legend Rock - 1m Dura"] = 1000000, ["Muscle King Rock - 5m Dura"] = 5000000,
		["Jungle Rock - 10m Dura"] = 10000000, ["Industrial Rock - 25m Dura"] = 25000000,},
	SelectedRock = nil
}

tabs.farming.RockDropdown = tabs.farming:AddDropdown("Select Rock", function(selection) tabs.farming.RockData.SelectedRock = selection end)
for rockName in pairs(tabs.farming.RockData.Data) do tabs.farming.RockDropdown:Add(rockName) end

tabs.farming.RockSwitch = tabs.farming:AddSwitch("Auto Rock", function(enabled)
	tabs.farming.RockFarmRunning = enabled
	if enabled and tabs.farming.RockData.SelectedRock then
		runtime:Spawn(function()
			while tabs.farming.RockFarmRunning do
				task.wait(0.12)
				if tabs.farming.RockFarmRunning and utils.playerData.Player.Character
					and utils.playerData.Player.Character:FindFirstChild("LeftHand")
					and utils.playerData.Player.Character:FindFirstChild("RightHand")
					and utils.playerData.Player.Durability.Value >= tabs.farming.RockData.Data[tabs.farming.RockData.SelectedRock] then
					for _, v in pairs(tabs.farming.MachinesFolder:GetDescendants()) do
						if v.Name == "neededDurability" and v.Value == tabs.farming.RockData.Data[tabs.farming.RockData.SelectedRock] and
						   utils.playerData.Player.Character:FindFirstChild("LeftHand") and v.Parent:FindFirstChild("Rock") then
							utils.touchParts(v.Parent.Rock, utils.playerData.Player.Character.RightHand, 0)
							utils.touchParts(v.Parent.Rock, utils.playerData.Player.Character.RightHand, 1)
							utils.touchParts(v.Parent.Rock, utils.playerData.Player.Character.LeftHand, 0)
							utils.touchParts(v.Parent.Rock, utils.playerData.Player.Character.LeftHand, 1)
							tabs.killing.getTool()
						end
					end
				end
			end
		end)
	end
end)

tabs.farming:AddHeading("Better Strength Farming:")

tabs.farming.Configs = {
	{name = "Pushup + Industrial Rock", tool = "Pushups", rock = "Industrial Rock"},
	{name = "Pushup + Jungle Rock", tool = "Pushups", rock = "Ancient Jungle Rock"},
	{name = "Pushup + Muscle King Rock", tool = "Pushups", rock = "Muscle King Mountain"},
	{name = "Pushup + Legends Rock", tool = "Pushups", rock = "Rock Of Legends"}
}
tabs.farming.ActiveConfigs = {}

for _, config in ipairs(tabs.farming.Configs) do
	tabs.farming.ActiveConfigs[config.name] = false
	config.Switch = tabs.farming:AddSwitch(config.name, function(state)
		tabs.farming.ActiveConfigs[config.name] = state
		if tabs.farming.ActiveConfigs[config.name] then
			if utils.playerData.Player.Backpack:FindFirstChild(config.tool) and not utils.playerData.Player.Character:FindFirstChild(config.tool) then
				utils.playerData.Player.Character.Humanoid:EquipTool(utils.playerData.Player.Backpack[config.tool])
			end
			runtime:Spawn(function()
				while tabs.farming.ActiveConfigs[config.name] do
					utils.playerData.Player.muscleEvent:FireServer("rep")
					if tabs.farming.MachinesFolder:FindFirstChild(config.rock) and utils.playerData.Player.Character:FindFirstChild("LeftHand") then
						utils.touchParts(tabs.farming.MachinesFolder[config.rock].Rock, utils.playerData.Player.Character.LeftHand, 0)
						utils.touchParts(tabs.farming.MachinesFolder[config.rock].Rock, utils.playerData.Player.Character.LeftHand, 1)
					end
					if utils.playerData.Player.Backpack:FindFirstChild("Punch") then
						utils.playerData.Humanoid:EquipTool(utils.playerData.Player.Backpack.Punch)
						utils.playerData.Player.muscleEvent:FireServer("punch", "rightHand")
						utils.playerData.Player.muscleEvent:FireServer("punch", "leftHand")
					end
					services.RunService.RenderStepped:Wait()
					if utils.playerData.Player.Backpack:FindFirstChild(config.tool) then
						utils.playerData.Player.Character.Humanoid:EquipTool(utils.playerData.Player.Backpack[config.tool])
					end
				end
			end)
		else
			if utils.playerData.Player.Character:FindFirstChild(config.tool) then
				utils.playerData.Player.Character[config.tool].Parent = utils.playerData.Player.Backpack
			end
		end
	end)
end

tabs.boss:AddHeading("Boss Farming:")
tabs.boss.StatusLabel = tabs.boss:AddLabel("Status: Waiting for Boss")
tabs.boss.BossLabel = tabs.boss:AddLabel("Boss: None")
tabs.boss.HealthLabel = tabs.boss:AddLabel("Health: 0 / 0")
tabs.boss.NextBossLabel = tabs.boss:AddLabel("Next Boss: N/A")

tabs.boss.Data = {
	Running = false,
	Generation = 0,
	ContinueTraining = true,
	Phase = "Waiting",
	TrainingSnapshot = nil,
	TrainingRestore = nil,
	TrainingResumeGeneration = 0,
	PreparationSeconds = 4,
	PunchInterval = 0.3,
	LastPunch = 0,
	AttackSequence = nil,
	EvadeUntil = 0,
	EvadeDistance = 230,
	PunchBehindDistance = 45,
	StompHealthThreshold = 0.35,
	DodgeStomps = false,
	BossConfig = nil,
	Bosses = {},
	BossOrder = {},
	BossByDisplayName = {},
	SelectedBosses = {}
}

tabs.boss:AddTextBox("Seconds Training before Boss (when Rebirthing):", function(text)
	if tonumber(text) and tonumber(text) >= 0 then tabs.boss.Data.PreparationSeconds = tonumber(text) end
end, {clear = false})

tabs.boss.SelectedBossesLabel = tabs.boss:AddLabel("Targeted Bosses: Detecting...")
tabs.boss.BossDropdown = tabs.boss:AddDropdown("Target specific Bosses", function(displayName)
	tabs.boss.runtime.bossModelName = tabs.boss.Data.BossByDisplayName[displayName]
	if tabs.boss.runtime.bossModelName then
		tabs.boss.Data.SelectedBosses[tabs.boss.runtime.bossModelName] = not tabs.boss.Data.SelectedBosses[tabs.boss.runtime.bossModelName]
		tabs.boss.updateSelectedBossesLabel()
	end
end)

tabs.boss.updateSelectedBossesLabel = function(selectedNames)
	selectedNames = {}
	for _, modelName in ipairs(tabs.boss.Data.BossOrder) do
		if tabs.boss.Data.SelectedBosses[modelName] then
			table.insert(selectedNames, (string.gsub(tabs.boss.Data.Bosses[modelName], "%s+[Bb][Oo][Ss][Ss]$", "")))
		end
	end
	tabs.boss.SelectedBossesLabel.Text = "Targeted Bosses: " .. (#selectedNames > 0 and table.concat(selectedNames, ", ") or "None")
end

tabs.boss.addBossChoice = function(modelName, displayName)
	modelName = tostring(modelName or "")
	displayName = tostring(displayName or modelName)
	if modelName == "" or tabs.boss.Data.Bosses[modelName] then return end
	tabs.boss.Data.Bosses[modelName] = displayName
	tabs.boss.Data.BossByDisplayName[displayName] = modelName
	tabs.boss.Data.SelectedBosses[modelName] = true
	table.insert(tabs.boss.Data.BossOrder, modelName)
	tabs.boss.BossDropdown:Add(displayName)
	tabs.boss.updateSelectedBossesLabel()
end

tabs.boss.runtime.configSuccess, tabs.boss.Data.BossConfig = pcall(function()
	if services.isSolara then return nil end
	return require(services.ReplicatedStorage:WaitForChild("shared"):WaitForChild("config"):WaitForChild("BossEventConfig"))
end)
if tabs.boss.runtime.configSuccess and tabs.boss.Data.BossConfig and tabs.boss.Data.BossConfig.RARITIES then
	for _, rarity in ipairs(tabs.boss.Data.BossConfig.RARITIES) do
		tabs.boss.addBossChoice(rarity.BossModel, rarity.DisplayName or rarity.Name or rarity.BossModel)
	end
else
	tabs.boss.SelectedBossesLabel.Text = "Farmed Bosses: Waiting for detection"
end

tabs.boss.shouldFarmBoss = function(model)
	if not tabs.boss.Data.Bosses[model.Name] then
		tabs.boss.addBossChoice(model.Name, services.Workspace:GetAttribute("BossDisplayName") or model.Name)
	end
	return tabs.boss.Data.SelectedBosses[model.Name] == true
end

tabs.boss.findActiveBoss = function(model, stats, health, maxHealth, hitbox)
	for _, candidate in ipairs(services.CollectionService:GetTagged("BossEventBoss")) do
		if candidate:IsA("Model") and candidate:IsDescendantOf(services.Workspace) then
			model = candidate
			break
		end
	end

	if not model then
		tabs.boss.runtime.events = services.Workspace:FindFirstChild("Events")
		tabs.boss.runtime.bossFolder = tabs.boss.runtime.events and (tabs.boss.runtime.events:FindFirstChild("BossEvent") or tabs.boss.runtime.events:FindFirstChild("BossArena"))
		if tabs.boss.runtime.bossFolder then
			for _, candidate in ipairs(tabs.boss.runtime.bossFolder:GetDescendants()) do
				if candidate:IsA("Model") and (candidate:FindFirstChild("BossDamageHitbox") or candidate:HasTag("BossEventBoss")) then
					model = candidate
					break
				end
			end
		end
	end

	if not model then return end
	stats = model:FindFirstChild("stats")
	health = stats and stats:FindFirstChild("Health")
	maxHealth = stats and stats:FindFirstChild("MaxHealth")
	hitbox = model:FindFirstChild("BossDamageHitbox", true)
	if not hitbox or not hitbox:IsA("BasePart") then return end
	tabs.boss.runtime.currentHealth = health and health.Value or services.Workspace:GetAttribute("BossHealth")
	if typeof(tabs.boss.runtime.currentHealth) == "number" and tabs.boss.runtime.currentHealth <= 0 then return end
	return model, health, maxHealth, hitbox
end

tabs.boss.getBossDisplayName = function(model)
	return services.Workspace:GetAttribute("BossDisplayName") or model.Name
end

tabs.boss.getBossHealth = function(health)
	return health and health.Value or services.Workspace:GetAttribute("BossHealth") or 0
end

tabs.boss.getBossMaxHealth = function(maxHealth)
	return maxHealth and maxHealth.Value or services.Workspace:GetAttribute("BossMaxHealth") or 0
end

tabs.boss.formatCountdown = function(seconds, hours, minutes)
	seconds = math.max(0, math.floor(seconds or 0))
	hours = math.floor(seconds / 3600)
	minutes = math.floor(seconds % 3600 / 60)
	seconds = seconds % 60
	return string.format("%dh %dmin %ds", hours, minutes, seconds)
end

tabs.boss.leaveExerciseMachine = function(character, humanoid, root)
	character = utils.playerData.Player.Character
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 then return end

	pcall(function()
		services.VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
		humanoid.Sit = false
		humanoid.Jump = true
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		if root then root.AssemblyLinearVelocity = Vector3.new(0, math.max(root.AssemblyLinearVelocity.Y, 50), 0) end
	end)
	pcall(function() services.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
	tabs.farming.MachineCooldownUntil = math.max(tabs.farming.MachineCooldownUntil, os.clock() + 4)
	for _, machineData in pairs(tabs.farming.MachineExerciseData) do
		machineData.ReenterAt = math.max(machineData.ReenterAt, tabs.farming.MachineCooldownUntil)
	end
	task.wait(0.2)
end

tabs.boss.captureTraining = function()
	tabs.boss.Data.TrainingResumeGeneration += 1
	if tabs.boss.Data.TrainingSnapshot then return end
	if tabs.boss.Data.TrainingRestore then
		tabs.boss.Data.TrainingSnapshot = tabs.boss.Data.TrainingRestore
		tabs.boss.Data.TrainingRestore = nil
		return
	end
	tabs.boss.Data.TrainingSnapshot = {
		Rebirth = tabs.farming.RebirthData.IsAutoRebirthing,
		Size = tabs.farming.SizeData.Active,
		King = tabs.farming.KingData.TeleportActive,
		Tool = tabs.farming.ExerciseData.AutoFarm,
		SelectedTool = tabs.farming.ExerciseData.SelectedTool,
		Squat = tabs.farming.MachineExerciseData.Squat.Running,
		Lift = tabs.farming.MachineExerciseData.Lift.Running,
		SquatMachine = tabs.farming.MachineExerciseData.Squat.ActiveMachine or tabs.farming.MachineExerciseData.Squat.SelectedMachine,
		LiftMachine = tabs.farming.MachineExerciseData.Lift.ActiveMachine or tabs.farming.MachineExerciseData.Lift.SelectedMachine,
		AutoRep = tabs.farming.AutoRepRunning,
		Rock = tabs.farming.RockFarmRunning == true,
		Configs = {}
	}
	for _, config in ipairs(tabs.farming.Configs) do
		tabs.boss.Data.TrainingSnapshot.Configs[config.name] = tabs.farming.ActiveConfigs[config.name] == true
	end
end

tabs.boss.startSavedExercise = function(snapshot, preparing)
	if snapshot.Squat then
		tabs.farming.MachineExerciseData.Squat.SelectedMachine = snapshot.SquatMachine
		if not tabs.farming.MachineExerciseData.Squat.Running then tabs.farming.SquatExerciseSwitch:Set(true) end
	elseif snapshot.Lift then
		tabs.farming.MachineExerciseData.Lift.SelectedMachine = snapshot.LiftMachine
		if not tabs.farming.MachineExerciseData.Lift.Running then tabs.farming.LiftExerciseSwitch:Set(true) end
	elseif snapshot.Tool or preparing then
		tabs.farming.ExerciseData.SelectedTool = snapshot.Tool and snapshot.SelectedTool or "Pushups"
		if not tabs.farming.ExerciseData.AutoFarm then tabs.farming.ToolExerciseSwitch:Set(true) end
	end
end

tabs.boss.isTrainingReady = function(snapshot, preparing, character, humanoid, machine)
	character = utils.playerData.Player.Character
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or not character:FindFirstChild("HumanoidRootPart") then return false end
	if snapshot.Squat or snapshot.Lift then
		machine = snapshot.Squat and tabs.farming.MachineExerciseData.Squat or tabs.farming.MachineExerciseData.Lift
		return machine.Running and machine.ActiveMachine ~= nil and machine.ActiveMachine == machine.SelectedMachine
			and (not machine.SeatPart or humanoid.SeatPart == machine.SeatPart)
	end
	if snapshot.Tool or preparing then
		return tabs.farming.ExerciseData.AutoFarm
			and character:FindFirstChild(snapshot.Tool and snapshot.SelectedTool or "Pushups") ~= nil
	end
	return true
end

tabs.boss.pauseTraining = function(onMachine)
	tabs.boss.captureTraining()
	onMachine = tabs.farming.MachineExerciseData.Squat.ActiveMachine or tabs.farming.MachineExerciseData.Squat.EnteringMachine
		or tabs.farming.MachineExerciseData.Lift.ActiveMachine or tabs.farming.MachineExerciseData.Lift.EnteringMachine
	if tabs.farming.RebirthData.IsAutoRebirthing then tabs.farming.RebirthData.Switch:Set(false) end
	if tabs.farming.SizeData.Active then tabs.farming.SizeSwitch:Set(false) end
	if tabs.farming.KingData.TeleportActive then tabs.farming.KingSwitch:Set(false) end
	if tabs.farming.ExerciseData.AutoFarm then tabs.farming.ToolExerciseSwitch:Set(false) end
	if tabs.farming.MachineExerciseData.Squat.Running then tabs.farming.SquatExerciseSwitch:Set(false) end
	if tabs.farming.MachineExerciseData.Lift.Running then tabs.farming.LiftExerciseSwitch:Set(false) end
	if tabs.farming.AutoRepRunning then tabs.farming.AutoRepSwitch:Set(false) end
	if tabs.farming.RockFarmRunning then tabs.farming.RockSwitch:Set(false) end
	for _, config in ipairs(tabs.farming.Configs) do
		if tabs.farming.ActiveConfigs[config.name] and config.Switch then config.Switch:Set(false) end
	end
	if onMachine then tabs.boss.leaveExerciseMachine() end
end

tabs.boss.hasTrainingStats = function(strength, durability)
	strength = utils.playerData.Player.leaderstats:FindFirstChild("Strength")
	durability = utils.playerData.Player:FindFirstChild("Durability")
	return strength and durability and strength.Value > 0 and durability.Value > 0
end

tabs.boss.prepareForBoss = function(boss, preparation, character, humanoid, tool, backpack, toolName, strength)
	if not boss.Data.Preparation then
		tabs.boss.pauseTraining()
		boss.Data.Preparation = {LastRep = 0}
		boss.Data.Phase = "Training"
	end
	preparation = boss.Data.Preparation
	character = utils.playerData.Player.Character
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if preparation.Character ~= character or preparation.Rebirths ~= tabs.farming.RebirthData.Rebirths.Value then
		preparation.Character = character
		preparation.Rebirths = tabs.farming.RebirthData.Rebirths.Value
		preparation.StartedAt = nil
		preparation.PetsReady = nil
		preparation.LastRep = 0
		preparation.Required = not tabs.boss.hasTrainingStats()
	end
	if not humanoid or humanoid.Health <= 0 then
		preparation.StartedAt = nil
		boss.StatusLabel.Text = "Status: Waiting for Respawn"
		return false
	end
	if not preparation.Required then
		boss.Data.FightCharacter = character
		boss.Data.FightRebirths = tabs.farming.RebirthData.Rebirths.Value
		boss.Data.Preparation = nil
		return true
	end
	if utils.playerData.Player.Character ~= character or humanoid.Health <= 0 then return false end
	backpack = utils.playerData.Player:FindFirstChild("Backpack")
	strength = utils.playerData.Player.leaderstats:FindFirstChild("Strength")
	if not strength then return false end
	toolName = strength.Value < 2000 and "Weight" or "Pushups"
	if toolName == "Weight" then preparation.StartedAt = nil end
	tool = character:FindFirstChild(toolName) or backpack and backpack:FindFirstChild(toolName)
	if not tool then
		preparation.StartedAt = nil
		boss.StatusLabel.Text = "Status: Waiting for " .. toolName
		return false
	end
	if tool.Parent ~= character then humanoid:EquipTool(tool) end
	if tool.Parent ~= character then preparation.StartedAt = nil return false end
	if toolName == "Pushups" then preparation.StartedAt = preparation.StartedAt or os.clock() end
	if os.clock() - preparation.LastRep >= 0.1 then
		utils.playerData.Player.muscleEvent:FireServer("rep")
		preparation.LastRep = os.clock()
	end
	if toolName == "Weight" then
		boss.StatusLabel.Text = "Status: Weight Training | " .. utils.formatNumber(strength.Value) .. " / 2K Strength"
		return false
	end
	boss.StatusLabel.Text = "Status: Training before Boss (" .. string.format("%.1f", math.max(0, tabs.boss.Data.PreparationSeconds - (os.clock() - preparation.StartedAt))) .. "s)"
	if os.clock() - preparation.StartedAt < tabs.boss.Data.PreparationSeconds then return false end
	boss.Data.FightCharacter = character
	boss.Data.FightRebirths = tabs.farming.RebirthData.Rebirths.Value
	boss.Data.Preparation = nil
	return true
end

tabs.boss.needsRetraining = function(boss, character, humanoid)
	character = utils.playerData.Player.Character
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return not humanoid or humanoid.Health <= 0 or boss.Data.FightCharacter ~= utils.playerData.Player.Character
		or boss.Data.FightRebirths ~= tabs.farming.RebirthData.Rebirths.Value
end

tabs.boss.resumeTraining = function(snapshot)
	snapshot = tabs.boss.Data.TrainingSnapshot
	if not snapshot then return end
	tabs.boss.Data.TrainingSnapshot = nil
	tabs.boss.Data.TrainingRestore = snapshot
	tabs.boss.Data.TrainingResumeGeneration += 1
	if not snapshot.Tool and tabs.farming.ExerciseData.AutoFarm then tabs.farming.ToolExerciseSwitch:Set(false) end
	tabs.farming.ExerciseData.SelectedTool = snapshot.SelectedTool
	tabs.boss.startSavedExercise(snapshot, false)
	if snapshot.Size then tabs.farming.SizeSwitch:Set(true) end
	if snapshot.King then tabs.farming.KingSwitch:Set(true) end
	if snapshot.AutoRep then tabs.farming.AutoRepSwitch:Set(true) end
	if snapshot.Rock then tabs.farming.RockSwitch:Set(true) end
	for _, config in ipairs(tabs.farming.Configs) do
		if snapshot.Configs[config.name] and config.Switch then config.Switch:Set(true) end
	end
	runtime:Spawn(function(generation)
		while tabs.boss.Data.TrainingResumeGeneration == generation do
			if tabs.boss.isTrainingReady(snapshot, false) then
				tabs.boss.Data.TrainingRestore = nil
				if snapshot.Rebirth then tabs.farming.RebirthData.Switch:Set(true) end
				return
			end
			task.wait(0.1)
		end
	end, tabs.boss.Data.TrainingResumeGeneration)
end

tabs.boss.getBossHeadPosition = function(model, hitbox, head)
	head = model:FindFirstChild("Head", true) or model:FindFirstChild("head", true)
	if head and head:IsA("BasePart") then return head.Position end
	if head and head:IsA("Bone") then return head.WorldPosition end
	return hitbox.Position + Vector3.new(0, hitbox.Size.Y * 0.35, 0)
end

tabs.boss.getAliveCharacter = function(generation, timeout, startedAt, character, root, humanoid)
	if not tabs.boss.Data.Running or tabs.boss.Data.Generation ~= generation then return end
	startedAt = os.clock()
	repeat
		character = utils.playerData.Player.Character
		root = character and character:FindFirstChild("HumanoidRootPart")
		humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			utils.playerData.Character = character
			utils.playerData.Humanoid = humanoid
			return character, root, humanoid
		end
		tabs.boss.StatusLabel.Text = "Status: Waiting for Respawn"
		task.wait(0.1)
	until not tabs.boss.Data.Running
		or tabs.boss.Data.Generation ~= generation
		or (timeout and os.clock() - startedAt >= timeout)
end

tabs.boss.evadeAttack = function(boss, model, hitbox, root, humanoid, sequence, attackKind, attackCFrame, impactTime, direction, safePosition, center)
	sequence = model:GetAttribute("BossAttackSequence")
	attackKind = model:GetAttribute("BossAttackKind")
	attackCFrame = model:GetAttribute("BossAttackCFrame")
	impactTime = model:GetAttribute("BossAttackImpactTime")

	if typeof(sequence) == "number" and sequence ~= boss.Data.AttackSequence then
		boss.Data.AttackSequence = sequence
		if typeof(attackKind) == "string" and typeof(attackCFrame) == "CFrame" and typeof(impactTime) == "number" then
			boss.Data.EvadeUntil = impactTime + 0.6
		end
	end

	if typeof(attackCFrame) ~= "CFrame" or services.Workspace:GetServerTimeNow() > boss.Data.EvadeUntil then
		return
	end

	attackKind = string.lower(tostring(attackKind or ""))
	if string.find(attackKind, "punch", 1, true) then
		center = tabs.boss.getBossHeadPosition(model, hitbox)
		direction = Vector3.new(attackCFrame.LookVector.X, 0, attackCFrame.LookVector.Z)
		if direction.Magnitude < 1 then direction = Vector3.new(hitbox.CFrame.LookVector.X, 0, hitbox.CFrame.LookVector.Z) end
		if direction.Magnitude < 1 then direction = Vector3.new(0, 0, 1) end
		safePosition = center - direction.Unit * boss.Data.PunchBehindDistance
		root.CFrame = CFrame.lookAt(safePosition, center)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		boss.StatusLabel.Text = "Status: Dodging Punch"
		return "Punch"
	end

	if not string.find(attackKind, "stomp", 1, true) then return end
	if humanoid.Health / math.max(humanoid.MaxHealth, 1) <= boss.Data.StompHealthThreshold then
		boss.Data.DodgeStomps = true
	end
	if not boss.Data.DodgeStomps then return end

	direction = Vector3.new(root.Position.X - attackCFrame.Position.X, 0, root.Position.Z - attackCFrame.Position.Z)
	if direction.Magnitude < 1 then
		direction = Vector3.new(-attackCFrame.LookVector.X, 0, -attackCFrame.LookVector.Z)
	end
	if direction.Magnitude < 1 then direction = Vector3.new(1, 0, 0) end
	direction = direction.Unit
	safePosition = attackCFrame.Position + direction * boss.Data.EvadeDistance + Vector3.new(0, 18, 0)
	root.CFrame = CFrame.lookAt(safePosition, attackCFrame.Position)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	boss.StatusLabel.Text = "Status: Dodging Stomp"
	return "Stomp"
end

tabs.boss.attack = function(boss, model, health, maxHealth, hitbox, character, root, humanoid, punch, leftHand, rightHand, center, position, evadeMode)
	character = utils.playerData.Player.Character
	root = character and character:FindFirstChild("HumanoidRootPart")
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then return end
	evadeMode = tabs.boss.evadeAttack(boss, model, hitbox, root, humanoid)
	if evadeMode == "Stomp" then return end
	punch = character:FindFirstChild("Punch") or utils.playerData.Backpack:FindFirstChild("Punch")
	if punch and punch.Parent ~= character then humanoid:EquipTool(punch) end
	leftHand = character:FindFirstChild("LeftHand")
	rightHand = character:FindFirstChild("RightHand")
	center = tabs.boss.getBossHeadPosition(model, hitbox)
	if evadeMode ~= "Punch" then
		position = center
		root.CFrame = CFrame.lookAt(position, position + hitbox.CFrame.LookVector)
	end
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	pcall(function()
		if leftHand then
			utils.touchParts(hitbox, leftHand, 0)
			utils.touchParts(hitbox, leftHand, 1)
		end
		if rightHand then
			utils.touchParts(hitbox, rightHand, 0)
			utils.touchParts(hitbox, rightHand, 1)
		end
	end)

	if os.clock() - boss.Data.LastPunch >= boss.Data.PunchInterval then
		boss.Data.LastPunch = os.clock()
		pcall(function()
			utils.remotes.MuscleEvent:FireServer("punch", "leftHand")
			utils.remotes.MuscleEvent:FireServer("punch", "rightHand")
			if punch then punch:Activate() end
		end)
	end

	boss.BossLabel.Text = (boss.BossLabelPrefix or "Boss: ") .. boss.getBossDisplayName(model)
	boss.runtime.health = boss.getBossHealth(health, model)
	boss.runtime.maxHealth = boss.getBossMaxHealth(maxHealth, model)
	boss.HealthLabel.Text = "Health: " .. utils.formatNumber(boss.runtime.health) .. " / " .. utils.formatNumber(boss.runtime.maxHealth)
end

tabs.boss.findChest = function(chest, prompt, part)
	for _, candidate in ipairs(services.CollectionService:GetTagged("BossEventChest")) do
		if candidate:IsDescendantOf(services.Workspace) then chest = candidate break end
	end
	if not chest then chest = services.Workspace:FindFirstChild("BossChest", true) end
	if not chest then
		for _, candidate in ipairs(services.Workspace:GetDescendants()) do
			if candidate:IsA("ProximityPrompt") and candidate.Name == "bossChestPrompt" then
				chest = candidate.Parent
				break
			end
		end
	end
	if not chest then return end
	prompt = chest:FindFirstChild("bossChestPrompt", true)
	part = prompt and prompt.Parent or (chest:IsA("Model") and (chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart", true))) or chest
	if part and part:IsA("BasePart") then return chest, prompt, part end
end

tabs.boss.collectChest = function(generation, startedAt, chest, prompt, part, character, root)
	tabs.boss.StatusLabel.Text = "Status: Waiting for Chest"
	startedAt = os.clock()
	repeat
		chest, prompt, part = tabs.boss.findChest()
		if chest and chest:GetAttribute("BossChestEmerging") ~= true then break end
		task.wait(0.1)
	until not tabs.boss.Data.Running or tabs.boss.Data.Generation ~= generation or os.clock() - startedAt >= 12
	if not tabs.boss.Data.Running or tabs.boss.Data.Generation ~= generation or not chest or not part then return end

	tabs.boss.StatusLabel.Text = "Status: Collecting Chest"
	startedAt = os.clock()
	repeat
		character, root = tabs.boss.getAliveCharacter(generation, 2)
		if character and root and chest.Parent and part.Parent then
			tabs.boss.StatusLabel.Text = "Status: Collecting Chest"
			pcall(function()
				root.CFrame = CFrame.lookAt(part.Position + Vector3.new(0, 3, 4), part.Position)
				root.AssemblyLinearVelocity = Vector3.zero
			end)
			task.wait(0.15)
			if not tabs.boss.Data.Running or tabs.boss.Data.Generation ~= generation then return end
			if not (prompt and prompt.Parent and type(fireproximityprompt) == "function"
				and pcall(fireproximityprompt, prompt)) then
				pcall(function()
					services.VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
					task.wait(0.1)
					services.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
				end)
			end
		end
		task.wait(0.25)
	until not tabs.boss.Data.Running
		or tabs.boss.Data.Generation ~= generation
		or utils.playerData.Player:GetAttribute("BossChestPending") == false
		or not chest.Parent
		or os.clock() - startedAt >= 12
end

tabs.boss.ContinueSwitch = tabs.boss:AddSwitch("Continue Farming after Boss Kill", function(state)
	tabs.boss.Data.ContinueTraining = state
	if state and tabs.boss.Data.Phase == "Waiting"
		and (not tabs.boss.Halloween or not tabs.boss.Halloween.Data.Running) then tabs.boss.resumeTraining() end
end)
tabs.boss.ContinueSwitch:Set(true)

runtime:Spawn(function(model, health, maxHealth, hitbox, currentHealth, currentMaxHealth, nextTime)
	while true do
		model, health, maxHealth, hitbox = tabs.boss.findActiveBoss()
		if model then
			currentHealth = tabs.boss.getBossHealth(health)
			currentMaxHealth = tabs.boss.getBossMaxHealth(maxHealth)
			tabs.boss.BossLabel.Text = "Boss: " .. (services.Workspace:GetAttribute("BossDisplayName") or model.Name)
			tabs.boss.HealthLabel.Text = "Health: " .. utils.formatNumber(currentHealth) .. " / " .. utils.formatNumber(currentMaxHealth)
			tabs.boss.NextBossLabel.Text = "Next Boss: Current boss active"
		else
			tabs.boss.BossLabel.Text = "Boss: None"
			tabs.boss.HealthLabel.Text = "Health: 0 / 0"
			nextTime = services.Workspace:GetAttribute("BossSpawnNextTime")
			tabs.boss.NextBossLabel.Text = typeof(nextTime) == "number"
				and "Next Boss: " .. tabs.boss.formatCountdown(nextTime - services.Workspace:GetServerTimeNow())
				or "Next Boss: N/A"
		end
		task.wait(0.25)
	end
end)

tabs.boss:AddHeading("Boss Webhook:")
tabs.boss.Webhook = {Queue = {}, Pending = {}, Failed = {}, ChestKeys = setmetatable({}, {__mode = "k"})}
tabs.boss.Webhook.Input = tabs.boss:AddTextBox("Discord Webhook URL (optional)", function() end, {clear = false})
tabs.boss.Webhook.Status = tabs.boss:AddLabel("Webhook: Disabled")

_G.SilenceBossWebhookHistory = _G.SilenceBossWebhookHistory or {Seen = {}, Order = {}}

tabs.boss.webhookUrl = function()
	local text = tabs.boss.Webhook.Input.Text:match("^%s*(.-)%s*$")
	if text == "" then return nil end
	local host, path = text:match("^https://([^/]+)(/.*)$")
	local allowed = { ["discord.com"] = true, ["discordapp.com"] = true,
		["canary.discord.com"] = true, ["ptb.discord.com"] = true }
	if not allowed[host] or not path:match("^/api/webhooks/%d+/[%w_-]+$") then return nil, "Invalid Discord webhook URL" end
	return text
end

tabs.boss.webhookRequest = function()
	if type(request) == "function" then return request end
	if type(http_request) == "function" then return http_request end
	if type(syn) == "table" and type(syn.request) == "function" then return syn.request end
	if type(http) == "table" and type(http.request) == "function" then return http.request end
end

tabs.boss.webhookNumber = function(value)
	value = tonumber(value) or 0
	for _, unit in ipairs({{1e18, "qi"}, {1e15, "qa"}, {1e12, "t"}, {1e9, "b"}, {1e6, "m"}, {1e3, "k"}}) do
		if value >= unit[1] then return (string.format("%.2f", value / unit[1]):gsub("0+$", ""):gsub("%.$", "")) .. unit[2] end
	end
	return value == math.floor(value) and string.format("%.0f", value) or tostring(value)
end

tabs.boss.queueWebhook = function(kind, sequence, content)
	local state = tabs.boss.Webhook
	local url = tabs.boss.webhookUrl()
	if not url then return end
	if not tabs.boss.webhookRequest() then state.Status.Text = "Webhook: HTTP requests unavailable" return end
	local key = url .. "|" .. game.JobId .. "|" .. kind .. "|" .. tostring(sequence)
	if state.Pending[key] or state.Failed[key] or _G.SilenceBossWebhookHistory.Seen[key] then return end
	if #state.Queue >= 32 then state.Status.Text = "Webhook: Queue full" return end
	state.Pending[key] = true
	table.insert(state.Queue, {Url = url, Key = key, Content = content:sub(1, 2000), Attempts = 0, NextAt = 0})
	state.Status.Text = "Webhook: Queued"
end

tabs.boss.observeWebhookSpawn = function()
	if workspace:GetAttribute("BossActive") ~= true then return end
	local sequence = workspace:GetAttribute("BossSpawnSequence")
	local name = workspace:GetAttribute("BossDisplayName")
	local health = tonumber(workspace:GetAttribute("BossMaxHealth"))
	if sequence == nil or type(name) ~= "string" or not health or health <= 0 then return end
	tabs.boss.queueWebhook("spawn", sequence, name .. " Spawned!\nHealth: " .. tabs.boss.webhookNumber(health))
end

tabs.boss.webhookRewards = function(rewards)
	local lines = {}
	if type(rewards) ~= "table" then return lines end
	for _, reward in ipairs(rewards) do
		if type(reward) == "table" and type(reward.DisplayName) == "string"
			and type(reward.Amount) == "number" and reward.Amount > 0 then
			local quantity = reward.Amount == 1 and reward.Guaranteed ~= true and ""
				or tabs.boss.webhookNumber(reward.Amount) .. " "
			table.insert(lines, "- " .. quantity .. reward.DisplayName)
		end
	end
	return lines
end

tabs.boss.observeWebhookRewards = function(chest, rewards)
	if typeof(chest) ~= "Instance" or not chest:IsA("Model") then return end
	local rarity = chest:GetAttribute("BossRarityIndex")
	if type(rarity) ~= "number" then return end
	local lines = tabs.boss.webhookRewards(rewards)
	if #lines == 0 then return end
	local config = tabs.boss.Data.BossConfig
	local entry = config and config.RARITIES and config.RARITIES[rarity]
	local fallback = ({"Common", "Rare", "Epic", "Legendary", "Mythic", "Rainbow"})[rarity]
	local name = entry and (entry.DisplayName or entry.Name) or (fallback and fallback .. " Boss")
	if not name then return end
	local state = tabs.boss.Webhook
	state.ChestKeys[chest] = state.ChestKeys[chest]
		or tostring(workspace:GetAttribute("BossResultSequence") or workspace:GetAttribute("BossSpawnSequence")) .. ":" .. rarity
	tabs.boss.queueWebhook("defeated", state.ChestKeys[chest], name .. " Defeated!\nRewards:\n" .. table.concat(lines, "\n"))
end

tabs.boss.processWebhook = function()
	local state = tabs.boss.Webhook
	local item = state.Queue[1]
	if not item or os.clock() < item.NextAt then return end
	if item.Url ~= tabs.boss.webhookUrl() then
		state.Pending[item.Key] = nil
		table.remove(state.Queue, 1)
		return
	end
	local send = tabs.boss.webhookRequest()
	if not send then state.Status.Text = "Webhook: HTTP requests unavailable" return end
	item.Attempts = item.Attempts + 1
	local httpService = game:GetService("HttpService")
	local success, response = pcall(function()
		return send({Url = item.Url .. "?wait=true", Method = "POST",
			Headers = {["Content-Type"] = "application/json"},
			Body = httpService:JSONEncode({content = item.Content, allowed_mentions = {parse = {}}})})
	end)
	if not runtime.Alive then return end
	local code = success and type(response) == "table" and tonumber(response.StatusCode or response.Status)
	if code and code >= 200 and code < 300 then
		local history = _G.SilenceBossWebhookHistory
		history.Seen[item.Key] = true
		table.insert(history.Order, item.Key)
		if #history.Order > 200 then history.Seen[table.remove(history.Order, 1)] = nil end
		state.Pending[item.Key] = nil
		table.remove(state.Queue, 1)
		state.Status.Text = "Webhook: Sent"
		return
	end
	local retry = not code or code == 408 or code == 429 or code >= 500
	if retry and item.Attempts < 3 then
		local delay = 5 * item.Attempts
		if code == 429 then
			local decoded, body = pcall(function() return httpService:JSONDecode(response.Body) end)
			if decoded and type(body) == "table" then delay = math.max(delay, tonumber(body.retry_after) or 0) end
		end
		item.NextAt = os.clock() + delay
		state.Status.Text = "Webhook: Retrying"
	else
		state.Pending[item.Key] = nil
		state.Failed[item.Key] = true
		table.remove(state.Queue, 1)
		state.Status.Text = "Webhook: " .. (code and ("HTTP " .. code) or "Request failed")
	end
end

runtime:Connect(tabs.boss.Webhook.Input:GetPropertyChangedSignal("Text"), function()
	local url, message = tabs.boss.webhookUrl()
	tabs.boss.Webhook.Status.Text = url and "Webhook: Ready" or ("Webhook: " .. (message or "Disabled"))
	if url then runtime:Defer(tabs.boss.observeWebhookSpawn) end
end)

tabs.boss.Webhook.ResultSequence = workspace:GetAttribute("BossResultSequence")
tabs.boss.observeWebhookDespawn = function()
	local state = tabs.boss.Webhook
	local sequence = workspace:GetAttribute("BossResultSequence")
	if sequence == nil or sequence == state.ResultSequence then return end
	state.ResultSequence = sequence
	if workspace:GetAttribute("BossResultKind") ~= "Survived" then return end
	local rarity = workspace:GetAttribute("BossResultRarity")
	if type(rarity) ~= "number" then return end
	local config = tabs.boss.Data.BossConfig
	local entry = config and config.RARITIES and config.RARITIES[rarity]
	local fallback = ({"Common", "Rare", "Epic", "Legendary", "Mythic", "Rainbow"})[rarity]
	local name = entry and (entry.DisplayName or entry.Name) or (fallback and fallback .. " Boss")
	if name then tabs.boss.queueWebhook("despawn", sequence, name .. " Despawned!") end
end
runtime:Connect(workspace:GetAttributeChangedSignal("BossResultSequence"), tabs.boss.observeWebhookDespawn)

runtime:Connect(workspace:GetAttributeChangedSignal("BossSpawnSequence"), tabs.boss.observeWebhookSpawn)
runtime:Connect(workspace:GetAttributeChangedSignal("BossActive"), tabs.boss.observeWebhookSpawn)
runtime:Connect(workspace:GetAttributeChangedSignal("BossMaxHealth"), tabs.boss.observeWebhookSpawn)

runtime:Spawn(function()
	local events = game:GetService("ReplicatedStorage"):WaitForChild("rEvents")
	local event = events:WaitForChild("bossChestOpenedEvent", 15)
	if event and event:IsA("RemoteEvent") then runtime:Connect(event.OnClientEvent, tabs.boss.observeWebhookRewards) end
end)

runtime:Spawn(function()
	while runtime.Alive do
		tabs.boss.processWebhook()
		task.wait(0.5)
	end
end)

tabs.boss.AutoFarmSwitch = tabs.boss:AddSwitch("Auto Farm Boss", function(state)
	if state and tabs.boss.Halloween and tabs.boss.Halloween.Data.Running then
		tabs.boss.Halloween.AutoFarmSwitch:Set(false)
	end
	tabs.boss.Data.Running = state
	tabs.boss.Data.Generation += 1
	tabs.boss.runtime.generation = tabs.boss.Data.Generation
	if not state then
		tabs.boss.Data.Preparation = nil
		tabs.boss.Data.Phase = "Waiting"
		tabs.boss.StatusLabel.Text = "Status: Disabled"
		tabs.boss.resumeTraining()
		return
	end

	runtime:Spawn(function(generation, wasFighting, model, health, maxHealth, hitbox, selected)
		while tabs.boss.Data.Running and tabs.boss.Data.Generation == generation do
			pcall(function()
				model, health, maxHealth, hitbox = tabs.boss.findActiveBoss()
				selected = model and tabs.boss.shouldFarmBoss(model)
				if model and not selected then
					if wasFighting or tabs.boss.Data.Preparation then
						tabs.boss.Data.Preparation = nil
						wasFighting = false
						tabs.boss.resumeTraining()
					end
					tabs.boss.Data.Phase = "Waiting"
					tabs.boss.StatusLabel.Text = "Status: Skipping " .. (services.Workspace:GetAttribute("BossDisplayName") or model.Name)
				elseif model then
					if wasFighting and tabs.boss.needsRetraining(tabs.boss) then wasFighting = false end
					if not wasFighting then
						if not tabs.boss.prepareForBoss(tabs.boss) then return end
						wasFighting = true
						tabs.boss.Data.Phase = "Fighting"
						tabs.boss.Data.AttackSequence = nil
						tabs.boss.Data.EvadeUntil = 0
						tabs.boss.Data.DodgeStomps = false
						tabs.boss.pauseTraining()
					end
					if not tabs.boss.Data.Running or tabs.boss.Data.Generation ~= generation then return end
					if tabs.boss.needsRetraining(tabs.boss) then return end
					if utils.playerData.Player.Character
						and utils.playerData.Player.Character:FindFirstChildOfClass("Humanoid")
						and utils.playerData.Player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
						tabs.boss.StatusLabel.Text = "Status: Fighting"
						tabs.boss.attack(tabs.boss, model, health, maxHealth, hitbox)
					else
						tabs.boss.StatusLabel.Text = "Status: Waiting for Respawn"
					end
				elseif wasFighting then
					wasFighting = false
					tabs.boss.Data.Phase = "Collecting"
					pcall(tabs.boss.collectChest, generation)
					if not tabs.boss.Data.Running or tabs.boss.Data.Generation ~= generation then return end
					tabs.boss.BossLabel.Text = "Boss: None"
					tabs.boss.HealthLabel.Text = "Health: 0 / 0"
					if tabs.boss.Data.ContinueTraining then tabs.boss.resumeTraining() end
					tabs.boss.Data.Phase = "Waiting"
					tabs.boss.StatusLabel.Text = "Status: Waiting for Boss"
				else
					if tabs.boss.Data.Preparation then
						tabs.boss.Data.Preparation = nil
						tabs.boss.resumeTraining()
					end
					tabs.boss.StatusLabel.Text = "Status: Waiting for Boss"
				end
			end)
			task.wait(model and selected and 0.03 or 0.25)
		end
	end, tabs.boss.runtime.generation)
end)

tabs.boss:AddLabel("")

tabs.boss:AddHeading("Halloween Boss Farming:")
tabs.boss.Halloween = {
	runtime = {},
	BossLabelPrefix = "Halloween Boss: ",
	StatusLabel = tabs.boss:AddLabel("Status: Waiting for Halloween Boss"),
	BossLabel = tabs.boss:AddLabel("Halloween Boss: None"),
	HealthLabel = tabs.boss:AddLabel("Health: 0 / 0"),
	NextBossLabel = tabs.boss:AddLabel("Next Halloween Boss: Waiting for spawn"),
	Data = {
		Running = false,
		Generation = 0,
		Phase = "Waiting",
		PunchInterval = 0.3,
		LastPunch = 0,
		AttackSequence = nil,
		EvadeUntil = 0,
		EvadeDistance = 230,
		PunchBehindDistance = 45,
		StompHealthThreshold = 0.35,
		DodgeStomps = false,
		Bosses = {
			GrimReaper = "Grim Reaper",
			FrankenBrute = "Frankenbrute",
			PumpkinTitan = "Pumpkin Titan",
			ScarecrowColossus = "Scarecrow Colossus"
		},
		BossOrder = {"GrimReaper", "FrankenBrute", "PumpkinTitan", "ScarecrowColossus"},
		BossByDisplayName = {},
		SelectedBosses = {},
		Target = nil
	}
}

tabs.boss.Halloween.getBossDisplayName = function(model)
	return tabs.boss.Halloween.Data.Bosses[model:GetAttribute("BossId") or model.Name] or model.Name
end

tabs.boss.Halloween.getBossHealth = function(health, model)
	return tonumber(model:GetAttribute("Health")) or 0
end

tabs.boss.Halloween.getBossMaxHealth = function(maxHealth, model)
	return tonumber(model:GetAttribute("MaxHealth")) or 0
end

tabs.boss.Halloween.SelectedBossesLabel = tabs.boss:AddLabel("Targeted Halloween Bosses: All")
tabs.boss.Halloween.updateSelectedBossesLabel = function(selectedNames)
	selectedNames = {}
	for _, bossId in ipairs(tabs.boss.Halloween.Data.BossOrder) do
		if tabs.boss.Halloween.Data.SelectedBosses[bossId] then
			table.insert(selectedNames, tabs.boss.Halloween.Data.Bosses[bossId])
		end
	end
	tabs.boss.Halloween.SelectedBossesLabel.Text = "Targeted Halloween Bosses: "
		.. (#selectedNames > 0 and table.concat(selectedNames, ", ") or "None")
end

tabs.boss.Halloween.BossDropdown = tabs.boss:AddDropdown("Target specific Halloween Bosses", function(displayName, bossId)
	bossId = tabs.boss.Halloween.Data.BossByDisplayName[displayName]
	if not bossId then return end
	tabs.boss.Halloween.Data.SelectedBosses[bossId] = not tabs.boss.Halloween.Data.SelectedBosses[bossId]
	tabs.boss.Halloween.updateSelectedBossesLabel()
end)
for _, bossId in ipairs(tabs.boss.Halloween.Data.BossOrder) do
	tabs.boss.Halloween.Data.BossByDisplayName[tabs.boss.Halloween.Data.Bosses[bossId]] = bossId
	tabs.boss.Halloween.Data.SelectedBosses[bossId] = true
	tabs.boss.Halloween.BossDropdown:Add(tabs.boss.Halloween.Data.Bosses[bossId])
end
tabs.boss.Halloween.updateSelectedBossesLabel()

tabs.boss.Halloween.shouldFarmBoss = function(model)
	return tabs.boss.Halloween.Data.SelectedBosses[model:GetAttribute("BossId") or model.Name] == true
end

tabs.boss.Halloween.findActiveBoss = function(selectedOnly, model, hitbox, candidateHitbox, character, root, distance, closestDistance)
	character = utils.playerData.Player.Character
	root = character and character:FindFirstChild("HumanoidRootPart")
	closestDistance = math.huge
	for _, candidate in ipairs(services.CollectionService:GetTagged("HalloweenBoss")) do
		if candidate:IsA("Model") and candidate:IsDescendantOf(services.Workspace)
			and tabs.boss.Halloween.getBossHealth(nil, candidate) > 0
			and (not selectedOnly or tabs.boss.Halloween.shouldFarmBoss(candidate)) then
			candidateHitbox = candidate:FindFirstChild("BossDamageHitbox", true)
				or candidate.PrimaryPart or candidate:FindFirstChild("HumanoidRootPart")
			if candidateHitbox and candidateHitbox:IsA("BasePart") then
				if selectedOnly and candidate == tabs.boss.Halloween.Data.Target then
					return candidate, nil, nil, candidateHitbox
				end
				distance = root and (root.Position - candidateHitbox.Position).Magnitude or 0
				if not model or distance < closestDistance then
					model, hitbox, closestDistance = candidate, candidateHitbox, distance
				end
			end
		end
	end
	return model, nil, nil, hitbox
end

runtime:Spawn(function(model)
	while true do
		model = tabs.boss.Halloween.Data.Target
		if not model or not model.Parent or tabs.boss.Halloween.getBossHealth(nil, model) <= 0 then
			model = tabs.boss.Halloween.findActiveBoss()
		end
		if model then
			tabs.boss.Halloween.BossLabel.Text = "Halloween Boss: " .. tabs.boss.Halloween.getBossDisplayName(model)
			tabs.boss.Halloween.HealthLabel.Text = "Health: " .. utils.formatNumber(tabs.boss.Halloween.getBossHealth(nil, model))
				.. " / " .. utils.formatNumber(tabs.boss.Halloween.getBossMaxHealth(nil, model))
			tabs.boss.Halloween.NextBossLabel.Text = "Next Halloween Boss: Current boss active"
		else
			tabs.boss.Halloween.BossLabel.Text = "Halloween Boss: None"
			tabs.boss.Halloween.HealthLabel.Text = "Health: 0 / 0"
			tabs.boss.Halloween.NextBossLabel.Text = "Next Halloween Boss: Waiting for spawn"
		end
		task.wait(0.25)
	end
end)

tabs.boss.Halloween.AutoFarmSwitch = tabs.boss:AddSwitch("Auto Farm Halloween Boss", function(state)
	if state and tabs.boss.Data.Running then tabs.boss.AutoFarmSwitch:Set(false) end
	tabs.boss.Halloween.Data.Running = state
	tabs.boss.Halloween.Data.Generation += 1
	if not state then
		tabs.boss.Halloween.Data.Preparation = nil
		tabs.boss.Halloween.Data.Target = nil
		tabs.boss.Halloween.Data.Phase = "Waiting"
		tabs.boss.Halloween.StatusLabel.Text = "Status: Disabled"
		tabs.boss.resumeTraining()
		return
	end

	runtime:Spawn(function(generation, wasFighting, model, health, maxHealth, hitbox)
		while tabs.boss.Halloween.Data.Running and tabs.boss.Halloween.Data.Generation == generation do
			pcall(function()
				model, health, maxHealth, hitbox = tabs.boss.Halloween.findActiveBoss(true)
				if model then
					if wasFighting and tabs.boss.needsRetraining(tabs.boss.Halloween) then wasFighting = false end
					if not wasFighting then
						if not tabs.boss.prepareForBoss(tabs.boss.Halloween) then return end
						wasFighting = true
						tabs.boss.pauseTraining()
					end
					if not tabs.boss.Halloween.Data.Running or tabs.boss.Halloween.Data.Generation ~= generation then return end
					if tabs.boss.needsRetraining(tabs.boss.Halloween) then return end
					if tabs.boss.Halloween.Data.Target ~= model then
						tabs.boss.Halloween.Data.Target = model
						tabs.boss.Halloween.Data.AttackSequence = nil
						tabs.boss.Halloween.Data.EvadeUntil = 0
						tabs.boss.Halloween.Data.DodgeStomps = false
					end
					tabs.boss.Halloween.Data.Phase = "Fighting"
					if utils.playerData.Player.Character
						and utils.playerData.Player.Character:FindFirstChildOfClass("Humanoid")
						and utils.playerData.Player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
						tabs.boss.Halloween.StatusLabel.Text = "Status: Fighting"
						tabs.boss.attack(tabs.boss.Halloween, model, health, maxHealth, hitbox)
					else
						tabs.boss.Halloween.StatusLabel.Text = "Status: Waiting for Respawn"
					end
				else
					tabs.boss.Halloween.Data.Target = nil
					tabs.boss.Halloween.Data.Phase = "Waiting"
					if tabs.boss.Halloween.Data.Preparation then
						tabs.boss.Halloween.Data.Preparation = nil
						tabs.boss.resumeTraining()
					elseif wasFighting then
						tabs.boss.resumeTraining()
					end
					wasFighting = false
					tabs.boss.Halloween.StatusLabel.Text = "Status: Waiting for Halloween Boss"
				end
			end)
			task.wait(model and 0.03 or 0.25)
		end
	end, tabs.boss.Halloween.Data.Generation)
end)

tabs.inventory:AddHeading("Crystals:")

tabs.inventory.Crystals = {
	Catalog = services.ReplicatedStorage.shared.catalogs:WaitForChild("crystalChances"),
	Remote = services.ReplicatedStorage.rEvents:WaitForChild("openCrystalRemote"),
	Settings = {}, Dirty = {}, RetryAt = {}, Selected = nil, Amount = 1, Running = false, Rendering = false,
	Options = {}
}

tabs.inventory.crystalEntries = function(name)
	local entries, rarest = {}, math.huge
	local folder = name and tabs.inventory.Crystals.Catalog:FindFirstChild(name)
	if not folder then return entries end
	for _, item in ipairs(folder:GetChildren()) do
		local object = item:IsA("ObjectValue") and item.Value
		local itemName = item:GetAttribute("ItemName") or (object and object.Name)
		local kind = item:GetAttribute("ItemKind")
		local chance = item:FindFirstChild("chanceValue")
		if type(itemName) == "string" and (kind == "Pet" or kind == "Aura") then
			local entry = {Name = itemName, Kind = kind, Chance = chance and chance.Value or 0,
				Eligible = item:GetAttribute("AutoSellEligible") == true,
				Protected = item:GetAttribute("AutoSellProtected") == true}
			table.insert(entries, entry)
			if kind == "Pet" then rarest = math.min(rarest, entry.Chance) end
		end
	end
	for _, entry in ipairs(entries) do
		if entry.Kind == "Pet" and entry.Chance == rarest then entry.Protected = true end
	end
	table.sort(entries, function(a, b) return a.Name:lower() < b.Name:lower() end)
	return entries
end

tabs.inventory.normalizeCrystalSetting = function(name, value)
	value = type(value) == "table" and value or {}
	local result = {Enabled = value.Enabled == true, Pets = {}, Auras = {}}
	for _, entry in ipairs(tabs.inventory.crystalEntries(name)) do
		local key = entry.Kind == "Pet" and "Pets" or "Auras"
		if entry.Eligible and not entry.Protected and type(value[key]) == "table" and value[key][entry.Name] == true then
			result[key][entry.Name] = true
		end
	end
	return result
end

tabs.inventory.getCrystalSetting = function(name)
	local state = tabs.inventory.Crystals
	if not state.Settings[name] then
		local success, setting = pcall(function()
			return require(services.ReplicatedStorage.packages.ReplicatorClient).get("Data"):TryIndex({"crystalAutoSell", name})
		end)
		state.Settings[name] = tabs.inventory.normalizeCrystalSetting(name, success and setting or nil)
	end
	return state.Settings[name]
end

tabs.inventory.markCrystalSetting = function(name)
	local state = tabs.inventory.Crystals
	state.Dirty[name] = (state.Dirty[name] or 0) + 1
	state.RetryAt[name] = 0
	state.SellStatus.Text = "Auto Sell: Saving"
end

tabs.inventory.renderCrystalSetting = function()
	local state = tabs.inventory.Crystals
	state.Rendering = true
	state.SellDropdown:Clear()
	state.Options = {}
	local selected = {}
	local setting = state.Selected and tabs.inventory.getCrystalSetting(state.Selected)
	if setting then
		for _, entry in ipairs(tabs.inventory.crystalEntries(state.Selected)) do
			local key = entry.Kind == "Pet" and "Pets" or "Auras"
			local enabled = setting[key][entry.Name] == true
			local locked = entry.Protected or not entry.Eligible
			local label = (enabled and "[x] " or "[ ] ") .. entry.Name
				.. (entry.Kind == "Aura" and " (Aura)" or "") .. (locked and " (protected)" or "")
			state.Options[label] = entry
			state.SellDropdown:Add(label)
			if enabled then table.insert(selected, entry.Name) end
		end
	end
	state.SellSelection.Text = "Auto Sell Items: " .. (#selected > 0 and table.concat(selected, ", ") or "None")
	state.SellSwitch:Set(setting ~= nil and setting.Enabled)
	state.SellStatus.Text = not setting and "Auto Sell: Select a crystal"
		or (state.Dirty[state.Selected] and "Auto Sell: Saving" or (setting.Enabled and "Auto Sell: Enabled" or "Auto Sell: Disabled"))
	state.Rendering = false
end

tabs.inventory.Crystals.Status = tabs.inventory:AddLabel("Hatch: Inactive")
tabs.inventory.Crystals.Dropdown = tabs.inventory:AddDropdown("Select Crystal", function(name)
	local state = tabs.inventory.Crystals
	if not state.Catalog:FindFirstChild(name) then return end
	state.Selected = name
	tabs.inventory.renderCrystalSetting()
end)
tabs.inventory.Crystals.Dropdown:SetConfigKey("Pets.Crystal")

tabs.inventory.Crystals.AmountDropdown = tabs.inventory:AddDropdown("Hatch Amount", function(value)
	local amount = tonumber(value:match("^(%d+)x$"))
	if amount == 1 or amount == 3 or amount == 10 then tabs.inventory.Crystals.Amount = amount end
end)
for _, amount in ipairs({"1x", "3x", "10x"}) do tabs.inventory.Crystals.AmountDropdown:Add(amount) end
tabs.inventory.Crystals.AmountDropdown:SetConfigKey("Pets.CrystalAmount"):SetValue("1x")

tabs.inventory.Crystals.HatchSwitch = tabs.inventory:AddSwitch("Auto Hatch Crystal", function(enabled)
	tabs.inventory.Crystals.Running = enabled
	tabs.inventory.Crystals.Status.Text = enabled and "Hatch: Preparing" or "Hatch: Inactive"
end)
tabs.inventory.Crystals.HatchSwitch:SetConfigKey("Pets.AutoHatchCrystal")
tabs.inventory.Crystals.SellStatus = tabs.inventory:AddLabel("Auto Sell: Select a crystal")
tabs.inventory.Crystals.SellSelection = tabs.inventory:AddLabel("Auto Sell Items: None")
tabs.inventory.Crystals.SellDropdown = tabs.inventory:AddDropdown("Select Auto Sell Items", function(label)
	local state = tabs.inventory.Crystals
	local entry = state.Options[label]
	if not state.Selected or not entry then return end
	if entry.Protected or not entry.Eligible then
		state.SellStatus.Text = "Auto Sell: This item is protected by the game"
		return
	end
	local key = entry.Kind == "Pet" and "Pets" or "Auras"
	local setting = tabs.inventory.getCrystalSetting(state.Selected)
	setting[key][entry.Name] = setting[key][entry.Name] ~= true or nil
	tabs.inventory.markCrystalSetting(state.Selected)
	tabs.inventory.renderCrystalSetting()
end)
tabs.inventory.Crystals.SellDropdown:SetConfigKey("Pets.CrystalAutoSellLastItem")

tabs.inventory.Crystals.SellSwitch = tabs.inventory:AddSwitch("Auto Sell", function(enabled)
	local state = tabs.inventory.Crystals
	if state.Rendering then return end
	if not state.Selected then
		state.Rendering = true
		state.SellSwitch:Set(false)
		state.Rendering = false
		state.SellStatus.Text = "Auto Sell: Select a crystal first"
		return
	end
	tabs.inventory.getCrystalSetting(state.Selected).Enabled = enabled
	tabs.inventory.markCrystalSetting(state.Selected)
end)
tabs.inventory.Crystals.SellSwitch:SetConfigKey("Pets.CrystalAutoSellEnabled")

tabs.inventory.refreshCrystals = function()
	local state, names = tabs.inventory.Crystals, {}
	for _, folder in ipairs(state.Catalog:GetChildren()) do table.insert(names, folder.Name) end
	table.sort(names, function(a, b) return a:lower() < b:lower() end)
	state.Dropdown:Refresh(names)
	if state.Selected and state.Catalog:FindFirstChild(state.Selected) then
		state.Dropdown:SetValue(state.Selected)
	else
		state.Selected = nil
		tabs.inventory.renderCrystalSetting()
	end
end
runtime:Connect(tabs.inventory.Crystals.Catalog.ChildAdded, tabs.inventory.refreshCrystals)
runtime:Connect(tabs.inventory.Crystals.Catalog.ChildRemoved, tabs.inventory.refreshCrystals)
tabs.inventory.refreshCrystals()

utils.silence:RegisterConfig("Pets.CrystalAutoSellSettings", function()
	local settings = {}
	for name, value in pairs(tabs.inventory.Crystals.Settings) do
		settings[name] = tabs.inventory.normalizeCrystalSetting(name, value)
	end
	return settings
end, function(values)
	if type(values) ~= "table" then return end
	for name, value in pairs(values) do
		if tabs.inventory.Crystals.Catalog:FindFirstChild(name) and type(value) == "table" then
			tabs.inventory.Crystals.Settings[name] = tabs.inventory.normalizeCrystalSetting(name, value)
			tabs.inventory.markCrystalSetting(name)
		end
	end
	tabs.inventory.renderCrystalSetting()
end)

utils.runtime.crystalConfigGetter = utils.silence.GetConfigValues
utils.runtime.crystalConfigSetter = utils.silence.ApplyConfigValues
function utils.silence:GetConfigValues()
	local values = utils.runtime.crystalConfigGetter(self)
	values["Pets.CrystalAutoSellLastItem"] = nil
	return values
end
function utils.silence:ApplyConfigValues(values)
	local restored = {}
	for key, value in pairs(values) do
		if key ~= "Pets.CrystalAutoSellLastItem" then restored[key] = value end
	end
	return utils.runtime.crystalConfigSetter(self, restored)
end

tabs.inventory.saveCrystalSetting = function(name)
	local state = tabs.inventory.Crystals
	local revision = state.Dirty[name]
	local setting = tabs.inventory.normalizeCrystalSetting(name, tabs.inventory.getCrystalSetting(name))
	local success, result = pcall(function() return state.Remote:InvokeServer("saveAutoSell", name, setting) end)
	if not runtime.Alive then return end
	if success and type(result) == "table" and result.Ok == true and type(result.Setting) == "table" then
		if state.Dirty[name] == revision then
			state.Settings[name] = tabs.inventory.normalizeCrystalSetting(name, result.Setting)
			state.Dirty[name] = nil
			if state.Selected == name then tabs.inventory.renderCrystalSetting() end
		end
	else
		state.RetryAt[name] = os.clock() + 5
		if state.Selected == name then state.SellStatus.Text = "Auto Sell: Save failed, retrying" end
	end
end

tabs.inventory.hatchCrystal = function(name, amount)
	local state = tabs.inventory.Crystals
	if amount > 1 then
		local available, enabled = pcall(function()
			return require(services.ReplicatedStorage.shared.modules.GlobalFunctions).isBulkCrystalOpenEnabled()
		end)
		if not available or not enabled then return false, "Bulk hatch is unavailable" end
		local result = state.Remote:InvokeServer("openCrystalBulk", name, amount)
		if type(result) ~= "table" then return false, "No hatch result" end
		return type(result.Results) == "table" and #result.Results > 0, result.StopReason
	end
	local item, rarity, image, color, sold, value, reason = state.Remote:InvokeServer("openCrystal", name)
	return item ~= nil and rarity ~= nil and image ~= nil, reason
end

runtime:Spawn(function()
	while runtime.Alive do
		local state = tabs.inventory.Crystals
		for name in pairs(state.Dirty) do
			if os.clock() >= (state.RetryAt[name] or 0) then tabs.inventory.saveCrystalSetting(name) end
		end
		if state.Running then
			local name, amount = state.Selected, state.Amount
			if not name then
				state.Status.Text = "Hatch: Select a crystal"
			elseif state.Dirty[name] then
				state.Status.Text = "Hatch: Waiting for auto-sell settings"
			else
				local success, opened, reason = pcall(tabs.inventory.hatchCrystal, name, amount)
				if state.Running and state.Selected == name then
					state.Status.Text = success and opened and ("Hatch: " .. name .. " | " .. amount .. "x")
						or ("Hatch: Waiting | " .. tostring(success and (reason or "Check currency, capacity and crystal access") or opened))
				end
			end
		end
		task.wait(1)
	end
end)

tabs.inventory:AddHeading("Pet Shop:")

tabs.inventory.PetShopRuntime = services.ReplicatedStorage:WaitForChild("shared"):WaitForChild("runtime")
tabs.inventory.PetShopFolder = tabs.inventory.PetShopRuntime:WaitForChild("cPetShopFolder")
tabs.inventory.PetShopRemote = services.ReplicatedStorage.rEvents:WaitForChild("cPetShopRemote")

tabs.inventory.PetShopData = {
	PetList = {},
	Selected = {},
	SelectedList = {},
	BuyAmount = 1
}

tabs.inventory.AuraData = {
	AuraList = {},
	Selected = {},
	SelectedList = {},
	BuyAmount = 1
}

tabs.inventory.EvolveData = {Selected = {}, SelectedList = {}, Amount = 1}

for _, item in ipairs(tabs.inventory.PetShopFolder:GetChildren()) do
	if item:GetAttribute("IsPowerUp") == true then
		table.insert(tabs.inventory.AuraData.AuraList, item.Name)
	else
		table.insert(tabs.inventory.PetShopData.PetList, item.Name)
	end
end
table.sort(tabs.inventory.PetShopData.PetList)
table.sort(tabs.inventory.AuraData.AuraList)

tabs.inventory.BuyPetLabel = tabs.inventory:AddLabel("Selected Pets: None")
tabs.inventory.BuyPetDropdown = tabs.inventory:AddDropdown("Choose Pets", function(text)
	utils.toggleSelection(tabs.inventory.PetShopData.Selected, tabs.inventory.PetShopData.SelectedList, text, tabs.inventory.BuyPetLabel, "Selected Pets: ")
end)
for _, petName in ipairs(tabs.inventory.PetShopData.PetList) do tabs.inventory.BuyPetDropdown:Add(petName) end

tabs.inventory:AddTextBox("Buy Amount:", function(text)
	tabs.inventory.PetShopData.BuyAmount = math.max(1, math.floor(tonumber(text) or 1))
end, {clear = false})

tabs.inventory:AddSwitch("Buy Pet", function(bool)
	_G.AutoHatchPet = bool
	if bool then
		runtime:Spawn(function()
			while _G.AutoHatchPet do
				for _, petName in ipairs(tabs.inventory.PetShopData.SelectedList) do
					tabs.inventory.runtime.selectedPet = tabs.inventory.PetShopFolder:FindFirstChild(petName)
					if tabs.inventory.runtime.selectedPet then
						for _ = 1, tabs.inventory.PetShopData.BuyAmount do
							runtime:Spawn(function(selectedPet)
								pcall(function() tabs.inventory.PetShopRemote:InvokeServer(selectedPet) end)
							end, tabs.inventory.runtime.selectedPet)
						end
					end
				end
				task.wait(0.1)
			end
		end)
	end
end)

tabs.inventory:AddHeading("Auras:")

tabs.inventory.AuraLabel = tabs.inventory:AddLabel("Selected Auras: None")
tabs.inventory.AuraDropdown = tabs.inventory:AddDropdown("Select Auras", function(text)
	utils.toggleSelection(tabs.inventory.AuraData.Selected, tabs.inventory.AuraData.SelectedList, text, tabs.inventory.AuraLabel, "Selected Auras: ")
end)
for _, auraName in ipairs(tabs.inventory.AuraData.AuraList) do tabs.inventory.AuraDropdown:Add(auraName) end

tabs.inventory:AddTextBox("Buy Amount:", function(text)
	tabs.inventory.AuraData.BuyAmount = math.max(1, math.floor(tonumber(text) or 1))
end, {clear = false})

tabs.inventory:AddSwitch("Buy Aura", function(bool)
	_G.AutoHatchAura = bool
	if bool then
		runtime:Spawn(function()
			while _G.AutoHatchAura do
				for _, auraName in ipairs(tabs.inventory.AuraData.SelectedList) do
					tabs.inventory.runtime.selectedAura = tabs.inventory.PetShopFolder:FindFirstChild(auraName)
					if tabs.inventory.runtime.selectedAura then
						for _ = 1, tabs.inventory.AuraData.BuyAmount do
							runtime:Spawn(function(selectedAura)
								pcall(function() tabs.inventory.PetShopRemote:InvokeServer(selectedAura) end)
							end, tabs.inventory.runtime.selectedAura)
						end
					end
				end
				task.wait(0.1)
			end
		end)
	end
end)

tabs.inventory:AddLabel("You need Gems and Inventory Space!")

tabs.inventory:AddHeading("Auto Evolving:")

tabs.inventory.EvolveLabel = tabs.inventory:AddLabel("Selected Pets: None")
tabs.inventory.EvolvePetDropdown = tabs.inventory:AddDropdown("Choose Pets", function(text)
	utils.toggleSelection(tabs.inventory.EvolveData.Selected, tabs.inventory.EvolveData.SelectedList, text, tabs.inventory.EvolveLabel, "Selected Pets: ")
end)
for _, petName in ipairs(tabs.inventory.PetShopData.PetList) do tabs.inventory.EvolvePetDropdown:Add(petName) end

tabs.inventory:AddTextBox("Evolve Amount:", function(text)
	tabs.inventory.EvolveData.Amount = math.max(1, math.floor(tonumber(text) or 1))
end, {clear = false})

tabs.inventory.AutoEvolveRunning = false

tabs.inventory:AddSwitch("Auto Evolve", function(state)
    tabs.inventory.AutoEvolveRunning = state
    if not state then return end

    runtime:Spawn(function()
        while tabs.inventory.AutoEvolveRunning do
			for _, petName in ipairs(tabs.inventory.EvolveData.SelectedList) do
				for _ = 1, tabs.inventory.EvolveData.Amount do
					services.ReplicatedStorage.rEvents.petEvolveEvent:FireServer("evolvePet", petName)
				end
			end
            task.wait(0.5)
        end
    end)
end)

tabs.inventory:AddHeading("Auto Trading:")

tabs.inventory.TradeData = {SelectedPlayers = {}, SelectedPlayerList = {}, SelectedPets = {}, SelectedPetList = {}, Generation = 0}

tabs.inventory.TradePlayerLabel = tabs.inventory:AddLabel("Selected Players: None")
tabs.inventory.TradePlayerDropdown = tabs.inventory:AddDropdown("Choose Player", function(name)
    tabs.inventory.runtime.username_2258 = name:match(" | (.+)") or name
    utils.toggleSelection(tabs.inventory.TradeData.SelectedPlayers, tabs.inventory.TradeData.SelectedPlayerList, tabs.inventory.runtime.username_2258, tabs.inventory.TradePlayerLabel, "Selected Players: ")
end)

tabs.inventory:AddButton("Add All Players", function()
	for _, player in ipairs(services.Players:GetPlayers()) do
		if player ~= services.Players.LocalPlayer and not tabs.inventory.TradeData.SelectedPlayers[player.Name] then
			tabs.inventory.TradeData.SelectedPlayers[player.Name] = true
			table.insert(tabs.inventory.TradeData.SelectedPlayerList, player.Name)
		end
	end
	tabs.inventory.TradePlayerLabel.Text = "Selected Players: " .. (#tabs.inventory.TradeData.SelectedPlayerList > 0 and table.concat(tabs.inventory.TradeData.SelectedPlayerList, ", ") or "None")
end)

for _, player in ipairs(services.Players:GetPlayers()) do
    if player ~= services.Players.LocalPlayer then
        tabs.inventory.TradePlayerDropdown:Add(player.DisplayName .. " | " .. player.Name)
    end
end

runtime:Connect(services.Players.PlayerAdded, function(player)
    if player ~= services.Players.LocalPlayer then
        tabs.inventory.TradePlayerDropdown:Add(player.DisplayName .. " | " .. player.Name)
    end
end)

runtime:Connect(services.Players.PlayerRemoving, function(player)
    tabs.inventory.TradePlayerDropdown:Remove(player.DisplayName .. " | " .. player.Name)
    if tabs.inventory.TradeData.SelectedPlayers[player.Name] then
		utils.toggleSelection(tabs.inventory.TradeData.SelectedPlayers, tabs.inventory.TradeData.SelectedPlayerList, player.Name, tabs.inventory.TradePlayerLabel, "Selected Players: ")
	end
end)

tabs.inventory.TradePetLabel = tabs.inventory:AddLabel("Selected Pets: None")
tabs.inventory.TradePetDropdown = tabs.inventory:AddDropdown("Choose Pets", function(text)
	utils.toggleSelection(tabs.inventory.TradeData.SelectedPets, tabs.inventory.TradeData.SelectedPetList, text, tabs.inventory.TradePetLabel, "Selected Pets: ")
end)
for _, petName in ipairs(tabs.inventory.PetShopData.PetList) do tabs.inventory.TradePetDropdown:Add(petName) end

tabs.inventory.AutoTradeRunning = false

tabs.inventory:AddSwitch("Auto Trade", function(state)
    tabs.inventory.AutoTradeRunning = state
	tabs.inventory.TradeData.Generation += 1
    if not state then return end

    runtime:Spawn(function(generation)
        while tabs.inventory.AutoTradeRunning and tabs.inventory.TradeData.Generation == generation do
            if #tabs.inventory.TradeData.SelectedPlayerList > 0 and #tabs.inventory.TradeData.SelectedPetList > 0 then
				for _, username in ipairs(tabs.inventory.TradeData.SelectedPlayerList) do
					tabs.inventory.runtime.tradePlayer = services.Players:FindFirstChild(username)
					if not tabs.inventory.AutoTradeRunning or tabs.inventory.TradeData.Generation ~= generation then break end
					if tabs.inventory.runtime.tradePlayer then
						tabs.inventory.runtime.tradingEvent = services.ReplicatedStorage.rEvents.tradingEvent
						tabs.inventory.runtime.unique = game.Players.LocalPlayer.petsFolder.Unique

						tabs.inventory.runtime.tradingEvent:FireServer(
							"sendTradeRequest",
							tabs.inventory.runtime.tradePlayer
						)

						task.wait(0.5)

						tabs.inventory.runtime.offered = 0
						tabs.inventory.runtime.offeredPets = {}
						repeat
							tabs.inventory.runtime.addedPet = false
							for _, selectedName in ipairs(tabs.inventory.TradeData.SelectedPetList) do
								for _, pet in ipairs(tabs.inventory.runtime.unique:GetChildren()) do
									if pet.Name == selectedName and not tabs.inventory.runtime.offeredPets[pet] then
										tabs.inventory.runtime.tradingEvent:FireServer("offerItem", pet)
										tabs.inventory.runtime.offeredPets[pet] = true
										tabs.inventory.runtime.offered += 1
										tabs.inventory.runtime.addedPet = true
										task.wait(0.01)
										break
									end
								end
								if not tabs.inventory.AutoTradeRunning or tabs.inventory.TradeData.Generation ~= generation or tabs.inventory.runtime.offered >= 6 then break end
							end
						until not tabs.inventory.AutoTradeRunning or tabs.inventory.TradeData.Generation ~= generation or tabs.inventory.runtime.offered >= 6 or not tabs.inventory.runtime.addedPet

						task.wait(0.05)

						if tabs.inventory.AutoTradeRunning and tabs.inventory.TradeData.Generation == generation then
							tabs.inventory.runtime.tradingEvent:FireServer("acceptTrade")
							task.wait(2)
						end
					end
				end
            end

            task.wait(2)
        end
    end, tabs.inventory.TradeData.Generation)
end)

tabs.boosts:AddHeading("Boost Eater:")

tabs.boosts.EggEaterData = {Running = false}

runtime:Spawn(function()
	while true do
		if tabs.boosts.EggEaterData.Running then
			tabs.boosts.runtime.tool_2122 = (utils.playerData.Player.Character and utils.playerData.Player.Character:FindFirstChild("Protein Egg")) or utils.playerData.Player.Backpack:FindFirstChild("Protein Egg")
			if tabs.boosts.runtime.tool_2122 then utils.playerData.Player.muscleEvent:FireServer("proteinEgg", tabs.boosts.runtime.tool_2122) end
			task.wait(0.25)
		else
			task.wait(1)
		end
	end
end)

tabs.boosts:AddSwitch("Eat All Eggs", function(state) tabs.boosts.EggEaterData.Running = state end):Set(false)

tabs.boosts.BoostData = {
	ItemList = {"Tropical Shake", "ULTRA Shake", "Energy Shake", "Protein Bar", "TOUGH Bar", "Protein Shake", "Energy Bar"},
	Running = false
}

runtime:Spawn(function()
	while true do
		if tabs.boosts.BoostData.Running then
			for _, itemName in ipairs(tabs.boosts.BoostData.ItemList) do
				tabs.boosts.runtime.tool_2142 = (utils.playerData.Player.Character and utils.playerData.Player.Character:FindFirstChild(itemName)) or utils.playerData.Player.Backpack:FindFirstChild(itemName)
				if tabs.boosts.runtime.tool_2142 then
					tabs.boosts.runtime.parts = {}
					for word in itemName:gmatch("%S+") do table.insert(tabs.boosts.runtime.parts, word:lower()) end
					for i = 2, #tabs.boosts.runtime.parts do tabs.boosts.runtime.parts[i] = tabs.boosts.runtime.parts[i]:sub(1, 1):upper() .. tabs.boosts.runtime.parts[i]:sub(2) end
					for i = 1, 10 do utils.playerData.Player.muscleEvent:FireServer(table.concat(tabs.boosts.runtime.parts), tabs.boosts.runtime.tool_2142) end
				end
			end
		end
		task.wait(0.1)
	end
end)

tabs.boosts:AddSwitch("Eat all Boosts (expect lag)", function(state) tabs.boosts.BoostData.Running = state end)

tabs.boosts:AddHeading("Egg Gifter:")

tabs.boosts.EggGifterData = {ProteinEggLabel = tabs.boosts:AddLabel("Protein Eggs: 0"), SelectedPlayer = nil, EggCount = 0}

tabs.boosts.EggPlayerDropdown = tabs.boosts:AddDropdown("Choose Player", function(name)
    tabs.boosts.runtime.username_2340 = name:match(" | (.+)") or name
    tabs.boosts.EggGifterData.SelectedPlayer = services.Players:FindFirstChild(tabs.boosts.runtime.username_2340)
end)

for _, player in ipairs(services.Players:GetPlayers()) do
    if player ~= services.Players.LocalPlayer then
        tabs.boosts.EggPlayerDropdown:Add(player.DisplayName .. " | " .. player.Name)
    end
end

runtime:Connect(services.Players.PlayerAdded, function(player)
    if player ~= services.Players.LocalPlayer then
        tabs.boosts.EggPlayerDropdown:Add(player.DisplayName .. " | " .. player.Name)
    end
end)

runtime:Connect(services.Players.PlayerRemoving, function(player)
    tabs.boosts.EggPlayerDropdown:Remove(player.DisplayName .. " | " .. player.Name)
    if tabs.boosts.EggGifterData.SelectedPlayer == player then tabs.boosts.EggGifterData.SelectedPlayer = nil end
end)

tabs.boosts.EggAmountTextBox = tabs.boosts:AddTextBox("Amount:", function(text)
	tabs.boosts.runtime.amount_2362 = tonumber(text)
	if tabs.boosts.runtime.amount_2362 then
		tabs.boosts.EggGifterData.EggCount = math.max(0, math.floor(tabs.boosts.runtime.amount_2362))
	end
end, {clear = false})

tabs.boosts:AddButton("Start Gifting", function()
	tabs.boosts.runtime.amount_2369 = tonumber(tabs.boosts.EggAmountTextBox.Text) or tabs.boosts.EggGifterData.EggCount
	tabs.boosts.runtime.amount_2369 = tabs.boosts.runtime.amount_2369 and math.max(0, math.floor(tabs.boosts.runtime.amount_2369)) or 0
	tabs.boosts.EggGifterData.EggCount = tabs.boosts.runtime.amount_2369

	if not tabs.boosts.EggGifterData.SelectedPlayer or tabs.boosts.runtime.amount_2369 == 0 then return end

	runtime:Spawn(function()
		for _ = 1, tabs.boosts.runtime.amount_2369 do
			tabs.boosts.runtime.egg = services.Players.LocalPlayer.consumablesFolder:FindFirstChild("Protein Egg")
			if not tabs.boosts.runtime.egg then break end

			pcall(function()
				services.ReplicatedStorage.rEvents.giftRemote:InvokeServer("giftRequest", tabs.boosts.EggGifterData.SelectedPlayer, tabs.boosts.runtime.egg)
			end)
			task.wait(0.1)
		end
	end)
end)

tabs.boosts:AddHeading("Shake Gifter:")

tabs.boosts.ShakeGifterData = {TropicalShakeLabel = tabs.boosts:AddLabel("Tropical Shakes: 0"), SelectedPlayer = nil, ShakeCount = 0}

tabs.boosts.ShakePlayerDropdown = tabs.boosts:AddDropdown("Choose Player", function(name)
	tabs.boosts.runtime.usernameone = name:match(" | (.+)") or name
	tabs.boosts.ShakeGifterData.SelectedPlayer = services.Players:FindFirstChild(tabs.boosts.runtime.usernameone)
end)

for _, player in ipairs(services.Players:GetPlayers()) do
	if player ~= services.Players.LocalPlayer then
		tabs.boosts.ShakePlayerDropdown:Add(player.DisplayName .. " | " .. player.Name)
	end
end

runtime:Connect(services.Players.PlayerAdded, function(player)
	if player ~= services.Players.LocalPlayer then
		tabs.boosts.ShakePlayerDropdown:Add(player.DisplayName .. " | " .. player.Name)
	end
end)

runtime:Connect(services.Players.PlayerRemoving, function(player)
	tabs.boosts.ShakePlayerDropdown:Remove(player.DisplayName .. " | " .. player.Name)
	if tabs.boosts.ShakeGifterData.SelectedPlayer == player then tabs.boosts.ShakeGifterData.SelectedPlayer = nil end
end)

tabs.boosts.ShakeAmountTextBox = tabs.boosts:AddTextBox("Amount:", function(text)
	tabs.boosts.runtime.amount_2415 = tonumber(text)
	if tabs.boosts.runtime.amount_2415 then
		tabs.boosts.ShakeGifterData.ShakeCount = math.max(0, math.floor(tabs.boosts.runtime.amount_2415))
	end
end, {clear = false})

tabs.boosts:AddButton("Start Gifting", function()
	tabs.boosts.runtime.amount_2422 = tonumber(tabs.boosts.ShakeAmountTextBox.Text) or tabs.boosts.ShakeGifterData.ShakeCount
	tabs.boosts.runtime.amount_2422 = tabs.boosts.runtime.amount_2422 and math.max(0, math.floor(tabs.boosts.runtime.amount_2422)) or 0
	tabs.boosts.ShakeGifterData.ShakeCount = tabs.boosts.runtime.amount_2422

	if not tabs.boosts.ShakeGifterData.SelectedPlayer or tabs.boosts.runtime.amount_2422 == 0 then return end

	runtime:Spawn(function()
		for _ = 1, tabs.boosts.runtime.amount_2422 do
			tabs.boosts.runtime.shake = services.Players.LocalPlayer.consumablesFolder:FindFirstChild("Tropical Shake")
			if not tabs.boosts.runtime.shake then break end

			pcall(function()
				services.ReplicatedStorage.rEvents.giftRemote:InvokeServer("giftRequest", tabs.boosts.ShakeGifterData.SelectedPlayer, tabs.boosts.runtime.shake)
			end)
			task.wait(0.1)
		end
	end)
end)

runtime:Spawn(function()
	while true do
		tabs.boosts.runtime.proteinEggCount = 0
		tabs.boosts.runtime.tropicalShakeCount = 0
		if utils.playerData.Backpack then
			for _, item in ipairs(utils.playerData.Backpack:GetChildren()) do
				if item.Name == "Protein Egg" then tabs.boosts.runtime.proteinEggCount = tabs.boosts.runtime.proteinEggCount + 1
				elseif item.Name == "Tropical Shake" then tabs.boosts.runtime.tropicalShakeCount = tabs.boosts.runtime.tropicalShakeCount + 1 end
			end
		end
		tabs.boosts.EggGifterData.ProteinEggLabel.Text = "Protein Eggs: " .. tabs.boosts.runtime.proteinEggCount
		tabs.boosts.ShakeGifterData.TropicalShakeLabel.Text = "Tropical Shakes: " .. tabs.boosts.runtime.tropicalShakeCount
		task.wait(7.5)
	end
end)

tabs.boosts:AddLabel("Interferes with Boosts you got gifted. Get on a machine for less Lag!")

tabs.teleport:AddHeading("Main:")

tabs.teleport.Locations = {
	{name = "Tiny Island", pos = CFrame.new(-37.1, 9.2, 1919)},
	{name = "Main Island", pos = CFrame.new(16.07, 9.08, 133.8)},
	{name = "Beach", pos = CFrame.new(-8, 9, -169.2)}
}

for _, loc in ipairs(tabs.teleport.Locations) do
	tabs.teleport:AddButton(loc.name, function()
		if utils.playerData.Player.Character and utils.playerData.Player.Character:FindFirstChild("HumanoidRootPart") then
			utils.playerData.Player.Character.HumanoidRootPart.CFrame = loc.pos
		end
	end)
end

tabs.teleport:AddHeading("Gyms:")

tabs.teleport.GymLocations = {
	{name = "Halloween", pos = CFrame.new(5437.915039, 83.205795, 5875.647949)},
	{name = "Overcharged Gym", pos = CFrame.new(-2941.766, 151.797, 4994.552)},
	{name = "Industrial gym", pos = CFrame.new(-5254.681641, 58.342850, 4931.850586)},
	{name = "Jungle Gym", pos = CFrame.new(-8543, 6.8, 2400)},
	{name = "Muscle King Gym", pos = CFrame.new(-8665.4, 17.21, -5792.9)},
	{name = "Legends Gym", pos = CFrame.new(4516, 991.5, -3856)},
	{name = "Infernal Gym", pos = CFrame.new(-6759, 7.36, -1284)},
	{name = "Mythical Gym", pos = CFrame.new(2250, 7.37, 1073.2)},
	{name = "Frost Gym", pos = CFrame.new(-2623, 7.36, -409)}
}

for _, gym in ipairs(tabs.teleport.GymLocations) do
	tabs.teleport:AddButton(gym.name, function()
		if utils.playerData.Player.Character and utils.playerData.Player.Character:FindFirstChild("HumanoidRootPart") then
			utils.playerData.Player.Character.HumanoidRootPart.CFrame = gym.pos
		end
	end)
end

tabs.stats:AddHeading("Elapsed Time:")

tabs.stats.Data = {
	StopwatchLabel = tabs.stats:AddLabel("0d 0h 0m 0s"),
	StartTime = tick(),
	Leaderstats = utils.playerData.Player:WaitForChild("leaderstats"),
	Stats = {},
	InitialValues = {},
	StatLabels = {}
}

tabs.stats:AddHeading("Stats:")

runtime:Spawn(function()
	while true do
		tabs.stats.runtime.elapsedTime = tick() - tabs.stats.Data.StartTime
		tabs.stats.runtime.days = math.floor(tabs.stats.runtime.elapsedTime / (24 * 3600))
		tabs.stats.runtime.hours = math.floor((tabs.stats.runtime.elapsedTime % (24 * 3600)) / 3600)
		tabs.stats.runtime.minutes = math.floor((tabs.stats.runtime.elapsedTime % 3600) / 60)
		tabs.stats.runtime.seconds = math.floor(tabs.stats.runtime.elapsedTime % 60)
		tabs.stats.Data.StopwatchLabel.Text = string.format("%dd %dh %dm %ds", tabs.stats.runtime.days, tabs.stats.runtime.hours, tabs.stats.runtime.minutes, tabs.stats.runtime.seconds)
		task.wait(0.1)
	end
end)

tabs.stats.Data.Stats = {
	{name = tabs.specs.Data.EmojiMap["Strength"] .. " Strength", stat = tabs.stats.Data.Leaderstats:WaitForChild("Strength")},
	{name = tabs.specs.Data.EmojiMap["Rebirths"] .. " Rebirths", stat = tabs.stats.Data.Leaderstats:WaitForChild("Rebirths")},
	{name = tabs.specs.Data.EmojiMap["Durability"] .. " Durability", stat = utils.playerData.Player:WaitForChild("Durability")},
	{name = tabs.specs.Data.EmojiMap["Kills"] .. " Kills", stat = tabs.stats.Data.Leaderstats:WaitForChild("Kills")},
	{name = tabs.specs.Data.EmojiMap["Agility"] .. " Agility", stat = utils.playerData.Player:WaitForChild("Agility")},
	{name = tabs.specs.Data.EmojiMap["Evil Karma"] .. " Evil Karma", stat = utils.playerData.Player:WaitForChild("evilKarma")},
	{name = tabs.specs.Data.EmojiMap["Good Karma"] .. " Good Karma", stat = utils.playerData.Player:WaitForChild("goodKarma")},
	{name = tabs.specs.Data.EmojiMap["Brawls"] .. " Brawls", stat = tabs.stats.Data.Leaderstats:WaitForChild("Brawls")}
}

for _, info in ipairs(tabs.stats.Data.Stats) do
	tabs.stats.Data.InitialValues[info.name] = info.stat.Value
	tabs.stats.Data.StatLabels[info.name] = tabs.stats:AddLabel("")
end

runtime:Spawn(function()
	while true do
		for _, info in ipairs(tabs.stats.Data.Stats) do
			tabs.stats.runtime.currentValue = info.stat.Value
			tabs.stats.runtime.gained = tabs.stats.runtime.currentValue - tabs.stats.Data.InitialValues[info.name]
			tabs.stats.Data.StatLabels[info.name].Text = string.format("%s: %s (%s) | Gained: %s (%s)", info.name,
				utils.formatNumber(tabs.stats.runtime.currentValue), utils.formatWithCommas(tabs.stats.runtime.currentValue),
				utils.formatNumber(tabs.stats.runtime.gained), utils.formatWithCommas(tabs.stats.runtime.gained))
		end
		task.wait(0.1)
	end
end)
tabs.info:AddLabel("Made by xyzhenrik")
tabs.info:AddLabel("Any issues? Create a Ticket on Discord")
tabs.info:AddLabel("Official Discord: discord.gg/9eFf93Kg8D")
tabs.info:AddButton("Copy Invite", function()
	if type(setclipboard) == "function" and pcall(setclipboard, "https://discord.gg/9eFf93Kg8D") then
		pcall(function() game.StarterGui:SetCore("SendNotification", {Title = "Link Copied!", Text = "You can continue to Discord now.", Duration = 3}) end)
	else
		pcall(function() game.StarterGui:SetCore("SendNotification", {Title = "Error!", Text = "Clipboard not Supported.", Duration = 3}) end)
	end
end)
tabs.info:AddLabel("")
tabs.info:AddHeading("Contributors:")
tabs.info:AddLabel("- Henrik @xyzhenrik")
tabs.info:AddLabel("- Muki @mukimagdich")
tabs.info:AddLabel("- HalisAnteo @xyzhalis")
tabs.info:AddLabel("")
tabs.info:AddLabel("Silence is Open-Source!")
tabs.info:AddLabel("")
tabs.info.VersionLabel = tabs.info:AddLabel("Muscle Legends [V4.3.0]")
tabs.info.VersionLabel.TextSize = 20
tabs.info.VersionLabel.Font = Enum.Font.Arcade


runtime:Defer(function()
    utils.configManager:LoadStartup()
    if utils.silence.FitToScreen then utils.silence:FitToScreen() end
end)

do
local services = {
    players = game:GetService("Players"),
    replicatedstorage = game:GetService("ReplicatedStorage"),
    runservice = game:GetService("RunService"),
    tws = game:GetService("TweenService"),
    userinputservice = game:GetService("UserInputService"),
    httpservice = game:GetService("HttpService"),
    virtualinputmanager = game:GetService("VirtualInputManager"),
    lighting = game:GetService("Lighting"),
    startergui = game:GetService("StarterGui"),
    collectionservice = game:GetService("CollectionService")
}


do
	local success, executorName = pcall(function()
		local identify = identifyexecutor
		if type(identify) ~= "function" then identify = getexecutorname end
		if type(identify) == "function" then return identify() end
	end)
	services.isSolara = success and type(executorName) == "string" and string.lower(executorName) == "solara"
end

local lp = {
    player = services.players.LocalPlayer,
    userid = services.players.LocalPlayer.UserId,
    username = services.players.LocalPlayer.Name,
    displayname = services.players.LocalPlayer.DisplayName
}

function deleteAds()
	for _, portal in pairs(game:GetDescendants()) do
		if portal.Name == "RobloxForwardPortals" then
			portal:Destroy()
		end
	end
	if _G.ads then
		_G.ads:Disconnect()
	end

	_G.ads = runtime:Connect(game.DescendantAdded, function(descendant)
		if descendant.Name == "RobloxForwardPortals" then
			descendant:Destroy()
		end
	end)
end
deleteAds()

function deleteBodyMovementScript()
    if lp.player.Character and lp.player.Character:FindFirstChild("bodyMovementScript") then
        lp.player.Character.bodyMovementScript:Destroy()
    end
end
deleteBodyMovementScript()

services.muscleEvent = lp.player:WaitForChild("muscleEvent")
services.touchParts = function(part, hand, state)
    if type(firetouchinterest) ~= "function" or not part or not hand then return false end
    return pcall(firetouchinterest, part, hand, state)
end

local function greeting(hour)
    hour = hour or os.date("*t").hour
    if hour >= 6 and hour < 12 then return "Good Morning!"
    elseif hour >= 12 and hour < 13 then return "Good Noon!"
    elseif hour >= 13 and hour < 19 then return "Good Afternoon!"
    elseif hour >= 19 and hour < 22 then return "Good Evening!"
    else return "Good Night!" end
end

local farmingSection = silence:Section({
    Title = "Fast Farming",
    Icon = "lucide:tractor",
    Opened = true
})

local sharedTabs = tabs

local tabs = {
    rebirths = wrapTab(farmingSection:Tab({Title = "Rebirths", Icon = "lucide:rotate-ccw", Border = true})),
    strength = wrapTab(farmingSection:Tab({Title = "Strength", Icon = "lucide:dumbbell", Border = true})),
    strength2 = wrapTab(farmingSection:Tab({Title = "Strength (Auto)", Icon = "lucide:repeat", Border = true})),
    boss = wrapTab(farmingSection:Tab({Title = "Boss", Icon = "lucide:skull", Border = true})),
    other = wrapTab(farmingSection:Tab({Title = "Other", Icon = "lucide:layers", Border = true}))
}

tabs.customize = sharedTabs.customize
tabs.configs = sharedTabs.configs
tabs.info = sharedTabs.info

services.configManager = configManager

tabs.other.RedactConfigPath = "Silence/MuscleLegendsFarmingConfig.json"
tabs.other.RedactConfig = {
    RedactName = true,
    RedactStats = true,
}

tabs.other.loadRedactConfig = function()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return end
    pcall(function()
        if not isfile(tabs.other.RedactConfigPath) then return end
        local savedConfig = services.httpservice:JSONDecode(readfile(tabs.other.RedactConfigPath))
        if typeof(savedConfig) == "table" then
            tabs.other.RedactConfig.RedactName = savedConfig.RedactName == true
            tabs.other.RedactConfig.RedactStats = savedConfig.RedactStats == true
        end
    end)
end

tabs.other.saveRedactConfig = function()
    if type(writefile) ~= "function" then return end
    pcall(function()
        if type(makefolder) == "function"
            and (type(isfolder) ~= "function" or not isfolder("Silence")) then
            pcall(makefolder, "Silence")
        end
        writefile(tabs.other.RedactConfigPath, services.httpservice:JSONEncode(tabs.other.RedactConfig))
    end)
end

tabs.other.NameVisibility = {Character = nil, Connections = {}, Guis = {}, Watches = {}}

tabs.other.clearNameVisibility = function()
    local state = tabs.other.NameVisibility
    for _, connection in ipairs(state.Connections) do
        connection:Disconnect()
        runtime.Connections[connection] = nil
    end
    table.clear(state.Connections)
    for gui, connection in pairs(state.Watches) do
        connection:Disconnect()
        runtime.Connections[connection] = nil
        state.Watches[gui] = nil
    end
    for gui, wasEnabled in pairs(state.Guis) do
        if gui.Parent then gui.Enabled = wasEnabled end
    end
    table.clear(state.Guis)
    state.Character = nil
end
runtime:AddCleanup(tabs.other.clearNameVisibility)

tabs.other.applyNameVisibility = function()
    local state = tabs.other.NameVisibility
    local character = lp.player.Character
    if state.Character ~= character then
        tabs.other.clearNameVisibility()
        state.Character = character
        if character then
            local function watchNameGui(gui)
                if not gui:IsA("BillboardGui") or gui.Name ~= "nameGui" or state.Guis[gui] ~= nil then return end
                state.Guis[gui] = gui.Enabled
                state.Watches[gui] = runtime:Connect(gui:GetPropertyChangedSignal("Enabled"), function()
                    if tabs.other.RedactConfig.RedactName and gui.Enabled then gui.Enabled = false end
                end)
                if tabs.other.RedactConfig.RedactName then gui.Enabled = false end
            end
            table.insert(state.Connections, runtime:Connect(character.DescendantAdded, watchNameGui))
            table.insert(state.Connections, runtime:Connect(character.DescendantRemoving, function(gui)
                if state.Guis[gui] ~= nil then
                    local connection = state.Watches[gui]
                    if connection then connection:Disconnect(); runtime.Connections[connection] = nil end
                    state.Watches[gui] = nil
                    gui.Enabled = state.Guis[gui]
                    state.Guis[gui] = nil
                end
            end))
            for _, gui in ipairs(character:GetDescendants()) do watchNameGui(gui) end
        end
    end
    for gui, wasEnabled in pairs(state.Guis) do
        if gui.Parent then gui.Enabled = not tabs.other.RedactConfig.RedactName and wasEnabled end
    end
end

tabs.other.applyStatsVisibility = function()
    pcall(function()
        lp.player.PlayerGui.gameGui.hudNewMenu.Top.InfoSlots.Visible = not tabs.other.RedactConfig.RedactStats
    end)
    pcall(function() services.startergui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, not tabs.other.RedactConfig.RedactStats) end)
end

tabs.other.loadRedactConfig()

function formatNumber(num)
    if num >= 1e18 then return string.format("%.2fQi", num/1e18) end
    if num >= 1e15 then return string.format("%.2fQa", num/1e15) end
    if num >= 1e12 then return string.format("%.2fT", num/1e12) end
    if num >= 1e9 then return string.format("%.2fB", num/1e9) end
    if num >= 1e6 then return string.format("%.2fM", num/1e6) end
    if num >= 1e3 then return string.format("%.2fK", num/1e3) end
    return string.format("%.0f", num)
end

tabs.other.redactStats = tabs.other.RedactConfig.RedactStats

local function formatCurrentStat(value)
    return tabs.other.redactStats and "####" or formatNumber(value)
end

function formatRate(ratePerSecond)
    return formatNumber(ratePerSecond) .. "/s | "
        .. formatNumber(ratePerSecond * 60) .. "/min | "
        .. formatNumber(ratePerSecond * 3600) .. "/h | "
        .. formatNumber(ratePerSecond * 86400) .. "/d"
end

local PETS = {
    ["Omega Overlord"] = {
        repSpeed = 20,
        strength = 0,
        durability = 0,
        rebirth = 0,
    },

    ["Swift Samurai"] = {
        repSpeed = 15,
        strength = 0,
        durability = 0,
        rebirth = 0,
    },

    ["Powercore Hound"] = {
        repSpeed = 0,
        strength = 25,
        durability = 15,
        rebirth = 0,
    },

    ["Titanium Hydra"] = {
        repSpeed = 0,
        strength = 0,
        durability = 0,
        rebirth = 2,
    },

    ["Tribal Overlord"] = {
        repSpeed = 0,
        strength = 0,
        durability = 0,
        rebirth = 2,
    },
	["Inferno Unicorn"] = {
		repSpeed = 0,
		strength = 25,
		durability = 25,
		rebirth = 0,
	},
	["Common Boss Pet"] = {
		repSpeed = 5,
		strength = 0,
		durability = 0,
		rebirth = 0,
	},
	["Rare Boss Pet"] = {
		repSpeed = 7,
		strength = 0,
		durability = 0,
		rebirth = 0,
	},
	["Epic Boss Pet"] = {
		repSpeed = 10,
		strength = 0,
		durability = 0,
		rebirth = 0,
	},
	["Rainbow Boss Pet"] = {
		repSpeed = 10,
		strength = 7,
		durability = 0,
		rebirth = 0,
	},
	["Legendary Boss Pet"] = {
		repSpeed = 10,
		strength = 10,
		durability = 0,
		rebirth = 0,
	},
	["Mythic Boss Pet"] = {
		repSpeed = 10,
		strength = 20,
		durability = 0,
		rebirth = 0,
	},
    ["Inferno Drake"] = {
        repSpeed = 40,
        strength = 0,
        durability = 0,
        rebirth = 0,
    },
}

local MAX_PET_SLOTS = 12
local TARGET_REP_SPEED = 100

local function applyPetLoadout(selected, isCurrent)
    local remote = services.replicatedstorage.rEvents.equipPetEvent
    for _, folder in ipairs(lp.player.petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in ipairs(folder:GetChildren()) do
                if isCurrent and not isCurrent() then return false end
                remote:FireServer("unequipPet", pet)
            end
        end
    end
    task.wait(0.1)
    for _, pet in ipairs(selected) do
        if isCurrent and not isCurrent() then return false end
        remote:FireServer("equipPet", pet)
    end
    task.wait(0.1)
    return not isCurrent or isCurrent()
end

local function sendTrainingReps(state, rate, maxBurst, canSend)
    local now = os.clock()
    local elapsed = math.clamp(now - (state.LastAt or now), 0, 0.1)
    state.LastAt = now
    state.Tokens = math.min(maxBurst, (state.Tokens or 0) + rate * elapsed)
    local sent = 0
    while state.Tokens >= 1 and canSend() do
        services.muscleEvent:FireServer("rep")
        state.Tokens = state.Tokens - 1
        sent = sent + 1
    end
    return sent
end

local function getElapsed(tab)
    return tab.totalElapsed + (tab.timerStarted and os.clock() - tab.startedAt or 0)
end

local function setTimerRunning(tab, enabled)
    tab.totalElapsed = getElapsed(tab)
    tab.startedAt = os.clock()
    tab.timerStarted = enabled
end

local function recordStatGain(tab, key, value)
    local previous = tab.statSamples[key]
    tab.statSamples[key] = value
    if tab.running and tab.timerStarted and previous then
        tab.statGains[key] = tab.statGains[key] + math.max(0, value - previous)
    end
end

local function updateRuntimeLabel(tab)
    local elapsed = getElapsed(tab)
    tab.Runtime.Text = string.format("Runtime: %dd %dh %dm %ds",
        math.floor(elapsed / 86400), math.floor(elapsed % 86400 / 3600),
        math.floor(elapsed % 3600 / 60), math.floor(elapsed % 60))
end

local function resetCalculations(tab)
    tab.totalElapsed = 0
    tab.startedAt = os.clock()
    tab.timerStarted = tab.running and tab.timerStarted
    tab.nextAverageElapsed = 10
    for key in pairs(tab.statGains) do
        tab.statGains[key] = 0
    end
    for key, stat in pairs({Rebirths = tab.rebirths, Strength = tab.strength, Durability = tab.durability}) do
        if tab.statSamples[key] ~= nil then tab.statSamples[key] = stat.Value end
    end
    if tab.AverageRate then
        tab.baselineReady = false
        tab.timerStarted = false
        tab.measuredCycles = 0
        tab.AverageRate.Text = "Average: -- / Hour | -- / Day | -- / Week"
    else
        tab.StrengthAverage.Text = "Str Ø: --/s | --/min | --/h | --/d"
        tab.DurabilityAverage.Text = "Dura Ø: --/s | --/min | --/h | --/d"
    end
    tab.updateStats()
    tab.updateRuntime()
end

local function getOwnedConfiguredPets()
    local ownedPets = {}

    for _, folder in ipairs(lp.player.petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in ipairs(folder:GetChildren()) do
                local config = PETS[pet.Name]
                if config then
                    table.insert(ownedPets, {
                        instance = pet,
                        name = pet.Name,
                        repSpeed = config.repSpeed or 0,
                        strength = config.strength or 0,
                        durability = config.durability or 0,
                        rebirth = config.rebirth or 0,
                    })
                end
            end
        end
    end

    return ownedPets
end

local function equipBestFarmingPets(isCurrent)
    if isCurrent and not isCurrent() then return end

    local pets = getOwnedConfiguredPets()
    local selected = {}
    local equipped = {}
    local equippedCount = 0
    local currentRepSpeed = 0

    table.sort(pets, function(a, b)
        return a.repSpeed > b.repSpeed
    end)

    for _, pet in ipairs(pets) do
        if equippedCount >= MAX_PET_SLOTS or currentRepSpeed >= TARGET_REP_SPEED then
            break
        end

        if pet.repSpeed > 0 then
            table.insert(selected, pet.instance)
            equipped[pet.instance] = true
            equippedCount = equippedCount + 1
            currentRepSpeed = currentRepSpeed + pet.repSpeed
        end
    end

    local remainingPets = {}

    for _, pet in ipairs(pets) do
        if not equipped[pet.instance] then
            table.insert(remainingPets, pet)
        end
    end

    table.sort(remainingPets, function(a, b)
        local scoreA = a.strength + a.durability
        local scoreB = b.strength + b.durability
        return scoreA > scoreB
    end)

    for _, pet in ipairs(remainingPets) do
        if equippedCount >= MAX_PET_SLOTS then
            break
        end

        if pet.strength > 0 or pet.durability > 0 then
            table.insert(selected, pet.instance)
            equipped[pet.instance] = true
            equippedCount = equippedCount + 1
        end
    end

    applyPetLoadout(selected, isCurrent)
    return currentRepSpeed, equippedCount
end

local function equipBestRebirthPets(isCurrent)
    if isCurrent and not isCurrent() then return end

    local pets = getOwnedConfiguredPets()
    local selected = {}

    table.sort(pets, function(a, b)
        return a.rebirth > b.rebirth
    end)

    local equippedCount = 0
    local totalRebirthMultiplier = 0

    for _, pet in ipairs(pets) do
        if equippedCount >= MAX_PET_SLOTS then
            break
        end

        if pet.rebirth > 0 then
            table.insert(selected, pet.instance)
            equippedCount = equippedCount + 1
            totalRebirthMultiplier = totalRebirthMultiplier + pet.rebirth
        end
    end

    applyPetLoadout(selected, isCurrent)
    return totalRebirthMultiplier, equippedCount
end

tabs.rebirths.leaderstats = lp.player:WaitForChild("leaderstats")
tabs.rebirths.rebirths = tabs.rebirths.leaderstats:WaitForChild("Rebirths")
tabs.rebirths.strength = tabs.rebirths.leaderstats:WaitForChild("Strength")
tabs.rebirths.running = false
tabs.rebirths.workerActive = false
tabs.rebirths.startedAt = 0
tabs.rebirths.timerStarted = false
tabs.rebirths.hasStarted = false
tabs.rebirths.baselineReady = false
tabs.rebirths.measuredCycles = 0
tabs.rebirths.lastConfirmedAt = nil
tabs.rebirths.nextRequestAt = 0
tabs.rebirths.cooldown = 6
tabs.rebirths.totalElapsed = 0
tabs.rebirths.statSamples = {Rebirths = tabs.rebirths.rebirths.Value}
tabs.rebirths.statGains = {Rebirths = 0}
tabs.rebirths.generation = 0
tabs.rebirths.adaptive = {
    TargetSeconds = 3,
    MinRate = 3,
    MaxRate = 50,
    SendRate = 10,
    ProbeRate = 10,
    ProbeReps = 10,
    FeedbackTimeout = 1,
    StrengthPerRep = nil,
    LastTrainingSeconds = nil
}
tabs.rebirths.Status = tabs.rebirths:AddLabel("Status: Inactive")
tabs.rebirths.Runtime = tabs.rebirths:AddLabel("Runtime: 0d 0h 0m 0s")
tabs.rebirths.RebirthStats = tabs.rebirths:AddLabel("Rebirths: " .. formatCurrentStat(tabs.rebirths.rebirths.Value) .. " | Gained: 0")
tabs.rebirths.RebirthStats:SetAttribute("EleriumUpdateInterval", 0.05)
tabs.rebirths.AverageRate = tabs.rebirths:AddLabel("Average: -- / Hour | -- / Day | -- / Week")
tabs.rebirths.Status.TextColor3 = Color3.fromRGB(255, 80, 80)

tabs.rebirths.updateStats = function()
    tabs.rebirths.RebirthStats.Text = "Rebirths: " .. formatCurrentStat(tabs.rebirths.rebirths.Value)
        .. " | Gained: " .. formatNumber(tabs.rebirths.statGains.Rebirths)
end

tabs.rebirths.updateRuntime = function()
    updateRuntimeLabel(tabs.rebirths)
end

tabs.rebirths.updateAverage = function()
    local elapsed = getElapsed(tabs.rebirths)
    if elapsed <= 0 then return end
    local hourly = tabs.rebirths.statGains.Rebirths / elapsed * 3600
    tabs.rebirths.AverageRate.Text = string.format("Average: %s / Hour | %s / Day | %s / Week",
        formatNumber(hourly), formatNumber(hourly * 24), formatNumber(hourly * 168))
end

tabs.rebirths:AddButton("Reset Calcs", function()
    resetCalculations(tabs.rebirths)
end)

tabs.rebirths.isCurrent = function(generation)
    return tabs.rebirths.running and tabs.rebirths.generation == generation
end

tabs.rebirths.equipFarmingPets = function(generation)
    equipBestFarmingPets(function() return tabs.rebirths.isCurrent(generation) end)
end

tabs.rebirths.equipRebirthPets = function(generation)
    equipBestRebirthPets(function() return tabs.rebirths.isCurrent(generation) end)
end

tabs.rebirths.updateAdaptiveSpeed = function(cycle, finalSample)
    local adaptive = tabs.rebirths.adaptive
    local now = os.clock()
    if not finalSample and now - cycle.SampleAt < 0.25 then return end
    local strength = tabs.rebirths.strength.Value
    local gain = strength - cycle.StartStrength
    if gain > 0 and cycle.Sent > 0 and (finalSample or strength > cycle.SampleStrength) then
        adaptive.StrengthPerRep = gain / cycle.Sent
        cycle.SampleStrength = strength
    end
    if adaptive.StrengthPerRep and adaptive.StrengthPerRep > 0 then
        local reps = math.max(1, math.ceil(math.max(0, cycle.Target - cycle.StartStrength) / adaptive.StrengthPerRep))
        adaptive.SendRate = math.clamp(reps / adaptive.TargetSeconds, adaptive.MinRate, adaptive.MaxRate)
    else
        adaptive.SendRate = adaptive.ProbeRate
    end
    cycle.SampleAt = now
end

tabs.rebirths.performRebirth = function(generation)
    local adaptive = tabs.rebirths.adaptive
    local cycle = {
        Target = 5000 + tabs.rebirths.rebirths.Value * 2550,
        Rebirths = tabs.rebirths.rebirths.Value,
        SampleAt = os.clock(),
        StartStrength = tabs.rebirths.strength.Value,
        SampleStrength = tabs.rebirths.strength.Value,
        LastSentAt = os.clock(),
        Sent = 0,
        Tokens = 0,
        LastAt = os.clock(),
        StatusAt = -math.huge,
        TrainingSeconds = 0
    }
    adaptive.SendRate = adaptive.StrengthPerRep and math.clamp(
        math.max(0, cycle.Target - cycle.StartStrength) / adaptive.StrengthPerRep / adaptive.TargetSeconds,
        adaptive.MinRate, adaptive.MaxRate) or adaptive.ProbeRate
    cycle.RepBudget = adaptive.StrengthPerRep and math.max(adaptive.ProbeReps, math.ceil(
        math.max(0, cycle.Target - cycle.StartStrength) / adaptive.StrengthPerRep)) or adaptive.ProbeReps
    local lastTrainingAt = os.clock()
    local function needsTraining()
        return tabs.rebirths.isCurrent(generation)
            and tabs.rebirths.rebirths.Value == cycle.Rebirths
            and tabs.rebirths.strength.Value < cycle.Target
    end
    while needsTraining() do
        local now = os.clock()
        local character = lp.player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            cycle.TrainingSeconds = cycle.TrainingSeconds + math.max(0, now - lastTrainingAt)
            tabs.rebirths.updateAdaptiveSpeed(cycle)
            if cycle.Sent >= cycle.RepBudget then
                cycle.Tokens = 0
                cycle.LastAt = now
                if now - cycle.LastSentAt >= adaptive.FeedbackTimeout then
                    local missing = math.max(0, cycle.Target - tabs.rebirths.strength.Value)
                    local extra = adaptive.StrengthPerRep and math.ceil(missing / adaptive.StrengthPerRep) or adaptive.ProbeReps
                    cycle.RepBudget = cycle.Sent + math.clamp(extra, math.ceil(adaptive.ProbeReps / 2), adaptive.ProbeReps)
                end
            else
                local budget = cycle.RepBudget - cycle.Sent
                local sent = sendTrainingReps(cycle, adaptive.SendRate, 5, function()
                    if budget <= 0 or not needsTraining() then return false end
                    budget = budget - 1
                    return true
                end)
                cycle.Sent = cycle.Sent + sent
                if sent > 0 then cycle.LastSentAt = now end
            end
            if now - cycle.StatusAt >= 0.25 then
                tabs.rebirths.Status.Text = (cycle.Sent >= cycle.RepBudget and "Status: Waiting for Strength Update | " or "Status: Strength Training | ")
                    .. string.format("%.1fs", cycle.TrainingSeconds) .. " | " .. formatNumber(adaptive.SendRate) .. " reps/s"
                cycle.StatusAt = now
            end
        else
            cycle.Tokens = 0
            cycle.LastAt = now
            tabs.rebirths.Status.Text = "Status: Waiting for Respawn"
        end
        lastTrainingAt = now
        services.runservice.Heartbeat:Wait()
    end
    if not tabs.rebirths.isCurrent(generation) or tabs.rebirths.rebirths.Value ~= cycle.Rebirths then return end
    tabs.rebirths.updateAdaptiveSpeed(cycle, true)
    adaptive.LastTrainingSeconds = cycle.TrainingSeconds
    tabs.rebirths.Status.Text = "Status: Switching to Rebirth Pets"
    tabs.rebirths.equipRebirthPets(generation)
    task.wait(0.25)
    while tabs.rebirths.isCurrent(generation) and tabs.rebirths.rebirths.Value == cycle.Rebirths do
        local remaining = tabs.rebirths.nextRequestAt - os.clock()
        if remaining > 0 then
            tabs.rebirths.Status.Text = "Status: Rebirth Cooldown | " .. string.format("%.1fs", remaining)
            task.wait(math.min(remaining, 0.1))
        else
            tabs.rebirths.nextRequestAt = os.clock() + tabs.rebirths.cooldown
            services.replicatedstorage.rEvents.rebirthRemote:InvokeServer("rebirthRequest")
            tabs.rebirths.recordRebirth()
        end
    end
end

tabs.rebirths.startWorker = function()
    if tabs.rebirths.workerActive then return end
    tabs.rebirths.workerActive = true
    runtime:Spawn(function(generation, success)
        success = pcall(function()
            while tabs.rebirths.isCurrent(generation) do
                tabs.rebirths.equipFarmingPets(generation)
                if not tabs.rebirths.isCurrent(generation) then break end
                tabs.rebirths.performRebirth(generation)
                task.wait()
            end
        end)
        tabs.rebirths.workerActive = false
        if not success then task.wait(0.5) end
        if tabs.rebirths.running then tabs.rebirths.startWorker() end
    end, tabs.rebirths.generation)
end

tabs.rebirths.recordRebirth = function()
    local current = tabs.rebirths.rebirths.Value
    local previous = tabs.rebirths.statSamples.Rebirths
    if current > previous then
        tabs.rebirths.lastConfirmedAt = os.clock()
        tabs.rebirths.nextRequestAt = tabs.rebirths.lastConfirmedAt + tabs.rebirths.cooldown
        if tabs.rebirths.running then
            if not tabs.rebirths.baselineReady then
                tabs.rebirths.baselineReady = true
                tabs.rebirths.statSamples.Rebirths = current
                setTimerRunning(tabs.rebirths, true)
            else
                recordStatGain(tabs.rebirths, "Rebirths", current)
                tabs.rebirths.measuredCycles = tabs.rebirths.measuredCycles + 1
                if tabs.rebirths.measuredCycles >= 2 then tabs.rebirths.updateAverage() end
            end
        end
    end
    tabs.rebirths.statSamples.Rebirths = current
    tabs.rebirths.updateStats()
end

runtime:Connect(tabs.rebirths.rebirths:GetPropertyChangedSignal("Value"), tabs.rebirths.recordRebirth)

tabs.rebirths.Switch = tabs.rebirths:AddSwitch("Pack Rebirth (Yes, Robux Packs)", function(state)
    tabs.rebirths.recordRebirth()
    setTimerRunning(tabs.rebirths, state and tabs.rebirths.baselineReady)
    tabs.rebirths.statSamples.Rebirths = tabs.rebirths.rebirths.Value
    tabs.rebirths.generation = tabs.rebirths.generation + 1
    tabs.rebirths.running = state
    if state then
        if tabs.strength.running then tabs.strength.FastRepToggle:Set(false) end
        if tabs.strength2.running then tabs.strength2.FastRepToggle:Set(false) end
        tabs.rebirths.hasStarted = true
        tabs.rebirths.Status.Text = "Status: Rebirthing"
        tabs.rebirths.Status.TextColor3 = Color3.fromRGB(80, 255, 120)
        tabs.rebirths.updateStats()
        tabs.rebirths.startWorker()
    else
        tabs.rebirths.Status.Text = tabs.rebirths.hasStarted and "Status: Paused" or "Status: Inactive"
        tabs.rebirths.Status.TextColor3 = tabs.rebirths.hasStarted and Color3.fromRGB(255, 180, 70) or Color3.fromRGB(255, 80, 80)
    end
    tabs.rebirths.updateRuntime()
end)
tabs.rebirths.Switch:Set(false)

local function readDataPing()
    local success, ping = pcall(function()
        return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if success and type(ping) == "number" and ping == ping and ping >= 0 and ping < math.huge then
        return ping
    end
end

tabs.strength.leaderstats = lp.player:WaitForChild("leaderstats")
tabs.strength.strength = tabs.strength.leaderstats:WaitForChild("Strength")
tabs.strength.durability = lp.player:WaitForChild("Durability")
tabs.strength.running = false
tabs.strength.workerActive = false
tabs.strength.startedAt = 0
tabs.strength.totalElapsed = 0
tabs.strength.timerStarted = false
tabs.strength.gainedBaselineSet = false
tabs.strength.statSamples = {Strength = tabs.strength.strength.Value, Durability = tabs.strength.durability.Value}
tabs.strength.statGains = {Strength = 0, Durability = 0}
tabs.strength.initialSendRate = 200
tabs.strength.maxSendRate = 462
tabs.strength.sendRate = math.min(tabs.strength.initialSendRate, tabs.strength.maxSendRate)
tabs.strength.maxBurst = 24
tabs.strength.Tokens = 0
tabs.strength.controlInterval = 0.5
tabs.strength.lastControlAt = tick()
tabs.strength.lastControlStrength = tabs.strength.strength.Value
tabs.strength.lastControlDurability = tabs.strength.durability.Value
tabs.strength.stalledIntervals = 0
tabs.strength.LastAt = os.clock()
tabs.strength.Status = tabs.strength:AddLabel("Status: Inactive")
tabs.strength.Runtime = tabs.strength:AddLabel("Runtime: 0d 0h 0m 0s")
tabs.strength.StrengthStats = tabs.strength:AddLabel("Strength: " .. formatCurrentStat(tabs.strength.strength.Value) .. " | Gained: 0")
tabs.strength.StrengthStats:SetAttribute("EleriumUpdateInterval", 0.02)
tabs.strength.DurabilityStats = tabs.strength:AddLabel("Durability: " .. formatCurrentStat(tabs.strength.durability.Value) .. " | Gained: 0")
tabs.strength.DurabilityStats:SetAttribute("EleriumUpdateInterval", 0.02)
tabs.strength.StrengthAverage = tabs.strength:AddLabel("Str Ø: --/s | --/min | --/h | --/d")
tabs.strength.DurabilityAverage = tabs.strength:AddLabel("Dura Ø: --/s | --/min | --/h | --/d")
tabs.strength.Status.TextColor3 = Color3.fromRGB(255, 80, 80)

tabs.strength.updateRuntime = function()
    updateRuntimeLabel(tabs.strength)
end

tabs.strength.updateStats = function()
    tabs.strength.StrengthStats.Text = "Strength: " .. formatCurrentStat(tabs.strength.strength.Value)
        .. " | Gained: " .. (tabs.strength.running and not tabs.strength.timerStarted
            and "Preparing" or formatNumber(tabs.strength.statGains.Strength))
    tabs.strength.DurabilityStats.Text = "Durability: " .. formatCurrentStat(tabs.strength.durability.Value)
        .. " | Gained: " .. (tabs.strength.running and not tabs.strength.timerStarted
            and "Preparing" or formatNumber(tabs.strength.statGains.Durability))
end

tabs.strength.updateAverage = function()
    local elapsed = getElapsed(tabs.strength)
    if elapsed <= 0 then return end
    tabs.strength.StrengthAverage.Text = "Str Ø: " .. formatRate(tabs.strength.statGains.Strength / elapsed)
    tabs.strength.DurabilityAverage.Text = "Dura Ø: " .. formatRate(tabs.strength.statGains.Durability / elapsed)
end

tabs.strength:AddButton("Reset Calcs", function()
    resetCalculations(tabs.strength)
end)

tabs.strength.startMeasurement = function()
    if not tabs.strength.running or tabs.strength.timerStarted
        or tabs.strength.sendRate < tabs.strength.maxSendRate then return end
    tabs.strength.statSamples.Strength = tabs.strength.strength.Value
    tabs.strength.statSamples.Durability = tabs.strength.durability.Value
    setTimerRunning(tabs.strength, true)
    tabs.strength.nextAverageElapsed = getElapsed(tabs.strength) + 10
    tabs.strength.updateStats()
end

tabs.strength.updateAdaptiveRate = function()
    tabs.strength.controlNow = tick()
    tabs.strength.controlElapsed = tabs.strength.controlNow - tabs.strength.lastControlAt
    if tabs.strength.controlElapsed < tabs.strength.controlInterval then
        return
    end

    tabs.strength.serverProgress = tabs.strength.strength.Value > tabs.strength.lastControlStrength
        or tabs.strength.durability.Value > tabs.strength.lastControlDurability

    if tabs.strength.serverProgress then
        tabs.strength.stalledIntervals = 0
        tabs.strength.sendRate = math.min(tabs.strength.maxSendRate, tabs.strength.sendRate * 1.12)
        tabs.strength.Status.Text = (tabs.strength.sendRate >= tabs.strength.maxSendRate
            and "Status: Farming | " or "Status: Preparing | ") .. formatNumber(tabs.strength.sendRate) .. " reps/s"
        tabs.strength.Status.TextColor3 = Color3.fromRGB(80, 255, 120)
    else
        tabs.strength.stalledIntervals = tabs.strength.stalledIntervals + 1
    end

    if tabs.strength.stalledIntervals >= 2 then
        tabs.strength.sendRate = math.max(math.min(tabs.strength.initialSendRate, tabs.strength.maxSendRate), tabs.strength.sendRate * 0.65)
        tabs.strength.Tokens = 0
        tabs.strength.Status.Text = "Status: Slowing for server | "
            .. formatNumber(tabs.strength.sendRate) .. " reps/s"
        tabs.strength.Status.TextColor3 = Color3.fromRGB(255, 180, 70)
    end

    tabs.strength.lastControlAt = tabs.strength.controlNow
    tabs.strength.lastControlStrength = tabs.strength.strength.Value
    tabs.strength.lastControlDurability = tabs.strength.durability.Value
end

tabs.strength.workerLoop = function()
    tabs.strength.LastAt = os.clock()
    local function isRunning()
        return tabs.strength.running
    end
    while tabs.strength.running do
        tabs.strength.updateAdaptiveRate()
        tabs.strength.startMeasurement()
        sendTrainingReps(tabs.strength, tabs.strength.sendRate, tabs.strength.maxBurst, isRunning)

        services.runservice.Heartbeat:Wait()
    end

    tabs.strength.workerActive = false
    if tabs.strength.running then
        tabs.strength.startWorker()
    end
end

tabs.strength.startWorker = function()
    if tabs.strength.workerActive then
        return
    end

    tabs.strength.workerActive = true
    runtime:Spawn(tabs.strength.workerLoop)
end

runtime:Connect(tabs.strength.strength:GetPropertyChangedSignal("Value"), function()
    recordStatGain(tabs.strength, "Strength", tabs.strength.strength.Value)
    tabs.strength.updateStats()
end)

runtime:Connect(tabs.strength.durability:GetPropertyChangedSignal("Value"), function()
    recordStatGain(tabs.strength, "Durability", tabs.strength.durability.Value)
    tabs.strength.updateStats()
end)

tabs.strength:AddTextBox("Max reps/s: " .. tabs.strength.maxSendRate, function(inputText, value)
    value = tonumber(inputText)
    if not value or value ~= value or value == math.huge or value == -math.huge then return end
    value = math.max(1, value)
    if value ~= tabs.strength.maxSendRate and tabs.strength.running then
        recordStatGain(tabs.strength, "Strength", tabs.strength.strength.Value)
        recordStatGain(tabs.strength, "Durability", tabs.strength.durability.Value)
        setTimerRunning(tabs.strength, false)
        tabs.strength.updateStats()
    end
    tabs.strength.maxSendRate = value
    tabs.strength.sendRate = math.min(tabs.strength.sendRate, tabs.strength.maxSendRate)
end, {clear = false})

tabs.strength:AddLabel("Recommended Speed: 462, you can always try more.")

tabs.strength.FastRepToggle = tabs.strength:AddSwitch("Fast Rep", function(state)
    recordStatGain(tabs.strength, "Strength", tabs.strength.strength.Value)
    recordStatGain(tabs.strength, "Durability", tabs.strength.durability.Value)
    setTimerRunning(tabs.strength, false)
    tabs.strength.statSamples.Strength = tabs.strength.strength.Value
    tabs.strength.statSamples.Durability = tabs.strength.durability.Value
    tabs.strength.running = state
    tabs.strength.Tokens = 0
    if state then
        if tabs.rebirths.running then tabs.rebirths.Switch:Set(false) end
        tabs.strength.gainedBaselineSet = true
        tabs.strength.sendRate = math.min(tabs.strength.initialSendRate, tabs.strength.maxSendRate)
        tabs.strength.LastAt = os.clock()
        tabs.strength.lastControlAt = tick()
        tabs.strength.lastControlStrength = tabs.strength.strength.Value
        tabs.strength.lastControlDurability = tabs.strength.durability.Value
        tabs.strength.stalledIntervals = 0
        tabs.strength.Status.Text = "Status: Preparing | " .. formatNumber(tabs.strength.sendRate) .. " reps/s"
        tabs.strength.Status.TextColor3 = Color3.fromRGB(80, 255, 120)
        tabs.strength.startWorker()
    else
        tabs.strength.Status.Text = tabs.strength.gainedBaselineSet and "Status: Paused" or "Status: Inactive"
        tabs.strength.Status.TextColor3 = tabs.strength.gainedBaselineSet and Color3.fromRGB(255, 180, 70) or Color3.fromRGB(255, 80, 80)
        tabs.strength.updateRuntime()
    end
    tabs.strength.updateStats()
end)

tabs.strength.FastRepToggle:Set(false)

runtime:Spawn(function()
    while true do
        tabs.rebirths.updateRuntime()
        tabs.strength.updateRuntime()
        if tabs.strength.timerStarted and getElapsed(tabs.strength) >= tabs.strength.nextAverageElapsed then
            tabs.strength.updateAverage()
            tabs.strength.nextAverageElapsed = getElapsed(tabs.strength) + 10
        end
        task.wait(0.1)
    end
end)

tabs.strength2.leaderstats = lp.player:WaitForChild("leaderstats")
tabs.strength2.strength = tabs.strength2.leaderstats:WaitForChild("Strength")
tabs.strength2.durability = lp.player:WaitForChild("Durability")
tabs.strength2.running = false
tabs.strength2.workerActive = false
tabs.strength2.startedAt = 0
tabs.strength2.totalElapsed = 0
tabs.strength2.timerStarted = false
tabs.strength2.gainedBaselineSet = false
tabs.strength2.statSamples = {Strength = tabs.strength2.strength.Value, Durability = tabs.strength2.durability.Value}
tabs.strength2.statGains = {Strength = 0, Durability = 0}
tabs.strength2.initialSendRate = 300
tabs.strength2.maxSendRate = 480
tabs.strength2.sendRate = tabs.strength2.initialSendRate
tabs.strength2.maxBurst = 24
tabs.strength2.Tokens = 0
tabs.strength2.pingLimit = 350
tabs.strength2.resumePing = 300
tabs.strength2.recoverySeconds = 2
tabs.strength2.rampInterval = 2
tabs.strength2.rampStep = 25
tabs.strength2.minAdaptiveRate = 450
tabs.strength2.fineRampStep = 2
tabs.strength2.backoffStep = 4
tabs.strength2.learnedLimit = false
tabs.strength2.lastPingSampleAt = os.clock()
tabs.strength2.lastPingSample = nil
tabs.strength2.lastPingRise = 0
tabs.strength2.stableInterval = 60
tabs.strength2.stableStep = 2
tabs.strength2.stableSince = os.clock()
tabs.strength2.pingPaused = false
tabs.strength2.lastRampAt = os.clock()
tabs.strength2.LastAt = os.clock()
tabs.strength2.Status = tabs.strength2:AddLabel("Status: Inactive")
tabs.strength2.Runtime = tabs.strength2:AddLabel("Runtime: 0d 0h 0m 0s")
tabs.strength2.StrengthStats = tabs.strength2:AddLabel("Strength: " .. formatCurrentStat(tabs.strength2.strength.Value) .. " | Gained: 0")
tabs.strength2.StrengthStats:SetAttribute("EleriumUpdateInterval", 0.02)
tabs.strength2.DurabilityStats = tabs.strength2:AddLabel("Durability: " .. formatCurrentStat(tabs.strength2.durability.Value) .. " | Gained: 0")
tabs.strength2.DurabilityStats:SetAttribute("EleriumUpdateInterval", 0.02)
tabs.strength2.StrengthAverage = tabs.strength2:AddLabel("Str Ø: --/s | --/min | --/h | --/d")
tabs.strength2.DurabilityAverage = tabs.strength2:AddLabel("Dura Ø: --/s | --/min | --/h | --/d")
tabs.strength2.Status.TextColor3 = Color3.fromRGB(255, 80, 80)

tabs.strength2.updateRuntime = function()
    updateRuntimeLabel(tabs.strength2)
end

tabs.strength2.updateStats = function()
    tabs.strength2.StrengthStats.Text = "Strength: " .. formatCurrentStat(tabs.strength2.strength.Value)
        .. " | Gained: " .. (tabs.strength2.running and not tabs.strength2.timerStarted
            and "Preparing" or formatNumber(tabs.strength2.statGains.Strength))
    tabs.strength2.DurabilityStats.Text = "Durability: " .. formatCurrentStat(tabs.strength2.durability.Value)
        .. " | Gained: " .. (tabs.strength2.running and not tabs.strength2.timerStarted
            and "Preparing" or formatNumber(tabs.strength2.statGains.Durability))
end

tabs.strength2.updateAverage = function()
    local elapsed = getElapsed(tabs.strength2)
    if elapsed <= 0 then return end
    tabs.strength2.StrengthAverage.Text = "Str Ø: " .. formatRate(tabs.strength2.statGains.Strength / elapsed)
    tabs.strength2.DurabilityAverage.Text = "Dura Ø: " .. formatRate(tabs.strength2.statGains.Durability / elapsed)
end

tabs.strength2:AddButton("Reset Calcs", function()
    resetCalculations(tabs.strength2)
end)

tabs.strength2.startMeasurement = function()
    if not tabs.strength2.running or tabs.strength2.timerStarted then return end
    tabs.strength2.statSamples.Strength = tabs.strength2.strength.Value
    tabs.strength2.statSamples.Durability = tabs.strength2.durability.Value
    setTimerRunning(tabs.strength2, true)
    tabs.strength2.nextAverageElapsed = getElapsed(tabs.strength2) + 10
    tabs.strength2.updateStats()
end

tabs.strength2.readPing = readDataPing

tabs.strength2.updateStatus = function(ping)
    local tab = tabs.strength2
    local pingText = ping and string.format(" | Ping: %.1f ms", ping) or " | Ping: unavailable"
    if not tab.running then
        tab.Status.Text = (tab.gainedBaselineSet and "Status: Paused" or "Status: Inactive") .. pingText
        tab.Status.TextColor3 = tab.gainedBaselineSet and Color3.fromRGB(255, 180, 70) or Color3.fromRGB(255, 80, 80)
    elseif tab.pingPaused or not ping or ping > tab.pingLimit then
        tab.Status.Text = "Status: Waiting | " .. formatNumber(tab.sendRate) .. " reps/s" .. pingText
        tab.Status.TextColor3 = Color3.fromRGB(255, 180, 70)
    else
        tab.Status.Text = "Status: Farming | " .. formatNumber(tab.sendRate) .. " reps/s" .. pingText
        tab.Status.TextColor3 = Color3.fromRGB(80, 255, 120)
    end
end

tabs.strength2.updateAdaptiveRate = function()
    local tab = tabs.strength2
    local now = os.clock()
    local ping = tab.readPing()
    tab.sendRate = math.min(tab.sendRate, tab.maxSendRate)
    if ping and now - tab.lastPingSampleAt >= 1 then
        tab.lastPingRise = tab.lastPingSample and ping - tab.lastPingSample or 0
        tab.lastPingSample = ping
        tab.lastPingSampleAt = now
    end
    if not ping or ping > tab.pingLimit then
        if not tab.pingPaused then
            tab.sendRate = math.max(math.min(tab.minAdaptiveRate, tab.sendRate), tab.sendRate - tab.backoffStep)
            tab.learnedLimit = true
        end
        tab.pingPaused = true
        tab.stableSince = now
        tab.recoveryStartedAt = nil
    elseif tab.pingPaused then
        if ping < tab.resumePing then
            tab.recoveryStartedAt = tab.recoveryStartedAt or now
            if now - tab.recoveryStartedAt >= tab.recoverySeconds then
                tab.pingPaused = false
                tab.recoveryStartedAt = nil
                tab.lastRampAt = now
                tab.stableSince = now
                tab.lastPingSample = ping
                tab.lastPingRise = 0
            end
        else
            tab.recoveryStartedAt = nil
        end
    elseif now - tab.lastRampAt >= tab.rampInterval then
        local pressure = ping >= tab.resumePing or (ping >= 150 and tab.lastPingRise >= 20)
        if pressure then
            tab.sendRate = math.max(math.min(tab.minAdaptiveRate, tab.sendRate), tab.sendRate - tab.fineRampStep)
            tab.learnedLimit = true
            tab.stableSince = now
        elseif tab.sendRate < tab.minAdaptiveRate then
            tab.sendRate = math.min(tab.minAdaptiveRate, tab.sendRate + tab.rampStep)
            tab.stableSince = now
        elseif not tab.learnedLimit then
            tab.sendRate = math.min(tab.maxSendRate, tab.sendRate + tab.fineRampStep)
            tab.stableSince = now
        elseif now - tab.stableSince >= tab.stableInterval then
            tab.sendRate = math.min(tab.maxSendRate, tab.sendRate + tab.stableStep)
            tab.stableSince = now
        end
        tab.lastRampAt = now
    end

    if tab.pingPaused then
        tab.Tokens = 0
        tab.LastAt = now
    end
    tab.updateStatus(ping)
end

tabs.strength2.workerLoop = function()
    tabs.strength2.LastAt = os.clock()
    local function isRunning()
        return tabs.strength2.running and not tabs.strength2.pingPaused
    end
    while tabs.strength2.running do
        if tabs.strength.running or tabs.rebirths.running then
            tabs.strength2.FastRepToggle:Set(false)
            break
        end
        tabs.strength2.updateAdaptiveRate()
        tabs.strength2.startMeasurement()
        if not tabs.strength2.pingPaused then
            sendTrainingReps(tabs.strength2, tabs.strength2.sendRate, tabs.strength2.maxBurst, isRunning)
        end

        services.runservice.Heartbeat:Wait()
    end

    tabs.strength2.workerActive = false
    if tabs.strength2.running then
        tabs.strength2.startWorker()
    end
end

tabs.strength2.startWorker = function()
    if tabs.strength2.workerActive then
        return
    end

    tabs.strength2.workerActive = true
    runtime:Spawn(tabs.strength2.workerLoop)
end

runtime:Connect(tabs.strength2.strength:GetPropertyChangedSignal("Value"), function()
    recordStatGain(tabs.strength2, "Strength", tabs.strength2.strength.Value)
    tabs.strength2.updateStats()
end)

runtime:Connect(tabs.strength2.durability:GetPropertyChangedSignal("Value"), function()
    recordStatGain(tabs.strength2, "Durability", tabs.strength2.durability.Value)
    tabs.strength2.updateStats()
end)

tabs.strength2.FastRepToggle = tabs.strength2:AddSwitch("Fast Rep", function(state)
    recordStatGain(tabs.strength2, "Strength", tabs.strength2.strength.Value)
    recordStatGain(tabs.strength2, "Durability", tabs.strength2.durability.Value)
    setTimerRunning(tabs.strength2, false)
    tabs.strength2.statSamples.Strength = tabs.strength2.strength.Value
    tabs.strength2.statSamples.Durability = tabs.strength2.durability.Value
    tabs.strength2.running = state
    tabs.strength2.Tokens = 0
    if state then
        if tabs.strength.running then tabs.strength.FastRepToggle:Set(false) end
        if tabs.rebirths.running then tabs.rebirths.Switch:Set(false) end
        tabs.strength2.gainedBaselineSet = true
        tabs.strength2.maxSendRate = 480
        tabs.strength2.learnedLimit = false
        tabs.strength2.lastPingSampleAt = os.clock()
        tabs.strength2.lastPingSample = nil
        tabs.strength2.lastPingRise = 0
        tabs.strength2.sendRate = tabs.strength2.initialSendRate
        tabs.strength2.pingPaused = false
        tabs.strength2.recoveryStartedAt = nil
        tabs.strength2.LastAt = os.clock()
        tabs.strength2.lastRampAt = os.clock()
        tabs.strength2.stableSince = os.clock()
        tabs.strength2.Status.Text = "Status: Preparing | " .. formatNumber(tabs.strength2.sendRate) .. " reps/s"
        tabs.strength2.Status.TextColor3 = Color3.fromRGB(80, 255, 120)
        tabs.strength2.startWorker()
    else
        tabs.strength2.Status.Text = tabs.strength2.gainedBaselineSet and "Status: Paused" or "Status: Inactive"
        tabs.strength2.Status.TextColor3 = tabs.strength2.gainedBaselineSet and Color3.fromRGB(255, 180, 70) or Color3.fromRGB(255, 80, 80)
        tabs.strength2.updateRuntime()
    end
    tabs.strength2.updateStats()
    tabs.strength2.updateStatus(tabs.strength2.readPing())
end)

tabs.strength2.FastRepToggle:Set(false)

runtime:Spawn(function()
    while true do
        local ping = readDataPing()
        if not tabs.strength2.running then
            tabs.strength2.updateStatus(ping)
        end
        task.wait(0.5)
    end
end)

runtime:Spawn(function()
    while true do
        tabs.strength2.updateRuntime()
        if tabs.strength2.timerStarted and getElapsed(tabs.strength2) >= tabs.strength2.nextAverageElapsed then
            tabs.strength2.updateAverage()
            tabs.strength2.nextAverageElapsed = getElapsed(tabs.strength2) + 10
        end
        task.wait(0.1)
    end
end)

tabs.boss.runtime = {}

tabs.boss:AddHeading("Boss Farming:")
tabs.boss.StatusLabel = tabs.boss:AddLabel("Status: Waiting for Boss")
tabs.boss.BossLabel = tabs.boss:AddLabel("Boss: None")
tabs.boss.HealthLabel = tabs.boss:AddLabel("Health: 0 / 0")
tabs.boss.NextBossLabel = tabs.boss:AddLabel("Next Boss: N/A")

tabs.boss.Data = {
	Running = false,
	Generation = 0,
	ContinueTraining = true,
	Phase = "Waiting",
	MachineCooldownUntil = 0,
	TrainingSnapshot = nil,
	TrainingRestore = nil,
	TrainingResumeGeneration = 0,
	PreparationSeconds = 4,
	PunchInterval = 0.3,
	LastPunch = 0,
	AttackSequence = nil,
	EvadeUntil = 0,
	EvadeDistance = 230,
	PunchBehindDistance = 45,
	StompHealthThreshold = 0.35,
	DodgeStomps = false,
	BossConfig = nil,
	Bosses = {},
	BossOrder = {},
	BossByDisplayName = {},
	SelectedBosses = {}
}

tabs.boss:AddTextBox("Seconds Training before Boss (when Rebirthing):", function(text)
	if tonumber(text) and tonumber(text) >= 0 then tabs.boss.Data.PreparationSeconds = tonumber(text) end
end, {clear = false})

tabs.boss.SelectedBossesLabel = tabs.boss:AddLabel("Targeted Bosses: Detecting...")
tabs.boss.BossDropdown = tabs.boss:AddDropdown("Target specific Bosses", function(displayName)
	tabs.boss.runtime.bossModelName = tabs.boss.Data.BossByDisplayName[displayName]
	if tabs.boss.runtime.bossModelName then
		tabs.boss.Data.SelectedBosses[tabs.boss.runtime.bossModelName] = not tabs.boss.Data.SelectedBosses[tabs.boss.runtime.bossModelName]
		tabs.boss.updateSelectedBossesLabel()
	end
end)

tabs.boss.updateSelectedBossesLabel = function(selectedNames)
	selectedNames = {}
	for _, modelName in ipairs(tabs.boss.Data.BossOrder) do
		if tabs.boss.Data.SelectedBosses[modelName] then
			table.insert(selectedNames, (string.gsub(tabs.boss.Data.Bosses[modelName], "%s+[Bb][Oo][Ss][Ss]$", "")))
		end
	end
	tabs.boss.SelectedBossesLabel.Text = "Targeted Bosses: " .. (#selectedNames > 0 and table.concat(selectedNames, ", ") or "None")
end

tabs.boss.addBossChoice = function(modelName, displayName)
	modelName = tostring(modelName or "")
	displayName = tostring(displayName or modelName)
	if modelName == "" or tabs.boss.Data.Bosses[modelName] then return end
	tabs.boss.Data.Bosses[modelName] = displayName
	tabs.boss.Data.BossByDisplayName[displayName] = modelName
	tabs.boss.Data.SelectedBosses[modelName] = true
	table.insert(tabs.boss.Data.BossOrder, modelName)
	tabs.boss.BossDropdown:Add(displayName)
	tabs.boss.updateSelectedBossesLabel()
end

tabs.boss.runtime.configSuccess, tabs.boss.Data.BossConfig = pcall(function()
	if services.isSolara then return nil end
	return require(services.replicatedstorage:WaitForChild("shared"):WaitForChild("config"):WaitForChild("BossEventConfig"))
end)
if tabs.boss.runtime.configSuccess and tabs.boss.Data.BossConfig and tabs.boss.Data.BossConfig.RARITIES then
	for _, rarity in ipairs(tabs.boss.Data.BossConfig.RARITIES) do
		tabs.boss.addBossChoice(rarity.BossModel, rarity.DisplayName or rarity.Name or rarity.BossModel)
	end
else
	tabs.boss.SelectedBossesLabel.Text = "Farmed Bosses: Waiting for detection"
end

tabs.boss.shouldFarmBoss = function(model)
	if not tabs.boss.Data.Bosses[model.Name] then
		tabs.boss.addBossChoice(model.Name, workspace:GetAttribute("BossDisplayName") or model.Name)
	end
	return tabs.boss.Data.SelectedBosses[model.Name] == true
end

tabs.boss.findActiveBoss = function(model, stats, health, maxHealth, hitbox)
	for _, candidate in ipairs(services.collectionservice:GetTagged("BossEventBoss")) do
		if candidate:IsA("Model") and candidate:IsDescendantOf(workspace) then
			model = candidate
			break
		end
	end

	if not model then
		tabs.boss.runtime.events = workspace:FindFirstChild("Events")
		tabs.boss.runtime.bossFolder = tabs.boss.runtime.events and (tabs.boss.runtime.events:FindFirstChild("BossEvent") or tabs.boss.runtime.events:FindFirstChild("BossArena"))
		if tabs.boss.runtime.bossFolder then
			for _, candidate in ipairs(tabs.boss.runtime.bossFolder:GetDescendants()) do
				if candidate:IsA("Model") and (candidate:FindFirstChild("BossDamageHitbox") or candidate:HasTag("BossEventBoss")) then
					model = candidate
					break
				end
			end
		end
	end

	if not model then return end
	stats = model:FindFirstChild("stats")
	health = stats and stats:FindFirstChild("Health")
	maxHealth = stats and stats:FindFirstChild("MaxHealth")
	hitbox = model:FindFirstChild("BossDamageHitbox", true)
	if not hitbox or not hitbox:IsA("BasePart") then return end
	tabs.boss.runtime.currentHealth = health and health.Value or workspace:GetAttribute("BossHealth")
	if typeof(tabs.boss.runtime.currentHealth) == "number" and tabs.boss.runtime.currentHealth <= 0 then return end
	return model, health, maxHealth, hitbox
end

tabs.boss.getBossDisplayName = function(model)
	return workspace:GetAttribute("BossDisplayName") or model.Name
end

tabs.boss.getBossHealth = function(health)
	return health and health.Value or workspace:GetAttribute("BossHealth") or 0
end

tabs.boss.getBossMaxHealth = function(maxHealth)
	return maxHealth and maxHealth.Value or workspace:GetAttribute("BossMaxHealth") or 0
end

tabs.boss.formatCountdown = function(seconds, hours, minutes)
	seconds = math.max(0, math.floor(seconds or 0))
	hours = math.floor(seconds / 3600)
	minutes = math.floor(seconds % 3600 / 60)
	seconds = seconds % 60
	return string.format("%dh %dmin %ds", hours, minutes, seconds)
end

tabs.boss.getTrainingMachine = function(character, root, seat, machines, best, bestDistance, distance, part)
	character = lp.player.Character
	root = character and character:FindFirstChild("HumanoidRootPart")
	seat = character and character:FindFirstChildOfClass("Humanoid")
	seat = seat and seat.SeatPart
	machines = workspace:FindFirstChild("machinesFolder")
	if not root or not machines then return end
	bestDistance = 35
	for _, machine in ipairs(machines:GetChildren()) do
		if seat and seat:IsDescendantOf(machine) then return machine, seat end
		part = tabs.boss.getMachineInteractPart(machine)
		if part then
			distance = (part.Position - root.Position).Magnitude
			if distance < bestDistance then best, bestDistance = machine, distance end
		end
	end
	return best, nil
end

tabs.boss.getMachineInteractPart = function(machine)
	for _, descendant in ipairs(machine:GetDescendants()) do
		if descendant:IsA("BasePart") and string.lower(descendant.Name) == "interactseat" then return descendant end
	end
end

tabs.boss.leaveExerciseMachine = function(character, humanoid, root)
	character = lp.player.Character
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 then return end
	pcall(function()
		services.virtualinputmanager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
		humanoid.Sit = false
		humanoid.Jump = true
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		if root then root.AssemblyLinearVelocity = Vector3.new(0, math.max(root.AssemblyLinearVelocity.Y, 50), 0) end
	end)
	pcall(function() services.virtualinputmanager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
	tabs.boss.Data.MachineCooldownUntil = math.max(tabs.boss.Data.MachineCooldownUntil, os.clock() + 4)
	task.wait(0.2)
end

tabs.boss.captureTraining = function(character, root)
	tabs.boss.Data.TrainingResumeGeneration = tabs.boss.Data.TrainingResumeGeneration + 1
	if tabs.boss.Data.TrainingSnapshot then return end
	if tabs.boss.Data.TrainingRestore then
		tabs.boss.Data.TrainingSnapshot = tabs.boss.Data.TrainingRestore
		tabs.boss.Data.TrainingRestore = nil
		return
	end
	character = lp.player.Character
	root = character and character:FindFirstChild("HumanoidRootPart")
	tabs.boss.Data.TrainingSnapshot = {
		Rebirth = tabs.rebirths.running,
		Strength = tabs.strength.running,
		Strength2 = tabs.strength2.running,
		Position = root and root.CFrame,
		Tool = character and character:FindFirstChildOfClass("Tool"),
		Character = character
	}
	tabs.boss.Data.TrainingSnapshot.Machine, tabs.boss.Data.TrainingSnapshot.SeatPart = tabs.boss.getTrainingMachine()
end

tabs.boss.pauseTraining = function()
	tabs.boss.captureTraining()
	if tabs.rebirths.running then tabs.rebirths.Switch:Set(false) end
	if tabs.strength.running then tabs.strength.FastRepToggle:Set(false) end
	if tabs.strength2.running then tabs.strength2.FastRepToggle:Set(false) end
end

tabs.boss.hasTrainingStats = function(strength, durability)
	strength = tabs.rebirths.strength
	durability = lp.player:FindFirstChild("Durability")
	return strength and durability and strength.Value > 0 and durability.Value > 0
end

tabs.boss.prepareForBoss = function(boss, preparation, character, humanoid, tool, backpack, toolName)
	if not boss.Data.Preparation then
		tabs.boss.pauseTraining()
		boss.Data.Preparation = {LastRep = 0}
		boss.Data.Phase = "Training"
	end
	preparation = boss.Data.Preparation
	if tabs.rebirths.workerActive or tabs.strength.workerActive or tabs.strength2.workerActive then
		boss.StatusLabel.Text = "Status: Waiting for Farming to Pause"
		return false
	end
	character = lp.player.Character
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if preparation.Character ~= character or preparation.Rebirths ~= tabs.rebirths.rebirths.Value then
		preparation.Character = character
		preparation.Rebirths = tabs.rebirths.rebirths.Value
		preparation.StartedAt = nil
		preparation.Detached = false
		preparation.PetsReady = nil
		preparation.LastRep = 0
		preparation.Required = not tabs.boss.hasTrainingStats()
	end
	if not humanoid or humanoid.Health <= 0 then
		preparation.StartedAt = nil
		boss.StatusLabel.Text = "Status: Waiting for Respawn"
		return false
	end
	if not preparation.Detached then
		preparation.Detached = true
		if tabs.boss.Data.TrainingSnapshot.Machine or humanoid.SeatPart then tabs.boss.leaveExerciseMachine() end
		if not boss.Data.Running then return false end
	end
	if not preparation.Required then
		boss.Data.FightCharacter = character
		boss.Data.FightRebirths = tabs.rebirths.rebirths.Value
		boss.Data.Preparation = nil
		return true
	end
	if not preparation.PetsReady then
		equipBestFarmingPets(function() return boss.Data.Running and boss.Data.Preparation == preparation end)
		if not boss.Data.Running or boss.Data.Preparation ~= preparation then return false end
		preparation.PetsReady = true
	end
	if lp.player.Character ~= character or humanoid.Health <= 0 then return false end
	backpack = lp.player:FindFirstChild("Backpack")
	toolName = tabs.rebirths.strength.Value < 2000 and "Weight" or "Pushups"
	if toolName == "Weight" then preparation.StartedAt = nil end
	tool = character:FindFirstChild(toolName) or backpack and backpack:FindFirstChild(toolName)
	if not tool then
		preparation.StartedAt = nil
		boss.StatusLabel.Text = "Status: Waiting for " .. toolName
		return false
	end
	if tool.Parent ~= character then humanoid:EquipTool(tool) end
	if tool.Parent ~= character then preparation.StartedAt = nil return false end
	if toolName == "Pushups" then preparation.StartedAt = preparation.StartedAt or os.clock() end
	if os.clock() - preparation.LastRep >= 0.1 then
		services.muscleEvent:FireServer("rep")
		preparation.LastRep = os.clock()
	end
	if toolName == "Weight" then
		boss.StatusLabel.Text = "Status: Weight Training | " .. formatCurrentStat(tabs.rebirths.strength.Value) .. " / 2K Strength"
		return false
	end
	boss.StatusLabel.Text = "Status: Training before Boss (" .. string.format("%.1f", math.max(0, tabs.boss.Data.PreparationSeconds - (os.clock() - preparation.StartedAt))) .. "s)"
	if os.clock() - preparation.StartedAt < tabs.boss.Data.PreparationSeconds then return false end
	boss.Data.FightCharacter = character
	boss.Data.FightRebirths = tabs.rebirths.rebirths.Value
	boss.Data.Preparation = nil
	return true
end

tabs.boss.needsRetraining = function(boss, character, humanoid)
	character = lp.player.Character
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return not humanoid or humanoid.Health <= 0 or boss.Data.FightCharacter ~= character
		or boss.Data.FightRebirths ~= tabs.rebirths.rebirths.Value
end

tabs.boss.restoreMachine = function(snapshot, generation, character, humanoid, root, part, tool, backpack)
	if tabs.boss.Data.TrainingResumeGeneration ~= generation then return false end
	character = lp.player.Character
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not humanoid or humanoid.Health <= 0 then return false end
	humanoid:UnequipTools()
	if snapshot.Machine then
		if not snapshot.Machine.Parent then return false end
		part = tabs.boss.getMachineInteractPart(snapshot.Machine)
		if not part or os.clock() < tabs.boss.Data.MachineCooldownUntil then return false end
		root.CFrame = part.CFrame * CFrame.new(0, 3, 0)
		root.AssemblyLinearVelocity = Vector3.zero
		task.wait(0.4)
		if tabs.boss.Data.TrainingResumeGeneration ~= generation or lp.player.Character ~= character or humanoid.Health <= 0 then return false end
		services.virtualinputmanager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
		task.wait(0.1)
		services.virtualinputmanager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
		task.wait(0.4)
		if tabs.boss.Data.TrainingResumeGeneration ~= generation or lp.player.Character ~= character or humanoid.Health <= 0 then return false end
		if snapshot.SeatPart and (not humanoid.SeatPart or not humanoid.SeatPart:IsDescendantOf(snapshot.Machine)) then return false end
	elseif snapshot.Position then
		root.CFrame = snapshot.Position
		root.AssemblyLinearVelocity = Vector3.zero
	end
	backpack = lp.player:FindFirstChild("Backpack")
	tool = snapshot.Tool and (snapshot.Tool.Parent and snapshot.Tool or backpack and backpack:FindFirstChild(snapshot.Tool.Name))
	if tool then humanoid:EquipTool(tool) end
	return true
end

tabs.boss.resumeTraining = function(snapshot)
	snapshot = tabs.boss.Data.TrainingSnapshot
	if not snapshot then return end
	tabs.boss.Data.TrainingSnapshot = nil
	tabs.boss.Data.TrainingRestore = snapshot
	tabs.boss.Data.TrainingResumeGeneration = tabs.boss.Data.TrainingResumeGeneration + 1
	runtime:Spawn(function(generation)
		while tabs.boss.Data.TrainingResumeGeneration == generation do
			if tabs.boss.restoreMachine(snapshot, generation) then
				if tabs.boss.Data.TrainingResumeGeneration ~= generation then return end
				tabs.boss.Data.TrainingRestore = nil
				if snapshot.Strength then tabs.strength.FastRepToggle:Set(true) end
				if snapshot.Strength2 then tabs.strength2.FastRepToggle:Set(true) end
				if snapshot.Rebirth then tabs.rebirths.Switch:Set(true) end
				return
			end
			task.wait(0.1)
		end
	end, tabs.boss.Data.TrainingResumeGeneration)
end

tabs.boss.getBossHeadPosition = function(model, hitbox, head)
	head = model:FindFirstChild("Head", true) or model:FindFirstChild("head", true)
	if head and head:IsA("BasePart") then return head.Position end
	if head and head:IsA("Bone") then return head.WorldPosition end
	return hitbox.Position + Vector3.new(0, hitbox.Size.Y * 0.35, 0)
end

tabs.boss.getAliveCharacter = function(generation, timeout, startedAt, character, root, humanoid)
	if not tabs.boss.Data.Running or tabs.boss.Data.Generation ~= generation then return end
	startedAt = os.clock()
	repeat
		character = lp.player.Character
		root = character and character:FindFirstChild("HumanoidRootPart")
		humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			return character, root, humanoid
		end
		tabs.boss.StatusLabel.Text = "Status: Waiting for Respawn"
		task.wait(0.1)
	until not tabs.boss.Data.Running
		or tabs.boss.Data.Generation ~= generation
		or (timeout and os.clock() - startedAt >= timeout)
end

tabs.boss.evadeAttack = function(boss, model, hitbox, root, humanoid, sequence, attackKind, attackCFrame, impactTime, direction, safePosition, center)
	sequence = model:GetAttribute("BossAttackSequence")
	attackKind = model:GetAttribute("BossAttackKind")
	attackCFrame = model:GetAttribute("BossAttackCFrame")
	impactTime = model:GetAttribute("BossAttackImpactTime")

	if typeof(sequence) == "number" and sequence ~= boss.Data.AttackSequence then
		boss.Data.AttackSequence = sequence
		if typeof(attackKind) == "string" and typeof(attackCFrame) == "CFrame" and typeof(impactTime) == "number" then
			boss.Data.EvadeUntil = impactTime + 0.6
		end
	end

	if typeof(attackCFrame) ~= "CFrame" or workspace:GetServerTimeNow() > boss.Data.EvadeUntil then
		return
	end

	attackKind = string.lower(tostring(attackKind or ""))
	if string.find(attackKind, "punch", 1, true) then
		center = tabs.boss.getBossHeadPosition(model, hitbox)
		direction = Vector3.new(attackCFrame.LookVector.X, 0, attackCFrame.LookVector.Z)
		if direction.Magnitude < 1 then direction = Vector3.new(hitbox.CFrame.LookVector.X, 0, hitbox.CFrame.LookVector.Z) end
		if direction.Magnitude < 1 then direction = Vector3.new(0, 0, 1) end
		safePosition = center - direction.Unit * boss.Data.PunchBehindDistance
		root.CFrame = CFrame.lookAt(safePosition, center)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		boss.StatusLabel.Text = "Status: Dodging Punch"
		return "Punch"
	end

	if not string.find(attackKind, "stomp", 1, true) then return end
	if humanoid.Health / math.max(humanoid.MaxHealth, 1) <= boss.Data.StompHealthThreshold then
		boss.Data.DodgeStomps = true
	end
	if not boss.Data.DodgeStomps then return end

	direction = Vector3.new(root.Position.X - attackCFrame.Position.X, 0, root.Position.Z - attackCFrame.Position.Z)
	if direction.Magnitude < 1 then
		direction = Vector3.new(-attackCFrame.LookVector.X, 0, -attackCFrame.LookVector.Z)
	end
	if direction.Magnitude < 1 then direction = Vector3.new(1, 0, 0) end
	direction = direction.Unit
	safePosition = attackCFrame.Position + direction * boss.Data.EvadeDistance + Vector3.new(0, 18, 0)
	root.CFrame = CFrame.lookAt(safePosition, attackCFrame.Position)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	boss.StatusLabel.Text = "Status: Dodging Stomp"
	return "Stomp"
end

tabs.boss.attack = function(boss, model, health, maxHealth, hitbox, character, root, humanoid, punch, leftHand, rightHand, center, position, evadeMode)
	character = lp.player.Character
	root = character and character:FindFirstChild("HumanoidRootPart")
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then return end
	evadeMode = tabs.boss.evadeAttack(boss, model, hitbox, root, humanoid)
	if evadeMode == "Stomp" then return end
	punch = character:FindFirstChild("Punch") or lp.player.Backpack:FindFirstChild("Punch")
	if punch and punch.Parent ~= character then humanoid:EquipTool(punch) end
	leftHand = character:FindFirstChild("LeftHand")
	rightHand = character:FindFirstChild("RightHand")
	center = tabs.boss.getBossHeadPosition(model, hitbox)
	if evadeMode ~= "Punch" then
		position = center
		root.CFrame = CFrame.lookAt(position, position + hitbox.CFrame.LookVector)
	end
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	pcall(function()
		if leftHand then
			services.touchParts(hitbox, leftHand, 0)
			services.touchParts(hitbox, leftHand, 1)
		end
		if rightHand then
			services.touchParts(hitbox, rightHand, 0)
			services.touchParts(hitbox, rightHand, 1)
		end
	end)

	if os.clock() - boss.Data.LastPunch >= boss.Data.PunchInterval then
		boss.Data.LastPunch = os.clock()
		pcall(function()
			services.muscleEvent:FireServer("punch", "leftHand")
			services.muscleEvent:FireServer("punch", "rightHand")
			if punch then punch:Activate() end
		end)
	end

	boss.BossLabel.Text = (boss.BossLabelPrefix or "Boss: ") .. boss.getBossDisplayName(model)
	boss.runtime.health = boss.getBossHealth(health, model)
	boss.runtime.maxHealth = boss.getBossMaxHealth(maxHealth, model)
	boss.HealthLabel.Text = "Health: " .. formatCurrentStat(boss.runtime.health) .. " / " .. formatCurrentStat(boss.runtime.maxHealth)
end

tabs.boss.findChest = function(chest, prompt, part)
	for _, candidate in ipairs(services.collectionservice:GetTagged("BossEventChest")) do
		if candidate:IsDescendantOf(workspace) then chest = candidate break end
	end
	if not chest then chest = workspace:FindFirstChild("BossChest", true) end
	if not chest then
		for _, candidate in ipairs(workspace:GetDescendants()) do
			if candidate:IsA("ProximityPrompt") and candidate.Name == "bossChestPrompt" then
				chest = candidate.Parent
				break
			end
		end
	end
	if not chest then return end
	prompt = chest:FindFirstChild("bossChestPrompt", true)
	part = prompt and prompt.Parent or (chest:IsA("Model") and (chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart", true))) or chest
	if part and part:IsA("BasePart") then return chest, prompt, part end
end

tabs.boss.collectChest = function(generation, startedAt, chest, prompt, part, character, root)
	tabs.boss.StatusLabel.Text = "Status: Waiting for Chest"
	startedAt = os.clock()
	repeat
		chest, prompt, part = tabs.boss.findChest()
		if chest and chest:GetAttribute("BossChestEmerging") ~= true then break end
		task.wait(0.1)
	until not tabs.boss.Data.Running or tabs.boss.Data.Generation ~= generation or os.clock() - startedAt >= 12
	if not tabs.boss.Data.Running or tabs.boss.Data.Generation ~= generation or not chest or not part then return end

	tabs.boss.StatusLabel.Text = "Status: Collecting Chest"
	startedAt = os.clock()
	repeat
		character, root = tabs.boss.getAliveCharacter(generation, 2)
		if character and root and chest.Parent and part.Parent then
			tabs.boss.StatusLabel.Text = "Status: Collecting Chest"
			pcall(function()
				root.CFrame = CFrame.lookAt(part.Position + Vector3.new(0, 3, 4), part.Position)
				root.AssemblyLinearVelocity = Vector3.zero
			end)
			task.wait(0.15)
			if not tabs.boss.Data.Running or tabs.boss.Data.Generation ~= generation then return end
			if not (prompt and prompt.Parent and type(fireproximityprompt) == "function"
				and pcall(fireproximityprompt, prompt)) then
				pcall(function()
					services.virtualinputmanager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
					task.wait(0.1)
					services.virtualinputmanager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
				end)
			end
		end
		task.wait(0.25)
	until not tabs.boss.Data.Running
		or tabs.boss.Data.Generation ~= generation
		or lp.player:GetAttribute("BossChestPending") == false
		or not chest.Parent
		or os.clock() - startedAt >= 12
end

tabs.boss.ContinueSwitch = tabs.boss:AddSwitch("Continue Farming after Boss Kill", function(state)
	tabs.boss.Data.ContinueTraining = state
	if state and tabs.boss.Data.Phase == "Waiting"
		and (not tabs.boss.Halloween or not tabs.boss.Halloween.Data.Running) then tabs.boss.resumeTraining() end
end)
tabs.boss.ContinueSwitch:Set(true)

runtime:Spawn(function(model, health, maxHealth, hitbox, currentHealth, currentMaxHealth, nextTime)
	while true do
		model, health, maxHealth, hitbox = tabs.boss.findActiveBoss()
		if model then
			currentHealth = tabs.boss.getBossHealth(health)
			currentMaxHealth = tabs.boss.getBossMaxHealth(maxHealth)
			tabs.boss.BossLabel.Text = "Boss: " .. (workspace:GetAttribute("BossDisplayName") or model.Name)
			tabs.boss.HealthLabel.Text = "Health: " .. formatCurrentStat(currentHealth) .. " / " .. formatCurrentStat(currentMaxHealth)
			tabs.boss.NextBossLabel.Text = "Next Boss: Current boss active"
		else
			tabs.boss.BossLabel.Text = "Boss: None"
			tabs.boss.HealthLabel.Text = "Health: 0 / 0"
			nextTime = workspace:GetAttribute("BossSpawnNextTime")
			tabs.boss.NextBossLabel.Text = typeof(nextTime) == "number"
				and "Next Boss: " .. tabs.boss.formatCountdown(nextTime - workspace:GetServerTimeNow())
				or "Next Boss: N/A"
		end
		task.wait(0.25)
	end
end)

tabs.boss:AddHeading("Boss Webhook:")
tabs.boss.Webhook = {Queue = {}, Pending = {}, Failed = {}, ChestKeys = setmetatable({}, {__mode = "k"})}
tabs.boss.Webhook.Input = tabs.boss:AddTextBox("Discord Webhook URL (optional)", function() end, {clear = false})
tabs.boss.Webhook.Status = tabs.boss:AddLabel("Webhook: Disabled")

_G.SilenceBossWebhookHistory = _G.SilenceBossWebhookHistory or {Seen = {}, Order = {}}

tabs.boss.webhookUrl = function()
	local text = tabs.boss.Webhook.Input.Text:match("^%s*(.-)%s*$")
	if text == "" then return nil end
	local host, path = text:match("^https://([^/]+)(/.*)$")
	local allowed = { ["discord.com"] = true, ["discordapp.com"] = true,
		["canary.discord.com"] = true, ["ptb.discord.com"] = true }
	if not allowed[host] or not path:match("^/api/webhooks/%d+/[%w_-]+$") then return nil, "Invalid Discord webhook URL" end
	return text
end

tabs.boss.webhookRequest = function()
	if type(request) == "function" then return request end
	if type(http_request) == "function" then return http_request end
	if type(syn) == "table" and type(syn.request) == "function" then return syn.request end
	if type(http) == "table" and type(http.request) == "function" then return http.request end
end

tabs.boss.webhookNumber = function(value)
	value = tonumber(value) or 0
	for _, unit in ipairs({{1e18, "qi"}, {1e15, "qa"}, {1e12, "t"}, {1e9, "b"}, {1e6, "m"}, {1e3, "k"}}) do
		if value >= unit[1] then return (string.format("%.2f", value / unit[1]):gsub("0+$", ""):gsub("%.$", "")) .. unit[2] end
	end
	return value == math.floor(value) and string.format("%.0f", value) or tostring(value)
end

tabs.boss.queueWebhook = function(kind, sequence, content)
	local state = tabs.boss.Webhook
	local url = tabs.boss.webhookUrl()
	if not url then return end
	if not tabs.boss.webhookRequest() then state.Status.Text = "Webhook: HTTP requests unavailable" return end
	local key = url .. "|" .. game.JobId .. "|" .. kind .. "|" .. tostring(sequence)
	if state.Pending[key] or state.Failed[key] or _G.SilenceBossWebhookHistory.Seen[key] then return end
	if #state.Queue >= 32 then state.Status.Text = "Webhook: Queue full" return end
	state.Pending[key] = true
	table.insert(state.Queue, {Url = url, Key = key, Content = content:sub(1, 2000), Attempts = 0, NextAt = 0})
	state.Status.Text = "Webhook: Queued"
end

tabs.boss.observeWebhookSpawn = function()
	if workspace:GetAttribute("BossActive") ~= true then return end
	local sequence = workspace:GetAttribute("BossSpawnSequence")
	local name = workspace:GetAttribute("BossDisplayName")
	local health = tonumber(workspace:GetAttribute("BossMaxHealth"))
	if sequence == nil or type(name) ~= "string" or not health or health <= 0 then return end
	tabs.boss.queueWebhook("spawn", sequence, name .. " Spawned!\nHealth: " .. tabs.boss.webhookNumber(health))
end

tabs.boss.webhookRewards = function(rewards)
	local lines = {}
	if type(rewards) ~= "table" then return lines end
	for _, reward in ipairs(rewards) do
		if type(reward) == "table" and type(reward.DisplayName) == "string"
			and type(reward.Amount) == "number" and reward.Amount > 0 then
			local quantity = reward.Amount == 1 and reward.Guaranteed ~= true and ""
				or tabs.boss.webhookNumber(reward.Amount) .. " "
			table.insert(lines, "- " .. quantity .. reward.DisplayName)
		end
	end
	return lines
end

tabs.boss.observeWebhookRewards = function(chest, rewards)
	if typeof(chest) ~= "Instance" or not chest:IsA("Model") then return end
	local rarity = chest:GetAttribute("BossRarityIndex")
	if type(rarity) ~= "number" then return end
	local lines = tabs.boss.webhookRewards(rewards)
	if #lines == 0 then return end
	local config = tabs.boss.Data.BossConfig
	local entry = config and config.RARITIES and config.RARITIES[rarity]
	local fallback = ({"Common", "Rare", "Epic", "Legendary", "Mythic", "Rainbow"})[rarity]
	local name = entry and (entry.DisplayName or entry.Name) or (fallback and fallback .. " Boss")
	if not name then return end
	local state = tabs.boss.Webhook
	state.ChestKeys[chest] = state.ChestKeys[chest]
		or tostring(workspace:GetAttribute("BossResultSequence") or workspace:GetAttribute("BossSpawnSequence")) .. ":" .. rarity
	tabs.boss.queueWebhook("defeated", state.ChestKeys[chest], name .. " Defeated!\nRewards:\n" .. table.concat(lines, "\n"))
end

tabs.boss.processWebhook = function()
	local state = tabs.boss.Webhook
	local item = state.Queue[1]
	if not item or os.clock() < item.NextAt then return end
	if item.Url ~= tabs.boss.webhookUrl() then
		state.Pending[item.Key] = nil
		table.remove(state.Queue, 1)
		return
	end
	local send = tabs.boss.webhookRequest()
	if not send then state.Status.Text = "Webhook: HTTP requests unavailable" return end
	item.Attempts = item.Attempts + 1
	local httpService = game:GetService("HttpService")
	local success, response = pcall(function()
		return send({Url = item.Url .. "?wait=true", Method = "POST",
			Headers = {["Content-Type"] = "application/json"},
			Body = httpService:JSONEncode({content = item.Content, allowed_mentions = {parse = {}}})})
	end)
	if not runtime.Alive then return end
	local code = success and type(response) == "table" and tonumber(response.StatusCode or response.Status)
	if code and code >= 200 and code < 300 then
		local history = _G.SilenceBossWebhookHistory
		history.Seen[item.Key] = true
		table.insert(history.Order, item.Key)
		if #history.Order > 200 then history.Seen[table.remove(history.Order, 1)] = nil end
		state.Pending[item.Key] = nil
		table.remove(state.Queue, 1)
		state.Status.Text = "Webhook: Sent"
		return
	end
	local retry = not code or code == 408 or code == 429 or code >= 500
	if retry and item.Attempts < 3 then
		local delay = 5 * item.Attempts
		if code == 429 then
			local decoded, body = pcall(function() return httpService:JSONDecode(response.Body) end)
			if decoded and type(body) == "table" then delay = math.max(delay, tonumber(body.retry_after) or 0) end
		end
		item.NextAt = os.clock() + delay
		state.Status.Text = "Webhook: Retrying"
	else
		state.Pending[item.Key] = nil
		state.Failed[item.Key] = true
		table.remove(state.Queue, 1)
		state.Status.Text = "Webhook: " .. (code and ("HTTP " .. code) or "Request failed")
	end
end

runtime:Connect(tabs.boss.Webhook.Input:GetPropertyChangedSignal("Text"), function()
	local url, message = tabs.boss.webhookUrl()
	tabs.boss.Webhook.Status.Text = url and "Webhook: Ready" or ("Webhook: " .. (message or "Disabled"))
	if url then runtime:Defer(tabs.boss.observeWebhookSpawn) end
end)

tabs.boss.Webhook.ResultSequence = workspace:GetAttribute("BossResultSequence")
tabs.boss.observeWebhookDespawn = function()
	local state = tabs.boss.Webhook
	local sequence = workspace:GetAttribute("BossResultSequence")
	if sequence == nil or sequence == state.ResultSequence then return end
	state.ResultSequence = sequence
	if workspace:GetAttribute("BossResultKind") ~= "Survived" then return end
	local rarity = workspace:GetAttribute("BossResultRarity")
	if type(rarity) ~= "number" then return end
	local config = tabs.boss.Data.BossConfig
	local entry = config and config.RARITIES and config.RARITIES[rarity]
	local fallback = ({"Common", "Rare", "Epic", "Legendary", "Mythic", "Rainbow"})[rarity]
	local name = entry and (entry.DisplayName or entry.Name) or (fallback and fallback .. " Boss")
	if name then tabs.boss.queueWebhook("despawn", sequence, name .. " Despawned!") end
end
runtime:Connect(workspace:GetAttributeChangedSignal("BossResultSequence"), tabs.boss.observeWebhookDespawn)

runtime:Connect(workspace:GetAttributeChangedSignal("BossSpawnSequence"), tabs.boss.observeWebhookSpawn)
runtime:Connect(workspace:GetAttributeChangedSignal("BossActive"), tabs.boss.observeWebhookSpawn)
runtime:Connect(workspace:GetAttributeChangedSignal("BossMaxHealth"), tabs.boss.observeWebhookSpawn)

runtime:Spawn(function()
	local events = game:GetService("ReplicatedStorage"):WaitForChild("rEvents")
	local event = events:WaitForChild("bossChestOpenedEvent", 15)
	if event and event:IsA("RemoteEvent") then runtime:Connect(event.OnClientEvent, tabs.boss.observeWebhookRewards) end
end)

runtime:Spawn(function()
	while runtime.Alive do
		tabs.boss.processWebhook()
		task.wait(0.5)
	end
end)

tabs.boss.AutoFarmSwitch = tabs.boss:AddSwitch("Auto Farm Boss", function(state)
	if state and tabs.boss.Halloween and tabs.boss.Halloween.Data.Running then
		tabs.boss.Halloween.AutoFarmSwitch:Set(false)
	end
	tabs.boss.Data.Running = state
	tabs.boss.Data.Generation += 1
	tabs.boss.runtime.generation = tabs.boss.Data.Generation
	if not state then
		tabs.boss.Data.Preparation = nil
		tabs.boss.Data.Phase = "Waiting"
		tabs.boss.StatusLabel.Text = "Status: Disabled"
		tabs.boss.resumeTraining()
		return
	end

	runtime:Spawn(function(generation, wasFighting, model, health, maxHealth, hitbox, selected)
		while tabs.boss.Data.Running and tabs.boss.Data.Generation == generation do
			pcall(function()
				model, health, maxHealth, hitbox = tabs.boss.findActiveBoss()
				selected = model and tabs.boss.shouldFarmBoss(model)
				if model and not selected then
					if wasFighting or tabs.boss.Data.Preparation then
						tabs.boss.Data.Preparation = nil
						wasFighting = false
						tabs.boss.resumeTraining()
					end
					tabs.boss.Data.Phase = "Waiting"
					tabs.boss.StatusLabel.Text = "Status: Skipping " .. (workspace:GetAttribute("BossDisplayName") or model.Name)
				elseif model then
					if wasFighting and tabs.boss.needsRetraining(tabs.boss) then wasFighting = false end
					if not wasFighting then
						if not tabs.boss.prepareForBoss(tabs.boss) then return end
						wasFighting = true
						tabs.boss.Data.Phase = "Fighting"
						tabs.boss.Data.AttackSequence = nil
						tabs.boss.Data.EvadeUntil = 0
						tabs.boss.Data.DodgeStomps = false
						tabs.boss.pauseTraining()
					end
					if not tabs.boss.Data.Running or tabs.boss.Data.Generation ~= generation then return end
					if tabs.boss.needsRetraining(tabs.boss) then return end
					if lp.player.Character
						and lp.player.Character:FindFirstChildOfClass("Humanoid")
						and lp.player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
						tabs.boss.StatusLabel.Text = "Status: Fighting"
						tabs.boss.attack(tabs.boss, model, health, maxHealth, hitbox)
					else
						tabs.boss.StatusLabel.Text = "Status: Waiting for Respawn"
					end
				elseif wasFighting then
					wasFighting = false
					tabs.boss.Data.Phase = "Collecting"
					pcall(tabs.boss.collectChest, generation)
					if not tabs.boss.Data.Running or tabs.boss.Data.Generation ~= generation then return end
					tabs.boss.BossLabel.Text = "Boss: None"
					tabs.boss.HealthLabel.Text = "Health: 0 / 0"
					if tabs.boss.Data.ContinueTraining then tabs.boss.resumeTraining() end
					tabs.boss.Data.Phase = "Waiting"
					tabs.boss.StatusLabel.Text = "Status: Waiting for Boss"
				else
					if tabs.boss.Data.Preparation then
						tabs.boss.Data.Preparation = nil
						tabs.boss.resumeTraining()
					end
					tabs.boss.StatusLabel.Text = "Status: Waiting for Boss"
				end
			end)
			task.wait(model and selected and 0.03 or 0.25)
		end
	end, tabs.boss.runtime.generation)
end)

tabs.boss:AddLabel("")

tabs.boss:AddHeading("Halloween Boss Farming:")
tabs.boss.Halloween = {
	runtime = {},
	BossLabelPrefix = "Halloween Boss: ",
	StatusLabel = tabs.boss:AddLabel("Status: Waiting for Halloween Boss"),
	BossLabel = tabs.boss:AddLabel("Halloween Boss: None"),
	HealthLabel = tabs.boss:AddLabel("Health: 0 / 0"),
	NextBossLabel = tabs.boss:AddLabel("Next Halloween Boss: Waiting for spawn"),
	Data = {
		Running = false,
		Generation = 0,
		Phase = "Waiting",
		PunchInterval = 0.3,
		LastPunch = 0,
		AttackSequence = nil,
		EvadeUntil = 0,
		EvadeDistance = 230,
		PunchBehindDistance = 45,
		StompHealthThreshold = 0.35,
		DodgeStomps = false,
		Bosses = {
			GrimReaper = "Grim Reaper",
			FrankenBrute = "Frankenbrute",
			PumpkinTitan = "Pumpkin Titan",
			ScarecrowColossus = "Scarecrow Colossus"
		},
		BossOrder = {"GrimReaper", "FrankenBrute", "PumpkinTitan", "ScarecrowColossus"},
		BossByDisplayName = {},
		SelectedBosses = {},
		Target = nil
	}
}

tabs.boss.Halloween.getBossDisplayName = function(model)
	return tabs.boss.Halloween.Data.Bosses[model:GetAttribute("BossId") or model.Name] or model.Name
end

tabs.boss.Halloween.getBossHealth = function(health, model)
	return tonumber(model:GetAttribute("Health")) or 0
end

tabs.boss.Halloween.getBossMaxHealth = function(maxHealth, model)
	return tonumber(model:GetAttribute("MaxHealth")) or 0
end

tabs.boss.Halloween.SelectedBossesLabel = tabs.boss:AddLabel("Targeted Halloween Bosses: All")
tabs.boss.Halloween.updateSelectedBossesLabel = function(selectedNames)
	selectedNames = {}
	for _, bossId in ipairs(tabs.boss.Halloween.Data.BossOrder) do
		if tabs.boss.Halloween.Data.SelectedBosses[bossId] then
			table.insert(selectedNames, tabs.boss.Halloween.Data.Bosses[bossId])
		end
	end
	tabs.boss.Halloween.SelectedBossesLabel.Text = "Targeted Halloween Bosses: "
		.. (#selectedNames > 0 and table.concat(selectedNames, ", ") or "None")
end

tabs.boss.Halloween.BossDropdown = tabs.boss:AddDropdown("Target specific Halloween Bosses", function(displayName, bossId)
	bossId = tabs.boss.Halloween.Data.BossByDisplayName[displayName]
	if not bossId then return end
	tabs.boss.Halloween.Data.SelectedBosses[bossId] = not tabs.boss.Halloween.Data.SelectedBosses[bossId]
	tabs.boss.Halloween.updateSelectedBossesLabel()
end)
for _, bossId in ipairs(tabs.boss.Halloween.Data.BossOrder) do
	tabs.boss.Halloween.Data.BossByDisplayName[tabs.boss.Halloween.Data.Bosses[bossId]] = bossId
	tabs.boss.Halloween.Data.SelectedBosses[bossId] = true
	tabs.boss.Halloween.BossDropdown:Add(tabs.boss.Halloween.Data.Bosses[bossId])
end
tabs.boss.Halloween.updateSelectedBossesLabel()

tabs.boss.Halloween.shouldFarmBoss = function(model)
	return tabs.boss.Halloween.Data.SelectedBosses[model:GetAttribute("BossId") or model.Name] == true
end

tabs.boss.Halloween.findActiveBoss = function(selectedOnly, model, hitbox, candidateHitbox, character, root, distance, closestDistance)
	character = lp.player.Character
	root = character and character:FindFirstChild("HumanoidRootPart")
	closestDistance = math.huge
	for _, candidate in ipairs(services.collectionservice:GetTagged("HalloweenBoss")) do
		if candidate:IsA("Model") and candidate:IsDescendantOf(workspace)
			and tabs.boss.Halloween.getBossHealth(nil, candidate) > 0
			and (not selectedOnly or tabs.boss.Halloween.shouldFarmBoss(candidate)) then
			candidateHitbox = candidate:FindFirstChild("BossDamageHitbox", true)
				or candidate.PrimaryPart or candidate:FindFirstChild("HumanoidRootPart")
			if candidateHitbox and candidateHitbox:IsA("BasePart") then
				if selectedOnly and candidate == tabs.boss.Halloween.Data.Target then
					return candidate, nil, nil, candidateHitbox
				end
				distance = root and (root.Position - candidateHitbox.Position).Magnitude or 0
				if not model or distance < closestDistance then
					model, hitbox, closestDistance = candidate, candidateHitbox, distance
				end
			end
		end
	end
	return model, nil, nil, hitbox
end

runtime:Spawn(function(model)
	while true do
		model = tabs.boss.Halloween.Data.Target
		if not model or not model.Parent or tabs.boss.Halloween.getBossHealth(nil, model) <= 0 then
			model = tabs.boss.Halloween.findActiveBoss()
		end
		if model then
			tabs.boss.Halloween.BossLabel.Text = "Halloween Boss: " .. tabs.boss.Halloween.getBossDisplayName(model)
			tabs.boss.Halloween.HealthLabel.Text = "Health: " .. formatCurrentStat(tabs.boss.Halloween.getBossHealth(nil, model))
				.. " / " .. formatCurrentStat(tabs.boss.Halloween.getBossMaxHealth(nil, model))
			tabs.boss.Halloween.NextBossLabel.Text = "Next Halloween Boss: Current boss active"
		else
			tabs.boss.Halloween.BossLabel.Text = "Halloween Boss: None"
			tabs.boss.Halloween.HealthLabel.Text = "Health: 0 / 0"
			tabs.boss.Halloween.NextBossLabel.Text = "Next Halloween Boss: Waiting for spawn"
		end
		task.wait(0.25)
	end
end)

tabs.boss.Halloween.AutoFarmSwitch = tabs.boss:AddSwitch("Auto Farm Halloween Boss", function(state)
	if state and tabs.boss.Data.Running then tabs.boss.AutoFarmSwitch:Set(false) end
	tabs.boss.Halloween.Data.Running = state
	tabs.boss.Halloween.Data.Generation += 1
	if not state then
		tabs.boss.Halloween.Data.Preparation = nil
		tabs.boss.Halloween.Data.Target = nil
		tabs.boss.Halloween.Data.Phase = "Waiting"
		tabs.boss.Halloween.StatusLabel.Text = "Status: Disabled"
		tabs.boss.resumeTraining()
		return
	end

	runtime:Spawn(function(generation, wasFighting, model, health, maxHealth, hitbox)
		while tabs.boss.Halloween.Data.Running and tabs.boss.Halloween.Data.Generation == generation do
			pcall(function()
				model, health, maxHealth, hitbox = tabs.boss.Halloween.findActiveBoss(true)
				if model then
					if wasFighting and tabs.boss.needsRetraining(tabs.boss.Halloween) then wasFighting = false end
					if not wasFighting then
						if not tabs.boss.prepareForBoss(tabs.boss.Halloween) then return end
						wasFighting = true
						tabs.boss.pauseTraining()
					end
					if not tabs.boss.Halloween.Data.Running or tabs.boss.Halloween.Data.Generation ~= generation then return end
					if tabs.boss.needsRetraining(tabs.boss.Halloween) then return end
					if tabs.boss.Halloween.Data.Target ~= model then
						tabs.boss.Halloween.Data.Target = model
						tabs.boss.Halloween.Data.AttackSequence = nil
						tabs.boss.Halloween.Data.EvadeUntil = 0
						tabs.boss.Halloween.Data.DodgeStomps = false
					end
					tabs.boss.Halloween.Data.Phase = "Fighting"
					if lp.player.Character
						and lp.player.Character:FindFirstChildOfClass("Humanoid")
						and lp.player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
						tabs.boss.Halloween.StatusLabel.Text = "Status: Fighting"
						tabs.boss.attack(tabs.boss.Halloween, model, health, maxHealth, hitbox)
					else
						tabs.boss.Halloween.StatusLabel.Text = "Status: Waiting for Respawn"
					end
				else
					tabs.boss.Halloween.Data.Target = nil
					tabs.boss.Halloween.Data.Phase = "Waiting"
					if tabs.boss.Halloween.Data.Preparation then
						tabs.boss.Halloween.Data.Preparation = nil
						tabs.boss.resumeTraining()
					elseif wasFighting then
						tabs.boss.resumeTraining()
					end
					wasFighting = false
					tabs.boss.Halloween.StatusLabel.Text = "Status: Waiting for Halloween Boss"
				end
			end)
			task.wait(model and 0.03 or 0.25)
		end
	end, tabs.boss.Halloween.Data.Generation)
end)

tabs.other:AddHeading("Boosts:")


tabs.other.eggsowned = tabs.other:AddLabel("Protein Eggs: 0")
tabs.other.eggsowned.TextSize = 14
tabs.other.shakesowned = tabs.other:AddLabel("Tropical Shakes: 0")
tabs.other.shakesowned.TextSize = 14

tabs.other.autoEgg = false
tabs.other.autoShake = false
tabs.other.autoSpinWheel = false
tabs.other.eggUsedThisCycle = false

runtime:Spawn(function()
    while true do
        tabs.other.proteinEggCount = 0
        tabs.other.tropicalShakeCount = 0
        tabs.other.backpack = lp.player:FindFirstChild("Backpack")
        if tabs.other.backpack then
            for _, item in ipairs(tabs.other.backpack:GetChildren()) do
                if item.Name == "Protein Egg" then
                    tabs.other.proteinEggCount = tabs.other.proteinEggCount + 1
                elseif item.Name == "Tropical Shake" then
                    tabs.other.tropicalShakeCount = tabs.other.tropicalShakeCount + 1
                end
            end
        end
        tabs.other.eggsowned.Text = "Protein Eggs: " .. tabs.other.proteinEggCount
        tabs.other.shakesowned.Text = "Tropical Shakes: " .. tabs.other.tropicalShakeCount
        task.wait(1)
    end
end)


tabs.other.x2str = tabs.other:AddLabel("x2 Strength: 00:00")
tabs.other.x2str.TextSize = 14
tabs.other.x125dur = tabs.other:AddLabel("x1.25 Durability: 00:00")
tabs.other.x125dur.TextSize = 14

function formatTime(seconds)
    return string.format("%dd %dh %dm %ds", math.floor(seconds / 86400), math.floor((seconds % 86400) / 3600), math.floor((seconds % 3600) / 60), seconds % 60)
end

runtime:Spawn(function()
    while true do
        tabs.other.boostTimersFolder = lp.player:FindFirstChild("boostTimersFolder")
        tabs.other.boost = tabs.other.boostTimersFolder and tabs.other.boostTimersFolder:FindFirstChild("Protein Egg")
        tabs.other.seconds = (tabs.other.boost and tabs.other.boost:IsA("IntValue")) and tabs.other.boost.Value or 0
        tabs.other.x2str.Text = "x2 Strength: " .. formatTime(tabs.other.seconds)
        local shakeBoost = tabs.other.boostTimersFolder and tabs.other.boostTimersFolder:FindFirstChild("Tropical Shake")
        local shakeSeconds = (shakeBoost and shakeBoost:IsA("IntValue")) and shakeBoost.Value or 0
        tabs.other.x125dur.Text = "x1.25 Durability: " .. formatTime(shakeSeconds)
        task.wait(0.5)
    end
end)

function eatEgg()
    tabs.other.character = lp.player.Character
    tabs.other.backpack = lp.player:FindFirstChild("Backpack")
    tabs.other.tool = (tabs.other.character and tabs.other.character:FindFirstChild("Protein Egg")) or (tabs.other.backpack and tabs.other.backpack:FindFirstChild("Protein Egg"))
    if tabs.other.tool then
        for _ = 1, 10 do
            services.muscleEvent:FireServer("proteinEgg", tabs.other.tool)
        end
    end
end

runtime:Spawn(function()
    while true do
        if tabs.other.autoEgg then
            eatEgg()
            task.wait(0.5)
        else
            task.wait(1)
        end
    end
end)

tabs.other:AddSwitch("Eat Eggs", function(state)
    tabs.other.autoEgg = state
    if state then
        eatEgg()
    end
end)

function eatShake()
    tabs.other.character = lp.player.Character
    tabs.other.backpack = lp.player:FindFirstChild("Backpack")
    tabs.other.tool = (tabs.other.character and tabs.other.character:FindFirstChild("Tropical Shake")) or (tabs.other.backpack and tabs.other.backpack:FindFirstChild("Tropical Shake"))
    if tabs.other.tool then
    for _ = 1, 10 do
        services.muscleEvent:FireServer("tropicalShake", tabs.other.tool)
    end
    end
end

runtime:Spawn(function()
    while true do
        if tabs.other.autoShake then
            eatShake()
            task.wait(0.5)
        else
            task.wait(1)
        end
    end
end)

tabs.other:AddSwitch("Eat Shakes", function(state)
    tabs.other.autoShake = state
    if state then
        eatShake()
    end
end)



tabs.other.boostItemList = {
    "Tropical Shake",
    "Energy Shake",
    "Protein Bar",
    "TOUGH Bar",
    "Protein Shake",
    "ULTRA Shake",
    "Energy Bar",
}

tabs.other.boostActions = {
    ["Tropical Shake"] = "tropicalShake",
    ["Energy Shake"] = "energyShake",
    ["Protein Bar"] = "proteinBar",
    ["TOUGH Bar"] = "toughBar",
    ["Protein Shake"] = "proteinShake",
    ["ULTRA Shake"] = "ultraShake",
    ["Energy Bar"] = "energyBar",
}

tabs.other.eatAllBoostsRunning = false

runtime:Spawn(function()
    while true do
        if tabs.other.eatAllBoostsRunning then
            tabs.other.boostItemIndex = 1
            while tabs.other.boostItemIndex <= #tabs.other.boostItemList do
                tabs.other.boostItemName = tabs.other.boostItemList[tabs.other.boostItemIndex]
                tabs.other.character = lp.player.Character
                tabs.other.backpack = lp.player:FindFirstChild("Backpack")
                tabs.other.boostTool = (tabs.other.character and tabs.other.character:FindFirstChild(tabs.other.boostItemName))
                    or (tabs.other.backpack and tabs.other.backpack:FindFirstChild(tabs.other.boostItemName))

                if tabs.other.boostTool then
                    tabs.other.boostUseIndex = 1
                    while tabs.other.boostUseIndex <= 10 do
                        services.muscleEvent:FireServer(tabs.other.boostActions[tabs.other.boostItemName], tabs.other.boostTool)
                        tabs.other.boostUseIndex = tabs.other.boostUseIndex + 1
                    end
                end

                tabs.other.boostItemIndex = tabs.other.boostItemIndex + 1
            end

            task.wait(0.1)
        else
            task.wait(1)
        end
    end
end)

tabs.other:AddSwitch("Eat All Boosts (Expect Lag)", function(state)
    tabs.other.eatAllBoostsRunning = state
end):Set(false)

tabs.other:AddHeading("Misc:")

tabs.other.spinFortuneWheel = function()
    tabs.other.spinResult = table.pack(pcall(function()
        return game:GetService("ReplicatedStorage").rEvents.openFortuneWheelRemote:InvokeServer(
            "openFortuneWheel",
            "Fortune Wheel"
        )
    end))
end

tabs.other:AddSwitch("Spin Fortune Wheel", function(bool)
    _G.AutoSpinWheel = bool

    if bool then
        runtime:Spawn(function()
            tabs.other.rspin = game:GetService("ReplicatedStorage").rEvents.openFortuneWheelRemote
            tabs.other.chances = game:GetService("ReplicatedStorage").shared.catalogs.fortuneWheelChances["Fortune Wheel"]

            while _G.AutoSpinWheel do
                tabs.other.rspin:InvokeServer("openFortuneWheel", tabs.other.chances)
                task.wait(1)
            end
        end)
    end
end)

tabs.other:AddHeading("Visual:")

tabs.other.VisibilitySettings = {
    {Name = "Show Pets", GuiName = "MyPetsBase", Enabled = false},
    {Name = "Show Other Pets", GuiName = "OtherPets", Enabled = false},
    {Name = "Show PopUps", GuiName = "PopUps", Enabled = false}
}

tabs.other.syncVisibilitySetting = function(setting, success, connections)
    if not setting.OnText or not setting.OnText.Parent or not setting.Button or not setting.Button.Parent
        or setting.Pending or setting.OnText.Visible == setting.Enabled then return end
    if type(firesignal) ~= "function" or type(getconnections) ~= "function" then return end
    for _, button in ipairs({setting.Button, setting.Button:FindFirstChild(setting.OnText.Visible and "OnButton" or "OffButton")}) do
        for _, eventName in ipairs({"MouseButton1Click", "Activated"}) do
            success, connections = pcall(getconnections, button[eventName])
            if success and type(connections) == "table" then
                for _, connection in ipairs(connections) do
                    if connection.Enabled ~= false then
                        setting.Pending = true
                        if pcall(firesignal, button[eventName]) then return end
                        setting.Pending = false
                    end
                end
            end
        end
    end
end

tabs.other.bindVisibilitySetting = function(setting, node, onText, button)
    node = lp.player
    for _, childName in ipairs({"PlayerGui", "gameGui", "settingsNewMenu", "Content", "ListLayout", "ScrollingFrame", setting.GuiName}) do
        node = node:WaitForChild(childName, 10)
        if not node then return end
    end
    onText = node:WaitForChild("OnText", 10)
    button = node:WaitForChild("Switch", 10)
    if not onText or not button then return end
    if setting.OnText ~= onText or setting.Button ~= button then
        if setting.Connection then setting.Connection:Disconnect() end
        setting.OnText = onText
        setting.Button = button
        setting.Pending = false
        setting.Connection = runtime:Connect(onText:GetPropertyChangedSignal("Visible"), function()
            setting.Pending = false
            runtime:Defer(tabs.other.syncVisibilitySetting, setting)
        end)
    end
    tabs.other.syncVisibilitySetting(setting)
end

for _, setting in ipairs(tabs.other.VisibilitySettings) do
    setting.Switch = tabs.other:AddSwitch(setting.Name, function(state)
        setting.Enabled = state
        tabs.other.syncVisibilitySetting(setting)
    end)
    setting.Switch:Set(false)
    runtime:Spawn(tabs.other.bindVisibilitySetting, setting)
end
runtime:Connect(lp.player.CharacterAdded, function()
    for _, setting in ipairs(tabs.other.VisibilitySettings) do
        runtime:Spawn(tabs.other.bindVisibilitySetting, setting)
    end
end)

tabs.other.HideNameSwitch = tabs.other:AddSwitch("Hide Name", function(state)
    tabs.other.RedactConfig.RedactName = state
    tabs.other.applyNameVisibility()
    tabs.other.saveRedactConfig()
end)
tabs.other.HideNameSwitch:Set(tabs.other.RedactConfig.RedactName)

tabs.other.RedactStatsSwitch = tabs.other:AddSwitch("Hide Stats", function(state)
    tabs.other.redactStats = state
    tabs.other.RedactConfig.RedactStats = state
    tabs.other.applyStatsVisibility()
    tabs.other.saveRedactConfig()
    tabs.rebirths.updateStats()
    tabs.strength.updateStats()
    tabs.strength2.updateStats()
end)
tabs.other.RedactStatsSwitch:Set(tabs.other.RedactConfig.RedactStats)

runtime:Connect(lp.player.CharacterAdded, function()
    runtime:Defer(tabs.other.applyStatsVisibility)
    tabs.other.applyNameVisibility()
end)

tabs.other:AddButton("Anti Lag (for bad devices)", function()
    tabs.other.playerGui = lp.player:WaitForChild("PlayerGui")

    for _, gui in pairs(tabs.other.playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name ~= "imgui" then
            gui:Destroy()
        end
    end

    tabs.other.darkenSky = function()
        for _, v in pairs(services.lighting:GetChildren()) do
            if v:IsA("Sky") then
                v:Destroy()
            end
        end

        tabs.other.darkSky = Instance.new("Sky")
        tabs.other.darkSky.Name = "DarkSky"
        tabs.other.darkSky.SkyboxBk = "rbxassetid://0"
        tabs.other.darkSky.SkyboxDn = "rbxassetid://0"
        tabs.other.darkSky.SkyboxFt = "rbxassetid://0"
        tabs.other.darkSky.SkyboxLf = "rbxassetid://0"
        tabs.other.darkSky.SkyboxRt = "rbxassetid://0"
        tabs.other.darkSky.SkyboxUp = "rbxassetid://0"
        tabs.other.darkSky.Parent = services.lighting

        services.lighting.Brightness = 0
        services.lighting.ClockTime = 0
        services.lighting.TimeOfDay = "00:00:00"
        services.lighting.OutdoorAmbient = Color3.new(0, 0, 0)
        services.lighting.Ambient = Color3.new(0, 0, 0)
        services.lighting.FogColor = Color3.new(0, 0, 0)
        services.lighting.FogEnd = 100

        runtime:Spawn(function()
            while true do
                wait(5)
                if not services.lighting:FindFirstChild("DarkSky") then
                    tabs.other.darkSky:Clone().Parent = services.lighting
                end
                services.lighting.Brightness = 0
                services.lighting.ClockTime = 0
                services.lighting.OutdoorAmbient = Color3.new(0, 0, 0)
                services.lighting.Ambient = Color3.new(0, 0, 0)
                services.lighting.FogColor = Color3.new(0, 0, 0)
                services.lighting.FogEnd = 100
            end
        end)
    end

    tabs.other.removeParticleEffects = function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") then
                obj:Destroy()
            end
        end
    end

    tabs.other.removeLightSources = function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                obj:Destroy()
            end
        end
    end

for _, v in pairs(services.lighting:GetChildren()) do
    if v:IsA("Atmosphere") then
        v:Destroy()
    end
end

    workspace.Terrain.WaterColor = Color3.new(0, 0, 0)
    workspace.Terrain.WaterReflectance = 0
    workspace.Terrain.WaterTransparency = 1

    services.lighting.GlobalShadows = false
    services.lighting.EnvironmentDiffuseScale = 0
    services.lighting.EnvironmentSpecularScale = 0
    services.lighting.ExposureCompensation = -10

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Color = Color3.new(0, 0, 0)
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
        end
    end

    tabs.other.removeParticleEffects()
    tabs.other.removeLightSources()
    tabs.other.darkenSky()
    services.replicatedstorage.shared.assets.ui.strengthFrame:Destroy()
    services.replicatedstorage.shared.assets.ui.durabilityFrame:Destroy()
end)

tabs.other.tpE = function(position)
    tabs.other.character = lp.player.Character or lp.player.CharacterAdded:Wait()
    tabs.other.hrp = tabs.other.character:WaitForChild("HumanoidRootPart")
    tabs.other.hrp.CFrame = CFrame.new(position)
    tabs.other.hrp.AssemblyLinearVelocity = Vector3.zero
    tabs.other.hrp.AssemblyAngularVelocity = Vector3.zero
    task.wait(0.4)
    services.virtualinputmanager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.1)
    services.virtualinputmanager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

tabs.other:AddHeading("Weights:")

tabs.other:AddSwitch("Halloween Lift", function(state)
    if not state then return end
    tabs.other.tpE(Vector3.new(5760.389, 83.206, 6117.898))
end)

tabs.other:AddSwitch("Halloween Squat", function(state)
    if not state then return end
    tabs.other.tpE(Vector3.new(4803.357, 83.791, 5827.032))
end)



tabs.other:AddButton("Equip Rep Pets", function()
    equipBestFarmingPets()
end)

tabs.other:AddHeading("Reconnect:")

tabs.other.Reconnect = {Enabled = false, Disconnected = false, NextAttemptAt = 0, Attempting = false}

local function getReconnectUrl(text)
    text = tostring(text or ""):match("^%s*(.-)%s*$")
    if text == "" then return nil end
    local host, path = text:match("^https?://([^/]+)(/.*)$")
    if host ~= "roblox.com" and host ~= "www.roblox.com" then return nil, "Enter a Roblox private server link" end
    local code = path:match("[?&]privateServerLinkCode=([%w_-]+)")
    if code then
        local placeId = tonumber(path:match("^/games/(%d+)"))
        if placeId ~= game.PlaceId then return nil, "The private server link must be for this game" end
        return "roblox://placeId=" .. tostring(placeId) .. "&linkCode=" .. code
    end
    code = path:match("[?&]code=([%w_-]+)")
    local linkType = path:match("[?&]type=([^&#]+)")
    if path:match("^/share%?") and code and linkType == "Server" then
        return "roblox://navigation/share_links?code=" .. code .. "&type=Server"
    end
    return nil, "Enter a Roblox private server link"
end

local function reconnectDue(state, now)
    if not state.Enabled or not state.Disconnected or state.Attempting or now < state.NextAttemptAt then return false end
    state.NextAttemptAt = now + 30
    return true
end

tabs.other.ReconnectLink = tabs.other:AddTextBox("Private Server Link (optional)", function() end, {clear = false})

tabs.other.checkDisconnect = function()
    if not tabs.other.Reconnect.Enabled or tabs.other.Reconnect.Disconnected then return end
    local success, disconnected = pcall(function()
        local guiService = game:GetService("GuiService")
        local code = guiService:GetErrorCode()
        return guiService:GetErrorMessage() ~= "" and (
            guiService:GetErrorType() == Enum.ConnectionError.DisconnectErrors
            or (code >= 256 and code < 512)
            or code >= 1024
        )
    end)
    if not success then
        local readable, visible = pcall(function()
            local promptGui = game:GetService("CoreGui"):FindFirstChild("RobloxPromptGui")
            local overlay = promptGui and promptGui:FindFirstChild("promptOverlay")
            local prompt = overlay and overlay:FindFirstChild("ErrorPrompt")
            return prompt and prompt.Visible and prompt:FindFirstChild("ErrorFrame", true) ~= nil
        end)
        success, disconnected = readable, visible
    end
    if success and disconnected then
        tabs.other.Reconnect.Disconnected = true
        tabs.other.Reconnect.NextAttemptAt = os.clock() + 30
    end
end

tabs.other.ReconnectSwitch = tabs.other:AddSwitch("Auto Reconnect (if you disconnect)", function(state)
    tabs.other.Reconnect.Enabled = state
    tabs.other.Reconnect.Disconnected = false
    tabs.other.Reconnect.NextAttemptAt = 0
    if state then tabs.other.checkDisconnect() end
end)
tabs.other.ReconnectSwitch:SetConfigKey("Other.AutoReconnect")

tabs.other:AddLabel("Continueing Farming will require a Config Profile AND the Script in Autoexecute Folder. It does NOT work on every Executor!")

tabs.other.farmingloadstring = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/silencedevs/SilenceScripts/main/Scripts/MuscleLegends/Farming.luau", true))()'

tabs.other:AddButton("Copy direct Farming loadstring", function()
	if type(setclipboard) == "function" and pcall(setclipboard, tabs.other.farmingloadstring) then
		pcall(function() game.StarterGui:SetCore("SendNotification", {Title = "Loadstring copied!", Text = "Save it to autoexecute now", Duration = 3}) end)
	else
		pcall(function() game.StarterGui:SetCore("SendNotification", {Title = "Error!", Text = "Clipboard not Supported.", Duration = 3}) end)
	end
end)

pcall(function()
    runtime:Connect(game:GetService("GuiService").ErrorMessageChanged, tabs.other.checkDisconnect)
end)

tabs.other.attemptReconnect = function()
    local url, validationError = getReconnectUrl(tabs.other.ReconnectLink.Text)
    if validationError then error(validationError, 0) end
    if url then
        local supported, openUrl = pcall(function() return game:GetService("LinkingService").OpenUrl end)
        if not supported or type(openUrl) ~= "function" then
            error("This executor does not support opening private server links", 0)
        end
        openUrl(game:GetService("LinkingService"), url)
        return
    end
    local teleportService = game:GetService("TeleportService")
    local success = pcall(function() teleportService:TeleportReconnect() end)
    if success then
        pcall(function() teleportService:UnblockAsync() end)
    else
        teleportService:Teleport(game.PlaceId, lp.player)
    end
end

runtime:Spawn(function()
    while runtime.Alive do
        tabs.other.checkDisconnect()
        if reconnectDue(tabs.other.Reconnect, os.clock()) then
            tabs.other.Reconnect.Attempting = true
            local success, message = pcall(tabs.other.attemptReconnect)
            tabs.other.Reconnect.Attempting = false
            if not success then
                pcall(function()
                    services.startergui:SetCore("SendNotification", {
                        Title = "Reconnect failed",
                        Text = tostring(message) .. " | Retrying in 30 seconds",
                        Duration = 5
                    })
                end)
            end
        end
        task.wait(1)
    end
end)

tabs.info:AddLabel("Made by xyzhenrik")
tabs.info:AddLabel("Any issues? Create a Ticket on Discord")
tabs.info:AddLabel("Official Discord: discord.gg/9eFf93Kg8D")
tabs.info:AddButton("Copy Invite", function()
	if type(setclipboard) == "function" and pcall(setclipboard, "https://discord.gg/9eFf93Kg8D") then
		pcall(function() game.StarterGui:SetCore("SendNotification", {Title = "Link Copied!", Text = "You can continue to Discord now.", Duration = 3}) end)
	else
		pcall(function() game.StarterGui:SetCore("SendNotification", {Title = "Error!", Text = "Clipboard not Supported.", Duration = 3}) end)
	end
end)
tabs.info:AddLabel("")
tabs.info:AddHeading("Contributors:")
tabs.info:AddLabel("- Henrik @xyzhenrik")
tabs.info:AddLabel("- Muki @mukimagdich")
tabs.info:AddLabel("")
tabs.info:AddLabel("Silence is Open-Source!")
tabs.info:AddLabel("")
tabs.info.VersionLabel = tabs.info:AddLabel("Muscle Legends [V4.3.0]")
tabs.info.VersionLabel.TextSize = 20
tabs.info.VersionLabel.Font = Enum.Font.Arcade


runtime:Defer(function()
    services.configManager:LoadStartup()
end)

end
