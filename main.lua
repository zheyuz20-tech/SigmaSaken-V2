
--[[
    SIGMASAKEN V2 | ALPHA 0.4
    Animated Mobile UI
    Loading / Tabs / Resize / Minimize
    Player and Visuals: UI placeholders
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("SigmaSakenV2")
if old then old:Destroy() end

local colors = {
    bg = Color3.fromRGB(9, 9, 14),
    sidebar = Color3.fromRGB(15, 14, 22),
    card = Color3.fromRGB(23, 22, 33),
    button = Color3.fromRGB(37, 35, 51),
    accent = Color3.fromRGB(166, 91, 255),
    accentDark = Color3.fromRGB(76, 39, 117),
    text = Color3.fromRGB(245, 242, 255),
    muted = Color3.fromRGB(153, 148, 170)
}

local animations = true
local options = {}

local function make(class, parent, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local function round(obj, r)
    make("UICorner", obj, {
        CornerRadius = UDim.new(0, r)
    })
end

local function tween(obj, time, props)
    if not animations then
        for k, v in pairs(props) do
            obj[k] = v
        end
        return nil
    end

    local t = TweenService:Create(
        obj,
        TweenInfo.new(time, Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out),
        props
    )
    t:Play()
    return t
end

local function text(parent, value, size, bold)
    return make("TextLabel", parent, {
        BackgroundTransparency = 1,
        Text = value,
        TextSize = size,
        Font = bold and Enum.Font.GothamBold
            or Enum.Font.Gotham,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true
    })
end

local gui = make("ScreenGui", playerGui, {
    Name = "SigmaSakenV2",
    IgnoreGuiInset = true,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

local connections = {}
local function listen(signal, fn)
    local connection = signal:Connect(fn)
    table.insert(connections, connection)
    return connection
end

listen(gui.Destroying, function()
    for _, c in ipairs(connections) do
        if c.Connected then
            c:Disconnect()
        end
    end
end)

-- LOADING SCREEN

local loading = make("Frame", gui, {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(310, 175),
    BackgroundColor3 = colors.bg
})
round(loading, 16)

local loadingScale = make("UIScale", loading, {
    Scale = 0.85
})

local loadingTitle = text(
    loading, "SIGMASAKEN V2", 24, true
)
loadingTitle.Position = UDim2.fromOffset(22, 22)
loadingTitle.Size = UDim2.new(1, -44, 0, 42)
loadingTitle.TextColor3 = colors.accent

local status = text(
    loading, "INITIALIZING... 0%", 13, true
)
status.Position = UDim2.fromOffset(22, 79)
status.Size = UDim2.new(1, -44, 0, 24)
status.TextColor3 = colors.muted

local track = make("Frame", loading, {
    Position = UDim2.fromOffset(22, 120),
    Size = UDim2.new(1, -44, 0, 10),
    BackgroundColor3 = colors.button,
    ClipsDescendants = true
})
round(track, 6)

local fill = make("Frame", track, {
    Size = UDim2.fromScale(0, 1),
    BackgroundColor3 = colors.accent
})
round(fill, 6)

-- FLOATING LAUNCHER

local floating = make("TextButton", gui, {
    Position = UDim2.new(0, 15, 0.5, -27),
    Size = UDim2.fromOffset(54, 54),
    BackgroundColor3 = colors.bg,
    Text = "Σ",
    TextColor3 = colors.accent,
    TextSize = 31,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    Visible = false
})
round(floating, 15)

local floatingScale = make("UIScale", floating, {
    Scale = 1
})

-- MAIN WINDOW

local camera = workspace.CurrentCamera
local viewport = camera and camera.ViewportSize
    or Vector2.new(1024, 768)

local width = math.floor(math.min(610, viewport.X * 0.90))
local height = math.floor(math.min(405, viewport.Y * 0.78))

local main = make("Frame", gui, {
    Position = UDim2.fromOffset(
        (viewport.X - width) / 2,
        (viewport.Y - height) / 2
    ),
    Size = UDim2.fromOffset(width, height),
    BackgroundColor3 = colors.bg,
    ClipsDescendants = true,
    Visible = false
})
round(main, 15)

local mainScale = make("UIScale", main, {
    Scale = 1
})

local sidebarWidth = 145

local sidebar = make("Frame", main, {
    Size = UDim2.new(0, sidebarWidth, 1, 0),
    BackgroundColor3 = colors.sidebar
})

local logo = text(sidebar, "Σ SIGMA", 22, true)
logo.Position = UDim2.fromOffset(15, 18)
logo.Size = UDim2.new(1, -20, 0, 33)
logo.TextColor3 = colors.accent

local subtitle = text(
    sidebar, "SAKEN V2 / ALPHA", 10, true
)
subtitle.Position = UDim2.fromOffset(16, 52)
subtitle.Size = UDim2.new(1, -20, 0, 20)
subtitle.TextColor3 = colors.muted

local nav = make("Frame", sidebar, {
    Position = UDim2.fromOffset(9, 92),
    Size = UDim2.new(1, -18, 1, -140),
    BackgroundTransparency = 1
})

make("UIListLayout", nav, {
    Padding = UDim.new(0, 9),
    SortOrder = Enum.SortOrder.LayoutOrder
})

local build = text(sidebar, "BUILD 0.4 • MOBILE", 10)
build.Position = UDim2.new(0, 13, 1, -30)
build.Size = UDim2.new(1, -20, 0, 19)
build.TextColor3 = colors.muted

local content = make("Frame", main, {
    Position = UDim2.fromOffset(sidebarWidth, 0),
    Size = UDim2.new(1, -sidebarWidth, 1, 0),
    BackgroundTransparency = 1
})

local header = make("Frame", content, {
    Size = UDim2.new(1, 0, 0, 62),
    BackgroundTransparency = 1
})

local dragBar = make("Frame", header, {
    Size = UDim2.new(1, -100, 1, 0),
    BackgroundTransparency = 1,
    Active = true
})

local heading = text(dragBar, "Dashboard", 21, true)
heading.Position = UDim2.fromOffset(17, 12)
heading.Size = UDim2.new(1, -20, 0, 36)

local function headerButton(symbol, x)
    local b = make("TextButton", header, {
        Position = UDim2.new(1, x, 0, 16),
        Size = UDim2.fromOffset(31, 31),
        BackgroundColor3 = colors.button,
        Text = symbol,
        TextColor3 = colors.text,
        TextSize = 22,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false
    })
    round(b, 8)
    return b
end

local minimize = headerButton("−", -80)
local close = headerButton("×", -43)

local holder = make("Frame", content, {
    Position = UDim2.fromOffset(16, 65),
    Size = UDim2.new(1, -32, 1, -85),
    BackgroundTransparency = 1,
    ClipsDescendants = true
})

-- PAGES

local pages = {}
local buttons = {}
local currentPage

local function createPage(name)
    local page = make("ScrollingFrame", holder, {
        Name = name,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = colors.accent,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false
    })

    make("UIListLayout", page, {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    make("UIPadding", page, {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 12),
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
    local base = make("Frame", page, {
        Size = UDim2.new(1, -5, 0, 82),
        BackgroundColor3 = colors.card
    })
    round(base, 10)

    local h = text(base, title, 15, true)
    h.Position = UDim2.fromOffset(13, 10)
    h.Size = UDim2.new(1, -26, 0, 25)

    local d = text(base, description, 12)
    d.Position = UDim2.fromOffset(13, 36)
    d.Size = UDim2.new(1, -26, 0, 36)
    d.TextColor3 = colors.muted
end

local function toggle(page, title, description, key, callback)
    options[key] = false

    local base = make("Frame", page, {
        Size = UDim2.new(1, -5, 0, 69),
        BackgroundColor3 = colors.card
    })
    round(base, 10)

    local h = text(base, title, 14, true)
    h.Position = UDim2.fromOffset(12, 8)
    h.Size = UDim2.new(1, -82, 0, 25)

    local d = text(base, description, 11)
    d.Position = UDim2.fromOffset(12, 33)
    d.Size = UDim2.new(1, -82, 0, 28)
    d.TextColor3 = colors.muted

    local switch = make("TextButton", base, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -13, 0.5, 0),
        Size = UDim2.fromOffset(48, 27),
        BackgroundColor3 = colors.button,
        Text = "",
        AutoButtonColor = false
    })
    round(switch, 14)

    local knob = make("Frame", switch, {
        Position = UDim2.fromOffset(4, 4),
        Size = UDim2.fromOffset(19, 19),
        BackgroundColor3 = colors.text
    })
    round(knob, 10)

    listen(switch.MouseButton1Click, function()
        options[key] = not options[key]
        local enabled = options[key]

        tween(switch, 0.23, {
            BackgroundColor3 = enabled
                and colors.accent or colors.button
        })
        tween(knob, 0.23, {
            Position = enabled
                and UDim2.fromOffset(25, 4)
                or UDim2.fromOffset(4, 4)
        })

        if callback then callback(enabled) end
    end)
end

local function slider(page, title, low, high, initial, callback)
    local base = make("Frame", page, {
        Size = UDim2.new(1, -5, 0, 90),
        BackgroundColor3 = colors.card
    })
    round(base, 10)

    local h = text(base, title, 14, true)
    h.Position = UDim2.fromOffset(13, 8)
    h.Size = UDim2.new(1, -105, 0, 25)

    local valueText = text(base, tostring(initial), 13, true)
    valueText.Position = UDim2.new(1, -90, 0, 8)
    valueText.Size = UDim2.fromOffset(75, 25)
    valueText.TextColor3 = colors.accent
    valueText.TextXAlignment = Enum.TextXAlignment.Right

    local track = make("Frame", base, {
        Position = UDim2.fromOffset(14, 55),
        Size = UDim2.new(1, -28, 0, 8),
        BackgroundColor3 = colors.button,
        Active = true
    })
    round(track, 4)

    local fill = make("Frame", track, {
        Size = UDim2.fromScale((initial - low) / (high - low), 1),
        BackgroundColor3 = colors.accent
    })
    round(fill, 4)

    local activeInput

    local function update(x)
        local percentage = math.clamp(
            (x - track.AbsolutePosition.X)
                / math.max(1, track.AbsoluteSize.X),
            0, 1
        )
        local value = math.floor(
            low + percentage * (high - low) + 0.5
        )
        valueText.Text = tostring(value)
        tween(fill, 0.08, {
            Size = UDim2.fromScale(
                (value - low) / (high - low), 1
            )
        })
        if callback then callback(value) end
    end

    listen(track.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType ==
                Enum.UserInputType.MouseButton1 then
            activeInput = input
            update(input.Position.X)
        end
    end)

    listen(UIS.InputChanged, function(input)
        if not activeInput then return end
        if input == activeInput or
            (activeInput.UserInputType ==
                Enum.UserInputType.MouseButton1
            and input.UserInputType ==
                Enum.UserInputType.MouseMovement) then
            update(input.Position.X)
        end
    end)

    listen(UIS.InputEnded, function(input)
        if input == activeInput then
            activeInput = nil
        end
    end)
end

-- PAGE CONTENTS

card(home, "WELCOME TO SIGMASAKEN V2",
    "Advanced animated mobile interface.")

card(home, "SYSTEM STATUS",
    "Interface loaded. Build Alpha 0.4.")

card(home, "MODULES",
    "Player / Visuals / Config")

card(playerPage, "PLAYER MODULE",
    "Settings preview. Gameplay functions are not connected.")

toggle(playerPage, "Sprint",
    "Sprint toggle preview", "Sprint")

toggle(playerPage, "Infinite Stamina",
    "Stamina toggle preview", "Stamina")

toggle(playerPage, "Speed Boost",
    "Movement toggle preview", "Speed")

slider(playerPage, "Speed value", 16, 50, 24)

card(visuals, "VISUALS MODULE",
    "Visual controls are not connected to the game.")

toggle(visuals, "Player ESP",
    "Highlight preview", "ESP")

toggle(visuals, "Name ESP",
    "Player name preview", "NameESP")

toggle(visuals, "Distance ESP",
    "Distance preview", "DistanceESP")

card(config, "APPEARANCE",
    "Dark UI with purple accent.")

toggle(config, "UI Animations",
    "Enable or disable transitions", "Animations",
    function(enabled)
        animations = enabled
    end
)

options.Animations = true

slider(config, "Window opacity", 40, 100, 100,
    function(value)
        main.BackgroundTransparency = 1 - value / 100
    end
)

card(config, "WINDOW CONTROLS",
    "Drag the header to move. Drag the bottom corner to resize.")

-- NAVIGATION

local titles = {
    Home = "Dashboard",
    Player = "Player",
    Visuals = "Visuals",
    Config = "Settings"
}

local function changePage(name)
    if currentPage == name then return end
    currentPage = name
    heading.Text = titles[name]

    for key, page in pairs(pages) do
        page.Visible = key == name
    end

    for key, button in pairs(buttons) do
        tween(button, 0.22, {
            BackgroundColor3 = key == name
                and colors.accentDark
                or colors.sidebar,
            TextColor3 = key == name
                and colors.text
                or colors.muted
        })
    end

    local page = pages[name]
    page.Position = UDim2.fromOffset(16, 0)
    tween(page, 0.28, {
        Position = UDim2.fromOffset(0, 0)
    })
end

local sections = {
    {"⌂  Home", "Home"},
    {"◉  Player", "Player"},
    {"◇  Visuals", "Visuals"},
    {"⚙  Config", "Config"}
}

for index, entry in ipairs(sections) do
    local button = make("TextButton", nav, {
        LayoutOrder = index,
        Size = UDim2.new(1, 0, 0, 43),
        Text = entry[1],
        BackgroundColor3 = colors.sidebar,
        TextColor3 = colors.muted,
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false
    })
    round(button, 9)
    make("UIPadding", button, {
        PaddingLeft = UDim.new(0, 10)
    })

    buttons[entry[2]] = button

    listen(button.MouseButton1Click, function()
        changePage(entry[2])
    end)
end

changePage("Home")

-- DRAG WINDOW

local dragging = nil

listen(dragBar.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType ==
            Enum.UserInputType.MouseButton1 then
        dragging = {
            input = input,
            start = input.Position,
            original = main.Position
        }
    end
end)

listen(UIS.InputChanged, function(input)
    if not dragging then return end

    if input == dragging.input or
        (dragging.input.UserInputType ==
            Enum.UserInputType.MouseButton1
        and input.UserInputType ==
            Enum.UserInputType.MouseMovement) then

        local delta = input.Position - dragging.start
        local screen = workspace.CurrentCamera.ViewportSize

        local x = math.clamp(
            dragging.original.X.Offset + delta.X,
            0, math.max(0, screen.X - main.AbsoluteSize.X)
        )
        local y = math.clamp(
            dragging.original.Y.Offset + delta.Y,
            0, math.max(0, screen.Y - main.AbsoluteSize.Y)
        )

        main.Position = UDim2.fromOffset(x, y)
    end
end)

listen(UIS.InputEnded, function(input)
    if dragging and input == dragging.input then
        dragging = nil
    end
end)

-- RESIZE

local resize = make("TextButton", main, {
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -3, 1, -3),
    Size = UDim2.fromOffset(33, 33),
    BackgroundTransparency = 1,
    Text = "◢",
    TextColor3 = colors.accent,
    TextSize = 23,
    Font = Enum.Font.GothamBold,
    ZIndex = 4
})

local resizing = nil

listen(resize.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType ==
            Enum.UserInputType.MouseButton1 then
        resizing = {
            input = input,
            start = input.Position,
            size = main.Size
        }
    end
end)

listen(UIS.InputChanged, function(input)
    if not resizing then return end

    if input == resizing.input or
        (resizing.input.UserInputType ==
            Enum.UserInputType.MouseButton1
        and input.UserInputType ==
            Enum.UserInputType.MouseMovement) then

        local delta = input.Position - resizing.start
        local screen = workspace.CurrentCamera.ViewportSize

        local maxW = math.max(300,
            screen.X - main.Position.X.Offset - 5)
        local maxH = math.max(230,
            screen.Y - main.Position.Y.Offset - 5)

        local minW = math.min(380, maxW)
        local minH = math.min(260, maxH)

        main.Size = UDim2.fromOffset(
            math.clamp(
                resizing.size.X.Offset + delta.X,
                minW, maxW
            ),
            math.clamp(
                resizing.size.Y.Offset + delta.Y,
                minH, maxH
            )
        )
    end
end)

listen(UIS.InputEnded, function(input)
    if resizing and input == resizing.input then
        resizing = nil
    end
end)

-- OPEN AND CLOSE ANIMATIONS

local isOpen = false
local transitionId = 0

local function openMenu()
    if isOpen then return end
    isOpen = true
    transitionId = transitionId + 1

    main.Visible = true
    mainScale.Scale = 0.85

    tween(mainScale, 0.35, {Scale = 1})
    tween(floatingScale, 0.2, {Scale = 0.92})
end

local function hideMenu()
    if not isOpen then return end
    isOpen = false
    transitionId = transitionId + 1

    local token = transitionId
    local animation = tween(
        mainScale, 0.23, {Scale = 0.82}
    )

    if animation then
        listen(animation.Completed, function()
            if token == transitionId and not isOpen then
                main.Visible = false
            end
        end)
    else
        main.Visible = false
    end

    tween(floatingScale, 0.2, {Scale = 1})
end

listen(floating.MouseButton1Click, function()
    if isOpen then
        hideMenu()
    else
        openMenu()
    end
end)

listen(minimize.MouseButton1Click, hideMenu)
listen(close.MouseButton1Click, hideMenu)

-- TWO SECOND LOADING

tween(loadingScale, 0.35, {Scale = 1})

local started = os.clock()
local progressTween = TweenService:Create(
    fill,
    TweenInfo.new(2, Enum.EasingStyle.Linear),
    {Size = UDim2.fromScale(1, 1)}
)

progressTween:Play()

while os.clock() - started < 2 do
    local percent = math.clamp(
        math.floor((os.clock() - started) / 2 * 100),
        0, 100
    )
    status.Text = "INITIALIZING... " .. percent .. "%"
    task.wait(0.03)
end

progressTween:Cancel()
fill.Size = UDim2.fromScale(1, 1)
status.Text = "INITIALIZING... 100%"

task.wait(0.1)
loading:Destroy()

floating.Visible = true
openMenu()

print("SigmaSaken V2 Alpha 0.4 loaded")
