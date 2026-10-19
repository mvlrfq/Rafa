-- Spotify Navy Dashboard - Universal (Android & iOS)
-- Features: Perfect Zero-Jump Drag via RenderStepped, CoreGui Persistence, Stable Scrubbing
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

--------------------------------------------------------------------------------
-- 1. KONFIGURASI SERVER & COREGUI PERSISTENCE
--------------------------------------------------------------------------------
local SERVER_URL = "https://till-however-arts-zinc.trycloudflare.com"
local LOCAL_JSON_FILE = "navyspotify_playlist.json"

local TOGGLE_IMAGE_ID = "" -- Masukkan link/asset ID gambar jika ada

local ExistingSound = SoundService:FindFirstChild("NavySpotifySound")
if ExistingSound then
    ExistingSound:Stop()
    ExistingSound:Destroy()
end

if CoreGui:FindFirstChild("NavySpotifyUI") then
    CoreGui.NavySpotifyUI:Destroy()
end
if PlayerGui:FindFirstChild("NavySpotifyUI") then
    PlayerGui.NavySpotifyUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NavySpotifyUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 2147483647
ScreenGui.IgnoreGuiInset = true

local successProtect = pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
    elseif protectgui then
        protectgui(ScreenGui)
        ScreenGui.Parent = CoreGui
    else
        ScreenGui.Parent = CoreGui
    end
end)

if not successProtect or ScreenGui.Parent ~= CoreGui then
    ScreenGui.Parent = PlayerGui
end

--------------------------------------------------------------------------------
-- 2. MAIN FRAME & HEADER
--------------------------------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 580, 0, 330)
MainFrame.Position = UDim2.new(0.5, -290, 0.5, -165)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = false
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(40, 55, 80)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, -40, 0, 32)
TopBar.BackgroundTransparency = 1
TopBar.Active = true
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 1, 0)
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
MinBtn.Position = UDim2.new(1, 6, 0, 4)
MinBtn.BackgroundColor3 = Color3.fromRGB(28, 38, 56)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 14
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = TopBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1, 0)
MinCorner.Parent = MinBtn

local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Size = UDim2.new(0, 44, 0, 44)
ToggleBtn.Position = UDim2.new(0, 12, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
ToggleBtn.Image = TOGGLE_IMAGE_ID ~= "" and TOGGLE_IMAGE_ID or ""
ToggleBtn.Visible = false
ToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleBtn

if TOGGLE_IMAGE_ID == "" then
    local ToggleText = Instance.new("TextLabel")
    ToggleText.Size = UDim2.new(1, 0, 1, 0)
    ToggleText.BackgroundTransparency = 1
    ToggleText.Text = "🎵"
    ToggleText.TextSize = 20
    ToggleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleText.Parent = ToggleBtn
end

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
-- 3. FIX ABSOLUT DRAG (RENDERSTEPPED - TANPA LONCAT/PERGESERAN SAMA SEKALI)
--------------------------------------------------------------------------------
local function SetupSmoothDrag(frame, handle)
    local dragging = false
    local startInputPos = Vector2.new(0, 0)
    local startFramePos = Vector2.new(0, 0)
    local renderConn = nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startInputPos = Vector2.new(input.Position.X, input.Position.Y)
            startFramePos = Vector2.new(frame.AbsolutePosition.X, frame.AbsolutePosition.Y)

            if renderConn then renderConn:Disconnect() end

            renderConn = RunService.RenderStepped:Connect(function()
                if not dragging then
                    if renderConn then
                        renderConn:Disconnect()
                        renderConn = nil
                    end
                    return
                end

                local currentMouse = UserInputService:GetMouseLocation()
                -- Modifikasi posisi berdasarkan perbedaan koordinat awal
                local deltaX = currentMouse.X - startInputPos.X
                local deltaY = currentMouse.Y - startInputPos.Y

                local camera = workspace.CurrentCamera
                local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)

                local targetX = math.clamp(startFramePos.X + deltaX, 0, math.max(0, viewport.X - frame.AbsoluteSize.X))
                local targetY = math.clamp(startFramePos.Y + deltaY, 0, math.max(0, viewport.Y - frame.AbsoluteSize.Y))

                frame.Position = UDim2.new(0, targetX, 0, targetY)
            end)

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if renderConn then
                        renderConn:Disconnect()
                        renderConn = nil
                    end
                end
            end)
        end
    end)
