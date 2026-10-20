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
    CollectionService = game:GetService("CollectionService")
}

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/silencedevs/SilenceScripts/refs/heads/main/libraries/eleriumv2/eleriumv2.luau"))()
library:Use(loadstring(game:HttpGet("https://raw.githubusercontent.com/silencedevs/SilenceScripts/refs/heads/main/libraries/eleriumv2/modules/ConfigManager.luau"))())
library:Use(loadstring(game:HttpGet("https://raw.githubusercontent.com/silencedevs/SilenceScripts/refs/heads/main/libraries/eleriumv2/modules/Customize.luau"))())
local runtime = library.Runtime
local silence = library:AddWindow("Silence | Steal An Egg", {
    main_color = Color3.fromRGB(138, 0, 0),
    min_size = Vector2.new(566, 680),
    can_resize = true
})
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
    settings = {
        eggs = {Priority = "Closest", Rarities = {}, Areas = {}, Mutations = {}, Species = {}, MinWeight = 0, MinValue = 0},
        place = {Rarities = {}, Mutations = {}, MinWeight = 0, Spacing = 6},
        hatch = {Delay = 1},
        eggSell = {Rarities = {}, Mutations = {}, MaxWeight = 0, WeightOnly = false, ProtectHalloween = true},
        pets = {Interval = 5},
        sell = {Rarities = {}, Species = {}, Mutations = {}, MaxIncome = 0, KeepBest = 1, Unequip = false},
        fuse = {MaxRarity = "Epic", Species = {}, SkipMutated = true, EjectIncomplete = false},
        treadmill = {MaxLevel = 100},
        trails = {Selected = {}},
        visuals = {Distance = 1000, Everyone = false, Rarities = {}, Mutations = {}},
        player = {Speed = 18, JumpPower = 50, SpeedEnabled = false, JumpEnabled = false, AntiRagdoll = false, InfiniteJump = false, InstantPrompts = false},
        travel = {Mode = "Walk", Speed = 100},
        server = {Mode = "Least Players", Delay = 5, Target = "", Visited = {[game.JobId] = true}},
        race = {Shop = {}, Reserve = 0, Racer = "Best Owned"},
        mastery = {Shop = {}, Reserve = 0, MinWeight = 0},
        lightDark = {Team = "Light"},
        halloween = {Zones = {}, Rarities = {}, Species = {}, MinValue = 0, Priority = "Rarity"}
    }
}
local tabs = {
    eggs = silence:AddTab("Farm"),
    manage = silence:AddTab("Inventory"),
    pets = silence:AddTab("Pets"),
    sell = silence:AddTab("Sell"),
    automation = silence:AddTab("Upgrades"),
    racing = silence:AddTab("Race"),
    halloween = silence:AddTab("Halloween"),
    events = silence:AddTab("Events"),
    visuals = silence:AddTab("ESP"),
    player = silence:AddTab("Character"),
    server = silence:AddTab("Servers")
}

function utils.identityReset()
    if type(setthreadidentity) == "function" then setthreadidentity(utils.identity) end
end

function utils.call(callback, ...)
    local result = table.pack(pcall(callback, ...))
    utils.identityReset()
    if not result[1] then error(tostring(result[2]), 0) end
    return table.unpack(result, 2, result.n)
end

function utils.load(name, module)
    local success, result = pcall(require, module)
    utils.identityReset()
    if success then utils.modules[name] = result end
    return success
end

function utils.message(key, message)
    utils.status[key] = tostring(message or "")
    if utils.controls[key] then utils.controls[key].Text = utils.status[key] end
end

function utils.label(tab, key, text)
    utils.controls[key] = tab:AddLabel(text or "Idle")
    utils.status[key] = text or "Idle"
end

function utils.action(tab, label, key, callback)
    return tab:AddButton(label, function()
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
            if not success then utils.message(key, tostring(result))
            elseif result ~= nil then utils.message(key, result) end
        end)
    end)
end

function utils.job(tab, label, key, interval, callback, cleanup)
    utils.jobs[key] = {Enabled = false, Generation = 0, Busy = false, Callback = callback, Interval = interval}
    utils.controls[key .. "Switch"] = tab:AddSwitch(label, function(enabled)
        utils.jobs[key].Enabled = enabled
        utils.jobs[key].Generation += 1
        if utils.pipeline.Keys[key] then
            utils.pipeline.Next[key] = 0
            if not enabled and utils.pipeline.Owner == key then utils.cancelPipeline() end
            if not enabled then utils.pipeline.Requests[key] = nil end
            utils.message(key, enabled and "Queued" or "Off")
            return
        end
        if not enabled then
            if utils.jobs[key].Thread and coroutine.status(utils.jobs[key].Thread) ~= "dead" then
                pcall(task.cancel, utils.jobs[key].Thread)
                runtime.Threads[utils.jobs[key].Thread] = nil
            end
            utils.jobs[key].Thread = nil
            utils.jobs[key].Busy = false
            if cleanup then cleanup() end
            utils.message(key, "Off")
            return
        end
        utils.message(key, "Starting")
        utils.jobs[key].Thread = runtime:Spawn(function()
            local generation = utils.jobs[key].Generation
            while runtime.Alive and utils.jobs[key].Enabled and utils.jobs[key].Generation == generation do
                if not utils.jobs[key].Busy then
                    utils.jobs[key].Busy = true
                    local success, result = pcall(callback)
                    utils.identityReset()
                    utils.jobs[key].Busy = false
                    if not success then utils.message(key, tostring(result))
                    elseif result ~= nil then utils.message(key, result) end
                end
                task.wait(math.max(0.25, type(interval) == "function" and interval() or interval))
            end
        end)
    end)
    utils.controls[key .. "Switch"]:SetConfigKey("Enabled." .. key)
    return utils.controls[key .. "Switch"]
end

function utils.slider(tab, text, settings, key, min, max, step)
    local initial = settings[key]
    local control = tab:AddSlider(text, function(value) settings[key] = value end, {min = min, max = max, step = step or 1})
    control:Set(initial)
    return control
end

function utils.dropdown(tab, text, settings, key, values)
    local control = tab:AddDropdown(text, function(value) settings[key] = value end)
    for _, value in ipairs(values) do control:Add(value) end
    if settings[key] then control:SetValue(settings[key]) end
    return control
end

function utils.number(tab, text, settings, key)
    local apply = function(value)
        if tostring(value):match("^%s*$") then settings[key] = 0; return end
        local number, suffix = tostring(value):lower():gsub(",", ""):match("^%s*(%d*%.?%d+)%s*([kmbtq]?)%s*$")
        if not number then utils.message("Input", text .. ": enter a non-negative number"); return end
        number = tonumber(number) * (({k = 1e3, m = 1e6, b = 1e9, t = 1e12, q = 1e15})[suffix] or 1)
        if number >= math.huge then utils.message("Input", text .. ": value is too large"); return end
        settings[key] = number
    end
    local control = tab:AddTextBox(text, apply, {clear = false})
    control.Text = settings[key] ~= 0 and tostring(settings[key]) or ""
    for _, entry in pairs(silence.ConfigControls) do
        if entry.Node == control then
            entry.Set = function(_, value)
                assert(type(value) == "string", "Invalid input")
                control.Text = value
                apply(value)
            end
        end
    end
    runtime:Connect(control.FocusLost, function() apply(control.Text) end)
    return control
end

