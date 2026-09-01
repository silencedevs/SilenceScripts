--[[
    Silence - Ml Main
    by Henne @xyzhenrik_
]]

local Services = {
	Players = game:GetService("Players"),
	ReplicatedStorage = game:GetService("ReplicatedStorage"),
	VirtualUser = game:GetService("VirtualUser"),
	Workspace = workspace,
	Lighting = game:GetService("Lighting"),
	UserInputService = game:GetService("UserInputService"),
	VirtualInputManager = game:GetService("VirtualInputManager"),
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
	if n >= 1e18 then return string.format("%.1fqi", n / 1e18)
	elseif n >= 1e15 then return string.format("%.1fqa", n / 1e15)
	elseif n >= 1e12 then return string.format("%.1ft", n / 1e12)
	elseif n >= 1e9 then return string.format("%.1fb", n / 1e9)
	elseif n >= 1e6 then return string.format("%.1fm", n / 1e6)
	elseif n >= 1e3 then return string.format("%.1fk", n / 1e3)
	else return tostring(n) end
end

function Utils.formatWithCommas(n)
	local formatted = tostring(math.floor(n))
	while true do
		formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1.%2")
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

local function deleteAds()
	for _, portal in pairs(game:GetDescendants()) do
		if portal.Name == "RobloxForwardPortals" then
			portal:Destroy()
		end
	end
	if _G.ads then
		_G.ads:Disconnect()
	end

	_G.ads = game.DescendantAdded:Connect(function(descendant)
		if descendant.Name == "RobloxForwardPortals" then
			descendant:Destroy()
		end
	end)
end
deleteAds()

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/silencedevs/SilenceScripts/refs/heads/main/librarys/eleriumv2.luau", true))()

local window = library:AddWindow("Silence | Main - " .. Utils.greeting(), {
	main_color = Color3.fromRGB(138, 0, 0),
	min_size = Vector2.new(494, 780),
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
Tabs.Info:AddLabel("Made by Henne")
Tabs.Info:AddLabel("Any issues? Ping @xyzhenrik_ on Discord")
Tabs.Info:AddLabel("Official Discord: discord.gg/9eFf93Kg8D")
Tabs.Info:AddButton("Copy Invite", function()
	if setclipboard then
		setclipboard("https://discord.gg/9eFf93Kg8D")
		game.StarterGui:SetCore("SendNotification", {Title = "Link Copied!", Text = "You can continue to Discord now.", Duration = 3})
	else
		game.StarterGui:SetCore("SendNotification", {Title = "Error!", Text = "Clipboard not Supported.", Duration = 3})
	end
end)

local wLabel = Tabs.Info:AddLabel("Muscle Legends [V4.0.0]")
wLabel.TextSize = 20
wLabel.Font = Enum.Font.Arcade

Tabs.Main:AddLabel("User Settings:")

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
end, {clear = false})

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
end, {clear = false})

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
	end, {clear = false})

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

Tabs.Main:AddLabel("Protection and Visuals:")

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

local VisibilitySettings = {
	HidePets = false,
	HidePopups = true,
	ShowPetsEvent = Services.ReplicatedStorage.rEvents:WaitForChild("showPetsEvent"),
	SavePlayerSizeEvent = Services.ReplicatedStorage.rEvents:WaitForChild("savePlayerSizeEvent")
}

Tabs.Main:AddSwitch("Hide Pets", function(state)
	VisibilitySettings.HidePets = state
	VisibilitySettings.ShowPetsEvent:FireServer(state and "hidePets" or "showPets")
end):Set(true)

VisibilitySettings.HidePopupsSwitch = Tabs.Main:AddSwitch("Hide Popups", function(state)
	VisibilitySettings.HidePopups = state
	VisibilitySettings.SavePlayerSizeEvent:FireServer("showPopupsOption")
end)
VisibilitySettings.HidePopupsSwitch:Set(true)

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

Tabs.Main:AddLabel("Other:")

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

local FortuneWheelData = {
	Running = false,
	Generation = 0,
	Remote = Services.ReplicatedStorage.rEvents:WaitForChild("openFortuneWheelRemote"),
	Chances = Services.ReplicatedStorage
		:WaitForChild("shared")
		:WaitForChild("catalogs")
		:WaitForChild("fortuneWheelChances")
		:WaitForChild("Fortune Wheel")
}

local function spinFortuneWheel()
	pcall(function()
		FortuneWheelData.Remote:InvokeServer(
			"openFortuneWheel",
			FortuneWheelData.Chances
		)
	end)
end

Tabs.Main:AddSwitch("Spin Fortune Wheel", function(state)
	FortuneWheelData.Running = state
	FortuneWheelData.Generation += 1
	local generation = FortuneWheelData.Generation

	if not state then return end

	task.spawn(function()
		while FortuneWheelData.Running and FortuneWheelData.Generation == generation do
			spinFortuneWheel()
			task.wait(1)
		end
	end)
end)

local timeDropdown = Tabs.Main:AddDropdown("Change Time", function(selection)
	Services.Lighting.ClockTime = selection == "Night" and 0 or 9
end)
timeDropdown:Add("Night")
timeDropdown:Add("Day")

Tabs.Specs:AddLabel("Player Stats:")

