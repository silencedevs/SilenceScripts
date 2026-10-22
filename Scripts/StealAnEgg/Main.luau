local services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = workspace,
    RunService = game:GetService("RunService"),
    TweenService = game:GetService("TweenService"),
    PathfindingService = game:GetService("PathfindingService"),
    UserInputService = game:GetService("UserInputService"),
    ProximityPromptService = game:GetService("ProximityPromptService"),
    TeleportService = game:GetService("TeleportService"),
    HttpService = game:GetService("HttpService"),
    CollectionService = game:GetService("CollectionService"),
    StarterGui = game:GetService("StarterGui"),
    Lighting = game:GetService("Lighting"),
    SoundService = game:GetService("SoundService")
}

if _G.SilenceStealAnEggRuntime then _G.SilenceStealAnEggRuntime:Destroy() end
local runtime = {Alive = true, Threads = {}, Connections = {}, Cleanups = {}}
_G.SilenceStealAnEggRuntime = runtime

function runtime:Spawn(callback)
    if not self.Alive then return end
    local thread
    thread = coroutine.create(function()
        local success, result = pcall(callback)
        self.Threads[thread] = nil
        if not success then self.LastError = result end
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
    if _G.SilenceStealAnEggRuntime == self then _G.SilenceStealAnEggRuntime = nil end
end

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/silencedevs/SilenceScripts/refs/heads/main/libraries/windui/windui.luau"))()
local desktop = services.UserInputService.KeyboardEnabled and services.UserInputService.MouseEnabled
local silence = WindUI:CreateWindow({
    Title = "Silence - Steal An Egg",
    Author = "by Henrik @xyzhenrik",
    Icon = "solar:moon-bold",
    IconSize = 26,
    Theme = "Crimson",
    NewElements = true,
    TopBarButtonIconSize = desktop and 24 or 16,
    Size = UDim2.fromOffset(560, 620),
    Folder = "Silence/StealAnEgg/" .. tostring(services.Players.LocalPlayer.UserId),
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

local utils = {
    player = services.Players.LocalPlayer,
    identity = type(getthreadidentity) == "function" and getthreadidentity() or 8,
    modules = {},
    jobs = {},
    controls = {},
    status = {},
    selection = {Cooldowns = {}},
    markers = {},
    originals = setmetatable({}, {__mode = "k"}),
    route = 0,
    pipeline = {Keys = {Steal = true, Place = true, Hatch = true}, Requests = {}, Next = {}, PendingHatches = {}, Owner = nil, Generation = 0},
    navigation = {Zones = setmetatable({}, {__mode = "k"}), Folder = nil, Speed = nil, Restarts = 0},
    started = os.clock(),
    settings = {
        eggs = {Priority = "Closest", Rarities = {}, Areas = {}, Mutations = {}, Species = {}, Specific = {}, TargetAreas = {}, MinRarity = "Any", MinWeight = 0, MinValue = 0, SafeZone = false, AntiGuard = true, NightWait = true, Index = false, Lab = false},
        travel = {Mode = "Tween", Speed = 120},
        place = {Mode = "Always", Order = "Highest Value", Rarities = {}, Mutations = {}, Specific = {}, MinWeight = 0, MinValue = 0, Spacing = 6},
        hatch = {Delay = 1},
        treadmill = {MaxLevel = 100},
        pets = {Interval = 5},
        sell = {
            Pets = {Rule = "Rarity And Value", MaxRarity = "Epic", Value = 0, KeepMutated = true, Blacklist = {}, Unequip = false},
            Eggs = {Rule = "Rarity And Value", MaxRarity = "Epic", Value = 0, KeepMutated = true, Blacklist = {}, ProtectHalloween = true},
            Lab = {Rule = "Rarity And Value", MaxRarity = "Off", Value = 0, KeepMutated = true, KeepPets = {}},
            KeepBest = 1
        },
        fuse = {MaxRarity = "Epic", Species = {}, SkipMutated = true, EjectIncomplete = false, Priority = "Best Rarity"},
        favorite = {Rule = "Match All", MinRarity = "Off", Mutations = {}, Value = 0, Always = {}},
        mutation = {Targets = {}, Mutations = {}, MinRarity = "Any", MinValue = 0, Priority = "Highest Value", BuyNitro = false},
        halloween = {
            Speed = 40, Priority = "Value", Rarities = {}, Species = {}, Zones = {}, MinValue = 0,
            MonsterKinds = {}, MonsterOrder = "Closest", MonsterSpeed = 300,
            Pumpkin = true, BuyEgg = false, CastLuck = "x1.5 Perfect"
        },
        train = {Vacuum = true, Speed = 300, TradeSouls = false},
        lab = {Reroll = false, Banners = {}},
        butterfly = {Priority = "Rarest", Species = {}, Speed = 320, TradeUp = false, Essence = false},
        capture = {Auto = false, Take = true, Height = 45, KeepAway = 45},
        race = {Shop = {}, Reserve = 0, Racer = "Best Owned"},
        trails = {Selected = {}},
        mastery = {Shop = {}, Reserve = 0, MinWeight = 0},
        lightDark = {Team = "Light"},
        visuals = {Eggs = false, OwnBase = true, OtherBase = false, Guards = false, Players = false, Distance = 1000, MinRarity = "Any", MinValue = 0, Info = {}, Size = 75, Highlight = true, Rarities = {}, Mutations = {}},
        player = {Speed = 18, JumpPower = 50, SpeedEnabled = false, JumpEnabled = false, AntiRagdoll = false, AntiVoid = false, AntiTrap = false, InfiniteJump = false, InstantPrompts = false, Invisibility = false},
        combat = {Mode = "Off", Target = "", Speed = 400, MaxSpeed = 750, Lead = -275, Sweep = 60},
        server = {Mode = "Least Players", Delay = 5, Target = "", Visited = {[game.JobId] = true}, AutoRejoin = false},
        hop = {Mode = "Steal Then Hop", Rare = "Cosmic", Sync = true, MinRarity = "Any", Areas = {}, Specific = {}, Rarities = {}, MinValue = 0, Delay = 5},
        performance = {FpsCap = 240, Disable3D = false, Background = "White", Optimizer = false, AntiAfk = false, HideGameUi = false}
    }
}
local tabs = {
    farm = silence:Tab({Title = "Farm", Icon = "lucide:egg", Border = true}),
    automation = silence:Tab({Title = "Automation", Icon = "lucide:bot", Border = true}),
    inventory = silence:Tab({Title = "Inventory", Icon = "lucide:package", Border = true}),
    events = silence:Tab({Title = "Events", Icon = "lucide:sparkles", Border = true}),
    minigames = silence:Tab({Title = "Minigames", Icon = "lucide:gamepad-2", Border = true}),
    esp = silence:Tab({Title = "ESP", Icon = "lucide:eye", Border = true}),
    character = silence:Tab({Title = "Character", Icon = "lucide:person-standing", Border = true}),
    combat = silence:Tab({Title = "Combat", Icon = "lucide:swords", Border = true}),
    server = silence:Tab({Title = "Servers", Icon = "lucide:server", Border = true}),
    misc = silence:Tab({Title = "Misc", Icon = "lucide:settings", Border = true}),
    config = silence:Tab({Title = "Configuration", Icon = "lucide:save", Border = true}),
    info = silence:Tab({Title = "About", Icon = "lucide:info", Border = true})
}
tabs.farm:Select()

function utils.identityReset()
    if type(setthreadidentity) == "function" then setthreadidentity(utils.identity) end
end

function utils.call(callback, ...)
    local result = table.pack(pcall(callback, ...))
    utils.identityReset()
    if not result[1] then error(tostring(result[2]), 0) end
    return table.unpack(result, 2, result.n)
end

function utils.safeRequire(path)
    local success, result = pcall(require, path)
    utils.identityReset()
    if success and type(result) == "table" then return result end
end

function utils.load(name, module)
    local success, result = pcall(require, module)
    utils.identityReset()
    if success then utils.modules[name] = result end
    return success
end

function utils.message(key, message)
    utils.status[key] = tostring(message or "")
    local control = utils.controls[key]
    if control and control.SetTitle then control:SetTitle(key .. ": " .. utils.status[key]) end
end

function utils.label(tab, key, text)
    utils.controls[key] = tab:Paragraph({Title = key .. ": " .. tostring(text or "Idle")})
    utils.status[key] = tostring(text or "Idle")
    return utils.controls[key]
end

function utils.section(tab, text)
    tab:Section({Title = text, TextSize = 22, Box = false, TextXAlignment = "Center"})
end

function utils.job(tab, text, key, interval, callback, cleanup)
    utils.jobs[key] = {Enabled = false, Generation = 0, Busy = false, Callback = callback, Interval = interval}
    utils.controls[key .. "Switch"] = tab:Toggle({
        Title = text, Value = false, Flag = "Enabled." .. key,
        Callback = function(enabled)
            local job = utils.jobs[key]
            if not job then return end
            job.Enabled = enabled
            job.Generation += 1
            if utils.pipeline.Keys[key] then
                utils.pipeline.Next[key] = 0
                if not enabled and utils.pipeline.Owner == key then utils.cancelPipeline() end
                if not enabled then utils.pipeline.Requests[key] = nil end
                utils.message(key, enabled and "Queued" or "Off")
                return
            end
            if not enabled then
                if job.Thread and coroutine.status(job.Thread) ~= "dead" then
                    pcall(task.cancel, job.Thread)
                    runtime.Threads[job.Thread] = nil
                end
                job.Thread = nil
                job.Busy = false
                if utils.featureOwner == key then utils.featureOwner = nil end
                if cleanup then pcall(cleanup) end
                utils.message(key, "Off")
                return
            end
            utils.message(key, "Starting")
            job.Thread = runtime:Spawn(function()
                local generation = job.Generation
                while runtime.Alive and job.Enabled and job.Generation == generation do
                    if not job.Busy then
                        if utils.featureOwner and utils.featureOwner ~= key then
                            utils.message(key, "Waiting for " .. utils.featureOwner)
                        else
                            job.Busy = true
                            utils.featureOwner = key
                            local success, result = pcall(callback)
                            utils.identityReset()
                            if utils.featureOwner == key then utils.featureOwner = nil end
                            job.Busy = false
                            if not success then utils.message(key, tostring(result))
                            elseif result ~= nil then utils.message(key, result) end
                        end
                    end
                    task.wait(math.max(0.25, type(interval) == "function" and interval() or interval))
                end
            end)
        end
    })
    return utils.controls[key .. "Switch"]
end

function utils.action(tab, text, key, callback)
    return tab:Button({Title = text, Callback = function()
        if utils.pipeline.Keys[key] then
            utils.pipeline.Requests[key] = callback
            utils.message(key, "Queued")
            return
        end
        if utils.jobs[key] and utils.jobs[key].Busy then utils.message(key, "Already running"); return end
        utils.jobs[key] = utils.jobs[key] or {}
        utils.jobs[key].Busy = true
        utils.message(key, "Working")
        utils.jobs[key].Thread = runtime:Spawn(function()
            local success, result = pcall(callback)
            utils.identityReset()
            utils.jobs[key].Busy = false
            if not success then
                utils.message(key, tostring(result))
                WindUI:Notify({Title = text, Content = tostring(result), Duration = 4})
            elseif result ~= nil then utils.message(key, result) end
        end)
    end})
end

function utils.toggle(tab, text, settings, key, flag)
    local control
    control = tab:Toggle({Title = text, Value = settings[key] == true, Flag = flag, Callback = function(enabled)
        settings[key] = enabled
    end})
    return control
end

function utils.slider(tab, text, settings, key, min, max, step, flag)
    local control = tab:Slider({
        Title = text,
        Value = {Min = min, Max = max, Default = settings[key], Step = step or 1},
        Flag = flag,
        Callback = function(value) settings[key] = value end
    })
    return control
end

function utils.dropdown(tab, text, settings, key, values, flag, mapper)
    if #values == 0 then values = {"None"} end
    return tab:Dropdown({
        Title = text, Values = values, Value = settings[key], Multi = false,
        SearchBarEnabled = #values > 8, Flag = flag,
        Callback = function(value) settings[key] = mapper and mapper(value) or value end
    })
end

function utils.number(tab, text, settings, key, flag)
    local apply = function(value)
        if tostring(value):match("^%s*$") then settings[key] = 0; return end
        local number, suffix = tostring(value):lower():gsub(",", ""):match("^%s*(%d*%.?%d+)%s*([kmbtq]?)%s*$")
        if not number then utils.message("Input", text .. ": enter a non-negative number"); return end
        number = tonumber(number) * (({k = 1e3, m = 1e6, b = 1e9, t = 1e12, q = 1e15})[suffix] or 1)
        if number >= math.huge then utils.message("Input", text .. ": value is too large"); return end
        settings[key] = number
    end
    return tab:Input({
        Title = text, Value = settings[key] ~= 0 and tostring(settings[key]) or "",
        Placeholder = "0 = off", Flag = flag,
        Callback = apply
    })
end

function utils.textSet(tab, text, settings, key, flag)
    local function serialize()
        return table.concat(utils.keys(settings[key] or {}), ", ")
    end
    return tab:Input({
        Title = text,
        Value = serialize(),
        Placeholder = "Category1, Category2 (empty = all)",
        Flag = flag,
        Callback = function(value)
            table.clear(settings[key])
            for raw in tostring(value):gmatch("[^,]+") do
                local name = raw:match("^%s*(.-)%s*$")
                if name ~= "" then
                    settings[key][utils.normalizeCategory(name)] = true
                end
            end
        end
    })
end

function utils.normalizeCategory(name)
    local exact = utils.options.CategoryByLower and utils.options.CategoryByLower[tostring(name):lower()]
    return exact or tostring(name)
end

function utils.multi(tab, text, settings, key, values, flag)
    if #values == 0 then values = {"None"} end
    local selected = {}
    for name, enabled in pairs(settings[key] or {}) do if enabled then table.insert(selected, name) end end
    return tab:Dropdown({
        Title = text, Values = values, Value = selected, Multi = true,
        SearchBarEnabled = #values > 8, Flag = flag,
        Callback = function(value)
            table.clear(settings[key])
            if type(value) == "table" then
                for _, name in pairs(value) do
                    if type(name) == "string" and table.find(values, name) then settings[key][name] = true end
                end
            end
        end
    })
end

function utils.keys(tableValue)
    local keys = {}
    for key in pairs(tableValue) do table.insert(keys, key) end
    table.sort(keys)
    return keys
end

function utils.matches(selection, value)
    return next(selection) == nil or selection[value] == true
end

function utils.mutated(selection, row)
    if next(selection) == nil then return true end
    local mutations = row.Mutations
    local values = {}
    if type(mutations) == "table" then
        for name, enabled in pairs(mutations) do
            if type(name) == "string" and enabled ~= false then table.insert(values, name)
            elseif type(enabled) == "string" then table.insert(values, enabled) end
        end
    elseif type(mutations) == "string" then
        for name in mutations:gmatch("[^,]+") do table.insert(values, name:match("^%s*(.-)%s*$")) end
    end
    if row.BaseMutation and selection[row.BaseMutation] then return true end
    for _, name in ipairs(values) do if selection[name] then return true end end
    return selection.Normal == true and (not row.BaseMutation or row.BaseMutation == "Normal") and #values == 0
end

function utils.character()
    local character = utils.player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if humanoid and root and humanoid.Health > 0 then return character, humanoid, root end
end

function utils.net(path, ...)
    local packages = services.ReplicatedStorage:FindFirstChild("Packages")
    local networking = packages and packages:FindFirstChild("Networking")
    local remote = networking and networking:FindFirstChild(path)
    assert(remote, path .. " is unavailable")
    if remote:IsA("RemoteFunction") then
        local response = table.pack(utils.call(function(...) return remote:InvokeServer(...) end, ...))
        if response[1] == false then error(tostring(response[2] or "Request rejected"), 0) end
        return table.unpack(response, 1, response.n)
    end
    remote:FireServer(...)
    return true
end

function utils.remote(group, name, ...)
    local remote = utils.modules.remotes and utils.modules.remotes[group] and utils.modules.remotes[group][name]
    if not remote then
        local packages = services.ReplicatedStorage:FindFirstChild("Packages")
        local networking = packages and packages:FindFirstChild("Networking")
        remote = networking and (networking:FindFirstChild("RF/" .. group .. "/" .. name) or networking:FindFirstChild("RE/" .. group .. "/" .. name))
    end
    assert(remote, group .. "." .. name .. " is unavailable")
    if remote:IsA("RemoteFunction") then
        local response = table.pack(utils.call(function(...) return remote:InvokeServer(...) end, ...))
        if response[1] == false then error(tostring(response[2] or "Request rejected"), 0) end
        return table.unpack(response, 1, response.n)
    end
    remote:FireServer(...)
    return true
end

function utils.save()
    return utils.modules.save and utils.call(utils.modules.save.Peek) or {}
end

function utils.plot()
    local slot = utils.call(utils.modules.plots.ResolveLocalSlot)
    local folder = services.Workspace:FindFirstChild("Plots")
    return slot and folder and folder:FindFirstChild(tostring(slot))
end

function utils.stop()
    utils.route += 1
    utils.moving = false
    if utils.navigation.Humanoid and utils.navigation.Speed then
        pcall(function() utils.navigation.Humanoid.WalkSpeed = utils.navigation.Speed end)
    end
    if utils.navigation.Humanoid and utils.navigation.Jump then
        pcall(function()
            utils.navigation.Humanoid.JumpPower = utils.navigation.Jump.Power
            utils.navigation.Humanoid.UseJumpPower = utils.navigation.Jump.Enabled
        end)
    end
    utils.navigation.Humanoid = nil
    utils.navigation.Speed = nil
    utils.navigation.Jump = nil
    if utils.navigation.InputEnabled and utils.navigation.Controls then pcall(function() utils.navigation.Controls:Enable() end) end
    utils.navigation.InputEnabled = nil
    if utils.navigation.Connection then utils.navigation.Connection:Disconnect(); utils.navigation.Connection = nil end
    if utils.navigation.Path then utils.navigation.Path:Destroy(); utils.navigation.Path = nil end
    if utils.tween then utils.tween:Cancel(); utils.tween = nil end
    local _, humanoid, root = utils.character()
    if humanoid and root then humanoid:MoveTo(root.Position) end
end

function utils.cancelPipeline()
    utils.pipeline.Generation += 1
    utils.stop()
    if utils.pipeline.Thread and coroutine.status(utils.pipeline.Thread) ~= "dead" then
        pcall(task.cancel, utils.pipeline.Thread)
        runtime.Threads[utils.pipeline.Thread] = nil
    end
    if utils.pipeline.Owner and utils.jobs[utils.pipeline.Owner] then utils.jobs[utils.pipeline.Owner].Busy = false end
    utils.pipeline.Thread = nil
    utils.pipeline.Owner = nil
    utils.featureOwner = nil
end

function utils.pendingWork()
    local work = {Place = 0, Hatch = 0}
    for uid, row in pairs(utils.call(utils.modules.eggs.ReadOwnerEggs, utils.player.UserId)) do
        if utils.pipeline.PendingHatches[uid] or (row.Placement and utils.call(utils.modules.eggs.IsReadyToHatch, uid)) then work.Hatch += 1 end
        if not row.Placement then
            local info = utils.eggInfo(uid, row)
            if info and utils.matches(utils.settings.place.Rarities, info.Rarity)
                and utils.mutated(utils.settings.place.Mutations, row)
                and info.Weight >= utils.settings.place.MinWeight
                and (utils.settings.place.MinValue <= 0 or info.Income >= utils.settings.place.MinValue) then work.Place += 1 end
        end
    end
    return work
end

function utils.nextPipelineJob()
    if utils.pipeline.Owner or utils.moving then return end
    for _, key in ipairs({"Hatch", "Place", "Steal"}) do
        if utils.pipeline.Requests[key] then return key, utils.pipeline.Requests[key] end
    end
    if not (utils.jobs.Steal.Enabled or utils.jobs.Place.Enabled or utils.jobs.Hatch.Enabled) then return end
    if utils.call(utils.modules.eggs.ReadCarryState).IsCarrying then return "Steal", utils.jobs.Steal.Callback end
    local work = utils.pendingWork()
    for _, key in ipairs({"Hatch", "Place"}) do
        if utils.jobs[key].Enabled and work[key] > 0 then
            if os.clock() >= (utils.pipeline.Next[key] or 0) then return key, utils.jobs[key].Callback end
            return
        end
    end
    if utils.jobs.Steal.Enabled and os.clock() >= (utils.pipeline.Next.Steal or 0) then return "Steal", utils.jobs.Steal.Callback end
end

function utils.pipelineStep()
    local key, callback = utils.nextPipelineJob()
    if not key then return end
    utils.pipeline.Requests[key] = nil
    utils.pipeline.Owner = key
    utils.jobs[key].Busy = true
    utils.featureOwner = key
    local generation = utils.pipeline.Generation
    utils.pipeline.Thread = runtime:Spawn(function()
        local success, result = pcall(callback)
        utils.identityReset()
        if utils.pipeline.Generation ~= generation then return end
        if utils.featureOwner == key then utils.featureOwner = nil end
        utils.jobs[key].Busy = false
        utils.pipeline.Owner = nil
        utils.pipeline.Thread = nil
        utils.pipeline.Next[key] = os.clock() + (success and 0.5 or 3)
        if result ~= nil then utils.message(key, tostring(result)) end
    end)
end

function utils.avoid(instance)
    if not instance or not instance.Parent then return end
    if not instance:IsA("Model") and not instance:IsA("BasePart") then return end
    local frame, size
    if instance:IsA("Model") then frame, size = instance:GetBoundingBox()
    else frame, size = instance.CFrame, instance.Size end
    local zone = utils.navigation.Zones[instance]
    if not zone or not zone.Parent then
        zone = Instance.new("Part")
        zone.Name = "Avoid"
        zone.Anchored = true
        zone.CanCollide = false
        zone.CanTouch = false
        zone.CanQuery = false
        zone.Transparency = 1
        local modifier = Instance.new("PathfindingModifier")
        modifier.Label = "Avoid"
        modifier.Parent = zone
        zone.Parent = utils.navigation.Folder
        utils.navigation.Zones[instance] = zone
    end
    zone.Size = Vector3.new(size.X + 3, math.max(14, size.Y + 4), size.Z + 3)
    zone.CFrame = frame
end

function utils.refreshAvoidance()
    if not utils.navigation.Folder then
        utils.navigation.Folder = Instance.new("Folder")
        utils.navigation.Folder.Name = "ClientNav"
        utils.navigation.Folder.Parent = services.Workspace
    end
    for source, zone in pairs(utils.navigation.Zones) do
        if not source.Parent then zone:Destroy(); utils.navigation.Zones[source] = nil end
    end
    local plots = services.Workspace:FindFirstChild("Plots")
    for _, plot in ipairs(plots and plots:GetChildren() or {}) do
        for _, name in ipairs({"TreadmillBottom", "TreadmillUpgrade", "PlotUpgrade"}) do utils.avoid(plot:FindFirstChild(name)) end
    end
    local renders = services.Workspace:FindFirstChild("__ClientTreadmillRenders")
    for _, model in ipairs(renders and renders:GetChildren() or {}) do utils.avoid(model) end
    local stands = services.Workspace:FindFirstChild("Stands")
    local models = stands and stands:FindFirstChild("Models")
    for _, model in ipairs(models and models:GetChildren() or {}) do utils.avoid(model) end
end

function utils.segmentAvoided(from, destination)
    for _, zone in pairs(utils.navigation.Zones) do
        if zone.Parent then
            local origin = zone.CFrame:PointToObjectSpace(from)
            local delta = zone.CFrame:VectorToObjectSpace(destination - from)
            local half = zone.Size / 2
            local ending = origin + delta
            if math.abs(origin.X) <= half.X and math.abs(origin.Y) <= half.Y and math.abs(origin.Z) <= half.Z
                and (math.abs(ending.X) > half.X or math.abs(ending.Y) > half.Y or math.abs(ending.Z) > half.Z) then continue end
            local entry, exit = 0, 1
            for _, axis in ipairs({"X", "Y", "Z"}) do
                if math.abs(delta[axis]) < 0.0001 then
                    if math.abs(origin[axis]) > half[axis] then entry = 2; break end
                else
                    local a, b = (-half[axis] - origin[axis]) / delta[axis], (half[axis] - origin[axis]) / delta[axis]
                    entry, exit = math.max(entry, math.min(a, b)), math.min(exit, math.max(a, b))
                    if entry > exit then break end
                end
            end
            if entry <= exit and exit >= 0 and entry <= 1 then return true end
        end
    end
    return false
end

function utils.detour(from, destination, route, height, params)
    if Vector3.new(destination.X - from.X, 0, destination.Z - from.Z).Magnitude > 180 then return end
    local overlap = OverlapParams.new()
    overlap.FilterType = params.FilterType
    overlap.FilterDescendantsInstances = params.FilterDescendantsInstances
    overlap.RespectCanCollide = true
    local samples = {}
    local function sample(x, z)
        local key = x .. ":" .. z
        if samples[key] ~= nil then return samples[key] end
        local point = from + Vector3.new(x * 4, 0, z * 4)
        local hit = services.Workspace:Raycast(point + Vector3.new(0, 12, 0), Vector3.new(0, -40, 0), params)
        if not hit then samples[key] = false; return false end
        point = Vector3.new(point.X, hit.Position.Y + height, point.Z)
        if utils.segmentAvoided(point, point + Vector3.new(0, 0.1, 0))
            or #services.Workspace:GetPartBoundsInBox(CFrame.new(point), Vector3.new(2, 3.5, 2), overlap) > 0 then
            samples[key] = false
            return false
        end
        samples[key] = point
        return point
    end
    local function clear(a, b)
        return math.abs(a.Y - b.Y) <= 3 and not utils.segmentAvoided(a, b)
            and not services.Workspace:Blockcast(CFrame.new(a), Vector3.new(2, 3.5, 2), b - a, params)
    end
    local open = {{Key = "0:0", X = 0, Z = 0, Point = from, Cost = 0, Score = (destination - from).Magnitude}}
    local best = {["0:0"] = 0}
    local closed = {}
    for iteration = 1, 3500 do
        if not runtime.Alive or utils.route ~= route or #open == 0 then return end
        local lowest = 1
        for index = 2, #open do if open[index].Score < open[lowest].Score then lowest = index end end
        local current = table.remove(open, lowest)
        if closed[current.Key] then continue end
        closed[current.Key] = true
        if (destination - current.Point).Magnitude <= 6 and clear(current.Point, destination) then
            local points = {destination}
            while current.Parent do table.insert(points, 1, current.Point); current = current.Parent end
            return points
        end
        for _, offset in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}, {1, 1}, {-1, -1}, {1, -1}, {-1, 1}}) do
            local x, z = current.X + offset[1], current.Z + offset[2]
            if math.abs(x) > 60 or math.abs(z) > 60 then continue end
            local key = x .. ":" .. z
            if closed[key] then continue end
            local point = sample(x, z)
            if point and clear(current.Point, point) then
                local cost = current.Cost + (point - current.Point).Magnitude
                if cost < (best[key] or math.huge) then
                    best[key] = cost
                    table.insert(open, {Key = key, X = x, Z = z, Point = point, Parent = current, Cost = cost, Score = cost + (destination - point).Magnitude})
                end
            end
        end
        if iteration % 50 == 0 then task.wait() end
    end
