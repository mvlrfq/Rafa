-- Spotify Navy Dashboard - Landscape Universal (Android & iOS)
-- Features: Resizable, Fixed Boundary, Seekable Progress Bar, Manual Volume Input, Play All/Shuffle Local, Resume Audio Fix
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

--------------------------------------------------------------------------------
-- 1. KONFIGURASI SERVER
--------------------------------------------------------------------------------
local SERVER_URL = "https://till-however-arts-zinc.trycloudflare.com"
local LOCAL_JSON_FILE = "navyspotify_playlist.json"

if PlayerGui:FindFirstChild("NavySpotifyUI") then
    PlayerGui.NavySpotifyUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NavySpotifyUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999999
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

--------------------------------------------------------------------------------
-- 2. MAIN FRAME (LANDSCAPE, NORMAL DRAGGABLE & RESIZABLE)
--------------------------------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 560, 0, 320)
MainFrame.Position = UDim2.new(0.5, -280, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = false
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(40, 55, 80)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Top Bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 32)
TopBar.BackgroundTransparency = 1
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🎵 Spotify Navy Dashboard"
Title.TextColor3 = Color3.fromRGB(240, 245, 255)
Title.TextSize = 12
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 24, 0, 24)
MinBtn.Position = UDim2.new(1, -30, 0, 4)
MinBtn.BackgroundColor3 = Color3.fromRGB(28, 38, 56)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 14
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = TopBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1, 0)
MinCorner.Parent = MinBtn

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 44, 0, 44)
ToggleBtn.Position = UDim2.new(0, 12, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
ToggleBtn.Text = "🎵"
ToggleBtn.TextSize = 20
ToggleBtn.Active = true
ToggleBtn.Draggable = true
ToggleBtn.Visible = false
ToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleBtn

-- Resizing Handle (Pojok Kanan Bawah)
local ResizeHandle = Instance.new("TextButton")
ResizeHandle.Size = UDim2.new(0, 16, 0, 16)
ResizeHandle.Position = UDim2.new(1, -16, 1, -16)
ResizeHandle.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
ResizeHandle.Text = "↘"
ResizeHandle.TextColor3 = Color3.fromRGB(255, 255, 255)
ResizeHandle.TextSize = 10
ResizeHandle.Font = Enum.Font.GothamBold
ResizeHandle.Parent = MainFrame

local ResizeCorner = Instance.new("UICorner")
ResizeCorner.CornerRadius = UDim.new(0, 4)
ResizeCorner.Parent = ResizeHandle

--------------------------------------------------------------------------------
-- 3. BOUNDARY GUARD (MENCEGAH NYANGKUT DI ATAS)
--------------------------------------------------------------------------------
local function ClampToScreen(frame)
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    
    local absPos = frame.AbsolutePosition
    local absSize = frame.AbsoluteSize
    
    local clampedX = math.clamp(absPos.X, 10, math.max(10, viewport.X - absSize.X - 10))
    local clampedY = math.clamp(absPos.Y, 10, math.max(10, viewport.Y - absSize.Y - 10))
    
    if absPos.X ~= clampedX or absPos.Y ~= clampedY then
        frame.Position = UDim2.new(0, clampedX, 0, clampedY)
    end
end

MainFrame:GetPropertyChangedSignal("Position"):Connect(function()
    ClampToScreen(MainFrame)
end)

ToggleBtn:GetPropertyChangedSignal("Position"):Connect(function()
    ClampToScreen(ToggleBtn)
end)

-- Resizing Logic
local isResizing = false
local startSize, startMousePos

ResizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = true
        startSize = MainFrame.Size
        startMousePos = input.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - startMousePos
        local newWidth = math.clamp(startSize.X.Offset + delta.X, 450, 800)
        local newHeight = math.clamp(startSize.Y.Offset + delta.Y, 260, 500)
        MainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = false
    end
end)

--------------------------------------------------------------------------------
-- 4. SIDEBAR KIRI (NAVIGASI & WIDGET PING TERPISAH)
--------------------------------------------------------------------------------
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 150, 1, -40)
Sidebar.Position = UDim2.new(0, 10, 0, 34)
Sidebar.BackgroundColor3 = Color3.fromRGB(20, 26, 38)
Sidebar.Parent = MainFrame

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 8)
SidebarCorner.Parent = Sidebar

local MenuLayout = Instance.new("UIListLayout")
MenuLayout.Padding = UDim.new(0, 6)
MenuLayout.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 8)
SidebarPadding.PaddingLeft = UDim.new(0, 8)
SidebarPadding.PaddingRight = UDim.new(0, 8)
SidebarPadding.PaddingBottom = UDim.new(0, 8)
SidebarPadding.Parent = Sidebar

local TabSearchBtn = Instance.new("TextButton")
TabSearchBtn.Size = UDim2.new(1, 0, 0, 36)
TabSearchBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
TabSearchBtn.Text = "🔍 Cari YouTube"
TabSearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TabSearchBtn.TextSize = 11
TabSearchBtn.Font = Enum.Font.GothamBold
TabSearchBtn.Parent = Sidebar

