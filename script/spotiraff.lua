-- Spotify Navy Premium Music Player (Full Complete Code)
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

--------------------------------------------------------------------------------
-- 1. KONFIGURASI URL PUBLIC SERVER
--------------------------------------------------------------------------------
local SERVER_URL = "https://smoking-church-tomatoes-lay.trycloudflare.com"

-- Hapus UI lama jika ada
if PlayerGui:FindFirstChild("NavySpotifyUI") then
    PlayerGui.NavySpotifyUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NavySpotifyUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999
ScreenGui.Parent = PlayerGui

--------------------------------------------------------------------------------
-- 2. MAIN FRAME & HEADER
--------------------------------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 360, 0, 340)
MainFrame.Position = UDim2.new(0.5, -180, 0.35, -170)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 24, 36)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(35, 48, 72)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Header Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 0, 38)
Title.Position = UDim2.new(0, 16, 0, 2)
Title.BackgroundTransparency = 1
Title.Text = "Spotify Dashboard"
Title.TextColor3 = Color3.fromRGB(240, 244, 255)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -38, 0, 7)
MinBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 18
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = MainFrame

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1, 0)
MinCorner.Parent = MinBtn

-- Floating Toggle Icon (🎵)
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
SearchBox.Size = UDim2.new(1, -90, 0, 34)
SearchBox.Position = UDim2.new(0, 16, 0, 42)
SearchBox.BackgroundColor3 = Color3.fromRGB(26, 34, 50)
SearchBox.PlaceholderText = "Ketik judul lagu..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(130, 145, 170)
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.TextSize = 11
SearchBox.Font = Enum.Font.Gotham
SearchBox.Parent = MainFrame

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 10)
SearchCorner.Parent = SearchBox

local SearchBtn = Instance.new("TextButton")
SearchBtn.Size = UDim2.new(0, 50, 0, 34)
SearchBtn.Position = UDim2.new(1, -66, 0, 42)
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
-- 4. SCROLLING CONTAINER HASIL LAGU
--------------------------------------------------------------------------------
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -32, 1, -195)
ScrollFrame.Position = UDim2.new(0, 16, 0, 84)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(22, 29, 42)
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
-- 5. ADVANCED AUDIO PLAYER PANEL (PLAYER DENGAN PROGRESS BAR & KONTROL)
--------------------------------------------------------------------------------
local PlayerBar = Instance.new("Frame")
PlayerBar.Size = UDim2.new(1, -32, 0, 95)
PlayerBar.Position = UDim2.new(0, 16, 1, -103)
PlayerBar.BackgroundColor3 = Color3.fromRGB(26, 34, 50)
PlayerBar.Parent = MainFrame

local PlayerCorner = Instance.new("UICorner")
PlayerCorner.CornerRadius = UDim.new(0, 12)
PlayerCorner.Parent = PlayerBar

-- Track Title
local TrackTitle = Instance.new("TextLabel")
TrackTitle.Size = UDim2.new(1, -20, 0, 18)
TrackTitle.Position = UDim2.new(0, 10, 0, 6)
TrackTitle.BackgroundTransparency = 1
TrackTitle.Text = "Pilih lagu untuk diputar..."
TrackTitle.TextColor3 = Color3.fromRGB(220, 232, 255)
TrackTitle.TextSize = 11
TrackTitle.Font = Enum.Font.GothamMedium
TrackTitle.TextTruncate = Enum.TextTruncate.AtEnd
TrackTitle.TextXAlignment = Enum.TextXAlignment.Left
TrackTitle.Parent = PlayerBar

-- Progress Bar Background
local ProgressBg = Instance.new("Frame")
ProgressBg.Size = UDim2.new(1, -20, 0, 4)
ProgressBg.Position = UDim2.new(0, 10, 0, 28)
ProgressBg.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
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

-- Time Labels (Current Time / Duration)
local TimeLabel = Instance.new("TextLabel")
TimeLabel.Size = UDim2.new(1, -20, 0, 12)
TimeLabel.Position = UDim2.new(0, 10, 0, 34)
TimeLabel.BackgroundTransparency = 1
TimeLabel.Text = "00:00 / 00:00"
TimeLabel.TextColor3 = Color3.fromRGB(140, 155, 180)
TimeLabel.TextSize = 9
TimeLabel.Font = Enum.Font.Gotham
TimeLabel.TextXAlignment = Enum.TextXAlignment.Right
TimeLabel.Parent = PlayerBar

-- Kontrol Tombol (Play/Pause, Stop, Loop)
local PlayBtn = Instance.new("TextButton")
PlayBtn.Size = UDim2.new(0, 32, 0, 32)
PlayBtn.Position = UDim2.new(0, 10, 0, 52)
PlayBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
PlayBtn.Text = "▶"
PlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayBtn.TextSize = 12
PlayBtn.Font = Enum.Font.GothamBold
PlayBtn.Parent = PlayerBar

local PlayCorner = Instance.new("UICorner")
PlayCorner.CornerRadius = UDim.new(0, 8)
PlayCorner.Parent = PlayBtn

