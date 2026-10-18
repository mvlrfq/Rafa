-- Spotify Navy Dashboard (Fixed Layout Spacing, Smooth Corners & Drag Resizer)
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local SERVER_URL = "https://suggestions-computed-finishing-restructuring.trycloudflare.com" -- Ganti dengan IP PC Anda

-- Hapus UI lama jika ada
if PlayerGui:FindFirstChild("SimpleNavyUI") then
    PlayerGui.SimpleNavyUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SimpleNavyUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

--------------------------------------------------------------------------------
-- 1. MAIN FRAME (Sesuai Struktur Dasar yang Sudah Jalan)
--------------------------------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 340, 0, 290)
MainFrame.Position = UDim2.new(0.5, -170, 0.4, -145)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 26, 38)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- Menggunakan fitur drag bawaan yang sudah terbukti jalan
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16) -- Sudut lebih melengkung & tidak tajam
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(35, 48, 72)
MainStroke.Thickness = 1
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

-- Tombol Minimize (-)
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -38, 0, 7)
MinBtn.BackgroundColor3 = Color3.fromRGB(32, 42, 61)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 18
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = MainFrame

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1, 0)
MinCorner.Parent = MinBtn

-- Tombol Toggle Mengambang (🎵 saat Minimize - Juga Bisa Di Drag)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 46, 0, 46)
ToggleBtn.Position = UDim2.new(0, 15, 0.4, 0)
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

--------------------------------------------------------------------------------
-- 2. ELEMENT ISI (SEARCH, LIST, PLAYER BAR)
--------------------------------------------------------------------------------
-- Search Box
local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -32, 0, 34)
SearchBox.Position = UDim2.new(0, 16, 0, 42)
SearchBox.BackgroundColor3 = Color3.fromRGB(28, 36, 52)
SearchBox.PlaceholderText = "Cari nama berkas / lagu..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(140, 155, 180)
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.TextSize = 11
SearchBox.Font = Enum.Font.Gotham
SearchBox.Parent = MainFrame

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 10)
SearchCorner.Parent = SearchBox

-- Scroll List Lagu
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -32, 1, -142)
ScrollFrame.Position = UDim2.new(0, 16, 0, 84)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(24, 31, 44)
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

-- Bottom Player Bar (Memberikan margin bawah agar tidak bertumpuk dengan resizer)
local PlayerBar = Instance.new("Frame")
PlayerBar.Size = UDim2.new(1, -32, 0, 42)
PlayerBar.Position = UDim2.new(0, 16, 1, -50)
PlayerBar.BackgroundColor3 = Color3.fromRGB(28, 36, 52)
PlayerBar.Parent = MainFrame

local PlayerCorner = Instance.new("UICorner")
PlayerCorner.CornerRadius = UDim.new(0, 10)
PlayerCorner.Parent = PlayerBar

local TrackTitle = Instance.new("TextLabel")
TrackTitle.Size = UDim2.new(1, -50, 1, 0)
TrackTitle.Position = UDim2.new(0, 10, 0, 0)
TrackTitle.BackgroundTransparency = 1
TrackTitle.Text = "Pilih lagu..."
TrackTitle.TextColor3 = Color3.fromRGB(220, 230, 250)
TrackTitle.TextSize = 11
TrackTitle.Font = Enum.Font.GothamMedium
TrackTitle.TextXAlignment = Enum.TextXAlignment.Left
TrackTitle.Parent = PlayerBar

local PlayBtn = Instance.new("TextButton")
PlayBtn.Size = UDim2.new(0, 30, 0, 30)
PlayBtn.Position = UDim2.new(1, -36, 0.5, -15)
PlayBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
PlayBtn.Text = "▶"
PlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayBtn.TextSize = 12
PlayBtn.Font = Enum.Font.GothamBold
PlayBtn.Parent = PlayerBar

local PlayCorner = Instance.new("UICorner")
PlayCorner.CornerRadius = UDim.new(0, 8)
PlayCorner.Parent = PlayBtn

--------------------------------------------------------------------------------
-- 3. FITUR RESIZE DRAG (TARIK POJOK KANAN BAWAH)
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
        MainFrame.Draggable = false -- Matikan drag window sementara saat sedang meresize
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - startPos
        local newWidth = math.clamp(startSize.X + delta.X, 280, 500)
        local newHeight = math.clamp(startSize.Y + delta.Y, 220, 420)
        MainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
end)

local function StopResize(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if isResizing then
            isResizing = false
            MainFrame.Draggable = true -- Aktifkan kembali drag window utama
        end
    end
end

UserInputService.InputEnded:Connect(StopResize)

--------------------------------------------------------------------------------
-- LOGIKA MINIMIZE & SOUND
--------------------------------------------------------------------------------
MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    ToggleBtn.Visible = true
end)

ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    ToggleBtn.Visible = false
end)

local CurrentSound = Instance.new("Sound")
CurrentSound.Parent = workspace

PlayBtn.MouseButton1Click:Connect(function()
    if CurrentSound.IsPlaying then
        CurrentSound:Pause()
        PlayBtn.Text = "▶"
    else
        CurrentSound:Play()
        PlayBtn.Text = "⏸"
    end
end)

local function PlayTrack(id, name)
    TrackTitle.Text = "Memuat..."
    task.spawn(function()
        local body = HttpService:JSONEncode({ videoId = id, title = name })
        local res = request({
            Url = SERVER_URL .. "/api/download",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body
        })
        if res and res.Body then
            local data = HttpService:JSONDecode(res.Body)
            if data.success then
                TrackTitle.Text = name
                CurrentSound.SoundId = data.downloadUrl
                CurrentSound:Play()
                PlayBtn.Text = "⏸"
            end
        end
    end)
end

SearchBox.FocusLost:Connect(function(enter)
    if not enter or SearchBox.Text == "" then return end
    for _, c in pairs(ScrollFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    
    local res = request({ Url = SERVER_URL .. "/api/search?q=" .. HttpService:UrlEncode(SearchBox.Text), Method = "GET" })
    if res and res.Body then
        local data = HttpService:JSONDecode(res.Body)
        if data.success then
            ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, (#data.results * 32) + 8)
            for _, song in ipairs(data.results) do
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, 28)
                btn.BackgroundColor3 = Color3.fromRGB(32, 42, 61)
                btn.Text = "  " .. song.title
                btn.TextColor3 = Color3.fromRGB(230, 240, 255)
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.TextSize = 11
                btn.Font = Enum.Font.Gotham
                btn.Parent = ScrollFrame
                
                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 6)
                btnCorner.Parent = btn
                
                btn.MouseButton1Click:Connect(function()
                    PlayTrack(song.id, song.title)
                end)
            end
        end
    end
end)
