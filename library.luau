--[[
    GameSense UI Library for Roblox
    Client-sided | LocalScript compatible
    Usage: local UI = loadstring(game:HttpGet("..."))()
--]]

local GameSenseUI = {}
GameSenseUI.__index = GameSenseUI

-- ── SERVICES ──────────────────────────────────────────────────────────────────
local Players        = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local RunService     = game:GetService("RunService")
local LocalPlayer    = Players.LocalPlayer
local Mouse          = LocalPlayer:GetMouse()

-- ── THEME ─────────────────────────────────────────────────────────────────────
local Theme = {
    BgPanel       = Color3.fromRGB(20, 20, 24),
    BgSidebar     = Color3.fromRGB(12, 12, 16),
    Surface       = Color3.fromRGB(26, 26, 32),
    SurfaceHover  = Color3.fromRGB(34, 34, 42),
    Border        = Color3.fromRGB(40, 40, 50),
    BorderActive  = Color3.fromRGB(100, 50, 220),
    Text          = Color3.fromRGB(212, 212, 224),
    TextMuted     = Color3.fromRGB(122, 122, 144),
    TextFaint     = Color3.fromRGB(74, 74, 96),
    Accent        = Color3.fromRGB(140, 80, 255),
    AccentDim     = Color3.fromRGB(30, 15, 55),
    CheckOn       = Color3.fromRGB(140, 80, 255),
    White         = Color3.fromRGB(255, 255, 255),
    Black         = Color3.fromRGB(0, 0, 0),
    Red           = Color3.fromRGB(220, 60, 60),
}

-- ── UTILS ─────────────────────────────────────────────────────────────────────
local function tween(obj, props, duration, style, dir)
    local info = TweenInfo.new(
        duration or 0.15,
        style or Enum.EasingStyle.Quad,
        dir   or Enum.EasingDirection.Out
    )
    TweenService:Create(obj, info, props):Play()
end

local function create(class, props, children)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then obj[k] = v end
    end
    for _, child in pairs(children or {}) do
        child.Parent = obj
    end
    if props and props.Parent then obj.Parent = props.Parent end
    return obj
end

local function makeCorner(radius, parent)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 3), Parent = parent })
end

local function makeStroke(color, thickness, parent)
    return create("UIStroke", {
        Color     = color or Theme.Border,
        Thickness = thickness or 1,
        Parent    = parent,
    })
end

local function makePadding(t, r, b, l, parent)
    return create("UIPadding", {
        PaddingTop    = UDim.new(0, t or 0),
        PaddingRight  = UDim.new(0, r or 0),
        PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft   = UDim.new(0, l or 0),
        Parent        = parent,
    })
end

