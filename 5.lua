--[[
 SIGMASAKEN V2 | RELEASE 5.0
 Dedicated PC and Mobile layouts with responsive square tile grids
 Loading / Sections / Drag / Resize / Floating launcher
 Client-side player modules: noclip, sprint, speed, jump, ESP, visuals.
 All controls from Release 3.0 preserved, shared between both layouts.
 Killer warning overlay + M1/ability guard attempts + fake running-in-place animation.
 Auto-block offers conservative M1 and experimental broad attack modes.
 Server-authoritative game actions are not guaranteed.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
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
    Noclip = false,
    JumpBoost = false,
    InfiniteJump = false,
    ESP = false,
    Names = false,
    Distance = false,
    Fullbright = false,
    NoFog = false,
    WideFOV = false,
    SprintValue = 26,
    SpeedValue = 36,
    JumpValue = 75,
    FOVValue = 90,
    AutoJump = false,
    NoSit = false,
    AutoRotate = true,
    HealthESP = false,
    TeamColors = false,
    OnlyOutline = false,
    ESPThroughWalls = true,
    RainbowESP = false,
    SelfHighlight = false,
    ESPRange = 600,
    ESPOpacity = 65,
    FirstPerson = false,
    UnlockZoom = false,
    ZoomMax = 50,
    CameraOffset = false,
    CameraOffsetX = 2,
    NightMode = false,
    DisableShadows = false,
    HighSaturation = false,
    HighContrast = false,
    BloomEffect = false,
    BlurEffect = false,
    NightVision = false,
    ColorCycle = false,
    RemoveClouds = false,
    SaturationValue = 60,
    ContrastValue = 25,
    BlurValue = 8,
    BloomValue = 1,
    FPSHUD = false,
    SpeedHUD = false,
    CoordinatesHUD = false,
    PlayerHUD = false,
    ClockHUD = false,
    HealthHUD = false,
    Crosshair = false,
    ShowQuickRun = true,
    ShowQuickNoclip = false,
    ShowQuickJump = false,
    HUDScale = 100,
    MuteAll = false,
    QuietMode = false,
    MuteMusic = false,
    VolumePercent = 100,
    MenuScale = 100,
    ShowToasts = true,
    KillerHitbox = false,
    KillerAura = false,
    KillerLabel = false,
    KillerRadius = 7,
    KillerMarkerOpacity = 78,
    GuestAutoBlock = false,
    GuestBlockRange = 13,
    GuestBlockCooldown = 27,
    GuestBlockAlerts = false,
    GuestBlockAll = false,
    GuestProximityGuard = false,
    FakeLag = false,
    FakeLagStutter = true,
    FakeLagAnimSpeed = 16,
    ShowQuickFakeLag = true
}

local extraCleanup = function() end
local cleanupFeatures = function() end
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
    pcall(cleanupFeatures)
    for _, c in ipairs(connections) do
        if c.Connected then c:Disconnect() end
    end
    if launcherGui.Parent then launcherGui:Destroy() end
end)

-- DEVICE MODE: freshly selected every time the script runs.
local selectedMode = nil
local showDevicePicker = function() end
local applyDeviceLayout = function(_) end

-- LOADING: 2 seconds, followed by a choice of PC or Mobile.
local loading = make("Frame", mainGui, {
    AnchorPoint = Vector2.new(.5, .5),
    Position = UDim2.fromScale(.5, .5),
    Size = UDim2.fromOffset(335, 188),
    BackgroundColor3 = P.bg
})
rounded(loading, 30)
outline(loading, P.purple, 1.5, .3)
local loadingScale = make("UIScale", loading, {Scale = .76})
local lt = label(loading, "✦  SIGMASAKEN V2", 22, true, P.light)
lt.Position = UDim2.fromOffset(24, 24)
lt.Size = UDim2.new(1, -48, 0, 46)
local ls = label(loading, "PREPARING INTERFACE... 0%", 12, true, P.muted)
ls.Position = UDim2.fromOffset(24, 85)
ls.Size = UDim2.new(1, -48, 0, 25)
local barTrack = make("Frame", loading, {
    Position = UDim2.fromOffset(24, 128),
    Size = UDim2.new(1, -48, 0, 13),
    BackgroundColor3 = P.dim, ClipsDescendants = true
})
rounded(barTrack, 100)
local bar = make("Frame", barTrack, {
    Size = UDim2.fromScale(0, 1), BackgroundColor3 = P.purple
})
rounded(bar, 100)
make("UIGradient", bar, {Color = ColorSequence.new(P.purple, P.light)})

-- Always-on-top, independently draggable launcher.
local floating = make("TextButton", launcherGui, {
    Name = "OpenCloseButton", AnchorPoint = Vector2.new(0, 0),
    Position = UDim2.fromOffset(18, 270),
    Size = UDim2.fromOffset(62, 62),
    BackgroundColor3 = P.bg, Text = "Σ", TextSize = 31,
    Font = Enum.Font.GothamBold, TextColor3 = P.light,
    AutoButtonColor = false, Visible = false
})
rounded(floating, 100)
local floatRing = outline(floating, P.purple, 2.2, .12)
local floatScale = make("UIScale", floating, {Scale = 1})
local floatGlow = make("Frame", floating, {
    AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5),
    Size = UDim2.fromOffset(51,51), BackgroundTransparency = 1, ZIndex = 0
})
rounded(floatGlow, 100)
local glowRing = outline(floatGlow, P.light, 1.1, .7)
TweenService:Create(floatRing, TweenInfo.new(
    1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true
), {Transparency = .65}):Play()
TweenService:Create(glowRing, TweenInfo.new(
    2.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true
), {Transparency = .1}):Play()

-- Independent selection screen, so every execution asks again.
local selector = make("Frame", mainGui, {
    Name = "DeviceSelector", Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = P.bg, BackgroundTransparency = .28,
    Visible = false, ZIndex = 30
})
local selectorPanel = make("Frame", selector, {
    AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5),
    Size = UDim2.fromOffset(480, 300), BackgroundColor3 = P.side,
    ZIndex = 31
})
rounded(selectorPanel, 31)
outline(selectorPanel, P.purple, 1.6, .28)
local selectorScale = make("UIScale", selectorPanel, {Scale = .78})
local selectorTitle = label(selectorPanel, "SELECT YOUR DEVICE", 24, true, P.light)
selectorTitle.Position = UDim2.fromOffset(20, 20)
selectorTitle.Size = UDim2.new(1,-40,0,45)
selectorTitle.TextXAlignment = Enum.TextXAlignment.Center
local selectorSub = label(selectorPanel, "Choose a layout for this session", 13, false, P.muted)
selectorSub.Position = UDim2.fromOffset(20, 66)
selectorSub.Size = UDim2.new(1,-40,0,25)
selectorSub.TextXAlignment = Enum.TextXAlignment.Center
local optionPC = make("TextButton", selectorPanel, {
    Position = UDim2.new(0, 22, 0, 116),
    Size = UDim2.new(.5, -33, 0, 136),
    BackgroundColor3 = P.card2,
    Text = "▣\nPC\nDESKTOP", TextColor3 = P.white,
    Font = Enum.Font.GothamBold, TextSize = 20, AutoButtonColor = false
})
rounded(optionPC, 26)
outline(optionPC, P.purple, 1.3, .4)
pressEffect(optionPC)
local optionMobile = make("TextButton", selectorPanel, {
    Position = UDim2.new(.5, 11, 0, 116),
    Size = UDim2.new(.5, -33, 0, 136),
    BackgroundColor3 = P.card2,
    Text = "▥\nMOBILE\nTOUCH", TextColor3 = P.white,
    Font = Enum.Font.GothamBold, TextSize = 20, AutoButtonColor = false
})
rounded(optionMobile, 26)
outline(optionMobile, P.purple, 1.3, .4)
pressEffect(optionMobile)
local selectorFoot = label(selectorPanel,
    "Same features • Different layout • Choose each launch", 11, false, P.muted)
selectorFoot.Position = UDim2.fromOffset(20, 269)
selectorFoot.Size = UDim2.new(1,-40,0,23)
selectorFoot.TextXAlignment = Enum.TextXAlignment.Center

local camera = workspace.CurrentCamera
local viewport = camera and camera.ViewportSize or Vector2.new(1024,768)
local initialW = math.min(640, viewport.X - 24)
local initialH = math.min(440, viewport.Y - 28)

local main = make("Frame", mainGui, {
    Name = "MainWindow",
    Position = UDim2.fromOffset(math.floor((viewport.X-initialW)/2),
        math.floor((viewport.Y-initialH)/2)),
    Size = UDim2.fromOffset(initialW, initialH),
    BackgroundColor3 = P.bg, ClipsDescendants = true, Visible = false
})
rounded(main, 32)
local mainStroke = outline(main, P.purple, 1.6, .42)
local mainScale = make("UIScale", main, {Scale = 1})
make("UIGradient", main, {
    Rotation = 24,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, P.bg),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20,14,34))
    })
})
local accentStrip = make("Frame", main, {
    Position = UDim2.fromOffset(0,0), Size = UDim2.new(1,0,0,4),
    BackgroundColor3 = P.purple, ZIndex = 5
})
local stripGradient = make("UIGradient", accentStrip, {
    Color = ColorSequence.new(P.dark, P.light)
})
TweenService:Create(stripGradient, TweenInfo.new(6, Enum.EasingStyle.Linear,
    Enum.EasingDirection.InOut, -1), {Rotation = 360}):Play()

-- PC gets a wide sidebar. Mobile gets a horizontal tab ribbon.
local pcSidebarWidth = 210
local sidebar = make("Frame", main, {
    Size = UDim2.new(0, pcSidebarWidth, 1, 0),
    BackgroundColor3 = P.side, Visible = false
})
local logoCircle = make("Frame", sidebar, {
    Position = UDim2.fromOffset(22,21),
    Size = UDim2.fromOffset(49,49), BackgroundColor3 = P.dark
})
rounded(logoCircle, 100)
local logoSymbol = label(logoCircle, "Σ", 31, true, P.light)
logoSymbol.Size = UDim2.fromScale(1,1)
logoSymbol.TextXAlignment = Enum.TextXAlignment.Center
local logoName = label(sidebar, "SIGMA", 23, true, P.light)
logoName.Position = UDim2.fromOffset(82,25)
logoName.Size = UDim2.new(1,-91,0,38)
local subname = label(sidebar, "SAKEN V2  •  PC", 11, true, P.muted)
subname.Position = UDim2.fromOffset(22,79)
subname.Size = UDim2.new(1,-35,0,23)
local nav = make("ScrollingFrame", sidebar, {
    Position = UDim2.fromOffset(13,125),
    Size = UDim2.new(1,-26,1,-180),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = P.purple,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.fromOffset(0,0)
})
make("UIListLayout", nav, {
    Padding = UDim.new(0,9), SortOrder = Enum.SortOrder.LayoutOrder
})
make("UIPadding", nav, {PaddingBottom = UDim.new(0,12)})
local build = label(sidebar, "RELEASE 5.0  •  DESKTOP", 11, true, P.muted)
build.Position = UDim2.new(0,17,1,-36)
build.Size = UDim2.new(1,-26,0,25)

local content = make("Frame", main, {
    Position = UDim2.fromOffset(0,0),
    Size = UDim2.fromScale(1,1), BackgroundTransparency = 1
})
local header = make("Frame", content, {
    Size = UDim2.new(1,0,0,77), BackgroundTransparency = 1
})
local dragBar = make("Frame", header, {
    Size = UDim2.new(1,-116,1,0),
    BackgroundTransparency = 1, Active = true
})
local heading = label(dragBar, "Dashboard", 25, true, P.white)
heading.Position = UDim2.fromOffset(21,12)
heading.Size = UDim2.new(1,-22,0,37)
heading.Active = true
local headingSub = label(dragBar, "SIGMASAKEN V2 • RESPONSIVE", 11, true, P.muted)
headingSub.Position = UDim2.fromOffset(22,48)
headingSub.Size = UDim2.new(1,-24,0,19)
headingSub.Active = true

local function topButton(symbol, rightOffset)
    local b = make("TextButton", header, {
        Position = UDim2.new(1,rightOffset,0,18),
        Size = UDim2.fromOffset(38,38),
        BackgroundColor3 = P.card2, Text = symbol, TextColor3 = P.white,
        Font = Enum.Font.GothamBold, TextSize = 24, AutoButtonColor = false
    })
    rounded(b, 100)
    pressEffect(b)
    return b
end
local minimize = topButton("−", -97)
local close = topButton("×", -52)

