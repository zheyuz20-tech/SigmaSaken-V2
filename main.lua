--[[
 SIGMASAKEN V2 | RELEASE 16.0 - CUSTOM INTERFACE
 Rounded dark red/black UI, global search, pinned sections and reduced motion.
 Mobile floating action shortcuts removed; menu launcher retained.
 No external UI library. PC and Mobile. Made by xbolitas.
 Existing gameplay modules retained from release 12; not runtime verified.
 Named config profiles are stored in a new local JSON file.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
-- Rayfield windows outlive our custom ScreenGui; unload previous run.
if type(getgenv) == "function" and getgenv().SigmaSakenRayfieldV2 then
    pcall(function() getgenv().SigmaSakenRayfieldV2:Unload() end)
    getgenv().SigmaSakenRayfieldV2 = nil
elseif _G.SigmaSakenRayfieldV2 then
    pcall(function() _G.SigmaSakenRayfieldV2:Unload() end)
    _G.SigmaSakenRayfieldV2 = nil
end

-- Remove older copies when this script is executed again.
for _, name in ipairs({"SigmaSakenV2", "SigmaSakenV2Launcher"}) do
    local old = playerGui:FindFirstChild(name)
    if old then old:Destroy() end
end

local P = {
    bg = Color3.fromRGB(11, 11, 15),
    side = Color3.fromRGB(18, 18, 24),
    card = Color3.fromRGB(24, 24, 31),
    card2 = Color3.fromRGB(30, 29, 38),
    dim = Color3.fromRGB(40, 39, 47),
    purple = Color3.fromRGB(232, 72, 95), -- shared accent reference
    light = Color3.fromRGB(255, 137, 150),
    dark = Color3.fromRGB(68, 33, 43),
    white = Color3.fromRGB(241, 239, 243),
    muted = Color3.fromRGB(157, 155, 165)
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
    GuestBlockCooldown = 3, -- anti-spam interval; game still controls actual ability cooldown
    GuestBlockAlerts = false,
    GuestBlockAll = false,
    GuestProximityGuard = false,
    GuestAutoPunch = false,
    GuestPunchAim = true,
    GuestPunchRange = 13,
    GuestPunchDelay = 6, -- hundredths of a second; 6 = 60ms
    FakeLag = false,
    FakeLagStutter = true,
    FakeLagAnimSpeed = 16,

}

settings.SigmaEnv = (type(getgenv) == "function" and getgenv()) or _G
settings.UIRefs = {}
settings.SearchText = ""
settings.PinnedPages = {}
settings.AmbientTweens = {}
local extraCleanup = function() end
local cleanupFeatures = function() end
local connections = {}
local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections, c)
    return c
end

function settings.readable(value)
    if type(value) ~= "string" then return value end
    local map = { ["•"]="-", ["−"]="-", ["×"]="X", ["›"]=">",
        ["✓"]="ON", ["⚠"]="", ["▾"]=" >", ["°"]=" deg", ["–"]="-",
        ["▣"]="", ["▥"]="", ["✦"]="", ["ⓘ"]="", ["◉"]="",
        ["⚔"]="", ["◈"]="", ["▤"]="", ["◇"]="", ["♪"]="",
        ["⚙"]="", ["⌨"]="", ["⚡"]="", ["⌁"]="", ["⛨"]="",
        ["🥊"]="", ["✧"]="", ["⌂"]="", ["◎"]="", ["⊕"]="", ["◢"]="" }
    for glyph, replacement in pairs(map) do
        value = value:gsub(glyph, replacement)
    end
    return value:gsub("^ +", "")
end

local function make(class, parent, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k == "Text" or k == "PlaceholderText" then v = settings.readable(v) end
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local function rounded(obj, radius)
    return make("UICorner", obj, {CornerRadius = radius >= 100 and UDim.new(.5, 0) or UDim.new(0, radius)})
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

function settings.ambientTween(object, info, props)
    local t = TweenService:Create(object,info,props)
    table.insert(settings.AmbientTweens,t)
    if settings.Animations then t:Play() end
    return t
end
function settings.refreshAmbientMotion()
    for _,t in ipairs(settings.AmbientTweens) do
        if settings.Animations then t:Play() else t:Pause() end
    end
end

local function pressEffect(button)
    local scale = make("UIScale", button, {Scale = 1})
    connect(button.MouseButton1Down, function()
        tween(scale, 0.12, {Scale = 0.94}, Enum.EasingStyle.Quad)
    end)
    connect(button.MouseButton1Up, function()
        tween(scale, 0.30, {Scale = 1}, Enum.EasingStyle.Back)
    end)
    connect(button.MouseEnter, function()
        tween(scale, 0.22, {Scale = 1.015}, Enum.EasingStyle.Sine)
    end)
    connect(button.MouseLeave, function()
        tween(scale, 0.25, {Scale = 1})
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
    for _,t in ipairs(settings.AmbientTweens) do t:Cancel() end
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

-- Floating launcher: sleek glass-gradient orb. Drag to reposition, tap to open.
local floating = make("TextButton", launcherGui, {
    Name = "OpenCloseButton", AnchorPoint = Vector2.new(0, 0),
    Position = UDim2.fromOffset(18, 270),
    Size = UDim2.fromOffset(68, 68),
    BackgroundColor3 = Color3.fromRGB(30, 19, 25),
    BorderSizePixel = 0,
    Text = "", AutoButtonColor = false,
    Visible = false, ZIndex = 14,
    ClipsDescendants = false
})
rounded(floating, 100)
local floatScale = make("UIScale", floating, {Scale = 1})
do
local outerPulse = make("Frame", floating, {
    AnchorPoint = Vector2.new(.5,.5),
    Position = UDim2.fromScale(.5,.5),
    Size = UDim2.fromOffset(78,78),
    BackgroundTransparency = 1, ZIndex = 12
})
rounded(outerPulse, 100)
local pulseStroke = outline(outerPulse, P.purple, 2, .40)
local outerGradient = make("UIGradient", floating, {
    Rotation = 40,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(64,28,39)),
        ColorSequenceKeypoint.new(.5,Color3.fromRGB(15,14,18)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(114,40,54))
    })
})
local floatRing = outline(floating, P.light, 2, .10)
local ringGradient = make("UIGradient", floatRing, {
    Rotation = 0,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,P.purple),
        ColorSequenceKeypoint.new(.5,P.light),
        ColorSequenceKeypoint.new(1,P.dark)
    })
})
local floatingCore = make("Frame", floating, {
    AnchorPoint = Vector2.new(.5,.5),
    Position = UDim2.fromScale(.5,.5),
    Size = UDim2.fromOffset(53,53),
    BackgroundColor3 = Color3.fromRGB(30,19,25),
    BackgroundTransparency = .08, ZIndex = 15
})
rounded(floatingCore,100)
local coreGradient = make("UIGradient",floatingCore,{
    Rotation=70,Color=ColorSequence.new(
        Color3.fromRGB(82,34,47),Color3.fromRGB(24,17,21))
})
local floatingGlyph = label(floatingCore, "Σ", 34, true, P.white)
floatingGlyph.Size = UDim2.fromScale(1,1)
floatingGlyph.TextXAlignment = Enum.TextXAlignment.Center
floatingGlyph.ZIndex = 16
settings.UIRefs.floatRing = floatRing
settings.UIRefs.pulseStroke = pulseStroke
settings.UIRefs.core = floatingCore
settings.UIRefs.glyph = floatingGlyph
settings.UIRefs.ringGradient = ringGradient
local floatingDot = make("Frame", floating, {
    AnchorPoint = Vector2.new(.5,.5),
    Position = UDim2.fromScale(.80,.80),
    Size = UDim2.fromOffset(10,10),
    BackgroundColor3 = Color3.fromRGB(172,255,212),
    BorderSizePixel=0, ZIndex=17
})
rounded(floatingDot,100)
outline(floatingDot, Color3.fromRGB(15,15,26), 2, 0)
-- Loops attached to objects are cancelled automatically on re-execution.
settings.ambientTween(ringGradient, TweenInfo.new(
    5.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1
), {Rotation=360})
settings.ambientTween(pulseStroke, TweenInfo.new(
    1.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true
), {Transparency=.86})
settings.ambientTween(outerPulse, TweenInfo.new(
    1.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true
), {Size=UDim2.fromOffset(87,87)})
end -- launcher visuals

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
do
local selectorTitle = label(selectorPanel, "SELECT YOUR DEVICE", 24, true, P.light)
selectorTitle.Position = UDim2.fromOffset(20, 20)
selectorTitle.Size = UDim2.new(1,-40,0,45)
selectorTitle.TextXAlignment = Enum.TextXAlignment.Center
local selectorSub = label(selectorPanel, "Made by xbolitas • choose PC or Mobile", 13, false, P.muted)
selectorSub.Position = UDim2.fromOffset(20, 66)
selectorSub.Size = UDim2.new(1,-40,0,25)
selectorSub.TextXAlignment = Enum.TextXAlignment.Center
end -- picker static captions
local optionPC = make("TextButton", selectorPanel, {
    Position = UDim2.new(0, 22, 0, 116),
    Size = UDim2.new(.5, -33, 0, 136),
    BackgroundColor3 = P.card2,
    Text = "PC\nDESKTOP", TextColor3 = P.white,
    Font = Enum.Font.GothamBold, TextSize = 20, AutoButtonColor = false
})
rounded(optionPC, 26)
outline(optionPC, P.purple, 1.3, .4)
pressEffect(optionPC)
local optionMobile = make("TextButton", selectorPanel, {
    Position = UDim2.new(.5, 11, 0, 116),
    Size = UDim2.new(.5, -33, 0, 136),
    BackgroundColor3 = P.card2,
    Text = "MOBILE\nTOUCH", TextColor3 = P.white,
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
rounded(main, 26)
local mainStroke = outline(main, P.purple, 1.6, .42)
local mainScale = make("UIScale", main, {Scale = 1})
make("UIGradient", main, {
    Rotation = 24,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, P.bg),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(16,16,20))
    })
})
local accentStrip = make("Frame", main, {
    Position = UDim2.fromOffset(0,0), Size = UDim2.new(1,0,0,2),
    BackgroundColor3 = P.purple, ZIndex = 5
})
local stripGradient = make("UIGradient", accentStrip, {
    Color = ColorSequence.new(P.dark, P.light)
})
settings.ambientTween(stripGradient, TweenInfo.new(6, Enum.EasingStyle.Linear,
    Enum.EasingDirection.InOut, -1), {Rotation = 360})

-- Reference-style icon rail with compact navigation.
local sidebar = make("Frame", main, {
    Size = UDim2.new(0, 128, 1, 0),
    BackgroundColor3 = P.side, Visible = false, BorderSizePixel=0
})
do
    local brand = label(sidebar, "Σ", 36, true, P.purple)
    brand.Position = UDim2.fromOffset(0,8)
    brand.Size = UDim2.new(1,0,0,54)
    brand.TextXAlignment = Enum.TextXAlignment.Center
    settings.UIRefs.brand = brand
    make("Frame",sidebar,{Position=UDim2.new(1,-1,0,0),Size=UDim2.new(0,1,1,0),BackgroundColor3=P.dim,BorderSizePixel=0})
