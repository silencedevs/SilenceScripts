--[[
    Silence - Ml Farming
    by Henne @xyzhenrik_
       Muki @mukimagdich
]]

local services = {
    players = game:GetService("Players"),
    replicatedstorage = game:GetService("ReplicatedStorage"),
    runservice = game:GetService("RunService"),
    tws = game:GetService("TweenService"),
    userinputservice = game:GetService("UserInputService"),
    httpservice = game:GetService("HttpService"),
    virtualuser = game:GetService("VirtualUser"),
    virtualinputmanager = game:GetService("VirtualInputManager"),
    lighting = game:GetService("Lighting"),
    startergui = game:GetService("StarterGui")
}

local lp = {
    player = services.players.LocalPlayer,
    userid = services.players.LocalPlayer.UserId,
    username = services.players.LocalPlayer.Name,
    displayname = services.players.LocalPlayer.DisplayName
}

lp.player.Idled:Connect(function()
    services.virtualinputmanager:SendKeyEvent(true, Enum.KeyCode.Y, false, game)
    task.wait(0.05)
    services.virtualinputmanager:SendKeyEvent(false, Enum.KeyCode.Y, false, game)
end)

function deleteAds()
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

function deleteBodyMovementScript()
    if lp.player.Character and lp.player.Character:FindFirstChild("bodyMovementScript") then
        lp.player.Character.bodyMovementScript:Destroy()
    end
end
deleteBodyMovementScript()


services.muscleEvent = lp.player:WaitForChild("muscleEvent")

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/silencedevs/SilenceScripts/refs/heads/main/librarys/eleriumv2.luau"))()
local silence = library:AddWindow("Silence | Fast Farming - Hey, " .. lp.displayname .. "!", {
    main_color = Color3.fromRGB(138, 0, 0),
    min_size = Vector2.new(500, 500),
    can_resize = false
})

local tabs = {
    rebirths = silence:AddTab("Rebirths"),
    strength = silence:AddTab("Strength (Main)"),
    strength2 = silence:AddTab("Strength (If Main lags)"),
    other = silence:AddTab("Other"),
    info = silence:AddTab("Info")
}

tabs.other:Show()

function formatNumber(num)
    if num >= 1e18 then return string.format("%.2fQi", num/1e18) end
    if num >= 1e15 then return string.format("%.2fQa", num/1e15) end
    if num >= 1e12 then return string.format("%.2fT", num/1e12) end
    if num >= 1e9 then return string.format("%.2fB", num/1e9) end
    if num >= 1e6 then return string.format("%.2fM", num/1e6) end
    if num >= 1e3 then return string.format("%.2fK", num/1e3) end
    return string.format("%.0f", num)
end

-- Rebirth Tab

tabs.rebirths.leaderstats = lp.player:WaitForChild("leaderstats")
tabs.rebirths.rebirths = tabs.rebirths.leaderstats:WaitForChild("Rebirths")
tabs.rebirths.strength = tabs.rebirths.leaderstats:WaitForChild("Strength")
tabs.rebirths.running = false
tabs.rebirths.workerActive = false
tabs.rebirths.startedAt = 0
tabs.rebirths.timerStarted = false
tabs.rebirths.hasStarted = false
tabs.rebirths.totalElapsed = 0
tabs.rebirths.startRebirths = tabs.rebirths.rebirths.Value
tabs.rebirths.gainedBaselineSet = false
tabs.rebirths.lastRebirthAt = tick()
tabs.rebirths.lastRebirthValue = tabs.rebirths.rebirths.Value
tabs.rebirths.paceBaselineReady = false
tabs.rebirths.petFolders = {}
tabs.rebirths.pets = {}
tabs.rebirths.uniquePets = {}
tabs.rebirths.omegas = {}
tabs.rebirths.swifts = {}
tabs.rebirths.hounds = {}
tabs.rebirths.hydras = {}
tabs.rebirths.tribals = {}
tabs.rebirths.folderIndex = 1
tabs.rebirths.petIndex = 1
tabs.rebirths.repIndex = 1
tabs.rebirths.equippedCount = 0
tabs.rebirths.currentPercent = 0
tabs.rebirths.maxSlots = 9
tabs.rebirths.strengthTarget = 0
tabs.rebirths.repsPerBurst = 12
tabs.rebirths.rebirthValueBefore = tabs.rebirths.rebirths.Value
tabs.rebirths.Status = tabs.rebirths:AddLabel("Status: Inactive")
tabs.rebirths.Runtime = tabs.rebirths:AddLabel("Runtime: 0d 0h 0m 0s")
tabs.rebirths.RebirthStats = tabs.rebirths:AddLabel("Rebirths: " .. formatNumber(tabs.rebirths.rebirths.Value) .. " | Gained: 0")
tabs.rebirths.Pace = tabs.rebirths:AddLabel("Pace: -- / Hour | -- / Day | -- / Week")
tabs.rebirths.AveragePace = tabs.rebirths:AddLabel("Average: -- / Hour | -- / Day | -- / Week")
tabs.rebirths.Status.TextColor3 = Color3.fromRGB(255, 80, 80)

tabs.rebirths.updateStats = function()
    tabs.rebirths.RebirthStats.Text = "Rebirths: " .. formatNumber(tabs.rebirths.rebirths.Value)
        .. " | Gained: " .. formatNumber(tabs.rebirths.rebirths.Value - tabs.rebirths.startRebirths)
end

tabs.rebirths.updateRuntime = function()
    tabs.rebirths.elapsed = tabs.rebirths.totalElapsed
    if tabs.rebirths.running and tabs.rebirths.timerStarted then
        tabs.rebirths.elapsed = tabs.rebirths.elapsed + tick() - tabs.rebirths.startedAt
    end

    tabs.rebirths.Runtime.Text = string.format(
        "Runtime: %dd %dh %dm %ds",
        math.floor(tabs.rebirths.elapsed / 86400),
        math.floor((tabs.rebirths.elapsed % 86400) / 3600),
        math.floor((tabs.rebirths.elapsed % 3600) / 60),
        math.floor(tabs.rebirths.elapsed % 60)
    )
end

