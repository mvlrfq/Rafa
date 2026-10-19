-- Spotify Navy Dashboard - Universal (Android & iOS)
-- Features: Resizable UI, Bounds Guard, Separate Status, Local Cached Songs (+Delete Button), Fixed Auto-Canvas Scroll
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

--------------------------------------------------------------------------------
-- 1. KONFIGURASI SERVER
--------------------------------------------------------------------------------
local SERVER_URL = "https://till-however-arts-zinc.trycloudflare.com"
local LOCAL_JSON_FILE = "navyspotify_playlist.json"

if PlayerGui:FindFirstChild("NavySpotifyUI") then
    PlayerGui.NavySpotifyUI:Destroy()
end

--------------------------------------------------------------------------------
-- SCREEN GUI & MAIN FRAME (MAX Z-INDEX & PERSISTENT GUARD)
--------------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NavySpotifyUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999999 -- Dipastikan selalu berada di paling depan
ScreenGui.IgnoreGuiInset = true    -- Menembus batas topbar bawaan Roblox
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 420)
MainFrame.Position = UDim2.new(0.5, -170, 0.25, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = false
MainFrame.ZIndex = 999 -- ZIndex tinggi agar tidak terhalang UI lain
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(40, 55, 80)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Header Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 0, 32)
Title.Position = UDim2.new(0, 12, 0, 2)
Title.BackgroundTransparency = 1
Title.Text = "🎵 Spotify Navy Dashboard"
Title.TextColor3 = Color3.fromRGB(240, 245, 255)
Title.TextSize = 12
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 24, 0, 24)
MinBtn.Position = UDim2.new(1, -30, 0, 6)
MinBtn.BackgroundColor3 = Color3.fromRGB(28, 38, 56)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 14
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = MainFrame

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1, 0)
MinCorner.Parent = MinBtn

-- Floating Toggle Icon (Memiliki Screen Boundary Guard)
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

-- Resizing Handle (Tombol Tarik Ukuran UI)
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
-- 3. STATUS KONEKSI & PENCARIAN (BAGIAN ATAS DEKAT INPUT)
--------------------------------------------------------------------------------
local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -80, 0, 32)
SearchBox.Position = UDim2.new(0, 12, 0, 36)
SearchBox.BackgroundColor3 = Color3.fromRGB(22, 30, 45)
SearchBox.PlaceholderText = "Cari judul lagu atau artis..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(120, 135, 165)
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.TextSize = 11
SearchBox.Font = Enum.Font.Gotham
SearchBox.Parent = MainFrame

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 8)
SearchCorner.Parent = SearchBox

local SearchBtn = Instance.new("TextButton")
SearchBtn.Size = UDim2.new(0, 52, 0, 32)
SearchBtn.Position = UDim2.new(1, -64, 0, 36)
SearchBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
SearchBtn.Text = "Cari"
SearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBtn.TextSize = 11
SearchBtn.Font = Enum.Font.GothamBold
SearchBtn.Parent = MainFrame

local SearchBtnCorner = Instance.new("UICorner")
SearchBtnCorner.CornerRadius = UDim.new(0, 8)
SearchBtnCorner.Parent = SearchBtn

-- Info Status Pencarian & Server (Berada di atas, terlihat jelas oleh user)
local SearchStatusLabel = Instance.new("TextLabel")
SearchStatusLabel.Size = UDim2.new(1, -24, 0, 16)
SearchStatusLabel.Position = UDim2.new(0, 12, 0, 72)
SearchStatusLabel.BackgroundTransparency = 1
SearchStatusLabel.Text = "Status Server: 🟡 Memeriksa koneksi..."
SearchStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
SearchStatusLabel.TextSize = 9
SearchStatusLabel.Font = Enum.Font.Gotham
SearchStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
SearchStatusLabel.Parent = MainFrame

--------------------------------------------------------------------------------
-- 4. CONTAINER UTAMA DENGAN AUTO SCROLL
--------------------------------------------------------------------------------
local MainScroll = Instance.new("ScrollingFrame")
MainScroll.Size = UDim2.new(1, -24, 1, -210)
MainScroll.Position = UDim2.new(0, 12, 0, 92)
MainScroll.BackgroundTransparency = 1
MainScroll.BorderSizePixel = 0
MainScroll.ScrollBarThickness = 3
MainScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
MainScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
MainScroll.Parent = MainFrame