local mobileNav = make("ScrollingFrame", content, {
    Name = "MobileNavigation", Position = UDim2.fromOffset(14,75),
    Size = UDim2.new(1,-28,0,49),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.X,
    CanvasSize = UDim2.fromOffset(0,0), Visible = false
})
local mobileNavList = make("UIListLayout", mobileNav, {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0,9), SortOrder = Enum.SortOrder.LayoutOrder
})
connect(mobileNavList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
    mobileNav.CanvasSize = UDim2.fromOffset(
        mobileNavList.AbsoluteContentSize.X + 10,0)
end)

local holder = make("Frame", content, {
    Position = UDim2.fromOffset(16,82),
    Size = UDim2.new(1,-32,1,-100),
    BackgroundTransparency = 1, ClipsDescendants = true
})
local pages = {}
local pageGrids = {}
local navButtons = {}
local currentPage = nil

local function createPage(name)
    local page = make("ScrollingFrame", holder, {
        Name = name, Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = P.purple,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.fromOffset(0,0), Visible = false
    })
    local layout = make("UIGridLayout", page, {
        CellPadding = UDim2.fromOffset(12,12),
        CellSize = UDim2.fromOffset(184,184),
        FillDirectionMaxCells = 2,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    make("UIPadding", page, {
        PaddingTop = UDim.new(0,6),
        PaddingBottom = UDim.new(0,18),
        PaddingRight = UDim.new(0,5)
    })
    connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        page.CanvasSize = UDim2.fromOffset(0,layout.AbsoluteContentSize.Y+28)
    end)
    pageGrids[name] = layout
    pages[name] = page
    return page
end

local home = createPage("Home")
local playerPage = createPage("Player")
local combatPage = createPage("Combat")
local visuals = createPage("Visuals")
local cameraPage = createPage("Camera")
local worldPage = createPage("World")
local hudPage = createPage("HUD")
local audioPage = createPage("Audio")
local config = createPage("Config")

-- Equal square tiles in BOTH modes. Descriptions and controls stay inside tiles.
local tileOrder = 0
local function tile(parent, background)
    tileOrder = tileOrder + 1
    local box = make("Frame", parent, {
        LayoutOrder = tileOrder,
        Size = UDim2.fromOffset(180,180),
        BackgroundColor3 = background or P.card,
        ClipsDescendants = true
    })
    rounded(box, 25)
    outline(box, P.dark, 1, .72)
    local accentDot = make("Frame", box, {
        Position = UDim2.fromOffset(15,15),
        Size = UDim2.fromOffset(8,8),
        BackgroundColor3 = P.purple
    })
    rounded(accentDot, 100)
    return box
end
local function card(page, title, description)
    local box = tile(page, P.card)
    local h = label(box, title, 14, true)
    h.Position = UDim2.fromOffset(15,32)
    h.Size = UDim2.new(1,-30,0,48)
    local d = label(box, description, 11, false, P.muted)
    d.Position = UDim2.fromOffset(15,83)
    d.Size = UDim2.new(1,-30,1,-106)
    d.TextYAlignment = Enum.TextYAlignment.Top
    return box
end
local toggleRefresh = {}
local function addToggle(page, title, description, key, callback)
    -- The entire square tile is a tappable button.
    tileOrder = tileOrder + 1
    local b = make("TextButton", page, {
        LayoutOrder = tileOrder,
        Size = UDim2.fromOffset(180,180),
        BackgroundColor3 = P.card,
        Text = "", AutoButtonColor = false, ClipsDescendants = true
    })
    rounded(b, 25)
    outline(b, P.dark, 1, .7)
    pressEffect(b)
    local h = label(b, title, 14, true)
    h.Position = UDim2.fromOffset(15,15)
    h.Size = UDim2.new(1,-30,0,54)
    h.TextYAlignment = Enum.TextYAlignment.Top
    local d = label(b, description, 11, false, P.muted)
    d.Position = UDim2.fromOffset(15,69)
    d.Size = UDim2.new(1,-30,1,-132)
    d.TextYAlignment = Enum.TextYAlignment.Top
    local status = label(b, "OFF", 11, true, P.muted)
    status.AnchorPoint = Vector2.new(0,1)
    status.Position = UDim2.new(0,15,1,-14)
    status.Size = UDim2.fromOffset(37,28)
    local switch = make("Frame", b, {
        AnchorPoint = Vector2.new(1,1),
        Position = UDim2.new(1,-14,1,-15),
        Size = UDim2.fromOffset(52,28),
        BackgroundColor3 = settings[key] and P.purple or P.dim
    })
    rounded(switch, 100)
    local knob = make("Frame", switch, {
        Position = settings[key] and UDim2.fromOffset(26,4)
            or UDim2.fromOffset(4,4),
        Size = UDim2.fromOffset(20,20), BackgroundColor3 = P.white
    })
    rounded(knob, 100)
    local function refresh()
        local on = settings[key]
        status.Text = on and "ON" or "OFF"
        status.TextColor3 = on and P.light or P.muted
        tween(b,.2,{BackgroundColor3=on and P.card2 or P.card})
        tween(switch,.24,{BackgroundColor3=on and P.purple or P.dim})
        tween(knob,.28,{
            Position = on and UDim2.fromOffset(28,4)
                or UDim2.fromOffset(4,4)
        },Enum.EasingStyle.Back)
    end
    toggleRefresh[key] = refresh
    connect(b.MouseButton1Click, function()
        settings[key] = not settings[key]
        refresh()
        if callback then callback(settings[key]) end
    end)
    refresh()
    return b
end
local sliderRefresh = {}
local function addSlider(page, title, minimum, maximum, initial, callback)
    local base = tile(page, P.card2)
    local h = label(base, title, 14, true)
    h.Position = UDim2.fromOffset(15,15)
    h.Size = UDim2.new(1,-30,0,45)
    local display = label(base, tostring(initial), 24, true, P.light)
    display.Position = UDim2.fromOffset(15,63)
    display.Size = UDim2.new(1,-30,0,37)
    local hit = make("TextButton", base, {
        Position = UDim2.new(0,14,1,-56),
        Size = UDim2.new(1,-28,0,39),
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false
    })
    local track = make("Frame", hit, {
        AnchorPoint = Vector2.new(0,.5), Position = UDim2.fromScale(0,.5),
        Size = UDim2.new(1,0,0,9), BackgroundColor3 = P.dim
    })
    rounded(track,100)
    local fill = make("Frame", track, {
        Size = UDim2.fromScale((initial-minimum)/(maximum-minimum),1),
        BackgroundColor3 = P.purple
    })
    rounded(fill,100)
    local thumb = make("Frame",hit,{
        AnchorPoint = Vector2.new(.5,.5),
        Position = UDim2.fromScale((initial-minimum)/(maximum-minimum),.5),
        Size = UDim2.fromOffset(22,22), BackgroundColor3 = P.light
    })
    rounded(thumb,100)
    local activeInput = nil
    local function update(x)
        local fraction = math.clamp(
            (x-hit.AbsolutePosition.X)/math.max(1,hit.AbsoluteSize.X),0,1)
        local value = math.floor(minimum+fraction*(maximum-minimum)+.5)
        local exact = (value-minimum)/(maximum-minimum)
        display.Text = tostring(value)
        tween(fill,.08,{Size=UDim2.fromScale(exact,1)})
        tween(thumb,.08,{Position=UDim2.fromScale(exact,.5)})
        if callback then callback(value) end
    end
    connect(hit.InputBegan,function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
            input.UserInputType == Enum.UserInputType.MouseButton1 then
            activeInput = input
            update(input.Position.X)
        end
    end)
    connect(UIS.InputChanged,function(input)
        if not activeInput then return end
        if input == activeInput or (activeInput.UserInputType ==
            Enum.UserInputType.MouseButton1 and
            input.UserInputType == Enum.UserInputType.MouseMovement) then
            update(input.Position.X)
        end
    end)
    connect(UIS.InputEnded,function(input)
        if activeInput == input then activeInput = nil end
    end)
    local function setValue(requested)
        local value = math.clamp(math.floor(requested+.5),minimum,maximum)
        local fraction = (value-minimum)/(maximum-minimum)
        display.Text=tostring(value)
        tween(fill,.14,{Size=UDim2.fromScale(fraction,1)})
        tween(thumb,.14,{Position=UDim2.fromScale(fraction,.5)})
        if callback then callback(value) end
    end
    sliderRefresh[title] = setValue
    return setValue
end
local function addAction(page, title, description, callback)
    tileOrder = tileOrder + 1
    local b = make("TextButton",page,{
        LayoutOrder = tileOrder, Size = UDim2.fromOffset(180,180),
        BackgroundColor3 = P.card2, Text = "",
        AutoButtonColor = false, ClipsDescendants = true
    })
    rounded(b,25)
    outline(b,P.dark,1,.58)
    pressEffect(b)
    local h = label(b,title,14,true,P.light)
    h.Position = UDim2.fromOffset(15,16)
    h.Size = UDim2.new(1,-30,0,53)
    h.TextYAlignment = Enum.TextYAlignment.Top
    local d = label(b,description,11,false,P.muted)
    d.Position = UDim2.fromOffset(15,70)
    d.Size = UDim2.new(1,-30,1,-126)
    d.TextYAlignment = Enum.TextYAlignment.Top
    local go = make("Frame",b,{
        AnchorPoint = Vector2.new(1,1), Position = UDim2.new(1,-14,1,-12),
        Size = UDim2.fromOffset(30,30),BackgroundColor3=P.dark
    })
    rounded(go,100)
    local arrow = label(go,"›",22,true,P.light)
    arrow.Size=UDim2.fromScale(1,1)
    arrow.TextXAlignment=Enum.TextXAlignment.Center
    connect(b.MouseButton1Click,function()
        tween(b,.15,{BackgroundColor3=P.dark})
        task.delay(.20,function()
            if b.Parent then tween(b,.25,{BackgroundColor3=P.card2}) end
        end)
        if callback then
            local ok,err=pcall(callback)
            if not ok then warn("SigmaSaken action error: "..tostring(err)) end
        end
    end)
    return b
end

-- RESPONSIVE LAYOUT: same page data and actions, different frame/navigation.
local function updateTileGrid()
    local pc = selectedMode == "PC"
    local width = main.Size.X.Offset
    local available = width - (pc and pcSidebarWidth or 0) - 52
    local cols = pc and (available >= 875 and 4 or 3) or 2
    local gap = pc and 15 or 11
    local cell = math.floor((available - (cols-1)*gap)/cols)
    cell = math.clamp(cell, 112, pc and 245 or 260)
    for name, grid in pairs(pageGrids) do
        grid.FillDirectionMaxCells = cols
        grid.CellPadding = UDim2.fromOffset(gap,gap)
        grid.CellSize = UDim2.fromOffset(cell,cell)
    end
end
applyDeviceLayout = function(mode)
    selectedMode = mode
    local pc = mode == "PC"
    local vs = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
        or Vector2.new(1024,768)
    local w = math.floor(math.min(pc and 1160 or 650, vs.X-(pc and 60 or 22)))
    local h = math.floor(math.min(pc and 700 or 510, vs.Y-(pc and 74 or 25)))
    main.Size = UDim2.fromOffset(w,h)
    main.Position = UDim2.fromOffset(math.floor((vs.X-w)/2),math.floor((vs.Y-h)/2))
    sidebar.Visible = pc
    mobileNav.Visible = not pc
    content.Position = UDim2.fromOffset(pc and pcSidebarWidth or 0,0)
    content.Size = UDim2.new(1,pc and -pcSidebarWidth or 0,1,0)
    holder.Position = UDim2.fromOffset(17,pc and 83 or 135)
    holder.Size = UDim2.new(1,-34,1,pc and -102 or -153)
    headingSub.Text = pc and "DESKTOP EXPERIENCE • GRID" or
        "MOBILE EXPERIENCE • GRID"
    build.Text = "RELEASE 5.0  •  " .. mode:upper()
    settings.MenuScale = 100
    mainScale.Scale = 1
    if sliderRefresh["UI scale"] then
        sliderRefresh["UI scale"](100)
    end
    task.defer(updateTileGrid)
end
connect(main:GetPropertyChangedSignal("Size"),function()
    task.defer(updateTileGrid)
end)
-- ===========================================================================
-- FUNCTIONAL CLIENT MODULES (local-only: server may correct or reject changes)
-- ===========================================================================
local character, humanoid, rootPart = nil, nil, nil
local originalSpeed, originalJumpPower, originalJumpHeight
local appliedSpeed = false
local appliedJump = false
local collisionBackup = {}
local espRecords = {}
local quickSprint = false
local originalLighting = {
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    GlobalShadows = Lighting.GlobalShadows,
    ExposureCompensation = Lighting.ExposureCompensation
}
local originalFOV = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70
local lastStaminaReport = "Not detected"

local function restoreCollision()
    for part, value in pairs(collisionBackup) do
        if part and part.Parent then
            pcall(function() part.CanCollide = value end)
        end
    end
    table.clear(collisionBackup)
end

local function restoreLighting()
    for property, value in pairs(originalLighting) do
        pcall(function() Lighting[property] = value end)
    end
end

local function restoreMovement()
    if humanoid and humanoid.Parent then
        if appliedSpeed and originalSpeed then
            pcall(function() humanoid.WalkSpeed = originalSpeed end)
        end
        if originalJumpPower then
            pcall(function() humanoid.JumpPower = originalJumpPower end)
        end
        if originalJumpHeight then
            pcall(function() humanoid.JumpHeight = originalJumpHeight end)
        end
    end
    appliedSpeed = false
    appliedJump = false
end

local function stopESP()
    for target, record in pairs(espRecords) do
        if record.highlight then record.highlight:Destroy() end
        if record.billboard then record.billboard:Destroy() end
        espRecords[target] = nil
    end
end

local stopFakeLag = function() end
local startFakeLag = function() return false end
local fakeLagReport = "Not enabled"

local function bindCharacter(newCharacter)
    stopFakeLag()
    restoreCollision()
    character = newCharacter
    humanoid = character and character:FindFirstChildOfClass("Humanoid") or nil
    rootPart = character and character:FindFirstChild("HumanoidRootPart") or nil
    originalSpeed = humanoid and humanoid.WalkSpeed or nil
    originalJumpPower = humanoid and humanoid.JumpPower or nil
    originalJumpHeight = humanoid and humanoid.JumpHeight or nil
    appliedSpeed = false
    appliedJump = false
end

bindCharacter(player.Character)
connect(player.CharacterAdded, function(newCharacter)
    bindCharacter(newCharacter)
end)

-- FAKE LAG: run-in-place animation, NOT real network lag/desync.
-- Only the local avatar animation and local walking speed are changed.
do
local fakeLagTrack, fakeLagAnimation, fakeLagHumanoid, fakeLagSavedSpeed
local fakeLagTick = 0

local function findRunId(model, h)
    local animateScript = model and model:FindFirstChild("Animate")
    if animateScript then
        for _, item in ipairs(animateScript:GetDescendants()) do
            if item:IsA("Animation") then
                local idName = (item.Name .. " " .. (item.Parent and item.Parent.Name or "")):lower()
                if idName:find("sprint", 1, true) or idName:find("run", 1, true) then
                    if tostring(item.AnimationId):match("%d+") then
                        return item.AnimationId, false
                    end
                end
            end
        end
    end
    -- Roblox stock rig animations; may not be permitted for every custom avatar.
    if h and h.RigType == Enum.HumanoidRigType.R6 then
        return "rbxassetid://180426354", true
    end
    return "rbxassetid://507767714", true
end

stopFakeLag = function()
    if fakeLagTrack then
        pcall(function() fakeLagTrack:Stop(0.15) end)
        pcall(function() fakeLagTrack:Destroy() end)
        fakeLagTrack = nil
    end
    if fakeLagAnimation then fakeLagAnimation:Destroy(); fakeLagAnimation = nil end
    if fakeLagHumanoid and fakeLagHumanoid.Parent
        and fakeLagHumanoid.WalkSpeed == 0 then
        pcall(function()
            fakeLagHumanoid.WalkSpeed = fakeLagSavedSpeed or originalSpeed or 16
        end)
    end
    fakeLagHumanoid = nil
    fakeLagSavedSpeed = nil
end

startFakeLag = function()
    if not settings.FakeLag then return false end
    if not character or not humanoid or humanoid.Health <= 0 then
        fakeLagReport = "Character not ready"
        return false
    end
    if fakeLagTrack and fakeLagHumanoid == humanoid then
        return true
    end
    stopFakeLag()
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    local animationId, fallback = findRunId(character, humanoid)
    local anim = Instance.new("Animation")
    anim.Name = "SigmaFakeLagRun"
    anim.AnimationId = animationId
    local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
    if not ok or not track then
        anim:Destroy()
        fakeLagReport = "Run animation unavailable"
        return false
    end
    local started = pcall(function()
        track.Priority = Enum.AnimationPriority.Action4
        track.Looped = true
        track:Play(0.15, 1, settings.FakeLagAnimSpeed / 10)
    end)
    if not started then
        pcall(function() track:Destroy() end)
        anim:Destroy()
        fakeLagReport = "Animation playback failed"
        return false
    end
    fakeLagTrack = track
    fakeLagAnimation = anim
    fakeLagHumanoid = humanoid
    fakeLagSavedSpeed = humanoid.WalkSpeed
    fakeLagReport = fallback and "Stock run animation (fallback)" or "Custom run animation"
    return true
end

-- Update in small intervals. No anchoring, teleporting, packet throttling,
-- or permanent alteration of character physics/network ownership.
connect(RunService.Heartbeat, function(dt)
    fakeLagTick = fakeLagTick + dt
    if fakeLagTick < 0.10 then return end
    fakeLagTick = 0
    if not settings.FakeLag then
        if fakeLagTrack then stopFakeLag() end
        return
    end
    if not startFakeLag() then return end
    if fakeLagTrack then
        local speed = settings.FakeLagAnimSpeed / 10
        if settings.FakeLagStutter then
            -- Brief visual animation pauses to mimic laggy movement.
            speed = (math.floor(os.clock() * 4) % 7 == 0) and 0.07 or speed
        end
        pcall(function()
            if not fakeLagTrack.IsPlaying then fakeLagTrack:Play(0.1, 1, speed) end
            fakeLagTrack:AdjustSpeed(speed)
        end)
    end
    if humanoid and humanoid.Parent then
        humanoid.WalkSpeed = 0
        humanoid:Move(Vector3.zero, false)
    end
end)
end -- fake-lag private state

-- Noclip: turn off collision on local character parts, then restore originals.
local function updateNoclip()
    if not settings.Noclip then return end
    if not character or not character.Parent then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if collisionBackup[part] == nil then
                collisionBackup[part] = part.CanCollide
            end
            if part.CanCollide then part.CanCollide = false end
        end
    end
end

-- Sprint: always-on when enabled in Player. The mobile quick button
-- allows temporary toggle without opening the large window.
local function updateMovement()
    if not humanoid or not humanoid.Parent then return end
    local wantSprint = settings.Sprint or quickSprint
    local wantSpeed = settings.Speed
    if settings.FakeLag then
        if humanoid.WalkSpeed ~= 0 then humanoid.WalkSpeed = 0 end
        appliedSpeed = true
    elseif wantSprint or wantSpeed then
        local requested = wantSpeed and settings.SpeedValue or settings.SprintValue
        if wantSprint and wantSpeed then
            requested = math.max(settings.SpeedValue, settings.SprintValue)
        end
        if humanoid.WalkSpeed ~= requested then
            humanoid.WalkSpeed = requested
        end
        appliedSpeed = true
    elseif appliedSpeed then
        if originalSpeed then humanoid.WalkSpeed = originalSpeed end
        appliedSpeed = false
    end
    if settings.JumpBoost then
        appliedJump = true
        if humanoid.UseJumpPower then
            humanoid.JumpPower = settings.JumpValue
        else
            humanoid.JumpHeight = math.max(7.2, settings.JumpValue / 7)
        end
    elseif appliedJump and originalJumpPower and originalJumpHeight then
        appliedJump = false
        if humanoid.JumpPower ~= originalJumpPower then
            humanoid.JumpPower = originalJumpPower
        end
        if humanoid.JumpHeight ~= originalJumpHeight then
            humanoid.JumpHeight = originalJumpHeight
        end
    end
end

-- Experimental stamina support. Only works if this game exposes writable
-- IntValue / NumberValue instances or attributes with recognizable names.
-- Forsaken may keep the real stamina entirely in server/private modules.
local staminaNames = {"Stamina", "CurrentStamina", "SprintStamina"}
local function refillStamina()
    if not settings.Stamina then return end
    local found = 0
    local scopes = {player}
    if character then table.insert(scopes, character) end
    for _, scope in ipairs(scopes) do
        if scope then
            for _, name in ipairs(staminaNames) do
                local object = scope:FindFirstChild(name, true)
                if object and (object:IsA("NumberValue") or object:IsA("IntValue")) then
                    local maximum = object:GetAttribute("MaxStamina")
                        or scope:GetAttribute("MaxStamina") or 100
                    if type(maximum) == "number" and maximum > 0 then
                        pcall(function() object.Value = maximum end)
                        found = found + 1
                    end
                end
            end
            for _, name in ipairs(staminaNames) do
                local value = scope:GetAttribute(name)
                if type(value) == "number" then
                    local maximum = scope:GetAttribute("MaxStamina") or 100
                    pcall(function() scope:SetAttribute(name, maximum) end)
                    found = found + 1
                end
            end
        end
    end
    lastStaminaReport = found > 0 and "Local values found" or "No exposed stamina value"
end

-- ESP: local Highlight and BillboardGui; does not modify other players.
local function removeESP(target)
    local record = espRecords[target]
    if not record then return end
    if record.highlight then record.highlight:Destroy() end
    if record.billboard then record.billboard:Destroy() end
    espRecords[target] = nil
end

local function syncESP()
    local showAny = settings.ESP or settings.Names or settings.Distance or settings.HealthESP
    if not showAny then
        if next(espRecords) then stopESP() end
        return
    end
    local current = {}
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= player then
            current[target] = true
            local model = target.Character
            local anchor = model and (model:FindFirstChild("Head")
                or model:FindFirstChild("HumanoidRootPart"))
            local targetHum = model and model:FindFirstChildOfClass("Humanoid")
            if not model or not anchor or not targetHum or targetHum.Health <= 0 then
                removeESP(target)
            else
                local record = espRecords[target]
                if record and record.character ~= model then
                    removeESP(target)
                    record = nil
                end
                if not record then
                    record = {character = model}
                    espRecords[target] = record
                end
                if settings.ESP and not record.highlight then
                    record.highlight = make("Highlight", model, {
                        Name = "SigmaLocalHighlight",
                        Adornee = model,
                        FillColor = Color3.fromRGB(199, 110, 255),
                        OutlineColor = P.light,
                        FillTransparency = 0.65,
                        OutlineTransparency = 0.05,
                        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    })
                elseif not settings.ESP and record.highlight then
                    record.highlight:Destroy()
                    record.highlight = nil
                end
                if (settings.Names or settings.Distance or settings.HealthESP) and not record.billboard then
                    local billboard = make("BillboardGui", mainGui, {
                        Name = "SigmaNameESP",
                        Adornee = anchor,
                        Size = UDim2.fromOffset(190, 36),
                        StudsOffset = Vector3.new(0, 2.8, 0),
                        AlwaysOnTop = true,
                        MaxDistance = 1500
                    })
                    local nameLabel = label(billboard, "", 13, true, P.light)
                    nameLabel.Size = UDim2.fromScale(1, 1)
                    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
                    nameLabel.TextStrokeTransparency = 0.25
                    record.billboard = billboard
                    record.nameLabel = nameLabel
                elseif not (settings.Names or settings.Distance or settings.HealthESP) and record.billboard then
                    record.billboard:Destroy()
                    record.billboard = nil
                    record.nameLabel = nil
                end
                if record.highlight then
                    local distance = rootPart and (rootPart.Position - anchor.Position).Magnitude or 0
                    record.highlight.Enabled = distance <= settings.ESPRange
                    record.highlight.FillTransparency = settings.OnlyOutline and 1
                        or settings.ESPOpacity / 100
                    record.highlight.DepthMode = settings.ESPThroughWalls
                        and Enum.HighlightDepthMode.AlwaysOnTop
                        or Enum.HighlightDepthMode.Occluded
                    local hue = (os.clock() * 0.13) % 1
                    record.highlight.FillColor = settings.RainbowESP
                        and Color3.fromHSV(hue, 0.85, 1)
                        or (settings.TeamColors and target.TeamColor.Color or P.purple)
                    record.highlight.OutlineColor = settings.TeamColors
                        and target.TeamColor.Color or P.light
                end
                if record.nameLabel then
                    local parts = {}
                    if settings.Names then table.insert(parts, target.DisplayName) end
                    local distance = rootPart and (rootPart.Position - anchor.Position).Magnitude or 0
                    if settings.Distance and rootPart then
                        table.insert(parts, tostring(math.floor(distance)) .. " studs")
                    end
                    if settings.HealthESP then
                        table.insert(parts, "HP " .. tostring(math.floor(targetHum.Health))
                            .. "/" .. tostring(math.floor(targetHum.MaxHealth)))
                    end
                    record.nameLabel.Text = table.concat(parts, "  |  ")
                    record.billboard.Enabled = (distance <= settings.ESPRange)
                    record.nameLabel.TextColor3 = settings.TeamColors and target.TeamColor.Color or P.light
                end
            end
        end
    end
    for target in pairs(espRecords) do
        if not current[target] then removeESP(target) end
    end
end

connect(Players.PlayerRemoving, removeESP)
connect(UIS.JumpRequest, function()
    if settings.InfiniteJump and humanoid and humanoid.Parent then
        pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
    end
end)

-- PERFORMANCE: fast collision loop, throttled movement and ESP refresh.
local movementAccum, espAccum, staminaAccum, lightingAccum = 0, 0, 0, 0
connect(RunService.Stepped, updateNoclip)
connect(RunService.Heartbeat, function(dt)
    movementAccum = movementAccum + dt
    espAccum = espAccum + dt
    staminaAccum = staminaAccum + dt
    lightingAccum = lightingAccum + dt
    if movementAccum >= 0.07 then
        movementAccum = 0
        if not humanoid and player.Character then bindCharacter(player.Character) end
        updateMovement()
    end
    if espAccum >= 0.23 then
        espAccum = 0
        syncESP()
    end
    if staminaAccum >= 0.16 then
        staminaAccum = 0
        refillStamina()
    end
    if lightingAccum >= 0.4 then
        lightingAccum = 0
        if settings.Fullbright then
            Lighting.Brightness = 3
            Lighting.ClockTime = settings.NightMode and 0 or 14
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        elseif settings.NightMode then
            Lighting.ClockTime = 0
        end
        if settings.DisableShadows then
            Lighting.GlobalShadows = false
        end
        if settings.NoFog then
            Lighting.FogStart = 0
            Lighting.FogEnd = 1000000
        end
        local camera = workspace.CurrentCamera
        if camera and settings.WideFOV then
            camera.FieldOfView = settings.FOVValue
        end
    end
end)

cleanupFeatures = function()
    settings.FakeLag = false
    stopFakeLag()
    restoreCollision()
    restoreMovement()
    stopESP()
    restoreLighting()
    local camera = workspace.CurrentCamera
    if camera then camera.FieldOfView = originalFOV end
    pcall(extraCleanup)
end

-- MOBILE QUICK SPRINT: touch button, separate from the draggable launcher.
local runButton = make("TextButton", launcherGui, {
    Name = "QuickSprint",
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -22, 1, -110),
    Size = UDim2.fromOffset(74, 50),
    BackgroundColor3 = P.card,
    Text = "RUN",
    TextColor3 = P.light,
    TextSize = 15,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    Visible = false
})
rounded(runButton, 100)
outline(runButton, P.purple, 1.4, 0.25)
pressEffect(runButton)
connect(runButton.MouseButton1Click, function()
    quickSprint = not quickSprint
    runButton.Text = quickSprint and "RUN ON" or "RUN"
    tween(runButton, 0.2, {
        BackgroundColor3 = quickSprint and P.dark or P.card,
        TextColor3 = quickSprint and P.white or P.light
    })
end)

