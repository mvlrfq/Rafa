local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- 1. Inisialisasi Audio
local sound = Instance.new("Sound")
sound.Name = "ExternalAudioPlayer"
sound.Volume = 0.5
sound.Looped = false
sound.Parent = SoundService

-- Data Playlist Default
local playlist = {
    {Name = "Default Track 1", Source = "1848354536"},
    {Name = "Default Track 2", Source = "1837879082"}
}
local currentTrackIndex = 1

-- 2. GUI Utama
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdvancedAudioPlayerGui"
screenGui.Parent = (RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui")) or CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 450)
frame.Position = UDim2.new(0.5, -140, 0.25, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.ClipsDescendants = true
frame.Parent = screenGui

-- Title Bar
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 25)
title.Position = UDim2.new(0, 0, 0, 0)
title.Text = " External Audio Player & Playlist"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
title.BorderSizePixel = 0
title.Font = Enum.Font.SourceSansBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local titleRightBar = Instance.new("Frame")
titleRightBar.Size = UDim2.new(0, 60, 0, 25)
titleRightBar.Position = UDim2.new(1, -60, 0, 0)
titleRightBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
titleRightBar.BorderSizePixel = 0
titleRightBar.Parent = frame

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 30, 0, 25)
minBtn.Position = UDim2.new(0, 0, 0, 0)
minBtn.Text = "-"
minBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.BorderSizePixel = 0
minBtn.Font = Enum.Font.SourceSansBold
minBtn.TextSize = 16
minBtn.Parent = titleRightBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 25)
closeBtn.Position = UDim2.new(0, 30, 0, 0)
closeBtn.Text = "X"
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BorderSizePixel = 0
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 14
closeBtn.Parent = titleRightBar

-- Content Container
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -25)
contentFrame.Position = UDim2.new(0, 0, 0, 25)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = frame

-- Input Nama & Link
local nameBox = Instance.new("TextBox")
nameBox.Size = UDim2.new(1, -20, 0, 25)
nameBox.Position = UDim2.new(0, 10, 0, 10)
nameBox.PlaceholderText = "Judul Lagu (Opsional)..."
nameBox.Text = ""
nameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
nameBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
nameBox.BorderSizePixel = 0
nameBox.ClearTextOnFocus = false
nameBox.Font = Enum.Font.SourceSans
nameBox.TextSize = 12
nameBox.Parent = contentFrame

local urlBox = Instance.new("TextBox")
urlBox.Size = UDim2.new(1, -20, 0, 25)
urlBox.Position = UDim2.new(0, 10, 0, 40)
urlBox.PlaceholderText = "Link MP3 atau Sound ID..."
urlBox.Text = ""
urlBox.TextColor3 = Color3.fromRGB(255, 255, 255)
urlBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
urlBox.BorderSizePixel = 0
urlBox.ClearTextOnFocus = false
urlBox.Font = Enum.Font.SourceSans
urlBox.TextSize = 12
urlBox.Parent = contentFrame

-- Tombol Tambah ke Playlist
local addBtn = Instance.new("TextButton")
addBtn.Size = UDim2.new(1, -20, 0, 25)
addBtn.Position = UDim2.new(0, 10, 0, 70)
addBtn.Text = "+ Tambahkan ke Playlist"
addBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
addBtn.BorderSizePixel = 0
addBtn.Font = Enum.Font.SourceSansBold
addBtn.Parent = contentFrame

-- Playlist Container (ScrollingFrame)
local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1, -20, 0, 100)
listFrame.Position = UDim2.new(0, 10, 0, 100)
listFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 4
listFrame.Parent = contentFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Parent = listFrame
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Padding = UDim.new(0, 2)

-- Kontrol Playback (Prev, Play, Next)
local prevBtn = Instance.new("TextButton")
prevBtn.Size = UDim2.new(0, 75, 0, 25)
prevBtn.Position = UDim2.new(0, 10, 0, 205)
prevBtn.Text = "Prev"
prevBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
prevBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
prevBtn.BorderSizePixel = 0
prevBtn.Font = Enum.Font.SourceSansBold
prevBtn.Parent = contentFrame