local MainScrollList = Instance.new("UIListLayout")
MainScrollList.Padding = UDim.new(0, 8)
MainScrollList.SortOrder = Enum.SortOrder.LayoutOrder
MainScrollList.Parent = MainScroll

-- 4A. SECTION HASIL PENCARIAN YOUTUBE
local SearchSectionHeader = Instance.new("TextLabel")
SearchSectionHeader.Size = UDim2.new(1, 0, 0, 16)
SearchSectionHeader.BackgroundTransparency = 1
SearchSectionHeader.Text = "🔍 HASIL PENCARIAN YOUTUBE:"
SearchSectionHeader.TextColor3 = Color3.fromRGB(140, 160, 190)
SearchSectionHeader.TextSize = 9
SearchSectionHeader.Font = Enum.Font.GothamBold
SearchSectionHeader.TextXAlignment = Enum.TextXAlignment.Left
SearchSectionHeader.LayoutOrder = 1
SearchSectionHeader.Parent = MainScroll

local SearchResultFrame = Instance.new("Frame")
SearchResultFrame.Size = UDim2.new(1, 0, 0, 0)
SearchResultFrame.BackgroundTransparency = 1
SearchResultFrame.AutomaticSize = Enum.AutomaticSize.Y
SearchResultFrame.LayoutOrder = 2
SearchResultFrame.Parent = MainScroll

local SearchResultList = Instance.new("UIListLayout")
SearchResultList.Padding = UDim.new(0, 4)
SearchResultList.Parent = SearchResultFrame

-- 4B. SECTION LAGU LOKAL TERSIMPAN
local LocalSectionHeader = Instance.new("TextLabel")
LocalSectionHeader.Size = UDim2.new(1, 0, 0, 16)
LocalSectionHeader.BackgroundTransparency = 1
LocalSectionHeader.Text = "💾 LAGU LOKAL TERSIMPAN (Tanpa Kuota/Download):"
LocalSectionHeader.TextColor3 = Color3.fromRGB(80, 220, 120)
LocalSectionHeader.TextSize = 9
LocalSectionHeader.Font = Enum.Font.GothamBold
LocalSectionHeader.TextXAlignment = Enum.TextXAlignment.Left
LocalSectionHeader.LayoutOrder = 3
LocalSectionHeader.Parent = MainScroll

local LocalResultFrame = Instance.new("Frame")
LocalResultFrame.Size = UDim2.new(1, 0, 0, 0)
LocalResultFrame.BackgroundTransparency = 1
LocalResultFrame.AutomaticSize = Enum.AutomaticSize.Y
LocalResultFrame.LayoutOrder = 4
LocalResultFrame.Parent = MainScroll

local LocalResultList = Instance.new("UIListLayout")
LocalResultList.Padding = UDim.new(0, 4)
LocalResultList.Parent = LocalResultFrame

--------------------------------------------------------------------------------
-- 5. ACTIVE PLAYER PANEL (BAGIAN BAWAH TERPISAH)
--------------------------------------------------------------------------------
local PlayerBar = Instance.new("Frame")
PlayerBar.Size = UDim2.new(1, -24, 0, 110)
PlayerBar.Position = UDim2.new(0, 12, 1, -118)
PlayerBar.BackgroundColor3 = Color3.fromRGB(22, 30, 46)
PlayerBar.Parent = MainFrame

local PlayerCorner = Instance.new("UICorner")
PlayerCorner.CornerRadius = UDim.new(0, 10)
PlayerCorner.Parent = PlayerBar

local PlayerStroke = Instance.new("UIStroke")
PlayerStroke.Color = Color3.fromRGB(41, 158, 239)
PlayerStroke.Transparency = 0.4
PlayerStroke.Thickness = 1
PlayerStroke.Parent = PlayerBar

local TrackTitle = Instance.new("TextLabel")
TrackTitle.Size = UDim2.new(1, -16, 0, 18)
TrackTitle.Position = UDim2.new(0, 8, 0, 6)
TrackTitle.BackgroundTransparency = 1
TrackTitle.Text = "Belum ada lagu diputar"
TrackTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
TrackTitle.TextSize = 10
TrackTitle.Font = Enum.Font.GothamBold
TrackTitle.TextTruncate = Enum.TextTruncate.AtEnd
TrackTitle.TextXAlignment = Enum.TextXAlignment.Left
TrackTitle.Parent = PlayerBar