local SpecsData = {
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
Tabs.Specs:AddLabel("Advanced Stats:")

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

local function isSpawnProtected(player)
	if not player or not player.Character then return false end
	if player.Character:FindFirstChildOfClass("ForceField")
		or player.Character:FindFirstChild("spawnProtectionHighlight") then
		return true
	end
	local protectedUntil = player.Character:GetAttribute("SpawnProtectedUntil")
	return typeof(protectedUntil) == "number" and Services.Workspace:GetServerTimeNow() < protectedUntil
end

local function getLocalCombatCharacter()
	local character = Services.Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not humanoid or humanoid.Health <= 0 or not humanoidRootPart then return end
	return character, humanoid, humanoidRootPart
end

local function positionNearTarget(target, heightOffset)
	if not isPlayerAlive(target)
		or isSpawnProtected(target)
		or isSpawnProtected(Services.Players.LocalPlayer) then
		return false
	end
	local _, _, localRoot = getLocalCombatCharacter()
	local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if not localRoot or not targetRoot then return false end

	localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, heightOffset, 0)
	localRoot.AssemblyLinearVelocity = Vector3.zero
	localRoot.AssemblyAngularVelocity = Vector3.zero
	return true
end

local function touchAndPunchTarget(target, heightOffset)
	if not positionNearTarget(target, heightOffset) then return false, false end
	Services.RunService.Heartbeat:Wait()
	if not positionNearTarget(target, heightOffset) then return false, false end

	local character = getLocalCombatCharacter()
	local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	local targetHumanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
	if not character or not targetRoot or not targetHumanoid or isSpawnProtected(target) then return false, false end

	local hand = character:FindFirstChild("LeftHand") or character:FindFirstChild("RightHand")
	if not hand then return false, false end

	local punchTool = character:FindFirstChild("Punch") or Services.Players.LocalPlayer.Backpack:FindFirstChild("Punch")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if punchTool and punchTool.Parent ~= character and humanoid then
		humanoid:EquipTool(punchTool)
	end

	local healthBefore = targetHumanoid.Health
	local attempted = pcall(function()
		firetouchinterest(targetRoot, hand, 0)
		firetouchinterest(targetRoot, hand, 1)
		Services.Players.LocalPlayer.muscleEvent:FireServer("punch", hand.Name == "LeftHand" and "leftHand" or "rightHand")
	end)
	if not attempted then return false, false end

	for _ = 1, 4 do
		Services.RunService.Heartbeat:Wait()
		if not isPlayerAlive(target) or targetHumanoid.Health < healthBefore then
			return true, true
		end
		if isSpawnProtected(target) then
			return false, false
		end
	end

	return false, true
end

local function attackPlayerWithLimit(target, hitLimit, shouldContinue, heightOffset)
	local hits = 0
	while hits < hitLimit and shouldContinue() and isPlayerAlive(target) and not isSpawnProtected(target) do
		local hitRegistered, attempted = touchAndPunchTarget(target, heightOffset)
		if not attempted then break end
		if hitRegistered then
			hits += 1
		else
			task.wait(0.05)
		end
	end
	return hits
end

Tabs.Killing:AddLabel("Misc:")

local function equipBestStatPets(priority)
	for _, folder in pairs(Services.Players.LocalPlayer.petsFolder:GetChildren()) do
		if folder:IsA("Folder") then
			for _, pet in pairs(folder:GetChildren()) do
				Services.ReplicatedStorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
			end
		end
	end

	task.wait(0.2)
	local petsByName = {}
	for _, petName in ipairs(priority) do petsByName[petName] = {} end

	for _, pet in pairs(Services.Players.LocalPlayer.petsFolder.Unique:GetChildren()) do
		if petsByName[pet.Name] then table.insert(petsByName[pet.Name], pet) end
	end

	local equippedCount = 0
	for _, petName in ipairs(priority) do
		for _, pet in ipairs(petsByName[petName]) do
			if equippedCount >= 9 then return end
			Services.ReplicatedStorage.rEvents.equipPetEvent:FireServer("equipPet", pet)
			equippedCount += 1
			task.wait(0.1)
		end
	end
end

Tabs.Killing:AddButton("Equip Best Damage", function()
	equipBestStatPets({"Wild Wizard", "Chaos Sorcerer", "Mighty Monster", "Small Fry"})
end)

Tabs.Killing:AddButton("Equip Best Health", function()
	equipBestStatPets({"Mighty Monster", "Small Fry", "Wild Wizard", "Chaos Sorcerer"})
end)

