local Services = {
	Players = game:GetService("Players"),
	ReplicatedStorage = game:GetService("ReplicatedStorage"),
	VirtualUser = game:GetService("VirtualUser"),
	Workspace = workspace,
	Lighting = game:GetService("Lighting"),
	UserInputService = game:GetService("UserInputService"),
	RunService = game:GetService("RunService")
}

local PlayerData = {
	Player = Services.Players.LocalPlayer,
	DisplayName = Services.Players.LocalPlayer.DisplayName,
	Character = Services.Players.LocalPlayer.Character,
	Humanoid = nil,
	Camera = Services.Workspace.CurrentCamera,
	Backpack = Services.Players.LocalPlayer:WaitForChild("Backpack")
}

PlayerData.Humanoid = PlayerData.Character and PlayerData.Character:FindFirstChildOfClass("Humanoid")

local Remotes = {
	ChangeSpeedSize = Services.ReplicatedStorage.rEvents.changeSpeedSizeRemote,
	MuscleEvent = PlayerData.Player.muscleEvent
}

local Utils = {}

function Utils.formatNumber(n)
	if n >= 1e15 then return string.format("%.1fqa", n / 1e15)
	elseif n >= 1e12 then return string.format("%.1ft", n / 1e12)
	elseif n >= 1e9 then return string.format("%.1fb", n / 1e9)
	elseif n >= 1e6 then return string.format("%.1fm", n / 1e6)
	elseif n >= 1e3 then return string.format("%.1fk", n / 1e3)
	else return tostring(n) end
end

function Utils.formatWithCommas(n)
	local formatted = tostring(math.floor(n))
	while true do
		formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return formatted
end

function Utils.greeting()
	local hour = os.date("*t").hour
	if hour >= 6 and hour < 12 then return "Good Morning " .. PlayerData.DisplayName
	elseif hour >= 12 and hour < 13 then return "Good Noon " .. PlayerData.DisplayName
	elseif hour >= 13 and hour < 19 then return "Good Afternoon " .. PlayerData.DisplayName
	elseif hour >= 19 and hour < 22 then return "Good Evening " .. PlayerData.DisplayName
	else return "Good Night " .. PlayerData.DisplayName end
end

if getgenv().sbe ~= "sbevalid" then
	PlayerData.Player:Kick("Always use the Loader")
	getgenv().sbe = ""
	task.wait(0.5)
	return
else
	getgenv().sbe = ""
end


local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ghjkl1312/bhkjhk/refs/heads/main/lib.luau", true))()

local window = library:AddWindow("Silence | Main - " .. Utils.greeting(), {
	title_bar = {Color3.fromRGB(255, 0, 0), Color3.fromRGB(155, 0, 0)},
	title_bar_transparency = 0.3,
	background = {Color3.fromRGB(90, 0, 0), Color3.fromRGB(0, 0, 0)},
	background_transparency = 0.2,
	main_color = Color3.fromRGB(255, 0, 0),
	min_size = Vector2.new(450, 450),
	can_resize = true,
})

PlayerData.Player.Idled:Connect(function()
	Services.VirtualUser:CaptureController()
	Services.VirtualUser:ClickButton2(Vector2.new())
end)

local Tabs = {
	Main = window:AddTab("Main"),
	Killing = window:AddTab("Killing"),
	Specs = window:AddTab("Specs"),
	Farming = window:AddTab("Farming"),
	Inventory = window:AddTab("Inventory"),
	Teleport = window:AddTab("Teleports"),
	Stats = window:AddTab("Stats"),
	Info = window:AddTab("Info")
}

Tabs.Info:Show()
Tabs.Info:AddLabel("Made with ♥️ by Henne").TextSize = 17
Tabs.Info:AddLabel("Official Discord: discord.gg/9eFf93Kg8D").TextSize = 17
Tabs.Info:AddButton("Copy Discord Invite", function()
	if setclipboard then
		setclipboard("https://discord.gg/9eFf93Kg8D")
		game.StarterGui:SetCore("SendNotification", {Title = "Link Copied!", Text = "You can continue to Discord now.", Duration = 3})
	else
		game.StarterGui:SetCore("SendNotification", {Title = "Error!", Text = "Clipboard not Supported.", Duration = 3})
	end
end)

Tabs.Info:AddButton("Execute Silencecord", function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/imhenne187/Silence/refs/heads/main/scripts/silencecord.luau"))()
end)

Tabs.Info:AddLabel("")
local wLabel = Tabs.Info:AddLabel("Silence [V3.3.0]")
wLabel.TextSize = 40
wLabel.Font = Enum.Font.Arcade

Tabs.Main:AddLabel("⚙️ User Settings:")

local Settings = {
	Size = {Value = 2, Enabled = false},
	Speed = {Value = 120, Enabled = false},
	FOV = {Value = 70, Enabled = false}
}

Tabs.Main:AddTextBox("Size:", function(text)
	text = string.gsub(text, "%s+", "")
	if tonumber(text) and tonumber(text) > 0 then
		Settings.Size.Value = tonumber(text)
	end
end)

Tabs.Main:AddSwitch("Set Size", function(bool)
	Settings.Size.Enabled = bool
end)

task.spawn(function()
	while true do
		if Settings.Size.Enabled and PlayerData.Character and PlayerData.Humanoid then
			Remotes.ChangeSpeedSize:InvokeServer("changeSize", Settings.Size.Value)
		end
		task.wait(0.01)
	end
end)

Tabs.Main:AddTextBox("Speed:", function(text)
	text = string.gsub(text, "%s+", "")
	if tonumber(text) and tonumber(text) > 0 then
		Settings.Speed.Value = tonumber(text)
	end
end)

Tabs.Main:AddSwitch("Set Speed", function(bool)
	Settings.Speed.Enabled = bool
end)

task.spawn(function()
	while true do
		if Settings.Speed.Enabled and PlayerData.Character and PlayerData.Humanoid then
			Remotes.ChangeSpeedSize:InvokeServer("changeSpeed", Settings.Speed.Value)
		end
		task.wait(0.01)
	end
end)

if PlayerData.Camera then
	Tabs.Main:AddTextBox("FOV:", function(text)
		text = string.gsub(text, "%s+", "")
		if tonumber(text) and tonumber(text) >= 1 and tonumber(text) <= 120 then
			Settings.FOV.Value = tonumber(text)
		end
	end)

	Tabs.Main:AddSwitch("Set FOV", function(bool)
		Settings.FOV.Enabled = bool
		PlayerData.Camera.FieldOfView = bool and Settings.FOV.Value or 70
	end)

	task.spawn(function()
		while true do
			if Settings.FOV.Enabled and PlayerData.Camera then
				PlayerData.Camera.FieldOfView = Settings.FOV.Value
			end
			task.wait(0.01)
		end
	end)
end

Tabs.Main:AddLabel("🛡️ Protection and Visuals:")

local Protection = {
	AntiFling = {Enabled = false},
	PositionLock = {Enabled = false, Position = nil}
}

local function eAntiFling()
	if not Protection.AntiFling.Enabled or not PlayerData.Player.Character then return end
	if not PlayerData.Player.Character:FindFirstChild("HumanoidRootPart") then return end
	if PlayerData.Player.Character.HumanoidRootPart:FindFirstChild("BodyVelocity") and 
	   PlayerData.Player.Character.HumanoidRootPart.BodyVelocity.MaxForce == Vector3.new(100000, 0, 100000) then
		PlayerData.Player.Character.HumanoidRootPart.BodyVelocity:Destroy()
	end
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(100000, 0, 100000)
	bv.Velocity = Vector3.new(0, 0, 0)
	bv.P = 1250
	bv.Parent = PlayerData.Player.Character.HumanoidRootPart
end

local function dAntiFling()
	if not PlayerData.Player.Character or not PlayerData.Player.Character:FindFirstChild("HumanoidRootPart") then return end
	if PlayerData.Player.Character.HumanoidRootPart:FindFirstChild("BodyVelocity") and 
	   PlayerData.Player.Character.HumanoidRootPart.BodyVelocity.MaxForce == Vector3.new(100000, 0, 100000) then
		PlayerData.Player.Character.HumanoidRootPart.BodyVelocity:Destroy()
	end
end

Tabs.Main:AddSwitch("Anti Fling", function(bool)
	Protection.AntiFling.Enabled = bool
	if bool then eAntiFling() else dAntiFling() end
end):Set(true)

PlayerData.Player.CharacterAdded:Connect(function(newChar)
	newChar:WaitForChild("HumanoidRootPart", 5)
	if Protection.AntiFling.Enabled then eAntiFling() end
end)

local function lockPosition()
	eAntiFling()
	if not Protection.PositionLock.Enabled or not Protection.PositionLock.Position or not PlayerData.Player.Character then return end
	if not PlayerData.Player.Character:FindFirstChild("HumanoidRootPart") then return end
	if PlayerData.Player.Character.HumanoidRootPart:FindFirstChild("PositionLocker") then
		PlayerData.Player.Character.HumanoidRootPart.PositionLocker.Position = Protection.PositionLock.Position
	else
		dAntiFling()
		local bp = Instance.new("BodyPosition")
		bp.Name = "PositionLocker"
		bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		bp.Position = Protection.PositionLock.Position
		bp.P = 100000
		bp.Parent = PlayerData.Player.Character.HumanoidRootPart
	end
end

local function unlockPosition()
	if PlayerData.Player.Character and PlayerData.Player.Character:FindFirstChild("HumanoidRootPart") then
		if PlayerData.Player.Character.HumanoidRootPart:FindFirstChild("PositionLocker") then
			PlayerData.Player.Character.HumanoidRootPart.PositionLocker:Destroy()
		end
	end
	Protection.PositionLock.Position = nil
end

Tabs.Main:AddSwitch("Lock Position", function(bool)
	Protection.PositionLock.Enabled = bool
	if bool then
		if PlayerData.Player.Character and PlayerData.Player.Character:FindFirstChild("HumanoidRootPart") then
			Protection.PositionLock.Position = PlayerData.Player.Character.HumanoidRootPart.Position
		end
		lockPosition()
	else
		unlockPosition()
	end
end)

PlayerData.Player.CharacterAdded:Connect(function(newChar)
	if Protection.PositionLock.Enabled and newChar:WaitForChild("HumanoidRootPart", 5) then
		Protection.PositionLock.Position = newChar.HumanoidRootPart.Position
		lockPosition()
	end
end)

task.spawn(function()
	while true do
		if Protection.PositionLock.Enabled then lockPosition() end
		task.wait(0.1)
	end
end)