end

SetupSmoothDrag(MainFrame, TopBar)
SetupSmoothDrag(ToggleBtn, ToggleBtn)

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
        local newWidth = math.clamp(startSize.X.Offset + delta.X, 480, 850)
        local newHeight = math.clamp(startSize.Y.Offset + delta.Y, 280, 550)
        MainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = false
    end
end)

--------------------------------------------------------------------------------
-- 4. SIDEBAR KIRI
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
-- 5. KONTEN UTAMA KANAN
--------------------------------------------------------------------------------
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -170, 1, -40)
ContentArea.Position = UDim2.new(0, 164, 0, 34)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

-- TAB 1: SEARCH YOUTUBE
local SearchView = Instance.new("Frame")
SearchView.Size = UDim2.new(1, 0, 1, -95)
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
SearchStatusLabel.Text = "Status Pencarian: Siap mencari..."
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

-- TAB 2: LOCAL PLAYLIST
local LocalView = Instance.new("Frame")
LocalView.Size = UDim2.new(1, 0, 1, -95)
LocalView.BackgroundTransparency = 1
LocalView.Visible = false
LocalView.Parent = ContentArea

local LocalActionBar = Instance.new("Frame")
LocalActionBar.Size = UDim2.new(1, 0, 0, 26)
LocalActionBar.BackgroundTransparency = 1
LocalActionBar.Parent = LocalView

local LocalTitle = Instance.new("TextLabel")
LocalTitle.Size = UDim2.new(1, 0, 1, 0)
LocalTitle.BackgroundTransparency = 1
LocalTitle.Text = "💾 Playlist Lokal:"
LocalTitle.TextColor3 = Color3.fromRGB(80, 220, 120)
LocalTitle.TextSize = 10
LocalTitle.Font = Enum.Font.GothamBold
LocalTitle.TextXAlignment = Enum.TextXAlignment.Left
LocalTitle.Parent = LocalActionBar

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
-- 6. ACTIVE PLAYER PANEL
--------------------------------------------------------------------------------
local PlayerBar = Instance.new("Frame")
PlayerBar.Size = UDim2.new(1, 0, 0, 85)
PlayerBar.Position = UDim2.new(0, 0, 1, -85)
PlayerBar.BackgroundColor3 = Color3.fromRGB(22, 30, 46)
PlayerBar.Parent = ContentArea

local PlayerCorner = Instance.new("UICorner")
PlayerCorner.CornerRadius = UDim.new(0, 8)
PlayerCorner.Parent = PlayerBar

local TrackTitle = Instance.new("TextLabel")
TrackTitle.Size = UDim2.new(1, -12, 0, 16)
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
PlayerStatusLabel.Size = UDim2.new(1, -12, 0, 12)
PlayerStatusLabel.Position = UDim2.new(0, 6, 0, 20)
PlayerStatusLabel.BackgroundTransparency = 1
PlayerStatusLabel.Text = "Status: Standby"
PlayerStatusLabel.TextColor3 = Color3.fromRGB(140, 160, 190)
PlayerStatusLabel.TextSize = 8
PlayerStatusLabel.Font = Enum.Font.Gotham
PlayerStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
PlayerStatusLabel.Parent = PlayerBar

-- Seekable Progress Bar
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

-- Baris Tombol Kontrol
local PrevBtn = Instance.new("TextButton")
PrevBtn.Size = UDim2.new(0, 24, 0, 24)
PrevBtn.Position = UDim2.new(0, 6, 0, 52)
PrevBtn.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
PrevBtn.Text = "⏮"
PrevBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PrevBtn.TextSize = 10
PrevBtn.Font = Enum.Font.GothamBold
PrevBtn.Parent = PlayerBar

