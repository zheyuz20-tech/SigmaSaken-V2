--[[
 SIGMASAKEN V2 | ALPHA 0.6
 Rounded animated UI for touch screens
 Loading / Sections / Drag / Resize / Floating launcher
 Player and Visuals settings are interface demonstrations only.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remove older copies when this script is executed again.
for _, name in ipairs({"SigmaSakenV2", "SigmaSakenV2Launcher"}) do
    local old = playerGui:FindFirstChild(name)
    if old then old:Destroy() end
end

local P = {
    bg = Color3.fromRGB(8, 8, 14),
    side = Color3.fromRGB(13, 12, 21),
    card = Color3.fromRGB(25, 23, 38),
    card2 = Color3.fromRGB(32, 28, 49),
    dim = Color3.fromRGB(43, 39, 58),
    purple = Color3.fromRGB(173, 91, 255),
    light = Color3.fromRGB(220, 175, 255),
    dark = Color3.fromRGB(83, 38, 135),
    white = Color3.fromRGB(250, 247, 255),
    muted = Color3.fromRGB(150, 145, 171)
}

local settings = {
    Animations = true,
    Glow = true,
    Sprint = false,
    Stamina = false,
    Speed = false,
    ESP = false,
    Names = false,
    Distance = false
}

local connections = {}
local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections, c)
    return c
end

local function make(class, parent, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local function rounded(obj, radius)
    return make("UICorner", obj, {CornerRadius = UDim.new(0, radius)})
end

local function outline(obj, color, thickness, transparency)
    return make("UIStroke", obj, {
        Color = color or P.dark,
        Thickness = thickness or 1,
        Transparency = transparency or 0.45
    })
end

local function label(parent, value, size, bold, color)
    return make("TextLabel", parent, {
        BackgroundTransparency = 1,
        Text = value,
        TextSize = size,
        TextColor3 = color or P.white,
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true
    })
end

local function tween(obj, duration, props, style)
    if not settings.Animations then
        for k, v in pairs(props) do obj[k] = v end
        return nil
    end
    local t = TweenService:Create(obj, TweenInfo.new(
        duration, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out
    ), props)
    t:Play()
    return t
end

local function pressEffect(button)
    local scale = make("UIScale", button, {Scale = 1})
    connect(button.MouseButton1Down, function()
        tween(scale, 0.12, {Scale = 0.96})
    end)
    connect(button.MouseButton1Up, function()
        tween(scale, 0.22, {Scale = 1}, Enum.EasingStyle.Back)
    end)
    connect(button.MouseLeave, function()
        tween(scale, 0.22, {Scale = 1})
    end)
end

local mainGui = make("ScreenGui", playerGui, {
    Name = "SigmaSakenV2", ResetOnSpawn = false,
    IgnoreGuiInset = true, DisplayOrder = 400,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})
local launcherGui = make("ScreenGui", playerGui, {
    Name = "SigmaSakenV2Launcher", ResetOnSpawn = false,
    IgnoreGuiInset = true, DisplayOrder = 401,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

connect(mainGui.Destroying, function()
    for _, c in ipairs(connections) do
        if c.Connected then c:Disconnect() end
    end
    if launcherGui.Parent then launcherGui:Destroy() end
end)

-- LOADING: 2 seconds.
local loading = make("Frame", mainGui, {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(320, 185),
    BackgroundColor3 = P.bg
})
rounded(loading, 26)
outline(loading, P.purple, 1.3, 0.5)
local loadingScale = make("UIScale", loading, {Scale = 0.78})
local lt = label(loading, "✦  SIGMASAKEN V2", 22, true, P.light)
lt.Position = UDim2.fromOffset(23, 25)
lt.Size = UDim2.new(1, -46, 0, 44)
local ls = label(loading, "PREPARING UI... 0%", 12, true, P.muted)
ls.Position = UDim2.fromOffset(23, 79)
ls.Size = UDim2.new(1, -46, 0, 25)
local barTrack = make("Frame", loading, {
    Position = UDim2.fromOffset(23, 127),
    Size = UDim2.new(1, -46, 0, 12),
    BackgroundColor3 = P.dim, ClipsDescendants = true
})
rounded(barTrack, 12)
local bar = make("Frame", barTrack, {
    Size = UDim2.fromScale(0, 1), BackgroundColor3 = P.purple
})
rounded(bar, 12)
make("UIGradient", bar, {
    Color = ColorSequence.new(P.purple, P.light)
})

-- FLOATING LAUNCHER: own ScreenGui, always above the menu.
local floating = make("TextButton", launcherGui, {
    Name = "OpenCloseButton", AnchorPoint = Vector2.new(0, 0),
    Position = UDim2.fromOffset(18, 270),
    Size = UDim2.fromOffset(62, 62),
    BackgroundColor3 = P.bg,
    Text = "Σ", TextSize = 31, Font = Enum.Font.GothamBold,
    TextColor3 = P.light, AutoButtonColor = false,
    Visible = false
})
rounded(floating, 100)
local floatRing = outline(floating, P.purple, 2.2, 0.12)
local floatScale = make("UIScale", floating, {Scale = 1})
local floatGlow = make("Frame", floating, {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(51, 51),
    BackgroundTransparency = 1,
    ZIndex = 0
})
rounded(floatGlow, 100)
local glowRing = outline(floatGlow, P.light, 1.1, 0.7)
TweenService:Create(floatRing, TweenInfo.new(
    1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true
), {Transparency = 0.65}):Play()
TweenService:Create(glowRing, TweenInfo.new(
    2.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true
), {Transparency = 0.1}):Play()

-- MAIN WINDOW.
local camera = workspace.CurrentCamera
local viewport = camera and camera.ViewportSize or Vector2.new(1024, 768)
local initialW = math.floor(math.min(640, viewport.X - 32))
local initialH = math.floor(math.min(440, viewport.Y - 40))

local main = make("Frame", mainGui, {
    Name = "MainWindow",
    Position = UDim2.fromOffset(
        math.floor((viewport.X - initialW) / 2),
        math.floor((viewport.Y - initialH) / 2)
    ),
    Size = UDim2.fromOffset(initialW, initialH),
    BackgroundColor3 = P.bg,
    ClipsDescendants = true, Visible = false
})
rounded(main, 27)
local mainStroke = outline(main, P.purple, 1.4, 0.52)
local mainScale = make("UIScale", main, {Scale = 1})
make("UIGradient", main, {
    Rotation = 30,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, P.bg),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 13, 29))
    })
})