local PlayerStatusLabel = Instance.new("TextLabel")
PlayerStatusLabel.Size = UDim2.new(1, -16, 0, 14)
PlayerStatusLabel.Position = UDim2.new(0, 8, 0, 24)
PlayerStatusLabel.BackgroundTransparency = 1
PlayerStatusLabel.Text = "Status Pemutar: Standby"
PlayerStatusLabel.TextColor3 = Color3.fromRGB(140, 160, 190)
PlayerStatusLabel.TextSize = 8
PlayerStatusLabel.Font = Enum.Font.Gotham
PlayerStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
PlayerStatusLabel.Parent = PlayerBar

local ProgressBg = Instance.new("Frame")
ProgressBg.Size = UDim2.new(1, -16, 0, 4)
ProgressBg.Position = UDim2.new(0, 8, 0, 42)
ProgressBg.BackgroundColor3 = Color3.fromRGB(35, 48, 70)
ProgressBg.BorderSizePixel = 0
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
TimeLabel.Size = UDim2.new(1, -16, 0, 12)
TimeLabel.Position = UDim2.new(0, 8, 0, 48)
TimeLabel.BackgroundTransparency = 1
TimeLabel.Text = "00:00 / 00:00"
TimeLabel.TextColor3 = Color3.fromRGB(150, 170, 200)
TimeLabel.TextSize = 8
TimeLabel.Font = Enum.Font.Gotham
TimeLabel.TextXAlignment = Enum.TextXAlignment.Right
TimeLabel.Parent = PlayerBar

local PlayBtn = Instance.new("TextButton")
PlayBtn.Size = UDim2.new(0, 32, 0, 32)
PlayBtn.Position = UDim2.new(0, 8, 0, 68)
PlayBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
PlayBtn.Text = "▶"
PlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayBtn.TextSize = 12
PlayBtn.Font = Enum.Font.GothamBold
PlayBtn.Parent = PlayerBar

local PlayCorner = Instance.new("UICorner")
PlayCorner.CornerRadius = UDim.new(0, 6)
PlayCorner.Parent = PlayBtn

local StopBtn = Instance.new("TextButton")
StopBtn.Size = UDim2.new(0, 32, 0, 32)
StopBtn.Position = UDim2.new(0, 46, 0, 68)
StopBtn.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
StopBtn.Text = "◼"
StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StopBtn.TextSize = 10
StopBtn.Font = Enum.Font.GothamBold
StopBtn.Parent = PlayerBar

local StopCorner = Instance.new("UICorner")
StopCorner.CornerRadius = UDim.new(0, 6)
StopCorner.Parent = StopBtn

local LoopBtn = Instance.new("TextButton")
LoopBtn.Size = UDim2.new(0, 32, 0, 32)
LoopBtn.Position = UDim2.new(0, 84, 0, 68)
LoopBtn.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
LoopBtn.Text = "🔁"
LoopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LoopBtn.TextSize = 11
LoopBtn.Font = Enum.Font.GothamBold
LoopBtn.Parent = PlayerBar

local LoopCorner = Instance.new("UICorner")
LoopCorner.CornerRadius = UDim.new(0, 6)
LoopCorner.Parent = LoopBtn

local VolIcon = Instance.new("TextLabel")
VolIcon.Size = UDim2.new(0, 16, 0, 32)
VolIcon.Position = UDim2.new(1, -110, 0, 68)
VolIcon.BackgroundTransparency = 1
VolIcon.Text = "🔊"
VolIcon.TextSize = 11
VolIcon.Parent = PlayerBar

local VolBg = Instance.new("TextButton")
VolBg.Size = UDim2.new(0, 80, 0, 5)
VolBg.Position = UDim2.new(1, -90, 0, 82)
VolBg.BackgroundColor3 = Color3.fromRGB(35, 48, 70)
VolBg.Text = ""
VolBg.AutoButtonColor = false
VolBg.Parent = PlayerBar

local VolBgCorner = Instance.new("UICorner")
VolBgCorner.CornerRadius = UDim.new(1, 0)
VolBgCorner.Parent = VolBg

local VolFill = Instance.new("Frame")
VolFill.Size = UDim2.new(1, 0, 1, 0)
VolFill.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
VolFill.BorderSizePixel = 0
VolFill.Parent = VolBg