Tabs.Killing:AddSwitch("Remove Attack Animations", function(bool)
	if bool then
		local blockedAnimations = {
			["3638729053"] = true,
			["3638767427"] = true,
			["507768375"] = true,
			["522635514"] = true,
			["522638767"] = true,
			["182393478"] = true,
			["129967390"] = true,
			["129967478"] = true
		}

		local function shouldBlockAnimation(track)
			if not track or not track.Animation then return false end
			local animationId = tostring(track.Animation.AnimationId):match("%d+")
			local animationName = string.lower((track.Name or "") .. " " .. (track.Animation.Name or ""))
			return blockedAnimations[animationId] == true
				or string.find(animationName, "punch", 1, true) ~= nil
				or string.find(animationName, "attack", 1, true) ~= nil
				or string.find(animationName, "right", 1, true) ~= nil
				or string.find(animationName, "equip", 1, true) ~= nil
				or string.find(animationName, "tool", 1, true) ~= nil
				or string.find(animationName, "hold", 1, true) ~= nil
		end

		local function isAttackTool(tool)
			if not tool or not tool:IsA("Tool") then return false end
			local name = string.lower(tool.Name)
			return string.find(name, "punch", 1, true) ~= nil
				or string.find(name, "attack", 1, true) ~= nil
				or string.find(name, "right", 1, true) ~= nil
		end

		local function hasAttackToolEquipped(character)
			if not character then return false end
			for _, child in ipairs(character:GetChildren()) do
				if isAttackTool(child) then return true end
			end
			return false
		end

		local function isMovementAnimation(track, character)
			local animation = track and track.Animation
			local animate = character and character:FindFirstChild("Animate")
			if not animation or not animate or not animation:IsDescendantOf(animate) then
				return false
			end

			local path = ""
			local current = animation
			while current and current ~= animate.Parent do
				path = path .. " " .. string.lower(current.Name)
				if current == animate then break end
				current = current.Parent
			end

			if string.find(path, "tool", 1, true)
				or string.find(path, "punch", 1, true)
				or string.find(path, "attack", 1, true)
				or string.find(path, "equip", 1, true)
				or string.find(path, "hold", 1, true) then
				return false
			end

			for _, movementName in ipairs({"idle", "walk", "run", "jump", "fall", "climb", "swim", "sit"}) do
				if string.find(path, movementName, 1, true) then return true end
			end
			return false
		end

		local function stopBlockedAnimations(character)
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not humanoid then return end
			for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
				if shouldBlockAnimation(track) then track:Stop(0) end
			end
		end

		local function stopEquipAnimations(character)
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not humanoid then return end
			for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
				local priority = track.Priority
				if shouldBlockAnimation(track)
					or not isMovementAnimation(track, character)
					or priority == Enum.AnimationPriority.Action
					or priority == Enum.AnimationPriority.Action2
					or priority == Enum.AnimationPriority.Action3
					or priority == Enum.AnimationPriority.Action4 then
					track:Stop(0)
				end
			end
		end

		local function setupAnimationBlocking()
			local char = Services.Players.LocalPlayer.Character
			local humanoid = char and char:FindFirstChildOfClass("Humanoid")
			if not humanoid then return end

			stopBlockedAnimations(char)
			if _G.AnimBlockConnection then _G.AnimBlockConnection:Disconnect() end
			_G.AnimBlockConnection = humanoid.AnimationPlayed:Connect(function(track)
				if shouldBlockAnimation(track)
					or (hasAttackToolEquipped(char) and not isMovementAnimation(track, char)) then
					track:Stop(0)
				end
			end)
		end

		local function processTool(tool)
			if isAttackTool(tool) then
				if not tool:GetAttribute("ActivatedOverride") then
					tool:SetAttribute("ActivatedOverride", true)

					_G.ToolConnections = _G.ToolConnections or {}
					_G.ToolConnections[tool] = tool.Activated:Connect(function()
						task.wait(0.05)
						stopBlockedAnimations(Services.Players.LocalPlayer.Character)
					end)

					_G.ToolEquipConnections = _G.ToolEquipConnections or {}
					_G.ToolEquipConnections[tool] = tool.Equipped:Connect(function()
						for _, delayTime in ipairs({0, 0.03, 0.08, 0.15, 0.25}) do
							task.delay(delayTime, function()
								stopEquipAnimations(Services.Players.LocalPlayer.Character)
							end)
						end
					end)
				end

				if tool.Parent == Services.Players.LocalPlayer.Character then
					stopEquipAnimations(Services.Players.LocalPlayer.Character)
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

		_G.AnimMonitorConnection = Services.RunService.RenderStepped:Connect(function()
			local character = Services.Players.LocalPlayer.Character
			if hasAttackToolEquipped(character) then
				stopEquipAnimations(character)
			else
				stopBlockedAnimations(character)
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

		if _G.ToolEquipConnections then
			for _, connection in pairs(_G.ToolEquipConnections) do
				if connection then connection:Disconnect() end
			end
			_G.ToolEquipConnections = nil
		end
	end
end)

Tabs.Killing:AddLabel("Auto Kill:")

_G.whitelistedPlayers = _G.whitelistedPlayers or {}
_G.blacklistedPlayers = _G.blacklistedPlayers or {}

for _, connectionName in ipairs({
	"killAllConnection",
	"farmBadKarmaConnection",
	"farmGoodKarmaConnection",
	"blacklistKillConnection",
	"deathRingConnection"
}) do
	local connection = _G[connectionName]
	if connection then
		pcall(function() connection:Disconnect() end)
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

local removeWhitelistDropdown
local whitelistDropdown = Tabs.Killing:AddDropdown("Add to Whitelist", function(selectedText)
	local playerName = selectedText:match("| (.+)$")
	if playerName then
		playerName = playerName:gsub("^%s*(.-)%s*$", "%1")
		for _, name in ipairs(_G.whitelistedPlayers) do
			if name:lower() == playerName:lower() then return end
		end
		table.insert(_G.whitelistedPlayers, playerName)
		if removeWhitelistDropdown then removeWhitelistDropdown:Add(playerName) end
	end
end)

Tabs.Killing:AddSwitch("Kill Everyone", function(bool)
	_G.killAll = bool
	_G.killAllGeneration = (_G.killAllGeneration or 0) + 1
	local generation = _G.killAllGeneration
	if not bool then return end

	task.spawn(function()
		while _G.killAll and _G.killAllGeneration == generation do
			local foundTarget = false
			for _, player in ipairs(Services.Players:GetPlayers()) do
				if not _G.killAll or _G.killAllGeneration ~= generation then break end
				if player ~= Services.Players.LocalPlayer
					and not isWhitelisted(player)
					and isPlayerAlive(player)
					and not isSpawnProtected(player) then
					foundTarget = true
					attackPlayerWithLimit(player, 4, function()
						return _G.killAll and _G.killAllGeneration == generation and not isWhitelisted(player)
					end, 3.5)
				end
			end
			if foundTarget then
				Services.RunService.Heartbeat:Wait()
			else
				task.wait(0.1)
			end
		end
	end)
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

Tabs.Killing:AddLabel("Karma Killing:")

local KarmaKillData = {FarmEvil = false, FarmGood = false, Generation = 0}

local function matchesKarmaMode(player)
	local goodKarma = player:FindFirstChild("goodKarma")
	local evilKarma = player:FindFirstChild("evilKarma")
	if not goodKarma or not evilKarma then return false end

	local goodValue = goodKarma.Value or 0
	local evilValue = evilKarma.Value or 0
	if goodValue + evilValue < 5 then return false end
	return (KarmaKillData.FarmEvil and goodValue > evilValue)
		or (KarmaKillData.FarmGood and evilValue > goodValue)
end

local function restartKarmaWorker()
	KarmaKillData.Generation += 1
	local generation = KarmaKillData.Generation
	if not KarmaKillData.FarmEvil and not KarmaKillData.FarmGood then return end

	task.spawn(function()
		while (KarmaKillData.FarmEvil or KarmaKillData.FarmGood) and KarmaKillData.Generation == generation do
			local foundTarget = false
			for _, player in ipairs(Services.Players:GetPlayers()) do
				if KarmaKillData.Generation ~= generation then break end
				if player ~= Services.Players.LocalPlayer
					and not isWhitelisted(player)
					and isPlayerAlive(player)
					and not isSpawnProtected(player)
					and matchesKarmaMode(player) then
					foundTarget = true
					attackPlayerWithLimit(player, 4, function()
						return KarmaKillData.Generation == generation
							and not isWhitelisted(player)
							and matchesKarmaMode(player)
					end, 3.5)
				end
			end
			if foundTarget then
				Services.RunService.Heartbeat:Wait()
			else
				task.wait(0.1)
			end
		end
	end)
end

Tabs.Killing:AddSwitch("Farm Evil Karma", function(state)
	KarmaKillData.FarmEvil = state
	restartKarmaWorker()
end)

Tabs.Killing:AddSwitch("Farm Good Karma", function(state)
	KarmaKillData.FarmGood = state
	restartKarmaWorker()
end)



Tabs.Killing:AddLabel("Target Killing:")

local removeKilllistDropdown
local blacklistDropdown = Tabs.Killing:AddDropdown("Add to Killlist", function(selectedText)
	local playerName = selectedText:match("| (.+)$")
	if playerName then
		playerName = playerName:gsub("^%s*(.-)%s*$", "%1")
		if not isBlacklisted({Name = playerName}) then
			table.insert(_G.blacklistedPlayers, playerName)
			if removeKilllistDropdown then removeKilllistDropdown:Add(playerName) end
		end
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

local targetKillAntiGravityName = "SilenceTargetKillAntiGravity"
local targetKillHeightOffset = 10
local targetKillGravityState = {
	Active = false,
	OriginalGravity = nil,
	Connection = nil
}

local function setTargetKillAntiGravity(enabled)
	local character = Services.Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if enabled then
		if not targetKillGravityState.Active then
			targetKillGravityState.Active = true
			targetKillGravityState.OriginalGravity = Services.Workspace.Gravity
			Services.Workspace.Gravity = 0

			targetKillGravityState.Connection = Services.RunService.Heartbeat:Connect(function()
				Services.Workspace.Gravity = 0
				local currentCharacter = Services.Players.LocalPlayer.Character
				local currentRoot = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
				if currentRoot then
					local velocity = currentRoot.AssemblyLinearVelocity
					currentRoot.AssemblyLinearVelocity = Vector3.new(velocity.X, 0, velocity.Z)
				end
			end)
		end

		if root then
			local oldAntiGravity = root:FindFirstChild(targetKillAntiGravityName)
			if oldAntiGravity then oldAntiGravity:Destroy() end
			local velocity = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(velocity.X, 0, velocity.Z)
			root.AssemblyAngularVelocity = Vector3.zero
		end
	else
		if targetKillGravityState.Connection then
			targetKillGravityState.Connection:Disconnect()
			targetKillGravityState.Connection = nil
		end
		if targetKillGravityState.Active then
			Services.Workspace.Gravity = targetKillGravityState.OriginalGravity or 196.2
		end
		targetKillGravityState.Active = false
		targetKillGravityState.OriginalGravity = nil
	end
end

Tabs.Killing:AddSwitch("Kill List", function(bool)
	_G.killBlacklistedOnly = bool
	_G.killListGeneration = (_G.killListGeneration or 0) + 1
	local generation = _G.killListGeneration
	if not bool then
		setTargetKillAntiGravity(false)
		return
	end

	task.spawn(function()
		while _G.killBlacklistedOnly and _G.killListGeneration == generation do
			local target = nil
			for _, player in ipairs(Services.Players:GetPlayers()) do
				if not _G.killBlacklistedOnly or _G.killListGeneration ~= generation then break end
				if player ~= Services.Players.LocalPlayer
					and isBlacklisted(player)
					and isPlayerAlive(player)
					and not isSpawnProtected(player) then
					target = player
					break
				end
			end

			if target then
				setTargetKillAntiGravity(true)
				pcall(function()
					while _G.killBlacklistedOnly
						and _G.killListGeneration == generation
						and target.Parent == Services.Players
						and isBlacklisted(target)
						and isPlayerAlive(target)
						and not isSpawnProtected(target) do
						local _, attempted = touchAndPunchTarget(target, targetKillHeightOffset)
						if not attempted then task.wait(0.1) end
					end
				end)
				setTargetKillAntiGravity(false)
				Services.RunService.Heartbeat:Wait()
			else
				setTargetKillAntiGravity(false)
				task.wait(0.1)
			end
		end
		setTargetKillAntiGravity(false)
	end)
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

Tabs.Killing:AddLabel("Kill Aura:")

local KillAura = {
	RingPart = nil,
	RingColor = Color3.fromRGB(138, 0, 0),
	RingTransparency = 0.6,
	CenterCFrame = nil,
	Frozen = false,
	Generation = 0
}
_G.showDeathRing = false
_G.deathRingRange = 20

local staleKillAuraRing = Services.Workspace:FindFirstChild("SilenceKillAuraRing")
if staleKillAuraRing then staleKillAuraRing:Destroy() end

Tabs.Killing:AddTextBox("Range (1-140):", function(text)
	if tonumber(text) then
		_G.deathRingRange = math.clamp(tonumber(text), 1, 140)
		if KillAura.RingPart then
			KillAura.RingPart.Size = Vector3.new(0.2, _G.deathRingRange * 2, _G.deathRingRange * 2)
		end
	end
end, {clear = false})

local RingColors = {
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

local ringColorDropdown = Tabs.Killing:AddDropdown("Ring Color", function(selection)
	for _, colorData in ipairs(RingColors) do
		if colorData.Name == selection then
			KillAura.RingColor = colorData.Color
			if KillAura.RingPart then KillAura.RingPart.Color = colorData.Color end
			break
		end
	end
end)
for _, colorData in ipairs(RingColors) do
	ringColorDropdown:Add(colorData.Name)
end

local function destroyKillAuraRing()
	if KillAura.RingPart then
		KillAura.RingPart:Destroy()
		KillAura.RingPart = nil
	end
end

local function createKillAuraRing()
	destroyKillAuraRing()
	local oldRing = Services.Workspace:FindFirstChild("SilenceKillAuraRing")
	if oldRing then oldRing:Destroy() end

	KillAura.RingPart = Instance.new("Part")
	KillAura.RingPart.Name = "SilenceKillAuraRing"
	KillAura.RingPart.Shape = Enum.PartType.Cylinder
	KillAura.RingPart.Material = Enum.Material.Neon
	KillAura.RingPart.Color = KillAura.RingColor
	KillAura.RingPart.Transparency = KillAura.RingTransparency
	KillAura.RingPart.Anchored = true
	KillAura.RingPart.CanCollide = false
	KillAura.RingPart.CanTouch = false
	KillAura.RingPart.CanQuery = false
	KillAura.RingPart.CastShadow = false
	KillAura.RingPart.Size = Vector3.new(0.2, _G.deathRingRange * 2, _G.deathRingRange * 2)
	if KillAura.CenterCFrame then
		KillAura.RingPart.CFrame = KillAura.CenterCFrame * CFrame.Angles(0, 0, math.rad(90))
	end
	KillAura.RingPart.Parent = Services.Workspace
end

local showRingSwitch
showRingSwitch = Tabs.Killing:AddSwitch("Show Ring", function(bool)
	if bool and not _G.deathRingEnabled then
		_G.showDeathRing = false
		showRingSwitch:Set(false)
		return
	end

	_G.showDeathRing = bool
	if bool then
		createKillAuraRing()
	else
		destroyKillAuraRing()
	end
end)

if _G.deathRingConnection then
	_G.deathRingConnection:Disconnect()
	_G.deathRingConnection = nil
end

local function updateKillAuraRing()
	if KillAura.RingPart and KillAura.CenterCFrame then
		KillAura.RingPart.CFrame = KillAura.CenterCFrame * CFrame.Angles(0, 0, math.rad(90))
	end
end

Tabs.Killing:AddSwitch("Toggle Ring", function(bool)
	_G.deathRingEnabled = bool
	KillAura.Generation += 1
	local generation = KillAura.Generation
	if not bool then
		if showRingSwitch and _G.showDeathRing then showRingSwitch:Set(false) end
		return
	end

	local _, _, initialRoot = getLocalCombatCharacter()
	if initialRoot then KillAura.CenterCFrame = initialRoot.CFrame end

	task.spawn(function()
		while _G.deathRingEnabled and KillAura.Generation == generation do
			local _, _, localRoot = getLocalCombatCharacter()
			if localRoot and not KillAura.Frozen then
				KillAura.CenterCFrame = localRoot.CFrame
			end
			updateKillAuraRing()
			Services.RunService.RenderStepped:Wait()
		end
	end)

	task.spawn(function()
		while _G.deathRingEnabled and KillAura.Generation == generation do
			if KillAura.Frozen or not KillAura.CenterCFrame then
				task.wait(0.05)
				continue
			end

			local centerCFrame = KillAura.CenterCFrame
			local attackedPlayer = false
			for _, player in ipairs(Services.Players:GetPlayers()) do
				if not _G.deathRingEnabled or KillAura.Generation ~= generation then break end
				local targetRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if player ~= Services.Players.LocalPlayer
					and not isWhitelisted(player)
					and isPlayerAlive(player)
					and not isSpawnProtected(player)
					and targetRoot
					and (centerCFrame.Position - targetRoot.Position).Magnitude <= _G.deathRingRange then
					attackedPlayer = true
					KillAura.Frozen = true
					KillAura.CenterCFrame = centerCFrame
					updateKillAuraRing()

					attackPlayerWithLimit(player, 4, function()
						local currentTargetRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
						return _G.deathRingEnabled
							and KillAura.Generation == generation
							and not isWhitelisted(player)
							and currentTargetRoot
							and (centerCFrame.Position - currentTargetRoot.Position).Magnitude <= _G.deathRingRange
					end, 3.5)

					for _ = 1, 4 do
						local _, _, currentLocalRoot = getLocalCombatCharacter()
						if currentLocalRoot then
							currentLocalRoot.CFrame = centerCFrame
							currentLocalRoot.AssemblyLinearVelocity = Vector3.zero
							currentLocalRoot.AssemblyAngularVelocity = Vector3.zero
						end
						KillAura.CenterCFrame = centerCFrame
						updateKillAuraRing()
						Services.RunService.Heartbeat:Wait()
					end
					KillAura.Frozen = false
				end
			end

			if not attackedPlayer then task.wait(0.05) end
		end
		KillAura.Frozen = false
	end)
end)

local whitelistLabel = Tabs.Killing:AddLabel("Whitelist: None")
removeWhitelistDropdown = Tabs.Killing:AddDropdown("Remove from Whitelist", function(selectedName)
	for index = #_G.whitelistedPlayers, 1, -1 do
		if _G.whitelistedPlayers[index]:lower() == selectedName:lower() then
			table.remove(_G.whitelistedPlayers, index)
		end
	end
	removeWhitelistDropdown:Remove(selectedName)
end)

for _, playerName in ipairs(_G.whitelistedPlayers) do
	removeWhitelistDropdown:Add(playerName)
end

Tabs.Killing:AddButton("Clear Whitelist", function()
	_G.whitelistedPlayers = {}
	removeWhitelistDropdown:Clear()
end)

local blacklistLabel = Tabs.Killing:AddLabel("Killlist: None")
removeKilllistDropdown = Tabs.Killing:AddDropdown("Remove from Killlist", function(selectedName)
	for index = #_G.blacklistedPlayers, 1, -1 do
		if _G.blacklistedPlayers[index]:lower() == selectedName:lower() then
			table.remove(_G.blacklistedPlayers, index)
		end
	end
	removeKilllistDropdown:Remove(selectedName)
end)

for _, playerName in ipairs(_G.blacklistedPlayers) do
	removeKilllistDropdown:Add(playerName)
end

Tabs.Killing:AddButton("Clear Killlist", function()
	_G.blacklistedPlayers = {}
	removeKilllistDropdown:Clear()
end)

task.spawn(function()
	while true do
		whitelistLabel.Text = #_G.whitelistedPlayers == 0 and "Whitelist: None" or "Whitelist: " .. table.concat(_G.whitelistedPlayers, ", ")
		blacklistLabel.Text = #_G.blacklistedPlayers == 0 and "Killlist: None" or "Killlist: " .. table.concat(_G.blacklistedPlayers, ", ")
		task.wait(0.01)
	end
end)

Tabs.Farming:AddLabel("Rebirths:")

local RebirthData = {
	Label = Tabs.Farming:AddLabel("Rebirths: 0"),
	TargetLabel = Tabs.Farming:AddLabel("Target: None"),
	Rebirths = PlayerData.Player.leaderstats:WaitForChild("Rebirths"),
	TargetRebirths = 0,
	IsAutoRebirthing = false
}


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

Tabs.Farming:AddLabel("Auto Exercises (recommended for rebirthing):")

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

local machinesFolder = Services.Workspace:WaitForChild("machinesFolder")
local squatsByName = {}
local squatMachineNames = {}
local liftMachineNames = {}
local MachineExerciseData = {
	Squat = {SelectedMachine = nil, ActiveMachine = nil, Running = false, Generation = 0, ReenterAt = 0, SeatPart = nil, Choices = {}},
	Lift = {SelectedMachine = nil, ActiveMachine = nil, Running = false, Generation = 0, ReenterAt = 0, SeatPart = nil, Choices = {}}
}

for _, machine in ipairs(machinesFolder:GetChildren()) do
	local lowerName = string.lower(machine.Name)
	if string.find(lowerName, "squat", 1, true) and lowerName ~= "squat rack" then
		squatsByName[machine.Name] = squatsByName[machine.Name] or {}
		table.insert(squatsByName[machine.Name], machine)
	elseif string.find(lowerName, "lift", 1, true) and lowerName ~= "deadlift" then
		MachineExerciseData.Lift.Choices[machine.Name] = machine
		table.insert(liftMachineNames, machine.Name)
	end
end

for machineName, matchingSquats in pairs(squatsByName) do
	MachineExerciseData.Squat.Choices[machineName] = matchingSquats[1]
	table.insert(squatMachineNames, machineName)
end

table.sort(squatMachineNames)
table.sort(liftMachineNames)

local function getMachineInteractPart(machine)
	for _, descendant in ipairs(machine:GetDescendants()) do
		if descendant:IsA("BasePart") and string.lower(descendant.Name) == "interactseat" then
			return descendant
		end
	end
end

local function enterExerciseMachine(machine)
	if not machine or not machine.Parent then return false end

	local character = PlayerData.Player.Character or PlayerData.Player.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
	local interactPart = getMachineInteractPart(machine)
	if not humanoidRootPart or not interactPart then return false end

	humanoidRootPart.CFrame = interactPart.CFrame * CFrame.new(0, 3, 0)
	humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
	humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
	task.wait(0.4)
	Services.VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
	task.wait(0.1)
	Services.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
	task.wait(0.4)
	return true
end

local toolExerciseSwitch
local squatExerciseSwitch
local liftExerciseSwitch

toolExerciseSwitch = Tabs.Farming:AddSwitch("Start exercising", function(enabled)
	ExerciseData.AutoFarm = enabled

	if enabled then
		if squatExerciseSwitch and MachineExerciseData.Squat.Running then squatExerciseSwitch:Set(false) end
		if liftExerciseSwitch and MachineExerciseData.Lift.Running then liftExerciseSwitch:Set(false) end

		task.spawn(function()
			while ExerciseData.AutoFarm do
				if PlayerData.Character ~= PlayerData.Player.Character then
					PlayerData.Character = PlayerData.Player.Character
					PlayerData.Humanoid = PlayerData.Character and PlayerData.Character:FindFirstChildOfClass("Humanoid")
				end

				if not PlayerData.Character or not PlayerData.Character:FindFirstChildOfClass("Humanoid") then
					PlayerData.Player.CharacterAdded:Wait()
					PlayerData.Character = PlayerData.Player.Character
					PlayerData.Humanoid = PlayerData.Character and PlayerData.Character:FindFirstChildOfClass("Humanoid")
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

local function addMachineDropdown(label, machineData, machineNames)
	local dropdown = Tabs.Farming:AddDropdown(label, function(selection)
		machineData.SelectedMachine = machineData.Choices[selection]
		machineData.ActiveMachine = nil
		machineData.SeatPart = nil
		machineData.ReenterAt = 0
	end)

	for _, machineName in ipairs(machineNames) do
		dropdown:Add(machineName)
	end
end

local function startMachineExercise(machineData)
	machineData.Generation += 1
	local generation = machineData.Generation
	local lastCharacter = PlayerData.Player.Character

	task.spawn(function()
		while machineData.Running and machineData.Generation == generation do
			local character = PlayerData.Player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")

			if character ~= lastCharacter then
				lastCharacter = character
				machineData.ActiveMachine = nil
				machineData.SeatPart = nil
				machineData.ReenterAt = os.clock() + 3.5
			end

			if not character or not humanoid or humanoid.Health <= 0 then
				machineData.ActiveMachine = nil
				machineData.SeatPart = nil
				machineData.ReenterAt = math.max(machineData.ReenterAt, os.clock() + 3.5)
				task.wait(0.1)
				continue
			end

			local humanoidState = humanoid:GetState()
			local jumpedOff = machineData.ActiveMachine and (
				humanoidState == Enum.HumanoidStateType.Jumping
				or humanoidState == Enum.HumanoidStateType.Freefall
				or (machineData.SeatPart and humanoid.SeatPart ~= machineData.SeatPart)
			)

			if jumpedOff then
				machineData.ActiveMachine = nil
				machineData.SeatPart = nil
				machineData.ReenterAt = os.clock() + 3.5
			end

			if machineData.SelectedMachine and not machineData.ActiveMachine and os.clock() >= machineData.ReenterAt then
				if enterExerciseMachine(machineData.SelectedMachine) then
					machineData.ActiveMachine = machineData.SelectedMachine
					machineData.SeatPart = humanoid.SeatPart
				end
			end

			if machineData.ActiveMachine then
				pcall(function()
					PlayerData.Player.muscleEvent:FireServer("rep")
				end)
			end

			task.wait()
		end
	end)
end

local function setMachineExerciseState(machineData, otherMachineData, state)
	machineData.Running = state
	machineData.Generation += 1
	machineData.ActiveMachine = nil
	machineData.SeatPart = nil
	machineData.ReenterAt = 0

	if not state then return end
	if toolExerciseSwitch and ExerciseData.AutoFarm then toolExerciseSwitch:Set(false) end
	if otherMachineData.Running then
		if machineData == MachineExerciseData.Squat and liftExerciseSwitch then
			liftExerciseSwitch:Set(false)
		elseif machineData == MachineExerciseData.Lift and squatExerciseSwitch then
			squatExerciseSwitch:Set(false)
		end
	end
	startMachineExercise(machineData)
end

addMachineDropdown("Select Squat", MachineExerciseData.Squat, squatMachineNames)
squatExerciseSwitch = Tabs.Farming:AddSwitch("Auto Squat", function(state)
	setMachineExerciseState(MachineExerciseData.Squat, MachineExerciseData.Lift, state)
end)

addMachineDropdown("Select Lift", MachineExerciseData.Lift, liftMachineNames)
liftExerciseSwitch = Tabs.Farming:AddSwitch("Auto Lift", function(state)
	setMachineExerciseState(MachineExerciseData.Lift, MachineExerciseData.Squat, state)
end)

Tabs.Farming:AddLabel("Glitching:")

local RockData = {
	Data = {["Tiny Rock - 0 Dura"] = 0, ["Large Rock - 100 Dura"] = 100, ["Punching Rock - 10 Dura"] = 10,
		["Golden Rock - 5k Dura"] = 5000, ["Frost Rock - 150k Dura"] = 150000, ["Mythical Rock - 400k Dura"] = 400000,
		["Eternal Rock - 750k Dura"] = 750000, ["Legend Rock - 1m Dura"] = 1000000, ["Muscle King Rock - 5m Dura"] = 5000000,
		["Jungle Rock - 10m Dura"] = 10000000, ["Industrial Rock - 25m Dura"] = 25000000,},
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

Tabs.Farming:AddLabel("Better Strength Farming:")

local farmingConfigs = {
	{name = "Pushup + Industrial Rock", tool = "Pushups", rock = "Industrial Rock"},
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

Tabs.Inventory:AddLabel("Boost Eater:")

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

Tabs.Inventory:AddLabel("Pet Shop:")

local PetShopRuntime = Services.ReplicatedStorage:WaitForChild("shared"):WaitForChild("runtime")
local PetShopFolder = PetShopRuntime:WaitForChild("cPetShopFolder")
local PetShopRemote = Services.ReplicatedStorage.rEvents:WaitForChild("cPetShopRemote")

local PetShopData = {
	SelectedPet = nil,
	PetList = {}
}

local AuraData = {
	SelectedAura = nil,
	AuraList = {}
}

for _, item in ipairs(PetShopFolder:GetChildren()) do
	if item:GetAttribute("IsPowerUp") == true then
		table.insert(AuraData.AuraList, item.Name)
	else
		table.insert(PetShopData.PetList, item.Name)
	end
end
table.sort(PetShopData.PetList)
table.sort(AuraData.AuraList)

local petDropdown = Tabs.Inventory:AddDropdown("Choose Pet", function(text) PetShopData.SelectedPet = text end)
for _, petName in ipairs(PetShopData.PetList) do petDropdown:Add(petName) end

Tabs.Inventory:AddSwitch("Buy Pet", function(bool)
	_G.AutoHatchPet = bool
	if bool then
		task.spawn(function()
			while _G.AutoHatchPet do
				local selectedPet = PetShopData.SelectedPet and PetShopFolder:FindFirstChild(PetShopData.SelectedPet)
				if selectedPet then
					pcall(function()
						PetShopRemote:InvokeServer(selectedPet)
					end)
				end
				task.wait(0.1)
			end
		end)
	end
end)

Tabs.Inventory:AddLabel("Auras:")

local auraDropdown = Tabs.Inventory:AddDropdown("Select Aura", function(text) AuraData.SelectedAura = text end)
for _, auraName in ipairs(AuraData.AuraList) do auraDropdown:Add(auraName) end

Tabs.Inventory:AddSwitch("Buy Aura", function(bool)
	_G.AutoHatchAura = bool
	if bool then
		task.spawn(function()
			while _G.AutoHatchAura do
				local selectedAura = AuraData.SelectedAura and PetShopFolder:FindFirstChild(AuraData.SelectedAura)
				if selectedAura then
					pcall(function()
						PetShopRemote:InvokeServer(selectedAura)
					end)
				end
				task.wait(0.1)
			end
		end)
	end
end)

Tabs.Inventory:AddLabel("You need Gems and Inventory Space!")

Tabs.Inventory:AddLabel("Auto Evolving:")

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



Tabs.Inventory:AddLabel("Auto Trading:")

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





Tabs.Inventory:AddLabel("Egg Gifter:")

local EggGifterData = {ProteinEggLabel = Tabs.Inventory:AddLabel("Protein Eggs: 0"), SelectedPlayer = nil, EggCount = 0}

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

local eggAmountTextBox = Tabs.Inventory:AddTextBox("Amount:", function(text)
	local amount = tonumber(text)
	if amount then
		EggGifterData.EggCount = math.max(0, math.floor(amount))
	end
end, {clear = false})

Tabs.Inventory:AddButton("Start Gifting", function()
	local amount = tonumber(eggAmountTextBox.Text) or EggGifterData.EggCount
	amount = amount and math.max(0, math.floor(amount)) or 0
	EggGifterData.EggCount = amount

	if not EggGifterData.SelectedPlayer or amount == 0 then return end

	task.spawn(function()
		for _ = 1, amount do
			local egg = Services.Players.LocalPlayer.consumablesFolder:FindFirstChild("Protein Egg")
			if not egg then break end

			pcall(function()
				Services.ReplicatedStorage.rEvents.giftRemote:InvokeServer("giftRequest", EggGifterData.SelectedPlayer, egg)
			end)
			task.wait(0.1)
		end
	end)
end)

Tabs.Inventory:AddLabel("Shake Gifter:")

local ShakeGifterData = {TropicalShakeLabel = Tabs.Inventory:AddLabel("Tropical Shakes: 0"), SelectedPlayer = nil, ShakeCount = 0}

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

local shakeAmountTextBox = Tabs.Inventory:AddTextBox("Amount:", function(text)
	local amount = tonumber(text)
	if amount then
		ShakeGifterData.ShakeCount = math.max(0, math.floor(amount))
	end
end, {clear = false})

Tabs.Inventory:AddButton("Start Gifting", function()
	local amount = tonumber(shakeAmountTextBox.Text) or ShakeGifterData.ShakeCount
	amount = amount and math.max(0, math.floor(amount)) or 0
	ShakeGifterData.ShakeCount = amount

	if not ShakeGifterData.SelectedPlayer or amount == 0 then return end

	task.spawn(function()
		for _ = 1, amount do
			local shake = Services.Players.LocalPlayer.consumablesFolder:FindFirstChild("Tropical Shake")
			if not shake then break end

			pcall(function()
				Services.ReplicatedStorage.rEvents.giftRemote:InvokeServer("giftRequest", ShakeGifterData.SelectedPlayer, shake)
			end)
			task.wait(0.1)
		end
	end)
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

Tabs.Inventory:AddLabel("Interferes with Boosts you got gifted. Get on a machine for less Lag!")

Tabs.Teleport:AddLabel("Main:")

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

Tabs.Teleport:AddLabel("Gyms:")

local gymLocations = {
	{name = "Industrial gym", pos = CFrame.new(-5254.681641, 58.342850, 4931.850586)},
	{name = "Jungle Gym", pos = CFrame.new(-8543, 6.8, 2400)},
	{name = "Muscle King Gym", pos = CFrame.new(-8665.4, 17.21, -5792.9)},
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

Tabs.Stats:AddLabel("Elapsed Time:")

local StatsData = {
	StopwatchLabel = Tabs.Stats:AddLabel("0d 0h 0m 0s"),
	StartTime = tick(),
	Leaderstats = PlayerData.Player:WaitForChild("leaderstats"),
	Stats = {},
	InitialValues = {},
	StatLabels = {}
}

Tabs.Stats:AddLabel("Stats:")

task.spawn(function()
	while true do
		local elapsedTime = tick() - StatsData.StartTime
		local days = math.floor(elapsedTime / (24 * 3600))
		local hours = math.floor((elapsedTime % (24 * 3600)) / 3600)
		local minutes = math.floor((elapsedTime % 3600) / 60)
		local seconds = math.floor(elapsedTime % 60)
		StatsData.StopwatchLabel.Text = string.format("%dd %dh %dm %ds", days, hours, minutes, seconds)
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
