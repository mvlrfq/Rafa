-- Roblox Executor Spotify Player UI (Hybrid Local & Public)
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

--------------------------------------------------------------------------------
-- KONFIGURASI ALAMAT SERVER (Ubah Sesuai Kebutuhan Anda)
--------------------------------------------------------------------------------
local LOCAL_URL  = "http://192.168.1.10:3000"              -- IP Lokal PC Anda
local PUBLIC_URL = "https://your-localtunnel-domain.loca.lt" -- Domain Publik (LocalTunnel/Ngrok/VPS)

local ACTIVE_SERVER_URL = LOCAL_URL -- Default URL

--------------------------------------------------------------------------------
-- FUNGSI HTTP REQUEST COMPATIBLE
--------------------------------------------------------------------------------
local function customRequest(reqData)
    local req = (syn and syn.request) or request or http_request or (http and http.request)
    if req then
        return req(reqData)
    else
        warn("Executor tidak mendukung HTTP Request!")
        return nil
    end
end

--------------------------------------------------------------------------------
-- PENDETEKSI KONEKSI OTOMATIS (PING CHECK)
--------------------------------------------------------------------------------
local function AutoDetectServer()
    print("[Spotify UI] Memeriksa koneksi server lokal...")
    local testLocal = customRequest({ Url = LOCAL_URL .. "/api/search?q=test", Method = "GET" })
    
    if testLocal and (testLocal.StatusCode == 200 or testLocal.Body) then
        ACTIVE_SERVER_URL = LOCAL_URL
        print("[Spotify UI] Terhubung menggunakan JARINGAN LOKAL:", ACTIVE_SERVER_URL)
    else
        print("[Spotify UI] Jaringan lokal tidak merespons, beralih ke JARINGAN PUBLIK...")
        ACTIVE_SERVER_URL = PUBLIC_URL
        print("[Spotify UI] Terhubung menggunakan JARINGAN PUBLIK:", ACTIVE_SERVER_URL)
    end
end

-- Jalankan pengecekan otomatis saat script dimuat
AutoDetectServer()

--------------------------------------------------------------------------------
-- INTERFACE (GUI) SPOTIFY
--------------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpotifyHybridUI"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

-- Frame Utama
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 430)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -215)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

-- Header Status Server
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -50, 0, 35)
StatusLabel.Position = UDim2.new(0, 12, 0, 5)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Spotify Player"
StatusLabel.TextColor3 = Color3.fromRGB(30, 215, 96)
StatusLabel.TextSize = 18
StatusLabel.Font = Enum.Font.SourceSansBold
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

-- Tombol Minimize
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -38, 0, 8)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 18
MinimizeBtn.Parent = MainFrame

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 15)
MinCorner.Parent = MinimizeBtn

-- Floating Toggle Button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "SpotifyToggleBtn"
ToggleBtn.Size = UDim2.new(0, 45, 0, 45)
ToggleBtn.Position = UDim2.new(0, 15, 0.5, -22)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 215, 96)
ToggleBtn.Text = "🎵"
ToggleBtn.TextSize = 22
ToggleBtn.Visible = false
ToggleBtn.Active = true
ToggleBtn.Draggable = true
ToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleBtn

-- Kolom Pencarian
local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -24, 0, 35)
SearchBox.Position = UDim2.new(0, 12, 0, 42)
SearchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
SearchBox.PlaceholderText = "Cari lagu / artis..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.TextSize = 14
SearchBox.Font = Enum.Font.SourceSans
SearchBox.Parent = MainFrame

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 8)
SearchCorner.Parent = SearchBox

-- Scroll Frame Hasil Lagu
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -24, 0, 260)
ScrollFrame.Position = UDim2.new(0, 12, 0, 85)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 3
ScrollFrame.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.Parent = ScrollFrame

-- Bottom Player Bar
local PlayerBar = Instance.new("Frame")
PlayerBar.Size = UDim2.new(1, -24, 0, 60)
PlayerBar.Position = UDim2.new(0, 12, 1, -70)
PlayerBar.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
PlayerBar.Parent = MainFrame

local PlayerCorner = Instance.new("UICorner")
PlayerCorner.CornerRadius = UDim.new(0, 8)
PlayerCorner.Parent = PlayerBar

