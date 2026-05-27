local services = {
    players = game:GetService("Players"),
    replicatedStorage = game:GetService("ReplicatedStorage"),
    workspace = game:GetService("Workspace"),
    runService = game:GetService("RunService"),
    virtualUser = game:GetService("VirtualUser"),
    userInputService = game:GetService("UserInputService"),
    tweenService = game:GetService("TweenService"),
    lighting = game:GetService("Lighting"),
    soundService = game:GetService("SoundService")
}

local player = {
    player = services.players.LocalPlayer,
    name = services.players.LocalPlayer.Name,
    displayName = services.players.LocalPlayer.DisplayName,
    network = require(services.replicatedStorage.Modules.Network),
    rebirths = require(services.replicatedStorage.Game.Rebirths),
    replication = require(services.replicatedStorage.Game.Replication),
}

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local silence = WindUI:CreateWindow({
    Title = "Silence - Tap Simulator",
    Author = "by Henne @imhenne",
    Icon = "solar:moon-bold",
    IconSize = 13*2,
    Theme = "Crimson",
    NewElements = true,
    Size = UDim2.fromOffset(450, 450),

    OpenButton = {
        Title = "Reopen Silence",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 3,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 0.5,
        
        Color = ColorSequence.new(
            Color3.fromHex("#880000"),
            Color3.fromHex("000000")
        )},
    Topbar = {
        Height = 44,
        ButtonsType = "Default",
    },
})

silence:Tag({
    Title = "Silence [V.3]",
    Icon = "github",
    Color = Color3.fromHex("#1c1c1c"),
    Border = true,
})

local tabColors = {
    config = Color3.fromRGB(138, 0, 0),
    main = Color3.fromRGB(138, 0, 0),
    hatching = Color3.fromRGB(138, 0, 0),
    crafting = Color3.fromRGB(138, 0, 0),
    teleport = Color3.fromRGB(138, 0, 0),
    enchanting = Color3.fromRGB(138, 0, 0),
    misc = Color3.fromRGB(138, 0, 0),
    webhook = Color3.fromRGB(138, 0, 0),
    stats = Color3.fromRGB(138, 0, 0),
    info = Color3.fromRGB(138, 0, 0),
}

local tabs = {
    config = silence:Tab({
        Title = "Configuration",
        Desc = "Create and Autoload Configurations",
        Icon = "lucide:settings",
        IconColor = tabColors.config,
        IconShape = "Square",
        Border = true,
    }),
    main = silence:Tab({
        Title = "Main",
        Desc = "Main features of the script",
        Icon = "lucide:house",
        IconColor = tabColors.main,
        IconShape = "Square",
        Border = true,
    }),
    hatching = silence:Tab({
        Title = "Auto Hatching",
        Desc = "Hatch Eggs and delete Pets Automatically",
        Icon = "lucide:egg",
        IconColor = tabColors.hatching,
        IconShape = "Square",
        Border = true,
    }),
    crafting = silence:Tab({
        Title = "Pet Crafting",
        Desc = "Automatically Craft Gold, Rainbow and Mutated Pets",
        Icon = "lucide:paw-print",
        IconColor = tabColors.crafting,
        IconShape = "Square",
        Border = true,
    }),
    teleport = silence:Tab({
        Title = "Teleports",
        Desc = "Teleport anywhere and automatically teleport on Join",
        Icon = "lucide:map",
        IconColor = tabColors.teleport,
        IconShape = "Square",
        Border = true,
    }),
    enchanting = silence:Tab({
        Title = "Auto Enchanting",
        Desc = "Automatically Enchant any Pet",
        Icon = "lucide:sparkles",
        IconColor = tabColors.enchanting,
        IconShape = "Square",
        Border = true,
    }),
    misc = silence:Tab({
        Title = "Misc",
        Desc = "Miscellaneous features",
        Icon = "lucide:layers",
        IconColor = tabColors.misc,
        IconShape = "Square",
        Border = true,
    }),
    webhook = silence:Tab({
        Title = "Webhook",
        Desc = "Log your Pet Hatches to Discord",
        Icon = "lucide:link",
        IconColor = tabColors.webhook,
        IconShape = "Square",
        Border = true,
    }),
    info = silence:Tab({
        Title = "About Silence",
        Desc = "Information about me and Silence",
        Icon = "lucide:info",
        IconColor = tabColors.info,
        IconShape = "Square",
        Border = true,
    })
}

tabs.main:Select()

function formatSuffix(val)
    tabs.main.suffixes = {"", "K", "M", "B", "T", "QD", "QN", "SX", "SP", "O", "N", "D", "UD", "DD"}
    tabs.main.i = 1
    while val >= 1000 and tabs.main.i < #tabs.main.suffixes do
        val = val / 1000
        tabs.main.i = tabs.main.i + 1
    end
    return tabs.main.i == 1 and tostring(val)
        or string.format("%.2f%s", val, tabs.main.suffixes[tabs.main.i]):gsub("%.00", "")
end

--[[
    REBIRTH STUFF - boa ne ey windui dropdowns
]]


tabs.main.rebValues = {}
tabs.main.rebMap = {}
tabs.main.selectedRebirth = nil

function getRebShit()
    table.clear(tabs.main.rebValues)
    table.clear(tabs.main.rebMap)
    tabs.main.success, tabs.main.err = pcall(function()
        tabs.main.Rebirths = require(services.replicatedStorage.Game.Rebirths)
        repeat task.wait() until player.replication.Loaded and player.replication.Data
        tabs.main.rebButtons = player.replication.Data.RebirthOptions or 0
        tabs.main.currentReb = player.replication.Data.Statistics.Rebirths or 0
        tabs.main.currentClicks = player.replication.Data.Statistics.Clicks or 0
        for index = tabs.main.rebButtons, 1, -1 do
            tabs.main.amount = tabs.main.Rebirths:fromIndex(index)
            if tabs.main.amount then
                tabs.main.price = tabs.main.Rebirths:getPrice(tabs.main.amount)
                tabs.main.clicksNeeded = tabs.main.Rebirths:ClicksPrice(tabs.main.price, tabs.main.currentReb)
                tabs.main.text = string.format("%d. +%s (%s)",
                    index,
                    formatSuffix(tabs.main.amount),
                    formatSuffix(tabs.main.clicksNeeded)
                )
                table.insert(tabs.main.rebValues, tabs.main.text)
                tabs.main.rebMap[tabs.main.text] = {
                    index = index,
                    amount = tabs.main.amount,
                    price = tabs.main.price
                }
            end
        end
    end)
end
getRebShit()


--[[
    POTIONS halt unnotig aber die müssen global sein
]]

tabs.main.selectedPotionValues = {}
tabs.main.buyingPotions = nil

--[[
    HATCHING STUFF :P
]]

tabs.hatching.selectedEgg = nil
tabs.hatching.selectedHatchAmount = 1
tabs.hatching.autoHatch = false
tabs.hatching.autoHatching = nil
tabs.hatching.maxDistance = 25

function getEggs()
    tabs.main.char = player.player.Character
    if tabs.main.char and tabs.main.char:FindFirstChild("HumanoidRootPart") then
        tabs.main.char.HumanoidRootPart.CFrame = CFrame.new(-145.5439, 213.212769, 236.957123, -0.311900645, 9.30314492e-09, 0.950114727, 2.13227711e-08, 1, -2.79183032e-09, -0.950114727, 1.93883061e-08, -0.311900645)
        task.wait(2)
    end

    tabs.hatching.eggsFolder = services.workspace:WaitForChild("Eggs", 30)
    repeat task.wait(1) until #tabs.hatching.eggsFolder:GetChildren() >= 27

    tabs.hatching.eggs = require(services.replicatedStorage.Game.Eggs)
    tabs.hatching.eggList = {}
    tabs.hatching.sortedEggs = {}

    for eggName, eggData in pairs(tabs.hatching.eggs) do
        if type(eggData) == "table"
        and not eggData.Currency
        and eggData.Price
        and eggData.Price > 0
        and tabs.hatching.eggsFolder:FindFirstChild(eggName) then
            table.insert(tabs.hatching.sortedEggs, {
                name = eggName,
                price = eggData.Price
            })
        end
    end

    table.sort(tabs.hatching.sortedEggs, function(a, b)
        return a.price < b.price
    end)

    for _, egg in ipairs(tabs.hatching.sortedEggs) do
        tabs.hatching.priceStr = formatSuffix(egg.price)
        table.insert(tabs.hatching.eggList, string.format("%s - %s", egg.name, tabs.hatching.priceStr))
    end
    return tabs.hatching.eggList, tabs.hatching.sortedEggs
end

function getEggPosition(eggName)
    tabs.hatching.eggsFolder = services.workspace:FindFirstChild("Eggs")
    if not tabs.hatching.eggsFolder then return nil end

    tabs.hatching.eggModel = tabs.hatching.eggsFolder:FindFirstChild(eggName)
    if not tabs.hatching.eggModel then return nil end
    tabs.hatching.eggPrimary = tabs.hatching.eggModel.PrimaryPart
        or tabs.hatching.eggModel:FindFirstChildWhichIsA("BasePart")

    if tabs.hatching.eggPrimary then
        return tabs.hatching.eggPrimary.Position
    end

    return nil
end