tabs.rebirths.updatePace = function()
    if not tabs.rebirths.running then
        return
    end

    if not tabs.rebirths.paceBaselineReady then
        tabs.rebirths.paceBaselineReady = true
        tabs.rebirths.timerStarted = true
        tabs.rebirths.startedAt = tick()
        tabs.rebirths.lastRebirthAt = tick()
        tabs.rebirths.lastRebirthValue = tabs.rebirths.rebirths.Value
        tabs.rebirths.averageStartedAt = tick()
        tabs.rebirths.averageStartRebirths = tabs.rebirths.rebirths.Value
        return
    end

    if tabs.rebirths.rebirths.Value <= tabs.rebirths.lastRebirthValue then
        return
    end

    tabs.rebirths.rebirthGain = tabs.rebirths.rebirths.Value - tabs.rebirths.lastRebirthValue
    tabs.rebirths.secondsPerRebirth = (tick() - tabs.rebirths.lastRebirthAt) / tabs.rebirths.rebirthGain
    tabs.rebirths.hourlyPace = 3600 / tabs.rebirths.secondsPerRebirth
    tabs.rebirths.dailyPace = 86400 / tabs.rebirths.secondsPerRebirth
    tabs.rebirths.weeklyPace = 604800 / tabs.rebirths.secondsPerRebirth

    tabs.rebirths.Pace.Text = string.format(
        "Pace: %s / Hour | %s / Day | %s / Week",
        formatNumber(tabs.rebirths.hourlyPace),
        formatNumber(tabs.rebirths.dailyPace),
        formatNumber(tabs.rebirths.weeklyPace)
    )

    tabs.rebirths.averageElapsed = tick() - tabs.rebirths.averageStartedAt
    tabs.rebirths.averageHourlyPace = (tabs.rebirths.rebirths.Value - tabs.rebirths.averageStartRebirths)
        / tabs.rebirths.averageElapsed * 3600

    tabs.rebirths.AveragePace.Text = string.format(
        "Average: %s / Hour | %s / Day | %s / Week",
        formatNumber(tabs.rebirths.averageHourlyPace),
        formatNumber(tabs.rebirths.averageHourlyPace * 24),
        formatNumber(tabs.rebirths.averageHourlyPace * 168)
    )

    tabs.rebirths.lastRebirthAt = tick()
    tabs.rebirths.lastRebirthValue = tabs.rebirths.rebirths.Value
end

tabs.rebirths.unequipAllPets = function()
    tabs.rebirths.petFolders = lp.player.petsFolder:GetChildren()
    tabs.rebirths.folderIndex = 1
    while tabs.rebirths.folderIndex <= #tabs.rebirths.petFolders do
        tabs.rebirths.petFolder = tabs.rebirths.petFolders[tabs.rebirths.folderIndex]
        if tabs.rebirths.petFolder:IsA("Folder") then
            tabs.rebirths.pets = tabs.rebirths.petFolder:GetChildren()
            tabs.rebirths.petIndex = 1
            while tabs.rebirths.petIndex <= #tabs.rebirths.pets do
                tabs.rebirths.pet = tabs.rebirths.pets[tabs.rebirths.petIndex]
                services.replicatedstorage.rEvents.equipPetEvent:FireServer("unequipPet", tabs.rebirths.pet)
                tabs.rebirths.petIndex = tabs.rebirths.petIndex + 1
            end
        end
        tabs.rebirths.folderIndex = tabs.rebirths.folderIndex + 1
    end
    task.wait(0.1)
end

tabs.rebirths.equipFarmingPets = function()
    tabs.rebirths.unequipAllPets()

    tabs.rebirths.omegas = {}
    tabs.rebirths.swifts = {}
    tabs.rebirths.hounds = {}
    tabs.rebirths.uniquePets = lp.player.petsFolder.Unique:GetChildren()
    tabs.rebirths.petIndex = 1

    while tabs.rebirths.petIndex <= #tabs.rebirths.uniquePets do
        tabs.rebirths.pet = tabs.rebirths.uniquePets[tabs.rebirths.petIndex]
        if tabs.rebirths.pet.Name == "Omega Overlord" then
            table.insert(tabs.rebirths.omegas, tabs.rebirths.pet)
        elseif tabs.rebirths.pet.Name == "Swift Samurai" then
            table.insert(tabs.rebirths.swifts, tabs.rebirths.pet)
        elseif tabs.rebirths.pet.Name == "Powercore Hound" then
            table.insert(tabs.rebirths.hounds, tabs.rebirths.pet)
        end
        tabs.rebirths.petIndex = tabs.rebirths.petIndex + 1
    end

    tabs.rebirths.equippedCount = 0
    tabs.rebirths.currentPercent = 0

    tabs.rebirths.petIndex = #tabs.rebirths.omegas
    while tabs.rebirths.petIndex >= 1 do
        if tabs.rebirths.equippedCount < tabs.rebirths.maxSlots and tabs.rebirths.currentPercent < 100 then
            tabs.rebirths.pet = table.remove(tabs.rebirths.omegas, tabs.rebirths.petIndex)
            services.replicatedstorage.rEvents.equipPetEvent:FireServer("equipPet", tabs.rebirths.pet)
            tabs.rebirths.currentPercent = tabs.rebirths.currentPercent + 20
            tabs.rebirths.equippedCount = tabs.rebirths.equippedCount + 1
        end
        tabs.rebirths.petIndex = tabs.rebirths.petIndex - 1
    end

    tabs.rebirths.petIndex = #tabs.rebirths.swifts
    while tabs.rebirths.petIndex >= 1 do
        if tabs.rebirths.equippedCount < tabs.rebirths.maxSlots and tabs.rebirths.currentPercent < 100 then
            tabs.rebirths.pet = table.remove(tabs.rebirths.swifts, tabs.rebirths.petIndex)
            services.replicatedstorage.rEvents.equipPetEvent:FireServer("equipPet", tabs.rebirths.pet)
            tabs.rebirths.currentPercent = tabs.rebirths.currentPercent + 15
            tabs.rebirths.equippedCount = tabs.rebirths.equippedCount + 1
        end
        tabs.rebirths.petIndex = tabs.rebirths.petIndex - 1
    end

    if tabs.rebirths.currentPercent >= 100 then
        tabs.rebirths.petIndex = #tabs.rebirths.hounds
        while tabs.rebirths.petIndex >= 1 do
            if tabs.rebirths.equippedCount < tabs.rebirths.maxSlots then
                tabs.rebirths.pet = table.remove(tabs.rebirths.hounds, tabs.rebirths.petIndex)
                services.replicatedstorage.rEvents.equipPetEvent:FireServer("equipPet", tabs.rebirths.pet)
                tabs.rebirths.equippedCount = tabs.rebirths.equippedCount + 1
            end
            tabs.rebirths.petIndex = tabs.rebirths.petIndex - 1
        end
    end

    tabs.rebirths.petIndex = #tabs.rebirths.omegas
    while tabs.rebirths.petIndex >= 1 do
        if tabs.rebirths.equippedCount < tabs.rebirths.maxSlots then
            tabs.rebirths.pet = table.remove(tabs.rebirths.omegas, tabs.rebirths.petIndex)
            services.replicatedstorage.rEvents.equipPetEvent:FireServer("equipPet", tabs.rebirths.pet)
            tabs.rebirths.equippedCount = tabs.rebirths.equippedCount + 1
        end
        tabs.rebirths.petIndex = tabs.rebirths.petIndex - 1
    end

    tabs.rebirths.petIndex = #tabs.rebirths.swifts
    while tabs.rebirths.petIndex >= 1 do
        if tabs.rebirths.equippedCount < tabs.rebirths.maxSlots then
            tabs.rebirths.pet = table.remove(tabs.rebirths.swifts, tabs.rebirths.petIndex)
            services.replicatedstorage.rEvents.equipPetEvent:FireServer("equipPet", tabs.rebirths.pet)
            tabs.rebirths.equippedCount = tabs.rebirths.equippedCount + 1
        end
        tabs.rebirths.petIndex = tabs.rebirths.petIndex - 1
    end