local showpetsswitch = Tabs.Main:AddSwitch("Show Pets", function(bool)
	if PlayerData.Player:FindFirstChild("hidePets") then
		PlayerData.Player.hidePets.Value = bool
	end
end)
showpetsswitch:Set(false)

local showotherpetsswitch = Tabs.Main:AddSwitch("Show Other Pets", function(bool)
	if PlayerData.Player:FindFirstChild("showOtherPetsOn") then
		PlayerData.Player.showOtherPetsOn.Value = bool
	end
end)
showotherpetsswitch:Set(false)

local blockedFrames = {"strengthFrame", "durabilityFrame", "agilityFrame", "evilKarmaFrame", "goodKarmaFrame"}

local frameSwitch = Tabs.Main:AddSwitch("Hide Stat Frames", function(bool)
	if bool then
		for _, name in ipairs(blockedFrames) do
			if Services.ReplicatedStorage:FindFirstChild(name) and Services.ReplicatedStorage[name]:IsA("GuiObject") then
				Services.ReplicatedStorage[name].Visible = false
			end
		end
		if not _G.frameMonitorConnection then
			_G.frameMonitorConnection = Services.ReplicatedStorage.ChildAdded:Connect(function(child)
				for _, name in ipairs(blockedFrames) do
					if child.Name == name and child:IsA("GuiObject") then
						child.Visible = false
					end
				end
			end)
		end
	else
		for _, name in ipairs(blockedFrames) do
			if Services.ReplicatedStorage:FindFirstChild(name) and Services.ReplicatedStorage[name]:IsA("GuiObject") then
				Services.ReplicatedStorage[name].Visible = true
			end
		end
		if _G.frameMonitorConnection then
			_G.frameMonitorConnection:Disconnect()
			_G.frameMonitorConnection = nil
		end
	end
end)
frameSwitch:Set(true)

local WaterParts = {
	Parts = {},
	PartSize = 2048,
	TotalDistance = 50000,
	StartPosition = Vector3.new(-2, -9.5, -2)
}

task.spawn(function()
	for x = 0, math.ceil(WaterParts.TotalDistance / WaterParts.PartSize) - 1 do
		for z = 0, math.ceil(WaterParts.TotalDistance / WaterParts.PartSize) - 1 do
			for i, offset in ipairs({
				{x * WaterParts.PartSize, z * WaterParts.PartSize, "Side_" .. x .. "_" .. z},
				{-x * WaterParts.PartSize, z * WaterParts.PartSize, "LeftRight_" .. x .. "_" .. z},
				{-x * WaterParts.PartSize, -z * WaterParts.PartSize, "UpLeft_" .. x .. "_" .. z},
				{x * WaterParts.PartSize, -z * WaterParts.PartSize, "UpRight_" .. x .. "_" .. z}
			}) do
				local part = Instance.new("Part")
				part.Size = Vector3.new(WaterParts.PartSize, 1, WaterParts.PartSize)
				part.Position = WaterParts.StartPosition + Vector3.new(offset[1], 0, offset[2])
				part.Anchored = true
				part.Transparency = 1
				part.CanCollide = true
				part.Name = "Part_" .. offset[3]
				part.Parent = Services.Workspace
				table.insert(WaterParts.Parts, part)
			end
		end
	end
end)

local walkonwaterSwicth = Tabs.Main:AddSwitch("Walk on Water", function(bool)
	for _, part in ipairs(WaterParts.Parts) do
		if part and part.Parent then part.CanCollide = bool end
	end
end)
walkonwaterSwicth:Set(true)

Tabs.Main:AddLabel("🧩 Other:")

Tabs.Main:AddSwitch("Infinite Jump", function(bool)
	_G.InfiniteJump = bool
	if bool then
		Services.UserInputService.JumpRequest:Connect(function()
			if _G.InfiniteJump then
				Services.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
			end
		end)
	end
end)

Tabs.Main:AddSwitch("Automatically Spin Fortune Wheel", function(bool)
	_G.AutoSpinWheel = bool
	if bool then
		spawn(function()
			while _G.AutoSpinWheel and wait(1) do
				Services.ReplicatedStorage.rEvents.openFortuneWheelRemote:InvokeServer("openFortuneWheel", Services.ReplicatedStorage.fortuneWheelChances["Fortune Wheel"])
			end
		end)
	end
end)

local timeDropdown = Tabs.Main:AddDropdown("Change Time", function(selection)
	Services.Lighting.ClockTime = selection == "Night" and 0 or 9
end)
timeDropdown:Add("Night")
timeDropdown:Add("Day")

Tabs.Specs:AddLabel("📊 Player Stats:").TextSize = 18