function tpToEgg(eggName)
    tabs.hatching.eggPos = getEggPosition(eggName)
    if tabs.hatching.eggPos and player.player.Character and player.player.Character:FindFirstChild("HumanoidRootPart") then
        player.player.Character.HumanoidRootPart.CFrame = CFrame.new(
            tabs.hatching.eggPos + Vector3.new(0, 0, 10)
        )
        return true
    end
    return false
end

function checkDistanceToEgg(eggName)
    tabs.hatching.eggPos = getEggPosition(eggName)
    if not tabs.hatching.eggPos then return false end
    
    if player.player.Character and player.player.Character:FindFirstChild("HumanoidRootPart") then
        tabs.hatching.playerPos = player.player.Character.HumanoidRootPart.Position
        tabs.hatching.distance = (tabs.hatching.playerPos - tabs.hatching.eggPos).Magnitude
        
        if tabs.hatching.distance > tabs.hatching.maxDistance then
            return false
        end
        return true
    end
    return false
end


tabs.hatching.eggDropdownValues, tabs.hatching.sortedEggsData = getEggs()

if tabs.hatching.sortedEggsData and tabs.hatching.sortedEggsData[1] then
    tabs.hatching.selectedEgg = tabs.hatching.sortedEggsData[1].name
end

--[[
    Auto Crafting bullshit (holy work 😭)
]]

tabs.crafting.craftingstate = {
    isActive = false,
    savedPosition = nil,
    currentZone = nil,
    lastRefresh = 0,
    processing = false
}

tabs.crafting.normalPets = {}
tabs.crafting.selectedGoldenPets = {}
tabs.crafting.selectedGoldenChance = "100% (6 pets)"
tabs.crafting.autoGoldenEnabled = false

tabs.crafting.goldenPets = {}
tabs.crafting.selectedRainbowPets = {}
tabs.crafting.selectedRainbowTime = "8h - 1 Pet"
tabs.crafting.autoRainbowEnabled = false

function getPetIdsForGoldenCraft(petName, amount)
    tabs.crafting.ids = {}
    repeat task.wait() until player.replication.Loaded and player.replication.Data
    
    for petId, petData in pairs(player.replication.Data.Pets) do
        if petData.Name == petName 
            and petData.Tier == "Normal" 
            and not petData.Locked 
            and #tabs.crafting.ids < amount then
            table.insert(tabs.crafting.ids, petId)
        end
    end
    return tabs.crafting.ids
end

function getGoldenPetIdsForRainbowCraft(petName, amount)
    tabs.crafting.ids = {}
    repeat task.wait() until player.replication.Loaded and player.replication.Data
    
    for petId, petData in pairs(player.replication.Data.Pets) do
        if petData.Name == petName 
            and petData.Tier == "Golden" 
            and not petData.Locked 
            and #tabs.crafting.ids < amount then
            table.insert(tabs.crafting.ids, petId)
        end
    end
    return tabs.crafting.ids
end

function getNormalPetNames()
    repeat task.wait() until player.replication.Loaded and player.replication.Data
    
    tabs.crafting.petNames = {}
    tabs.crafting.nameSet = {}
    
    for petId, petData in pairs(player.replication.Data.Pets) do
        if petData.Tier == "Normal" and not tabs.crafting.nameSet[petData.Name] then
            table.insert(tabs.crafting.petNames, petData.Name)
            tabs.crafting.nameSet[petData.Name] = true
        end
    end
    
    table.sort(tabs.crafting.petNames)
    return tabs.crafting.petNames
end

function getGoldenPetNames()
    repeat task.wait() until player.replication.Loaded and player.replication.Data
    
    tabs.crafting.petNames = {}
    tabs.crafting.nameSet = {}
    
    for petId, petData in pairs(player.replication.Data.Pets) do
        if petData.Tier == "Golden" and not tabs.crafting.nameSet[petData.Name] then
            table.insert(tabs.crafting.petNames, petData.Name)
            tabs.crafting.nameSet[petData.Name] = true
        end
    end
    
    table.sort(tabs.crafting.petNames)
    return tabs.crafting.petNames
end

function getCurrentlyRainbowCrafting()
    tabs.crafting.crafting = {}
    repeat task.wait() until player.replication.Loaded and player.replication.Data
    
    if player.replication.Data.CraftingPets and player.replication.Data.CraftingPets.Rainbow then
        for petId, craftData in pairs(player.replication.Data.CraftingPets.Rainbow) do
            tabs.crafting.timeLeft = math.max(0, craftData.EndTime - os.time())
            table.insert(tabs.crafting.crafting, {
                id = petId,
                name = craftData.Name or "Unknown",
                timeLeft = tabs.crafting.timeLeft,
                claimable = tabs.crafting.timeLeft <= 0
            })
        end
    end
    
    return tabs.crafting.crafting
end




function teleportToGoldenMachine()
    tabs.crafting.character = player.player.Character
    if not tabs.crafting.character or not tabs.crafting.character:FindFirstChild("HumanoidRootPart") then return false end
    pcall(function()
        tabs.crafting.character:PivotTo(CFrame.new(1417.860718, 657.786133, -13457.016602))
    end)
    task.wait(0.5)
    return true
end

function teleportToRainbowMachine()
    tabs.crafting.character = player.player.Character
    if not tabs.crafting.character or not tabs.crafting.character:FindFirstChild("HumanoidRootPart") then return false end
    pcall(function()
        tabs.crafting.character:PivotTo(CFrame.new(1211.502075, 664.584900, -13382.567383))
    end)
    task.wait(0.5)
    return true
end

function processGoldenCraft(petName, petsNeeded)
    tabs.crafting.petIds = getPetIdsForGoldenCraft(petName, petsNeeded)
    
    if #tabs.crafting.petIds < petsNeeded then
        return false
    end
    
    tabs.crafting.success = pcall(function()
        player.network:InvokeServer("CraftPets", tabs.crafting.petIds)
    end)
    
    return tabs.crafting.success
end

function processRainbowCraft(petName, petsNeeded)
    tabs.crafting.currentCrafting = getCurrentlyRainbowCrafting()
    tabs.crafting.usedSlots = #tabs.crafting.currentCrafting
    tabs.crafting.availableSlots = 3 - tabs.crafting.usedSlots
    
    for _, craft in ipairs(tabs.crafting.currentCrafting) do
        if craft.claimable then
            pcall(function()
                player.network:InvokeServer("ClaimRainbow", craft.id)
            end)
            task.wait(0.1)
        end
    end
    
    tabs.crafting.currentCrafting = getCurrentlyRainbowCrafting()
    tabs.crafting.availableSlots = 3 - #tabs.crafting.currentCrafting
    
    if tabs.crafting.availableSlots <= 0 then return false end
    
    tabs.crafting.petIds = getGoldenPetIdsForRainbowCraft(petName, petsNeeded)
    if #tabs.crafting.petIds < petsNeeded then return false end
    
    tabs.crafting.success = pcall(function()
        player.network:InvokeServer("StartRainbow", tabs.crafting.petIds)
    end)
    
    if tabs.crafting.success then task.wait(0.1) end
    return tabs.crafting.success
end


function buildCraftQueue()
    tabs.crafting.goldenQueue = {}
    tabs.crafting.rainbowQueue = {}

    if tabs.crafting.autoGoldenEnabled and tabs.crafting.selectedGoldenPets then
        tabs.crafting.petsNeeded = 6
        
        if tabs.crafting.selectedGoldenChance then
            if tabs.crafting.selectedGoldenChance:match("5%%") then
                tabs.crafting.petsNeeded = 1
            elseif tabs.crafting.selectedGoldenChance:match("15%%") then
                tabs.crafting.petsNeeded = 2
            elseif tabs.crafting.selectedGoldenChance:match("35%%") then
                tabs.crafting.petsNeeded = 3
            elseif tabs.crafting.selectedGoldenChance:match("60%%") then
                tabs.crafting.petsNeeded = 4
            elseif tabs.crafting.selectedGoldenChance:match("80%%") then
                tabs.crafting.petsNeeded = 5
            elseif tabs.crafting.selectedGoldenChance:match("100%%") then
                tabs.crafting.petsNeeded = 6
            end
        end
        
        for petName, isSelected in pairs(tabs.crafting.selectedGoldenPets) do
            if isSelected then
                table.insert(tabs.crafting.goldenQueue, {
                    type = "golden",
                    petName = petName,
                    petsNeeded = tabs.crafting.petsNeeded
                })
            end
        end
    end
    

    if tabs.crafting.autoRainbowEnabled and tabs.crafting.selectedRainbowPets then
        tabs.crafting.petsNeeded = 1
        
        if tabs.crafting.selectedRainbowTime then
            if tabs.crafting.selectedRainbowTime:match("1 Pet") then
                tabs.crafting.petsNeeded = 1
            elseif tabs.crafting.selectedRainbowTime:match("2 Pets") then
                tabs.crafting.petsNeeded = 2
            elseif tabs.crafting.selectedRainbowTime:match("3 Pets") then
                tabs.crafting.petsNeeded = 3
            elseif tabs.crafting.selectedRainbowTime:match("4 Pets") then
                tabs.crafting.petsNeeded = 4
            elseif tabs.crafting.selectedRainbowTime:match("5 Pets") then
                tabs.crafting.petsNeeded = 5
            end
        end
        
        for petName, isSelected in pairs(tabs.crafting.selectedRainbowPets) do
            if isSelected then
                table.insert(tabs.crafting.rainbowQueue, {
                    type = "rainbow",
                    petName = petName,
                    petsNeeded = tabs.crafting.petsNeeded
                })
            end
        end
    end
    
    return tabs.crafting.goldenQueue, tabs.crafting.rainbowQueue
