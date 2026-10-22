--[[
    Silence - ML Loader
    by Henrik @xyzhenrik
]]

local LoaderSystem = {}
LoaderSystem.__index = LoaderSystem

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local function Create(className, properties, parent)
    local instance = Instance.new(className)

    for property, value in pairs(properties) do
        instance[property] = value
    end

    if parent then
        instance.Parent = parent
    end

    return instance
end

local UI_OPTIONS = {"Elerium", "WindUI"}
local UI_CONFIG_FOLDER = "Silence"
local UI_CONFIG_PATH = "Silence/MuscleLegendsUIPref.json"

local function isValidUI(name)
    return name == "Elerium" or name == "WindUI"
end

local function loadSavedUI()
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" and isValidUI(env.SilenceUILibrary) then
            return env.SilenceUILibrary
        end
    end

    if isValidUI(_G.SilenceUILibrary) then
        return _G.SilenceUILibrary
    end

    if type(readfile) ~= "function" or type(isfile) ~= "function" then
        return nil
    end

    local ok, content = pcall(function()
        if not isfile(UI_CONFIG_PATH) then return nil end
        return readfile(UI_CONFIG_PATH)
    end)

    if not ok or type(content) ~= "string" or content == "" then
        return nil
    end

    local decodeOk, decoded = pcall(function()
        return game:GetService("HttpService"):JSONDecode(content)
    end)

    if decodeOk and type(decoded) == "table" and isValidUI(decoded.library) then
        return decoded.library
    end

    -- fallback for plain-text saves
    return content:match("WindUI") or content:match("Elerium")
end

local function saveUI(name)
    if not isValidUI(name) then return end

    _G.SilenceUILibrary = name

    if type(getgenv) == "function" then
        pcall(function()
            getgenv().SilenceUILibrary = name
        end)
    end

    if type(writefile) ~= "function" then return end

    pcall(function()
        if type(makefolder) == "function" then
            pcall(makefolder, UI_CONFIG_FOLDER)
        end
        writefile(UI_CONFIG_PATH, game:GetService("HttpService"):JSONEncode({library = name}))
    end)
end



