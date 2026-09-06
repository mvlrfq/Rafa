local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ================= STATE & VARIABLES =================
local checkpoints = {}
local customWaypoints = {}
local autoCPActive = false
local autoCustomActive = false
local loopDelay = 2

local folderName = "raff-wp"
local fileName = folderName .. "/Waypoints_" .. tostring(game.PlaceId) .. ".json"

local function ensureFolderExists()
    if makefolder and isfolder then
        if not isfolder(folderName) then
            makefolder(folderName)
        end
    end
end

local function teleportTo(cframe)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cframe + Vector3.new(0, 3, 0)
    end
end

-- Cleanup UI Lama jika ada
local parentGui = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
if parentGui:FindFirstChild("GunungTeleportCustomUI") then
    parentGui.GunungTeleportCustomUI:Destroy()
end

-- ================= MAIN SCREEN GUI =================
local MainGui = Instance.new("ScreenGui")
MainGui.Name = "GunungTeleportCustomUI"
MainGui.ResetOnSpawn = false
MainGui.Parent = parentGui

-- System Notifikasi Custom
local NotificationHolder = Instance.new("Frame")
NotificationHolder.Name = "NotificationHolder"
NotificationHolder.Size = UDim2.new(0, 220, 1, -20)
NotificationHolder.Position = UDim2.new(1, -230, 0, 10)
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.Parent = MainGui

local NotifListLayout = Instance.new("UIListLayout")
NotifListLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifListLayout.Padding = UDim.new(0, 8)
NotifListLayout.Parent = NotificationHolder

local currentNotifFrame = nil

local function showNotification(title, text, duration)
    duration = duration or 3

    if currentNotifFrame and currentNotifFrame.Parent then
        currentNotifFrame:Destroy()
        currentNotifFrame = nil
    end

    local NotifFrame = Instance.new("Frame")
    NotifFrame.Size = UDim2.new(1, 0, 0, 60)
    NotifFrame.Position = UDim2.new(1.2, 0, 0, 0)
    NotifFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    NotifFrame.BorderSizePixel = 0
    NotifFrame.Parent = NotificationHolder
    
    currentNotifFrame = NotifFrame

    local NotifCorner = Instance.new("UICorner")
    NotifCorner.CornerRadius = UDim.new(0, 6)
    NotifCorner.Parent = NotifFrame

    local AccentBar = Instance.new("Frame")
    AccentBar.Size = UDim2.new(0, 4, 1, 0)
    AccentBar.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    AccentBar.BorderSizePixel = 0
    AccentBar.Parent = NotifFrame

    local AccentCorner = Instance.new("UICorner")
    AccentCorner.CornerRadius = UDim.new(0, 2)
    AccentCorner.Parent = AccentBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -15, 0, 20)
    TitleLabel.Position = UDim2.new(0, 10, 0, 6)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 12
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = NotifFrame

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(1, -15, 0, 30)
    TextLabel.Position = UDim2.new(0, 10, 0, 24)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = text
    TextLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    TextLabel.TextSize = 11
    TextLabel.Font = Enum.Font.SourceSans
    TextLabel.TextWrapped = true
    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel.Parent = NotifFrame

    NotifFrame:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.3, true)

    task.delay(duration, function()
        if NotifFrame and NotifFrame.Parent then
            local tweenOut = TweenService:Create(NotifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(1.2, 0, 0, 0)
            })
            tweenOut:Play()
            tweenOut.Completed:Connect(function()
                if NotifFrame and NotifFrame.Parent then
                    NotifFrame:Destroy()
                    if currentNotifFrame == NotifFrame then
                        currentNotifFrame = nil
                    end
                end
            end)
        end
    end)
end