-- ===========================================================================
-- RELEASE 3.0: EXTENDED LOCAL FEATURES, MOBILE HUD AND INTERACTIVE ACTIONS
-- ===========================================================================

local toastFrame = make("Frame", launcherGui, {
    Name = "SigmaToast",
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, -80),
    Size = UDim2.fromOffset(280, 53),
    BackgroundColor3 = P.card2,
    Visible = false
})
rounded(toastFrame, 24)
outline(toastFrame, P.purple, 1.1, 0.15)
local toastLabel = label(toastFrame, "", 12, true, P.white)
toastLabel.TextXAlignment = Enum.TextXAlignment.Center
toastLabel.Size = UDim2.fromScale(1, 1)
local toastSerial = 0
local function notify(message)
    if not settings.ShowToasts then return end
    toastSerial = toastSerial + 1
    local id = toastSerial
    toastLabel.Text = "✦ " .. tostring(message)
    toastFrame.Visible = true
    toastFrame.Position = UDim2.new(0.5, 0, 0, -80)
    tween(toastFrame, 0.34, {
        Position = UDim2.new(0.5, 0, 0, 16)
    }, Enum.EasingStyle.Back)
    task.delay(2.1, function()
        if id ~= toastSerial or not toastFrame.Parent then return end
        local t = tween(toastFrame, 0.27, {
            Position = UDim2.new(0.5, 0, 0, -80)
        })
        if t then t.Completed:Wait() end
        if id == toastSerial and toastFrame.Parent then
            toastFrame.Visible = false
        end
    end)