end

tabs.rebirths.equipRebirthPets = function()
    tabs.rebirths.unequipAllPets()

    tabs.rebirths.hydras = {}
    tabs.rebirths.tribals = {}
    tabs.rebirths.uniquePets = lp.player.petsFolder.Unique:GetChildren()
    tabs.rebirths.petIndex = 1

    while tabs.rebirths.petIndex <= #tabs.rebirths.uniquePets do
        tabs.rebirths.pet = tabs.rebirths.uniquePets[tabs.rebirths.petIndex]
        if tabs.rebirths.pet.Name == "Titanium Hydra" then
            table.insert(tabs.rebirths.hydras, tabs.rebirths.pet)
        elseif tabs.rebirths.pet.Name == "Tribal Overlord" then
            table.insert(tabs.rebirths.tribals, tabs.rebirths.pet)
        end
        tabs.rebirths.petIndex = tabs.rebirths.petIndex + 1
    end

    tabs.rebirths.equippedCount = 0

    tabs.rebirths.petIndex = 1
    while tabs.rebirths.petIndex <= #tabs.rebirths.hydras do
        if tabs.rebirths.equippedCount < tabs.rebirths.maxSlots then
            tabs.rebirths.pet = tabs.rebirths.hydras[tabs.rebirths.petIndex]
            services.replicatedstorage.rEvents.equipPetEvent:FireServer("equipPet", tabs.rebirths.pet)
            tabs.rebirths.equippedCount = tabs.rebirths.equippedCount + 1
        end
        tabs.rebirths.petIndex = tabs.rebirths.petIndex + 1
    end

    tabs.rebirths.petIndex = 1
    while tabs.rebirths.petIndex <= #tabs.rebirths.tribals do
        if tabs.rebirths.equippedCount < tabs.rebirths.maxSlots then
            tabs.rebirths.pet = tabs.rebirths.tribals[tabs.rebirths.petIndex]
            services.replicatedstorage.rEvents.equipPetEvent:FireServer("equipPet", tabs.rebirths.pet)
            tabs.rebirths.equippedCount = tabs.rebirths.equippedCount + 1
        end
        tabs.rebirths.petIndex = tabs.rebirths.petIndex + 1
    end
end

tabs.rebirths.performRebirth = function()
    tabs.rebirths.strengthTarget = 5000 + tabs.rebirths.rebirths.Value * 2550
    tabs.rebirths.repsPerBurst = lp.player.MembershipType == Enum.MembershipType.Premium and 6 or 12

    tabs.rebirths.repIndex = 1
    while tabs.rebirths.running and tabs.rebirths.strength.Value < tabs.rebirths.strengthTarget do
        tabs.rebirths.repIndex = 1
        while tabs.rebirths.repIndex <= tabs.rebirths.repsPerBurst do
            services.muscleEvent:FireServer("rep")
            tabs.rebirths.repIndex = tabs.rebirths.repIndex + 1
        end
        task.wait(0.02)
    end

    if tabs.rebirths.running and tabs.rebirths.strength.Value >= tabs.rebirths.strengthTarget then
        tabs.rebirths.equipRebirthPets()
        task.wait(0.25)
        tabs.rebirths.rebirthValueBefore = tabs.rebirths.rebirths.Value

        repeat
            services.replicatedstorage.rEvents.rebirthRemote:InvokeServer("rebirthRequest")
            task.wait(0.05)
        until tabs.rebirths.rebirths.Value > tabs.rebirths.rebirthValueBefore or not tabs.rebirths.running
    end
end

tabs.rebirths.startWorker = function()
    if tabs.rebirths.workerActive then
        return
    end

    tabs.rebirths.workerActive = true
    task.spawn(function()
        while tabs.rebirths.running do
            tabs.rebirths.equipFarmingPets()
            tabs.rebirths.performRebirth()
            task.wait(0.5)
        end
        tabs.rebirths.workerActive = false
    end)
end

tabs.rebirths.rebirths:GetPropertyChangedSignal("Value"):Connect(function()
    tabs.rebirths.updatePace()
    tabs.rebirths.updateStats()
end)

tabs.rebirths:AddSwitch("Fast Rebirth", function(state)
    tabs.rebirths.running = state
    if state then
        tabs.rebirths.hasStarted = true
        tabs.rebirths.startedAt = 0
        tabs.rebirths.timerStarted = false
        if not tabs.rebirths.gainedBaselineSet then
            tabs.rebirths.startRebirths = tabs.rebirths.rebirths.Value
            tabs.rebirths.gainedBaselineSet = true
        end
        tabs.rebirths.lastRebirthAt = tick()
        tabs.rebirths.lastRebirthValue = tabs.rebirths.rebirths.Value
        tabs.rebirths.paceBaselineReady = false
        tabs.rebirths.Status.Text = "Status: Rebirthing"
        tabs.rebirths.Status.TextColor3 = Color3.fromRGB(80, 255, 120)
        tabs.rebirths.updateStats()
        tabs.rebirths.startWorker()
    else
        if tabs.rebirths.timerStarted and tabs.rebirths.startedAt > 0 then
            tabs.rebirths.totalElapsed = tabs.rebirths.totalElapsed + tick() - tabs.rebirths.startedAt
            tabs.rebirths.startedAt = 0
            tabs.rebirths.timerStarted = false
        end
        tabs.rebirths.Status.Text = tabs.rebirths.hasStarted and "Status: Paused" or "Status: Inactive"
        tabs.rebirths.Status.TextColor3 = tabs.rebirths.hasStarted and Color3.fromRGB(255, 180, 70) or Color3.fromRGB(255, 80, 80)
        tabs.rebirths.updateRuntime()
    end
end):Set(false)

