-- Spotify Navy Premium Music Player (Full Features & Universal Support)
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

--------------------------------------------------------------------------------
-- 1. KONFIGURASI SERVER CLOUDFLARE TUNNEL
--------------------------------------------------------------------------------
local SERVER_URL = "https://till-however-arts-zinc.trycloudflare.com"

if PlayerGui:FindFirstChild("NavySpotifyUI") then
    PlayerGui.NavySpotifyUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NavySpotifyUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999
ScreenGui.Parent = PlayerGui

--------------------------------------------------------------------------------
-- 2. MAIN FRAME & HEADER INFORMATIF
--------------------------------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 480)
MainFrame.Position = UDim2.new(0.5, -200, 0.3, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(40, 55, 80)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Header Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -120, 0, 30)
Title.Position = UDim2.new(0, 16, 0, 6)
Title.BackgroundTransparency = 1
Title.Text = "🎵 Spotify Navy Dashboard"
Title.TextColor3 = Color3.fromRGB(240, 245, 255)
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- Status Server & Ping Indicator (Fitur Lama Dikembalikan!)
local ServerStatusLabel = Instance.new("TextLabel")
ServerStatusLabel.Size = UDim2.new(1, -32, 0, 16)
ServerStatusLabel.Position = UDim2.new(0, 16, 0, 32)
ServerStatusLabel.BackgroundTransparency = 1
ServerStatusLabel.Text = "Status: 🟡 Memeriksa Koneksi..."
ServerStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
ServerStatusLabel.TextSize = 10
ServerStatusLabel.Font = Enum.Font.Gotham
ServerStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
ServerStatusLabel.Parent = MainFrame

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 26, 0, 26)
MinBtn.Position = UDim2.new(1, -36, 0, 8)
MinBtn.BackgroundColor3 = Color3.fromRGB(28, 38, 56)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 16
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = MainFrame

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1, 0)
MinCorner.Parent = MinBtn

-- Floating Toggle Icon
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 48, 0, 48)
ToggleBtn.Position = UDim2.new(0, 15, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
ToggleBtn.Text = "🎵"
ToggleBtn.TextSize = 22
ToggleBtn.Active = true
ToggleBtn.Draggable = true
ToggleBtn.Visible = false
ToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleBtn

--------------------------------------------------------------------------------
-- 3. KOTAK PENCARIAN & TOMBOL CARI
--------------------------------------------------------------------------------
local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -95, 0, 36)
SearchBox.Position = UDim2.new(0, 16, 0, 54)
SearchBox.BackgroundColor3 = Color3.fromRGB(22, 30, 45)
SearchBox.PlaceholderText = "Cari judul lagu atau artis..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(120, 135, 165)
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.TextSize = 12
SearchBox.Font = Enum.Font.Gotham
SearchBox.Parent = MainFrame

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 10)
SearchCorner.Parent = SearchBox

local SearchBtn = Instance.new("TextButton")
SearchBtn.Size = UDim2.new(0, 60, 0, 36)
SearchBtn.Position = UDim2.new(1, -76, 0, 54)
SearchBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
SearchBtn.Text = "Cari"
SearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBtn.TextSize = 12
SearchBtn.Font = Enum.Font.GothamBold
SearchBtn.Parent = MainFrame

local SearchBtnCorner = Instance.new("UICorner")
SearchBtnCorner.CornerRadius = UDim.new(0, 10)
SearchBtnCorner.Parent = SearchBtn

--------------------------------------------------------------------------------
-- 4. SECTION 1: DAFTAR PENCARIAN LAGU (SCROLLING LIST)
--------------------------------------------------------------------------------
local ListSectionLabel = Instance.new("TextLabel")
ListSectionLabel.Size = UDim2.new(1, -32, 0, 18)
ListSectionLabel.Position = UDim2.new(0, 16, 0, 98)
ListSectionLabel.BackgroundTransparency = 1
ListSectionLabel.Text = "📁 HASIL PENCARIAN (Klik lagu untuk memutar):"
ListSectionLabel.TextColor3 = Color3.fromRGB(140, 160, 190)
ListSectionLabel.TextSize = 10
ListSectionLabel.Font = Enum.Font.GothamBold
ListSectionLabel.TextXAlignment = Enum.TextXAlignment.Left
ListSectionLabel.Parent = MainFrame

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -32, 0, 180)
ScrollFrame.Position = UDim2.new(0, 16, 0, 118)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(18, 24, 38)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.Parent = MainFrame

