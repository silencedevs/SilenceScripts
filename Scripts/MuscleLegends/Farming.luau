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

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/silencedevs/SilenceScripts/refs/heads/main/libraries/eleriumv2.luau?cache=" .. tostring(os.time()), true))()
local runtime = library.Runtime

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

library:EnableAntiAFK()

local silence = library:AddWindow("Silence | Fast Farming - " .. greeting(), {
    main_color = Color3.fromRGB(138, 0, 0),
    min_size = Vector2.new(500, 560),
    can_resize = false
})

runtime:Spawn(function()
    while true do
        task.wait(60)
        silence:SetTitle("Silence | Fast Farming - " .. greeting())
    end
end)

local tabs = {
    rebirths = silence:AddTab("Rebirths"),
    strength = silence:AddTab("Strength"),
    boss = silence:AddTab("Boss"),
    other = silence:AddTab("Other"),
    info = silence:AddTab("Info")
}

tabs.other:Show()

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

tabs.other.applyNameVisibility = function()
    pcall(function()
        workspace.HenneZocktTV.Head.nameGui.Enabled = not tabs.other.RedactConfig.RedactName
    end)
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

function formatPace(ratePerSecond)
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
    local wanted, equipped = {}, {}
    for _, pet in ipairs(selected) do wanted[pet] = true end
    local equippedFolder = lp.player:FindFirstChild("equippedPets")
    if equippedFolder then
        for _, value in ipairs(equippedFolder:GetChildren()) do
            if value:IsA("ObjectValue") and value.Value then equipped[value.Value] = true end
        end
    else
        for _, folder in ipairs(lp.player.petsFolder:GetChildren()) do
            if folder:IsA("Folder") then
                for _, pet in ipairs(folder:GetChildren()) do equipped[pet] = true end
            end
        end
    end
    local removed = false
    for pet in pairs(equipped) do
        if isCurrent and not isCurrent() then return end
        if not wanted[pet] or not equippedFolder then
            services.replicatedstorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
            equipped[pet] = nil
            removed = true
        end
    end
    if removed then task.wait(0.1) end
    for _, pet in ipairs(selected) do
        if isCurrent and not isCurrent() then return end
        if not equipped[pet] then
            services.replicatedstorage.rEvents.equipPetEvent:FireServer("equipPet", pet)
        end
    end
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

local function updateRuntimeLabel(tab)
    local elapsed = tab.totalElapsed
    if tab.running and tab.timerStarted then elapsed = elapsed + tick() - tab.startedAt end
    tab.Runtime.Text = string.format("Runtime: %dd %dh %dm %ds",
        math.floor(elapsed / 86400), math.floor(elapsed % 86400 / 3600),
        math.floor(elapsed % 3600 / 60), math.floor(elapsed % 60))
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
tabs.rebirths.totalElapsed = 0
tabs.rebirths.startRebirths = tabs.rebirths.rebirths.Value
tabs.rebirths.gainedBaselineSet = false
tabs.rebirths.lastRebirthAt = tick()
tabs.rebirths.lastRebirthValue = tabs.rebirths.rebirths.Value
tabs.rebirths.paceBaselineReady = false
tabs.rebirths.generation = 0
tabs.rebirths.adaptive = {
    TargetSeconds = 3,
    MaxRate = 50,
    SendRate = 50,
    StrengthPerRep = nil,
    LastTrainingSeconds = nil
}
tabs.rebirths.Status = tabs.rebirths:AddLabel("Status: Inactive")
tabs.rebirths.Runtime = tabs.rebirths:AddLabel("Runtime: 0d 0h 0m 0s")
tabs.rebirths.RebirthStats = tabs.rebirths:AddLabel("Rebirths: " .. formatCurrentStat(tabs.rebirths.rebirths.Value) .. " | Gained: 0")
tabs.rebirths.Pace = tabs.rebirths:AddLabel("Pace: -- / Hour | -- / Day | -- / Week")
tabs.rebirths.AveragePace = tabs.rebirths:AddLabel("Average: -- / Hour | -- / Day | -- / Week")
tabs.rebirths.Status.TextColor3 = Color3.fromRGB(255, 80, 80)