-- ================= POPUP DIALOG KONFIRMASI =================
local function showConfirmation(title, message, onConfirm)
    local Overlay = Instance.new("TextButton")
    Overlay.Name = "ConfirmOverlay"
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Overlay.BackgroundTransparency = 0.5
    Overlay.Text = ""
    Overlay.AutoButtonColor = false
    Overlay.Parent = MainGui

    local DialogBox = Instance.new("Frame")
    DialogBox.Size = UDim2.new(0, 280, 0, 140)
    DialogBox.Position = UDim2.new(0.5, -140, 0.5, -70)
    DialogBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    DialogBox.BorderSizePixel = 0
    DialogBox.Parent = Overlay

    local DialogCorner = Instance.new("UICorner")
    DialogCorner.CornerRadius = UDim.new(0, 8)
    DialogCorner.Parent = DialogBox

    local DialogTitle = Instance.new("TextLabel")
    DialogTitle.Size = UDim2.new(1, -20, 0, 30)
    DialogTitle.Position = UDim2.new(0, 10, 0, 8)
    DialogTitle.BackgroundTransparency = 1
    DialogTitle.Text = title
    DialogTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    DialogTitle.Font = Enum.Font.SourceSansBold
    DialogTitle.TextSize = 14
    DialogTitle.TextXAlignment = Enum.TextXAlignment.Center
    DialogTitle.Parent = DialogBox

    local DialogMsg = Instance.new("TextLabel")
    DialogMsg.Size = UDim2.new(1, -20, 0, 40)
    DialogMsg.Position = UDim2.new(0, 10, 0, 40)
    DialogMsg.BackgroundTransparency = 1
    DialogMsg.Text = message
    DialogMsg.TextColor3 = Color3.fromRGB(200, 200, 200)
    DialogMsg.Font = Enum.Font.SourceSans
    DialogMsg.TextSize = 12
    DialogMsg.TextWrapped = true
    DialogMsg.TextXAlignment = Enum.TextXAlignment.Center
    DialogMsg.Parent = DialogBox

    local YesBtn = Instance.new("TextButton")
    YesBtn.Size = UDim2.new(0, 110, 0, 30)
    YesBtn.Position = UDim2.new(0, 20, 1, -40)
    YesBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    YesBtn.Text = "Ya, Lanjutkan"
    YesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    YesBtn.Font = Enum.Font.SourceSansBold
    YesBtn.TextSize = 12
    YesBtn.Parent = DialogBox

    local YesCorner = Instance.new("UICorner")
    YesCorner.CornerRadius = UDim.new(0, 4)
    YesCorner.Parent = YesBtn

    local NoBtn = Instance.new("TextButton")
    NoBtn.Size = UDim2.new(0, 110, 0, 30)
    NoBtn.Position = UDim2.new(1, -130, 1, -40)
    NoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    NoBtn.Text = "Batal"
    NoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    NoBtn.Font = Enum.Font.SourceSansBold
    NoBtn.TextSize = 12
    NoBtn.Parent = DialogBox

    local NoCorner = Instance.new("UICorner")
    NoCorner.CornerRadius = UDim.new(0, 4)
    NoCorner.Parent = NoBtn

    YesBtn.MouseButton1Click:Connect(function()
        Overlay:Destroy()
        if onConfirm then onConfirm() end
    end)

    NoBtn.MouseButton1Click:Connect(function()
        Overlay:Destroy()
    end)
end

-- Frame Utama
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 460, 0, 320)
MainFrame.Position = UDim2.new(0.5, -230, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = MainGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

-- Top Bar (Header)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 8)
TopCorner.Parent = TopBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -90, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "raff-wp"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

-- Tombol Minimize & Close
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 25)
MinimizeBtn.Position = UDim2.new(1, -65, 0, 5)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 18
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.Parent = TopBar

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 4)
MinimizeCorner.Parent = MinimizeBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 25)
CloseBtn.Position = UDim2.new(1, -32, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseBtn

-- Sidebar Tab Container
local TabHolder = Instance.new("Frame")
TabHolder.Size = UDim2.new(0, 110, 1, -45)
TabHolder.Position = UDim2.new(0, 5, 0, 40)
TabHolder.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TabHolder.BorderSizePixel = 0
TabHolder.Parent = MainFrame

local TabCorner = Instance.new("UICorner")
TabCorner.CornerRadius = UDim.new(0, 6)
TabCorner.Parent = TabHolder

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 4)
TabListLayout.Parent = TabHolder

