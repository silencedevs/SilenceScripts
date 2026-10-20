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
    tab:AddHeading("Layout")
    controls.WindowScale = tab:AddSlider("Window Size (%)", function(value)
        if not syncing then window:SetTheme({WindowScale = value / 100}) end
    end, {min = 50, max = 150, step = 1, commitOnRelease = true})
    local function sync(theme)
        syncing = true
        for _, key in ipairs({"MainColor", "BackgroundColor", "TextColor"}) do
            controls[key]:Set(theme[key])
        end
        controls.Font:SetValue(theme.Font.Name)
        if not controls.WindowScale:IsDragging() then controls.WindowScale:Set(theme.WindowScale * 100) end
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
    if not window.CustomizePreferencesLoaded and not savedLoadError then
        runtime:Spawn(function()
            -- Let startup profiles apply before saving the initial appearance
            for _ = 1, 3 do game:GetService("RunService").Heartbeat:Wait() end
            dirty = true
            local ok, err = saveNow()
            if not ok then status.Text = tostring(err) end
        end)
    end
    controls.SaveAppearance = saveNow
    controls.SettingsPath = path
    return tab, controls, content
end
return Module