local VolFillCorner = Instance.new("UICorner")
VolFillCorner.CornerRadius = UDim.new(1, 0)
VolFillCorner.Parent = VolFill

--------------------------------------------------------------------------------
-- 6. FITUR RESIZING & SCREEN BOUNDARY GUARD
--------------------------------------------------------------------------------
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
        local newWidth = math.clamp(startSize.X.Offset + delta.X, 280, 500)
        local newHeight = math.clamp(startSize.Y.Offset + delta.Y, 360, 600)
        MainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = false
    end
end)

-- Boundary Guard agar UI tidak bisa digeser ke luar layar
local function ClampToScreen(frame)
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    
    local absPos = frame.AbsolutePosition
    local absSize = frame.AbsoluteSize
    
    local clampedX = math.clamp(absPos.X, 0, math.max(0, viewport.X - absSize.X))
    local clampedY = math.clamp(absPos.Y, 0, math.max(0, viewport.Y - absSize.Y))
    
    if absPos.X ~= clampedX or absPos.Y ~= clampedY then
        frame.Position = UDim2.new(0, clampedX, 0, clampedY)
    end
end

MainFrame:GetPropertyChangedSignal("Position"):Connect(function()
    if not isResizing then ClampToScreen(MainFrame) end
end)

ToggleBtn:GetPropertyChangedSignal("Position"):Connect(function()
    ClampToScreen(ToggleBtn)
end)

--------------------------------------------------------------------------------
-- 7. EXECUTOR FILE FUNCTIONS & PLAYLIST MANAGEMENT
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
            if pSuccess and type(data) == "table" then
                return data
            end
        end
    end
    return {}
end

local function SaveLocalPlaylist(playlist)
    if writefileFn then
        pcall(function()
            writefileFn(LOCAL_JSON_FILE, HttpService:JSONEncode(playlist))
        end)
    end
end

--------------------------------------------------------------------------------
-- 8. KONEKSI CHECK & AUDIO ENGINE
--------------------------------------------------------------------------------
local function customRequest(reqData)
    local req = (syn and syn.request) or request or http_request or (http and http.request)
    if not req then return nil end
    reqData.Headers = reqData.Headers or {}
    reqData.Headers["bypass-tunnel-reminder"] = "true"
    local success, response = pcall(function() return req(reqData) end)
    if not success then return nil end
    return response
end