-- Content Container
local ContentHolder = Instance.new("Frame")
ContentHolder.Size = UDim2.new(1, -130, 1, -45)
ContentHolder.Position = UDim2.new(0, 120, 0, 40)
ContentHolder.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ContentHolder.BorderSizePixel = 0
ContentHolder.Parent = MainFrame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 6)
ContentCorner.Parent = ContentHolder

-- Tombol Melayang MENU (Floating Toggle)
local MenuToggleBtn = Instance.new("TextButton")
MenuToggleBtn.Name = "MenuToggleBtn"
MenuToggleBtn.Size = UDim2.new(0, 40, 0, 40)
MenuToggleBtn.Position = UDim2.new(0.05, 0, 0.15, 0)
MenuToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MenuToggleBtn.Text = "🚩"
MenuToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MenuToggleBtn.Font = Enum.Font.SourceSansBold
MenuToggleBtn.TextSize = 11
MenuToggleBtn.Active = true
MenuToggleBtn.Draggable = true
MenuToggleBtn.Parent = MainGui

local MenuCorner = Instance.new("UICorner")
MenuCorner.CornerRadius = UDim.new(0, 20)
MenuCorner.Parent = MenuToggleBtn

-- System Tab Switching
local tabs = {}
local function createTab(name, isScrolling)
    if isScrolling == nil then isScrolling = true end

    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1, 0, 0, 30)
    tabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    tabBtn.Text = name
    tabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabBtn.Font = Enum.Font.SourceSansBold
    tabBtn.TextSize = 13
    tabBtn.Parent = TabHolder

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = tabBtn

    local page
    if isScrolling then
        page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, -10, 1, -10)
        page.Position = UDim2.new(0, 5, 0, 5)
        page.BackgroundTransparency = 1
        page.ScrollBarThickness = 4
        page.Visible = false
        page.Parent = ContentHolder

        local pageList = Instance.new("UIListLayout")
        pageList.SortOrder = Enum.SortOrder.LayoutOrder
        pageList.Padding = UDim.new(0, 6)
        pageList.Parent = page

        pageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, pageList.AbsoluteContentSize.Y + 10)
        end)
    else
        page = Instance.new("Frame")
        page.Size = UDim2.new(1, -10, 1, -10)
        page.Position = UDim2.new(0, 5, 0, 5)
        page.BackgroundTransparency = 1
        page.Visible = false
        page.Parent = ContentHolder
    end

    tabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do
            t.Page.Visible = false
            t.Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            t.Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        page.Visible = true
        tabBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    table.insert(tabs, {Btn = tabBtn, Page = page})
    return page
end

local PageMain = createTab("Main CP", true)
local PageCustom = createTab("Waypoint", false)
local PageSettings = createTab("Setting", true)

tabs[1].Page.Visible = true
tabs[1].Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
tabs[1].Btn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- ================= HELPER UI CREATORS =================
local function createButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 13
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function createToggle(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -6, 0, 30)
    frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -40, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 24, 0, 20)
    toggleBtn.Position = UDim2.new(1, -28, 0, 5)
    toggleBtn.BackgroundColor3 = default and Color3.fromRGB(0, 170, 90) or Color3.fromRGB(80, 80, 80)
    toggleBtn.Text = default and "ON" or "OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.SourceSansBold
    toggleBtn.TextSize = 10
    toggleBtn.Parent = frame

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(0, 4)
    tCorner.Parent = toggleBtn

    local state = default
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        toggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 90) or Color3.fromRGB(80, 80, 80)
        toggleBtn.Text = state and "ON" or "OFF"
        callback(state)
    end)
end

local function createInput(parent, placeholder, callback)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -6, 0, 30)
    box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    box.PlaceholderText = placeholder
    box.Text = ""
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.SourceSans
    box.TextSize = 13
    box.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = box

    box.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            callback(box.Text)
        end
    end)
end