local PrevCorner = Instance.new("UICorner")
PrevCorner.CornerRadius = UDim.new(0, 5)
PrevCorner.Parent = PrevBtn

local PlayBtn = Instance.new("TextButton")
PlayBtn.Size = UDim2.new(0, 26, 0, 24)
PlayBtn.Position = UDim2.new(0, 34, 0, 52)
PlayBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
PlayBtn.Text = "▶"
PlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayBtn.TextSize = 10
PlayBtn.Font = Enum.Font.GothamBold
PlayBtn.Parent = PlayerBar

local PlayCorner = Instance.new("UICorner")
PlayCorner.CornerRadius = UDim.new(0, 5)
PlayCorner.Parent = PlayBtn

local NextBtn = Instance.new("TextButton")
NextBtn.Size = UDim2.new(0, 24, 0, 24)
NextBtn.Position = UDim2.new(0, 64, 0, 52)
NextBtn.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
NextBtn.Text = "⏭"
NextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
NextBtn.TextSize = 10
NextBtn.Font = Enum.Font.GothamBold
NextBtn.Parent = PlayerBar

local NextCorner = Instance.new("UICorner")
NextCorner.CornerRadius = UDim.new(0, 5)
NextCorner.Parent = NextBtn

local StopBtn = Instance.new("TextButton")
StopBtn.Size = UDim2.new(0, 24, 0, 24)
StopBtn.Position = UDim2.new(0, 92, 0, 52)
StopBtn.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
StopBtn.Text = "◼"
StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StopBtn.TextSize = 9
StopBtn.Font = Enum.Font.GothamBold
StopBtn.Parent = PlayerBar

local StopCorner = Instance.new("UICorner")
StopCorner.CornerRadius = UDim.new(0, 5)
StopCorner.Parent = StopBtn

local LoopBtn = Instance.new("TextButton")
LoopBtn.Size = UDim2.new(0, 24, 0, 24)
LoopBtn.Position = UDim2.new(0, 120, 0, 52)
LoopBtn.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
LoopBtn.Text = "🔁"
LoopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LoopBtn.TextSize = 10
LoopBtn.Font = Enum.Font.GothamBold
LoopBtn.Parent = PlayerBar

local LoopCorner = Instance.new("UICorner")
LoopCorner.CornerRadius = UDim.new(0, 5)
LoopCorner.Parent = LoopBtn

local ShuffleBtn = Instance.new("TextButton")
ShuffleBtn.Size = UDim2.new(0, 24, 0, 24)
ShuffleBtn.Position = UDim2.new(0, 148, 0, 52)
ShuffleBtn.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
ShuffleBtn.Text = "🔀"
ShuffleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ShuffleBtn.TextSize = 10
ShuffleBtn.Font = Enum.Font.GothamBold
ShuffleBtn.Parent = PlayerBar

local ShuffleCorner = Instance.new("UICorner")
ShuffleCorner.CornerRadius = UDim.new(0, 5)
ShuffleCorner.Parent = ShuffleBtn

-- Time Label
local TimeLabel = Instance.new("TextLabel")
TimeLabel.Size = UDim2.new(0, 75, 0, 12)
TimeLabel.Position = UDim2.new(1, -210, 0, 48)
TimeLabel.BackgroundTransparency = 1
TimeLabel.Text = "00:00/00:00"
TimeLabel.TextColor3 = Color3.fromRGB(150, 170, 200)
TimeLabel.TextSize = 8
TimeLabel.Font = Enum.Font.Gotham
TimeLabel.TextXAlignment = Enum.TextXAlignment.Right
TimeLabel.Parent = PlayerBar

-- Volume Section
local VolIcon = Instance.new("TextLabel")
VolIcon.Size = UDim2.new(0, 14, 0, 24)
VolIcon.Position = UDim2.new(1, -128, 0, 52)
VolIcon.BackgroundTransparency = 1
VolIcon.Text = "🔊"
VolIcon.TextSize = 10
VolIcon.Parent = PlayerBar