local ScrollCorner = Instance.new("UICorner")
ScrollCorner.CornerRadius = UDim.new(0, 10)
ScrollCorner.Parent = ScrollFrame

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 6)
UIList.Parent = ScrollFrame

local UIPadding = Instance.new("UIPadding")
UIPadding.PaddingTop = UDim.new(0, 6)
UIPadding.PaddingBottom = UDim.new(0, 6)
UIPadding.PaddingLeft = UDim.new(0, 6)
UIPadding.PaddingRight = UDim.new(0, 6)
UIPadding.Parent = ScrollFrame

--------------------------------------------------------------------------------
-- 5. SECTION 2: ACTIVE PLAYER PANEL (PEMUTAR AUDIO AKTIF)
--------------------------------------------------------------------------------
local PlayerSectionLabel = Instance.new("TextLabel")
PlayerSectionLabel.Size = UDim2.new(1, -32, 0, 18)
PlayerSectionLabel.Position = UDim2.new(0, 16, 0, 310)
PlayerSectionLabel.BackgroundTransparency = 1
PlayerSectionLabel.Text = "🎧 PEMUTAR AUDIO AKTIF (Active Player):"
PlayerSectionLabel.TextColor3 = Color3.fromRGB(41, 158, 239)
PlayerSectionLabel.TextSize = 10
PlayerSectionLabel.Font = Enum.Font.GothamBold
PlayerSectionLabel.TextXAlignment = Enum.TextXAlignment.Left
PlayerSectionLabel.Parent = MainFrame

local PlayerBar = Instance.new("Frame")
PlayerBar.Size = UDim2.new(1, -32, 0, 130)
PlayerBar.Position = UDim2.new(0, 16, 0, 330)
PlayerBar.BackgroundColor3 = Color3.fromRGB(22, 30, 46)
PlayerBar.Parent = MainFrame

local PlayerCorner = Instance.new("UICorner")
PlayerCorner.CornerRadius = UDim.new(0, 12)
PlayerCorner.Parent = PlayerBar

local PlayerStroke = Instance.new("UIStroke")
PlayerStroke.Color = Color3.fromRGB(41, 158, 239)
PlayerStroke.Transparency = 0.4
PlayerStroke.Thickness = 1
PlayerStroke.Parent = PlayerBar

-- Status Track / Judul Lagu
local TrackTitle = Instance.new("TextLabel")
TrackTitle.Size = UDim2.new(1, -20, 0, 22)
TrackTitle.Position = UDim2.new(0, 10, 0, 8)
TrackTitle.BackgroundTransparency = 1
TrackTitle.Text = "Belum ada lagu yang diputar"
TrackTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
TrackTitle.TextSize = 11
TrackTitle.Font = Enum.Font.GothamBold
TrackTitle.TextTruncate = Enum.TextTruncate.AtEnd
TrackTitle.TextXAlignment = Enum.TextXAlignment.Left
TrackTitle.Parent = PlayerBar

-- Status Detail Progress
local StatusDetail = Instance.new("TextLabel")
StatusDetail.Size = UDim2.new(1, -20, 0, 14)
StatusDetail.Position = UDim2.new(0, 10, 0, 30)
StatusDetail.BackgroundTransparency = 1
StatusDetail.Text = "Status: Standby"
StatusDetail.TextColor3 = Color3.fromRGB(140, 160, 190)
StatusDetail.TextSize = 9
StatusDetail.Font = Enum.Font.Gotham
StatusDetail.TextXAlignment = Enum.TextXAlignment.Left
StatusDetail.Parent = PlayerBar