end

-- MOBILE ACTION BUTTONS
local function quickButton(name, textValue, x)
    local button = make("TextButton", launcherGui, {
        Name = name,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, x, 1, -165),
        Size = UDim2.fromOffset(75, 48),
        BackgroundColor3 = P.card2,
        Text = textValue,
        TextColor3 = P.light,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        AutoButtonColor = false,
        Visible = false
    })
    rounded(button, 100)
    outline(button, P.purple, 1.25, 0.20)
    pressEffect(button)
    return button
end
local quickNoclip = quickButton("QuickNoclip", "CLIP", -20)
local quickJump = quickButton("QuickJump", "JUMP", -104)
local quickFakeLag = quickButton("QuickFakeLag", "LAG", -188)

local function refreshQuickButtons()
    if not settings.ShowQuickRun then
        quickSprint = false
        runButton.Text = "RUN"
    end
    runButton.Visible = settings.ShowQuickRun
    quickNoclip.Visible = settings.ShowQuickNoclip
    quickJump.Visible = settings.ShowQuickJump
    quickFakeLag.Visible = settings.ShowQuickFakeLag
    quickFakeLag.Text = settings.FakeLag and "LAG ON" or "LAG"
    quickFakeLag.BackgroundColor3 = settings.FakeLag and P.dark or P.card2
    quickNoclip.Text = settings.Noclip and "NOCLIP ✓" or "CLIP"
    quickNoclip.BackgroundColor3 = settings.Noclip and P.dark or P.card2