tabs.rebirths.updateStats = function()
    tabs.rebirths.RebirthStats.Text = "Rebirths: " .. formatCurrentStat(tabs.rebirths.rebirths.Value)
        .. " | Gained: " .. formatNumber(tabs.rebirths.rebirths.Value - tabs.rebirths.startRebirths)
end

tabs.rebirths.updateRuntime = function()
    updateRuntimeLabel(tabs.rebirths)
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

tabs.rebirths.isCurrent = function(generation)
    return tabs.rebirths.running and tabs.rebirths.generation == generation
end

tabs.rebirths.equipFarmingPets = function(generation)
    equipBestFarmingPets(function() return tabs.rebirths.isCurrent(generation) end)
end

tabs.rebirths.equipRebirthPets = function(generation)
    equipBestRebirthPets(function() return tabs.rebirths.isCurrent(generation) end)
end

tabs.rebirths.updateAdaptiveSpeed = function(cycle)
    local adaptive = tabs.rebirths.adaptive
    local now = os.clock()
    if now - cycle.SampleAt < 0.25 then return end
    local gain = tabs.rebirths.strength.Value - cycle.StartStrength
    if gain > 0 and cycle.Sent > 0 then

        adaptive.StrengthPerRep = gain / cycle.Sent
        local remaining = math.max(0, cycle.Target - tabs.rebirths.strength.Value)
        local seconds = math.max(0.1, adaptive.TargetSeconds - cycle.TrainingSeconds)
        adaptive.SendRate = math.clamp(remaining / adaptive.StrengthPerRep / seconds, 1, adaptive.MaxRate)
    elseif cycle.TrainingSeconds >= adaptive.TargetSeconds then
        adaptive.SendRate = adaptive.MaxRate
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
        Sent = 0,
        Tokens = 0,
        LastAt = os.clock(),
        StatusAt = -math.huge,
        TrainingSeconds = 0
    }
    adaptive.SendRate = adaptive.StrengthPerRep and math.clamp(
        math.max(0, cycle.Target - cycle.StartStrength) / adaptive.StrengthPerRep / adaptive.TargetSeconds,
        1, adaptive.MaxRate) or adaptive.MaxRate
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
            cycle.Sent = cycle.Sent + sendTrainingReps(cycle, adaptive.SendRate, 5, needsTraining)
            if now - cycle.StatusAt >= 0.25 then
                tabs.rebirths.Status.Text = "Status: Strength Training | " .. string.format("%.1fs", cycle.TrainingSeconds)
                    .. " | " .. formatNumber(adaptive.SendRate) .. " reps/s"
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
    adaptive.LastTrainingSeconds = cycle.TrainingSeconds
    tabs.rebirths.Status.Text = "Status: Switching to Rebirth Pets"
    tabs.rebirths.equipRebirthPets(generation)
    task.wait(0.25)
    while tabs.rebirths.isCurrent(generation) and tabs.rebirths.rebirths.Value == cycle.Rebirths do
        services.replicatedstorage.rEvents.rebirthRemote:InvokeServer("rebirthRequest")
        task.wait(0.25)
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

runtime:Connect(tabs.rebirths.rebirths:GetPropertyChangedSignal("Value"), function()
    tabs.rebirths.updatePace()
    tabs.rebirths.updateStats()
end)

tabs.rebirths.Switch = tabs.rebirths:AddSwitch("Pack Rebirth (Yes, Robux Packs)", function(state)
    tabs.rebirths.generation = tabs.rebirths.generation + 1
    tabs.rebirths.running = state
    if state then
        if tabs.strength.running then tabs.strength.FastRepToggle:Set(false) end
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
end)
tabs.rebirths.Switch:Set(false)

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
tabs.strength.calculationInterval = 10
tabs.strength.lastCalculationAt = tick()
tabs.strength.lastCalculatedStrength = tabs.strength.strength.Value
tabs.strength.lastCalculatedDurability = tabs.strength.durability.Value
tabs.strength.initialSendRate = 200
tabs.strength.maxSendRate = 656
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
tabs.strength.DurabilityStats = tabs.strength:AddLabel("Durability: " .. formatCurrentStat(tabs.strength.durability.Value) .. " | Gained: 0")
tabs.strength.StrengthPace = tabs.strength:AddLabel("Str Pace: --/s | --/min | --/h | --/d")
tabs.strength.DurabilityPace = tabs.strength:AddLabel("Dura Pace: --/s | --/min | --/h | --/d")
tabs.strength.StrengthAverage = tabs.strength:AddLabel("Str Ø: --/s | --/min | --/h | --/d")
tabs.strength.DurabilityAverage = tabs.strength:AddLabel("Dura Ø: --/s | --/min | --/h | --/d")
tabs.strength.Status.TextColor3 = Color3.fromRGB(255, 80, 80)