-- Progress Bar Background
local ProgressBg = Instance.new("Frame")
ProgressBg.Size = UDim2.new(1, -20, 0, 5)
ProgressBg.Position = UDim2.new(0, 10, 0, 50)
ProgressBg.BackgroundColor3 = Color3.fromRGB(35, 48, 70)
ProgressBg.BorderSizePixel = 0
ProgressBg.Parent = PlayerBar

local ProgressBgCorner = Instance.new("UICorner")
ProgressBgCorner.CornerRadius = UDim.new(1, 0)
ProgressBgCorner.Parent = ProgressBg

-- Progress Bar Fill
local ProgressFill = Instance.new("Frame")
ProgressFill.Size = UDim2.new(0, 0, 1, 0)
ProgressFill.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
ProgressFill.BorderSizePixel = 0
ProgressFill.Parent = ProgressBg

local ProgressFillCorner = Instance.new("UICorner")
ProgressFillCorner.CornerRadius = UDim.new(1, 0)
ProgressFillCorner.Parent = ProgressFill

-- Time Labels
local TimeLabel = Instance.new("TextLabel")
TimeLabel.Size = UDim2.new(1, -20, 0, 14)
TimeLabel.Position = UDim2.new(0, 10, 0, 58)
TimeLabel.BackgroundTransparency = 1
TimeLabel.Text = "00:00 / 00:00"
TimeLabel.TextColor3 = Color3.fromRGB(150, 170, 200)
TimeLabel.TextSize = 10
TimeLabel.Font = Enum.Font.Gotham
TimeLabel.TextXAlignment = Enum.TextXAlignment.Right
TimeLabel.Parent = PlayerBar

-- Tombol Kontrol (Play, Stop, Loop)
local PlayBtn = Instance.new("TextButton")
PlayBtn.Size = UDim2.new(0, 38, 0, 38)
PlayBtn.Position = UDim2.new(0, 10, 0, 80)
PlayBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
PlayBtn.Text = "▶"
PlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayBtn.TextSize = 14
PlayBtn.Font = Enum.Font.GothamBold
PlayBtn.Parent = PlayerBar

local PlayCorner = Instance.new("UICorner")
PlayCorner.CornerRadius = UDim.new(0, 8)
PlayCorner.Parent = PlayBtn

local StopBtn = Instance.new("TextButton")
StopBtn.Size = UDim2.new(0, 38, 0, 38)
StopBtn.Position = UDim2.new(0, 54, 0, 80)
StopBtn.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
StopBtn.Text = "◼"
StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StopBtn.TextSize = 12
StopBtn.Font = Enum.Font.GothamBold
StopBtn.Parent = PlayerBar

local StopCorner = Instance.new("UICorner")
StopCorner.CornerRadius = UDim.new(0, 8)
StopCorner.Parent = StopBtn

local LoopBtn = Instance.new("TextButton")
LoopBtn.Size = UDim2.new(0, 38, 0, 38)
LoopBtn.Position = UDim2.new(0, 98, 0, 80)
LoopBtn.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
LoopBtn.Text = "🔁"
LoopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LoopBtn.TextSize = 13
LoopBtn.Font = Enum.Font.GothamBold
LoopBtn.Parent = PlayerBar

local LoopCorner = Instance.new("UICorner")
LoopCorner.CornerRadius = UDim.new(0, 8)
LoopCorner.Parent = LoopBtn

-- Volume Slider
local VolIcon = Instance.new("TextLabel")
VolIcon.Size = UDim2.new(0, 20, 0, 38)
VolIcon.Position = UDim2.new(1, -125, 0, 80)
VolIcon.BackgroundTransparency = 1
VolIcon.Text = "🔊"
VolIcon.TextSize = 13
VolIcon.Parent = PlayerBar