-- ── DRAGGING ──────────────────────────────────────────────────────────────────
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
--  WINDOW
-- ══════════════════════════════════════════════════════════════════════════════
function GameSenseUI.new(config)
    config = config or {}
    local self = setmetatable({}, GameSenseUI)

    self.Title       = config.Title       or "GameSense"
    self.ToggleKey   = config.ToggleKey   or Enum.KeyCode.Insert
    self.Width       = config.Width       or 620
    self.Height      = config.Height      or 460
    self.Tabs        = {}
    self.ActiveTab   = nil
    self.Visible     = true

    -- ── SCREENGU ──────────────────────────────────────────────────────────────
    self.ScreenGui = create("ScreenGui", {
        Name               = "GameSenseUI",
        ResetOnSpawn       = false,
        ZIndexBehavior     = Enum.ZIndexBehavior.Sibling,
        DisplayOrder       = 999,
        IgnoreGuiInset     = true,
        Parent             = (gethui and gethui()) or LocalPlayer:WaitForChild("PlayerGui"),
    })

    -- ── MAIN FRAME ────────────────────────────────────────────────────────────
    self.MainFrame = create("Frame", {
        Name              = "MainFrame",
        Size              = UDim2.new(0, self.Width, 0, self.Height),
        Position          = UDim2.new(0.5, -(self.Width/2), 0.5, -(self.Height/2)),
        BackgroundColor3  = Theme.BgPanel,
        BorderSizePixel   = 0,
        ClipsDescendants  = true,
        Parent            = self.ScreenGui,
    })
    makeCorner(4, self.MainFrame)
    makeStroke(Theme.Border, 1, self.MainFrame)

    -- top accent line
    create("Frame", {
        Name             = "AccentLine",
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        Parent           = self.MainFrame,
    })

    -- ── TITLE BAR (drag handle) ────────────────────────────────────────────
    self.TitleBar = create("Frame", {
        Name             = "TitleBar",
        Size             = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = Theme.BgSidebar,
        BorderSizePixel  = 0,
        Parent           = self.MainFrame,
    })
    create("TextLabel", {
        Text             = self.Title,
        Font             = Enum.Font.GothamBold,
        TextSize         = 11,
        TextColor3       = Theme.TextMuted,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, -60, 1, 0),
        Position         = UDim2.new(0, 10, 0, 0),
        Parent           = self.TitleBar,
    })

    -- Close button
    local closeBtn = create("TextButton", {
        Text             = "×",
        Font             = Enum.Font.GothamBold,
        TextSize         = 16,
        TextColor3       = Theme.TextFaint,
        BackgroundTransparency = 1,
        Size             = UDim2.new(0, 28, 1, 0),
        Position         = UDim2.new(1, -28, 0, 0),
        Parent           = self.TitleBar,
    })
    closeBtn.MouseButton1Click:Connect(function() self:Toggle() end)
    closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = Theme.Red end)
    closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = Theme.TextFaint end)

    makeDraggable(self.MainFrame, self.TitleBar)

    -- ── SIDEBAR ───────────────────────────────────────────────────────────────
    self.Sidebar = create("Frame", {
        Name             = "Sidebar",
        Size             = UDim2.new(0, 44, 1, -28),
        Position         = UDim2.new(0, 0, 0, 28),
        BackgroundColor3 = Theme.BgSidebar,
        BorderSizePixel  = 0,
        Parent           = self.MainFrame,
    })
    create("UIListLayout", {
        SortOrder   = Enum.SortOrder.LayoutOrder,
        Padding     = UDim.new(0, 2),
        Parent      = self.Sidebar,
    })
    makePadding(8, 4, 8, 4, self.Sidebar)
    -- right border
    create("Frame", {
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel  = 0,
        Parent           = self.Sidebar,
    })

    -- ── TAB CONTAINER ─────────────────────────────────────────────────────────
    self.TabContainer = create("Frame", {
        Name             = "TabContainer",
        Size             = UDim2.new(1, -44, 1, -28),
        Position         = UDim2.new(0, 44, 0, 28),
        BackgroundTransparency = 1,
        Parent           = self.MainFrame,
    })

    -- ── TOGGLE KEY ────────────────────────────────────────────────────────────
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == self.ToggleKey then
            self:Toggle()
        end
    end)

    return self
end

-- ── TOGGLE VISIBILITY ─────────────────────────────────────────────────────────
function GameSenseUI:Toggle()
    self.Visible = not self.Visible
    tween(self.MainFrame, {
        Size = self.Visible
            and UDim2.new(0, self.Width, 0, self.Height)
            or  UDim2.new(0, self.Width, 0, 0),
    }, 0.2, Enum.EasingStyle.Quad)
    self.MainFrame.Visible = self.Visible
end

