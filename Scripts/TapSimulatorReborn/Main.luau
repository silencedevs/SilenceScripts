assert(game.PlaceId == 72858262610964, "Open Tap Simulator REBORN before running Silence")

local services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = workspace,
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    VirtualUser = game:GetService("VirtualUser"),
    HttpService = game:GetService("HttpService"),
    CollectionService = game:GetService("CollectionService"),
    Lighting = game:GetService("Lighting")
}

if _G.SilenceTapRebornRuntime then _G.SilenceTapRebornRuntime:Destroy() end
local runtime = {Alive = true, Threads = {}, Connections = {}, Cleanups = {}}
_G.SilenceTapRebornRuntime = runtime

function runtime:Spawn(callback)
    if not self.Alive then return end
    local thread
    thread = coroutine.create(function()
        local success, result = pcall(callback)
        self.Threads[thread] = nil
        if not success then warn("[Silence Reborn] " .. tostring(result)) end
    end)
    self.Threads[thread] = true
    task.spawn(thread)
    return thread
end

function runtime:Connect(signal, callback)
    local connection = signal:Connect(function(...) if self.Alive then callback(...) end end)
    table.insert(self.Connections, connection)
    return connection
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
    if _G.SilenceTapRebornRuntime == self then _G.SilenceTapRebornRuntime = nil end
end

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/silencedevs/SilenceScripts/refs/heads/main/libraries/windui/windui.luau"))()
local silence = WindUI:CreateWindow({
    Title = "Silence - Tap Simulator Reborn",
    Author = "by Henrik @xyzhenrik",
    Icon = "solar:moon-bold",
    IconSize = 26,
    Theme = "Crimson",
    NewElements = true,
    TopBarButtonIconSize = (services.UserInputService.KeyboardEnabled and services.UserInputService.MouseEnabled) and 24 or 16,
    Size = UDim2.fromOffset(500, 500),
    Folder = "Silence/TapSimulatorReborn/" .. tostring(services.Players.LocalPlayer.UserId),
    OpenButton = {
        Title = "Reopen Silence",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 3,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = (services.UserInputService.KeyboardEnabled and services.UserInputService.MouseEnabled) and 1.25 or 0.5,
        Color = ColorSequence.new(Color3.fromHex("880000"), Color3.fromHex("000000"))
    },
    Topbar = {Height = (services.UserInputService.KeyboardEnabled and services.UserInputService.MouseEnabled) and 56 or 44, ButtonsType = "Default"}
})
silence:OnDestroy(function() runtime:Destroy() end)
runtime:AddCleanup(function() if not silence.Destroyed then silence:Destroy() end end)

local utils = {
    player = services.Players.LocalPlayer,
    identity = type(getthreadidentity) == "function" and getthreadidentity() or 8,
    modules = {},
    jobs = {},
    controls = {},
    status = {},
    next = {},
    travel = {Owner = nil, Origin = nil},
    hatch = {Sequence = 0, Pending = {}, Count = 0, Errors = 0, NextAt = 0},
    arena = {Active = false, Opponents = {}, Wave = 0},
    memory = {Id = nil, Known = {}},
    log = {Queue = {}, Next = 0, Dropped = 0},
    originals = {},
    clickVisuals = {Enabled = false, Hooks = {}, Saved = {}},
    hatchVisuals = {Enabled = false, Hooks = {}},
    performance = {Enabled = false, Saved = setmetatable({}, {__mode = "k"})},
    started = os.clock(),
    settings = {
        farm = {Rebirth = "Maximum", Egg = "Basic", HatchCount = 3, Reserve = 0},
        pets = {Team = "Clicks", Names = {}, Rarities = {}, Tiers = {}, CraftMode = "Ready", GoldenCount = 6, DiamondCount = 5, RainbowCount = 5, GoldenPets = {["All Pets"] = true}, DiamondPets = {["All Pets"] = true}, RainbowPets = {["All Pets"] = true}},
        enchant = {Traits = {}, Pets = {["Equipped Pets"] = true}, PetIds = {}, UseEquipped = true, Reserve = 25},
        boosts = {Types = {Luck = true}, Brew = "Luck Potion I", Bundle = "1", Reserve = 0, Shrine = "Luck", Relic = "Automatic"},
        webhook = {URL = "", UserId = "", ShowUser = false, Rarities = {Legendary = true, Mythical = true, ["Secret I"] = true, ["Secret II"] = true, ["Secret III"] = true, ["Secret X"] = true}},
        character = {Speed = 24, Jump = 50}
    }
}
local tabs = {
    config = silence:Tab({Title = "Configuration", Icon = "lucide:settings", Border = true}),
    main = silence:Tab({Title = "Main", Icon = "lucide:house", Border = true}),
    hatching = silence:Tab({Title = "Hatching", Icon = "lucide:egg", Border = true}),
    pets = silence:Tab({Title = "Pets", Icon = "lucide:paw-print", Border = true}),
    crafting = silence:Tab({Title = "Pet Crafting", Icon = "lucide:gem", Border = true}),
    enchanting = silence:Tab({Title = "Enchanting", Icon = "lucide:sparkles", Border = true}),
    teleport = silence:Tab({Title = "Teleports", Icon = "lucide:map", Border = true}),
    misc = silence:Tab({Title = "Misc", Icon = "lucide:layers", Border = true}),
    webhook = silence:Tab({Title = "Webhook", Icon = "lucide:link", Border = true}),
    stats = silence:Tab({Title = "Stats", Icon = "lucide:chart-no-axes-column", Border = true}),
    info = silence:Tab({Title = "About", Icon = "lucide:info", Border = true})
}
tabs.main:Select()

function utils.identityReset()
    if type(setthreadidentity) == "function" then setthreadidentity(utils.identity) end
end

function utils.load(name, path)
    local instance = services.ReplicatedStorage
    for part in path:gmatch("[^.]+") do instance = instance and instance:FindFirstChild(part) end
    assert(instance and instance:IsA("ModuleScript"), "Missing module: " .. path)
    local success, result = pcall(require, instance)
    utils.identityReset()
    assert(success, tostring(result))
    utils.modules[name] = result
    return result
end

utils.load("data", "Controllers.Core.DataController")
utils.load("eggController", "Controllers.Pets.EggController")
utils.load("menu", "Controllers.UI.MenuController")
utils.load("profileStats", "Modules.Client.Game.ProfileStats")
utils.load("format", "Modules.Client.Common.FormatNumber")
utils.load("tapFormula", "Shared.Progression.TapFormula")
utils.load("treatConfig", "Shared.Items.ActiveTreatConfig")
utils.load("launchPets", "Shared.Pets.LaunchPetConfig")
utils.load("eggIdle", "Modules.Client.Pets.EggIdleAnimation")
utils.load("offlineHatch", "Shared.Pets.OfflineHatchConfig")
utils.replica = utils.modules.data:GetReplica()
utils.identityReset()
for name, path in pairs({
    rebirth = "Progression.RebirthConfig", buttons = "Progression.RebirthButtonConfig",
    skills = "Progression.SkillTreeFormula", islands = "Progression.IslandConfig",
    eggs = "Pets.LaunchEggConfig", machines = "Pets.MachineConfig", enchants = "Pets.EnchantConfig",
    levels = "Pets.PetLevelConfig", rarity = "Pets.HatchRulesConfig", catalog = "Pets.OriginalPetCatalog",
    boosts = "Items.BoostConfig", items = "Items.ItemCatalog", brew = "Items.PotionBrewConfig",
    recipes = "Items.PotionCraftConfig", relics = "Progression.RelicConfig", stars = "Game.ShinyStarConfig",
    dig = "Minigames.DigConfig", digWorld = "Minigames.DigWorld", memoryWorld = "Minigames.MemoryMatchWorld"
}) do utils.load(name, "Shared." .. path) end

function utils.save()
    return utils.replica.Data
end

function utils.remote(group, name, ...)
    local folder = services.ReplicatedStorage.RemoteServices:FindFirstChild(group .. "Service")
    local remote = folder and ((folder:FindFirstChild("RF") and folder.RF:FindFirstChild(name)) or (folder:FindFirstChild("RE") and folder.RE:FindFirstChild(name)))
    assert(remote, "Missing remote: " .. group .. "." .. name)
    if remote:IsA("RemoteEvent") then remote:FireServer(...); return end
    local result = remote:InvokeServer(...)
    if type(result) == "table" then
        assert(result.Success ~= false and not result.Error, tostring(result.Error or result.Reason or "Request rejected"))
    end
    return result
end

function utils.message(key, value)
    utils.status[key] = tostring(value or "Idle")
    if utils.controls[key] then utils.controls[key]:SetTitle(key .. ": " .. utils.status[key]) end
end

function utils.label(tab, key)
    utils.controls[key] = tab:Paragraph({Title = key .. ": Off"})
end

function utils.section(tab, text)
    tab:Section({Title = text, TextSize = 22, Box = false, TextXAlignment = "Center"})
end

function utils.job(tab, text, key, interval, callback, cleanup)
    utils.jobs[key] = {Enabled = false, Busy = false, Generation = 0, Callback = callback, Next = 0, Interval = interval, Cleanup = cleanup}
    utils.controls[key .. "Switch"] = tab:Toggle({
        Title = text, Value = false, Flag = "Enabled." .. key,
        Callback = function(enabled)
            local job = utils.jobs[key]
            job.Generation += 1
            job.Enabled, job.Next = enabled, 0
            if not enabled and cleanup then pcall(cleanup) end
            utils.message(key, enabled and "Waiting" or "Off")
        end
    })
end

function utils.action(tab, text, key, callback)
    return tab:Button({Title = text, Callback = function()
        if utils.jobs[key] and utils.jobs[key].Busy then return end
        runtime:Spawn(function()
            local success, result = pcall(callback)
            utils.identityReset()
            utils.message(key, success and (result or "Requested") or result)
            if not success then WindUI:Notify({Title = text, Content = tostring(result), Duration = 4}) end
        end)
    end})
end

function utils.dropdown(tab, text, settings, key, values, flag, mapper)
    return tab:Dropdown({
        Title = text, Values = values, Value = mapper and tostring(settings[key]) or settings[key],
        Multi = false, SearchBarEnabled = #values > 8, Flag = flag,
        Callback = function(value) settings[key] = mapper and mapper(value) or value end
    })
end

function utils.number(tab, text, settings, key, minimum, maximum, flag)
    return tab:Input({Title = text, Value = tostring(settings[key]), Placeholder = text, Flag = flag, Callback = function(value)
        local number = tonumber(value)
        if number and number == number and number >= minimum and number <= maximum then settings[key] = number
        else WindUI:Notify({Title = text, Content = "Enter a number from " .. minimum .. " to " .. maximum, Duration = 3}) end
    end})
end

function utils.multi(tab, text, settings, key, values, flag)
    local selected = {}
    for name, enabled in pairs(settings[key]) do if enabled then table.insert(selected, name) end end
    return tab:Dropdown({Title = text, Values = values, Value = selected, Multi = true, SearchBarEnabled = true, Flag = flag,
        Callback = function(value)
            table.clear(settings[key])
            if type(value) == "table" then for _, name in pairs(value) do if type(name) == "string" and table.find(values, name) then settings[key][name] = true end end end
        end
    })
end

function utils.keys(value)
    local keys = {}
    for key in pairs(value) do table.insert(keys, key) end
    table.sort(keys)
    return keys
end

function utils.formatNumber(number)
    return utils.modules.format:Abbreviate(tonumber(number) or 0, true)
end