local StopBtn = Instance.new("TextButton")
StopBtn.Size = UDim2.new(0, 32, 0, 32)
StopBtn.Position = UDim2.new(0, 48, 0, 52)
StopBtn.BackgroundColor3 = Color3.fromRGB(45, 58, 82)
StopBtn.Text = "◼"
StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StopBtn.TextSize = 11
StopBtn.Font = Enum.Font.GothamBold
StopBtn.Parent = PlayerBar

local StopCorner = Instance.new("UICorner")
StopCorner.CornerRadius = UDim.new(0, 8)
StopCorner.Parent = StopBtn

local LoopBtn = Instance.new("TextButton")
LoopBtn.Size = UDim2.new(0, 32, 0, 32)
LoopBtn.Position = UDim2.new(0, 86, 0, 52)
LoopBtn.BackgroundColor3 = Color3.fromRGB(45, 58, 82)
LoopBtn.Text = "🔁"
LoopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LoopBtn.TextSize = 12
LoopBtn.Font = Enum.Font.GothamBold
LoopBtn.Parent = PlayerBar

local LoopCorner = Instance.new("UICorner")
LoopCorner.CornerRadius = UDim.new(0, 8)
LoopCorner.Parent = LoopBtn

-- Volume Slider (🔊)
local VolIcon = Instance.new("TextLabel")
VolIcon.Size = UDim2.new(0, 20, 0, 32)
VolIcon.Position = UDim2.new(1, -115, 0, 52)
VolIcon.BackgroundTransparency = 1
VolIcon.Text = "🔊"
VolIcon.TextSize = 12
VolIcon.Parent = PlayerBar

local VolBg = Instance.new("TextButton")
VolBg.Size = UDim2.new(0, 80, 0, 6)
VolBg.Position = UDim2.new(1, -90, 0, 65)
VolBg.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
VolBg.Text = ""
VolBg.AutoButtonColor = false
VolBg.Parent = PlayerBar

local VolBgCorner = Instance.new("UICorner")
VolBgCorner.CornerRadius = UDim.new(1, 0)
VolBgCorner.Parent = VolBg

local VolFill = Instance.new("Frame")
VolFill.Size = UDim2.new(1, 0, 1, 0) -- Default Volume 100%
VolFill.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
VolFill.BorderSizePixel = 0
VolFill.Parent = VolBg

local VolFillCorner = Instance.new("UICorner")
VolFillCorner.CornerRadius = UDim.new(1, 0)
VolFillCorner.Parent = VolFill

--------------------------------------------------------------------------------
-- 6. FITUR RESIZE DRAG FRAME
--------------------------------------------------------------------------------
local ResizeGrip = Instance.new("TextButton")
ResizeGrip.Size = UDim2.new(0, 16, 0, 16)
ResizeGrip.Position = UDim2.new(1, -16, 1, -16)
ResizeGrip.BackgroundTransparency = 1
ResizeGrip.Text = "⤢"
ResizeGrip.TextColor3 = Color3.fromRGB(100, 120, 150)
ResizeGrip.TextSize = 12
ResizeGrip.Font = Enum.Font.GothamBold
ResizeGrip.ZIndex = 100
ResizeGrip.Parent = MainFrame

local isResizing = false
local startPos, startSize

ResizeGrip.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = true
        startPos = input.Position
        startSize = MainFrame.AbsoluteSize
        MainFrame.Draggable = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - startPos
        local newWidth = math.clamp(startSize.X + delta.X, 300, 520)
        local newHeight = math.clamp(startSize.Y + delta.Y, 280, 500)
        MainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if isResizing then
            isResizing = false
            MainFrame.Draggable = true
        end
    end
end)

--------------------------------------------------------------------------------
-- 7. KONTROL AUDIO SOUND SERVICE (AUDIO FIX)
--------------------------------------------------------------------------------
-- Menggunakan SoundService agar audio terdengar keras & stabil di HP
local CurrentSound = SoundService:FindFirstChild("NavySpotifySound")
if not CurrentSound then
    CurrentSound = Instance.new("Sound")
    CurrentSound.Name = "NavySpotifySound"
    CurrentSound.Volume = 1
    CurrentSound.Looped = false
    CurrentSound.Parent = SoundService
end

local function FormatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end

-- Update Progress Bar Realtime
RunService.RenderStepped:Connect(function()
    if CurrentSound.IsPlaying and CurrentSound.TimeLength > 0 then
        local alpha = math.clamp(CurrentSound.TimePosition / CurrentSound.TimeLength, 0, 1)
        ProgressFill.Size = UDim2.new(alpha, 0, 1, 0)
        TimeLabel.Text = FormatTime(CurrentSound.TimePosition) .. " / " .. FormatTime(CurrentSound.TimeLength)
    elseif not CurrentSound.IsPlaying and CurrentSound.TimePosition == 0 then
        ProgressFill.Size = UDim2.new(0, 0, 1, 0)
    end
end)