end

function utils.safeWaypoints(waypoints, from, route, height, params)
    for _ = 1, 8 do
        local previous = from
        local unsafe
        for index, waypoint in ipairs(waypoints) do
            local point = waypoint.Position + Vector3.new(0, height, 0)
            if utils.segmentAvoided(previous, point) then unsafe = index; break end
            previous = point
        end
        if not unsafe then return waypoints end
        local exit = unsafe
        while exit <= #waypoints do
            local point = waypoints[exit].Position + Vector3.new(0, height, 0)
            if not utils.segmentAvoided(point, point + Vector3.new(0, 0.1, 0)) then break end
            exit += 1
        end
        if exit > #waypoints then return end
        local points = utils.detour(previous, waypoints[exit].Position + Vector3.new(0, height, 0), route, height, params)
        if not points then return end
        local replacement = {}
        for index = 1, unsafe - 1 do table.insert(replacement, waypoints[index]) end
        for _, point in ipairs(points) do table.insert(replacement, {Position = point - Vector3.new(0, height, 0), Action = Enum.PathWaypointAction.Walk}) end
        for index = exit + 1, #waypoints do table.insert(replacement, waypoints[index]) end
        waypoints = replacement
    end
end

function utils.path(point, route)
    local character, humanoid, root = utils.character()
    assert(root, "Wait for your character to respawn")
    utils.refreshAvoidance()
    utils.navigation.Target = point
    local height = humanoid.HipHeight + root.Size.Y / 2
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character, utils.navigation.Folder, utils.visualFolder}
    params.RespectCanCollide = true
    for attempt = 1, 4 do
        if not runtime.Alive or utils.route ~= route then return false end
        local path = services.PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = attempt > 1, WaypointSpacing = 3, Costs = {Avoid = math.huge}})
        local computed = pcall(function() path:ComputeAsync(root.Position, point) end)
        local retry = not computed or path.Status ~= Enum.PathStatus.Success
        utils.navigation.Reason = retry and "No path" or nil
        if not retry then
            local waypoints = utils.safeWaypoints(path:GetWaypoints(), root.Position, route, height, params)
            if not waypoints then
                retry = true
                utils.navigation.Reason = "No safe detour"
            else
                local smooth, previous, index = {}, root.Position, 1
                while index <= #waypoints do
                    local selected = index
                    for nextIndex = index + 1, math.min(index + 20, #waypoints) do
                        if waypoints[nextIndex - 1].Action == Enum.PathWaypointAction.Jump or waypoints[nextIndex].Action == Enum.PathWaypointAction.Jump then break end
                        local target = waypoints[nextIndex].Position + Vector3.new(0, height, 0)
                        if math.abs(target.Y - previous.Y) > 3 or utils.segmentAvoided(previous, target)
                            or services.Workspace:Blockcast(CFrame.new(previous), Vector3.new(2, 3.5, 2), target - previous, params) then break end
                        selected = nextIndex
                    end
                    table.insert(smooth, waypoints[selected])
                    previous = waypoints[selected].Position + Vector3.new(0, height, 0)
                    index = selected + 1
                end
                waypoints = smooth
            end
            local index, blocked = 1, false
            local connection = path.Blocked:Connect(function(obstacle) if obstacle >= index then blocked = true end end)
            utils.navigation.Connection = connection
            utils.navigation.Path = path
            for waypointIndex, waypoint in ipairs(waypoints or {}) do
                index = waypointIndex
                if not runtime.Alive or utils.route ~= route or utils.player.Character ~= character then break end
                local target = waypoint.Position + Vector3.new(0, height, 0)
                utils.navigation.Waypoint = target
                local best, progress = math.huge, os.clock()
                local started = os.clock()
                if utils.segmentAvoided(root.Position, target) then utils.navigation.Reason = "Unsafe segment"; retry = true; break end
                if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
                humanoid:MoveTo(waypoint.Position)
                while true do
                    if not runtime.Alive or utils.route ~= route or utils.player.Character ~= character then break end
                    local offset = target - root.Position
                    local distance = Vector3.new(offset.X, 0, offset.Z).Magnitude
                    if distance <= 2.5 and math.abs(offset.Y) <= 5 then break end
                    if utils.settings.travel.Mode == "Walk" then
                        local speed = utils.settings.player.SpeedEnabled and math.min(utils.settings.player.Speed, 50) or math.min(utils.settings.travel.Speed, 50)
                        humanoid.WalkSpeed = math.min(speed, math.max(16, distance * 8))
                    elseif utils.settings.travel.Mode ~= "Walk" and waypoint.Action ~= Enum.PathWaypointAction.Jump then
                        local step = math.min(offset.Magnitude, utils.settings.travel.Mode == "Step" and 4 or utils.settings.travel.Speed * 0.03)
                        local delta = offset.Magnitude > 0 and offset.Unit * step or Vector3.zero
                        if utils.segmentAvoided(root.Position, root.Position + delta)
                            or services.Workspace:Blockcast(CFrame.new(root.Position), Vector3.new(2, 3.5, 2), delta, params) then retry = true; break end
                        character:PivotTo(character:GetPivot() + delta)
                        root.AssemblyLinearVelocity = Vector3.zero
                    end
                    if distance < best - 0.25 then best, progress = distance, os.clock() end
                    if blocked or humanoid.Health <= 0 or os.clock() - progress > 1.5 or os.clock() - started > 12 then
                        utils.navigation.Reason = blocked and "Path changed" or "No movement"
                        retry = true
                        break
                    end
                    task.wait(0.03)
                end
                if retry or utils.route ~= route then break end
            end
            connection:Disconnect()
            utils.navigation.Connection = nil
            utils.navigation.Path = nil
        end
        path:Destroy()
        if not runtime.Alive or utils.route ~= route or utils.player.Character ~= character then return false end
        if not retry and (root.Position - point).Magnitude < 7 then return true end
        utils.navigation.Restarts += 1
        pcall(utils.remote, "Treadmill", "AskDoff")
        humanoid.Sit = false
        humanoid:MoveTo(root.Position)
        task.wait(0.35)
    end
    error("Route is blocked; waiting before trying again", 0)
end

function utils.move(point, route)
    assert(typeof(point) == "Vector3", "Target position unavailable")
    local _, humanoid = utils.character()
    assert(humanoid, "Wait for your character to respawn")
    route = route or utils.route
    if not utils.navigation.Controls then
        local success, controls = pcall(function() return require(utils.player.PlayerScripts.PlayerModule):GetControls() end)
        utils.identityReset()
        if success then utils.navigation.Controls = controls end
    end
    if utils.navigation.Controls then
        utils.navigation.InputEnabled = utils.navigation.Controls.controlsEnabled ~= false
        utils.navigation.Controls:Disable()
    end
    utils.navigation.Humanoid = humanoid
    utils.navigation.Speed = humanoid.WalkSpeed
    utils.navigation.Jump = {Power = humanoid.JumpPower, Enabled = humanoid.UseJumpPower}
    local walkSpeed = math.min(utils.settings.travel.Speed, 50)
    humanoid.WalkSpeed = utils.settings.player.SpeedEnabled and math.min(utils.settings.player.Speed, 50) or walkSpeed
    humanoid.UseJumpPower = true
    humanoid.JumpPower = math.min(humanoid.JumpPower, 50)
    pcall(utils.remote, "Treadmill", "AskDoff")
    local success, result = pcall(utils.path, point, route)
    if utils.route == route then
        if utils.navigation.Speed and humanoid.Parent then humanoid.WalkSpeed = utils.navigation.Speed end
        if utils.navigation.Jump and humanoid.Parent then
            humanoid.JumpPower = utils.navigation.Jump.Power
            humanoid.UseJumpPower = utils.navigation.Jump.Enabled
        end
        utils.navigation.Humanoid, utils.navigation.Speed = nil, nil
        utils.navigation.Jump = nil
        if utils.navigation.InputEnabled and utils.navigation.Controls then utils.navigation.Controls:Enable() end
        utils.navigation.InputEnabled = nil
    end
    if not success then error(result, 0) end
    return result
end


function utils.flyTo(point, route, speed)
    assert(typeof(point) == "Vector3", "Target position unavailable")
    local character, humanoid, root = utils.character()
    assert(root, "Wait for your character to respawn")
    route = route or utils.route
    speed = speed or 400
    local started = os.clock()
    while runtime.Alive and utils.route == route and os.clock() - started < 25 do
        local offset = point - root.Position
        if offset.Magnitude <= 3 then return true end
        local step = math.min(offset.Magnitude, speed * 0.03)
        local target = root.Position + offset.Unit * step
        pcall(function() character:PivotTo(CFrame.new(root.Position, target)) end)
        root.CFrame = CFrame.new(target)
        root.AssemblyLinearVelocity = Vector3.zero
        task.wait(0.03)
    end
    return utils.route == route and (root.Position - point).Magnitude <= 5
end

function utils.flySafe(point, route, speed)
    assert(typeof(point) == "Vector3", "Target position unavailable")
    local character, humanoid, root = utils.character()
    assert(root, "Wait for your character to respawn")
    route = route or utils.route
    speed = math.min(speed or 120, 120)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character, utils.navigation.Folder, utils.visualFolder}
    params.RespectCanCollide = true
    local started = os.clock()
    while runtime.Alive and utils.route == route and os.clock() - started < 30 do
        local delta = point - root.Position
        if Vector3.new(delta.X, 0, delta.Z).Magnitude <= 4 and math.abs(delta.Y) <= 8 then return true end
        local horizontal = Vector3.new(delta.X, 0, delta.Z)
        local step = math.min(horizontal.Magnitude, math.max(4, speed * 0.03))
        local ahead = root.Position + horizontal.Unit * step
        local ground = services.Workspace:Raycast(ahead + Vector3.new(0, 60, 0), Vector3.new(0, -200, 0), params)
        if not ground then return false end
        local nextY = ground.Position.Y + humanoid.HipHeight + root.Size.Y / 2 + 0.5
        local destination = Vector3.new(ahead.X, nextY, ahead.Z)
        pcall(function() character:PivotTo(CFrame.new(destination)) end)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        task.wait(0.03)
    end
    return utils.route == route and (root.Position - point).Magnitude <= 8
end

function utils.eggItem(row)
    return {Category = row.AssetCategory, Scale = row.AssetScale or 1, Mutations = row.Mutations or {}, BaseMutation = row.BaseMutation, ColorIndex = row.AssetColorIndex or 0}
end

function utils.eggValue(row)
    local config = utils.modules.assets and utils.modules.assets.Directory[row.AssetCategory]
    if not config then return 0 end
    local scale = tonumber(row.AssetScale) or 1
    local scaleFactor = scale > 5 and (scale / 5) ^ 1.2 * 19.637875755794113 or scale ^ 1.85
    local mutations = 1
    local mutationModule = utils.modules.mutations
    if mutationModule and type(mutationModule.EarningsFor) == "function" then
        local success, result = pcall(mutationModule.EarningsFor, type(row.Mutations) == "table" and row.Mutations or {})
        if success and type(result) == "number" and result > 0 then mutations = result end
    end
    return (tonumber(config.EarningRate) or 0) * scaleFactor * mutations
end

function utils.eggInfo(uid, row)
    local config = utils.modules.assets.Directory[row.AssetCategory]
    if not config then return end
    return {
        Uid = uid, Row = row, Category = row.AssetCategory,
        Rarity = config.Rarity._id, Rank = config.Rarity.Rank,
        Weight = utils.call(utils.modules.eggRecords.WeightKg, row),
        Value = utils.call(utils.modules.eggRecords.SellPrice, row),
        Income = utils.eggValue(row),
        Position = typeof(row.BottomCFrame) == "CFrame" and row.BottomCFrame.Position or nil,
        Placed = row.Placement ~= nil,
        Scale = row.AssetScale or 1
    }
end

function utils.rarityRank(name)
    local rarities = utils.modules.rarities and utils.modules.rarities.Rarities or {}
    local config = rarities[name]
    return config and tonumber(config.Rank) or 0
end

function utils.matchesFilters(info, row, settings, specific, areas)
    specific = specific or settings.Specific
    areas = areas or settings.TargetAreas
    if not info then return false end
    if settings.MinRarity and settings.MinRarity ~= "Any" and info.Rank < utils.rarityRank(settings.MinRarity) then return false end
    if not utils.matches(settings.Rarities, info.Rarity) then return false end
    if areas and next(areas) ~= nil and not areas[row.AreaId] then return false end
    if not utils.matches(settings.Areas, row.AreaId) then return false end
    if not utils.matches(settings.Species, row.AssetCategory) then return false end
    if specific and next(specific) ~= nil and not specific[row.AssetCategory] then return false end
    if not utils.mutated(settings.Mutations, row) then return false end
    if info.Weight < (settings.MinWeight or 0) then return false end
    if info.Income < (settings.MinValue or 0) then return false end
    return true
end

function utils.guardAwake(areaId)
    local world = services.Workspace:FindFirstChild("World") or services.Workspace:FindFirstChild("__OBJECTS")
    local areas = world and world:FindFirstChild("Areas")
    local guardAreas = areas and areas:FindFirstChild("GuardAreas")
    local area = guardAreas and guardAreas:FindFirstChild(tostring(areaId))
    local guard = area and area:FindFirstChild("Guard")
    if guard then
        local state = guard:GetAttribute("GuardState")
        local target = guard:GetAttribute("TargetPlayer")
        return (state == "Chasing" and target == utils.player.UserId) or state == "Waking"
    end
    return false
end

function utils.indexNeeds()
    local save = utils.save()
    local needed = {}
    local index = type(save.Index) == "table" and save.Index or {}
    local directory = utils.modules.areas and utils.modules.areas.Directory or {}
    for _, area in pairs(directory) do
        for _, entry in pairs(type(area) == "table" and area.DropTable or {}) do
            local category = type(entry) == "table" and entry[1] or nil
            if type(category) == "string" and index[category] ~= true then
                needed[category] = true
            end
        end
    end
    return needed
end

function utils.labNeeds()
    if utils.labNeedsCache and os.clock() - utils.labNeedsCache.At < 10 then return utils.labNeedsCache.Set end
    local state = utils.labState()
    local set = {}
    if state and type(state.Requirements) == "table" then
        for _, category in ipairs(state.Requirements) do set[tostring(category)] = true end
    end
    utils.labNeedsCache = {At = os.clock(), Set = set}
    return set
end

function utils.fieldRecord(uid)
    local snapshot = utils.call(utils.modules.eggs.ReadFieldEggs)
    for _, row in pairs(snapshot.Records or {}) do
        if row.Uid == uid then return row end
    end
end

function utils.fieldEggs(priority, unfiltered)
    local snapshot = utils.call(utils.modules.eggs.ReadFieldEggs)
    local entries = {}
    local _, _, root = utils.character()
    local indexNeeds = utils.settings.eggs.Index and utils.indexNeeds() or nil
    local labNeeds = utils.settings.eggs.Lab and utils.labNeeds() or nil
    for _, row in pairs(snapshot.Records or {}) do
        local starter = tostring(row.Uid):find("^FirstAreaEgg_") ~= nil
        if (row.State == "Slot" or row.State == "Dropped") and not starter and (utils.selection.Cooldowns[row.Uid] or 0) <= os.clock() then
            local info = utils.eggInfo(row.Uid, row)
            local forced = (indexNeeds and indexNeeds[row.AssetCategory]) or (labNeeds and labNeeds[row.AssetCategory])
            if info and info.Position and not (utils.settings.eggs.AntiGuard and utils.guardAwake(row.AreaId))
                and (unfiltered or forced or utils.matchesFilters(info, row, utils.settings.eggs)) then
                info.Distance = root and (root.Position - info.Position).Magnitude or math.huge
                table.insert(entries, info)
            end
        end
    end
    table.sort(entries, function(a, b)
        local order = priority or utils.settings.eggs.Priority
        local av, bv
        if order == "Closest" then av, bv = -a.Distance, -b.Distance
        elseif order == "Rarity" or order == "Best Rarity" then av, bv = a.Rank, b.Rank
        elseif order == "Weight" or order == "Biggest Weight" then av, bv = a.Weight, b.Weight
        elseif order == "Lowest Value" then av, bv = -a.Income, -b.Income
        else av, bv = a.Income, b.Income end
        if av == bv then
            if order == "Rarity" or order == "Best Rarity" then
                if a.Income ~= b.Income then return a.Income > b.Income end
                if a.Distance ~= b.Distance then return a.Distance < b.Distance end
            elseif order == "Best Mutation" then
                if a.Income ~= b.Income then return a.Income > b.Income end
            end
            return a.Uid < b.Uid
        end
        return av > bv
    end)
    return entries
end

function utils.grab(uid, slot)
    local success, accepted, reason = pcall(utils.modules.eggs.CarryFieldEgg, uid, slot)
    if success and accepted ~= false then return true end
    local folder = services.Workspace:FindFirstChild("AreaEggSlotsClient")
    local model = folder and folder:FindFirstChild(uid)
    local promptPart = model and model:FindFirstChild("SmartPromptPart", true)
    if not promptPart then
        local smart = services.Workspace:FindFirstChild("SmartPromptPart")
        if smart then promptPart = smart end
    end
    local prompt = promptPart and promptPart:FindFirstChild("CarryAreaEgg")
    if not prompt and model then prompt = model:FindFirstChild("CarryAreaEgg", true) end
    if prompt and type(fireproximityprompt) == "function" then
        pcall(function() prompt.HoldDuration = 0 end)
        pcall(fireproximityprompt, prompt)
        task.wait(0.15)
    end
    local success2, accepted2, reason2 = pcall(utils.modules.eggs.CarryFieldEgg, uid, slot)
    if success2 then return accepted2, reason2 end
    return false, reason2 or reason or "Egg pickup rejected"
end

function utils.drop()
    local success, result = pcall(utils.modules.eggs.DropFieldEgg, "PlayerRequest")
    utils.identityReset()
    if not success then error(result, 0) end
    return result
end

function utils.isNight()
    local cycle = utils.modules.areaCycle
    if cycle and type(cycle.IsNightPhase) == "function" then
        local success, result = pcall(cycle.IsNightPhase, services.Workspace:GetServerTimeNow())
        if success then return result == true end
    end
    return false
end

function utils.wallSealed()
    local wall = utils.modules.areaWall
    if wall then
        if type(wall.IsSealed) == "function" then
            local success, result = pcall(wall.IsSealed)
            if success then return result == true end
        end
        if type(wall.Sealed) == "boolean" then return wall.Sealed end
    end
    return false
end

function utils.ownedCount()
    local count = 0
    for _ in pairs(utils.call(utils.modules.eggs.ReadOwnerEggs, utils.player.UserId)) do count += 1 end
    return count
end

function utils.chooseEgg(priority, unfiltered)
    local target = utils.fieldEggs(priority, unfiltered)[1]
    assert(target, unfiltered and "No field eggs are available" or "No eggs match your filters")
    return target
end

function utils.eggSlot(target)
    local firstArea = utils.call(utils.modules.slotIdentity.LooksLikeFirstAreaUid, target.Uid)
    if not firstArea then return nil end
    return utils.call(utils.modules.slotIdentity.SlotKey, target.Row.AreaId, target.Row.NestId)
end

function utils.refreshEgg(target)
    local row = utils.fieldRecord(target.Uid)
    if not row or typeof(row.BottomCFrame) ~= "CFrame" then return false end
    target.Row = row
    target.Position = row.BottomCFrame.Position
    return true
end

function utils.pickupEgg(target, route)
    utils.selection.Target = target.Uid
    utils.message("Steal", "Travelling to " .. target.Category)
    pcall(utils.net, "RF/Treadmill/AskDoff")
    local reason = "Egg pickup rejected"
    for _ = 1, 5 do
        if not utils.refreshEgg(target) then error("Target egg disappeared", 0) end
        assert(utils.travelTo(target.Position + Vector3.new(0, 1, 0), route), "Route cancelled or target not reached")
        assert(runtime.Alive and utils.route == route, "Route cancelled")
        if not utils.refreshEgg(target) then error("Target egg disappeared", 0) end
        local slot = utils.eggSlot(target)
        utils.selection.TargetSlot = slot
        local accepted, message = utils.grab(target.Uid, slot)
        if accepted then return end
        reason = message or reason
        local _, _, root = utils.character()
        if not root or (root.Position - target.Position).Magnitude > 14 then
            task.wait(0.1)
        else
            break
        end
    end
    error(reason, 0)