local VolBg = Instance.new("TextButton")
VolBg.Size = UDim2.new(0, 90, 0, 6)
VolBg.Position = UDim2.new(1, -100, 0, 96)
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
-- 6. TOAST NOTIFICATION SYSTEM (FITUR LAMA DIKEMBALIKAN!)
--------------------------------------------------------------------------------
local function ShowToast(message, isError)
    local Toast = Instance.new("Frame")
    Toast.Size = UDim2.new(0, 280, 0, 32)
    Toast.Position = UDim2.new(0.5, -140, 0.9, 0)
    Toast.BackgroundColor3 = isError and Color3.fromRGB(180, 40, 50) or Color3.fromRGB(30, 140, 90)
    Toast.Parent = ScreenGui

    local ToastCorner = Instance.new("UICorner")
    ToastCorner.CornerRadius = UDim.new(0, 8)
    ToastCorner.Parent = Toast

    local ToastText = Instance.new("TextLabel")
    ToastText.Size = UDim2.new(1, -16, 1, 0)
    ToastText.Position = UDim2.new(0, 8, 0, 0)
    ToastText.BackgroundTransparency = 1
    ToastText.Text = message
    ToastText.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToastText.TextSize = 11
    ToastText.Font = Enum.Font.GothamBold
    ToastText.Parent = Toast

    task.delay(3, function()
        if Toast then Toast:Destroy() end
    end)
end

--------------------------------------------------------------------------------
-- 7. HELPER REQUEST & CROSS-PLATFORM EXECUTOR COMPATIBILITY
--------------------------------------------------------------------------------
local writefileFn = writefile or (syn and syn.writefile)
local getcustomassetFn = getcustomasset or getsynasset or (syn and syn.getcustomasset)

local function customRequest(reqData)
    local req = (syn and syn.request) or request or http_request or (http and http.request)
    if not req then return nil end
    reqData.Headers = reqData.Headers or {}
    reqData.Headers["bypass-tunnel-reminder"] = "true"
    local success, response = pcall(function() return req(reqData) end)
    if not success then return nil end
    return response
end

-- Check Server Status Loop
task.spawn(function()
    while task.wait(5) do
        local startTime = os.clock()
        local res = customRequest({ Url = SERVER_URL .. "/api/status", Method = "GET" })
        local latency = math.floor((os.clock() - startTime) * 1000)
        
        if res and res.StatusCode == 200 then
            ServerStatusLabel.Text = string.format("Status: 🟢 Connected (%d ms)", latency)
            ServerStatusLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
        else
            ServerStatusLabel.Text = "Status: 🔴 Server Disconnected!"
            ServerStatusLabel.TextColor3 = Color3.fromRGB(240, 80, 80)
        end
    end
end)

--------------------------------------------------------------------------------
-- 8. LOGIKA AUDIO SOUNDSERVICE
--------------------------------------------------------------------------------
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
            StatusDetail.Text = "Status: Diberhentikan Sementara (Paused)"
        else
            CurrentSound:Play()
            PlayBtn.Text = "⏸"
            StatusDetail.Text = "Status: Memutar Musik..."
        end
    end
end)

StopBtn.MouseButton1Click:Connect(function()
    CurrentSound:Stop()
    CurrentSound.TimePosition = 0
    PlayBtn.Text = "▶"
    ProgressFill.Size = UDim2.new(0, 0, 1, 0)
    StatusDetail.Text = "Status: Dihentikan (Stopped)"
end)