task.spawn(function()
    while true do
        tabs.rebirths.updateRuntime()
        task.wait(1)
    end
end)

-- Strength Tab

tabs.strength.leaderstats = lp.player:WaitForChild("leaderstats")
tabs.strength.strength = tabs.strength.leaderstats:WaitForChild("Strength")
tabs.strength.durability = lp.player:WaitForChild("Durability")
tabs.strength.running = false
tabs.strength.workerActive = false
tabs.strength.startedAt = 0
tabs.strength.totalElapsed = 0
tabs.strength.timerStarted = false
tabs.strength.gainedBaselineSet = false
tabs.strength.startStrength = tabs.strength.strength.Value
tabs.strength.startDurability = tabs.strength.durability.Value
tabs.strength.lastSampleAt = tick()
tabs.strength.lastStrength = tabs.strength.strength.Value
tabs.strength.lastDurability = tabs.strength.durability.Value
tabs.strength.paceBaselineReady = false
tabs.strength.calculationInterval = 10
tabs.strength.lastCalculationAt = tick()
tabs.strength.lastCalculatedStrength = tabs.strength.strength.Value
tabs.strength.lastCalculatedDurability = tabs.strength.durability.Value
tabs.strength.initialSendRate = 200
tabs.strength.maxSendRate = 1200
tabs.strength.sendRate = tabs.strength.initialSendRate
tabs.strength.sendTokens = 0
tabs.strength.maxBurst = 24
tabs.strength.controlInterval = 0.5
tabs.strength.lastControlAt = tick()
tabs.strength.lastProgressAt = tick()
tabs.strength.lastControlStrength = tabs.strength.strength.Value
tabs.strength.lastControlDurability = tabs.strength.durability.Value
tabs.strength.stalledIntervals = 0
tabs.strength.lastLoopAt = os.clock()
tabs.strength.repIndex = 1
tabs.strength.Status = tabs.strength:AddLabel("Status: Inactive")
tabs.strength.Runtime = tabs.strength:AddLabel("Runtime: 0d 0h 0m 0s")
tabs.strength.StrengthStats = tabs.strength:AddLabel("Strength: " .. formatNumber(tabs.strength.strength.Value) .. " | Gained: 0")
tabs.strength.DurabilityStats = tabs.strength:AddLabel("Durability: " .. formatNumber(tabs.strength.durability.Value) .. " | Gained: 0")
tabs.strength.StrengthPace = tabs.strength:AddLabel("Strength Pace: -- / Hour | -- / Day")
tabs.strength.DurabilityPace = tabs.strength:AddLabel("Durability Pace: -- / Hour | -- / Day")
tabs.strength.StrengthAverage = tabs.strength:AddLabel("Strength Average: -- / Hour | -- / Day")
tabs.strength.DurabilityAverage = tabs.strength:AddLabel("Durability Average: -- / Hour | -- / Day")
tabs.strength.Status.TextColor3 = Color3.fromRGB(255, 80, 80)

tabs.strength.updateRuntime = function()
    tabs.strength.elapsed = tabs.strength.totalElapsed
    if tabs.strength.running and tabs.strength.timerStarted then
        tabs.strength.elapsed = tabs.strength.elapsed + tick() - tabs.strength.startedAt
    end

    tabs.strength.Runtime.Text = string.format(
        "Runtime: %dd %dh %dm %ds",
        math.floor(tabs.strength.elapsed / 86400),
        math.floor((tabs.strength.elapsed % 86400) / 3600),
        math.floor((tabs.strength.elapsed % 3600) / 60),
        math.floor(tabs.strength.elapsed % 60)
    )
end

tabs.strength.updateStats = function()
    tabs.strength.StrengthStats.Text = "Strength: " .. formatNumber(tabs.strength.strength.Value)
        .. " | Gained: " .. formatNumber(tabs.strength.strength.Value - tabs.strength.startStrength)
    tabs.strength.DurabilityStats.Text = "Durability: " .. formatNumber(tabs.strength.durability.Value)
        .. " | Gained: " .. formatNumber(tabs.strength.durability.Value - tabs.strength.startDurability)
end

tabs.strength.updatePace = function()
    if not tabs.strength.running then
        return
    end

    if not tabs.strength.timerStarted then
        if tabs.strength.strength.Value == tabs.strength.startStrength and tabs.strength.durability.Value == tabs.strength.startDurability then
            return
        end

        tabs.strength.timerStarted = true
        tabs.strength.startedAt = tick()
        tabs.strength.lastSampleAt = tick()
        tabs.strength.lastStrength = tabs.strength.strength.Value
        tabs.strength.lastDurability = tabs.strength.durability.Value
        tabs.strength.lastCalculationAt = tick()
        tabs.strength.lastCalculatedStrength = tabs.strength.strength.Value
        tabs.strength.lastCalculatedDurability = tabs.strength.durability.Value
        return
    end

end