end


function processCraftQueue()
    if tabs.crafting.craftingstate.processing then
        return false
    end
    
    tabs.crafting.craftingstate.processing = true
    tabs.crafting.goldenQueue, tabs.crafting.rainbowQueue = buildCraftQueue()
    tabs.crafting.craftedAny = false
    

    if tabs.crafting.autoGoldenEnabled and #tabs.crafting.goldenQueue > 0 then
        teleportToGoldenMachine()
        
        for _, craftJob in ipairs(tabs.crafting.goldenQueue) do
            if not tabs.crafting.autoGoldenEnabled then break end
            

            while tabs.crafting.autoGoldenEnabled do
                tabs.crafting.success = processGoldenCraft(craftJob.petName, craftJob.petsNeeded)
                if not tabs.crafting.success then break end
                tabs.crafting.craftedAny = true
                task.wait(0.05)
            end
        end
        

        if tabs.crafting.craftedAny then
            refreshCraftingDropdowns()
        end
    end
    

    if tabs.crafting.autoRainbowEnabled and #tabs.crafting.rainbowQueue > 0 then
        teleportToRainbowMachine()
        
        for _, craftJob in ipairs(tabs.crafting.rainbowQueue) do
            if not tabs.crafting.autoRainbowEnabled then break end
            
            tabs.crafting.success = processRainbowCraft(craftJob.petName, craftJob.petsNeeded)
            if tabs.crafting.success then
                tabs.crafting.craftedAny = true
                task.wait(0.05)
            end
        end
        
        if tabs.crafting.craftedAny then
            refreshCraftingDropdowns()
        end
    end
    
    tabs.crafting.craftingstate.processing = false
    return tabs.crafting.craftedAny
end


function refreshCraftingDropdowns()
    tabs.crafting.currentTime = os.clock()
    
    if tabs.crafting.currentTime - tabs.crafting.craftingstate.lastRefresh < 5 then
        return
    end
    
    tabs.crafting.craftingstate.lastRefresh = tabs.crafting.currentTime
    
    task.spawn(function()
        if tabs.crafting.goldenPetsDropdown then
            pcall(function()
                tabs.crafting.goldenPetsDropdown:Refresh(getNormalPetNames())
            end)
        end
        
        if tabs.crafting.rainbowPetsDropdown then
            pcall(function()
                tabs.crafting.rainbowPetsDropdown:Refresh(getGoldenPetNames())
            end)
        end
    end)
end

function startCraftingLoop()
    if tabs.crafting.craftingstate.isActive then
        return
    end
    
    tabs.crafting.craftingstate.isActive = true
    
    tabs.crafting.character = player.player.Character
    if tabs.crafting.character and tabs.crafting.character:FindFirstChild("HumanoidRootPart") then
        tabs.crafting.craftingstate.savedPosition = tabs.crafting.character:GetPivot()
    end
    
    task.spawn(function()
        while tabs.crafting.craftingstate.isActive and (tabs.crafting.autoGoldenEnabled or tabs.crafting.autoRainbowEnabled) do
            tabs.crafting.craftedAny = processCraftQueue()
            
            if tabs.crafting.craftedAny then
                task.wait(0.25)
            else
                task.wait(5)
            end
        end
        

        if tabs.crafting.craftingstate.savedPosition then
            tabs.crafting.character = player.player.Character
            if tabs.crafting.character and tabs.crafting.character:FindFirstChild("HumanoidRootPart") then
                pcall(function()
                    tabs.crafting.character:PivotTo(tabs.crafting.craftingstate.savedPosition)
                end)
            end
            tabs.crafting.craftingstate.savedPosition = nil
        end
        
        tabs.crafting.craftingstate.isActive = false
    end)
end

function stopCraftingLoop()
    tabs.crafting.craftingstate.isActive = false
end

tabs.crafting.normalPets = {}
tabs.crafting.goldenPets = {}

function refreshNormalPets()
    table.clear(tabs.crafting.normalPets)
    repeat task.wait() until player.replication.Loaded and player.replication.Data
    tabs.crafting.nameSet = {}
    for _, petData in pairs(player.replication.Data.Pets) do
        if petData.Tier == "Normal" and not tabs.crafting.nameSet[petData.Name] then
            table.insert(tabs.crafting.normalPets, petData.Name)
            tabs.crafting.nameSet[petData.Name] = true
        end
    end
    table.sort(tabs.crafting.normalPets)
end

function refreshGoldenPets()
    table.clear(tabs.crafting.goldenPets)
    repeat task.wait() until player.replication.Loaded and player.replication.Data
    tabs.crafting.nameSet = {}
    for _, petData in pairs(player.replication.Data.Pets) do
        if petData.Tier == "Golden" and not tabs.crafting.nameSet[petData.Name] then
            table.insert(tabs.crafting.goldenPets, petData.Name)
            tabs.crafting.nameSet[petData.Name] = true
        end
    end
    table.sort(tabs.crafting.goldenPets)
end

refreshNormalPets()
refreshGoldenPets()

function updateGoldenStatus()
    if not tabs.crafting.goldenStatusLabel then return end
    
    tabs.crafting.statusText = "Selected Pets:\n"
    tabs.crafting.hasSelected = false
    
    for petName, isSelected in pairs(tabs.crafting.selectedGoldenPets) do
        if isSelected then
            tabs.crafting.hasSelected = true
            tabs.crafting.count = 0
            for _, petData in pairs(player.replication.Data.Pets) do
                if petData.Name == petName and petData.Tier == "Normal" and not petData.Locked then
                    tabs.crafting.count = tabs.crafting.count + 1
                end
            end
            tabs.crafting.statusText = tabs.crafting.statusText .. string.format("%s: %d owned\n", petName, tabs.crafting.count)
        end
    end
    
    if not tabs.crafting.hasSelected then
        tabs.crafting.statusText = "No pets selected"
    end
    
    tabs.crafting.goldenStatusLabel:SetDesc(tabs.crafting.statusText)
end

function updateRainbowStatus()
    if not tabs.crafting.rainbowStatusLabel then return end
    
    tabs.crafting.statusText = "Selected Pets:\n"
    tabs.crafting.hasSelected = false
    
    for petName, isSelected in pairs(tabs.crafting.selectedRainbowPets) do
        if isSelected then
            tabs.crafting.hasSelected = true
            tabs.crafting.count = 0
            for _, petData in pairs(player.replication.Data.Pets) do
                if petData.Name == petName and petData.Tier == "Golden" and not petData.Locked then
                    tabs.crafting.count = tabs.crafting.count + 1
                end
            end
            tabs.crafting.statusText = tabs.crafting.statusText .. string.format("%s: %d owned\n", petName, tabs.crafting.count)
        end
    end
    
    if not tabs.crafting.hasSelected then
        tabs.crafting.statusText = "No pets selected\n"
    end

    tabs.crafting.currentCrafting = getCurrentlyRainbowCrafting()
    
    if #tabs.crafting.currentCrafting > 0 then
        tabs.crafting.statusText = tabs.crafting.statusText .. "\nCurrently Crafting:\n"
        

        tabs.crafting.uniqueCrafts = {}
        for _, craft in ipairs(tabs.crafting.currentCrafting) do
            tabs.crafting.uniqueCrafts[craft.id] = craft
        end
        
        for craftId, craft in pairs(tabs.crafting.uniqueCrafts) do
            tabs.crafting.hours = math.floor(craft.timeLeft / 3600)
            tabs.crafting.mins = math.floor((craft.timeLeft % 3600) / 60)
            tabs.crafting.secs = craft.timeLeft % 60
            
            if tabs.crafting.hours > 0 then
                tabs.crafting.timeStr = string.format("%dh %dm %ds", tabs.crafting.hours, tabs.crafting.mins, tabs.crafting.secs)
            elseif tabs.crafting.mins > 0 then
                tabs.crafting.timeStr = string.format("%dm %ds", tabs.crafting.mins, tabs.crafting.secs)
            else
                tabs.crafting.timeStr = string.format("%ds", tabs.crafting.secs)
            end
            
            tabs.crafting.statusText = tabs.crafting.statusText .. string.format("%s: %s\n", craft.name, tabs.crafting.timeStr)
        end
    end
    
    tabs.crafting.rainbowStatusLabel:SetDesc(tabs.crafting.statusText)
end

tabs.crafting:Space({Colums = 2})
tabs.crafting:Section({
    Title = "Gold Pets",
    TextSize = 22,
    TextXAlignment = "Center",
    Box = false,
})
tabs.crafting:Dropdown({
    Title = "Select Chance",
    Values = {"5% (1 pet)", "15% (2 pets)", "35% (3 pets)", "60% (4 pets)", "80% (5 pets)", "100% (6 pets)"},
    Value = "100% (6 pets)",
    Multi = false,
    Callback = function(value)
        tabs.crafting.selectedGoldenChance = value
    end
})
tabs.crafting.goldenPetsDropdown = tabs.crafting:Dropdown({
    Title = "Select Pets",
    Values = tabs.crafting.normalPets,
    Value = {},
    Multi = true,
    SearchBarEnabled = true,
    Callback = function(value)
        tabs.crafting.selectedGoldenPets = {}
        if type(value) == "table" then
            for _, petName in pairs(value) do
                if type(petName) == "string" then
                    tabs.crafting.selectedGoldenPets[petName] = true
                end
            end
        end
        updateGoldenStatus()
    end
})