local VolBg = Instance.new("TextButton")
VolBg.Size = UDim2.new(0, 70, 0, 5)
VolBg.Position = UDim2.new(1, -110, 0, 61)
VolBg.BackgroundColor3 = Color3.fromRGB(35, 48, 70)
VolBg.Text = ""
VolBg.Parent = PlayerBar

local VolBgCorner = Instance.new("UICorner")
VolBgCorner.CornerRadius = UDim.new(1, 0)
VolBgCorner.Parent = VolBg

local VolFill = Instance.new("Frame")
VolFill.Size = UDim2.new(0.5, 0, 1, 0)
VolFill.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
VolFill.BorderSizePixel = 0
VolFill.Parent = VolBg

local VolInputBox = Instance.new("TextBox")
VolInputBox.Size = UDim2.new(0, 32, 0, 20)
VolInputBox.Position = UDim2.new(1, -36, 0, 54)
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
-- 7. MODAL KONFIRMASI HAPUS
--------------------------------------------------------------------------------
local ConfirmOverlay = Instance.new("TextButton")
ConfirmOverlay.Size = UDim2.new(1, 0, 1, 0)
ConfirmOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ConfirmOverlay.BackgroundTransparency = 0.4
ConfirmOverlay.AutoButtonColor = false
ConfirmOverlay.Text = ""
ConfirmOverlay.Visible = false
ConfirmOverlay.ZIndex = 1000
ConfirmOverlay.Parent = MainFrame

local ConfirmModal = Instance.new("Frame")
ConfirmModal.Size = UDim2.new(0, 260, 0, 120)
ConfirmModal.Position = UDim2.new(0.5, -130, 0.5, -60)
ConfirmModal.BackgroundColor3 = Color3.fromRGB(20, 28, 42)
ConfirmModal.ZIndex = 1001
ConfirmModal.Parent = ConfirmOverlay

local ConfirmCorner = Instance.new("UICorner")
ConfirmCorner.CornerRadius = UDim.new(0, 8)
ConfirmCorner.Parent = ConfirmModal

local ConfirmTitle = Instance.new("TextLabel")
ConfirmTitle.Size = UDim2.new(1, -20, 0, 20)
ConfirmTitle.Position = UDim2.new(0, 10, 0, 10)
ConfirmTitle.BackgroundTransparency = 1
ConfirmTitle.Text = "⚠️ Konfirmasi Hapus"
ConfirmTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
ConfirmTitle.TextSize = 11
ConfirmTitle.Font = Enum.Font.GothamBold
ConfirmTitle.ZIndex = 1002
ConfirmTitle.Parent = ConfirmModal

local ConfirmDesc = Instance.new("TextLabel")
ConfirmDesc.Size = UDim2.new(1, -20, 0, 36)
ConfirmDesc.Position = UDim2.new(0, 10, 0, 32)
ConfirmDesc.BackgroundTransparency = 1
ConfirmDesc.Text = "Apakah Anda yakin ingin menghapus lagu ini secara permanen dari perangkat?"
ConfirmDesc.TextColor3 = Color3.fromRGB(200, 210, 230)
ConfirmDesc.TextSize = 9
ConfirmDesc.Font = Enum.Font.Gotham
ConfirmDesc.TextWrapped = true
ConfirmDesc.ZIndex = 1002
ConfirmDesc.Parent = ConfirmModal

local CancelBtn = Instance.new("TextButton")
CancelBtn.Size = UDim2.new(0, 100, 0, 26)
CancelBtn.Position = UDim2.new(0, 20, 1, -34)
CancelBtn.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
CancelBtn.Text = "Batal"
CancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CancelBtn.TextSize = 10
CancelBtn.Font = Enum.Font.GothamBold
CancelBtn.ZIndex = 1002
CancelBtn.Parent = ConfirmModal

local CancelCorner = Instance.new("UICorner")
CancelCorner.CornerRadius = UDim.new(0, 5)
CancelCorner.Parent = CancelBtn

