--[[
    Silence - Loader
    by Havoc @seancode4life
       Henne @xyzhenrik_
]]
local KeySystem = {}
KeySystem.__index = KeySystem

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local isVerifying = false
local lastClickTime = 0
local clickCooldown = 1

local function ValidateKey(inputKey, validKeys)
    for _, validKey in pairs(validKeys) do
        if inputKey == validKey then
            return true
        end
    end
    return false
end

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

function KeySystem:CreateKeySystem(Config)
    local Title = "Silence"
    local Description = Config.Description or "Input Key..."
    local Keys = Config.Keys or {"", "", ""}
    local MainScriptCallback = Config.MainScriptCallback or function(success) end
    local SaveKey = Config.SaveKey == true
    local KeyFileName = Config.KeyFileName or "SilenceKey.txt"

    if SaveKey and type(isfile) == "function" and type(readfile) == "function" then
        local readSuccess, savedKey = pcall(function()
            if isfile(KeyFileName) then
                return readfile(KeyFileName)
            end
        end)

        if readSuccess and savedKey and ValidateKey(savedKey, Keys) then
            MainScriptCallback(true)
            return
        end
    end

    local PurpleColor = Color3.fromRGB(221, 0, 0)
    local LightPurple = Color3.fromRGB(201, 0, 0)
    local DarkPurple = Color3.fromRGB(130, 0, 0)
    local AccentPurple = Color3.fromRGB(211, 0, 0)
    local NeonPurple = Color3.fromRGB(183, 6, 6)


    local KeySystemGui = Create("ScreenGui", {
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        Name = "KeySystemGui"
    }, RunService:IsStudio() and Player.PlayerGui or 
       (gethui and gethui() or game:GetService("CoreGui")))

    local BlurBackground = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(20, 10, 35),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Name = "BlurBackground"
    }, KeySystemGui)

    local BackgroundGradient = Create("UIGradient", {
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0.0, Color3.fromRGB(135, 0, 0)),
            ColorSequenceKeypoint.new(0.3, Color3.fromRGB(116, 0, 0)),
            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(103, 0, 0)),
            ColorSequenceKeypoint.new(1.0, Color3.fromRGB(85, 0, 0))
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

    local KeyContainer = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 340, 0, 310),
        Name = "KeyContainer"
    }, BlurBackground)

    Create("UICorner", {CornerRadius = UDim.new(0, 18)}, KeyContainer)

    local BorderStroke = Create("UIStroke", {
        Color = PurpleColor,
        Thickness = 2.5,
        Transparency = 0.2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, KeyContainer)

    for i = 1, 3 do
        local glowSize = 8 + (i * 4)
        local GlowFrame = Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, glowSize, 1, glowSize),
            BackgroundColor3 = i == 1 and PurpleColor or (i == 2 and NeonPurple or LightPurple),
            BackgroundTransparency = 0.8 + (i * 0.05),
            BorderSizePixel = 0,
            ZIndex = KeyContainer.ZIndex - i
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

    local CloseButton = Create("TextButton", {
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 22,
        BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -35, 0, 8),
        Size = UDim2.new(0, 28, 0, 28),
        Name = "CloseButton"
    }, KeyContainer)

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
        TextStrokeColor3 = Color3.fromRGB(255, 0, 0),
        TextStrokeTransparency = 0.3,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0, 35),
        Size = UDim2.new(0, 300, 0, 40),
        TextXAlignment = Enum.TextXAlignment.Center,
        Name = "TitleLabel"
    }, KeyContainer)

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
    }, KeyContainer)

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
        }, KeyContainer)

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
            while KeySystemGui.Parent and blinkCursor do
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

        while KeySystemGui.Parent do
            blinkCursor = false

            for i = 1, #Title do
                if not KeySystemGui.Parent then break end

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
                if not KeySystemGui.Parent then break end

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
        }, KeyContainer)

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
        Font = Enum.Font.Gotham,
        Text = Description,
        TextColor3 = Color3.fromRGB(220, 200, 255),
        TextSize = 15,
        TextWrapped = true,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 65),
        Size = UDim2.new(1, -40, 0, 30),
        TextXAlignment = Enum.TextXAlignment.Center,
        Name = "DescLabel"
    }, KeyContainer)

    local DescGlow = Create("TextLabel", {
        Font = Enum.Font.Gotham,
        Text = Description,
        TextColor3 = Color3.fromRGB(255, 120, 120),
        TextTransparency = 0.8,
        TextSize = 15,
        TextWrapped = true,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 21, 0, 66),
        Size = UDim2.new(1, -40, 0, 30),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = DescLabel.ZIndex - 1,
        Name = "DescGlow"
    }, KeyContainer)

    local InputFrame = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(70, 35, 35),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 20, 0, 110), 
        Size = UDim2.new(1, -40, 0, 45),
        Name = "InputFrame"
    }, KeyContainer) 

    Create("UICorner", {CornerRadius = UDim.new(0, 12)}, InputFrame)

    local InputStroke = Create("UIStroke", {
        Color = Color3.fromRGB(138, 0, 0),
        Thickness = 1.5,
        Transparency = 0.4
    }, InputFrame)

    local InputGlow = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 4, 1, 4),
        BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        ZIndex = InputFrame.ZIndex - 1
    }, InputFrame)
    Create("UICorner", {CornerRadius = UDim.new(0, 14)}, InputGlow)

    local KeyInput = Create("TextBox", {
        Font = Enum.Font.Gotham,
        PlaceholderText = "Enter the Key...",
        PlaceholderColor3 = Color3.fromRGB(201, 0, 0),
        Text = "",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(1, -30, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Name = "KeyInput"
    }, InputFrame)

    KeyInput.Focused:Connect(function()
        TweenService:Create(InputStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Color = NeonPurple, Transparency = 0.1, Thickness = 3}):Play()
        TweenService:Create(InputFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(1, -32, 0, 50)}):Play()
        TweenService:Create(InputGlow, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.7, Size = UDim2.new(1, 8, 1, 8)}):Play()
    end)

    KeyInput.FocusLost:Connect(function()
        TweenService:Create(InputStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Color = Color3.fromRGB(201, 0, 0), Transparency = 0.4, Thickness = 1.5}):Play()
        TweenService:Create(InputFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(1, -40, 0, 45)}):Play()
        TweenService:Create(InputGlow, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.9, Size = UDim2.new(1, 4, 1, 4)}):Play()
    end)

    local ButtonsFrame = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 170),
        Size = UDim2.new(1, -40, 0, 77),
        Name = "ButtonsFrame"
    }, KeyContainer)

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

    local function showNotification(text)
        local NotificationGui = Create("ScreenGui", {
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            IgnoreGuiInset = true,
            Name = "NotificationGui"
        }, RunService:IsStudio() and Player.PlayerGui or 
           (gethui and gethui() or game:GetService("CoreGui")))

        local Notification = Create("Frame", {
            BackgroundColor3 = Color3.fromRGB(50, 20, 20),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            Position = UDim2.new(1, 20, 1, -80),
            Size = UDim2.new(0, 280, 0, 60),
            Name = "Notification"
        }, NotificationGui)

        Create("UICorner", {CornerRadius = UDim.new(0, 12)}, Notification)

        local NotificationStroke = Create("UIStroke", {
            Color = PurpleColor,
            Thickness = 2,
            Transparency = 0.3,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        }, Notification)

        local NotificationGlow = Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, 6, 1, 6),
            BackgroundColor3 = PurpleColor,
            BackgroundTransparency = 0.85,
            BorderSizePixel = 0,
            ZIndex = Notification.ZIndex - 1
        }, Notification)
        Create("UICorner", {CornerRadius = UDim.new(0, 14)}, NotificationGlow)

        local NotificationText = Create("TextLabel", {
            Font = Enum.Font.GothamBold,
            Text = text,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 14,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 15, 0, 0),
            Size = UDim2.new(1, -30, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            Name = "NotificationText"
        }, Notification)

        TweenService:Create(Notification, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, -300, 1, -80)
        }):Play()

        TweenService:Create(NotificationStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Color = NeonPurple,
            Transparency = 0.1
        }):Play()

        wait(2.5)

        TweenService:Create(Notification, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 20, 1, -80)
        }):Play()

        wait(0.5)
        NotificationGui:Destroy()
    end

    local GetKeyButton, GetKeyGlow = createEnhancedButton({
        Font = Enum.Font.GothamBold,
        Text = "Get Key (Discord)",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 16,
        BackgroundColor3 = AccentPurple,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 35),
        Name = "GetKeyButton"
    }, ButtonsFrame)

    GetKeyButton.Activated:Connect(function()
        local discordLink = "https://discord.gg/9eFf93Kg8D"
        if setclipboard then
            setclipboard(discordLink)
            showNotification("Discord Invite Copied")
        end
    end)

    local MainScript, MainGlow = createEnhancedButton({
        Font = Enum.Font.GothamBold,
        Text = "Execute Silence",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 16,
        BackgroundColor3 = DarkPurple,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 42),
        Size = UDim2.new(1, 0, 0, 35),
        Name = "MainScript"
    }, ButtonsFrame)

    local FooterLabel = Create("TextLabel", {
        Font = Enum.Font.GothamBold,
        Text = "Made with ♥️ by the Silence Team",
        TextColor3 = Color3.fromRGB(255, 0, 0),
        TextSize = 14,
        TextTransparency = 0.3,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 1, -30),
        Size = UDim2.new(1, 0, 0, 25),
        TextXAlignment = Enum.TextXAlignment.Center,
        Name = "FooterLabel"
    }, KeyContainer)

    local FooterGradient = Create("UIGradient", {
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 0, 0)),
            ColorSequenceKeypoint.new(1.0, Color3.fromRGB(185, 0, 0))
        },
        Rotation = 0
    }, FooterLabel)

    local footerGradientTween = TweenService:Create(
        FooterGradient,
        TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false),
        {Rotation = 360}
    )
    footerGradientTween:Play()

    local StatusLabel = Create("TextLabel", {
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = Color3.fromRGB(255, 150, 150),
        TextSize = 14,
        BackgroundColor3 = Color3.fromRGB(50, 30, 30),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 20, 0, 252),
        Size = UDim2.new(1, -40, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Center,
        Visible = false,
        Name = "StatusLabel"
    }, KeyContainer)

    Create("UICorner", {CornerRadius = UDim.new(0, 6)}, StatusLabel)

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

    addEnhancedHoverEffect(GetKeyButton, GetKeyGlow, Color3.fromRGB(231, 10, 10), AccentPurple)
    addEnhancedHoverEffect(MainScript, MainGlow, Color3.fromRGB(150, 15, 15), DarkPurple)

    local function playSuccessAnimation()

        local ScreenFlash = Create("Frame", {
            BackgroundColor3 = Color3.fromRGB(255, 50, 50),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            Name = "ScreenFlash"
        }, BlurBackground)

        TweenService:Create(ScreenFlash, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.8}):Play()
        TweenService:Create(ScreenFlash, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()

        local SuccessOverlay = Create("Frame", {
            BackgroundColor3 = Color3.fromRGB(255, 50, 50),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            Name = "SuccessOverlay"
        }, KeyContainer)

        Create("UICorner", {CornerRadius = UDim.new(0, 18)}, SuccessOverlay)

        for i = 1, 3 do
            local CheckMark = Create("TextLabel", {
                Font = Enum.Font.GothamBold,
                Text = "✓",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextTransparency = i == 1 and 0 or 0.5,
                TextSize = 80 + (i * 5),
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, (i-1) * 2, 0.5, (i-1) * 2),
                Size = UDim2.new(0, 100, 0, 100),
                TextScaled = true,
                ZIndex = 10 - i,
                Name = "CheckMark" .. i
            }, SuccessOverlay)

            CheckMark.Size = UDim2.new(0, 0, 0, 0)
            TweenService:Create(CheckMark, TweenInfo.new(0.8 + (i * 0.1), Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 100, 0, 100)
            }):Play()
        end

        local SuccessText = Create("TextLabel", {
            Font = Enum.Font.GothamBold,
            Text = "ACCESS GRANTED!",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 20,
            TextTransparency = 1,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0.7, 0),
            Size = UDim2.new(1, 0, 0, 30),
            TextXAlignment = Enum.TextXAlignment.Center,
            Name = "SuccessText"
        }, SuccessOverlay)

        TweenService:Create(SuccessOverlay, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.1}):Play()

        wait(0.3)
        TweenService:Create(SuccessText, TweenInfo.new(0.5, Enum.EasingStyle.Back), {TextTransparency = 0, TextSize = 22}):Play()

        TweenService:Create(BorderStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Color = Color3.fromRGB(255, 50, 50), Thickness = 4}):Play()

        for i = 1, 40 do
            local successParticle = Create("Frame", {
                BackgroundColor3 = i <= 20 and Color3.fromRGB(255, 50, 50) or (i <= 30 and NeonPurple or Color3.fromRGB(255, 255, 255)),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Size = UDim2.new(0, math.random(2, 12), 0, math.random(2, 12)),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Name = "SuccessParticle" .. i
            }, KeyContainer)

            Create("UICorner", {CornerRadius = UDim.new(math.random(0, 1), 0)}, successParticle)

            local randomX = math.random(-300, 300)
            local randomY = math.random(-300, 300)
            local randomTime = math.random(15, 35) / 10

            TweenService:Create(successParticle, TweenInfo.new(randomTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.5, randomX, 0.5, randomY),
                BackgroundTransparency = 1,
                Rotation = math.random(-720, 720),
                Size = UDim2.new(0, 0, 0, 0)
            }):Play()

            spawn(function()
                wait(randomTime)
                successParticle:Destroy()
            end)
        end

        wait(0.5)
        spawn(function()
            wait(2)
            ScreenFlash:Destroy()
        end)
    end

    local function verifyKey(scriptType)
        local currentTime = tick()

        if isVerifying then
            StatusLabel.Text = "⏳ Please wait before trying again!"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
            StatusLabel.BackgroundColor3 = Color3.fromRGB(45, 20, 20)
            StatusLabel.BackgroundTransparency = 1
            StatusLabel.Visible = true

            wait(1)
            StatusLabel.Visible = false
            return
        end

        if currentTime - lastClickTime < clickCooldown then
            StatusLabel.Text = "⚠️ Too fast! Slow down."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 217, 0)
            StatusLabel.BackgroundColor3 = Color3.fromRGB(45, 20, 20)
            StatusLabel.BackgroundTransparency = 1
            StatusLabel.Visible = true

            local originalContainerPos = KeyContainer.Position
            for i = 1, 4 do
                KeyContainer.Position = originalContainerPos + UDim2.new(0, (i % 2 == 0 and 5 or -5), 0, 0)
                wait(0.05)
            end
            KeyContainer.Position = originalContainerPos

            wait(1.5)
            StatusLabel.Visible = false
            return
        end

        isVerifying = true
        lastClickTime = currentTime

        local inputKey = KeyInput.Text

        if inputKey == "" then
            StatusLabel.Text = "⚠️ Please enter a key!"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 217, 0)
            StatusLabel.BackgroundColor3 = Color3.fromRGB(45, 20, 20)
            StatusLabel.BackgroundTransparency = 1
            StatusLabel.Visible = true

            local originalInputPos = InputFrame.Position
            for i = 1, 8 do
                InputFrame.Position = originalInputPos + UDim2.new(0, (i % 2 == 0 and 10 or -10), 0, 0)
                wait(0.06)
            end
            InputFrame.Position = originalInputPos

            wait(2)
            StatusLabel.Visible = false
            isVerifying = false
            return
        end

        if ValidateKey(inputKey, Keys) then
            StatusLabel.Text = "✅ Key Valid - Loading " .. scriptType .. "..."
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 21)
            StatusLabel.BackgroundColor3 = Color3.fromRGB(45, 20, 20)
            StatusLabel.BackgroundTransparency = 1
            StatusLabel.Visible = true

            if SaveKey and type(writefile) == "function" then
                pcall(writefile, KeyFileName, inputKey)
            end

            playSuccessAnimation()

            wait(2.5)
            KeySystemGui:Destroy()

            MainScriptCallback(true)
        else
            StatusLabel.Text = "❌ Key Invalid - Try again!"
            StatusLabel.TextColor3 = Color3.fromRGB(230, 7, 7)
            StatusLabel.BackgroundColor3 = Color3.fromRGB(45, 20, 20)
            StatusLabel.BackgroundTransparency = 1
            StatusLabel.Visible = true

            local originalContainerPos = KeyContainer.Position
            for i = 1, 12 do
                KeyContainer.Position = originalContainerPos + UDim2.new(0, (i % 2 == 0 and 15 or -15), 0, 0)
                wait(0.04)
            end
            KeyContainer.Position = originalContainerPos

            TweenService:Create(BorderStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Color = Color3.fromRGB(255, 0, 0), Thickness = 4}):Play()
            TweenService:Create(BorderStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Color = Color3.fromRGB(255, 120, 120), Thickness = 3}):Play()
            wait(0.5)
            TweenService:Create(BorderStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Color = PurpleColor, Thickness = 2.5}):Play()

            KeyInput.Text = ""
            wait(2)
            StatusLabel.Visible = false
        end

        isVerifying = false
    end
    MainScript.Activated:Connect(function()
        verifyKey("Main Script")
    end)
    CloseButton.Activated:Connect(function()
        TweenService:Create(KeyContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0), 
            BackgroundTransparency = 1,
            Rotation = 180
        }):Play()
        TweenService:Create(BlurBackground, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
        wait(0.6)
        KeySystemGui:Destroy()
    end)

    KeyContainer.Size = UDim2.new(0, 0, 0, 0)
    KeyContainer.BackgroundTransparency = 1
    KeyContainer.Rotation = -180

    TweenService:Create(KeyContainer, TweenInfo.new(1.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 340, 0, 310),
        BackgroundTransparency = 0,
        Rotation = 0
    }):Play()

    local elements = {TitleLabel, DescLabel, InputFrame, ButtonsFrame, FooterLabel}
    for i, element in pairs(elements) do
        element.Position = element.Position + UDim2.new(0, 0, 0, 50)
        element.BackgroundTransparency = 1
        element.Rotation = math.random(-45, 45)

        TweenService:Create(element, TweenInfo.new(0.8 + (i * 0.1), Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = element.Position - UDim2.new(0, 0, 0, 50),
            Rotation = 0
        }):Play()

        if element.BackgroundTransparency then
            TweenService:Create(element, TweenInfo.new(0.6 + (i * 0.1), Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = element.BackgroundTransparency
            }):Play()
        end
    end

    return KeySystemGui
end

KeySystem:CreateKeySystem({
    Description = "",
    Keys = {"sot", "SilenceOnTop", "SOT"},
    SaveKey = true,
    MainScriptCallback = function(success)
        if success then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/silencedevs/SilenceScripts/refs/heads/main/Loader/Supported.luau"))()

            getgenv().Get = setmetatable({}, {
                __index = function(_, serviceName)
                    return game:GetService(serviceName)
                end
            })

            local scriptUrl = supported[game.PlaceId]
            if scriptUrl then
                loadstring(game:HttpGet(scriptUrl))()
            else
                warn("[Silence]: Game not supported.")
            end
    end
end})