tabs.strength.calculatePace = function()
    if not tabs.strength.running or not tabs.strength.timerStarted then
        return
    end

    if tick() - tabs.strength.lastCalculationAt < tabs.strength.calculationInterval then
        return
    end

    tabs.strength.calculationElapsed = tick() - tabs.strength.lastCalculationAt
    tabs.strength.strengthDelta = tabs.strength.strength.Value - tabs.strength.lastCalculatedStrength
    tabs.strength.durabilityDelta = tabs.strength.durability.Value - tabs.strength.lastCalculatedDurability
    tabs.strength.strengthHourlyPace = tabs.strength.strengthDelta / tabs.strength.calculationElapsed * 3600
    tabs.strength.durabilityHourlyPace = tabs.strength.durabilityDelta / tabs.strength.calculationElapsed * 3600

    if tabs.strength.strengthDelta > 0 then
        tabs.strength.StrengthPace.Text = "Strength Pace: " .. formatNumber(tabs.strength.strengthHourlyPace)
            .. " / Hour | " .. formatNumber(tabs.strength.strengthHourlyPace * 24) .. " / Day"
    end
    if tabs.strength.durabilityDelta > 0 then
        tabs.strength.DurabilityPace.Text = "Durability Pace: " .. formatNumber(tabs.strength.durabilityHourlyPace)
            .. " / Hour | " .. formatNumber(tabs.strength.durabilityHourlyPace * 24) .. " / Day"
    end

    tabs.strength.averageElapsed = tabs.strength.totalElapsed + tick() - tabs.strength.startedAt
    tabs.strength.averageStrengthHourly = (tabs.strength.strength.Value - tabs.strength.startStrength)
        / tabs.strength.averageElapsed * 3600
    tabs.strength.averageDurabilityHourly = (tabs.strength.durability.Value - tabs.strength.startDurability)
        / tabs.strength.averageElapsed * 3600
    tabs.strength.StrengthAverage.Text = "Strength Average: " .. formatNumber(tabs.strength.averageStrengthHourly)
        .. " / Hour | " .. formatNumber(tabs.strength.averageStrengthHourly * 24) .. " / Day"
    tabs.strength.DurabilityAverage.Text = "Durability Average: " .. formatNumber(tabs.strength.averageDurabilityHourly)
        .. " / Hour | " .. formatNumber(tabs.strength.averageDurabilityHourly * 24) .. " / Day"

    tabs.strength.lastCalculationAt = tick()
    tabs.strength.lastCalculatedStrength = tabs.strength.strength.Value
    tabs.strength.lastCalculatedDurability = tabs.strength.durability.Value
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
        tabs.strength.lastProgressAt = tabs.strength.controlNow
        tabs.strength.sendRate = math.min(tabs.strength.maxSendRate, tabs.strength.sendRate * 1.12)
        tabs.strength.Status.Text = "Status: Farming | "
            .. formatNumber(tabs.strength.sendRate) .. " reps/s"
        tabs.strength.Status.TextColor3 = Color3.fromRGB(80, 255, 120)
    else
        tabs.strength.stalledIntervals = tabs.strength.stalledIntervals + 1
    end

    if tabs.strength.stalledIntervals >= 2 then
        tabs.strength.sendRate = math.max(tabs.strength.initialSendRate, tabs.strength.sendRate * 0.65)
        tabs.strength.sendTokens = 0
        tabs.strength.Status.Text = "Status: Slowing for server | "
            .. formatNumber(tabs.strength.sendRate) .. " reps/s"
        tabs.strength.Status.TextColor3 = Color3.fromRGB(255, 180, 70)
    end

    tabs.strength.lastControlAt = tabs.strength.controlNow
    tabs.strength.lastControlStrength = tabs.strength.strength.Value
    tabs.strength.lastControlDurability = tabs.strength.durability.Value
end

tabs.strength.workerLoop = function()
    tabs.strength.lastLoopAt = os.clock()
    while tabs.strength.running do
        tabs.strength.loopNow = os.clock()
        tabs.strength.loopElapsed = math.min(0.1, tabs.strength.loopNow - tabs.strength.lastLoopAt)
        tabs.strength.lastLoopAt = tabs.strength.loopNow

        tabs.strength.updateAdaptiveRate()
        tabs.strength.sendTokens = math.min(
            tabs.strength.maxBurst,
            tabs.strength.sendTokens + tabs.strength.sendRate * tabs.strength.loopElapsed
        )
        tabs.strength.burstLimit = math.max(
            1,
            math.min(tabs.strength.maxBurst, math.ceil(tabs.strength.sendRate * 0.05))
        )
        tabs.strength.sendCount = math.min(
            math.floor(tabs.strength.sendTokens),
            tabs.strength.burstLimit
        )
        tabs.strength.repIndex = 1
        while tabs.strength.repIndex <= tabs.strength.sendCount do
            services.muscleEvent:FireServer("rep")
            tabs.strength.repIndex = tabs.strength.repIndex + 1
        end
        tabs.strength.sendTokens = tabs.strength.sendTokens - tabs.strength.sendCount

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
    task.spawn(tabs.strength.workerLoop)
end

tabs.strength.strength:GetPropertyChangedSignal("Value"):Connect(function()
    tabs.strength.updateStats()
    tabs.strength.updatePace()
end)

tabs.strength.durability:GetPropertyChangedSignal("Value"):Connect(function()
    tabs.strength.updateStats()
    tabs.strength.updatePace()
end)

tabs.strength.FastRepToggle = tabs.strength:AddSwitch("Fast Rep", function(state)
    tabs.strength.running = state
    if state then
        if not tabs.strength.gainedBaselineSet then
            tabs.strength.startStrength = tabs.strength.strength.Value
            tabs.strength.startDurability = tabs.strength.durability.Value
            tabs.strength.gainedBaselineSet = true
        end
        tabs.strength.timerStarted = false
        tabs.strength.startedAt = 0
        tabs.strength.lastSampleAt = tick()
        tabs.strength.lastStrength = tabs.strength.strength.Value
        tabs.strength.lastDurability = tabs.strength.durability.Value
        tabs.strength.paceBaselineReady = false
        tabs.strength.sendRate = tabs.strength.initialSendRate
        tabs.strength.sendTokens = 0
        tabs.strength.lastLoopAt = os.clock()
        tabs.strength.lastControlAt = tick()
        tabs.strength.lastProgressAt = tick()
        tabs.strength.lastControlStrength = tabs.strength.strength.Value
        tabs.strength.lastControlDurability = tabs.strength.durability.Value
        tabs.strength.stalledIntervals = 0
        tabs.strength.Status.Text = "Status: Farming | 200 reps/s"
        tabs.strength.Status.TextColor3 = Color3.fromRGB(80, 255, 120)
        tabs.strength.startWorker()
    else
        if tabs.strength.timerStarted and tabs.strength.startedAt > 0 then
            tabs.strength.totalElapsed = tabs.strength.totalElapsed + tick() - tabs.strength.startedAt
            tabs.strength.startedAt = 0
            tabs.strength.timerStarted = false
        end
        tabs.strength.sendTokens = 0
        tabs.strength.Status.Text = tabs.strength.gainedBaselineSet and "Status: Paused" or "Status: Inactive"
        tabs.strength.Status.TextColor3 = tabs.strength.gainedBaselineSet and Color3.fromRGB(255, 180, 70) or Color3.fromRGB(255, 80, 80)
        tabs.strength.updateRuntime()
    end
end)

tabs.strength.FastRepToggle:Set(false)

task.spawn(function()
    while true do
        tabs.strength.updateRuntime()
        tabs.strength.calculatePace()
        task.wait(1)
    end
end)

tabs.strength:AddLabel("Reaching Average Speed takes some time!")

-- Strength Tab (For bad devices)