function utils.multi(tab, text, settings, key, values, configKey, emptyMeaning)
    emptyMeaning = emptyMeaning == "none" and "None" or emptyMeaning or "All"
    local label = tab:AddLabel(text .. ": " .. emptyMeaning)
    local update = function()
        local names = {}
        for name, enabled in pairs(settings[key]) do if enabled then table.insert(names, name) end end
        table.sort(names)
        label.Text = text .. ": " .. (#names == 0 and emptyMeaning or table.concat(names, ", "))
    end
    local control, node = tab:AddDropdown("Select " .. text:lower(), function(value)
        if value == "Clear" then table.clear(settings[key])
        else settings[key][value] = not settings[key][value] or nil end
        update()
    end)
    for _, entry in pairs(silence.ConfigControls) do
        if entry.Node == node then
            entry.Get = function() return nil end
            entry.Set = function() end
        end
    end
    control:Add("Clear")
    for _, value in ipairs(values) do control:Add(value) end
    silence:RegisterConfig(configKey, function() return table.clone(settings[key]) end, function(value)
        assert(type(value) == "table", "Invalid selection")
        table.clear(settings[key])
        for name, enabled in pairs(value) do if type(name) == "string" and enabled == true and table.find(values, name) then settings[key][name] = true end end
        update()
    end)
    return control
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
    if row.BaseMutation and selection[row.BaseMutation] then return true end
    for _, name in pairs(row.Mutations or {}) do if selection[name] then return true end end
    return selection.Normal == true and not row.BaseMutation and next(row.Mutations or {}) == nil
end

function utils.character()
    local character = utils.player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if humanoid and root and humanoid.Health > 0 then return character, humanoid, root end
end

function utils.remote(group, name, ...)
    local remote = utils.modules.remotes[group] and utils.modules.remotes[group][name]
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
    return utils.call(utils.modules.save.Peek) or {}
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
    if humanoid then humanoid:MoveTo(root.Position) end
end

function utils.cancelPipeline()
    utils.pipeline.Generation += 1
    utils.stop()
    if utils.pipeline.Thread and coroutine.status(utils.pipeline.Thread) ~= "dead" then
        pcall(task.cancel, utils.pipeline.Thread)
        runtime.Threads[utils.pipeline.Thread] = nil
    end
    if utils.pipeline.Owner then utils.jobs[utils.pipeline.Owner].Busy = false end
    utils.pipeline.Thread = nil
    utils.pipeline.Owner = nil
end

function utils.pendingWork()
    local work = {Place = 0, Hatch = 0}
    for uid, row in pairs(utils.call(utils.modules.eggs.ReadOwnerEggs, utils.player.UserId)) do
        if utils.pipeline.PendingHatches[uid] or (row.Placement and utils.call(utils.modules.eggs.IsReadyToHatch, uid)) then work.Hatch += 1 end
        if not row.Placement then
            local info = utils.eggInfo(uid, row)
            if info and utils.matches(utils.settings.place.Rarities, info.Rarity)
                and utils.mutated(utils.settings.place.Mutations, row) and info.Weight >= utils.settings.place.MinWeight then work.Place += 1 end
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
    local generation = utils.pipeline.Generation
    utils.pipeline.Thread = runtime:Spawn(function()
        local success, result = pcall(callback)
        utils.identityReset()
        if utils.pipeline.Generation ~= generation then return end
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
        modifier.Label = "SilenceAvoid"
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
        utils.navigation.Folder.Name = "SilenceNavigation"
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
        local path = services.PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = attempt > 1, WaypointSpacing = 3, Costs = {SilenceAvoid = math.huge}})
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
                        local speed = utils.settings.player.SpeedEnabled and utils.settings.player.Speed or utils.settings.travel.Speed
                        humanoid.WalkSpeed = math.min(speed, math.max(16, distance * 8))
                    end
                    if distance < best - 0.25 then best, progress = distance, os.clock() end
                    if blocked or humanoid.Health <= 0 or os.clock() - progress > 1.5 or os.clock() - started > 12 then
                        utils.navigation.Reason = blocked and "Path changed" or "No movement"
                        retry = true
                        break
                    end
                    if utils.settings.travel.Mode ~= "Walk" and waypoint.Action ~= Enum.PathWaypointAction.Jump then
                        local step = math.min(offset.Magnitude, utils.settings.travel.Mode == "Step" and 4 or utils.settings.travel.Speed * 0.03)
                        local delta = offset.Magnitude > 0 and offset.Unit * step or Vector3.zero
                        if utils.segmentAvoided(root.Position, root.Position + delta)
                            or services.Workspace:Blockcast(CFrame.new(root.Position), Vector3.new(2, 3.5, 2), delta, params) then retry = true; break end
                        character:PivotTo(character:GetPivot() + delta)
                        root.AssemblyLinearVelocity = Vector3.zero
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
    humanoid.WalkSpeed = utils.settings.player.SpeedEnabled and utils.settings.player.Speed or utils.settings.travel.Speed
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

function utils.placementCandidates(area, occupied)
    utils.pipeline.RejectedPositions = utils.pipeline.RejectedPositions or {}
    for index = #utils.pipeline.RejectedPositions, 1, -1 do
        if utils.pipeline.RejectedPositions[index].Expires <= os.clock() then table.remove(utils.pipeline.RejectedPositions, index) end
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

function utils.home(route)
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
    return utils.move(ground.Position + Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2, 0), route or utils.route)
end

function utils.eggItem(row)
    return {Category = row.AssetCategory, Scale = row.AssetScale or 1, Mutations = row.Mutations or {}, BaseMutation = row.BaseMutation, ColorIndex = row.AssetColorIndex or 0}
end

function utils.eggInfo(uid, row)
    local config = utils.modules.assets.Directory[row.AssetCategory]
    if not config then return end
    local item = utils.eggItem(row)
    return {
        Uid = uid, Row = row, Category = row.AssetCategory,
        Rarity = config.Rarity._id, Rank = config.Rarity.Rank,
        Weight = utils.call(utils.modules.eggRecords.WeightKg, row),
        Value = utils.call(utils.modules.eggRecords.SellPrice, row),
        Income = utils.call(utils.modules.earnings.RatePerSecond, item),
        Position = typeof(row.BottomCFrame) == "CFrame" and row.BottomCFrame.Position or nil
    }
end

function utils.fieldEggs(priority, unfiltered)
    local snapshot = utils.call(utils.modules.eggs.ReadFieldEggs)
    local entries = {}
    local _, _, root = utils.character()
    for _, row in pairs(snapshot.Records or {}) do
        if (row.State == "Slot" or row.State == "Dropped") and (utils.selection.Cooldowns[row.Uid] or 0) <= os.clock() then
            local info = utils.eggInfo(row.Uid, row)
            if info and info.Position and (unfiltered or (utils.matches(utils.settings.eggs.Rarities, info.Rarity)
                and utils.matches(utils.settings.eggs.Areas, row.AreaId)
                and utils.matches(utils.settings.eggs.Species, row.AssetCategory)
                and utils.mutated(utils.settings.eggs.Mutations, row)
                and info.Weight >= utils.settings.eggs.MinWeight and info.Value >= utils.settings.eggs.MinValue)) then
                info.Distance = root and (root.Position - info.Position).Magnitude or math.huge
                table.insert(entries, info)
            end
        end
    end
    table.sort(entries, function(a, b)
        local order = priority or utils.settings.eggs.Priority
        local av = order == "Closest" and -a.Distance or order == "Rarity" and a.Rank or order == "Weight" and a.Weight or a.Value
        local bv = order == "Closest" and -b.Distance or order == "Rarity" and b.Rank or order == "Weight" and b.Weight or b.Value
        if av == bv and order == "Rarity" then
            if a.Value ~= b.Value then return a.Value > b.Value end
            if a.Distance ~= b.Distance then return a.Distance < b.Distance end
        end
        return av == bv and a.Uid < b.Uid or av > bv
    end)
    return entries