local playBtn = Instance.new("TextButton")
playBtn.Size = UDim2.new(0, 100, 0, 25)
playBtn.Position = UDim2.new(0, 90, 0, 205)
playBtn.Text = "Play / Pause"
playBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
playBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
playBtn.BorderSizePixel = 0
playBtn.Font = Enum.Font.SourceSansBold
playBtn.Parent = contentFrame

local nextBtn = Instance.new("TextButton")
nextBtn.Size = UDim2.new(0, 75, 0, 25)
nextBtn.Position = UDim2.new(0, 195, 0, 205)
nextBtn.Text = "Next"
nextBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
nextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
nextBtn.BorderSizePixel = 0
nextBtn.Font = Enum.Font.SourceSansBold
nextBtn.Parent = contentFrame

-- Tombol Toggle Loop
local loopBtn = Instance.new("TextButton")
loopBtn.Size = UDim2.new(0, 125, 0, 25)
loopBtn.Position = UDim2.new(0, 10, 0, 235)
loopBtn.Text = "Loop Single: OFF"
loopBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
loopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
loopBtn.BorderSizePixel = 0
loopBtn.Font = Enum.Font.SourceSansBold
loopBtn.Parent = contentFrame

-- Tombol Shuffle (Acak Playlist)
local shuffleBtn = Instance.new("TextButton")
shuffleBtn.Size = UDim2.new(0, 130, 0, 25)
shuffleBtn.Position = UDim2.new(0, 140, 0, 235)
shuffleBtn.Text = "🔀 Shuffle Playlist"
shuffleBtn.BackgroundColor3 = Color3.fromRGB(140, 80, 200)
shuffleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
shuffleBtn.BorderSizePixel = 0
shuffleBtn.Font = Enum.Font.SourceSansBold
shuffleBtn.Parent = contentFrame

-- Tombol Clear All (Hapus Semua)
local clearAllBtn = Instance.new("TextButton")
clearAllBtn.Size = UDim2.new(1, -20, 0, 25)
clearAllBtn.Position = UDim2.new(0, 10, 0, 265)
clearAllBtn.Text = "🗑️ Clear All (Hapus Semua)"
clearAllBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
clearAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearAllBtn.BorderSizePixel = 0
clearAllBtn.Font = Enum.Font.SourceSansBold
clearAllBtn.Parent = contentFrame

-- Volume Slider
local volumeLabel = Instance.new("TextLabel")
volumeLabel.Size = UDim2.new(1, -20, 0, 20)
volumeLabel.Position = UDim2.new(0, 10, 0, 295)
volumeLabel.Text = "Volume: 50%"
volumeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
volumeLabel.BackgroundTransparency = 1
volumeLabel.Font = Enum.Font.SourceSans
volumeLabel.TextSize = 13
volumeLabel.TextXAlignment = Enum.TextXAlignment.Left
volumeLabel.Parent = contentFrame

local sliderBar = Instance.new("Frame")
sliderBar.Size = UDim2.new(1, -20, 0, 8)
sliderBar.Position = UDim2.new(0, 10, 0, 320)
sliderBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
sliderBar.BorderSizePixel = 0
sliderBar.Parent = contentFrame

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.5, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBar

local sliderKnob = Instance.new("TextButton")
sliderKnob.Size = UDim2.new(0, 14, 0, 14)
sliderKnob.Position = UDim2.new(0.5, -7, 0.5, -7)
sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderKnob.Text = ""
sliderKnob.BorderSizePixel = 0
sliderKnob.Parent = sliderBar

-- Label Status
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 340)
statusLabel.Text = "Status: Ready"
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.SourceSansItalic
statusLabel.TextSize = 12
statusLabel.Parent = contentFrame