tabs.strength2.leaderstats = lp.player:WaitForChild("leaderstats")
tabs.strength2.strength = tabs.strength2.leaderstats:WaitForChild("Strength")
tabs.strength2.durability = lp.player:WaitForChild("Durability")
tabs.strength2.running = false
tabs.strength2.workerActive = false
tabs.strength2.startedAt = 0
tabs.strength2.totalElapsed = 0
tabs.strength2.timerStarted = false
tabs.strength2.gainedBaselineSet = false
tabs.strength2.startStrength = tabs.strength2.strength.Value
tabs.strength2.startDurability = tabs.strength2.durability.Value
tabs.strength2.calculationInterval = 10
tabs.strength2.lastCalculationAt = tick()
tabs.strength2.lastCalculatedStrength = tabs.strength2.strength.Value
tabs.strength2.lastCalculatedDurability = tabs.strength2.durability.Value
tabs.strength2.repSpeed = 350
tabs.strength2.pingControl = true
tabs.strength2.currentPing = 0
tabs.strength2.Status = tabs.strength2:AddLabel("Status: Inactive")
tabs.strength2.Runtime = tabs.strength2:AddLabel("Runtime: 0d 0h 0m 0s")
tabs.strength2.StrengthStats = tabs.strength2:AddLabel("Strength: " .. formatNumber(tabs.strength2.strength.Value) .. " | Gained: 0")
tabs.strength2.DurabilityStats = tabs.strength2:AddLabel("Durability: " .. formatNumber(tabs.strength2.durability.Value) .. " | Gained: 0")
tabs.strength2.StrengthPace = tabs.strength2:AddLabel("Strength Pace: -- / Hour | -- / Day")
tabs.strength2.DurabilityPace = tabs.strength2:AddLabel("Durability Pace: -- / Hour | -- / Day")
tabs.strength2.StrengthAverage = tabs.strength2:AddLabel("Strength Average: -- / Hour | -- / Day")
tabs.strength2.DurabilityAverage = tabs.strength2:AddLabel("Durability Average: -- / Hour | -- / Day")
tabs.strength2.Status.TextColor3 = Color3.fromRGB(255, 80, 80)

tabs.strength2.updateRuntime = function()
    tabs.strength2.elapsed = tabs.strength2.totalElapsed
    if tabs.strength2.running and tabs.strength2.timerStarted then
        tabs.strength2.elapsed = tabs.strength2.elapsed + tick() - tabs.strength2.startedAt
    end

    tabs.strength2.Runtime.Text = string.format(
        "Runtime: %dd %dh %dm %ds",
        math.floor(tabs.strength2.elapsed / 86400),
        math.floor((tabs.strength2.elapsed % 86400) / 3600),
        math.floor((tabs.strength2.elapsed % 3600) / 60),
        math.floor(tabs.strength2.elapsed % 60)
    )
end

tabs.strength2.updateStats = function()
    tabs.strength2.StrengthStats.Text = "Strength: " .. formatNumber(tabs.strength2.strength.Value)
        .. " | Gained: " .. formatNumber(tabs.strength2.strength.Value - tabs.strength2.startStrength)
    tabs.strength2.DurabilityStats.Text = "Durability: " .. formatNumber(tabs.strength2.durability.Value)
        .. " | Gained: " .. formatNumber(tabs.strength2.durability.Value - tabs.strength2.startDurability)
end

tabs.strength2.updatePace = function()
    if not tabs.strength2.running or tabs.strength2.timerStarted then
        return
    end
    if tabs.strength2.strength.Value == tabs.strength2.startStrength
        and tabs.strength2.durability.Value == tabs.strength2.startDurability then
        return
    end

    tabs.strength2.timerStarted = true
    tabs.strength2.startedAt = tick()
    tabs.strength2.lastCalculationAt = tick()
    tabs.strength2.lastCalculatedStrength = tabs.strength2.strength.Value
    tabs.strength2.lastCalculatedDurability = tabs.strength2.durability.Value
end

tabs.strength2.calculatePace = function()
    if not tabs.strength2.running or not tabs.strength2.timerStarted then
        return
    end

    tabs.strength2.calculationElapsed = tick() - tabs.strength2.lastCalculationAt
    if tabs.strength2.calculationElapsed < tabs.strength2.calculationInterval then
        return
    end

    tabs.strength2.strengthDelta = tabs.strength2.strength.Value - tabs.strength2.lastCalculatedStrength
    tabs.strength2.durabilityDelta = tabs.strength2.durability.Value - tabs.strength2.lastCalculatedDurability
    tabs.strength2.strengthHourlyPace = tabs.strength2.strengthDelta / tabs.strength2.calculationElapsed * 3600
    tabs.strength2.durabilityHourlyPace = tabs.strength2.durabilityDelta / tabs.strength2.calculationElapsed * 3600

    if tabs.strength2.strengthDelta > 0 then
        tabs.strength2.StrengthPace.Text = "Strength Pace: " .. formatNumber(tabs.strength2.strengthHourlyPace)
            .. " / Hour | " .. formatNumber(tabs.strength2.strengthHourlyPace * 24) .. " / Day"
    end
    if tabs.strength2.durabilityDelta > 0 then
        tabs.strength2.DurabilityPace.Text = "Durability Pace: " .. formatNumber(tabs.strength2.durabilityHourlyPace)
            .. " / Hour | " .. formatNumber(tabs.strength2.durabilityHourlyPace * 24) .. " / Day"
    end

    tabs.strength2.averageElapsed = tabs.strength2.totalElapsed + tick() - tabs.strength2.startedAt
    if tabs.strength2.averageElapsed > 0 then
        tabs.strength2.averageStrengthHourly = (tabs.strength2.strength.Value - tabs.strength2.startStrength)
            / tabs.strength2.averageElapsed * 3600
        tabs.strength2.averageDurabilityHourly = (tabs.strength2.durability.Value - tabs.strength2.startDurability)
            / tabs.strength2.averageElapsed * 3600
        tabs.strength2.StrengthAverage.Text = "Strength Average: " .. formatNumber(tabs.strength2.averageStrengthHourly)
            .. " / Hour | " .. formatNumber(tabs.strength2.averageStrengthHourly * 24) .. " / Day"
        tabs.strength2.DurabilityAverage.Text = "Durability Average: " .. formatNumber(tabs.strength2.averageDurabilityHourly)
            .. " / Hour | " .. formatNumber(tabs.strength2.averageDurabilityHourly * 24) .. " / Day"
    end

    tabs.strength2.lastCalculationAt = tick()
    tabs.strength2.lastCalculatedStrength = tabs.strength2.strength.Value
    tabs.strength2.lastCalculatedDurability = tabs.strength2.durability.Value
end

tabs.strength2.networkStats = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]

tabs.strength2.getCurrentPing = function()
    return tabs.strength2.networkStats:GetValue()
end

tabs.strength2.getAdaptiveSpeed = function(ping)
    if ping < 80 then
        return 500
    elseif ping < 150 then
        return 300
    elseif ping < 250 then
        return 100
    end
    return 50
end