end

function utils.steal(priority, unfiltered)
    assert(not utils.moving, "Another route is active")
    utils.stop()
    utils.moving = true
    local route = utils.route
    local success, result = pcall(function()
        local before = 0
        for _ in pairs(utils.call(utils.modules.eggs.ReadOwnerEggs, utils.player.UserId)) do before += 1 end
        local carry = utils.call(utils.modules.eggs.ReadCarryState)
        if not carry.IsCarrying then
            local target = utils.fieldEggs(priority, unfiltered)[1]
            assert(target, unfiltered and "No field eggs are available" or "No eggs match your filters")
            utils.selection.Target = target.Uid
            utils.message("Steal", "Travelling to " .. target.Category)
            assert(utils.move(target.Position + Vector3.new(0, 3, 0), route), "Route cancelled or target not reached")
            assert(runtime.Alive and utils.route == route, "Route cancelled")
            local slot = utils.call(utils.modules.slotIdentity.LooksLikeFirstAreaUid, target.Uid)
                and utils.call(utils.modules.slotIdentity.SlotKey, target.Row.AreaId, target.Row.NestId) or nil
            local accepted, reason = utils.call(utils.modules.eggs.CarryFieldEgg, target.Uid, slot)
            assert(accepted, reason or "Egg pickup rejected")
        end
        utils.message("Steal", "Returning to your plot")
        assert(runtime.Alive and utils.route == route and utils.home(route), "Return route cancelled")
        local deadline = os.clock() + 6
        repeat
            assert(runtime.Alive and utils.route == route, "Route cancelled")
            if not utils.call(utils.modules.eggs.ReadCarryState).IsCarrying then
                local count = 0
                for _ in pairs(utils.call(utils.modules.eggs.ReadOwnerEggs, utils.player.UserId)) do count += 1 end
                if count > before then return "Egg delivery confirmed in your inventory" end
            end
            task.wait(0.25)
        until os.clock() >= deadline or not runtime.Alive
        error("Egg delivery was not confirmed; retrying another egg", 0)
    end)
    if utils.route == route then utils.moving = false end
    if not success then
        if utils.selection.Target then utils.selection.Cooldowns[utils.selection.Target] = os.clock() + 30 end
        if utils.route == route then utils.stop() end
        error(result, 0)
    end
    return result
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
    for _, row in pairs(owned) do
        if row.Placement and typeof(row.Placement.LocalCFrame) == "CFrame" then
            table.insert(occupied, (center.CFrame * row.Placement.LocalCFrame).Position)
        end
    end
    for uid, row in pairs(owned) do
        if not runtime.Alive then break end
        local info = utils.eggInfo(uid, row)
        if not row.Placement and info and utils.matches(utils.settings.place.Rarities, info.Rarity)
            and utils.mutated(utils.settings.place.Mutations, row) and info.Weight >= utils.settings.place.MinWeight then
            local candidates = utils.placementCandidates(area, occupied)
            if #candidates == 0 then return count .. " placed; no accessible space left in the pen" end
            local placed, reason = false, "No accessible placement found"
            for index = 1, math.min(12, #candidates) do
                local point = candidates[index].Point
                placed, reason = pcall(function()
                    assert(utils.move(point + Vector3.new(0, 3, 0), route), "Placement route cancelled or blocked")
                    assert(runtime.Alive and utils.route == route, "Placement cancelled")
                    local accepted, message = utils.call(utils.modules.eggs.PlantEgg, uid, center.CFrame:ToObjectSpace(CFrame.new(point)))
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
    end
    if #failures > 0 then
        if count == 0 then error(failures[1], 0) end
        return count .. " eggs placed; " .. #failures .. " waiting to retry"
    end
    return count .. " eggs placed"
end

function utils.place()
    assert(not utils.moving, "Another route is active")
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
    for uid, row in pairs(owned) do
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

function utils.sellEggs()
    assert(utils.settings.eggSell.WeightOnly or next(utils.settings.eggSell.Rarities) ~= nil or next(utils.settings.eggSell.Mutations) ~= nil, "Choose a sell filter first")
    assert(not utils.settings.eggSell.WeightOnly or utils.settings.eggSell.MaxWeight > 0, "Set a positive maximum egg weight")
    local selection = {}
    for uid, row in pairs(utils.call(utils.modules.eggs.ReadOwnerEggs, utils.player.UserId)) do
        local info = utils.eggInfo(uid, row)
        local halloween = row.AssetCategory and utils.modules.halloweenPets.Specs[row.AssetCategory]
        if info and not row.Placement and not row.IsFavorite
            and not (utils.settings.eggSell.ProtectHalloween and halloween)
            and (utils.settings.eggSell.MaxWeight == 0 or info.Weight <= utils.settings.eggSell.MaxWeight)
            and (utils.settings.eggSell.WeightOnly or (utils.matches(utils.settings.eggSell.Rarities, info.Rarity) and utils.mutated(utils.settings.eggSell.Mutations, row))) then
            table.insert(selection, uid)
        end
    end
    if #selection > 0 then utils.remote("PetSatchel", "SellSelection", {Assets = {}, Eggs = selection}) end
    return #selection .. " eggs submitted for sale"
end

function utils.sellPets()
    assert(next(utils.settings.sell.Rarities) ~= nil or next(utils.settings.sell.Species) ~= nil or next(utils.settings.sell.Mutations) ~= nil or utils.settings.sell.MaxIncome > 0, "Choose a pet sell filter first")
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
            and utils.matches(utils.settings.sell.Rarities, config.Rarity._id)
            and utils.matches(utils.settings.sell.Species, entry.Item.Category)
            and utils.mutated(utils.settings.sell.Mutations, entry.Item)
            and (utils.settings.sell.MaxIncome == 0 or entry.Income < utils.settings.sell.MaxIncome) then
            if table.find(save.EquippedAssets or {}, entry.Uid) then
                if utils.settings.sell.Unequip then utils.remote("PenRoster", "AskDoff", entry.Uid)
                else continue end
            end
            table.insert(selection, entry.Uid)
        end
    end
    if #selection > 0 then utils.remote("PetSatchel", "SellSelection", {Assets = selection, Eggs = {}}) end
    return #selection .. " pets submitted for sale"
end

function utils.fuse()
    local save = utils.save()
    if save.FusionEggReward then utils.remote("Fusery", "FinishReveal"); return "Fusion reward claimed" end
    if save.FusionLocked then return "Fusion in progress" end
    local groups = {}
    local limit = utils.modules.rarities.Rarities[utils.settings.fuse.MaxRarity].Rank
    for uid, item in pairs(save.Inventory or {}) do
        local config = utils.modules.assets.Directory[item.Category]
        if config and config.Rarity.Rank <= limit and not item.InFuse and not item.IsFavorite
            and not table.find(save.EquippedAssets or {}, uid)
            and utils.matches(utils.settings.fuse.Species, item.Category)
            and (not utils.settings.fuse.SkipMutated or (not item.BaseMutation and next(item.Mutations or {}) == nil)) then
            groups[item.Category] = groups[item.Category] or {}
            table.insert(groups[item.Category], uid)
        end
    end
    local slots = save.FusionSlots or {}
    local category = slots[1] and save.Inventory[slots[1]] and save.Inventory[slots[1]].Category
    for name, group in pairs(groups) do
        if (not category or category == name) and #group + #slots >= 3 then
            utils.remote("Fusery", "ConfirmBriefing")
            for index = 1, 3 - #slots do utils.remote("Fusery", "LoadPet", group[index], false); task.wait(0.3) end
            utils.remote("Fusery", "BeginFuse")
            return "Fusion started: " .. name
        end
    end
    if utils.settings.fuse.EjectIncomplete then
        for _, uid in ipairs(slots) do utils.remote("Fusery", "EjectPet", uid) end
    end
    return "Waiting for three matching unequipped pets"
end

function utils.upgradeTreadmill()
    local save = utils.save()
    if (save.TreadmillUpgradeLevel or 0) >= utils.settings.treadmill.MaxLevel then return "Upgrade limit reached" end
    local config = utils.call(utils.modules.treadmills.GetByUpgradeLevel, (save.TreadmillUpgradeLevel or 0) + 1)
    if not config then return "Maximum treadmill level reached" end
    if (save.Money or 0) < config.Price then return "Waiting for enough cash" end
    utils.remote("Treadmill", "AskTierRaise", config._id)
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
            utils.remote("Trailwear", "AskPurchase", name)
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

function utils.mark(key, model, text, color)
    if not model or not model:IsA("Model") then return end
    local marker = utils.markers[key]
    if marker and marker.Model ~= model then marker.Highlight:Destroy(); marker.Gui:Destroy(); utils.markers[key] = nil; marker = nil end
    if not marker then
        local highlight = Instance.new("Highlight")
        highlight.Name = "SilenceHighlight"
        highlight.Adornee = model
        highlight.FillTransparency = 0.8
        highlight.OutlineColor = color
        highlight.FillColor = color
        highlight.Parent = utils.visualFolder
        local gui = Instance.new("BillboardGui")
        gui.Name = "SilenceLabel"
        gui.Adornee = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
        gui.Size = UDim2.fromOffset(250, 52)
        gui.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
        gui.AlwaysOnTop = true
        gui.Parent = utils.visualFolder
        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundColor3 = Color3.fromRGB(22, 22, 24)
        label.BackgroundTransparency = 0.15
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 13
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextWrapped = true
        label.Parent = gui
        marker = {Model = model, Highlight = highlight, Gui = gui, Label = label}
        utils.markers[key] = marker
    end
    marker.Gui.MaxDistance = utils.settings.visuals.Distance
    marker.Label.Text = text
    marker.Seen = utils.visualRevision
end

function utils.esp()
    utils.visualRevision = (utils.visualRevision or 0) + 1
    local _, _, root = utils.character()
    if not root then return "Waiting for character" end
    if utils.settings.visuals.EggESP or utils.settings.visuals.Predictor then
        local snapshots = {}
        if utils.settings.visuals.EggESP then
            table.insert(snapshots, {Rows = utils.call(utils.modules.eggs.ReadFieldEggs).Records or {}, Folder = services.Workspace:FindFirstChild("AreaEggSlotsClient"), Wild = true})
        end
        if utils.settings.visuals.Everyone then
            for _, owner in ipairs(utils.call(utils.modules.eggs.ReadOwnedEggs)) do
                table.insert(snapshots, {Rows = owner.Records, Folder = services.Workspace:FindFirstChild("PlacedEggRenders"), Owner = owner.OwnerUserId})
            end
        else
            table.insert(snapshots, {Rows = utils.call(utils.modules.eggs.ReadOwnerEggs, utils.player.UserId), Folder = services.Workspace:FindFirstChild("PlacedEggRenders"), Owner = utils.player.UserId})
        end
        for _, snapshot in ipairs(snapshots) do
            for key, row in pairs(snapshot.Rows) do
                local uid = row.Uid or key
                local info = utils.eggInfo(uid, row)
                local model = snapshot.Folder and snapshot.Folder:FindFirstChild(snapshot.Wild and uid or tostring(snapshot.Owner) .. "_" .. uid)
                if info and model and model:IsA("Model") and (model:GetPivot().Position - root.Position).Magnitude <= utils.settings.visuals.Distance
                    and utils.matches(utils.settings.visuals.Rarities, info.Rarity) and utils.mutated(utils.settings.visuals.Mutations, row) then
                    utils.mark("egg:" .. tostring(uid), model, string.format("%s | %s\n%.2f kg | $%.0f/s", info.Category, info.Rarity, info.Weight, info.Income), utils.modules.rarities.Rarities[info.Rarity].Color)
                end
            end
        end
    end
    if utils.settings.visuals.GuardESP then
        local folder = services.Workspace:FindFirstChild("_Guards")
        for _, model in ipairs(folder and folder:GetChildren() or {}) do
            if model:IsA("Model") and (model:GetPivot().Position - root.Position).Magnitude <= utils.settings.visuals.Distance then
                utils.mark(model, model, model.Name, Color3.fromRGB(255, 120, 100))
            end
        end
    end
    for key, marker in pairs(utils.markers) do
        if marker.Seen ~= utils.visualRevision or not marker.Model.Parent then
            marker.Highlight:Destroy(); marker.Gui:Destroy(); utils.markers[key] = nil
        end
    end
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

function utils.serverHop()
    assert(not utils.hopping, "A server hop is already pending")
    utils.hopping = true
    local success, result = pcall(function()
        local cursor, servers = "", {}
        for _ = 1, 3 do
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100" .. (cursor ~= "" and "&cursor=" .. services.HttpService:UrlEncode(cursor) or "")
            local response = services.HttpService:JSONDecode(game:HttpGet(url))
            for _, server in ipairs(response.data or {}) do
                if server.id ~= game.JobId and not utils.settings.server.Visited[server.id] and server.playing < server.maxPlayers then table.insert(servers, server) end
            end
            cursor = response.nextPageCursor
            if not cursor then break end
        end
        assert(#servers > 0, "No unvisited server with a free slot was found")
        table.sort(servers, function(a, b)
            if utils.settings.server.Mode == "Most Players" then return a.playing > b.playing end
            return a.playing < b.playing
        end)
        local selected = utils.settings.server.Mode == "Random" and servers[math.random(1, #servers)] or servers[1]
        utils.settings.server.Visited[selected.id] = true
        services.TeleportService:TeleportToPlaceInstance(game.PlaceId, selected.id, utils.player)
        return "Joining server"
    end)
    if not success then utils.hopping = false; error(result, 0) end
    return result
end

utils.label(tabs.eggs, "Data", "Loading game modules")
utils.label(tabs.eggs, "Input", "Ready")
for name, path in pairs({
    remotes = services.ReplicatedStorage.Shared.Remotes,
    save = services.ReplicatedStorage.Shared.Save,
    eggs = services.ReplicatedStorage.Client.EggState,
    plots = services.ReplicatedStorage.Client.PlotState,
    roster = services.ReplicatedStorage.Client.AssetRoster,
    assets = services.ReplicatedStorage.Data.Assets,
    rarities = services.ReplicatedStorage.Data.Rarity,
    areas = services.ReplicatedStorage.Data.Areas,
    trails = services.ReplicatedStorage.Data.Trails,
    bases = services.ReplicatedStorage.Data.Bases,
    treadmills = services.ReplicatedStorage.Data.Treadmills,
    eggRecords = services.ReplicatedStorage.Shared.Util.EggRecords,
    assetItems = services.ReplicatedStorage.Shared.Util.AssetItems,
    earnings = services.ReplicatedStorage.Shared.Util.AssetEarnings,
    slotIdentity = services.ReplicatedStorage.Shared.Util.AreaEggSlotIdentity,
    mutations = services.ReplicatedStorage.Shared.Modules.Mutations,
    halloweenPets = services.ReplicatedStorage.Data.HalloweenPets,
    race = services.ReplicatedStorage.Data.RaceRally,
    mountRace = services.ReplicatedStorage.Data.MountRace,
    mastery = services.ReplicatedStorage.Data.BossMastery,
    wisp = services.ReplicatedStorage.Data.WispQuests,
    lightDark = services.ReplicatedStorage.Data.LightVsDarkness,
    beanstalk = services.ReplicatedStorage.Data.BeanstalkEvent
}) do
    if not utils.load(name, path) then utils.message("Data", "Could not load " .. name .. "; rejoin and rerun"); return end
end
utils.message("Data", "Loaded")
utils.options = {
    Rarities = utils.keys(utils.modules.rarities.Rarities),
    Species = utils.keys(utils.modules.assets.Directory),
    Areas = {},
    Mutations = {"Normal"}
}
for name in pairs(utils.call(utils.modules.mutations.Ids)) do table.insert(utils.options.Mutations, name) end
table.sort(utils.options.Mutations)
for _, row in pairs(utils.call(utils.modules.eggs.ReadFieldEggs).Records or {}) do
    if row.AreaId and not table.find(utils.options.Areas, row.AreaId) then table.insert(utils.options.Areas, row.AreaId) end
end
table.sort(utils.options.Areas)

tabs.eggs:AddHeading("Egg farming")
utils.label(tabs.eggs, "Steal")
utils.job(tabs.eggs, "Auto collect", "Steal", 2, utils.steal, utils.stop)
utils.action(tabs.eggs, "Collect egg", "Steal", utils.steal)
tabs.eggs:AddHeading("Targets")
utils.dropdown(tabs.eggs, "Priority", utils.settings.eggs, "Priority", {"Value", "Rarity", "Weight", "Closest"})
utils.multi(tabs.eggs, "Rarities", utils.settings.eggs, "Rarities", utils.options.Rarities, "Eggs.Rarities")
utils.multi(tabs.eggs, "Areas", utils.settings.eggs, "Areas", utils.options.Areas, "Eggs.Areas")
utils.multi(tabs.eggs, "Mutations", utils.settings.eggs, "Mutations", utils.options.Mutations, "Eggs.Mutations")
utils.multi(tabs.eggs, "Species", utils.settings.eggs, "Species", utils.options.Species, "Eggs.Species")
utils.number(tabs.eggs, "Minimum weight (kg)", utils.settings.eggs, "MinWeight")
utils.number(tabs.eggs, "Minimum value", utils.settings.eggs, "MinValue")
utils.action(tabs.eggs, "Check target", "Steal", function()
    local target = utils.fieldEggs()[1]
    assert(target, "No eggs match your filters")
    utils.selection.Target = target.Uid
    return string.format("%s | %s | %.2f kg | %.0f studs", target.Category, target.Rarity, target.Weight, target.Distance)
end)
utils.action(tabs.eggs, "Collect rarest egg", "Steal", function() return utils.steal("Rarity", true) end)
tabs.eggs:AddHeading("Travel")
utils.action(tabs.eggs, "Drop egg", "Steal", function()
    local accepted, reason = utils.call(utils.modules.eggs.DropFieldEgg)
    assert(accepted, reason or "No field egg is held")
    return "Egg dropped"
end)
utils.dropdown(tabs.eggs, "Method", utils.settings.travel, "Mode", {"Walk", "Tween", "Step"})
utils.slider(tabs.eggs, "Travel speed", utils.settings.travel, "Speed", 20, 300)
utils.action(tabs.eggs, "Go home", "Steal", function()
    utils.stop()
    assert(utils.home(), "Return route cancelled")
    return "At your plot"
end)
tabs.eggs:AddButton("Stop moving", function() utils.stop(); utils.message("Steal", "Stopped") end)

tabs.manage:AddHeading("Place eggs")
utils.multi(tabs.manage, "Rarities", utils.settings.place, "Rarities", utils.options.Rarities, "Place.Rarities")
utils.multi(tabs.manage, "Mutations", utils.settings.place, "Mutations", utils.options.Mutations, "Place.Mutations")
utils.number(tabs.manage, "Minimum weight (kg)", utils.settings.place, "MinWeight")
utils.slider(tabs.manage, "Spacing", utils.settings.place, "Spacing", 2, 16)
utils.label(tabs.manage, "Place")
utils.job(tabs.manage, "Auto place", "Place", 3, utils.place, utils.stop)
utils.action(tabs.manage, "Place eggs", "Place", utils.place)
tabs.manage:AddHeading("Hatch eggs")
utils.slider(tabs.manage, "Delay", utils.settings.hatch, "Delay", 1, 10)
utils.label(tabs.manage, "Hatch")
utils.job(tabs.manage, "Auto hatch", "Hatch", 2, utils.hatch)
utils.action(tabs.manage, "Hatch ready eggs", "Hatch", utils.hatch)
tabs.sell:AddHeading("Eggs")
utils.multi(tabs.sell, "Rarities", utils.settings.eggSell, "Rarities", utils.options.Rarities, "EggSell.Rarities")
utils.multi(tabs.sell, "Mutations", utils.settings.eggSell, "Mutations", utils.options.Mutations, "EggSell.Mutations")
utils.number(tabs.sell, "Maximum weight (kg)", utils.settings.eggSell, "MaxWeight")
tabs.sell:AddSwitch("Weight only", function(enabled) utils.settings.eggSell.WeightOnly = enabled end)
utils.controls.ProtectHalloween = tabs.sell:AddSwitch("Keep Halloween eggs", function(enabled) utils.settings.eggSell.ProtectHalloween = enabled end)
utils.controls.ProtectHalloween:Set(true)
utils.label(tabs.sell, "EggSell")
utils.job(tabs.sell, "Auto sell eggs", "EggSell", 5, utils.sellEggs)
utils.action(tabs.sell, "Sell eggs", "EggSell", utils.sellEggs)

tabs.pets:AddHeading("Equipment")
utils.slider(tabs.pets, "Equip interval", utils.settings.pets, "Interval", 5, 60)
utils.label(tabs.pets, "Equip")
utils.job(tabs.pets, "Auto equip best", "Equip", function() return utils.settings.pets.Interval end, function() utils.remote("Haul", "WearBest"); return "Best pets equipped" end)
utils.action(tabs.pets, "Equip best", "Equip", function() utils.remote("Haul", "WearBest"); return "Best pets equipped" end)
tabs.sell:AddHeading("Pets")
utils.multi(tabs.sell, "Rarities", utils.settings.sell, "Rarities", utils.options.Rarities, "Sell.Rarities")
utils.multi(tabs.sell, "Species", utils.settings.sell, "Species", utils.options.Species, "Sell.Species")
utils.multi(tabs.sell, "Mutations", utils.settings.sell, "Mutations", utils.options.Mutations, "Sell.Mutations")
utils.number(tabs.sell, "Maximum income /s", utils.settings.sell, "MaxIncome")
utils.slider(tabs.sell, "Keep best pets", utils.settings.sell, "KeepBest", 1, 20)
tabs.sell:AddSwitch("Unequip before selling", function(enabled) utils.settings.sell.Unequip = enabled end)
utils.label(tabs.sell, "PetSell")
utils.job(tabs.sell, "Auto sell pets", "PetSell", 5, utils.sellPets)
utils.action(tabs.sell, "Sell pets", "PetSell", utils.sellPets)
tabs.pets:AddHeading("Fusion")
utils.dropdown(tabs.pets, "Maximum rarity", utils.settings.fuse, "MaxRarity", utils.options.Rarities)
utils.multi(tabs.pets, "Species", utils.settings.fuse, "Species", utils.options.Species, "Fuse.Species")
utils.controls.SkipMutated = tabs.pets:AddSwitch("Skip mutated pets", function(enabled) utils.settings.fuse.SkipMutated = enabled end)
utils.controls.SkipMutated:Set(true)
tabs.pets:AddSwitch("Return incomplete sets", function(enabled) utils.settings.fuse.EjectIncomplete = enabled end)
utils.label(tabs.pets, "Fuse")
utils.job(tabs.pets, "Auto fuse", "Fuse", 5, utils.fuse)
utils.action(tabs.pets, "Fuse pets", "Fuse", utils.fuse)

tabs.manage:AddHeading("Offline income")
utils.label(tabs.manage, "Offline")
utils.job(tabs.manage, "Auto claim income", "Offline", 30, function()
    local summary = utils.remote("AwayEarnings", "FetchSummary")
    if not summary or (summary.TotalAmount or 0) <= 0 then return "No pending offline earnings" end
    utils.remote("AwayEarnings", "AskCollect", {Kind = "Claim"})
    return "Offline earnings claimed"
end)
utils.action(tabs.manage, "Claim income", "Offline", function() utils.remote("AwayEarnings", "AskCollect", {Kind = "Claim"}); return "Claim requested" end)
tabs.automation:AddHeading("Treadmill")
utils.slider(tabs.automation, "Level limit", utils.settings.treadmill, "MaxLevel", 1, 100)
utils.label(tabs.automation, "TreadmillUpgrade")
utils.job(tabs.automation, "Auto upgrade treadmill", "TreadmillUpgrade", 3, utils.upgradeTreadmill)
utils.action(tabs.automation, "Upgrade treadmill", "TreadmillUpgrade", utils.upgradeTreadmill)
utils.label(tabs.automation, "Training")
utils.job(tabs.automation, "Auto train", "Training", 5, function()
    assert(not utils.moving and not utils.jobs.Steal.Enabled and not utils.jobs.Place.Enabled and not utils.jobs.Hatch.Enabled, "Paused during egg automation")
    utils.remote("Treadmill", "AskWearStill")
    return "Training requested"
end, function() pcall(utils.remote, "Treadmill", "AskDoff") end)
tabs.automation:AddHeading("Pen")
utils.label(tabs.automation, "PenUpgrade")
utils.job(tabs.automation, "Auto upgrade pen", "PenUpgrade", 4, utils.upgradePen)
utils.action(tabs.automation, "Upgrade pen", "PenUpgrade", utils.upgradePen)
tabs.automation:AddHeading("Trails")
utils.multi(tabs.automation, "Trails", utils.settings.trails, "Selected", utils.keys(utils.modules.trails.Directory), "Trails.Selected", "none")
utils.label(tabs.automation, "Trails")
utils.job(tabs.automation, "Auto buy selected", "Trails", 5, function() return utils.buyTrails(false) end)
utils.action(tabs.automation, "Buy selected trails", "Trails", function() return utils.buyTrails(false) end)
utils.label(tabs.automation, "AllTrails")
utils.job(tabs.automation, "Auto buy all", "AllTrails", 5, function() return utils.buyTrails(true) end)
utils.action(tabs.automation, "Buy all cash trails", "AllTrails", function() return utils.buyTrails(true) end)
utils.label(tabs.automation, "EquipTrail")
utils.job(tabs.automation, "Auto equip best", "EquipTrail", 10, utils.equipTrail)
utils.action(tabs.automation, "Equip best trail", "EquipTrail", utils.equipTrail)

utils.visualFolder = Instance.new("Folder")
utils.visualFolder.Name = "SilenceEggVisuals"
utils.visualFolder.Parent = services.Workspace
tabs.visuals:AddHeading("Highlights")
tabs.visuals:AddSwitch("Eggs", function(enabled) utils.settings.visuals.EggESP = enabled end)
tabs.visuals:AddSwitch("Show unhatched pets", function(enabled) utils.settings.visuals.Predictor = enabled end)
tabs.visuals:AddSwitch("Guards", function(enabled) utils.settings.visuals.GuardESP = enabled end)
tabs.visuals:AddSwitch("Other players' eggs", function(enabled) utils.settings.visuals.Everyone = enabled end)
utils.slider(tabs.visuals, "View distance", utils.settings.visuals, "Distance", 50, 10000, 50)
utils.multi(tabs.visuals, "Rarities", utils.settings.visuals, "Rarities", utils.options.Rarities, "ESP.Rarities")
utils.multi(tabs.visuals, "Mutations", utils.settings.visuals, "Mutations", utils.options.Mutations, "ESP.Mutations")
utils.label(tabs.visuals, "ESP")
tabs.visuals:AddHeading("Performance")
tabs.visuals:AddSwitch("Hide pets", function(enabled)
    local folder = services.Workspace:FindFirstChild("ClientRenderedAssets")
    if enabled and folder then
        for _, part in ipairs(folder:GetDescendants()) do if part:IsA("BasePart") then utils.remember(part, "LocalTransparencyModifier", 1) end end
    else utils.restore("LocalTransparencyModifier") end
    utils.settings.visuals.HidePets = enabled
end)
runtime:Connect(services.Workspace.DescendantAdded, function(instance)
    if utils.settings.visuals.HidePets and instance:IsA("BasePart") then
        local folder = services.Workspace:FindFirstChild("ClientRenderedAssets")
        if folder and instance:IsDescendantOf(folder) then utils.remember(instance, "LocalTransparencyModifier", 1) end
    end
end)

tabs.player:AddHeading("Movement")
utils.slider(tabs.player, "Walkspeed", utils.settings.player, "Speed", 8, 2000)
tabs.player:AddSwitch("Custom speed", function(enabled)
    utils.settings.player.SpeedEnabled = enabled
    if not enabled then utils.restore("WalkSpeed") end
end)
utils.slider(tabs.player, "Jump power", utils.settings.player, "JumpPower", 20, 400)
tabs.player:AddSwitch("Custom jump", function(enabled)
    utils.settings.player.JumpEnabled = enabled
    if not enabled then utils.restore("JumpPower"); utils.restore("UseJumpPower") end
end)
tabs.player:AddSwitch("Infinite jump", function(enabled) utils.settings.player.InfiniteJump = enabled end)
tabs.player:AddSwitch("Anti ragdoll", function(enabled) utils.settings.player.AntiRagdoll = enabled end)
tabs.player:AddSwitch("Instant prompts", function(enabled)
    utils.settings.player.InstantPrompts = enabled
    if not enabled then utils.restore("HoldDuration") end
end)
utils.label(tabs.player, "Movement", "Server movement rules may override local settings")
runtime:Connect(services.UserInputService.JumpRequest, function()
    if utils.settings.player.InfiniteJump and not services.UserInputService:GetFocusedTextBox() then
        local _, humanoid = utils.character()
        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)
runtime:Connect(services.ProximityPromptService.PromptShown, function(prompt)
    if utils.settings.player.InstantPrompts then utils.remember(prompt, "HoldDuration", 0) end
end)
runtime:Connect(services.RunService.Heartbeat, function()
    local _, humanoid = utils.character()
    if not humanoid then return end
    if utils.settings.player.SpeedEnabled and not utils.moving then utils.remember(humanoid, "WalkSpeed", utils.settings.player.Speed) end
    if utils.settings.player.JumpEnabled then utils.remember(humanoid, "UseJumpPower", true); utils.remember(humanoid, "JumpPower", utils.moving and math.min(50, utils.settings.player.JumpPower) or utils.settings.player.JumpPower) end
    if utils.settings.player.AntiRagdoll and (humanoid:GetState() == Enum.HumanoidStateType.Ragdoll or humanoid:GetState() == Enum.HumanoidStateType.Physics) then
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end)

tabs.server:AddHeading("Server hopping")
utils.dropdown(tabs.server, "Preference", utils.settings.server, "Mode", {"Least Players", "Most Players", "Random"})
utils.slider(tabs.server, "Hop delay", utils.settings.server, "Delay", 5, 120)
utils.label(tabs.server, "Server")
utils.action(tabs.server, "Find a server", "Server", utils.serverHop)
utils.job(tabs.server, "Hop when targets run out", "AutoHop", function() return utils.settings.server.Delay end, function()
    if utils.moving then return "Waiting for egg delivery" end
    if #utils.fieldEggs() > 0 then return "Matching eggs remain" end
    return utils.serverHop()
end)
tabs.server:AddHeading("Join a server")
tabs.server:AddButton("Copy server ID", function()
    if type(setclipboard) == "function" then setclipboard(game.JobId); utils.message("Server", "JobId copied")
    else utils.message("Server", game.JobId) end
end)
tabs.server:AddTextBox("Server ID", function(value) utils.settings.server.Target = tostring(value):match("^%s*(.-)%s*$") end, {clear = false})
utils.action(tabs.server, "Join server", "Server", function()
    assert(utils.settings.server.Target:match("^[%x]+%-%x+%-%x+%-%x+%-%x+$"), "Enter a valid JobId")
    services.TeleportService:TeleportToPlaceInstance(game.PlaceId, utils.settings.server.Target, utils.player)
    return "Joining target server"
end)
runtime:Connect(services.TeleportService.TeleportInitFailed, function(player, _, message)
    if player == utils.player then utils.hopping = false; utils.message("Server", message) end
end)

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
    local success, result = pcall(utils.move, utils.worldPosition(instance) + Vector3.new(0, 3, 0), route)
    if utils.route == route then utils.moving = false end
    if not success then error(result, 0) end
    assert(result, "Travel cancelled or destination not reached")
    return "Destination reached"
end

function utils.halloweenEggs()
    local entries = {}
    local _, _, root = utils.character()
    for _, model in ipairs(services.CollectionService:GetTagged("HalloweenWorldEgg")) do
        if model:IsA("Model") and model:GetAttribute("HalloweenEggCanPickUp") == true then
            local category = model:GetAttribute("PreparedSourceName")
            local spec = utils.modules.halloweenPets.Specs[category]
            local rarity = spec and spec.Rarity
            local zone = tostring(model:GetAttribute("Zone"))
            if spec and utils.matches(utils.settings.halloween.Zones, zone)
                and utils.matches(utils.settings.halloween.Species, category)
                and utils.matches(utils.settings.halloween.Rarities, rarity)
                and spec.EarningRate >= utils.settings.halloween.MinValue then
                table.insert(entries, {Model = model, Uid = model:GetAttribute("HalloweenEggUid"), Category = category,
                    Rank = utils.modules.rarities.Rarities[rarity].Rank, Value = spec.EarningRate,
                    Distance = root and (model:GetPivot().Position - root.Position).Magnitude or math.huge})
            end
        end
    end
    table.sort(entries, function(a, b)
        local priority = utils.settings.halloween.Priority
        local av = priority == "Closest" and -a.Distance or priority == "Value" and a.Value or a.Rank
        local bv = priority == "Closest" and -b.Distance or priority == "Value" and b.Value or b.Rank
        return av == bv and a.Uid < b.Uid or av > bv
    end)
    return entries
end

function utils.halloweenSteal()
    assert(utils.player:GetAttribute("InHalloweenDimension"), "Enter the Halloween dimension first")
    if not utils.player:GetAttribute("HalloweenCarrying") then
        local target = utils.halloweenEggs()[1]
        assert(target, "No Halloween eggs match your filters")
        utils.visit(target.Model)
        utils.remote("HalloweenDimension", "AskCarryEgg", target.Uid)
    end
    local dimension = services.Workspace:FindFirstChild("HalloweenDimension")
    local spawns = dimension and dimension:FindFirstChild("Spawns")
    utils.visit(spawns and spawns:FindFirstChild("EntryCircle"))
    return "Returned to the Halloween entry"
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

tabs.racing:AddHeading("Rewards")
utils.label(tabs.racing, "RaceRewards")
utils.job(tabs.racing, "Auto claim rewards", "RaceRewards", 10, utils.claimRace)
utils.action(tabs.racing, "Claim rewards", "RaceRewards", utils.claimRace)
tabs.racing:AddHeading("Mounts")
utils.options.Racers = {"Best Owned"}
for _, row in ipairs(utils.call(utils.modules.race.OrderedRacers)) do table.insert(utils.options.Racers, row.Id) end
utils.dropdown(tabs.racing, "Racer", utils.settings.race, "Racer", utils.options.Racers)
utils.label(tabs.racing, "Racer")
utils.job(tabs.racing, "Auto equip racer", "Racer", 10, utils.equipRacer)
utils.action(tabs.racing, "Equip racer", "Racer", utils.equipRacer)
tabs.racing:AddHeading("Shop")
utils.options.RaceShop = {}
for _, row in ipairs(utils.call(utils.modules.race.OrderedOffers)) do table.insert(utils.options.RaceShop, row.Id) end
utils.multi(tabs.racing, "Items", utils.settings.race, "Shop", utils.options.RaceShop, "Race.Shop", "none")
utils.number(tabs.racing, "Trophy reserve", utils.settings.race, "Reserve")
utils.label(tabs.racing, "RaceShop")
utils.job(tabs.racing, "Auto buy selected", "RaceShop", 8, utils.buyRaceShop)
utils.action(tabs.racing, "Buy selected items", "RaceShop", utils.buyRaceShop)
tabs.racing:AddHeading("Travel")
utils.label(tabs.racing, "RaceJoin")
utils.action(tabs.racing, "Go to race portal", "RaceJoin", function()
    local world = services.Workspace:FindFirstChild("World")
    return utils.visit(world and world:FindFirstChild("RaceRallyPortal"))
end)

tabs.events:AddHeading("Rift")
utils.label(tabs.events, "Boss")
utils.action(tabs.events, "Enter rift", "Boss", function() utils.remote("BossEvent", "AskEnter"); return "Rift entry accepted" end)
utils.label(tabs.events, "Mastery")
utils.job(tabs.events, "Auto claim mastery", "Mastery", 10, utils.claimMastery)
utils.action(tabs.events, "Claim mastery", "Mastery", utils.claimMastery)
tabs.events:AddHeading("Boss shop")
utils.options.BossShop = {}
for _, offer in ipairs(utils.modules.mastery.ShopProducts) do table.insert(utils.options.BossShop, offer.Id) end
utils.multi(tabs.events, "Items", utils.settings.mastery, "Shop", utils.options.BossShop, "Boss.Shop", "none")
utils.number(tabs.events, "Token reserve", utils.settings.mastery, "Reserve")
utils.label(tabs.events, "BossShop")
utils.job(tabs.events, "Auto buy selected", "BossShop", 8, utils.buyBossShop)
utils.action(tabs.events, "Buy selected items", "BossShop", utils.buyBossShop)
tabs.events:AddHeading("Wisp")
utils.label(tabs.events, "Wisp")
utils.job(tabs.events, "Claim completed quests", "Wisp", 10, function()
    local state = utils.save().WispCompanion or {}
    if not state.Unlocked or not state.Accepted then return "Accept a Wisp quest in the game first" end
    local count = 0
    for _, quest in ipairs(utils.modules.wisp.List) do
        if not (state.Claimed or {})[quest.Id] and (state.Progress or {})[quest.Id] and state.Progress[quest.Id] >= quest.Target then
            utils.remote("WispCompanion", "Request", "Claim", quest.Id)
            count += 1
            task.wait(0.5)
        end
    end
    return count .. " completed quests claimed"
end)
tabs.events:AddHeading("Light vs Darkness")
utils.dropdown(tabs.events, "Team", utils.settings.lightDark, "Team", {"Light", "Darkness"})
utils.label(tabs.events, "LightTeam")
utils.action(tabs.events, "Join team", "LightTeam", function()
    utils.remote("LightVsDarkness", "AskSelectTeam", utils.settings.lightDark.Team)
    return "Team selection requested"
end)
utils.label(tabs.events, "LightRings")
utils.job(tabs.events, "Collect rings", "LightRings", 1, function() return utils.collectFolder("LightVsDarknessRings") end, utils.stop)
utils.label(tabs.events, "LightPowerUps")
utils.job(tabs.events, "Collect power-ups", "LightPowerUps", 1, function() return utils.collectFolder("LightVsDarknessPowerUps") end, utils.stop)
utils.label(tabs.events, "LightRewards")
utils.job(tabs.events, "Claim milestones", "LightRewards", 5, function()
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
tabs.events:AddHeading("Sammy")
utils.label(tabs.events, "Sammy")
utils.job(tabs.events, "Collect pickups", "Sammy", 1, function() return utils.collectFolder("SammyEmpPickups") end, utils.stop)
tabs.events:AddHeading("Beanstalk")
utils.label(tabs.events, "Beanstalk")
utils.job(tabs.events, "Stage assist", "Beanstalk", 1, function()
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
    return "Complete the current flight or escape stage in the game"
end)

tabs.halloween:AddHeading("Travel")
utils.label(tabs.halloween, "Dimension")
utils.action(tabs.halloween, "Go to gateway", "Dimension", function()
    local world = services.Workspace:FindFirstChild("World")
    return utils.visit(world and world:FindFirstChild("HalloweenDimensionPortal"))
end)
utils.action(tabs.halloween, "Go to entrance", "Dimension", function()
    local dimension = services.Workspace:FindFirstChild("HalloweenDimension")
    local spawns = dimension and dimension:FindFirstChild("Spawns")
    return utils.visit(spawns and spawns:FindFirstChild("EntryCircle"))
end)
tabs.halloween:AddHeading("Eggs")
utils.multi(tabs.halloween, "Zones", utils.settings.halloween, "Zones", {"1", "2", "3"}, "Halloween.Zones")
utils.multi(tabs.halloween, "Rarities", utils.settings.halloween, "Rarities", utils.options.Rarities, "Halloween.Rarities")
utils.multi(tabs.halloween, "Species", utils.settings.halloween, "Species", utils.keys(utils.modules.halloweenPets.Specs), "Halloween.Species")
utils.number(tabs.halloween, "Minimum income /s", utils.settings.halloween, "MinValue")
utils.dropdown(tabs.halloween, "Priority", utils.settings.halloween, "Priority", {"Rarity", "Value", "Closest"})
utils.label(tabs.halloween, "HalloweenSteal")
utils.job(tabs.halloween, "Auto collect", "HalloweenSteal", 3, utils.halloweenSteal, utils.stop)
utils.action(tabs.halloween, "Collect egg", "HalloweenSteal", utils.halloweenSteal)
utils.action(tabs.halloween, "Drop egg", "HalloweenSteal", function() utils.remote("HalloweenDimension", "AskDropEgg"); return "Drop requested" end)
tabs.halloween:AddHeading("Shop")
utils.label(tabs.halloween, "HalloweenShop")
utils.job(tabs.halloween, "Auto buy egg", "HalloweenShop", 10, function() utils.remote("HalloweenDimension", "AskBuyEgg"); return "Dimension egg purchased" end)
utils.action(tabs.halloween, "Buy egg", "HalloweenShop", function() utils.remote("HalloweenDimension", "AskBuyEgg"); return "Dimension egg purchased" end)
tabs.halloween:AddHeading("Ghost Hunter")
utils.label(tabs.halloween, "Manor")
utils.action(tabs.halloween, "Talk", "Manor", function()
    utils.remote("HalloweenManor", "Talk")
    return "Ghost Hunter interaction accepted"
end)

tabs.customize = silence:AddCustomizeTab()
tabs.configs, utils.configManager = silence:AddConfigTab({Folder = "Silence/Configs/StealAnEgg"})
tabs.info = silence:AddTab("About")
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
tabs.info:AddLabel("")
tabs.info:AddLabel("Silence is Open-Source!")
tabs.info:AddLabel("")
tabs.info.VersionLabel = tabs.info:AddLabel("Steal An Egg [V1.0.0]")
tabs.info.VersionLabel.TextSize = 20
tabs.info.VersionLabel.Font = Enum.Font.Arcade
tabs.eggs:AddHeading("Status")
utils.label(tabs.eggs, "Runtime", "Running")
utils.label(tabs.eggs, "Dashboard", "Loading")
tabs.eggs:AddButton("Stop all automation", function()
    for key in pairs(utils.jobs) do
        if utils.controls[key .. "Switch"] then utils.controls[key .. "Switch"]:Set(false) end
        if utils.jobs[key].Thread and coroutine.status(utils.jobs[key].Thread) ~= "dead" then
            pcall(task.cancel, utils.jobs[key].Thread)
            runtime.Threads[utils.jobs[key].Thread] = nil
        end
        utils.jobs[key].Thread = nil
        utils.jobs[key].Busy = false
    end
    table.clear(utils.pipeline.Requests)
    utils.cancelPipeline()
    utils.message("Runtime", "Automation stopped")
end)
tabs.configs:AddButton("Unload Silence", function() silence:Destroy() end)
runtime:AddCleanup(function()
    utils.stop()
    utils.visualFolder:Destroy()
    if utils.navigation.Folder then utils.navigation.Folder:Destroy() end
    for instance, properties in pairs(utils.originals) do
        if instance.Parent then for property, value in pairs(properties) do pcall(function() instance[property] = value end) end end
    end
end)
runtime:Connect(utils.player.CharacterAdded, function() utils.stop() end)
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
        if not success then utils.message("ESP", result) end
        utils.message("Dashboard", table.concat({
            "Steal: " .. (utils.status.Steal or "Off"),
            "Place: " .. (utils.status.Place or "Off"),
            "Hatch: " .. (utils.status.Hatch or "Off"),
            "Race: " .. (utils.status.RaceRewards or "Off"),
            "Halloween: " .. (utils.status.HalloweenSteal or "Off")
        }, "\n"))
        task.wait(1)
    end
end)
utils.configManager:LoadStartup()
tabs.info:Show()