local ConfirmDeleteBtn = Instance.new("TextButton")
ConfirmDeleteBtn.Size = UDim2.new(0, 100, 0, 26)
ConfirmDeleteBtn.Position = UDim2.new(1, -120, 1, -34)
ConfirmDeleteBtn.BackgroundColor3 = Color3.fromRGB(190, 40, 50)
ConfirmDeleteBtn.Text = "Hapus"
ConfirmDeleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ConfirmDeleteBtn.TextSize = 10
ConfirmDeleteBtn.Font = Enum.Font.GothamBold
ConfirmDeleteBtn.ZIndex = 1002
ConfirmDeleteBtn.Parent = ConfirmModal

local ConfirmDelCorner = Instance.new("UICorner")
ConfirmDelCorner.CornerRadius = UDim.new(0, 5)
ConfirmDelCorner.Parent = ConfirmDeleteBtn

--------------------------------------------------------------------------------
-- 8. ANIMASI SKELETON LOADING
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
-- 9. TAB NAVIGATION
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
-- 10. AUDIO ENGINE & SCRUBBING
--------------------------------------------------------------------------------
local writefileFn = writefile or (syn and syn.writefile)
local readfileFn = readfile or (syn and syn.readfile)
local isfileFn = isfile or (syn and syn.isfile)
local delfileFn = delfile or (syn and syn.delfile)
local getcustomassetFn = getcustomasset or getsynasset or (syn and syn.getcustomasset)

local currentLocalIndex = 1
local isPlaylistMode = false
local isShuffleMode = false

-- Riwayat shuffle: lagu yang sudah diputar putaran ini tidak dipilih lagi
-- sampai semua lagu lain sudah diputar.
local shufflePlayed = {}

local function ResetShuffleHistory()
    shufflePlayed = {}
end

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

-- Ping Loop
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

local CurrentSound = Instance.new("Sound")
CurrentSound.Name = "NavySpotifySound"
CurrentSound.Volume = 1
CurrentSound.Parent = SoundService

RunService.RenderStepped:Connect(function()
    if CurrentSound.IsPlaying and CurrentSound.TimeLength > 0 then
        local alpha = math.clamp(CurrentSound.TimePosition / CurrentSound.TimeLength, 0, 1)
        ProgressFill.Size = UDim2.new(alpha, 0, 1, 0)
        local m1, s1 = math.floor(CurrentSound.TimePosition / 60), math.floor(CurrentSound.TimePosition % 60)
        local m2, s2 = math.floor(CurrentSound.TimeLength / 60), math.floor(CurrentSound.TimeLength % 60)
        TimeLabel.Text = string.format("%02d:%02d/%02d:%02d", m1, s1, m2, s2)
    elseif not CurrentSound.IsPlaying and CurrentSound.TimePosition == 0 then
        ProgressFill.Size = UDim2.new(0, 0, 1, 0)
    end
end)

local PlayLocalTrackIndex -- forward decl
local PickShuffleIndex -- forward decl

CurrentSound.Ended:Connect(function()
    PlayBtn.Text = "▶"
    PlayerStatusLabel.Text = "Status: Selesai"
    
    if isPlaylistMode then
        local playlist = LoadLocalPlaylist()
        if #playlist > 0 then
            if isShuffleMode then
                currentLocalIndex = PickShuffleIndex(playlist)
            else
                currentLocalIndex = currentLocalIndex + 1
                if currentLocalIndex > #playlist then 
                    currentLocalIndex = 1 
                end
            end
            PlayLocalTrackIndex(currentLocalIndex)
        end
    end
end)