tabs.crafting.goldenStatusLabel = tabs.crafting:Paragraph({
    Title = "Pet Status",
    Desc = "No pets selected",
})
tabs.crafting:Toggle({
    Title = "Auto Craft Golden",
    Value = false,
    Icon = "lucide:sparkles",
    Callback = function(value)
        tabs.crafting.autoGoldenEnabled = value
        if value then
            startCraftingLoop()
        elseif not tabs.crafting.autoRainbowEnabled then
            stopCraftingLoop()
        end
    end
})

tabs.crafting:Space({Colums = 2})
tabs.crafting:Section({
    Title = "Rainbow Pets",
    TextSize = 22,
    TextXAlignment = "Center",
    Box = false,
})
tabs.crafting:Dropdown({
    Title = "Select Time",
    Values = {"8h - 1 Pet", "5h - 2 Pets", "2.5h - 3 Pets", "1h - 4 Pets", "30s - 5 Pets"},
    Value = "8h - 1 Pet",
    Multi = false,
    Callback = function(value)
        tabs.crafting.selectedRainbowTime = value
    end
})
tabs.crafting.rainbowPetsDropdown = tabs.crafting:Dropdown({
    Title = "Select Pets",
    Values = tabs.crafting.goldenPets,
    Value = {},
    Multi = true,
    SearchBarEnabled = true,
    Callback = function(value)
        tabs.crafting.selectedRainbowPets = {}
        if type(value) == "table" then
            for _, petName in pairs(value) do
                if type(petName) == "string" then
                    tabs.crafting.selectedRainbowPets[petName] = true
                end
            end
        end
        updateRainbowStatus()
    end
})
tabs.crafting.rainbowStatusLabel = tabs.crafting:Paragraph({
    Title = "Pet Status",
    Desc = "No pets selected",
})


tabs.crafting:Toggle({
    Title = "Auto Craft Rainbow",
    Value = false,
    Icon = "lucide:rainbow",
    Callback = function(value)
        tabs.crafting.autoRainbowEnabled = value
        if value then
            startCraftingLoop()
        elseif not tabs.crafting.autoGoldenEnabled then
            stopCraftingLoop()
        end
    end
})

task.spawn(function()
    while true do
        task.wait(10)
        refreshNormalPets()
        refreshGoldenPets()
        pcall(function() tabs.crafting.goldenPetsDropdown:Refresh(tabs.crafting.normalPets) end)
        pcall(function() tabs.crafting.rainbowPetsDropdown:Refresh(tabs.crafting.goldenPets) end)
    end
end)

task.spawn(function()
    while true do
        task.wait(2)
        if player.replication.Loaded and player.replication.Data then
            pcall(updateGoldenStatus)
            pcall(updateRainbowStatus)
        end
    end
end)


--[[
    Teleporting stuff
]]

function getMainZones()
    tabs.teleport.Portals = require(services.replicatedStorage.Game.Portals)
    tabs.teleport.mainZones = {}
    tabs.teleport.spaceZoneNames = {Kryo = true, Magma = true, Celestial = true, Holographic = true, Lunar = true, Cyberpunk = true, Rainbow = true}

    for portalName, portalData in pairs(tabs.teleport.Portals) do
        if type(portalData) == "table" and portalData.Price and not tabs.teleport.spaceZoneNames[portalName] then
            table.insert(tabs.teleport.mainZones, {
                name = portalName,
                price = portalData.Price
            })
        end
    end

    table.sort(tabs.teleport.mainZones, function(a, b) return a.price < b.price end)
    return tabs.teleport.mainZones
end

tabs.teleport.mainZones = getMainZones()
tabs.teleport.spaceZones = {
    {name = "Kryo"},
    {name = "Magma"},
    {name = "Celestial"},
    {name = "Holographic"},
    {name = "Lunar"},
    {name = "Cyberpunk"},
    {name = "Rainbow"},
}

tabs.teleport.worldTeleports = {
    ["Spawn (Main World)"] = "Main",
    ["Space World"] = "Space",
}

tabs.teleport:Section({
    Title = "Main World",
    TextSize = 22,
    Box = false,
    TextXAlignment = "Center",
})

tabs.teleport:Button({
    Title = "Teleport to Spawn",
    Callback = function()
        pcall(function()
            player.network:InvokeServer("TeleportWorld", "Main")
        end)
    end
})

for _, zone in ipairs(tabs.teleport.mainZones) do
    tabs.teleport:Button({
        Title = "Teleport to " .. zone.name,
        Callback = function()
            pcall(function()
                player.network:InvokeServer("TeleportZone", zone.name)
            end)
        end
    })
end


tabs.teleport:Section({
    Title = "Space World",
    TextSize = 22,
    Box = false,
    TextXAlignment = "Center",
})

tabs.teleport:Button({
    Title = "Teleport to Space World",
    Callback = function()
        pcall(function()
            player.network:InvokeServer("TeleportWorld", "Space")
        end)
    end
})

for _, zone in ipairs(tabs.teleport.spaceZones) do
    tabs.teleport:Button({
        Title = "Teleport to " .. zone.name,
        Callback = function()
            pcall(function()
                player.network:InvokeServer("TeleportZone", zone.name)
            end)
        end
    })
end


tabs.teleport.selectedZone = "Spawn (Main World)"
tabs.teleport.teleportOnJoinEnabled = false

function getTeleportDropdownValues()
    tabs.teleport.dropdownValues = {"Spawn (Main World)"}

    for _, zone in ipairs(tabs.teleport.mainZones) do
        table.insert(tabs.teleport.dropdownValues, zone.name)
    end

    table.insert(tabs.teleport.dropdownValues, "Space World")

    for _, zone in ipairs(tabs.teleport.spaceZones) do
        table.insert(tabs.teleport.dropdownValues, zone.name)
    end

    return tabs.teleport.dropdownValues
end

--[[
    ENCHANTING STUFF
]]

tabs.enchanting.selectedEnchants = {}
tabs.enchanting.selectedPets = {}
tabs.enchanting.petDropdownMap = {}
tabs.enchanting.liveEnchantData = {}
tabs.enchanting.autoEnchantEnabled = false
tabs.enchanting.autoEnchanting = nil
tabs.enchanting.petDropdown = nil
tabs.enchanting.statusLabel = nil

task.spawn(function()
    repeat task.wait() until player.replication.Loaded and player.replication.Data and player.replication.Data.Pets
    for petId, petData in pairs(player.replication.Data.Pets) do
        tabs.enchanting.liveEnchantData[petId] = petData.Enchant or ""
    end
end)

function getEnchantNames()
    tabs.enchanting.EnchantData = require(services.replicatedStorage.Game.EnchantData)
    tabs.enchanting.enchantList = {}
    if tabs.enchanting.EnchantData and tabs.enchanting.EnchantData.Enchants then
        for enchantName, _ in pairs(tabs.enchanting.EnchantData.Enchants) do
            table.insert(tabs.enchanting.enchantList, enchantName)
        end
    end
    tabs.enchanting.nameOrder = { Taps=1, Gems=2, Rebirths=3, Luck=4 }
    tabs.enchanting.tierOrder = { I=1, II=2, III=3 }
    table.sort(tabs.enchanting.enchantList, function(a, b)
        tabs.enchanting.nA, tabs.enchanting.tA = a:match("^(.-) (I+)$")
        tabs.enchanting.nB, tabs.enchanting.tB = b:match("^(.-) (I+)$")
        if tabs.enchanting.nA and not tabs.enchanting.nB then return true end
        if not tabs.enchanting.nA and tabs.enchanting.nB then return false end
        if tabs.enchanting.nA and tabs.enchanting.nB then
            tabs.enchanting.oA = tabs.enchanting.nameOrder[tabs.enchanting.nA] or 99
            tabs.enchanting.oB = tabs.enchanting.nameOrder[tabs.enchanting.nB] or 99
            if tabs.enchanting.oA ~= tabs.enchanting.oB then return tabs.enchanting.oA < tabs.enchanting.oB end
            return (tabs.enchanting.tierOrder[tabs.enchanting.tA] or 99) < (tabs.enchanting.tierOrder[tabs.enchanting.tB] or 99)
        end
        return a < b
    end)
    return tabs.enchanting.enchantList
end

function getEnchantPetPower(petData)
    tabs.enchanting.PetStats = require(services.replicatedStorage.Game.PetStats)
    if petData.Multiplier1 and tonumber(petData.Multiplier1) and tonumber(petData.Multiplier1) > 0 then
        return tonumber(petData.Multiplier1)
    end
    tabs.enchanting.globalBest = (player.replication.Data.BestMultiplier and player.replication.Data.BestMultiplier[1]) or 0
    tabs.enchanting.pct = tabs.enchanting.PetStats:GetPercentage(petData.Name or "Unknown")
    if tabs.enchanting.pct then
        tabs.enchanting.base = (tabs.enchanting.globalBest * tabs.enchanting.pct) / 100
        return tabs.enchanting.PetStats:GetMulti(tabs.enchanting.base, petData.Tier or "Normal", petData.Level or 1, petData)
    end
    return tabs.enchanting.PetStats:GetMulti(petData.Multi1 or 0, petData.Tier or "Normal", petData.Level or 1, petData)