-- Server Health Check Loop
task.spawn(function()
    while task.wait(5) do
        local startTime = os.clock()
        local res = customRequest({ Url = SERVER_URL .. "/api/status", Method = "GET" })
        local latency = math.floor((os.clock() - startTime) * 1000)
        
        if res and res.StatusCode == 200 then
            SearchStatusLabel.Text = string.format("Status Server: 🟢 Terhubung (%d ms)", latency)
            SearchStatusLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
        else
            SearchStatusLabel.Text = "Status Server: 🔴 Terputus dari Cloudflare!"
            SearchStatusLabel.TextColor3 = Color3.fromRGB(240, 80, 80)
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

local function FormatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end

RunService.RenderStepped:Connect(function()
    if CurrentSound.IsPlaying and CurrentSound.TimeLength > 0 then
        local alpha = math.clamp(CurrentSound.TimePosition / CurrentSound.TimeLength, 0, 1)
        ProgressFill.Size = UDim2.new(alpha, 0, 1, 0)
        TimeLabel.Text = FormatTime(CurrentSound.TimePosition) .. " / " .. FormatTime(CurrentSound.TimeLength)
    elseif not CurrentSound.IsPlaying and CurrentSound.TimePosition == 0 then
        ProgressFill.Size = UDim2.new(0, 0, 1, 0)
    end
end)

PlayBtn.MouseButton1Click:Connect(function()
    if CurrentSound.SoundId ~= "" then
        if CurrentSound.IsPlaying then
            CurrentSound:Pause()
            PlayBtn.Text = "▶"
            PlayerStatusLabel.Text = "Status Pemutar: Diberhentikan (Paused)"
        else
            CurrentSound:Play()
            PlayBtn.Text = "⏸"
            PlayerStatusLabel.Text = "Status Pemutar: Memutar Musik..."
        end
    end
end)

StopBtn.MouseButton1Click:Connect(function()
    CurrentSound:Stop()
    CurrentSound.TimePosition = 0
    PlayBtn.Text = "▶"
    ProgressFill.Size = UDim2.new(0, 0, 1, 0)
    PlayerStatusLabel.Text = "Status Pemutar: Dihentikan"
end)

LoopBtn.MouseButton1Click:Connect(function()
    CurrentSound.Looped = not CurrentSound.Looped
    LoopBtn.BackgroundColor3 = CurrentSound.Looped and Color3.fromRGB(41, 158, 239) or Color3.fromRGB(40, 52, 75)
end)

-- Volume Drag Function
local settingVol = false
VolBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        settingVol = true
        local alpha = math.clamp((input.Position.X - VolBg.AbsolutePosition.X) / VolBg.AbsoluteSize.X, 0, 1)
        VolFill.Size = UDim2.new(alpha, 0, 1, 0)
        CurrentSound.Volume = alpha * 2
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if settingVol and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local alpha = math.clamp((input.Position.X - VolBg.AbsolutePosition.X) / VolBg.AbsoluteSize.X, 0, 1)
        VolFill.Size = UDim2.new(alpha, 0, 1, 0)
        CurrentSound.Volume = alpha * 2
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        settingVol = false
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
-- 9. LOGIKA TAMPILAN LAGU LOKAL TERSIMPAN & MENGHAPUS FILE
--------------------------------------------------------------------------------
local RenderLocalPlaylist -- forward declaration

RenderLocalPlaylist = function()
    for _, child in pairs(LocalResultFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local playlist = LoadLocalPlaylist()
    
    if #playlist == 0 then
        LocalSectionHeader.Text = "💾 LAGU LOKAL TERSIMPAN (Belum ada lagu lokal):"
        return
    end
    
    LocalSectionHeader.Text = string.format("💾 LAGU LOKAL TERSIMPAN (%d lagu siap diputar):", #playlist)
    
    for idx, item in ipairs(playlist) do
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, 30)
        Card.BackgroundColor3 = Color3.fromRGB(22, 34, 48)
        Card.Parent = LocalResultFrame
        
        local CardCorner = Instance.new("UICorner")
        CardCorner.CornerRadius = UDim.new(0, 6)
        CardCorner.Parent = Card
        
        local PlayLocalBtn = Instance.new("TextButton")
        PlayLocalBtn.Size = UDim2.new(1, -36, 1, 0)
        PlayLocalBtn.Position = UDim2.new(0, 6, 0, 0)
        PlayLocalBtn.BackgroundTransparency = 1
        PlayLocalBtn.Text = "🎵  " .. item.title
        PlayLocalBtn.TextColor3 = Color3.fromRGB(220, 245, 220)
        PlayLocalBtn.TextXAlignment = Enum.TextXAlignment.Left
        PlayLocalBtn.TextSize = 10
        PlayLocalBtn.Font = Enum.Font.Gotham
        PlayLocalBtn.TextTruncate = Enum.TextTruncate.AtEnd
        PlayLocalBtn.Parent = Card
        
        local DeleteBtn = Instance.new("TextButton")
        DeleteBtn.Size = UDim2.new(0, 24, 0, 22)
        DeleteBtn.Position = UDim2.new(1, -26, 0, 4)
        DeleteBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 60)
        DeleteBtn.Text = "🗑️"
        DeleteBtn.TextSize = 10
        DeleteBtn.Parent = Card
        
        local DelCorner = Instance.new("UICorner")
        DelCorner.CornerRadius = UDim.new(0, 4)
        DelCorner.Parent = DeleteBtn
        
        -- Memutar lagu lokal tanpa perlu mendownload dari server
        PlayLocalBtn.MouseButton1Click:Connect(function()
            if isfileFn and isfileFn(item.fileName) then
                TrackTitle.Text = "🎵 " .. item.title
                PlayerStatusLabel.Text = "Status Pemutar: 📂 Memuat file lokal..."
                
                local assetUrl = getcustomassetFn(item.fileName)
                CurrentSound:Stop()
                CurrentSound.SoundId = assetUrl
                task.wait(0.1)
                CurrentSound:Play()
                
                PlayBtn.Text = "⏸"
                PlayerStatusLabel.Text = "Status Pemutar: 🟢 Memutar dari Penyimpanan Lokal"
            else
                PlayerStatusLabel.Text = "Status Pemutar: ❌ File lokal hilang!"
            end
        end)
        
        -- Hapus lagu lokal
        DeleteBtn.MouseButton1Click:Connect(function()
            if delfileFn and isfileFn and isfileFn(item.fileName) then
                pcall(function() delfileFn(item.fileName) end)
            end
            table.remove(playlist, idx)
            SaveLocalPlaylist(playlist)
            RenderLocalPlaylist()
            PlayerStatusLabel.Text = "Status Pemutar: 🗑️ Lagu dihapus dari lokal"
        end)
    end
end

--------------------------------------------------------------------------------
-- 10. DOWNLOAD & PENCARIAN YOUTUBE
--------------------------------------------------------------------------------
local function PlayAndSaveTrack(id, name)
    TrackTitle.Text = "🎵 " .. name
    PlayerStatusLabel.Text = "Status Pemutar: ⏳ Mendownload dari YouTube..."
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
                PlayerStatusLabel.Text = "Status Pemutar: 💾 Menyimpan ke lokal..."
                
                local streamUrl = SERVER_URL .. "/stream/" .. data.fileName
                local audioBinary = game:HttpGet(streamUrl)
                
                local safeLocalFileName = "navy_song_" .. id .. ".mp3"
                if writefileFn then
                    writefileFn(safeLocalFileName, audioBinary)
                end
                
                -- Simpan ke Playlist JSON lokal jika belum ada
                local playlist = LoadLocalPlaylist()
                local exists = false
                for _, p in ipairs(playlist) do
                    if p.id == id then exists = true break end
                end
                
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
                PlayerStatusLabel.Text = "Status Pemutar: 🟢 Memutar Musik"
            else
                PlayerStatusLabel.Text = "Status Pemutar: ❌ Gagal memproses audio server"
                PlayBtn.Text = "▶"
            end
        else
            PlayerStatusLabel.Text = "Status Pemutar: ❌ Gagal koneksi ke server"
            PlayBtn.Text = "▶"
        end
    end)