tabs.strength2.workerLoop = function()
    tabs.strength2.lastPingUpdate = time()
    tabs.strength2.currentPing = tabs.strength2.getCurrentPing()

    while tabs.strength2.running do
        if time() - tabs.strength2.lastPingUpdate > 0.5 then
            tabs.strength2.currentPing = tabs.strength2.getCurrentPing()
            tabs.strength2.lastPingUpdate = time()
        end

        tabs.strength2.repsToFire = tabs.strength2.pingControl
            and tabs.strength2.getAdaptiveSpeed(tabs.strength2.currentPing)
            or tabs.strength2.repSpeed
        tabs.strength2.repsToFire = math.min(tabs.strength2.repsToFire, tabs.strength2.repSpeed)
        tabs.strength2.delayBetweenBatches = math.clamp(tabs.strength2.currentPing / 2500, 0.001, 0.1)

        tabs.strength2.Status.Text = "Status: Farming | " .. formatNumber(tabs.strength2.repsToFire)
            .. " reps/batch | " .. formatNumber(tabs.strength2.currentPing) .. " ms"
        tabs.strength2.Status.TextColor3 = Color3.fromRGB(80, 255, 120)

        for repCount = 1, tabs.strength2.repsToFire do
            if not tabs.strength2.running then
                break
            end
            services.muscleEvent:FireServer("rep")
            if repCount % 500 == 0 then
                task.wait()
            end
        end
        task.wait(tabs.strength2.delayBetweenBatches)
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
    task.spawn(tabs.strength2.workerLoop)
end

tabs.strength2.strength:GetPropertyChangedSignal("Value"):Connect(function()
    tabs.strength2.updateStats()
    tabs.strength2.updatePace()
end)

tabs.strength2.durability:GetPropertyChangedSignal("Value"):Connect(function()
    tabs.strength2.updateStats()
    tabs.strength2.updatePace()
end)

tabs.strength2:AddTextBox("Rep Speed:", function(inputText)
    tabs.strength2.speedValue = tonumber(inputText)
    if tabs.strength2.speedValue then
        tabs.strength2.repSpeed = math.clamp(math.floor(tabs.strength2.speedValue), 1, 1000)
    end
end)

tabs.strength2:AddSwitch("Controlled Speed", function(state)
    tabs.strength2.pingControl = state
end):Set(true)

tabs.strength2.FastRepToggle = tabs.strength2:AddSwitch("Fast Rep", function(state)
    tabs.strength2.running = state
    if state then
        if not tabs.strength2.gainedBaselineSet then
            tabs.strength2.startStrength = tabs.strength2.strength.Value
            tabs.strength2.startDurability = tabs.strength2.durability.Value
            tabs.strength2.gainedBaselineSet = true
        end
        tabs.strength2.timerStarted = false
        tabs.strength2.startedAt = 0
        tabs.strength2.lastCalculationAt = tick()
        tabs.strength2.lastCalculatedStrength = tabs.strength2.strength.Value
        tabs.strength2.lastCalculatedDurability = tabs.strength2.durability.Value
        tabs.strength2.Status.Text = "Status: Starting..."
        tabs.strength2.Status.TextColor3 = Color3.fromRGB(80, 255, 120)
        tabs.strength2.startWorker()
    else
        if tabs.strength2.timerStarted and tabs.strength2.startedAt > 0 then
            tabs.strength2.totalElapsed = tabs.strength2.totalElapsed + tick() - tabs.strength2.startedAt
            tabs.strength2.startedAt = 0
            tabs.strength2.timerStarted = false
        end
        tabs.strength2.Status.Text = tabs.strength2.gainedBaselineSet and "Status: Paused" or "Status: Inactive"
        tabs.strength2.Status.TextColor3 = tabs.strength2.gainedBaselineSet
            and Color3.fromRGB(255, 180, 70)
            or Color3.fromRGB(255, 80, 80)
        tabs.strength2.updateRuntime()
    end
end)

tabs.strength2.FastRepToggle:Set(false)

task.spawn(function()
    while true do
        tabs.strength2.updateRuntime()
        tabs.strength2.calculatePace()
        task.wait(1)
    end
end)

tabs.strength2:AddLabel("For me, 20-40 works the best. Try around!")
tabs.strength2:AddLabel("Reaching Average Speed takes some time!")

-- Other Tab