local TrackTitle = Instance.new("TextLabel")
TrackTitle.Size = UDim2.new(1, -60, 1, 0)
TrackTitle.Position = UDim2.new(0, 10, 0, 0)
TrackTitle.BackgroundTransparency = 1
TrackTitle.Text = "Pilih lagu..."
TrackTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
TrackTitle.TextSize = 13
TrackTitle.TextTruncate = Enum.TextTruncate.AtEnd
TrackTitle.Font = Enum.Font.SourceSansBold
TrackTitle.TextXAlignment = Enum.TextXAlignment.Left
TrackTitle.Parent = PlayerBar

local PlayPauseBtn = Instance.new("TextButton")
PlayPauseBtn.Size = UDim2.new(0, 38, 0, 38)
PlayPauseBtn.Position = UDim2.new(1, -48, 0.5, -19)
PlayPauseBtn.BackgroundColor3 = Color3.fromRGB(30, 215, 96)
PlayPauseBtn.Text = "▶"
PlayPauseBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
PlayPauseBtn.TextSize = 16
PlayPauseBtn.Parent = PlayerBar

local PlayCorner = Instance.new("UICorner")
PlayCorner.CornerRadius = UDim.new(1, 0)
PlayCorner.Parent = PlayPauseBtn

-- Audio Sound Object
local CurrentSound = Instance.new("Sound")
CurrentSound.Name = "SpotifyAudioClient"
CurrentSound.Parent = workspace

--------------------------------------------------------------------------------
-- EVENT LISTENERS & LOGIKA
--------------------------------------------------------------------------------
MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    ToggleBtn.Visible = true
end)

ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    ToggleBtn.Visible = false
end)

PlayPauseBtn.MouseButton1Click:Connect(function()
    if CurrentSound.IsPlaying then
        CurrentSound:Pause()
        PlayPauseBtn.Text = "▶"
    else
        CurrentSound:Play()
        PlayPauseBtn.Text = "⏸"
    end
end)

-- Fungsi Download & Play Audio
local function PlayTrack(videoId, title)
    TrackTitle.Text = "Mengunduh..."
    
    local body = HttpService:JSONEncode({ videoId = videoId, title = title })
    local res = customRequest({
        Url = ACTIVE_SERVER_URL .. "/api/download",
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = body
    })
    
    if res and res.Body then
        local data = HttpService:JSONDecode(res.Body)
        if data.success and data.downloadUrl then
            TrackTitle.Text = title
            
            -- Memutar audio secara streaming via URL (Kompatibel dengan Lokal & Publik)
            CurrentSound.SoundId = data.downloadUrl
            CurrentSound:Play()
            PlayPauseBtn.Text = "⏸"
        else
            TrackTitle.Text = "Gagal memuat lagu!"
        end
    else
        TrackTitle.Text = "Koneksi terputus!"
    end
end

-- Fungsi Pencarian
SearchBox.FocusLost:Connect(function(enterPressed)
    if not enterPressed or SearchBox.Text == "" then return end
    
    for _, child in pairs(ScrollFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    TrackTitle.Text = "Mencari..."
    
    local searchUrl = ACTIVE_SERVER_URL .. "/api/search?q=" .. HttpService:UrlEncode(SearchBox.Text)
    local res = customRequest({ Url = searchUrl, Method = "GET" })
    
    if res and res.Body then
        local data = HttpService:JSONDecode(res.Body)
        if data.success and data.results then
            ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, #data.results * 40)
            
            for _, song in ipairs(data.results) do
                local ItemBtn = Instance.new("TextButton")
                ItemBtn.Size = UDim2.new(1, -6, 0, 36)
                ItemBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                ItemBtn.Text = "  " .. song.title
                ItemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                ItemBtn.TextXAlignment = Enum.TextXAlignment.Left
                ItemBtn.TextTruncate = Enum.TextTruncate.AtEnd
                ItemBtn.Font = Enum.Font.SourceSans
                ItemBtn.TextSize = 12
                ItemBtn.Parent = ScrollFrame
                
                local ItemCorner = Instance.new("UICorner")
                ItemCorner.CornerRadius = UDim.new(0, 6)
                ItemCorner.Parent = ItemBtn
                
                ItemBtn.MouseButton1Click:Connect(function()
                    PlayTrack(song.id, song.title)
                end)
            end
            TrackTitle.Text = "Pilih lagu"
        end
    else
        TrackTitle.Text = "Gagal terhubung ke server!"
    end
end)
