local nativeTask = task
local runtime = {Alive = true, Threads = {}, Connections = {}, Cleanups = {}}

function runtime:Schedule(schedule, callback, ...)
    if not self.Alive then return end
    local arguments = table.pack(...)
    local thread
    thread = coroutine.create(function()
        if not self.Alive then self.Threads[thread] = nil return end
        local results = table.pack(pcall(callback, table.unpack(arguments, 1, arguments.n)))
        self.Threads[thread] = nil
        if not results[1] then error(results[2], 0) end
        return table.unpack(results, 2, results.n)
    end)
    self.Threads[thread] = true
    schedule(thread)
    return thread
end

function runtime:Spawn(callback, ...)
    return self:Schedule(nativeTask.spawn, callback, ...)
end

function runtime:Defer(callback, ...)
    return self:Schedule(nativeTask.defer, callback, ...)
end

function runtime:Delay(seconds, callback, ...)
    return self:Schedule(function(thread) nativeTask.delay(seconds, thread) end, callback, ...)
end

function runtime:Connect(signal, callback)
    if not self.Alive then return end
    local connection = signal:Connect(function(...)
        self:Spawn(callback, ...)
    end)
    self.Connections[connection] = true
    return connection
end

function runtime:AddCleanup(callback)
    if self.Alive then
        table.insert(self.Cleanups, callback)
    else
        pcall(callback)
    end
    return callback
end

function runtime:Destroy()
    if not self.Alive then return end
    self.Alive = false
    for connection in pairs(self.Connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(self.Connections)
    local current = coroutine.running()
    for thread in pairs(self.Threads) do
        if thread ~= current and coroutine.status(thread) ~= "dead" then
            pcall(nativeTask.cancel, thread)
        end
    end
    table.clear(self.Threads)
    for index = #self.Cleanups, 1, -1 do
        pcall(self.Cleanups[index])
    end
    table.clear(self.Cleanups)
    if _G.SilenceRuntime == self then _G.SilenceRuntime = nil end
end

if _G.SilenceRuntime then
    _G.SilenceRuntime:Destroy()
end
_G.SilenceRuntime = runtime
runtime.Threads[coroutine.running()] = true

local isSolara = false
do
	local success, executorName = pcall(function()
		local identify = identifyexecutor
		if type(identify) ~= "function" then identify = getexecutorname end
		if type(identify) == "function" then return identify() end
	end)
	isSolara = success and type(executorName) == "string" and string.lower(executorName) == "solara"
end

local ui_options = {
	main_color = Color3.fromRGB(41, 74, 122),
	min_size = Vector2.new(400, 300),
	toggle_key = Enum.KeyCode.RightShift,
	can_resize = true,
}

do
	local function destroyImguiIn(parent)
		if parent and parent.FindFirstChild then
			local existing = parent:FindFirstChild("imgui")
			if existing then
				pcall(function() existing:Destroy() end)
			end
		end
	end

	if not isSolara then
		pcall(function() destroyImguiIn(game:GetService("CoreGui")) end)
	end

	local Players = game:GetService("Players")
	if Players and Players.LocalPlayer then
		destroyImguiIn(Players.LocalPlayer:FindFirstChild("PlayerGui"))
	end

	if not isSolara and type(gethui) == "function" then
		local ok, gh = pcall(gethui)
		if ok and gh then
			destroyImguiIn(gh)
		end
	end

	if not isSolara then
		for _,v in pairs(game:GetDescendants()) do
			if v.Name == "imgui" and v:IsA("ScreenGui") then
				pcall(function() v:Destroy() end)
			end
		end
	end
end

local imgui = Instance.new("ScreenGui")
runtime:AddCleanup(function() imgui:Destroy() end)
runtime:Connect(imgui.Destroying, function() runtime:Destroy() end)
local prefabs = Instance.new("Frame")
local label = Instance.new("TextLabel")
local window = Instance.new("ImageLabel")
local resizer = Instance.new("Frame")
local bar = Instance.new("Frame")
local toggle = Instance.new("ImageButton")
local base = Instance.new("ImageLabel")
local top = Instance.new("ImageLabel")
local tabs = Instance.new("Frame")
local titleLabel = Instance.new("TextLabel")
local tabSelection = Instance.new("ImageLabel")
local tabButtons = Instance.new("ScrollingFrame")
local uiListLayout = Instance.new("UIListLayout")
local frame = Instance.new("Frame")
local tab = Instance.new("ScrollingFrame")
local uiListLayout2 = Instance.new("UIListLayout")
local textBox = Instance.new("TextBox")
local textBoxRoundify4px = Instance.new("ImageLabel")
local slider = Instance.new("ImageLabel")
local sliderTitle = Instance.new("TextLabel")
local indicator = Instance.new("ImageLabel")
local sliderValue = Instance.new("TextLabel")
local textLabel = Instance.new("TextLabel")
local textLabel2 = Instance.new("TextLabel")
local circle = Instance.new("ImageLabel")
local uiListLayout3 = Instance.new("UIListLayout")
local dropdown = Instance.new("TextButton")
local dropdownIndicator = Instance.new("ImageLabel")
local dropdownBox = Instance.new("ImageButton")
local dropdownObjects = Instance.new("ScrollingFrame")
local uiListLayout4 = Instance.new("UIListLayout")
local textButtonRoundify4px = Instance.new("ImageLabel")
local tabButton = Instance.new("TextButton")
local textButtonRoundify4px_2 = Instance.new("ImageLabel")
local folder = Instance.new("ImageLabel")
local button = Instance.new("TextButton")
local textButtonRoundify4px_3 = Instance.new("ImageLabel")
local toggle2 = Instance.new("ImageLabel")
local objects2 = Instance.new("Frame")
local uiListLayout5 = Instance.new("UIListLayout")
local horizontalAlignment = Instance.new("Frame")
local uiListLayout6 = Instance.new("UIListLayout")
local console = Instance.new("ImageLabel")
local scrollingFrame = Instance.new("ScrollingFrame")
local source = Instance.new("TextBox")
local commentsLabel = Instance.new("TextLabel")
local globalsLabel = Instance.new("TextLabel")
local keywordsLabel = Instance.new("TextLabel")
local remoteHighlight = Instance.new("TextLabel")
local stringsLabel = Instance.new("TextLabel")
local tokensLabel = Instance.new("TextLabel")
local numbersLabel = Instance.new("TextLabel")
local infoLabel = Instance.new("TextLabel")
local linesLabel = Instance.new("TextLabel")
local colorPicker = Instance.new("ImageLabel")
local palette = Instance.new("ImageLabel")
local indicator3 = Instance.new("ImageLabel")
local sample = Instance.new("ImageLabel")
local saturation = Instance.new("ImageLabel")
local indicator4 = Instance.new("Frame")
local switchButton = Instance.new("TextButton")
local textButtonRoundify4px_4 = Instance.new("ImageLabel")
local title3Label = Instance.new("TextLabel")
local button2 = Instance.new("TextButton")
local textButtonRoundify4px_5 = Instance.new("ImageLabel")
local dropdownButton = Instance.new("TextButton")
local keybind = Instance.new("ImageLabel")
local title4Label = Instance.new("TextLabel")
local inputButton = Instance.new("TextButton")
local inputRoundify4px = Instance.new("ImageLabel")
local windowsFrame = Instance.new("Frame")
local cloneref = type(cloneref) == "function" and cloneref or function(...) return ... end
local CoreGui
if not isSolara then pcall(function() CoreGui = game:GetService("CoreGui") end) end
if CoreGui then pcall(function() CoreGui = cloneref(CoreGui) end) end

imgui.Name = "imgui"
imgui.ResetOnSpawn = false
if not isSolara and type(gethui) == "function" then
	pcall(function() imgui.Parent = gethui() end)
end
if not imgui.Parent and CoreGui then pcall(function() imgui.Parent = CoreGui end) end
if not imgui.Parent then imgui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end
prefabs.Name = "Prefabs"
prefabs.Parent = imgui
prefabs.BackgroundColor3 = Color3.new(1, 1, 1)
prefabs.Size = UDim2.new(0, 100, 0, 100)
prefabs.Visible = false

label.Name = "Label"
label.Parent = prefabs
label.BackgroundColor3 = Color3.new(1, 1, 1)
label.BackgroundTransparency = 1
label.Size = UDim2.new(0, 200, 0, 20)
label.Font = Enum.Font.GothamSemibold
label.Text = "Hello, world 123"
label.TextColor3 = Color3.new(1, 1, 1)
label.TextSize = 14
label.TextXAlignment = Enum.TextXAlignment.Left

window.Name = "Window"
window.Parent = prefabs
window.Active = true
window.BackgroundColor3 = Color3.new(1, 1, 1)
window.BackgroundTransparency = 1
window.ClipsDescendants = true
window.Position = UDim2.new(0, 20, 0, 20)
window.Selectable = true
window.Size = UDim2.new(0, 200, 0, 200)
window.Image = "rbxassetid://2851926732"
window.ImageColor3 = Color3.new(0.0823529, 0.0862745, 0.0901961)
window.ScaleType = Enum.ScaleType.Slice
window.SliceCenter = Rect.new(12, 12, 12, 12)

resizer.Name = "Resizer"
resizer.Parent = window
resizer.Active = true
resizer.BackgroundColor3 = Color3.new(1, 1, 1)
resizer.BackgroundTransparency = 1
resizer.BorderSizePixel = 0
resizer.Position = UDim2.new(1, -20, 1, -20)
resizer.Size = UDim2.new(0, 20, 0, 20)

bar.Name = "Bar"
bar.Parent = window
bar.BackgroundColor3 = Color3.new(0.160784, 0.290196, 0.478431)
bar.BorderSizePixel = 0
bar.Position = UDim2.new(0, 0, 0, 5)
bar.Size = UDim2.new(1, 0, 0, 15)

toggle.Name = "Toggle"
toggle.Parent = bar
toggle.BackgroundColor3 = Color3.new(1, 1, 1)
toggle.BackgroundTransparency = 1
toggle.Position = UDim2.new(0, 5, 0, -2)
toggle.Rotation = 0
toggle.Size = UDim2.new(0, 20, 0, 20)
toggle.ZIndex = 2
toggle.Image = "https://www.roblox.com/Thumbs/Asset.ashx?width=420&height=420&assetId=136171704230647"

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0.5, 0)
toggleCorner.Parent = toggle

base.Name = "Base"
base.Parent = bar
base.BackgroundColor3 = Color3.new(0.160784, 0.290196, 0.478431)
base.BorderSizePixel = 0
base.Position = UDim2.new(0, 0, 0.800000012, 0)
base.Size = UDim2.new(1, 0, 0, 10)
base.Image = "rbxassetid://2851926732"
base.ImageColor3 = Color3.new(0.160784, 0.290196, 0.478431)
base.ScaleType = Enum.ScaleType.Slice
base.SliceCenter = Rect.new(12, 12, 12, 12)

top.Name = "Top"
top.Parent = bar
top.BackgroundColor3 = Color3.new(1, 1, 1)
top.BackgroundTransparency = 1
top.Position = UDim2.new(0, 0, 0, -5)
top.Size = UDim2.new(1, 0, 0, 10)
top.Image = "rbxassetid://2851926732"
top.ImageColor3 = Color3.new(0.160784, 0.290196, 0.478431)
top.ScaleType = Enum.ScaleType.Slice
top.SliceCenter = Rect.new(12, 12, 12, 12)

tabs.Name = "Tabs"
tabs.Parent = window
tabs.BackgroundColor3 = Color3.new(1, 1, 1)
tabs.BackgroundTransparency = 1
tabs.Position = UDim2.new(0, 15, 0, 60)
tabs.Size = UDim2.new(1, -30, 1, -60)

titleLabel.Name = "Title"
titleLabel.Parent = window
titleLabel.BackgroundColor3 = Color3.new(1, 1, 1)
titleLabel.BackgroundTransparency = 1
titleLabel.Position = UDim2.new(0, 30, 0, 3)
titleLabel.Size = UDim2.new(0, 200, 0, 20)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "Gamer Time"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

tabSelection.Name = "TabSelection"
tabSelection.Parent = window
tabSelection.BackgroundColor3 = Color3.new(1, 1, 1)
tabSelection.BackgroundTransparency = 1
tabSelection.Position = UDim2.new(0, 15, 0, 30)
tabSelection.Size = UDim2.new(1, -30, 0, 25)
tabSelection.Visible = false
tabSelection.Image = "rbxassetid://2851929490"
tabSelection.ImageColor3 = Color3.new(0.145098, 0.14902, 0.156863)
tabSelection.ScaleType = Enum.ScaleType.Slice
tabSelection.SliceCenter = Rect.new(4, 4, 4, 4)

tabButtons.Name = "TabButtons"
tabButtons.Parent = tabSelection
tabButtons.BackgroundColor3 = Color3.new(1, 1, 1)
tabButtons.BackgroundTransparency = 1
tabButtons.Size = UDim2.new(1, 0, 1, 0)
tabButtons.BorderSizePixel = 0
tabButtons.CanvasSize = UDim2.new()
tabButtons.ScrollingDirection = Enum.ScrollingDirection.X
tabButtons.ScrollBarThickness = 4
tabButtons.ScrollBarImageColor3 = Color3.fromRGB(145, 150, 155)
tabButtons.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
tabButtons.ClipsDescendants = true

uiListLayout.Parent = tabButtons
uiListLayout.FillDirection = Enum.FillDirection.Horizontal
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Padding = UDim.new(0, 2)

frame.Parent = tabSelection
frame.BackgroundColor3 = Color3.new(0.12549, 0.227451, 0.372549)
frame.BorderColor3 = Color3.new(0.105882, 0.164706, 0.207843)
frame.BorderSizePixel = 0
frame.Position = UDim2.new(0, 0, 1, 0)
frame.Size = UDim2.new(1, 0, 0, 2)

tab.Name = "Tab"
tab.Parent = prefabs
tab.BackgroundColor3 = Color3.new(1, 1, 1)
tab.BackgroundTransparency = 1
tab.Size = UDim2.new(1, 0, 1, 0)
tab.Visible = false
tab.BorderSizePixel = 0
tab.CanvasSize = UDim2.new()
tab.ScrollingDirection = Enum.ScrollingDirection.Y
tab.ScrollBarThickness = 5
tab.ScrollBarImageColor3 = Color3.fromRGB(145, 150, 155)
tab.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
tab.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
tab.ClipsDescendants = true

uiListLayout2.Parent = tab
uiListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout2.Padding = UDim.new(0, 5)

textBox.Parent = prefabs
textBox.BackgroundColor3 = Color3.new(1, 1, 1)
textBox.BackgroundTransparency = 1
textBox.BorderSizePixel = 0
textBox.Size = UDim2.new(1, 0, 0, 20)
textBox.ZIndex = 2
textBox.Font = Enum.Font.GothamSemibold
textBox.PlaceholderColor3 = Color3.new(0.698039, 0.698039, 0.698039)
textBox.PlaceholderText = "Input Text"
textBox.Text = ""
textBox.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
textBox.TextSize = 14

textBoxRoundify4px.Name = "TextBox_Roundify_4px"
textBoxRoundify4px.Parent = textBox
textBoxRoundify4px.BackgroundColor3 = Color3.new(1, 1, 1)
textBoxRoundify4px.BackgroundTransparency = 1
textBoxRoundify4px.Size = UDim2.new(1, 0, 1, 0)
textBoxRoundify4px.Image = "rbxassetid://2851929490"
textBoxRoundify4px.ImageColor3 = Color3.new(0.203922, 0.207843, 0.219608)
textBoxRoundify4px.ScaleType = Enum.ScaleType.Slice
textBoxRoundify4px.SliceCenter = Rect.new(4, 4, 4, 4)

slider.Name = "Slider"
slider.Parent = prefabs
slider.BackgroundColor3 = Color3.new(1, 1, 1)
slider.BackgroundTransparency = 1
slider.Position = UDim2.new(0, 0, 0.178571433, 0)
slider.Size = UDim2.new(1, 0, 0, 20)
slider.Image = "rbxassetid://2851929490"
slider.ImageColor3 = Color3.new(0.145098, 0.14902, 0.156863)
slider.ScaleType = Enum.ScaleType.Slice
slider.SliceCenter = Rect.new(4, 4, 4, 4)