PickShuffleIndex = function(playlist)
    local total = #playlist
    if total <= 1 then return 1 end

    local currentItem = playlist[currentLocalIndex]
    local currentKey = currentItem and (currentItem.id or currentItem.fileName)

    local function collect()
        local list = {}
        for i, item in ipairs(playlist) do
            local key = item.id or item.fileName
            if i ~= currentLocalIndex and key ~= currentKey and not shufflePlayed[key] then
                table.insert(list, i)
            end
        end
        return list
    end

    local candidates = collect()
    if #candidates == 0 then
        -- semua lagu sudah diputar: mulai putaran baru (lagu sekarang tetap dikecualikan)
        shufflePlayed = {}
        if currentKey then shufflePlayed[currentKey] = true end
        candidates = collect()
    end
    if #candidates == 0 then
        return (currentLocalIndex % total) + 1
    end
    return candidates[math.random(1, #candidates)]
end

PlayLocalTrackIndex = function(index)
    local playlist = LoadLocalPlaylist()
    if #playlist > 0 and playlist[index] then
        currentLocalIndex = index
        local item = playlist[index]
        shufflePlayed[item.id or item.fileName] = true
        
        TrackTitle.Text = "🎵 " .. item.title
        
        if isfileFn and isfileFn(item.fileName) then
            PlayerStatusLabel.Text = "Status: 📂 Memuat file..."
            local assetUrl = getcustomassetFn(item.fileName)
            
            CurrentSound:Stop()
            CurrentSound.TimePosition = 0
            CurrentSound.SoundId = assetUrl
            
            task.wait(0.1)
            CurrentSound:Play()
            PlayBtn.Text = "⏸"
            PlayerStatusLabel.Text = "Status: 🟢 Memutar Lagu Lokal"
        else
            PlayerStatusLabel.Text = "Status: ❌ File lokal hilang!"
        end
    end
end

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

NextBtn.MouseButton1Click:Connect(function()
    local playlist = LoadLocalPlaylist()
    if #playlist > 0 then
        isPlaylistMode = true
        if isShuffleMode then
            currentLocalIndex = PickShuffleIndex(playlist)
        else
            currentLocalIndex = (currentLocalIndex % #playlist) + 1
        end
        PlayLocalTrackIndex(currentLocalIndex)
    end
end)

PrevBtn.MouseButton1Click:Connect(function()
    local playlist = LoadLocalPlaylist()
    if #playlist > 0 then
        isPlaylistMode = true
        currentLocalIndex = currentLocalIndex - 1
        if currentLocalIndex < 1 then currentLocalIndex = #playlist end
        PlayLocalTrackIndex(currentLocalIndex)
    end
end)

LoopBtn.MouseButton1Click:Connect(function()
    CurrentSound.Looped = not CurrentSound.Looped
    LoopBtn.BackgroundColor3 = CurrentSound.Looped and Color3.fromRGB(41, 158, 239) or Color3.fromRGB(40, 52, 75)
end)

-- SCRUBBING FIX
local isSeeking = false
local wasPlayingBeforeSeek = false

local function UpdateSeekPosition(input)
    if CurrentSound.TimeLength > 0 then
        local absPos = ProgressBg.AbsolutePosition.X
        local absSize = ProgressBg.AbsoluteSize.X
        local clickX = input.Position.X
        local alpha = math.clamp((clickX - absPos) / absSize, 0, 1)
        CurrentSound.TimePosition = alpha * CurrentSound.TimeLength
        ProgressFill.Size = UDim2.new(alpha, 0, 1, 0)
    end
end

ProgressBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isSeeking = true
        wasPlayingBeforeSeek = CurrentSound.IsPlaying
        if wasPlayingBeforeSeek then
            CurrentSound:Pause()
        end
        UpdateSeekPosition(input)
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                if isSeeking then
                    isSeeking = false
                    if wasPlayingBeforeSeek then
                        CurrentSound:Resume()
                        PlayBtn.Text = "⏸"
                    end
                end
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isSeeking and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateSeekPosition(input)
    end
end)

-- Volume Dragging
local settingVol = false

local function UpdateVol(input)
    local alpha = math.clamp((input.Position.X - VolBg.AbsolutePosition.X) / VolBg.AbsoluteSize.X, 0, 1)
    VolFill.Size = UDim2.new(alpha, 0, 1, 0)
    local volVal = alpha * 2
    CurrentSound.Volume = volVal
    VolInputBox.Text = tostring(math.floor(volVal * 100))
end

VolBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        settingVol = true
        UpdateVol(input)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if settingVol and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateVol(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        settingVol = false
    end
end)

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
-- 11. RENDER LOCAL PLAYLIST & DIALOG KONFIRMASI HAPUS
--------------------------------------------------------------------------------
local RenderLocalPlaylist
local pendingDeleteIndex = nil

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
            isPlaylistMode = true
            ResetShuffleHistory()
            PlayLocalTrackIndex(idx)
        end)
        
        DeleteBtn.MouseButton1Click:Connect(function()
            pendingDeleteIndex = idx
            ConfirmOverlay.Visible = true
        end)
    end
end

CancelBtn.MouseButton1Click:Connect(function()
    pendingDeleteIndex = nil
    ConfirmOverlay.Visible = false
end)

ConfirmDeleteBtn.MouseButton1Click:Connect(function()
    if pendingDeleteIndex then
        local playlist = LoadLocalPlaylist()
        local item = playlist[pendingDeleteIndex]
        if item then
            if delfileFn and isfileFn and isfileFn(item.fileName) then
                pcall(function() delfileFn(item.fileName) end)
            end
            table.remove(playlist, pendingDeleteIndex)
            SaveLocalPlaylist(playlist)
            RenderLocalPlaylist()
            PlayerStatusLabel.Text = "Status: 🗑️ Lagu dihapus dari lokal"
        end
        pendingDeleteIndex = nil
    end
    ConfirmOverlay.Visible = false
end)

ShuffleBtn.MouseButton1Click:Connect(function()
    isShuffleMode = not isShuffleMode
    ResetShuffleHistory()
    ShuffleBtn.BackgroundColor3 = isShuffleMode and Color3.fromRGB(41, 158, 239) or Color3.fromRGB(40, 52, 75)
end)

--------------------------------------------------------------------------------
-- 12. DOWNLOAD & SEARCH
--------------------------------------------------------------------------------
local function PlayAndSaveTrack(id, name)
    SearchStatusLabel.Text = "Status Pencarian: ⏳ Mendownload " .. name .. "..."
    SearchStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
    isPlaylistMode = false
    
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
                SearchStatusLabel.Text = "Status Pencarian: 💾 Menyimpan file lokal..."
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
                
                TrackTitle.Text = "🎵 " .. name
                local assetUrl = getcustomassetFn(safeLocalFileName)
                CurrentSound:Stop()
                CurrentSound.TimePosition = 0
                CurrentSound.SoundId = assetUrl
                task.wait(0.2)
                CurrentSound:Play()
                PlayBtn.Text = "⏸"
                
                PlayerStatusLabel.Text = "Status: 🟢 Memutar Musik Baru"
                SearchStatusLabel.Text = "Status Pencarian: 🟢 Berhasil terdownload & disimpan!"
                SearchStatusLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
            else
                SearchStatusLabel.Text = "Status Pencarian: ❌ Gagal memproses server"
                SearchStatusLabel.TextColor3 = Color3.fromRGB(240, 80, 80)
            end
        else
            SearchStatusLabel.Text = "Status Pencarian: ❌ Koneksi server gagal"
            SearchStatusLabel.TextColor3 = Color3.fromRGB(240, 80, 80)
        end
    end)
end

local function ExecuteSearch()
    if SearchBox.Text == "" then return end
    
    ShowSkeletonLoading(SearchScroll)
    SearchStatusLabel.Text = "Status Pencarian: ⏳ Mencari lagu di YouTube..."
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
                SearchStatusLabel.Text = string.format("Status Pencarian: 🟢 Ditemukan %d lagu", #data.results)
                SearchStatusLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
            else
                SearchStatusLabel.Text = "Status Pencarian: ⚠️ Lagu tidak ditemukan!"
                SearchStatusLabel.TextColor3 = Color3.fromRGB(240, 80, 80)
            end
        else
            SearchStatusLabel.Text = "Status Pencarian: ❌ Server tidak merespons!"
            SearchStatusLabel.TextColor3 = Color3.fromRGB(240, 80, 80)
        end
    end)
end

SearchBtn.MouseButton1Click:Connect(ExecuteSearch)
SearchBox.FocusLost:Connect(ExecuteSearch)

RenderLocalPlaylist()