end

function getFormattedEnchantPetList()
    repeat task.wait() until player.replication.Loaded and player.replication.Data and player.replication.Data.Pets
    table.clear(tabs.enchanting.petDropdownMap)

    tabs.enchanting.petsToSort = {}
    for _, petData in pairs(player.replication.Data.Pets) do
        table.insert(tabs.enchanting.petsToSort, petData)
    end
    table.sort(tabs.enchanting.petsToSort, function(a, b)
        return getEnchantPetPower(a) > getEnchantPetPower(b)
    end)

    tabs.enchanting.formattedList = {}
    for i, petData in ipairs(tabs.enchanting.petsToSort) do
        tabs.enchanting.currentEnchant = tabs.enchanting.liveEnchantData[petData.Id] or petData.Enchant or ""
        tabs.enchanting.finalStr = string.format("%d. %s (%s)", i, petData.Name or "Unknown", tabs.enchanting.currentEnchant ~= "" and tabs.enchanting.currentEnchant or "No Enchant")
        table.insert(tabs.enchanting.formattedList, tabs.enchanting.finalStr)
        tabs.enchanting.petDropdownMap[tabs.enchanting.finalStr] = petData.Id
    end
    return tabs.enchanting.formattedList
end

function refreshEnchantPetDropdown()
    if tabs.enchanting.autoEnchantEnabled then return end
    task.spawn(function()
        if tabs.enchanting.petDropdown then
            pcall(function()
                tabs.enchanting.petDropdown:Refresh(getFormattedEnchantPetList())
            end)
        end
    end)
end

function updateEnchantStatus()
    if not tabs.enchanting.statusLabel then return end
    if tabs.enchanting.autoEnchantEnabled then return end
    repeat task.wait() until player.replication.Loaded and player.replication.Data

    tabs.enchanting.crystals = (player.replication.Data.Items and player.replication.Data.Items.EnchantCrystal) or 0
    tabs.enchanting.statusText = "Enchant Crystals: " .. tostring(tabs.enchanting.crystals) .. "\n\nSelected Pets:\n"
    tabs.enchanting.hasSelection = false

    for petStr, isSelected in pairs(tabs.enchanting.selectedPets) do
        if isSelected then
            tabs.enchanting.hasSelection = true
            tabs.enchanting.petId = tabs.enchanting.petDropdownMap[petStr]
            if tabs.enchanting.petId and player.replication.Data.Pets[tabs.enchanting.petId] then
                tabs.enchanting.pData = player.replication.Data.Pets[tabs.enchanting.petId]
                tabs.enchanting.ench = tabs.enchanting.liveEnchantData[tabs.enchanting.petId] or tabs.enchanting.pData.Enchant or ""
                tabs.enchanting.multi = formatSuffix(getEnchantPetPower(tabs.enchanting.pData))
                tabs.enchanting.line = string.format("%s (x%s)", tabs.enchanting.pData.Name or "Unknown", tabs.enchanting.multi)
                if tabs.enchanting.ench ~= "" then
                    tabs.enchanting.line = tabs.enchanting.line .. ": " .. tabs.enchanting.ench
                end
                tabs.enchanting.statusText = tabs.enchanting.statusText .. tabs.enchanting.line .. "\n"
            end
        end
    end

    if not tabs.enchanting.hasSelection then
        tabs.enchanting.statusText = tabs.enchanting.statusText .. "None"
    end

    tabs.enchanting.statusLabel:SetDesc(tabs.enchanting.statusText)
end

function startEnchantLoop()
    if tabs.enchanting.autoEnchanting then
        task.cancel(tabs.enchanting.autoEnchanting)
        tabs.enchanting.autoEnchanting = nil
    end

    tabs.enchanting.autoEnchanting = task.spawn(function()
        tabs.enchanting.originalInvoke = player.network.InvokeServer

        while tabs.enchanting.autoEnchantEnabled do
            repeat task.wait() until player.replication.Loaded and player.replication.Data

            tabs.enchanting.targetPet = nil
            for petStr, isSelected in pairs(tabs.enchanting.selectedPets) do
                if isSelected then
                    tabs.enchanting.pId = tabs.enchanting.petDropdownMap[petStr]
                    if tabs.enchanting.pId then
                        tabs.enchanting.curEnchant = tabs.enchanting.liveEnchantData[tabs.enchanting.pId] or ""
                        if not tabs.enchanting.selectedEnchants[tabs.enchanting.curEnchant] then
                            tabs.enchanting.targetPet = {
                                id = tabs.enchanting.pId,
                                name = (player.replication.Data.Pets[tabs.enchanting.pId] and player.replication.Data.Pets[tabs.enchanting.pId].Name) or "Unknown"
                            }
                            break
                        end
                    end
                end
            end

            tabs.enchanting.crystals = (player.replication.Data.Items and player.replication.Data.Items.EnchantCrystal) or 0

            if not tabs.enchanting.targetPet then
                tabs.enchanting.statusLabel:SetDesc("Enchant Crystals: " .. tabs.enchanting.crystals .. "\n\nAll selected pets have a desired enchant!")
                task.wait(3)
            elseif tabs.enchanting.crystals <= 0 then
                tabs.enchanting.statusLabel:SetDesc("Out of Enchant Crystals!")
                task.wait(3)
            else
                tabs.enchanting.curId = tabs.enchanting.targetPet.id
                tabs.enchanting.lastResult = nil
                tabs.enchanting.currentOfTarget = tabs.enchanting.liveEnchantData[tabs.enchanting.curId] or ""
                tabs.enchanting.currentDisplay = tabs.enchanting.currentOfTarget ~= "" and tabs.enchanting.currentOfTarget or "No Enchant"
                tabs.enchanting.statusLabel:SetDesc("Enchant Crystals: " .. tabs.enchanting.crystals .. "\n\nEnchanting: " .. tabs.enchanting.targetPet.name .. "\nCurrently: " .. tabs.enchanting.currentDisplay)

                player.network.InvokeServer = function(self, eventName, ...)
                    tabs.enchanting.res = tabs.enchanting.originalInvoke(self, eventName, ...)
                    if eventName == "EnchantPet" and select(1, ...) == tabs.enchanting.curId then
                        tabs.enchanting.lastResult = tabs.enchanting.res
                        tabs.enchanting.liveEnchantData[tabs.enchanting.curId] = tabs.enchanting.res
                        if player.replication.Data.Pets[tabs.enchanting.curId] then
                            player.replication.Data.Pets[tabs.enchanting.curId].Enchant = tabs.enchanting.res
                        end
                        player.network.InvokeServer = tabs.enchanting.originalInvoke
                    end
                    return tabs.enchanting.res
                end

                pcall(player.network.InvokeServer, player.network, "EnchantPet", tabs.enchanting.curId)

                tabs.enchanting.timeout = 0
                repeat
                    task.wait(0.2)
                    tabs.enchanting.timeout = tabs.enchanting.timeout + 0.2
                until tabs.enchanting.lastResult ~= nil or tabs.enchanting.timeout >= 5

                player.network.InvokeServer = tabs.enchanting.originalInvoke

                if not tabs.enchanting.lastResult then
                    tabs.enchanting.statusLabel:SetDesc("Enchant Crystals: " .. tabs.enchanting.crystals .. "\n\nCurrently enchanting " .. tabs.enchanting.targetPet.name .. ". Retrying...")
                    task.wait(3)
                end
            end

            task.wait(1)
        end

        player.network.InvokeServer = tabs.enchanting.originalInvoke
    end)
end

function stopEnchantLoop()
    tabs.enchanting.autoEnchantEnabled = false
    if tabs.enchanting.autoEnchanting then
        task.cancel(tabs.enchanting.autoEnchanting)
        tabs.enchanting.autoEnchanting = nil
    end
    pcall(updateEnchantStatus)
end

tabs.enchanting.initialPetList = getFormattedEnchantPetList()


--[[
    manoman ach du scheisse das war so viel aber das ist ENCHANTING
]]