sliderTitle.Name = "Title"
sliderTitle.Parent = slider
sliderTitle.BackgroundColor3 = Color3.new(1, 1, 1)
sliderTitle.BackgroundTransparency = 1
sliderTitle.Position = UDim2.new(0.5, 0, 0.5, -10)
sliderTitle.Size = UDim2.new(0, 0, 0, 20)
sliderTitle.ZIndex = 2
sliderTitle.Font = Enum.Font.GothamSemibold
sliderTitle.Text = "Slider"
sliderTitle.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
sliderTitle.TextSize = 14

indicator.Name = "Indicator"
indicator.Parent = slider
indicator.BackgroundColor3 = Color3.new(1, 1, 1)
indicator.BackgroundTransparency = 1
indicator.Size = UDim2.new(0, 0, 0, 20)
indicator.Image = "rbxassetid://2851929490"
indicator.ImageColor3 = Color3.new(0.254902, 0.262745, 0.278431)
indicator.ScaleType = Enum.ScaleType.Slice
indicator.SliceCenter = Rect.new(4, 4, 4, 4)

sliderValue.Name = "Value"
sliderValue.Parent = slider
sliderValue.BackgroundColor3 = Color3.new(1, 1, 1)
sliderValue.BackgroundTransparency = 1
sliderValue.Position = UDim2.new(1, -55, 0.5, -10)
sliderValue.Size = UDim2.new(0, 50, 0, 20)
sliderValue.Font = Enum.Font.GothamSemibold
sliderValue.Text = "0%"
sliderValue.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
sliderValue.TextSize = 14

textLabel.Parent = slider
textLabel.BackgroundColor3 = Color3.new(1, 1, 1)
textLabel.BackgroundTransparency = 1
textLabel.Position = UDim2.new(1, -20, -0.75, 0)
textLabel.Size = UDim2.new(0, 26, 0, 50)
textLabel.Font = Enum.Font.GothamSemibold
textLabel.Text = "]"
textLabel.TextColor3 = Color3.new(0.627451, 0.627451, 0.627451)
textLabel.TextSize = 14

textLabel2.Parent = slider
textLabel2.BackgroundColor3 = Color3.new(1, 1, 1)
textLabel2.BackgroundTransparency = 1
textLabel2.Position = UDim2.new(1, -65, -0.75, 0)
textLabel2.Size = UDim2.new(0, 26, 0, 50)
textLabel2.Font = Enum.Font.GothamSemibold
textLabel2.Text = "["
textLabel2.TextColor3 = Color3.new(0.627451, 0.627451, 0.627451)
textLabel2.TextSize = 14

circle.Name = "Circle"
circle.Parent = prefabs
circle.BackgroundColor3 = Color3.new(1, 1, 1)
circle.BackgroundTransparency = 1
circle.Image = "rbxassetid://266543268"
circle.ImageTransparency = 0.5

uiListLayout3.Parent = prefabs
uiListLayout3.FillDirection = Enum.FillDirection.Horizontal
uiListLayout3.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout3.Padding = UDim.new(0, 20)

dropdown.Name = "Dropdown"
dropdown.Parent = prefabs
dropdown.BackgroundColor3 = Color3.new(1, 1, 1)
dropdown.BackgroundTransparency = 1
dropdown.BorderSizePixel = 0
dropdown.Position = UDim2.new(0, 0, 0.0833333284, 0)
dropdown.Size = UDim2.new(1, 0, 0, 20)
dropdown.ZIndex = 2
dropdown.Font = Enum.Font.GothamSemibold
dropdown.Text = "      Dropdown"
dropdown.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
dropdown.TextSize = 14
dropdown.TextXAlignment = Enum.TextXAlignment.Left

dropdownIndicator.Name = "Indicator"
dropdownIndicator.Parent = dropdown
dropdownIndicator.BackgroundColor3 = Color3.new(1, 1, 1)
dropdownIndicator.BackgroundTransparency = 1
dropdownIndicator.Position = UDim2.new(1, -25, 0.100000001, 0)
dropdownIndicator.Rotation = -90
dropdownIndicator.Size = UDim2.new(0, 15, 0, 15)
dropdownIndicator.ZIndex = 2
dropdownIndicator.Image = "https://www.roblox.com/Thumbs/Asset.ashx?width=420&height=420&assetId=4744658743"

dropdownBox.Name = "Box"
dropdownBox.Parent = dropdown
dropdownBox.BackgroundColor3 = Color3.new(1, 1, 1)
dropdownBox.BackgroundTransparency = 1
dropdownBox.Position = UDim2.new(0, 0, 0, 25)
dropdownBox.Size = UDim2.new(1, 0, 0, 150)
dropdownBox.ZIndex = 3
dropdownBox.Image = "rbxassetid://2851929490"
dropdownBox.ImageColor3 = Color3.new(0.129412, 0.133333, 0.141176)
dropdownBox.ScaleType = Enum.ScaleType.Slice
dropdownBox.SliceCenter = Rect.new(4, 4, 4, 4)

dropdownObjects.Name = "Objects"
dropdownObjects.Parent = dropdownBox
dropdownObjects.BackgroundColor3 = Color3.new(1, 1, 1)
dropdownObjects.BackgroundTransparency = 1
dropdownObjects.BorderSizePixel = 0
dropdownObjects.Size = UDim2.new(1, 0, 1, 0)
dropdownObjects.ZIndex = 3
dropdownObjects.CanvasSize = UDim2.new(0, 0, 0, 0)
dropdownObjects.ScrollBarThickness = 8

uiListLayout4.Parent = dropdownObjects
uiListLayout4.SortOrder = Enum.SortOrder.LayoutOrder

textButtonRoundify4px.Name = "TextButton_Roundify_4px"
textButtonRoundify4px.Parent = dropdown
textButtonRoundify4px.BackgroundColor3 = Color3.new(1, 1, 1)
textButtonRoundify4px.BackgroundTransparency = 1
textButtonRoundify4px.Size = UDim2.new(1, 0, 1, 0)
textButtonRoundify4px.Image = "rbxassetid://2851929490"
textButtonRoundify4px.ImageColor3 = Color3.new(0.203922, 0.207843, 0.219608)
textButtonRoundify4px.ScaleType = Enum.ScaleType.Slice
textButtonRoundify4px.SliceCenter = Rect.new(4, 4, 4, 4)

tabButton.Name = "TabButton"
tabButton.Parent = prefabs
tabButton.BackgroundColor3 = Color3.new(0.160784, 0.290196, 0.478431)
tabButton.BackgroundTransparency = 1
tabButton.BorderSizePixel = 0
tabButton.Position = UDim2.new(0.185185179, 0, 0, 0)
tabButton.Size = UDim2.new(0, 71, 0, 20)
tabButton.ZIndex = 2
tabButton.Font = Enum.Font.GothamSemibold
tabButton.Text = "Test tab"
tabButton.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
tabButton.TextSize = 14

textButtonRoundify4px_2.Name = "TextButton_Roundify_4px"
textButtonRoundify4px_2.Parent = tabButton
textButtonRoundify4px_2.BackgroundColor3 = Color3.new(1, 1, 1)
textButtonRoundify4px_2.BackgroundTransparency = 1
textButtonRoundify4px_2.Size = UDim2.new(1, 0, 1, 0)
textButtonRoundify4px_2.Image = "rbxassetid://2851929490"
textButtonRoundify4px_2.ImageColor3 = Color3.new(0.203922, 0.207843, 0.219608)
textButtonRoundify4px_2.ScaleType = Enum.ScaleType.Slice
textButtonRoundify4px_2.SliceCenter = Rect.new(4, 4, 4, 4)

folder.Name = "Folder"
folder.Parent = prefabs
folder.BackgroundColor3 = Color3.new(1, 1, 1)
folder.BackgroundTransparency = 1
folder.Position = UDim2.new(0, 0, 0, 50)
folder.Size = UDim2.new(1, 0, 0, 20)
folder.Image = "rbxassetid://2851929490"
folder.ImageColor3 = Color3.new(0.0823529, 0.0862745, 0.0901961)
folder.ScaleType = Enum.ScaleType.Slice
folder.SliceCenter = Rect.new(4, 4, 4, 4)

button.Name = "Button"
button.Parent = folder
button.BackgroundColor3 = Color3.new(0.160784, 0.290196, 0.478431)
button.BackgroundTransparency = 1
button.BorderSizePixel = 0
button.Size = UDim2.new(1, 0, 0, 20)
button.ZIndex = 2
button.Font = Enum.Font.GothamSemibold
button.Text = "      Folder"
button.TextColor3 = Color3.new(1, 1, 1)
button.TextSize = 14
button.TextXAlignment = Enum.TextXAlignment.Left

textButtonRoundify4px_3.Name = "TextButton_Roundify_4px"
textButtonRoundify4px_3.Parent = button
textButtonRoundify4px_3.BackgroundColor3 = Color3.new(1, 1, 1)
textButtonRoundify4px_3.BackgroundTransparency = 1
textButtonRoundify4px_3.Size = UDim2.new(1, 0, 1, 0)
textButtonRoundify4px_3.Image = "rbxassetid://2851929490"
textButtonRoundify4px_3.ImageColor3 = Color3.new(0.160784, 0.290196, 0.478431)
textButtonRoundify4px_3.ScaleType = Enum.ScaleType.Slice
textButtonRoundify4px_3.SliceCenter = Rect.new(4, 4, 4, 4)

	toggle2.Name = "Toggle"
	toggle2.Parent = button
	toggle2.BackgroundColor3 = Color3.new(1, 1, 1)
	toggle2.BackgroundTransparency = 1
	toggle2.Position = UDim2.new(0, 5, 0, 0)
	toggle2.Size = UDim2.new(0, 20, 0, 20)
	toggle2.Image = "https://www.roblox.com/Thumbs/Asset.ashx?width=420&height=420&assetId=4731371541"

	local toggle2Corner = Instance.new("UICorner")
	toggle2Corner.CornerRadius = UDim.new(0.5, 0)
	toggle2Corner.Parent = toggle2

objects2.Name = "Objects"
objects2.Parent = folder
objects2.BackgroundColor3 = Color3.new(1, 1, 1)
objects2.BackgroundTransparency = 1
objects2.Position = UDim2.new(0, 10, 0, 25)
objects2.Size = UDim2.new(1, -10, 1, -25)
objects2.Visible = false

uiListLayout5.Parent = objects2
uiListLayout5.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout5.Padding = UDim.new(0, 5)

horizontalAlignment.Name = "HorizontalAlignment"
horizontalAlignment.Parent = prefabs
horizontalAlignment.BackgroundColor3 = Color3.new(1, 1, 1)
horizontalAlignment.BackgroundTransparency = 1
horizontalAlignment.Size = UDim2.new(1, 0, 0, 20)

uiListLayout6.Parent = horizontalAlignment
uiListLayout6.FillDirection = Enum.FillDirection.Horizontal
uiListLayout6.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout6.Padding = UDim.new(0, 5)

console.Name = "Console"
console.Parent = prefabs
console.BackgroundColor3 = Color3.new(1, 1, 1)
console.BackgroundTransparency = 1
console.Size = UDim2.new(1, 0, 0, 200)
console.Image = "rbxassetid://2851928141"
console.ImageColor3 = Color3.new(0.129412, 0.133333, 0.141176)
console.ScaleType = Enum.ScaleType.Slice
console.SliceCenter = Rect.new(8, 8, 8, 8)

scrollingFrame.Parent = console
scrollingFrame.BackgroundColor3 = Color3.new(1, 1, 1)
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.BorderSizePixel = 0
scrollingFrame.Size = UDim2.new(1, 0, 1, 1)
scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollingFrame.ScrollBarThickness = 4

source.Name = "Source"
source.Parent = scrollingFrame
source.BackgroundColor3 = Color3.new(1, 1, 1)
source.BackgroundTransparency = 1
source.Position = UDim2.new(0, 40, 0, 0)
source.Size = UDim2.new(1, -40, 0, 10000)
source.ZIndex = 3
source.ClearTextOnFocus = false
source.Font = Enum.Font.Code
source.MultiLine = true
source.PlaceholderColor3 = Color3.new(0.8, 0.8, 0.8)
source.Text = ""
source.TextColor3 = Color3.new(1, 1, 1)
source.TextSize = 15
source.TextStrokeColor3 = Color3.new(1, 1, 1)
source.TextWrapped = true
source.TextXAlignment = Enum.TextXAlignment.Left
source.TextYAlignment = Enum.TextYAlignment.Top

commentsLabel.Name = "Comments"
commentsLabel.Parent = source
commentsLabel.BackgroundColor3 = Color3.new(1, 1, 1)
commentsLabel.BackgroundTransparency = 1
commentsLabel.Size = UDim2.new(1, 0, 1, 0)
commentsLabel.ZIndex = 5
commentsLabel.Font = Enum.Font.Code
commentsLabel.Text = ""
commentsLabel.TextColor3 = Color3.new(0.231373, 0.784314, 0.231373)
commentsLabel.TextSize = 15
commentsLabel.TextXAlignment = Enum.TextXAlignment.Left
commentsLabel.TextYAlignment = Enum.TextYAlignment.Top

globalsLabel.Name = "Globals"
globalsLabel.Parent = source
globalsLabel.BackgroundColor3 = Color3.new(1, 1, 1)
globalsLabel.BackgroundTransparency = 1
globalsLabel.Size = UDim2.new(1, 0, 1, 0)
globalsLabel.ZIndex = 5
globalsLabel.Font = Enum.Font.Code
globalsLabel.Text = ""
globalsLabel.TextColor3 = Color3.new(0.517647, 0.839216, 0.968628)
globalsLabel.TextSize = 15
globalsLabel.TextXAlignment = Enum.TextXAlignment.Left
globalsLabel.TextYAlignment = Enum.TextYAlignment.Top

keywordsLabel.Name = "Keywords"
keywordsLabel.Parent = source
keywordsLabel.BackgroundColor3 = Color3.new(1, 1, 1)
keywordsLabel.BackgroundTransparency = 1
keywordsLabel.Size = UDim2.new(1, 0, 1, 0)
keywordsLabel.ZIndex = 5
keywordsLabel.Font = Enum.Font.Code
keywordsLabel.Text = ""
keywordsLabel.TextColor3 = Color3.new(0.972549, 0.427451, 0.486275)
keywordsLabel.TextSize = 15
keywordsLabel.TextXAlignment = Enum.TextXAlignment.Left
keywordsLabel.TextYAlignment = Enum.TextYAlignment.Top

remoteHighlight.Name = "RemoteHighlight"
remoteHighlight.Parent = source
remoteHighlight.BackgroundColor3 = Color3.new(1, 1, 1)
remoteHighlight.BackgroundTransparency = 1
remoteHighlight.Size = UDim2.new(1, 0, 1, 0)
remoteHighlight.ZIndex = 5
remoteHighlight.Font = Enum.Font.Code
remoteHighlight.Text = ""
remoteHighlight.TextColor3 = Color3.new(0, 0.568627, 1)
remoteHighlight.TextSize = 15
remoteHighlight.TextXAlignment = Enum.TextXAlignment.Left
remoteHighlight.TextYAlignment = Enum.TextYAlignment.Top

stringsLabel.Name = "Strings"
stringsLabel.Parent = source
stringsLabel.BackgroundColor3 = Color3.new(1, 1, 1)
stringsLabel.BackgroundTransparency = 1
stringsLabel.Size = UDim2.new(1, 0, 1, 0)
stringsLabel.ZIndex = 5
stringsLabel.Font = Enum.Font.Code
stringsLabel.Text = ""
stringsLabel.TextColor3 = Color3.new(0.678431, 0.945098, 0.584314)
stringsLabel.TextSize = 15
stringsLabel.TextXAlignment = Enum.TextXAlignment.Left
stringsLabel.TextYAlignment = Enum.TextYAlignment.Top

tokensLabel.Name = "Tokens"
tokensLabel.Parent = source
tokensLabel.BackgroundColor3 = Color3.new(1, 1, 1)
tokensLabel.BackgroundTransparency = 1
tokensLabel.Size = UDim2.new(1, 0, 1, 0)
tokensLabel.ZIndex = 5
tokensLabel.Font = Enum.Font.Code
tokensLabel.Text = ""
tokensLabel.TextColor3 = Color3.new(1, 1, 1)
tokensLabel.TextSize = 15
tokensLabel.TextXAlignment = Enum.TextXAlignment.Left
tokensLabel.TextYAlignment = Enum.TextYAlignment.Top