-- ── SET THEME COLOR ──────────────────────────────────────────────────────────
function GameSenseUI:SetAccent(color)
    Theme.Accent = color
    Theme.CheckOn = color
    Theme.BorderActive = color
    -- refresh active sidebar indicator
    if self.ActiveTab and self.ActiveTab._SidebarIndicator then
        self.ActiveTab._SidebarIndicator.BackgroundColor3 = color
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
--  TAB
-- ══════════════════════════════════════════════════════════════════════════════
function GameSenseUI:AddTab(config)
    config = config or {}
    local tab = {}
    tab.Name    = config.Name    or ("Tab " .. (#self.Tabs + 1))
    tab.Icon    = config.Icon    or "☰"
    tab.Columns = {}

    -- ── Sidebar icon button ───────────────────────────────────────────────────
    local iconBtn = create("TextButton", {
        Name             = "Tab_" .. tab.Name,
        Text             = tab.Icon,
        Font             = Enum.Font.GothamBold,
        TextSize         = 14,
        TextColor3       = Theme.TextFaint,
        BackgroundColor3 = Theme.BgSidebar,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 36),
        LayoutOrder      = #self.Tabs + 1,
        Parent           = self.Sidebar,
    })
    makeCorner(3, iconBtn)

    -- active left indicator bar
    local indicator = create("Frame", {
        Size             = UDim2.new(0, 2, 0, 18),
        Position         = UDim2.new(0, 0, 0.5, -9),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        Visible          = false,
        Parent           = iconBtn,
    })
    makeCorner(2, indicator)
    tab._SidebarIndicator = indicator

    -- ── Tab content frame ─────────────────────────────────────────────────────
    local contentFrame = create("ScrollingFrame", {
        Name                  = "Content_" .. tab.Name,
        Size                  = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel       = 0,
        ScrollBarThickness    = 3,
        ScrollBarImageColor3  = Color3.fromRGB(80, 80, 100),
        CanvasSize            = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize   = Enum.AutomaticSize.Y,
        Visible               = false,
        Parent                = self.TabContainer,
    })
    makePadding(8, 8, 8, 8, contentFrame)

    -- columns layout
    local colLayout = create("UIListLayout", {
        FillDirection  = Enum.FillDirection.Horizontal,
        SortOrder      = Enum.SortOrder.LayoutOrder,
        Padding        = UDim.new(0, 8),
        Parent         = contentFrame,
    })

    tab._ContentFrame = contentFrame
    tab._ColLayout    = colLayout

    -- hover states
    iconBtn.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            tween(iconBtn, { BackgroundTransparency = 0.85 }, 0.1)
            iconBtn.TextColor3 = Theme.TextMuted
        end
    end)
    iconBtn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            tween(iconBtn, { BackgroundTransparency = 1 }, 0.1)
            iconBtn.TextColor3 = Theme.TextFaint
        end
    end)

    iconBtn.MouseButton1Click:Connect(function()
        self:_SelectTab(tab)
    end)

    table.insert(self.Tabs, tab)

    if #self.Tabs == 1 then
        self:_SelectTab(tab)
    end

    return tab
end

function GameSenseUI:_SelectTab(tab)
    -- deselect all
    for _, t in ipairs(self.Tabs) do
        t._ContentFrame.Visible = false
        t._SidebarIndicator.Visible = false
        -- find icon btn
        local btn = self.Sidebar:FindFirstChild("Tab_" .. t.Name)
        if btn then
            btn.BackgroundTransparency = 1
            btn.TextColor3 = Theme.TextFaint
        end
    end

    -- select
    tab._ContentFrame.Visible = true
    tab._SidebarIndicator.Visible = true
    local btn = self.Sidebar:FindFirstChild("Tab_" .. tab.Name)
    if btn then
        btn.BackgroundColor3 = Theme.AccentDim
        btn.BackgroundTransparency = 0
        btn.TextColor3 = Theme.Accent
    end
    self.ActiveTab = tab
end

-- ══════════════════════════════════════════════════════════════════════════════
--  COLUMN
-- ══════════════════════════════════════════════════════════════════════════════
function GameSenseUI:AddColumn(tab)
    local col = create("Frame", {
        Name             = "Col_" .. (#tab.Columns + 1),
        Size             = UDim2.new(0.5, -4, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder      = #tab.Columns + 1,
        Parent           = tab._ContentFrame,
    })
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 8),
        Parent    = col,
    })

    local colObj = { _Frame = col, Sections = {} }
    table.insert(tab.Columns, colObj)
    return colObj
end

-- ══════════════════════════════════════════════════════════════════════════════
--  SECTION
-- ══════════════════════════════════════════════════════════════════════════════
function GameSenseUI:AddSection(col, title)
    local section = create("Frame", {
        Name             = "Section_" .. (title or ""),
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel  = 0,
        LayoutOrder      = #col.Sections + 1,
        ClipsDescendants = true,
        Parent           = col._Frame,
    })
    makeCorner(3, section)
    makeStroke(Theme.Border, 1, section)

    -- header
    local header = create("Frame", {
        Size             = UDim2.new(1, 0, 0, 24),
        BackgroundColor3 = Color3.fromRGB(10, 10, 14),
        BackgroundTransparency = 0.3,
        BorderSizePixel  = 0,
        Parent           = section,
    })
    create("TextLabel", {
        Text             = string.upper(title or ""),
        Font             = Enum.Font.GothamBold,
        TextSize         = 9,
        TextColor3       = Theme.TextMuted,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 1, 0),
        Parent           = header,
    })
    makePadding(0, 0, 0, 10, header)

    -- body
    local body = create("Frame", {
        Name             = "Body",
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        Position         = UDim2.new(0, 0, 0, 24),
        BackgroundTransparency = 1,
        Parent           = section,
    })
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 0),
        Parent    = body,
    })
    makePadding(4, 0, 6, 0, body)

    local sectionObj = { _Frame = section, _Body = body, Items = {} }
    table.insert(col.Sections, sectionObj)
    return sectionObj