function LoaderSystem:CreateLoader(Config)
    local Title = "Silence | ML"
    local Description = Config.Description or "Choose your script..."
    local MainScriptURL = Config.MainScriptURL or "https://raw.githubusercontent.com/silencedevs/SilenceScripts/refs/heads/main/Scripts/MuscleLegends/Main.luau"
    local FastFarmingURL = Config.FastFarmingURL or "https://raw.githubusercontent.com/silencedevs/SilenceScripts/refs/heads/main/Scripts/MuscleLegends/Farming.luau"
    local WindScriptURL = Config.WindScriptURL or "https://raw.githubusercontent.com/silencedevs/SilenceScripts/refs/heads/main/Scripts/MuscleLegends/WindUIVersion.luau"
    local PurpleColor = Color3.fromRGB(226, 43, 43)
    local LightPurple = Color3.fromRGB(201, 0, 0)
    local DarkPurple = Color3.fromRGB(130, 0, 0)
    local AccentPurple = Color3.fromRGB(211, 0, 0)
    local NeonPurple = Color3.fromRGB(134, 0, 0)
    local DeepPurple = Color3.fromRGB(146, 0, 0)

    local LoaderGui = Create("ScreenGui", {
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        Name = "LoaderGui"
    }, RunService:IsStudio() and Player.PlayerGui or 
       (gethui and gethui() or game:GetService("CoreGui")))

    local BlurBackground = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(97, 0, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Name = "BlurBackground"
    }, LoaderGui)

    local BackgroundGradient = Create("UIGradient", {
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0.0, Color3.fromRGB(120, 0, 0)),
            ColorSequenceKeypoint.new(0.3, Color3.fromRGB(80, 0, 0)),
            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(40, 0, 0)),
            ColorSequenceKeypoint.new(1.0, Color3.fromRGB(0, 0, 0))
        },
        Rotation = 45
    }, BlurBackground)

    local bgGradientTween = TweenService:Create(
        BackgroundGradient,
        TweenInfo.new(8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Rotation = 225}
    )
    bgGradientTween:Play()

    for i = 1, 25 do
        local particleSize = math.random(1, 6)
        local particle = Create("Frame", {
            BackgroundColor3 = i <= 15 and PurpleColor or (i <= 20 and NeonPurple or LightPurple),
            BackgroundTransparency = math.random(70, 90) / 100,
            BorderSizePixel = 0,
            Size = UDim2.new(0, particleSize, 0, particleSize),
            Position = UDim2.new(math.random(0, 100) / 100, 0, math.random(0, 100) / 100, 0),
            Name = "Particle" .. i
        }, BlurBackground)

        Create("UICorner", {CornerRadius = UDim.new(1, 0)}, particle)

        if i <= 10 then
            local particleGlow = Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, 4, 1, 4),
                BackgroundColor3 = particle.BackgroundColor3,
                BackgroundTransparency = 0.9,
                BorderSizePixel = 0,
                ZIndex = particle.ZIndex - 1
            }, particle)
            Create("UICorner", {CornerRadius = UDim.new(1, 0)}, particleGlow)

            local glowTween = TweenService:Create(
                particleGlow,
                TweenInfo.new(math.random(2, 4), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                {BackgroundTransparency = 0.95, Size = UDim2.new(1, 8, 1, 8)}
            )
            glowTween:Play()
        end

        local floatSpeed = math.random(8, 30)
        local floatTween = TweenService:Create(
            particle,
            TweenInfo.new(floatSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {
                Position = UDim2.new(math.random(0, 100) / 100, 0, math.random(0, 100) / 100, 0),
                BackgroundTransparency = math.random(40, 95) / 100,
                Rotation = math.random(-180, 180)
            }
        )
        floatTween:Play()
    end

    local LoaderContainer = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 340, 0, 340),
        Name = "LoaderContainer"
    }, BlurBackground)

    Create("UICorner", {CornerRadius = UDim.new(0, 18)}, LoaderContainer)

    local BorderStroke = Create("UIStroke", {
        Color = PurpleColor,
        Thickness = 2.5,
        Transparency = 0.2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, LoaderContainer)

    for i = 1, 3 do
        local glowSize = 8 + (i * 4)
        local GlowFrame = Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, glowSize, 1, glowSize),
            BackgroundColor3 = i == 1 and PurpleColor or (i == 2 and NeonPurple or LightPurple),
            BackgroundTransparency = 0.8 + (i * 0.05),
            BorderSizePixel = 0,
            ZIndex = LoaderContainer.ZIndex - i
        }, BlurBackground)

        Create("UICorner", {CornerRadius = UDim.new(0, 22 + (i * 2))}, GlowFrame)

        local glowTween = TweenService:Create(
            GlowFrame,
            TweenInfo.new(2 + i, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {
                BackgroundTransparency = 0.95,
                Size = UDim2.new(1, glowSize + 8, 1, glowSize + 8)
            }
        )
        glowTween:Play()
    end

    local FooterFrame = Create("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 1, -35),
    Size = UDim2.new(1, 0, 0, 35),
    ZIndex = 1000,
    Name = "FooterFrame"
}, LoaderContainer)

local FooterLine = Create("Frame", {
    BackgroundColor3 = PurpleColor,
    BackgroundTransparency = 0.6,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 20, 0, 0),
    Size = UDim2.new(1, -40, 0, 1),
    ZIndex = 1001,
    Name = "FooterLine"
}, FooterFrame)

local FooterText = Create("TextLabel", {
    Font = Enum.Font.FredokaOne,
    Text = "Made with  ❤️  by Henne",
    TextColor3 = Color3.fromRGB(255, 0, 0),
    TextSize = 15,
    TextTransparency = 0,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 8),
    Size = UDim2.new(1, 0, 0, 20),
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 1002,
    Name = "FooterText"
}, FooterFrame)

