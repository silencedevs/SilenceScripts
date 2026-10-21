return function(utils, window)
    local results, calls = {}, {}
    local original = {Save = utils.save, Remote = utils.remote, Pets = utils.settings.pets, Farm = utils.settings.farm, Boosts = utils.settings.boosts, Memory = utils.memory, Originals = utils.originals, Trip = utils.trip, Portal = utils.islandPortal, HideClicks = utils.clickVisuals.Enabled}
    local success, failure = xpcall(function()
        utils.stop()
        utils.remote = function(group, name, packet)
            table.insert(calls, {Group = group, Name = name, Packet = packet})
            return {Success = true}
        end
        utils.tap()
        utils.tap()
        assert(#calls == 2, "Auto Tap must only send manual tap requests")
        for _, call in ipairs(calls) do
            assert(call.Group == "Tap" and call.Name == "TapRequested" and call.Packet.Auto == false, "Auto Tap changed the built-in auto clicker")
        end
        assert(calls[2].Packet.ClientSequence > calls[1].Packet.ClientSequence, "Tap sequences must increase")
        assert(utils.jobs.Tap.Interval == utils.modules.gameConfig.ManualTapInterval, "Tap interval differs from the game limit")
        table.insert(results, "Auto Tap sends manual requests at the configured limit without toggling the native auto clicker")
        table.clear(calls)
        local data = {
            Pets = {Equipped = {"equipped"}, StorageLimit = 150, Owned = {
                equipped = {Name = "Doggy", Rarity = "Common", Tier = "Normal"},
                locked = {Name = "Doggy", Rarity = "Common", Tier = "Normal", Locked = true},
                enchanted = {Name = "Doggy", Rarity = "Common", Tier = "Normal", Enchant = "Power I"},
                reserved = {Name = "Doggy", Rarity = "Common", Tier = "Normal", Reserved = true},
                free = {Name = "Doggy", Rarity = "Common", Tier = "Normal"}
            }},
            Currencies = {Coins = 0, Gems = 0}, Statistics = {Rebirths = 0, EggsOpened = 1},
            Upgrades = {RebirthButtons = 2}, Progression = {World = "Main", UnlockedIslands = {}, UnlockedZones = {}},
            Boosts = {}, Items = {Owned = {}}, ActiveBoosts = {}, Settings = {HideClicks = false}
        }
        utils.save = function() return data end
        utils.settings.pets = {Names = {}, Rarities = {}, Tiers = {}, GoldenCount = 6, GoldenPets = {["All Pets"] = true}, DiamondCount = 5, DiamondPets = {["All Pets"] = true}}
        assert(not pcall(utils.sellPets) and #calls == 0, "Unfiltered pet deletion emitted a request")
        utils.settings.pets.Rarities.Common = true
        utils.settings.pets.Tiers.Normal = true
        utils.settings.pets.Names["All Pets"] = true
        utils.jobs.Cleanup.Enabled = true
        utils.sellPets()
        utils.jobs.Cleanup.Enabled = false
        assert(#calls == 1 and #calls[1].Packet.PetIds == 1 and calls[1].Packet.PetIds[1] == "free", "Protected pets were selected for deletion")
        table.insert(results, "Deletion requires explicit filters; equipped, locked, enchanted and reserved pets survive")

        for index = 1, 12 do data.Pets.Owned["copy" .. index] = {Name = "Kitty", Rarity = "Common", Tier = "Normal"} end
        local groups = utils.craftGroups("Golden", data)
        assert(#groups == 2, "Golden batches must use exact group sizes")
        local seen = {}
        for _, ids in ipairs(groups) do
            assert(#ids == 6, "Incomplete golden group")
            for _, id in ipairs(ids) do assert(not seen[id], "A pet was reused in two crafts"); seen[id] = true end
        end
        utils.settings.pets.GoldenPets = {Doggy = true}
        assert(#utils.craftGroups("Golden", data) == 0, "Species filter ignored")
        table.insert(results, "Craft groups are disjoint, respect species filters and exclude protected pets")

        utils.settings.farm = {Rebirth = "16", Egg = "Basic", Reserve = 1000}
        assert(utils.rebirthIndex(data, false) == 3, "Locked rebirth buttons must fall back to the highest unlocked button")
        assert(utils.rebirthIndex(data, true) == nil, "Unaffordable rebirth selected")
        data.Currencies.Coins = 100000000
        assert(utils.rebirthIndex(data, true) == 3, "Highest affordable rebirth was not selected")
        table.insert(results, "Rebirth selection respects unlocks and affordability")

        data.Currencies.Coins = 999
        assert(utils.pickEgg(data) == "Basic", "Explicit egg selection must stay selected when coins are low")
        data.Currencies.Coins = 100000000
        local egg, config = utils.pickEgg(data)
        assert(egg and not config.Island and (config.Zone == nil or config.Zone == "Spawn"), "Locked island or zone egg selected")
        table.insert(results, "Egg selection preserves the chosen egg and respects island and zone gates")

        local lastPrice = -math.huge
        for _, row in ipairs(utils.sortedEggs()) do
            assert(row.Price >= lastPrice and row.Name ~= "Test", "Egg prices are not sorted")
            lastPrice = row.Price
        end
        local lastOrder = -math.huge
        for _, row in ipairs(utils.sortedIslands()) do
            assert(row.Config.Order >= lastOrder, "Island progression is not sorted")
            lastOrder = row.Config.Order
        end
        assert(utils.eggMap["Basic - " .. utils.formatNumber(utils.modules.eggs.Basic.Price)] == "Basic", "Priced egg labels do not resolve to their remote name")
        table.insert(results, "Egg dropdown prices map back to egg IDs and areas follow progression order")

        table.clear(calls)
        local moved = false
        utils.islandPortal = function(name) assert(name == "Sky Island"); return {CFrame = CFrame.new(10, 20, 30)} end
        utils.trip = function(key, destination, callback)
            assert(key == "Islands" and typeof(destination) == "CFrame", "Unlock did not travel to a portal")
            moved = true
            return callback()
        end
        local recorder = utils.remote
        utils.remote = function(group, name, packet)
            if group == "Island" and name == "IslandUnlockRequested" then
                assert(moved, "Unlock request was sent before portal travel")
                data.Progression.UnlockedIslands[packet.Island] = true
            end
            return recorder(group, name, packet)
        end
        assert(utils.islands() == "Unlocked Sky Island", "Unlock did not confirm replicated progression")
        assert(#calls == 1 and calls[1].Packet.Action == "Purchase", "Unexpected unlock request")
        utils.trip, utils.islandPortal, utils.remote = original.Trip, original.Portal, recorder
        table.insert(results, "Area unlocking travels to the portal before sending the purchase request")

        utils.memory = {Known = {"Doggy", "Kitty", "Doggy", "Kitty"}}
        local state = {Cards = {{Matched = false}, {Matched = false}, {Matched = false}, {Matched = false}}}
        assert(utils.memoryChoice(state, 1) == 3, "Remembered pair was not selected")
        state.Cards[3].Matched = true
        assert(utils.memoryChoice(state, 1) ~= 3, "Matched card was selected twice")
        table.insert(results, "Memory solver reuses revealed pairs and skips matched cards")

        table.clear(calls)
        utils.settings.boosts = {Types = {Luck = true}}
        data.Boosts["Luck Potion I"] = 1
        assert(utils.potions() == "Used Luck Potion I", "Potion stock must come from Boosts")
        assert(#calls == 1 and calls[1].Group == "Boost" and calls[1].Packet == "Luck Potion I", "Incorrect potion request")
        table.insert(results, "Potion consumption uses the game's actual inventory field")

        table.clear(calls)
        utils.originals = {}
        utils.setting("HideClicks", true)
        assert(#calls == 1 and calls[1].Packet.Name == "HideClicks" and calls[1].Packet.Value == true, "Settings must use a Name/Value request table")
        assert(utils.originals.HideClicks.Value == false, "Original setting was not recorded for cleanup")
        table.insert(results, "Visual setting requests use the verified schema and preserve the original value")

        if window.ConfigManager then
            local profile = window.ConfigManager:CreateConfig("_silence_reborn_test")
            profile:Save()
            local value, reason = profile:Load()
            assert(value ~= false, tostring(reason))
            task.wait(0.5)
            assert(profile:Delete(), "Temporary profile could not be deleted")
            table.insert(results, "WindUI configuration saves, loads and deletes a temporary profile")
        end
    end, debug.traceback)
    utils.jobs.Cleanup.Enabled = false
    utils.save, utils.remote = original.Save, original.Remote
    utils.settings.pets, utils.settings.farm, utils.settings.boosts = original.Pets, original.Farm, original.Boosts
    utils.memory = original.Memory
    utils.originals = original.Originals
    utils.trip, utils.islandPortal = original.Trip, original.Portal
    utils.identityReset()
    if not success then error(failure, 0) end
    return results
end