local TabSearchCorner = Instance.new("UICorner")
TabSearchCorner.CornerRadius = UDim.new(0, 6)
TabSearchCorner.Parent = TabSearchBtn

local TabLocalBtn = Instance.new("TextButton")
TabLocalBtn.Size = UDim2.new(1, 0, 0, 36)
TabLocalBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 58)
TabLocalBtn.Text = "💾 Lagu Lokal"
TabLocalBtn.TextColor3 = Color3.fromRGB(180, 200, 220)
TabLocalBtn.TextSize = 11
TabLocalBtn.Font = Enum.Font.GothamBold
TabLocalBtn.Parent = Sidebar

local TabLocalCorner = Instance.new("UICorner")
TabLocalCorner.CornerRadius = UDim.new(0, 6)
TabLocalCorner.Parent = TabLocalBtn

-- Widget Ping Terisolasi
local PingWidget = Instance.new("Frame")
PingWidget.Size = UDim2.new(1, 0, 0, 55)
PingWidget.Position = UDim2.new(0, 0, 1, -55)
PingWidget.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
PingWidget.Parent = Sidebar

local PingCorner = Instance.new("UICorner")
PingCorner.CornerRadius = UDim.new(0, 6)
PingCorner.Parent = PingWidget

local PingTitle = Instance.new("TextLabel")
PingTitle.Size = UDim2.new(1, -8, 0, 16)
PingTitle.Position = UDim2.new(0, 4, 0, 4)
PingTitle.BackgroundTransparency = 1
PingTitle.Text = "SERVER PING:"
PingTitle.TextColor3 = Color3.fromRGB(130, 150, 180)
PingTitle.TextSize = 8
PingTitle.Font = Enum.Font.GothamBold
PingTitle.TextXAlignment = Enum.TextXAlignment.Left
PingTitle.Parent = PingWidget

local ServerPingLabel = Instance.new("TextLabel")
ServerPingLabel.Size = UDim2.new(1, -8, 0, 30)
ServerPingLabel.Position = UDim2.new(0, 4, 0, 20)
ServerPingLabel.BackgroundTransparency = 1
ServerPingLabel.Text = "🟡 Memeriksa..."
ServerPingLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
ServerPingLabel.TextSize = 9
ServerPingLabel.Font = Enum.Font.GothamBold
ServerPingLabel.TextXAlignment = Enum.TextXAlignment.Left
ServerPingLabel.TextWrapped = true
ServerPingLabel.Parent = PingWidget

--------------------------------------------------------------------------------
-- 5. KONTEN UTAMA KANAN (TAB TERPISAH)
--------------------------------------------------------------------------------
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -170, 1, -40)
ContentArea.Position = UDim2.new(0, 164, 0, 34)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

-- TAB 1: PENCARIAN YOUTUBE
local SearchView = Instance.new("Frame")
SearchView.Size = UDim2.new(1, 0, 1, -85)
SearchView.BackgroundTransparency = 1
SearchView.Visible = true
SearchView.Parent = ContentArea

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -58, 0, 32)
SearchBox.BackgroundColor3 = Color3.fromRGB(22, 30, 45)
SearchBox.PlaceholderText = "Cari judul lagu di YouTube..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(120, 135, 165)
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.TextSize = 11
SearchBox.Font = Enum.Font.Gotham
SearchBox.Parent = SearchView

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 6)
SearchCorner.Parent = SearchBox

local SearchBtn = Instance.new("TextButton")
SearchBtn.Size = UDim2.new(0, 50, 0, 32)
SearchBtn.Position = UDim2.new(1, -50, 0, 0)
SearchBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
SearchBtn.Text = "Cari"
SearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBtn.TextSize = 11
SearchBtn.Font = Enum.Font.GothamBold
SearchBtn.Parent = SearchView

local SearchBtnCorner = Instance.new("UICorner")
SearchBtnCorner.CornerRadius = UDim.new(0, 6)
SearchBtnCorner.Parent = SearchBtn

local SearchStatusLabel = Instance.new("TextLabel")
SearchStatusLabel.Size = UDim2.new(1, 0, 0, 16)
SearchStatusLabel.Position = UDim2.new(0, 0, 0, 36)
SearchStatusLabel.BackgroundTransparency = 1
SearchStatusLabel.Text = "Status: Siap mencari..."
SearchStatusLabel.TextColor3 = Color3.fromRGB(150, 170, 200)
SearchStatusLabel.TextSize = 9
SearchStatusLabel.Font = Enum.Font.Gotham
SearchStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
SearchStatusLabel.Parent = SearchView

local SearchScroll = Instance.new("ScrollingFrame")
SearchScroll.Size = UDim2.new(1, 0, 1, -56)
SearchScroll.Position = UDim2.new(0, 0, 0, 56)
SearchScroll.BackgroundTransparency = 1
SearchScroll.BorderSizePixel = 0
SearchScroll.ScrollBarThickness = 3
SearchScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
SearchScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SearchScroll.Parent = SearchView