local FooterGlow = Create("TextLabel", {
    Font = Enum.Font.FredokaOne,
    Text = "Made with  ❤️  by Henne",
    TextColor3 = Color3.fromRGB(255, 0, 0),
    TextTransparency = 0.85,
    TextSize = 15,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 1, 0, 9),
    Size = UDim2.new(1, 0, 0, 20),
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 1001,
    Name = "FooterGlow"
}, FooterFrame)

    local CloseButton = Create("TextButton", {
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 22,
        BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        BackgroundTransparency = 0,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -35, 0, 8),
        Size = UDim2.new(0, 28, 0, 28),
        Name = "CloseButton"
    }, LoaderContainer)

    Create("UICorner", {CornerRadius = UDim.new(0, 8)}, CloseButton)

    local CloseButtonGlow = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 6, 1, 6),
        BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        ZIndex = CloseButton.ZIndex - 1
    }, CloseButton)
    Create("UICorner", {CornerRadius = UDim.new(0, 12)}, CloseButtonGlow)

    local TitleLabel = Create("TextLabel", {
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 32,
        TextStrokeColor3 = Color3.fromRGB(226, 43, 43),
        TextStrokeTransparency = 0.3,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0, 35),
        Size = UDim2.new(0, 300, 0, 40),
        TextXAlignment = Enum.TextXAlignment.Center,
        Name = "TitleLabel"
    }, LoaderContainer)

    local TitleGradient = Create("UIGradient", {
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0.0, Color3.fromRGB(135, 0, 0)),
            ColorSequenceKeypoint.new(0.3, Color3.fromRGB(175, 0, 0)),
            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(215, 0, 0)),
            ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 0, 0))
        },
        Rotation = 45
    }, TitleLabel)

    local TitleShadow = Create("TextLabel", {
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = Color3.fromRGB(0, 0, 0),
        TextSize = 32,
        TextTransparency = 0.7,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 2, 0, 37),
        Size = UDim2.new(0, 300, 0, 40),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = TitleLabel.ZIndex - 1,
        Name = "TitleShadow"
    }, LoaderContainer)

    for i = 1, 3 do
        local TitleGlow = Create("Frame", {
            BackgroundColor3 = i == 1 and Color3.fromRGB(226, 43, 43) or (i == 2 and NeonPurple or LightPurple),
            BackgroundTransparency = 0.85 + (i * 0.03),
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0, 35),
            Size = UDim2.new(0, 180 + (i * 20), 0, 35 + (i * 5)),
            ZIndex = TitleLabel.ZIndex - (i + 1),
            Name = "TitleGlow" .. i
        }, LoaderContainer)

        Create("UICorner", {CornerRadius = UDim.new(0, 15 + i)}, TitleGlow)

        local titleGlowTween = TweenService:Create(
            TitleGlow,
            TweenInfo.new(1.5 + i, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {
                BackgroundTransparency = 0.7 + (i * 0.05),
                Size = UDim2.new(0, 200 + (i * 25), 0, 40 + (i * 8))
            }
        )
        titleGlowTween:Play()
    end

    local gradientTween = TweenService:Create(
        TitleGradient,
        TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false),
        {Rotation = 405}
    )
    gradientTween:Play()

    local function animateTitle()
        local cursorChar = "|"
        local blinkCursor = true

        local function blinkCursorAnimation()
            while LoaderGui.Parent and blinkCursor do
                TitleLabel.Text = TitleLabel.Text:gsub("|", "") .. cursorChar
                TitleShadow.Text = TitleLabel.Text
                wait(0.5)
                if blinkCursor then
                    TitleLabel.Text = TitleLabel.Text:gsub("|", "")
                    TitleShadow.Text = TitleLabel.Text
                    wait(0.5)
                end
            end
        end

        while LoaderGui.Parent do
            blinkCursor = false

            for i = 1, #Title do
                if not LoaderGui.Parent then break end

                local currentText = string.sub(Title, 1, i)
                TitleLabel.Text = currentText
                TitleShadow.Text = currentText

                TitleLabel.TextSize = 38
                TitleShadow.TextSize = 38
                TweenService:Create(TitleLabel, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextSize = 32}):Play()
                TweenService:Create(TitleShadow, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextSize = 32}):Play()

                local flashColors = {
                    Color3.fromRGB(255, 255, 255),
                    Color3.fromRGB(255, 200, 200),
                    Color3.fromRGB(200, 255, 255)
                }
                local originalColor = TitleLabel.TextStrokeColor3
                TitleLabel.TextStrokeColor3 = flashColors[math.random(1, 3)]
                TweenService:Create(TitleLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextStrokeColor3 = originalColor}):Play()

                TweenService:Create(BorderStroke, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {Color = NeonPurple, Transparency = 0.1}):Play()
                TweenService:Create(BorderStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Color = PurpleColor, Transparency = 0.2}):Play()

                wait(0.1)
            end

            blinkCursor = true
            spawn(blinkCursorAnimation)
            wait(3)
            blinkCursor = false

            for i = #Title, 0, -1 do
                if not LoaderGui.Parent then break end

                local currentText = string.sub(Title, 1, i)
                TitleLabel.Text = currentText
                TitleShadow.Text = currentText

                TitleLabel.TextSize = 34
                TitleShadow.TextSize = 34
                TweenService:Create(TitleLabel, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextSize = 32}):Play()
                TweenService:Create(TitleShadow, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextSize = 32}):Play()

                TweenService:Create(TitleLabel, TweenInfo.new(0.04, Enum.EasingStyle.Quad), {TextTransparency = 0.5}):Play()
                TweenService:Create(TitleLabel, TweenInfo.new(0.04, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()

                wait(0.05)
            end

            wait(1)
        end
    end

    spawn(animateTitle)

    for i = 1, 20 do
        local sparkleType = i <= 8 and 1 or (i <= 14 and 2 or 3)
        local sparkleSize = sparkleType == 1 and 2 or (sparkleType == 2 and 3 or 1)
        local sparkleColor = sparkleType == 1 and Color3.fromRGB(255, 255, 255) or 
                            (sparkleType == 2 and NeonPurple or LightPurple)

        local sparkle = Create("Frame", {
            BackgroundColor3 = sparkleColor,
            BackgroundTransparency = 0.6,
            BorderSizePixel = 0,
            Size = UDim2.new(0, sparkleSize, 0, sparkleSize),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, math.random(-120, 120), 0, 35 + math.random(-30, 30)),
            ZIndex = TitleLabel.ZIndex + 1,
            Name = "Sparkle" .. i
        }, LoaderContainer)

        if sparkleType == 3 then
            Create("UICorner", {CornerRadius = UDim.new(0, 1)}, sparkle) 
        else
            Create("UICorner", {CornerRadius = UDim.new(1, 0)}, sparkle) 
        end

        local sparkleSpeed = math.random(10, 40) / 10
        local sparkleTween = TweenService:Create(
            sparkle,
            TweenInfo.new(sparkleSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {
                BackgroundTransparency = 0.2,
                Size = UDim2.new(0, sparkleSize + 2, 0, sparkleSize + 2),
                Position = UDim2.new(0.5, math.random(-140, 140), 0, 35 + math.random(-35, 35)),
                Rotation = math.random(-360, 360)
            }
        )
        sparkleTween:Play()
    end

    local DescLabel = Create("TextLabel", {
        Font = Enum.Font.FredokaOne,
        Text = Description,
        TextColor3 = Color3.fromRGB(255, 0, 0),
        TextSize = 15,
        TextWrapped = true,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 75),
        Size = UDim2.new(1, -40, 0, 30),
        TextXAlignment = Enum.TextXAlignment.Center,
        Name = "DescLabel"
    }, LoaderContainer)

    local DescGlow = Create("TextLabel", {
        Font = Enum.Font.FredokaOne,
        Text = Description,
        TextColor3 = Color3.fromRGB(255, 120, 120),
        TextTransparency = 0.8,
        TextSize = 15,
        TextWrapped = true,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 21, 0, 76),
        Size = UDim2.new(1, -40, 0, 30),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = DescLabel.ZIndex - 1,
        Name = "DescGlow"
    }, LoaderContainer)

    local UISelectFrame = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 106),
        Size = UDim2.new(1, -40, 0, 46),
        Name = "UISelectFrame"
    }, LoaderContainer)

    Create("TextLabel", {
        Font = Enum.Font.FredokaOne,
        Text = "UI LIBRARY",
        TextColor3 = Color3.fromRGB(255, 120, 120),
        TextSize = 11,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 2, 0, 0),
        Size = UDim2.new(1, 0, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Left,
        Name = "UISelectLabel"
    }, UISelectFrame)

    local UIOptionButtons = {}
    local SelectedUI = loadSavedUI() or "Elerium"
    local updateButtonLayout

    local function styleUIOption(name)
        local option = UIOptionButtons[name]
        if not option then return end

        local active = name == SelectedUI

        TweenService:Create(option.Button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            BackgroundColor3 = active and LightPurple or Color3.fromRGB(26, 3, 3),
            BackgroundTransparency = active and 0 or 0.15,
            TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 70, 70)
        }):Play()

        TweenService:Create(option.Stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Color = active and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(90, 25, 25),
            Transparency = active and 0 or 0.55,
            Thickness = active and 1.5 or 1
        }):Play()

        TweenService:Create(option.Glow, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            BackgroundTransparency = active and 0.85 or 1
        }):Play()
    end

    local function selectUI(name)
        if SelectedUI == name then return end
        SelectedUI = name
        saveUI(name)
        for _, optionName in ipairs(UI_OPTIONS) do
            styleUIOption(optionName)
        end
        if updateButtonLayout then updateButtonLayout() end
    end

    for index, name in ipairs(UI_OPTIONS) do
        local gap = 8
        local isLeft = index == 1

        local optionButton = Create("TextButton", {
            Font = Enum.Font.FredokaOne,
            Text = name,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(160, 70, 70),
            BackgroundColor3 = Color3.fromRGB(26, 3, 3),
            BackgroundTransparency = 0.15,
            AutoButtonColor = false,
            BorderSizePixel = 0,
            Position = UDim2.new(isLeft and 0 or 0.5, isLeft and 0 or (gap / 2), 0, 16),
            Size = UDim2.new(0.5, -(gap / 2), 0, 30),
            Name = name .. "Option"
        }, UISelectFrame)

        Create("UICorner", {CornerRadius = UDim.new(0, 8)}, optionButton)

        local optionStroke = Create("UIStroke", {
            Color = Color3.fromRGB(90, 25, 25),
            Thickness = 1,
            Transparency = 0.55,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        }, optionButton)

        local optionGlow = Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, 6, 1, 6),
            BackgroundColor3 = LightPurple,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = optionButton.ZIndex - 1
        }, optionButton)
        Create("UICorner", {CornerRadius = UDim.new(0, 12)}, optionGlow)

        UIOptionButtons[name] = {
            Button = optionButton,
            Stroke = optionStroke,
            Glow = optionGlow
        }

        optionButton.Activated:Connect(function()
            selectUI(name)
        end)

        optionButton.MouseEnter:Connect(function()
            if SelectedUI == name then return end
            TweenService:Create(optionButton, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                BackgroundColor3 = Color3.fromRGB(55, 8, 8),
                TextColor3 = Color3.fromRGB(255, 190, 190)
            }):Play()
        end)

        optionButton.MouseLeave:Connect(function()
            styleUIOption(name)
        end)
    end

    for _, optionName in ipairs(UI_OPTIONS) do
        styleUIOption(optionName)
    end

    local ButtonsFrame = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 164),
        Size = UDim2.new(1, -40, 0, 120),
        Name = "ButtonsFrame"
    }, LoaderContainer)

    local function createEnhancedButton(properties, parent)
        local button = Create("TextButton", properties, parent)
        Create("UICorner", {CornerRadius = UDim.new(0, 10)}, button)

        local buttonGlow = Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, 4, 1, 4),
            BackgroundColor3 = properties.BackgroundColor3,
            BackgroundTransparency = 0.9,
            BorderSizePixel = 0,
            ZIndex = button.ZIndex - 1
        }, button)
        Create("UICorner", {CornerRadius = UDim.new(0, 12)}, buttonGlow)

        return button, buttonGlow
    end

    local MainScriptButton, MainScriptGlow = createEnhancedButton({
        Font = Enum.Font.FredokaOne,
        Text = "Main Script (All Features)",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        BackgroundColor3 = LightPurple,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 50),
        Name = "MainScriptButton"
    }, ButtonsFrame)

    local FastFarmingButton, FastFarmingGlow = createEnhancedButton({
        Font = Enum.Font.FredokaOne,
        Text = "Fast Farming (Rep Pets only!)",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        BackgroundColor3 = DarkPurple,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 60),
        Size = UDim2.new(1, 0, 0, 50),
        Name = "FastFarmingButton"
    }, ButtonsFrame)

    local WindScriptButton, WindScriptGlow = createEnhancedButton({
        Font = Enum.Font.FredokaOne,
        Text = "Full Script (WindUI)",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        BackgroundColor3 = AccentPurple,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 35),
        Size = UDim2.new(1, 0, 0, 50),
        Visible = false,
        Name = "WindScriptButton"
    }, ButtonsFrame)

    function updateButtonLayout()
        local useWindUI = SelectedUI == "WindUI"
        MainScriptButton.Visible = not useWindUI
        FastFarmingButton.Visible = not useWindUI
        WindScriptButton.Visible = useWindUI
    end

    updateButtonLayout()

    local function addEnhancedHoverEffect(button, buttonGlow, hoverColor, originalColor)
        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                BackgroundColor3 = hoverColor,
                Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset, button.Size.Y.Scale, button.Size.Y.Offset + 3),
                TextSize = button.TextSize + 1
            }):Play()
            TweenService:Create(buttonGlow, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                BackgroundTransparency = 0.7,
                Size = UDim2.new(1, 8, 1, 8)
            }):Play()
        end)

        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                BackgroundColor3 = originalColor,
                Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset, button.Size.Y.Scale, button.Size.Y.Offset - 3),
                TextSize = button.TextSize - 1
            }):Play()
            TweenService:Create(buttonGlow, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                BackgroundTransparency = 0.9,
                Size = UDim2.new(1, 4, 1, 4)
            }):Play()
        end)
    end

    addEnhancedHoverEffect(MainScriptButton, MainScriptGlow, Color3.fromRGB(255, 0, 0), LightPurple)
    addEnhancedHoverEffect(FastFarmingButton, FastFarmingGlow, Color3.fromRGB(150, 15, 15), DarkPurple)
    addEnhancedHoverEffect(WindScriptButton, WindScriptGlow, Color3.fromRGB(255, 60, 60), AccentPurple)

    MainScriptButton.Activated:Connect(function()
        saveUI(SelectedUI)
        script = Instance.new("LocalScript")
        script.Name = "SilenceRuntime"
        LoaderGui:Destroy()
        loadstring(game:HttpGet(MainScriptURL))()
    end)

    FastFarmingButton.Activated:Connect(function()
        saveUI(SelectedUI)
        script = Instance.new("LocalScript")
        script.Name = "SilenceRuntime"
        LoaderGui:Destroy()
        loadstring(game:HttpGet(FastFarmingURL))()
    end)

    WindScriptButton.Activated:Connect(function()
        saveUI(SelectedUI)
        script = Instance.new("LocalScript")
        script.Name = "SilenceRuntime"
        LoaderGui:Destroy()
        loadstring(game:HttpGet(WindScriptURL))()
    end)

    CloseButton.Activated:Connect(function()
        TweenService:Create(LoaderContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0), 
            BackgroundTransparency = 1,
            Rotation = 180
        }):Play()
        TweenService:Create(BlurBackground, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
        wait(0.6)
        LoaderGui:Destroy()
    end)

    LoaderContainer.Size = UDim2.new(0, 0, 0, 0)
    LoaderContainer.BackgroundTransparency = 1
    LoaderContainer.Rotation = -180

    TweenService:Create(LoaderContainer, TweenInfo.new(1.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 340, 0, 340),
        BackgroundTransparency = 0,
        Rotation = 0
    }):Play()

    local elements = {TitleLabel, DescLabel, UISelectFrame, ButtonsFrame}
    for i, element in pairs(elements) do
        element.Position = element.Position + UDim2.new(0, 0, 0, 50)
        element.Rotation = math.random(-45, 45)

        TweenService:Create(element, TweenInfo.new(0.8 + (i * 0.1), Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = element.Position - UDim2.new(0, 0, 0, 50),
            Rotation = 0
        }):Play()
    end

    return LoaderGui
end

LoaderSystem:CreateLoader({
    Description = "Choose your script to execute"
})

return LoaderSystem