local function createSliderWithInput(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -6, 0, 45)
    frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 0, 20)
    label.Position = UDim2.new(0, 8, 0, 2)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local valBox = Instance.new("TextBox")
    valBox.Size = UDim2.new(0, 45, 0, 18)
    valBox.Position = UDim2.new(1, -50, 0, 3)
    valBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    valBox.Text = tostring(default)
    valBox.TextColor3 = Color3.fromRGB(0, 170, 255)
    valBox.Font = Enum.Font.SourceSansBold
    valBox.TextSize = 12
    valBox.Parent = frame

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 3)
    boxCorner.Parent = valBox

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -16, 0, 6)
    sliderBg.Position = UDim2.new(0, 8, 0, 28)
    sliderBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    sliderBg.Parent = frame

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, 3)
    trackCorner.Parent = sliderBg

    local sliderFill = Instance.new("Frame")
    local initPercent = math.clamp((default - min) / (max - min), 0, 1)
    sliderFill.Size = UDim2.new(initPercent, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    sliderFill.Parent = sliderBg

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = sliderFill

    local isDragging = false

    local function updateValue(val, triggerCallback)
        local clamped = math.clamp(math.floor(val + 0.5), min, max)
        local percent = (clamped - min) / (max - min)
        
        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
        valBox.Text = tostring(clamped)
        
        if triggerCallback then
            callback(clamped)
        end
    end

    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            local mousePos = UserInputService:GetMouseLocation().X
            local relPos = mousePos - sliderBg.AbsolutePosition.X
            local percent = math.clamp(relPos / sliderBg.AbsoluteSize.X, 0, 1)
            local val = min + (percent * (max - min))
            updateValue(val, true)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local mousePos = UserInputService:GetMouseLocation().X
            local relPos = mousePos - sliderBg.AbsolutePosition.X
            local percent = math.clamp(relPos / sliderBg.AbsoluteSize.X, 0, 1)
            local val = min + (percent * (max - min))
            updateValue(val, true)
        end
    end)

    valBox.FocusLost:Connect(function(enterPressed)
        local num = tonumber(valBox.Text)
        if num then
            updateValue(num, true)
        else
            valBox.Text = tostring(loopDelay)
        end
    end)
end

-- ================= SETUP LAYOUT WAYPOINT TAB =================
local WaypointTopControls = Instance.new("ScrollingFrame")
WaypointTopControls.Size = UDim2.new(1, 0, 0, 115)
WaypointTopControls.BackgroundTransparency = 1
WaypointTopControls.ScrollBarThickness = 3
WaypointTopControls.Parent = PageCustom

local TopListLayout = Instance.new("UIListLayout")
TopListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TopListLayout.Padding = UDim.new(0, 5)
TopListLayout.Parent = WaypointTopControls

TopListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    WaypointTopControls.CanvasSize = UDim2.new(0, 0, 0, TopListLayout.AbsoluteContentSize.Y + 5)
end)

local WaypointDivider = Instance.new("Frame")
WaypointDivider.Size = UDim2.new(1, -6, 0, 1)
WaypointDivider.Position = UDim2.new(0, 0, 0, 120)
WaypointDivider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
WaypointDivider.BorderSizePixel = 0
WaypointDivider.Parent = PageCustom

local WaypointListTitle = Instance.new("TextLabel")
WaypointListTitle.Size = UDim2.new(1, -6, 0, 18)
WaypointListTitle.Position = UDim2.new(0, 2, 0, 125)
WaypointListTitle.BackgroundTransparency = 1
WaypointListTitle.Text = "Daftar Wp tersimpan"
WaypointListTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
WaypointListTitle.Font = Enum.Font.SourceSansBold
WaypointListTitle.TextSize = 12
WaypointListTitle.TextXAlignment = Enum.TextXAlignment.Left
WaypointListTitle.Parent = PageCustom

local WaypointListBox = Instance.new("Frame")
WaypointListBox.Size = UDim2.new(1, -6, 1, -148)
WaypointListBox.Position = UDim2.new(0, 0, 0, 145)
WaypointListBox.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
WaypointListBox.BorderSizePixel = 0
WaypointListBox.Parent = PageCustom

local ListBoxCorner = Instance.new("UICorner")
ListBoxCorner.CornerRadius = UDim.new(0, 6)
ListBoxCorner.Parent = WaypointListBox