end

local function ExecuteSearch()
    if SearchBox.Text == "" then return end
    
    for _, c in pairs(SearchResultFrame:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    
    SearchStatusLabel.Text = "Status Pencarian: 🔍 Mencari di YouTube..."
    SearchStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
    
    task.spawn(function()
        local searchUrl = SERVER_URL .. "/api/search?q=" .. HttpService:UrlEncode(SearchBox.Text)
        local res = customRequest({ Url = searchUrl, Method = "GET" })
        
        if res and res.Body then
            local success, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
            if success and data and data.success and data.results and #data.results > 0 then
                
                for _, song in ipairs(data.results) do
                    local Card = Instance.new("Frame")
                    Card.Size = UDim2.new(1, 0, 0, 30)
                    Card.BackgroundColor3 = Color3.fromRGB(26, 36, 54)
                    Card.Parent = SearchResultFrame
                    
                    local CardCorner = Instance.new("UICorner")
                    CardCorner.CornerRadius = UDim.new(0, 6)
                    CardCorner.Parent = Card
                    
                    local SongBtn = Instance.new("TextButton")
                    SongBtn.Size = UDim2.new(1, -10, 1, 0)
                    SongBtn.Position = UDim2.new(0, 5, 0, 0)
                    SongBtn.BackgroundTransparency = 1
                    SongBtn.Text = "▶  " .. song.title .. " (" .. (song.uploader or "YouTube") .. ")"
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
                
                SearchStatusLabel.Text = string.format("Status Pencarian: Ditemukan %d lagu di YouTube", #data.results)
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

-- Inisialisasi Tampilan Lagu Lokal saat pertama kali dimuat
RenderLocalPlaylist()

--------------------------------------------------------------------------------
-- PROTECTION AGAINST UI DESTRUCTION (LOADING SCREEN / TELEPORT AUTO-REPAIR)
--------------------------------------------------------------------------------
PlayerGui.ChildRemoved:Connect(function(child)
    if child.Name == "NavySpotifyUI" then
        task.wait(0.5)
        -- Jika UI terhapus oleh loading screen/game, re-parent kembali ScreenGui
        if not PlayerGui:FindFirstChild("NavySpotifyUI") then
            ScreenGui.Parent = PlayerGui
        end
    end
end)