local SearchScrollList = Instance.new("UIListLayout")
SearchScrollList.Padding = UDim.new(0, 4)
SearchScrollList.Parent = SearchScroll

-- TAB 2: LAGU LOKAL TERSIMPAN
local LocalView = Instance.new("Frame")
LocalView.Size = UDim2.new(1, 0, 1, -85)
LocalView.BackgroundTransparency = 1
LocalView.Visible = false
LocalView.Parent = ContentArea

-- Top Action Bar Local (Play All & Shuffle Buttons)
local LocalActionBar = Instance.new("Frame")
LocalActionBar.Size = UDim2.new(1, 0, 0, 26)
LocalActionBar.BackgroundTransparency = 1
LocalActionBar.Parent = LocalView

local LocalTitle = Instance.new("TextLabel")
LocalTitle.Size = UDim2.new(1, -120, 1, 0)
LocalTitle.BackgroundTransparency = 1
LocalTitle.Text = "💾 Playlist Lokal:"
LocalTitle.TextColor3 = Color3.fromRGB(80, 220, 120)
LocalTitle.TextSize = 10
LocalTitle.Font = Enum.Font.GothamBold
LocalTitle.TextXAlignment = Enum.TextXAlignment.Left
LocalTitle.Parent = LocalActionBar

local PlayAllLocalBtn = Instance.new("TextButton")
PlayAllLocalBtn.Size = UDim2.new(0, 55, 1, 0)
PlayAllLocalBtn.Position = UDim2.new(1, -114, 0, 0)
PlayAllLocalBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
PlayAllLocalBtn.Text = "▶ Semua"
PlayAllLocalBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayAllLocalBtn.TextSize = 9
PlayAllLocalBtn.Font = Enum.Font.GothamBold
PlayAllLocalBtn.Parent = LocalActionBar

local PlayAllCorner = Instance.new("UICorner")
PlayAllCorner.CornerRadius = UDim.new(0, 4)
PlayAllCorner.Parent = PlayAllLocalBtn

local ShuffleLocalBtn = Instance.new("TextButton")
ShuffleLocalBtn.Size = UDim2.new(0, 55, 1, 0)
ShuffleLocalBtn.Position = UDim2.new(1, -55, 0, 0)
ShuffleLocalBtn.BackgroundColor3 = Color3.fromRGB(60, 70, 95)
ShuffleLocalBtn.Text = "🔀 Acak"
ShuffleLocalBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ShuffleLocalBtn.TextSize = 9
ShuffleLocalBtn.Font = Enum.Font.GothamBold
ShuffleLocalBtn.Parent = LocalActionBar

local ShuffleCorner = Instance.new("UICorner")
ShuffleCorner.CornerRadius = UDim.new(0, 4)
ShuffleCorner.Parent = ShuffleLocalBtn

local LocalScroll = Instance.new("ScrollingFrame")
LocalScroll.Size = UDim2.new(1, 0, 1, -30)
LocalScroll.Position = UDim2.new(0, 0, 0, 30)
LocalScroll.BackgroundTransparency = 1
LocalScroll.BorderSizePixel = 0
LocalScroll.ScrollBarThickness = 3
LocalScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
LocalScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
LocalScroll.Parent = LocalView

local LocalScrollList = Instance.new("UIListLayout")
LocalScrollList.Padding = UDim.new(0, 4)
LocalScrollList.Parent = LocalScroll

--------------------------------------------------------------------------------
-- 6. ACTIVE PLAYER PANEL (SEEKABLE PROGRESS BAR & MANUAL VOLUME)
--------------------------------------------------------------------------------
local PlayerBar = Instance.new("Frame")
PlayerBar.Size = UDim2.new(1, 0, 0, 75)
PlayerBar.Position = UDim2.new(0, 0, 1, -75)
PlayerBar.BackgroundColor3 = Color3.fromRGB(22, 30, 46)
PlayerBar.Parent = ContentArea

local PlayerCorner = Instance.new("UICorner")
PlayerCorner.CornerRadius = UDim.new(0, 8)
PlayerCorner.Parent = PlayerBar

local TrackTitle = Instance.new("TextLabel")
TrackTitle.Size = UDim2.new(1, -10, 0, 16)
TrackTitle.Position = UDim2.new(0, 6, 0, 4)
TrackTitle.BackgroundTransparency = 1
TrackTitle.Text = "Belum ada lagu diputar"
TrackTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
TrackTitle.TextSize = 10
TrackTitle.Font = Enum.Font.GothamBold
TrackTitle.TextTruncate = Enum.TextTruncate.AtEnd
TrackTitle.TextXAlignment = Enum.TextXAlignment.Left
TrackTitle.Parent = PlayerBar