end
local nav = make("ScrollingFrame", sidebar, {
    Position = UDim2.fromOffset(7,72),
    Size = UDim2.new(1,-14,1,-105),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 0, ScrollBarImageColor3 = P.purple,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.fromOffset(0,0)
})
make("UIListLayout", nav, {Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder})
make("UIPadding", nav, {PaddingBottom=UDim.new(0,4)})
local build = label(sidebar,"V2",10,true,P.muted)
build.Position = UDim2.new(0,0,1,-26)
build.Size = UDim2.new(1,0,0,18)
build.TextXAlignment = Enum.TextXAlignment.Center

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
local headingSub = label(dragBar, "Made by xbolitas • Custom UI", 11, true, P.muted)
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
local navButtons = {}
local currentPage = nil
local rowOrder = 0
settings.PageUI = {}

local function createPage(name)
    local page = make("ScrollingFrame", holder, {
        Name = name, Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = P.purple,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.fromOffset(0,0), Visible = false
    })
    local layout = make("UIListLayout", page, {
        Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center
    })
    make("UIPadding", page, {
        PaddingTop = UDim.new(0,5), PaddingBottom = UDim.new(0,18),
        PaddingLeft = UDim.new(0,2), PaddingRight = UDim.new(0,7)
    })
    connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y+34)
    end)
    pages[name] = page
    settings.PageUI[name] = {layout=layout}
    return page
end

local home = createPage("Home")
local playerPage = createPage("Player")
createPage("Player Extras")
local combatPage = createPage("Combat")
local visuals = createPage("Visuals")
local cameraPage = createPage("Camera")
local worldPage = createPage("World")
local hudPage = createPage("HUD")
local audioPage = createPage("Audio")
local config = createPage("Config")
createPage("Keybinds")

-- Registry shared with every toggle and action; details are built later.
local Bindings = {registry = {}, order = {}}
Bindings.controls = {}
-- Preserve all existing controls and callbacks in the native UI.
-- Place the new registry inside the existing Bindings table to avoid Lua's
-- per-chunk local-variable limit.
function Bindings.addControl(kind, page, opts)
    opts.kind = kind
    opts.page = page.Name
    table.insert(Bindings.controls, opts)
    return opts
end

local function registerBindable(id, title, page, callback, kind)
    if not id or Bindings.registry[id] then return end
    local entry = {
        id = id, title = title, category = page.Name,
        perform = callback, kind = kind
    }
    Bindings.registry[id] = entry
    table.insert(Bindings.order, entry)
end

local function listRow(page, sizeY, background)
    rowOrder = rowOrder + 1
    local row = make("Frame", page, {
        LayoutOrder = rowOrder,
        Size = UDim2.new(1,-4,0,sizeY),
        BackgroundColor3 = background or P.card,
        ClipsDescendants = true
    })
    rounded(row,16)
    row.BorderSizePixel=0
    row:SetAttribute("ControlKind","card")
    return row
end
local function card(page,title,description)
    Bindings.addControl("card",page,{title=title,description=description})
    local row = listRow(page,76,P.card)
    local h = label(row,title,15,true,P.light)
    h.Position = UDim2.fromOffset(10,5)
    h.Size = UDim2.new(1,-20,0,25)
    local d = label(row,description,11,false,P.muted)
    d.Position = UDim2.fromOffset(10,29)
    d.Size = UDim2.new(1,-20,0,42)
    return row
end

local toggleRefresh = {}
local function addToggle(page,title,description,key,callback)
    Bindings.addControl("toggle",page,{title=title,description=description,key=key})
    rowOrder = rowOrder + 1
    local b = make("TextButton",page,{
        LayoutOrder = rowOrder,
        Size = UDim2.new(1,-4,0,65),
        BackgroundColor3 = P.card, Text = "",
        AutoButtonColor = false, ClipsDescendants = true
    })
    rounded(b,16)
    b.BorderSizePixel=0
    b:SetAttribute("ControlKind","toggle")
    pressEffect(b)
    local h = label(b,title,15,true)
    h.Position = UDim2.fromOffset(10,4)
    h.Size = UDim2.new(1,-61,0,26)
    local d = label(b,description,11,false,P.muted)
    d.Position = UDim2.fromOffset(10,29)
    d.Size = UDim2.new(1,-61,0,33)
    local switch = make("Frame",b,{
        AnchorPoint = Vector2.new(1,.5),
        Position = UDim2.new(1,-9,.5,0),
        Size = UDim2.fromOffset(40,22),
        BackgroundColor3 = settings[key] and P.purple or P.dim
    })
    rounded(switch,100)
    local knob = make("Frame",switch,{
        Position = settings[key] and UDim2.fromOffset(19,2) or UDim2.fromOffset(3,2),
        Size = UDim2.fromOffset(18,18),BackgroundColor3=P.white
    })
    rounded(knob,100)
    local function refresh()
        local enabled = settings[key]
        tween(b,.2,{BackgroundColor3=enabled and P.card2 or P.card})
        tween(switch,.27,{BackgroundColor3=enabled and P.purple or P.dim})
        tween(knob,.3,{Position=enabled and UDim2.fromOffset(19,2)
                or UDim2.fromOffset(3,2)},Enum.EasingStyle.Back)
    end
    toggleRefresh[key]=refresh
    local function performToggle()
        settings[key]=not settings[key]
        refresh()
        if callback then callback(settings[key]) end
        if Bindings.autoSave then Bindings.autoSave() end
    end
    connect(b.MouseButton1Click,performToggle)
    registerBindable("Toggle:"..key,title,page,performToggle,"toggle")
    return b
end

local sliderRefresh = {}
local function addSlider(page,title,minimum,maximum,initial,callback)
    local raySliderDef = Bindings.addControl("slider",page,{
        title=title, minimum=minimum, maximum=maximum, initial=initial
    })
    local base=listRow(page,74,P.card)
    base:SetAttribute("ControlKind","slider")
    raySliderDef.value = initial
    local h=label(base,title,15,true)
    h.Position=UDim2.fromOffset(10,4)
    h.Size=UDim2.new(1,-117,0,27)
    local display=label(base,tostring(initial),17,true,P.light)
    display.Position=UDim2.new(1,-90,0,3)
    display.Size=UDim2.fromOffset(80,28)
    display.TextXAlignment=Enum.TextXAlignment.Right
    local hit=make("TextButton",base,{
        Position=UDim2.fromOffset(12,31),
        Size=UDim2.new(1,-24,0,36),
        BackgroundTransparency=1,Text="",AutoButtonColor=false
    })
    local track=make("Frame",hit,{
        AnchorPoint=Vector2.new(0,.5),Position=UDim2.fromScale(0,.5),
        Size=UDim2.new(1,0,0,7),BackgroundColor3=P.dim
    })
    rounded(track,100)
    local fill=make("Frame",track,{
        Size=UDim2.fromScale((initial-minimum)/(maximum-minimum),1),
        BackgroundColor3=P.purple
    })
    rounded(fill,100)
    local thumb=make("Frame",hit,{
        AnchorPoint=Vector2.new(.5,.5),
        Position=UDim2.fromScale((initial-minimum)/(maximum-minimum),.5),
        Size=UDim2.fromOffset(17,17),BackgroundColor3=P.white
    })
    rounded(thumb,100)
    local activeInput=nil
    local function setValue(requested)
        local value=math.clamp(math.floor(requested+.5),minimum,maximum)
        local fraction=(value-minimum)/(maximum-minimum)
        display.Text=tostring(value)
        raySliderDef.value = value
        tween(fill,.11,{Size=UDim2.fromScale(fraction,1)})
        tween(thumb,.11,{Position=UDim2.fromScale(fraction,.5)})
        if callback then callback(value) end
        if Bindings.autoSave then Bindings.autoSave() end
    end
    local function update(x)
        local fraction=math.clamp((x-hit.AbsolutePosition.X)/
            math.max(1,hit.AbsoluteSize.X),0,1)
        setValue(minimum+fraction*(maximum-minimum))
    end
    connect(hit.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.Touch or
            input.UserInputType==Enum.UserInputType.MouseButton1 then
            activeInput=input
            update(input.Position.X)
        end
    end)
    connect(UIS.InputChanged,function(input)
        if not activeInput then return end
        if input==activeInput or (activeInput.UserInputType==
            Enum.UserInputType.MouseButton1 and
            input.UserInputType==Enum.UserInputType.MouseMovement) then
            update(input.Position.X)
        end
    end)
    connect(UIS.InputEnded,function(input)
        if input==activeInput then activeInput=nil end
    end)
    sliderRefresh[title]=setValue
    raySliderDef.apply = setValue
    return setValue
end

local function addAction(page,title,description,callback)
    Bindings.addControl("action",page,{title=title,description=description})
    rowOrder = rowOrder + 1
    local b=make("TextButton",page,{
        LayoutOrder=rowOrder,Size=UDim2.new(1,-4,0,62),
        BackgroundColor3=P.card2,Text="",AutoButtonColor=false,
        ClipsDescendants=true
    })
    rounded(b,16)
    b.BorderSizePixel=0
    b:SetAttribute("ControlKind","action")
    pressEffect(b)
    local h=label(b,title,15,true,P.light)
    h.Position=UDim2.fromOffset(10,4)
    h.Size=UDim2.new(1,-52,0,24)
    local d=label(b,description,11,false,P.muted)
    d.Position=UDim2.fromOffset(10,27)
    d.Size=UDim2.new(1,-52,0,31)
    local circle=make("Frame",b,{
        AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-16,.5,0),
        Size=UDim2.fromOffset(26,26),BackgroundColor3=P.dark
    })
    rounded(circle,100)
    local arrow=label(circle,"›",24,true,P.light)
    arrow.Size=UDim2.fromScale(1,1)
    arrow.TextXAlignment=Enum.TextXAlignment.Center
    local function performAction()
        tween(b,.12,{BackgroundColor3=P.dark})
        task.delay(.2,function()
            if b.Parent then tween(b,.23,{BackgroundColor3=P.card2}) end
        end)
        if callback then
            local ok,err=pcall(callback)
            if not ok then warn("SigmaSaken action: "..tostring(err)) end
        end
        if Bindings.autoSave and not (page==config and (title=="Create Config" or title=="Select Config by Name" or title=="Load Config" or title=="Save Config" or title=="Delete Config")) then Bindings.autoSave() end
    end
    connect(b.MouseButton1Click,performAction)
    registerBindable("Action:"..page.Name..":"..title,title,page,performAction,"action")
    return b
end