end

function utils.safeZonePosition()
    local _, _, root = utils.character()
    assert(root, "Wait for your character to respawn")
    local ground = services.Workspace:Raycast(Vector3.new(600, 500, -325), Vector3.new(0, -1000, 0))
    return ground and (ground.Position + Vector3.new(0, 3, 0)) or Vector3.new(600, root.Position.Y, -325)
end

function utils.deliverEgg(route, before)
    if utils.ownedCount() > before then return "Egg delivery confirmed in your inventory" end
    if utils.settings.eggs.SafeZone then
        utils.message("Steal", "Dropping egg at the safe zone")
        local arrived = utils.travelTo(utils.safeZonePosition(), route)
        if not arrived then pcall(utils.flyTo, utils.safeZonePosition(), route, 200) end
        local deadline = os.clock() + 2
        repeat
            if not utils.call(utils.modules.eggs.ReadCarryState).IsCarrying then break end
            pcall(utils.drop)
            task.wait(0.2)
        until os.clock() >= deadline or not runtime.Alive
        if utils.selection.Target then utils.selection.Cooldowns[utils.selection.Target] = os.clock() + 900 end
        return "Egg dropped at the safe zone"
    end

    utils.message("Steal", "Returning to your plot")
    local destination = utils.homePosition()
    local arrived = utils.travelTo(destination, route)
    if not arrived then pcall(utils.flySafe, destination, route, 120) end
    task.wait(0.4)
    if utils.ownedCount() > before then return "Egg delivery confirmed in your inventory" end
    if utils.call(utils.modules.eggs.ReadCarryState).IsCarrying then pcall(utils.drop) end

    local deadline = os.clock() + 4
    repeat
        if utils.ownedCount() > before then return "Egg delivery confirmed in your inventory" end
        if not utils.call(utils.modules.eggs.ReadCarryState).IsCarrying then
            task.wait(0.2)
        end
        task.wait(0.2)
    until os.clock() >= deadline or not runtime.Alive or utils.route ~= route
    pcall(utils.drop)
    error("Egg delivery was not confirmed; retrying another egg", 0)
end

function utils.steal(priority, unfiltered)
    assert(not utils.moving, "Another route is active")
    if utils.settings.eggs.NightWait and (utils.isNight() or utils.wallSealed()) then
        error("Waiting for the field to reset", 0)
    end
    utils.stop()
    utils.moving = true
    local route = utils.route
    local success, result = pcall(function()
        local before = 0
        for _ in pairs(utils.call(utils.modules.eggs.ReadOwnerEggs, utils.player.UserId)) do before += 1 end
        if not utils.call(utils.modules.eggs.ReadCarryState).IsCarrying then
            utils.pickupEgg(utils.chooseEgg(priority, unfiltered), route)
        end
        return utils.deliverEgg(route, before)
    end)
    if utils.route == route then utils.moving = false end
    if not success then
        if utils.selection.Target then utils.selection.Cooldowns[utils.selection.Target] = os.clock() + 30 end
        if utils.route == route then utils.stop() end
        error(result, 0)
    end
    utils.lastStealAt = os.clock()
    return result
end

function utils.placementCandidates(area, occupied)
    for index = #(utils.pipeline.RejectedPositions or {}), 1, -1 do
        local rejected = utils.pipeline.RejectedPositions[index]
        if rejected.Expires <= os.clock() then table.remove(utils.pipeline.RejectedPositions, index) end
    end
    local candidates = {}
    local _, _, root = utils.character()
    local spacing = utils.settings.place.Spacing
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {utils.player.Character, utils.navigation.Folder, utils.visualFolder}
    params.RespectCanCollide = true
    for x = -area.Size.X / 2 + 3, area.Size.X / 2 - 3, spacing do
        for z = -area.Size.Z / 2 + 3, area.Size.Z / 2 - 3, spacing do
            local point = area.CFrame:PointToWorldSpace(Vector3.new(x, area.Size.Y / 2, z))
            local clear = true
            for _, used in ipairs(occupied) do
                if Vector3.new(used.X - point.X, 0, used.Z - point.Z).Magnitude < spacing - 0.05 then clear = false; break end
            end
            if clear then
                for _, rejected in ipairs(utils.pipeline.RejectedPositions or {}) do
                    if rejected.Expires > os.clock() and (rejected.Point - point).Magnitude < 1 then clear = false; break end
                end
            end
            if clear and not utils.segmentAvoided(point + Vector3.new(0, 3, 0), point + Vector3.new(0, 3.1, 0)) then
                local parts = services.Workspace:GetPartBoundsInBox(CFrame.new(point + Vector3.new(0, 3.1, 0)), Vector3.new(3, 4, 3), params)
                if #parts == 0 then table.insert(candidates, {Point = point, Distance = root and (root.Position - point).Magnitude or 0}) end
            end
        end
    end
    table.sort(candidates, function(a, b) return a.Distance < b.Distance end)
    return candidates
end

function utils.travelTo(point, route, speed)
    local mode = utils.settings.travel.Mode
    if mode == "Tween" then
        return utils.flySafe(point, route, speed or utils.settings.travel.Speed)
    end
    local success, result = pcall(utils.move, point, route)
    if success and result then return true end
    return utils.flySafe(point, route, math.min(speed or utils.settings.travel.Speed, 120))
end

function utils.homePosition()
    local plot = utils.plot()
    assert(plot and plot:FindFirstChild("SpawnPoint"), "Your plot has not loaded")
    local _, humanoid, root = utils.character()
    assert(root, "Wait for your character to respawn")
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {utils.player.Character, utils.navigation.Folder, utils.visualFolder}
    params.RespectCanCollide = true
    local point = plot.SpawnPoint.Position
    local ground = services.Workspace:Raycast(point + Vector3.new(0, 3, 0), Vector3.new(0, -40, 0), params)
    assert(ground, "Your plot entrance is not loaded")
    return ground.Position + Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2, 0)
end

function utils.home(route)
    return utils.travelTo(utils.homePosition(), route or utils.route)
end