local WaypointScrollList = Instance.new("ScrollingFrame")
WaypointScrollList.Size = UDim2.new(1, -10, 1, -10)
WaypointScrollList.Position = UDim2.new(0, 5, 0, 5)
WaypointScrollList.BackgroundTransparency = 1
WaypointScrollList.ScrollBarThickness = 4
WaypointScrollList.Parent = WaypointListBox

local WaypointListLayout = Instance.new("UIListLayout")
WaypointListLayout.SortOrder = Enum.SortOrder.LayoutOrder
WaypointListLayout.Padding = UDim.new(0, 5)
WaypointListLayout.Parent = WaypointScrollList

WaypointListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    WaypointScrollList.CanvasSize = UDim2.new(0, 0, 0, WaypointListLayout.AbsoluteContentSize.Y + 10)
end)

-- ================= LOGIKA SCRIPT =================
local function renderCustomWaypointsUI()
    for _, child in pairs(WaypointScrollList:GetChildren()) do
        if child:IsA("TextButton") then 
            child:Destroy() 
        end
    end

    for _, wp in ipairs(customWaypoints) do
        createButton(WaypointScrollList, "Teleport ke " .. wp.Name, function()
            teleportTo(wp.CF)
            showNotification("Teleport", "Berhasil teleport ke " .. wp.Name, 2)
        end)
    end
end

local function saveWaypointsToFile()
    ensureFolderExists()
    local dataToSave = {}
    for _, wp in ipairs(customWaypoints) do
        local pos = wp.CF.Position
        table.insert(dataToSave, {Name = wp.Name, Pos = {pos.X, pos.Y, pos.Z}})
    end
    pcall(function()
        writefile(fileName, HttpService:JSONEncode(dataToSave))
    end)
end