function utils.updateStats(data)
    local function update(name, value) tabs.stats.labels[name]:SetTitle(name .. ": " .. value) end
    local rank = utils.player:GetAttribute("PetPowerRank")
    local treatMultiplier = 1
    for name, duration in pairs(data.Items.ActiveTreats or {}) do
        local config = utils.modules.treatConfig[name]
        if duration > 0 and config and config.Type == "PetClicks" then treatMultiplier += config.Multiplier end
    end
    local clickPower = utils.modules.tapFormula.GetAmount(data, 1, utils.clickCombo or 1, utils.player:GetAttribute("TotemClicksBoost") or 1, treatMultiplier)
    local rarest = data.Statistics.RarestHatch
    update("Global Rank", type(rank) == "number" and rank > 0 and ("#" .. utils.modules.format:Commas(rank)) or "Unranked")
    update("Pet Power", utils.formatNumber(utils.modules.profileStats.TotalPetPower(data)))
    update("Click Power", utils.formatNumber(clickPower))
    update("Rarest Hatch", rarest and (tostring(rarest.Tier or "Normal") .. " " .. tostring(rarest.Name) .. " | 1 in " .. utils.formatNumber(rarest.OneIn)) or "None")
    update("Total Coins", utils.formatNumber(data.Statistics.LifetimeCoins))
    update("Rebirth", utils.formatNumber(data.Statistics.Rebirths))
    update("Eggs Hatched", utils.formatNumber(data.Statistics.EggsOpened))
end

function utils.sortedEggs()
    local eggs = {}
    for name, config in pairs(utils.modules.eggs) do
        if name ~= "Test" and type(config.Price) == "number" and config.Price > 0 and not config.Currency then
            table.insert(eggs, {Name = name, Price = config.Price})
        end
    end
    table.sort(eggs, function(a, b) return a.Price == b.Price and a.Name < b.Name or a.Price < b.Price end)
    return eggs
end

function utils.sortedIslands()
    local islands = {}
    for name, config in pairs(utils.modules.islands.Islands) do table.insert(islands, {Name = name, Config = config}) end
    table.sort(islands, function(a, b)
        if a.Config.Order ~= b.Config.Order then return a.Config.Order < b.Config.Order end
        if a.Config.Price ~= b.Config.Price then return a.Config.Price < b.Config.Price end
        return a.Name < b.Name
    end)
    return islands
end

function utils.character()
    local character = utils.player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    assert(root and humanoid and humanoid.Health > 0, "Waiting for character")
    return root, humanoid
end

function utils.position(instance)
    if not instance then return end
    if instance:IsA("BasePart") then return instance.CFrame end
    if instance:IsA("Model") then return instance:GetPivot() end
    local part = instance:FindFirstChildWhichIsA("BasePart", true)
    return part and part.CFrame
end

function utils.closeCraftMenus()
    for _, menu in ipairs({"Golden", "Diamond", "RainbowFuse", "CraftingRoll"}) do
        pcall(utils.modules.menu.Close, utils.modules.menu, menu)
    end
end

function utils.trip(key, target, callback)
    assert(not utils.travel.Owner, "Character busy: " .. tostring(utils.travel.Owner))
    local root = utils.character()
    local destination = typeof(target) == "CFrame" and target or utils.position(target)
    assert(destination, "Location unavailable")
    utils.travel.Owner, utils.travel.Origin = key, root.CFrame
    local success, result = pcall(function()
        root.CFrame = destination + Vector3.new(0, 3, 0)
        root.AssemblyLinearVelocity = Vector3.zero
        task.wait(1.2)
        assert(runtime.Alive and root.Parent and utils.travel.Owner == key, "Travel interrupted")
        return callback()
    end)
    if key == "Golden" or key == "Diamond" or key == "Shiny" then
        utils.closeCraftMenus()
    end
    if root.Parent and utils.travel.Origin then
        root.CFrame = utils.travel.Origin
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        task.wait(0.2)
    end
    utils.travel.Owner, utils.travel.Origin = nil, nil
    if not success then error(result, 0) end
    return result
end

function utils.protected(id, pet, data)
    return pet.Locked or pet.Equip or pet.Enchant or pet.Enchant2 or pet.Reserved or table.find(data.Pets.Equipped, id) ~= nil
end

function utils.count(value)
    local count = 0
    for _ in pairs(value or {}) do count += 1 end
    return count
end

function utils.stop()
    for key, job in pairs(utils.jobs) do
        if utils.controls[key .. "Switch"] then utils.controls[key .. "Switch"]:Set(false) else job.Enabled = false end
    end
end

utils.load("pricing", "Shared.Pets.EggPricing")
utils.load("perks", "Shared.Monetization.GamepassPerks")
utils.load("boostFormula", "Shared.Items.BoostFormula")
utils.load("gameConfig", "Shared.Core.GameConfig")
utils.load("tapController", "Controllers.Game.TapController")
utils.tapCounter = utils.modules.tapController.GetManualTapCount
utils.syncTapCounter = false
if type(debug.getupvalues) == "function" and type(debug.setupvalue) == "function" then
    local success, upvalues = pcall(debug.getupvalues, utils.tapCounter)
    utils.syncTapCounter = success and type(upvalues[1]) == "number" and upvalues[1] == utils.modules.tapController:GetManualTapCount()
end

function utils.tap()
    if utils.syncTapCounter then
        -- Keep manual UI clicks and script taps on the same server sequence.
        local sequence = utils.modules.tapController:GetManualTapCount() + 1
        debug.setupvalue(utils.tapCounter, 1, sequence)
        utils.remote("Tap", "TapRequested", {Auto = false, Source = "button", ClientSequence = sequence})
    else
        utils.modules.tapController:Tap()
        utils.identityReset()
    end
    return "Tapping"
end

function utils.rebirthIndex(data, affordable)
    local maximum = utils.modules.buttons.GetOptionCount(data.Upgrades.RebirthButtons or 0, data.Progression.World)
    local index = utils.settings.farm.Rebirth == "Maximum" and maximum or math.clamp(tonumber(utils.settings.farm.Rebirth) or maximum, 1, maximum)
    if affordable then
        for candidate = maximum, 1, -1 do
            if data.Currencies.Coins >= utils.modules.rebirth.GetPrice(utils.modules.rebirth.GetAmountFromIndex(candidate), data.Statistics.Rebirths, utils.player) then return candidate end
        end
        return nil
    end
    return index
end

function utils.rebirth()
    if utils.travel.Owner then return "Character busy" end
    local data = utils.save()
    local index = utils.rebirthIndex(data, false)
    if not index then return "Waiting for coins" end
    local price = utils.modules.rebirth.GetPrice(utils.modules.rebirth.GetAmountFromIndex(index), data.Statistics.Rebirths, utils.player)
    if data.Currencies.Coins < price then return "Waiting for " .. utils.formatNumber(price) .. " coins" end
    utils.remote("Rebirth", "RebirthRequested", {Index = index})
    return "Requested x" .. utils.formatNumber(utils.modules.rebirth.GetAmountFromIndex(index))
end

function utils.eggAvailable(name, config, data)
    return name ~= "Test" and config.Price and not config.Currency
        and (not config.Island or data.Progression.UnlockedIslands[config.Island])
        and (not config.Zone or config.Zone == "Spawn" or data.Progression.UnlockedZones[config.Zone])
end

function utils.pickEgg(data)
    local selected = utils.settings.farm.Egg
    local config = utils.modules.eggs[selected]
    if config and utils.eggAvailable(selected, config, data) then return selected, config end
end

function utils.eggStandPosition(egg, root, humanoid)
    local pivot = utils.position(egg)
    local front = pivot:PointToWorldSpace(Vector3.new(4.32, 11.79, 3.98))
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {root.Parent, workspace.Eggs}
    params.RespectCanCollide = true
    local floor = workspace:Raycast(front + Vector3.new(0, 12, 0), Vector3.new(0, -60, 0), params)
    if not floor or floor.Normal.Y < 0.6 then return end
    local height = humanoid.HipHeight + root.Size.Y / 2
    if humanoid.RigType == Enum.HumanoidRigType.R6 then
        local leg = root.Parent:FindFirstChild("Left Leg")
        height += leg and leg.Size.Y or 2
    end
    local position = Vector3.new(front.X, floor.Position.Y + height + 0.1, front.Z)
    local facing = Vector3.new(pivot.Position.X, position.Y, pivot.Position.Z)
    return CFrame.lookAt(position, facing)
end

function utils.hatchEgg()
    local job = utils.jobs.Hatch
    local generation = job.Generation
    local function active() return runtime.Alive and job.Enabled and job.Generation == generation end
    if not active() then return "Stopped" end
    if utils.travel.Owner then return "Character busy" end
    local display = utils.modules.eggController:GetForcedHatchDebugState()
    if display.Queue > 0 or display.Worker or display.Busy then return "Hatch animation playing" end
    if os.clock() < utils.hatch.NextAt then return string.format("Hatch cooldown: %.1fs", utils.hatch.NextAt - os.clock()) end
    for sequence, pending in pairs(utils.hatch.Pending) do
        if os.clock() - pending.At > 10 then utils.hatch.Pending[sequence] = nil; utils.hatch.Errors += 1 end
    end
    if utils.count(utils.hatch.Pending) >= 1 then return "Hatch request sent - awaiting server result" end
    local data = utils.save()
    local name, config = utils.pickEgg(data)
    if not name then
        local selected = utils.settings.farm.Egg
        local selectedConfig = utils.modules.eggs[selected]
        if not selectedConfig then return "Select an egg" end
        if selectedConfig.Island and not data.Progression.UnlockedIslands[selectedConfig.Island] then return "Unlock " .. selectedConfig.Island end
        if selectedConfig.Zone and selectedConfig.Zone ~= "Spawn" and not data.Progression.UnlockedZones[selectedConfig.Zone] then return "Unlock " .. selectedConfig.Zone end
        return "Egg unavailable: " .. selected
    end
    local amount = utils.settings.farm.HatchCount
    if amount > 3 and not utils.modules.perks.Has(data, "x8Egg") and not utils.modules.boostFormula.HasType(data, "OctoHatch") then amount = 3 end
    amount = math.min(amount, data.Pets.StorageLimit - utils.count(data.Pets.Owned))
    if amount < 1 then return "Storage full" end
    while amount > 0 and utils.modules.pricing.GetTotal(data, name, config.Price, amount, utils.player) > data.Currencies.Coins - utils.settings.farm.Reserve do amount -= 1 end
    if amount < 1 then
        local price = utils.modules.pricing.GetTotal(data, name, config.Price, 1, utils.player)
        local missing = price - (data.Currencies.Coins - utils.settings.farm.Reserve)
        return "Not enough coins - need " .. utils.formatNumber(math.max(0, missing)) .. " more for " .. name
    end
    local root, humanoid = utils.character()
    local egg = workspace.Eggs:FindFirstChild(name)
    if not egg then
        utils.travel.Owner, utils.travel.Origin = "Hatch", root.CFrame
        local success, result = pcall(function()
            utils.remote("Island", "Travel", {Island = config.Island or "Spawn", Source = "Menu"})
            local deadline = os.clock() + 8
            repeat task.wait(0.2); egg = workspace.Eggs:FindFirstChild(name) until egg or os.clock() >= deadline or not active()
        end)
        utils.travel.Owner, utils.travel.Origin = nil, nil
        if not active() then return "Stopped" end
        assert(success, tostring(result))
        assert(egg, "Egg is not streamed: " .. name)
    end
    local eggPart = egg:FindFirstChild("Egg")
    local center = utils.modules.eggIdle.GetPosition(egg) or (eggPart and eggPart:IsA("BasePart") and eggPart.Position) or utils.position(egg).Position
    local inRange = (root.Position - center).Magnitude <= utils.modules.offlineHatch.ResumeRange + 6
    if utils.hatch.LastEgg ~= name or not inRange then
        local position = utils.eggStandPosition(egg, root, humanoid)
        if not position then return "Ground in front of egg is not loaded" end
        humanoid.Sit = false
        humanoid.PlatformStand = false
        root.CFrame = position
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        task.wait(0.4)
        if utils.travel.Owner then return "Character busy" end
    end
    utils.hatch.LastEgg = name
    if utils.travel.Owner then return "Character busy" end
    if not active() then return "Stopped" end
    utils.hatch.Sequence += 1
    local sequence = utils.hatch.Sequence
    utils.hatch.NextAt = os.clock() + 3.5
    utils.hatch.Pending[sequence] = {At = os.clock(), Egg = name}
    utils.remote("Egg", "EggHatchRequested", {Egg = name, Count = amount, Auto = true, Seq = sequence})
    return "Opening " .. name