LoopBtn.MouseButton1Click:Connect(function()
    CurrentSound.Looped = not CurrentSound.Looped
    if CurrentSound.Looped then
        LoopBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
        ShowToast("🔁 Loop Mode Aktif", false)
    else
        LoopBtn.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
        ShowToast("🔁 Loop Mode Nonaktif", false)
    end
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
-- 9. LOGIKA SEARCH & PLAY TRACK (DENGAN DETAIL LOGGING)
--------------------------------------------------------------------------------
local function PlayTrack(id, name)
    TrackTitle.Text = "🎵 " .. name
    StatusDetail.Text = "Status: ⏳ Unduh dari YouTube via Node.js..."
    PlayBtn.Text = "⏳"
    ShowToast("Proses mengunduh lagu...", false)
    
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
                StatusDetail.Text = "Status: 📥 Menyiapkan file audio lokal..."
                
                local streamUrl = SERVER_URL .. "/stream/" .. data.fileName
                local audioBinary = game:HttpGet(streamUrl)
                
                local localFileName = "navyspotify_play.mp3"
                if writefileFn then
                    writefileFn(localFileName, audioBinary)
                end
                
                local assetUrl = ""
                if getcustomassetFn then
                    assetUrl = getcustomassetFn(localFileName)
                end
                
                CurrentSound:Stop()
                CurrentSound.SoundId = assetUrl
                task.wait(0.2)
                CurrentSound:Play()
                
                PlayBtn.Text = "⏸"
                StatusDetail.Text = "Status: 🟢 Memutar Musik"
                ShowToast("Berhasil memutar lagu!", false)
            else
                StatusDetail.Text = "Status: ❌ Gagal memproses audio di server"
                PlayBtn.Text = "▶"
                ShowToast("Gagal memproses audio!", true)
            end
        else
            StatusDetail.Text = "Status: ❌ Gagal terhubung ke server"
            PlayBtn.Text = "▶"
            ShowToast("Gagal koneksi ke server!", true)
        end
    end)
end

local function ExecuteSearch()
    if SearchBox.Text == "" then return end
    
    for _, c in pairs(ScrollFrame:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
    end
    
    StatusDetail.Text = "Status: 🔍 Mencari lagu di YouTube..."
    ShowToast("Mencari lagu...", false)
    
    task.spawn(function()
        local searchUrl = SERVER_URL .. "/api/search?q=" .. HttpService:UrlEncode(SearchBox.Text)
        local res = customRequest({ Url = searchUrl, Method = "GET" })
        
        if res and res.Body then
            local success, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
            if success and data and data.success and data.results and #data.results > 0 then
                ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, (#data.results * 42) + 10)
                
                for _, song in ipairs(data.results) do
                    local Card = Instance.new("Frame")
                    Card.Size = UDim2.new(1, 0, 0, 36)
                    Card.BackgroundColor3 = Color3.fromRGB(26, 36, 54)
                    Card.Parent = ScrollFrame
                    
                    local CardCorner = Instance.new("UICorner")
                    CardCorner.CornerRadius = UDim.new(0, 8)
                    CardCorner.Parent = Card
                    
                    local SongBtn = Instance.new("TextButton")
                    SongBtn.Size = UDim2.new(1, -10, 1, 0)
                    SongBtn.Position = UDim2.new(0, 5, 0, 0)
                    SongBtn.BackgroundTransparency = 1
                    SongBtn.Text = "▶  " .. song.title .. " (" .. (song.uploader or "YouTube") .. ")"
                    SongBtn.TextColor3 = Color3.fromRGB(220, 235, 255)
                    SongBtn.TextXAlignment = Enum.TextXAlignment.Left
                    SongBtn.TextSize = 11
                    SongBtn.Font = Enum.Font.Gotham
                    SongBtn.TextTruncate = Enum.TextTruncate.AtEnd
                    SongBtn.Parent = Card
                    
                    SongBtn.MouseButton1Click:Connect(function()
                        PlayTrack(song.id, song.title)
                    end)
                end
                
                StatusDetail.Text = "Status: Ditemukan " .. #data.results .. " lagu. Pilih lagu untuk diputar."
                ShowToast("Pencarian berhasil!", false)
            else
                StatusDetail.Text = "Status: ⚠️ Lagu tidak ditemukan!"
                ShowToast("Lagu tidak ditemukan!", true)
            end
        else
            StatusDetail.Text = "Status: ❌ Gagal terhubung ke server!"
            ShowToast("Server tidak merespons!", true)
        end
    end)
end

SearchBtn.MouseButton1Click:Connect(ExecuteSearch)
SearchBox.FocusLost:Connect(ExecuteSearch)