local function loadWaypointsFromFile(isAutoLoad)
    ensureFolderExists()
    if readfile and isfile and isfile(fileName) then
        local success, err = pcall(function()
            local rawData = readfile(fileName)
            local decoded = HttpService:JSONDecode(rawData)
            customWaypoints = {}
            for _, item in ipairs(decoded) do
                table.insert(customWaypoints, {
                    Name = item.Name,
                    CF = CFrame.new(item.Pos[1], item.Pos[2], item.Pos[3])
                })
            end
            renderCustomWaypointsUI()
        end)

        if success then
            if isAutoLoad then
                showNotification("Auto Load", "Config map dimuat otomatis (" .. #customWaypoints .. " waypoint)", 3)
            else
                showNotification("Config Loaded", "Berhasil memuat " .. #customWaypoints .. " waypoint.", 3)
            end
        else
            if not isAutoLoad then
                showNotification("Config Error", "Gagal membaca isi file config.", 3)
            end
        end
    else
        if not isAutoLoad then
            showNotification("Config Error", "File simpanan tidak ditemukan.", 3)
        end
    end
end

local function scanCheckpoints()
    checkpoints = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local nameLower = obj.Name:lower()
            if nameLower:find("cp") or nameLower:find("checkpoint") or nameLower:find("stage") or nameLower:find("pos") then
                table.insert(checkpoints, obj)
            end
        end
    end
    table.sort(checkpoints, function(a, b)
        local numA = tonumber(a.Name:match("%d+")) or 0
        local numB = tonumber(b.Name:match("%d+")) or 0
        return numA < numB
    end)
    showNotification("Scan Selesai", "Ditemukan " .. #checkpoints .. " checkpoint di map.", 3)
end

-- --- TAB 1: MAIN CP ---
createButton(PageMain, "Scan Checkpoints Map", function()
    scanCheckpoints()
end)

createToggle(PageMain, "Auto Teleport CP (Looping)", false, function(Value)
    autoCPActive = Value
    showNotification("Auto CP", "Auto Teleport CP: " .. (Value and "ON" or "OFF"), 2)
    task.spawn(function()
        while autoCPActive do
            if #checkpoints == 0 then scanCheckpoints() end
            for _, cp in ipairs(checkpoints) do
                if not autoCPActive then break end
                local targetCF = cp:IsA("Model") and cp:GetPivot() or cp.CFrame
                teleportTo(targetCF)
                task.wait(loopDelay)
            end
            task.wait(0.5)
        end
    end)
end)

createInput(PageMain, "Ketik Angka CP (Misal: 1, 2)", function(Text)
    local cpIndex = tonumber(Text)
    if cpIndex and checkpoints[cpIndex] then
        local cp = checkpoints[cpIndex]
        local targetCF = cp:IsA("Model") and cp:GetPivot() or cp.CFrame
        teleportTo(targetCF)
        showNotification("Teleport CP", "Teleport ke Checkpoint " .. cpIndex, 2)
    else
        showNotification("Error", "Checkpoint tidak ditemukan!", 2)
    end
end)

-- --- TAB 2: WAYPOINT ---
createButton(WaypointTopControls, "Tambah Waypoint di Posisi Ini", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local currentCF = LocalPlayer.Character.HumanoidRootPart.CFrame
        local wpName = "Waypoint " .. (#customWaypoints + 1)
        table.insert(customWaypoints, {Name = wpName, CF = currentCF})
        saveWaypointsToFile()
        renderCustomWaypointsUI()
        showNotification("Waypoint Saved", wpName .. " berhasil ditambahkan!", 2)
    end
end)

createButton(WaypointTopControls, "Load Config Waypoint Tersimpan", function()
    loadWaypointsFromFile(false)
end)

createToggle(WaypointTopControls, "Auto Custom Teleport (Looping)", false, function(Value)
    autoCustomActive = Value
    showNotification("Auto Waypoint", "Auto Teleport Waypoint: " .. (Value and "ON" or "OFF"), 2)
    task.spawn(function()
        while autoCustomActive do
            if #customWaypoints == 0 then break end
            for _, wp in ipairs(customWaypoints) do
                if not autoCustomActive then break end
                teleportTo(wp.CF)
                task.wait(loopDelay)
            end
            task.wait(0.5)
        end
    end)
end)

-- Tombol hapus dengan Konfirmasi Pop-up
createButton(WaypointTopControls, "Hapus Semua Waypoint", function()
    showConfirmation(
        "Hapus Config Waypoint?", 
        "Apakah kamu yakin ingin menghapus seluruh waypoint & file penyimpanan?", 
        function()
            customWaypoints = {}
            renderCustomWaypointsUI()
            if delfile and isfile and isfile(fileName) then
                delfile(fileName)
            end
            showNotification("Waypoint Cleared", "Semua waypoint dan file telah dihapus.", 3)
        end
    )
end)

-- --- TAB 3: SETTING ---
createSliderWithInput(PageSettings, "Delay Teleport (Detik)", 1, 10, loopDelay, function(Value)
    loopDelay = Value
    showNotification("Setting Updated", "Delay teleport: " .. Value .. " detik", 1.5)
end)

local function cleanupAll()
    autoCPActive = false
    autoCustomActive = false
    checkpoints = {}
    customWaypoints = {}
    MainGui:Destroy()
end

-- Tombol close script dengan Konfirmasi Pop-up
createButton(PageSettings, "Close Script & Reset Status", function()
    showConfirmation(
        "Tutup Script?", 
        "Script akan dihentikan dan UI akan dihapus. Lanjutkan?", 
        function()
            cleanupAll()
        end
    )
end)

-- ================= TOMBOL EVENT HANDLER =================
MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    showNotification("UI Minimize", "Tekan tombol MENU untuk membuka kembali.", 2)
end)

MenuToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Tombol "X" header dengan Konfirmasi Pop-up
CloseBtn.MouseButton1Click:Connect(function()
    showConfirmation(
        "Keluar dari Script?", 
        "Apakah kamu yakin ingin menutup dan mematikan UI script?", 
        function()
            cleanupAll()
        end
    )
end)

-- Initial Load Notification & Auto Load Config Map Active
showNotification("Script Loaded", "raff-wp Siap Digunakan!", 3)
task.spawn(function()
    loadWaypointsFromFile(true)
end)