-- Subtle animated accent strip.
local accentStrip = make("Frame", main, {
    Position = UDim2.new(0, 0, 0, 0),
    Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = P.purple,
    ZIndex = 5
})
local stripGradient = make("UIGradient", accentStrip, {
    Rotation = 0,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, P.dark),
        ColorSequenceKeypoint.new(0.5, P.light),
        ColorSequenceKeypoint.new(1, P.dark)
    })
})
TweenService:Create(stripGradient, TweenInfo.new(
    7, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1
), {Rotation = 360}):Play()

local sideW = 152
local sidebar = make("Frame", main, {
    Size = UDim2.new(0, sideW, 1, 0), BackgroundColor3 = P.side
})
local logoCircle = make("Frame", sidebar, {
    Position = UDim2.fromOffset(17, 22),
    Size = UDim2.fromOffset(38, 38), BackgroundColor3 = P.dark
})
rounded(logoCircle, 100)
local logoSymbol = label(logoCircle, "Σ", 25, true, P.light)
logoSymbol.Size = UDim2.fromScale(1, 1)
logoSymbol.TextXAlignment = Enum.TextXAlignment.Center
local logoName = label(sidebar, "SIGMA", 18, true, P.light)
logoName.Position = UDim2.fromOffset(63, 23)
logoName.Size = UDim2.new(1, -66, 0, 34)
local subname = label(sidebar, "SAKEN V2", 10, true, P.muted)
subname.Position = UDim2.fromOffset(20, 69)
subname.Size = UDim2.new(1, -28, 0, 22)

local nav = make("Frame", sidebar, {
    Position = UDim2.fromOffset(11, 118),
    Size = UDim2.new(1, -22, 1, -180),
    BackgroundTransparency = 1
})
make("UIListLayout", nav, {
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder
})
local build = label(sidebar, "ALPHA 0.6  •  MOBILE", 10, false, P.muted)
build.Position = UDim2.new(0, 17, 1, -40)
build.Size = UDim2.new(1, -20, 0, 24)