-- Tombol Play/Pause
PlayBtn.MouseButton1Click:Connect(function()
    if CurrentSound.SoundId ~= "" then
        if CurrentSound.IsPlaying then
            CurrentSound:Pause()
            PlayBtn.Text = "▶"
        else
            CurrentSound:Play()
            PlayBtn.Text = "⏸"
        end
    end
end)

-- Tombol Stop
StopBtn.MouseButton1Click:Connect(function()
    CurrentSound:Stop()
    CurrentSound.TimePosition = 0
    PlayBtn.Text = "▶"
    ProgressFill.Size = UDim2.new(0, 0, 1, 0)
end)

-- Tombol Loop
LoopBtn.MouseButton1Click:Connect(function()
    CurrentSound.Looped = not CurrentSound.Looped
    if CurrentSound.Looped then
        LoopBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
    else
        LoopBtn.BackgroundColor3 = Color3.fromRGB(45, 58, 82)
    end
end)

-- Volume Control Drag / Click
local settingVol = false
VolBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        settingVol = true
        local alpha = math.clamp((input.Position.X - VolBg.AbsolutePosition.X) / VolBg.AbsoluteSize.X, 0, 1)
        VolFill.Size = UDim2.new(alpha, 0, 1, 0)
        CurrentSound.Volume = alpha * 2 -- Skala 0 sampai 2x
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

-- Minimize Logic
MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    ToggleBtn.Visible = true
end)

ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    ToggleBtn.Visible = false
end)

--------------------------------------------------------------------------------
-- 8. FUNGSI REQUEST SERVER & NETWORK
--------------------------------------------------------------------------------
local function customRequest(reqData)
    local req = (syn and syn.request) or request or http_request or (http and http.request)
    if not req then return nil, "Request executor tidak ditemukan!" end
    
    reqData.Headers = reqData.Headers or {}
    reqData.Headers["bypass-tunnel-reminder"] = "true"
    reqData.Headers["User-Agent"] = "Mozilla/5.0"
    
    local success, response = pcall(function() return req(reqData) end)
    if not success then return nil, "Error pcall: " .. tostring(response) end
    
    return response, nil
end

local function PlayTrack(id, name)
    TrackTitle.Text = "Memuat audio..."
    PlayBtn.Text = "⏳"
    
    task.spawn(function()
        local body = HttpService:JSONEncode({ videoId = id, title = name })
        local res, err = customRequest({
            Url = SERVER_URL .. "/api/download",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body
        })
        
        if res and res.Body then
            local success, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
            if success and data and data.success and data.downloadUrl then
                TrackTitle.Text = name
                CurrentSound:Stop()
                
                -- Memastikan URL dipasangkan dengan benar ke SoundId Roblox
                CurrentSound.SoundId = data.downloadUrl
                
                -- Berikan jeda sebentar agar Roblox memuat buffer audio
                task.wait(0.3)
                CurrentSound:Play()
                PlayBtn.Text = "⏸"
            else
                TrackTitle.Text = "Gagal memproses lagu!"
                PlayBtn.Text = "▶"
            end
        else
            TrackTitle.Text = "Gagal terhubung ke server!"
            PlayBtn.Text = "▶"
        end
    end)
end

local function ExecuteSearch()
    if SearchBox.Text == "" then return end
    
    for _, c in pairs(ScrollFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    
    TrackTitle.Text = "Mencari lagu..."
    
    task.spawn(function()
        local searchUrl = SERVER_URL .. "/api/search?q=" .. HttpService:UrlEncode(SearchBox.Text)
        local res, err = customRequest({ Url = searchUrl, Method = "GET" })
        
        if not res then
            TrackTitle.Text = "Gagal terhubung server!"
            return
        end
        
        if res.Body then
            local success, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
            if success and data and data.success and data.results then
                ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, (#data.results * 34) + 8)
                for _, song in ipairs(data.results) do
                    local btn = Instance.new("TextButton")
                    btn.Size = UDim2.new(1, 0, 0, 30)
                    btn.BackgroundColor3 = Color3.fromRGB(30, 40, 58)
                    btn.Text = "  🎵  " .. song.title
                    btn.TextColor3 = Color3.fromRGB(230, 240, 255)
                    btn.TextXAlignment = Enum.TextXAlignment.Left
                    btn.TextSize = 11
                    btn.Font = Enum.Font.Gotham
                    btn.Parent = ScrollFrame
                    
                    local btnCorner = Instance.new("UICorner")
                    btnCorner.CornerRadius = UDim.new(0, 8)
                    btnCorner.Parent = btn
                    
                    btn.MouseButton1Click:Connect(function()
                        PlayTrack(song.id, song.title)
                    end)
                end
                TrackTitle.Text = "Pilih lagu dari daftar"
            else
                TrackTitle.Text = "Lagu tidak ditemukan!"
            end
        else
            TrackTitle.Text = "Respon server kosong!"
        end
    end)
end

SearchBtn.MouseButton1Click:Connect(ExecuteSearch)
SearchBox.FocusLost:Connect(ExecuteSearch)
