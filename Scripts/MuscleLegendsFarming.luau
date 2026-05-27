local players = game:GetService("Players")
local player = players.LocalPlayer

local VirtualInputManager = game:GetService("VirtualInputManager")
local replicatedStorage = game:GetService("ReplicatedStorage")
local muscleEvent = player:WaitForChild("muscleEvent")
local leaderstats = player:WaitForChild("leaderstats")
local rebirthsStat = leaderstats:WaitForChild("Rebirths")
local displayName = player.DisplayName
local virtualUser = game:GetService("VirtualUser")
local lighting = game:GetService("Lighting")


if getgenv().sbe ~= "sbevalid" then
	player:Kick("Always use the Loader")
	getgenv().sbe = ""
	task.wait(0.5)
	return
else
	getgenv().sbe = ""
end




local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ghjkl1312/bhkjhk/refs/heads/main/lib.luau", true))()

local window = library:AddWindow("Silence | Fast Farming - Good Farming " .. displayName, {
	title_bar = { Color3.fromRGB(255, 0, 0), Color3.fromRGB(155, 0, 0) },
	title_bar_transparency = 0.3,
	background = { Color3.fromRGB(90, 0, 0), Color3.fromRGB(0, 0, 0) },
	background_transparency = 0.2,
	main_color = Color3.fromRGB(255, 255, 255),
	min_size = Vector2.new(600, 450),
	can_resize = true,
})



player.Idled:Connect(function()
	virtualUser:CaptureController()
	virtualUser:ClickButton2(Vector2.new())
end)

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

local rebirthTab = window:AddTab("Fast Rebirth")

local function formatNumber(num)
    if num >= 1e15 then return string.format("%.2fQa", num/1e15) end
    if num >= 1e12 then return string.format("%.2fT", num/1e12) end
    if num >= 1e9 then return string.format("%.2fB", num/1e9) end
    if num >= 1e6 then return string.format("%.2fM", num/1e6) end
    if num >= 1e3 then return string.format("%.2fK", num/1e3) end
    return string.format("%.0f", num)
end

local isRunning = false
local startTime = 0
local totalElapsed = 0
local initialRebirths = rebirthsStat.Value
local lastPaceUpdate = 0

local serverLabel = rebirthTab:AddLabel("📊 Stats:")
serverLabel.TextSize = 17
local timeLabel = rebirthTab:AddLabel("0d 0h 0m 0s - Inactive")
local paceLabel = rebirthTab:AddLabel("Rebirth Pace: /Hour | /Day | /Week")
local averagePaceLabel = rebirthTab:AddLabel("Average Rebirth Pace: /Hour | /Day | /Week")

paceLabel.TextSize = 15
averagePaceLabel.TextSize = 15

timeLabel.TextSize = 15
timeLabel.TextColor3 = Color3.fromRGB(255, 50, 50)

local rebirthsStatsLabel = rebirthTab:AddLabel("Rebirths: "..formatNumber(rebirthsStat.Value).." | Gained: 0")
rebirthsStatsLabel.TextSize = 15


local lastRebirthTime = tick()
local lastRebirthValue = rebirthsStat.Value

local function updateRebirthsLabel()
    local gained = rebirthsStat.Value - initialRebirths
    rebirthsStatsLabel.Text = string.format("Rebirths: %s | Gained: %s", 
                                           formatNumber(rebirthsStat.Value),
                                           formatNumber(gained))
end

local function updateUI(forceUpdate)
    local currentTime = tick()
    local elapsed = isRunning and (currentTime - startTime + totalElapsed) or totalElapsed
    
    local days = math.floor(elapsed / 86400)
    local hours = math.floor((elapsed % 86400) / 3600)
    local minutes = math.floor((elapsed % 3600) / 60)
    local seconds = math.floor(elapsed % 60)
    
    local statusText = isRunning and "Rebirthing" or (elapsed > 0 and "Rebirthing Paused" or "Fast Reb Inactive")
    timeLabel.Text = string.format("%dd %dh %dm %ds - %s", days, hours, minutes, seconds, statusText)
    
    if isRunning then
        timeLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
    elseif elapsed > 0 then
        timeLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
    else
        timeLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    end