local PlayerStatusLabel = Instance.new("TextLabel")
PlayerStatusLabel.Size = UDim2.new(1, -10, 0, 12)
PlayerStatusLabel.Position = UDim2.new(0, 6, 0, 20)
PlayerStatusLabel.BackgroundTransparency = 1
PlayerStatusLabel.Text = "Status: Standby"
PlayerStatusLabel.TextColor3 = Color3.fromRGB(140, 160, 190)
PlayerStatusLabel.TextSize = 8
PlayerStatusLabel.Font = Enum.Font.Gotham
PlayerStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
PlayerStatusLabel.Parent = PlayerBar

-- Interactive Seekable Progress Bar (TextButton agar bisa diklik/digeser untuk melompat detik lagu)
local ProgressBg = Instance.new("TextButton")
ProgressBg.Size = UDim2.new(1, -12, 0, 6)
ProgressBg.Position = UDim2.new(0, 6, 0, 36)
ProgressBg.BackgroundColor3 = Color3.fromRGB(35, 48, 70)
ProgressBg.Text = ""
ProgressBg.AutoButtonColor = false
ProgressBg.Parent = PlayerBar

local ProgressBgCorner = Instance.new("UICorner")
ProgressBgCorner.CornerRadius = UDim.new(1, 0)
ProgressBgCorner.Parent = ProgressBg

local ProgressFill = Instance.new("Frame")
ProgressFill.Size = UDim2.new(0, 0, 1, 0)
ProgressFill.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
ProgressFill.BorderSizePixel = 0
ProgressFill.Parent = ProgressBg

local ProgressFillCorner = Instance.new("UICorner")
ProgressFillCorner.CornerRadius = UDim.new(1, 0)
ProgressFillCorner.Parent = ProgressFill

local TimeLabel = Instance.new("TextLabel")
TimeLabel.Size = UDim2.new(1, -10, 0, 10)
TimeLabel.Position = UDim2.new(0, 6, 0, 44)
TimeLabel.BackgroundTransparency = 1
TimeLabel.Text = "00:00 / 00:00"
TimeLabel.TextColor3 = Color3.fromRGB(150, 170, 200)
TimeLabel.TextSize = 8
TimeLabel.Font = Enum.Font.Gotham
TimeLabel.TextXAlignment = Enum.TextXAlignment.Right
TimeLabel.Parent = PlayerBar

-- Tombol Kontrol: Play/Pause (Digabung jadi 1), Stop, Loop, Shuffle
local PlayBtn = Instance.new("TextButton")
PlayBtn.Size = UDim2.new(0, 26, 0, 24)
PlayBtn.Position = UDim2.new(0, 6, 0, 46)
PlayBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
PlayBtn.Text = "▶"
PlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayBtn.TextSize = 10
PlayBtn.Font = Enum.Font.GothamBold
PlayBtn.Parent = PlayerBar

local PlayCorner = Instance.new("UICorner")
PlayCorner.CornerRadius = UDim.new(0, 6)
PlayCorner.Parent = PlayBtn

local StopBtn = Instance.new("TextButton")
StopBtn.Size = UDim2.new(0, 26, 0, 24)
StopBtn.Position = UDim2.new(0, 36, 0, 46)
StopBtn.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
StopBtn.Text = "◼"
StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StopBtn.TextSize = 9
StopBtn.Font = Enum.Font.GothamBold
StopBtn.Parent = PlayerBar

local StopCorner = Instance.new("UICorner")
StopCorner.CornerRadius = UDim.new(0, 6)
StopCorner.Parent = StopBtn

local LoopBtn = Instance.new("TextButton")
LoopBtn.Size = UDim2.new(0, 26, 0, 24)
LoopBtn.Position = UDim2.new(0, 66, 0, 46)
LoopBtn.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
LoopBtn.Text = "🔁"
LoopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LoopBtn.TextSize = 10
LoopBtn.Font = Enum.Font.GothamBold
LoopBtn.Parent = PlayerBar

local LoopCorner = Instance.new("UICorner")
LoopCorner.CornerRadius = UDim.new(0, 6)
LoopCorner.Parent = LoopBtn

local ShuffleBtn = Instance.new("TextButton")
ShuffleBtn.Size = UDim2.new(0, 26, 0, 24)
ShuffleBtn.Position = UDim2.new(0, 96, 0, 46)
ShuffleBtn.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
ShuffleBtn.Text = "🔀"
ShuffleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ShuffleBtn.TextSize = 10
ShuffleBtn.Font = Enum.Font.GothamBold
ShuffleBtn.Parent = PlayerBar

local ShuffleCorner = Instance.new("UICorner")
ShuffleCorner.CornerRadius = UDim.new(0, 6)
ShuffleCorner.Parent = ShuffleBtn

-- Volume Slider & Manual Volume Input (%)
local VolIcon = Instance.new("TextLabel")
VolIcon.Size = UDim2.new(0, 16, 0, 24)
VolIcon.Position = UDim2.new(1, -115, 0, 46)
VolIcon.BackgroundTransparency = 1
VolIcon.Text = "🔊"
VolIcon.TextSize = 10
VolIcon.Parent = PlayerBar