tabs.strength.updateRuntime = function()
    updateRuntimeLabel(tabs.strength)
end

tabs.strength.updateStats = function()
    tabs.strength.StrengthStats.Text = "Strength: " .. formatCurrentStat(tabs.strength.strength.Value)
        .. " | Gained: " .. formatNumber(tabs.strength.strength.Value - tabs.strength.startStrength)
    tabs.strength.DurabilityStats.Text = "Durability: " .. formatCurrentStat(tabs.strength.durability.Value)
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
    tabs.strength.strengthPacePerSecond = tabs.strength.strengthDelta / tabs.strength.calculationElapsed
    tabs.strength.durabilityPacePerSecond = tabs.strength.durabilityDelta / tabs.strength.calculationElapsed

    if tabs.strength.strengthDelta > 0 then
        tabs.strength.StrengthPace.Text = "Str Pace: " .. formatPace(tabs.strength.strengthPacePerSecond)
    end
    if tabs.strength.durabilityDelta > 0 then
        tabs.strength.DurabilityPace.Text = "Dura Pace: " .. formatPace(tabs.strength.durabilityPacePerSecond)
    end

    tabs.strength.averageElapsed = tabs.strength.totalElapsed + tick() - tabs.strength.startedAt
    tabs.strength.averageStrengthPerSecond = (tabs.strength.strength.Value - tabs.strength.startStrength)
        / tabs.strength.averageElapsed
    tabs.strength.averageDurabilityPerSecond = (tabs.strength.durability.Value - tabs.strength.startDurability)
        / tabs.strength.averageElapsed
    tabs.strength.StrengthAverage.Text = "Str Ø: " .. formatPace(tabs.strength.averageStrengthPerSecond)
    tabs.strength.DurabilityAverage.Text = "Dura Ø: " .. formatPace(tabs.strength.averageDurabilityPerSecond)

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
        tabs.strength.sendRate = math.min(tabs.strength.maxSendRate, tabs.strength.sendRate * 1.12)
        tabs.strength.Status.Text = "Status: Farming | "
            .. formatNumber(tabs.strength.sendRate) .. " reps/s"
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
    tabs.strength.statsDirty = true
    tabs.strength.updatePace()
end)

runtime:Connect(tabs.strength.durability:GetPropertyChangedSignal("Value"), function()
    tabs.strength.statsDirty = true
    tabs.strength.updatePace()
end)

tabs.strength:AddTextBox("Max reps/s: " .. tabs.strength.maxSendRate, function(inputText, value)
    value = tonumber(inputText)
    if not value or value ~= value or value == math.huge or value == -math.huge then return end
    tabs.strength.maxSendRate = math.max(1, value)
    tabs.strength.sendRate = math.min(tabs.strength.sendRate, tabs.strength.maxSendRate)
end, {clear = false})

tabs.strength:AddLabel("Recommended Speed: 656, more = lag")