end

local paceHistoryHour = {}
local paceHistoryDay = {}
local paceHistoryWeek = {}

local maxHistoryLength = 20

local rebirthCount = 0
local savedPaceHour = 0
local savedPaceDay = 0
local savedPaceWeek = 0
local savedAvgHour = 0
local savedAvgDay = 0
local savedAvgWeek = 0

local function calculatePaceOnRebirth()
    rebirthCount = rebirthCount + 1
    if rebirthCount < 2 then
        lastRebirthTime = tick()
        lastRebirthValue = rebirthsStat.Value
        return
    end

    if not isRunning then
        return
    end

    local now = tick()
    local gained = rebirthsStat.Value - lastRebirthValue

    if gained > 0 then
        local avgTimePerRebirth = (now - lastRebirthTime) / gained
        local paceHour = 3600 / avgTimePerRebirth
        local paceDay = 86400 / avgTimePerRebirth
        local paceWeek = 604800 / avgTimePerRebirth

        savedPaceHour = paceHour
        savedPaceDay = paceDay
        savedPaceWeek = paceWeek

        paceLabel.Text = string.format("Pace: %s / Hour | %s / Day | %s / Week",
            formatNumber(paceHour), formatNumber(paceDay), formatNumber(paceWeek))

        table.insert(paceHistoryHour, paceHour)
        table.insert(paceHistoryDay, paceDay)
        table.insert(paceHistoryWeek, paceWeek)

        if #paceHistoryHour > maxHistoryLength then
            table.remove(paceHistoryHour, 1)
            table.remove(paceHistoryDay, 1)
            table.remove(paceHistoryWeek, 1)
        end

        local function average(tbl)
            local sum = 0
            for _, v in ipairs(tbl) do
                sum = sum + v
            end
            return #tbl > 0 and (sum / #tbl) or 0
        end

        local avgHour = average(paceHistoryHour)
        local avgDay = average(paceHistoryDay)
        local avgWeek = average(paceHistoryWeek)

        savedAvgHour = avgHour
        savedAvgDay = avgDay
        savedAvgWeek = avgWeek

        averagePaceLabel.Text = string.format("Average Pace: %s / Hour | %s / Day | %s / Week",
            formatNumber(avgHour), formatNumber(avgDay), formatNumber(avgWeek))

        lastRebirthTime = now
        lastRebirthValue = rebirthsStat.Value
    end
end




rebirthsStat:GetPropertyChangedSignal("Value"):Connect(function()
    calculatePaceOnRebirth()
    updateRebirthsLabel()
end)