end
connect(quickNoclip.MouseButton1Click, function()
    settings.Noclip = not settings.Noclip
    if not settings.Noclip then restoreCollision() end
    if toggleRefresh.Noclip then toggleRefresh.Noclip() end
    refreshQuickButtons()
    notify(settings.Noclip and "Noclip enabled locally" or "Noclip disabled")
end)
connect(quickJump.MouseButton1Click, function()
    if humanoid and humanoid.Parent then
        humanoid.Jump = true
        pcall(function()
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end
end)
connect(quickFakeLag.MouseButton1Click, function()
    settings.FakeLag = not settings.FakeLag
    if settings.FakeLag then startFakeLag() else stopFakeLag() end
    if toggleRefresh.FakeLag then toggleRefresh.FakeLag() end
    refreshQuickButtons()
    notify(settings.FakeLag and ("Run in place • " .. fakeLagReport)
        or "Run in place disabled")
end)

-- LOCAL CAMERA CONTROLS
local originalCameraMode = player.CameraMode
local originalMinZoom = player.CameraMinZoomDistance
local originalMaxZoom = player.CameraMaxZoomDistance
local originalAutoRotate = true
local originalCameraOffset = Vector3.new(0, 0, 0)
local spectateIndex = 0
local spectateTarget = nil
local currentCamera = workspace.CurrentCamera
local function getHumanoid()
    return humanoid and humanoid.Parent and humanoid or nil
end
local function resetSpectate()
    spectateTarget = nil
    local cam = workspace.CurrentCamera
    if cam and getHumanoid() then
        cam.CameraSubject = humanoid
    end
end
local function spectate(step)
    local targets = {}
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player and other.Character then
            local h = other.Character:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then table.insert(targets, other) end
        end
    end
    table.sort(targets, function(a,b) return a.Name < b.Name end)
    if #targets == 0 then
        notify("No players to spectate")
        resetSpectate()
        return
    end
    spectateIndex = ((spectateIndex + step - 1) % #targets) + 1
    spectateTarget = targets[spectateIndex]
    local h = spectateTarget.Character:FindFirstChildOfClass("Humanoid")
    local cam = workspace.CurrentCamera
    if cam then cam.CameraSubject = h end
    notify("Spectating " .. spectateTarget.DisplayName)
end
local function restoreCameraSettings()
    player.CameraMode = originalCameraMode
    player.CameraMinZoomDistance = originalMinZoom
    player.CameraMaxZoomDistance = originalMaxZoom
    local cam = workspace.CurrentCamera
    if cam then
        cam.FieldOfView = originalFOV
        if getHumanoid() then cam.CameraSubject = humanoid end
    end
    if getHumanoid() then
        humanoid.CameraOffset = originalCameraOffset
        humanoid.AutoRotate = originalAutoRotate
    end
    spectateTarget = nil
end

local function captureCharacterExtras()
    local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if h then
        originalCameraOffset = h.CameraOffset
        originalAutoRotate = h.AutoRotate
    end
end
captureCharacterExtras()
connect(player.CharacterAdded, function(ch)
    task.defer(function()
        local h = ch:WaitForChild("Humanoid", 8)
        local rp = ch:WaitForChild("HumanoidRootPart", 8)
        if player.Character ~= ch or not h then return end
        bindCharacter(ch)
        if rp then rootPart = rp end
        originalCameraOffset = h.CameraOffset
        originalAutoRotate = h.AutoRotate
        if spectateTarget == nil and workspace.CurrentCamera then
            workspace.CurrentCamera.CameraSubject = h
        end
    end)
end)

-- LOCAL GRAPHICS: own postprocessing, do not edit existing effects.
local correction = make("ColorCorrectionEffect", Lighting, {
    Name = "SigmaV2ColorCorrection",
    Enabled = false
})
local bloom = make("BloomEffect", Lighting, {
    Name = "SigmaV2Bloom", Enabled = false,
    Intensity = 1, Threshold = 1.1, Size = 24
})
local blur = make("BlurEffect", Lighting, {
    Name = "SigmaV2Blur", Enabled = false,
    Size = 8
})
local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
local oldCloudCover = clouds and clouds.Cover or nil
local oldCloudDensity = clouds and clouds.Density or nil
local selfHighlight = nil
local function updateSelfHighlight()
    local model = player.Character
    if not settings.SelfHighlight or not model then
        if selfHighlight then selfHighlight:Destroy(); selfHighlight = nil end
        return
    end
    if not selfHighlight or selfHighlight.Parent ~= model then
        if selfHighlight then selfHighlight:Destroy() end
        selfHighlight = make("Highlight", model, {
            Name = "SigmaLocalSelfHighlight",
            Adornee = model,
            FillColor = P.purple,
            OutlineColor = P.light,
            FillTransparency = 0.7,
            DepthMode = Enum.HighlightDepthMode.Occluded
        })
    end
    selfHighlight.FillColor = settings.RainbowESP and
        Color3.fromHSV((os.clock() * .12) % 1, .85, 1) or P.purple
end
local function restoreWorldExtras()
    correction.Enabled = false
    bloom.Enabled = false
    blur.Enabled = false
    if clouds and clouds.Parent then
        if oldCloudCover ~= nil then clouds.Cover = oldCloudCover end
        if oldCloudDensity ~= nil then clouds.Density = oldCloudDensity end
    end
    Lighting.GlobalShadows = originalLighting.GlobalShadows
    Lighting.ClockTime = originalLighting.ClockTime
    Lighting.ExposureCompensation = originalLighting.ExposureCompensation
end
local function applyWorldExtras()
    correction.Enabled = settings.HighSaturation or settings.HighContrast
        or settings.NightVision
    correction.Saturation = settings.HighSaturation
        and settings.SaturationValue / 100 or 0
    correction.Contrast = settings.HighContrast
        and settings.ContrastValue / 100 or 0
    correction.TintColor = settings.NightVision
        and Color3.fromRGB(135, 255, 168) or Color3.new(1,1,1)
    correction.Brightness = settings.NightVision and .13 or 0
    bloom.Enabled = settings.BloomEffect
    bloom.Intensity = settings.BloomValue / 10
    blur.Enabled = settings.BlurEffect
    blur.Size = settings.BlurValue
    if settings.ColorCycle then
        local color = Color3.fromHSV((os.clock() * .05) % 1, .45, 1)
        Lighting.Ambient = color
    end
    if settings.RemoveClouds and clouds and clouds.Parent then
        clouds.Cover = 0
        clouds.Density = 0
    end
end

-- AUDIO CONTROLS: changes local Sound.Volume, reversible when disabled.
local audioOriginal = {}
local function restoreAudio()
    for sound, volume in pairs(audioOriginal) do
        if sound and sound.Parent then
            pcall(function() sound.Volume = volume end)
        end
        audioOriginal[sound] = nil
    end
end
local function isMusic(sound)
    local name = sound.Name:lower()
    return name:find("music", 1, true) ~= nil
        or name:find("theme", 1, true) ~= nil
        or name:find("bgm", 1, true) ~= nil
        or name:find("soundtrack", 1, true) ~= nil
end
local function applyAudio()
    local volumeFactor = settings.VolumePercent / 100
    local needsAudio = settings.MuteAll or settings.QuietMode
        or settings.MuteMusic or settings.VolumePercent ~= 100
    if not needsAudio then
        if next(audioOriginal) then restoreAudio() end
        return
    end
    for _, container in ipairs({workspace, game:GetService("SoundService"), playerGui}) do
        for _, sound in ipairs(container:GetDescendants()) do
            if sound:IsA("Sound") then
                if audioOriginal[sound] == nil then
                    audioOriginal[sound] = sound.Volume
                end
                local v = audioOriginal[sound] * volumeFactor
                if settings.QuietMode then v = v * .25 end
                if settings.MuteAll or
                    (settings.MuteMusic and isMusic(sound)) then
                    v = 0
                end
                if math.abs(sound.Volume - v) > .001 then
                    pcall(function() sound.Volume = v end)
                end
            end
        end
    end
end

-- HUD: compact, draggable UI survives minimize and works independently.
local hudBox = make("Frame", launcherGui, {
    Name = "SigmaStatsHUD",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -12, 0, 18),
    Size = UDim2.fromOffset(204, 165),
    BackgroundColor3 = P.bg,
    BackgroundTransparency = 0.13,
    Visible = false
})
rounded(hudBox, 20)
outline(hudBox, P.dark, 1, 0.25)
local hudTitle = label(hudBox, "Σ  LIVE STATUS", 13, true, P.light)
hudTitle.Position = UDim2.fromOffset(14, 10)
hudTitle.Size = UDim2.new(1, -25, 0, 24)
local hudBody = label(hudBox, "", 12, false, P.white)
hudBody.Position = UDim2.fromOffset(14, 38)
hudBody.Size = UDim2.new(1, -24, 1, -48)
hudBody.TextYAlignment = Enum.TextYAlignment.Top
hudBody.TextWrapped = false
local hudScaleObj = make("UIScale", hudBox, {Scale = 1})
local crosshair = label(launcherGui, "+", 32, true, P.light)
crosshair.Name = "SigmaCrosshair"
crosshair.AnchorPoint = Vector2.new(.5,.5)
crosshair.Position = UDim2.fromScale(.5,.5)
crosshair.Size = UDim2.fromOffset(50,50)
crosshair.TextXAlignment = Enum.TextXAlignment.Center
crosshair.Visible = false
crosshair.TextStrokeTransparency = .45

local fpsSmoothed = 60
connect(RunService.RenderStepped, function(dt)
    if dt > 0 then
        local instantaneous = math.clamp(1/dt, 1, 240)
        fpsSmoothed = fpsSmoothed * .91 + instantaneous * .09
    end
end)
local function updateHUD()
    local lines = {}
    local h = getHumanoid()
    local root = rootPart and rootPart.Parent and rootPart
    if settings.FPSHUD then
        table.insert(lines, "FPS: " .. math.floor(fpsSmoothed+.5))
    end
    if settings.SpeedHUD and root then
        local v = root.AssemblyLinearVelocity
        table.insert(lines, "Speed: " .. math.floor(Vector3.new(v.X,0,v.Z).Magnitude+.5) .. " studs/s")
    end
    if settings.CoordinatesHUD and root then
        local p = root.Position
        table.insert(lines, string.format("XYZ: %d  %d  %d",
            math.floor(p.X), math.floor(p.Y), math.floor(p.Z)))
    end
    if settings.HealthHUD and h then
        table.insert(lines, string.format("Health: %d/%d",
            math.floor(h.Health), math.floor(h.MaxHealth)))
    end
    if settings.PlayerHUD then
        table.insert(lines, "Players: " .. #Players:GetPlayers())
    end
    if settings.ClockHUD then
        table.insert(lines, "Game clock: " .. string.format("%.1f", Lighting.ClockTime))
    end
    hudBox.Visible = #lines > 0
    hudBody.Text = table.concat(lines, "\n")
    hudBox.Size = UDim2.fromOffset(220, math.max(62, 50 + #lines * 23))
    hudScaleObj.Scale = settings.HUDScale/100
    crosshair.Visible = settings.Crosshair
end

-- CURRENT THEME ACCENT: updates accent references and visible elements.
local themes = {
    {name = "Violet", color = Color3.fromRGB(173,91,255)},
    {name = "Cyan", color = Color3.fromRGB(48,211,255)},
    {name = "Rose", color = Color3.fromRGB(255,105,174)},
    {name = "Emerald", color = Color3.fromRGB(76,230,172)},
    {name = "Gold", color = Color3.fromRGB(255,196,86)}
}
local themeIndex = 1
local function nextTheme()
    themeIndex = themeIndex % #themes + 1
    local chosen = themes[themeIndex]
    P.purple = chosen.color
    P.light = chosen.color:Lerp(Color3.new(1,1,1), .3)
    tween(mainStroke, .3, {Color = P.purple})
    tween(floatRing, .3, {Color = P.purple})
    tween(glowRing, .3, {Color = P.light})
    tween(accentStrip, .3, {BackgroundColor3 = P.purple})
    tween(floating, .3, {TextColor3 = P.light})
    tween(logoSymbol, .3, {TextColor3 = P.light})
    tween(logoName, .3, {TextColor3 = P.light})
    tween(runButton, .3, {TextColor3 = P.light})
    tween(quickNoclip, .3, {TextColor3 = P.light})
    tween(quickJump, .3, {TextColor3 = P.light})
    tween(quickFakeLag, .3, {TextColor3 = P.light})
    hudTitle.TextColor3 = P.light
    crosshair.TextColor3 = P.light
    nav.ScrollBarImageColor3 = P.purple
    notify("Theme: " .. chosen.name)
end

-- Apply repeating LOCAL features at a measured cadence (avoid a per-frame GUI rebuild).
local extraAccum, hudAccum, soundAccum = 0, 0, 0
local jumpAccum = 0
connect(RunService.Heartbeat, function(dt)
    extraAccum = extraAccum + dt
    hudAccum = hudAccum + dt
    soundAccum = soundAccum + dt
    jumpAccum = jumpAccum + dt
    if extraAccum >= .28 then
        extraAccum = 0
        local h = getHumanoid()
        if h then
            if settings.NoSit and h.Sit then h.Sit = false end
            h.AutoRotate = settings.AutoRotate and originalAutoRotate or false
            h.CameraOffset = settings.CameraOffset and
                Vector3.new(settings.CameraOffsetX,0,0) or originalCameraOffset
            if settings.AutoJump and jumpAccum >= .85
                and h.MoveDirection.Magnitude > .05
                and h.FloorMaterial ~= Enum.Material.Air then
                jumpAccum = 0
                h.Jump = true
            end
        end
        if settings.FirstPerson then
            player.CameraMode = Enum.CameraMode.LockFirstPerson
        elseif player.CameraMode ~= originalCameraMode then
            player.CameraMode = originalCameraMode
        end
        if settings.UnlockZoom then
            player.CameraMinZoomDistance = .5
            player.CameraMaxZoomDistance = settings.ZoomMax
        elseif player.CameraMaxZoomDistance ~= originalMaxZoom then
            player.CameraMinZoomDistance = originalMinZoom
            player.CameraMaxZoomDistance = originalMaxZoom
        end
        updateSelfHighlight()
        applyWorldExtras()
        if spectateTarget and (not spectateTarget.Character
            or not spectateTarget.Character:FindFirstChildOfClass("Humanoid")) then
            resetSpectate()
        end
    end
    if hudAccum >= .35 then
        hudAccum = 0
        updateHUD()
    end
    if soundAccum >= 1.1 then
        soundAccum = 0
        applyAudio()
    end
end)

extraCleanup = function()
    restoreCameraSettings()
    restoreWorldExtras()
    restoreAudio()
    if selfHighlight then selfHighlight:Destroy(); selfHighlight = nil end
    if correction.Parent then correction:Destroy() end
    if bloom.Parent then bloom:Destroy() end
    if blur.Parent then blur:Destroy() end
end

-- ===========================================================================
-- RELEASE 5.0: KILLER MARKERS + ATTACK DETECTION
-- Default remains an M1 whitelist. Experimental "All attacks" recognizes
-- additional published IDs and attack-like animation names, and an optional
-- proximity guard can attempt defense against unknown attacks.
-- This CANNOT make Guest immune, ignore ability rules or bypass cooldowns.
-- ===========================================================================
local Combat = {}
do
local killerRecords = {}
local killerPollTimer = 0
local blockAttemptAt = -1e9
local blockReport = "No attack detected"

-- Strict ID whitelist: Slasher / c00lkidd / 1x1x1x1 BASE M1 only.
-- Not used: generic 'Attack' or 'Slash' names, as they can match abilities.
local basicM1Animations = {
    ["126830014841198"] = "Slasher M1",
    ["18885909645"] = "c00lkidd M1",
    ["83829782357897"] = "1x1x1x1 M1",
    ["105458270463374"] = "John Doe Slash",
    ["94162446513587"] = "John Doe !Joner Slash",
    ["73656797029876"] = "Noli Ssampong M4 Slash"
}
-- Community-listed ability IDs; not independently verified for current skins.
local extraAttackAnimations = {
    ["126355327951215"] = "Slasher Behead",
    ["121086746534252"] = "Slasher Gashing Wound",
    ["98456918873918"] = "c00lkidd Walkspeed Override",
    ["127172483138092"] = "John Doe Corrupt Energy"
}
local attackWords = {
    "attack", "slash", "punch", "strike", "stab", "swing", "bite", "claw",
    "behead", "wound", "rush", "dash", "pierce", "lunge", "smash",
    "kick", "hit", "corrupt", "energy", "skill", "ability", "override",
    "execute", "grasp", "charge", "dive", "projectile"
}
local movementWords = {
    "idle", "walk", "running", "sprinting", "jump", "fall", "land",
    "climb", "swim", "emote", "dance", "stun", "death", "spawn",
    "breath", "victory", "pose", "spectate"
}

local function normalizedName(value)
    return tostring(value or ""):lower():gsub("[^a-z0-9]", "")
end

local function playingGuest1337()
    local c = player.Character
    if not c or not c.Parent then return false end
    if normalizedName(c.Name):find("guest1337", 1, true) then return true end
    for _, object in ipairs({c, player}) do
        for _, attr in ipairs({"Character", "CharacterName", "SurvivorName", "Survivor", "Class"}) do
            local value = object:GetAttribute(attr)
            if type(value) == "string" and
                normalizedName(value):find("guest1337", 1, true) then
                return true
            end
        end
    end
    return false
end

-- Forsaken commonly uses workspace.Players.Killers for the active round.
-- Team / Role fallback supports basic Roblox test places.
local function findActiveKillers()
    local models, used = {}, {}
    local container = workspace:FindFirstChild("Players")
    local folder = container and container:FindFirstChild("Killers")
    if folder then
        for _, obj in ipairs(folder:GetChildren()) do
            if obj:IsA("Model") and obj ~= player.Character then
                models[#models+1] = obj
                used[obj] = true
            end
        end
    else
        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= player and other.Character then
                local role = other:GetAttribute("Role")
                    or other.Character:GetAttribute("Role")
                    or (other.Team and other.Team.Name)
                if normalizedName(role):find("killer", 1, true)
                    and not used[other.Character] then
                    models[#models+1] = other.Character
                    used[other.Character] = true
                end
            end
        end
    end
    return models
end

local function destroyKillerRecord(model)
    local record = killerRecords[model]
    if not record then return end
    if record.attackConnection then record.attackConnection:Disconnect() end
    for _, obj in ipairs({record.aura, record.range, record.label}) do
        if obj then obj:Destroy() end
    end
    killerRecords[model] = nil
end

local function clearAllKillerRecords()
    for model in pairs(killerRecords) do destroyKillerRecord(model) end
end

local function getVisibleBlockButton()
    -- Search only normal game UI; never accidentally click our own UI.
    for _, obj in ipairs(playerGui:GetDescendants()) do
        if obj:IsA("GuiButton") and obj.Visible
            and obj.AbsoluteSize.X > 5 and obj.AbsoluteSize.Y > 5
            and not obj:IsDescendantOf(mainGui)
            and not obj:IsDescendantOf(launcherGui) then
            local name = normalizedName(obj.Name)
            local caption = obj:IsA("TextButton") and normalizedName(obj.Text) or ""
            if name == "block" or name == "blockbutton" or caption == "block" then
                return obj
            end
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("TextLabel") and normalizedName(child.Text) == "block" then
                    return obj
                end
            end
        end
    end
    return nil
end

local function trySendBlock()
    -- CLIENT INPUT ONLY, no guessed server remotes.
    local okService, vim = pcall(function()
        return game:GetService("VirtualInputManager")
    end)
    local button = getVisibleBlockButton()
    if button and okService and vim then
        local pos = button.AbsolutePosition + button.AbsoluteSize / 2
        local ok = pcall(function()
            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
        end)
        if ok then return true, "Mobile Block button" end
    end
    if okService and vim then
        local ok = pcall(function()
            vim:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
            vim:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
        end)
        if ok then return true, "Q key" end
    end
    -- Executor-specific last resort; not guaranteed on iPad.
    local down = keypress
    local up = keyrelease
    if type(down) == "function" and type(up) == "function" then
        local ok = pcall(function()
            down(0x51)
            up(0x51)
        end)
        if ok then return true, "Q simulated" end
    end
    return false, "Block input unsupported by this executor"
end

local function attackFromTrack(track)
    if not track or not track.Animation then return nil, nil end
    local anim = track.Animation
    local id = tostring(anim.AnimationId or ""):match("(%d+)")
    if id and basicM1Animations[id] then
        return basicM1Animations[id], "M1"
    end
    if id and extraAttackAnimations[id] then
        return extraAttackAnimations[id], "Ability"
    end
    local rawName = tostring(anim.Name or "") .. " " .. tostring(track.Name or "")
    local key = rawName:lower():gsub("[^%a]", "")
    for _, word in ipairs(movementWords) do
        if key:find(word, 1, true) then return nil, nil end
    end
    for _, word in ipairs(attackWords) do
        if key:find(word, 1, true) then
            return "Animation " .. tostring(anim.Name), "UnknownAttack"
        end
    end
    return nil, nil
end

local function attemptBlock(model, attackLabel)
    if not playingGuest1337() then
        blockReport = "Not Guest 1337"
        return false
    end
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local killerRoot = model and model:FindFirstChild("HumanoidRootPart")
    local killerHum = model and model:FindFirstChildOfClass("Humanoid")
    if not myRoot or not killerRoot or (killerHum and killerHum.Health <= 0) then
        return false
    end
    local distance = (myRoot.Position - killerRoot.Position).Magnitude
    if distance > settings.GuestBlockRange then return false end
    local now = os.clock()
    -- Cooldown slider uses CENTISECONDS, not literal seconds.
    if now - blockAttemptAt < settings.GuestBlockCooldown / 100 then return false end
    blockAttemptAt = now
    local ok, method = trySendBlock()
    blockReport = attackLabel .. " | " .. (ok and "Input sent" or "Input unavailable")
    if settings.GuestBlockAlerts then
        notify(ok and ("Guard attempted: " .. attackLabel .. " via " .. method)
            or ("Guard failed: " .. method))
    end
    return ok
end

local function reactToAttack(model, track)
    if not (settings.GuestAutoBlock or settings.GuestBlockAll) then return end
    local attack, kind = attackFromTrack(track)
    if not attack then return end
    if settings.GuestAutoBlock and kind == "M1" then
        attemptBlock(model, attack)
    elseif settings.GuestBlockAll then
        attemptBlock(model, attack .. " [" .. kind .. "]")
    end
end

local function updateProximityGuard()
    if not settings.GuestProximityGuard or not playingGuest1337() then return end
    local mine = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not mine then return end
    for _, model in ipairs(findActiveKillers()) do
        local root = model:FindFirstChild("HumanoidRootPart")
        local hum = model:FindFirstChildOfClass("Humanoid")
        if root and hum and hum.Health > 0 then
            local offset = mine.Position - root.Position
            local distance = offset.Magnitude
            if distance > 0.25 and distance <= settings.GuestBlockRange then
                local direction = offset.Unit
                local facing = root.CFrame.LookVector:Dot(direction)
                local speedToward = root.AssemblyLinearVelocity:Dot(direction)
                -- Early warning attempt, not actual attack detection.
                if facing > 0.35 and speedToward > 4 then
                    attemptBlock(model, "Close-range approach")
                    break
                end
            end
        end
    end
end

local function updateKillers()
    local visual = settings.KillerHitbox or settings.KillerAura or settings.KillerLabel
    if not visual and not (settings.GuestAutoBlock or settings.GuestBlockAll
        or settings.GuestProximityGuard) then
        if next(killerRecords) then clearAllKillerRecords() end
        return
    end

    local active = {}
    for _, model in ipairs(findActiveKillers()) do
        local root = model:FindFirstChild("HumanoidRootPart")
        local hum = model:FindFirstChildOfClass("Humanoid")
        if root and hum and hum.Health > 0 then
            active[model] = true
            local record = killerRecords[model]
            if not record then
                record = {}
                killerRecords[model] = record
            end

            local animator = hum:FindFirstChildOfClass("Animator")
            if record.animator ~= animator then
                if record.attackConnection then record.attackConnection:Disconnect() end
                record.attackConnection = nil
                record.animator = animator
                if animator and (settings.GuestAutoBlock or settings.GuestBlockAll) then
                    record.attackConnection = animator.AnimationPlayed:Connect(function(track)
                        reactToAttack(model, track)
                    end)
                end
            elseif animator and (settings.GuestAutoBlock or settings.GuestBlockAll)
                and not record.attackConnection then
                record.attackConnection = animator.AnimationPlayed:Connect(function(track)
                    reactToAttack(model, track)
                end)
            elseif not (settings.GuestAutoBlock or settings.GuestBlockAll)
                and record.attackConnection then
                record.attackConnection:Disconnect()
                record.attackConnection = nil
            end

            if settings.KillerAura then
                if not record.aura then
                    record.aura = make("Highlight", mainGui, {
                        Name = "SigmaKillerAura", Adornee = model,
                        FillColor = Color3.fromRGB(255, 52, 83),
                        OutlineColor = Color3.fromRGB(255, 204, 48),
                        FillTransparency = .67,
                        OutlineTransparency = 0,
                        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    })
                end
            elseif record.aura then
                record.aura:Destroy()
                record.aura = nil
            end

            if settings.KillerHitbox then
                if not record.range then
                    record.range = make("SphereHandleAdornment", mainGui, {
                        Name = "SigmaKillerThreatRadius",
                        Adornee = root,
                        AlwaysOnTop = true,
                        Color3 = Color3.fromRGB(255, 100, 45),
                        Transparency = .78,
                        Radius = settings.KillerRadius
                    })
                end
                record.range.Radius = settings.KillerRadius
                record.range.Transparency = settings.KillerMarkerOpacity / 100
            elseif record.range then
                record.range:Destroy()
                record.range = nil
            end

            if settings.KillerLabel then
                if not record.label then
                    local billboard = make("BillboardGui", mainGui, {
                        Name = "SigmaKillerTag", Adornee = root,
                        AlwaysOnTop = true, MaxDistance = 1500,
                        Size = UDim2.fromOffset(190, 43),
                        StudsOffsetWorldSpace = Vector3.new(0, 4.0, 0)
                    })
                    local title = label(billboard, "", 16, true,
                        Color3.fromRGB(255, 120, 85))
                    title.Size = UDim2.fromScale(1, 1)
                    title.TextXAlignment = Enum.TextXAlignment.Center
                    title.TextStrokeTransparency = .15
                    record.label = billboard
                    record.labelText = title
                end
                local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                local studs = myRoot and math.floor((root.Position - myRoot.Position).Magnitude) or nil
                record.labelText.Text = "⚠ KILLER" .. (studs and (" • " .. studs .. " STUDS") or "")
            elseif record.label then
                record.label:Destroy()
                record.label = nil
                record.labelText = nil
            end
        end
    end
    for model in pairs(killerRecords) do
        if not active[model] then destroyKillerRecord(model) end
    end
end

connect(RunService.Heartbeat, function(dt)
    killerPollTimer = killerPollTimer + dt
    if killerPollTimer >= .12 then
        killerPollTimer = 0
        updateKillers()
        updateProximityGuard()
    end
end)

-- Incorporate combat cleanup into existing safe Unload pipeline.
local oldExtraCleanup = extraCleanup
extraCleanup = function()
    clearAllKillerRecords()
    oldExtraCleanup()
end

local function resetCombat()
    for _, key in ipairs({"KillerHitbox", "KillerAura", "KillerLabel",
        "GuestAutoBlock", "GuestBlockAll", "GuestProximityGuard", "GuestBlockAlerts"}) do
        settings[key] = false
        if toggleRefresh[key] then toggleRefresh[key]() end
    end
    clearAllKillerRecords()
    blockReport = "Reset"
end

Combat.updateKillers = updateKillers
Combat.clearAllKillerRecords = clearAllKillerRecords
Combat.findActiveKillers = findActiveKillers
Combat.playingGuest1337 = playingGuest1337
Combat.resetCombat = resetCombat
Combat.getBlockReport = function() return blockReport end
end

local function resetAllExtras()
    for _, key in ipairs({
        "AutoJump", "NoSit", "HealthESP", "TeamColors", "OnlyOutline",
        "RainbowESP", "SelfHighlight", "FirstPerson", "UnlockZoom",
        "CameraOffset", "NightMode", "DisableShadows", "HighSaturation",
        "HighContrast", "BloomEffect", "BlurEffect", "NightVision",
        "ColorCycle", "RemoveClouds", "FPSHUD", "SpeedHUD",
        "CoordinatesHUD", "PlayerHUD", "ClockHUD", "HealthHUD",
        "Crosshair", "MuteAll", "QuietMode", "MuteMusic"
    }) do
        settings[key] = false
        if toggleRefresh[key] then toggleRefresh[key]() end
    end
    settings.ESPThroughWalls = true
    settings.AutoRotate = true
    settings.HUDScale = 100
    if sliderRefresh["HUD size"] then sliderRefresh["HUD size"](100) end
    if toggleRefresh.ESPThroughWalls then toggleRefresh.ESPThroughWalls() end
    if toggleRefresh.AutoRotate then toggleRefresh.AutoRotate() end
    settings.VolumePercent = 100
    if sliderRefresh["Volume percent"] then
        sliderRefresh["Volume percent"](100)
    end
    restoreAudio()
    restoreCameraSettings()
    restoreWorldExtras()
    updateSelfHighlight()
    updateHUD()
end


-- ===========================================================================
-- RELEASE 3.0 PAGES: ALL CONTROLS HAVE A CLIENT-SIDE CALLBACK / EFFECT
-- ===========================================================================
local function setToggle(key, value)
    settings[key] = value
    if toggleRefresh[key] then toggleRefresh[key]() end
end
local function resetEverything()
    quickSprint = false
    runButton.Text = "RUN"
    for _, key in ipairs({
        "Sprint", "Speed", "Noclip", "JumpBoost", "InfiniteJump",
        "Stamina", "ESP", "Names", "Distance", "Fullbright",
        "NoFog", "WideFOV", "FakeLag"
    }) do
        setToggle(key, false)
    end
    stopFakeLag()
    restoreCollision()
    restoreMovement()
    stopESP()
    restoreLighting()
    resetAllExtras()
    Combat.resetCombat()
    refreshQuickButtons()
    notify("Local settings reset")
end

-- HOME
card(home, "✦  SIGMASAKEN V2 • 5.0", "PC / Mobile grid, broad defense attempts and visual fake lag.")
card(home, "◉  PLAYER TOOLS", "Sprint, speed, noclip, jumping, mobile buttons and camera offset.")
card(home, "◇  VISUAL TOOLS", "Player highlights, names, health, team colors and range filters.")
card(home, "⚔  KILLER COMBAT", "M1 / ability animation guard, proximity guard and killer overlays.")
card(home, "◈  CAMERA + WORLD", "FOV, spectating, zoom, lighting and effects.")
card(home, "▤  HUD + AUDIO", "Live FPS, position, speed, health, player count and local audio.")
card(home, "ⓘ  HOW IT WORKS", "Client-only controls: a game server can override movement and stamina.")
addAction(home, "Show controls", "Test the animated notification", function()
    notify("SigmaSaken V2 is ready")
end)
addAction(home, "Reset all local effects", "Restore the movement, camera and world", resetEverything)

-- PLAYER
card(playerPage, "◉  MOVEMENT", "Local Humanoid controls. Server corrections are possible.")
addToggle(playerPage, "Sprint", "Always sprint locally", "Sprint")
addSlider(playerPage, "Sprint speed", 18, 60, 26, function(v) settings.SprintValue = v end)
addToggle(playerPage, "Speed Boost", "Set local walking speed", "Speed")
addSlider(playerPage, "Speed value", 16, 85, 36, function(v) settings.SpeedValue = v end)
addToggle(playerPage, "Noclip", "Disable local character collisions", "Noclip", function(on)
    if not on then restoreCollision() end
    refreshQuickButtons()
end)
addToggle(playerPage, "Jump Boost", "Increase your local jump power", "JumpBoost")
addSlider(playerPage, "Jump power", 50, 140, 75, function(v) settings.JumpValue = v end)
addToggle(playerPage, "Infinite Jump", "Request another jump while airborne", "InfiniteJump")
addToggle(playerPage, "Auto Jump", "Jump repeatedly while moving on ground", "AutoJump")
addToggle(playerPage, "No Sit", "Automatically stand when seated", "NoSit")
addToggle(playerPage, "Auto Rotate", "Turn your character towards movement", "AutoRotate", function(on)
    if getHumanoid() then humanoid.AutoRotate = on end
end)
addToggle(playerPage, "Infinite Stamina • experimental", "Only works with exposed local stamina values", "Stamina")
card(playerPage, "⚡  FAKE LAG • RUN IN PLACE", "Run animation while staying still. This is visual only, NOT actual network lag.")
addToggle(playerPage, "Fake Lag • Run in Place", "Animate running while staying in one spot", "FakeLag", function(on)
    if on then startFakeLag() else stopFakeLag() end
    refreshQuickButtons()
    notify(on and ("Fake Lag: " .. fakeLagReport) or "Fake Lag disabled")
end)
addToggle(playerPage, "Fake Lag Stutter", "Periodically pause frames of the running animation", "FakeLagStutter")
addSlider(playerPage, "Fake Lag animation speed", 5, 30, 16, function(v)
    settings.FakeLagAnimSpeed = v
end)
addAction(playerPage, "Fake Lag status", "Check whether a run animation was loaded", function()
    notify("Fake Lag: " .. fakeLagReport)
end)
addAction(playerPage, "Stop Fake Lag", "Resume standard movement and idle animation", function()
    setToggle("FakeLag", false)
    stopFakeLag()
    refreshQuickButtons()
    notify("Fake Lag stopped")
end)
card(playerPage, "⌁  QUICK MOBILE BUTTONS", "Show optional touch buttons even with the panel minimized.")
addToggle(playerPage, "Quick RUN button", "Show the floating run control", "ShowQuickRun", refreshQuickButtons)
addToggle(playerPage, "Quick NOCLIP button", "Toggle noclip without opening the menu", "ShowQuickNoclip", refreshQuickButtons)
addToggle(playerPage, "Quick JUMP button", "Jump from an extra touch control", "ShowQuickJump", refreshQuickButtons)
addToggle(playerPage, "Quick LAG button", "Show running-in-place shortcut on screen", "ShowQuickFakeLag", refreshQuickButtons)
addAction(playerPage, "Jump now", "Trigger a local Humanoid jump", function()
    if getHumanoid() then
        humanoid.Jump = true
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)
addAction(playerPage, "Turn noclip ON/OFF", "Instantly switch the collision setting", function()
    setToggle("Noclip", not settings.Noclip)
    if not settings.Noclip then restoreCollision() end
    refreshQuickButtons()
    notify("Noclip: " .. tostring(settings.Noclip))
end)
addAction(playerPage, "Reset movement", "Restore original speed, jump and collisions", function()
    for _, key in ipairs({"Sprint", "Speed", "Noclip", "JumpBoost", "InfiniteJump", "AutoJump", "NoSit", "Stamina"}) do
        setToggle(key, false)
    end
    quickSprint = false
    runButton.Text = "RUN"
    setToggle("FakeLag", false)
    stopFakeLag()
    restoreMovement()
    restoreCollision()
    refreshQuickButtons()
    notify("Movement reset")
end)

-- COMBAT / KILLER  (same square-grid page in BOTH PC and Mobile)
card(combatPage, "⚔  KILLER RADAR", "Highlights the active killer(s) detected in Workspace.Players.Killers.")
addToggle(combatPage, "Killer Aura", "Red highlight with a golden border", "KillerAura", Combat.updateKillers)
addToggle(combatPage, "Killer Hitbox Marker", "Orange sphere showing APPROXIMATE threat range", "KillerHitbox", Combat.updateKillers)
addSlider(combatPage, "Killer marker radius", 3, 20, 7, function(v)
    settings.KillerRadius = v
    Combat.updateKillers()
end)
addSlider(combatPage, "Killer marker transparency", 35, 95, 78, function(v)
    settings.KillerMarkerOpacity = v
    Combat.updateKillers()
end)
addToggle(combatPage, "Killer Warning Label", "Show KILLER and distance over the target", "KillerLabel", Combat.updateKillers)
card(combatPage, "⛨  GUEST 1337 DEFENSE", "M1 mode is selective; broad mode attempts abilities too, but cannot guarantee blocks.")
addToggle(combatPage, "Auto Block Guest M1", "React to known basic attack animations as Guest", "GuestAutoBlock", function(on)
    Combat.updateKillers()
    notify(on and "M1 guard enabled • Guest only" or "M1 guard disabled")
end)
addToggle(combatPage, "Auto Block All • experimental", "Try M1, known abilities and attack-named animations", "GuestBlockAll", function(on)
    Combat.updateKillers()
    notify(on and "Broad auto guard active; no guaranteed defense" or "Broad guard disabled")
end)
addToggle(combatPage, "Proximity Guard • experimental", "Attempt guard when a killer approaches facing you", "GuestProximityGuard", function(on)
    Combat.updateKillers()
    notify(on and "Approach-based guard; false positives possible" or "Proximity guard disabled")
end)
addSlider(combatPage, "Auto Block range", 5, 25, 13, function(v)
    settings.GuestBlockRange = v
end)
addSlider(combatPage, "Guard interval (centiseconds)", 8, 150, 27, function(v)
    settings.GuestBlockCooldown = v
end)
addToggle(combatPage, "Block Alerts", "Notify when defense input is attempted", "GuestBlockAlerts")
addAction(combatPage, "Check Guest + Killer", "Check your current character and nearby killers", function()
    local killers = Combat.findActiveKillers()
    notify((Combat.playingGuest1337() and "Guest 1337 OK" or "Guest 1337 not detected") ..
        " • " .. tostring(#killers) .. " killer(s)")
end)
addAction(combatPage, "Block status", "Show last detection / input result", function()
    notify(Combat.getBlockReport())
end)
addAction(combatPage, "Refresh Killer Markers", "Rebuild local overlays and animation listeners", function()
    Combat.clearAllKillerRecords()
    Combat.updateKillers()
    notify("Killer scan refreshed")
end)
addAction(combatPage, "Disable all Combat", "Remove markers and stop automatic blocking", function()
    Combat.resetCombat()
    notify("Combat options disabled")
end)
card(combatPage, "ⓘ  ATTACK COMPATIBILITY", "Some animation IDs/skins are unknown. Generic attack names can give false positives.")
card(combatPage, "ⓘ  SERVER AUTHORITY", "Guard cannot make Guest invulnerable; abilities may break block or only reduce damage.")

-- VISUALS
card(visuals, "◇  PLAYER OVERLAYS", "Rendered on your device; does not change other players.")
addToggle(visuals, "Player ESP", "Highlight other player characters", "ESP", syncESP)
addToggle(visuals, "Name ESP", "Display player display names", "Names", syncESP)
addToggle(visuals, "Distance ESP", "Show character distance in studs", "Distance", syncESP)
addToggle(visuals, "Health ESP", "Show local Humanoid health text", "HealthESP", syncESP)
addToggle(visuals, "Team Colors", "Use each player's TeamColor for highlight", "TeamColors", syncESP)
addToggle(visuals, "Only Outline", "Hide ESP fill and keep character outline", "OnlyOutline", syncESP)
addToggle(visuals, "ESP Through Walls", "Use AlwaysOnTop rather than Occluded", "ESPThroughWalls", syncESP)
addToggle(visuals, "Rainbow ESP", "Slowly cycle the ESP highlight color", "RainbowESP", syncESP)
addToggle(visuals, "Self Highlight", "Highlight your own character locally", "SelfHighlight", updateSelfHighlight)
addSlider(visuals, "ESP max range", 50, 1500, 600, function(v) settings.ESPRange = v end)
addSlider(visuals, "ESP fill transparency", 0, 100, 65, function(v) settings.ESPOpacity = v end)
addAction(visuals, "Refresh player overlays", "Rebuild all local ESP elements", function()
    stopESP()
    syncESP()
    notify("ESP refreshed")
end)
addAction(visuals, "Clear player overlays", "Disable all highlights and labels", function()
    for _, key in ipairs({"ESP","Names","Distance","HealthESP","SelfHighlight"}) do
        setToggle(key, false)
    end
    stopESP()
    updateSelfHighlight()
    notify("Overlays cleared")
end)

-- CAMERA
card(cameraPage, "◈  CAMERA CONTROLS", "Modify your local Roblox camera.")
addToggle(cameraPage, "Custom FOV", "Set the camera's FieldOfView", "WideFOV", function(on)
    if not on and workspace.CurrentCamera then
        workspace.CurrentCamera.FieldOfView = originalFOV
    end
end)
addSlider(cameraPage, "Field of view", 45, 120, 90, function(v) settings.FOVValue = v end)
addToggle(cameraPage, "First Person", "Set CameraMode to LockFirstPerson", "FirstPerson")
addToggle(cameraPage, "Unlock Camera Zoom", "Customize the maximum zoom distance", "UnlockZoom")
addSlider(cameraPage, "Max zoom", 10, 150, 50, function(v) settings.ZoomMax = v end)
addToggle(cameraPage, "Shoulder Offset", "Apply a horizontal Humanoid.CameraOffset", "CameraOffset")
addSlider(cameraPage, "Camera offset", -8, 8, 2, function(v) settings.CameraOffsetX = v end)
addAction(cameraPage, "Wide FOV preset", "Set 105° field of view", function()
    settings.FOVValue = 105
    if sliderRefresh["Field of view"] then
        sliderRefresh["Field of view"](105)
    end
    setToggle("WideFOV", true)
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = 105 end
    notify("FOV 105")
end)
addAction(cameraPage, "Normal FOV preset", "Restore the original field of view", function()
    setToggle("WideFOV", false)
    if sliderRefresh["Field of view"] then
        sliderRefresh["Field of view"](originalFOV)
    end
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = originalFOV end
    notify("FOV restored")
end)
addAction(cameraPage, "Spectate next player", "Switch CameraSubject to another player", function() spectate(1) end)
addAction(cameraPage, "Spectate previous player", "Cycle backwards through players", function() spectate(-1) end)
addAction(cameraPage, "Stop spectating", "Return camera view to your own character", function()
    resetSpectate()
    notify("Camera returned")
end)
addAction(cameraPage, "Reset camera settings", "Restore FOV, zoom, offset and camera mode", function()
    for _, key in ipairs({"WideFOV", "FirstPerson", "UnlockZoom", "CameraOffset"}) do
        setToggle(key, false)
    end
    restoreCameraSettings()
    notify("Camera settings reset")
end)

-- WORLD
card(worldPage, "✧  LOCAL WORLD EFFECTS", "These changes affect your screen, not the server.")
addToggle(worldPage, "Fullbright", "Bright lighting and ambient color", "Fullbright", function(on)
    if not on then restoreLighting() end
end)
addToggle(worldPage, "No Fog", "Extend local fog render distance", "NoFog", function(on)
    if not on then restoreLighting() end
end)
addToggle(worldPage, "Night Mode", "Set the local clock to midnight", "NightMode", function(on)
    if not on then Lighting.ClockTime = originalLighting.ClockTime end
end)
addToggle(worldPage, "Disable Shadows", "Turn off GlobalShadows locally", "DisableShadows", function(on)
    if not on then Lighting.GlobalShadows = originalLighting.GlobalShadows end
end)
addToggle(worldPage, "High Saturation", "Apply a color-correction filter", "HighSaturation")
addSlider(worldPage, "Saturation amount", 0, 100, 60, function(v) settings.SaturationValue = v end)
addToggle(worldPage, "High Contrast", "Increase filter contrast", "HighContrast")
addSlider(worldPage, "Contrast amount", 0, 100, 25, function(v) settings.ContrastValue = v end)
addToggle(worldPage, "Bloom", "Add bright highlights using BloomEffect", "BloomEffect")
addSlider(worldPage, "Bloom intensity", 0, 30, 10, function(v) settings.BloomValue = v end)
addToggle(worldPage, "Blur", "Apply screen blur with BlurEffect", "BlurEffect")
addSlider(worldPage, "Blur amount", 0, 24, 8, function(v) settings.BlurValue = v end)
addToggle(worldPage, "Night Vision", "Add green tint and brightness", "NightVision")
addToggle(worldPage, "Ambient Rainbow", "Cycle local ambient lighting colors", "ColorCycle")
addToggle(worldPage, "Hide Terrain Clouds", "Set the local Clouds cover to zero", "RemoveClouds", function(on)
    if not on and clouds and clouds.Parent and oldCloudCover ~= nil then
        clouds.Cover = oldCloudCover
        clouds.Density = oldCloudDensity
    end
end)
addAction(worldPage, "Daylight preset", "Enable local midday light", function()
    setToggle("NightMode", false)
    setToggle("Fullbright", true)
    Lighting.ClockTime = 14
    notify("Daylight enabled")
end)
addAction(worldPage, "Midnight preset", "Turn the clock to 00:00", function()
    setToggle("Fullbright", false)
    setToggle("NightMode", true)
    Lighting.ClockTime = 0
    notify("Night enabled")
end)
addAction(worldPage, "Restore world", "Undo local lighting, clouds and filters", function()
    for _, key in ipairs({"Fullbright", "NoFog", "NightMode", "DisableShadows",
        "HighSaturation", "HighContrast", "BloomEffect", "BlurEffect",
        "NightVision", "ColorCycle", "RemoveClouds"}) do
        setToggle(key, false)
    end
    restoreLighting()
    restoreWorldExtras()
    notify("World effects restored")
end)

-- HUD
card(hudPage, "▤  LIVE HUD", "Show real local stats over the game screen.")
addToggle(hudPage, "FPS Counter", "Show smoothed frames per second", "FPSHUD", updateHUD)
addToggle(hudPage, "Speedometer", "Show local horizontal speed", "SpeedHUD", updateHUD)
addToggle(hudPage, "Coordinates", "Show character X / Y / Z", "CoordinatesHUD", updateHUD)
addToggle(hudPage, "Health Display", "Show your character health", "HealthHUD", updateHUD)
addToggle(hudPage, "Player Counter", "Show current server player count", "PlayerHUD", updateHUD)
addToggle(hudPage, "Game Clock", "Show Lighting.ClockTime", "ClockHUD", updateHUD)
addToggle(hudPage, "Crosshair", "Small plus in the middle of screen", "Crosshair", updateHUD)
addSlider(hudPage, "HUD size", 65, 140, 100, function(v)
    settings.HUDScale = v
    updateHUD()
end)
addAction(hudPage, "Enable all HUD stats", "Turn on all live stat fields", function()
    for _, key in ipairs({"FPSHUD", "SpeedHUD", "CoordinatesHUD",
        "HealthHUD", "PlayerHUD", "ClockHUD"}) do
        setToggle(key, true)
    end
    updateHUD()
    notify("HUD enabled")
end)
addAction(hudPage, "Hide all HUD elements", "Disable stats and crosshair", function()
    for _, key in ipairs({"FPSHUD", "SpeedHUD", "CoordinatesHUD",
        "HealthHUD", "PlayerHUD", "ClockHUD", "Crosshair"}) do
        setToggle(key, false)
    end
    updateHUD()
    notify("HUD hidden")
end)

-- AUDIO
card(audioPage, "♪  AUDIO MANAGER", "Local sound controls; named music detection is approximate.")
addToggle(audioPage, "Mute All Sounds", "Set detected Sound volumes to zero", "MuteAll", applyAudio)
addToggle(audioPage, "Quiet Mode", "Reduce detected Sound volumes to 25%", "QuietMode", applyAudio)
addToggle(audioPage, "Mute Music", "Mute Sound names containing music/theme/bgm", "MuteMusic", applyAudio)
addSlider(audioPage, "Volume percent", 0, 200, 100, function(v)
    settings.VolumePercent = v
    -- Audio is reapplied on the scheduled loop to avoid iPad lag while dragging.
end)
addAction(audioPage, "Restore sound volumes", "Return locally changed Sound volumes", function()
    for _, key in ipairs({"MuteAll", "QuietMode", "MuteMusic"}) do
        setToggle(key, false)
    end
    settings.VolumePercent = 100
    if sliderRefresh["Volume percent"] then
        sliderRefresh["Volume percent"](100)
    end
    restoreAudio()
    notify("Sound restored")
end)
addAction(audioPage, "Apply sound filters now", "Refresh currently existing Sound objects", function()
    applyAudio()
    notify("Sound controls applied")
end)

-- CONFIG
card(config, "⚙  STYLE & CONTROLS", "PC and Mobile modes, animated tiles and movable bubble.")
addToggle(config, "UI Animations", "Enable elastic and fade transitions", "Animations")
addToggle(config, "Purple Glow", "Animate window border opacity", "Glow", function(enabled)
    tween(mainStroke, .25, {Transparency = enabled and .52 or 1})
end)
addToggle(config, "Notifications", "Show small animated toast messages", "ShowToasts")
addSlider(config, "Window opacity", 55, 100, 100, function(v)
    main.BackgroundTransparency = 1 - v/100
end)
addSlider(config, "UI scale", 70, 115, 100, function(v)
    settings.MenuScale = v
    mainScale.Scale = v/100
end)
addAction(config, "Change accent theme", "Cycle violet, cyan, rose, emerald and gold", nextTheme)
addAction(config, "Recenter menu", "Center the window on your screen", function()
    local vs = workspace.CurrentCamera.ViewportSize
    main.Position = UDim2.fromOffset((vs.X-main.Size.X.Offset)/2,
        (vs.Y-main.Size.Y.Offset)/2)
    notify("Window centered")
end)
addAction(config, "Restore default size", "Restore the selected device window size", function()
    applyDeviceLayout(selectedMode or "Mobile")
    notify("Size restored")
end)
addAction(config, "Reset local settings", "Restore movement, visuals, HUD, audio and camera", resetEverything)
addAction(config, "Test animation", "Show a notification to check transitions", function()
    notify("SigmaSaken V2 • animated")
end)
addAction(config, "Switch PC / Mobile layout", "Reopen the device selection screen", function()
    showDevicePicker()
end)
addAction(config, "Unload SigmaSaken", "Remove the interface and restore local changes", function()
    mainGui:Destroy()
end)
card(config, "ⓘ  COMPATIBILITY", "Local Roblox effects are implemented. Forsaken can override client movement and stamina.")



local pageTitles = {
    Home="Dashboard", Player="Player", Combat="Combat", Visuals="Visuals",
    Camera="Camera", World="World", HUD="HUD",
    Audio="Audio", Config="Configuration"
}
local function changePage(name)
    if currentPage == name then return end
    currentPage = name
    heading.Text = pageTitles[name]
    for key,p in pairs(pages) do
        p.Visible = (key == name)
        if key == name then p.CanvasPosition = Vector2.new(0,0) end
    end
    for key,group in pairs(navButtons) do
        for _,button in ipairs(group) do
            tween(button,.25,{
                BackgroundColor3 = key == name and P.dark or P.card,
                TextColor3 = key == name and P.white or P.muted
            })
        end
    end
    local page = pages[name]
    page.Position = UDim2.fromOffset(22,0)
    tween(page,.35,{Position=UDim2.fromOffset(0,0)},Enum.EasingStyle.Back)
end
local sectionData = {
    {"⌂  Home","Home"}, {"◉  Player","Player"},
    {"⚔  Combat","Combat"}, {"◇  Visuals","Visuals"}, {"◈  Camera","Camera"},
    {"✧  World","World"}, {"▤  HUD","HUD"},
    {"♪  Audio","Audio"}, {"⚙  Config","Config"}
}
for i,item in ipairs(sectionData) do
    navButtons[item[2]] = {}
    local desk = make("TextButton",nav,{
        LayoutOrder=i, Size=UDim2.new(1,-4,0,51),
        BackgroundColor3=P.card,Text=item[1],
        TextColor3=P.muted,TextSize=15,
        Font=Enum.Font.GothamMedium,
        TextXAlignment=Enum.TextXAlignment.Left,
        AutoButtonColor=false
    })
    rounded(desk,24)
    make("UIPadding",desk,{PaddingLeft=UDim.new(0,17)})
    pressEffect(desk)
    table.insert(navButtons[item[2]],desk)
    connect(desk.MouseButton1Click,function() changePage(item[2]) end)
    local phone = make("TextButton",mobileNav,{
        LayoutOrder=i,Size=UDim2.fromOffset(110,45),
        BackgroundColor3=P.card,Text=item[1],
        TextColor3=P.muted,TextSize=13,
        Font=Enum.Font.GothamMedium,
        AutoButtonColor=false
    })
    rounded(phone,100)
    pressEffect(phone)
    table.insert(navButtons[item[2]],phone)
    connect(phone.MouseButton1Click,function() changePage(item[2]) end)
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
        math.clamp(resizing.size.X.Offset + delta.X, math.min(selectedMode == "PC" and 570 or 310, maxW), maxW),
        math.clamp(resizing.size.Y.Offset + delta.Y, math.min(selectedMode == "PC" and 420 or 320, maxH), maxH)
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
    local targetScale = settings.MenuScale/100
    mainScale.Scale = 0.78 * targetScale
    tween(mainScale, 0.42, {Scale = targetScale}, Enum.EasingStyle.Back)
end
local function hideMenu()
    if not isOpen then return end
    isOpen = false
    transition = transition + 1
    local token = transition
    floating.Visible = true
    floatScale.Scale = 0.65
    tween(floatScale, 0.38, {Scale = 1}, Enum.EasingStyle.Back)
    local t = tween(mainScale, 0.25, {Scale = 0.78 * settings.MenuScale/100})
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

-- DEVICE CHOICE: always prompt on execution, no stored selection.
showDevicePicker = function()
    if main.Visible then
        main.Visible = false
    end
    isOpen = false
    floating.Visible = false
    -- Prevent touch movement controls from obscuring the picker.
    runButton.Visible = false
    quickNoclip.Visible = false
    quickJump.Visible = false
    quickFakeLag.Visible = false
    selector.Visible = true
    local vs = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
        or Vector2.new(1024,768)
    local sw = math.floor(math.min(480,vs.X-35))
    local sh = math.floor(math.min(300,vs.Y-35))
    selectorPanel.Size = UDim2.fromOffset(sw,sh)
    -- Retain large, tappable choices when screen height is limited.
    optionPC.Position = UDim2.new(0,18,0,math.floor(sh*.38))
    optionMobile.Position = UDim2.new(.5,9,0,math.floor(sh*.38))
    optionPC.Size = UDim2.new(.5,-27,0,math.floor(sh*.42))
    optionMobile.Size = UDim2.new(.5,-27,0,math.floor(sh*.42))
    selectorFoot.Position = UDim2.new(0,12,1,-29)
    selectorScale.Scale = .72
    tween(selectorScale,.42,{Scale=1},Enum.EasingStyle.Back)
end
local function acceptDevice(mode)
    selectedMode = mode
    applyDeviceLayout(mode)
    if mode == "PC" then
        settings.ShowQuickRun = false
        settings.ShowQuickFakeLag = false
    else
        settings.ShowQuickRun = true
        settings.ShowQuickFakeLag = true
    end
    if toggleRefresh.ShowQuickRun then toggleRefresh.ShowQuickRun() end
    if toggleRefresh.ShowQuickFakeLag then toggleRefresh.ShowQuickFakeLag() end
    refreshQuickButtons()
    local endTween = tween(selectorScale,.21,{Scale=.86})
    if endTween then endTween.Completed:Wait() end
    selector.Visible = false
    showMenu()
    notify("Release 5.0 • " .. mode .. " layout")
end
connect(optionPC.MouseButton1Click,function() acceptDevice("PC") end)
connect(optionMobile.MouseButton1Click,function() acceptDevice("Mobile") end)

-- LOADING: then mode picker, then game UI.
tween(loadingScale,.42,{Scale=1},Enum.EasingStyle.Back)
local started = os.clock()
local progressTween = TweenService:Create(bar,TweenInfo.new(
    2,Enum.EasingStyle.Linear),{Size=UDim2.fromScale(1,1)})
progressTween:Play()
while os.clock()-started < 2 do
    ls.Text = "PREPARING INTERFACE... " ..
        math.clamp(math.floor((os.clock()-started)/2*100),0,100) .. "%"
    task.wait(.03)
end
progressTween:Cancel()
bar.Size = UDim2.fromScale(1,1)
ls.Text = "PREPARING INTERFACE... 100%"
local endLoad = tween(loadingScale,.18,{Scale=.80})
if endLoad then endLoad.Completed:Wait() end
loading:Destroy()
showDevicePicker()
print("SigmaSaken V2 Release 5.0: PC / Mobile; defense attempts + visual Fake Lag")