numbersLabel.Name = "Numbers"
numbersLabel.Parent = source
numbersLabel.BackgroundColor3 = Color3.new(1, 1, 1)
numbersLabel.BackgroundTransparency = 1
numbersLabel.Size = UDim2.new(1, 0, 1, 0)
numbersLabel.ZIndex = 4
numbersLabel.Font = Enum.Font.Code
numbersLabel.Text = ""
numbersLabel.TextColor3 = Color3.new(1, 0.776471, 0)
numbersLabel.TextSize = 15
numbersLabel.TextXAlignment = Enum.TextXAlignment.Left
numbersLabel.TextYAlignment = Enum.TextYAlignment.Top

infoLabel.Name = "Info"
infoLabel.Parent = source
infoLabel.BackgroundColor3 = Color3.new(1, 1, 1)
infoLabel.BackgroundTransparency = 1
infoLabel.Size = UDim2.new(1, 0, 1, 0)
infoLabel.ZIndex = 5
infoLabel.Font = Enum.Font.Code
infoLabel.Text = ""
infoLabel.TextColor3 = Color3.new(0, 0.635294, 1)
infoLabel.TextSize = 15
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top

linesLabel.Name = "Lines"
linesLabel.Parent = scrollingFrame
linesLabel.BackgroundColor3 = Color3.new(1, 1, 1)
linesLabel.BackgroundTransparency = 1
linesLabel.BorderSizePixel = 0
linesLabel.Size = UDim2.new(0, 40, 0, 10000)
linesLabel.ZIndex = 4
linesLabel.Font = Enum.Font.Code
linesLabel.Text = "1\n"
linesLabel.TextColor3 = Color3.new(1, 1, 1)
linesLabel.TextSize = 15
linesLabel.TextWrapped = true
linesLabel.TextYAlignment = Enum.TextYAlignment.Top

colorPicker.Name = "ColorPicker"
colorPicker.Parent = prefabs
colorPicker.BackgroundColor3 = Color3.new(1, 1, 1)
colorPicker.BackgroundTransparency = 1
colorPicker.Size = UDim2.new(0, 180, 0, 110)
colorPicker.Image = "rbxassetid://2851929490"
colorPicker.ImageColor3 = Color3.new(0.203922, 0.207843, 0.219608)
colorPicker.ScaleType = Enum.ScaleType.Slice
colorPicker.SliceCenter = Rect.new(4, 4, 4, 4)

palette.Name = "Palette"
palette.Parent = colorPicker
palette.BackgroundColor3 = Color3.new(1, 1, 1)
palette.BackgroundTransparency = 1
palette.Position = UDim2.new(0.0500000007, 0, 0.0500000007, 0)
palette.Size = UDim2.new(0, 100, 0, 100)
palette.Image = "rbxassetid://698052001"
palette.ScaleType = Enum.ScaleType.Slice
palette.SliceCenter = Rect.new(4, 4, 4, 4)

indicator3.Name = "Indicator"
indicator3.Parent = palette
indicator3.BackgroundColor3 = Color3.new(1, 1, 1)
indicator3.BackgroundTransparency = 1
indicator3.Size = UDim2.new(0, 5, 0, 5)
indicator3.ZIndex = 2
indicator3.Image = "rbxassetid://2851926732"
indicator3.ImageColor3 = Color3.new(0, 0, 0)
indicator3.ScaleType = Enum.ScaleType.Slice
indicator3.SliceCenter = Rect.new(12, 12, 12, 12)

sample.Name = "Sample"
sample.Parent = colorPicker
sample.BackgroundColor3 = Color3.new(1, 1, 1)
sample.BackgroundTransparency = 1
sample.Position = UDim2.new(0.800000012, 0, 0.0500000007, 0)
sample.Size = UDim2.new(0, 25, 0, 25)
sample.Image = "rbxassetid://2851929490"
sample.ScaleType = Enum.ScaleType.Slice
sample.SliceCenter = Rect.new(4, 4, 4, 4)

saturation.Name = "Saturation"
saturation.Parent = colorPicker
saturation.BackgroundColor3 = Color3.new(1, 1, 1)
saturation.Position = UDim2.new(0.649999976, 0, 0.0500000007, 0)
saturation.Size = UDim2.new(0, 15, 0, 100)
saturation.Image = "rbxassetid://3641079629"

indicator4.Name = "Indicator"
indicator4.Parent = saturation
indicator4.BackgroundColor3 = Color3.new(1, 1, 1)
indicator4.BorderSizePixel = 0
indicator4.Size = UDim2.new(0, 20, 0, 2)
indicator4.ZIndex = 2

switchButton.Name = "Switch"
switchButton.Parent = prefabs
switchButton.BackgroundColor3 = Color3.new(1, 1, 1)
switchButton.BackgroundTransparency = 1
switchButton.BorderSizePixel = 0
switchButton.Position = UDim2.new(0.229411766, 0, 0.20714286, 0)
switchButton.Size = UDim2.new(0, 20, 0, 20)
switchButton.ZIndex = 2
switchButton.Font = Enum.Font.GothamSemibold
switchButton.Text = ""
switchButton.TextColor3 = Color3.new(1, 1, 1)
switchButton.TextSize = 18

textButtonRoundify4px_4.Name = "TextButton_Roundify_4px"
textButtonRoundify4px_4.Parent = switchButton
textButtonRoundify4px_4.BackgroundColor3 = Color3.new(1, 1, 1)
textButtonRoundify4px_4.BackgroundTransparency = 1
textButtonRoundify4px_4.Size = UDim2.new(1, 0, 1, 0)
textButtonRoundify4px_4.Image = "rbxassetid://2851929490"
textButtonRoundify4px_4.ImageColor3 = Color3.new(0.160784, 0.290196, 0.478431)
textButtonRoundify4px_4.ImageTransparency = 0.5
textButtonRoundify4px_4.ScaleType = Enum.ScaleType.Slice
textButtonRoundify4px_4.SliceCenter = Rect.new(4, 4, 4, 4)

title3Label.Name = "Title"
title3Label.Parent = switchButton
title3Label.BackgroundColor3 = Color3.new(1, 1, 1)
title3Label.BackgroundTransparency = 1
title3Label.Position = UDim2.new(1.20000005, 0, 0, 0)
title3Label.Size = UDim2.new(0, 20, 0, 20)
title3Label.Font = Enum.Font.GothamBold
title3Label.Text = "Switch"
title3Label.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
title3Label.TextSize = 14
title3Label.TextXAlignment = Enum.TextXAlignment.Left

button2.Name = "Button"
button2.Parent = prefabs
button2.BackgroundColor3 = Color3.new(0.160784, 0.290196, 0.478431)
button2.BackgroundTransparency = 1
button2.BorderSizePixel = 0
button2.Size = UDim2.new(0, 91, 0, 20)
button2.ZIndex = 2
button2.Font = Enum.Font.GothamSemibold
button2.TextColor3 = Color3.new(1, 1, 1)
button2.TextSize = 14

textButtonRoundify4px_5.Name = "TextButton_Roundify_4px"
textButtonRoundify4px_5.Parent = button2
textButtonRoundify4px_5.BackgroundColor3 = Color3.new(1, 1, 1)
textButtonRoundify4px_5.BackgroundTransparency = 1
textButtonRoundify4px_5.Size = UDim2.new(1, 0, 1, 0)
textButtonRoundify4px_5.Image = "rbxassetid://2851929490"
textButtonRoundify4px_5.ImageColor3 = Color3.new(0.160784, 0.290196, 0.478431)
textButtonRoundify4px_5.ScaleType = Enum.ScaleType.Slice
textButtonRoundify4px_5.SliceCenter = Rect.new(4, 4, 4, 4)

dropdownButton.Name = "DropdownButton"
dropdownButton.Parent = prefabs
dropdownButton.BackgroundColor3 = Color3.new(0.129412, 0.133333, 0.141176)
dropdownButton.BorderSizePixel = 0
dropdownButton.Size = UDim2.new(1, 0, 0, 20)
dropdownButton.ZIndex = 3
dropdownButton.Font = Enum.Font.GothamSemibold
dropdownButton.Text = "      Button"
dropdownButton.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
dropdownButton.TextSize = 14
dropdownButton.TextXAlignment = Enum.TextXAlignment.Left

keybind.Name = "Keybind"
keybind.Parent = prefabs
keybind.BackgroundColor3 = Color3.new(1, 1, 1)
keybind.BackgroundTransparency = 1
keybind.Size = UDim2.new(0, 200, 0, 20)
keybind.Image = "rbxassetid://2851929490"
keybind.ImageColor3 = Color3.new(0.203922, 0.207843, 0.219608)
keybind.ScaleType = Enum.ScaleType.Slice
keybind.SliceCenter = Rect.new(4, 4, 4, 4)

title4Label.Name = "Title"
title4Label.Parent = keybind
title4Label.BackgroundColor3 = Color3.new(1, 1, 1)
title4Label.BackgroundTransparency = 1
title4Label.Size = UDim2.new(0, 0, 1, 0)
title4Label.Font = Enum.Font.GothamBold
title4Label.Text = "Keybind"
title4Label.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
title4Label.TextSize = 14
title4Label.TextXAlignment = Enum.TextXAlignment.Left

inputButton.Name = "Input"
inputButton.Parent = keybind
inputButton.BackgroundColor3 = Color3.new(1, 1, 1)
inputButton.BackgroundTransparency = 1
inputButton.BorderSizePixel = 0
inputButton.Position = UDim2.new(1, -85, 0, 2)
inputButton.Size = UDim2.new(0, 80, 1, -4)
inputButton.ZIndex = 2
inputButton.Font = Enum.Font.GothamSemibold
inputButton.Text = "RShift"
inputButton.TextColor3 = Color3.new(0.784314, 0.784314, 0.784314)
inputButton.TextSize = 12
inputButton.TextWrapped = true

inputRoundify4px.Name = "Input_Roundify_4px"
inputRoundify4px.Parent = inputButton
inputRoundify4px.BackgroundColor3 = Color3.new(1, 1, 1)
inputRoundify4px.BackgroundTransparency = 1
inputRoundify4px.Size = UDim2.new(1, 0, 1, 0)
inputRoundify4px.Image = "rbxassetid://2851929490"
inputRoundify4px.ImageColor3 = Color3.new(0.290196, 0.294118, 0.313726)
inputRoundify4px.ScaleType = Enum.ScaleType.Slice
inputRoundify4px.SliceCenter = Rect.new(4, 4, 4, 4)

windowsFrame.Name = "Windows"
windowsFrame.Parent = imgui
windowsFrame.BackgroundColor3 = Color3.new(1, 1, 1)
windowsFrame.BackgroundTransparency = 1
windowsFrame.Position = UDim2.new(0, 20, 0, 20)
windowsFrame.Size = UDim2.new(1, 20, 1, -20)

local root = imgui

local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("RunService")
local ps = game:GetService("Players")

local p = ps.LocalPlayer
local mouse = p:GetMouse()

local Prefabs = prefabs
local Windows = windowsFrame

local checks = {
	["binding"] = false,
}

runtime:Connect(UIS.InputBegan, function(input, gameProcessed)
	if input.KeyCode == ((typeof(ui_options.toggle_key) == "EnumItem") and ui_options.toggle_key or Enum.KeyCode.RightShift) then
		if root then
			if not checks.binding and root.Enabled ~= nil then
				root.Enabled = not root.Enabled
			end
		end
	end
end)

