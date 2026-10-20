return function(utils, silence)
    local results = {}
    local original = {
        Save = utils.save,
        Remote = utils.remote,
        Sell = utils.settings.sell,
        EggSell = utils.settings.eggSell,
        Eggs = utils.modules.eggs,
        HatchDelay = utils.settings.hatch.Delay,
        EggFilters = utils.settings.eggs,
        Areas = table.clone(utils.settings.eggs.Areas),
        PendingWork = utils.pendingWork,
        PipelineOwner = utils.pipeline.Owner,
        PipelineRequests = utils.pipeline.Requests,
        PipelineNext = utils.pipeline.Next,
        NavigationZones = utils.navigation.Zones,
        Enabled = {Steal = utils.jobs.Steal.Enabled, Place = utils.jobs.Place.Enabled, Hatch = utils.jobs.Hatch.Enabled}
    }
    local success, failure = pcall(function()
        local category
        for name, config in pairs(utils.modules.assets.Directory) do
            if config.Rarity._id == "Common" then category = name; break end
        end
        assert(category, "No common category available for tests")
        local calls = {}
        utils.remote = function(group, name, packet)
            table.insert(calls, {Group = group, Name = name, Packet = packet})
            return true
        end
        utils.save = function()
            return {
                Inventory = {
                    best = {Category = category, Scale = 3, Mutations = {}},
                    favorite = {Category = category, Scale = 1, Mutations = {}, IsFavorite = true},
                    fusing = {Category = category, Scale = 1, Mutations = {}, InFuse = true},
                    equipped = {Category = category, Scale = 1, Mutations = {}},
                    eligible = {Category = category, Scale = 1, Mutations = {}}
                },
                EquippedAssets = {"equipped"}
            }
        end
        utils.settings.sell = {Rarities = {}, Species = {}, Mutations = {}, MaxIncome = 0, KeepBest = 1, Unequip = false}
        assert(not pcall(utils.sellPets), "Unfiltered selling must be rejected")
        assert(#calls == 0, "Rejected selling emitted a remote call")
        table.insert(results, "Unfiltered selling rejected")
        utils.settings.sell.Rarities.Common = true
        utils.sellPets()
        assert(#calls == 1 and calls[1].Name == "SellSelection", "Expected one sale packet")
        assert(#calls[1].Packet.Assets == 1 and calls[1].Packet.Assets[1] == "eligible", "Pet protection failed")
        table.insert(results, "Favorite, fusion, equipment and keep-best protections")
        utils.settings.eggSell = {Rarities = {}, Mutations = {}, MaxWeight = 0, WeightOnly = true, ProtectHalloween = true}
        assert(not pcall(utils.sellEggs), "Weight-only selling without a weight cap must fail")
        table.insert(results, "Weight-only selling requires a limit")
        utils.settings.hatch.Delay = 0
        utils.modules.eggs = table.clone(original.Eggs)
        local hatched = {}
        utils.modules.eggs.ReadOwnerEggs = function() return {ready = {}, growing = {}} end
        utils.modules.eggs.IsReadyToHatch = function(uid) return uid == "ready" end
        utils.modules.eggs.BeginHatch = function(uid) table.insert(hatched, "begin:" .. uid); return true, nil, "session:" .. uid end
        utils.modules.eggs.FinishHatch = function(token) table.insert(hatched, "finish:" .. token); return true end
        assert(utils.hatch() == "1 eggs hatched", "Expected one hatch")
        assert(table.concat(hatched, ",") == "begin:ready,finish:session:ready", "Hatch lifecycle, token or readiness failed")
        table.insert(results, "Only ready eggs complete the hatch lifecycle")
        utils.modules.eggs.ReadFieldEggs = function() return {Records = {}} end
        assert(#utils.fieldEggs() == 0, "Empty field snapshot should be empty")
        table.insert(results, "Empty field snapshots handled")
        local config = silence:GetConfigValues()
        for key in pairs(config) do assert(not key:find("/AddDropdown/Toggle ", 1, true), "Toggle dropdown leaks into config") end
        assert(type(config["Eggs.Rarities"]) == "table", "Multi-select is not serialized")
        table.insert(results, "Multi-select config serialization")
        assert(#silence:ApplyConfigValues({["Eggs.Areas"] = {Forest = true}}) == 0, "Config application failed")
        assert(#silence:ApplyConfigValues({["Eggs.Areas"] = {Forest = true}}) == 0, "Repeated config application failed")
        assert(utils.settings.eggs.Areas.Forest == true, "Repeated application toggled the filter off")
        table.insert(results, "Multi-select config loading is idempotent")
        utils.pipeline.Owner = nil
        utils.pipeline.Requests = {}
        utils.pipeline.Next = {}
        for _, key in ipairs({"Steal", "Place", "Hatch"}) do utils.jobs[key].Enabled = true end
        local work = {Hatch = 1, Place = 2}
        utils.pendingWork = function() return work end
        utils.modules.eggs.ReadCarryState = function() return {IsCarrying = false} end
        assert(utils.nextPipelineJob() == "Hatch", "Ready eggs must hatch before farming")
        work.Hatch = 0
        assert(utils.nextPipelineJob() == "Place", "Unplaced eggs must be placed before farming")
        work.Place = 0
        assert(utils.nextPipelineJob() == "Steal", "Farming must resume after inventory work")
        work.Hatch = 1
        utils.modules.eggs.ReadCarryState = function() return {IsCarrying = true} end
        assert(utils.nextPipelineJob() == "Steal", "A carried egg must be delivered first")
        utils.pipeline.Owner = "Place"
        assert(utils.nextPipelineJob() == nil, "Concurrent character jobs must be rejected")
        utils.controls.HatchSwitch:Set(false)
        assert(utils.pipeline.Owner == "Place", "Disabling hatch interrupted placement")
        utils.pipeline.Owner = nil
        table.insert(results, "Egg jobs serialize, prioritize inventory and resume farming")
        local zone = Instance.new("Part")
        zone.Anchored = true
        zone.CanCollide = false
        zone.CanTouch = false
        zone.Transparency = 1
        zone.Size = Vector3.new(4, 10, 6)
        zone.CFrame = CFrame.new(0, -1000, 0) * CFrame.Angles(0, math.rad(30), 0)
        zone.Parent = workspace
        utils.navigation.Zones = {test = zone}
        local crosses = utils.segmentAvoided(Vector3.new(-10, -1000, 0), Vector3.new(10, -1000, 0))
        local clears = not utils.segmentAvoided(Vector3.new(-10, -1000, 10), Vector3.new(10, -1000, 10))
        zone:Destroy()
        utils.navigation.Zones = original.NavigationZones
        assert(crosses and clears, "Avoidance must block crossing a rotated zone without blocking a clear route")
        table.insert(results, "Rotated treadmill/shop zones reject crossing segments")
    end)
    utils.save = original.Save
    utils.remote = original.Remote
    utils.settings.sell = original.Sell
    utils.settings.eggSell = original.EggSell
    utils.modules.eggs = original.Eggs
    utils.settings.hatch.Delay = original.HatchDelay
    utils.settings.eggs = original.EggFilters
    utils.settings.eggs.Areas = original.Areas
    utils.pendingWork = original.PendingWork
    utils.pipeline.Owner = original.PipelineOwner
    utils.pipeline.Requests = original.PipelineRequests
    utils.pipeline.Next = original.PipelineNext
    utils.navigation.Zones = original.NavigationZones
    for key, enabled in pairs(original.Enabled) do utils.jobs[key].Enabled = enabled end
    utils.identityReset()
    if not success then error(failure, 0) end
    return results
end