local VolBg = Instance.new("TextButton")
VolBg.Size = UDim2.new(0, 60, 0, 5)
VolBg.Position = UDim2.new(1, -95, 0, 55)
VolBg.BackgroundColor3 = Color3.fromRGB(35, 48, 70)
VolBg.Text = ""
VolBg.Parent = PlayerBar

local VolFill = Instance.new("Frame")
VolFill.Size = UDim2.new(1, 0, 1, 0)
VolFill.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
VolFill.BorderSizePixel = 0
VolFill.Parent = VolBg

-- Manual Volume Input TextBox (%)
local VolInputBox = Instance.new("TextBox")
VolInputBox.Size = UDim2.new(0, 30, 0, 18)
VolInputBox.Position = UDim2.new(1, -30, 0, 49)
VolInputBox.BackgroundColor3 = Color3.fromRGB(28, 38, 56)
VolInputBox.Text = "100"
VolInputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
VolInputBox.TextSize = 9
VolInputBox.Font = Enum.Font.GothamBold
VolInputBox.Parent = PlayerBar

local VolInputCorner = Instance.new("UICorner")
VolInputCorner.CornerRadius = UDim.new(0, 4)
VolInputCorner.Parent = VolInputBox

--------------------------------------------------------------------------------
-- 7. ANIMASI LOADING & SKELETON PULSE
--------------------------------------------------------------------------------
local activeSkeletonTweens = {}

local function ShowSkeletonLoading(container)
    for _, child in pairs(container:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    activeSkeletonTweens = {}
    
    for i = 1, 4 do
        local SkelCard = Instance.new("Frame")
        SkelCard.Name = "SkeletonCard"
        SkelCard.Size = UDim2.new(1, 0, 0, 28)
        SkelCard.BackgroundColor3 = Color3.fromRGB(25, 33, 48)
        SkelCard.Parent = container
        
        local SkelCorner = Instance.new("UICorner")
        SkelCorner.CornerRadius = UDim.new(0, 5)
        SkelCorner.Parent = SkelCard
        
        local PulseFrame = Instance.new("Frame")
        PulseFrame.Size = UDim2.new(0.6, 0, 0.5, 0)
        PulseFrame.Position = UDim2.new(0, 8, 0.25, 0)
        PulseFrame.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
        PulseFrame.BorderSizePixel = 0
        PulseFrame.Parent = SkelCard
        
        local PulseCorner = Instance.new("UICorner")
        PulseCorner.CornerRadius = UDim.new(0, 3)
        PulseCorner.Parent = PulseFrame
        
        local tweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
        local tween = TweenService:Create(PulseFrame, tweenInfo, { BackgroundTransparency = 0.7 })
        tween:Play()
        table.insert(activeSkeletonTweens, tween)
    end
end

local function ClearSkeletonLoading(container)
    for _, tween in ipairs(activeSkeletonTweens) do tween:Cancel() end
    activeSkeletonTweens = {}
    for _, child in pairs(container:GetChildren()) do
        if child.Name == "SkeletonCard" then child:Destroy() end
    end
end

--------------------------------------------------------------------------------
-- 8. TAB NAVIGATION LOGIC
--------------------------------------------------------------------------------
TabSearchBtn.MouseButton1Click:Connect(function()
    SearchView.Visible = true
    LocalView.Visible = false
    TabSearchBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
    TabSearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TabLocalBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 58)
    TabLocalBtn.TextColor3 = Color3.fromRGB(180, 200, 220)
end)

TabLocalBtn.MouseButton1Click:Connect(function()
    SearchView.Visible = false
    LocalView.Visible = true
    TabLocalBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
    TabLocalBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TabSearchBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 58)
    TabSearchBtn.TextColor3 = Color3.fromRGB(180, 200, 220)
end)

--------------------------------------------------------------------------------
-- 9. AUDIO ENGINE, SEEKING, & MANUAL VOLUME LOGIC
--------------------------------------------------------------------------------
local writefileFn = writefile or (syn and syn.writefile)
local readfileFn = readfile or (syn and syn.readfile)
local isfileFn = isfile or (syn and syn.isfile)
local delfileFn = delfile or (syn and syn.delfile)
local getcustomassetFn = getcustomasset or getsynasset or (syn and syn.getcustomasset)

local function LoadLocalPlaylist()
    if isfileFn and isfileFn(LOCAL_JSON_FILE) then
        local success, content = pcall(function() return readfileFn(LOCAL_JSON_FILE) end)
        if success and content then
            local pSuccess, data = pcall(function() return HttpService:JSONDecode(content) end)
            if pSuccess and type(data) == "table" then return data end
        end
    end
    return {}
end

local function SaveLocalPlaylist(playlist)
    if writefileFn then
        pcall(function() writefileFn(LOCAL_JSON_FILE, HttpService:JSONEncode(playlist)) end)
    end
end