tabs.enchanting:Space({Colums = 2})
tabs.enchanting:Section({
    Title = "Auto Enchanting",
    TextSize = 22,
    TextXAlignment = "Center",
    Box = false,
})
tabs.enchanting:Dropdown({
    Title = "Select Desired Enchant(s)",
    Values = getEnchantNames(),
    Value = {},
    Multi = true,
    SearchBarEnabled = true,
    Callback = function(value)
        tabs.enchanting.selectedEnchants = {}
        if type(value) == "table" then
            for _, enchantName in pairs(value) do
                if type(enchantName) == "string" then
                    tabs.enchanting.selectedEnchants[enchantName] = true
                end
            end
        end
    end,
})
tabs.enchanting.petDropdown = tabs.enchanting:Dropdown({
    Title = "Select Pet(s) to Enchant",
    Values = tabs.enchanting.initialPetList,
    Value = {},
    Multi = true,
    SearchBarEnabled = true,
    Callback = function(value)
        tabs.enchanting.selectedPets = {}
        if type(value) == "table" then
            for _, petStr in pairs(value) do
                if type(petStr) == "string" then
                    tabs.enchanting.selectedPets[petStr] = true
                end
            end
        end
        pcall(updateEnchantStatus)
    end,
})
tabs.enchanting:Button({
    Title = "Refresh Pet List",
    Icon = "lucide:refresh-cw",
    Callback = function()
        if tabs.enchanting.autoEnchantEnabled then
            tabs.enchanting.statusLabel:SetDesc("Stop Auto Enchant before refreshing!")
            return
        end
        refreshEnchantPetDropdown()
        pcall(updateEnchantStatus)
    end,
})
tabs.enchanting.statusLabel = tabs.enchanting:Paragraph({
    Title = "Status",
    Desc = "Loading...",
})
tabs.enchanting:Toggle({
    Title = "Auto Enchant",
    Value = false,
    Icon = "lucide:sparkles",
    Callback = function(value)
        tabs.enchanting.autoEnchantEnabled = value
        if value then
            if not next(tabs.enchanting.selectedPets) or not next(tabs.enchanting.selectedEnchants) then
                tabs.enchanting.autoEnchantEnabled = false
                tabs.enchanting.statusLabel:SetDesc("Select at least one pet and one enchant first!")
                return
            end
            startEnchantLoop()
        else
            stopEnchantLoop()
        end
    end,
})

task.spawn(function()
    repeat task.wait() until player.replication.Loaded and player.replication.Data
    pcall(updateEnchantStatus)
end)

--[[
    MISC also das ist wirklich quatsch das das noch meine struktur auseinandernimmt
]]

tabs.misc.selectedDeletePets = {}
tabs.misc.deletePetsDropdown = nil
tabs.misc.autoDeleteEnabled = false
tabs.misc.autoDeleting = nil

function getOwnedPetNamesWithTier()
    repeat task.wait() until player.replication.Loaded and player.replication.Data
    tabs.misc.nameSet = {}
    tabs.misc.allPetNames = {}
    for _, petData in pairs(player.replication.Data.Pets) do
        tabs.misc.key = petData.Tier .. " - " .. petData.Name
        if not petData.Locked and not tabs.misc.nameSet[tabs.misc.key] then
            table.insert(tabs.misc.allPetNames, tabs.misc.key)
            tabs.misc.nameSet[tabs.misc.key] = true
        end
    end
    table.sort(tabs.misc.allPetNames)
    return tabs.misc.allPetNames
end

tabs.misc.spinEnabled = false
tabs.misc.spinning = nil

tabs.misc.digEnabled = false
tabs.misc.digging = nil

tabs.misc.deletePetName = ""
tabs.misc.deleting = nil

tabs.misc:Section({
    Title = "Wheels",
    TextSize = 22,
    Box = false,
    TextXAlignment = "Center",
})

tabs.misc:Toggle({
    Title = "Spin Valentines Wheel",
    Value = false,
    Icon = "lucide:circle-dashed",
    Callback = function(value)
        tabs.misc.spinEnabled = value
        if tabs.misc.spinning then
            task.cancel(tabs.misc.spinning)
            tabs.misc.spinning = nil
        end
        if value then
            tabs.misc.spinning = task.spawn(function()
                tabs.misc.Network = require(services.replicatedStorage.Modules.Network)
                while tabs.misc.spinEnabled do
                    pcall(function()
                        tabs.misc.Network:InvokeServer("SpinWheel")
                    end)
                    task.wait(5)
                end
            end)
        end
    end
})

tabs.misc:Space({ Colums = 2 })
tabs.misc:Section({
    Title = "Dig Minigame",
    TextSize = 22,
    Box = false,
    TextXAlignment = "Center",
})

tabs.misc:Toggle({
    Title = "Auto Dig",
    Value = false,
    Icon = "lucide:shovel",
    Callback = function(value)
        tabs.misc.digEnabled = value
        if tabs.misc.digging then
            task.cancel(tabs.misc.digging)
            tabs.misc.digging = nil
        end
        if value then
            tabs.misc.digging = task.spawn(function()
                tabs.misc.Network = require(services.replicatedStorage.Modules.Network)
                while tabs.misc.digEnabled do
                    pcall(function()
                        tabs.misc.Network:InvokeServer("StartMinigame", "DigGame")
                        task.wait(0.25)
                        tabs.misc.Network:InvokeServer("FinishMinigame", "DigGame")
                    end)
                    task.wait(1)
                end
            end)
        end
    end
})

tabs.misc:Space({ Colums = 2 })
tabs.misc:Section({
    Title = "Delete Pets by Name",
    TextSize = 22,
    Box = false,
    TextXAlignment = "Center",
})

tabs.misc.deletePetsDropdown = tabs.misc:Dropdown({
    Title = "Select Pets to Delete",
    Values = getOwnedPetNamesWithTier(),
    Value = {},
    Multi = true,
    SearchBarEnabled = true,
    Callback = function(value)
        tabs.misc.selectedDeletePets = {}
        if type(value) == "table" then
            for _, entry in pairs(value) do
                if type(entry) == "string" then
                    tabs.misc.selectedDeletePets[entry] = true
                end
            end
        end
    end
})

tabs.misc:Button({
    Title = "Refresh Pet List",
    Icon = "lucide:refresh-cw",
    Callback = function()
        tabs.misc.selectedDeletePets = {}
        pcall(function()
            tabs.misc.deletePetsDropdown:Refresh(getOwnedPetNamesWithTier())
        end)
    end
})