-- Forward Declarations
local playTrack
local refreshPlaylistUI

-- 3. Fungsi Pemutar Lagu
playTrack = function(index)
    if #playlist == 0 then
        sound:Stop()
        statusLabel.Text = "Playlist Kosong!"
        return
    end
    if index < 1 then index = #playlist end
    if index > #playlist then index = 1 end
    
    currentTrackIndex = index
    local track = playlist[currentTrackIndex]
    
    sound:Stop()
    statusLabel.Text = "Memuat: " .. track.Name
    
    if string.sub(track.Source, 1, 4) == "http" then
        task.spawn(function()
            local success, result = pcall(function()
                local fileName = "playlist_audio_" .. currentTrackIndex .. ".mp3"
                if not isfile(fileName) then
                    local audioData = game:HttpGet(track.Source)
                    writefile(fileName, audioData)
                end
                return getcustomasset(fileName)
            end)

            if success then
                sound.SoundId = result
                sound:Play()
                statusLabel.Text = "Playing: " .. track.Name
            else
                statusLabel.Text = "Gagal memuat URL!"
            end
        end)
    else
        local cleanId = string.match(track.Source, "%d+")
        if cleanId then
            sound.SoundId = "rbxassetid://" .. cleanId
            sound:Play()
            statusLabel.Text = "Playing: " .. track.Name
        else
            statusLabel.Text = "ID tidak valid!"
        end
    end
    
    refreshPlaylistUI()
end

