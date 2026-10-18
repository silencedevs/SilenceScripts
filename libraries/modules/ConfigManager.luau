local Module = {Method = "AddConfigTab"}
local Http = game:GetService("HttpService")

local function encode(value)
    local kind = typeof(value)
    if kind == "Color3" then return {Type = "Color3", R = value.R, G = value.G, B = value.B} end
    if kind == "EnumItem" then return {Type = "Enum", Enum = tostring(value.EnumType), Name = value.Name} end
    if type(value) == "table" then
        local result = {}
        for key, item in pairs(value) do result[key] = encode(item) end
        return result
    end
    return value
end
local function decode(value)
    if type(value) ~= "table" then return value end
    if value.Type == "Color3" then
        assert(type(value.R) == "number" and type(value.G) == "number" and type(value.B) == "number", "Invalid color")
        return Color3.new(value.R, value.G, value.B)
    end
    if value.Type == "Enum" then
        local enum = (value.Enum == "Enum.Font" or value.Enum == "Font") and Enum.Font
            or (value.Enum == "Enum.KeyCode" or value.Enum == "KeyCode") and Enum.KeyCode
        assert(enum and enum[value.Name], "Invalid enum")
        return enum[value.Name]
    end
    local result = {}
    for key, item in pairs(value) do result[key] = decode(item) end
    return result
end
local function validName(name)
    assert(type(name) == "string", "Enter a config name")
    name = name:match("^%s*(.-)%s*$")
    assert(#name > 0 and #name <= 64 and name:match("^[%w _%-]+$"), "Use 1–64 letters, numbers, spaces, - or _")
    assert(name ~= "_autoload", "Reserved profile name")
    return name
end
local function mkdir(path)
    assert(type(writefile) == "function" and type(readfile) == "function", "Executor does not support config files")
    local built = ""
    for part in path:gmatch("[^/]+") do
        built = built == "" and part or built .. "/" .. part
        if type(makefolder) == "function" then pcall(makefolder, built) end
    end
end

function Module:Build(window, settings)
    settings = settings or {}
    local folder = settings.Folder or "Silence/Configs/" .. tostring(game.PlaceId)
    local tab, content = window:AddTab(settings.Title or "Configs")
    tab:SetConfigIgnored(true)
    local manager = {Tab = tab, Folder = folder, Selected = nil}
    tab:AddHeading("Configuration profiles")
    local status = tab:AddLabel("Save and restore your script settings and appearance.")
    local nameInput = tab:AddTextBox("New profile name", function() end, {clear = false})
    local list = tab:AddDropdown("Select profile", function(name) manager.Selected = name end)

    function manager:Refresh()
        local names = {}
        if type(listfiles) == "function" then
            mkdir(folder)
            for _, path in ipairs(listfiles(folder)) do
                local name = path:gsub("\\", "/"):match("/([^/]+)%.json$")
                if name and name ~= "_autoload" then table.insert(names, name) end
            end
        end
        table.sort(names)
        list:Refresh(names)
        if self.Selected and table.find(names, self.Selected) then list:SetValue(self.Selected)
        else self.Selected = nil end
        return names
    end
    function manager:Save(name)
        name = validName(name)
        mkdir(folder)
        local data = {Version = 1, Values = encode(window:GetConfigValues()), Theme = encode(window:GetTheme())}
        writefile(folder .. "/" .. name .. ".json", Http:JSONEncode(data))
        self.Selected = name
        self:Refresh()
        return name
    end
    function manager:Load(name, loadOptions)
        name = validName(name)
        local data = Http:JSONDecode(readfile(folder .. "/" .. name .. ".json"))
        assert(type(data) == "table" and data.Version == 1 and type(data.Values) == "table", "Unsupported config format")
        local values = decode(data.Values)
        if data.Theme and not (loadOptions and loadOptions.SkipTheme) then window:SetTheme(decode(data.Theme)) end
        local failures = window:ApplyConfigValues(values)
        self.Selected = name
        if #failures > 0 then error("Partially loaded: " .. table.concat(failures, "; ")) end
        return name
    end
    function manager:Delete(name)
        name = validName(name)
        assert(type(delfile) == "function", "Executor cannot delete files")
        delfile(folder .. "/" .. name .. ".json")
        if self:GetAutoload() == name then self:SetAutoload(nil) end
        if self.Selected == name then self.Selected = nil end
        self:Refresh()
    end
    function manager:SetAutoload(name)
        mkdir(folder)
        writefile(folder .. "/_autoload.json", Http:JSONEncode({Name = name and validName(name) or false}))
    end
    function manager:GetAutoload()
        local ok, data = pcall(function() return Http:JSONDecode(readfile(folder .. "/_autoload.json")) end)
        return ok and type(data) == "table" and type(data.Name) == "string" and data.Name or nil
    end
    function manager:LoadAutoload()
        local name = self:GetAutoload()
        if name then return self:Load(name, {SkipTheme = window.CustomizePreferencesLoaded == true}) end
    end
    local function action(callback)
        return function()
            local ok, message = pcall(callback)
            status.Text = ok and (message or "Done") or tostring(message)
            status.TextColor3 = ok and Color3.fromRGB(100, 230, 140) or Color3.fromRGB(255, 155, 100)
        end
    end
    tab:AddButton("Create profile", action(function()
        local name = validName(nameInput.Text)
        assert(type(isfile) ~= "function" or not isfile(folder .. "/" .. name .. ".json"), "Profile already exists")
        manager:Save(name)
        return "Created: " .. name
    end))
    tab:AddButton("Save selected profile", action(function() return "Saved: " .. manager:Save(manager.Selected) end))
    tab:AddButton("Load selected profile", action(function() return "Loaded: " .. manager:Load(manager.Selected) end))
    tab:AddButton("Refresh profiles", action(function() return "Profiles: " .. #manager:Refresh() end))
    tab:AddButton("Delete selected profile", action(function() manager:Delete(manager.Selected); return "Profile deleted" end))
    tab:AddHeading("Startup profile")
    local autoloadLabel = tab:AddLabel("Autoload: none")
    local function updateAutoload() autoloadLabel.Text = "Autoload: " .. (manager:GetAutoload() or "none") end
    tab:AddButton("Use selected profile on startup", action(function()
        assert(manager.Selected, "Select a profile first")
        manager:SetAutoload(manager.Selected); updateAutoload(); return "Startup profile selected"
    end))
    tab:AddButton("Clear startup profile", action(function() manager:SetAutoload(nil); updateAutoload(); return "Startup profile cleared" end))
    local ok, err = pcall(function() manager:Refresh(); updateAutoload() end)
    if not ok then status.Text = tostring(err) end
    function manager:LoadStartup()
        local ok, result = pcall(self.LoadAutoload, self)
        status.Text = ok and (result and "Loaded: " .. result or "Autoload: none") or tostring(result)
        status.TextColor3 = ok and Color3.fromRGB(100, 230, 140) or Color3.fromRGB(255, 155, 100)
        return ok, result
    end
    if settings.AutoLoad == true then manager:LoadStartup() end
    return tab, manager, content
end
return Module