local function managePets(petName)
    for _, folder in pairs(player.petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in pairs(folder:GetChildren()) do
                replicatedStorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
            end
        end
    end
    task.wait(0.1)
    
    for _, pet in pairs(player.petsFolder.Unique:GetChildren()) do
        if pet.Name == petName then
            replicatedStorage.rEvents.equipPetEvent:FireServer("equipPet", pet)
        end
    end
end

local function doRebirth()
    local rebirths = rebirthsStat.Value
    local strengthTarget = 5000 + (rebirths * 2550)
    
    while isRunning and player.leaderstats.Strength.Value < strengthTarget do
        local reps = player.MembershipType == Enum.MembershipType.Premium and 12 or 20
        for _ = 1, reps do
            muscleEvent:FireServer("rep")
        end
        task.wait(0.02)
    end
    
    if isRunning and player.leaderstats.Strength.Value >= strengthTarget then
        managePets("Tribal Overlord")
        task.wait(0.25)
        
        local before = rebirthsStat.Value
        repeat
            replicatedStorage.rEvents.rebirthRemote:InvokeServer("rebirthRequest")
            task.wait(0.05)
        until rebirthsStat.Value > before or not isRunning
    end
end

local function fastRebirthLoop()
    while isRunning do
        managePets("Swift Samurai")
        doRebirth()
        task.wait(0.5)
    end
end

rebirthTab:AddLabel("")
rebirthTab:AddLabel("🔄️ Rebirth:").TextSize = 17

rebirthTab:AddSwitch("Fast Rebirth", function(state)
    isRunning = state
    
    if state then
        startTime = tick()
        if savedPaceHour > 0 then
            paceLabel.Text = string.format("Pace: %s / Hour | %s / Day | %s / Week",
                formatNumber(savedPaceHour), formatNumber(savedPaceDay), formatNumber(savedPaceWeek))
            averagePaceLabel.Text = string.format("Average Pace: %s / Hour | %s / Day | %s / Week",
                formatNumber(savedAvgHour), formatNumber(savedAvgDay), formatNumber(savedAvgWeek))
        end
        task.spawn(fastRebirthLoop)
    else
        totalElapsed = totalElapsed + (tick() - startTime)
        updateUI(true)
    end
end)

task.spawn(function()
    while true do
        updateUI(false)
        task.wait(0.1)
    end
end)







local farmTab = window:AddTab("Fast Farm")

local strengthStat = leaderstats:WaitForChild("Strength")
local durabilityStat = player:WaitForChild("Durability")

farmTab:AddLabel("📊 Stats:").TextSize = 17
local stopwatchLabel = farmTab:AddLabel("0d 0h 0m 0s - Fast Rep Inactive")
stopwatchLabel.TextSize = 15
stopwatchLabel.TextColor3 = Color3.fromRGB(255, 50, 50)

local projectedStrengthLabel = farmTab:AddLabel("Strength: /Hour | /Day | /Week")
projectedStrengthLabel.TextSize = 15
local averageStrengthLabel = farmTab:AddLabel("Average: /Hour | /Day | /Week")
averageStrengthLabel.TextSize = 15
farmTab:AddLabel("")
local projectedDurabilityLabel = farmTab:AddLabel("Dura: /Hour | /Day | /Week")
projectedDurabilityLabel.TextSize = 15
local averageDurabilityLabel = farmTab:AddLabel("Average: /Hour | /Day | /Week")
averageDurabilityLabel.TextSize = 15
farmTab:AddLabel("")

local strengthLabel = farmTab:AddLabel("Strength: " .. formatNumber(strengthStat.Value) .. " | Gained: 0")
strengthLabel.TextSize = 15
local durabilityLabel = farmTab:AddLabel("Durability: " .. formatNumber(durabilityStat.Value) .. " | Gained: 0")
durabilityLabel.TextSize = 15

local startTime = 0
local pausedElapsedTime = 0
local lastPauseTime = 0

local runFastRep = false
local trackingStarted = false

local strengthHistory = {}
local durabilityHistory = {}
local calculationInterval = 10

local initialStrength = strengthStat.Value
local initialDurability = durabilityStat.Value

local savedStrengthPerHour = 0
local savedStrengthPerDay = 0
local savedStrengthPerWeek = 0
local savedDurabilityPerHour = 0
local savedDurabilityPerDay = 0
local savedDurabilityPerWeek = 0

local savedAvgStrengthPerHour = 0
local savedAvgStrengthPerDay = 0
local savedAvgStrengthPerWeek = 0
local savedAvgDurabilityPerHour = 0
local savedAvgDurabilityPerDay = 0
local savedAvgDurabilityPerWeek = 0

task.spawn(function()
    local lastCalcTime = tick()
    while true do
        local currentTime = tick()
        local currentStrength = strengthStat.Value
        local currentDurability = durabilityStat.Value

        strengthLabel.Text = "Strength: " .. formatNumber(currentStrength) .. " | Gained: " .. formatNumber(currentStrength - initialStrength)
        durabilityLabel.Text = "Durability: " .. formatNumber(currentDurability) .. " | Gained: " .. formatNumber(currentDurability - initialDurability)

        if runFastRep then
            if not trackingStarted then
                trackingStarted = true
                startTime = currentTime
                strengthHistory = {}
                durabilityHistory = {}
                
                if savedStrengthPerHour > 0 then
                    projectedStrengthLabel.Text = "Strength: " .. formatNumber(savedStrengthPerHour) .. "/Hour | " .. formatNumber(savedStrengthPerDay) .. "/Day | " .. formatNumber(savedStrengthPerWeek) .. "/Week"
                    projectedDurabilityLabel.Text = "Dura: " .. formatNumber(savedDurabilityPerHour) .. "/Hour | " .. formatNumber(savedDurabilityPerDay) .. "/Day | " .. formatNumber(savedDurabilityPerWeek) .. "/Week"
                    averageStrengthLabel.Text = "Average: " .. formatNumber(savedAvgStrengthPerHour) .. "/Hour | " .. formatNumber(savedAvgStrengthPerDay) .. "/Day | " .. formatNumber(savedAvgStrengthPerWeek) .. "/Week"
                    averageDurabilityLabel.Text = "Average: " .. formatNumber(savedAvgDurabilityPerHour) .. "/Hour | " .. formatNumber(savedAvgDurabilityPerDay) .. "/Day | " .. formatNumber(savedAvgDurabilityPerWeek) .. "/Week"
                end
            end
            
            local elapsedTime = pausedElapsedTime + (currentTime - startTime)
            local days = math.floor(elapsedTime / (24 * 3600))
            local hours = math.floor((elapsedTime % (24 * 3600)) / 3600)
            local minutes = math.floor((elapsedTime % 3600) / 60)
            local seconds = math.floor(elapsedTime % 60)
            stopwatchLabel.Text = string.format("%dd %dh %dm %ds - Farming", days, hours, minutes, seconds)
            stopwatchLabel.TextColor3 = Color3.fromRGB(50, 255, 50)

            table.insert(strengthHistory, {time = currentTime, value = currentStrength})
            table.insert(durabilityHistory, {time = currentTime, value = currentDurability})

            while #strengthHistory > 0 and currentTime - strengthHistory[1].time > calculationInterval do
                table.remove(strengthHistory, 1)
            end
            while #durabilityHistory > 0 and currentTime - durabilityHistory[1].time > calculationInterval do
                table.remove(durabilityHistory, 1)
            end

            if currentTime - lastCalcTime >= calculationInterval then
                lastCalcTime = currentTime

                if #strengthHistory >= 2 then
                    local strengthDelta = strengthHistory[#strengthHistory].value - strengthHistory[1].value
                    local strengthPerSecond = strengthDelta / calculationInterval
                    savedStrengthPerHour = strengthPerSecond * 3600
                    savedStrengthPerDay = strengthPerSecond * 86400
                    savedStrengthPerWeek = strengthPerSecond * 604800
                    projectedStrengthLabel.Text = "Strength: " .. formatNumber(savedStrengthPerHour) .. "/Hour | " .. formatNumber(savedStrengthPerDay) .. "/Day | " .. formatNumber(savedStrengthPerWeek) .. "/Week"
                end

                if #durabilityHistory >= 2 then
                    local durabilityDelta = durabilityHistory[#durabilityHistory].value - durabilityHistory[1].value
                    local durabilityPerSecond = durabilityDelta / calculationInterval
                    savedDurabilityPerHour = durabilityPerSecond * 3600
                    savedDurabilityPerDay = durabilityPerSecond * 86400
                    savedDurabilityPerWeek = durabilityPerSecond * 604800
                    projectedDurabilityLabel.Text = "Dura: " .. formatNumber(savedDurabilityPerHour) .. "/Hour | " .. formatNumber(savedDurabilityPerDay) .. "/Day | " .. formatNumber(savedDurabilityPerWeek) .. "/Week"
                end

                local totalElapsed = pausedElapsedTime + (currentTime - startTime)
                if totalElapsed > 0 then
                    local avgStrengthPerSecond = (currentStrength - initialStrength) / totalElapsed
                    savedAvgStrengthPerHour = avgStrengthPerSecond * 3600
                    savedAvgStrengthPerDay = avgStrengthPerSecond * 86400
                    savedAvgStrengthPerWeek = avgStrengthPerSecond * 604800
                    averageStrengthLabel.Text = "Average: " .. formatNumber(savedAvgStrengthPerHour) .. "/Hour | " .. formatNumber(savedAvgStrengthPerDay) .. "/Day | " .. formatNumber(savedAvgStrengthPerWeek) .. "/Week"

                    local avgDurabilityPerSecond = (currentDurability - initialDurability) / totalElapsed
                    savedAvgDurabilityPerHour = avgDurabilityPerSecond * 3600
                    savedAvgDurabilityPerDay = avgDurabilityPerSecond * 86400
                    savedAvgDurabilityPerWeek = avgDurabilityPerSecond * 604800
                    averageDurabilityLabel.Text = "Average: " .. formatNumber(savedAvgDurabilityPerHour) .. "/Hour | " .. formatNumber(savedAvgDurabilityPerDay) .. "/Day | " .. formatNumber(savedAvgDurabilityPerWeek) .. "/Week"
                end
            end
        else
            if trackingStarted then
                trackingStarted = false
                pausedElapsedTime = pausedElapsedTime + (currentTime - startTime)
                local days = math.floor(pausedElapsedTime / (24 * 3600))
                local hours = math.floor((pausedElapsedTime % (24 * 3600)) / 3600)
                local minutes = math.floor((pausedElapsedTime % 3600) / 60)
                local seconds = math.floor(pausedElapsedTime % 60)
                
                if pausedElapsedTime > 0 then
                    stopwatchLabel.Text = string.format("%dd %dh %dm %ds - Farming Paused", days, hours, minutes, seconds)
                    stopwatchLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
                else
                    stopwatchLabel.Text = "0d 0h 0m 0s - Fast Rep Inactive"
                    stopwatchLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                end

                strengthHistory = {}
                durabilityHistory = {}
            end
        end

        task.wait(0.05)
    end
end)

farmTab:AddLabel("")
farmTab:AddLabel("⚡ Fast Farm:").TextSize = 17
local farmRunning = false
local repSpeed = 350
local pingControl = true

local networkStats = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]

local function getCurrentPing()
    return networkStats:GetValue()
end

local function getAdaptiveSpeed(ping)
    if ping < 80 then
        return 500
    elseif ping < 150 then
        return 300
    elseif ping < 250 then
        return 100
    else
        return 50
    end
end



farmTab.AddTextBox(farmTab, "Rep Speed:", function(inputText)
    local speedValue = tonumber(inputText)
    if speedValue then
        repSpeed = math.clamp(math.floor(speedValue), 1, 1000)
    end
end)

farmTab.AddSwitch(farmTab, "Controlled Speed", function(isEnabled)
    pingControl = isEnabled
end):Set(true)

local function startAutoRep()
    local lastPingUpdate = time()
    local currentPing = getCurrentPing()
    while farmRunning do
        if time() - lastPingUpdate > 0.5 then
            currentPing = getCurrentPing()
            lastPingUpdate = time()
        end
        local repsToFire = pingControl and getAdaptiveSpeed(currentPing) or repSpeed
        local delayBetweenBatches = math.clamp(currentPing / 2500, 0.001, 0.1)
        for repCount = 1, math.min(repsToFire, repSpeed) do
            muscleEvent:FireServer("rep")
            if repCount % 500 == 0 then
                task.wait(0)
            end
        end
        task.wait(delayBetweenBatches)
    end
end

farmTab.AddSwitch(farmTab, "Fast Rep", function(isEnabled)
    farmRunning = isEnabled
    if farmRunning then
        runFastRep = true
        task.spawn(startAutoRep)
    else 
        runFastRep = false
        task.cancel(startAutoRep)
    end
end)


farmTab:AddLabel("For me, 20-40 works the best").TextSize = 15
farmTab:AddLabel("Try Around!")


local settingsTab = window:AddTab("Misc")

settingsTab:AddLabel("📈 Better Farming:").TextSize = 17

local running = false
local thread = nil

local sizeSwitch = settingsTab:AddSwitch("Set Size 1", function(bool)
    running = bool
    if running then
        thread = coroutine.create(function()
            while running do
                game:GetService("ReplicatedStorage").rEvents.changeSpeedSizeRemote:InvokeServer("changeSize", 1)
                wait(0.01)
            end
        end)
        coroutine.resume(thread)
    end
end)

local posLocked = false
local lockedPosition = nil

local function lockPosition()
	if not posLocked or not lockedPosition then
		return
	end

	local currentCharacter = player.Character
	if not currentCharacter then
		return
	end

	local rootPart = currentCharacter:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	local existingPosition = rootPart:FindFirstChild("PositionLocker")

	if existingPosition then
		existingPosition.Position = lockedPosition
	else
		local bodyPosition = Instance.new("BodyPosition")
		bodyPosition.Name = "PositionLocker"
		bodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		bodyPosition.Position = lockedPosition
		bodyPosition.P = 100000
		bodyPosition.Parent = rootPart
	end
end

local function unlockPosition()
	local currentCharacter = player.Character
	if currentCharacter then
		local rootPart = currentCharacter:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local existingPosition = rootPart:FindFirstChild("PositionLocker")
			if existingPosition then
				existingPosition:Destroy()
			end
		end
	end
	lockedPosition = nil
end

local lockPositionSwitch = settingsTab:AddSwitch("Lock Position", function(bool)
	posLocked = bool

	if bool then
		local currentRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if currentRootPart then
			lockedPosition = currentRootPart.Position
		end
		lockPosition()
	else
		unlockPosition()
	end
end)

player.CharacterAdded:Connect(function(newCharacter)
	local rootPart = newCharacter:WaitForChild("HumanoidRootPart", 5)
	if posLocked and rootPart then
		lockedPosition = rootPart.Position
		lockPosition()
	end
end)

task.spawn(function()
	while true do
		if posLocked then
			lockPosition()
		end
		task.wait(0.1)
	end
end)


local blockedFrames = {
	"strengthFrame",
	"durabilityFrame",
	"agilityFrame",
	"evilKarmaFrame",
	"goodKarmaFrame",
}

local frameSwitch = settingsTab:AddSwitch("Hide Stat Frames", function(bool)
	if bool then
		for _, name in ipairs(blockedFrames) do
			local frame = replicatedStorage:FindFirstChild(name)
			if frame and frame:IsA("GuiObject") then
				frame.Visible = false
			end
		end

		if not _G.frameMonitorConnection then
			_G.frameMonitorConnection = replicatedStorage.ChildAdded:Connect(function(child)
				for _, name in ipairs(blockedFrames) do
					if child.Name == name and child:IsA("GuiObject") then
						child.Visible = false
					end
				end
			end)
		end
	else
		for _, name in ipairs(blockedFrames) do
			local frame = replicatedStorage:FindFirstChild(name)
			if frame and frame:IsA("GuiObject") then
				frame.Visible = true
			end
		end

		if _G.frameMonitorConnection then
			_G.frameMonitorConnection:Disconnect()
			_G.frameMonitorConnection = nil
		end
	end
end)
frameSwitch:Set(false)


settingsTab:AddButton("Anti Lag", function()
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local lighting = game:GetService("Lighting")

    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            gui:Destroy()
        end
    end

    local function darkenSky()
        for _, v in pairs(lighting:GetChildren()) do
            if v:IsA("Sky") then
                v:Destroy()
            end
        end

        local darkSky = Instance.new("Sky")
        darkSky.Name = "DarkSky"
        darkSky.SkyboxBk = "rbxassetid://0"
        darkSky.SkyboxDn = "rbxassetid://0"
        darkSky.SkyboxFt = "rbxassetid://0"
        darkSky.SkyboxLf = "rbxassetid://0"
        darkSky.SkyboxRt = "rbxassetid://0"
        darkSky.SkyboxUp = "rbxassetid://0"
        darkSky.Parent = lighting

        lighting.Brightness = 0
        lighting.ClockTime = 0
        lighting.TimeOfDay = "00:00:00"
        lighting.OutdoorAmbient = Color3.new(0, 0, 0)
        lighting.Ambient = Color3.new(0, 0, 0)
        lighting.FogColor = Color3.new(0, 0, 0)
        lighting.FogEnd = 100

        task.spawn(function()
            while true do
                wait(5)
                if not lighting:FindFirstChild("DarkSky") then
                    darkSky:Clone().Parent = lighting
                end
                lighting.Brightness = 0
                lighting.ClockTime = 0
                lighting.OutdoorAmbient = Color3.new(0, 0, 0)
                lighting.Ambient = Color3.new(0, 0, 0)
                lighting.FogColor = Color3.new(0, 0, 0)
                lighting.FogEnd = 100
            end
        end)
    end

    local function removeParticleEffects()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") then
                obj:Destroy()
            end
        end
    end

    local function removeLightSources()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                obj:Destroy()
            end
        end
    end

    removeParticleEffects()
    removeLightSources()
    darkenSky()
end)
    
local PlayerData = {
    Backpack = player:WaitForChild("Backpack")
}

settingsTab:AddLabel("🔥 QoL:").TextSize = 17

local ProteinEggLabel = settingsTab:AddLabel("Protein Eggs Owned: 0")
ProteinEggLabel.TextSize = 14

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
		ProteinEggLabel.Text = "Protein Eggs: " .. proteinEggCount
		task.wait(7.5)
	end
end)

local ProteinEggBoostLabel = settingsTab:AddLabel("Protein Egg Boost: 00:00")
ProteinEggBoostLabel.TextSize = 14

local function formatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%02d:%02d", m, s)
end

task.spawn(function()
    while true do
        local boostTimersFolder = game.Players.LocalPlayer:FindFirstChild("boostTimersFolder")
        if boostTimersFolder then
            local boost = boostTimersFolder:FindFirstChild("Protein Egg")
            if boost and boost:IsA("IntValue") then
                local seconds = boost.Value
                ProteinEggBoostLabel.Text = "Protein Egg Timer: " .. formatTime(seconds)
            else
                ProteinEggBoostLabel.Text = "Protein Egg Timer: 00:00"
            end
        else
            ProteinEggBoostLabel.Text = "Protein Egg Timer: 00:00"
        end
        task.wait(0.5)
    end
end)


local function useEggs()
    local boost = game.Players.LocalPlayer.boostTimersFolder:FindFirstChild("Protein Egg")
    if boost and boost:IsA("IntValue") then
        local seconds = boost.Value
        if seconds >= 5 then
            return
        end
    end
    
    local tool = player.Character:FindFirstChild("Protein Egg") or player.Backpack:FindFirstChild("Protein Egg")
    if tool then
        muscleEvent:FireServer("proteinEgg", tool)
    end
end

local running1 = false

task.spawn(function()
    while true do
        if running1 then
            useEggs()
            task.wait(1800)
        else
            task.wait(1)
        end
    end
end)

local autoEggSwitch = settingsTab:AddSwitch("Auto Egg", function(state)
    running1 = state
    if state then
        useEggs()
    end
end)


local function useShakes()
    local tool = player.Character:FindFirstChild("Tropical Shake") or player.Backpack:FindFirstChild("Tropical Shake")
    if tool then
        muscleEvent:FireServer("tropicalShake", tool)
    end
end

local running2 = false

task.spawn(function()
    while true do
        if running2 then
            useShakes()
            task.wait(450)
        else
            task.wait(1)
        end
    end
end)

local autoShakeSwitch = settingsTab:AddSwitch("Auto Shake", function(state)
    running2 = state
    if state then
        useShakes()
    end
end)


local spinwheelSwitch = settingsTab:AddSwitch("Spin Fortune Wheel", function(bool)
    _G.AutoSpinWheel = bool
    
    if bool then
        spawn(function()
            while _G.AutoSpinWheel and wait(1) do
                game:GetService("ReplicatedStorage").rEvents.openFortuneWheelRemote:InvokeServer("openFortuneWheel", game:GetService("ReplicatedStorage").fortuneWheelChances["Fortune Wheel"])
            end
        end)
    end
end)

local statPetDropdown = settingsTab:AddDropdown("Perk Pet Equip", function(text)
	local petsFolder = game.Players.LocalPlayer.petsFolder
	for _, folder in pairs(petsFolder:GetChildren()) do
		if folder:IsA("Folder") then
			for _, pet in pairs(folder:GetChildren()) do
				game:GetService("ReplicatedStorage").rEvents.equipPetEvent:FireServer("unequipPet", pet)
			end
		end
	end
	task.wait(0.2)

	local petName = text
	local petsToEquip = {}

	for _, pet in pairs(game.Players.LocalPlayer.petsFolder.Unique:GetChildren()) do
		if pet.Name == petName then
			table.insert(petsToEquip, pet)
		end
	end

	for i = 1, math.min(8, #petsToEquip) do
		game:GetService("ReplicatedStorage").rEvents.equipPetEvent:FireServer("equipPet", petsToEquip[i])
		task.wait(0.1)
	end
end)
statPetDropdown:Add("Swift Samurai")
statPetDropdown:Add("Tribal Overlord")

local char = player.Character or player.CharacterAdded:wait()
local hrp = char:WaitForChild("HumanoidRootPart")

settingsTab:AddButton("Jungle Lift",function()
    hrp.CFrame = CFrame.new(-8642.396484375, 6.7980651855, 2086.1030273)
    task.wait(0.2)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end)

settingsTab:AddButton("Jungle Squat",function()
    hrp.CFrame = CFrame.new(-8371.43359375, 6.79806327, 2858.88525390)
    task.wait(0.2)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end)

local infoTab = window:AddTab("Info")
infoTab:Show()
infoTab:AddLabel("Made with ♥️ by Henne").TextSize = 17
infoTab:AddLabel("You need 7-8 Robux Packs for Fast Farming❕").TextSize = 17
infoTab:AddLabel("Official Discord: discord.gg/9eFf93Kg8D").TextSize = 17
infoTab:AddButton("Copy Discord Invite", function()
    local link = "https://discord.gg/9eFf93Kg8D"
    if setclipboard then
        setclipboard(link)
        game.StarterGui:SetCore("SendNotification", {
            Title = "Link Copied!";
            Text = "You can continue to Discord now.";
            Duration = 3;
        })
    else
        game.StarterGui:SetCore("SendNotification", {
            Title = "Error!";
            Text = "Clipboard not Supported.";
            Duration = 3;
        })
    end
end)

infoTab:AddLabel("")
local wLabel = infoTab:AddLabel("Silence [V3.3.0]")
wLabel.TextSize = 40
wLabel.Font = Enum.Font.Arcade