end

-- ══════════════════════════════════════════════════════════════════════════════
--  TOGGLE (checkbox)
-- ══════════════════════════════════════════════════════════════════════════════
function GameSenseUI:AddToggle(section, config)
    config = config or {}
    local label    = config.Label    or "Toggle"
    local default  = config.Default  or false
    local callback = config.Callback or function() end

    local state = default

    local row = create("TextButton", {
        Name             = "Toggle_" .. label,
        Size             = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Text             = "",
        LayoutOrder      = #section.Items + 1,
        Parent           = section._Body,
    })

    -- checkbox box
    local box = create("Frame", {
        Size             = UDim2.new(0, 11, 0, 11),
        Position         = UDim2.new(0, 10, 0.5, -5),
        BackgroundColor3 = state and Theme.CheckOn or Theme.Surface,
        BorderSizePixel  = 0,
        Parent           = row,
    })
    makeCorner(2, box)
    local boxStroke = makeStroke(state and Theme.CheckOn or Theme.TextFaint, 1, box)

    -- checkmark
    local check = create("TextLabel", {
        Text             = "✓",
        Font             = Enum.Font.GothamBold,
        TextSize         = 8,
        TextColor3       = Theme.White,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 1, 0),
        Visible          = state,
        Parent           = box,
    })

    -- label
    create("TextLabel", {
        Text             = label,
        Font             = Enum.Font.Gotham,
        TextSize         = 11,
        TextColor3       = Theme.Text,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, -30, 1, 0),
        Position         = UDim2.new(0, 28, 0, 0),
        Parent           = row,
    })

    local function setState(val)
        state = val
        check.Visible = state
        tween(box, { BackgroundColor3 = state and Theme.CheckOn or Theme.Surface }, 0.12)
        boxStroke.Color = state and Theme.CheckOn or Theme.TextFaint
        callback(state)
    end

    row.MouseButton1Click:Connect(function() setState(not state) end)
    row.MouseEnter:Connect(function()
        tween(row, { BackgroundColor3 = Theme.SurfaceHover, BackgroundTransparency = 0 }, 0.1)
    end)
    row.MouseLeave:Connect(function()
        tween(row, { BackgroundTransparency = 1 }, 0.1)
    end)

    local obj = {}
    function obj:Set(val) setState(val) end
    function obj:Get() return state end
    table.insert(section.Items, obj)
    return obj
end