end

function utils.equip()
    utils.remote("Pet", "PetActionRequested", {Action = "EquipBest", Mode = utils.settings.pets.Team})
    return "Team requested"
end

function utils.sellPets()
    local settings = utils.settings.pets
    assert(next(settings.Rarities) and next(settings.Tiers) and next(settings.Names), "Select rarities, variants and pets to delete")
    local function matches(pet)
        local variant = pet.Tier == "Shiny" and "Rainbow" or pet.Tier or "Normal"
        return (settings.Rarities["All Rarities"] or settings.Rarities[pet.Rarity])
            and (settings.Tiers["All Variants"] or settings.Tiers[variant])
            and (settings.Names["All Pets"] or settings.Names[pet.Name])
    end
    local ids = {}
    for id, pet in pairs(utils.save().Pets.Owned) do
        if matches(pet) and not utils.protected(id, pet, utils.save()) then table.insert(ids, id) end
    end
    local count = 0
    for index = 1, #ids, 400 do
        if not runtime.Alive or not utils.jobs.Cleanup.Enabled then break end
        local batch = {}
        for offset = index, math.min(index + 399, #ids) do
            local pet = utils.save().Pets.Owned[ids[offset]]
            if pet and matches(pet) and not utils.protected(ids[offset], pet, utils.save()) then table.insert(batch, ids[offset]) end
        end
        if #batch > 0 then
            utils.remote("Pet", "PetActionRequested", {Action = "Delete", PetIds = batch})
            count += #batch
        end
        if index + 400 <= #ids then task.wait(1.1) end
    end
    return utils.formatNumber(count) .. " deletion requests"
end

function utils.sortedRarities(rarities)
    local names = utils.keys(rarities)
    table.sort(names, function(a, b)
        local first, second = utils.modules.rarity.GetRank(a), utils.modules.rarity.GetRank(b)
        return first == second and a < b or first < second
    end)
    return names
end

function utils.sortedPetNames(pets)
    local names = utils.keys(pets)
    table.sort(names, function(a, b)
        local first = utils.modules.launchPets[a] or utils.modules.catalog[a]
        local second = utils.modules.launchPets[b] or utils.modules.catalog[b]
        local firstRank = utils.modules.rarity.GetRank(first and first.Rarity or pets[a])
        local secondRank = utils.modules.rarity.GetRank(second and second.Rarity or pets[b])
        return firstRank == secondRank and a < b or firstRank < secondRank
    end)
    return names
end

function utils.inventoryPetNames()
    local names = {}
    for _, pet in pairs(utils.save().Pets.Owned) do names[pet.Name] = pet.Rarity or "Common" end
    local sorted = utils.sortedPetNames(names)
    table.insert(sorted, 1, "All Pets")
    return sorted
end

function utils.refreshEggDelete()
    local egg = utils.settings.farm.Egg
    local config = utils.modules.eggs[egg]
    local names, values, map, selected, rarityKeys = {}, {}, {}, {}, {}
    for _, pets in ipairs({config and config.Pets or {}, config and config.Secrets or {}}) do
        for name in pairs(pets) do names[name] = true end
    end
    local entries = utils.save().Eggs.AutoDelete[egg] or {}
    for _, name in ipairs(utils.sortedPetNames(names)) do
        local pet = utils.modules.launchPets[name] or utils.modules.catalog[name]
        local rarity = pet and pet.Rarity
        if rarity then rarityKeys[rarity] = rarityKeys[rarity] or {} end
        for _, tier in ipairs({"Normal", "Golden", "Diamond", "Shiny"}) do
            local label = (tier == "Shiny" and "Rainbow" or tier) .. " " .. name
            local key = utils.modules.rarity.AutoDeleteKey(name, tier)
            table.insert(values, label)
            map[label] = key
            if rarity then table.insert(rarityKeys[rarity], key) end
            if table.find(entries, key) then table.insert(selected, label) end
        end
    end
    tabs.hatching.deleteMap = map
    tabs.hatching.deleteRarityKeys = rarityKeys
    local selectedRarities = {}
    for rarity, keys in pairs(rarityKeys) do
        local all = true
        for _, key in ipairs(keys) do if not table.find(entries, key) then all = false; break end end
        if all then table.insert(selectedRarities, rarity) end
    end
    tabs.hatching.deleteRarities = selectedRarities
    if tabs.hatching.deleteDropdown then
        tabs.hatching.deleteDropdown.Value = selected
        tabs.hatching.deleteDropdown:Refresh(values)
    end
    if tabs.hatching.rarityDropdown then
        tabs.hatching.rarityDropdown.Value = selectedRarities
        tabs.hatching.rarityDropdown:Refresh(utils.sortedRarities(rarityKeys))
    end
    return values, selected
end

function utils.deleteEggRarities(values)
    values = type(values) == "table" and values or {}
    local previous = tabs.hatching.deleteRarities or {}
    local entries, changed = {}, false
    for _, label in pairs(tabs.hatching.deleteDropdown.Value or {}) do
        local key = tabs.hatching.deleteMap[label]
        if key then entries[key] = true end
    end
    for rarity, keys in pairs(tabs.hatching.deleteRarityKeys) do
        local enabled = table.find(values, rarity) ~= nil
        if enabled ~= (table.find(previous, rarity) ~= nil) then
            changed = true
            for _, key in ipairs(keys) do entries[key] = enabled or nil end
        end
    end
    tabs.hatching.deleteRarities = table.clone(values)
    if not changed then return end
    local selected = {}
    for _, label in ipairs(tabs.hatching.deleteDropdown.Values) do
        if entries[tabs.hatching.deleteMap[label]] then table.insert(selected, label) end
    end
    tabs.hatching.deleteDropdown:Select(selected)
end

function utils.craftGroups(machine, data)
    local config = utils.modules.machines[machine]
    local key = machine == "Shiny" and "Rainbow" or machine
    local selected = utils.settings.pets[key .. "Pets"]
    local required = utils.settings.pets[key .. "Count"]
    local groups, ready = {}, {}
    for id, pet in pairs(data.Pets.Owned) do
        if (selected["All Pets"] or selected[pet.Name]) and pet.Tier == config.SourceTier and not utils.protected(id, pet, data) then
            local key = pet.Name .. "/" .. tostring(pet.Mutation or "")
            groups[key] = groups[key] or {}
            table.insert(groups[key], id)
        end
    end
    for _, ids in pairs(groups) do
        table.sort(ids)
        while #ids >= required do
            local group = {}
            for _ = 1, required do table.insert(group, table.remove(ids)) end
            table.insert(ready, group)
        end
    end
    return ready
end

function utils.machinePoint(machine)
    local folder = workspace:FindFirstChild("InteractionPoints")
    local point = folder and folder:FindFirstChild(machine)
    if point then return point end
    for _, instance in ipairs(services.CollectionService:GetTagged("InteractionPoint")) do
        if instance.Name == machine and instance:IsDescendantOf(workspace) then return instance end
    end
end

function utils.craft(machine)
    local data = utils.save()
    if machine == "Diamond" and not data.Progression.UnlockedIslands["Crystal Cave"] then return "Unlock Crystal Cave" end
    if machine == "Shiny" and not data.ShinyStars.Unlocked then return "Collect all Shiny Stars" end
    local queue = (data.Machines.Shiny or {}).Queue or {}
    for id, craft in pairs(queue) do
        if (craft.EndTime or math.huge) <= workspace:GetServerTimeNow() then
            utils.remote("Machine", "MachineCraftRequested", {Machine = "Shiny", Action = "Claim", CraftId = craft.Id or id})
        end
    end
    if utils.settings.pets.CraftMode == "Storage" and utils.count(data.Pets.Owned) < math.floor(data.Pets.StorageLimit * 0.85) then return "Waiting for storage" end
    local groups = utils.craftGroups(machine, data)
    if #groups == 0 then return "Waiting for matching pets" end
    return utils.trip(machine, utils.machinePoint(machine), function()
        local count = 0
        for _, ids in ipairs(groups) do
            if not runtime.Alive or (utils.jobs[machine] and not utils.jobs[machine].Enabled) then break end
            if machine == "Shiny" and count + utils.count(queue) >= utils.modules.machines.Shiny.MaxQueue then break end
            utils.craftPending = (utils.craftPending or 0) + 1
            utils.remote("Machine", "MachineCraftRequested", {Machine = machine, Action = machine == "Shiny" and "Start" or "Craft", PetIds = ids})
            count += 1
            task.wait(1)
        end
        return tostring(count) .. " craft requests"
    end)
end

function utils.skills()
    local data = utils.save()
    local pending = utils.skillPending
    if pending then
        if data.SkillTree.Unlocked[pending.Name] then
            utils.skillPending = nil
            return "Purchased " .. pending.Name
        end
        if not pending.Done then return "Waiting for " .. pending.Name end
        utils.skillPending = nil
        if not pending.Success then return tostring(pending.Result) end
        if os.clock() - pending.At < 5 then
            utils.skillPending = pending
            return "Confirming " .. pending.Name
        end
        return "Unlock not confirmed: " .. pending.Name
    end
    local candidates = {}
    for name, node in pairs(utils.modules.skills.Nodes) do
        local available = not node.Data.RequiredIsland or data.Progression.UnlockedIslands[node.Data.RequiredIsland]
        if available and not data.SkillTree.Unlocked[name] and (not node.Parent or data.SkillTree.Unlocked[node.Parent]) then
            local price = utils.modules.skills.GetPrice(data, name)
            local currency = node.Data.Currency or "Gems"
            local reserve = currency == "Gems" and utils.settings.boosts.Reserve or 0
            if price <= (data.Currencies[currency] or 0) - reserve then table.insert(candidates, {Name = name, Price = price}) end
        end
    end
    table.sort(candidates, function(a, b) return a.Price == b.Price and a.Name < b.Name or a.Price < b.Price end)
    local node = candidates[1]
    if not node then return "Waiting for affordable unlocked skills" end
    pending = {Name = node.Name, At = os.clock(), Done = false}
    utils.skillPending = pending
    runtime:Spawn(function()
        pending.Success, pending.Result = pcall(utils.remote, "SkillTree", "Unlock", {Name = node.Name})
        utils.identityReset()
        pending.Done = true
    end)
    return "Buying " .. node.Name
end

function utils.islands()
    local data, island = utils.save(), nil
    for _, candidate in ipairs(utils.sortedIslands()) do
        if not data.Progression.UnlockedIslands[candidate.Name] then island = candidate; break end
    end
    if not island then return "All islands unlocked" end
    if data.Currencies.Coins < island.Config.Price then return "Saving for " .. island.Name end
    local portal = utils.islandPortal(island.Name)
    if not portal then
        utils.remote("Island", "Travel", {Island = data.Progression.Island or "Spawn", Source = "Menu"})
        task.wait(0.5)
        portal = utils.islandPortal(island.Name)
    end
    assert(portal, "Portal is not streamed: " .. island.Name)
    return utils.trip("Islands", portal.CFrame * CFrame.new(0, 0, 5), function()
        utils.remote("Island", "IslandUnlockRequested", {Action = "Purchase", Island = island.Name})
        local deadline = os.clock() + 4
        repeat task.wait(0.1) until data.Progression.UnlockedIslands[island.Name] or os.clock() >= deadline or not runtime.Alive
        return data.Progression.UnlockedIslands[island.Name] and ("Unlocked " .. island.Name) or ("Requested " .. island.Name)
    end)
end

function utils.islandPortal(name)
    local candidates = {}
    local nextPortals = workspace:FindFirstChild("NextPortals")
    if nextPortals then table.insert(candidates, nextPortals:FindFirstChild(name)) end
    local portals = workspace:FindFirstChild("Portals")
    local hub = portals and portals:FindFirstChild("Portals")
    local config = utils.modules.islands.Islands[name]
    if hub and config then table.insert(candidates, hub:FindFirstChild(config.PortalName)) end
    for _, model in ipairs(candidates) do
        if model then
            local part = model:FindFirstChild("Portal_Hitbox", true) or model:FindFirstChild("Portal", true)
            if part and part:IsA("BasePart") then return part end
        end
    end
end

function utils.memoryChoice(state, first)
    local known = utils.memory.Known
    for index, card in ipairs(state.Cards or {}) do if card.Pet then known[index] = card.Pet end end
    if first then
        for index, card in ipairs(state.Cards) do
            if index ~= first and not card.Matched and known[index] == known[first] then return index end
        end
    else
        for index, card in ipairs(state.Cards) do
            if not card.Matched and known[index] then
                for other, row in ipairs(state.Cards) do if index ~= other and not row.Matched and known[other] == known[index] then return index end end
            end
        end
    end
    for index, card in ipairs(state.Cards) do if index ~= first and not card.Matched and not known[index] then return index end end
    for index, card in ipairs(state.Cards) do if index ~= first and not card.Matched then return index end end
end

function utils.memoryGame()
    return utils.trip("Memory", utils.modules.memoryWorld.GetPad(), function()
        local state = utils.remote("MemoryMatch", "Open", false)
        if state.Outcome ~= "Playing" then
            if (utils.save().MemoryMatch.NextPlay or 0) > workspace:GetServerTimeNow() then return "On cooldown" end
            state = utils.remote("MemoryMatch", "Open", true)
        end
        assert(state and state.Id, "No memory session")
        if state.Id ~= utils.memory.Id then utils.memory.Id = state.Id; table.clear(utils.memory.Known) end
        local deadline = os.clock() + 150
        local first
        local visible = {}
        for index, card in ipairs(state.Cards or {}) do if card.Pet and not card.Matched then table.insert(visible, index) end end
        if #visible == 1 and (state.UnlockAt or 0) == 0 then first = visible[1] end
        while runtime.Alive and utils.jobs.Memory.Enabled and state.Outcome == "Playing" and os.clock() < deadline do
            local delay = math.max(0.2, (state.UnlockAt or 0) - workspace:GetServerTimeNow() + 0.1)
            task.wait(delay)
            if not utils.jobs.Memory.Enabled then break end
            local choice = utils.memoryChoice(state, first)
            if not choice then break end
            state = utils.remote("MemoryMatch", "Flip", state.Id, choice)
            assert(state and state.Cards, "Missing card result")
            for index, card in ipairs(state.Cards) do if card.Pet then utils.memory.Known[index] = card.Pet end end
            first = first and nil or choice
            if (state.UnlockAt or 0) > 0 then first = nil end
            utils.message("Memory", tostring(state.Pairs or 0) .. "/6 pairs")
        end
        if state.Outcome ~= "Playing" then utils.memory.Id = nil end
        return state.Outcome or "Paused"
    end)
end

function utils.digGame()
    local allowance = utils.modules.dig.Allowance(utils.save().Digging, workspace:GetServerTimeNow())
    if allowance <= 0 then return "Hourly limit reached" end
    local site = utils.modules.digWorld.GetSite()
    local zone = site and site:FindFirstChild("DigZone")
    if not utils.save().Progression.UnlockedIslands.Autumn then return "Unlock Autumn" end
    return utils.trip("Dig", zone, function()
        local state = utils.remote("Dig", "Begin")
        local deadline = os.clock() + utils.modules.dig.SessionTimeout
        while runtime.Alive and utils.jobs.Dig.Enabled and state and state.Round and not state.Complete and os.clock() < deadline do
            local round = state.Round
            local target, best = nil, math.huge
            local now = workspace:GetServerTimeNow() + 0.2
            for step = 0, 400 do
                local at = now + step * 0.005
                local error = math.abs(utils.modules.dig.Cursor(round, at) - round.Center)
                if error < best then target, best = at, error end
                if error < 0.003 then break end
            end
            while runtime.Alive and utils.jobs.Dig.Enabled and workspace:GetServerTimeNow() < target do task.wait(0.01) end
            if not utils.jobs.Dig.Enabled then break end
            state = utils.remote("Dig", "Hit", state.Id, round.Sequence, target)
            utils.message("Dig", state.Complete and "Complete" or "Digging")
        end
        if state and state.Complete then return "Complete" end
        pcall(utils.remote, "Dig", "Cancel")
        return "Paused"
    end)
end

function utils.arenaReward()
    local data = utils.save().Colosseum
    local pending = data.PendingReward
    if not pending then return "No pending reward" end
    local old, new = data.Relic, pending.NewRelic
    local score = function(relic)
        local value = 0
        for _, boost in ipairs(relic and relic.Boosts or {}) do value += tonumber(boost.Value) or 0 end
        return value
    end
    return utils.remote("Colosseum", "ClaimMinigameReward", score(new) > score(old) and "replace" or "keep")
end

function utils.colosseum()
    if utils.save().Colosseum.PendingReward then utils.arenaReward() end
    local lastRun = utils.save().Colosseum.Cooldown or 0
    if lastRun > 0 and lastRun + 1800 > workspace:GetServerTimeNow() then return "On cooldown" end
    return utils.trip("Arena", utils.machinePoint("Colosseum"), function()
        table.clear(utils.arena.Opponents)
        local result = utils.remote("Colosseum", "StartWaveDefense")
        assert(type(result) == "table" and not result.OnCooldown, "Arena unavailable")
        utils.arena.Active = true
        local deadline = os.clock() + 900
        while runtime.Alive and utils.jobs.Arena.Enabled and utils.arena.Active and os.clock() < deadline do
            for id in pairs(utils.arena.Opponents) do
                local response = utils.remote("Colosseum", "AttackOpponent", id)
                if response and response.Health and response.Health <= 0 then utils.arena.Opponents[id] = nil end
                task.wait(0.1)
                if not utils.jobs.Arena.Enabled then break end
            end
            task.wait(0.1)
        end
        if utils.arena.Active then pcall(utils.remote, "Colosseum", "EndWaveDefense") end
        utils.arena.Active = false
        task.wait(0.5)
        utils.arenaReward()
        pcall(utils.remote, "Colosseum", "ReturnFromArena")
        return "Wave " .. tostring(utils.save().Colosseum.BestWave or 0)
    end)
end

function utils.feed()
    local data = utils.save()
    if not utils.modules.levels.LevelingUnlocked(data) then return "Pet leveling is locked" end
    for _, id in ipairs(data.Pets.Equipped) do
        local pet = data.Pets.Owned[id]
        if pet and (pet.Level or 1) < utils.modules.levels.GetMaxLevel(pet.Rarity) then
            for _, name in ipairs({"RegularTreat", "BagOfTreats"}) do
                if (data.Items.Owned[name] or 0) > 0 then
                    utils.remote("Item", "UseOnPet", {Item = name, PetId = id, Amount = 1})
                    return "Fed " .. pet.Name
                end
            end
        end
    end
    return "No treats or eligible team pets"
end

function utils.potions()
    local data = utils.save()
    for _, name in ipairs(utils.keys(utils.modules.boosts.Definitions)) do
        local config = utils.modules.boosts.Definitions[name]
        if utils.settings.boosts.Types[config.Type] and (data.Boosts[name] or 0) > 0 and not utils.modules.boostFormula.HasType(data, config.Type) then
            utils.remote("Boost", "Use", name)
            return "Used " .. name
        end
    end
    return "Boosts active or potions unavailable"
end

function utils.potionMachine()
    local data = utils.save()
    if data.Currencies.Gems <= utils.settings.boosts.Reserve then return "Gem reserve reached" end
    return utils.trip("Potions", workspace.Map1:FindFirstChild("PotionMachine"), function()
        local slots = utils.save().PotionMachine.Slots or {}
        local now = workspace:GetServerTimeNow()
        for index, slot in pairs(slots) do
            if (slot.ReadyAt or slot.FinishAt or math.huge) <= now then utils.remote("PotionMachine", "Claim", tonumber(index) or index) end
        end
        local cost = utils.modules.brew.GetPrice(utils.save().Statistics.Rebirths)
        for slot = 1, utils.modules.brew.SlotCount do
            if not slots[tostring(slot)] and utils.save().Currencies.Gems - cost >= utils.settings.boosts.Reserve then
                utils.remote("PotionMachine", "Brew", utils.settings.boosts.Brew, slot)
                task.wait(0.25)
            end
        end
        for _, recipe in ipairs(utils.modules.recipes.Recipes) do
            local amount = math.floor((utils.save().Boosts[recipe.Input] or 0) / recipe.Required)
            if amount > 0 then utils.remote("PotionMachine", "Craft", recipe.Output, amount) end
        end
        return "Machine checked"
    end)
end

function utils.totems()
    local data = utils.save()
    local root = utils.character()
    local active = utils.remote("Item", "GetActiveTotems") or {}
    for _, name in ipairs({"TotemOfHatchSpeed", "TotemOfLuck", "TotemOfSecretLuck", "TotemOfClicks", "TotemOfRebirths"}) do
        if (data.Items.Owned[name] or 0) > 0 then
            local placed = false
            for _, totem in pairs(active.Totems or active) do
                if type(totem) == "table" and totem.TotemName == name and (totem.ExpiresAt or 0) > workspace:GetServerTimeNow() then placed = true end
            end
            if not placed then
                utils.remote("Item", "PlaceTotem", {TotemName = name, Position = root.Position})
                return "Placed " .. name
            end
        end
    end
    return "No unused totems"
end

function utils.relic()
    local data, selected, best = utils.save(), nil, -math.huge
    for name, owned in pairs(data.Mastery.RelicInventory or {}) do
        if owned and utils.modules.relics.Relics[name] then
            local score = 0
            for _, boost in ipairs(utils.modules.relics.Relics[name].Boosts) do score += boost.Value end
            if utils.settings.boosts.Relic == name then selected = name; break end
            if utils.settings.boosts.Relic == "Automatic" and score > best then selected, best = name, score end
        end
    end
    if not selected then return "No selected relic owned" end
    if selected ~= data.Mastery.EquippedRelic then utils.remote("Mastery", "EquipRelic", selected) end
    return selected
end

function utils.enchantTargets(data)
    local targets = {}
    if utils.settings.enchant.UseEquipped then
        for _, id in pairs(data.Pets.Equipped or {}) do
            if data.Pets.Owned[id] then targets[id] = true end
        end
    end
    for id in pairs(utils.settings.enchant.PetIds) do
        if data.Pets.Owned[id] then targets[id] = true end
    end
    return targets
end

function utils.enchant()
    assert(next(utils.settings.enchant.Traits), "Select target traits")
    local data = utils.save()
    local targets = utils.enchantTargets(data)
    local pending = data.Enchanting.Pending
    if pending then
        if not targets[pending.PetId] then return "Finish the pending enchant first" end
        local success, result = pcall(utils.remote, "Enchant", "Resolve", {Token = pending.Token, UseNew = true})
        if not success and tostring(result):find("PetChangedChooseKeep", 1, true) then
            utils.remote("Enchant", "Resolve", {Token = pending.Token, UseNew = false})
        elseif not success then error(result, 0) end
        return "Pending enchant resolved"
    end
    for id in pairs(targets) do
        local pet = data.Pets.Owned[id]
        if pet and not utils.modules.enchants.AutoMatch(utils.settings.enchant.Traits, pet.Enchant, pet.Enchant2) then
            for slot = 1, utils.modules.enchants.GetSlotCount(pet) do
                local current = pet.Enchant
                if slot == 2 then current = pet.Enchant2 end
                if not utils.modules.enchants.IsProtected(current) then
                    local price = utils.modules.enchants.GetRollPrice(pet)
                    if data.Currencies.Gems < price * utils.settings.enchant.Reserve then return "Waiting for enchant reserve" end
                    local point = utils.machinePoint("Enchanting") or utils.machinePoint("Enchant")
                    return utils.trip("Enchant", point, function()
                        local currentData = utils.save()
                        local currentPet = currentData.Pets.Owned[id]
                        if not utils.jobs.Enchant.Enabled or not utils.enchantTargets(currentData)[id] or not currentPet then return "Pet selection changed" end
                        if utils.modules.enchants.AutoMatch(utils.settings.enchant.Traits, currentPet.Enchant, currentPet.Enchant2) then return "Pet already matched" end
                        local currentEnchant = currentPet.Enchant
                        if slot == 2 then currentEnchant = currentPet.Enchant2 end
                        if utils.modules.enchants.IsProtected(currentEnchant) then return "Enchant protected" end
                        local result = utils.remote("Enchant", "Enchant", {PetId = id, Slot = slot, RequestId = services.HttpService:GenerateGUID(false)})
                        local pending = result and result.Pending
                        assert(pending and pending.Token, "No pending enchant token")
                        utils.remote("Enchant", "Resolve", {Token = pending.Token, UseNew = true})
                        return "Rolled " .. pet.Name
                    end)
                end
            end
        end
    end
    return "Team matched or protected"
end

function utils.shrine()
    if utils.player:GetAttribute("ShrineBlessing") == utils.settings.boosts.Shrine then return utils.settings.boosts.Shrine end
    if not utils.modules.shrineVisuals then utils.load("shrineVisuals", "Modules.Client.Game.ShrineVisuals") end
    local position = utils.modules.shrineVisuals.GetCrystalPosition()
    assert(position, "Shrine is not streamed")
    return utils.trip("Shrine", CFrame.new(position), function()
        utils.remote("Shrine", "Choose", utils.settings.boosts.Shrine)
        return utils.settings.boosts.Shrine
    end)
end

function utils.collectStars()
    local data = utils.save()
    if data.ShinyStars.Unlocked then return "All stars found" end
    for _, config in ipairs(utils.modules.stars.Stars) do
        if not data.ShinyStars.Found[config.Id] and (config.Island == "Spawn" or data.Progression.UnlockedIslands[config.Island]) then
            local model = workspace.ShinyStars:FindFirstChild(config.Id)
            if model then
                local center = model:GetAttribute("ShinyStarCenter")
                return utils.trip("Stars", typeof(center) == "Vector3" and CFrame.new(center) or model, function()
                    utils.remote("ShinyStar", "Collect", config.Id)
                    return "Collected " .. config.Id
                end)
            end
        end
    end
    return "Unlock more islands"
end

function utils.rewards()
    local data, count = utils.save(), 0
    for id, quest in pairs(data.Quests) do
        if quest.Completed and not quest.Claimed then utils.remote("Quest", "ClaimQuest", id); count += 1 end
    end
    utils.remote("PetIndex", "ClaimAllRequested")
    if data.Offline.Pending then utils.remote("OfflineRewards", "Claim"); count += 1 end
    local result = utils.remote("Leaderboard", "GetPendingRewards")
    for _, reward in pairs(type(result) == "table" and (result.Rewards or result) or {}) do
        if type(reward) == "table" and reward.Id then utils.remote("Leaderboard", "ClaimReward", reward.Id); count += 1 end
    end
    return tostring(count) .. " rewards checked"
end

function utils.webhookPayload(embeds)
    local id = utils.settings.webhook.UserId
    return {
        content = id ~= "" and "<@" .. id .. ">" or "",
        allowed_mentions = {parse = {}, users = id ~= "" and {id} or {}},
        embeds = embeds
    }
end

function utils.logHatch(packet)
    if not utils.jobs.Webhook.Enabled then return end
    local fields, firstRarity = {}, nil
    for _, pet in ipairs(packet.Pets or {}) do
        if utils.settings.webhook.Rarities[pet.Rarity] then
            firstRarity = firstRarity or pet.Rarity
            table.insert(fields, {
                name = string.format("🐾 Pet #%d:", #fields + 1),
                value = string.format("**%s %s**\n✨ **Rarity:** `%s`", pet.Tier or "Normal", pet.Name, pet.Rarity),
                inline = true
            })
        end
    end
    if #fields == 0 then return end
    local colors = {Common = 0xFFFFFF, Rare = 0x3498DB, Epic = 0x9B59B6, Legendary = 0xF1C40F, Mythical = 0xE74C3C}
    if #utils.log.Queue >= 30 then table.remove(utils.log.Queue, 1); utils.log.Dropped += 1 end
    table.insert(utils.log.Queue, utils.webhookPayload({{
        title = string.format("🥚 `%s` Hatched %d Pet(s) from %s Egg!", utils.settings.webhook.ShowUser and utils.player.Name or "Anonymous", #fields, packet.Egg or "Unknown"),
        color = colors[firstRarity] or 0xFFFFFF,
        fields = fields,
        footer = {text = "Sent by Silence"},
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
    }}))
end

function utils.sendLog()
    if os.clock() < utils.log.Next or #utils.log.Queue == 0 then return "Queue " .. tostring(#utils.log.Queue) end
    local url = utils.settings.webhook.URL
    assert(url:match("^https://discord%.com/api/webhooks/%d+/[%w_%-]+$") or url:match("^https://discordapp%.com/api/webhooks/%d+/[%w_%-]+$"), "Enter a Discord webhook URL")
    local requestFunction = request or http_request or (syn and syn.request)
    assert(type(requestFunction) == "function", "Executor HTTP requests unavailable")
    local payload = utils.log.Queue[1]
    local response = requestFunction({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = services.HttpService:JSONEncode(payload)})
    local status = response and tonumber(response.StatusCode)
    if status == 429 then
        local success, body = pcall(services.HttpService.JSONDecode, services.HttpService, response.Body or "")
        utils.log.Next = os.clock() + math.clamp(success and tonumber(body.retry_after) or 5, 1, 300)
        return "Rate limited"
    end
    assert(status and status >= 200 and status < 300, "Webhook HTTP " .. tostring(status))
    table.remove(utils.log.Queue, 1)
    utils.log.Next = os.clock() + 2
    return "Delivered"
end

function utils.bind(group, event, callback)
    local folder = services.ReplicatedStorage.RemoteServices:FindFirstChild(group .. "Service")
    local remote = folder and folder:FindFirstChild("RE") and folder.RE:FindFirstChild(event)
    if remote then runtime:Connect(remote.OnClientEvent, callback) end
end

utils.bind("Tap", "TapResult", function(packet)
    if type(packet) == "table" and type(packet.Combo) == "table" then
        utils.clickCombo = tonumber(packet.Combo.Multiplier) or 1
    end
end)
utils.bind("Machine", "MachineCraftResult", function()
    if (utils.craftPending or 0) <= 0 then return end
    utils.craftPending -= 1
    runtime:Spawn(function()
        task.wait(0.2)
        if not utils.travel.Owner and utils.jobs.Hatch.Enabled then utils.closeCraftMenus() end
    end)
end)

utils.bind("Egg", "EggHatchResult", function(packet)
    if type(packet) ~= "table" or not utils.hatch.Pending[packet.Seq] then return end
    local sentAt = utils.hatch.Pending[packet.Seq].At
    utils.hatch.Pending[packet.Seq] = nil
    if packet.Success then
        utils.hatch.NextAt = math.max(os.clock() + 0.2, sentAt + math.max(0.5, 3.5 / (tonumber(packet.Speed) or 1)))
        utils.hatch.Count += #(packet.Pets or {})
        utils.message("Hatch", packet.Egg .. " | " .. utils.formatNumber(utils.hatch.Count) .. " pets")
        utils.logHatch(packet)
    else
        utils.hatch.NextAt = os.clock() + 4
        utils.hatch.Errors += 1
        utils.message("Hatch", packet.Error or packet.Reason or "Rejected")
    end
end)
utils.bind("Colosseum", "WaveDefenseOpponentSpawned", function(packet)
    if utils.arena.Active and packet and packet.Id then utils.arena.Opponents[packet.Id] = packet end
end)
utils.bind("Colosseum", "WaveDefenseOpponentDefeated", function(packet)
    if packet then utils.arena.Opponents[packet.OpponentId] = nil end
end)
utils.bind("Colosseum", "WaveDefenseWaveStarting", function(packet)
    utils.arena.Wave = type(packet) == "table" and (packet.Wave or packet.WaveNumber or 0) or tonumber(packet) or 0
    utils.message("Arena", "Wave " .. tostring(utils.arena.Wave))
end)
utils.bind("Colosseum", "WaveDefenseGameOver", function() utils.arena.Active = false end)
utils.bind("LuckyDucky", "Spawn", function(packet)
    if utils.jobs.Rewards and utils.jobs.Rewards.Enabled and packet and packet.Id then pcall(utils.remote, "LuckyDucky", "Claim", packet.Id) end
end)
for _, group in ipairs({"Machine", "Pet", "Rebirth", "Island"}) do
    local event = ({Machine = "MachineCraftResult", Pet = "PetActionResult", Rebirth = "RebirthResult", Island = "IslandUnlockResult"})[group]
    utils.bind(group, event, function(packet)
        if type(packet) == "table" and (packet.Success == false or packet.Error) then utils.message(group, packet.Error or packet.Reason or "Rejected") end
    end)
end

utils.load("chests", "Shared.Game.TapChestConfig")
function utils.chestModel(id)
    for _, model in ipairs(services.CollectionService:GetTagged(utils.modules.chests.Tag)) do
        if model:IsDescendantOf(workspace) and model:GetAttribute(utils.modules.chests.Attributes.Id) == id then return model end
    end
end

function utils.chests()
    if utils.travel.Owner then return "Character busy" end
    local data, nearest = utils.save(), nil
    for _, id in ipairs(utils.keys(utils.modules.chests.Chests)) do
        local config = utils.modules.chests.Get(id)
        if data.Progression.UnlockedIslands[config.Island] then
            local readyAt = utils.modules.chests.GetReadyAt(data, id)
            if readyAt <= workspace:GetServerTimeNow() then
                local job = utils.jobs.Chests
                local generation = job.Generation
                local function active() return runtime.Alive and job.Enabled and job.Generation == generation end
                local model = utils.chestModel(id)
                if not model then
                    utils.travel.Owner = "Chests"
                    local success, result = pcall(function()
                        utils.remote("Island", "Travel", {Island = config.Island, Source = "Menu"})
                        local deadline = os.clock() + 8
                        repeat
                            task.wait(0.2)
                            model = utils.chestModel(id)
                        until model or os.clock() >= deadline or not active()
                    end)
                    utils.travel.Owner = nil
                    assert(success, tostring(result))
                end
                if not active() then return "Stopped" end
                if not model then return "Chest is not streamed: " .. config.Island end
                local front = model:GetAttribute(utils.modules.chests.Attributes.Front)
                local target = typeof(front) == "CFrame" and front or utils.position(model)
                return utils.trip("Chests", target, function()
                    if not active() then return "Stopped" end
                    local claims = utils.modules.chests.GetClaims(utils.save(), id)
                    utils.remote("TapChest", "Claim", id)
                    local deadline = os.clock() + 5
                    repeat task.wait(0.1) until utils.modules.chests.GetClaims(utils.save(), id) > claims or os.clock() >= deadline or not active()
                    if utils.modules.chests.GetClaims(utils.save(), id) > claims then return "Claimed " .. config.Island end
                    return "Claim not confirmed: " .. config.Island
                end)
            end
            nearest = math.min(nearest or math.huge, readyAt - workspace:GetServerTimeNow())
        end
    end
    return nearest and ("Next chest in " .. utils.modules.chests.FormatCountdown(nearest)) or "Unlock a chest island"
end

function utils.setting(name, value)
    if utils.originals[name] == nil then utils.originals[name] = {Value = utils.save().Settings[name]} end
    utils.remote("Settings", "UpdateSetting", {Name = name, Value = value})
end

function utils.hideTapVisual(instance)
    if not utils.clickVisuals.Enabled or utils.clickVisuals.Saved[instance] then return end
    local name, property = instance.Name, nil
    if instance:IsA("ScreenGui") and (name == "Popups" or name == "TS2CriticalPopups") then property = "Enabled"
    elseif instance:IsA("GuiObject") and (name:match("^TS2Tap") or name:match("^TS2Click") or name:match("^TS2Critical") or name:match("^TS2PhysicsCoin") or name:match("^TS2CoinDrop")) then property = "Visible" end
    if not property then return end
    local saved = {Property = property, Value = instance[property]}
    utils.clickVisuals.Saved[instance] = saved
    instance[property] = false
    saved.Connection = runtime:Connect(instance:GetPropertyChangedSignal(property), function()
        if utils.clickVisuals.Enabled and instance[property] then instance[property] = false end
    end)
end

function utils.hideClicks(enabled)
    local state = utils.clickVisuals
    if state.Enabled == enabled then return end
    state.Enabled = enabled
    if not enabled then
        if state.Connection then state.Connection:Disconnect(); state.Connection = nil end
        for _, hook in ipairs(state.Hooks) do
            if hook.Module[hook.Name] == hook.Replacement then hook.Module[hook.Name] = hook.Original end
        end
        table.clear(state.Hooks)
        for instance, saved in pairs(state.Saved) do
            if saved.Connection then saved.Connection:Disconnect() end
            if instance.Parent then instance[saved.Property] = saved.Value end
        end
        table.clear(state.Saved)
        if utils.modules.tapEffects then
            pcall(utils.modules.tapEffects.SetPointerEffectsEnabled, utils.modules.tapEffects, utils.modules.skills.CanClickAnywhere(utils.save()))
        end
        return
    end
    if not utils.modules.tapEffects then utils.load("tapEffects", "Modules.Client.Game.TapEffects") end
    if not utils.modules.clickFx then utils.load("clickFx", "Modules.Client.Game.ClickFx") end
    local replace = function(module, name, callback)
        if type(module[name]) ~= "function" then return end
        local original = module[name]
        module[name] = callback
        table.insert(state.Hooks, {Module = module, Name = name, Original = original, Replacement = callback})
    end
    local suppress = function() end
    for _, name in ipairs({"Emit", "PredictManualTap", "PlayClickPopup", "PlayCriticalBurst", "BurstAtPointer", "QueueCritical"}) do replace(utils.modules.tapEffects, name, suppress) end
    replace(utils.modules.clickFx, "Request", suppress)
    utils.modules.tapEffects:SetPointerEffectsEnabled(false)
    local pointer = utils.modules.tapEffects.SetPointerEffectsEnabled
    replace(utils.modules.tapEffects, "SetPointerEffectsEnabled", function(self) return pointer(self, false) end)
    local gui = utils.player.PlayerGui
    for _, instance in ipairs(gui:GetDescendants()) do utils.hideTapVisual(instance) end
    state.Connection = runtime:Connect(gui.DescendantAdded, utils.hideTapVisual)
end

function utils.closeRewards()
    if not utils.modules.rewardPopup then utils.load("rewardPopup", "Controllers.UI.RewardPopupController") end
    if utils.modules.rewardPopup:IsOpen() then
        utils.modules.rewardPopup:Close()
        return "Closing"
    end
    return "No reward popup"
end

function utils.reduceGraphics(instance)
    local state = utils.performance
    if not state.Enabled then return end
    local function set(property, value)
        local success, original = pcall(function() return instance[property] end)
        if not success or original == value then return end
        local saved = state.Saved[instance]
        if saved and saved[property] ~= nil then return end
        if pcall(function() instance[property] = value end) then
            state.Saved[instance] = saved or {}
            state.Saved[instance][property] = {Value = original}
        end
    end
    if instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam")
        or instance:IsA("Fire") or instance:IsA("Smoke") or instance:IsA("Sparkles") then
        set("Enabled", false)
    elseif instance:IsA("PostEffect") then
        set("Enabled", false)
    elseif instance:IsA("Light") then
        set("Shadows", false)
    elseif instance:IsA("BasePart") then
        set("CastShadow", false)
        local model = instance:FindFirstAncestorOfClass("Model")
        if not (model and model:FindFirstChildOfClass("Humanoid")) then
            set("Material", Enum.Material.SmoothPlastic)
            set("Reflectance", 0)
            if instance:IsA("MeshPart") then set("RenderFidelity", Enum.RenderFidelity.Performance) end
        end
    elseif instance:IsA("Terrain") then
        set("WaterWaveSize", 0)
        set("WaterWaveSpeed", 0)
        set("WaterReflectance", 0)
        set("Decoration", false)
    elseif instance == services.Lighting then
        set("GlobalShadows", false)
        set("EnvironmentSpecularScale", 0)
    end
end

function utils.antiLag()
    local state = utils.performance
    if state.Enabled then return "Anti Lag already enabled" end
    state.Enabled = true
    state.Connection = runtime:Connect(workspace.DescendantAdded, utils.reduceGraphics)
    state.LightingConnection = runtime:Connect(services.Lighting.DescendantAdded, utils.reduceGraphics)
    utils.reduceGraphics(services.Lighting)
    for _, container in ipairs({workspace, services.Lighting}) do
        for index, instance in ipairs(container:GetDescendants()) do
            if not runtime.Alive then return "Stopped" end
            utils.reduceGraphics(instance)
            if index % 250 == 0 then task.wait() end
        end
    end
    return "Anti Lag enabled"
end

runtime:AddCleanup(function()
    utils.performance.Enabled = false
    if utils.performance.Connection then utils.performance.Connection:Disconnect() end
    if utils.performance.LightingConnection then utils.performance.LightingConnection:Disconnect() end
    for instance, properties in pairs(utils.performance.Saved) do
        for property, saved in pairs(properties) do pcall(function() instance[property] = saved.Value end) end
    end
    table.clear(utils.performance.Saved)
end)

function utils.hideHatch(enabled)
    local state = utils.hatchVisuals
    if state.Enabled == enabled then return end
    if not enabled then
        state.Enabled = false
        for _, hook in ipairs(state.Hooks) do
            if hook.Module[hook.Name] == hook.Replacement then hook.Module[hook.Name] = hook.Original end
        end
        table.clear(state.Hooks)
        utils.setting("HatchAnimation", utils.originals.HatchAnimation and utils.originals.HatchAnimation.Value or 1)
        return
    end
    for name, path in pairs({hatchRenderer = "HatchRenderer", secretRenderer = "SecretHatchRenderer", secretCutscenes = "SecretHatchCutscenes"}) do
        if not utils.modules[name] then utils.load(name, "Modules.Client.Pets." .. path) end
    end
    local function replace(module, name, callback)
        assert(type(module[name]) == "function", "Missing hatch renderer method: " .. name)
        table.insert(state.Hooks, {Module = module, Name = name, Original = module[name], Replacement = callback})
        module[name] = callback
    end
    -- Complete the game's sequence so receipts and queued results still settle.
    replace(utils.modules.hatchRenderer, "Play", function(self, egg, packet, done)
        if type(done) == "function" then task.defer(done) end
    end)
    for _, name in ipairs({"Play", "PlayReveal"}) do
        replace(utils.modules.secretRenderer, name, function(self, pet, done)
            if type(done) == "function" then task.defer(done) end
        end)
    end
    replace(utils.modules.secretCutscenes, "Has", function() return false end)
    state.Enabled = true
    utils.setting("HatchAnimation", 3)
end

utils.section(tabs.main, "Clicking")
utils.job(tabs.main, "Auto Tap", "Tap", utils.modules.gameConfig.ManualTapInterval, utils.tap)
utils.controls.HideClicks = tabs.main:Toggle({Title = "Hide Clicks", Value = false, Flag = "Visual.HideTaps", Callback = utils.hideClicks})
utils.section(tabs.main, "Rebirths")
tabs.main.rebirthValues, tabs.main.rebirthMap = {"Max"}, {}
function utils.refreshRebirths()
    local values, map = {"Max"}, {}
    local data = utils.save()
    for index = 1, utils.modules.buttons.GetOptionCount(data.Upgrades.RebirthButtons or 0, data.Progression.World) do
        local label = utils.formatNumber(utils.modules.rebirth.GetAmountFromIndex(index))
        table.insert(values, label)
        map[label] = tostring(index)
    end
    tabs.main.rebirthValues, tabs.main.rebirthMap = values, map
    if tabs.main.rebirthDropdown then tabs.main.rebirthDropdown:Refresh(values) end
end
utils.refreshRebirths()
tabs.main.rebirthDropdown = tabs.main:Dropdown({Title = "Select Rebirth Amount", Values = tabs.main.rebirthValues, Value = "Max", Multi = false, SearchBarEnabled = true, Flag = "Farm.RebirthAmount",
    Callback = function(value) utils.settings.farm.Rebirth = value == "Max" and "Maximum" or tabs.main.rebirthMap[value] or "Maximum" end})
utils.job(tabs.main, "Auto Rebirth", "Rebirth", 0.5, utils.rebirth)
utils.section(tabs.main, "Progression")
utils.job(tabs.main, "Auto Skill Tree", "Skills", 0.5, utils.skills)
utils.job(tabs.main, "Auto Unlock Islands", "Islands", 5, utils.islands)
utils.job(tabs.main, "Auto Claim Rewards", "Rewards", 20, utils.rewards)
utils.job(tabs.main, "Auto Close Rewards", "RewardPopup", 0.3, utils.closeRewards)
utils.job(tabs.main, "Auto Claim Chests", "Chests", 30, utils.chests)
utils.label(tabs.main, "Rebirth")
utils.section(tabs.main, "Performance")
utils.action(tabs.main, "Anti Lag", "Performance", utils.antiLag)
utils.label(tabs.main, "Performance")

utils.section(tabs.hatching, "Hatching")
utils.eggNames, utils.eggMap = {}, {}
for _, egg in ipairs(utils.sortedEggs()) do
    local label = egg.Name .. " - " .. utils.formatNumber(egg.Price)
    table.insert(utils.eggNames, label)
    utils.eggMap[label] = egg.Name
end
tabs.hatching:Dropdown({Title = "Select Egg", Values = utils.eggNames, Value = "Basic - " .. utils.formatNumber(utils.modules.eggs.Basic.Price), Multi = false, SearchBarEnabled = true, Flag = "Hatch.Egg",
    Callback = function(value)
        utils.settings.farm.Egg = utils.eggMap[value] or (utils.modules.eggs[value] and value) or "Basic"
        utils.refreshEggDelete()
    end})
tabs.hatching:Dropdown({Title = "Hatch Amount", Values = {"1x", "3x", "8x", "Max"}, Value = "Max", Multi = false, Flag = "Hatch.Amount",
    Callback = function(value) utils.settings.farm.HatchCount = value == "Max" and 8 or tonumber(value:match("%d+")) or 3 end})
utils.settings.farm.HatchCount = 8
utils.job(tabs.hatching, "Auto Hatch", "Hatch", 0.2, utils.hatchEgg)
tabs.hatching:Toggle({Title = "Hide Hatch Animation", Value = false, Flag = "Visual.HideHatch", Callback = utils.hideHatch})
utils.label(tabs.hatching, "Hatch")
utils.section(tabs.hatching, "Egg Auto Delete")
local eggDeleteValues, eggDeleteSelected = utils.refreshEggDelete()
tabs.hatching.deleteDropdown = tabs.hatching:Dropdown({Title = "Select Pets to Delete", Values = eggDeleteValues, Value = eggDeleteSelected, Multi = true, SearchBarEnabled = true,
    Callback = function(values)
        local entries = {}
        for _, label in pairs(type(values) == "table" and values or {}) do
            local key = tabs.hatching.deleteMap[label]
            if key then table.insert(entries, key) end
        end
        utils.remote("Egg", "AutoDeleteRequested", {Egg = utils.settings.farm.Egg, Entries = entries})
    end})
tabs.hatching.rarityDropdown = tabs.hatching:Dropdown({Title = "Select Rarities to Delete", Values = utils.sortedRarities(tabs.hatching.deleteRarityKeys), Value = tabs.hatching.deleteRarities, Multi = true, SearchBarEnabled = true,
    Callback = utils.deleteEggRarities})
utils.section(tabs.pets, "Team")
utils.dropdown(tabs.pets, "Select Team Focus", utils.settings.pets, "Team", {"Clicks", "Gems", "Luck"}, "Pets.Team")
utils.job(tabs.pets, "Auto Equip Best", "Team", 10, utils.equip)
utils.action(tabs.pets, "Equip Best", "Team", utils.equip)
utils.job(tabs.pets, "Auto Feed Treats", "Treats", 10, utils.feed)
utils.section(tabs.pets, "Auto Delete")
utils.rarities = {"Common", "Rare", "Epic", "Legendary", "Mythical", "Secret I", "Secret II", "Secret III", "Secret X"}
local deleteRarities = table.clone(utils.rarities)
table.insert(deleteRarities, 1, "All Rarities")
utils.multi(tabs.pets, "Select Rarities", utils.settings.pets, "Rarities", deleteRarities, "Pets.Rarities")
utils.multi(tabs.pets, "Select Variants", utils.settings.pets, "Tiers", {"All Variants", "Normal", "Golden", "Diamond", "Rainbow"}, "Pets.Variants")
tabs.pets.deleteNames = tabs.pets:Dropdown({Title = "Select Pets", Values = utils.inventoryPetNames(), Value = {}, Multi = true, SearchBarEnabled = true, Flag = "Pets.DeleteNames",
    Callback = function(values)
        table.clear(utils.settings.pets.Names)
        for _, name in pairs(type(values) == "table" and values or {}) do if type(name) == "string" then utils.settings.pets.Names[name] = true end end
    end})
utils.job(tabs.pets, "Auto Delete Pets", "Cleanup", 15, utils.sellPets)
utils.label(tabs.pets, "Cleanup")

tabs.crafting.petDropdowns = {}
function utils.petNames(tier)
    local names = {["All Pets"] = true}
    for _, pet in pairs(utils.save().Pets.Owned) do if pet.Tier == tier then names[pet.Name] = true end end
    return utils.keys(names)
end
for _, row in ipairs({{"Golden", "Golden", "Normal"}, {"Diamond", "Diamond", "Golden"}, {"Rainbow", "Shiny", "Diamond"}}) do
    local title, machine, tier = row[1], row[2], row[3]
    utils.section(tabs.crafting, title .. " Pets")
    if machine == "Shiny" then
        tabs.crafting:Dropdown({Title = "Select Time", Values = {"5h - 2 Pets", "2.5h - 3 Pets", "1h - 4 Pets", "30s - 5 Pets"}, Value = "30s - 5 Pets", Multi = false, Flag = "Craft.RainbowAmount",
            Callback = function(value) utils.settings.pets.RainbowCount = tonumber(value:match("(%d+) Pets")) or 5 end})
    else
        local choices, amounts = {}, {}
        for count, chance in ipairs(utils.modules.machines[machine].Chances) do
            local text = tostring(chance) .. "% (" .. tostring(count) .. " Pets)"
            table.insert(choices, text)
            amounts[text] = count
        end
        tabs.crafting:Dropdown({Title = "Select Chance", Values = choices, Value = choices[#choices], Multi = false, Flag = "Craft." .. title .. "Amount",
            Callback = function(value) utils.settings.pets[title .. "Count"] = amounts[value] or #choices end})
    end
    tabs.crafting.petDropdowns[tier] = utils.multi(tabs.crafting, "Select " .. title .. " Pets", utils.settings.pets, title .. "Pets", utils.petNames(tier), "Craft." .. title .. "Pets")
    utils.job(tabs.crafting, "Auto Craft " .. title, machine, 8, function() return utils.craft(machine) end)
    utils.label(tabs.crafting, machine)
end
utils.job(tabs.crafting, "Auto Collect Shiny Stars", "Stars", 5, utils.collectStars)

utils.section(tabs.enchanting, "Enchanting")
utils.multi(tabs.enchanting, "Select Enchants", utils.settings.enchant, "Traits", utils.keys(utils.modules.enchants.Enchants), "Enchant.Traits")
function utils.enchantPets()
    local data = utils.save()
    local rows, values, map = {}, {"Equipped Pets"}, {}
    local equipped = {}
    for _, id in pairs(data.Pets.Equipped or {}) do equipped[id] = true end
    for id, pet in pairs(data.Pets.Owned) do
        local tier = pet.Tier == "Shiny" and "Rainbow" or pet.Tier or "Normal"
        local label = pet.Name .. " | " .. tier
        if pet.Mutation then label ..= " | " .. pet.Mutation end
        label ..= " | " .. tostring(pet.Rarity or "Common") .. " | " .. tostring(id):sub(1, 8)
        if equipped[id] then label ..= " [Equipped]" end
        table.insert(rows, {Id = id, Label = label, Equipped = equipped[id] == true, Rank = utils.modules.rarity.GetRank(pet.Rarity)})
    end
    table.sort(rows, function(a, b)
        if a.Equipped ~= b.Equipped then return a.Equipped end
        if a.Rank ~= b.Rank then return a.Rank > b.Rank end
        return a.Label < b.Label
    end)
    for _, row in ipairs(rows) do
        table.insert(values, row.Label)
        map[row.Label] = row.Id
    end
    utils.enchantPetMap = map
    return values
end

function utils.selectEnchantPets(values)
    local settings = utils.settings.enchant
    settings.UseEquipped = false
    table.clear(settings.Pets)
    table.clear(settings.PetIds)
    for _, label in pairs(type(values) == "table" and values or {}) do
        if label == "Equipped Pets" then
            settings.UseEquipped = true
            settings.Pets[label] = true
        elseif type(label) == "string" then
            local id = utils.enchantPetMap[label]
            if not id then
                local prefix = label:match("| (%x%x%x%x%x%x%x%x)%s*")
                if prefix then
                    for ownedId in pairs(utils.save().Pets.Owned) do
                        if ownedId:sub(1, 8) == prefix then id = ownedId; break end
                    end
                end
            end
            if id then settings.PetIds[id] = true; settings.Pets[label] = true end
        end
    end
end

function utils.refreshEnchantPets(force)
    local values = utils.enchantPets()
    local signature = table.concat(values, "\n")
    if not force and signature == tabs.enchanting.petSignature then return end
    tabs.enchanting.petSignature = signature
    local selected = {}
    if utils.settings.enchant.UseEquipped then table.insert(selected, "Equipped Pets") end
    for _, label in ipairs(values) do
        local id = utils.enchantPetMap[label]
        if id and utils.settings.enchant.PetIds[id] then table.insert(selected, label) end
    end
    tabs.enchanting.petDropdown.Value = selected
    tabs.enchanting.petDropdown:Refresh(values)
end

tabs.enchanting.petDropdown = tabs.enchanting:Dropdown({Title = "Select Pets", Values = utils.enchantPets(), Value = {"Equipped Pets"}, Multi = true, SearchBarEnabled = true, Flag = "Enchant.Pets",
    Callback = utils.selectEnchantPets})
utils.action(tabs.enchanting, "Refresh Pet List", "Enchant", function() utils.refreshEnchantPets(true); return "Refreshed" end)
utils.job(tabs.enchanting, "Auto Enchant", "Enchant", 2, utils.enchant)
utils.label(tabs.enchanting, "Enchant")

utils.section(tabs.teleport, "Islands")
utils.settings.destination = {Island = "Spawn", OnJoin = false}
utils.islandNames = {"Spawn"}
for _, island in ipairs(utils.sortedIslands()) do table.insert(utils.islandNames, island.Name) end
utils.dropdown(tabs.teleport, "Select Island", utils.settings.destination, "Island", utils.islandNames, "Travel.Island")
function utils.teleport()
    assert(not utils.travel.Owner, "Character busy")
    utils.remote("Island", "Travel", {Island = utils.settings.destination.Island, Source = "Menu"})
    return utils.settings.destination.Island
end
utils.action(tabs.teleport, "Teleport", "Travel", utils.teleport)
tabs.teleport:Toggle({Title = "Teleport on Join", Value = false, Flag = "Travel.OnJoin", Callback = function(enabled)
    utils.settings.destination.OnJoin = enabled
    if enabled then runtime:Spawn(function() task.wait(1); if runtime.Alive and utils.settings.destination.OnJoin then pcall(utils.teleport) end end) end
end})
utils.label(tabs.teleport, "Travel")

utils.section(tabs.misc, "Minigames")
utils.job(tabs.misc, "Auto Colosseum", "Arena", 20, utils.colosseum, function()
    if utils.arena.Active then pcall(utils.remote, "Colosseum", "EndWaveDefense") end
    utils.arena.Active = false
end)
utils.job(tabs.misc, "Auto Memory Match", "Memory", 20, utils.memoryGame)
utils.job(tabs.misc, "Auto Dig", "Dig", 20, utils.digGame)
utils.label(tabs.misc, "Arena")
utils.label(tabs.misc, "Memory")
utils.label(tabs.misc, "Dig")
utils.section(tabs.misc, "Potions")
utils.multi(tabs.misc, "Select Potion Types", utils.settings.boosts, "Types", {"Coins", "Gems", "Luck", "OctoHatch", "GoldenHatch", "EnchantAnimSpeed"}, "Boosts.Types")
utils.job(tabs.misc, "Auto Use Potions", "Boosts", 15, utils.potions)
utils.dropdown(tabs.misc, "Select Potion", utils.settings.boosts, "Brew", utils.modules.brew.Potions, "Boosts.Brew")
utils.job(tabs.misc, "Auto Potion Machine", "Potions", 20, utils.potionMachine)
utils.dropdown(tabs.misc, "Select Potion Amount", utils.settings.boosts, "Bundle", {"1", "3", "10"}, "Boosts.Bundle")
utils.action(tabs.misc, "Buy Potions", "Potions", function()
    return utils.trip("Potions", workspace.Map1:FindFirstChild("PotionMachine"), function()
        utils.remote("PotionMachine", "Buy", tonumber(utils.settings.boosts.Bundle))
        return "Purchased"
    end)
end)
utils.section(tabs.misc, "Boosts")
utils.dropdown(tabs.misc, "Select Blessing", utils.settings.boosts, "Shrine", {"Luck", "Golden", "AutoClicker"}, "Boosts.Shrine")
utils.job(tabs.misc, "Auto Shrine", "Shrine", 30, utils.shrine)
utils.job(tabs.misc, "Auto Totems", "Totems", 30, utils.totems)
utils.relicNames = {"Automatic"}
for _, name in ipairs(utils.modules.relics.Order) do table.insert(utils.relicNames, name) end
utils.dropdown(tabs.misc, "Select Relic", utils.settings.boosts, "Relic", utils.relicNames, "Boosts.Relic")
utils.job(tabs.misc, "Auto Relic", "Relic", 20, utils.relic)

utils.section(tabs.webhook, "Settings")
tabs.webhook:Input({Title = "Webhook URL", Placeholder = "https://discord.com/api/webhooks/...", Callback = function(value) utils.settings.webhook.URL = value:match("^%s*(.-)%s*$") end})
tabs.webhook:Input({Title = "Discord User ID", Placeholder = "Discord User ID", Callback = function(value) utils.settings.webhook.UserId = value:match("^%d+$") or "" end})
tabs.webhook:Toggle({Title = "Show Roblox User", Value = false, Flag = "Webhook.ShowUser", Callback = function(value) utils.settings.webhook.ShowUser = value end})
utils.section(tabs.webhook, "Pet Webhook")
utils.multi(tabs.webhook, "Select Rarities", utils.settings.webhook, "Rarities", utils.rarities, "Webhook.Rarities")
utils.job(tabs.webhook, "Pet Webhook", "Webhook", 2, utils.sendLog, function() table.clear(utils.log.Queue) end)
utils.action(tabs.webhook, "Test Webhook", "Webhook", function()
    table.insert(utils.log.Queue, 1, utils.webhookPayload({{
        title = "🔔 Webhook Test",
        description = "Your webhook is working correctly!",
        color = 0x00FF00,
        fields = {
            {name = "👤 User", value = utils.settings.webhook.ShowUser and utils.player.Name or "Anonymous", inline = true},
            {name = "🎮 Game", value = "Tap Simulator Reborn", inline = true}
        },
        footer = {text = "Sent by Silence"},
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
    }}))
    utils.log.Next = 0
    return utils.sendLog()
end)
utils.label(tabs.webhook, "Webhook")

tabs.stats.labels = {}
for _, name in ipairs({"Global Rank", "Pet Power", "Click Power", "Rarest Hatch"}) do
    tabs.stats.labels[name] = tabs.stats:Paragraph({Title = name .. ": Loading"})
end
tabs.stats:Space()
for _, name in ipairs({"Total Coins", "Rebirth", "Eggs Hatched"}) do
    tabs.stats.labels[name] = tabs.stats:Paragraph({Title = name .. ": Loading"})
end
tabs.stats:Space()
utils.label(tabs.stats, "Session")
utils.label(tabs.stats, "Storage")
utils.label(tabs.stats, "Currency")
utils.action(tabs.stats, "Stop All", "Session", function() utils.stop(); return "Stopped" end)
utils.action(tabs.stats, "Unload Silence", "Session", function() runtime:Destroy(); return "Unloaded" end)
tabs.info:Paragraph({Title = "Made by xyzhenrik"})
tabs.info:Paragraph({Title = "Any issues? Create a Ticket on Discord"})
tabs.info:Paragraph({Title = "Official Discord: discord.gg/9eFf93Kg8D"})
tabs.info:Button({Title = "Copy Invite", Callback = function()
    local success = type(setclipboard) == "function" and pcall(setclipboard, "https://discord.gg/9eFf93Kg8D")
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = success and "Link Copied!" or "Error!",
            Text = success and "You can continue to Discord now." or "Clipboard not Supported.",
            Duration = 3
        })
    end)
end})
tabs.info:Space()
tabs.info:Section({Title = "Contributors:", TextSize = 17, Box = false})
tabs.info:Paragraph({Title = "- Henrik @xyzhenrik"})
tabs.info:Space()
tabs.info:Paragraph({Title = "Silence is Open-Source!"})
tabs.info:Space()
tabs.info.VersionLabel = tabs.info:Section({Title = "Tap Simulator Reborn [V1.0.0]", TextSize = 20, Box = false})
for _, label in ipairs(tabs.info.VersionLabel.ElementFrame:GetDescendants()) do
    if label:IsA("TextLabel") and label.Text == tabs.info.VersionLabel.Title then label.Font = Enum.Font.Arcade end
end

utils.configManager = silence.ConfigManager
utils.settings.config = {Name = "", Selected = nil}
function utils.configName()
    local name = utils.settings.config.Name:match("^%s*(.-)%s*$")
    if name == "" then name = utils.settings.config.Selected end
    assert(type(name) == "string" and #name > 0 and #name <= 48 and name:match("^[%w _%-]+$"), "Enter a valid configuration name")
    return name
end
function utils.refreshConfigs()
    local names = utils.configManager and utils.configManager:AllConfigs() or {}
    table.sort(names)
    if tabs.config.dropdown then tabs.config.dropdown:Refresh(names) end
    return names
end
tabs.config:Input({Title = "Configuration Name", Placeholder = "Configuration Name", Callback = function(value) utils.settings.config.Name = value end})
tabs.config.dropdown = tabs.config:Dropdown({Title = "Select Configuration", Values = utils.refreshConfigs(), Multi = false, SearchBarEnabled = true,
    Callback = function(value) utils.settings.config.Selected = value end})
utils.action(tabs.config, "Save Configuration", "Configuration", function()
    assert(utils.configManager, "Executor configuration files unavailable")
    local name = utils.configName()
    local config = utils.configManager:CreateConfig(name)
    config:Save()
    utils.settings.config.Selected = name
    utils.refreshConfigs()
    return "Saved " .. name
end)
utils.action(tabs.config, "Load Configuration", "Configuration", function()
    assert(utils.configManager, "Executor configuration files unavailable")
    local config = utils.configManager:CreateConfig(utils.configName())
    local result, reason = config:Load()
    assert(result ~= false, reason)
    return "Loaded"
end)
utils.action(tabs.config, "Delete Configuration", "Configuration", function()
    assert(utils.configManager, "Executor configuration files unavailable")
    local success, reason = utils.configManager:DeleteConfig(utils.configName())
    assert(success, reason)
    utils.refreshConfigs()
    return "Deleted"
end)
tabs.config:Toggle({Title = "Autoload Configuration", Value = false, Callback = function(enabled)
    if not utils.configManager or not utils.settings.config.Selected then return end
    local config = utils.configManager:CreateConfig(utils.settings.config.Selected)
    config:SetAutoLoad(enabled)
    config:Save()
end})
utils.action(tabs.config, "Refresh Configurations", "Configuration", utils.refreshConfigs)
utils.label(tabs.config, "Configuration")

runtime:Connect(utils.player.Idled, function()
    pcall(function()
        services.VirtualUser:CaptureController()
        services.VirtualUser:ClickButton2(Vector2.new())
    end)
end)
runtime:Connect(utils.player.CharacterAdded, function()
    utils.travel.Owner, utils.travel.Origin = nil, nil
    utils.hatch.LastEgg = nil
    table.clear(utils.hatch.Pending)
end)
runtime:AddCleanup(function()
    utils.hideClicks(false)
    utils.hideHatch(false)
    for _, job in pairs(utils.jobs) do
        job.Enabled = false
        if job.Cleanup then pcall(job.Cleanup) end
    end
    if utils.travel.Origin then pcall(function() local root = utils.character(); root.CFrame = utils.travel.Origin end) end
    for name, value in pairs(utils.originals) do pcall(utils.remote, "Settings", "UpdateSetting", {Name = name, Value = value.Value}) end
end)
runtime:Spawn(function()
    local deadline
    while runtime.Alive do
        local job = utils.jobs.Tap
        if job.Enabled then
            deadline = deadline or os.clock()
            local success, result = pcall(job.Callback)
            utils.identityReset()
            if not success then utils.message("Tap", result) end
            deadline += job.Interval
            if deadline < os.clock() then deadline = os.clock() + job.Interval end
            task.wait(math.max(0, deadline - os.clock()))
        else
            deadline = nil
            task.wait(0.05)
        end
    end
end)
runtime:Spawn(function()
    while runtime.Alive do
        local now = os.clock()
        for key, job in pairs(utils.jobs) do
            if key ~= "Tap" and job.Enabled and not job.Busy and now >= job.Next then
                job.Busy = true
                runtime:Spawn(function()
                    local success, result = pcall(job.Callback)
                    utils.identityReset()
                    job.Busy = false
                    job.Next = os.clock() + math.max(0.1, job.Interval)
                    if job.Enabled then utils.message(key, success and (result or "Active") or result) end
                end)
            end
        end
        task.wait(0.05)
    end
end)
runtime:Spawn(function()
    local buttons
    while runtime.Alive do
        local data = utils.save()
        utils.refreshEnchantPets()
        utils.updateStats(data)
        utils.message("Session", utils.modules.profileStats.FormatDuration(os.clock() - utils.started) .. " | " .. utils.formatNumber(utils.hatch.Count) .. " hatches")
        utils.message("Storage", utils.formatNumber(utils.count(data.Pets.Owned)) .. "/" .. utils.formatNumber(data.Pets.StorageLimit))
        utils.message("Currency", utils.formatNumber(data.Currencies.Coins) .. " coins | " .. utils.formatNumber(data.Currencies.Gems) .. " gems")
        if buttons ~= data.Upgrades.RebirthButtons then buttons = data.Upgrades.RebirthButtons; utils.refreshRebirths() end
        task.wait(2)
    end
end)
runtime:Spawn(function()
    while runtime.Alive do
        for tier, control in pairs(tabs.crafting.petDropdowns) do control:Refresh(utils.petNames(tier)) end
        tabs.pets.deleteNames:Refresh(utils.inventoryPetNames())
        task.wait(10)
    end
end)
if utils.configManager then
    for _, name in ipairs(utils.refreshConfigs()) do utils.configManager:CreateConfig(name) end
end

return utils, silence