tabs.misc:Toggle({
    Title = "Auto Delete Selected Pets",
    Icon = "lucide:trash-2",
    Value = false,
    Callback = function(value)
        tabs.misc.autoDeleteEnabled = value
        if tabs.misc.autoDeleting then
            task.cancel(tabs.misc.autoDeleting)
            tabs.misc.autoDeleting = nil
        end
        if value then
            tabs.misc.autoDeleting = task.spawn(function()
                tabs.misc.Network = require(services.replicatedStorage.Modules.Network)
                while tabs.misc.autoDeleteEnabled do
                    if next(tabs.misc.selectedDeletePets) then
                        repeat task.wait() until player.replication.Loaded and player.replication.Data
                        for petId, petData in pairs(player.replication.Data.Pets) do
                            tabs.misc.key = petData.Tier .. " - " .. petData.Name
                            if tabs.misc.selectedDeletePets[tabs.misc.key] and not petData.Locked then
                                pcall(function()
                                    tabs.misc.Network:InvokeServer("DeletePet", petId)
                                end)
                                task.wait(0.2)
                            end
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end
})

--[[
    WEBHOOK TAB
]]

tabs.webhook.url = ""
tabs.webhook.discordId = ""
tabs.webhook.showUser = false
tabs.webhook.selectedRarities = {}
tabs.webhook.petWebhookEnabled = false
tabs.webhook.petWebhooking = nil
tabs.webhook.originalInvoke = nil

tabs.webhook.requestFunc = (syn and syn.request) or (http and http.request) or request

function sendWebhook(content, embeds)
    if not tabs.webhook.url or tabs.webhook.url == "" then return end
    pcall(function()
        tabs.webhook.requestFunc({
            Url = tabs.webhook.url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = game:GetService("HttpService"):JSONEncode({
                content = content,
                embeds = embeds
            })
        })
    end)
end

function getRarityList()
    tabs.webhook.PetStatsRarities = require(services.replicatedStorage.Game.PetStats.Rarities)
    tabs.webhook.orderedRarities = {
        "Common", "Rare", "Epic", "Legendary", "Mythical",
        "Godly", "Exclusive", "Secret I", "Secret II", "Secret III"
    }
    tabs.webhook.rarityList = {}
    for _, rarity in ipairs(tabs.webhook.orderedRarities) do
        if tabs.webhook.PetStatsRarities[rarity] then
            table.insert(tabs.webhook.rarityList, rarity)
        end
    end
    return tabs.webhook.rarityList
end

function getRarityColor(rarity)
    tabs.webhook.PetStatsRarities = require(services.replicatedStorage.Game.PetStats.Rarities)
    if tabs.webhook.PetStatsRarities[rarity] and tabs.webhook.PetStatsRarities[rarity][1] then
        tabs.webhook.c = tabs.webhook.PetStatsRarities[rarity][1]
        return math.floor(tabs.webhook.c.R * 255) * 65536
            + math.floor(tabs.webhook.c.G * 255) * 256
            + math.floor(tabs.webhook.c.B * 255)
    end
    return 0xFFFFFF
end

tabs.webhook:Section({
    Title = "Settings",
    TextSize = 22,
    Box = false,
    TextXAlignment = "Center",
})

tabs.webhook:Input({
    Title = "Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(value)
        tabs.webhook.url = value
    end
})

tabs.webhook:Input({
    Title = "Discord User ID",
    Placeholder = "123456789012345678",
    Callback = function(value)
        tabs.webhook.discordId = value
    end
})

tabs.webhook:Toggle({
    Title = "Show Roblox User",
    Value = false,
    Icon = "lucide:user",
    Callback = function(value)
        tabs.webhook.showUser = value
    end
})

tabs.webhook:Button({
    Title = "Test Webhook",
    Icon = "lucide:send",
    Callback = function()
        sendWebhook(
            tabs.webhook.discordId ~= "" and string.format("<@%s>", tabs.webhook.discordId) or "",
            {{
                title = "🔔 Webhook Test",
                description = "Your webhook is working correctly!",
                color = 0x00FF00,
                fields = {
                    {
                        name = "👤 User",
                        value = tabs.webhook.showUser and player.name or "Anonymous",
                        inline = true
                    },
                    {
                        name = "🎮 Game",
                        value = "Tap Simulator",
                        inline = true
                    }
                },
                footer = { text = "Sent by Silence" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
            }}
        )
    end
})

tabs.webhook:Space({ Colums = 2 })
tabs.webhook:Section({
    Title = "Pet Webhook",
    TextSize = 22,
    Box = false,
    TextXAlignment = "Center",
})

tabs.webhook:Dropdown({
    Title = "Select Rarities to Track",
    Values = getRarityList(),
    Value = {},
    Multi = true,
    SearchBarEnabled = true,
    Callback = function(value)
        tabs.webhook.selectedRarities = {}
        if type(value) == "table" then
            for _, rarity in pairs(value) do
                if type(rarity) == "string" then
                    tabs.webhook.selectedRarities[rarity] = true
                end
            end
        end
    end
})

tabs.webhook:Toggle({
    Title = "Enable Pet Webhook",
    Value = false,
    Icon = "lucide:link",
    Callback = function(value)
        tabs.webhook.petWebhookEnabled = value

        if tabs.webhook.petWebhooking then
            task.cancel(tabs.webhook.petWebhooking)
            tabs.webhook.petWebhooking = nil
        end

        if tabs.webhook.originalInvoke then
            player.network.InvokeServer = tabs.webhook.originalInvoke
            tabs.webhook.originalInvoke = nil
        end

        if value then
            tabs.webhook.petWebhooking = task.spawn(function()
                tabs.webhook.PetStats = require(services.replicatedStorage.Game.PetStats)
                tabs.webhook.originalInvoke = player.network.InvokeServer

                player.network.InvokeServer = function(self, eventName, ...)
                    tabs.webhook.res = tabs.webhook.originalInvoke(self, eventName, ...)

                    if eventName == "OpenEgg" and tabs.webhook.petWebhookEnabled then
                        tabs.webhook.eggName = select(1, ...)

                        if tabs.webhook.res ~= nil and type(tabs.webhook.res) == "table" then
                            tabs.webhook.petsToSend = {}

                            for _, petData in ipairs(tabs.webhook.res) do
                                if petData ~= nil and type(petData) == "table" then
                                    tabs.webhook.petName = petData[1]
                                    tabs.webhook.petTier = petData[2]

                                    if tabs.webhook.petName then
                                        tabs.webhook.rarity = "Unknown"
                                        pcall(function()
                                            tabs.webhook.rarity = tabs.webhook.PetStats:GetRarity(tabs.webhook.petName, true) or "Unknown"
                                        end)

                                        if tabs.webhook.selectedRarities[tabs.webhook.rarity] then
                                            table.insert(tabs.webhook.petsToSend, {
                                                name = tabs.webhook.petName,
                                                tier = tabs.webhook.petTier,
                                                rarity = tabs.webhook.rarity
                                            })
                                        end
                                    end
                                end
                            end

                            if #tabs.webhook.petsToSend > 0 then
                                tabs.webhook.fields = {}
                                for i, pet in ipairs(tabs.webhook.petsToSend) do
                                    table.insert(tabs.webhook.fields, {
                                        name = string.format("🐾 Pet #%d:", i),
                                        value = string.format("**%s %s**\n✨ **Rarity:** `%s`", pet.tier or "Normal", pet.name, pet.rarity),
                                        inline = true
                                    })
                                end

                                sendWebhook(
                                    tabs.webhook.discordId ~= "" and string.format("<@%s>", tabs.webhook.discordId) or "",
                                    {{
                                        title = string.format("🥚 `" .. player.name .. "` Hatched %d Pet(s) from %s Egg!", #tabs.webhook.petsToSend, tabs.webhook.eggName or "Unknown"),
                                        color = getRarityColor(tabs.webhook.petsToSend[1].rarity),
                                        fields = tabs.webhook.fields,
                                        footer = {
                                            text = "Sent by Silence"
                                        },
                                        timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
                                    }}
                                )
                            end
                        end
                    end

                    return tabs.webhook.res
                end

                while tabs.webhook.petWebhookEnabled do
                    task.wait(1)
                end

                player.network.InvokeServer = tabs.webhook.originalInvoke
                tabs.webhook.originalInvoke = nil
            end)
        end
    end
})

local elements = {
    config = {
        tabs.config:Paragraph({
            Title = "Coming Soon",
            Desc = "I need to write my own Config-Manager because WindUI has no built in one"
        })
    },
    main = {
        tabs.main:Section({
            Title = "Clicking",
            TextSize = 22,
            Box = false,
            TextXAlignment = "Center",
        }),
        tabs.main:Toggle({
            Title = "Auto Click",
            Value = false,
            Icon = "lucide:mouse-pointer-2",
            Callback = function(state)
                if state then
                    tabs.main.clicking = task.spawn(function()
                        tabs.main.getButton = function()
                            return player.player.PlayerGui
                                and player.player.PlayerGui:FindFirstChild("Game")
                                and player.player.PlayerGui.Game.Bottom.Tap:FindFirstChild("Button")
                        end
                        while true do
                            pcall(function()
                                player.network:FireServer("Tap", true)
                            end)
                            tabs.main.button = tabs.main.getButton()
                            if tabs.main.button then
                                pcall(function()
                                    for _, c in pairs(getconnections(tabs.main.button.MouseButton1Down)) do
                                        c:Fire()
                                    end
                                end)
                            end
                            task.wait()
                        end
                    end)
                else
                    if tabs.main.clicking then
                        task.cancel(tabs.main.clicking)
                        tabs.main.clicking = nil
                    end
                end
            end,
        }),
        tabs.main:Toggle({
            Title = "Hide Taps",
            Value = false,
            Icon = "lucide:mouse-pointer-2-off",
            Callback = function(enabled)
                tabs.main.popupModulePath = player.player.PlayerScripts.Modules.Controllers["UI Controller"].Popups
                tabs.main.success, tabs.main.PopupsModule = pcall(require, tabs.main.popupModulePath)
                tabs.main.originalStates = tabs.main.originalStates or {}
                if enabled then
                    tabs.main.soundsToMute = { ["Critical"]=true, ["Taps"]=true, ["Click"]=true, ["Click2"]=true, ["Shine"]=true, ["PopUp"]=true }
                    tabs.main.originalStates.sounds = {}
                    for _, soundObject in ipairs(services.soundService:GetDescendants()) do
                        if soundObject:IsA("Sound") and tabs.main.soundsToMute[soundObject.Name] then
                            tabs.main.originalStates.sounds[soundObject] = {
                                volume = soundObject.Volume,
                                connection = soundObject:GetPropertyChangedSignal("Volume"):Connect(function()
                                    if soundObject.Volume > 0 then soundObject.Volume = 0 end
                                end)
                            }
                            soundObject.Volume = 0
                        end
                    end
                    if tabs.main.success and tabs.main.PopupsModule and not tabs.main.originalStates.Popup then
                        tabs.main.originalStates.Popup = tabs.main.PopupsModule.Popup
                        tabs.main.PopupsModule.Popup = function(self, popupType, ...)
                            if popupType == "tap" or popupType == "tapArea" or popupType == "critTapArea" then return end
                            return tabs.main.originalStates.Popup(self, popupType, ...)
                        end
                    end
                else
                    if tabs.main.originalStates.sounds then
                        for soundObject, data in pairs(tabs.main.originalStates.sounds) do
                            if data.connection then data.connection:Disconnect() end
                            if soundObject and soundObject.Parent then
                                soundObject.Volume = data.volume
                            end
                        end
                        tabs.main.originalStates.sounds = nil
                    end
                    if tabs.main.success and tabs.main.PopupsModule and tabs.main.originalStates.Popup then
                        tabs.main.PopupsModule.Popup = tabs.main.originalStates.Popup
                        tabs.main.originalStates.Popup = nil
                    end
                end
            end,
        }),
        tabs.main:Space({Colums = 2}),
        tabs.main:Section({
            Title = "Rebirths",
            TextSize = 22,
            Box = false,
            TextXAlignment = "Center",
        }),

        tabs.main:Dropdown({
            Title = "Select Rebirth Amount",
            Values = tabs.main.rebValues,
            Value = tabs.main.rebValues[1],
            Multi = false,
            SearchBarEnabled = true,
            Callback = function(selected)
                tabs.main.selectedRebirth = selected
            end,
        }),

        tabs.main:Toggle({
            Title = "Auto Rebirth",
            Value = false,
            Icon = "lucide:repeat",
            Callback = function(state)
                if state then
                    tabs.main.rebirthing = task.spawn(function()
                        while true do
                            if tabs.main.selectedRebirth then
                                tabs.main.option = tabs.main.rebMap[tabs.main.selectedRebirth]
                                if tabs.main.option then
                                    player.network:InvokeServer("Rebirth", tabs.main.option.index)
                                end
                            end
                            task.wait(0.1)
                        end
                    end)
                else
                    if tabs.main.rebirthing then
                        task.cancel(tabs.main.rebirthing)
                        tabs.main.rebirthing = nil
                    end
                end
            end,
        }),
        tabs.main:Space({Colums = 2}),
        tabs.main:Section({
            Title = "Potions",
            TextSize = 22,
            Box = false,
            TextXAlignment = "Center",
        }),

        tabs.main:Dropdown({
        Title = "Select Amount",
        Values = {"x1", "x3", "x10"},
        Value = {},
        Multi = true,
        Callback = function(value)
            tabs.main.selectedPotionValues = {}
            if type(value) == "table" then
                for _, amountStr in pairs(value) do
                    tabs.main.amount = tonumber(amountStr:match("x(%d+)"))
                    if tabs.main.amount then
                        table.insert(tabs.main.selectedPotionValues, tabs.main.amount)
                    end
                end
                table.sort(tabs.main.selectedPotionValues)
            end
        end
        }),
        tabs.main:Toggle({
            Title = "Buy Potions",
            Value = false,
            Icon = "lucide:flask-round",
            Callback = function(value)
                tabs.main.buyPotions = value
                if tabs.main.buyingPotions then
                    task.cancel(tabs.main.buyingPotions)
                    tabs.main.buyingPotions = nil
                end
                if value then
                    tabs.main.buyingPotions = task.spawn(function()
                        tabs.main.Network = require(services.replicatedStorage.Modules.Network)
                    
                        while tabs.main.buyPotions do
                            for _, amount in ipairs(tabs.main.selectedPotionValues) do
                                if tabs.main.buyPotions then
                                    pcall(function()
                                        tabs.main.Network:InvokeServer("BuyPotionMachine", amount)
                                    end)
                                    task.wait(2)
                                end
                            end
                            task.wait(300)
                        end
                    end)
                end
            end
        }),
        tabs.main:Space({Colums = 2}),
        tabs.main:Section({
            Title = "Ranks",
            TextSize = 22,
            Box = false,
            TextXAlignment = "Center",
        }),
        tabs.main:Toggle({
            Title = "Claim Rank Rewards",
            Value = false,
            Icon = "lucide:award",
            Callback = function(value)
                    tabs.main.claimRewards = value
                    
                    if tabs.main.autoClaiming then
                        task.cancel(tabs.main.autoClaiming)
                        tabs.main.autoClaiming = nil
                    end
                    
                    if value then
                        tabs.main.autoClaiming = task.spawn(function()
                            tabs.main.network = require(services.replicatedStorage.Modules.Network)
                            
                            while tabs.main.claimRewards do
                                pcall(function()
                                    tabs.main.network:InvokeServer("ClaimRankReward")
                                end)
                                
                                task.wait(60)
                            end
                        end)
                    end
                end
        }),
    },
    hatching = {
        tabs.hatching:Section({
            Title = "Hatching",
            TextSize = 22,
            Box = false,
            TextXAlignment = "Center",
        }),
        tabs.hatching:Dropdown({
        Title = "Select Egg",
        Values = tabs.hatching.eggDropdownValues,
        Value = tabs.hatching.eggDropdownValues[1] or "Basic - 250",
        Multi = false,
        SearchBarEnabled = true,
        Callback = function(selectedValue)
            tabs.hatching.eggName = selectedValue:match("^(.-)%s*%-")
            if tabs.hatching.eggName then
                tabs.hatching.selectedEgg = tabs.hatching.eggName
            end
        end,
        }),
        tabs.hatching:Dropdown({
            Title = "Hatch Amount",
            Values = {"1x", "3x", "8x", "Max"},
            Value = "Max",
            Multi = false,
            Callback = function(selectedValue)
                if selectedValue == "1x" then
                    tabs.hatching.selectedHatchAmount = 1
                elseif selectedValue == "3x" then
                    tabs.hatching.selectedHatchAmount = 3
                elseif selectedValue == "8x" then
                    tabs.hatching.selectedHatchAmount = 8
                elseif selectedValue == "Max" then
                    tabs.hatching.data = player.replication.Data
                    if tabs.hatching.data.MaxEggsHatch then
                        tabs.hatching.selectedHatchAmount = tabs.hatching.data.MaxEggsHatch
                    else
                        tabs.hatching.gamepasses = tabs.hatching.data.Gamepasses or {}
                        if tabs.hatching.gamepasses.x8Egg then
                            tabs.hatching.selectedHatchAmount = 8
                        else
                            tabs.hatching.selectedHatchAmount = 3
                        end
                    end
                end
            end
        }),
        tabs.hatching:Toggle({
            Title = "Auto Hatch",
            Value = false,
            Icon = "lucide:egg",
            Callback = function(value)
                tabs.hatching.autoHatch = value
                if tabs.hatching.autoHatching then
                    task.cancel(tabs.hatching.autoHatching)
                    tabs.hatching.autoHatching = nil
                end
                if value then
                    tabs.hatching.autoHatching = task.spawn(function()
                        tabs.hatching.Network = require(services.replicatedStorage.Modules.Network)
                        tabs.main.char = player.player.Character
                        if tabs.main.char and tabs.main.char:FindFirstChild("HumanoidRootPart") then
                            tabs.main.char.HumanoidRootPart.CFrame = CFrame.new(-145.5439, 213.212769, 236.957123, -0.311900645, 9.30314492e-09, 0.950114727, 2.13227711e-08, 1, -2.79183032e-09, -0.950114727, 1.93883061e-08, -0.311900645)
                            task.wait(0.5)
                        end
                        task.wait(0.2)
                        tpToEgg(tabs.hatching.selectedEgg)
                        task.wait(0.2)
                        
                        while tabs.hatching.autoHatch do
                            if tabs.crafting.craftingstate.processing then
                                task.wait(0.5)
                                continue
                            end
                            
                            if tabs.hatching.selectedEgg then
                                if not checkDistanceToEgg(tabs.hatching.selectedEgg) then
                                    tpToEgg(tabs.hatching.selectedEgg)
                                    task.wait(0.5)
                                end
                                
                                pcall(function()
                                    tabs.hatching.Network:InvokeServer("OpenEgg", tabs.hatching.selectedEgg, tabs.hatching.selectedHatchAmount)
                                end)
                            end
                            task.wait(0.1)
                        end
                    end)
                end
            end,
        }),
    },
    crafting = {
        -- ab hier ist alles gefckt :sob:
    },
    teleport = {
        tabs.teleport:Section({
            Title = "Teleport on Join",
            TextSize = 22,
            Box = false,
            TextXAlignment = "Center",
        }),
        tabs.teleport:Dropdown({
            Title = "Select Zone",
            Values = getTeleportDropdownValues(),
            Value = tabs.teleport.selectedZone,
            Multi = false,
            SearchBarEnabled = true,
            Callback = function(selectedValue)
                tabs.teleport.selectedZone = selectedValue
            end
        }),
        tabs.teleport:Toggle({
            Title = "Teleport on Join",
            Desc = "Requires Config Autoloading",
            Value = false,
            Icon = "lucide:map-pin",
            Callback = function(value)
                tabs.teleport.teleportOnJoinEnabled = value

                if value and tabs.teleport.selectedZone then
                    task.spawn(function()
                        tabs.teleport.character = player.player.Character or player.player.CharacterAdded:Wait()
                        tabs.teleport.hrp = tabs.teleport.character:WaitForChild("HumanoidRootPart", 10)

                        if tabs.teleport.hrp then
                            task.wait(1)
                            tabs.teleport.worldName = tabs.teleport.worldTeleports[tabs.teleport.selectedZone]
                            if tabs.teleport.worldName then
                                pcall(function()
                                    player.network:InvokeServer("TeleportWorld", tabs.teleport.worldName)
                                end)
                            else
                                pcall(function()
                                    player.network:InvokeServer("TeleportZone", tabs.teleport.selectedZone)
                                end)
                            end
                        end
                    end)
                end
            end,
        }),
    },
    enchanting = {
        -- rip x2
    },
    misc = {
        -- rip x3
    },
    webhook = {
        -- jetzt mach ich das auch ausserhalb also ehrlich
    },
    info = {
        tabs.info:Section({
            Title = "Info",
            TextSize = 22,
            Box = false,
            TextXAlignment = "Center",
        }),
        tabs.info:Paragraph({
            Title = "Silence V3",
            Desc = "Tap Simulator V1.0"
        }),
        tabs.info:Button({
            Title = "Copy Discord Invite",
            Desc = "dsc.gg/silenceontop",
            Icon = "lucide:clipboard",
            Callback = function()
                setclipboard("https://discord.gg/9eFf93Kg8D")
                WindUI:Notify({
                    Title = "Silence Studios",
                    Content = "Invite Copied to Clipboard!"
                })
            end
        }),
        tabs.info:Space({Columns = 1}),
        tabs.info:Section({
            Title = "Credits",
            TextSize = 22,
            Box = false,
            TextXAlignment = "Center",
        }),
        tabs.info:Paragraph({
            Title = "Made by Henne @ Silence Studios",
            Desc = "Encountered a bug? Report it on Discord!"
        })
    },
}

WindUI:Notify({
    Title = "Silence V3",
    Content = "Script loaded completely"
})