-- ══════════════════════════════════════════════════════════════════════════════
--  SLIDER
-- ══════════════════════════════════════════════════════════════════════════════
function GameSenseUI:AddSlider(section, config)
    config = config or {}
    local label    = config.Label    or "Slider"
    local min      = config.Min      or 0
    local max      = config.Max      or 100
    local default  = config.Default  or min
    local suffix   = config.Suffix   or ""
    local callback = config.Callback or function() end

    local value = math.clamp(default, min, max)

    local wrapper = create("Frame", {
        Size             = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        LayoutOrder      = #section.Items + 1,
        Parent           = section._Body,
    })
    makePadding(2, 10, 4, 10, wrapper)

    -- label row
    local labelRow = create("Frame", {
        Size             = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Parent           = wrapper,
    })
    create("TextLabel", {
        Text             = label,
        Font             = Enum.Font.Gotham,
        TextSize         = 11,
        TextColor3       = Theme.Text,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size             = UDim2.new(0.7, 0, 1, 0),
        Parent           = labelRow,
    })
    local valLabel = create("TextLabel", {
        Text             = tostring(value) .. suffix,
        Font             = Enum.Font.GothamBold,
        TextSize         = 10,
        TextColor3       = Theme.TextMuted,
        TextXAlignment   = Enum.TextXAlignment.Right,
        BackgroundTransparency = 1,
        Size             = UDim2.new(0.3, 0, 1, 0),
        Position         = UDim2.new(0.7, 0, 0, 0),
        Parent           = labelRow,
    })

    -- track
    local track = create("Frame", {
        Size             = UDim2.new(1, 0, 0, 3),
        Position         = UDim2.new(0, 0, 0, 22),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel  = 0,
        Parent           = wrapper,
    })
    makeCorner(2, track)

    -- fill
    local fill = create("Frame", {
        Size             = UDim2.new((value - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        Parent           = track,
    })
    makeCorner(2, fill)

    -- thumb
    local thumb = create("Frame", {
        Size             = UDim2.new(0, 11, 0, 11),
        Position         = UDim2.new((value - min) / (max - min), -5, 0.5, -5),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        Parent           = track,
    })
    makeCorner(999, thumb)
    makeStroke(Color3.fromRGB(200, 180, 255), 1, thumb)

    -- drag logic
    local dragging = false

    local function updateValue(inputX)
        local trackPos  = track.AbsolutePosition.X
        local trackSize = track.AbsoluteSize.X
        local pct = math.clamp((inputX - trackPos) / trackSize, 0, 1)
        local raw = min + (max - min) * pct
        -- round to step
        local step = config.Step or 1
        value = math.floor(raw / step + 0.5) * step
        value = math.clamp(value, min, max)

        fill.Size     = UDim2.new(pct, 0, 1, 0)
        thumb.Position = UDim2.new(pct, -5, 0.5, -5)

        local display = (config.Decimals) and string.format("%." .. config.Decimals .. "f", value) or tostring(value)
        valLabel.Text = display .. suffix
        callback(value)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateValue(input.Position.X)
        end
    end)
    track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateValue(input.Position.X)
        end
    end)

    local obj = {}
    function obj:Set(val)
        value = math.clamp(val, min, max)
        local pct = (value - min) / (max - min)
        fill.Size      = UDim2.new(pct, 0, 1, 0)
        thumb.Position = UDim2.new(pct, -5, 0.5, -5)
        valLabel.Text  = tostring(value) .. suffix
        callback(value)
    end
    function obj:Get() return value end
    table.insert(section.Items, obj)
    return obj
end