local content = make("Frame", main, {
    Position = UDim2.fromOffset(sideW, 0),
    Size = UDim2.new(1, -sideW, 1, 0),
    BackgroundTransparency = 1
})
local header = make("Frame", content, {
    Size = UDim2.new(1, 0, 0, 76),
    BackgroundTransparency = 1
})
local dragBar = make("Frame", header, {
    Size = UDim2.new(1, -114, 1, 0),
    BackgroundTransparency = 1, Active = true
})
local heading = label(dragBar, "Dashboard", 23, true)
heading.Position = UDim2.fromOffset(21, 13)
heading.Size = UDim2.new(1, -22, 0, 36)
heading.Active = true
local headingSub = label(dragBar, "SIGMASAKEN EXPERIENCE", 10, true, P.muted)
headingSub.Position = UDim2.fromOffset(22, 46)
headingSub.Size = UDim2.new(1, -22, 0, 17)
headingSub.Active = true

local function topButton(symbol, rightOffset)
    local b = make("TextButton", header, {
        Position = UDim2.new(1, rightOffset, 0, 19),
        Size = UDim2.fromOffset(35, 35),
        BackgroundColor3 = P.card2,
        Text = symbol, TextColor3 = P.white,
        Font = Enum.Font.GothamBold, TextSize = 24,
        AutoButtonColor = false
    })
    rounded(b, 16)
    pressEffect(b)
    return b
end
local minimize = topButton("−", -92)
local close = topButton("×", -48)

local holder = make("Frame", content, {
    Position = UDim2.fromOffset(17, 82),
    Size = UDim2.new(1, -35, 1, -100),
    BackgroundTransparency = 1,
    ClipsDescendants = true
})
local pages = {}
local navButtons = {}
local currentPage = nil

local function createPage(name)
    local page = make("ScrollingFrame", holder, {
        Name = name, Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = P.purple,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false
    })
    make("UIListLayout", page, {
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    make("UIPadding", page, {
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 15),
        PaddingRight = UDim.new(0, 7)
    })
    pages[name] = page
    return page
end

local home = createPage("Home")
local playerPage = createPage("Player")
local visuals = createPage("Visuals")
local config = createPage("Config")

local function card(page, title, description)
    local box = make("Frame", page, {
        Size = UDim2.new(1, -4, 0, 87),
        BackgroundColor3 = P.card
    })
    rounded(box, 20)
    outline(box, P.dark, 1, 0.79)
    local h = label(box, title, 15, true)
    h.Position = UDim2.fromOffset(17, 10)
    h.Size = UDim2.new(1, -34, 0, 29)
    local d = label(box, description, 12, false, P.muted)
    d.Position = UDim2.fromOffset(17, 41)
    d.Size = UDim2.new(1, -34, 0, 37)
    return box
end

local function addToggle(page, title, description, key, callback)
    local button = make("TextButton", page, {
        Size = UDim2.new(1, -4, 0, 78),
        BackgroundColor3 = P.card,
        Text = "", AutoButtonColor = false
    })
    rounded(button, 21)
    outline(button, P.dark, 1, 0.8)
    pressEffect(button)
    local h = label(button, title, 15, true)
    h.Position = UDim2.fromOffset(17, 10)
    h.Size = UDim2.new(1, -104, 0, 26)
    local d = label(button, description, 11, false, P.muted)
    d.Position = UDim2.fromOffset(17, 41)
    d.Size = UDim2.new(1, -104, 0, 26)
    local switch = make("Frame", button, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -15, 0.5, 0),
        Size = UDim2.fromOffset(56, 30),
        BackgroundColor3 = settings[key] and P.dark or P.dim
    })
    rounded(switch, 100)
    local knob = make("Frame", switch, {
        Position = settings[key] and UDim2.fromOffset(29, 4)
            or UDim2.fromOffset(4, 4),
        Size = UDim2.fromOffset(22, 22),
        BackgroundColor3 = P.white
    })
    rounded(knob, 100)
    connect(button.MouseButton1Click, function()
        settings[key] = not settings[key]
        local enabled = settings[key]
        tween(button, 0.2, {
            BackgroundColor3 = enabled and P.card2 or P.card
        })
        tween(switch, 0.3, {
            BackgroundColor3 = enabled and P.purple or P.dim
        }, Enum.EasingStyle.Back)
        tween(knob, 0.33, {
            Position = enabled and UDim2.fromOffset(30, 4)
                or UDim2.fromOffset(4, 4)
        }, Enum.EasingStyle.Back)
        if callback then callback(enabled) end
    end)