local SpecsData = {
	PlayerToInspect = nil,
	EmojiMap = {
		["Time"] = utf8.char(0x1F55B), ["Stats"] = utf8.char(0x1F4CA), ["Strength"] = utf8.char(0x1F4AA),
		["Rebirths"] = utf8.char(0x1F504), ["Durability"] = utf8.char(0x1F6E1), ["Kills"] = utf8.char(0x1F480),
		["Agility"] = utf8.char(0x1F3C3), ["Evil Karma"] = utf8.char(0x1F608), ["Good Karma"] = utf8.char(0x1F607),
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

local specdropdown = Tabs.Specs:AddDropdown("Choose Player", function(text)
	for _, player in ipairs(Services.Players:GetPlayers()) do
		if text == player.DisplayName .. " | " .. player.Name then
			SpecsData.PlayerToInspect = player
			break
		end
	end
end)

for _, player in ipairs(Services.Players:GetPlayers()) do
	specdropdown:Add(player.DisplayName .. " | " .. player.Name)
end

Services.Players.PlayerAdded:Connect(function(player)
	specdropdown:Add(player.DisplayName .. " | " .. player.Name)
end)

Services.Players.PlayerRemoving:Connect(function()
	specdropdown:Clear()
	for _, p in ipairs(Services.Players:GetPlayers()) do
		specdropdown:Add(p.DisplayName .. " | " .. p.Name)
	end
end)

local playerNameLabel = Tabs.Specs:AddLabel("👤 Name: N/A")
local playerUsernameLabel = Tabs.Specs:AddLabel("🎫 Username: N/A")

for _, info in ipairs(SpecsData.StatDefinitions) do
	SpecsData.StatLabels[info.name] = Tabs.Specs:AddLabel(SpecsData.EmojiMap[info.name] .. " " .. info.name .. ": N/A")
end

local function updateStatLabels(targetPlayer)
	if not targetPlayer then return end
	playerNameLabel.Text = "👤 Name: " .. targetPlayer.DisplayName
	playerUsernameLabel.Text = "🎫 Username: " .. targetPlayer.Name
	if not targetPlayer:FindFirstChild("leaderstats") then return end
	for _, info in ipairs(SpecsData.StatDefinitions) do
		local statObject = targetPlayer.leaderstats:FindFirstChild(info.statName) or targetPlayer:FindFirstChild(info.statName)
		if statObject then
			SpecsData.StatLabels[info.name].Text = string.format("%s %s: %s (%s)", SpecsData.EmojiMap[info.name] or "", info.name, 
				Utils.formatNumber(statObject.Value), Utils.formatWithCommas(statObject.Value))
		else
			SpecsData.StatLabels[info.name].Text = SpecsData.EmojiMap[info.name] .. " " .. info.name .. ": 0 (0)"
		end
	end
end

task.spawn(function()
	while true do
		if SpecsData.PlayerToInspect then updateStatLabels(SpecsData.PlayerToInspect) end
		task.wait(0.1)
	end
end)

Tabs.Specs:AddLabel("———————————————————————————————————")
Tabs.Specs:AddLabel("🔱 Advanced Stats:").TextSize = 18

local AdvancedStats = {
	HealthLabel = Tabs.Specs:AddLabel("🛡️ Enemy Health: N/A"),
	EnemyDamageLabel = Tabs.Specs:AddLabel("💥 Enemy Damage: N/A"),
	PlayerHealthLabel = Tabs.Specs:AddLabel("🛡️ Your Health: N/A"),
	PlayerDamageLabel = Tabs.Specs:AddLabel("💥 Your Damage: N/A"),
	HitsToKillLabel = Tabs.Specs:AddLabel("👊 Hits to Kill: N/A")
}

local StatsCache = {
	health = 0,
	enemyDamage = 0,
	playerHealth = 0,
	playerDamage = 0,
	hitsToKill = "N/A"
}

local function calculatePlayerHealth(targetPlayer)
	if not targetPlayer then return 0 end
	local durabilityStat = targetPlayer:FindFirstChild("Durability") or 
		(targetPlayer:FindFirstChild("leaderstats") and targetPlayer.leaderstats:FindFirstChild("Durability"))
	if not durabilityStat then return 0 end
	local totalMultiplier = 1
	if targetPlayer:FindFirstChild("ultimatesFolder") and targetPlayer.ultimatesFolder:FindFirstChild("Infernal Health") then
		totalMultiplier = totalMultiplier + 0.15 * (targetPlayer.ultimatesFolder["Infernal Health"].Value or 0)
	end
	if targetPlayer:FindFirstChild("equippedPets") then
		for _, petValue in ipairs(targetPlayer.equippedPets:GetChildren()) do
			if petValue:IsA("ObjectValue") and petValue.Value then
				if string.lower(petValue.Value.Name):match("mighty") and string.lower(petValue.Value.Name):match("monster") then
					totalMultiplier = totalMultiplier + 0.5
				end
				if string.lower(petValue.Value.Name):match("small") and string.lower(petValue.Value.Name):match("fry") then
					totalMultiplier = totalMultiplier + 0.25
				end
			end
		end
	end
	return durabilityStat.Value * totalMultiplier
end

local function calculatePlayerDamage(targetPlayer)
	if not targetPlayer then return 0 end
	if not targetPlayer:FindFirstChild("leaderstats") or not targetPlayer.leaderstats:FindFirstChild("Strength") then return 0 end
	local baseDamage = targetPlayer.leaderstats.Strength.Value * 0.066666666666666666666666666666666666666666666667
	local totalMultiplier = 1
	if targetPlayer:FindFirstChild("ultimatesFolder") and targetPlayer.ultimatesFolder:FindFirstChild("Demon Damage") then
		totalMultiplier = totalMultiplier + 0.1 * (targetPlayer.ultimatesFolder["Demon Damage"].Value or 0)
	end
	if targetPlayer:FindFirstChild("equippedPets") then
		for _, petValue in ipairs(targetPlayer.equippedPets:GetChildren()) do
			if petValue:IsA("ObjectValue") and petValue.Value then
				if string.lower(petValue.Value.Name):match("wild") and string.lower(petValue.Value.Name):match("wizard") then
					totalMultiplier = totalMultiplier + 0.5
				end
				if string.lower(petValue.Value.Name):match("chaos") and string.lower(petValue.Value.Name):match("sorcerer") then
					totalMultiplier = totalMultiplier + 0.25
				end
			end
		end
	end
	return baseDamage * totalMultiplier
end

local function updateAdvancedStats(targetPlayer)
	if not targetPlayer then
		AdvancedStats.HealthLabel.Text = "🛡️ Enemy Health: N/A"
		AdvancedStats.EnemyDamageLabel.Text = "💥 Enemy Damage: N/A"
		AdvancedStats.PlayerHealthLabel.Text = "🛡️ Your Health: N/A"
		AdvancedStats.PlayerDamageLabel.Text = "💥 Your Damage: N/A"
		AdvancedStats.HitsToKillLabel.Text = "👊 Hits to Kill: N/A"
		return
	end
	
	StatsCache.health = calculatePlayerHealth(targetPlayer)
	StatsCache.enemyDamage = calculatePlayerDamage(targetPlayer)
	StatsCache.playerHealth = calculatePlayerHealth(PlayerData.Player)
	StatsCache.playerDamage = calculatePlayerDamage(PlayerData.Player)
	StatsCache.hitsToKill = StatsCache.playerDamage <= 0 and "∞" or (math.ceil(StatsCache.health / StatsCache.playerDamage) > 200 and "∞" or 
		(math.ceil(StatsCache.health / StatsCache.playerDamage) < 1 and "instant" or math.ceil(StatsCache.health / StatsCache.playerDamage)))
	
	AdvancedStats.HealthLabel.Text = string.format("🛡️ Enemy Health: %s (%s)", Utils.formatNumber(StatsCache.health), Utils.formatWithCommas(StatsCache.health))
	AdvancedStats.EnemyDamageLabel.Text = string.format("💥 Enemy Damage: %s (%s)", Utils.formatNumber(StatsCache.enemyDamage), Utils.formatWithCommas(StatsCache.enemyDamage))
	AdvancedStats.PlayerHealthLabel.Text = string.format("🛡️ Your Health: %s (%s)", Utils.formatNumber(StatsCache.playerHealth), Utils.formatWithCommas(StatsCache.playerHealth))
	AdvancedStats.PlayerDamageLabel.Text = string.format("💥 Your Damage: %s (%s)", Utils.formatNumber(StatsCache.playerDamage), Utils.formatWithCommas(StatsCache.playerDamage))
	AdvancedStats.HitsToKillLabel.Text = string.format("👊 Hits to Kill: %s", tostring(StatsCache.hitsToKill))
end

task.spawn(function()
	while true do
		updateAdvancedStats(SpecsData.PlayerToInspect)
		task.wait(0.1)
	end
end)


-- Kill Tab (i never know where it stars)


local function checkCharacter()
	if not Services.Players.LocalPlayer.Character then
		repeat task.wait() until Services.Players.LocalPlayer.Character
	end
	return Services.Players.LocalPlayer.Character
end

local function gettool()
	for _, v in pairs(Services.Players.LocalPlayer.Backpack:GetChildren()) do
		if v.Name == "Punch" and Services.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
			Services.Players.LocalPlayer.Character.Humanoid:EquipTool(v)
		end
	end
	Services.Players.LocalPlayer.muscleEvent:FireServer("punch", "leftHand")
	Services.Players.LocalPlayer.muscleEvent:FireServer("punch", "rightHand")
end

local function isPlayerAlive(player)
	return player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and 
		player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0
end

local function killPlayer(target)
	if not isPlayerAlive(target) or not checkCharacter():FindFirstChild("LeftHand") then return end
	pcall(function()
		firetouchinterest(target.Character.HumanoidRootPart, checkCharacter().LeftHand, 0)
		firetouchinterest(target.Character.HumanoidRootPart, checkCharacter().LeftHand, 1)
		gettool()
	end)
end

Tabs.Killing:AddLabel("⚙️ Misc:")

local statPetDropdown = Tabs.Killing:AddDropdown("Stat Pet Equip", function(text)
	for _, folder in pairs(Services.Players.LocalPlayer.petsFolder:GetChildren()) do
		if folder:IsA("Folder") then
			for _, pet in pairs(folder:GetChildren()) do
				Services.ReplicatedStorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
			end
		end
	end
	task.wait(0.2)
	local petsToEquip = {}
	for _, pet in pairs(Services.Players.LocalPlayer.petsFolder.Unique:GetChildren()) do
		if pet.Name == text then table.insert(petsToEquip, pet) end
	end
	for i = 1, math.min(8, #petsToEquip) do
		Services.ReplicatedStorage.rEvents.equipPetEvent:FireServer("equipPet", petsToEquip[i])
		task.wait(0.1)
	end
end)
for _, petName in ipairs({"Wild Wizard", "Mighty Monster", "Chaos Sorcerer", "Small Fry"}) do
	statPetDropdown:Add(petName)
end
Tabs.Killing:AddSwitch("Remove Attack Animations", function(bool)
	if bool then
		local blockedAnimations = {
			["rbxassetid://3638729053"] = true,
			["rbxassetid://3638767427"] = true,
		}

		local function setupAnimationBlocking()
			local char = Services.Players.LocalPlayer.Character
			if not char or not char:FindFirstChild("Humanoid") then
				return
			end

			for _, track in pairs(PlayerData.Humanoid:GetPlayingAnimationTracks()) do
				if track.Animation then
					local animId = track.Animation.AnimationId
					local animName = track.Name:lower()

					if
						blockedAnimations[animId]
						or animName:match("punch")
						or animName:match("attack")
						or animName:match("right")
					then
						track:Stop()
					end
				end
			end

			_G.AnimBlockConnection = PlayerData.Humanoid.AnimationPlayed:Connect(function(track)
				if track.Animation then
					local animId = track.Animation.AnimationId
					local animName = track.Name:lower()

					if
						blockedAnimations[animId]
						or animName:match("punch")
						or animName:match("attack")
						or animName:match("right")
					then
						track:Stop()
					end
				end
			end)
		end

		local function processTool(tool)
			if tool and (tool.Name == "Punch" or tool.Name:match("Attack") or tool.Name:match("Right")) then
				if not tool:GetAttribute("ActivatedOverride") then
					tool:SetAttribute("ActivatedOverride", true)

					_G.ToolConnections = _G.ToolConnections or {}
					_G.ToolConnections[tool] = tool.Activated:Connect(function()
						task.wait(0.05)
						local char = Services.Players.LocalPlayer.Character
						if char and char:FindFirstChild("Humanoid") then
							for _, track in pairs(char.Humanoid:GetPlayingAnimationTracks()) do
								if track.Animation then
									local animId = track.Animation.AnimationId
									local animName = track.Name:lower()

									if
										blockedAnimations[animId]
										or animName:match("punch")
										or animName:match("attack")
										or animName:match("right")
									then
										track:Stop()
									end
								end
							end
						end
					end)
				end
			end
		end

		local function overrideToolActivation()
			for _, tool in pairs(Services.Players.LocalPlayer.Backpack:GetChildren()) do
				processTool(tool)
			end

			local char = Services.Players.LocalPlayer.Character
			if char then
				for _, tool in pairs(char:GetChildren()) do
					if tool:IsA("Tool") then
						processTool(tool)
					end
				end
			end

			_G.BackpackAddedConnection = Services.Players.LocalPlayer.Backpack.ChildAdded:Connect(function(child)
				if child:IsA("Tool") then
					task.wait(0.1)
					processTool(child)
				end
			end)

			if char then
				_G.CharacterToolAddedConnection = char.ChildAdded:Connect(function(child)
					if child:IsA("Tool") then
						task.wait(0.1)
						processTool(child)
					end
				end)
			end
		end

		_G.AnimMonitorConnection = Services.RunService.Heartbeat:Connect(function()
			if tick() % 0.5 < 0.01 then
				local char = Services.Players.LocalPlayer.Character
				if char and char:FindFirstChild("Humanoid") then
					for _, track in pairs(char.Humanoid:GetPlayingAnimationTracks()) do
						if track.Animation then
							local animId = track.Animation.AnimationId
							local animName = track.Name:lower()

							if
								blockedAnimations[animId]
								or animName:match("punch")
								or animName:match("attack")
								or animName:match("right")
							then
								track:Stop()
							end
						end
					end
				end
			end
		end)

		_G.CharacterAddedConnection = Services.Players.LocalPlayer.CharacterAdded:Connect(function(newChar)
			task.wait(1)
			setupAnimationBlocking()
			overrideToolActivation()

			if _G.CharacterToolAddedConnection then
				_G.CharacterToolAddedConnection:Disconnect()
			end

			_G.CharacterToolAddedConnection = newChar.ChildAdded:Connect(function(child)
				if child:IsA("Tool") then
					task.wait(0.1)
					processTool(child)
				end
			end)
		end)

		setupAnimationBlocking()
		overrideToolActivation()
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
	end
end)

local NanData = {Enabled = false}

Tabs.Killing:AddSwitch("NaN + Egg", function(bool)
	NanData.Enabled = bool
	if bool then
		Remotes.ChangeSpeedSize:InvokeServer("changeSize", 0 / 0)
		task.spawn(function()
			while NanData.Enabled do
				if PlayerData.Player.Character then
					local eggsInHand = 0
					for _, item in ipairs(PlayerData.Player.Character:GetChildren()) do
						if item.Name == "Protein Egg" then
							eggsInHand = eggsInHand + 1
							if eggsInHand > 1 then item.Parent = PlayerData.Player.Backpack end
						end
					end
					if eggsInHand == 0 and PlayerData.Player.Backpack:FindFirstChild("Protein Egg") then
						PlayerData.Player.Backpack["Protein Egg"].Parent = PlayerData.Player.Character
					end
				end
				task.wait(0.2)
			end
		end)
	end
end)

local DisableEggState = {
	enabled = false,
	connections = {}
}

local function noEgg(tool)
	for _, desc in ipairs(tool:GetDescendants()) do
		if desc:IsA("Script") or desc:IsA("LocalScript") then
			if desc:IsA("LocalScript") then desc.Disabled = true else desc:Destroy() end
		end
		if desc:IsA("RemoteEvent") then pcall(function() desc.FireServer = function() end end) end
	end
end

local function setupEggDisable()
	for _, container in ipairs({PlayerData.Player.Backpack, PlayerData.Player.Character}) do
		if container then
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") and tool.Name == "Protein Egg" then noEgg(tool) end
			end
			local conn = container.ChildAdded:Connect(function(child)
				if DisableEggState.enabled and child:IsA("Tool") and child.Name == "Protein Egg" then 
					task.defer(noEgg, child) 
				end
			end)
			table.insert(DisableEggState.connections, conn)
		end
	end
end

local function cleanupEggDisable()
	for _, conn in ipairs(DisableEggState.connections) do
		conn:Disconnect()
	end
	DisableEggState.connections = {}
end

local DisableEggSwitch = Tabs.Killing:AddSwitch("Disable Eating Eggs", function(bool)
	DisableEggState.enabled = bool
	if bool then
		setupEggDisable()
	else
		cleanupEggDisable()
	end
end)

PlayerData.Player.CharacterAdded:Connect(function(character)
	if DisableEggState.enabled then
		cleanupEggDisable()
		task.wait(0.5)
		setupEggDisable()
	end
end)

Tabs.Killing:AddLabel("💀 Auto Kill:")

_G.whitelistedPlayers = _G.whitelistedPlayers or {}
_G.blacklistedPlayers = _G.blacklistedPlayers or {}

local function isWhitelisted(player)
	for _, name in ipairs(_G.whitelistedPlayers) do
		if name:lower() == player.Name:lower() then return true end
	end
	return false
end

local function isBlacklisted(player)
	for _, name in ipairs(_G.blacklistedPlayers) do
		if name:lower() == player.Name:lower() then return true end
	end
	return false
end

local whitelistDropdown = Tabs.Killing:AddDropdown("Add to Whitelist", function(selectedText)
	local playerName = selectedText:match("| (.+)$")
	if playerName then
		playerName = playerName:gsub("^%s*(.-)%s*$", "%1")
		for _, name in ipairs(_G.whitelistedPlayers) do
			if name:lower() == playerName:lower() then return end
		end
		table.insert(_G.whitelistedPlayers, playerName)
	end
end)

Tabs.Killing:AddSwitch("Kill Everyone", function(bool)
	_G.killAll = bool
	if bool then
		if not _G.killAllConnection then
			_G.killAllConnection = Services.RunService.Heartbeat:Connect(function()
				if _G.killAll then
					for _, player in ipairs(Services.Players:GetPlayers()) do
						if player ~= Services.Players.LocalPlayer and not isWhitelisted(player) then killPlayer(player) end
					end
				end
			end)
		end
	else
		if _G.killAllConnection then _G.killAllConnection:Disconnect() _G.killAllConnection = nil end
	end
end)

Tabs.Killing:AddSwitch("Whitelist Friends", function(bool)
	_G.whitelistFriends = bool
	
	if bool then
		for _, player in pairs(Services.Players:GetPlayers()) do
			if player ~= Services.Players.LocalPlayer and player:IsFriendsWith(Services.Players.LocalPlayer.UserId) then
				if not isWhitelisted(player) then 
					table.insert(_G.whitelistedPlayers, player.Name) 
				end
			end
		end
		
		_G.friendWhitelistConnection = Services.Players.PlayerAdded:Connect(function(player)
			if _G.whitelistFriends and player:IsFriendsWith(Services.Players.LocalPlayer.UserId) then
				if not isWhitelisted(player) then
					table.insert(_G.whitelistedPlayers, player.Name)
				end
			end
		end)
		
		_G.friendCheckLoop = task.spawn(function()
			while _G.whitelistFriends do
				task.wait(3)
				for _, player in pairs(Services.Players:GetPlayers()) do
					if player ~= Services.Players.LocalPlayer and player:IsFriendsWith(Services.Players.LocalPlayer.UserId) then
						if not isWhitelisted(player) then
							table.insert(_G.whitelistedPlayers, player.Name)
							print("Neuer Freund zur Whitelist hinzugefügt:", player.Name)
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

Tabs.Killing:AddLabel("🧿 Karma Killing:")

Tabs.Killing:AddSwitch("Farm Evil Karma", function(bool)
	_G.farmBadKarma = bool
	if bool then
		if not _G.farmBadKarmaConnection then
			_G.farmBadKarmaConnection = Services.RunService.Heartbeat:Connect(function()
				if _G.farmBadKarma then
					for _, player in ipairs(Services.Players:GetPlayers()) do
						if player ~= Services.Players.LocalPlayer and not isWhitelisted(player) and isPlayerAlive(player) then
							local goodKarma = player:FindFirstChild("goodKarma")
							local evilKarma = player:FindFirstChild("evilKarma")
							if goodKarma and evilKarma then
								local goodKarmaValue = goodKarma.Value or 0
								local evilKarmaValue = evilKarma.Value or 0
								if goodKarmaValue > evilKarmaValue and (goodKarmaValue + evilKarmaValue) >= 5 then
									killPlayer(player)
								end
							end
						end
					end
				end
			end)
		end
	else
		if _G.farmBadKarmaConnection then _G.farmBadKarmaConnection:Disconnect() _G.farmBadKarmaConnection = nil end
	end
end)

Tabs.Killing:AddSwitch("Farm Good Karma", function(bool)
	_G.farmGoodKarma = bool
	if bool then
		if not _G.farmGoodKarmaConnection then
			_G.farmGoodKarmaConnection = Services.RunService.Heartbeat:Connect(function()
				if _G.farmGoodKarma then
					for _, player in ipairs(Services.Players:GetPlayers()) do
						if player ~= Services.Players.LocalPlayer and not isWhitelisted(player) and isPlayerAlive(player) then
							local goodKarma = player:FindFirstChild("goodKarma")
							local evilKarma = player:FindFirstChild("evilKarma")
							if goodKarma and evilKarma then
								local goodKarmaValue = goodKarma.Value or 0
								local evilKarmaValue = evilKarma.Value or 0
								if evilKarmaValue > goodKarmaValue and (goodKarmaValue + evilKarmaValue) >= 5 then
									killPlayer(player)
								end
							end
						end
					end
				end
			end)
		end
	else
		if _G.farmGoodKarmaConnection then _G.farmGoodKarmaConnection:Disconnect() _G.farmGoodKarmaConnection = nil end
	end
end)



Tabs.Killing:AddLabel("👤 Target Killing:")

local blacklistDropdown = Tabs.Killing:AddDropdown("Add to Killlist", function(selectedText)
	local playerName = selectedText:match("| (.+)$")
	if playerName then
		playerName = playerName:gsub("^%s*(.-)%s*$", "%1")
		if not isBlacklisted({Name = playerName}) then table.insert(_G.blacklistedPlayers, playerName) end
	end
end)

for _, player in ipairs(Services.Players:GetPlayers()) do
	if player ~= Services.Players.LocalPlayer then
		whitelistDropdown:Add(player.DisplayName .. " | " .. player.Name)
		blacklistDropdown:Add(player.DisplayName .. " | " .. player.Name)
	end
end

Services.Players.PlayerAdded:Connect(function(player)
	if player ~= Services.Players.LocalPlayer then
		whitelistDropdown:Add(player.DisplayName .. " | " .. player.Name)
		blacklistDropdown:Add(player.DisplayName .. " | " .. player.Name)
	end
end)

Tabs.Killing:AddSwitch("Kill List", function(bool)
	_G.killBlacklistedOnly = bool
	if bool then
		if not _G.blacklistKillConnection then
			_G.blacklistKillConnection = Services.RunService.Heartbeat:Connect(function()
				if _G.killBlacklistedOnly then
					for _, player in ipairs(Services.Players:GetPlayers()) do
						if player ~= Services.Players.LocalPlayer and isBlacklisted(player) then killPlayer(player) end
					end
				end
			end)
		end
	else
		if _G.blacklistKillConnection then _G.blacklistKillConnection:Disconnect() _G.blacklistKillConnection = nil end
	end
end)

local SpectateData = {
	SelectedPlayer = nil,
	SelectedPlayerUserId = nil,
	Spectating = false,
	CurrentTargetConnection = nil,
	LocalPlayerRespawnConnection = nil,
	CameraMonitorLoop = nil
}

getgenv().SpectateState = getgenv().SpectateState or {
	SavedUserId = nil,
	IsSpectating = false
}

local function stopSpectating()
	if SpectateData.CurrentTargetConnection then
		SpectateData.CurrentTargetConnection:Disconnect()
		SpectateData.CurrentTargetConnection = nil
	end
	
	if SpectateData.CameraMonitorLoop then
		SpectateData.CameraMonitorLoop = false
	end

	local localPlayer = Services.Players.LocalPlayer
	if localPlayer.Character then
		local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			PlayerData.Camera.CameraSubject = humanoid
			PlayerData.Camera.CameraType = Enum.CameraType.Custom
		end
	end
	
	if PlayerData.Humanoid then
		PlayerData.Camera.CameraSubject = PlayerData.Humanoid
	end
end

local function startCameraMonitor()
	if SpectateData.CameraMonitorLoop then
		SpectateData.CameraMonitorLoop = false
		task.wait(0.3)
	end
	
	SpectateData.CameraMonitorLoop = true
	
	task.spawn(function()
		while SpectateData.CameraMonitorLoop do
			task.wait(0.2)
			if SpectateData.Spectating and SpectateData.SelectedPlayer then
				local targetChar = SpectateData.SelectedPlayer.Character
				if targetChar then
					local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
					if targetHumanoid then
						if PlayerData.Camera.CameraSubject ~= targetHumanoid then
							PlayerData.Camera.CameraSubject = targetHumanoid
						end
					end
				end
			else
				break
			end
		end
	end)
end

local function updateSpectateTarget(player)
	if not player then
		if SpectateData.SelectedPlayerUserId then
			for _, p in ipairs(Services.Players:GetPlayers()) do
				if p.UserId == SpectateData.SelectedPlayerUserId then
					player = p
					SpectateData.SelectedPlayer = player
					break
				end
			end
		end
		
		if not player and getgenv().SpectateState.SavedUserId then
			for _, p in ipairs(Services.Players:GetPlayers()) do
				if p.UserId == getgenv().SpectateState.SavedUserId then
					player = p
					SpectateData.SelectedPlayer = player
					SpectateData.SelectedPlayerUserId = p.UserId
					break
				end
			end
		end
		
		if not player then
			stopSpectating()
			return
		end
	end

	SpectateData.SelectedPlayerUserId = player.UserId
	SpectateData.SelectedPlayer = player

	if SpectateData.CurrentTargetConnection then
		SpectateData.CurrentTargetConnection:Disconnect()
		SpectateData.CurrentTargetConnection = nil
	end

	local function setCamera(char)
		if not SpectateData.Spectating or SpectateData.SelectedPlayerUserId ~= player.UserId then
			return
		end
		local humanoid = char:WaitForChild("Humanoid", 3)
		if humanoid and SpectateData.Spectating and SpectateData.SelectedPlayerUserId == player.UserId then
			PlayerData.Camera.CameraSubject = humanoid
		end
	end
	
	if player.Character then
		setCamera(player.Character)
	end
	
	SpectateData.CurrentTargetConnection = player.CharacterAdded:Connect(function(newChar)
		if SpectateData.Spectating and SpectateData.SelectedPlayerUserId == player.UserId then
			setCamera(newChar)
		end
	end)
end

local function updatePlayerList()
	return Services.Players:GetPlayers()
end

local specsdropdown = Tabs.Killing:AddDropdown("Choose Player", function(text)
	for _, player in ipairs(updatePlayerList()) do
		local optionText = player.DisplayName .. " | " .. player.Name
		if text == optionText then
			SpectateData.SelectedPlayer = player
			SpectateData.SelectedPlayerUserId = player.UserId
			getgenv().SpectateState.SavedUserId = player.UserId
			if SpectateData.Spectating then
				updateSpectateTarget(player)
			end
			break
		end
	end
end)

Tabs.Killing:AddSwitch("Spectate", function(bool)
	SpectateData.Spectating = bool
	getgenv().SpectateState.IsSpectating = bool

	if SpectateData.Spectating then
		if SpectateData.SelectedPlayerUserId then
			getgenv().SpectateState.SavedUserId = SpectateData.SelectedPlayerUserId
		end
		updateSpectateTarget()
		startCameraMonitor()
	else
		stopSpectating()
		task.wait(0.1)
		local localPlayer = Services.Players.LocalPlayer
		if localPlayer.Character then
			local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				PlayerData.Camera.CameraSubject = humanoid
			end
		end
		getgenv().SpectateState.IsSpectating = false
	end
end)

for _, player in ipairs(updatePlayerList()) do
	specsdropdown:Add(player.DisplayName .. " | " .. player.Name)
end

Services.Players.PlayerAdded:Connect(function(player)
	specsdropdown:Add(player.DisplayName .. " | " .. player.Name)
	if getgenv().SpectateState.IsSpectating and getgenv().SpectateState.SavedUserId == player.UserId then
		SpectateData.Spectating = true
		SpectateData.SelectedPlayer = player
		SpectateData.SelectedPlayerUserId = player.UserId
		updateSpectateTarget(player)
	end
end)

Services.Players.PlayerRemoving:Connect(function(player)
	if player.UserId == SpectateData.SelectedPlayerUserId then
		if SpectateData.Spectating then
			stopSpectating()

			SpectateData.SelectedPlayer = nil
			SpectateData.CurrentTargetConnection = nil
			
			local localPlayer = Services.Players.LocalPlayer
			if localPlayer.Character and PlayerData.Humanoid then
				PlayerData.Camera.CameraSubject = PlayerData.Humanoid
			end
		end
	end
end)

if SpectateData.LocalPlayerRespawnConnection then
	SpectateData.LocalPlayerRespawnConnection:Disconnect()
end

SpectateData.LocalPlayerRespawnConnection = Services.Players.LocalPlayer.CharacterAdded:Connect(function(char)
	local humanoid = char:WaitForChild("Humanoid", 3)
	if humanoid then
		PlayerData.Humanoid = humanoid
	end
	
	task.wait(0.5)
	
	if getgenv().SpectateState.IsSpectating then
		SpectateData.Spectating = true
		updateSpectateTarget()
		startCameraMonitor()
	else
		if PlayerData.Humanoid then
			PlayerData.Camera.CameraSubject = PlayerData.Humanoid
		end
	end
end)

Tabs.Killing:AddLabel("⭕ Kill Aura:")

local KillAura = {RingPart = nil, RingColor = Color3.fromRGB(50, 163, 255), RingTransparency = 0.6}
_G.showDeathRing = false
_G.deathRingRange = 20

Tabs.Killing:AddTextBox("Range (1-140):", function(text)
	if tonumber(text) then
		_G.deathRingRange = math.clamp(tonumber(text), 1, 140)
		if KillAura.RingPart then
			KillAura.RingPart.Size = Vector3.new(0.2, _G.deathRingRange * 2, _G.deathRingRange * 2)
		end
	end
end)

Tabs.Killing:AddSwitch("Show Ring", function(bool)
	_G.showDeathRing = bool
	if bool then
		KillAura.RingPart = Instance.new("Part")
		KillAura.RingPart.Shape = Enum.PartType.Cylinder
		KillAura.RingPart.Material = Enum.Material.Neon
		KillAura.RingPart.Color = KillAura.RingColor
		KillAura.RingPart.Transparency = KillAura.RingTransparency
		KillAura.RingPart.Anchored = true
		KillAura.RingPart.CanCollide = false
		KillAura.RingPart.CastShadow = false
		KillAura.RingPart.Size = Vector3.new(0.2, _G.deathRingRange * 2, _G.deathRingRange * 2)
		KillAura.RingPart.Parent = Services.Workspace
	elseif KillAura.RingPart then
		KillAura.RingPart:Destroy()
		KillAura.RingPart = nil
	end
end)

Tabs.Killing:AddSwitch("Toggle Ring", function(bool)
	_G.deathRingEnabled = bool
	if bool then
		if not _G.deathRingConnection then
			_G.deathRingConnection = Services.RunService.Heartbeat:Connect(function()
				if KillAura.RingPart and checkCharacter():FindFirstChild("HumanoidRootPart") then
					KillAura.RingPart.CFrame = checkCharacter().HumanoidRootPart.CFrame * CFrame.Angles(0, 0, math.rad(90))
				end
				if checkCharacter():FindFirstChild("HumanoidRootPart") then
					for _, player in ipairs(Services.Players:GetPlayers()) do
						if player ~= Services.Players.LocalPlayer and not isWhitelisted(player) and isPlayerAlive(player) then
							if (checkCharacter().HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude <= _G.deathRingRange then
								killPlayer(player)
							end
						end
					end
				end
			end)
		end
	else
		if _G.deathRingConnection then _G.deathRingConnection:Disconnect() _G.deathRingConnection = nil end
	end
end)

Tabs.Killing:AddLabel("🤝 Lend Damage:")

local lendPlayerDropdown = Tabs.Killing:AddDropdown("Choose Player", function(selectedText)
	local playerName = selectedText:match("| (.+)$")
	if playerName then
		_G.LendDamageTarget = Services.Players:FindFirstChild(playerName:gsub("^%s*(.-)%s*$", "%1"))
	end
end)

for _, plr in ipairs(Services.Players:GetPlayers()) do
	if plr ~= Services.Players.LocalPlayer then
		lendPlayerDropdown:Add(plr.DisplayName .. " | " .. plr.Name)
	end
end

Services.Players.PlayerAdded:Connect(function(plr)
	if plr ~= Services.Players.LocalPlayer then
		lendPlayerDropdown:Add(plr.DisplayName .. " | " .. plr.Name)
	end
end)

Services.Players.PlayerRemoving:Connect(function(plr)
	if _G.LendDamageTarget == plr then _G.LendDamageTarget = nil end
	lendPlayerDropdown:Clear()
	for _, p in ipairs(Services.Players:GetPlayers()) do
		if p ~= Services.Players.LocalPlayer then
			lendPlayerDropdown:Add(p.DisplayName .. " | " .. p.Name)
		end
	end
end)

Tabs.Killing:AddSwitch("Lend Damage", function(state)
	_G.LendDamageEnabled = state
	
	if state then
		if not _G.LendDamageConnection then
			_G.LendDamageCooldowns = {}
			_G.LendDamageConnection = Services.RunService.Heartbeat:Connect(function()
				if not _G.LendDamageEnabled or not _G.LendDamageTarget then return end
				
				local helper = _G.LendDamageTarget
				if not helper.Character or not helper.Character:FindFirstChild("HumanoidRootPart") or 
				   not helper.Character:FindFirstChild("Humanoid") or helper.Character.Humanoid.Health <= 0 then return end
				
				for _, handName in ipairs({"LeftHand", "RightHand"}) do
					local hand = helper.Character:FindFirstChild(handName)
					if hand then
						for _, touchPart in ipairs(hand:GetTouchingParts()) do
							local touchModel = touchPart:FindFirstAncestorOfClass("Model")
							local touchPlayer = Services.Players:GetPlayerFromCharacter(touchModel)
							
							if touchPlayer and touchPlayer ~= helper and touchPlayer ~= Services.Players.LocalPlayer and
							   touchPlayer.Character and touchPlayer.Character:FindFirstChild("HumanoidRootPart") and
							   touchPlayer.Character:FindFirstChild("Humanoid") and touchPlayer.Character.Humanoid.Health > 0 then
								
								local now = tick()
								if not _G.LendDamageCooldowns[touchPlayer.UserId] or now - _G.LendDamageCooldowns[touchPlayer.UserId] > 0.25 then
									_G.LendDamageCooldowns[touchPlayer.UserId] = now
									
									if PlayerData.Character and PlayerData.Character:FindFirstChild("LeftHand") then
										pcall(function()
											firetouchinterest(touchPlayer.Character.HumanoidRootPart, PlayerData.Character.LeftHand, 0)
											firetouchinterest(touchPlayer.Character.HumanoidRootPart, PlayerData.Character.LeftHand, 1)
											gettool()
										end)
									end
								end
							end
						end
					end
				end
			end)
		end
	else
		if _G.LendDamageConnection then
			_G.LendDamageConnection:Disconnect()
			_G.LendDamageConnection = nil
		end
		_G.LendDamageCooldowns = {}
	end
end)

local whitelistLabel = Tabs.Killing:AddLabel("Whitelist: None")
whitelistLabel.TextSize = 14
Tabs.Killing:AddButton("Clear Whitelist", function() _G.whitelistedPlayers = {} end)

local blacklistLabel = Tabs.Killing:AddLabel("Killlist: None")
blacklistLabel.TextSize = 14
Tabs.Killing:AddButton("Clear Killlist", function() _G.blacklistedPlayers = {} end)

task.spawn(function()
	while true do
		whitelistLabel.Text = #_G.whitelistedPlayers == 0 and "Whitelist: None" or "Whitelist: " .. table.concat(_G.whitelistedPlayers, ", ")
		blacklistLabel.Text = #_G.blacklistedPlayers == 0 and "Killlist: None" or "Killlist: " .. table.concat(_G.blacklistedPlayers, ", ")
		task.wait(0.01)
	end
end)

Tabs.Farming:AddLabel("⚙️ Misc:")

Tabs.Farming:AddSwitch("Auto Lift (Gamepass)", function(bool)
	if bool then
		for _, gamepass in pairs(Services.ReplicatedStorage.gamepassIds:GetChildren()) do
			local value = Instance.new("IntValue")
			value.Name = gamepass.Name
			value.Value = gamepass.Value
			value.Parent = PlayerData.Player.ownedGamepasses
		end
	else
		for _, gamepass in pairs(Services.ReplicatedStorage.gamepassIds:GetChildren()) do
			if PlayerData.Player.ownedGamepasses:FindFirstChild(gamepass.Name) and 
			   PlayerData.Player.ownedGamepasses[gamepass.Name].Value == gamepass.Value then
				PlayerData.Player.ownedGamepasses[gamepass.Name]:Destroy()
			end
		end
	end
end)

local PunchData = {AutoPunching = false}

Tabs.Farming:AddSwitch("Auto Punch (without animation)", function(enabled)
	PunchData.AutoPunching = enabled
	if enabled then
		task.spawn(function()
			local tool = PlayerData.Backpack:FindFirstChild("Punch") or PlayerData.Character:FindFirstChild("Punch")
			if not tool then repeat tool = PlayerData.Backpack:FindFirstChild("Punch") or PlayerData.Character:FindFirstChild("Punch") task.wait(0.1) until tool end
			if tool.Parent == PlayerData.Backpack then tool.Parent = PlayerData.Character end
			while PunchData.AutoPunching do
				if PlayerData.Player:FindFirstChild("muscleEvent") then
					PlayerData.Player.muscleEvent:FireServer("punch", "leftHand")
					PlayerData.Player.muscleEvent:FireServer("punch", "rightHand")
				end
				task.wait(0.2)
			end
		end)
	else
		if PlayerData.Character:FindFirstChild("Punch") then PlayerData.Character.Punch.Parent = PlayerData.Backpack end
	end
end)

local EggData = {Running = false}

task.spawn(function()
	while true do
		if EggData.Running then
			local tool = PlayerData.Player.Character:FindFirstChild("Protein Egg") or PlayerData.Player.Backpack:FindFirstChild("Protein Egg")
			if tool then PlayerData.Player.muscleEvent:FireServer("proteinEgg", tool) end
			task.wait(1800)
		else
			task.wait(1)
		end
	end
end)

Tabs.Farming:AddSwitch("Auto Egg (30 min)", function(state) EggData.Running = state end)

Tabs.Farming:AddLabel("🔄️ Rebirths:")

local RebirthData = {
	Label = Tabs.Farming:AddLabel("Rebirths: 0"),
	TargetLabel = Tabs.Farming:AddLabel("Target: None"),
	Rebirths = PlayerData.Player.leaderstats:WaitForChild("Rebirths"),
	TargetRebirths = 0,
	IsAutoRebirthing = false
}

RebirthData.Label.TextSize = 14
RebirthData.TargetLabel.TextSize = 14

Tabs.Farming:AddTextBox("Set Rebirth Target (Required):", function(text)
	if tonumber(text) and tonumber(text) >= 0 then RebirthData.TargetRebirths = tonumber(text) end
end)

RebirthData.Switch = Tabs.Farming:AddSwitch("Auto Rebirth", function(enabled)
	if enabled and RebirthData.TargetRebirths > 0 and RebirthData.Rebirths.Value < RebirthData.TargetRebirths then
		RebirthData.IsAutoRebirthing = true
		task.spawn(function()
			while RebirthData.IsAutoRebirthing and RebirthData.Rebirths.Value < RebirthData.TargetRebirths do
				Services.ReplicatedStorage.rEvents.rebirthRemote:InvokeServer("rebirthRequest")
				task.wait(0.05)
			end
			RebirthData.IsAutoRebirthing = false
			RebirthData.Switch:Set(false)
		end)
	else
		RebirthData.IsAutoRebirthing = false
	end
end)

task.spawn(function()
	while true do
		RebirthData.Label.Text = "Rebirths: " .. Utils.formatWithCommas(RebirthData.Rebirths.Value)
		RebirthData.TargetLabel.Text = "Target Rebirths: " .. Utils.formatWithCommas(RebirthData.TargetRebirths)
		task.wait(0.01)
	end
end)

local SizeData = {Active = false}

Tabs.Farming:AddSwitch("Auto Size 1", function(bool) SizeData.Active = bool end):Set(false)

task.spawn(function()
	while true do
		if SizeData.Active and PlayerData.Character and PlayerData.Humanoid then
			Remotes.ChangeSpeedSize:InvokeServer("changeSize", 1)
		end
		task.wait(0.01)
	end
end)

local KingData = {TargetPosition = CFrame.new(-8665.4, 17.21, -5792.9), TeleportActive = false}

Tabs.Farming:AddSwitch("Auto King", function(enabled)
	KingData.TeleportActive = enabled
end)

task.spawn(function()
	while true do
		if KingData.TeleportActive then
			if not PlayerData.Character or not PlayerData.Character:FindFirstChildOfClass("Humanoid") then
				PlayerData.Player.CharacterAdded:Wait()
				PlayerData.Character = PlayerData.Player.Character
				task.wait(2)
			end

			if not PlayerData.Humanoid or PlayerData.Humanoid.Health <= 0 then
				repeat
					task.wait(0.5)
					PlayerData.Character = PlayerData.Player.Character
					PlayerData.Humanoid = PlayerData.Character and PlayerData.Character:FindFirstChildOfClass("Humanoid")
				until PlayerData.Character and PlayerData.Humanoid and PlayerData.Humanoid.Health > 0
				task.wait(1)
			end

			if PlayerData.Character and PlayerData.Character:FindFirstChild("HumanoidRootPart") then
				if (PlayerData.Character.HumanoidRootPart.Position - KingData.TargetPosition.Position).magnitude > 5 then
					pcall(function() 
						PlayerData.Character.HumanoidRootPart.CFrame = KingData.TargetPosition 
					end)
				end
			end
		end
		task.wait(0.05)
	end
end)

Tabs.Farming:AddLabel("🦾 Auto Exercises (recommended for rebirthing):")

local ExerciseData = {
	SelectedTool = nil,
	AutoFarm = false
}

local toolDropdown = Tabs.Farming:AddDropdown("Select Exercise", function(selection)
	ExerciseData.SelectedTool = selection
end)
for _, tool in ipairs({"Weight", "Pushups", "Situps", "Handstands"}) do 
	toolDropdown:Add(tool)
end

Tabs.Farming:AddSwitch("Start exercising", function(enabled)
	ExerciseData.AutoFarm = enabled

	if enabled then
		task.spawn(function()
			while ExerciseData.AutoFarm do
				if not PlayerData.Character or not PlayerData.Character:FindFirstChildOfClass("Humanoid") then
					PlayerData.Player.CharacterAdded:Wait()
					PlayerData.Character = PlayerData.Player.Character
					task.wait(2)
				end

				if not PlayerData.Humanoid or PlayerData.Humanoid.Health <= 0 then
					repeat
						task.wait(0.5)
						PlayerData.Character = PlayerData.Player.Character
						PlayerData.Humanoid = PlayerData.Character and PlayerData.Character:FindFirstChildOfClass("Humanoid")
					until PlayerData.Character and PlayerData.Humanoid and PlayerData.Humanoid.Health > 0
					task.wait(1)
				end

				if PlayerData.Character and ExerciseData.SelectedTool then
					local toolName = ExerciseData.SelectedTool

					if not PlayerData.Character:FindFirstChild(toolName) then
						local toolInBackpack = PlayerData.Player.Backpack:FindFirstChild(toolName)
						if toolInBackpack then
							PlayerData.Humanoid:EquipTool(toolInBackpack)
							task.wait(0.2)
						end
					end

					if PlayerData.Character:FindFirstChild(toolName) then
						pcall(function()
							PlayerData.Player.muscleEvent:FireServer("rep")
						end)
					end

					if toolName == "Handstands" and tick() % 6 < 0.1 then
						pcall(function()
							Services.VirtualUser:CaptureController()
							Services.VirtualUser:ClickButton1(Vector2.new(500, 500))
						end)
					end
				end

				task.wait()
			end
		end)
	else
		if ExerciseData.SelectedTool and PlayerData.Player.Character then
			local equippedTool = PlayerData.Player.Character:FindFirstChild(ExerciseData.SelectedTool)
			if equippedTool then
				equippedTool.Parent = PlayerData.Player.Backpack
			end
		end
	end
end)

Tabs.Farming:AddLabel("👾 Glitching:")

local RockData = {
	Data = {["Tiny Rock - 0 Dura"] = 0, ["Large Rock - 100 Dura"] = 100, ["Punching Rock - 10 Dura"] = 10,
		["Golden Rock - 5k Dura"] = 5000, ["Frost Rock - 150k Dura"] = 150000, ["Mythical Rock - 400k Dura"] = 400000,
		["Eternal Rock - 750k Dura"] = 750000, ["Legend Rock - 1m Dura"] = 1000000, ["Muscle King Rock - 5m Dura"] = 5000000,
		["Jungle Rock - 10m Dura"] = 10000000},
	SelectedRock = nil
}

local rockDropdown = Tabs.Farming:AddDropdown("Select Rock", function(selection) RockData.SelectedRock = selection end)
for rockName in pairs(RockData.Data) do rockDropdown:Add(rockName) end

Tabs.Farming:AddSwitch("Auto Rock", function(enabled)
	getgenv().RockFarmRunning = enabled
	if enabled and RockData.SelectedRock then
		task.spawn(function()
			while getgenv().RockFarmRunning do
				task.wait(0.12)
				if PlayerData.Player.Durability.Value >= RockData.Data[RockData.SelectedRock] then
					for _, v in pairs(Services.Workspace.machinesFolder:GetDescendants()) do
						if v.Name == "neededDurability" and v.Value == RockData.Data[RockData.SelectedRock] and 
						   PlayerData.Player.Character:FindFirstChild("LeftHand") and v.Parent:FindFirstChild("Rock") then
							firetouchinterest(v.Parent.Rock, PlayerData.Player.Character.RightHand, 0)
							firetouchinterest(v.Parent.Rock, PlayerData.Player.Character.RightHand, 1)
							firetouchinterest(v.Parent.Rock, PlayerData.Player.Character.LeftHand, 0)
							firetouchinterest(v.Parent.Rock, PlayerData.Player.Character.LeftHand, 1)
							gettool()
						end
					end
				end
			end
		end)
	end
end)

Tabs.Farming:AddButton("Anti Lag (for everything)", function()
	for _, v in pairs(Services.Lighting:GetChildren()) do if v:IsA("Sky") then v:Destroy() end end
	local darkSky = Instance.new("Sky")
	darkSky.Name = "DarkSky"
	darkSky.SkyboxBk = "rbxassetid://0"
	darkSky.SkyboxDn = "rbxassetid://0"
	darkSky.SkyboxFt = "rbxassetid://0"
	darkSky.SkyboxLf = "rbxassetid://0"
	darkSky.SkyboxRt = "rbxassetid://0"
	darkSky.SkyboxUp = "rbxassetid://0"
	darkSky.Parent = Services.Lighting
	Services.Lighting.Brightness = 0
	Services.Lighting.ClockTime = 0
	Services.Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
	Services.Lighting.Ambient = Color3.new(0, 0, 0)
	Services.Lighting.FogColor = Color3.new(0, 0, 0)
	Services.Lighting.FogEnd = 100
	for _, obj in pairs(Services.Workspace:GetDescendants()) do
		if obj:IsA("ParticleEmitter") or obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
			obj:Destroy()
		end
	end
end)

Tabs.Farming:AddLabel("🔥 Better Strength Farming:")

local farmingConfigs = {
	{name = "Pushup + Jungle Rock", tool = "Pushups", rock = "Ancient Jungle Rock"},
	{name = "Pushup + Muscle King Rock", tool = "Pushups", rock = "Muscle King Mountain"},
	{name = "Pushup + Legends Rock", tool = "Pushups", rock = "Rock Of Legends"}
}

for _, config in ipairs(farmingConfigs) do
	local isActive = false
	Tabs.Farming:AddSwitch(config.name, function(state)
		isActive = state
		if isActive then
			if PlayerData.Player.Backpack:FindFirstChild(config.tool) and not PlayerData.Player.Character:FindFirstChild(config.tool) then
				PlayerData.Player.Character.Humanoid:EquipTool(PlayerData.Player.Backpack[config.tool])
			end
			task.spawn(function()
				while isActive do
					PlayerData.Player.muscleEvent:FireServer("rep")
					if Services.Workspace.machinesFolder:FindFirstChild(config.rock) and PlayerData.Player.Character:FindFirstChild("LeftHand") then
						firetouchinterest(Services.Workspace.machinesFolder[config.rock].Rock, PlayerData.Player.Character.LeftHand, 0)
						firetouchinterest(Services.Workspace.machinesFolder[config.rock].Rock, PlayerData.Player.Character.LeftHand, 1)
					end
					if PlayerData.Player.Backpack:FindFirstChild("Punch") then
						PlayerData.Humanoid:EquipTool(PlayerData.Player.Backpack.Punch)
						PlayerData.Player.muscleEvent:FireServer("punch", "rightHand")
						PlayerData.Player.muscleEvent:FireServer("punch", "leftHand")
					end
					Services.RunService.RenderStepped:Wait()
					if PlayerData.Player.Backpack:FindFirstChild(config.tool) then
						PlayerData.Player.Character.Humanoid:EquipTool(PlayerData.Player.Backpack[config.tool])
					end
				end
			end)
		else
			if PlayerData.Player.Character:FindFirstChild(config.tool) then
				PlayerData.Player.Character[config.tool].Parent = PlayerData.Player.Backpack
			end
		end
	end)
end

Tabs.Inventory:AddLabel("🍫 Boost Eater:")

local EggEaterData = {Running = false}

task.spawn(function()
	while true do
		if EggEaterData.Running then
			local tool = PlayerData.Player.Character:FindFirstChild("Protein Egg") or PlayerData.Player.Backpack:FindFirstChild("Protein Egg")
			if tool then PlayerData.Player.muscleEvent:FireServer("proteinEgg", tool) end
			task.wait(0.25)
		else
			task.wait(1)
		end
	end
end)

Tabs.Inventory:AddSwitch("Eat All Eggs", function(state) EggEaterData.Running = state end):Set(false)

local BoostData = {
	ItemList = {"Tropical Shake", "Energy Shake", "Protein Bar", "TOUGH Bar", "Protein Shake", "ULTRA Shake", "Energy Bar"},
	Running = false
}

task.spawn(function()
	while true do
		if BoostData.Running then
			for _, itemName in ipairs(BoostData.ItemList) do
				local tool = PlayerData.Player.Character:FindFirstChild(itemName) or PlayerData.Player.Backpack:FindFirstChild(itemName)
				if tool then
					local parts = {}
					for word in itemName:gmatch("%S+") do table.insert(parts, word:lower()) end
					for i = 2, #parts do parts[i] = parts[i]:sub(1, 1):upper() .. parts[i]:sub(2) end
					for i = 1, 10 do PlayerData.Player.muscleEvent:FireServer(table.concat(parts), tool) end
				end
			end
		end
		task.wait(0.1)
	end
end)

Tabs.Inventory:AddSwitch("Eat all Boosts (expect lag)", function(state) BoostData.Running = state end)

Tabs.Inventory:AddLabel("🛒 Pet Shop:")

local PetShopData = {
	SelectedPet = nil,
	PetList = {"Darkstar Hunter", "Neon Guardian", "Cybernetic Showdown Dragon", "Blue Birdie", "Blue Bunny", "Blue Firecaster",
		"Blue Pheonix", "Crimson Falcon", "Dark Golem", "Dark Legends Manticore", "Dark Vampy", "Eternal Strike Leviathan",
		"Frostwave Legends Penguin", "Gold Warrior", "Golden Pheonix", "Golden Viking", "Green Butterfly", "Green Firecaster",
		"Infernal Dragon", "Lightning Strike Phantom", "Magic Butterfly", "Muscle Sensei", "Orange Hedgehog", "Orange Pegasus",
		"Phantom Genesis Dragon", "Purple Dragon", "Purple Falcon", "Red Dragon", "Red Firecaster", "Red Kitty", "Silver Dog",
		"Ultimate Supernova Pegasus", "Ultra Birdie", "White Pegasus", "White Pheonix", "Yellow Butterfly"}
}

local petDropdown = Tabs.Inventory:AddDropdown("Choose Pet", function(text) PetShopData.SelectedPet = text end)
for _, petName in ipairs(PetShopData.PetList) do petDropdown:Add(petName) end

Tabs.Inventory:AddSwitch("Buy Pet", function(bool)
	_G.AutoHatchPet = bool
	if bool then
		spawn(function()
			while _G.AutoHatchPet and PetShopData.SelectedPet ~= "" do
				if Services.ReplicatedStorage.cPetShopFolder:FindFirstChild(PetShopData.SelectedPet) then
					Services.ReplicatedStorage.cPetShopRemote:InvokeServer(Services.ReplicatedStorage.cPetShopFolder[PetShopData.SelectedPet])
				end
				task.wait(0.1)
			end
			end)
	end
end)

Tabs.Inventory:AddLabel("Auras:").TextSize = 22

local AuraData = {
	SelectedAura = nil,
	AuraList = {"Entropic Blast", "Muscle King", "Dark Storm", "Astral Electro", "Azure Tundra", "Blue Aura", "Dark Electro",
		"Dark Lightning", "Electro", "Enchanted Mirage", "Eternal Megastrike", "Grand Supernova", "Green Aura", "Inferno",
		"Lightning", "Power Lightning", "Purple Aura", "Purple Nova", "Red Aura", "Supernova", "Ultra Inferno", "Ultra Mirage",
		"Unstable Mirage", "Yellow Aura"}
}

local auraDropdown = Tabs.Inventory:AddDropdown("Select Aura", function(text) AuraData.SelectedAura = text end)
for _, auraName in ipairs(AuraData.AuraList) do auraDropdown:Add(auraName) end

Tabs.Inventory:AddSwitch("Buy Aura", function(bool)
	_G.AutoHatchAura = bool
	if bool then
		spawn(function()
			while _G.AutoHatchAura and AuraData.SelectedAura ~= "" do
				if Services.ReplicatedStorage.cPetShopFolder:FindFirstChild(AuraData.SelectedAura) then
					Services.ReplicatedStorage.cPetShopRemote:InvokeServer(Services.ReplicatedStorage.cPetShopFolder[AuraData.SelectedAura])
				end
				task.wait(0.1)
			end
		end)
	end
end)

Tabs.Inventory:AddLabel("You need Gems and Inventory Space!").TextSize = 14

Tabs.Inventory:AddLabel("🔃 Auto Evolving:")

local petDropdown3 = Tabs.Inventory:AddDropdown("Choose Pet", function(text) PetShopData.SelectedPet = text end)
for _, petName in ipairs(PetShopData.PetList) do petDropdown3:Add(petName) end

local running = false

Tabs.Inventory:AddSwitch("Auto Evolve", function(state)
    running = state
    if not state then return end

    task.spawn(function()
        while running do
            if PetShopData.SelectedPet then
                game.ReplicatedStorage.rEvents.petEvolveEvent:FireServer(
                    "evolvePet",
                    PetShopData.SelectedPet
                )
            end
            task.wait(0.5)
        end
    end)
end)



Tabs.Inventory:AddLabel("🔁 Auto Trading:")

local TradeData = {SelectedPlayer = nil}

local playerDropdown4 = Tabs.Inventory:AddDropdown("Choose Player", function(name)
    local username = name:match(" | (.+)") or name
    TradeData.SelectedPlayer = Services.Players:FindFirstChild(username)
end)

for _, player in ipairs(Services.Players:GetPlayers()) do
    if player ~= Services.Players.LocalPlayer then
        playerDropdown4:Add(player.DisplayName .. " | " .. player.Name)
    end
end

Services.Players.PlayerAdded:Connect(function(player)
    if player ~= Services.Players.LocalPlayer then
        playerDropdown4:Add(player.DisplayName .. " | " .. player.Name)
    end
end)

Services.Players.PlayerRemoving:Connect(function(player)
    playerDropdown4:Remove(player.DisplayName .. " | " .. player.Name)
    if TradeData.SelectedPlayer == player then TradeData.SelectedPlayer = nil end
end)

local petDropdown2 = Tabs.Inventory:AddDropdown("Choose Pet", function(text) PetShopData.SelectedPet = text end)
for _, petName in ipairs(PetShopData.PetList) do petDropdown2:Add(petName) end



local running = false

Tabs.Inventory:AddSwitch("Auto Trade", function(state)
    running = state
    if not state then return end

    task.spawn(function()
        while running do
            if TradeData.SelectedPlayer and PetShopData.SelectedPet then
                local tradingEvent = game.ReplicatedStorage.rEvents.tradingEvent
                local unique = game.Players.LocalPlayer.petsFolder.Unique

                tradingEvent:FireServer(
                    "sendTradeRequest",
                    TradeData.SelectedPlayer
                )

                task.wait(0.5)

                local offered = 0
                for _, pet in ipairs(unique:GetChildren()) do
                    if not running then break end

                    if pet.Name == PetShopData.SelectedPet then
                        tradingEvent:FireServer("offerItem", pet)
                        offered += 1
                        task.wait(0.01)

                        if offered >= 6 then
                            break
                        end
                    end
                end

                task.wait(0.05)


                if running then
                    tradingEvent:FireServer("acceptTrade")
                end
            end

            task.wait(2)
        end
    end)
end)





Tabs.Inventory:AddLabel("🥚 Egg Gifter:")

local EggGifterData = {ProteinEggLabel = Tabs.Inventory:AddLabel("Protein Eggs: 0"), SelectedPlayer = nil, EggCount = 0}
EggGifterData.ProteinEggLabel.TextSize = 14

local playerDropdown = Tabs.Inventory:AddDropdown("Choose Player", function(name)
    local username = name:match(" | (.+)") or name
    EggGifterData.SelectedPlayer = Services.Players:FindFirstChild(username)
end)

for _, player in ipairs(Services.Players:GetPlayers()) do
    if player ~= Services.Players.LocalPlayer then
        playerDropdown:Add(player.DisplayName .. " | " .. player.Name)
    end
end

Services.Players.PlayerAdded:Connect(function(player)
    if player ~= Services.Players.LocalPlayer then
        playerDropdown:Add(player.DisplayName .. " | " .. player.Name)
    end
end)

Services.Players.PlayerRemoving:Connect(function(player)
    playerDropdown:Remove(player.DisplayName .. " | " .. player.Name)
    if EggGifterData.SelectedPlayer == player then EggGifterData.SelectedPlayer = nil end
end)

Tabs.Inventory:AddTextBox("Amount:", function(Text) EggGifterData.EggCount = tonumber(Text) end)

Tabs.Inventory:AddButton("Start Gifting", function()
    if EggGifterData.SelectedPlayer and EggGifterData.EggCount and EggGifterData.EggCount > 0 then
        local egg = Services.Players.LocalPlayer.consumablesFolder:FindFirstChild("Protein Egg")
        if egg then
            for i = 1, EggGifterData.EggCount do
                pcall(function()
                    Services.ReplicatedStorage.rEvents.giftRemote:InvokeServer("giftRequest", EggGifterData.SelectedPlayer, egg)
                end)
                task.wait(0.1)
            end
        end
    end
end)

Tabs.Inventory:AddLabel("🍹 Shake Gifter:")

local ShakeGifterData = {TropicalShakeLabel = Tabs.Inventory:AddLabel("Tropical Shakes: 0"), SelectedPlayer = nil, ShakeCount = 0}
ShakeGifterData.TropicalShakeLabel.TextSize = 14

local playerDropdown3 = Tabs.Inventory:AddDropdown("Choose Player", function(name)
	local usernameone = name:match(" | (.+)") or name
	ShakeGifterData.SelectedPlayer = Services.Players:FindFirstChild(usernameone)
end)

for _, player in ipairs(Services.Players:GetPlayers()) do
	if player ~= Services.Players.LocalPlayer then
		playerDropdown3:Add(player.DisplayName .. " | " .. player.Name)
	end
end

Services.Players.PlayerAdded:Connect(function(player)
	if player ~= Services.Players.LocalPlayer then
		playerDropdown3:Add(player.DisplayName .. " | " .. player.Name)
	end
end)

Services.Players.PlayerRemoving:Connect(function(player)
	playerDropdown3:Remove(player.DisplayName .. " | " .. player.Name)
	if ShakeGifterData.SelectedPlayer == player then ShakeGifterData.SelectedPlayer = nil end
end)

Tabs.Inventory:AddTextBox("Amount:", function(Text) ShakeGifterData.ShakeCount = tonumber(Text) end)

Tabs.Inventory:AddButton("Start Gifting", function()
	if ShakeGifterData.SelectedPlayer and ShakeGifterData.ShakeCount and ShakeGifterData.ShakeCount > 0 then
		for i = 1, ShakeGifterData.ShakeCount do
			Services.ReplicatedStorage.rEvents.giftRemote:InvokeServer("giftRequest", ShakeGifterData.SelectedPlayer, 
				Services.Players.LocalPlayer.consumablesFolder:FindFirstChild("Tropical Shake"))
		end
	end
end)

task.spawn(function()
	while true do
		local proteinEggCount = 0
		local tropicalShakeCount = 0
		if PlayerData.Backpack then
			for _, item in ipairs(PlayerData.Backpack:GetChildren()) do
				if item.Name == "Protein Egg" then proteinEggCount = proteinEggCount + 1
				elseif item.Name == "Tropical Shake" then tropicalShakeCount = tropicalShakeCount + 1 end
			end
		end
		EggGifterData.ProteinEggLabel.Text = "Protein Eggs: " .. proteinEggCount
		ShakeGifterData.TropicalShakeLabel.Text = "Tropical Shakes: " .. tropicalShakeCount
		task.wait(7.5)
	end
end)

Tabs.Inventory:AddLabel("Interferes with Boosts you got gifted. Get on a machine for less Lag!").TextSize = 14

Tabs.Teleport:AddLabel("🏖️ Main:")

local teleportLocations = {
	{name = "Tiny Island", pos = CFrame.new(-37.1, 9.2, 1919)},
	{name = "Main Island", pos = CFrame.new(16.07, 9.08, 133.8)},
	{name = "Beach", pos = CFrame.new(-8, 9, -169.2)}
}

for _, loc in ipairs(teleportLocations) do
	Tabs.Teleport:AddButton(loc.name, function()
		if PlayerData.Player.Character and PlayerData.Player.Character:FindFirstChild("HumanoidRootPart") then
			PlayerData.Player.Character.HumanoidRootPart.CFrame = loc.pos
		end
	end)
end

Tabs.Teleport:AddLabel("🏋️ Gyms:")

local gymLocations = {
	{name = "Muscle King Gym", pos = CFrame.new(-8665.4, 17.21, -5792.9)},
	{name = "Jungle Gym", pos = CFrame.new(-8543, 6.8, 2400)},
	{name = "Legends Gym", pos = CFrame.new(4516, 991.5, -3856)},
	{name = "Infernal Gym", pos = CFrame.new(-6759, 7.36, -1284)},
	{name = "Mythical Gym", pos = CFrame.new(2250, 7.37, 1073.2)},
	{name = "Frost Gym", pos = CFrame.new(-2623, 7.36, -409)}
}

for _, gym in ipairs(gymLocations) do
	Tabs.Teleport:AddButton(gym.name, function()
		if PlayerData.Player.Character and PlayerData.Player.Character:FindFirstChild("HumanoidRootPart") then
			PlayerData.Player.Character.HumanoidRootPart.CFrame = gym.pos
		end
	end)
end

Tabs.Stats:AddLabel(SpecsData.EmojiMap["Time"] .. " Elapsed Time:").TextSize = 18

local StatsData = {
	StopwatchLabel = Tabs.Stats:AddLabel("➡️ 0d 0h 0m 0s"),
	StartTime = tick(),
	Leaderstats = PlayerData.Player:WaitForChild("leaderstats"),
	Stats = {},
	InitialValues = {},
	StatLabels = {}
}

StatsData.StopwatchLabel.TextSize = 16
Tabs.Stats:AddLabel("")
Tabs.Stats:AddLabel(SpecsData.EmojiMap["Stats"] .. " Stats:").TextSize = 18

task.spawn(function()
	while true do
		local elapsedTime = tick() - StatsData.StartTime
		local days = math.floor(elapsedTime / (24 * 3600))
		local hours = math.floor((elapsedTime % (24 * 3600)) / 3600)
		local minutes = math.floor((elapsedTime % 3600) / 60)
		local seconds = math.floor(elapsedTime % 60)
		StatsData.StopwatchLabel.Text = string.format("➡️ %dd %dh %dm %ds", days, hours, minutes, seconds)
		task.wait(0.1)
	end
end)

StatsData.Stats = {
	{name = SpecsData.EmojiMap["Strength"] .. " Strength", stat = StatsData.Leaderstats:WaitForChild("Strength")},
	{name = SpecsData.EmojiMap["Rebirths"] .. " Rebirths", stat = StatsData.Leaderstats:WaitForChild("Rebirths")},
	{name = SpecsData.EmojiMap["Durability"] .. " Durability", stat = PlayerData.Player:WaitForChild("Durability")},
	{name = SpecsData.EmojiMap["Kills"] .. " Kills", stat = StatsData.Leaderstats:WaitForChild("Kills")},
	{name = SpecsData.EmojiMap["Agility"] .. " Agility", stat = PlayerData.Player:WaitForChild("Agility")},
	{name = SpecsData.EmojiMap["Evil Karma"] .. " Evil Karma", stat = PlayerData.Player:WaitForChild("evilKarma")},
	{name = SpecsData.EmojiMap["Good Karma"] .. " Good Karma", stat = PlayerData.Player:WaitForChild("goodKarma")},
	{name = SpecsData.EmojiMap["Brawls"] .. " Brawls", stat = StatsData.Leaderstats:WaitForChild("Brawls")}
}

for _, info in ipairs(StatsData.Stats) do
	StatsData.InitialValues[info.name] = info.stat.Value
	StatsData.StatLabels[info.name] = Tabs.Stats:AddLabel("")
	StatsData.StatLabels[info.name].TextSize = 16
end

while true do
	for _, info in ipairs(StatsData.Stats) do
		local currentValue = info.stat.Value
		local gained = currentValue - StatsData.InitialValues[info.name]
		StatsData.StatLabels[info.name].Text = string.format("%s: %s (%s) | Gained: %s (%s)", info.name,
			Utils.formatNumber(currentValue), Utils.formatWithCommas(currentValue),
			Utils.formatNumber(gained), Utils.formatWithCommas(gained))
	end
	wait(0.1)
end