function unequipPets()
    for _, folder in pairs(lp.player.petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in pairs(folder:GetChildren()) do
                services.replicatedstorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
            end
        end
    end
    task.wait(0.1)
end

function equipPetsByName(name)
    unequipPets()
    task.wait(0.01)
    for _, pet in pairs(lp.player.petsFolder.Unique:GetChildren()) do
        if pet.Name == name then
            services.replicatedstorage.rEvents.equipPetEvent:FireServer("equipPet", pet)
        end
    end
end

tabs.other.eggsowned = tabs.other:AddLabel("Protein Eggs: 0")
tabs.other.eggsowned.TextSize = 14

tabs.other.autoEgg = false
tabs.other.autoShake = false
tabs.other.autoSpinWheel = false
tabs.other.eggUsedThisCycle = false
tabs.other.hidePopups = true
tabs.other.popupSwitchInitializing = true
tabs.other.hidePets = false
tabs.other.savePlayerSizeEvent = services.replicatedstorage.rEvents:WaitForChild("savePlayerSizeEvent")
tabs.other.showPetsEvent = services.replicatedstorage.rEvents:WaitForChild("showPetsEvent")


task.spawn(function()
    while true do
        tabs.other.proteinEggCount = 0
        tabs.other.backpack = lp.player:FindFirstChild("Backpack")
        if tabs.other.backpack then
            for _, item in ipairs(tabs.other.backpack:GetChildren()) do
                if item.Name == "Protein Egg" then
                    tabs.other.proteinEggCount = tabs.other.proteinEggCount + 1
                end
            end
        end
        tabs.other.eggsowned.Text = "Protein Eggs: " .. tabs.other.proteinEggCount
        task.wait(1)
    end
end)

tabs.other.x2str = tabs.other:AddLabel("x2 Strength: 00:00")
tabs.other.x2str.TextSize = 14

function formatTime(seconds)
    return string.format("%dd %dh %dm %ds", math.floor(seconds / 86400), math.floor((seconds % 86400) / 3600), math.floor((seconds % 3600) / 60), seconds % 60)
end

task.spawn(function()
    while true do
        tabs.other.boostTimersFolder = lp.player:FindFirstChild("boostTimersFolder")
        tabs.other.boost = tabs.other.boostTimersFolder and tabs.other.boostTimersFolder:FindFirstChild("Protein Egg")
        tabs.other.seconds = (tabs.other.boost and tabs.other.boost:IsA("IntValue")) and tabs.other.boost.Value or 0
        tabs.other.x2str.Text = "x2 Strength: " .. formatTime(tabs.other.seconds)
        task.wait(0.5)
    end
end)

function eatEgg()
    tabs.other.character = lp.player.Character
    tabs.other.backpack = lp.player:FindFirstChild("Backpack")
    tabs.other.tool = (tabs.other.character and tabs.other.character:FindFirstChild("Protein Egg")) or (tabs.other.backpack and tabs.other.backpack:FindFirstChild("Protein Egg"))
    if tabs.other.tool then
        services.muscleEvent:FireServer("proteinEgg", tabs.other.tool)
    end
end

task.spawn(function()
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
        services.muscleEvent:FireServer("tropicalShake", tabs.other.tool)
    end
end

task.spawn(function()
    while true do
        if tabs.other.autoShake then
            eatShake()
            task.wait(150)
        else
            task.wait(1)
        end
    end
end)

tabs.other:AddSwitch("Auto Shake (just to eat them)", function(state)
    tabs.other.autoShake = state
    if state then
        eatShake()
    end
end)

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
        task.spawn(function()
            tabs.other.rspin = game:GetService("ReplicatedStorage").rEvents.openFortuneWheelRemote
            tabs.other.chances = game:GetService("ReplicatedStorage").shared.catalogs.fortuneWheelChances["Fortune Wheel"]
            
            while _G.AutoSpinWheel do
                tabs.other.rspin:InvokeServer("openFortuneWheel", tabs.other.chances)
                task.wait(1)
            end
        end)
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

task.spawn(function()
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

tabs.other:AddSwitch("Hide Pets", function(state)
    tabs.other.hidePets = state
    tabs.other.showPetsEvent:FireServer(state and "hidePets" or "showPets")
end):Set(true)

tabs.other.HidePopupsSwitch = tabs.other:AddSwitch("Hide Popups", function(state)
    tabs.other.hidePopups = state
    if not tabs.other.popupSwitchInitializing then
        tabs.other.savePlayerSizeEvent:FireServer("showPopupsOption")
    end
end)
tabs.other.HidePopupsSwitch:Set(true)
tabs.other.popupSwitchInitializing = false



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

tabs.other:AddButton("Industrial Lift",function()
    tabs.other.tpE(Vector3.new(-5491.68945, 81.2379913, 4643.85791))
end)

tabs.other:AddButton("Industrial Squat",function()
    tabs.other.tpE(Vector3.new(-5217.25049, 89.8445511, 5416.01025))
end)


tabs.other:AddButton("Anti Lag (for bad devices)", function()
    tabs.other.playerGui = lp.player:WaitForChild("PlayerGui")

    for _, gui in pairs(tabs.other.playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
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

        task.spawn(function()
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

tabs.other:AddButton("Equip Rep Pets", function()
    for _, folder in pairs(lp.player.petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in pairs(folder:GetChildren()) do
                services.replicatedstorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
            end
        end
    end
    task.wait(0.2)

    tabs.other.omegas = {}
    tabs.other.swifts = {}
    tabs.other.hounds = {}

    for _, pet in pairs(lp.player.petsFolder.Unique:GetChildren()) do
        if pet.Name == "Omega Overlord" then table.insert(tabs.other.omegas, pet)
        elseif pet.Name == "Swift Samurai" then table.insert(tabs.other.swifts, pet)
        elseif pet.Name == "Powercore Hound" then table.insert(tabs.other.hounds, pet)
        end
    end

    tabs.other.equippedCount = 0
    tabs.other.currentPercent = 0
    tabs.other.maxSlots = 9

    for i = #tabs.other.omegas, 1, -1 do
        if tabs.other.equippedCount < tabs.other.maxSlots and tabs.other.currentPercent < 100 then
            tabs.other.pet = table.remove(tabs.other.omegas, i)
            services.replicatedstorage.rEvents.equipPetEvent:FireServer("equipPet", tabs.other.pet)
            tabs.other.currentPercent = tabs.other.currentPercent + 20
            tabs.other.equippedCount = tabs.other.equippedCount + 1
            task.wait(0.1)
        end
    end

    for i = #tabs.other.swifts, 1, -1 do
        if tabs.other.equippedCount < tabs.other.maxSlots and tabs.other.currentPercent < 100 then
            tabs.other.pet = table.remove(tabs.other.swifts, i)
            services.replicatedstorage.rEvents.equipPetEvent:FireServer("equipPet", tabs.other.pet)
            tabs.other.currentPercent = tabs.other.currentPercent + 15
            tabs.other.equippedCount = tabs.other.equippedCount + 1
            task.wait(0.1)
        end
    end

    if tabs.other.currentPercent >= 100 then
        for i = #tabs.other.hounds, 1, -1 do
            if tabs.other.equippedCount < tabs.other.maxSlots then
                tabs.other.pet = table.remove(tabs.other.hounds, i)
                services.replicatedstorage.rEvents.equipPetEvent:FireServer("equipPet", tabs.other.pet)
                tabs.other.equippedCount = tabs.other.equippedCount + 1
                task.wait(0.1)
            end
        end
    end

    for i = #tabs.other.omegas, 1, -1 do
        if tabs.other.equippedCount < tabs.other.maxSlots then
            tabs.other.pet = table.remove(tabs.other.omegas, i)
            services.replicatedstorage.rEvents.equipPetEvent:FireServer("equipPet", tabs.other.pet)
            tabs.other.equippedCount = tabs.other.equippedCount + 1
            task.wait(0.1)
        end
    end

    for i = #tabs.other.swifts, 1, -1 do
        if tabs.other.equippedCount < tabs.other.maxSlots then
            tabs.other.pet = table.remove(tabs.other.swifts, i)
            services.replicatedstorage.rEvents.equipPetEvent:FireServer("equipPet", tabs.other.pet)
            tabs.other.equippedCount = tabs.other.equippedCount + 1
            task.wait(0.1)
        end
    end
end)

tabs.info:Show()
tabs.info:AddLabel("Made with ♥️ by Henne and Muki").TextSize = 17
tabs.info:AddLabel("Any issue? Ping @xyzhenrik_ or @mukimagdich on Discord").TextSize = 17
tabs.info:AddLabel("Official Discord: discord.gg/9eFf93Kg8D").TextSize = 17
tabs.info:AddButton("Copy Invite", function()
    tabs.info.link = "https://discord.gg/9eFf93Kg8D"
    if setclipboard then
        setclipboard(tabs.info.link)
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

tabs.info:AddLabel("")
tabs.info.wLabel = tabs.info:AddLabel("Farming [V4.1.1]")
tabs.info.wLabel.TextSize = 20
tabs.info.wLabel.Font = Enum.Font.Arcade