end

local function addSlider(page, title, minimum, maximum, initial, callback)
    local base = make("Frame", page, {
        Size = UDim2.new(1, -4, 0, 102),
        BackgroundColor3 = P.card
    })
    rounded(base, 21)
    local h = label(base, title, 15, true)
    h.Position = UDim2.fromOffset(17, 9)
    h.Size = UDim2.new(1, -115, 0, 28)
    local display = label(base, tostring(initial), 15, true, P.light)
    display.Position = UDim2.new(1, -98, 0, 9)
    display.Size = UDim2.fromOffset(80, 28)
    display.TextXAlignment = Enum.TextXAlignment.Right
    local hit = make("TextButton", base, {
        Position = UDim2.fromOffset(16, 47),
        Size = UDim2.new(1, -32, 0, 40),
        BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false
    })
    local track = make("Frame", hit, {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.new(1, 0, 0, 10),
        BackgroundColor3 = P.dim
    })
    rounded(track, 100)
    local fill = make("Frame", track, {
        Size = UDim2.fromScale((initial-minimum)/(maximum-minimum), 1),
        BackgroundColor3 = P.purple
    })
    rounded(fill, 100)
    local thumb = make("Frame", hit, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale((initial-minimum)/(maximum-minimum), 0.5),
        Size = UDim2.fromOffset(19, 19),
        BackgroundColor3 = P.light
    })
    rounded(thumb, 100)
    outline(thumb, P.purple, 1, 0.1)
    local activeInput = nil
    local function update(x)
        local fraction = math.clamp(
            (x - hit.AbsolutePosition.X)/math.max(1, hit.AbsoluteSize.X), 0, 1
        )
        local value = math.floor(minimum + fraction*(maximum-minimum) + 0.5)
        local exact = (value-minimum)/(maximum-minimum)
        display.Text = tostring(value)
        tween(fill, 0.09, {Size = UDim2.fromScale(exact, 1)})
        tween(thumb, 0.09, {Position = UDim2.fromScale(exact, 0.5)})
        if callback then callback(value) end
    end
    connect(hit.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            activeInput = input
            update(input.Position.X)
        end
    end)
    connect(UIS.InputChanged, function(input)
        if not activeInput then return end
        if input == activeInput or
            (activeInput.UserInputType == Enum.UserInputType.MouseButton1
                and input.UserInputType == Enum.UserInputType.MouseMovement) then
            update(input.Position.X)
        end
    end)
    connect(UIS.InputEnded, function(input)
        if activeInput == input then activeInput = nil end
    end)
end

-- THE FOUR SECTIONS.
card(home, "✦  WELCOME TO SIGMASAKEN", "Rounded animated dashboard • Alpha 0.6")
card(home, "◉  SYSTEM ONLINE", "Menu loaded. Touch the tabs to explore modules.")
card(home, "◈  FLOATING LAUNCHER", "Tap − to hide. Drag the Σ bubble anywhere, or tap it to reopen.")
card(home, "✧  MOBILE READY", "Resizable window, smooth navigation and animated controls.")

card(playerPage, "◉  PLAYER OPTIONS", "Interface preview — gameplay features not connected.")
addToggle(playerPage, "Sprint", "Animated sprint switch", "Sprint")
addToggle(playerPage, "Infinite Stamina", "Animated stamina switch", "Stamina")
addToggle(playerPage, "Speed Boost", "Animated movement switch", "Speed")
addSlider(playerPage, "Speed value", 16, 50, 24)

card(visuals, "◇  VISUAL OPTIONS", "Interface preview — ESP features not connected.")
addToggle(visuals, "Player ESP", "Player highlight switch", "ESP")
addToggle(visuals, "Name ESP", "Player label switch", "Names")
addToggle(visuals, "Distance ESP", "Distance indicator switch", "Distance")