local function Resize(part, new, _delay)
	_delay = _delay or 0.5
	local tweenInfo = TweenInfo.new(_delay, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(part, tweenInfo, new)
	tween:Play()
end

local function rgbtohsv(r, g, b)
	r, g, b = r / 255, g / 255, b / 255
	local max, min = math.max(r, g, b), math.min(r, g, b)
	local h, s, v
	v = max

	local d = max - min
	if max == 0 then
		s = 0
	else
		s = d / max
	end

	if max == min then
		h = 0
	else
		if max == r then
			h = (g - b) / d
			if g < b then
				h = h + 6
			end
		elseif max == g then
			h = (b - r) / d + 2
		elseif max == b then
			h = (r - g) / d + 4
		end
		h = h / 6
	end

	return h, s, v
end

local function hasprop(object, prop)
	local a, b = pcall(function()
		return object[tostring(prop)]
	end)
	if a then
		return b
	end
end

local function gNameLen(obj)
	return obj.TextBounds.X + 15
end

local function gMouse()
	return UIS:GetMouseLocation() - game:GetService("GuiService"):GetGuiInset()
end

local function ripple(button, x, y)
	runtime:Spawn(function()
		button.ClipsDescendants = true

		local circle = prefabs:FindFirstChild("Circle"):Clone()

		circle.Parent = button
		circle.ZIndex = 1000

		local new_x = x - circle.AbsolutePosition.X
		local new_y = y - circle.AbsolutePosition.Y
		circle.Position = UDim2.new(0, new_x, 0, new_y)

		local size = 0
		if button.AbsoluteSize.X > button.AbsoluteSize.Y then
			size = button.AbsoluteSize.X * 1.5
		elseif button.AbsoluteSize.X < button.AbsoluteSize.Y then
			size = button.AbsoluteSize.Y * 1.5
		elseif button.AbsoluteSize.X == button.AbsoluteSize.Y then
			size = button.AbsoluteSize.X * 1.5
		end

		circle:TweenSizeAndPosition(UDim2.new(0, size, 0, size), UDim2.new(0.5, -size / 2, 0.5, -size / 2), "Out", "Quad", 0.5, false, nil)
		Resize(circle, {ImageTransparency = 1}, 0.5)

		wait(0.5)
		circle:Destroy()
	end)
end

local windows = 0
local library = {Runtime = runtime}
library.WindowModules = {}
library.WindowInstances = {}
function library:Use(module)
    assert(type(module) == "table" and type(module.Method) == "string" and type(module.Build) == "function", "Invalid library module")
    self.WindowModules[module.Method] = module
    for _, windowData in ipairs(self.WindowInstances) do
        windowData[module.Method] = function(windowSelf, settings) return module:Build(windowSelf, settings) end
    end
    return self
end


function library:Destroy()
    runtime:Destroy()
end

function library:EnableAntiAFK()
	if _G.SilenceAntiAFKConnection then
		_G.SilenceAntiAFKConnection:Disconnect()
	end
	local player = game:GetService("Players").LocalPlayer
	local input = game:GetService("VirtualInputManager")
	local held = false
	_G.SilenceAntiAFKConnection = runtime:Connect(player.Idled, function()
		local success = pcall(function()
			input:SendKeyEvent(true, Enum.KeyCode.Y, false, game)
			held = true
			task.wait(0.05)
			input:SendKeyEvent(false, Enum.KeyCode.Y, false, game)
			held = false
		end)
		if not success then
			pcall(function()
				local virtualUser = game:GetService("VirtualUser")
				virtualUser:CaptureController()
				virtualUser:ClickButton2(Vector2.new())
			end)
		end
	end)
	local connection = _G.SilenceAntiAFKConnection
	runtime:AddCleanup(function()
		if held then
			pcall(function() input:SendKeyEvent(false, Enum.KeyCode.Y, false, game) end)
		end
		if _G.SilenceAntiAFKConnection == connection then _G.SilenceAntiAFKConnection = nil end
	end)
	return _G.SilenceAntiAFKConnection
end

function library:CreatePrivacyRedactor(player, redactorKey)
	local redactor = {
		Enabled = false,
		OriginalText = setmetatable({}, {__mode = "k"}),
	}
	local key = tostring(redactorKey or "Default")
	_G.SilencePrivacyGenerations = _G.SilencePrivacyGenerations or {}
	_G.SilencePrivacyGenerations[key] = (_G.SilencePrivacyGenerations[key] or 0) + 1
	local generation = _G.SilencePrivacyGenerations[key]
    runtime:AddCleanup(function() redactor:SetEnabled(false) end)

	local function replacePlain(text, search, replacement)
		local startPosition = string.find(text, search, 1, true)
		while startPosition do
			text = string.sub(text, 1, startPosition - 1) .. replacement
				.. string.sub(text, startPosition + #search)
			startPosition = string.find(text, search, startPosition + #replacement, true)
		end
		return text
	end

	local function setRedactedText(textObject, redactedText)
		local saved = redactor.OriginalText[textObject]
		if not saved or textObject.Text ~= saved.Redacted then
			saved = {Original = textObject.Text}
			redactor.OriginalText[textObject] = saved
		end
		saved.Redacted = redactedText
		textObject.Text = redactedText
	end

	local function redactName(textObject)
		local original = textObject.Text
		local redacted = replacePlain(original, player.Name, "########")
		if player.DisplayName ~= player.Name then
			redacted = replacePlain(redacted, player.DisplayName, "########")
		end
		if redacted ~= original then
			setRedactedText(textObject, redacted)
			return true
		end
		return false
	end

	local function redactScoreboard()
		local coreGui = game:GetService("CoreGui")
		for _, object in ipairs(coreGui:GetDescendants()) do
			local saved = redactor.OriginalText[object]
			local wasName = saved and (string.find(saved.Original, player.Name, 1, true)
				or string.find(saved.Original, player.DisplayName, 1, true))
			if (object:IsA("TextLabel") or object:IsA("TextButton")) and (redactName(object) or wasName) then
				local row = object.Parent
				if row then
					for _, valueObject in ipairs(row:GetDescendants()) do
						if (valueObject:IsA("TextLabel") or valueObject:IsA("TextButton"))
							and valueObject ~= object and string.find(valueObject.Text, "%d") then
							setRedactedText(valueObject, "####")
						end
					end
				end
			end
		end
	end

	local function redactNametag()
		local character = player.Character
		if not character then return end
		for _, object in ipairs(character:GetDescendants()) do
			if object:IsA("TextLabel") or object:IsA("TextButton") then
				redactName(object)
			end
		end
	end

	function redactor:SetEnabled(enabled)
		self.Enabled = enabled
		if enabled then
			pcall(redactNametag)
			pcall(redactScoreboard)
		else
			for object, saved in pairs(self.OriginalText) do
				if object and object.Parent then
					object.Text = saved.Original
				end
			end
			table.clear(self.OriginalText)
		end
	end

	runtime:Spawn(function()
		while _G.SilencePrivacyGenerations[key] == generation do
			if redactor.Enabled then
				pcall(redactNametag)
				pcall(redactScoreboard)
			end
			task.wait(1)
		end
	end)

	return redactor
end

local function format_windows()
	local ull = prefabs:FindFirstChild("UIListLayout"):Clone()
	ull.Parent = windowsFrame
	local data = {}

	for i,v in pairs(windowsFrame:GetChildren()) do
		if not (v:IsA("UIListLayout")) then
			data[v] = v.AbsolutePosition
		end
	end

	ull:Destroy()

	for i,v in pairs(data) do
		i.Position = UDim2.new(0, v.X, 0, v.Y)
	end
end

function library:FormatWindows()
	format_windows()
end

function library:AddWindow(title, options)
	if not runtime.Alive then return end
	windows = windows + 1
	local dropdown_open = false
	title = tostring(title or "New Window")
	options = (typeof(options) == "table") and options or ui_options
	options.tween_time = 0.1

    local mainColorTargets = setmetatable({}, {__mode = "k"})
    local function bindMainColor(object)
        if not object then return end
        object.ImageColor3 = options.main_color
        mainColorTargets[object] = true
    end

	local Window = prefabs:FindFirstChild("Window"):Clone()
	Window.Parent = windowsFrame
	Window:FindFirstChild("Title").Text = title
	Window.Size = UDim2.new(0, options.min_size.X, 0, options.min_size.Y)
	Window.ZIndex = Window.ZIndex + (windows * 10)

	do
		local Title = Window:FindFirstChild("Title")
		local Bar = Window:FindFirstChild("Bar")
		local Base = Bar:FindFirstChild("Base")
		local Top = Bar:FindFirstChild("Top")
		local SplitFrame = Window:FindFirstChild("TabSelection"):FindFirstChild("Frame")
		local Toggle = Bar:FindFirstChild("Toggle")

        Bar.BackgroundColor3 = options.main_color
        Base.BackgroundColor3 = options.main_color
        bindMainColor(Base)
        bindMainColor(Top)
        SplitFrame.BackgroundColor3 = options.main_color

	end

	local Resizer = Window:WaitForChild("Resizer")
	local Title = Window:FindFirstChild("Title")
	local Bar = Window:FindFirstChild("Bar")
	local Toggle = Bar:FindFirstChild("Toggle")
	local TabSelection = Window:FindFirstChild("TabSelection")
	local Tabs = Window:FindFirstChild("Tabs")
	local window_data = {}
	local minimized = false
	local expandedSize = Window.Size
	local gesture
	local sizeTween
	local sizeVersion = 0
	local contentSurfaces = {}
	local resizeEnabled = options.can_resize ~= false
	Window.ClipsDescendants = false
	Window.Draggable = false
    local windowRadius = 20
    Window.ImageTransparency = 1
    Window.BackgroundColor3 = Window.ImageColor3
    Window.BackgroundTransparency = 0
    local WindowCorner = Instance.new("UICorner")
    WindowCorner.Name = "WindowCorner"
    WindowCorner.CornerRadius = UDim.new(0, windowRadius)
    WindowCorner.Parent = Window

    local HeaderClip = Instance.new("Frame")
    HeaderClip.Name = "HeaderClip"
    HeaderClip.BackgroundTransparency = 1
    HeaderClip.BorderSizePixel = 0
    HeaderClip.Size = UDim2.new(1, 0, 0, 26)
    HeaderClip.ClipsDescendants = true
    HeaderClip.ZIndex = Window.ZIndex
    HeaderClip.Parent = Window
    local HeaderSurface = Instance.new("Frame")
    HeaderSurface.Name = "HeaderSurface"
    HeaderSurface.BackgroundColor3 = options.main_color
    HeaderSurface.BorderSizePixel = 0
    HeaderSurface.Size = UDim2.new(1, 0, 0, 46)
    HeaderSurface.ZIndex = Window.ZIndex
    HeaderSurface.Parent = HeaderClip
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.Name = "HeaderCorner"
    HeaderCorner.CornerRadius = UDim.new(0, windowRadius)
    HeaderCorner.Parent = HeaderSurface
    Bar.BackgroundTransparency = 1
    Bar.Base.BackgroundTransparency = 1
    Bar.Base.ImageTransparency = 1
    Bar.Top.BackgroundTransparency = 1
    Bar.Top.ImageTransparency = 1
    runtime:Connect(Bar:GetPropertyChangedSignal("BackgroundColor3"), function()
        HeaderSurface.BackgroundColor3 = Bar.BackgroundColor3
    end)
	Tabs.Position = UDim2.fromOffset(15, 68)
	Tabs.Size = UDim2.new(1, -30, 1, -82)
	TabSelection.Size = UDim2.new(1, -30, 0, 30)
	TabSelection.Position = UDim2.fromOffset(15, 32)
	Title.Position = UDim2.fromOffset(30, 3)
	Title.Size = UDim2.new(1, -104, 0, 20)
	Title.ZIndex = Window.ZIndex + 4
	Title.Active = true
	Toggle.ZIndex = Window.ZIndex + 5
	Toggle.Position = UDim2.fromOffset(5, -2)

	local function minimumSize()
		local textSize = game:GetService("TextService"):GetTextSize(Title.Text, Title.TextSize,
			Title.Font, Vector2.new(100000, 100000))
		return Vector2.new(math.ceil(textSize.X) + 108, 300)
	end

	local function clampSize(size)
		local minimum = minimumSize()
		return UDim2.fromOffset(math.max(minimum.X, size.X.Offset), math.max(minimum.Y, size.Y.Offset))
	end

    local function applySize(size, animated)
        expandedSize = clampSize(size)
        sizeVersion = sizeVersion + 1
        local version = sizeVersion
        if sizeTween then sizeTween:Cancel() end
        local target = minimized and UDim2.fromOffset(expandedSize.X.Offset, 26) or expandedSize
        local function finish()
            if version ~= sizeVersion then return end
            Window.ClipsDescendants = minimized
            Window.BackgroundTransparency = minimized and 1 or 0
        end
        if animated then
            Window.ClipsDescendants = true
            if not minimized then Window.BackgroundTransparency = 0 end
            sizeTween = TweenService:Create(Window,
                TweenInfo.new(options.tween_time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = target})
            sizeTween:Play()
            runtime:Delay(options.tween_time, finish)
        else
            Window.Size = target
            finish()
        end
    end

    local function endGesture()
        if gesture and gesture.Surface then
            gesture.Surface.ScrollingEnabled = gesture.WasScrollingEnabled
        end
        gesture = nil
    end

	function window_data:Destroy()
		library:Destroy()
	end

	function window_data:SetTitle(new_title)
		if not runtime.Alive then return end
		Title.Text = tostring(new_title or "New Window")
		applySize(expandedSize)
	end

	function window_data:SetSize(size)
		if not runtime.Alive then return end
		applySize(UDim2.fromOffset(size.X, size.Y))
	end

    local function lucideIcon(name, fallback)
        local success, asset = pcall(function()
            if type(getcustomasset) ~= "function" or type(writefile) ~= "function" then return fallback end
            if type(makefolder) == "function" then
                pcall(makefolder, "Silence")
                pcall(makefolder, "Silence/LibraryAssets")
            end
            local path = "Silence/LibraryAssets/lucide-" .. name .. ".png"
            if type(isfile) ~= "function" or not isfile(path) then
                writefile(path, game:HttpGet("https://raw.githubusercontent.com/silencedevs/SilenceScripts/refs/heads/main/libraries/assets/" .. name .. ".png"))
            end
            return getcustomasset(path)
        end)
        return success and asset or fallback
    end
    local lucideMinimize = lucideIcon("minimize-2", "rbxassetid://7733997870")
    local lucideMaximize = lucideIcon("maximize", "rbxassetid://7733992982")
    local lucideX = lucideIcon("x", "rbxassetid://7743878857")

	local function headerButton(name, asset, x)
		local control = Instance.new("TextButton")
		control.Name = name
		control.Text = ""
		control.Font = Enum.Font.GothamSemibold
		control.TextSize = 18
		control.TextColor3 = Color3.fromRGB(255, 255, 255)
		control.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		control.BackgroundTransparency = 1
		control.BorderSizePixel = 0
        control.AutoButtonColor = false
		control.Position = UDim2.new(1, x, 0, -4)
		control.Size = UDim2.fromOffset(24, 24)
		control.ZIndex = Window.ZIndex + 5
		control.Parent = Bar
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = control
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.BackgroundTransparency = 1
        icon.Image = asset
        icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.Position = UDim2.fromScale(0.5, 0.5)
        icon.Size = UDim2.fromOffset(16, 16)
        icon.ZIndex = control.ZIndex + 1
        icon.Parent = control
        local backgroundTween
        local function setHovered(hovered)
            if backgroundTween then backgroundTween:Cancel() end
            local info = TweenInfo.new(hovered and 0.12 or 0.17, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            backgroundTween = TweenService:Create(control, info, {BackgroundTransparency = hovered and 0.82 or 1})
            backgroundTween:Play()
        end
        runtime:Connect(control.MouseEnter, function() setHovered(true) end)
        runtime:Connect(control.MouseLeave, function() setHovered(false) end)
		return control
	end

	local Minimize = headerButton("Minimize", lucideMinimize, -62)
	local Close = headerButton("Close", lucideX, -32)
	local BottomResize = Instance.new("TextButton")
	BottomResize.Name = "BottomResize"
	BottomResize.Text = ""
	BottomResize.BackgroundTransparency = 1
	BottomResize.AnchorPoint = Vector2.new(0.5, 0)
	BottomResize.Position = UDim2.new(0.5, 0, 1, 0)
	BottomResize.Size = UDim2.new(0.36, 0, 0, 22)
	BottomResize.ZIndex = Window.ZIndex + 6
	BottomResize.Parent = Window
	local Grip = Instance.new("Frame")
	Grip.Name = "Grip"
	Grip.BackgroundColor3 = Color3.fromRGB(150, 155, 158)
	Grip.BorderSizePixel = 0
	Grip.AnchorPoint = Vector2.new(0.5, 0.5)
	Grip.Position = UDim2.fromScale(0.5, 0.5)
	Grip.Size = UDim2.new(1, 0, 0, 4)
	Grip.ZIndex = BottomResize.ZIndex
	Grip.Parent = BottomResize
	local GripCorner = Instance.new("UICorner")
	GripCorner.CornerRadius = UDim.new(1, 0)
	GripCorner.Parent = Grip

    Resizer.Size = UDim2.fromOffset(40, 40)
    Resizer.AnchorPoint = Vector2.new(0.5, 0.5)
    Resizer.Position = UDim2.new(1, -8, 1, -8)
    Resizer.ZIndex = Window.ZIndex + 6
    local CornerImage = Instance.new("ImageLabel")
    CornerImage.Name = "WindUIResize"
    CornerImage.BackgroundTransparency = 1
    CornerImage.Image = lucideIcon("windui-resize", "rbxassetid://120997033468887")
    CornerImage.Size = UDim2.fromOffset(120, 120)
    CornerImage.AnchorPoint = Vector2.new(190 / 420, 190 / 420)
    CornerImage.Position = UDim2.new(0.5, -windowRadius, 0.5, -windowRadius)
    CornerImage.ImageColor3 = options.main_color
    CornerImage.ImageTransparency = 0.6
    CornerImage.ZIndex = Resizer.ZIndex
    CornerImage.Parent = Resizer

    BottomResize.Position = UDim2.new(0.5, 0, 1, -2)
    BottomResize.Size = UDim2.fromOffset(212, 16)
    BottomResize.AutoButtonColor = false
    Grip.Size = UDim2.fromOffset(200, 5.143)
    Grip.BackgroundColor3 = options.main_color
    Grip.BackgroundTransparency = 0.6
    Grip.Position = UDim2.new(0.5, 0, 0, 6)
    Grip.AnchorPoint = Vector2.new(0.5, 0)

    runtime:Connect(Bar:GetPropertyChangedSignal("BackgroundColor3"), function()
        CornerImage.ImageColor3 = Bar.BackgroundColor3
        Grip.BackgroundColor3 = Bar.BackgroundColor3
    end)

    local hovered = {}
    local gripTweens = {}
    local function updateGrip(handle, active)
        local held = gesture and gesture.Handle == handle
        local visual = handle == Resizer and CornerImage or Grip
        local property = handle == Resizer and "ImageTransparency" or "BackgroundTransparency"
        local target = active and 0.35 or 0.6
        local scale = held and 1.12 or active and 1.06 or 1
        if gripTweens[handle] then gripTweens[handle]:Cancel() end
        gripTweens[handle] = TweenService:Create(visual, TweenInfo.new(active and 0.12 or 0.17,
            Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            [property] = target,
            Size = handle == Resizer and UDim2.fromOffset(120 * scale, 120 * scale)
                or UDim2.fromOffset(200 * scale, 5.143 * scale),
        })
        gripTweens[handle]:Play()
    end

	local function setMinimized(value, animated)
		if not runtime.Alive then return end
		endGesture()
        minimized = value
        HeaderSurface.Size = UDim2.new(1, 0, 0, value and 26 or 46)
        HeaderCorner.CornerRadius = UDim.new(0, value and 10 or windowRadius)
        HeaderClip.Visible = value
        Bar.BackgroundTransparency = value and 1 or 0
        Bar.Base.BackgroundTransparency = value and 1 or 0
        Bar.Base.ImageTransparency = value and 1 or 0
        Bar.Top.ImageTransparency = value and 1 or 0

		Tabs.Visible = not value
		TabSelection.Visible = not value and #TabSelection.TabButtons:GetChildren() > 1
		Resizer.Visible = not value and resizeEnabled
		Resizer.Active = not value and resizeEnabled
		BottomResize.Visible = not value and resizeEnabled
		Minimize.Icon.Image = value and lucideMaximize or lucideMinimize
		Bar.Base.Visible = true
		applySize(expandedSize, animated ~= false)
	end

	function window_data:Minimize(value)
		setMinimized(value == nil and not minimized or value == true)
	end
	runtime:Connect(Minimize.Activated, function() setMinimized(not minimized) end)
	runtime:Connect(Toggle.Activated, function() setMinimized(not minimized) end)
	runtime:Connect(Close.Activated, function() library:Destroy() end)

	local DragHandle = Instance.new("Frame")
	DragHandle.Name = "DragHandle"
	DragHandle.BackgroundTransparency = 1
	DragHandle.Active = true
	DragHandle.Size = UDim2.new(1, -104, 0, 26)
	DragHandle.Position = UDim2.fromOffset(30, 0)
	DragHandle.ZIndex = Window.ZIndex + 3
	DragHandle.Parent = Window

    local function startGesture(input, mode, surface)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if gesture then return end
        if mode ~= "move" and mode ~= "pending" and (minimized or not resizeEnabled) then return end
        gesture = {Input = input, Mode = mode, Start = Vector2.new(input.Position.X, input.Position.Y),
            Size = expandedSize, Position = Window.Position, Surface = surface}
        if surface then
            gesture.Canvas = surface.CanvasPosition
            gesture.WasScrollingEnabled = surface.ScrollingEnabled
            surface.ScrollingEnabled = false
        end
        if mode == "both" or mode == "height" then
            gesture.Handle = mode == "both" and Resizer or BottomResize
            updateGrip(gesture.Handle, true)
        end
    end

    local function contains(object, point)
        local origin, size = object.AbsolutePosition, object.AbsoluteSize
        return point.X >= origin.X and point.X <= origin.X + size.X
            and point.Y >= origin.Y and point.Y <= origin.Y + size.Y
    end

    local function visibleAt(object, point)
        local node = object
        while node and node ~= Window.Parent do
            if node:IsA("GuiObject") then
                if not node.Visible then return false end
                if node.ClipsDescendants and not contains(node, point) then return false end
            end
            node = node.Parent
        end
        return true
    end

    local scrollbars = {}
    local scrollPointer
    local function scrollbarPoint(input)
        local point = Vector2.new(input.Position.X, input.Position.Y)
        if imgui.IgnoreGuiInset then point = point + game:GetService("GuiService"):GetGuiInset() end
        return point
    end

    local function overScrollbar(surface, point)
        if surface.ScrollBarThickness <= 0 or not contains(surface, point) or not visibleAt(surface, point) then
            return false
        end
        local origin, size = surface.AbsolutePosition, surface.AbsoluteSize
        local thickness = surface.ScrollBarThickness + 2
        local vertical = surface.ScrollingDirection ~= Enum.ScrollingDirection.X
            and surface.AbsoluteCanvasSize.Y > surface.AbsoluteWindowSize.Y + 1
        local horizontal = surface.ScrollingDirection ~= Enum.ScrollingDirection.Y
            and surface.AbsoluteCanvasSize.X > surface.AbsoluteWindowSize.X + 1
        local left = surface.VerticalScrollBarPosition == Enum.VerticalScrollBarPosition.Left
        return vertical and (left and point.X <= origin.X + thickness
            or not left and point.X >= origin.X + size.X - thickness)
            or horizontal and point.Y >= origin.Y + size.Y - thickness
    end

    local function bindScrollbar(surface)
        if not surface:IsA("ScrollingFrame") or scrollbars[surface] then return end
        local state = {LastUsed = -math.huge, Active = false}
        scrollbars[surface] = state
        surface.ScrollBarImageColor3 = options.main_color
        surface.ScrollBarImageTransparency = 0.8
        runtime:Connect(surface:GetPropertyChangedSignal("CanvasPosition"), function()
            state.LastUsed = os.clock()
        end)
        runtime:Connect(surface.Destroying, function() scrollbars[surface] = nil end)
    end

    for _, object in ipairs(Window:GetDescendants()) do bindScrollbar(object) end
    runtime:Connect(Window.DescendantAdded, bindScrollbar)
    runtime:Connect(Bar:GetPropertyChangedSignal("BackgroundColor3"), function()
        for surface in pairs(scrollbars) do surface.ScrollBarImageColor3 = Bar.BackgroundColor3 end
    end)

    local function scrollbarInputBegan(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local point = scrollbarPoint(input)
        for surface, state in pairs(scrollbars) do
            if overScrollbar(surface, point) then state.Input = input end
        end
    end
    local function scrollbarInputEnded(input)
        for _, state in pairs(scrollbars) do
            if state.Input and (state.Input == input
                or state.Input.UserInputType == Enum.UserInputType.MouseButton1
                    and input.UserInputType == Enum.UserInputType.MouseButton1) then
                state.Input = nil
                state.LastUsed = os.clock()
            end
        end
    end
    runtime:Connect(UIS.InputBegan, scrollbarInputBegan)
    runtime:Connect(UIS.InputEnded, scrollbarInputEnded)
    runtime:Connect(UIS.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            scrollPointer = scrollbarPoint(input)
        end
    end)
    local scrollbarElapsed = 0
    runtime:Connect(RS.Heartbeat, function(delta)
        scrollbarElapsed = scrollbarElapsed + delta
        if scrollbarElapsed < 0.05 then return end
        scrollbarElapsed = 0
        local now = os.clock()
        for surface, state in pairs(scrollbars) do
            local active = state.Input ~= nil or now - state.LastUsed < 0.25
                or scrollPointer ~= nil and overScrollbar(surface, scrollPointer)
            if active ~= state.Active then
                state.Active = active
                if state.Tween then state.Tween:Cancel() end
                state.Tween = TweenService:Create(surface, TweenInfo.new(active and 0.1 or 0.17,
                    Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    ScrollBarImageTransparency = active and 0.35 or 0.8,
                })
                state.Tween:Play()
            end
        end
    end)

    local function overControl(surface, point)
        for _, node in ipairs(surface:GetDescendants()) do
            if node:IsA("GuiObject") and (node:IsA("GuiButton") or node:IsA("TextBox")
                or node:IsA("ScrollingFrame") or node.Name == "Slider" or node.Name == "Palette"
                or node.Name == "Saturation") and contains(node, point) and visibleAt(node, point) then
                return true
            end
        end
        local inset = surface.ScrollBarThickness
        if surface.ScrollingDirection == Enum.ScrollingDirection.Y then
            return surface.AbsoluteCanvasSize.Y > surface.AbsoluteWindowSize.Y
                and point.X >= surface.AbsolutePosition.X + surface.AbsoluteSize.X - inset - 2
        end
        return surface.AbsoluteCanvasSize.X > surface.AbsoluteWindowSize.X
            and point.Y >= surface.AbsolutePosition.Y + surface.AbsoluteSize.Y - inset - 2
    end

    contentSurfaces[TabSelection.TabButtons] = true
    runtime:Connect(UIS.InputBegan, function(input)
        if gesture or minimized or dropdown_open then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local point = Vector2.new(input.Position.X, input.Position.Y)
        if imgui.IgnoreGuiInset then point = point + game:GetService("GuiService"):GetGuiInset() end
        for surface in pairs(contentSurfaces) do
            if surface.Parent and contains(surface, point) and visibleAt(surface, point)
                and not overControl(surface, point) then
                startGesture(input, "pending", surface)
                return
            end
        end
    end)
    runtime:Connect(DragHandle.InputBegan, function(input) startGesture(input, "move") end)
    runtime:Connect(Title.InputBegan, function(input) startGesture(input, "move") end)
    runtime:Connect(Resizer.InputBegan, function(input) startGesture(input, "both") end)
    runtime:Connect(BottomResize.InputBegan, function(input) startGesture(input, "height") end)
    local function updateGesture(input)
        if not gesture then return end
        local touch = gesture.Input.UserInputType == Enum.UserInputType.Touch
        if (touch and input ~= gesture.Input)
            or (not touch and input.UserInputType ~= Enum.UserInputType.MouseMovement) then return end
        local delta = Vector2.new(input.Position.X, input.Position.Y) - gesture.Start
        if gesture.Mode == "pending" then
            if delta.Magnitude < 6 then return end
            local surface = gesture.Surface
            local xOverflow = surface.ScrollingDirection ~= Enum.ScrollingDirection.Y
                and surface.AbsoluteCanvasSize.X > surface.AbsoluteWindowSize.X + 1
            local yOverflow = surface.ScrollingDirection ~= Enum.ScrollingDirection.X
                and surface.AbsoluteCanvasSize.Y > surface.AbsoluteWindowSize.Y + 1
            gesture.Mode = xOverflow and math.abs(delta.X) > math.abs(delta.Y) and "scrollX"
                or yOverflow and math.abs(delta.Y) >= math.abs(delta.X) and "scrollY" or "move"
        end
        if gesture.Mode == "move" then
            Window.Position = UDim2.new(gesture.Position.X.Scale, gesture.Position.X.Offset + delta.X,
                gesture.Position.Y.Scale, gesture.Position.Y.Offset + delta.Y)
        elseif gesture.Mode == "scrollX" or gesture.Mode == "scrollY" then
            local surface = gesture.Surface
            local maxX = math.max(0, surface.AbsoluteCanvasSize.X - surface.AbsoluteWindowSize.X)
            local maxY = math.max(0, surface.AbsoluteCanvasSize.Y - surface.AbsoluteWindowSize.Y)
            surface.CanvasPosition = Vector2.new(
                math.clamp(gesture.Canvas.X - (gesture.Mode == "scrollX" and delta.X or 0), 0, maxX),
                math.clamp(gesture.Canvas.Y - (gesture.Mode == "scrollY" and delta.Y or 0), 0, maxY))
        else
            applySize(UDim2.fromOffset(gesture.Size.X.Offset + (gesture.Mode == "both" and delta.X or 0),
                gesture.Size.Y.Offset + delta.Y))
        end
    end
    runtime:Connect(UIS.InputChanged, updateGesture)
    runtime:Connect(UIS.InputEnded, function(input)
        if gesture and (input == gesture.Input or (gesture.Input.UserInputType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseButton1)) then
            local handle = gesture.Handle
            endGesture()
            if handle then updateGrip(handle, hovered[handle] == true) end
        end
    end)
    for _, handle in ipairs({Resizer, BottomResize}) do
        runtime:Connect(handle.MouseEnter, function()
            hovered[handle] = true
            if not gesture or gesture.Handle == handle then updateGrip(handle, true) end
        end)
        runtime:Connect(handle.MouseLeave, function()
            hovered[handle] = nil
            if not gesture or gesture.Handle ~= handle then updateGrip(handle, false) end
        end)
    end
    runtime:AddCleanup(endGesture)

	runtime:Connect(Title:GetPropertyChangedSignal("Text"), function() applySize(expandedSize) end)
	applySize(expandedSize)
	setMinimized(false, false)


    local themeDefaults = {
        MainColor = options.main_color,
        BackgroundColor = Window.BackgroundColor3,
        TextColor = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamSemibold,
        HeadingSize = 16, LabelSize = 14, ControlSize = 14, Spacing = 5,
    }
    local theme = table.clone(themeDefaults)
    local labels = {}
    local entries = {}
    local entryOrder = {}
    local keyCounts = {}
    local themeListeners = {}
    window_data.Frame = Window
    window_data.Runtime = runtime
    window_data.ConfigControls = entries

    local textService = game:GetService("TextService")
    local dirtyLabels = {}

    local function renderLabel(label)
        local state = labels[label]
        if not label.Parent or not state or state.Rendering then return end
        state.Rendering = true
        dirtyLabels[label] = nil
        local width = math.max(1, math.floor(label.AbsoluteSize.X + 0.5))
        state.Width = width
        if state.Text ~= label.Text then
            state.Text = label.Text
            state.Paragraphs = {}
            for paragraph in string.gmatch(label.Text:gsub("\r\n", "\n"):gsub("\r", "\n") .. "\n", "(.-)\n") do
                table.insert(state.Paragraphs, paragraph)
            end
        end
        local paragraphY = 0
        for index, paragraph in ipairs(state.Paragraphs) do
            local line = state.Lines[index]
            if not line or line.Parent ~= label then
                line = Instance.new("TextLabel")
                line.Name = "Line" .. index
                line.BackgroundTransparency = 1
                line.TextWrapped = true
                line.TextXAlignment = Enum.TextXAlignment.Left
                line.TextYAlignment = Enum.TextYAlignment.Center
                line:SetAttribute("EleriumLabelLine", true)
                line.Parent = label
                state.Lines[index] = line
            end
            line.Text = paragraph
            line.Font = label.Font
            line.TextSize = label.TextSize
            line.TextColor3 = label.TextColor3
            line.RichText = label.RichText
            line.ZIndex = label.ZIndex
            local cached = state.Measurements[index]
            if not cached or cached.Text ~= paragraph or cached.Width ~= width
                or cached.Font ~= label.Font or cached.Size ~= label.TextSize then
                local measured = textService:GetTextSize(paragraph == "" and " " or paragraph,
                    label.TextSize, label.Font, Vector2.new(width, 100000))
                cached = {Text = paragraph, Width = width, Font = label.Font, Size = label.TextSize,
                    Height = math.max(label.TextSize + 6, measured.Y)}
                state.Measurements[index] = cached
            end
            line.Position = UDim2.fromOffset(0, paragraphY)
            line.Size = UDim2.new(1, 0, 0, cached.Height)
            paragraphY = paragraphY + cached.Height + theme.Spacing
        end
        for index = #state.Lines, #state.Paragraphs + 1, -1 do
            state.Lines[index]:Destroy()
            state.Lines[index] = nil
            state.Measurements[index] = nil
        end
        label.Size = UDim2.new(1, -10, 0, math.max(label.TextSize + 6, paragraphY - theme.Spacing))
        state.Rendering = false
    end

    local function labelVisible(label)
        if minimized or not Window.Visible then return false end
        local node = label
        while node and node ~= Window do
            if node:IsA("GuiObject") and not node.Visible then return false end
            node = node.Parent
        end
        return node == Window
    end

    local labelElapsed = 0
    runtime:Connect(RS.Heartbeat, function(delta)
        labelElapsed = labelElapsed + delta
        if labelElapsed < 0.1 then return end
        labelElapsed = 0
        for label in pairs(dirtyLabels) do
            if not label.Parent then
                dirtyLabels[label] = nil
            elseif labelVisible(label) then
                renderLabel(label)
            end
        end
    end)

    local function addTextLabel(parent, text, heading)
        local object = prefabs.Label:Clone()
        object.Name = heading and "Heading" or "Label"
        object:SetAttribute("EleriumRole", heading and "Heading" or "Label")
        object.Text = tostring(text or "")
        object.Font = theme.Font
        object.TextSize = heading and theme.HeadingSize or theme.LabelSize
        object.TextColor3 = theme.TextColor
        object.TextTransparency = 1
        object.AutomaticSize = Enum.AutomaticSize.None
        object.TextWrapped = false
        object.Size = UDim2.new(1, -10, 0, object.TextSize + 6)
        object.ZIndex = object.ZIndex + windows * 10
        object.Parent = parent
        labels[object] = {Lines = {}, Measurements = {}}
        for _, property in ipairs({"Text", "TextSize", "Font", "TextColor3", "RichText", "ZIndex"}) do
            runtime:Connect(object:GetPropertyChangedSignal(property), function() dirtyLabels[object] = true end)
        end
        runtime:Connect(object:GetPropertyChangedSignal("AbsoluteSize"), function()
            local state = labels[object]
            if state and state.Width ~= math.max(1, math.floor(object.AbsoluteSize.X + 0.5)) then dirtyLabels[object] = true end
        end)
        runtime:Connect(object.Destroying, function()
            dirtyLabels[object] = nil
            labels[object] = nil
        end)
        renderLabel(object)
        return object
    end

    local function styleObject(object, recolor)
        if object:IsA("UIListLayout") and object.Parent ~= TabSelection.TabButtons then
            object.Padding = UDim.new(0, theme.Spacing)
        end
        if not object:IsA("GuiObject") or object:GetAttribute("EleriumLabelLine") then return end
        if not object:IsDescendantOf(Tabs) and not object:IsDescendantOf(TabSelection) then return end
        if not object:GetAttribute("EleriumRole") and object.Size.Y.Scale == 0
            and object.Size.Y.Offset >= 20 and object.Size.Y.Offset <= 36
            and not object:IsA("ScrollingFrame") and not object:GetAttribute("EleriumFixedSize")
            and (object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")
                or object.Parent and object.Parent:FindFirstChildOfClass("UIListLayout")) then
            object.Size = UDim2.new(object.Size.X.Scale, object.Size.X.Offset, 0, math.max(20, theme.ControlSize + 6))
        end
        if not (object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")) then return end
        if object:GetAttribute("EleriumRole") then return end
        if object:FindFirstAncestor("Console") then return end
        local previewFont = object:GetAttribute("EleriumFontPreview")
        object.Font = previewFont and Enum.Font[previewFont] or theme.Font
        object.TextSize = theme.ControlSize
        if recolor then object.TextColor3 = theme.TextColor end
        if object:IsA("TextButton") and not object:GetAttribute("EleriumFixedSize")
            and object.Size.X.Scale == 0 and object.Size.X.Offset > 30 then
            local measured = game:GetService("TextService"):GetTextSize(object.Text, object.TextSize,
                object.Font, Vector2.new(100000, 100000))
            object.Size = UDim2.new(0, measured.X + 15, object.Size.Y.Scale, object.Size.Y.Offset)
        end
    end

    function window_data:GetTheme()
        return table.clone(theme)
    end
    function window_data:GetDefaultTheme()
        return table.clone(themeDefaults)
    end
    function window_data:OnThemeChanged(callback)
        table.insert(themeListeners, callback)
        return callback
    end
    function window_data:SetTheme(changes)
        if not runtime.Alive then return end
        assert(type(changes) == "table", "Theme must be a table")
        local staged = table.clone(theme)
        for key, value in pairs(changes) do
            if themeDefaults[key] ~= nil then
                if key:find("Color") then
                    assert(typeof(value) == "Color3", key .. " must be Color3")
                elseif key == "Font" then
                    if type(value) == "string" then value = Enum.Font[value] end
                    assert(typeof(value) == "EnumItem" and value.EnumType == Enum.Font, "Invalid font")
                else
                    assert(type(value) == "number" and value == value and value < math.huge, "Invalid " .. key)
                    value = math.clamp(math.floor(value), key == "Spacing" and 0 or 10, key == "Spacing" and 20 or 30)
                end
                staged[key] = value
            end
        end
        theme = staged
        options.main_color = theme.MainColor
        Window.BackgroundColor3 = theme.BackgroundColor
        Window.ImageColor3 = theme.BackgroundColor
        Bar.BackgroundColor3 = theme.MainColor
        Bar.Base.BackgroundColor3 = theme.MainColor
        TabSelection.Frame.BackgroundColor3 = theme.MainColor
        for object in pairs(mainColorTargets) do
            if object.Parent then object.ImageColor3 = theme.MainColor end
        end
        for object in pairs(labels) do
            object.Font = theme.Font
            object.TextSize = object:GetAttribute("EleriumRole") == "Heading" and theme.HeadingSize or theme.LabelSize
            if changes.TextColor then object.TextColor3 = theme.TextColor end
            renderLabel(object)
        end
        for _, object in ipairs(Window:GetDescendants()) do styleObject(object, changes.TextColor ~= nil) end
        for _, callback in ipairs(themeListeners) do runtime:Spawn(callback, self:GetTheme()) end
    end
    function window_data:ResetTheme()
        self:SetTheme(themeDefaults)
    end
    runtime:Connect(Window.DescendantAdded, function(object)
        runtime:Defer(function() if object.Parent then styleObject(object, false) end end)
    end)

    local function decorateTab(tabData, content, tabName)
        function tabData:SetConfigIgnored(ignored)
            content:SetAttribute("EleriumIgnoreConfig", ignored == true)
        end
        local methods = {"AddSwitch", "AddSlider", "AddDropdown", "AddColorPicker", "AddTextBox", "AddKeybind"}
        for _, method in ipairs(methods) do
            local original = tabData[method]
            tabData[method] = function(self, ...)
                local args = table.pack(...)
                local callbackIndex = method == "AddColorPicker" and 1 or 2
                local callback = args[callbackIndex]
                args.n = math.max(args.n, callbackIndex)
                local current
                if method ~= "AddKeybind" then
                    args[callbackIndex] = function(value, ...)
                        current = value
                        if type(callback) == "function" then return callback(value, ...) end
                    end
                end
                local returned = table.pack(original(self, table.unpack(args, 1, args.n)))
                local data, node = returned[1], returned[2]
                if typeof(data) == "Instance" then node = data end
                local title = method == "AddColorPicker" and "Color" or tostring(args[1])
                local baseKey = tabName .. "/" .. method .. "/" .. title
                keyCounts[baseKey] = (keyCounts[baseKey] or 0) + 1
                local key = baseKey .. "/" .. keyCounts[baseKey]
                local entry = {Kind = method, Tab = content, Node = node, Key = key}
                if method == "AddSwitch" then current = false end
                if method == "AddKeybind" then
                    current = type(args[3]) == "table" and args[3].standard or Enum.KeyCode.RightShift
                    local setter = data.SetKeybind
                    data.SetKeybind = function(control, value)
                        current = value
                        return setter(control, value)
                    end
                end
                if method == "AddColorPicker" and current == nil then current = node.Sample.ImageColor3 end
                function entry:Get()
                    if method == "AddTextBox" then return node.Text end
                    return current
                end
                function entry:Set(value)
                    if method == "AddSwitch" then assert(type(value) == "boolean", "Invalid switch"); data:Set(value)
                    elseif method == "AddSlider" then assert(type(value) == "number", "Invalid slider"); data:Set(value)
                    elseif method == "AddColorPicker" then assert(typeof(value) == "Color3", "Invalid color"); data:Set(value)
                    elseif method == "AddKeybind" then
                        assert(typeof(value) == "EnumItem" and value.EnumType == Enum.KeyCode, "Invalid key")
                        data:SetKeybind(value)
                    elseif method == "AddTextBox" then
                        assert(type(value) == "string", "Invalid textbox")
                        node.Text = value
                        if value ~= "" and type(callback) == "function" then callback(value) end
                    elseif method == "AddDropdown" then
                        assert(type(value) == "string", "Invalid dropdown")
                        local found = false
                        for _, option in ipairs(node.Box.Objects:GetChildren()) do
                            if option:IsA("TextButton") and option.Text == value then found = true end
                        end
                        assert(found, "Dropdown option no longer available: " .. value)
                        node.Text = "      [ " .. value .. " ]"
                        current = value
                        if type(callback) == "function" then callback(value) end
                    end
                end
                if type(data) == "table" then
                    function data:GetValue() return entry:Get() end
                    function data:SetValue(value) return entry:Set(value) end
                end
                entries[key] = entry
                table.insert(entryOrder, entry)
                if type(data) == "table" then
                    function data:SetConfigKey(newKey)
                        assert(type(newKey) == "string" and newKey ~= "", "Invalid config key")
                        assert(not entries[newKey] or entries[newKey] == entry, "Duplicate config key")
                        entries[entry.Key] = nil
                        entry.Key = newKey
                        entries[newKey] = entry
                        return self
                    end
                end
                return table.unpack(returned, 1, returned.n)
            end
        end
    end

    function window_data:RegisterConfig(key, getter, setter)
        assert(type(key) == "string" and key ~= "" and not entries[key], "Duplicate or invalid config key")
        assert(type(getter) == "function" and type(setter) == "function", "Config binding requires get/set functions")
        local entry = {Key = key, Kind = "Custom", Get = function() return getter() end,
            Set = function(_, value) return setter(value) end}
        entries[key] = entry
        table.insert(entryOrder, entry)
        return entry
    end

    function window_data:GetConfigValues()
        local values = {}
        for key, entry in pairs(entries) do
            if not entry.Tab or not entry.Tab:GetAttribute("EleriumIgnoreConfig") then values[key] = entry:Get() end
        end
        return values
    end
    function window_data:ApplyConfigValues(values)
        assert(runtime.Alive, "Window closed")
        assert(type(values) == "table", "Invalid config values")
        local failures = {}
        for _, switches in ipairs({false, true}) do
            for _, entry in ipairs(entryOrder) do
                if (entry.Kind == "AddSwitch") == switches and values[entry.Key] ~= nil
                    and (not entry.Tab or not entry.Tab:GetAttribute("EleriumIgnoreConfig")) then
                    local ok, err = pcall(entry.Set, entry, values[entry.Key])
                    if not ok then table.insert(failures, entry.Key .. ": " .. tostring(err)) end
                end
            end
        end
        return failures
    end

	do
		local tabs = Window:FindFirstChild("Tabs")
		local tab_selection = Window:FindFirstChild("TabSelection")
		local tab_buttons = tab_selection:FindFirstChild("TabButtons")
        local buttonLayout = tab_buttons:FindFirstChildOfClass("UIListLayout")
        local function updateTabCanvas()
            tab_buttons.CanvasSize = UDim2.fromOffset(buttonLayout.AbsoluteContentSize.X, 0)
        end
        runtime:Connect(buttonLayout:GetPropertyChangedSignal("AbsoluteContentSize"), updateTabCanvas)
        updateTabCanvas()


		do
			function window_data:AddTab(tab_name)
				local tab_data = {}
				tab_name = tostring(tab_name or "New Tab")
				tab_selection.Visible = true

				local new_button = prefabs:FindFirstChild("TabButton"):Clone()
				new_button.Parent = tab_buttons
				new_button.Text = tab_name
				new_button.Size = UDim2.new(0, gNameLen(new_button), 0, 20)
				new_button.ZIndex = new_button.ZIndex + (windows * 10)
				new_button:GetChildren()[1].ZIndex = new_button:GetChildren()[1].ZIndex + (windows * 10)

				local new_tab = prefabs:FindFirstChild("Tab"):Clone()
				new_tab.Parent = tabs
				new_tab.ZIndex = new_tab.ZIndex + (windows * 10)
                new_tab.Name = tab_name
                contentSurfaces[new_tab] = true
                local contentLayout = new_tab:FindFirstChildOfClass("UIListLayout")
                local function updateContentCanvas()
                    new_tab.CanvasSize = UDim2.fromOffset(0, contentLayout.AbsoluteContentSize.Y + 10)
                end
                runtime:Connect(contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"), updateContentCanvas)
                runtime:Connect(new_tab:GetPropertyChangedSignal("AbsoluteSize"), updateContentCanvas)
                updateContentCanvas()


				local function show()
					if dropdown_open then return end
					for i, v in pairs(tab_buttons:GetChildren()) do
						if not (v:IsA("UIListLayout")) then
							v:GetChildren()[1].ImageColor3 = Color3.fromRGB(52, 53, 56)
							Resize(v, {Size = UDim2.new(0, v.AbsoluteSize.X, 0, 20)}, options.tween_time)
						end
					end
					for i, v in pairs(tabs:GetChildren()) do
						v.Visible = false
					end

					Resize(new_button, {Size = UDim2.new(0, new_button.AbsoluteSize.X, 0, 25)}, options.tween_time)
					new_button:GetChildren()[1].ImageColor3 = Color3.fromRGB(73, 75, 79)
                    if minimized then setMinimized(false) end
                    new_tab.Visible = true
                    local left = new_button.AbsolutePosition.X - tab_buttons.AbsolutePosition.X + tab_buttons.CanvasPosition.X
                    local visibleX = tab_buttons.CanvasPosition.X
                    if left < visibleX then
                        tab_buttons.CanvasPosition = Vector2.new(left, 0)
                    elseif left + new_button.AbsoluteSize.X > visibleX + tab_buttons.AbsoluteSize.X then
                        tab_buttons.CanvasPosition = Vector2.new(left + new_button.AbsoluteSize.X - tab_buttons.AbsoluteSize.X, 0)
                    end
				end

				runtime:Connect(new_button.MouseButton1Click, function()
					show()
				end)

				function tab_data:Show()
					show()
				end

				do

                    function tab_data:AddLabel(text)
                        return addTextLabel(new_tab, text, false)
                    end
                    function tab_data:AddHeading(text)
                        return addTextLabel(new_tab, text, true)
                    end

					function tab_data:AddButton(button_text, callback)
						button_text = tostring(button_text or "New Button")
						callback = typeof(callback) == "function" and callback or function()end

						local button = prefabs:FindFirstChild("Button"):Clone()

						button.Parent = new_tab
						button.Text = button_text
						button.Size = UDim2.new(0, gNameLen(button), 0, 20)
						button.ZIndex = button.ZIndex + (windows * 10)
						button:GetChildren()[1].ZIndex = button:GetChildren()[1].ZIndex + (windows * 10)

                        bindMainColor(button:GetChildren()[1])

						runtime:Connect(button.MouseButton1Click, function()
							ripple(button, mouse.X, mouse.Y)
							pcall(callback)
						end)

						return button
					end

					function tab_data:AddSwitch(switch_text, callback)
						local switch_data = {}

						switch_text = tostring(switch_text or "New Switch")
						callback = typeof(callback) == "function" and callback or function()end

						local switch = prefabs:FindFirstChild("Switch"):Clone()

						switch.Parent = new_tab
						switch:FindFirstChild("Title").Text = switch_text

						switch:FindFirstChild("Title").ZIndex = switch:FindFirstChild("Title").ZIndex + (windows * 10)
						switch.ZIndex = switch.ZIndex + (windows * 10)
						switch:GetChildren()[1].ZIndex = switch:GetChildren()[1].ZIndex + (windows * 10)

                        bindMainColor(switch:GetChildren()[1])

						local toggled = false
						runtime:AddCleanup(function()
							if toggled then
								toggled = false
								pcall(callback, false)
							end
						end)
						runtime:Connect(switch.MouseButton1Click, function()
							toggled = not toggled
							switch.Text = toggled and utf8.char(10003) or ""
							pcall(callback, toggled)
						end)

						function switch_data:Set(bool)
							if not runtime.Alive then return end
							toggled = (typeof(bool) == "boolean") and bool or false
							switch.Text = toggled and utf8.char(10003) or ""
							pcall(callback,toggled)
						end

						return switch_data, switch
					end

					function tab_data:AddTextBox(textbox_text, callback, textbox_options)
						textbox_text = tostring(textbox_text or "New TextBox")
						callback = typeof(callback) == "function" and callback or function()end
						textbox_options = typeof(textbox_options) == "table" and textbox_options or {["clear"] = true}
						textbox_options = {
							["clear"] = ((textbox_options.clear) == true)
						}

						local textbox = prefabs:FindFirstChild("TextBox"):Clone()

						textbox.Parent = new_tab
						textbox.PlaceholderText = textbox_text
						textbox.ZIndex = textbox.ZIndex + (windows * 10)
						textbox:GetChildren()[1].ZIndex = textbox:GetChildren()[1].ZIndex + (windows * 10)

						runtime:Connect(textbox.FocusLost, function(ep)
							if ep then
								if #textbox.Text > 0 then
									pcall(callback, textbox.Text)
									if textbox_options.clear then
										textbox.Text = ""
									end
								end
							end
						end)

						return textbox
					end

                    function tab_data:AddSlider(slider_text, callback, slider_options)
                        local slider_data = {}
                        callback = type(callback) == "function" and callback or function() end
                        slider_options = type(slider_options) == "table" and slider_options or {}
                        local minimum = tonumber(slider_options.min) or 0
                        local maximum = math.max(minimum, tonumber(slider_options.max) or 100)
                        local step = math.max(0.001, tonumber(slider_options.step) or 1)
                        local commitOnRelease = slider_options.commitOnRelease ~= false
                        local slider = prefabs.Slider:Clone()
                        slider.Active = true
                        slider.Parent = new_tab
                        slider.ZIndex = slider.ZIndex + windows * 10
                        local title, indicator, valueLabel = slider.Title, slider.Indicator, slider.Value
                        title.Text = tostring(slider_text or "New Slider")
                        for _, object in ipairs({title, indicator, valueLabel}) do object.ZIndex = object.ZIndex + windows * 10 end
                        local selected = minimum
                        local committed = minimum
                        local dragInput, scrollParent, previousScrolling
                        local initialX, initialWidth, dragStartValue

                        local function normalize(value)
                            value = tonumber(value) or minimum
                            if value ~= value then value = minimum end
                            value = math.clamp(value, minimum, maximum)
                            value = minimum + math.floor((value - minimum) / step + 0.5) * step
                            return math.clamp(value, minimum, maximum)
                        end
                        local function render(value)
                            selected = normalize(value)
                            local fraction = maximum == minimum and 0 or (selected - minimum) / (maximum - minimum)
                            indicator.Size = UDim2.new(fraction, 0, 1, 0)
                            valueLabel.Text = string.format("%.6g", selected)
                        end
                        local function notify()
                            committed = selected
                            callback(selected)
                        end
                        local function updateFromInput(input)
                            local fraction = math.clamp((input.Position.X - initialX) / initialWidth, 0, 1)
                            local before = selected
                            render(minimum + fraction * (maximum - minimum))
                            if selected ~= before and not commitOnRelease then notify() end
                        end
                        local function finishDrag(commit)
                            if not dragInput then return end
                            dragInput = nil
                            if scrollParent and scrollParent.Parent then scrollParent.ScrollingEnabled = previousScrolling end
                            scrollParent = nil
                            slider:SetAttribute("EleriumDragging", false)
                            if commitOnRelease then
                                if commit then notify() else render(dragStartValue) end
                            end
                        end
                        local function beginDrag(input)
                            if dragInput or slider_options.readonly or dropdown_open then return end
                            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                                and input.UserInputType ~= Enum.UserInputType.Touch then return end
                            dragInput = input
                            initialX, initialWidth = slider.AbsolutePosition.X, math.max(1, slider.AbsoluteSize.X)
                            dragStartValue = selected
                            scrollParent = slider:FindFirstAncestorWhichIsA("ScrollingFrame")
                            if scrollParent then
                                previousScrolling = scrollParent.ScrollingEnabled
                                scrollParent.ScrollingEnabled = false
                            end
                            slider:SetAttribute("EleriumDragging", true)
                            updateFromInput(input)
                        end
                        local function changeDrag(input)
                            if not dragInput then return end
                            local touch = dragInput.UserInputType == Enum.UserInputType.Touch
                            if touch and input ~= dragInput then return end
                            if not touch and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                            if input.UserInputState == Enum.UserInputState.Cancel then finishDrag(false); return end
                            updateFromInput(input)
                        end
                        local function endDrag(input)
                            if dragInput and (input == dragInput or dragInput.UserInputType == Enum.UserInputType.MouseButton1
                                and input.UserInputType == Enum.UserInputType.MouseButton1) then finishDrag(true) end
                        end
                        runtime:Connect(slider.InputBegan, beginDrag)
                        runtime:Connect(UIS.InputChanged, changeDrag)
                        runtime:Connect(UIS.InputEnded, endDrag)
                        runtime:Connect(UIS.WindowFocusReleased, function() finishDrag(false) end)
                        runtime:AddCleanup(function() finishDrag(false) end)
                        function slider_data:Set(value)
                            if not runtime.Alive then return end
                            render(value)
                            notify()
                        end
                        function slider_data:IsDragging() return dragInput ~= nil end
                        slider_data:Set(minimum)
                        return slider_data, slider
                    end

					function tab_data:AddKeybind(keybind_name, callback, keybind_options)
						local keybind_data = {}

						keybind_name = tostring(keybind_name or "New Keybind")
						callback = typeof(callback) == "function" and callback or function()end
						keybind_options = typeof(keybind_options) == "table" and keybind_options or {}
						keybind_options = {
							["standard"] = keybind_options.standard or Enum.KeyCode.RightShift,
						}

						local keybind = prefabs:FindFirstChild("Keybind"):Clone()
						local input = keybind:FindFirstChild("Input")
						local title = keybind:FindFirstChild("Title")
						keybind.ZIndex = keybind.ZIndex + (windows * 10)
						input.ZIndex = input.ZIndex + (windows * 10)
						input:GetChildren()[1].ZIndex = input:GetChildren()[1].ZIndex + (windows * 10)
						title.ZIndex = title.ZIndex + (windows * 10)

						keybind.Parent = new_tab
						title.Text = "  " .. keybind_name
						keybind.Size = UDim2.new(0, gNameLen(title) + 80, 0, 20)

						local shortkeys = {
							RightControl = 'RightCtrl',
							LeftControl = 'LeftCtrl',
							LeftShift = 'LShift',
							RightShift = 'RShift',
							MouseButton1 = "Mouse1",
							MouseButton2 = "Mouse2"
						}

						local keybind = keybind_options.standard

						function keybind_data:SetKeybind(Keybind)
							local key = shortkeys[Keybind.Name] or Keybind.Name
							input.Text = key
							keybind = Keybind
						end

						runtime:Connect(UIS.InputBegan, function(a, b)
							if checks.binding then
								runtime:Spawn(function()
									wait()
									checks.binding = false
								end)
								return
							end
							if a.KeyCode == keybind and not b then
								pcall(callback, keybind)
							end
						end)

						keybind_data:SetKeybind(keybind_options.standard)

						runtime:Connect(input.MouseButton1Click, function()
							if checks.binding then return end
							input.Text = "..."
							checks.binding = true
							local a, b = UIS.InputBegan:Wait()
							keybind_data:SetKeybind(a.KeyCode)
						end)

						return keybind_data, input.Parent
					end

					function tab_data:AddDropdown(dropdown_name, callback)
						local dropdown_data = {}
						local dropdown_objects = {}
						dropdown_name = tostring(dropdown_name or "New Dropdown")
						callback = typeof(callback) == "function" and callback or function()end

						local dropdown = prefabs:FindFirstChild("Dropdown"):Clone()
						local box = dropdown:FindFirstChild("Box")
						local objects = box:FindFirstChild("Objects")
						local indicator = dropdown:FindFirstChild("Indicator")
						dropdown.ZIndex = dropdown.ZIndex + (windows * 10)
						box.ZIndex = box.ZIndex + (windows * 10)
						objects.ZIndex = objects.ZIndex + (windows * 10)
						indicator.ZIndex = indicator.ZIndex + (windows * 10)
						dropdown:GetChildren()[3].ZIndex = dropdown:GetChildren()[3].ZIndex + (windows * 10)

						dropdown.Parent = new_tab
						dropdown.Text = "      " .. dropdown_name
						box.Size = UDim2.new(1, 0, 0, 0)

                        local open = false
                        local layout = objects:FindFirstChildOfClass("UIListLayout")
                        local function updateDropdownSize()
                            local count, visibleHeight = 0, 0
                            for _, item in ipairs(objects:GetChildren()) do
                                if item:IsA("GuiButton") and item.Visible then
                                    count = count + 1
                                    if count <= 10 then visibleHeight = visibleHeight + item.AbsoluteSize.Y end
                                end
                            end
                            local gap = layout.Padding.Offset + layout.Padding.Scale * objects.AbsoluteSize.Y
                            visibleHeight = visibleHeight + math.max(0, math.min(count, 10) - 1) * gap
                            objects.CanvasSize = UDim2.fromOffset(0, math.ceil(layout.AbsoluteContentSize.Y))
                            if open then
                                Resize(box, {Size = UDim2.new(1, 0, 0, math.ceil(visibleHeight))}, options.tween_time)
                            end
                        end
                        runtime:Connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"), updateDropdownSize)
                        runtime:Connect(dropdown.MouseButton1Click, function()
                            if not open and dropdown_open then return end
                            open = not open

                            if open then
                                dropdown_open = true
                                updateDropdownSize()
								Resize(indicator, {Rotation = 90}, options.tween_time)
							else
								dropdown_open = false
								Resize(box, {Size = UDim2.new(1, 0, 0, 0)}, options.tween_time)
								Resize(indicator, {Rotation = -90}, options.tween_time)
							end

						end)

						function dropdown_data:Add(n)
							local object_data = {}
							n = tostring(n or "New Object")
							if not objects or not objects.Parent then
								return object_data
							end

							local named_objects = dropdown_objects[n]
							local existing_object
							if named_objects then
								for index = #named_objects, 1, -1 do
									local current_object = named_objects[index]
									if not current_object or not current_object.Parent then
										table.remove(named_objects, index)
									elseif existing_object then
										current_object:Destroy()
										table.remove(named_objects, index)
									else
										existing_object = current_object
									end
								end

								if #named_objects == 0 then
									dropdown_objects[n] = nil
								end
							end

							if existing_object then
								function object_data:Remove()
									dropdown_data:Remove(n)
								end
								return existing_object, object_data
							end

							local object_prefab = prefabs and prefabs:FindFirstChild("DropdownButton")
							if not object_prefab then
								return object_data
							end

							local object = object_prefab:Clone()

							object.Parent = objects
							object.Text = n
							object.ZIndex = object.ZIndex + (windows * 10)
							dropdown_objects[n] = dropdown_objects[n] or {}
							table.insert(dropdown_objects[n], object)

							runtime:Connect(object.MouseEnter, function()
								object.BackgroundColor3 = options.main_color
							end)
							runtime:Connect(object.MouseLeave, function()
								object.BackgroundColor3 = Color3.fromRGB(33, 34, 36)
							end)

                            updateDropdownSize()

							runtime:Connect(object.MouseButton1Click, function()
								if dropdown_open then
									dropdown.Text = "      [ " .. n .. " ]"
									dropdown_open = false
									open = false
									Resize(box, {Size = UDim2.new(1, 0, 0, 0)}, options.tween_time)
									Resize(indicator, {Rotation = -90}, options.tween_time)
									pcall(callback, n)
								end
							end)

							function object_data:Remove()
								if object.Parent then object:Destroy() end
								local named_objects = dropdown_objects[n]
								if named_objects then
									for index = #named_objects, 1, -1 do
										if named_objects[index] == object then
											table.remove(named_objects, index)
										end
									end
									if #named_objects == 0 then dropdown_objects[n] = nil end
								end
							end

							return object, object_data
						end

						function dropdown_data:Remove(n)
							n = tostring(n or "New Object")
							local named_objects = dropdown_objects[n]
							if not named_objects then return end

							for _, object in ipairs(named_objects) do
								if object.Parent then object:Destroy() end
							end
							dropdown_objects[n] = nil
							if dropdown.Text == "      [ " .. n .. " ]" then
								dropdown.Text = "      " .. dropdown_name
							end
							if open then
								open = false
								dropdown_open = false
								Resize(box, {Size = UDim2.new(1, 0, 0, 0)}, options.tween_time)
								Resize(indicator, {Rotation = -90}, options.tween_time)
							end
						end

						function dropdown_data:Clear()
							for name, named_objects in pairs(dropdown_objects) do
								for _, object in ipairs(named_objects) do
									if object.Parent then object:Destroy() end
								end
								dropdown_objects[name] = nil
							end
							dropdown.Text = "      " .. dropdown_name
							if open then
								open = false
								dropdown_open = false
								Resize(box, {Size = UDim2.new(1, 0, 0, 0)}, options.tween_time)
								Resize(indicator, {Rotation = -90}, options.tween_time)
							end
						end

						function dropdown_data:Refresh(items)
							dropdown_data:Clear()
							for _, item in ipairs(items or {}) do
								dropdown_data:Add(item)
							end
						end

						return dropdown_data, dropdown
					end

                    function tab_data:AddColorPicker(callback)
                        callback = type(callback) == "function" and callback or function() end
                        local data = {}
                        local root = Instance.new("ImageLabel")
                        root.Name = "ColorPicker"
                        root.BackgroundTransparency = 1
                        root.ImageTransparency = 1
                        root.Size = UDim2.new(1, 0, 0, 28)
                        root.ZIndex = Window.ZIndex + windows * 10 + 1
                        root:SetAttribute("EleriumFixedSize", true)
                        root.Parent = new_tab
                        local function frame(name, parent, position, size, color)
                            local object = Instance.new("Frame")
                            object.Name = name
                            object.BorderSizePixel = 0
                            object.BackgroundColor3 = color or Color3.new(1, 1, 1)
                            object.Position = position
                            object.Size = size
                            object.ZIndex = root.ZIndex + 1
                            object.Parent = parent
                            return object
                        end
                        local function corner(parent, radius)
                            local object = Instance.new("UICorner")
                            object.CornerRadius = UDim.new(0, radius)
                            object.Parent = parent
                        end
                        local sample = Instance.new("ImageLabel")
                        sample.Name = "Sample"
                        sample.ImageTransparency = 1
                        sample.BorderSizePixel = 0
                        sample.Position = UDim2.fromOffset(2, 0)
                        sample.Size = UDim2.fromOffset(72, 28)
                        sample.ZIndex = root.ZIndex + 1
                        sample.Parent = root
                        corner(sample, 5)
                        local outline = Instance.new("UIStroke")
                        outline.Color = Color3.new(1, 1, 1)
                        outline.Transparency = 0.65
                        outline.Parent = sample
                        local trigger = Instance.new("TextButton")
                        trigger.Name = "OpenColorPicker"
                        trigger.Text = ""
                        trigger.BackgroundTransparency = 1
                        trigger.Size = UDim2.fromScale(1, 1)
                        trigger.ZIndex = root.ZIndex + 2
                        trigger.Parent = sample
                        local panel = frame("PickerPanel", root, UDim2.fromOffset(2, 34), UDim2.fromOffset(244, 180), Color3.fromRGB(33, 34, 36))
                        panel.Visible = false
                        corner(panel, 7)
                        local palette = frame("Palette", panel, UDim2.fromOffset(10, 10), UDim2.fromOffset(196, 124))
                        palette.Active = true
                        corner(palette, 6)
                        local white = frame("White", palette, UDim2.new(), UDim2.fromScale(1, 1))
                        corner(white, 6)
                        local whiteGradient = Instance.new("UIGradient")
                        whiteGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
                        whiteGradient.Parent = white
                        local black = frame("Black", palette, UDim2.new(), UDim2.fromScale(1, 1), Color3.new(0, 0, 0))
                        corner(black, 6)
                        local blackGradient = Instance.new("UIGradient")
                        blackGradient.Rotation = 90
                        blackGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
                        blackGradient.Parent = black
                        local marker = frame("Indicator", palette, UDim2.new(), UDim2.fromOffset(10, 10))
                        marker.AnchorPoint = Vector2.new(0.5, 0.5)
                        marker.ZIndex = root.ZIndex + 4
                        corner(marker, 5)
                        local markerStroke = Instance.new("UIStroke")
                        markerStroke.Thickness = 2
                        markerStroke.Color = Color3.new(1, 1, 1)
                        markerStroke.Parent = marker
                        local hueBar = frame("Saturation", panel, UDim2.fromOffset(216, 10), UDim2.fromOffset(18, 124))
                        hueBar.Active = true
                        corner(hueBar, 6)
                        local hueGradient = Instance.new("UIGradient")
                        hueGradient.Rotation = 90
                        local colors = {}
                        for index = 0, 6 do table.insert(colors, ColorSequenceKeypoint.new(index / 6, Color3.fromHSV(index / 6, 1, 1))) end
                        hueGradient.Color = ColorSequence.new(colors)
                        hueGradient.Parent = hueBar
                        local hueMarker = frame("Indicator", hueBar, UDim2.new(), UDim2.new(1, 4, 0, 2))
                        hueMarker.Position = UDim2.fromOffset(-2, 0)
                        corner(hueMarker, 1)
                        hueMarker.ZIndex = root.ZIndex + 4
                        local done = Instance.new("TextButton")
                        done.Name = "Done"
                        done.Text = "Done"
                        done.Font = theme.Font
                        done.TextSize = theme.ControlSize
                        done.TextColor3 = theme.TextColor
                        done.BackgroundColor3 = Color3.fromRGB(52, 53, 56)
                        done.BorderSizePixel = 0
                        done.Position = UDim2.fromOffset(10, 142)
                        done.Size = UDim2.new(1, -20, 0, 28)
                        done.ZIndex = root.ZIndex + 2
                        done:SetAttribute("EleriumFixedSize", true)
                        done.Parent = panel
                        corner(done, 5)
                        local hue, saturation, brightness = 0, 0, 1
                        local expanded = false
                        local captured, area, scrollParent, wasScrolling
                        local function render()
                            local color = Color3.fromHSV(hue, saturation, brightness)
                            sample.ImageColor3 = color
                            sample.BackgroundColor3 = color
                            palette.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                            marker.BackgroundColor3 = color
                            marker.Position = UDim2.fromScale(saturation, 1 - brightness)
                            hueMarker.Position = UDim2.new(0, -2, hue, -1)
                            return color
                        end
                        local function stopDrag()
                            captured = nil
                            if scrollParent and scrollParent.Parent then scrollParent.ScrollingEnabled = wasScrolling end
                            scrollParent = nil
                        end
                        function data:SetOpen(open)
                            expanded = open == true
                            if not expanded then stopDrag() end
                            panel.Visible = expanded
                            root.Size = UDim2.new(1, 0, 0, expanded and 214 or 28)
                            if expanded then
                                runtime:Defer(function()
                                    RS.Heartbeat:Wait()
                                    if not expanded or not root.Parent or not new_tab.Visible then return end
                                    local scroller = root:FindFirstAncestorWhichIsA("ScrollingFrame")
                                    if not scroller then return end
                                    local top = root.AbsolutePosition.Y - scroller.AbsolutePosition.Y
                                    local bottom = top + root.AbsoluteSize.Y
                                    local delta = top < 0 and top or math.max(0, bottom - scroller.AbsoluteWindowSize.Y)
                                    if delta ~= 0 then
                                        scroller.CanvasPosition = Vector2.new(scroller.CanvasPosition.X,
                                            math.max(0, scroller.CanvasPosition.Y + delta))
                                    end
                                end)
                            end
                        end
                        function data:IsOpen() return expanded end
                        function data:Set(color)
                            if not runtime.Alive then return end
                            assert(typeof(color) == "Color3", "Color picker requires Color3")
                            hue, saturation, brightness = color:ToHSV()
                            render()
                            callback(color)
                        end
                        local function update(input)
                            local position = Vector2.new(input.Position.X, input.Position.Y)
                            if imgui.IgnoreGuiInset then position = position + game:GetService("GuiService"):GetGuiInset() end
                            if area == palette then
                                saturation = math.clamp((position.X - palette.AbsolutePosition.X) / math.max(1, palette.AbsoluteSize.X), 0, 1)
                                brightness = 1 - math.clamp((position.Y - palette.AbsolutePosition.Y) / math.max(1, palette.AbsoluteSize.Y), 0, 1)
                            else
                                hue = math.clamp((position.Y - hueBar.AbsolutePosition.Y) / math.max(1, hueBar.AbsoluteSize.Y), 0, 1)
                            end
                            callback(render())
                        end
                        local function beginDrag(input, target)
                            if captured or not expanded then return end
                            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                            captured, area = input, target
                            scrollParent = root:FindFirstAncestorWhichIsA("ScrollingFrame")
                            if scrollParent then wasScrolling = scrollParent.ScrollingEnabled; scrollParent.ScrollingEnabled = false end
                            update(input)
                        end
                        local function changeDrag(input)
                            if not captured then return end
                            if captured.UserInputType == Enum.UserInputType.Touch and input ~= captured then return end
                            if captured.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                            if input.UserInputState == Enum.UserInputState.Cancel then stopDrag(); return end
                            update(input)
                        end
                        local function endDrag(input)
                            if captured and (captured == input or captured.UserInputType == Enum.UserInputType.MouseButton1
                                and input.UserInputType == Enum.UserInputType.MouseButton1) then stopDrag() end
                        end
                        runtime:Connect(trigger.Activated, function() data:SetOpen(not expanded) end)
                        runtime:Connect(done.Activated, function() data:SetOpen(false) end)
                        runtime:Connect(palette.InputBegan, function(input) beginDrag(input, palette) end)
                        runtime:Connect(hueBar.InputBegan, function(input) beginDrag(input, hueBar) end)
                        runtime:Connect(UIS.InputChanged, changeDrag)
                        runtime:Connect(UIS.InputEnded, endDrag)
                        runtime:Connect(UIS.WindowFocusReleased, stopDrag)
                        runtime:AddCleanup(stopDrag)
                        render()
                        return data, root
                    end

					function tab_data:AddConsole(console_options)
						local console_data = {}

						console_options = typeof(console_options) == "table" and console_options or {["readonly"] = true,["full"] = false,}
						console_options = {
							["y"] = tonumber(console_options.y) or 200,
							["source"] = console_options.source or "Logs",
							["readonly"] = ((console_options.readonly) == true),
							["full"] = ((console_options.full) == true),
						}

						local console = prefabs:FindFirstChild("Console"):Clone()

						console.Parent = new_tab
						console.ZIndex = console.ZIndex + (windows * 10)
						console.Size = UDim2.new(1, 0, console_options.full and 1 or 0, console_options.y)

						local sf = console:GetChildren()[1]
						local Source = sf:FindFirstChild("Source")
						local Lines = sf:FindFirstChild("Lines")
						Source.ZIndex = Source.ZIndex + (windows * 10)
						Lines.ZIndex = Lines.ZIndex + (windows * 10)

						Source.TextEditable = not console_options.readonly

						do
							for i,v in pairs(Source:GetChildren()) do
								v.ZIndex = v.ZIndex + (windows * 10) + 1
							end
						end
						Source.Comments.ZIndex = Source.Comments.ZIndex + 1

						do
							local lua_keywords = {"and", "break", "do", "else", "elseif", "end", "false", "for", "function", "goto", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while"}
							local global_env = {"getrawmetatable", "newcclosure", "islclosure", "setclipboard", "game", "workspace", "script", "math", "string", "table", "print", "wait", "BrickColor", "Color3", "next", "pairs", "ipairs", "select", "unpack", "Instance", "Vector2", "Vector3", "CFrame", "Ray", "UDim2", "Enum", "assert", "error", "warn", "tick", "loadstring", "_G", "shared", "getfenv", "setfenv", "newproxy", "setmetatable", "getmetatable", "os", "debug", "pcall", "ypcall", "xpcall", "rawequal", "rawset", "rawget", "tonumber", "tostring", "type", "typeof", "_VERSION", "coroutine", "delay", "require", "spawn", "LoadLibrary", "settings", "stats", "time", "UserSettings", "version", "Axes", "ColorSequence", "Faces", "ColorSequenceKeypoint", "NumberRange", "NumberSequence", "NumberSequenceKeypoint", "gcinfo", "elapsedTime", "collectgarbage", "PhysicalProperties", "Rect", "Region3", "Region3int16", "UDim", "Vector2int16", "Vector3int16", "load", "fire", "Fire"}

							local Highlight = function(string, keywords)
								local K = {}
								local S = string
								local Token =
									{
									["="] = true,
									["."] = true,
									[","] = true,
									["("] = true,
									[")"] = true,
									["["] = true,
									["]"] = true,
									["{"] = true,
									["}"] = true,
									[":"] = true,
									["*"] = true,
									["/"] = true,
									["+"] = true,
									["-"] = true,
									["%"] = true,
									[";"] = true,
									["~"] = true
								}
								for i, v in pairs(keywords) do
									K[v] = true
								end
								S = S:gsub(".", function(c)
									if Token[c] ~= nil then
										return "\32"
									else
										return c
									end
								end)
								S = S:gsub("%S+", function(c)
									if K[c] ~= nil then
										return c
									else
										return (" "):rep(#c)
									end
								end)

								return S
							end

							local hTokens = function(string)
								local Token =
									{
									["="] = true,
									["."] = true,
									[","] = true,
									["("] = true,
									[")"] = true,
									["["] = true,
									["]"] = true,
									["{"] = true,
									["}"] = true,
									[":"] = true,
									["*"] = true,
									["/"] = true,
									["+"] = true,
									["-"] = true,
									["%"] = true,
									[";"] = true,
									["~"] = true
								}
								local A = ""
								string:gsub(".", function(c)
									if Token[c] ~= nil then
										A = A .. c
									elseif c == "\n" then
										A = A .. "\n"
									elseif c == "\t" then
										A = A .. "\t"
									else
										A = A .. "\32"
									end
								end)

								return A
							end

							local strings = function(string)
								local highlight = ""
								local quote = false
								string:gsub(".", function(c)
									if quote == false and c == "\34" then
										quote = true
									elseif quote == true and c == "\34" then
										quote = false
									end
									if quote == false and c == "\34" then
										highlight = highlight .. "\34"
									elseif c == "\n" then
										highlight = highlight .. "\n"
									elseif c == "\t" then
										highlight = highlight .. "\t"
									elseif quote == true then
										highlight = highlight .. c
									elseif quote == false then
										highlight = highlight .. "\32"
									end
								end)

								return highlight
							end

							local info = function(string)
								local highlight = ""
								local quote = false
								string:gsub(".", function(c)
									if quote == false and c == "[" then
										quote = true
									elseif quote == true and c == "]" then
										quote = false
									end
									if quote == false and c == "]" then
										highlight = highlight .. "]"
									elseif c == "\n" then
										highlight = highlight .. "\n"
									elseif c == "\t" then
										highlight = highlight .. "\t"
									elseif quote == true then
										highlight = highlight .. c
									elseif quote == false then
										highlight = highlight .. "\32"
									end
								end)

								return highlight
							end

							local comments = function(string)
								local ret = ""
								string:gsub("[^\r\n]+", function(c)
									local comm = false
									local i = 0
									c:gsub(".", function(n)
										i = i + 1
										if c:sub(i, i + 1) == "--" then
											comm = true
										end
										if comm == true then
											ret = ret .. n
										else
											ret = ret .. "\32"
										end
									end)
									ret = ret
								end)

								return ret
							end

							local numbers = function(string)
								local A = ""
								string:gsub(".", function(c)
									if tonumber(c) ~= nil then
										A = A .. c
									elseif c == "\n" then
										A = A .. "\n"
									elseif c == "\t" then
										A = A .. "\t"
									else
										A = A .. "\32"
									end
								end)

								return A
							end

                            local function highlight_logs(s)
                                local result = s
                                for _, name in ipairs({"print","warn","error","console.log"}) do
                                    local pat = name:gsub("%.", "%%.")
                                    result = result:gsub(pat .. "%s*%b()", '<font color="rgb(130,255,170)">%0</font>')
                                end
                                return result
                            end

							local highlight_lua = function(type)
								if type == "Text" then
									Source.Text = Source.Text:gsub("\13", "")
									Source.Text = Source.Text:gsub("\t", "      ")
									local s = Source.Text

									Source.Keywords.Text = Highlight(s, lua_keywords)
									Source.Globals.Text = Highlight(s, global_env)
									Source.RemoteHighlight.Text = Highlight(s, {"FireServer", "fireServer", "InvokeServer", "invokeServer"})
									Source.Tokens.Text = hTokens(s)
									Source.Numbers.Text = numbers(s)
									Source.Strings.Text = strings(s)
									Source.Comments.Text = comments(s)

									local lin = 1
									s:gsub("\n", function()
										lin = lin + 1
									end)

									Lines.Text = ""
									for i = 1, lin do
										Lines.Text = Lines.Text .. i .. "\n"
									end

									sf.CanvasSize = UDim2.new(0, 0, lin * 0.153846154, 0)
								end

								local highlight_logs = function(type)
                                    if type == "Text" then
                                        Source.Text = Source.Text:gsub("\13", "")
                                        Source.Text = Source.Text:gsub("\t", "      ")
                                        local s = Source.Text
                                        Source.Keywords.Text     = Highlight(s, lua_keywords)
                                        Source.Globals.Text      = Highlight(s, global_env)
                                        Source.RemoteHighlight.Text = Highlight(s, {"FireServer", "fireServer", "InvokeServer", "invokeServer"})
                                        Source.Tokens.Text       = hTokens(s)
                                        Source.Numbers.Text      = numbers(s)
                                        Source.Strings.Text      = strings(s)
                                        Source.Comments.Text     = comments(s)
                                        Source.Logs.Text = highlight_logs(s)
                                        local lin = 1
                                        s:gsub("\n", function() lin = lin + 1 end)
                                        Lines.Text = ""
                                        for i = 1, lin do
                                            Lines.Text = Lines.Text .. i .. "\n"
                                        end

                                        sf.CanvasSize = UDim2.new(0, 0, lin * 0.153846154, 0)
                                    end
								end
								if type == "Text" then
									Source.Text = Source.Text:gsub("\13", "")
									Source.Text = Source.Text:gsub("\t", "      ")
									local s = Source.Text

									Source.Info.Text = info(s)

									local lin = 1
									s:gsub("\n", function()
										lin = lin + 1
									end)

									sf.CanvasSize = UDim2.new(0, 0, lin * 0.153846154, 0)
								end
							end

							if console_options.source == "Lua" then
								highlight_lua("Text")
								runtime:Connect(Source.Changed, highlight_lua)
							elseif console_options.source == "Logs" then
								Lines.Visible = false

								highlight_logs("Text")
								runtime:Connect(Source.Changed, highlight_logs)
							end

							function console_data:Set(code)
								Source.Text = tostring(code)
							end

							function console_data:Get()
								return Source.Text
							end

							function console_data:Log(msg)
								Source.Text = Source.Text .. "[*] " .. tostring(msg) .. "\n"
							end

						end

						return console_data, console
					end

					function tab_data:AddHorizontalAlignment()
						local ha_data = {}

						local ha = prefabs:FindFirstChild("HorizontalAlignment"):Clone()
						ha.Parent = new_tab

						function ha_data:AddButton(...)
							local data, object
							local ret = {tab_data:AddButton(...)}
							if typeof(ret[1]) == "table" then
								data = ret[1]
								object = ret[2]
								object.Parent = ha
								return data, object
							else
								object = ret[1]
								object.Parent = ha
								return object
							end
						end

						return ha_data, ha
					end

					function tab_data:AddFolder(folder_name)
						local folder_data = {}

						folder_name = tostring(folder_name or "New Folder")

						local folder = prefabs:FindFirstChild("Folder"):Clone()
						local button = folder:FindFirstChild("Button")
						local objects = folder:FindFirstChild("Objects")
						local toggle = button:FindFirstChild("Toggle")
						folder.ZIndex = folder.ZIndex + (windows * 10)
						button.ZIndex = button.ZIndex + (windows * 10)
						objects.ZIndex = objects.ZIndex + (windows * 10)
						toggle.ZIndex = toggle.ZIndex + (windows * 10)
						button:GetChildren()[1].ZIndex = button:GetChildren()[1].ZIndex + (windows * 10)

						folder.Parent = new_tab
						button.Text = "      " .. folder_name

                        bindMainColor(button:GetChildren()[1])

						local function gFolderLen()
							local n = math.max(20, theme.ControlSize + 6) + theme.Spacing
							for i,v in pairs(objects:GetChildren()) do
								if not (v:IsA("UIListLayout")) then
									n = n + v.AbsoluteSize.Y + theme.Spacing
								end
							end
							return n
						end

                        local open = false
                        local function updateFolderSize()
                            objects.Position = UDim2.fromOffset(0, math.max(20, theme.ControlSize + 6) + theme.Spacing)
                            local size = UDim2.new(1, 0, 0, open and gFolderLen() or math.max(20, theme.ControlSize + 6))
                            if folder.Size ~= size then Resize(folder, {Size = size}, options.tween_time) end
                        end
                        local layout = objects:FindFirstChildOfClass("UIListLayout")
                        runtime:Connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"), updateFolderSize)
                        table.insert(themeListeners, updateFolderSize)
                        runtime:Connect(button.MouseButton1Click, function()
							if open then
								objects.Visible = false
							else
								objects.Visible = true
							end

                            open = not open
                            updateFolderSize()
                        end)
                        updateFolderSize()

						for i,v in pairs(tab_data) do
                            if type(v) == "function" and i:sub(1, 3) == "Add" then
							folder_data[i] = function(...)
								local data, object
								local ret = {v(...)}
								if typeof(ret[1]) == "table" then
									data = ret[1]
									object = ret[2]
									object.Parent = objects
									return data, object
								else
									object = ret[1]
									object.Parent = objects
									return object
								end
							end
						end

                            end
						return folder_data, folder
					end

				end

                decorateTab(tab_data, new_tab, tab_name)
				return tab_data, new_tab
			end
		end
	end

	do
		for i, v in pairs(Window:GetDescendants()) do
			if hasprop(v, "ZIndex") then
				v.ZIndex = v.ZIndex + (windows * 10)
			end
		end
	end

    table.insert(library.WindowInstances, window_data)
    for method, module in pairs(library.WindowModules) do
        window_data[method] = function(windowSelf, settings) return module:Build(windowSelf, settings) end
    end
	return window_data, Window
end

return library