function utils.placeAtPen(route)
    utils.refreshAvoidance()
    local plot = utils.plot()
    local center = plot and plot:FindFirstChild("CenterPoint")
    local area = plot and plot:FindFirstChild("PetArea", true)
    assert(center and area, "Your pen is not loaded")
    local owned = utils.call(utils.modules.eggs.ReadOwnerEggs, utils.player.UserId)
    local occupied = {}
    local count = 0
    local failures = {}
    local eggs = {}
    for uid, row in pairs(owned) do
        if row.Placement and typeof(row.Placement.LocalCFrame) == "CFrame" then
            table.insert(occupied, (center.CFrame * row.Placement.LocalCFrame).Position)
        elseif not row.Placement then
            local info = utils.eggInfo(uid, row)
            if info then
                local specific = {}
                for category, enabled in pairs(utils.settings.place.Specific or {}) do if enabled then specific[category] = true end end
                if next(specific) == nil or specific[row.AssetCategory] then
                    if (utils.settings.place.MinValue <= 0 or info.Income >= utils.settings.place.MinValue)
                        and (next(utils.settings.place.Rarities) == nil or utils.settings.place.Rarities[info.Rarity])
                        and utils.mutated(utils.settings.place.Mutations, row) and info.Weight >= utils.settings.place.MinWeight then
                        table.insert(eggs, {Uid = uid, Row = row, Info = info})
                    end
                end
            end
        end
    end
    table.sort(eggs, function(a, b)
        local mode = utils.settings.place.Order
        if mode == "Biggest Size" then return (a.Info.Scale) > (b.Info.Scale) end
        if mode == "Smallest Size" then return (a.Info.Scale) < (b.Info.Scale) end
        if mode == "Highest Value" then return (a.Info.Income) > (b.Info.Income) end
        return tostring(a.Uid) < tostring(b.Uid)
    end)
    for _, entry in ipairs(eggs) do
        if not runtime.Alive then break end
        local candidates = utils.placementCandidates(area, occupied)
        if #candidates == 0 then return count .. " placed; no accessible space left in the pen" end
        local placed, reason = false, "No accessible placement found"
        for index = 1, math.min(12, #candidates) do
            local point = candidates[index].Point
            placed, reason = pcall(function()
                assert(utils.travelTo(point + Vector3.new(0, 3, 0), route), "Placement route cancelled or blocked")
                assert(runtime.Alive and utils.route == route, "Placement cancelled")
                local accepted, message = utils.call(utils.modules.eggs.PlantEgg, entry.Uid, center.CFrame:ToObjectSpace(CFrame.new(point)))
                assert(accepted, message or "Placement rejected")
            end)
            utils.identityReset()
            if placed then count += 1; table.insert(occupied, point); break end
            utils.pipeline.RejectedPositions = utils.pipeline.RejectedPositions or {}
            table.insert(utils.pipeline.RejectedPositions, {Point = point, Expires = os.clock() + 20})
            if not runtime.Alive or utils.route ~= route then break end
        end
        if not placed then table.insert(failures, tostring(reason)) end
        if not runtime.Alive or utils.route ~= route then return count .. " eggs placed; cancelled" end
        task.wait(0.35)
    end
    if #failures > 0 then
        if count == 0 then error(failures[1], 0) end
        return count .. " eggs placed; " .. #failures .. " waiting to retry"
    end
    return count .. " eggs placed"
end

function utils.place()
    assert(not utils.moving, "Another route is active")
    local mode = utils.settings.place.Mode
    if mode == "Night Only" and not utils.isNight() then return "Waiting for night" end
    if mode == "Steal Idle" then
        local carrying = false
        local success, carry = pcall(utils.call, utils.modules.eggs.ReadCarryState)
        if success and type(carry) == "table" then carrying = carry.IsCarrying == true end
        if carrying or (utils.jobs.Steal and utils.jobs.Steal.Enabled) then return "Waiting for Auto Steal" end
    elseif mode == "After Steal" then
        if not utils.lastStealAt or os.clock() - utils.lastStealAt > 12 then return "Waiting for an egg delivery" end
    end
    utils.stop()
    utils.moving = true
    local route = utils.route
    local success, result = pcall(utils.placeAtPen, route)
    if utils.route == route then utils.moving = false end
    if not success then
        if utils.route == route then utils.stop() end
        error(result, 0)
    end
    return result
end

function utils.hatchAtPen(route)
    local count = 0
    local failures = {}
    local owned = utils.call(utils.modules.eggs.ReadOwnerEggs, utils.player.UserId)
    for uid in pairs(utils.pipeline.PendingHatches) do if not owned[uid] then utils.pipeline.PendingHatches[uid] = nil end end
    for uid in pairs(owned) do
        if not runtime.Alive or utils.route ~= route then break end
        if utils.pipeline.PendingHatches[uid] or utils.call(utils.modules.eggs.IsReadyToHatch, uid) then
            local hatched, reason = pcall(function()
                assert(runtime.Alive and utils.route == route, "Hatching cancelled")
                if not utils.pipeline.PendingHatches[uid] then
                    local accepted, message, token = utils.call(utils.modules.eggs.BeginHatch, uid)
                    assert(accepted, message or "Hatch rejected")
                    utils.pipeline.PendingHatches[uid] = {Token = token or uid, Due = os.clock() + utils.settings.hatch.Delay}
                end
                local pending = utils.pipeline.PendingHatches[uid]
                while os.clock() < pending.Due do
                    assert(runtime.Alive and utils.route == route, "Hatching cancelled")
                    task.wait(0.1)
                end
                local finished, message = utils.call(utils.modules.eggs.FinishHatch, pending.Token)
                assert(finished, message or "Hatch has not finished")
                utils.pipeline.PendingHatches[uid] = nil
                count += 1
            end)
            utils.identityReset()
            if not hatched then table.insert(failures, tostring(reason)) end
        end
    end
    if #failures > 0 then
        if count == 0 then error(failures[1], 0) end
        return count .. " eggs hatched; " .. #failures .. " waiting to retry"
    end
    return count .. " eggs hatched"
end

function utils.hatch()
    assert(not utils.moving, "Another route is active")
    utils.stop()
    utils.moving = true
    local route = utils.route
    local success, result = pcall(utils.hatchAtPen, route)
    if utils.route == route then utils.moving = false end
    if not success then
        if utils.route == route then utils.stop() end
        error(result, 0)
    end
    return result
end
function utils.rulePasses(rule, rarityBelow, valueBelow)
    if rule == "Rarity Only" then return rarityBelow end
    if rule == "Value Only" then return valueBelow end
    if rule == "Rarity Or Value" then return rarityBelow or valueBelow end
    return rarityBelow and valueBelow
end

function utils.sellEggs()
    local settings = utils.settings.sell.Eggs
    assert(settings.MaxRarity ~= "Off" or settings.Value > 0, "Choose an egg sell rule first")
    local selection = {}
    for uid, row in pairs(utils.call(utils.modules.eggs.ReadOwnerEggs, utils.player.UserId)) do
        local info = utils.eggInfo(uid, row)
        local halloween = row.AssetCategory and utils.modules.halloweenPets and utils.modules.halloweenPets.Specs[row.AssetCategory]
        local protected = settings.Blacklist[row.AssetCategory]
        if info and not row.Placement and not row.IsFavorite and not protected
            and not (settings.KeepMutated and #utils.mutationNames(row) > 0)
            and not (settings.ProtectHalloween and halloween)
            and utils.rulePasses(settings.Rule, settings.MaxRarity == "Off" or info.Rank <= utils.rarityRank(settings.MaxRarity), settings.Value > 0 and info.Income < settings.Value) then
            table.insert(selection, uid)
        end
    end
    if #selection > 0 then utils.remote("PetSatchel", "SellSelection", {Assets = {}, Eggs = selection}) end
    return #selection .. " eggs submitted for sale"
end

function utils.sellPets()
    local settings = utils.settings.sell.Pets
    assert(settings.MaxRarity ~= "Off" or settings.Value > 0, "Choose a pet sell rule first")
    local save = utils.save()
    local ranked, protected, selection = {}, {}, {}
    for uid, item in pairs(save.Inventory or {}) do
        table.insert(ranked, {Uid = uid, Item = item, Income = utils.call(utils.modules.earnings.RatePerSecond, item)})
    end
    table.sort(ranked, function(a, b) return a.Income == b.Income and a.Uid < b.Uid or a.Income > b.Income end)
    for index = 1, math.min(utils.settings.sell.KeepBest, #ranked) do protected[ranked[index].Uid] = true end
    for _, entry in ipairs(ranked) do
        local config = utils.modules.assets.Directory[entry.Item.Category]
        if config and not protected[entry.Uid] and not entry.Item.IsFavorite and not entry.Item.InFuse
            and not settings.Blacklist[entry.Item.Category]
            and not (settings.KeepMutated and #utils.mutationNames(entry.Item) > 0)
            and utils.rulePasses(settings.Rule, settings.MaxRarity == "Off" or config.Rarity.Rank <= utils.rarityRank(settings.MaxRarity), settings.Value > 0 and entry.Income < settings.Value) then
            if table.find(save.EquippedAssets or {}, entry.Uid) then
                if utils.settings.sell.Unequip then utils.remote("PenRoster", "AskDoff", entry.Uid)
                else continue end
            end
            table.insert(selection, entry.Uid)
        end
    end
    if #selection > 0 then
        for index = 1, #selection, 50 do
            local batch = table.move(selection, index, math.min(index + 49, #selection), 1, {})
            utils.remote("PetSatchel", "SellSelection", {Assets = batch, Eggs = {}})
            task.wait(0.3)
        end
    end
    return #selection .. " pets submitted for sale"
end

function utils.sellLabEggs()
    local settings = utils.settings.sell.Lab
    local save = utils.save()
    local selection = {}
    local reserved = utils.labReserved or {}
    local banners = utils.modules.scramble and utils.modules.scramble.Banners or {}
    local skins, keepBanner = {}, {}
    for _, banner in pairs(banners) do
        if banner.EggSkin then skins[banner.EggSkin] = true end
        for _, pet in ipairs(banner.Pets or {}) do
            if pet.AssetId then keepBanner[pet.AssetId] = true end
        end
    end
    for _, row in pairs(save.EggInventory or {}) do
        local uid = row.Uid or row._id
        local skin = row.EggSkin
        if uid and skin and skins[skin] and not row.Placement and not row.IsFavorite
            and not reserved[uid]
            and not (settings.KeepMutated and #utils.mutationNames(row) > 0)
            and not settings.KeepPets[row.AssetCategory] and not keepBanner[row.AssetCategory] then
            local info = utils.eggInfo(uid, row)
            if info and utils.rulePasses(settings.Rule, settings.MaxRarity == "Off" or info.Rank <= utils.rarityRank(settings.MaxRarity), settings.Value > 0 and info.Income < settings.Value) then
                table.insert(selection, uid)
            end
        end
    end
    if #selection > 0 then utils.remote("PetSatchel", "SellSelection", {Assets = {}, Eggs = selection}) end
    return #selection .. " lab eggs submitted for sale"
end

function utils.favouriteSettingsActive(settings)
    return settings.MinRarity ~= "Off" or next(settings.Mutations) ~= nil or settings.Value > 0 or next(settings.Always) ~= nil
end

function utils.favouriteMatches(row, info)
    local settings = utils.settings.favorite
    if settings.Always[row.AssetCategory] then return true end
    local checks, passed = 0, 0
    if settings.MinRarity ~= "Off" then
        checks += 1
        if info.Rank >= utils.rarityRank(settings.MinRarity) then passed += 1 end
    end
    if settings.Mutations["Any Mutation"] or next(settings.Mutations) ~= nil then
        checks += 1
        local values = {}
        if type(row.Mutations) == "table" then
            for name, enabled in pairs(row.Mutations) do
                if type(name) == "string" and enabled ~= false then table.insert(values, name)
                elseif type(enabled) == "string" then table.insert(values, enabled) end
            end
        elseif type(row.Mutations) == "string" then
            for name in row.Mutations:gmatch("[^,]+") do table.insert(values, name:match("^%s*(.-)%s*$")) end
        end
        local hasAny = (row.BaseMutation and row.BaseMutation ~= "Normal") or #values > 0
        if settings.Mutations["Any Mutation"] then
            if hasAny then passed += 1 end
        else
            local found = false
            if row.BaseMutation and settings.Mutations[row.BaseMutation] then found = true end
            for _, name in ipairs(values) do if settings.Mutations[name] then found = true end end
            if found then passed += 1 end
        end
    end
    if settings.Value > 0 then
        checks += 1
        if info.Income >= settings.Value then passed += 1 end
    end
    if checks == 0 then return false end
    return settings.Rule == "Match Any" and passed > 0 or passed == checks
end

function utils.favouritePets(unfavourite, equippedOnly)
    local save = utils.save()
    local settings = utils.settings.favorite
    local count = 0
    local equipped = {}
    for _, uid in ipairs(save.EquippedAssets or {}) do equipped[uid] = true end
    for uid, item in pairs(save.Inventory or {}) do
        if count >= 25 then break end
        if equippedOnly and not equipped[uid] then continue end
        if equipped[uid] and not unfavourite and not equippedOnly then continue end
        if unfavourite and not item.IsFavorite then continue end
        local config = utils.modules.assets.Directory[item.Category]
        local info = config and {Rank = config.Rarity.Rank, Income = utils.call(utils.modules.earnings.RatePerSecond, item)} or nil
        local matches = info and utils.favouriteMatches(item, info) or false
        if (unfavourite and not matches) or ((not unfavourite) and matches and not item.IsFavorite) then
            utils.remote("PetSatchel", "WriteFavourite", uid, not unfavourite)
            count += 1
            task.wait(0.12)
        end
    end
    return count .. (unfavourite and " pets unfavorited" or " pets favorited")
end

function utils.equipBest()
    assert(not utils.moving, "Another route is active")
    local success, result = pcall(utils.net, "RF/Haul/WearBest")
    assert(success, tostring(result))
    return "Best pets equipped"
end

function utils.fuse()
    local save = utils.save()
    if save.FusionEggReward then utils.net("RF/Fusery/FinishReveal"); return "Fusion reward claimed" end
    if save.FusionLocked then return "Fusion in progress" end
    local groups = {}
    local limit = utils.rarityRank(utils.settings.fuse.MaxRarity)
    for uid, item in pairs(save.Inventory or {}) do
        local config = utils.modules.assets.Directory[item.Category]
        if config and config.Rarity.Rank <= limit and not item.InFuse and not item.IsFavorite
            and not table.find(save.EquippedAssets or {}, uid)
            and utils.matches(utils.settings.fuse.Species, item.Category)
            and (not utils.settings.fuse.SkipMutated or #utils.mutationNames(item) == 0) then
            groups[item.Category] = groups[item.Category] or {}
            table.insert(groups[item.Category], uid)
        end
    end
    local slots = save.FusionSlots or {}
    local category = slots[1] and save.Inventory[slots[1]] and save.Inventory[slots[1]].Category
    local names = utils.keys(groups)
    if utils.settings.fuse.Priority == "Highest Value" then
        table.sort(names, function(a, b)
            local ai = utils.modules.assets.Directory[a]
            local bi = utils.modules.assets.Directory[b]
            return (ai and ai.EarningRate or 0) > (bi and bi.EarningRate or 0)
        end)
    end
    for _, name in ipairs(names) do
        local group = groups[name]
        if (not category or category == name) and #group + #slots >= 3 then
            utils.net("RF/Fusery/ConfirmBriefing")
            for index = 1, 3 - #slots do
                utils.net("RF/Fusery/LoadPet", group[index], false)
                task.wait(0.3)
            end
            utils.net("RF/Fusery/BeginFuse")
            return "Fusion started: " .. name
        end
    end
    if utils.settings.fuse.EjectIncomplete then
        for _, uid in ipairs(slots) do utils.net("RF/Fusery/EjectPet", uid) end
    end
    return "Waiting for three matching unequipped pets"
end

function utils.mutationTools()
    local tools = {}
    local character = utils.player.Character
    local backpack = utils.player:FindFirstChildOfClass("Backpack")
    for _, container in ipairs({character, backpack}) do
        for _, tool in ipairs(container and container:GetChildren() or {}) do
            if tool:IsA("Tool") and tostring(tool:GetAttribute("ItemType")) == "MutationConsumable" then
                local id = tostring(tool:GetAttribute("MutationId") or tool:GetAttribute("MutationTemplate") or "")
                local uses = tonumber(tool:GetAttribute("Uses")) or tonumber(tostring(tool.Name):match("%[X(%d+)%]")) or 1
                if id ~= "" and uses > 0 then
                    tools[id] = tools[id] or {Tool = tool, Uses = 0}
                    tools[id].Uses += uses
                end
            end
        end
    end
    return tools
end

function utils.useMutation()
    local save = utils.save()
    local targets = {}
    for uid, row in pairs(utils.call(utils.modules.eggs.ReadOwnerEggs, utils.player.UserId)) do
        if row.Placement then
            local info = utils.eggInfo(uid, row)
            if info then
                local categoryOk = next(utils.settings.mutation.Targets) == nil or utils.settings.mutation.Targets[row.AssetCategory]
                if categoryOk
                    and (utils.settings.mutation.MinRarity == "Any" or info.Rank >= utils.rarityRank(utils.settings.mutation.MinRarity))
                    and (utils.settings.mutation.MinValue <= 0 or info.Income >= utils.settings.mutation.MinValue) then
                    table.insert(targets, {Uid = uid, Info = info})
                end
            end
        end
    end
    assert(#targets > 0, "No placed egg matches the mutation filters")
    if utils.settings.mutation.Priority == "Best Rarity" then
        table.sort(targets, function(a, b) return a.Info.Rank > b.Info.Rank end)
    else
        table.sort(targets, function(a, b) return a.Info.Income > b.Info.Income end)
    end
    local tools = utils.mutationTools()
    local selected = nil
    for id, entry in pairs(tools) do
        local wanted = utils.settings.mutation.Mutations[id] or (id == "Boss" and utils.settings.mutation.Mutations.Fractured)
        if wanted and (not selected or entry.Uses > selected.Uses) then selected = {Id = id, Tool = entry.Tool} end
    end
    if not selected then
        if utils.settings.mutation.BuyNitro then
            pcall(utils.net, "RF/RaceRally/AskBuy", "MutationToken")
            return "Buying a mutation token"
        end
        error("No selected mutation consumable in your bag")
    end
    local character, humanoid = utils.character()
    assert(character, "Wait for your character to respawn")
    local tool = selected.Tool
    if tool.Parent ~= character then humanoid:EquipTool(tool) end
    task.wait(0.2)
    local target = targets[1]
    local success, result = pcall(utils.net, "RF/BossMastery/AskUseMutationConsumable", target.Uid)
    humanoid:UnequipTools()
    assert(success, tostring(result))
    return "Applied " .. selected.Id .. " to " .. target.Info.Category
end

function utils.upgradeTreadmill()
    local save = utils.save()
    if (save.TreadmillUpgradeLevel or 0) >= utils.settings.treadmill.MaxLevel then return "Upgrade limit reached" end
    local config = utils.call(utils.modules.treadmills.GetByUpgradeLevel, (save.TreadmillUpgradeLevel or 0) + 1)
    if not config then return "Maximum treadmill level reached" end
    if (save.Money or 0) < config.Price then return "Waiting for enough cash" end
    utils.net("RF/Treadmill/AskTierRaise", config._id)
    return "Upgrade requested: " .. config._id
end

function utils.upgradePen()
    local save = utils.save()
    local config = utils.modules.bases.BASES[(save.BaseUpgradeLevel or 0) + 1]
    if not config then return "Maximum pen level reached" end
    if (save.Money or 0) < config.Cost then return "Waiting for enough cash" end
    utils.remote("Homestead", "AskBaseTierRaise")
    return "Pen upgrade requested"
end

function utils.buyTrails(all)
    local count = 0
    for name, config in pairs(utils.modules.trails.Directory) do
        if not runtime.Alive then break end
        local save = utils.save()
        if (all or utils.settings.trails.Selected[name]) and config.Price and config.Price > 0
            and not (save.TrailInventory or {})[name] and (save.Money or 0) >= config.Price then
            utils.net("RF/Trailwear/AskPurchase", name)
            count += 1
            task.wait(0.5)
        end
    end
    return count .. " cash trails purchased"
end

function utils.equipTrail()
    local save = utils.save()
    local best
    for name, owned in pairs(save.TrailInventory or {}) do
        local config = owned and utils.modules.trails.Directory[name]
        if config and (not best or config.SpeedMultiplier > best.SpeedMultiplier) then best = config end
    end
    if not best then return "No owned trail" end
    utils.remote("Trailwear", "AskChoose", best._id)
    return "Equipped " .. (best.DisplayName or best._id)
end

function utils.claimOffline()
    local summary = utils.net("RF/AwayEarnings/PendingCheck")
    local pending = tonumber(summary) or (type(summary) == "table" and tonumber(summary.TotalAmount)) or 0
    if summary == true then pending = math.max(pending, 1) end
    if pending <= 0 then
        local save = utils.save()
        pending = tonumber(save.PendingOfflineMoney) or 0
    end
    if pending <= 0 then return "No pending offline earnings" end
    utils.net("RF/AwayEarnings/AskCollect", {Kind = "Claim"})
    return "Offline earnings claimed"
end

function utils.claimCodex()
    local count = 0
    local success = pcall(utils.net, "RF/Codex/AskRedeemAll")
    if success then count += 1 end
    local save = utils.save()
    for _, entry in ipairs({{Gear = "GravityDisruptor", Id = "LimitedEgg"}, {Gear = "BeeLauncher", Id = "BrainrotEgg"}, {Gear = "BeeLauncher", Id = "MonsterEgg"}}) do
        if ((save.GearInventory or {})[entry.Gear] or 0) > 0 then
            local claimed = pcall(utils.net, "RF/Codex/AskRedeemLimitedEgg", entry.Id)
            if claimed then count += 1 end
        end
    end
    return count .. " codex rewards claimed"
end

function utils.labState()
    local success, result = pcall(utils.net, "RF/ScrambleTradeIn/AskState")
    if success and type(result) == "table" then return result end
    return nil
end

function utils.labTrade()
    local state = utils.labState()
    assert(state, "Lab is unavailable")
    if state.Unlocked ~= true then return "Lab is locked on this account" end
    local banners = utils.settings.lab.Banners
    if next(banners) ~= nil then
        local banner = tostring(state.BannerDisplayName or state.BannerId or "")
        if not banners[banner] and not banners[tostring(state.BannerId or "")] then
            return "Waiting for a selected Lab banner"
        end
    end
    if state.PendingReward ~= nil then
        utils.net("RF/ScrambleTradeIn/AskFinishReveal")
        return "Lab reward claimed"
    end
    local save = utils.save()
    local owned = save.EggInventory or {}
    local used, uids = {}, {}
    local missing
    for _, requirement in ipairs(state.Requirements or {}) do
        local chosen
        for uid, row in pairs(owned) do
            if not used[uid] and row.Placement == nil and tostring(row.AssetCategory) == tostring(requirement) then
                if not chosen or (row.BaseMutation and not chosen.BaseMutation)
                    or (tonumber(row.AssetScale) or 0) > (tonumber(chosen.AssetScale) or 0) then chosen = row; chosen.Uid = chosen.Uid or uid end
            end
        end
        if not chosen then missing = tostring(requirement); break end
        used[chosen.Uid] = true
        table.insert(uids, chosen.Uid)
    end
    if missing then
        if utils.settings.lab.Reroll and (tonumber(state.FreeRefreshesRemaining) or 0) > 0 then
            utils.net("RF/ScrambleTradeIn/AskRefresh")
            return "Rerolled the lab recipe"
        end
        return "Need a " .. missing .. " egg"
    end
    utils.net("RF/ScrambleTradeIn/AskTradeIn", uids)
    utils.labReserved = used
    return "Lab trade-in sent"
end

function utils.claimMastery()
    local save = utils.save()
    local state = save.BossMastery or {}
    local count = 0
    for _, milestone in ipairs(utils.modules.mastery.Milestones) do
        if not (state.ClaimedMilestoneIds or {})[milestone.Id] and (state.Mastery or 0) >= milestone.Kills then
            utils.remote("BossMastery", "AskClaimMilestone", milestone.Id)
            count += 1
            task.wait(0.4)
        end
    end
    return count .. " mastery rewards claimed"
end

function utils.buyBossShop()
    local count = 0
    for _, offer in ipairs(utils.modules.mastery.ShopProducts) do
        local save = utils.save()
        if utils.settings.mastery.Shop[offer.Id] and (save.BossTokens or 0) - offer.Price >= utils.settings.mastery.Reserve then
            utils.remote("BossMastery", "AskBuyShopItem", offer.Id)
            count += 1
            task.wait(0.5)
        end
    end
    return count .. " boss shop purchases"
end

function utils.claimRace()
    local state = utils.save().RaceRally or {}
    local count = 0
    for _, milestone in ipairs(utils.call(utils.modules.race.OrderedMilestones)) do
        if not (state.Milestones or {})[milestone.Id] and (state.Wins or 0) >= milestone.Config.Wins then
            utils.remote("RaceRally", "AskClaimMilestone", milestone.Id)
            count += 1
            task.wait(0.4)
        end
    end
    return count .. " race rewards claimed"
end

function utils.buyRaceShop()
    local count = 0
    for _, offer in ipairs(utils.call(utils.modules.race.OrderedOffers)) do
        local state = utils.save().RaceRally or {}
        if utils.settings.race.Shop[offer.Id] and (state.Tokens or 0) - offer.Config.Price >= utils.settings.race.Reserve then
            utils.remote("RaceRally", "AskBuy", offer.Id)
            count += 1
            task.wait(0.5)
        end
    end
    return count .. " race shop purchases"
end

function utils.equipRacer()
    local state = utils.save().RaceRally or {}
    local target
    for _, racer in ipairs(utils.call(utils.modules.race.OrderedRacers)) do
        if (racer.Id == utils.modules.race.DefaultRacer or (state.Racers or {})[racer.Id])
            and (utils.settings.race.Racer == "Best Owned" or utils.settings.race.Racer == racer.Id) then
            target = racer.Id
        end
    end
    assert(target, "Selected racer is not owned")
    if state.EquippedRacer ~= target then utils.remote("RaceRally", "AskEquipRacer", target) end
    return "Equipped racer: " .. target
end

function utils.worldPosition(instance)
    if not instance then return end
    if instance:IsA("BasePart") then return instance.Position end
    if instance:IsA("Model") then return instance:GetPivot().Position end
    if instance:IsA("Attachment") then return instance.WorldPosition end
end

function utils.visit(instance)
    assert(instance, "This destination is not loaded or its event is inactive")
    assert(not utils.moving, "Another route is active")
    utils.stop()
    utils.moving = true
    local route = utils.route
    local point = utils.worldPosition(instance)
    assert(point, "Destination position unavailable")
    local success, result = pcall(utils.flySafe, point + Vector3.new(0, 3, 0), route, 120)
    if utils.route == route then utils.moving = false end
    if not success then error(result, 0) end
    assert(result, "Travel cancelled or destination not reached")
    return "Destination reached"
end

function utils.collectFolder(name)
    local folder = services.Workspace:FindFirstChild(name)
    if not folder then return "Event inactive or pickups have not spawned" end
    local _, _, root = utils.character()
    assert(root, "Wait for your character to respawn")
    local target, distance
    for _, instance in ipairs(folder:GetChildren()) do
        local point = utils.worldPosition(instance)
        if point and (not distance or (point - root.Position).Magnitude < distance) then
            target, distance = instance, (point - root.Position).Magnitude
        end
    end
    if not target then return "Waiting for the next pickup wave" end
    utils.visit(target)
    return "Reached a pickup; waiting for server collection"
end
function utils.equipToolByName(names)
    local character, humanoid = utils.character()
    if not character then return end
    local backpack = utils.player:FindFirstChildOfClass("Backpack")
    for _, container in ipairs({character, backpack}) do
        for _, tool in ipairs(container and container:GetChildren() or {}) do
            if tool:IsA("Tool") then
                if table.find(names, tool.Name) or (tool:GetAttribute("ButterflyNet") == true) then
                    if tool.Parent ~= character then pcall(function() humanoid:EquipTool(tool) end) end
                    return tool
                end
            end
        end
    end
end

function utils.findBat()
    local character, humanoid = utils.character()
    if not character then return end
    local backpack = utils.player:FindFirstChildOfClass("Backpack")
    local best, bestRange
    for _, container in ipairs({character, backpack}) do
        for _, tool in ipairs(container and container:GetChildren() or {}) do
            if tool:IsA("Tool") then
                local name = tostring(tool:GetAttribute("GearName") or tool.Name):lower()
                local config = utils.modules.gears and utils.modules.gears.Directory and utils.modules.gears.Directory[tool:GetAttribute("GearName") or tool.Name]
                local bonus = config and config.BatControllerData and tonumber(config.BatControllerData.RangeBonus) or 0
                local isBat = tool:GetAttribute("IsBat") == true or config and config.BatControllerData or name:find("bat") or name:find("katana") or name:find("sword") or name:find("axe") or name:find("hammer")
                if isBat and (not bestRange or bonus > bestRange) then best, bestRange = tool, bonus end
            end
        end
    end
    if best and best.Parent ~= character then pcall(function() humanoid:EquipTool(best) end) end
    return best
end

function utils.swing(tool)
    if tool and tool.Parent then pcall(function() tool:Activate() end) end
    pcall(utils.net, "RE/ToolTrigger/Trigger", tool)
end

function utils.halloweenDimension()
    return services.Workspace:FindFirstChild("HalloweenDimension")
end

function utils.halloweenEggs()
    local entries = {}
    local dimension = utils.halloweenDimension()
    local folder = dimension and dimension:FindFirstChild("WorldEggs")
    local _, _, root = utils.character()
    local settings = utils.settings.halloween
    for _, model in ipairs(folder and folder:GetChildren() or {}) do
        local category = model:GetAttribute("PreparedSourceName")
        local spec = category and utils.modules.halloweenPets.Specs[category]
        if model:IsA("Model") and model:GetAttribute("HalloweenEggCanPickUp") == true and spec then
            local rarity = spec.Rarity
            local zone = tostring(model:GetAttribute("Zone"))
            if (next(settings.Zones) == nil or settings.Zones[zone])
                and utils.matches(settings.Species, category)
                and utils.matches(settings.Rarities, rarity)
                and (spec.EarningRate or 0) >= settings.MinValue then
                table.insert(entries, {
                    Model = model, Uid = model:GetAttribute("HalloweenEggUid"), Category = category,
                    Rank = utils.rarityRank(rarity), Value = spec.EarningRate or 0,
                    Position = model:GetPivot().Position,
                    Distance = root and (model:GetPivot().Position - root.Position).Magnitude or math.huge
                })
            end
        end
    end
    table.sort(entries, function(a, b)
        local priority = settings.Priority
        local av = priority == "Closest" and -a.Distance or priority == "Rarity" and a.Rank or a.Value
        local bv = priority == "Closest" and -b.Distance or priority == "Rarity" and b.Rank or b.Value
        return av == bv and tostring(a.Uid) < tostring(b.Uid) or av > bv
    end)
    return entries
end

local function requireHalloweenDimension()
    assert(utils.player:GetAttribute("InHalloweenDimension"), "Enter the Halloween dimension first")
end

function utils.halloweenSteal()
    requireHalloweenDimension()
    local settings = utils.settings.halloween
    if not utils.player:GetAttribute("HalloweenCarrying") then
        local target = utils.halloweenEggs()[1]
        assert(target, "No Halloween eggs match your filters")
        assert(not utils.moving, "Another route is active")
        utils.stop()
        utils.moving = true
        local route = utils.route
        local success, result = pcall(function()
            assert(utils.flySafe(target.Position + Vector3.new(0, 3, 0), route, settings.Speed), "Halloween route cancelled")
            task.wait(0.15)
            local prompt = target.Model:FindFirstChild("StealPrompt", true)
            if prompt and type(fireproximityprompt) == "function" then
                pcall(function() prompt.HoldDuration = 0 end)
                pcall(fireproximityprompt, prompt)
            end
            pcall(utils.net, "RF/HalloweenDimension/AskCarryEgg", target.Uid)
            task.wait(0.4)
        end)
        if utils.route == route then utils.moving = false end
        if not success then error(result, 0) end
    end
    if utils.player:GetAttribute("HalloweenCarrying") then
        local dimension = utils.halloweenDimension()
        local spawns = dimension and dimension:FindFirstChild("Spawns")
        local entry = spawns and spawns:FindFirstChild("EntryCircle")
        if entry then
            utils.moving = true
            local route = utils.route
            pcall(utils.flySafe, utils.worldPosition(entry) + Vector3.new(0, 3, 0), route, 120)
            task.wait(0.5)
            if utils.route == route then utils.moving = false end
        end
    end
    return "Halloween egg collected"
end

function utils.halloweenMonsters()
    requireHalloweenDimension()
    local settings = utils.settings.halloween
    local _, _, root = utils.character()
    assert(root, "Wait for your character to respawn")
    local best, bestScore
    for _, model in ipairs(services.CollectionService:GetTagged("HalloweenMonster")) do
        local kind = tostring(model:GetAttribute("MonsterKind") or model.Name)
        if model:IsA("Model") and model:GetAttribute("KilledBy") == nil
            and (next(settings.MonsterKinds) == nil or settings.MonsterKinds[kind]) then
            local position = utils.worldPosition(model)
            if position then
                local distance = (position - root.Position).Magnitude
                local tokens = tonumber(model:GetAttribute("Tokens") or model:GetAttribute("CandyCorn")) or 0
                local score = settings.MonsterOrder == "Most Tokens" and tokens or -distance
                if not bestScore or score > bestScore then best, bestScore = model, score end
            end
        end
    end
    if not best then return "Waiting for Halloween monsters" end
    local position = utils.worldPosition(best)
    if not position then return "Monster position unavailable" end
    if (position - root.Position).Magnitude > 14 then
        utils.flyTo(position + Vector3.new(0, 3, 0), utils.route, settings.MonsterSpeed)
    end
    local tool = utils.findBat()
    local _, humanoid = utils.character()
    if humanoid then humanoid.WalkSpeed = settings.MonsterSpeed end
    utils.swing(tool)
    pcall(utils.net, "RE/HalloweenDimension/MonsterHit", best)
    return "Attacking a Halloween monster"
end

function utils.halloweenPumpkin()
    local settings = utils.settings.halloween
    if settings.Pumpkin and services.Workspace:GetAttribute("HalloweenWorldEvent") == "PumpkinMoon" then
        local dimension = utils.halloweenDimension()
        if utils.player:GetAttribute("HalloweenPumpkinCarrying") then
            local altar = dimension and dimension:FindFirstChild("Altar")
            local deposit = altar and altar:FindFirstChild("PumpkinDeposit")
            local position = utils.worldPosition(deposit) or utils.worldPosition(altar)
            if position then
                utils.flyTo(position + Vector3.new(0, 3, 0), utils.route, 300)
                local prompt = deposit and deposit:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and type(fireproximityprompt) == "function" then
                    pcall(function() prompt.HoldDuration = 0 end)
                    pcall(fireproximityprompt, prompt)
                end
                return "Depositing a runaway pumpkin"
            end
        end
        local folder = dimension and dimension:FindFirstChild("RunawayPumpkins")
        if folder then
            local _, _, root = utils.character()
            local target
            for _, pumpkin in ipairs(folder:GetChildren()) do
                local position = utils.worldPosition(pumpkin)
                if position and root and (not target or (position - root.Position).Magnitude < target.Distance) then
                    target = {Instance = pumpkin, Distance = (position - root.Position).Magnitude, Position = position}
                end
            end
            if target then
                if target.Distance > 10 then utils.flyTo(target.Position, utils.route, 300) end
                local prompt = target.Instance:FindFirstChild("CatchPrompt", true)
                if prompt and type(fireproximityprompt) == "function" then
                    pcall(function() prompt.HoldDuration = 0 end)
                    pcall(fireproximityprompt, prompt)
                    return "Catching a runaway pumpkin"
                end
            end
        end
    end
    if settings.BuyEgg then
        local success = pcall(utils.net, "RF/HalloweenDimension/AskBuyEgg")
        if success then return "Dimension egg purchased" end
    end
    return "Waiting for the Pumpkin Moon event"
end

function utils.ghostDogQuest()
    requireHalloweenDimension()
    local dimension = utils.halloweenDimension()
    local quest = utils.save().GhostDogQuest or {}
    local markers = dimension and dimension:FindFirstChild("GhostDogQuest") and dimension.GhostDogQuest:FindFirstChild("Markers")
    local stage = tonumber(quest.Stage) or 0
    if stage >= 4 then return "Ghost Dog quest complete" end
    local function marker(name)
        local instance = markers and markers:FindFirstChild(name)
        return instance and utils.worldPosition(instance)
    end
    if stage == 0 then
        local point = marker("DogSpot")
        if point then utils.flyTo(point + Vector3.new(0, 3, 0), utils.route, 300); utils.net("RF/GhostDogQuest/Talk", "Dog") end
        return "Talking to the Ghost Dog"
    elseif stage == 1 then
        local artifacts = {"Artifact_Collar", "Artifact_Bone", "Artifact_Toy", "Artifact_Photo"}
        local collected = quest.Artifacts or {}
        for index, name in ipairs(artifacts) do
            if not collected[index] and not collected[name] then
                local point = marker(name)
                if point then
                    utils.flyTo(point + Vector3.new(0, 3, 0), utils.route, 300)
                    utils.net("RF/GhostDogQuest/Collect", name)
                    return "Collecting " .. name
                end
            end
        end
        return "Waiting for Ghost Dog memory artifacts"
    elseif stage == 2 then
        local point = marker("FishermanSpot")
        if point then utils.flyTo(point + Vector3.new(0, 3, 0), utils.route, 300); utils.net("RF/GhostDogQuest/Talk", "Fisherman") end
        return "Talking to the fisherman"
    elseif stage == 3 then
        local point = marker("CastTarget") or marker("ReturnSpot")
        if point then utils.flyTo(point + Vector3.new(0, 3, 0), utils.route, 300) end
        pcall(utils.net, "RF/GhostDogQuest/Cast")
        pcall(utils.net, "RF/GhostDogQuest/Claim")
        return "Catching the ghost dog"
    end
    return "Ghost Dog quest idle"
end

function utils.fishing()
    requireHalloweenDimension()
    local character, humanoid = utils.character()
    if not character then return "Wait for your character to respawn" end
    local rod
    for _, container in ipairs({character, utils.player:FindFirstChildOfClass("Backpack")}) do
        for _, tool in ipairs(container and container:GetChildren() or {}) do
            if tool:IsA("Tool") and (tool:GetAttribute("GhostDogRod") == true or tostring(tool:GetAttribute("ItemType")) == "FishingRod") then rod = tool end
        end
    end
    if not rod then return "Ghost Dog rod not found" end
    if rod.Parent ~= character then pcall(function() humanoid:EquipTool(rod) end) end
    local root = character:FindFirstChild("HumanoidRootPart")
    local ray = services.Workspace:Raycast(root.Position + Vector3.new(0, 40, 0), Vector3.new(0, -180, 0))
    local charge = utils.settings.halloween.CastLuck == "x1.2" and 0.5 or utils.settings.halloween.CastLuck == "x1.1" and 0.75 or utils.settings.halloween.CastLuck == "x1.0 Fastest" and 0.02 or 0.875
    pcall(utils.net, "RE/Fishing/Hold", true)
    task.wait(1.2 * charge ^ 0.7142857)
    local success, result = pcall(utils.net, "RF/Fishing/Cast", charge, root.Position + root.CFrame.LookVector * (10 + 32 * charge))
    pcall(utils.net, "RE/Fishing/Hold", false)
    if not success then return tostring(result) end
    if type(result) == "table" and result.Id then
        task.wait(tonumber(result.Wait) or 2)
        pcall(utils.net, "RE/Fishing/Reel", result.Id, "Caught", (ray and ray.Instance and ray.Instance.Material == Enum.Material.Water) and 16 or 8)
        return "Fishing cast reeled"
    end
    return "Waiting for a bite"
end

function utils.trainAction(action, ...)
    local success, result = pcall(utils.net, "RF/TrainEvent/Action", action, ...)
    return success and result or nil
end

function utils.phantomExpress()
    local settings = utils.settings.train
    local save = utils.save()
    local state = save.TrainEvent or {}
    if not state.AccessUnlocked then return "Phantom Express is locked" end
    local phase = services.Workspace:GetAttribute("TrainEventPhase")
    local inTown = utils.player:GetAttribute("TrainEventInForgottenTown")
    local _, _, root = utils.character()
    if not root then return "Wait for your character to respawn" end
    if settings.TradeSouls then
        local shop = save.SoulShop
        if type(shop) == "table" and shop.CanTrade and (tonumber(shop.Cost) or math.huge) <= (tonumber(shop.Souls) or 0) then
            utils.trainAction("TradeSouls", shop.Cost)
            return "Trading souls"
        end
    end
    if inTown then
        if settings.Vacuum then
            local boss = services.ReplicatedStorage:FindFirstChild("GhostBossState")
            if boss and boss:GetAttribute("Phase") then
                pcall(utils.net, "RE/GhostBoss/Suction", true, root.CFrame.LookVector)
                return "Vacuuming the Ghouler boss"
            end
            for _, model in ipairs(services.CollectionService:GetTagged("TrainGhost")) do
                local position = utils.worldPosition(model)
                if position and (position - root.Position).Magnitude < 140 then
                    utils.flyTo(position + Vector3.new(0, 3, 0), utils.route, settings.Speed)
                    pcall(utils.net, "RE/GhostBoss/Suction", true, (position - root.Position).Unit)
                    return "Vacuuming ghosts"
                end
            end
        end
        local returnCount = state.Tickets or 0
        if returnCount > 0 then utils.trainAction("Return") end
        return "Waiting in Forgotten Town"
    end
    local action = phase == "Boarding" and "Board" or "Status"
    local result = utils.trainAction(action)
    if type(result) == "table" and result.Boarded == false and result.ArrivalOpen then utils.trainAction("Board") end
    return "Phantom Express: " .. tostring(phase or "waiting")
end

function utils.islandWars()
    local snapshot
    local success, result = pcall(utils.net, "RF/IslandWars/Fetch")
    if success and type(result) == "table" then snapshot = result end
    local me = snapshot and (snapshot.Me or snapshot.LocalPlayer)
    if me and me.State and me.State ~= "Alive" then return "Waiting to respawn in Island Wars" end
    local _, _, root = utils.character()
    if not root then return "Wait for your character to respawn" end
    local target, distance
    local function scan(container)
        for _, instance in ipairs(container:GetChildren()) do
            local name = instance.Name:lower()
            local position = nil
            if instance:IsA("Model") or instance:IsA("BasePart") then position = utils.worldPosition(instance) end
            if position and (name:find("enemy") or name:find("crystal") or name:find("barrier") or name:find("base") or instance:GetAttribute("Team") == "Enemy") then
                local d = (position - root.Position).Magnitude
                if not distance or d < distance then target, distance = instance, d end
            end
        end
    end
    local world = services.Workspace:FindFirstChild("World")
    if world then scan(world) end
    if target then
        if distance > 22 then utils.flyTo(utils.worldPosition(target), utils.route, 300) end
        local bat = utils.findBat()
        if bat then utils.swing(bat) else utils.net("RE/IslandWars/Use", "Swing", target) end
        return "Attacking Island Wars target"
    end
    pcall(utils.net, "RE/IslandWars/Use", "Launch", 1, root.Position, root.CFrame.LookVector)
    return "Island Wars active"
end

function utils.starPayloadPosition(payload)
    if type(payload) ~= "table" then return end
    local client = services.Workspace:FindFirstChild("ShootingStarClient")
    local buddy = client and client:FindFirstChild("Buddy")
    local part = buddy and (buddy:FindFirstChild("RootPart") or buddy.PrimaryPart)
    if part then return part.Position end
    local now = services.Workspace:GetServerTimeNow()
    local leg = payload.Leg
    if type(leg) == "table" and leg.From and leg.To and tonumber(leg.StartAt) and tonumber(leg.ArriveAt) then
        local alpha = math.clamp((now - leg.StartAt) / math.max(0.001, leg.ArriveAt - leg.StartAt), 0, 1)
        return leg.From:Lerp(leg.To, alpha).Position
    end
    local landing = payload.Landing
    if typeof(landing) == "CFrame" then return landing.Position end
    if typeof(landing) == "Vector3" then return landing end
end

function utils.catchStar()
    local star = utils.starState or {}
    local payload = star.Payload
    if type(payload) ~= "table" and (not star.AskAt or os.clock() >= star.AskAt) then
        star.AskAt = os.clock() + 15
        local success, result = pcall(utils.net, "RF/ShootingStar/AskState")
        if success and type(result) == "table" then payload = result; star.Payload = result end
    end
    if type(payload) ~= "table" then return "Waiting for a Shooting Star" end
    local now = services.Workspace:GetServerTimeNow()
    if payload.ExpiresAt and now > payload.ExpiresAt then utils.starState.Payload = nil; return "Shooting Star expired" end
    if payload.LandAt and now < payload.LandAt then
        return string.format("Star lands in %.0fs", payload.LandAt - now)
    end
    local position = utils.starPayloadPosition(payload)
    if not position then return "Star position unavailable" end
    local _, _, root = utils.character()
    if not root then return "Wait for your character to respawn" end
    if (position - root.Position).Magnitude > 8 then
        utils.flyTo(position + Vector3.new(0, 3, 3), utils.route, 400)
        return "Flying to the Shooting Star"
    end
    local id = payload.Id or payload.Uid
    if id then
        pcall(utils.net, "RE/ShootingStar/Hold", id, true)
        pcall(utils.net, "RE/ShootingStar/Catch", id)
    end
    return "Catching the Shooting Star"
end

function utils.butterfly()
    local settings = utils.settings.butterfly
    if services.Workspace:GetAttribute("Event_ButterflyBloom") ~= true then return "Butterfly Bloom is not active" end
    local character, humanoid, root = utils.character()
    if not root then return "Wait for your character to respawn" end
    local net = utils.equipToolByName({"Butterfly Net"})
    if not net then
        local success = pcall(utils.net, "RF/Butterflies/AskClaimNet")
        return success and "Claiming the Butterfly Net" or "Butterfly Net not owned"
    end
    local swarm = services.Workspace:FindFirstChild("ButterflyBloomSwarm")
    local best, bestScore
    for _, container in ipairs({swarm, services.Workspace}) do
        for _, model in ipairs(container and container:GetChildren() or {}) do
            if model:IsA("Model") and (model.Name:find("Butterfly") or model:GetAttribute("Tier")) then
                local position = utils.worldPosition(model)
                local tier = tostring(model:GetAttribute("Tier") or model.Name)
                if position then
                    local score = (position - root.Position).Magnitude
                    if settings.Priority == "Rarest" or settings.Priority == "Rarest First" then
                        if tier:find("Golden") or tier:find("Radiant") then score -= 400
                        elseif tier:find("Purple") or tier:find("Amethyst") then score -= 200 end
                    end
                    if (next(settings.Species) == nil or settings.Species[model.Name] or settings.Species[tier])
                        and (not bestScore or score < bestScore) then best, bestScore = model, score end
                end
            end
        end
        if best then break end
    end
    if best then
        local position = utils.worldPosition(best)
        if position and (position - root.Position).Magnitude > 6 then
            utils.flyTo(position, utils.route, settings.Speed)
        end
        if humanoid then humanoid.WalkSpeed = settings.Speed end
        pcall(function() character:PivotTo(CFrame.lookAt(root.Position, position)) end)
        return "Catching a butterfly"
    end
    if settings.TradeUp then pcall(utils.net, "RF/Butterflies/AskTradeUp", "ButterflyMachine", "Green") end
    if settings.Essence then pcall(utils.net, "RF/Butterflies/AskCraftEssence", "MutationShrine") end
    return "Waiting for butterflies"
end

function utils.captureEgg()
    local settings = utils.settings.capture
    if services.Workspace:GetAttribute("Event_CaptureTheEgg") ~= true and services.Workspace:GetAttribute("Event_CaptureTheEggGameplay") ~= true then
        return "Waiting for Capture The Egg"
    end
    local uid = services.Workspace:GetAttribute("Event_CaptureTheEggUid")
    if not uid then return "Waiting for the event egg" end
    local row = utils.fieldRecord(uid)
    if not row then return "Waiting for the event egg" end
    if row.CarrierUserId == utils.player.UserId then
        local _, _, root = utils.character()
        if root then
            local nearest, nearestDistance
            for _, player in ipairs(services.Players:GetPlayers()) do
                if player ~= utils.player and player.Character then
                    local theirRoot = player.Character:FindFirstChild("HumanoidRootPart")
                    if theirRoot then
                        local distance = (theirRoot.Position - root.Position).Magnitude
                        if not nearestDistance or distance < nearestDistance then nearest, nearestDistance = theirRoot, distance end
                    end
                end
            end
            local destination = root.Position
            if nearest and nearestDistance < settings.KeepAway then
                local away = (root.Position - nearest.Position).Unit
                destination = root.Position + away * (settings.KeepAway - nearestDistance + 12)
            end
            destination = Vector3.new(destination.X, root.Position.Y + settings.Height, destination.Z)
            utils.flyTo(destination, utils.route, 220)
            local _, humanoid = utils.character()
            if humanoid then humanoid.WalkSpeed = 220 end
        end
        return "Holding the event egg"
    end
    if not row.CarrierUserId or settings.Take then
        local position = utils.eggInfo(uid, row) and utils.eggInfo(uid, row).Position
        if position then
            utils.flyTo(position + Vector3.new(0, 3, 0), utils.route, 400)
            local slot = utils.call(utils.modules.slotIdentity.LooksLikeFirstAreaUid, uid)
                and utils.call(utils.modules.slotIdentity.SlotKey, row.AreaId, row.NestId) or nil
            utils.grab(uid, slot)
            return "Taking the event egg"
        end
    end
    return "Chasing the event egg holder"
end

function utils.banjo()
    local save = utils.save()
    if save.EnchantedTreeUnlocked ~= true then return "Enchanted Tree is locked" end
    local state = utils.banjoState or {}
    utils.banjoState = state
    if state.Solved then
        local success = pcall(utils.net, "RF/BanjoCricket/AskClaim")
        state.Solved = false
        return success and "Claimed the Banjo Cricket reward" or "Waiting to claim Banjo Cricket"
    end
    if type(state.Notes) ~= "table" or #state.Notes == 0 then return "Waiting for the Banjo sequence" end
    local mushrooms = {}
    for _, model in ipairs(services.CollectionService:GetTagged("BanjoCricketMushroom")) do
        local index = tonumber(model:GetAttribute("MushroomIndex"))
        if index then mushrooms[index] = model:FindFirstChild("Hitbox") or model:FindFirstChild("Hitbox Part") or model end
    end
    local played = 0
    for _, note in ipairs(state.Notes) do
        local mushroom = mushrooms[note]
        if mushroom then
            local position = utils.worldPosition(mushroom)
            if position then
                utils.flyTo(position + Vector3.new(0, 2, 0), utils.route, 400)
                local prompt = mushroom:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and type(fireproximityprompt) == "function" then
                    pcall(function() prompt.HoldDuration = 0 end)
                    pcall(fireproximityprompt, prompt)
                end
                pcall(utils.net, "RE/BanjoCricket/Aim", note)
                played += 1
                task.wait(0.35)
            end
        end
    end
    state.Notes = {}
    return played > 0 and ("Played " .. played .. " Banjo notes") or "Banjo mushrooms are not loaded"
end

function utils.wisp()
    local save = utils.save()
    local state = save.WispCompanion or {}
    if not state.Unlocked then return "Wisp is locked on this account" end
    if not state.Accepted then
        local speedPower = tonumber(save.SpeedPower) or 0
        if speedPower < 50000000000 then
            return string.format("Needs 50B Speed Power (you have %.2fB)", speedPower / 1000000000)
        end
        local world = services.Workspace:FindFirstChild("World")
        local build = world and world:FindFirstChild("Build")
        local forest = build and build:FindFirstChild("EnchantedForestZone")
        local spawn = forest and forest:FindFirstChild("WispSpawn")
        if spawn then
            utils.flyTo(utils.worldPosition(spawn) + Vector3.new(0, 3, 0), utils.route, 400)
        end
        local success, result = pcall(utils.net, "RF/WispCompanion/Request", "Accept")
        return success and "Wisp accepted" or tostring(result)
    end
    local stage = tonumber(state.Stage) or 1
    local stageCount = tonumber(utils.modules.wisp.StageCount) or 4
    if stage >= stageCount then
        local world = services.Workspace:FindFirstChild("World")
        local build = world and world:FindFirstChild("Build")
        local forest = build and build:FindFirstChild("EnchantedForestZone")
        local props = forest and forest:FindFirstChild("Zone13Props")
        local tree = props and props:FindFirstChild("EnchantedTree")
        local anchor = tree and tree:FindFirstChild("WispAnchor")
        if anchor then utils.flyTo(utils.worldPosition(anchor) + Vector3.new(0, 3, 0), utils.route, 400) end
        local success, result = pcall(utils.net, "RF/WispCompanion/Request", "Return")
        return success and "Wisp returned" or tostring(result)
    end
    local count = 0
    for _, quest in ipairs(utils.modules.wisp.List) do
        if not (state.Claimed or {})[quest.Id] and (state.Progress or {})[quest.Id] and (state.Progress or {})[quest.Id] >= quest.Target then
            utils.net("RF/WispCompanion/Request", "Claim", quest.Id)
            count += 1
            task.wait(0.5)
        end
    end
    return count > 0 and (count .. " Wisp quests claimed") or "Waiting for Wisp quest progress"
end
function utils.remember(instance, property, value)
    utils.originals[instance] = utils.originals[instance] or {}
    if utils.originals[instance][property] == nil then utils.originals[instance][property] = instance[property] end
    instance[property] = value
end

function utils.restore(property)
    for instance, properties in pairs(utils.originals) do
        if properties[property] ~= nil then
            if instance.Parent then pcall(function() instance[property] = properties[property] end) end
            properties[property] = nil
        end
    end
end

function utils.mark(key, model, text, color, distance, size, highlight)
    if not model or not model:IsA("Model") then return end
    local marker = utils.markers[key]
    if marker and marker.Model ~= model then marker.Highlight:Destroy(); marker.Gui:Destroy(); utils.markers[key] = nil; marker = nil end
    if not marker then
        local highlightInstance = Instance.new("Highlight")
        highlightInstance.Name = "Highlight"
        highlightInstance.Adornee = model
        highlightInstance.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlightInstance.FillTransparency = 0.82
        highlightInstance.OutlineColor = color
        highlightInstance.FillColor = color
        highlightInstance.Parent = utils.visualFolder
        local gui = Instance.new("BillboardGui")
        gui.Name = "Label"
        gui.Adornee = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
        gui.Size = UDim2.fromOffset(250, 52)
        gui.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
        gui.AlwaysOnTop = true
        gui.LightInfluence = 0
        gui.Parent = utils.visualFolder
        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
        label.BackgroundTransparency = 0.25
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 13
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextStrokeTransparency = 0.6
        label.TextWrapped = true
        label.Parent = gui
        marker = {Model = model, Highlight = highlightInstance, Gui = gui, Label = label}
        utils.markers[key] = marker
    end
    marker.Highlight.Enabled = highlight ~= false
    local scale = (utils.settings.visuals.Size or 75) / 75
    marker.Gui.Size = UDim2.fromOffset(250 * scale, 52 * scale)
    marker.Gui.MaxDistance = distance or utils.settings.visuals.Distance
    marker.Gui.StudsOffsetWorldSpace = Vector3.new(0, (size or 4), 0)
    marker.Label.Text = text
    marker.Seen = utils.visualRevision
end

function utils.mutationNames(row)
    local values = {}
    if type(row.Mutations) == "table" then
        for name, enabled in pairs(row.Mutations) do
            if type(name) == "string" and enabled ~= false then table.insert(values, name)
            elseif type(enabled) == "string" then table.insert(values, enabled) end
        end
    elseif type(row.Mutations) == "string" then
        for name in row.Mutations:gmatch("[^,]+") do table.insert(values, name:match("^%s*(.-)%s*$")) end
    end
    if row.BaseMutation and row.BaseMutation ~= "Normal" then table.insert(values, row.BaseMutation) end
    return values
end

function utils.eggInfoText(info, row)
    local infoSettings = utils.settings.visuals.Info
    local lines = {}
    local chosen = {}
    if next(infoSettings) == nil then
        chosen = {Name = true, Rarity = true, Value = true}
    else
        chosen = infoSettings
    end
    local parts = {}
    local mutations = utils.mutationNames(row)
    if chosen.Name then table.insert(parts, info.Category) end
    if chosen.Rarity then table.insert(parts, info.Rarity) end
    if chosen.Mutation then table.insert(parts, #mutations > 0 and table.concat(mutations, ",") or "Normal") end
    if chosen.Value then table.insert(parts, string.format("$%.0f/s", info.Income)) end
    if chosen.Weight then table.insert(parts, string.format("%.1f kg", info.Weight)) end
    if chosen.Size then table.insert(parts, string.format("x%.2f", info.Scale)) end
    if chosen.Sell then table.insert(parts, string.format("$%.0f", info.Value)) end
    if chosen.Distance then table.insert(parts, string.format("%.0f st", info.Distance or 0)) end
    if chosen.Area then table.insert(parts, tostring(row.AreaId or "?")) end
    if chosen.State then table.insert(parts, tostring(row.State or "?")) end
    table.insert(lines, table.concat(parts, " | "))
    if chosen.Mutation and #mutations > 0 then table.insert(lines, table.concat(mutations, ", ")) end
    return table.concat(lines, "\n")
end

function utils.esp()
    utils.visualRevision = (utils.visualRevision or 0) + 1
    local _, _, root = utils.character()
    if not root then return "Waiting for character" end
    local settings = utils.settings.visuals
    if settings.Eggs then
        local snapshots = {}
        table.insert(snapshots, {Rows = utils.call(utils.modules.eggs.ReadFieldEggs).Records or {}, Folder = services.Workspace:FindFirstChild("AreaEggSlotsClient"), Wild = true})
        local owners = {}
        if settings.OwnBase then table.insert(owners, utils.player.UserId) end
        if settings.OtherBase then for _, player in ipairs(services.Players:GetPlayers()) do if player ~= utils.player then table.insert(owners, player.UserId) end end end
        for _, userId in ipairs(owners) do
            table.insert(snapshots, {Rows = utils.call(utils.modules.eggs.ReadOwnerEggs, userId), Folder = services.Workspace:FindFirstChild("PlacedEggRenders"), Owner = userId})
        end
        for _, snapshot in ipairs(snapshots) do
            for key, row in pairs(snapshot.Rows) do
                local uid = row.Uid or key
                local info = utils.eggInfo(uid, row)
                local model = snapshot.Folder and snapshot.Folder:FindFirstChild(snapshot.Wild and tostring(uid) or tostring(snapshot.Owner) .. "_" .. tostring(uid))
                if info and info.Position and model and model:IsA("Model") then
                    info.Distance = (model:GetPivot().Position - root.Position).Magnitude
                    local rarityOk = settings.MinRarity == "Any" or info.Rank >= utils.rarityRank(settings.MinRarity)
                    if info.Distance <= settings.Distance and rarityOk and (settings.MinValue <= 0 or info.Income >= settings.MinValue)
                        and utils.matches(settings.Rarities, info.Rarity) and utils.mutated(settings.Mutations, row) then
                        local color = utils.modules.rarities.Rarities[info.Rarity] and utils.modules.rarities.Rarities[info.Rarity].Color or Color3.fromRGB(255, 255, 255)
                        utils.mark("egg:" .. tostring(uid), model, utils.eggInfoText(info, row), color, settings.Distance, 4, settings.Highlight)
                    end
                end
            end
        end
    end
    if settings.Guards then
        local world = services.Workspace:FindFirstChild("World") or services.Workspace:FindFirstChild("__OBJECTS")
        local areas = world and world:FindFirstChild("Areas")
        local guardAreas = areas and areas:FindFirstChild("GuardAreas")
        for _, area in ipairs(guardAreas and guardAreas:GetChildren() or {}) do
            for _, model in ipairs(area:GetChildren()) do
                if model:IsA("Model") and model.Name == "Guard" then
                    local position = model:GetPivot().Position
                    if (position - root.Position).Magnitude <= settings.Distance then
                        local state = tostring(model:GetAttribute("GuardState") or "Guard")
                        local target = model:GetAttribute("TargetPlayer")
                        if state == "Chasing" and target then
                            local name = target == utils.player.UserId and "You" or tostring(target)
                            state = "Chasing " .. name
                        end
                        utils.mark("guard:" .. model:GetFullName(), model, area.Name .. " Guard\n" .. state, Color3.fromRGB(255, 120, 100), settings.Distance, 6, true)
                    end
                end
            end
        end
    end
    if settings.Players then
        for _, player in ipairs(services.Players:GetPlayers()) do
            if player ~= utils.player then
                local character = player.Character
                local head = character and character:FindFirstChild("Head")
                if head and character:FindFirstChild("HumanoidRootPart") then
                    local tool = character:FindFirstChildOfClass("Tool")
                    local info = player.DisplayName .. " (@" .. player.Name .. ")"
                    if tool then info ..= "\n" .. tool.Name end
                    utils.mark("player:" .. player.UserId, character, info, Color3.fromRGB(72, 207, 255), settings.Distance, 5, true)
                end
            end
        end
    end
    for key, marker in pairs(utils.markers) do
        if marker.Seen ~= utils.visualRevision or not marker.Model.Parent then
            marker.Highlight:Destroy(); marker.Gui:Destroy(); utils.markers[key] = nil
        end
    end
    return "ESP active"
end

function utils.eggHolders()
    local holders = {}
    local success, result = pcall(utils.call, utils.modules.eggs.ReadFieldEggs)
    if not success then return holders end
    for _, row in pairs(result.Records or {}) do
        if row.State == "Carried" and row.CarrierUserId then
            holders[row.CarrierUserId] = row.Uid
        end
    end
    return holders
end

function utils.combatTarget()
    local mode = utils.settings.combat.Mode
    if mode == "Off" then return end
    local _, _, root = utils.character()
    if not root then return end
    local range = 18
    if services.Workspace:GetAttribute("DragonEggEventActive") == true then range *= 2.5 end
    if services.Workspace:GetAttribute("PvPDisabled") == true then return end
    local best, bestDistance
    local holders = mode == "Egg Holders" and utils.eggHolders() or nil
    for _, player in ipairs(services.Players:GetPlayers()) do
        if player ~= utils.player and player.Character then
            local character = player.Character
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local theirRoot = character:FindFirstChild("HumanoidRootPart")
            if humanoid and theirRoot and humanoid.Health > 0 then
                local allowed = true
                if mode == "Specific Player" and utils.settings.combat.Target ~= "" and player.Name ~= utils.settings.combat.Target then allowed = false end
                if holders and not holders[player.UserId] then allowed = false end
                if allowed then
                    local distance = (theirRoot.Position - root.Position).Magnitude
                    if distance <= range + (mode == "Hit Aura" and 24 or 0) and (not bestDistance or distance < bestDistance) then
                        best, bestDistance = player, distance
                    end
                end
            end
        end
    end
    return best, bestDistance
end

function utils.combatTick()
    local settings = utils.settings.combat
    if settings.Mode == "Off" then return end
    local target, distance = utils.combatTarget()
    if not target then return "No target in range" end
    local character, humanoid, root = utils.character()
    if not root then return "Wait for character" end
    local theirRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not theirRoot then return "Target has no root" end
    local velocity = theirRoot.AssemblyLinearVelocity or Vector3.zero
    local predicted = theirRoot.Position + velocity * (settings.Lead / 1000)
    local offset = predicted - root.Position
    local direction = offset.Magnitude > 0 and offset.Unit or Vector3.new(0, 0, -1)
    local right = Vector3.new(-direction.Z, 0, direction.X).Unit
    local sweep = math.sin(os.clock() * 2 * math.pi / 1.1) * (settings.Sweep / 100) * 2.5
    local goal = predicted + right * sweep
    offset = goal - root.Position
    if offset.Magnitude > 8 then
        local step = offset.Unit * math.min(offset.Magnitude, math.min(settings.Speed, settings.MaxSpeed) * 0.1)
        pcall(function() character:PivotTo(CFrame.lookAt(root.Position + step, goal)) end)
        root.AssemblyLinearVelocity = Vector3.zero
    end
    local tool = utils.findBat()
    if tool then
        pcall(function() tool:Activate() end)
        local token = string.format("%d:%d:%d", utils.player.UserId, math.floor(settings.Sweep), math.floor(services.Workspace:GetServerTimeNow() * 1000))
        pcall(utils.net, "RE/BatSwing/Trigger", target, token)
    end
    return "Hit " .. target.Name .. string.format(" | %.0f studs", distance or 0)
end

function utils.applyCharacter()
    local settings = utils.settings.player
    if not (settings.SpeedEnabled or settings.JumpEnabled or settings.AntiRagdoll or settings.AntiVoid or settings.Invisibility) then return end
    local character, humanoid, root = utils.character()
    if not humanoid then return end
    if settings.SpeedEnabled and not utils.moving then utils.remember(humanoid, "WalkSpeed", settings.Speed) end
    if settings.JumpEnabled then
        utils.remember(humanoid, "UseJumpPower", true)
        utils.remember(humanoid, "JumpPower", utils.moving and math.min(50, settings.JumpPower) or settings.JumpPower)
    end
    if settings.AntiRagdoll then
        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.FallingDown then
            pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
            humanoid.PlatformStand = false
        end
    end
    if settings.AntiVoid and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth then humanoid.Health = humanoid.MaxHealth end
    if settings.Invisibility and root then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.LocalTransparencyModifier = 1 end
        end
    elseif not settings.Invisibility then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.LocalTransparencyModifier == 1 then part.LocalTransparencyModifier = 0 end
        end
    end
end

function utils.antiTrap()
    local enabled = utils.settings.player.AntiTrap
    if not enabled and not utils.antiTrapWasEnabled then return end
    utils.antiTrapWasEnabled = enabled
    for _, instance in ipairs(services.CollectionService:GetTagged("PlacedTrap")) do
        local owner = instance:GetAttribute("Owner")
        if enabled and owner ~= utils.player.Name then
            for _, part in ipairs(instance:GetDescendants()) do
                if part:IsA("BasePart") then utils.remember(part, "CanTouch", false) end
            end
        end
    end
    if not enabled then utils.restore("CanTouch") end
end

function utils.serverHop(mode)
    assert(not utils.hopping, "A server hop is already pending")
    utils.hopping = true
    local success, result = pcall(function()
        local cursor, servers = "", {}
        local base = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder="
            .. (mode == "Most Players" and "Desc" or "Asc") .. "&excludeFullGames=true&limit=100"
        for _ = 1, mode == "Least Players" and 3 or 6 do
            local url = base .. (cursor ~= "" and "&cursor=" .. services.HttpService:UrlEncode(cursor) or "")
            local response = services.HttpService:JSONDecode(game:HttpGet(url))
            for _, server in ipairs(response.data or {}) do
                if server.id ~= game.JobId and not utils.settings.server.Visited[server.id] and server.playing < server.maxPlayers then
                    table.insert(servers, server)
                end
            end
            cursor = response.nextPageCursor
            if not cursor then break end
        end
        assert(#servers > 0, "No unvisited server with a free slot was found")
        table.sort(servers, function(a, b)
            if mode == "Most Players" then return a.playing > b.playing end
            return a.playing < b.playing
        end)
        local selected = mode == "Random" and servers[math.random(1, #servers)] or servers[1]
        utils.settings.server.Visited[selected.id] = true
        services.TeleportService:TeleportToPlaceInstance(game.PlaceId, selected.id, utils.player)
        return "Joining server"
    end)
    if not success then utils.hopping = false; error(result, 0) end
    return result
end

function utils.applyFpsCap()
    local cap = utils.settings.performance.FpsCap
    if utils.settings.performance.Disable3D then cap = math.min(cap, 40) end
    if type(setfpscap) == "function" then pcall(setfpscap, cap) end
end

function utils.set3d(enabled)
    local backdrop = utils.renderBackdrop
    if type(services.RunService.Set3dRenderingEnabled) == "function" then pcall(function() services.RunService:Set3dRenderingEnabled(enabled) end) end
    if enabled then
        if backdrop then backdrop:Destroy(); utils.renderBackdrop = nil end
    else
        if not backdrop then
            local gui = Instance.new("ScreenGui")
            gui.Name = "Overlay"
            gui.IgnoreGuiInset = true
            gui.ResetOnSpawn = false
            gui.DisplayOrder = -1000
            local frame = Instance.new("Frame")
            frame.Size = UDim2.fromScale(1, 1)
            frame.BorderSizePixel = 0
            frame.BackgroundColor3 = utils.settings.performance.Background == "Black" and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
            frame.Parent = gui
            local parent = gethui and gethui() or utils.player:FindFirstChildOfClass("PlayerGui") or services.StarterGui
            gui.Parent = parent
            utils.renderBackdrop = gui
        end
    end
    utils.applyFpsCap()
end

function utils.setOptimizer(enabled)
    local saved = utils.optimizerSaved
    if enabled then
        if saved then return end
        saved = {}
        utils.optimizerSaved = saved
        saved.Lighting = {
            GlobalShadows = services.Lighting.GlobalShadows,
            ShadowSoftness = services.Lighting.ShadowSoftness,
            FogEnd = services.Lighting.FogEnd,
            Technology = services.Lighting.Technology
        }
        services.Lighting.GlobalShadows = false
        services.Lighting.ShadowSoftness = 0
        services.Lighting.FogEnd = 9e9
        local terrain = services.Workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            saved.TerrainDecoration = terrain.Decoration
            terrain.Decoration = false
        end
        local count = 0
        for _, instance in ipairs(services.Workspace:GetDescendants()) do
            count += 1
            if count % 500 == 0 then task.wait() end
            if instance:IsA("ParticleEmitter") then saved[instance] = {Enabled = instance.Enabled}; instance.Enabled = false
            elseif instance:IsA("Trail") or instance:IsA("Beam") then saved[instance] = {Enabled = instance.Enabled}; instance.Enabled = false
            elseif instance:IsA("PointLight") or instance:IsA("SpotLight") or instance:IsA("SurfaceLight") then saved[instance] = {Enabled = instance.Enabled}; instance.Enabled = false
            elseif instance:IsA("Decal") or instance:IsA("Texture") then saved[instance] = {Transparency = instance.Transparency}; instance.Transparency = 1
            elseif instance:IsA("MeshPart") then saved[instance] = {TextureID = instance.TextureID, CastShadow = instance.CastShadow}; instance.TextureID = ""; instance.CastShadow = false
            elseif instance:IsA("BasePart") then saved[instance] = {CastShadow = instance.CastShadow}; instance.CastShadow = false
            elseif instance:IsA("PostEffect") then saved[instance] = {Enabled = instance.Enabled}; instance.Enabled = false end
        end
    elseif saved then
        for instance, value in pairs(saved) do
            if typeof(instance) == "Instance" and instance.Parent then
                for property, original in pairs(value) do pcall(function() instance[property] = original end) end
            end
        end
        local lighting = saved.Lighting
        if lighting then
            services.Lighting.GlobalShadows = lighting.GlobalShadows
            services.Lighting.ShadowSoftness = lighting.ShadowSoftness
            services.Lighting.FogEnd = lighting.FogEnd
        end
        local terrain = services.Workspace:FindFirstChildOfClass("Terrain")
        if terrain and saved.TerrainDecoration ~= nil then terrain.Decoration = saved.TerrainDecoration end
        utils.optimizerSaved = nil
    end
end

function utils.antiAfk()
    if utils.settings.performance.AntiAfk then
        pcall(function()
            local virtualUser = game:GetService("VirtualUser")
            virtualUser:CaptureController()
            virtualUser:ClickButton2(Vector2.new())
        end)
    end
end
function utils.minigameEgg()
    local events = {{Flag = "Event_RedLightGreenLight", Prefix = "RLGL", Name = "Red Light Green Light"}, {Flag = "Event_TrexRun", Prefix = "TrexRun", Name = "T-Rex Run"}}
    for _, event in ipairs(events) do
        local position = services.Workspace:GetAttribute(event.Prefix .. "_EggPosition")
        local active = services.Workspace:GetAttribute(event.Flag) == true or typeof(position) == "Vector3"
        if active then
            if typeof(position) ~= "Vector3" then return event.Name .. ": waiting for the egg to land" end
            local snapshot = utils.call(utils.modules.eggs.ReadFieldEggs)
            local target
            for _, row in pairs(snapshot.Records or {}) do
                if row.State ~= "Claimed" and typeof(row.BottomCFrame) == "CFrame" then
                    local distance = (row.BottomCFrame.Position - position).Magnitude
                    if distance <= 20 and (not target or distance < target.Distance) then target = {Uid = row.Uid, Row = row, Distance = distance} end
                end
            end
            if target then
                local record = utils.eggInfo(target.Uid, target.Row)
                if record and record.Position then
                    utils.flySafe(record.Position + Vector3.new(0, 3, 0), utils.route, 120)
                    local slot = utils.call(utils.modules.slotIdentity.LooksLikeFirstAreaUid, target.Uid)
                        and utils.call(utils.modules.slotIdentity.SlotKey, target.Row.AreaId, target.Row.NestId) or nil
                    utils.grab(target.Uid, slot)
                    return event.Name .. ": grabbing the minigame egg"
                end
            end
            utils.flySafe(position + Vector3.new(0, 3, 0), utils.route, 120)
            return event.Name .. ": moving to the minigame egg"
        end
    end
    return "No minigame event is active"
end

function utils.findPath(path)
    local instance = services.ReplicatedStorage
    for part in tostring(path):gmatch("[^.]+") do
        instance = instance and instance:FindFirstChild(part)
    end
    return instance
end

function utils.loadModules()
    for name, path in pairs({
        remotes = "Shared.Remotes",
        save = "Shared.Save",
        eggs = "Client.EggState",
        plots = "Client.PlotState",
        roster = "Client.AssetRoster",
        assets = "Data.Assets",
        rarities = "Data.Rarity",
        areas = "Data.Areas",
        trails = "Data.Trails",
        bases = "Data.Bases",
        treadmills = "Data.Treadmills",
        eggRecords = "Shared.Util.EggRecords",
        assetItems = "Shared.Util.AssetItems",
        earnings = "Shared.Util.AssetEarnings",
        slotIdentity = "Shared.Util.AreaEggSlotIdentity",
        mutations = "Shared.Modules.Mutations",
        halloweenPets = "Data.HalloweenPets",
        race = "Data.RaceRally",
        mountRace = "Data.MountRace",
        mastery = "Data.BossMastery",
        wisp = "Data.WispQuests",
        lightDark = "Data.LightVsDarkness",
        beanstalk = "Data.BeanstalkEvent"
    }) do
        local module = utils.findPath(path)
        if not module or not utils.load(name, module) then
            utils.message("Data", "Could not load " .. name .. "; rejoin and rerun")
            return false
        end
    end
    local optional = {
        scramble = "Data.ScrambleTradeIn",
        gears = "Data.Gears",
        halloweenMonsters = "Data.HalloweenMonsters",
        ghostDog = "Data.GhostDogQuest",
        trainEvent = "Data.TrainEvent",
        ragdoll = "Shared.Modules.Ragdoll",
        areaCycle = "Data.AreaEggResetCycle",
        areaWall = "Client.AreaEggResetWall"
    }
    for name, path in pairs(optional) do
        local module = utils.findPath(path)
        if module then
            local success, result = pcall(require, module)
            utils.identityReset()
            if success then utils.modules[name] = result end
        end
    end
    utils.message("Data", "Loaded")
    return true
end

function utils.buildOptions()
    local options = {Rarities = utils.keys(utils.modules.rarities.Rarities), Species = utils.keys(utils.modules.assets.Directory), Areas = {}, Mutations = {"Normal"}, Specific = {}, SpecificMap = {}, RarityLabels = {"Any"}, RarityRank = {}, RarityLabelMap = {["Any"] = "Any"}}
    for name in pairs(utils.call(utils.modules.mutations.Ids)) do table.insert(options.Mutations, name) end
    table.sort(options.Mutations)
    for _, row in pairs(utils.call(utils.modules.eggs.ReadFieldEggs).Records or {}) do
        if row.AreaId and not table.find(options.Areas, row.AreaId) then table.insert(options.Areas, row.AreaId) end
    end
    table.sort(options.Areas)
    for _, name in ipairs(options.Rarities) do
        local config = utils.modules.rarities.Rarities[name]
        if config then
            local label = tostring(config.Rank) .. " - " .. tostring(config.DisplayName or name)
            table.insert(options.RarityLabels, label)
            options.RarityRank[name] = config.Rank
            options.RarityLabelMap[label] = name
        end
    end
    options.RarityChoices = {"Any"}
    options.RarityChoicesOff = {"Off"}
    for _, name in ipairs(options.Rarities) do
        table.insert(options.RarityChoices, name)
        table.insert(options.RarityChoicesOff, name)
    end
    local used = {}
    for category, config in pairs(utils.modules.assets.Directory) do
        local rarity = config.Rarity and (config.Rarity.DisplayName or config.Rarity._id) or "?"
        local label = string.format("%s [%s]", config.DisplayName or category, rarity)
        if used[label] then label = label .. " (" .. tostring(category) .. ")" end
        used[label] = true
        table.insert(options.Specific, label)
        options.SpecificMap[label] = category
    end
    table.sort(options.Specific)
    options.Trails = utils.keys(utils.modules.trails.Directory)
    options.Racers = {"Best Owned"}
    for _, row in ipairs(utils.call(utils.modules.race.OrderedRacers)) do table.insert(options.Racers, row.Id) end
    options.RaceShop = {}
    for _, row in ipairs(utils.call(utils.modules.race.OrderedOffers)) do table.insert(options.RaceShop, row.Id) end
    options.BossShop = {}
    for _, offer in ipairs(utils.modules.mastery.ShopProducts) do table.insert(options.BossShop, offer.Id) end
    options.HalloweenSpecies = utils.keys(utils.modules.halloweenPets.Specs)
    options.MonsterKinds = {}
    local monsterData = utils.modules.halloweenMonsters
    if type(monsterData) == "table" then
        local directory = type(monsterData.Directory) == "table" and monsterData.Directory or monsterData
        for name in pairs(directory) do
            if type(name) == "string" and name ~= "Directory" then table.insert(options.MonsterKinds, name) end
        end
    end
    if #options.MonsterKinds == 0 then options.MonsterKinds = {"Small", "Medium", "Large"} end
    table.sort(options.MonsterKinds)
    options.LabBanners = {}
    local scramble = utils.modules.scramble
    if scramble then
        for id, banner in pairs(scramble.Banners or {}) do
            table.insert(options.LabBanners, tostring(banner.DisplayName or id))
        end
        table.sort(options.LabBanners)
    end
    options.PlayerNames = {}
    options.CategoryByLower = {}
    for category in pairs(utils.modules.assets.Directory) do
        options.CategoryByLower[tostring(category):lower()] = tostring(category)
    end
    for _, player in ipairs(services.Players:GetPlayers()) do
        if player ~= utils.player then table.insert(options.PlayerNames, player.Name) end
    end
    table.sort(options.PlayerNames)
    utils.options = options
end

function utils.multiSpecific(tab, text, settings, key, flag)
    if #utils.options.Specific == 0 then utils.options.Specific = {"None"} end
    local selected = {}
    for category, enabled in pairs(settings[key] or {}) do
        if enabled then
            for label, mapped in pairs(utils.options.SpecificMap) do
                if mapped == category then table.insert(selected, label) end
            end
        end
    end
    return tab:Dropdown({
        Title = text, Values = utils.options.Specific, Value = selected, Multi = true,
        SearchBarEnabled = true, Flag = flag,
        Callback = function(values)
            table.clear(settings[key])
            if type(values) == "table" then
                for _, label in pairs(values) do
                    local category = utils.options.SpecificMap[label]
                    if category then settings[key][category] = true end
                end
            end
        end
    })
end
function utils.rarityLabel(name)
    if name == "Any" or name == "Off" then return name end
    for label, mapped in pairs(utils.options.RarityLabelMap) do
        if mapped == name then return label end
    end
    return "Any"
end

function utils.buildFarm()
    utils.section(tabs.farm, "Auto Steal")
    utils.label(tabs.farm, "Steal", "Off")
    utils.job(tabs.farm, "Auto Steal", "Steal", 2, utils.steal, utils.stop)
    utils.action(tabs.farm, "Steal Egg", "Steal", utils.steal)
    utils.action(tabs.farm, "Steal Rarest Egg", "Steal", function() return utils.steal("Best Rarity", true) end)
    utils.action(tabs.farm, "Preview Target", "Steal", function()
        local target = utils.fieldEggs()[1]
        assert(target, "No eggs match your filters")
        utils.selection.Target = target.Uid
        return string.format("%s | %s | %.2f kg | %.0f studs", target.Category, target.Rarity, target.Weight, target.Distance)
    end)

    utils.section(tabs.farm, "Target Filters")
    utils.dropdown(tabs.farm, "Steal Priority", utils.settings.eggs, "Priority", {"Highest Value", "Best Rarity", "Biggest Weight", "Best Mutation", "Lowest Value", "Closest"}, "Eggs.Priority")
    tabs.farm.minRarity = utils.dropdown(tabs.farm, "Minimum Rarity", utils.settings.eggs, "MinRarity", utils.options.RarityChoices, "Eggs.MinRarity")
    utils.multi(tabs.farm, "Rarities", utils.settings.eggs, "Rarities", utils.options.Rarities, "Eggs.Rarities")
    utils.multi(tabs.farm, "Areas", utils.settings.eggs, "Areas", utils.options.Areas, "Eggs.Areas")
    utils.multi(tabs.farm, "Mutations", utils.settings.eggs, "Mutations", utils.options.Mutations, "Eggs.Mutations")
    utils.textSet(tabs.farm, "Species (comma separated)", utils.settings.eggs, "Species", "Eggs.Species")
    utils.textSet(tabs.farm, "Target Specific Eggs (categories)", utils.settings.eggs, "Specific", "Eggs.Specific")
    utils.multi(tabs.farm, "Target Areas", utils.settings.eggs, "TargetAreas", utils.options.Areas, "Eggs.TargetAreas")
    utils.number(tabs.farm, "Minimum Weight (kg)", utils.settings.eggs, "MinWeight", "Eggs.MinWeight")
    utils.number(tabs.farm, "Minimum Income /s", utils.settings.eggs, "MinValue", "Eggs.MinValue")
    utils.toggle(tabs.farm, "Drop At Safe Zone", utils.settings.eggs, "SafeZone", "Eggs.SafeZone")
    utils.toggle(tabs.farm, "Wait For Night Reset", utils.settings.eggs, "NightWait", "Eggs.NightWait")
    utils.toggle(tabs.farm, "Skip Guarded Eggs", utils.settings.eggs, "AntiGuard", "Eggs.AntiGuard")
    utils.toggle(tabs.farm, "Steal Missing Index Eggs", utils.settings.eggs, "Index", "Eggs.Index")
    utils.toggle(tabs.farm, "Steal Missing Lab Eggs", utils.settings.eggs, "Lab", "Eggs.Lab")

    utils.section(tabs.farm, "Travel")
    utils.dropdown(tabs.farm, "Travel Method", utils.settings.travel, "Mode", {"Walk", "Tween", "Step"}, "Travel.Mode")
    utils.slider(tabs.farm, "Travel Speed", utils.settings.travel, "Speed", 20, 500, 5, "Travel.Speed")
    utils.action(tabs.farm, "Drop Carried Egg", "Steal", function() utils.drop(); return "Egg dropped" end)
    utils.action(tabs.farm, "Return Home", "Steal", function()
        utils.stop()
        assert(utils.home(), "Return route cancelled")
        return "At your plot"
    end)
    utils.action(tabs.farm, "Stop Route", "Steal", function() utils.stop(); return "Stopped" end)

    utils.section(tabs.farm, "Auto Place")
    utils.label(tabs.farm, "Place", "Off")
    utils.job(tabs.farm, "Auto Place Egg", "Place", 3, utils.place, utils.stop)
    utils.action(tabs.farm, "Place Inventory", "Place", utils.place)
    utils.dropdown(tabs.farm, "Place Rule", utils.settings.place, "Mode", {"Always", "Steal Idle", "After Steal", "Night Only"}, "Place.Mode")
    utils.dropdown(tabs.farm, "Place Order", utils.settings.place, "Order", {"Highest Value", "Biggest Size", "Smallest Size", "Backpack Order"}, "Place.Order")
    utils.multi(tabs.farm, "Place Rarities", utils.settings.place, "Rarities", utils.options.Rarities, "Place.Rarities")
    utils.textSet(tabs.farm, "Place Specific Eggs (categories)", utils.settings.place, "Specific", "Place.Specific")
    utils.number(tabs.farm, "Minimum Place Income /s", utils.settings.place, "MinValue", "Place.MinValue")
    utils.number(tabs.farm, "Minimum Place Weight", utils.settings.place, "MinWeight", "Place.MinWeight")
    utils.slider(tabs.farm, "Place Spacing", utils.settings.place, "Spacing", 2, 16, 1, "Place.Spacing")

    utils.section(tabs.farm, "Auto Hatch")
    utils.slider(tabs.farm, "Hatch Delay", utils.settings.hatch, "Delay", 0, 10, 0.1, "Hatch.Delay")
    utils.label(tabs.farm, "Hatch", "Off")
    utils.job(tabs.farm, "Auto Hatch", "Hatch", 2, utils.hatch)
    utils.action(tabs.farm, "Hatch Eggs", "Hatch", utils.hatch)

    utils.section(tabs.farm, "Session")
    utils.label(tabs.farm, "Runtime", "Running")
    utils.label(tabs.farm, "Dashboard", "Loading")
    utils.action(tabs.farm, "Stop All Automation", "Runtime", function()
        for key, job in pairs(utils.jobs) do
            if utils.controls[key .. "Switch"] then utils.controls[key .. "Switch"]:Set(false) else job.Enabled = false end
            if job.Thread and coroutine.status(job.Thread) ~= "dead" then
                pcall(task.cancel, job.Thread)
                runtime.Threads[job.Thread] = nil
            end
            job.Thread = nil
            job.Busy = false
        end
        utils.featureOwner = nil
        table.clear(utils.pipeline.Requests)
        utils.cancelPipeline()
        utils.message("Runtime", "Automation stopped")
        return "Stopped"
    end)
end

function utils.buildAutomation()
    utils.section(tabs.automation, "Auto Treadmill")
    utils.label(tabs.automation, "Treadmill", "Off")
    utils.job(tabs.automation, "Auto Treadmill", "Treadmill", 3, function()
        assert(not utils.moving, "Paused during egg automation")
        utils.net("RF/Treadmill/AskWearStill")
        return "On the treadmill"
    end, function() pcall(utils.net, "RF/Treadmill/AskDoff") end)
    utils.slider(tabs.automation, "Treadmill Level Limit", utils.settings.treadmill, "MaxLevel", 1, 100, 1, "Treadmill.MaxLevel")
    utils.label(tabs.automation, "TreadmillUpgrade", "Off")
    utils.job(tabs.automation, "Auto Upgrade Treadmill", "TreadmillUpgrade", 3, utils.upgradeTreadmill)
    utils.action(tabs.automation, "Upgrade Treadmill", "TreadmillUpgrade", utils.upgradeTreadmill)
    utils.label(tabs.automation, "PenUpgrade", "Off")
    utils.job(tabs.automation, "Auto Upgrade Pen", "PenUpgrade", 4, utils.upgradePen)
    utils.action(tabs.automation, "Upgrade Pen", "PenUpgrade", utils.upgradePen)

    utils.section(tabs.automation, "Auto Equip")
    utils.label(tabs.automation, "Equip", "Off")
    utils.job(tabs.automation, "Auto Equip Best", "Equip", function() return utils.settings.pets.Interval end, utils.equipBest)
    utils.action(tabs.automation, "Equip Best", "Equip", utils.equipBest)
    utils.slider(tabs.automation, "Equip Interval", utils.settings.pets, "Interval", 5, 60, 1, "Pets.Interval")

    utils.section(tabs.automation, "Auto Fuse")
    utils.dropdown(tabs.automation, "Maximum Rarity", utils.settings.fuse, "MaxRarity", utils.options.Rarities, "Fuse.MaxRarity")
    utils.textSet(tabs.automation, "Species To Fuse (categories)", utils.settings.fuse, "Species", "Fuse.Species")
    utils.dropdown(tabs.automation, "Fuse Priority", utils.settings.fuse, "Priority", {"Best Rarity", "Highest Value"}, "Fuse.Priority")
    utils.toggle(tabs.automation, "Skip Mutated Pets", utils.settings.fuse, "SkipMutated", "Fuse.SkipMutated")
    utils.toggle(tabs.automation, "Eject Incomplete Slots", utils.settings.fuse, "EjectIncomplete", "Fuse.EjectIncomplete")
    utils.label(tabs.automation, "Fuse", "Off")
    utils.job(tabs.automation, "Auto Fuse", "Fuse", 5, utils.fuse)
    utils.action(tabs.automation, "Fuse Pets", "Fuse", utils.fuse)

    utils.section(tabs.automation, "Auto Favorite")
    utils.dropdown(tabs.automation, "Favorite Rule", utils.settings.favorite, "Rule", {"Match All", "Match Any"}, "Favorite.Rule")
    tabs.automation.favoriteRarity = utils.dropdown(tabs.automation, "Favorite Min Rarity", utils.settings.favorite, "MinRarity", utils.options.RarityChoicesOff, "Favorite.MinRarity")
    local favoriteMutations = table.clone(utils.options.Mutations)
    table.insert(favoriteMutations, 1, "Any Mutation")
    utils.multi(tabs.automation, "Favorite Mutations", utils.settings.favorite, "Mutations", favoriteMutations, "Favorite.Mutations")
    utils.number(tabs.automation, "Favorite Min Income /s", utils.settings.favorite, "Value", "Favorite.Value")
    utils.textSet(tabs.automation, "Always Favorite Species (categories)", utils.settings.favorite, "Always", "Favorite.Always")
    utils.label(tabs.automation, "Favorite", "Off")
    utils.job(tabs.automation, "Auto Favorite", "Favorite", 4, function()
        if not utils.favouriteSettingsActive(utils.settings.favorite) then return "Choose a favorite rule first" end
        return utils.favouritePets(false)
    end)
    utils.action(tabs.automation, "Favorite Pets", "Favorite", function() return utils.favouritePets(false) end)
    utils.job(tabs.automation, "Auto Favorite Equipped", "FavoriteEquipped", 4, function()
        return utils.favouritePets(false, true)
    end)
    utils.job(tabs.automation, "Auto Unfavorite Equipped", "UnfavoriteEquipped", 4, function()
        return utils.favouritePets(true, true)
    end)
    utils.action(tabs.automation, "Unfavorite Equipped Now", "Favorite", function() return utils.favouritePets(true, true) end)

    utils.section(tabs.automation, "Auto Mutation")
    utils.textSet(tabs.automation, "Mutate Target Eggs (categories)", utils.settings.mutation, "Targets", "Mutation.Targets")
    utils.multi(tabs.automation, "Mutations To Use", utils.settings.mutation, "Mutations", {"Fractured", "Scrambled", "Enchanted", "Nitro"}, "Mutation.Mutations")
    tabs.automation.mutationRarity = utils.dropdown(tabs.automation, "Mutate Min Rarity", utils.settings.mutation, "MinRarity", utils.options.RarityChoices, "Mutation.MinRarity")
    utils.number(tabs.automation, "Mutate Min Income /s", utils.settings.mutation, "MinValue", "Mutation.MinValue")
    utils.dropdown(tabs.automation, "Mutate Priority", utils.settings.mutation, "Priority", {"Highest Value", "Best Rarity", "Biggest Size"}, "Mutation.Priority")
    utils.toggle(tabs.automation, "Auto Buy Nitro", utils.settings.mutation, "BuyNitro", "Mutation.BuyNitro")
    utils.label(tabs.automation, "Mutation", "Off")
    utils.job(tabs.automation, "Auto Mutate", "Mutation", 1, function()
        if next(utils.settings.mutation.Mutations) == nil then return "Pick a mutation first" end
        return utils.useMutation()
    end)
    utils.action(tabs.automation, "Apply Mutation", "Mutation", utils.useMutation)


end

function utils.predictorText()
    local owned = utils.call(utils.modules.eggs.ReadOwnerEggs, utils.player.UserId)
    local ready, growing, bag = 0, 0, 0
    for uid, row in pairs(owned) do
        if row.Placement then
            if utils.call(utils.modules.eggs.IsReadyToHatch, uid) then ready += 1 else growing += 1 end
        else
            bag += 1
        end
    end
    return string.format("Eggs: %d | Ready: %d | Growing: %d | In Bag: %d", ready + growing + bag, ready, growing, bag)
end

function utils.labPredictorText()
    local state = utils.labState()
    if not state then return "Lab data unavailable" end
    if state.Unlocked ~= true then return "Lab locked" end
    return string.format("%s | Pity: %s/%s | Free rerolls: %s",
        tostring(state.BannerDisplayName or state.BannerId or "Unknown banner"),
        tostring(state.PityCount or 0), tostring(state.PityThreshold or 0),
        tostring(state.FreeRefreshesRemaining or 0))
end

function utils.fusePredictorText()
    local save = utils.save()
    local groups = {}
    local limit = utils.rarityRank(utils.settings.fuse.MaxRarity)
    for _, item in pairs(save.Inventory or {}) do
        local config = utils.modules.assets.Directory[item.Category]
        if config and config.Rarity.Rank <= limit and not item.InFuse and not item.IsFavorite then
            groups[item.Category] = (groups[item.Category] or 0) + 1
        end
    end
    local ready = 0
    for _, count in pairs(groups) do if count >= 3 then ready += 1 end end
    return ready .. " fuse group(s) ready"
end

function utils.buildInventory()
    utils.section(tabs.inventory, "Sell Eggs")
    utils.dropdown(tabs.inventory, "Sell Egg Rule", utils.settings.sell.Eggs, "Rule", {"Rarity Only", "Value Only", "Rarity And Value", "Rarity Or Value"}, "Sell.Eggs.Rule")
    utils.dropdown(tabs.inventory, "Egg Max Rarity", utils.settings.sell.Eggs, "MaxRarity", {"Off", table.unpack(utils.options.Rarities)}, "Sell.Eggs.MaxRarity")
    utils.number(tabs.inventory, "Egg Sell Income /s", utils.settings.sell.Eggs, "Value", "Sell.Eggs.Value")
    utils.toggle(tabs.inventory, "Keep Mutated Eggs", utils.settings.sell.Eggs, "KeepMutated", "Sell.Eggs.KeepMutated")
    utils.toggle(tabs.inventory, "Keep Halloween Eggs", utils.settings.sell.Eggs, "ProtectHalloween", "Sell.Eggs.ProtectHalloween")
    utils.textSet(tabs.inventory, "Blacklist Sell Eggs (categories)", utils.settings.sell.Eggs, "Blacklist", "Sell.Eggs.Blacklist")
    utils.label(tabs.inventory, "EggSell", "Off")
    utils.job(tabs.inventory, "Auto Sell Eggs", "EggSell", 5, utils.sellEggs)
    utils.action(tabs.inventory, "Sell Eggs Now", "EggSell", utils.sellEggs)

    utils.section(tabs.inventory, "Sell Pets")
    utils.dropdown(tabs.inventory, "Sell Pet Rule", utils.settings.sell.Pets, "Rule", {"Rarity Only", "Value Only", "Rarity And Value", "Rarity Or Value"}, "Sell.Pets.Rule")
    utils.dropdown(tabs.inventory, "Pet Max Rarity", utils.settings.sell.Pets, "MaxRarity", {"Off", table.unpack(utils.options.Rarities)}, "Sell.Pets.MaxRarity")
    utils.number(tabs.inventory, "Pet Sell Income /s", utils.settings.sell.Pets, "Value", "Sell.Pets.Value")
    utils.toggle(tabs.inventory, "Keep Mutated Pets", utils.settings.sell.Pets, "KeepMutated", "Sell.Pets.KeepMutated")
    utils.toggle(tabs.inventory, "Unequip Before Selling", utils.settings.sell.Pets, "Unequip", "Sell.Pets.Unequip")
    utils.textSet(tabs.inventory, "Blacklist Sell Pets (categories)", utils.settings.sell.Pets, "Blacklist", "Sell.Pets.Blacklist")
    utils.slider(tabs.inventory, "Keep Best Pets", utils.settings.sell, "KeepBest", 1, 30, 1, "Sell.KeepBest")
    utils.label(tabs.inventory, "PetSell", "Off")
    utils.job(tabs.inventory, "Auto Sell Pets", "PetSell", 5, utils.sellPets)
    utils.action(tabs.inventory, "Sell Pets Now", "PetSell", utils.sellPets)

    utils.section(tabs.inventory, "Sell Lab Eggs")
    utils.dropdown(tabs.inventory, "Lab Egg Rule", utils.settings.sell.Lab, "Rule", {"Rarity Only", "Value Only", "Rarity And Value", "Rarity Or Value"}, "Sell.Lab.Rule")
    utils.dropdown(tabs.inventory, "Lab Egg Max Rarity", utils.settings.sell.Lab, "MaxRarity", {"Off", table.unpack(utils.options.Rarities)}, "Sell.Lab.MaxRarity")
    utils.number(tabs.inventory, "Lab Egg Sell Income /s", utils.settings.sell.Lab, "Value", "Sell.Lab.Value")
    utils.toggle(tabs.inventory, "Keep Mutated Lab Eggs", utils.settings.sell.Lab, "KeepMutated", "Sell.Lab.KeepMutated")
    utils.textSet(tabs.inventory, "Keep Lab Pets (categories)", utils.settings.sell.Lab, "KeepPets", "Sell.Lab.KeepPets")
    utils.label(tabs.inventory, "LabSell", "Off")
    utils.job(tabs.inventory, "Auto Sell Lab Eggs", "LabSell", 5, utils.sellLabEggs)
    utils.action(tabs.inventory, "Sell Lab Eggs Now", "LabSell", utils.sellLabEggs)

    utils.section(tabs.inventory, "Lab Trade-In")
    utils.label(tabs.inventory, "Lab", "Idle")
    utils.multi(tabs.inventory, "Lab Banners", utils.settings.lab, "Banners", utils.options.LabBanners, "Lab.Banners")
    utils.toggle(tabs.inventory, "Auto Reroll Lab Recipe", utils.settings.lab, "Reroll", "Lab.Reroll")
    utils.job(tabs.inventory, "Auto Lab", "Lab", 2, function()
        return utils.labTrade()
    end)
    utils.action(tabs.inventory, "Trade In Lab Recipe", "Lab", utils.labTrade)

    utils.section(tabs.inventory, "Progression")
    utils.label(tabs.inventory, "Collect", "Off")
    utils.job(tabs.inventory, "Auto Collect", "Collect", 15, function()
        local messages = {}
        local success, result = pcall(utils.claimOffline)
        table.insert(messages, success and result or tostring(result))
        local codexSuccess, codex = pcall(utils.claimCodex)
        if codexSuccess then table.insert(messages, codex) end
        return table.concat(messages, " | ")
    end)
    utils.action(tabs.inventory, "Claim Offline & Codex Now", "Collect", function()
        local success, result = pcall(utils.claimOffline)
        local codexSuccess, codex = pcall(utils.claimCodex)
        return tostring(success and result or result) .. " | " .. tostring(codexSuccess and codex or codex)
    end)
    utils.label(tabs.inventory, "Trails", "Off")
    utils.multi(tabs.inventory, "Selected Trails", utils.settings.trails, "Selected", utils.options.Trails, "Trails.Selected")
    utils.job(tabs.inventory, "Auto Buy Selected Trails", "Trails", 5, function() return utils.buyTrails(false) end)
    utils.action(tabs.inventory, "Buy Selected Trails", "Trails", function() return utils.buyTrails(false) end)
    utils.job(tabs.inventory, "Auto Buy All Trails", "AllTrails", 5, function() return utils.buyTrails(true) end)
    utils.action(tabs.inventory, "Buy All Cash Trails", "AllTrails", function() return utils.buyTrails(true) end)
    utils.label(tabs.inventory, "EquipTrail", "Off")
    utils.job(tabs.inventory, "Auto Equip Best Trail", "EquipTrail", 10, utils.equipTrail)
    utils.action(tabs.inventory, "Equip Best Trail", "EquipTrail", utils.equipTrail)

    utils.section(tabs.inventory, "Predictors")
    utils.label(tabs.inventory, "EggPredictor", "Loading")
    utils.label(tabs.inventory, "LabPredictor", "Loading")
    utils.label(tabs.inventory, "FusePredictor", "Loading")
    utils.action(tabs.inventory, "Refresh Predictors", "Predictor", function()
        utils.message("EggPredictor", utils.predictorText())
        utils.message("LabPredictor", utils.labPredictorText())
        utils.message("FusePredictor", utils.fusePredictorText())
        return "Predictors refreshed"
    end)
end
function utils.buildEvents()
    utils.section(tabs.events, "Halloween Dimension")
    utils.label(tabs.events, "Halloween", "Off")
    utils.job(tabs.events, "Auto Steal Halloween Eggs", "HalloweenSteal", 3, utils.halloweenSteal, utils.stop)
    utils.action(tabs.events, "Collect Halloween Egg", "HalloweenSteal", utils.halloweenSteal)
    utils.slider(tabs.events, "Halloween Steal Speed", utils.settings.halloween, "Speed", 10, 100, 5, "Halloween.Speed")
    utils.multi(tabs.events, "Halloween Egg Rarities", utils.settings.halloween, "Rarities", utils.options.Rarities, "Halloween.Rarities")
    utils.multi(tabs.events, "Halloween Eggs To Steal", utils.settings.halloween, "Species", utils.options.HalloweenSpecies, "Halloween.Species")
    utils.multi(tabs.events, "Halloween Zones", utils.settings.halloween, "Zones", {"1", "2", "3"}, "Halloween.Zones")
    utils.number(tabs.events, "Halloween Min Income /s", utils.settings.halloween, "MinValue", "Halloween.MinValue")
    utils.dropdown(tabs.events, "Halloween Priority", utils.settings.halloween, "Priority", {"Value", "Rarity", "Closest"}, "Halloween.Priority")
    utils.action(tabs.events, "Drop Halloween Egg", "HalloweenSteal", function() utils.net("RF/HalloweenDimension/AskDropEgg"); return "Drop requested" end)
    utils.job(tabs.events, "Auto Buy Dimension Egg", "HalloweenBuy", 10, function() utils.net("RF/HalloweenDimension/AskBuyEgg"); return "Dimension egg purchased" end)

    utils.section(tabs.events, "Halloween Monsters")
    utils.label(tabs.events, "Monsters", "Off")
    utils.job(tabs.events, "Auto Farm Monsters", "HalloweenMonsters", 1, utils.halloweenMonsters)
    utils.multi(tabs.events, "Monsters To Kill", utils.settings.halloween, "MonsterKinds", utils.options.MonsterKinds, "Halloween.MonsterKinds")
    utils.dropdown(tabs.events, "Monster Order", utils.settings.halloween, "MonsterOrder", {"Closest", "Most Tokens"}, "Halloween.MonsterOrder")
    utils.slider(tabs.events, "Monster Walk Speed", utils.settings.halloween, "MonsterSpeed", 100, 1000, 10, "Halloween.MonsterSpeed")

    utils.section(tabs.events, "Halloween Events")
    utils.label(tabs.events, "Pumpkin", "Off")
    utils.job(tabs.events, "Auto Pumpkin Moon", "Pumpkin", 2, function()
        return utils.halloweenPumpkin()
    end)
    utils.label(tabs.events, "GhostDog", "Off")
    utils.job(tabs.events, "Auto Ghost Dog Quest", "GhostDog", 2, function()
        return utils.ghostDogQuest()
    end)
    utils.dropdown(tabs.events, "Cast Luck", utils.settings.halloween, "CastLuck", {"x1.5 Perfect", "x1.2", "x1.1", "x1.0 Fastest"}, "Halloween.CastLuck")
    utils.label(tabs.events, "Fishing", "Off")
    utils.job(tabs.events, "Auto Fishing", "Fishing", 2, function()
        return utils.fishing()
    end)

    utils.section(tabs.events, "Phantom Express")
    utils.label(tabs.events, "Train", "Off")
    utils.job(tabs.events, "Auto Phantom Express", "Train", 2, function()
        return utils.phantomExpress()
    end)
    utils.toggle(tabs.events, "Auto Vacuum Ghouler Boss", utils.settings.train, "Vacuum", "Train.Vacuum")
    utils.slider(tabs.events, "Train Walk Speed", utils.settings.train, "Speed", 100, 1000, 10, "Train.Speed")
    utils.toggle(tabs.events, "Auto Trade Souls", utils.settings.train, "TradeSouls", "Train.TradeSouls")

    utils.section(tabs.events, "Cursed Island Wars")
    utils.label(tabs.events, "Islands", "Off")
    utils.job(tabs.events, "Auto Play Cursed Island Wars", "Islands", 1, function()
        return utils.islandWars()
    end)

    utils.section(tabs.events, "Shooting Star")
    utils.label(tabs.events, "Star", "Off")
    utils.job(tabs.events, "Auto Catch Shooting Star", "Star", 1, function()
        return utils.catchStar()
    end)

    utils.section(tabs.events, "Race Rally")
    utils.label(tabs.events, "RaceRewards", "Off")
    utils.job(tabs.events, "Auto Claim Race Rewards", "RaceRewards", 10, utils.claimRace)
    utils.action(tabs.events, "Claim Race Rewards", "RaceRewards", utils.claimRace)
    utils.dropdown(tabs.events, "Racer", utils.settings.race, "Racer", utils.options.Racers, "Race.Racer")
    utils.label(tabs.events, "Racer", "Off")
    utils.job(tabs.events, "Auto Equip Racer", "Racer", 10, utils.equipRacer)
    utils.action(tabs.events, "Equip Racer", "Racer", utils.equipRacer)
    utils.multi(tabs.events, "Race Shop Items", utils.settings.race, "Shop", utils.options.RaceShop, "Race.Shop")
    utils.number(tabs.events, "Trophy Reserve", utils.settings.race, "Reserve", "Race.Reserve")
    utils.label(tabs.events, "RaceShop", "Off")
    utils.job(tabs.events, "Auto Buy Race Items", "RaceShop", 8, utils.buyRaceShop)
    utils.action(tabs.events, "Buy Race Items", "RaceShop", utils.buyRaceShop)
    utils.action(tabs.events, "Go To Race Portal", "RaceJoin", function()
        local world = services.Workspace:FindFirstChild("World")
        return utils.visit(world and world:FindFirstChild("RaceRallyPortal"))
    end)

    utils.section(tabs.events, "Boss & Mastery")
    utils.label(tabs.events, "Boss", "Off")
    utils.action(tabs.events, "Enter Rift", "Boss", function() utils.remote("BossEvent", "AskEnter"); return "Rift entry requested" end)
    utils.label(tabs.events, "Mastery", "Off")
    utils.job(tabs.events, "Auto Claim Mastery", "Mastery", 10, utils.claimMastery)
    utils.action(tabs.events, "Claim Mastery", "Mastery", utils.claimMastery)
    utils.multi(tabs.events, "Boss Shop Items", utils.settings.mastery, "Shop", utils.options.BossShop, "Boss.Shop")
    utils.number(tabs.events, "Token Reserve", utils.settings.mastery, "Reserve", "Boss.Reserve")
    utils.label(tabs.events, "BossShop", "Off")
    utils.job(tabs.events, "Auto Buy Boss Items", "BossShop", 8, utils.buyBossShop)
    utils.action(tabs.events, "Buy Boss Items", "BossShop", utils.buyBossShop)

    utils.section(tabs.events, "Light vs Darkness")
    utils.dropdown(tabs.events, "Team", utils.settings.lightDark, "Team", {"Light", "Darkness"}, "LightDark.Team")
    utils.label(tabs.events, "LightTeam", "Off")
    utils.action(tabs.events, "Join Team", "LightTeam", function()
        utils.remote("LightVsDarkness", "AskSelectTeam", utils.settings.lightDark.Team)
        return "Team selection requested"
    end)
    utils.label(tabs.events, "LightRings", "Off")
    utils.job(tabs.events, "Collect Rings", "LightRings", 1, function() return utils.collectFolder("LightVsDarknessRings") end, utils.stop)
    utils.label(tabs.events, "LightPowerUps", "Off")
    utils.job(tabs.events, "Collect Power-Ups", "LightPowerUps", 1, function() return utils.collectFolder("LightVsDarknessPowerUps") end, utils.stop)
    utils.label(tabs.events, "LightRewards", "Off")
    utils.job(tabs.events, "Claim LvD Milestones", "LightRewards", 5, function()
        local collected = utils.player:GetAttribute("LvdRingsCollected") or 0
        local count = 0
        for index, milestone in ipairs(utils.modules.lightDark.MILESTONES) do
            local attribute = utils.call(utils.modules.lightDark.MilestoneAttribute, index)
            if collected >= milestone.Rings and not utils.player:GetAttribute(attribute) then
                utils.remote("LightVsDarkness", "AskClaimMilestone", index)
                count += 1
            end
        end
        return count .. " milestone claims requested"
    end)

    utils.section(tabs.events, "Sammy & Beanstalk")
    utils.label(tabs.events, "Sammy", "Off")
    utils.job(tabs.events, "Collect Sammy Pickups", "Sammy", 1, function() return utils.collectFolder("SammyEmpPickups") end, utils.stop)
    utils.label(tabs.events, "Beanstalk", "Off")
    utils.job(tabs.events, "Beanstalk Assist", "Beanstalk", 1, function()
        local stage = utils.player:GetAttribute(utils.modules.beanstalk.StageAttribute)
        if not utils.player:GetAttribute(utils.modules.beanstalk.ParticipatingAttribute) then return "Join the Beanstalk event first" end
        if stage == utils.modules.beanstalk.Stage.Fireflies then
            utils.remote("BeanstalkEvent", "AskCatchFirefly")
            return "Firefly catch requested"
        elseif stage == utils.modules.beanstalk.Stage.Watering then
            utils.remote("BeanstalkEvent", "AskPour")
            return "Watering requested"
        elseif stage == utils.modules.beanstalk.Stage.Complete then
            if not utils.player:GetAttribute(utils.modules.beanstalk.ClaimedAttribute) then utils.remote("BeanstalkEvent", "AskClaimReward", false) end
            return "Reward claim requested"
        end
        return "Waiting for the Beanstalk stage"
    end)
end

function utils.buildMinigames()
    utils.section(tabs.minigames, "Minigame Eggs")
    utils.label(tabs.minigames, "Minigame", "Off")
    utils.job(tabs.minigames, "Auto Steal Minigame Egg", "Minigame", 1, utils.minigameEgg)

    utils.section(tabs.minigames, "Capture The Egg")
    utils.label(tabs.minigames, "Capture", "Off")
    utils.job(tabs.minigames, "Auto Capture Event Egg", "Capture", 1, function()
        return utils.captureEgg()
    end)
    utils.toggle(tabs.minigames, "Take It From The Holder", utils.settings.capture, "Take", "Capture.Take")
    utils.slider(tabs.minigames, "Hold Height", utils.settings.capture, "Height", 20, 120, 5, "Capture.Height")
    utils.slider(tabs.minigames, "Keep Away Distance", utils.settings.capture, "KeepAway", 20, 150, 5, "Capture.KeepAway")

    utils.section(tabs.minigames, "Butterfly Bloom")
    utils.label(tabs.minigames, "Butterfly", "Off")
    utils.job(tabs.minigames, "Auto Butterfly Bloom", "Butterfly", 1, function()
        return utils.butterfly()
    end)
    utils.dropdown(tabs.minigames, "Catch Priority", utils.settings.butterfly, "Priority", {"Rarest", "Nearest"}, "Butterfly.Priority")
    utils.multi(tabs.minigames, "Catch Butterflies", utils.settings.butterfly, "Species", {"Radiant Butterfly", "Amethyst Butterfly", "Sapphire Butterfly", "Emerald Butterfly"}, "Butterfly.Species")
    utils.slider(tabs.minigames, "Butterfly Speed", utils.settings.butterfly, "Speed", 100, 600, 10, "Butterfly.Speed")
    utils.toggle(tabs.minigames, "Auto Trade Up", utils.settings.butterfly, "TradeUp", "Butterfly.TradeUp")
    utils.toggle(tabs.minigames, "Auto Craft Essence", utils.settings.butterfly, "Essence", "Butterfly.Essence")

    utils.section(tabs.minigames, "Quest Automation")
    utils.job(tabs.minigames, "Auto Wisp", "Wisp", 10, function()
        return utils.wisp()
    end)
    utils.label(tabs.minigames, "Wisp", "Off")
    utils.job(tabs.minigames, "Auto Banjo Cricket", "Banjo", 3, function()
        return utils.banjo()
    end)
    utils.label(tabs.minigames, "Banjo", "Off")


end

function utils.buildEsp()
    utils.section(tabs.esp, "Egg ESP")
    utils.toggle(tabs.esp, "ESP Eggs", utils.settings.visuals, "Eggs", "ESP.Eggs")
    utils.toggle(tabs.esp, "Own Base Eggs", utils.settings.visuals, "OwnBase", "ESP.OwnBase")
    utils.toggle(tabs.esp, "Other Base Eggs", utils.settings.visuals, "OtherBase", "ESP.OtherBase")
    utils.toggle(tabs.esp, "Highlight Eggs", utils.settings.visuals, "Highlight", "ESP.Highlight")
    tabs.esp.rarity = utils.dropdown(tabs.esp, "ESP Min Rarity", utils.settings.visuals, "MinRarity", utils.options.RarityChoices, "ESP.MinRarity")
    utils.number(tabs.esp, "ESP Min Income /s", utils.settings.visuals, "MinValue", "ESP.MinValue")
    utils.multi(tabs.esp, "ESP Show Info", utils.settings.visuals, "Info", {"Name", "Rarity", "Mutation", "Value", "Weight", "Size", "Sell", "Distance", "Area", "State"}, "ESP.Info")
    utils.multi(tabs.esp, "ESP Egg Rarities", utils.settings.visuals, "Rarities", utils.options.Rarities, "ESP.Rarities")
    utils.multi(tabs.esp, "ESP Egg Mutations", utils.settings.visuals, "Mutations", utils.options.Mutations, "ESP.Mutations")
    utils.slider(tabs.esp, "ESP View Distance", utils.settings.visuals, "Distance", 50, 10000, 50, "ESP.Distance")
    utils.slider(tabs.esp, "ESP Label Size", utils.settings.visuals, "Size", 50, 200, 5, "ESP.Size")

    utils.section(tabs.esp, "Other ESP")
    utils.toggle(tabs.esp, "ESP Guards", utils.settings.visuals, "Guards", "ESP.Guards")
    utils.toggle(tabs.esp, "ESP Players", utils.settings.visuals, "Players", "ESP.Players")
    utils.label(tabs.esp, "ESP", "Off")
    utils.action(tabs.esp, "Refresh ESP", "ESP", function() return utils.esp() end)
end

function utils.buildCharacter()
    utils.section(tabs.character, "Movement")
    utils.slider(tabs.character, "Walk Speed", utils.settings.player, "Speed", 8, 2000, 1, "Player.Speed")
    utils.toggle(tabs.character, "Custom Speed", utils.settings.player, "SpeedEnabled", "Player.SpeedEnabled")
    utils.slider(tabs.character, "Jump Power", utils.settings.player, "JumpPower", 20, 400, 1, "Player.JumpPower")
    utils.toggle(tabs.character, "Custom Jump", utils.settings.player, "JumpEnabled", "Player.JumpEnabled")
    utils.toggle(tabs.character, "Infinite Jump", utils.settings.player, "InfiniteJump", "Player.InfiniteJump")
    utils.section(tabs.character, "Safety")
    utils.toggle(tabs.character, "Anti Ragdoll", utils.settings.player, "AntiRagdoll", "Player.AntiRagdoll")
    utils.toggle(tabs.character, "Anti Void", utils.settings.player, "AntiVoid", "Player.AntiVoid")
    utils.toggle(tabs.character, "Anti Trap", utils.settings.player, "AntiTrap", "Player.AntiTrap")
    utils.toggle(tabs.character, "Instant Prompts", utils.settings.player, "InstantPrompts", "Player.InstantPrompts")
    utils.toggle(tabs.character, "Invisibility", utils.settings.player, "Invisibility", "Player.Invisibility")
    utils.label(tabs.character, "Movement", "Server movement rules may override local settings")
end

function utils.buildCombat()
    utils.section(tabs.combat, "Auto Hit")
    utils.dropdown(tabs.combat, "Combat Mode", utils.settings.combat, "Mode", {"Off", "Nearest", "Egg Holders", "Specific Player", "Hit Aura"}, "Combat.Mode")
    tabs.combat.target = utils.dropdown(tabs.combat, "Hit Player", utils.settings.combat, "Target", utils.options.PlayerNames, "Combat.Target")
    utils.slider(tabs.combat, "Hit Tween Speed", utils.settings.combat, "Speed", 100, 1000, 10, "Combat.Speed")
    utils.slider(tabs.combat, "Hit Max Speed", utils.settings.combat, "MaxSpeed", 100, 1000, 10, "Combat.MaxSpeed")
    utils.slider(tabs.combat, "Hit Lead", utils.settings.combat, "Lead", -400, 100, 1, "Combat.Lead")
    utils.slider(tabs.combat, "Hit Sweep", utils.settings.combat, "Sweep", 0, 250, 1, "Combat.Sweep")
    utils.label(tabs.combat, "Combat", "Off")
    utils.action(tabs.combat, "Refresh Player List", "Combat", function()
        local names = {}
        for _, player in ipairs(services.Players:GetPlayers()) do if player ~= utils.player then table.insert(names, player.Name) end end
        table.sort(names)
        utils.options.PlayerNames = names
        tabs.combat.target:Refresh(names)
        return "Player list refreshed"
    end)
end
function utils.hopMatches(info, row)
    local settings = utils.settings.hop
    if not info then return false end
    if settings.Sync then
        return utils.matchesFilters(info, row, utils.settings.eggs)
    end
    if settings.MinRarity ~= "Any" and info.Rank < utils.rarityRank(settings.MinRarity) then return false end
    if next(settings.Rarities) ~= nil and not settings.Rarities[info.Rarity] then return false end
    if next(settings.Areas) ~= nil and not settings.Areas[row.AreaId] then return false end
    if next(settings.Specific) ~= nil and not settings.Specific[row.AssetCategory] then return false end
    if info.Income < settings.MinValue then return false end
    return true
end

function utils.eggFinderStatus()
    local snapshot = utils.call(utils.modules.eggs.ReadFieldEggs)
    local _, _, root = utils.character()
    local best, count = nil, 0
    for key, row in pairs(snapshot.Records or {}) do
        if row.State == "Slot" or row.State == "Dropped" then
            local info = utils.eggInfo(row.Uid or key, row)
            if info and info.Position and utils.hopMatches(info, row) then
                info.Distance = root and (info.Position - root.Position).Magnitude or 0
                count += 1
                if not best or info.Income > best.Income then best = info end
            end
        end
    end
    local rareRank = utils.rarityRank(utils.settings.hop.Rare)
    local rare = false
    for _, row in pairs(snapshot.Records or {}) do
        local info = utils.eggInfo(row.Uid, row)
        if info and (row.State == "Slot" or row.State == "Dropped" or row.State == "Carried") and info.Rank >= rareRank then rare = true; break end
    end
    if best then
        return string.format("Found %d egg(s) | %s | %s | $%.0f/s", count, best.Category, best.Rarity, best.Income), true, best
    end
    return string.format("No matching egg on this server%s", rare and " (rare egg present)" or ""), false, nil, rare
end

function utils.autoHopTick()
    local settings = utils.settings.hop
    local status, found, best, rare = utils.eggFinderStatus()
    if found then return status end
    if utils.moving then return "Waiting for egg delivery" end
    if settings.Mode == "After A Rare Spawns" and not rare then return "Waiting for a " .. settings.Rare .. " egg" end
    if utils.settings.hop.NextHop and os.clock() < utils.settings.hop.NextHop then
        return string.format("Hopping in %.1fs", utils.settings.hop.NextHop - os.clock())
    end
    utils.settings.hop.NextHop = os.clock() + settings.Delay
    local success, result = pcall(utils.serverHop, "Least Players")
    if not success then utils.settings.hop.NextHop = os.clock() + 5; return tostring(result) end
    return result
end

function utils.rejoin()
    services.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, utils.player)
    return "Rejoining server"
end

function utils.joinJob(jobId)
    assert(jobId:match("^[%x]+%-%x+%-%x+%-%x+%-%x+$"), "Enter a valid JobId")
    services.TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, utils.player)
    return "Joining target server"
end

function utils.buildServer()
    utils.section(tabs.server, "Server Hop")
    utils.label(tabs.server, "Server", "Off")
    utils.dropdown(tabs.server, "Hop Mode", utils.settings.server, "Mode", {"Least Players", "Most Players", "Random"}, "Server.Mode")
    utils.slider(tabs.server, "Hop Delay", utils.settings.server, "Delay", 5, 120, 1, "Server.Delay")
    utils.action(tabs.server, "Find A Server", "Server", function() return utils.serverHop(utils.settings.server.Mode) end)
    utils.job(tabs.server, "Auto Hop", "AutoHop", function() return utils.settings.server.Delay end, function()
        if utils.fieldEggs()[1] then return "Matching eggs remain" end
        return utils.serverHop(utils.settings.server.Mode)
    end)
    utils.action(tabs.server, "Rejoin Server", "Rejoin", utils.rejoin)
    utils.job(tabs.server, "Auto Rejoin When Disconnected", "Rejoin", 30, function()
        if not utils.settings.server.AutoRejoin then return "Off" end
        if services.Players.LocalPlayer.Parent == nil then return utils.rejoin() end
        return "Connected"
    end)
    utils.action(tabs.server, "Copy Job ID", "Server", function()
        if type(setclipboard) == "function" then pcall(setclipboard, game.JobId) end
        return game.JobId
    end)
    utils.tabsServerInput = tabs.server:Input({Title = "Server Job ID", Placeholder = "Paste a JobId", Callback = function(value)
        utils.settings.server.Target = tostring(value):match("^%s*(.-)%s*$")
    end})
    utils.action(tabs.server, "Join Job ID", "Server", function() return utils.joinJob(utils.settings.server.Target) end)

    utils.section(tabs.server, "Egg Finder")
    utils.label(tabs.server, "Finder", "Idle")
    utils.toggle(tabs.server, "Sync With Auto Steal Filters", utils.settings.hop, "Sync", "Hop.Sync")
    utils.dropdown(tabs.server, "Hop Finder Mode", utils.settings.hop, "Mode", {"Until An Egg Matches", "Steal Then Hop", "After A Rare Spawns"}, "Hop.Mode")
    utils.dropdown(tabs.server, "Rarity To Wait For", utils.settings.hop, "Rare", utils.options.Rarities, "Hop.Rare")
    utils.dropdown(tabs.server, "Min Rarity", utils.settings.hop, "MinRarity", utils.options.RarityChoices, "Hop.MinRarity")
    utils.multi(tabs.server, "Target Areas", utils.settings.hop, "Areas", utils.options.Areas, "Hop.Areas")
    utils.textSet(tabs.server, "Target Specific Eggs (categories)", utils.settings.hop, "Specific", "Hop.Specific")
    utils.multi(tabs.server, "Finder Rarities", utils.settings.hop, "Rarities", utils.options.Rarities, "Hop.Rarities")
    utils.number(tabs.server, "Min Value To Find", utils.settings.hop, "MinValue", "Hop.MinValue")
    utils.slider(tabs.server, "First Hop Delay", utils.settings.hop, "Delay", 3, 30, 0.5, "Hop.Delay")
    utils.job(tabs.server, "Auto Hop Finder", "AutoHopFinder", 1, utils.autoHopTick)
end

function utils.buildMisc()
    utils.section(tabs.misc, "Performance")
    utils.controls.FpsCap = tabs.misc:Slider({Title = "FPS Cap", Value = {Min = 30, Max = 1000, Default = utils.settings.performance.FpsCap, Step = 1}, Flag = "Performance.FpsCap", Callback = function(value)
        utils.settings.performance.FpsCap = value
        utils.applyFpsCap()
    end})
    utils.tabs3d = tabs.misc:Toggle({Title = "Disable 3D Render", Value = utils.settings.performance.Disable3D, Flag = "Performance.Disable3D", Callback = function(enabled)
        utils.settings.performance.Disable3D = enabled
        utils.set3d(not enabled)
    end})
    utils.dropdown(tabs.misc, "Background Color", utils.settings.performance, "Background", {"White", "Black"}, "Performance.Background")
    utils.tabsOptimizer = tabs.misc:Toggle({Title = "Optimizer", Value = false, Flag = "Performance.Optimizer", Callback = function(enabled)
        utils.settings.performance.Optimizer = enabled
        utils.setOptimizer(enabled)
    end})
    utils.toggle(tabs.misc, "Hide Game UI", utils.settings.performance, "HideGameUi", "Performance.HideGameUi")
    utils.toggle(tabs.misc, "Anti AFK", utils.settings.performance, "AntiAfk", "Performance.AntiAfk")
    utils.section(tabs.misc, "Utility")
    utils.action(tabs.misc, "Stop All Automation", "Runtime", function()
        for key, job in pairs(utils.jobs) do
            if utils.controls[key .. "Switch"] then utils.controls[key .. "Switch"]:Set(false) else job.Enabled = false end
            if job.Thread and coroutine.status(job.Thread) ~= "dead" then pcall(task.cancel, job.Thread); runtime.Threads[job.Thread] = nil end
            job.Thread, job.Busy = nil, false
        end
        table.clear(utils.pipeline.Requests)
        utils.cancelPipeline()
        return "Stopped"
    end)
    utils.action(tabs.misc, "Unload Silence", "Runtime", function()
        runtime:Destroy()
        return "Unloaded"
    end)
    utils.label(tabs.misc, "Session", "Running")
end

function utils.buildConfig()
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
        utils.configManager:CreateConfig(name):Save()
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
    utils.label(tabs.config, "Configuration", "Idle")
end

function utils.buildInfo()
    tabs.info:Paragraph({Title = "Made by xyzhenrik"})
    tabs.info:Paragraph({Title = "Any issues? Create a Ticket on Discord"})
    tabs.info:Paragraph({Title = "Official Discord: discord.gg/9eFf93Kg8D"})
    tabs.info:Button({Title = "Copy Invite", Callback = function()
        local success = type(setclipboard) == "function" and pcall(setclipboard, "https://discord.gg/9eFf93Kg8D")
        pcall(function()
            services.StarterGui:SetCore("SendNotification", {
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
    tabs.info.VersionLabel = tabs.info:Section({Title = "Steal An Egg [V2.0.0]", TextSize = 20, Box = false})
end
function utils.bindNet(path, callback)
    local packages = services.ReplicatedStorage:FindFirstChild("Packages")
    local networking = packages and packages:FindFirstChild("Networking")
    local remote = networking and networking:FindFirstChild(path)
    if remote and remote:IsA("RemoteEvent") then
        runtime:Connect(remote.OnClientEvent, callback)
        return true
    end
    return false
end

utils.visualFolder = Instance.new("Folder")
utils.visualFolder.Name = "ClientFX"
utils.visualFolder.Parent = services.Workspace
utils.starState = {}

local loaded = utils.loadModules()
if not loaded then
    WindUI:Notify({Title = "Steal An Egg", Content = "Could not load game modules. Rejoin and execute Silence again.", Duration = 8})
    return
end

utils.buildOptions()
utils.buildFarm()
utils.buildAutomation()
utils.buildInventory()
utils.buildEvents()
utils.buildMinigames()
utils.buildEsp()
utils.buildCharacter()
utils.buildCombat()
utils.buildServer()
utils.buildMisc()
utils.buildConfig()
utils.buildInfo()

utils.bindNet("RE/ShootingStar/Fall", function(payload)
    utils.starState.Payload = payload
    utils.starState.At = os.clock()
end)
utils.bindNet("RE/ShootingStar/Wander", function(id, leg, noticed)
    if utils.starState.Payload and utils.starState.Payload.Id == id then
        utils.starState.Payload.Leg = leg or utils.starState.Payload.Leg
        utils.starState.Payload.Noticed = noticed
    end
end)
utils.bindNet("RE/ShootingStar/Slipped", function()
    utils.starState.Slipped = (utils.starState.Slipped or 0) + 1
end)
utils.bindNet("RE/ShootingStar/Claimed", function(id)
    if utils.starState.Payload and utils.starState.Payload.Id == id then utils.starState.Payload = nil end
end)
utils.bindNet("RE/ShootingStar/Expired", function(id)
    if utils.starState.Payload and utils.starState.Payload.Id == id then utils.starState.Payload = nil end
end)

utils.banjoState = {}
utils.bindNet("RE/BanjoCricket/Effect", function(payload)
    if type(payload) ~= "table" then return end
    local kind = payload.Type or payload.Kind or payload.Event
    if kind == "Playback" then
        local notes = {}
        for _, note in ipairs(payload.Notes or {}) do table.insert(notes, tonumber(note)) end
        utils.banjoState.Notes = notes
    elseif kind == "Reset" then
        utils.banjoState.Notes = nil
    elseif kind == "StageComplete" then
        utils.banjoState.Cleared = tonumber(payload.Cleared) or utils.banjoState.Cleared
    elseif kind == "Solved" then
        utils.banjoState.Solved = true
    end
end)

runtime:Connect(services.UserInputService.JumpRequest, function()
    if utils.settings.player.InfiniteJump and not services.UserInputService:GetFocusedTextBox() then
        local _, humanoid = utils.character()
        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)
runtime:Connect(services.ProximityPromptService.PromptShown, function(prompt)
    if utils.settings.player.InstantPrompts then utils.remember(prompt, "HoldDuration", 0) end
end)
runtime:Connect(utils.player.CharacterAdded, function()
    utils.stop()
    utils.pipeline.PendingHatches = {}
    task.wait(0.5)
    utils.applyCharacter()
end)
runtime:Connect(services.Players.PlayerAdded, function()
    local names = {}
    for _, player in ipairs(services.Players:GetPlayers()) do if player ~= utils.player then table.insert(names, player.Name) end end
    table.sort(names)
    utils.options.PlayerNames = names
    if tabs.combat.target then pcall(function() tabs.combat.target:Refresh(names) end) end
end)
runtime:Connect(services.Players.PlayerRemoving, function(player)
    local names = {}
    for _, other in ipairs(services.Players:GetPlayers()) do if other ~= utils.player and other ~= player then table.insert(names, other.Name) end end
    table.sort(names)
    utils.options.PlayerNames = names
    if tabs.combat.target then pcall(function() tabs.combat.target:Refresh(names) end) end
end)

runtime:Spawn(function()
    while runtime.Alive do
        local success, result = pcall(utils.pipelineStep)
        utils.identityReset()
        if not success then utils.message("Runtime", tostring(result)) end
        task.wait(0.25)
    end
end)

runtime:Spawn(function()
    while runtime.Alive do
        local success, result = pcall(utils.esp)
        utils.identityReset()
        if not success then utils.message("ESP", tostring(result)) end
        task.wait(1)
    end
end)

runtime:Spawn(function()
    while runtime.Alive do
        local success, result = pcall(utils.applyCharacter)
        utils.identityReset()
        if not success then utils.message("Character", tostring(result)) end
        task.wait(0.25)
    end
end)

runtime:Spawn(function()
    while runtime.Alive do
        pcall(utils.antiTrap)
        pcall(utils.antiAfk)
        local playerGui = utils.player:FindFirstChildOfClass("PlayerGui")
        local hud = playerGui and playerGui:FindFirstChild("HUD")
        if hud and hud:IsA("ScreenGui") then hud.Enabled = not utils.settings.performance.HideGameUi end
        task.wait(2)
    end
end)

runtime:Spawn(function()
    while runtime.Alive do
        if utils.settings.combat.Mode ~= "Off" then
            local success, result = pcall(utils.combatTick)
            utils.identityReset()
            if not success then utils.message("Combat", tostring(result)) else utils.message("Combat", result) end
        else
            utils.status.Combat = "Off"
        end
        task.wait(0.1)
    end
end)

runtime:Spawn(function()
    while runtime.Alive do
        local success, eggText = pcall(utils.predictorText)
        if success then utils.message("EggPredictor", eggText) end
        local fuseSuccess, fuseText = pcall(utils.fusePredictorText)
        if fuseSuccess then utils.message("FusePredictor", fuseText) end
        task.wait(5)
    end
end)

runtime:Spawn(function()
    while runtime.Alive do
        utils.message("Runtime", "Running")
        utils.message("Session", string.format("%.0fs", os.clock() - utils.started))
        utils.message("Dashboard", table.concat({
            "Steal: " .. (utils.status.Steal or "Off"),
            "Place: " .. (utils.status.Place or "Off"),
            "Hatch: " .. (utils.status.Hatch or "Off"),
            "Treadmill: " .. (utils.status.Treadmill or "Off"),
            "Mutation: " .. (utils.status.Mutation or "Off")
        }, "\n"))
        local finderStatus = utils.eggFinderStatus()
        utils.message("Finder", finderStatus)
        utils.message("Combat", utils.settings.combat.Mode == "Off" and "Off" or (utils.status.Combat or "Idle"))
        task.wait(1)
    end
end)

utils.setOptimizer(false)

utils.configManager = silence.ConfigManager
if utils.configManager then
    for _, name in ipairs(utils.refreshConfigs()) do utils.configManager:CreateConfig(name) end
end

runtime:AddCleanup(function()
    utils.stop()
    if utils.visualFolder then utils.visualFolder:Destroy() end
    if utils.navigation.Folder then utils.navigation.Folder:Destroy() end
    for instance, properties in pairs(utils.originals) do
        if instance.Parent then for property, value in pairs(properties) do pcall(function() instance[property] = value end) end end
    end
    pcall(utils.setOptimizer, false)
    pcall(utils.set3d, true)
    local playerGui = utils.player:FindFirstChildOfClass("PlayerGui")
    local hud = playerGui and playerGui:FindFirstChild("HUD")
    if hud and hud:IsA("ScreenGui") then hud.Enabled = true end
end)

return utils, silence