card(config, "⚙  CONFIGURATION", "Personalize the animated interface.")
addToggle(config, "UI Animations", "Enable or disable interactions", "Animations")
addToggle(config, "Purple Glow", "Decorative lighting around the window", "Glow", function(enabled)
    tween(mainStroke, 0.3, {Transparency = enabled and 0.5 or 1})
end)
addSlider(config, "Window opacity", 60, 100, 100, function(value)
    main.BackgroundTransparency = 1 - value/100
end)
card(config, "↗  WINDOW SIZE", "Drag the bottom-right purple handle to resize.")

local pageTitles = {
    Home = "Dashboard", Player = "Player",
    Visuals = "Visuals", Config = "Configuration"
}
local function changePage(name)
    if currentPage == name then return end
    currentPage = name
    heading.Text = pageTitles[name]
    for key, p in pairs(pages) do p.Visible = (key == name) end
    for key, b in pairs(navButtons) do
        tween(b, 0.25, {
            BackgroundColor3 = key == name and P.dark or P.side,
            TextColor3 = key == name and P.white or P.muted
        })
    end
    local page = pages[name]
    page.Position = UDim2.fromOffset(29, 0)
    tween(page, 0.36, {Position = UDim2.fromOffset(0, 0)}, Enum.EasingStyle.Back)
end

local sectionData = {
    {"⌂  Home", "Home"},
    {"◉  Player", "Player"},
    {"◇  Visuals", "Visuals"},
    {"⚙  Config", "Config"}
}
for i, item in ipairs(sectionData) do
    local button = make("TextButton", nav, {
        LayoutOrder = i, Size = UDim2.new(1, 0, 0, 49),
        BackgroundColor3 = P.side,
        Text = item[1], TextColor3 = P.muted,
        TextSize = 14, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false
    })
    rounded(button, 18)
    make("UIPadding", button, {PaddingLeft = UDim.new(0, 14)})
    pressEffect(button)
    navButtons[item[2]] = button
    connect(button.MouseButton1Click, function() changePage(item[2]) end)
end
changePage("Home")

-- DRAG MAIN WINDOW WITH HEADER (touch and mouse).
local dragging = nil
local function beginDrag(input)
    if input.UserInputType == Enum.UserInputType.Touch or
        input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = {input = input, start = input.Position, origin = main.Position}
    end
end
connect(dragBar.InputBegan, beginDrag)
connect(heading.InputBegan, beginDrag)
connect(headingSub.InputBegan, beginDrag)
connect(UIS.InputChanged, function(input)
    if not dragging then return end
    if input ~= dragging.input and not (
        dragging.input.UserInputType == Enum.UserInputType.MouseButton1 and
        input.UserInputType == Enum.UserInputType.MouseMovement
    ) then return end
    local delta = input.Position - dragging.start
    local screen = workspace.CurrentCamera.ViewportSize
    local x = math.clamp(dragging.origin.X.Offset + delta.X,
        0, math.max(0, screen.X - main.AbsoluteSize.X))
    local y = math.clamp(dragging.origin.Y.Offset + delta.Y,
        0, math.max(0, screen.Y - main.AbsoluteSize.Y))
    main.Position = UDim2.fromOffset(x, y)
end)
connect(UIS.InputEnded, function(input)
    if dragging and dragging.input == input then dragging = nil end
end)

-- RESIZING WITH BOTTOM-RIGHT CORNER.
local resize = make("TextButton", main, {
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -6, 1, -6),
    Size = UDim2.fromOffset(39, 39),
    BackgroundColor3 = P.dark,
    Text = "◢", TextSize = 21,
    TextColor3 = P.light, Font = Enum.Font.GothamBold,
    AutoButtonColor = false, ZIndex = 12
})
rounded(resize, 16)
local resizing = nil
connect(resize.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.Touch or
        input.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing = {input = input, start = input.Position, size = main.Size}
    end
end)
connect(UIS.InputChanged, function(input)
    if not resizing then return end
    if input ~= resizing.input and not (
        resizing.input.UserInputType == Enum.UserInputType.MouseButton1 and
        input.UserInputType == Enum.UserInputType.MouseMovement
    ) then return end
    local delta = input.Position - resizing.start
    local screen = workspace.CurrentCamera.ViewportSize
    local maxW = math.max(280, screen.X - main.Position.X.Offset - 8)
    local maxH = math.max(260, screen.Y - main.Position.Y.Offset - 8)
    main.Size = UDim2.fromOffset(
        math.clamp(resizing.size.X.Offset + delta.X, math.min(380, maxW), maxW),
        math.clamp(resizing.size.Y.Offset + delta.Y, math.min(285, maxH), maxH)
    )
end)
connect(UIS.InputEnded, function(input)
    if resizing and resizing.input == input then resizing = nil end
end)

