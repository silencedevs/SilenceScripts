local Module = {Method = "AddCustomizeTab"}
function Module:Build(window, settings)
    settings = settings or {}
    local tab, content = window:AddTab(settings.Title or "Customize")
    tab:SetConfigIgnored(true)
    local runtime = window.Runtime
    local Http = game:GetService("HttpService")
    local folder = settings.Folder or "Silence/Customize/" .. tostring(game.PlaceId)
    local path = folder .. "/appearance.json"
    local syncing = true
    local dirty = false
    local saveVersion = 0
    local function ensureFolder()
        local current = ""
        for part in folder:gmatch("[^/]+") do
            current = current == "" and part or current .. "/" .. part
            if type(makefolder) == "function" then pcall(makefolder, current) end
        end
    end
    local function saveNow()
        if not dirty then return true end
        if type(writefile) ~= "function" then return false, "Executor cannot save appearance" end
        local ok, err = pcall(function()
            ensureFolder()
            local theme = window:GetTheme()
            local data = {Version = 1}
            for key, value in pairs(theme) do
                data[key] = typeof(value) == "Color3" and "#" .. value:ToHex()
                    or typeof(value) == "EnumItem" and value.Name or value
            end
            writefile(path, Http:JSONEncode(data))
        end)
        if ok then dirty = false; window.CustomizePreferencesLoaded = true end
        return ok, err
    end
    local loaded, loadError = pcall(function()
        if type(readfile) ~= "function" then return false end
        if type(isfile) == "function" and not isfile(path) then return false end
        local success, encoded = pcall(readfile, path)
        if not success then return false end
        local data = Http:JSONDecode(encoded)
        assert(type(data) == "table" and data.Version == 1, "Invalid appearance settings")
        local theme = {}
        for key in pairs(window:GetDefaultTheme()) do
            local value = data[key]
            if value ~= nil then
                if key:find("Color") then
                    assert(type(value) == "string" and value:match("^#%x%x%x%x%x%x$"), "Invalid saved color")
                    value = Color3.fromHex(value:sub(2))
                end
                theme[key] = value
            end
        end
        window:SetTheme(theme)
        return true
    end)
    window.CustomizePreferencesLoaded = loaded and loadError == true
    local savedLoadError = not loaded and tostring(loadError) or nil
    local controls = {}
    local status = tab:AddLabel(savedLoadError or "Appearance is saved automatically.")
    tab:AddHeading("Colors")
    local function colorControl(key, title)
        tab:AddLabel(title)
        controls[key] = tab:AddColorPicker(function(value)
            if not syncing then window:SetTheme({[key] = value}) end
        end)

    end
    colorControl("MainColor", "Main color")
    colorControl("BackgroundColor", "Window background")
    colorControl("TextColor", "Text color")
    tab:AddHeading("Typography")
    controls.Font = tab:AddDropdown("Font", function(value)
        if not syncing then window:SetTheme({Font = value}) end
    end)
    for _, font in ipairs(Enum.Font:GetEnumItems()) do
        if font.Name ~= "Unknown" then
            local option = controls.Font:Add(font.Name)
            option:SetAttribute("EleriumFontPreview", font.Name)
            option.Font = font
        end
    end
    local function sizeControl(key, title, minimum, maximum)
        controls[key] = tab:AddSlider(title, function(value)
            if not syncing then window:SetTheme({[key] = value}) end
        end, {min = minimum, max = maximum, commitOnRelease = true})
    end
    sizeControl("HeadingSize", "Heading size", 10, 30)
    sizeControl("LabelSize", "Label size", 10, 30)
    sizeControl("ControlSize", "Control text size", 10, 24)
    tab:AddHeading("Layout")
    sizeControl("Spacing", "Space between rows", 0, 20)
    local function sync(theme)
        syncing = true
        for _, key in ipairs({"MainColor", "BackgroundColor", "TextColor"}) do
            controls[key]:Set(theme[key])
        end
        controls.Font:SetValue(theme.Font.Name)
        for _, key in ipairs({"HeadingSize", "LabelSize", "ControlSize", "Spacing"}) do
            if not controls[key]:IsDragging() then controls[key]:Set(theme[key]) end
        end
        syncing = false
    end
    window:OnThemeChanged(function(theme)
        sync(theme)
        dirty = true
        saveVersion = saveVersion + 1
        local version = saveVersion
        runtime:Delay(0.3, function()
            if version ~= saveVersion then return end
            local ok, err = saveNow()
            if not ok then status.Text = tostring(err) end
        end)
    end)
    runtime:AddCleanup(function() saveNow() end)
    tab:AddButton("Reset appearance", function() window:ResetTheme(); status.Text = "Default appearance restored" end)
    tab:AddHeading("Preview heading")
    tab:AddLabel("A regular label")
    tab:AddLabel("Hello\nWorld")
    sync(window:GetTheme())
    controls.SaveAppearance = saveNow
    controls.SettingsPath = path
    return tab, controls, content
end
return Module