local function customRequest(reqData)
    local req = (syn and syn.request) or request or http_request or (http and http.request)
    if not req then return nil end
    reqData.Headers = reqData.Headers or {}
    reqData.Headers["bypass-tunnel-reminder"] = "true"
    local success, response = pcall(function() return req(reqData) end)
    if not success then return nil end
    return response
end

-- Server Ping Loop
task.spawn(function()
    while task.wait(5) do
        local startTime = os.clock()
        local res = customRequest({ Url = SERVER_URL .. "/api/status", Method = "GET" })
        local latency = math.floor((os.clock() - startTime) * 1000)
        
        if res and res.StatusCode == 200 then
            ServerPingLabel.Text = string.format("🟢 Online\nPing: %d ms", latency)
            ServerPingLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
        else
            ServerPingLabel.Text = "🔴 Terputus!"
            ServerPingLabel.TextColor3 = Color3.fromRGB(240, 80, 80)
        end
    end
end)

local CurrentSound = SoundService:FindFirstChild("NavySpotifySound")
if not CurrentSound then
    CurrentSound = Instance.new("Sound")
    CurrentSound.Name = "NavySpotifySound"
    CurrentSound.Volume = 1
    CurrentSound.Parent = SoundService
end

RunService.RenderStepped:Connect(function()
    if CurrentSound.IsPlaying and CurrentSound.TimeLength > 0 then
        local alpha = math.clamp(CurrentSound.TimePosition / CurrentSound.TimeLength, 0, 1)
        ProgressFill.Size = UDim2.new(alpha, 0, 1, 0)
        local m1, s1 = math.floor(CurrentSound.TimePosition / 60), math.floor(CurrentSound.TimePosition % 60)
        local m2, s2 = math.floor(CurrentSound.TimeLength / 60), math.floor(CurrentSound.TimeLength % 60)
        TimeLabel.Text = string.format("%02d:%02d / %02d:%02d", m1, s1, m2, s2)
    elseif not CurrentSound.IsPlaying and CurrentSound.TimePosition == 0 then
        ProgressFill.Size = UDim2.new(0, 0, 1, 0)
    end
end)

-- Play/Pause Resume Logic
PlayBtn.MouseButton1Click:Connect(function()
    if CurrentSound.SoundId ~= "" then
        if CurrentSound.IsPlaying then
            CurrentSound:Pause()
            PlayBtn.Text = "▶"
            PlayerStatusLabel.Text = "Status: Paused"
        else
            if CurrentSound.IsPaused then
                CurrentSound:Resume()
            else
                CurrentSound:Play()
            end
            PlayBtn.Text = "⏸"
            PlayerStatusLabel.Text = "Status: Playing"
        end
    end
end)

StopBtn.MouseButton1Click:Connect(function()
    CurrentSound:Stop()
    CurrentSound.TimePosition = 0
    PlayBtn.Text = "▶"
    ProgressFill.Size = UDim2.new(0, 0, 1, 0)
    PlayerStatusLabel.Text = "Status: Stopped"
end)

LoopBtn.MouseButton1Click:Connect(function()
    CurrentSound.Looped = not CurrentSound.Looped
    LoopBtn.BackgroundColor3 = CurrentSound.Looped and Color3.fromRGB(41, 158, 239) or Color3.fromRGB(40, 52, 75)
end)

-- Interactive Seekable Progress Bar
ProgressBg.MouseButton1Click:Connect(function()
    -- handled via input began below for better precision
end)

ProgressBg.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and CurrentSound.TimeLength > 0 then
        local absPos = ProgressBg.AbsolutePosition.X
        local absSize = ProgressBg.AbsoluteSize.X
        local clickX = input.Position.X
        local alpha = math.clamp((clickX - absPos) / absSize, 0, 1)
        CurrentSound.TimePosition = alpha * CurrentSound.TimeLength
    end
end)

-- Volume Drag
local settingVol = false
VolBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        settingVol = true
        local alpha = math.clamp((input.Position.X - VolBg.AbsolutePosition.X) / VolBg.AbsoluteSize.X, 0, 1)
        VolFill.Size = UDim2.new(alpha, 0, 1, 0)
        local volVal = alpha * 2
        CurrentSound.Volume = volVal
        VolInputBox.Text = tostring(math.floor(volVal * 100))
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if settingVol and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local alpha = math.clamp((input.Position.X - VolBg.AbsolutePosition.X) / VolBg.AbsoluteSize.X, 0, 1)
        VolFill.Size = UDim2.new(alpha, 0, 1, 0)
        local volVal = alpha * 2
        CurrentSound.Volume = volVal
        VolInputBox.Text = tostring(math.floor(volVal * 100))
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        settingVol = false
    end
end)

-- Manual Volume Input (%)
VolInputBox.FocusLost:Connect(function()
    local num = tonumber(VolInputBox.Text)
    if num then
        num = math.clamp(num, 0, 200)
        local volVal = num / 100
        CurrentSound.Volume = volVal
        VolFill.Size = UDim2.new(math.clamp(volVal / 2, 0, 1), 0, 1, 0)
        VolInputBox.Text = tostring(math.floor(num))
    else
        VolInputBox.Text = tostring(math.floor(CurrentSound.Volume * 100))
    end
end)

MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    ToggleBtn.Visible = true
end)
ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    ToggleBtn.Visible = false
end)

--------------------------------------------------------------------------------
-- 10. RENDER LOCAL PLAYLIST, PLAY ALL, & SHUFFLE
--------------------------------------------------------------------------------
local PlayLocalTrack = function(item)
    if isfileFn and isfileFn(item.fileName) then
        TrackTitle.Text = "🎵 " .. item.title
        PlayerStatusLabel.Text = "Status: 📂 Memuat file lokal..."
        local assetUrl = getcustomassetFn(item.fileName)
        CurrentSound:Stop()
        CurrentSound.SoundId = assetUrl
        task.wait(0.1)
        CurrentSound:Play()
        PlayBtn.Text = "⏸"
        PlayerStatusLabel.Text = "Status: 🟢 Memutar (Lokal)"
    else
        PlayerStatusLabel.Text = "Status: ❌ File lokal tidak ditemukan!"
    end
end

local RenderLocalPlaylist

RenderLocalPlaylist = function()
    for _, child in pairs(LocalScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local playlist = LoadLocalPlaylist()
    if #playlist == 0 then
        LocalTitle.Text = "💾 Playlist Lokal (Kosong)"
        return
    end
    
    LocalTitle.Text = string.format("💾 Playlist (%d lagu):", #playlist)
    
    for idx, item in ipairs(playlist) do
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, 28)
        Card.BackgroundColor3 = Color3.fromRGB(22, 34, 48)
        Card.Parent = LocalScroll
        
        local CardCorner = Instance.new("UICorner")
        CardCorner.CornerRadius = UDim.new(0, 5)
        CardCorner.Parent = Card
        
        local PlayLocalBtn = Instance.new("TextButton")
        PlayLocalBtn.Size = UDim2.new(1, -30, 1, 0)
        PlayLocalBtn.Position = UDim2.new(0, 4, 0, 0)
        PlayLocalBtn.BackgroundTransparency = 1
        PlayLocalBtn.Text = "🎵 " .. item.title
        PlayLocalBtn.TextColor3 = Color3.fromRGB(220, 245, 220)
        PlayLocalBtn.TextXAlignment = Enum.TextXAlignment.Left
        PlayLocalBtn.TextSize = 10
        PlayLocalBtn.Font = Enum.Font.Gotham
        PlayLocalBtn.TextTruncate = Enum.TextTruncate.AtEnd
        PlayLocalBtn.Parent = Card
        
        local DeleteBtn = Instance.new("TextButton")
        DeleteBtn.Size = UDim2.new(0, 22, 0, 20)
        DeleteBtn.Position = UDim2.new(1, -24, 0, 4)
        DeleteBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 60)
        DeleteBtn.Text = "🗑️"
        DeleteBtn.TextSize = 9
        DeleteBtn.Parent = Card
        
        local DelCorner = Instance.new("UICorner")
        DelCorner.CornerRadius = UDim.new(0, 4)
        DelCorner.Parent = DeleteBtn
        
        PlayLocalBtn.MouseButton1Click:Connect(function()
            PlayLocalTrack(item)
        end)
        
        DeleteBtn.MouseButton1Click:Connect(function()
            if delfileFn and isfileFn and isfileFn(item.fileName) then
                pcall(function() delfileFn(item.fileName) end)
            end
            table.remove(playlist, idx)
            SaveLocalPlaylist(playlist)
            RenderLocalPlaylist()
            PlayerStatusLabel.Text = "Status: 🗑️ Lagu lokal dihapus"
        end)
    end
end

-- Play All Local Playlist
PlayAllLocalBtn.MouseButton1Click:Connect(function()
    local playlist = LoadLocalPlaylist()
    if #playlist > 0 then
        PlayLocalTrack(playlist[1])
        PlayerStatusLabel.Text = "Status: Memutar Playlist Lokal"
    end
end)