-- SHOW / HIDE with a dedicated floating bubble.
local isOpen = false
local transition = 0
local function showMenu()
    if isOpen then return end
    isOpen = true
    transition = transition + 1
    floating.Visible = false
    main.Visible = true
    mainScale.Scale = 0.78
    tween(mainScale, 0.42, {Scale = 1}, Enum.EasingStyle.Back)
end
local function hideMenu()
    if not isOpen then return end
    isOpen = false
    transition = transition + 1
    local token = transition
    floating.Visible = true
    floatScale.Scale = 0.65
    tween(floatScale, 0.38, {Scale = 1}, Enum.EasingStyle.Back)
    local t = tween(mainScale, 0.25, {Scale = 0.78})
    if t then
        connect(t.Completed, function()
            if not isOpen and transition == token then main.Visible = false end
        end)
    else
        main.Visible = false
    end
end
connect(minimize.MouseButton1Click, hideMenu)
connect(close.MouseButton1Click, hideMenu)

-- DRAG FLOATING BUTTON. Release without moving = open menu.
local floatingDrag = nil
connect(floating.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.Touch or
        input.UserInputType == Enum.UserInputType.MouseButton1 then
        floatingDrag = {
            input = input,
            start = input.Position,
            origin = floating.Position,
            moved = false
        }
        tween(floatScale, 0.12, {Scale = 0.91})
    end
end)
connect(UIS.InputChanged, function(input)
    if not floatingDrag then return end
    if input ~= floatingDrag.input and not (
        floatingDrag.input.UserInputType == Enum.UserInputType.MouseButton1 and
        input.UserInputType == Enum.UserInputType.MouseMovement
    ) then return end
    local delta = input.Position - floatingDrag.start
    if delta.Magnitude > 9 then floatingDrag.moved = true end
    if not floatingDrag.moved then return end
    local screen = workspace.CurrentCamera.ViewportSize
    local x = math.clamp(floatingDrag.origin.X.Offset + delta.X,
        4, math.max(4, screen.X - 66))
    local y = math.clamp(floatingDrag.origin.Y.Offset + delta.Y,
        4, math.max(4, screen.Y - 66))
    floating.Position = UDim2.fromOffset(x, y)
end)
connect(UIS.InputEnded, function(input)
    if not floatingDrag or input ~= floatingDrag.input then return end
    local wasMoved = floatingDrag.moved
    floatingDrag = nil
    tween(floatScale, 0.24, {Scale = 1}, Enum.EasingStyle.Back)
    if not wasMoved then showMenu() end
end)

-- Set a sensible initial floating position for the device.
floating.Position = UDim2.fromOffset(18,
    math.floor((viewport.Y - 62)/2))

-- LOAD THEN SHOW THE MAIN UI.
tween(loadingScale, 0.42, {Scale = 1}, Enum.EasingStyle.Back)
local started = os.clock()
local progressTween = TweenService:Create(bar, TweenInfo.new(
    2, Enum.EasingStyle.Linear
), {Size = UDim2.fromScale(1, 1)})
progressTween:Play()
while os.clock() - started < 2 do
    local pct = math.clamp(math.floor((os.clock()-started)/2*100), 0, 100)
    ls.Text = "PREPARING UI... " .. pct .. "%"
    task.wait(0.03)
end
progressTween:Cancel()
bar.Size = UDim2.fromScale(1, 1)
ls.Text = "PREPARING UI... 100%"
local endLoad = tween(loadingScale, 0.2, {Scale = 0.82})
if endLoad then endLoad.Completed:Wait() end
loading:Destroy()
showMenu()
print("SigmaSaken V2 Alpha 0.6 UI loaded")