-- Two independently arranged panels within one scrolling page.
-- Existing controls are reparented; their signals and callbacks are unchanged.
function Bindings.reflow()
    local wide = holder.AbsoluteSize.X >= 560
    local query = string.lower(settings.SearchText or ""):match("^%s*(.-)%s*$")
    for name,page in pairs(pages) do
        if name ~= "Keybinds" then
            local state=settings.PageUI[name]
            if not state.rows then
                state.rows={}
                for _, child in ipairs(page:GetChildren()) do
                    if child:IsA("GuiObject") then table.insert(state.rows,child) end
                end
                table.sort(state.rows,function(a,b) return a.LayoutOrder<b.LayoutOrder end)
                state.index={}
                for _,row in ipairs(state.rows) do
                    local words={name}
                    for _,child in ipairs(row:GetDescendants()) do
                        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                            if child.Text~="" then table.insert(words,child.Text) end
                            if child:IsA("TextBox") then table.insert(words,child.PlaceholderText) end
                        end
                    end
                    state.index[row]=string.lower(table.concat(words," "))
                end
                state.empty=label(page,"No matching options",14,true,P.muted)
                state.empty.Size=UDim2.new(1,-16,0,44)
                state.empty.Position=UDim2.fromOffset(8,10)
                state.empty.TextXAlignment=Enum.TextXAlignment.Center
                state.empty.Visible=false
                if state.layout then state.layout:Destroy() end
                local padding=page:FindFirstChildOfClass("UIPadding")
                if padding then padding:Destroy() end
                state.columns={}
                for i=1,2 do
                    local col=make("Frame",page,{BackgroundColor3=P.side,BorderSizePixel=0,ClipsDescendants=false})
                    rounded(col,22)
                    local title=label(col,i==1 and "General" or "Advanced",13,true,P.white)
                    title.Position=UDim2.fromOffset(10,3); title.Size=UDim2.new(1,-20,0,24)
                    local inner=make("Frame",col,{Position=UDim2.fromOffset(5,31),Size=UDim2.new(1,-10,0,0),BackgroundTransparency=1})
                    make("UIListLayout",inner,{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
                    state.columns[i]={frame=col,inner=inner}
                end
            end
            if state.lastWide~=wide or state.lastFilter~=(state.filter or "All") or state.lastQuery~=query then
            state.lastWide=wide; state.lastFilter=state.filter or "All"; state.lastQuery=query
            local totals={0,0}
            local matches=0
            for _,row in ipairs(state.rows) do
                local kind=row:GetAttribute("ControlKind") or "card"
                local visible=(not state.filter or state.filter=="All" or kind==state.filter)
                    and (query=="" or string.find(state.index[row] or "",query,1,true)~=nil)
                if visible then matches=matches+1 end
                row.Visible=visible
                local index=1
                if wide and totals[2]<totals[1] then index=2 end
                row.Parent=state.columns[index].inner
                row.Size=UDim2.new(1,0,0,row.Size.Y.Offset)
                if visible then totals[index]=totals[index]+row.Size.Y.Offset+8 end
            end
            for i,col in ipairs(state.columns) do
                col.frame.Visible=matches>0 and (i==1 or wide)
                col.frame.Position=wide and UDim2.new((i-1)*.5,i==1 and 0 or 5,0,0) or UDim2.fromOffset(0,0)
                col.frame.Size=UDim2.new(wide and .5 or 1,wide and -7 or -5,0,math.max(48,totals[i]+38))
                col.inner.Size=UDim2.new(1,-10,0,totals[i])
            end
            state.matches=matches
            state.empty.Visible=matches==0
            page.CanvasSize=UDim2.fromOffset(0,math.max(totals[1],totals[2])+47)
            end
        end
    end
    if Bindings.refreshSearchNav then Bindings.refreshSearchNav() end
end
applyDeviceLayout=function(mode)
    selectedMode=mode
    local pc=mode=="PC"
    local vs=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1024,768)
    local w=math.floor(math.max(250,math.min(pc and 1050 or 820,vs.X-(pc and 54 or 18))))
    local h=math.floor(math.max(230,math.min(pc and 660 or 520,vs.Y-(pc and 58 or 18))))
    main.Size=UDim2.fromOffset(w,h)
    main.Position=UDim2.fromOffset(math.floor((vs.X-w)/2),math.floor((vs.Y-h)/2))
    local sw=pc and 128 or 102
    sidebar.Size=UDim2.new(0,sw,1,0)
    sidebar.Visible=true; mobileNav.Visible=false
    for _,group in pairs(navButtons) do for _,button in ipairs(group) do local hint=button:FindFirstChild("NavHint"); if hint then hint.Visible=not pc end end end
    content.Position=UDim2.fromOffset(sw,0)
    content.Size=UDim2.new(1,-sw,1,0)
    holder.Position=UDim2.fromOffset(12,150)
    holder.Size=UDim2.new(1,-24,1,-164)
    headingSub.Text="Made by xbolitas  -  "..mode
    build.Text="16.0"
    if navButtons.Keybinds then
        for _,button in ipairs(navButtons.Keybinds) do button.Visible=pc end
    end
    if not pc and currentPage=="Keybinds" then
        pages.Keybinds.Visible=false; currentPage="Home"; pages.Home.Visible=true; heading.Text="Dashboard"
        if settings.FilterStrip then settings.FilterStrip.Visible=true end
        if Bindings.searchBar then Bindings.searchBar.Visible=true end
        if Bindings.refreshSearchNav then Bindings.refreshSearchNav() end
        for name,group in pairs(navButtons) do
            for _,button in ipairs(group) do
                button.BackgroundColor3=name=="Home" and P.dark or P.side
                button.TextColor3=name=="Home" and P.light or P.muted
            end
        end
    end
    task.defer(Bindings.reflow)
end
-- ===========================================================================
-- FUNCTIONAL CLIENT MODULES (local-only: server may correct or reject changes)
-- ===========================================================================
local character, humanoid, rootPart = nil, nil, nil
local originalSpeed, originalJumpPower, originalJumpHeight
local appliedSpeed = false
settings.LastForcedSpeed = nil
local appliedJump = false
local collisionBackup = {}
local espRecords = {}
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
        -- Restore only our own last forced value, not a speed replaced by game rules.
        if appliedSpeed and originalSpeed and humanoid.WalkSpeed == settings.LastForcedSpeed then
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
    settings.LastForcedSpeed = nil
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
    settings.LastForcedSpeed = nil
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

-- Sprint: controlled by the Player menu.
local function updateMovement()
    if not humanoid or not humanoid.Parent then return end
    local wantSprint = settings.Sprint
    local wantSpeed = settings.Speed
    if settings.FakeLag then
        if humanoid.WalkSpeed ~= 0 then humanoid.WalkSpeed = 0 end
        settings.LastForcedSpeed = 0
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
        settings.LastForcedSpeed = requested
    elseif appliedSpeed then
        if originalSpeed and humanoid.WalkSpeed == settings.LastForcedSpeed then
            humanoid.WalkSpeed = originalSpeed
        end
        appliedSpeed = false
        settings.LastForcedSpeed = nil
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

-- Infinite Stamina: module-aware client support. Forsaken may use a different
-- module after updates or enforce stamina on the server. No method is guaranteed.
-- Unlike older builds, this does not create a fake Stamina key on unrelated
-- module tables and will only report success if a real supported field is found.
local restoreStaminaModule, refillStamina
settings.LastStaminaDetails = "Not scanned"
do
    local staminaNames = {"Stamina", "CurrentStamina", "SprintStamina"}
    local sprintModuleCached = nil
    local sprintModuleNode = nil
    local sprintSaved = nil
    local lastModuleLookup = -100
    local lastFallbackScan = -100
    local lastEventFire = -100
    local lastSeenModuleValue = nil
    local scanFailures = 0
    local lastFieldSummary = "none"

    local function findSprintModule()
        local rs = game:GetService("ReplicatedStorage")
        local systems = rs:FindFirstChild("Systems")
        local charFolder = systems and systems:FindFirstChild("Character")
        local gameFolder = charFolder and charFolder:FindFirstChild("Game")
        local candidate = gameFolder and gameFolder:FindFirstChild("Sprinting")
        return candidate and candidate:IsA("ModuleScript") and candidate or nil
    end

    restoreStaminaModule = function()
        if sprintModuleCached and sprintSaved then
            local module = sprintModuleCached
            pcall(function()
                module.StaminaLossDisabled = sprintSaved.lossDisabled
                module.StaminaLoss = sprintSaved.loss
                module.StaminaGain = sprintSaved.gain
            end)
        end
        sprintModuleCached = nil
        sprintModuleNode = nil
        sprintSaved = nil
        lastSeenModuleValue = nil
        lastEventFire = -100
        lastModuleLookup = -100
    end

    local function getModule()
        local now = os.clock()
        if sprintModuleCached and sprintModuleNode and sprintModuleNode.Parent then
            return sprintModuleCached
        end
        if now - lastModuleLookup < 1 then return nil end
        lastModuleLookup = now
        local node = findSprintModule()
        if not node then
            settings.LastStaminaDetails = "Sprinting ModuleScript missing at ReplicatedStorage.Systems.Character.Game.Sprinting"
            return nil
        end
        local ok, module = pcall(require, node)
        if not ok or type(module) ~= "table" then
            scanFailures = scanFailures + 1
            settings.LastStaminaDetails = "ModuleScript cannot be required as a table (attempt " .. scanFailures .. ")"
            return nil
        end
        if module ~= sprintModuleCached then
            restoreStaminaModule()
            sprintModuleCached = module
            sprintModuleNode = node
            sprintSaved = {
                lossDisabled = module.StaminaLossDisabled,
                loss = module.StaminaLoss,
                gain = module.StaminaGain
            }
        end
        return module
    end

    local function maxFor(scope, fallback)
        local maximum = scope:GetAttribute("MaxStamina")
        if type(maximum) ~= "number" or maximum <= 0 then
            maximum = fallback or 100
        end
        return math.clamp(maximum, 1, 1000)
    end

    refillStamina = function(forceScan)
        if not settings.Stamina then
            if sprintModuleCached then restoreStaminaModule() end
            return
        end
        local now = os.clock()
        local found = 0
        local module = getModule()
        if module then
            local max = module.MaxStamina
            if type(max) ~= "number" or max <= 0 then
                max = 100
            end
            max = math.clamp(max, 1, 1000)
            local hadNumericStamina = false
            local before
            for _, field in ipairs(staminaNames) do
                if type(module[field]) == "number" then
                    before = before or module[field]
                    if math.abs(module[field] - max) > 0.001 then
                        pcall(function() module[field] = max end)
                    end
                    hadNumericStamina = true
                    found = found + 1
                end
            end
            -- Some Forsaken versions support disabling drain directly.
            if type(module.StaminaLossDisabled) == "boolean"
                or type(module.StaminaLoss) == "number"
                or hadNumericStamina then
                pcall(function() module.StaminaLossDisabled = true end)
                found = found + 1
            end
            if type(module.StaminaLoss) == "number" then
                pcall(function() module.StaminaLoss = 0 end)
                found = found + 1
            end
            if type(module.StaminaGain) == "number" then
                pcall(function() module.StaminaGain = math.max(module.StaminaGain, 50) end)
            end
            -- Refresh the game UI only when stamina has actually been refilled.
            if hadNumericStamina and before and before < max
                and now - lastEventFire >= 0.25 then
                local changed = module.StaminaChanged
                local ok = pcall(function()
                    if typeof(changed) == "Instance" and changed:IsA("BindableEvent") then
                        changed:Fire()
                    elseif type(changed) == "table" and type(changed.Fire) == "function" then
                        changed:Fire()
                    end
                end)
                if ok then lastEventFire = now end
            end
            lastSeenModuleValue = type(module.Stamina) == "number" and module.Stamina or nil
            if found > 0 then
                lastFieldSummary = "Sprinting table: " .. tostring(found) .. " recognized setting(s)"
            else
                lastFieldSummary = "Sprinting table present but no recognized stamina values"
            end
        end

        -- Fallback scan is deliberately sparse: avoids a descendant traversal
        -- on every render/heartbeat and avoids writing arbitrary new attributes.
        if (found == 0) and (forceScan or now - lastFallbackScan >= 0.6) then
            lastFallbackScan = now
            local scopes = {player}
            if character then table.insert(scopes, character) end
            for _, scope in ipairs(scopes) do
                for _, field in ipairs(staminaNames) do
                    local obj = scope:FindFirstChild(field, true)
                    if obj and (obj:IsA("IntValue") or obj:IsA("NumberValue")) then
                        local maximum = maxFor(obj, maxFor(scope, 100))
                        if pcall(function() obj.Value = maximum end) then
                            found = found + 1
                        end
                    end
                    local value = scope:GetAttribute(field)
                    if type(value) == "number" then
                        local maximum = maxFor(scope, 100)
                        if pcall(function() scope:SetAttribute(field, maximum) end) then
                            found = found + 1
                        end
                    end
                end
            end
            if found > 0 then lastFieldSummary = "Character/player stamina fields found" end
        end
        if found > 0 then
            lastStaminaReport = "Local stamina source updated; game/server acceptance not confirmed"
        else
            lastStaminaReport = "No compatible stamina source found (may be server-controlled)"
        end
        local path = module and "Sprinting module found" or "Sprinting module unavailable"
        settings.LastStaminaDetails = path .. " | " .. lastFieldSummary .. " | " .. lastStaminaReport
    end
end -- stamina support

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
    if staminaAccum >= 0.12 then
        staminaAccum = 0
        if settings.Stamina then refillStamina(false) end
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
    settings.Stamina = false
    restoreStaminaModule()
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
    toastLabel.Text = settings.readable(tostring(message))
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
    {name="Crimson",color=Color3.fromRGB(232,72,95)},
    {name="Violet",color=Color3.fromRGB(173,91,255)},
    {name="Cyan",color=Color3.fromRGB(48,211,255)},
    {name="Rose",color=Color3.fromRGB(255,105,174)},
    {name="Emerald",color=Color3.fromRGB(76,230,172)},
    {name="Gold",color=Color3.fromRGB(255,196,86)}
}
local themeIndex = 1
local function applyTheme(index)
    themeIndex=math.clamp(math.floor(tonumber(index) or 1),1,#themes)
    local chosen=themes[themeIndex]
    local oldAccent,oldLight,oldDark=P.purple,P.light,P.dark
    P.purple=chosen.color
    P.light=chosen.color:Lerp(Color3.new(1,1,1),.3)
    P.dark=chosen.color:Lerp(P.bg,.75)
    for _,root in ipairs({mainGui,launcherGui}) do
        for _,obj in ipairs(root:GetDescendants()) do
            local properties={}
            if obj:IsA("GuiObject") then table.insert(properties,"BackgroundColor3") end
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then table.insert(properties,"TextColor3") end
            if obj:IsA("UIStroke") then table.insert(properties,"Color") end
            if obj:IsA("ScrollingFrame") then table.insert(properties,"ScrollBarImageColor3") end
            for _,key in ipairs(properties) do
                if obj[key]==oldAccent then obj[key]=P.purple
                elseif obj[key]==oldLight then obj[key]=P.light
                elseif obj[key]==oldDark then obj[key]=P.dark end
            end
        end
    end
    if settings.UIRefs.brand then settings.UIRefs.brand.TextColor3=P.purple end
    if settings.UIRefs.ringGradient then settings.UIRefs.ringGradient.Color=ColorSequence.new(P.purple,P.light) end
    notify("Theme: "..chosen.name)
end
local function nextTheme() applyTheme(themeIndex % #themes + 1) end

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
local blockReport = "Waiting for a detected attack"
local lastAttackReport = "No killer attack observed"
local blockRequests = 0
local seenAttacks = 0
local lastBlockMethod = "None"

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

-- Network ability path observed in public Forsaken client scripts.
-- Important: FireServer only confirms a request was sent; the server may
-- ignore it (cooldown, wrong character, no active round, changed API).
local function abilityRemote()
    local modules = game:GetService("ReplicatedStorage"):FindFirstChild("Modules")
    local network = modules and modules:FindFirstChild("Network")
    local remote = network and network:FindFirstChild("RemoteEvent")
    return remote and remote:IsA("RemoteEvent") and remote or nil
end

local function requestAbility(ability)
    local remote = abilityRemote()
    if not remote then return false, "Ability RemoteEvent not found" end
    local ok, err = pcall(function()
        remote:FireServer("UseActorAbility", ability)
    end)
    if ok then return true, "network request: "..ability end
    return false, "RemoteEvent failed: "..tostring(err)
end

local function trySendBlock()
    -- First prefer the same network ability request used by Forsaken's
    -- client API. This DOES NOT synthesize screen touches or freeze a joystick.
    local sent, method = requestAbility("Block")
    if sent then return true, method end

    -- An executor may also be able to fire the visible game's Block button.
    local button = getVisibleBlockButton()
    if button and type(firesignal) == "function" then
        local ok = pcall(function() firesignal(button.Activated) end)
        if ok then return true, "Block UI signal" end
    end
    if UIS.TouchEnabled and not UIS.KeyboardEnabled then
        return false, method .. "; safe mobile fallback unavailable"
    end
    local okService,vim=pcall(function()
        return game:GetService("VirtualInputManager")
    end)
    if okService and vim then
        local ok=pcall(function()
            vim:SendKeyEvent(true,Enum.KeyCode.Q,false,game)
            vim:SendKeyEvent(false,Enum.KeyCode.Q,false,game)
        end)
        if ok then return true, "Q key event" end
    end
    if type(keypress)=="function" and type(keyrelease)=="function" then
        local ok=pcall(function() keypress(0x51); keyrelease(0x51) end)
        if ok then return true, "Q executor key" end
    end
    return false, method .. "; no supported input fallback"
end

local function initializeAutoPunch()
-- RELEASE 11: Auto Punch is deliberately gated on an observable successful
-- block cue. A block *attempt* alone is never treated as success.
-- The action uses the real Punch UI (or desktop R key) and never simulates
-- screen touches, which can steal the iPad movement joystick.
local punchReport = "Waiting for a successful block"
local lastPunchAt = -1e6
local punchCueAt = -1e6
local watchedChar = nil
local aimTarget = nil
local aimUntil = 0
local savedAutoRotate = nil
local lastUIPoll = 0
local previousParryCue = false
local attachedSounds = setmetatable({}, {__mode="k"})

local function findPunchButton()
    for _, obj in ipairs(playerGui:GetDescendants()) do
        if obj:IsA("GuiButton") and obj.Visible and
            obj.AbsoluteSize.X > 5 and obj.AbsoluteSize.Y > 5 and
            not obj:IsDescendantOf(mainGui) and
            not obj:IsDescendantOf(launcherGui) then
            local n = normalizedName(obj.Name)
            local t = obj:IsA("TextButton") and normalizedName(obj.Text) or ""
            if n == "punch" or n == "punchbutton" or
                n == "parrypunch" or t == "punch" or t == "parry" then
                return obj
            end
            for _, desc in ipairs(obj:GetDescendants()) do
                if desc:IsA("TextLabel") then
                    local v = normalizedName(desc.Text)
                    if v == "punch" or v == "parry" or v == "parrypunch" then
                        return obj
                    end
                end
            end
        end
    end
    return nil
end

local function closestPunchTarget()
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local bestModel, bestDistance = nil, settings.GuestPunchRange
    for _, killer in ipairs(findActiveKillers()) do
        local targetRoot = killer:FindFirstChild("HumanoidRootPart") or killer.PrimaryPart
        local human = killer:FindFirstChildOfClass("Humanoid")
        if targetRoot and (not human or human.Health > 0) then
            local delta = targetRoot.Position - myRoot.Position
            local flat = Vector3.new(delta.X,0,delta.Z)
            if flat.Magnitude > 0.01 and flat.Magnitude <= bestDistance then
                bestDistance = flat.Magnitude
                bestModel = killer
            end
        end
    end
    return bestModel
end

local function stopPunchAim()
    aimUntil = 0
    aimTarget = nil
    if savedAutoRotate ~= nil then
        local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if h then pcall(function() h.AutoRotate = savedAutoRotate end) end
        savedAutoRotate = nil
    end
end

local function startPunchAim(target)
    if not settings.GuestPunchAim then return end
    local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not h then return end
    stopPunchAim()
    savedAutoRotate = h.AutoRotate
    h.AutoRotate = false
    aimTarget = target
    aimUntil = os.clock() + 0.34 -- short: avoid breaking joystick movement
    -- Face the killer BEFORE Punch input, not just on the next Heartbeat.
    local me = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local targetPart = target and (target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart)
    if me and targetPart then
        local delta = targetPart.Position - me.Position
        local flat = Vector3.new(delta.X,0,delta.Z)
        if flat.Magnitude > .02 then
            me.CFrame = CFrame.lookAt(me.Position,me.Position+flat)
        end
    end
end

local function sendPunchInput()
    local sent, method = requestAbility("Punch")
    if sent then return true, method end
    local button = findPunchButton()
    if button and type(firesignal) == "function" then
        local ok = pcall(function() firesignal(button.Activated) end)
        if ok then return true, "Punch button signal" end
    end
    if UIS.TouchEnabled and not UIS.KeyboardEnabled then
        return false, "No supported mobile Punch signal found"
    end
    local okService, vim = pcall(function() return game:GetService("VirtualInputManager") end)
    if okService and vim then
        local ok = pcall(function()
            vim:SendKeyEvent(true,Enum.KeyCode.R,false,game)
            vim:SendKeyEvent(false,Enum.KeyCode.R,false,game)
        end)
        if ok then return true, "R key" end
    end
    if type(keypress) == "function" and type(keyrelease) == "function" then
        local ok = pcall(function() keypress(0x52); keyrelease(0x52) end)
        if ok then return true,"R executor key" end
    end
    return false,"No supported Punch input found"
end

local function onSuccessfulBlock(source)
    if not settings.GuestAutoPunch or not playingGuest1337() then return end
    local now = os.clock()
    if now - punchCueAt < 0.5 or now - lastPunchAt < 1 then return end
    punchCueAt = now
    punchReport = "Successful block cue: " .. source
    task.delay(settings.GuestPunchDelay / 100, function()
        if not settings.GuestAutoPunch or not playingGuest1337() then return end
        -- The parry window is short; do not punch if a delayed callback is stale.
        if os.clock() - now > 0.75 then return end
        local killer = closestPunchTarget()
        if not killer then
            punchReport = "Block detected; no killer within punch range"
            return
        end
        lastPunchAt = os.clock()
        startPunchAim(killer)
        local ok, method = sendPunchInput()
        punchReport = (ok and "Punch input sent via " or "Punch unavailable: ") .. method
        if settings.GuestBlockAlerts then notify("Auto Punch: "..punchReport) end
    end)
end

local function isSuccessSound(obj)
    if not obj:IsA("Sound") then return false end
    local n = normalizedName(obj.Name)
    return n:find("blocksuccess",1,true) ~= nil or
        n:find("successfulblock",1,true) ~= nil or
        n:find("parryready",1,true) ~= nil or
        n:find("blockhit",1,true) ~= nil
end

local function observeSuccessSound(sound)
    if not isSuccessSound(sound) or attachedSounds[sound] then return end
    attachedSounds[sound] = true
    connect(sound.Played, function()
        if player.Character == watchedChar then
            onSuccessfulBlock("sound "..sound.Name)
        end
    end)
end

local watchAttributes = {"BlockSuccess","SuccessfulBlock","ParryReady","CanParry","ParryPunch"}
local function installPunchDetection(c)
    watchedChar = c
    previousParryCue = false
    if not c then return end
    for _, obj in ipairs(c:GetDescendants()) do
        observeSuccessSound(obj)
    end
    connect(c.DescendantAdded, function(obj)
        if player.Character == c then observeSuccessSound(obj) end
    end)
    local seenValues = {}
    for _, attr in ipairs(watchAttributes) do
        seenValues[attr] = c:GetAttribute(attr)
        connect(c:GetAttributeChangedSignal(attr),function()
            if player.Character ~= c then return end
            local value = c:GetAttribute(attr)
            local before = seenValues[attr]
            seenValues[attr] = value
            if (value == true and before ~= true) or
                (type(value)=="number" and type(before)=="number" and value>before) then
                onSuccessfulBlock("attribute "..attr)
            end
        end)
    end
end

connect(player.CharacterAdded, installPunchDetection)
if player.Character then installPunchDetection(player.Character) end

-- Polling checks only visible UI 'PARRY' change; never assumes an attack
-- succeeded simply because we sent the Block key.
connect(RunService.Heartbeat,function(dt)
    if not settings.GuestAutoPunch then
        if aimUntil > 0 then stopPunchAim() end
        previousParryCue = false
        return
    end
    if aimUntil > 0 then
        local me = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local target = aimTarget and (aimTarget:FindFirstChild("HumanoidRootPart") or aimTarget.PrimaryPart)
        if me and target and os.clock() < aimUntil then
            local delta = target.Position - me.Position
            local flat = Vector3.new(delta.X,0,delta.Z)
            if flat.Magnitude > .02 then
                me.CFrame = CFrame.lookAt(me.Position, me.Position + flat)
            end
        else
            stopPunchAim()
        end
    end
    if not playingGuest1337() then return end
    if os.clock() - lastUIPoll < 0.1 then return end
    lastUIPoll = os.clock()
    local button = findPunchButton()
    local parry = false
    if button then
        local n = normalizedName(button.Name)
        local t = button:IsA("TextButton") and normalizedName(button.Text) or ""
        parry = n:find("parry",1,true) ~= nil or t:find("parry",1,true) ~= nil
        if not parry then
            for _, desc in ipairs(button:GetDescendants()) do
                if desc:IsA("TextLabel") and normalizedName(desc.Text):find("parry",1,true) then
                    parry = true
                    break
                end
            end
        end
    end
    if parry and not previousParryCue then onSuccessfulBlock("Parry UI") end
    previousParryCue = parry
end)

Combat.getPunchReport = function() return punchReport end
Combat.resetPunch = function()
    stopPunchAim()
    punchReport = "Reset"
end
end -- initializeAutoPunch
initializeAutoPunch()

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
    -- Broad mode only: many killer attack animations have generic names.
    -- An Action-priority track can be a combat animation, but it can also
    -- be an emote or unrelated ability. Server cooldown always applies.
    if settings.GuestBlockAll then
        local priority = track.Priority
        if priority == Enum.AnimationPriority.Action
            or priority == Enum.AnimationPriority.Action2
            or priority == Enum.AnimationPriority.Action3
            or priority == Enum.AnimationPriority.Action4 then
            return "Unclassified action animation " .. tostring(id or "?"), "UncertainAction"
        end
    end
    return nil, nil
end

local function attemptBlock(model, attackLabel)
    -- Forsaken can rename the character model and skins independently of
    -- the selected survivor. Do not silently disable the input merely because
    -- the optional character-name heuristic failed. The game server validates.
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local killerRoot = model and model:FindFirstChild("HumanoidRootPart")
    local killerHum = model and model:FindFirstChildOfClass("Humanoid")
    if not myRoot or not killerRoot or (killerHum and killerHum.Health <= 0) then
        return false
    end
    local distance = (myRoot.Position - killerRoot.Position).Magnitude
    if distance > settings.GuestBlockRange then
        blockReport = "Attack seen but out of range: "..math.floor(distance).." studs"
        return false
    end
    local now = os.clock()
    if now - blockAttemptAt < settings.GuestBlockCooldown then
        blockReport = "Attack seen; retry delay " .. string.format("%.1fs", settings.GuestBlockCooldown - (now - blockAttemptAt))
        return false
    end
    blockAttemptAt = now
    local ok, method = trySendBlock()
    blockRequests = blockRequests + (ok and 1 or 0)
    lastBlockMethod = method
    blockReport = attackLabel .. " | " .. (ok and "request sent (not verified)" or "request failed") .. " | " .. method
    if settings.GuestBlockAlerts then
        notify(ok and ("Guard attempted: " .. attackLabel .. " via " .. method)
            or ("Guard failed: " .. method))
    end
    return ok
end

local function reactToAttack(model, track)
    if not (settings.GuestAutoBlock or settings.GuestBlockAll) then return end
    local attack, kind = attackFromTrack(track)
    local animation = track and track.Animation
    local animationId = animation and tostring(animation.AnimationId):match("%d+") or "unknown"
    seenAttacks = seenAttacks + 1
    lastAttackReport = tostring(model and model.Name or "Killer") .. " animation " .. tostring(animationId)
    if not attack then
        blockReport = "Observed " .. lastAttackReport .. "; not identified as an attack"
        return
    end
    lastAttackReport = attack .. " [" .. tostring(kind) .. "]"
    if settings.GuestAutoBlock and kind == "M1" then
        attemptBlock(model, attack)
    elseif settings.GuestBlockAll then
        attemptBlock(model, attack .. " [" .. kind .. "]")
    end
end

local function updateProximityGuard()
    if not settings.GuestProximityGuard then return end
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
                        record.trackSeen = record.trackSeen or setmetatable({}, {__mode="k"})
                        record.trackSeen[track] = os.clock()
                        reactToAttack(model, track)
                    end)
                end
            elseif animator and (settings.GuestAutoBlock or settings.GuestBlockAll)
                and not record.attackConnection then
                record.attackConnection = animator.AnimationPlayed:Connect(function(track)
                    record.trackSeen = record.trackSeen or setmetatable({}, {__mode="k"})
                    record.trackSeen[track] = os.clock()
                    reactToAttack(model, track)
                end)
            elseif not (settings.GuestAutoBlock or settings.GuestBlockAll)
                and record.attackConnection then
                record.attackConnection:Disconnect()
                record.attackConnection = nil
            end

            -- Existing playing tracks may predate AnimationPlayed attachment.
            -- Poll current tracks too, with a short per-track deduplication.
            if animator and (settings.GuestAutoBlock or settings.GuestBlockAll) then
                record.trackSeen = record.trackSeen or setmetatable({}, {__mode="k"})
                local observedAt = os.clock()
                local okTracks, tracks = pcall(function()
                    return animator:GetPlayingAnimationTracks()
                end)
                if okTracks and tracks then
                    for _, track in ipairs(tracks) do
                        local last = record.trackSeen[track]
                        if not last or observedAt - last > 2 then
                            record.trackSeen[track] = observedAt
                            reactToAttack(model, track)
                        end
                    end
                end
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
                record.labelText.Text = "KILLER" .. (studs and (" - " .. studs .. " STUDS") or "")
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
    if Combat.resetPunch then Combat.resetPunch() end
    oldExtraCleanup()
end

local function resetCombat()
    for _, key in ipairs({"KillerHitbox", "KillerAura", "KillerLabel",
        "GuestAutoBlock", "GuestBlockAll", "GuestProximityGuard", "GuestBlockAlerts",
        "GuestAutoPunch", "GuestPunchAim"}) do
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
Combat.getBlockDebug = function()
    return "Killer(s): " .. tostring(#findActiveKillers())
        .. " | Guest name recognized: " .. tostring(playingGuest1337())
        .. " | Network found: " .. tostring(abilityRemote() ~= nil)
        .. " | Tracks seen: " .. tostring(seenAttacks)
        .. " | Requests sent: " .. tostring(blockRequests)
        .. " | Last input: " .. lastBlockMethod
        .. " | Last track: " .. lastAttackReport
end
Combat.testBlockNow = function()
    local ok, method = trySendBlock()
    blockRequests = blockRequests + (ok and 1 or 0)
    lastBlockMethod = method
    blockAttemptAt = os.clock()
    blockReport = "Manual block test: " .. (ok and "request sent; server result unknown" or "failed") .. " via " .. method
    return blockReport
end
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
    if Bindings.autoSave then Bindings.autoSave() end
end
local function resetEverything()
    for _, key in ipairs({
        "Sprint", "Speed", "Noclip", "JumpBoost", "InfiniteJump",
        "Stamina", "ESP", "Names", "Distance", "Fullbright",
        "NoFog", "WideFOV", "FakeLag"
    }) do
        setToggle(key, false)
    end
    stopFakeLag()
    restoreStaminaModule()
    restoreCollision()
    restoreMovement()
    stopESP()
    restoreLighting()
    resetAllExtras()
    Combat.resetCombat()
    notify("Local settings reset")
end

-- HOME
card(home, "Σ  SIGMASAKEN V2 • 16.0", "Custom interface • Made by xbolitas.")
card(home,"QUICK NAVIGATION","Search across all sections, use Next to jump to matching tabs, and Pin to keep your favorite tabs at the top.")
card(home, "◉  PLAYER TOOLS", "Simple Player page for sprint and stamina; extras in Player Extras.")
card(home, "◇  VISUAL TOOLS", "Player highlights, names, health, team colors and range filters.")
card(home, "⚔  KILLER COMBAT", "Updated Block request for mobile. Combat tab has TEST BLOCK NOW + Auto Block Debug.")
card(home, "◈  CAMERA + WORLD", "FOV, spectating, zoom, lighting and effects.")
card(home, "▤  HUD + AUDIO", "Live FPS, position, speed, health, player count and local audio.")
card(home, "ⓘ  HOW IT WORKS", "Client-only controls: a game server can override movement and stamina.")
addAction(home, "Show controls", "Test the animated notification", function()
    notify("SigmaSaken V2 is ready")
end)
addAction(home, "Reset all local effects", "Restore the movement, camera and world", resetEverything)

-- PLAYER
card(playerPage, "◉  PLAYER", "Simple controls: sprint speed and stamina. Server restrictions may override changes.")
addToggle(playerPage, "Player Sprint Speed", "Turn sprint speed on or off", "Sprint")
addSlider(playerPage, "Sprint Speed", 18, 60, 26, function(v) settings.SprintValue = v end)
addToggle(playerPage, "Infinite Stamina", "Try to keep stamina full (Forsaken may override it)", "Stamina", function(on)
    if on then refillStamina(true) else restoreStaminaModule() end
    notify("Stamina: "..(on and lastStaminaReport or "Disabled"))
end)
-- All older movement features remain available, but no longer crowd Player.
card(pages["Player Extras"], "✦  PLAYER EXTRAS", "Advanced movement, jumping and diagnostics.")
addToggle(pages["Player Extras"], "Speed Boost", "Set local walking speed", "Speed")
addSlider(pages["Player Extras"], "Speed value", 16, 85, 36, function(v) settings.SpeedValue = v end)
addToggle(pages["Player Extras"], "Noclip", "Disable local character collisions", "Noclip", function(on)
    if not on then restoreCollision() end
end)
addToggle(pages["Player Extras"], "Jump Boost", "Increase your local jump power", "JumpBoost")
addSlider(pages["Player Extras"], "Jump power", 50, 140, 75, function(v) settings.JumpValue = v end)
addToggle(pages["Player Extras"], "Infinite Jump", "Request another jump while airborne", "InfiniteJump")
addToggle(pages["Player Extras"], "Auto Jump", "Jump repeatedly while moving on ground", "AutoJump")
addToggle(pages["Player Extras"], "No Sit", "Automatically stand when seated", "NoSit")
addToggle(pages["Player Extras"], "Auto Rotate", "Turn your character towards movement", "AutoRotate", function(on)
    if getHumanoid() then humanoid.AutoRotate = on end
end)
addAction(pages["Player Extras"], "Stamina diagnostic", "Detailed compatibility check for current Forsaken update", function()
    local alreadyEnabled = settings.Stamina
    if not alreadyEnabled then
        notify("Turn on Infinite Stamina first, then run diagnostic")
    else
        refillStamina(true)
        notify(settings.LastStaminaDetails)
        warn("SigmaSaken stamina diagnostic: "..settings.LastStaminaDetails)
    end
end)
card(pages["Player Extras"], "⚡  FAKE LAG • RUN IN PLACE", "Run animation while staying still. This is visual only, NOT actual network lag.")
addToggle(pages["Player Extras"], "Fake Lag • Run in Place", "Animate running while staying in one spot", "FakeLag", function(on)
    if on then startFakeLag() else stopFakeLag() end
    notify(on and ("Fake Lag: " .. fakeLagReport) or "Fake Lag disabled")
end)
addToggle(pages["Player Extras"], "Fake Lag Stutter", "Periodically pause frames of the running animation", "FakeLagStutter")
addSlider(pages["Player Extras"], "Fake Lag animation speed", 5, 30, 16, function(v)
    settings.FakeLagAnimSpeed = v
end)
addAction(pages["Player Extras"], "Fake Lag status", "Check whether a run animation was loaded", function()
    notify("Fake Lag: " .. fakeLagReport)
end)
addAction(pages["Player Extras"], "Stop Fake Lag", "Resume standard movement and idle animation", function()
    setToggle("FakeLag", false)
    stopFakeLag()
    notify("Fake Lag stopped")
end)
addAction(pages["Player Extras"], "Jump now", "Trigger a local Humanoid jump", function()
    if getHumanoid() then
        humanoid.Jump = true
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)
addAction(pages["Player Extras"], "Turn noclip ON/OFF", "Instantly switch the collision setting", function()
    setToggle("Noclip", not settings.Noclip)
    if not settings.Noclip then restoreCollision() end
    notify("Noclip: " .. tostring(settings.Noclip))
end)
addAction(pages["Player Extras"], "Reset movement", "Restore original speed, jump and collisions", function()
    for _, key in ipairs({"Sprint", "Speed", "Noclip", "JumpBoost", "InfiniteJump", "AutoJump", "NoSit", "Stamina"}) do
        setToggle(key, false)
    end
    setToggle("FakeLag", false)
    stopFakeLag()
    restoreMovement()
    restoreCollision()
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
card(combatPage, "⛨  GUEST 1337 DEFENSE", "New Block network request for mobile. Use TEST BLOCK NOW then Auto Block Debug. Server validates cooldown.")
addToggle(combatPage, "Auto Block Guest M1", "M1 attack detection; direct ability request on mobile", "GuestAutoBlock", function(on)
    Combat.updateKillers()
    notify(on and "M1 guard enabled • Guest only" or "M1 guard disabled")
end)
addToggle(combatPage, "Auto Block All • experimental", "Experimental attack detection; direct ability request", "GuestBlockAll", function(on)
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
addSlider(combatPage, "Guard retry interval (seconds)", 1, 35, 3, function(v)
    settings.GuestBlockCooldown = v
end)
addToggle(combatPage, "Block Alerts", "Notify when defense input is attempted", "GuestBlockAlerts")
card(combatPage, "🥊  AUTO PUNCH", "On a confirmed successful Block cue, face the nearest killer and try Punch. Not triggered by failed blocks.")
addToggle(combatPage, "Auto Punch After Block", "Guest 1337 only; requires a positive successful-block cue", "GuestAutoPunch", function(on)
    if not on and Combat.resetPunch then Combat.resetPunch() end
    notify(on and "Auto Punch watching for successful blocks" or "Auto Punch disabled")
end)
addToggle(combatPage, "Punch Aimbot", "Briefly face the nearest killer during the punch", "GuestPunchAim")
addSlider(combatPage, "Punch Range", 5, 18, 13, function(v) settings.GuestPunchRange = v end)
addSlider(combatPage, "Punch Delay (x10 ms)", 0, 30, 6, function(v) settings.GuestPunchDelay = v end)
addAction(combatPage, "Auto Punch Status", "Show detection and input status for this session", function()
    notify("Auto Punch: "..Combat.getPunchReport())
end)
addAction(combatPage, "Check Guest + Killer", "Check your current character and nearby killers", function()
    local killers = Combat.findActiveKillers()
    notify((Combat.playingGuest1337() and "Guest 1337 OK" or "Guest 1337 not detected") ..
        " • " .. tostring(#killers) .. " killer(s)")
end)
addAction(combatPage, "Block status", "Show last attack and input attempt", function()
    notify(Combat.getBlockReport())
end)
addAction(combatPage, "TEST BLOCK NOW", "While playing Guest, manually test the real Block request. May use ability cooldown.", function()
    notify(Combat.testBlockNow())
end)
addAction(combatPage, "Auto Block Debug", "Show killer detection, remote status, detected animations and sent requests", function()
    notify(Combat.getBlockDebug())
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
card(config, "⚙  STYLE & CONTROLS", "Dark panels, compact rows and movable Sigma launcher.")
addToggle(config, "UI Animations", "Enable transitions and decorative motion", "Animations", settings.refreshAmbientMotion)
addToggle(config, "Accent Glow", "Animate window border opacity", "Glow", function(enabled)
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
addAction(config, "Change accent theme", "Cycle crimson, violet, cyan, rose, emerald and gold", nextTheme)
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




-- Native config profiles. No external UI library or network storage.
do
    local http=game:GetService("HttpService")
    local filename="SigmaSakenV2_CustomProfiles.json"
    local store={profiles={},active="",autoSave=false,autoLoad=false}
    local busy=false
    local generation=0
    if type(readfile)=="function" then
        local ok,data=pcall(function() return http:JSONDecode(readfile(filename)) end)
        if ok and type(data)=="table" and type(data.profiles)=="table" then
            store.profiles=data.profiles
            store.active=type(data.active)=="string" and data.active or ""
            store.autoSave=data.autoSave==true
            store.autoLoad=data.autoLoad==true
        end
    end
    local function persist()
        if type(writefile)~="function" then return false end
        return pcall(function() writefile(filename,http:JSONEncode(store)) end)
    end
    local function validName(value)
        local v=tostring(value or ""):match("^%s*(.-)%s*$")
        if #v>0 and #v<=32 and v:match("^[%w _%-]+$") then return v end
    end
    card(config,"CONFIG PROFILES","Create a named profile, save it, then load it on this device.")
    local inputRow=listRow(config,76,P.card)
    local caption=label(inputRow,"Config name",13,true)
    caption.Position=UDim2.fromOffset(9,3); caption.Size=UDim2.new(1,-18,0,22)
    local input=make("TextBox",inputRow,{Position=UDim2.fromOffset(9,30),Size=UDim2.new(1,-18,0,34),Text=store.active,PlaceholderText="e.g. MyConfig",ClearTextOnFocus=false,BackgroundColor3=P.dim,TextColor3=P.white,PlaceholderColor3=P.muted,TextSize=13,Font=Enum.Font.Gotham})
    rounded(input,14)
    inputRow:SetAttribute("ControlKind","action")
    local selection=listRow(config,48,P.card2)
    selection:SetAttribute("ControlKind","action")
    local selectButton=make("TextButton",selection,{Size=UDim2.fromScale(1,1),Text="Saved configs ▾",TextColor3=P.white,TextSize=13,Font=Enum.Font.GothamMedium,BackgroundTransparency=1,AutoButtonColor=false})
    local function refresh()
        selectButton.Text=(store.active~="" and store.active or "Saved configs").."  >"
    end
    refresh()
    local function selectNext()
        local names={}
        for name in pairs(store.profiles) do if type(name)=="string" then table.insert(names,name) end end
        table.sort(names)
        if #names==0 then notify("No profiles yet"); return end
        local idx=0
        for i,name in ipairs(names) do if name==store.active then idx=i end end
        generation=generation+1
        store.active=names[idx%#names+1]; input.Text=store.active; refresh(); persist()
    end
    connect(selectButton.Activated,selectNext)
    local function snapshot()
        local data={toggles={},sliders={},theme=themeIndex,keys={},pinned={}}
        for name,value in pairs(settings.PinnedPages) do if value then data.pinned[name]=true end end
        for _,def in ipairs(Bindings.controls) do
            if def.kind=="toggle" and def.key~="ProfileAutoSave" and def.key~="ProfileAutoLoad" then data.toggles[def.key]=settings[def.key]==true
            elseif def.kind=="slider" then data.sliders[def.page..":"..def.title]=def.value or def.initial end
        end
        if Bindings.exportKeys then data.keys=Bindings.exportKeys() end
        return data
    end
    local function save(silent)
        if busy or store.active=="" or not store.profiles[store.active] then if not silent then notify("Create or select a profile first") end; return false end
        local previous=store.profiles[store.active]
        store.profiles[store.active]=snapshot()
        local ok=persist()
        if not ok then store.profiles[store.active]=previous end
        if not silent then notify(ok and ("Saved: "..store.active) or "Cannot write profile on this device") end
        return ok
    end
    local function load(silent)
        generation=generation+1
        local data=store.profiles[store.active]
        if type(data)~="table" then if not silent then notify("Select a saved profile first") end; return end
        busy=true
        local ok,err=pcall(function()
            for _,def in ipairs(Bindings.controls) do
                if def.kind=="toggle" and type(data.toggles)=="table" and type(data.toggles[def.key])=="boolean" and def.key~="ProfileAutoSave" and def.key~="ProfileAutoLoad" then
                    local entry=Bindings.registry["Toggle:"..def.key]
                    if entry and settings[def.key]~=data.toggles[def.key] then entry.perform() end
                elseif def.kind=="slider" and type(data.sliders)=="table" and def.apply then
                    local v=data.sliders[def.page..":"..def.title]
                    if type(v)=="number" then def.apply(v) end
                end
            end
            if type(data.pinned)=="table" then
                table.clear(settings.PinnedPages)
                for name,value in pairs(data.pinned) do
                    if pages[name] and name~="Keybinds" and value==true then settings.PinnedPages[name]=true end
                end
                if Bindings.refreshSearchNav then Bindings.refreshSearchNav() end
            end
            if data.theme then applyTheme(data.theme) end
            if Bindings.importKeys and type(data.keys)=="table" then Bindings.importKeys(data.keys) end
        end)
        busy=false
        refresh()
        if not silent or not ok then notify(ok and ("Loaded: "..store.active) or ("Load failed: "..tostring(err))) end
    end
    addAction(config,"Create Config","Create and save the profile named above",function()
        local name=validName(input.Text)
        if not name then notify("Use 1–32 letters, digits, spaces, - or _"); return end
        if store.profiles[name] then notify("Profile exists; select it to overwrite"); return end
        generation=generation+1
        local old=store.active; store.active=name; store.profiles[name]=snapshot()
        if persist() then refresh(); notify("Created: "..name) else store.active=old; store.profiles[name]=nil; notify("Local file storage unavailable") end
    end)
    addAction(config,"Select Config by Name","Type an existing name or tap Saved configs to cycle",function()
        local name=validName(input.Text)
        if name and store.profiles[name] then generation=generation+1;store.active=name;refresh();persist();notify("Selected: "..name) else notify("Profile not found") end
    end)
    addAction(config,"Save Config","Save the selected profile",function() save(false) end)
    addAction(config,"Load Config","Restore the selected profile",function() load(false) end)
    addAction(config,"Delete Config","Delete the selected local profile",function()
        if not store.profiles[store.active] then return end
        generation=generation+1
        local old=store.active; local data=store.profiles[old]
        store.profiles[old]=nil;store.active=""
        if persist() then input.Text="";refresh();notify("Deleted: "..old) else store.active=old;store.profiles[old]=data;notify("Delete failed") end
    end)
    settings.ProfileAutoSave=store.autoSave
    settings.ProfileAutoLoad=store.autoLoad
    addToggle(config,"Auto Save","Save after 1.5 seconds without changes","ProfileAutoSave",function(v) store.autoSave=v;generation=generation+1;persist() end)
    addToggle(config,"Auto Load","Load the selected profile on startup","ProfileAutoLoad",function(v) store.autoLoad=v;persist() end)
    addSlider(config,"Floating Button Size",48,90,68,function(v)
        floating.Size=UDim2.fromOffset(v,v)
        settings.UIRefs.core.Size=UDim2.fromOffset(v-15,v-15)
        settings.UIRefs.glyph.TextSize=math.floor(v*.5)
    end)
    addSlider(config,"Accent Theme",1,#themes,1,applyTheme)
    do
        local rgb={232,72,95}
        local function color(i,v)
            rgb[i]=v
            local c=Color3.fromRGB(rgb[1],rgb[2],rgb[3])
            settings.UIRefs.floatRing.Color=c
            settings.UIRefs.pulseStroke.Color=c
            settings.UIRefs.glyph.TextColor3=c
            settings.UIRefs.ringGradient.Color=ColorSequence.new(c,c:Lerp(Color3.new(1,1,1),.35))
        end
        addSlider(config,"Launcher Red",0,255,232,function(v) color(1,v) end)
        addSlider(config,"Launcher Green",0,255,72,function(v) color(2,v) end)
        addSlider(config,"Launcher Blue",0,255,95,function(v) color(3,v) end)
    end
    Bindings.autoSave=function()
        if not settings.CustomAutoLoaded or busy or not store.autoSave or not store.profiles[store.active] then return end
        generation=generation+1
        local token=generation
        task.delay(1.5,function()
            if mainGui.Parent and token==generation and not busy and store.autoSave then save(true) end
        end)
    end
    Bindings.autoLoad=function()
        if store.autoLoad and store.active~="" then load(true) end
    end
end

do -- keep keybind UI state local to avoid Roblox chunk local-variable limits
local keybindPage = pages.Keybinds
local bindableRegistry = Bindings.registry
local bindableOrder = Bindings.order
local keyAssignments = {}
local keybindButtons = {}
local captureId = nil
local refreshKeybindFilter = function() end

-- ==========================================================================
-- PC KEYBINDS: type a key to assign it to any registered toggle/action.
-- Bindings work even when the main menu is minimized (PC mode only).
-- Save/load is optional and relies on executor's local file APIs.
-- ==========================================================================
local HttpService = game:GetService("HttpService")
local keybindFileName = "SigmaSakenV2_keybinds.json"
local searchText = ""

local function refreshBindLabels()
    for id, button in pairs(keybindButtons) do
        if button and button.Parent then
            if captureId == id then
                button.Text = "PRESS KEY..."
                button.TextColor3 = P.light
            else
                button.Text = keyAssignments[id] or "SET KEY"
                button.TextColor3 = keyAssignments[id] and P.white or P.muted
            end
        end
    end
end

local function bindKey(id, keyName)
    if not bindableRegistry[id] then return end
    if keyName ~= nil then
        local ok = pcall(function()
            return Enum.KeyCode[keyName]
        end)
        if not ok or Enum.KeyCode[keyName] == nil then return end
    end
    if keyName then
        for otherId, otherKey in pairs(keyAssignments) do
            if otherId ~= id and otherKey == keyName then
                keyAssignments[otherId] = nil
            end
        end
    end
    keyAssignments[id] = keyName
    refreshBindLabels()
    if Bindings.autoSave then Bindings.autoSave() end
end

local function saveKeybinds()
    if type(writefile) ~= "function" then
        notify("Saving shortcuts is unavailable on this executor")
        return
    end
    local ok, err = pcall(function()
        writefile(keybindFileName, HttpService:JSONEncode(keyAssignments))
    end)
    notify(ok and "Keybinds saved" or ("Save failed: "..tostring(err)))
end

local function loadKeybinds()
    if type(readfile) ~= "function" then
        notify("Loading shortcuts is unavailable on this executor")
        return
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(keybindFileName))
    end)
    if not ok or type(data) ~= "table" then
        notify("No saved keybind configuration found")
        return
    end
    table.clear(keyAssignments)
    for id, keyName in pairs(data) do
        if type(id) == "string" and type(keyName) == "string" then
            bindKey(id, keyName)
        end
    end
    refreshBindLabels()
    notify("Keybinds loaded")
end

card(keybindPage, "⌨  PERSONALIZED KEYBINDS",
    "PC only • Choose a function below, press SET KEY and then your desired key. Escape cancels; Backspace clears.")

local searchHolder = listRow(keybindPage, 67, P.card2)
local searchInput = make("TextBox", searchHolder, {
    Position = UDim2.fromOffset(16,12),
    Size = UDim2.new(1,-32,0,43),
    BackgroundColor3 = P.dim,
    Text = "",
    PlaceholderText = "Search controls (e.g. Sprint, ESP, Noclip)",
    PlaceholderColor3 = P.muted,
    TextColor3 = P.white,
    TextSize = 15,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left
})
rounded(searchInput, 19)
make("UIPadding",searchInput,{PaddingLeft=UDim.new(0,15)})

local function smallCommand(title, callback)
    local row = listRow(keybindPage,55,P.card2)
    local button = make("TextButton",row,{
        Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
        Text=title, TextColor3=P.light,
        Font=Enum.Font.GothamBold,TextSize=15,
        AutoButtonColor=false
    })
    pressEffect(button)
    connect(button.MouseButton1Click,callback)
    return row
end

smallCommand("SAVE KEYBINDS TO DEVICE",saveKeybinds)
smallCommand("LOAD SAVED KEYBINDS",loadKeybinds)
smallCommand("CLEAR ALL KEYBINDS",function()
    table.clear(keyAssignments)
    captureId = nil
    refreshBindLabels()
    notify("All keybinds cleared")
    if Bindings.autoSave then Bindings.autoSave() end
end)

local keybindRows = {}
for _, entry in ipairs(bindableOrder) do
    local row = listRow(keybindPage,74,P.card)
    keybindRows[entry.id] = row
    local name = label(row,entry.title,14,true,P.white)
    name.Position=UDim2.fromOffset(15,7)
    name.Size=UDim2.new(1,-158,0,30)
    local details = label(row,entry.category:upper().."  •  "..entry.kind,11,false,P.muted)
    details.Position=UDim2.fromOffset(15,38)
    details.Size=UDim2.new(1,-158,0,22)
    local captureButton=make("TextButton",row,{
        AnchorPoint=Vector2.new(1,.5),
        Position=UDim2.new(1,-13,.5,0),
        Size=UDim2.fromOffset(127,41),
        BackgroundColor3=P.dark,
        Text="SET KEY",TextColor3=P.muted,
        TextSize=13,Font=Enum.Font.GothamBold,
        AutoButtonColor=false
    })
    rounded(captureButton,18)
    outline(captureButton,P.purple,1,.4)
    pressEffect(captureButton)
    keybindButtons[entry.id]=captureButton
    connect(captureButton.MouseButton1Click,function()
        captureId=entry.id
        refreshBindLabels()
        notify("Press a keyboard key for "..entry.title)
    end)
end

refreshKeybindFilter=function()
    local q=string.lower(searchText)
    for _, entry in ipairs(bindableOrder) do
        local row=keybindRows[entry.id]
        local haystack=string.lower(entry.title.." "..entry.category.." "..entry.kind)
        row.Visible=(q=="" or string.find(haystack,q,1,true)~=nil)
    end
end

connect(searchInput:GetPropertyChangedSignal("Text"),function()
    searchText=searchInput.Text
    refreshKeybindFilter()
end)

connect(UIS.InputBegan,function(input,processed)
    if selectedMode ~= "PC" then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode == Enum.KeyCode.Unknown then return end
    if captureId then
        local id=captureId
        captureId=nil
        if input.KeyCode == Enum.KeyCode.Escape then
            refreshBindLabels()
            notify("Keybind cancelled")
        elseif input.KeyCode == Enum.KeyCode.Backspace or
            input.KeyCode == Enum.KeyCode.Delete then
            bindKey(id,nil)
            notify("Keybind removed")
        else
            bindKey(id,input.KeyCode.Name)
            notify(bindableRegistry[id].title.." = "..input.KeyCode.Name)
        end
        return
    end
    if processed or UIS:GetFocusedTextBox() then return end
    for id, keyName in pairs(keyAssignments) do
        if input.KeyCode.Name == keyName then
            local entry=bindableRegistry[id]
            if entry then
                local ok,err=pcall(entry.perform)
                if not ok then warn("Sigma keybind: "..tostring(err)) end
            end
            break
        end
    end
end)

-- Restore automatically only when the executor exposes local file access.
if type(readfile)=="function" then
    pcall(function()
        local saved=HttpService:JSONDecode(readfile(keybindFileName))
        if type(saved)=="table" then
            for id,keyName in pairs(saved) do
                if type(keyName)=="string" then bindKey(id,keyName) end
            end
        end
    end)
end

Bindings.exportKeys=function()
    local copy={}
    for id,key in pairs(keyAssignments) do copy[id]=key end
    return copy
end
Bindings.importKeys=function(data)
    table.clear(keyAssignments)
    for id,key in pairs(data) do if type(id)=="string" and type(key)=="string" then bindKey(id,key) end end
    refreshBindLabels()
end
end -- PC keybind UI

local pageTitles = {
    Home="Dashboard", Player="Player", ["Player Extras"]="Player Extras", Combat="Combat", Visuals="Visuals",
    Camera="Camera", World="World", HUD="HUD",
    Audio="Audio", Config="Configuration", Keybinds="Keybinds"
}
do
    local strip=make("Frame",content,{Position=UDim2.fromOffset(12,75),Size=UDim2.new(1,-24,0,29),BackgroundTransparency=1})
    make("UIListLayout",strip,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5)})
    settings.FilterButtons={}
    for _,item in ipairs({{"All","All"},{"Toggles","toggle"},{"Sliders","slider"},{"Actions","action"}}) do
        local b=make("TextButton",strip,{Size=UDim2.new(.25,-4,1,0),BackgroundColor3=P.card2,Text=item[1],TextColor3=P.muted,TextSize=11,Font=Enum.Font.GothamMedium,AutoButtonColor=false})
        rounded(b,100); pressEffect(b)
        settings.FilterButtons[item[2]]=b
        connect(b.Activated,function()
            if not currentPage or currentPage=="Keybinds" then return end
            settings.PageUI[currentPage].filter=item[2]
            for k,button in pairs(settings.FilterButtons) do tween(button,.18,{BackgroundColor3=k==item[2] and P.dark or P.card2,TextColor3=k==item[2] and P.light or P.muted}) end
            Bindings.reflow()
        end)
    end
    settings.FilterStrip=strip
end
local function changePage(name)
    if name == "Keybinds" and selectedMode ~= "PC" then return end
    if currentPage == name then return end
    currentPage = name
    heading.Text = pageTitles[name]
    headingSub.Text = name=="Combat" and "Combat settings and attack detection" or (name=="Config" and "Profiles, appearance and preferences" or "Made by xbolitas - "..name)
    settings.FilterStrip.Visible=name~="Keybinds"
    if Bindings.searchBar then Bindings.searchBar.Visible=name~="Keybinds" end
    holder.Position=UDim2.fromOffset(12,name=="Keybinds" and 82 or 150)
    holder.Size=UDim2.new(1,-24,1,name=="Keybinds" and -96 or -164)
    if Bindings.refreshSearchNav then Bindings.refreshSearchNav() end
    local filter=settings.PageUI[name].filter or "All"
    for k,b in pairs(settings.FilterButtons) do tween(b,.15,{BackgroundColor3=k==filter and P.dark or P.card2,TextColor3=k==filter and P.light or P.muted}) end
    for key,p in pairs(pages) do
        p.Visible = (key == name)
        if key == name then p.CanvasPosition = Vector2.new(0,0) end
    end
    for key,group in pairs(navButtons) do
        for _,button in ipairs(group) do
            tween(button,.25,{
                BackgroundColor3 = key == name and P.dark or P.side,
                TextColor3 = key == name and P.light or P.muted
            })
        end
    end
    local page = pages[name]
    page.Position = UDim2.fromOffset(26,6)
    heading.TextTransparency = .6
    headingSub.TextTransparency = .65
    tween(heading,.28,{TextTransparency=0},Enum.EasingStyle.Sine)
    tween(headingSub,.36,{TextTransparency=0},Enum.EasingStyle.Sine)
    tween(page,.38,{Position=UDim2.fromOffset(0,0)},Enum.EasingStyle.Quint)
end
local sectionData = {
    {"Home","Home"}, {"Combat","Combat"}, {"Player","Player"}, {"Extras","Player Extras"},
    {"Visuals","Visuals"}, {"Camera","Camera"}, {"World","World"}, {"HUD","HUD"},
    {"Audio","Audio"}, {"Config","Config"}, {"Keybinds","Keybinds"}
}
for i,item in ipairs(sectionData) do
    navButtons[item[2]]={}
    local desk=make("TextButton",nav,{
        LayoutOrder=i,Size=UDim2.new(1,0,0,40),BackgroundColor3=P.side,Text=item[1],
        TextColor3=P.muted,TextSize=13,Font=Enum.Font.GothamMedium,AutoButtonColor=false,
        TextXAlignment=Enum.TextXAlignment.Center
    })
    rounded(desk,100);pressEffect(desk)
    table.insert(navButtons[item[2]],desk)
    desk.Visible=item[2]~="Keybinds"
    connect(desk.Activated,function() changePage(item[2]) end)
    desk:SetAttribute("NavigationLabel",item[2])
end
-- Release 16: global option search, clear, jump between matching sections and pinned tabs.
do
    local toolbar=make("Frame",content,{
        Position=UDim2.fromOffset(12,109), Size=UDim2.new(1,-24,0,34),
        BackgroundTransparency=1})
    Bindings.searchBar=toolbar
    local field=make("TextBox",toolbar,{
        Size=UDim2.new(.54,-5,1,0), BackgroundColor3=P.card2,
        Text="",PlaceholderText="Search options...",TextColor3=P.white,
        PlaceholderColor3=P.muted,TextSize=13,Font=Enum.Font.Gotham,
        ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left})
    rounded(field,100)
    make("UIPadding",field,{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,8)})
    local function toolButton(title,x,w)
        local b=make("TextButton",toolbar,{
            Position=UDim2.new(x,0,0,0),Size=UDim2.new(w,-5,1,0),
            Text=title,TextSize=11,Font=Enum.Font.GothamMedium,
            TextColor3=P.white,BackgroundColor3=P.card2,AutoButtonColor=false})
        rounded(b,100);pressEffect(b);return b
    end
    local clear=toolButton("Clear",.54,.14)
    local nextButton=toolButton("Next",.68,.16)
    local pin=toolButton("Pin",.84,.16)
    local names={}
    for i,item in ipairs(sectionData) do
        names[i]=item[2]
        for _,b in ipairs(navButtons[item[2]]) do
            b:SetAttribute("BaseNavOrder",i)
            b:SetAttribute("BaseNavText",item[1])
        end
    end
    Bindings.refreshSearchNav=function()
        local q=string.lower(settings.SearchText or ""):match("^%s*(.-)%s*$")
        local count=0
        for _,name in ipairs(names) do
            local state=settings.PageUI[name]
            local matches=state and state.matches or 0
            if name~="Keybinds" and matches>0 then count=count+matches end
            for _,b in ipairs(navButtons[name] or {}) do
                local title=b:GetAttribute("BaseNavText") or name
                b.LayoutOrder=(b:GetAttribute("BaseNavOrder") or 0)-(settings.PinnedPages[name] and 100 or 0)
                b.Text=title..(settings.PinnedPages[name] and " +" or "")..
                    (q~="" and name~="Keybinds" and (" ("..matches..")") or "")
            end
        end
        nextButton.Text=q=="" and "Next" or ("Next "..count)
        pin.Text=settings.PinnedPages[currentPage] and "Unpin" or "Pin"
        pin.BackgroundColor3=settings.PinnedPages[currentPage] and P.dark or P.card2
    end
    local function jump()
        if settings.SearchText:match("^%s*$") then return end
        local at=table.find(names,currentPage) or 0
        for step=1,#names do
            local name=names[(at+step-1)%#names+1]
            local state=settings.PageUI[name]
            if name~="Keybinds" and state and (state.matches or 0)>0 then
                changePage(name);return
            end
        end
        notify("No matching options")
    end
    connect(field:GetPropertyChangedSignal("Text"),function()
        settings.SearchText=field.Text
        Bindings.reflow()
        if currentPage and pages[currentPage] then pages[currentPage].CanvasPosition=Vector2.zero end
    end)
    connect(field.FocusLost,function(enterPressed) if enterPressed then jump() end end)
    connect(clear.Activated,function() field.Text="";field:ReleaseFocus() end)
    connect(nextButton.Activated,jump)
    connect(pin.Activated,function()
        if not currentPage or currentPage=="Keybinds" then return end
        settings.PinnedPages[currentPage]=not settings.PinnedPages[currentPage]
        Bindings.refreshSearchNav()
        if Bindings.autoSave then Bindings.autoSave() end
    end)
end
changePage("Home")
connect(holder:GetPropertyChangedSignal("AbsoluteSize"),function()
    if selectedMode then task.defer(Bindings.reflow) end
end)
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
    Text = "", TextSize = 21,
    TextColor3 = P.light, Font = Enum.Font.GothamBold,
    AutoButtonColor = false, ZIndex = 12
})
rounded(resize, 100)
-- Native geometry for a resize handle; no font glyphs required.
do
    for i=1,3 do
        local line=make("Frame",resize,{
            AnchorPoint=Vector2.new(.5,.5),
            Position=UDim2.fromOffset(13+i*4,25-i*2),
            Size=UDim2.fromOffset(9+i*2,2),Rotation=-45,
            BackgroundColor3=P.light,BorderSizePixel=0,ZIndex=13})
        rounded(line,100)
    end
end
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
        4, math.max(4, screen.X - floating.AbsoluteSize.X - 4))
    local y = math.clamp(floatingDrag.origin.Y.Offset + delta.Y,
        4, math.max(4, screen.Y - floating.AbsoluteSize.Y - 4))
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
    math.floor((viewport.Y - 68)/2))

-- DEVICE CHOICE: always prompt on execution, no stored selection.
showDevicePicker = function()
    if main.Visible then
        main.Visible = false
    end
    isOpen = false
    floating.Visible = false
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
    if settings.SelectingDevice then return end
    settings.SelectingDevice=true
    selectedMode = mode
    applyDeviceLayout(mode)
    local endTween = tween(selectorScale,.21,{Scale=.86})
    if endTween then endTween.Completed:Wait() end
    selector.Visible = false
    Bindings.reflow()
    showMenu()
    if not settings.CustomAutoLoaded then
        settings.CustomAutoLoaded=true
        if Bindings.autoLoad then Bindings.autoLoad() end
    end
    settings.SelectingDevice=false
    notify("Made by xbolitas • Release 16.0 • "..mode)
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
ls.Text = "Made by xbolitas"
lt.Text = "SIGMASAKEN V2"
task.wait(.65)
local endLoad = tween(loadingScale,.18,{Scale=.80})
if endLoad then endLoad.Completed:Wait() end
loading:Destroy()
showDevicePicker()
print("SigmaSaken V2 Release 16.0 • Made by xbolitas • Custom UI")