-- ══════════════════════════════════════════════════════════════════════════════
--  DROPDOWN
-- ══════════════════════════════════════════════════════════════════════════════
function GameSenseUI:AddDropdown(section, config)
    config = config or {}
    local label    = config.Label    or "Dropdown"
    local options  = config.Options  or {}
    local default  = config.Default  or (options[1] or "")
    local callback = config.Callback or function() end

    local selected = default
    local open     = false

    local wrapper = create("Frame", {
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder      = #section.Items + 1,
        Parent           = section._Body,
        ClipsDescendants = false,
        ZIndex           = 10,
    })
    makePadding(2, 10, 6, 10, wrapper)

    if label ~= "" then
        create("TextLabel", {
            Text             = label,
            Font             = Enum.Font.Gotham,
            TextSize         = 9,
            TextColor3       = Theme.TextFaint,
            TextXAlignment   = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Size             = UDim2.new(1, 0, 0, 14),
            Parent           = wrapper,
        })
    end

    local btnOffset = (label ~= "") and 14 or 0

    -- button
    local btn = create("TextButton", {
        Size             = UDim2.new(1, 0, 0, 22),
        Position         = UDim2.new(0, 0, 0, btnOffset),
        BackgroundColor3 = Color3.fromRGB(10, 10, 16),
        BorderSizePixel  = 0,
        Text             = "",
        ZIndex           = 11,
        Parent           = wrapper,
    })
    makeCorner(3, btn)
    makeStroke(Theme.Border, 1, btn)

    local selLabel = create("TextLabel", {
        Text             = selected,
        Font             = Enum.Font.Gotham,
        TextSize         = 11,
        TextColor3       = Theme.Text,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, -20, 1, 0),
        Position         = UDim2.new(0, 8, 0, 0),
        ZIndex           = 12,
        Parent           = btn,
    })
    create("TextLabel", {
        Text             = "▾",
        Font             = Enum.Font.GothamBold,
        TextSize         = 10,
        TextColor3       = Theme.TextMuted,
        BackgroundTransparency = 1,
        Size             = UDim2.new(0, 16, 1, 0),
        Position         = UDim2.new(1, -18, 0, 0),
        ZIndex           = 12,
        Parent           = btn,
    })

    -- dropdown list
    local dropList = create("Frame", {
        Name             = "DropList",
        Size             = UDim2.new(1, 0, 0, 0),
        Position         = UDim2.new(0, 0, 0, btnOffset + 24),
        BackgroundColor3 = Color3.fromRGB(14, 14, 20),
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        Visible          = false,
        ZIndex           = 20,
        Parent           = wrapper,
    })
    makeCorner(3, dropList)
    makeStroke(Theme.Border, 1, dropList)

    local listLayout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 0),
        Parent    = dropList,
    })

    for i, opt in ipairs(options) do
        local optBtn = create("TextButton", {
            Size             = UDim2.new(1, 0, 0, 22),
            BackgroundColor3 = Theme.Surface,
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
            Text             = opt,
            Font             = Enum.Font.Gotham,
            TextSize         = 11,
            TextColor3       = (opt == selected) and Theme.Accent or Theme.TextMuted,
            TextXAlignment   = Enum.TextXAlignment.Left,
            LayoutOrder      = i,
            ZIndex           = 21,
            Parent           = dropList,
        })
        makePadding(0, 0, 0, 8, optBtn)

        optBtn.MouseEnter:Connect(function()
            tween(optBtn, { BackgroundTransparency = 0, BackgroundColor3 = Theme.SurfaceHover }, 0.1)
            optBtn.TextColor3 = Theme.Text
        end)
        optBtn.MouseLeave:Connect(function()
            tween(optBtn, { BackgroundTransparency = 1 }, 0.1)
            optBtn.TextColor3 = (opt == selected) and Theme.Accent or Theme.TextMuted
        end)
        optBtn.MouseButton1Click:Connect(function()
            selected = opt
            selLabel.Text = opt
            -- reset colors
            for _, c in ipairs(dropList:GetChildren()) do
                if c:IsA("TextButton") then
                    c.TextColor3 = (c.Text == selected) and Theme.Accent or Theme.TextMuted
                end
            end
            open = false
            tween(dropList, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
            task.delay(0.15, function() dropList.Visible = false end)
            callback(selected)
        end)
    end

    btn.MouseButton1Click:Connect(function()
        open = not open
        if open then
            dropList.Visible = true
            dropList.Size    = UDim2.new(1, 0, 0, 0)
            tween(dropList, { Size = UDim2.new(1, 0, 0, #options * 22) }, 0.15)
        else
            tween(dropList, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
            task.delay(0.15, function() dropList.Visible = false end)
        end
    end)

    local obj = {}
    function obj:Set(val)
        selected = val
        selLabel.Text = val
        callback(val)
    end
    function obj:Get() return selected end
    table.insert(section.Items, obj)
    return obj
end

-- ══════════════════════════════════════════════════════════════════════════════
--  BUTTON
-- ══════════════════════════════════════════════════════════════════════════════
function GameSenseUI:AddButton(section, config)
    config = config or {}
    local label    = config.Label    or "Button"
    local style    = config.Style    or "default" -- "default" | "primary" | "danger"
    local callback = config.Callback or function() end

    local bgColor = ({
        default = Color3.fromRGB(30, 30, 38),
        primary = Theme.AccentDim,
        danger  = Color3.fromRGB(50, 15, 15),
    })[style] or Color3.fromRGB(30, 30, 38)

    local txtColor = ({
        default = Theme.Text,
        primary = Color3.fromRGB(200, 170, 255),
        danger  = Color3.fromRGB(255, 110, 110),
    })[style] or Theme.Text

    local wrapper = create("Frame", {
        Size             = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        LayoutOrder      = #section.Items + 1,
        Parent           = section._Body,
    })
    makePadding(0, 10, 0, 10, wrapper)

    local btn = create("TextButton", {
        Size             = UDim2.new(1, 0, 0, 24),
        Position         = UDim2.new(0, 0, 0.5, -12),
        BackgroundColor3 = bgColor,
        BorderSizePixel  = 0,
        Text             = label,
        Font             = Enum.Font.Gotham,
        TextSize         = 11,
        TextColor3       = txtColor,
        Parent           = wrapper,
    })
    makeCorner(3, btn)
    makeStroke(({
        default = Theme.Border,
        primary = Theme.BorderActive,
        danger  = Color3.fromRGB(180, 50, 50),
    })[style] or Theme.Border, 1, btn)

    btn.MouseEnter:Connect(function()
        tween(btn, { BackgroundColor3 = Color3.fromRGB(
            math.min(bgColor.R * 255 + 10, 255) / 255,
            math.min(bgColor.G * 255 + 10, 255) / 255,
            math.min(bgColor.B * 255 + 10, 255) / 255
        )}, 0.1)
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, { BackgroundColor3 = bgColor }, 0.1)
    end)
    btn.MouseButton1Click:Connect(function()
        tween(btn, { BackgroundColor3 = Color3.fromRGB(10, 10, 14) }, 0.07)
        task.delay(0.07, function()
            tween(btn, { BackgroundColor3 = bgColor }, 0.1)
        end)
        callback()
    end)

    local obj = {}
    function obj:SetLabel(text) btn.Text = text end
    table.insert(section.Items, obj)
    return obj
end

-- ══════════════════════════════════════════════════════════════════════════════
--  TEXTBOX (input)
-- ══════════════════════════════════════════════════════════════════════════════
function GameSenseUI:AddTextbox(section, config)
    config = config or {}
    local label       = config.Label       or "Input"
    local placeholder = config.Placeholder or ""
    local default     = config.Default     or ""
    local callback    = config.Callback    or function() end

    local wrapper = create("Frame", {
        Size             = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        LayoutOrder      = #section.Items + 1,
        Parent           = section._Body,
    })
    makePadding(2, 10, 4, 10, wrapper)

    create("TextLabel", {
        Text             = label,
        Font             = Enum.Font.Gotham,
        TextSize         = 9,
        TextColor3       = Theme.TextFaint,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 14),
        Parent           = wrapper,
    })

    local box = create("TextBox", {
        Size             = UDim2.new(1, 0, 0, 22),
        Position         = UDim2.new(0, 0, 0, 16),
        BackgroundColor3 = Color3.fromRGB(10, 10, 16),
        BorderSizePixel  = 0,
        Text             = default,
        Font             = Enum.Font.Gotham,
        TextSize         = 11,
        TextColor3       = Theme.Text,
        PlaceholderText  = placeholder,
        PlaceholderColor3 = Theme.TextFaint,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent           = wrapper,
    })
    makeCorner(3, box)
    local stroke = makeStroke(Theme.Border, 1, box)
    makePadding(0, 0, 0, 8, box)

    box.Focused:Connect(function()
        tween(stroke, { Color = Theme.Accent }, 0.15)
    end)
    box.FocusLost:Connect(function(enter)
        tween(stroke, { Color = Theme.Border }, 0.15)
        callback(box.Text, enter)
    end)

    local obj = {}
    function obj:Get() return box.Text end
    function obj:Set(val) box.Text = val end
    table.insert(section.Items, obj)
    return obj
end

-- ══════════════════════════════════════════════════════════════════════════════
--  LABEL
-- ══════════════════════════════════════════════════════════════════════════════
function GameSenseUI:AddLabel(section, config)
    config = config or {}
    local text = config.Text or ""

    local lbl = create("TextLabel", {
        Text             = text,
        Font             = Enum.Font.Gotham,
        TextSize         = 11,
        TextColor3       = Theme.TextMuted,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 22),
        LayoutOrder      = #section.Items + 1,
        Parent           = section._Body,
    })
    makePadding(0, 10, 0, 10, lbl)

    local obj = {}
    function obj:Set(val) lbl.Text = val end
    function obj:SetColor(col) lbl.TextColor3 = col end
    table.insert(section.Items, obj)
    return obj
end

-- ══════════════════════════════════════════════════════════════════════════════
--  SEPARATOR
-- ══════════════════════════════════════════════════════════════════════════════
function GameSenseUI:AddSeparator(section)
    create("Frame", {
        Size             = UDim2.new(1, -20, 0, 1),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel  = 0,
        LayoutOrder      = #section.Items + 1,
        Parent           = section._Body,
    })
    makePadding(0, 10, 0, 10, section._Body)
end

-- ══════════════════════════════════════════════════════════════════════════════
--  NOTIFICATION (toast)
-- ══════════════════════════════════════════════════════════════════════════════
function GameSenseUI:Notify(config)
    config = config or {}
    local title    = config.Title    or "GameSense"
    local message  = config.Message  or ""
    local duration = config.Duration or 3

    -- container
    local gui = self.ScreenGui
    local notif = create("Frame", {
        Size             = UDim2.new(0, 220, 0, 52),
        Position         = UDim2.new(1, -230, 1, 10),
        BackgroundColor3 = Theme.BgPanel,
        BorderSizePixel  = 0,
        Parent           = gui,
    })
    makeCorner(4, notif)
    makeStroke(Theme.BorderActive, 1, notif)

    -- accent left bar
    create("Frame", {
        Size             = UDim2.new(0, 2, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        Parent           = notif,
    })
    makeCorner(2, notif:FindFirstChild("Frame"))

    create("TextLabel", {
        Text             = title,
        Font             = Enum.Font.GothamBold,
        TextSize         = 11,
        TextColor3       = Theme.Accent,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, -14, 0, 18),
        Position         = UDim2.new(0, 12, 0, 8),
        Parent           = notif,
    })
    create("TextLabel", {
        Text             = message,
        Font             = Enum.Font.Gotham,
        TextSize         = 10,
        TextColor3       = Theme.TextMuted,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, -14, 0, 18),
        Position         = UDim2.new(0, 12, 0, 28),
        Parent           = notif,
    })

    -- slide in
    tween(notif, { Position = UDim2.new(1, -230, 1, -(52 + 10)) }, 0.3, Enum.EasingStyle.Quad)

    task.delay(duration, function()
        tween(notif, { Position = UDim2.new(1, -230, 1, 10) }, 0.25, Enum.EasingStyle.Quad)
        task.delay(0.3, function() notif:Destroy() end)
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
--  RETURN
-- ══════════════════════════════════════════════════════════════════════════════
return GameSenseUI

--[[
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  EXAMPLE USAGE (paste in a LocalScript):

  local UI = loadstring(game:HttpGet("URL_AQUI"))()

  local Window = UI.new({
      Title     = "GameSense",
      ToggleKey = Enum.KeyCode.Insert,
      Width     = 620,
      Height    = 460,
  })

  local miscTab = Window:AddTab({ Name = "Misc", Icon = "⚙" })
  local aimTab  = Window:AddTab({ Name = "Aim",  Icon = "◎" })

  local col1 = Window:AddColumn(miscTab)
  local col2 = Window:AddColumn(miscTab)

  local movSection = Window:AddSection(col1, "Movement")

  local bhopToggle = Window:AddToggle(movSection, {
      Label    = "Bunny hop",
      Default  = true,
      Callback = function(val)
          print("Bunny hop:", val)
      end,
  })

  Window:AddSlider(movSection, {
      Label    = "Air strafe smoothing",
      Min      = 0,
      Max      = 100,
      Default  = 50,
      Suffix   = "%",
      Callback = function(val)
          print("Smoothing:", val)
      end,
  })

  Window:AddSeparator(movSection)

  Window:AddDropdown(movSection, {
      Label    = "Air strafe direction",
      Options  = { "View angles", "At target", "Opposite", "Random" },
      Default  = "View angles",
      Callback = function(val)
          print("Direction:", val)
      end,
  })

  local cfgSection = Window:AddSection(col2, "Config")

  Window:AddTextbox(cfgSection, {
      Label       = "New configuration name",
      Placeholder = "my_config",
      Callback    = function(text, enter)
          if enter then print("Config name:", text) end
      end,
  })

  Window:AddButton(cfgSection, {
      Label    = "Save config",
      Style    = "primary",
      Callback = function()
          Window:Notify({
              Title   = "GameSense",
              Message = "Configuration saved!",
              Duration = 3,
          })
      end,
  })

  Window:AddButton(cfgSection, {
      Label    = "Unload",
      Style    = "danger",
      Callback = function()
          Window.ScreenGui:Destroy()
      end,
  })

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
]]