-- Shuffle Local Playlist & Play Random
ShuffleLocalBtn.MouseButton1Click:Connect(function()
    local playlist = LoadLocalPlaylist()
    if #playlist > 0 then
        local randomIndex = math.random(1, #playlist)
        PlayLocalTrack(playlist[randomIndex])
        PlayerStatusLabel.Text = "Status: Memutar Acak (Shuffle)"
    end
end)

-- Tombol Shuffle Global di Player Bar
ShuffleBtn.MouseButton1Click:Connect(function()
    local playlist = LoadLocalPlaylist()
    if #playlist > 0 then
        local randomIndex = math.random(1, #playlist)
        PlayLocalTrack(playlist[randomIndex])
        ShuffleBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
        task.delay(0.5, function()
            ShuffleBtn.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
        end)
    end
end)

local function PlayAndSaveTrack(id, name)
    TrackTitle.Text = "🎵 " .. name
    PlayerStatusLabel.Text = "Status: ⏳ Mendownload dari YouTube..."
    PlayBtn.Text = "⏳"
    
    task.spawn(function()
        local body = HttpService:JSONEncode({ videoId = id, title = name })
        local res = customRequest({
            Url = SERVER_URL .. "/api/download",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body
        })
        
        if res and res.Body then
            local success, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
            if success and data and data.success and data.fileName then
                PlayerStatusLabel.Text = "Status: 💾 Menyimpan file lokal..."
                local streamUrl = SERVER_URL .. "/stream/" .. data.fileName
                local audioBinary = game:HttpGet(streamUrl)
                
                local safeLocalFileName = "navy_song_" .. id .. ".mp3"
                if writefileFn then writefileFn(safeLocalFileName, audioBinary) end
                
                local playlist = LoadLocalPlaylist()
                local exists = false
                for _, p in ipairs(playlist) do if p.id == id then exists = true break end end
                
                if not exists then
                    table.insert(playlist, 1, { id = id, title = name, fileName = safeLocalFileName })
                    SaveLocalPlaylist(playlist)
                    RenderLocalPlaylist()
                end
                
                local assetUrl = getcustomassetFn(safeLocalFileName)
                CurrentSound:Stop()
                CurrentSound.SoundId = assetUrl
                task.wait(0.2)
                CurrentSound:Play()
                PlayBtn.Text = "⏸"
                PlayerStatusLabel.Text = "Status: 🟢 Memutar Musik"
            else
                PlayerStatusLabel.Text = "Status: ❌ Gagal memproses server"
                PlayBtn.Text = "▶"
            end
        else
            PlayerStatusLabel.Text = "Status: ❌ Koneksi server gagal"
            PlayBtn.Text = "▶"
        end
    end)
end

local function ExecuteSearch()
    if SearchBox.Text == "" then return end
    
    ShowSkeletonLoading(SearchScroll)
    SearchStatusLabel.Text = "Status: ⏳ Mencari lagu di YouTube..."
    SearchStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
    
    task.spawn(function()
        local searchUrl = SERVER_URL .. "/api/search?q=" .. HttpService:UrlEncode(SearchBox.Text)
        local res = customRequest({ Url = searchUrl, Method = "GET" })
        
        ClearSkeletonLoading(SearchScroll)
        
        if res and res.Body then
            local success, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
            if success and data and data.success and data.results and #data.results > 0 then
                for _, song in ipairs(data.results) do
                    local Card = Instance.new("Frame")
                    Card.Size = UDim2.new(1, 0, 0, 28)
                    Card.BackgroundColor3 = Color3.fromRGB(26, 36, 54)
                    Card.Parent = SearchScroll
                    
                    local CardCorner = Instance.new("UICorner")
                    CardCorner.CornerRadius = UDim.new(0, 5)
                    CardCorner.Parent = Card
                    
                    local SongBtn = Instance.new("TextButton")
                    SongBtn.Size = UDim2.new(1, -6, 1, 0)
                    SongBtn.Position = UDim2.new(0, 4, 0, 0)
                    SongBtn.BackgroundTransparency = 1
                    SongBtn.Text = "▶ " .. song.title .. " (" .. (song.uploader or "YouTube") .. ")"
                    SongBtn.TextColor3 = Color3.fromRGB(220, 235, 255)
                    SongBtn.TextXAlignment = Enum.TextXAlignment.Left
                    SongBtn.TextSize = 10
                    SongBtn.Font = Enum.Font.Gotham
                    SongBtn.TextTruncate = Enum.TextTruncate.AtEnd
                    SongBtn.Parent = Card
                    
                    SongBtn.MouseButton1Click:Connect(function()
                        PlayAndSaveTrack(song.id, song.title)
                    end)
                end
                SearchStatusLabel.Text = string.format("Status: 🟢 Ditemukan %d lagu", #data.results)
                SearchStatusLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
            else
                SearchStatusLabel.Text = "Status: ⚠️ Lagu tidak ditemukan!"
                SearchStatusLabel.TextColor3 = Color3.fromRGB(240, 80, 80)
            end
        else
            SearchStatusLabel.Text = "Status: ❌ Server tidak merespons!"
            SearchStatusLabel.TextColor3 = Color3.fromRGB(240, 80, 80)
        end
    end)
end

SearchBtn.MouseButton1Click:Connect(ExecuteSearch)
SearchBox.FocusLost:Connect(ExecuteSearch)

RenderLocalPlaylist()

--------------------------------------------------------------------------------
-- 11. AUTO RESTORE PROTECTOR
--------------------------------------------------------------------------------
PlayerGui.ChildRemoved:Connect(function(child)
    if child.Name == "NavySpotifyUI" then
        task.wait(0.5)
        if not PlayerGui:FindFirstChild("NavySpotifyUI") then
            ScreenGui.Parent = PlayerGui
        end
    end
end)