-- Refresh UI Playlist
refreshPlaylistUI = function()
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    for i, track in ipairs(playlist) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(1, 0, 0, 22)
        itemFrame.BackgroundColor3 = (i == currentTrackIndex and #playlist > 0) and Color3.fromRGB(0, 100, 180) or Color3.fromRGB(35, 35, 35)
        itemFrame.BorderSizePixel = 0
        itemFrame.LayoutOrder = i
        itemFrame.Parent = listFrame

        -- Tombol Pilih Lagu
        local itemBtn = Instance.new("TextButton")
        itemBtn.Size = UDim2.new(1, -25, 1, 0)
        itemBtn.Position = UDim2.new(0, 0, 0, 0)
        itemBtn.Text = "  " .. i .. ". " .. track.Name
        itemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        itemBtn.BackgroundTransparency = 1
        itemBtn.Font = Enum.Font.SourceSans
        itemBtn.TextSize = 12
        itemBtn.TextXAlignment = Enum.TextXAlignment.Left
        itemBtn.Parent = itemFrame

        itemBtn.MouseButton1Click:Connect(function()
            playTrack(i)
        end)

        -- Tombol Hapus (X) Per Lagu
        local deleteBtn = Instance.new("TextButton")
        deleteBtn.Size = UDim2.new(0, 20, 0, 18)
        deleteBtn.Position = UDim2.new(1, -22, 0, 2)
        deleteBtn.Text = "X"
        deleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        deleteBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        deleteBtn.BorderSizePixel = 0
        deleteBtn.Font = Enum.Font.SourceSansBold
        deleteBtn.TextSize = 11
        deleteBtn.Parent = itemFrame

        deleteBtn.MouseButton1Click:Connect(function()
            table.remove(playlist, i)
            statusLabel.Text = "Lagu dihapus!"
            
            if #playlist == 0 then
                sound:Stop()
                sound.SoundId = ""
                statusLabel.Text = "Playlist Kosong!"
                currentTrackIndex = 1
                refreshPlaylistUI()
            elseif i == currentTrackIndex then
                playTrack(currentTrackIndex)
            else
                if i < currentTrackIndex then
                    currentTrackIndex = currentTrackIndex - 1
                end
                refreshPlaylistUI()
            end
        end)
    end
    
    listFrame.CanvasSize = UDim2.new(0, 0, 0, uiListLayout.AbsoluteContentSize.Y)
end

refreshPlaylistUI()

-- Auto-Next Lagu ketika musik selesai
sound.Ended:Connect(function()
    if not sound.Looped then
        playTrack(currentTrackIndex + 1)
    end
end)

-- 4. Event & Logic Tombol
addBtn.MouseButton1Click:Connect(function()
    local src = urlBox.Text
    local name = nameBox.Text
    if src == "" then return end
    if name == "" then name = "Track " .. (#playlist + 1) end
    
    table.insert(playlist, {Name = name, Source = src})
    urlBox.Text = ""
    nameBox.Text = ""
    refreshPlaylistUI()
    statusLabel.Text = "Lagu ditambahkan!"
end)

playBtn.MouseButton1Click:Connect(function()
    if #playlist == 0 then
        statusLabel.Text = "Playlist Kosong!"
        return
    end
    
    if sound.SoundId == "" then
        playTrack(currentTrackIndex)
    elseif sound.IsPlaying then
        sound:Pause()
        statusLabel.Text = "Status: Paused"
    else
        sound:Play()
        statusLabel.Text = "Playing: " .. playlist[currentTrackIndex].Name
    end
end)

nextBtn.MouseButton1Click:Connect(function()
    playTrack(currentTrackIndex + 1)
end)

prevBtn.MouseButton1Click:Connect(function()
    playTrack(currentTrackIndex - 1)
end)

loopBtn.MouseButton1Click:Connect(function()
    sound.Looped = not sound.Looped
    if sound.Looped then
        loopBtn.Text = "Loop Single: ON"
        loopBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 80)
    else
        loopBtn.Text = "Loop Single: OFF"
        loopBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    end
end)

-- Shuffle Logic (Mengacak Playlist)
shuffleBtn.MouseButton1Click:Connect(function()
    if #playlist <= 1 then
        statusLabel.Text = "Tidak cukup lagu!"
        return
    end

    local currentTrack = playlist[currentTrackIndex]

    for i = #playlist, 2, -1 do
        local j = math.random(i)
        playlist[i], playlist[j] = playlist[j], playlist[i]
    end

    for i, track in ipairs(playlist) do
        if track == currentTrack then
            currentTrackIndex = i
            break
        end
    end

    refreshPlaylistUI()
    statusLabel.Text = "Playlist diacak!"
end)

-- Clear All Logic (Menghapus Semua Lagu)
clearAllBtn.MouseButton1Click:Connect(function()
    if #playlist == 0 then
        statusLabel.Text = "Playlist sudah kosong!"
        return
    end

    playlist = {}
    currentTrackIndex = 1
    sound:Stop()
    sound.SoundId = ""
    refreshPlaylistUI()
    statusLabel.Text = "Semua lagu berhasil dihapus!"
end)

-- Minimize & Close Logic
local isMinimized = false
local originalSize = UDim2.new(0, 280, 0, 450)
local minimizedSize = UDim2.new(0, 280, 0, 25)

minBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        contentFrame.Visible = false
        frame.Size = minimizedSize
        minBtn.Text = "+"
    else
        frame.Size = originalSize
        contentFrame.Visible = true
        minBtn.Text = "-"
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    sound:Stop()
    sound:Destroy()
    screenGui:Destroy()
end)

-- Slider Volume Logic
local isDragging = false
local function updateVolume(input)
    local barAbsPos = sliderBar.AbsolutePosition.X
    local barAbsSize = sliderBar.AbsoluteSize.X
    local mouseX = input.Position.X
    local relativeX = math.clamp((mouseX - barAbsPos) / barAbsSize, 0, 1)

    sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
    sliderKnob.Position = UDim2.new(relativeX, -7, 0.5, -7)

    sound.Volume = relativeX
    volumeLabel.Text = "Volume: " .. math.floor(relativeX * 100) .. "%"
end

sliderKnob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isDragging = true end
end)
sliderBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        updateVolume(input)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isDragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateVolume(input)
    end
end)