tabs.strength.FastRepToggle = tabs.strength:AddSwitch("Fast Rep", function(state)
    tabs.strength.running = state
    tabs.strength.Tokens = 0
    if state then
        if tabs.rebirths.running then tabs.rebirths.Switch:Set(false) end
        if not tabs.strength.gainedBaselineSet then
            tabs.strength.startStrength = tabs.strength.strength.Value
            tabs.strength.startDurability = tabs.strength.durability.Value
            tabs.strength.gainedBaselineSet = true
        end
        tabs.strength.timerStarted = false
        tabs.strength.startedAt = 0
        tabs.strength.sendRate = math.min(tabs.strength.initialSendRate, tabs.strength.maxSendRate)
        tabs.strength.LastAt = os.clock()
        tabs.strength.lastControlAt = tick()
        tabs.strength.lastControlStrength = tabs.strength.strength.Value
        tabs.strength.lastControlDurability = tabs.strength.durability.Value
        tabs.strength.stalledIntervals = 0
        tabs.strength.Status.Text = "Status: Farming | " .. formatNumber(tabs.strength.sendRate) .. " reps/s"
        tabs.strength.Status.TextColor3 = Color3.fromRGB(80, 255, 120)
        tabs.strength.startWorker()
    else
        if tabs.strength.timerStarted and tabs.strength.startedAt > 0 then
            tabs.strength.totalElapsed = tabs.strength.totalElapsed + tick() - tabs.strength.startedAt
            tabs.strength.startedAt = 0
            tabs.strength.timerStarted = false
        end
        tabs.strength.Status.Text = tabs.strength.gainedBaselineSet and "Status: Paused" or "Status: Inactive"
        tabs.strength.Status.TextColor3 = tabs.strength.gainedBaselineSet and Color3.fromRGB(255, 180, 70) or Color3.fromRGB(255, 80, 80)
        tabs.strength.updateRuntime()
    end
end)

tabs.strength.FastRepToggle:Set(false)

runtime:Spawn(function()
    local lastRuntimeAt = 0
    while true do
        if tabs.strength.statsDirty then
            tabs.strength.statsDirty = false
            tabs.strength.updateStats()
        end
        if os.clock() - lastRuntimeAt >= 1 then
            tabs.rebirths.updateRuntime()
            tabs.strength.updateRuntime()
            tabs.strength.calculatePace()
            lastRuntimeAt = os.clock()
        end
        task.wait(0.25)
    end
end)

tabs.strength:AddLabel("Reaching Average Speed takes some time!")

tabs.boss.runtime = {}

tabs.boss:AddLabel("Boss Farming:")
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
	if tabs.rebirths.workerActive or tabs.strength.workerActive then
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

tabs.boss:AddLabel("Halloween Boss Farming:")
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

tabs.other.eggsowned = tabs.other:AddLabel("Protein Eggs: 0")
tabs.other.eggsowned.TextSize = 14

tabs.other.autoEgg = false
tabs.other.autoShake = false
tabs.other.autoSpinWheel = false
tabs.other.eggUsedThisCycle = false

runtime:Spawn(function()
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

runtime:Spawn(function()
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
        services.muscleEvent:FireServer("tropicalShake", tabs.other.tool)
    end
end

runtime:Spawn(function()
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
end)
tabs.other.RedactStatsSwitch:Set(tabs.other.RedactConfig.RedactStats)

runtime:Connect(lp.player.CharacterAdded, function(character, head)
    runtime:Defer(tabs.other.applyStatsVisibility)
    if character.Name ~= "HenneZocktTV" then return end
    head = character:WaitForChild("Head", 10)
    if head and head:WaitForChild("nameGui", 10) and lp.player.Character == character then
        tabs.other.applyNameVisibility()
    end
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

tabs.other:AddButton("Industrial Lift",function()
    tabs.other.tpE(Vector3.new(-5491.68945, 81.2379913, 4643.85791))
end)

tabs.other:AddButton("Industrial Squat",function()
    tabs.other.tpE(Vector3.new(-5217.25049, 89.8445511, 5416.01025))
end)

tabs.other:AddButton("Halloween Lift",function()
    tabs.other.tpE(Vector3.new(5760.389, 83.206, 6117.898))
end)

tabs.other:AddButton("Halloween Squat",function()
    tabs.other.tpE(Vector3.new(4803.357, 83.791, 5827.032))
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

tabs.other:AddButton("Equip Rep Pets", function()
    equipBestFarmingPets()
end)

tabs.info:Show()
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
tabs.info:AddLabel("Contributors:").TextSize = 17
tabs.info:AddLabel("- Henrik @xyzhenrik")
tabs.info:AddLabel("- Muki @mukimagdich")
tabs.info:AddLabel("")
tabs.info:AddLabel("Silence is Open-Source!")
tabs.info:AddLabel("")
tabs.info.VersionLabel = tabs.info:AddLabel("Muscle Legends [V4.2.0]")
tabs.info.VersionLabel.TextSize = 20
tabs.info.VersionLabel.Font = Enum.Font.Arcade
