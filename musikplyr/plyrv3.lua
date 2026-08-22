local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- 0. Pengaturan Folder dan File Penyimpanan Lokal
local FOLDER_NAME = "MyMusicPlayer"
local PLAYLIST_FILE = FOLDER_NAME .. "/playlist_data.json"

-- Buat folder jika belum ada di file lokal eksekutor
if makefolder and not isfolder(FOLDER_NAME) then
    makefolder(FOLDER_NAME)
end

-- Data Playlist Default (Jika belum ada file penyimpanan)
local playlist = {
    {Name = "Default Track 1", Source = "1848354536"},
    {Name = "Default Track 2", Source = "1837879082"}
}

-- Fungsi untuk Menyimpan Playlist ke File Lokal (.json)
local function savePlaylistToLocal()
    if writefile then
        local success, err = pcall(function()
            local jsonString = HttpService:JSONEncode(playlist)
            writefile(PLAYLIST_FILE, jsonString)
        end)
        if not success then
            warn("Gagal menyimpan playlist ke file lokal: ", err)
        end
    end
end

-- Fungsi untuk Memuat Playlist dari File Lokal (.json)
local function loadPlaylistFromLocal()
    if isfile and isfile(PLAYLIST_FILE) and readfile then
        local success, result = pcall(function()
            local fileContent = readfile(PLAYLIST_FILE)
            return HttpService:JSONDecode(fileContent)
        end)
        if success and type(result) == "table" and #result > 0 then
            playlist = result
        end
    end
end

-- Memuat playlist yang tersimpan saat script pertama kali dijalankan
loadPlaylistFromLocal()

-- 1. Inisialisasi Audio
local sound = Instance.new("Sound")
sound.Name = "ExternalAudioPlayer"
sound.Volume = 0.5
sound.Looped = false
sound.Parent = SoundService

local currentTrackIndex = 1

-- 2. GUI Utama
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CompactAudioPlayerGui"
screenGui.Parent = (RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui")) or CoreGui

-- Frame Utama (Ringkas: 260px)
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 270, 0, 260)
frame.Position = UDim2.new(0.5, -135, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.ClipsDescendants = true
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 8)
frameCorner.Parent = frame

-- Title Bar
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 28)
title.Position = UDim2.new(0, 10, 0, 0)
title.Text = "🎵 Audio Player"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 24, 0, 24)
minBtn.Position = UDim2.new(1, -54, 0, 2)
minBtn.Text = "-"
minBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.BorderSizePixel = 0
minBtn.Font = Enum.Font.SourceSansBold
minBtn.TextSize = 16
minBtn.Parent = frame

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 4)
minCorner.Parent = minBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -26, 0, 2)
closeBtn.Text = "X"
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BorderSizePixel = 0
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 12
closeBtn.Parent = frame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeBtn

-- 3. Ikon Logo Kecil (Muncul saat Minimize)
local miniIcon = Instance.new("TextButton")
miniIcon.Size = UDim2.new(0, 45, 0, 45)
miniIcon.Position = UDim2.new(0.05, 0, 0.2, 0)
miniIcon.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
miniIcon.Text = "🎵"
miniIcon.TextSize = 22
miniIcon.Visible = false
miniIcon.Active = true
miniIcon.Draggable = true
miniIcon.Parent = screenGui

local miniCorner = Instance.new("UICorner")
miniCorner.CornerRadius = UDim.new(1, 0)
miniCorner.Parent = miniIcon

local miniStroke = Instance.new("UIStroke")
miniStroke.Thickness = 2
miniStroke.Color = Color3.fromRGB(0, 150, 255)
miniStroke.Parent = miniIcon

-- 4. Main Scroll Container
local mainScroll = Instance.new("ScrollingFrame")
mainScroll.Size = UDim2.new(1, 0, 1, -30)
mainScroll.Position = UDim2.new(0, 0, 0, 30)
mainScroll.BackgroundTransparency = 1
mainScroll.BorderSizePixel = 0
mainScroll.ScrollBarThickness = 4
mainScroll.CanvasSize = UDim2.new(0, 0, 0, 320)
mainScroll.Parent = frame

-- Input Judul & Link Lagu
local nameBox = Instance.new("TextBox")
nameBox.Size = UDim2.new(1, -20, 0, 24)
nameBox.Position = UDim2.new(0, 10, 0, 0)
nameBox.PlaceholderText = "Judul Lagu (Opsional)..."
nameBox.Text = ""
nameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
nameBox.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
nameBox.BorderSizePixel = 0
nameBox.ClearTextOnFocus = false
nameBox.Font = Enum.Font.SourceSans
nameBox.TextSize = 12
nameBox.Parent = mainScroll

local urlBox = Instance.new("TextBox")
urlBox.Size = UDim2.new(1, -20, 0, 24)
urlBox.Position = UDim2.new(0, 10, 0, 28)
urlBox.PlaceholderText = "Link MP3 atau Sound ID..."
urlBox.Text = ""
urlBox.TextColor3 = Color3.fromRGB(255, 255, 255)
urlBox.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
urlBox.BorderSizePixel = 0
urlBox.ClearTextOnFocus = false
urlBox.Font = Enum.Font.SourceSans
urlBox.TextSize = 12
urlBox.Parent = mainScroll

-- Tombol Tambah ke Playlist
local addBtn = Instance.new("TextButton")
addBtn.Size = UDim2.new(1, -20, 0, 24)
addBtn.Position = UDim2.new(0, 10, 0, 56)
addBtn.Text = "+ Tambahkan ke Playlist"
addBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
addBtn.BorderSizePixel = 0
addBtn.Font = Enum.Font.SourceSansBold
addBtn.TextSize = 12
addBtn.Parent = mainScroll

-- Playlist Container
local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1, -20, 0, 85)
listFrame.Position = UDim2.new(0, 10, 0, 84)
listFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 3
listFrame.Parent = mainScroll

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Parent = listFrame
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Padding = UDim.new(0, 2)

-- Kontrol Playback
local prevBtn = Instance.new("TextButton")
prevBtn.Size = UDim2.new(0, 70, 0, 24)
prevBtn.Position = UDim2.new(0, 10, 0, 174)
prevBtn.Text = "Prev"
prevBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
prevBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
prevBtn.BorderSizePixel = 0
prevBtn.Font = Enum.Font.SourceSansBold
prevBtn.Parent = mainScroll

local playBtn = Instance.new("TextButton")
playBtn.Size = UDim2.new(0, 100, 0, 24)
playBtn.Position = UDim2.new(0, 85, 0, 174)
playBtn.Text = "Play / Pause"
playBtn.BackgroundColor3 = Color3.fromRGB(45, 140, 60)
playBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
playBtn.BorderSizePixel = 0
playBtn.Font = Enum.Font.SourceSansBold
playBtn.Parent = mainScroll

local nextBtn = Instance.new("TextButton")
nextBtn.Size = UDim2.new(0, 70, 0, 24)
nextBtn.Position = UDim2.new(0, 190, 0, 174)
nextBtn.Text = "Next"
nextBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
nextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
nextBtn.BorderSizePixel = 0
nextBtn.Font = Enum.Font.SourceSansBold
nextBtn.Parent = mainScroll

-- Tombol Loop & Shuffle
local loopBtn = Instance.new("TextButton")
loopBtn.Size = UDim2.new(0, 120, 0, 24)
loopBtn.Position = UDim2.new(0, 10, 0, 202)
loopBtn.Text = "Loop: OFF"
loopBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 85)
loopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
loopBtn.BorderSizePixel = 0
loopBtn.Font = Enum.Font.SourceSansBold
loopBtn.Parent = mainScroll

local shuffleBtn = Instance.new("TextButton")
shuffleBtn.Size = UDim2.new(0, 125, 0, 24)
shuffleBtn.Position = UDim2.new(0, 135, 0, 202)
shuffleBtn.Text = "🔀 Shuffle"
shuffleBtn.BackgroundColor3 = Color3.fromRGB(130, 70, 180)
shuffleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
shuffleBtn.BorderSizePixel = 0
shuffleBtn.Font = Enum.Font.SourceSansBold
shuffleBtn.Parent = mainScroll

-- Tombol Clear All
local clearAllBtn = Instance.new("TextButton")
clearAllBtn.Size = UDim2.new(1, -20, 0, 24)
clearAllBtn.Position = UDim2.new(0, 10, 0, 230)
clearAllBtn.Text = "🗑️ Clear All Playlist"
clearAllBtn.BackgroundColor3 = Color3.fromRGB(170, 45, 45)
clearAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearAllBtn.BorderSizePixel = 0
clearAllBtn.Font = Enum.Font.SourceSansBold
clearAllBtn.Parent = mainScroll

-- Slider Volume
local volumeLabel = Instance.new("TextLabel")
volumeLabel.Size = UDim2.new(1, -20, 0, 18)
volumeLabel.Position = UDim2.new(0, 10, 0, 258)
volumeLabel.Text = "Volume: 50%"
volumeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
volumeLabel.BackgroundTransparency = 1
volumeLabel.Font = Enum.Font.SourceSans
volumeLabel.TextSize = 12
volumeLabel.TextXAlignment = Enum.TextXAlignment.Left
volumeLabel.Parent = mainScroll

local sliderBar = Instance.new("Frame")
sliderBar.Size = UDim2.new(1, -20, 0, 6)
sliderBar.Position = UDim2.new(0, 10, 0, 278)
sliderBar.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
sliderBar.BorderSizePixel = 0
sliderBar.Parent = mainScroll

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.5, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBar

local sliderKnob = Instance.new("TextButton")
sliderKnob.Size = UDim2.new(0, 12, 0, 12)
sliderKnob.Position = UDim2.new(0.5, -6, 0.5, -6)
sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderKnob.Text = ""
sliderKnob.BorderSizePixel = 0
sliderKnob.Parent = sliderBar

-- Status Text
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 18)
statusLabel.Position = UDim2.new(0, 10, 0, 292)
statusLabel.Text = "Status: Ready"
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.SourceSansItalic
statusLabel.TextSize = 11
statusLabel.Parent = mainScroll

-- Declarations
local playTrack
local refreshPlaylistUI

-- 5. Logic Pemutar Lagu & Penyimpan Audio MP3 Offline
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
                -- Menyimpan audio MP3 langsung ke folder lokal agar hemat kuota di lain waktu
                local fileName = FOLDER_NAME .. "/track_" .. currentTrackIndex .. ".mp3"
                if isfile and not isfile(fileName) then
                    local audioData = game:HttpGet(track.Source)
                    if writefile then
                        writefile(fileName, audioData)
                    end
                end
                return getcustomasset and getcustomasset(fileName)
            end)

            if success and result then
                sound.SoundId = result
                sound:Play()
                statusLabel.Text = "Playing: " .. track.Name
            else
                statusLabel.Text = "Gagal memuat URL/File!"
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

refreshPlaylistUI = function()
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    for i, track in ipairs(playlist) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(1, 0, 0, 20)
        itemFrame.BackgroundColor3 = (i == currentTrackIndex and #playlist > 0) and Color3.fromRGB(0, 100, 180) or Color3.fromRGB(35, 35, 38)
        itemFrame.BorderSizePixel = 0
        itemFrame.LayoutOrder = i
        itemFrame.Parent = listFrame

        local itemBtn = Instance.new("TextButton")
        itemBtn.Size = UDim2.new(1, -22, 1, 0)
        itemBtn.Position = UDim2.new(0, 0, 0, 0)
        itemBtn.Text = " " .. i .. ". " .. track.Name
        itemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        itemBtn.BackgroundTransparency = 1
        itemBtn.Font = Enum.Font.SourceSans
        itemBtn.TextSize = 11
        itemBtn.TextXAlignment = Enum.TextXAlignment.Left
        itemBtn.Parent = itemFrame

        itemBtn.MouseButton1Click:Connect(function()
            playTrack(i)
        end)

        local deleteBtn = Instance.new("TextButton")
        deleteBtn.Size = UDim2.new(0, 18, 0, 16)
        deleteBtn.Position = UDim2.new(1, -20, 0, 2)
        deleteBtn.Text = "X"
        deleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        deleteBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        deleteBtn.BorderSizePixel = 0
        deleteBtn.Font = Enum.Font.SourceSansBold
        deleteBtn.TextSize = 10
        deleteBtn.Parent = itemFrame

        deleteBtn.MouseButton1Click:Connect(function()
            table.remove(playlist, i)
            savePlaylistToLocal() -- Simpan perubahan ke penyimpanan lokal
            statusLabel.Text = "Lagu dihapus & Disimpan!"
            
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

sound.Ended:Connect(function()
    if not sound.Looped then
        playTrack(currentTrackIndex + 1)
    end
end)

-- 6. Event Logic Tombol
addBtn.MouseButton1Click:Connect(function()
    local src = urlBox.Text
    local name = nameBox.Text
    if src == "" then return end
    if name == "" then name = "Track " .. (#playlist + 1) end
    
    table.insert(playlist, {Name = name, Source = src})
    savePlaylistToLocal() -- Menyimpan playlist baru ke penyimpanan HP/Lokal
    
    urlBox.Text = ""
    nameBox.Text = ""
    refreshPlaylistUI()
    statusLabel.Text = "Ditambahkan & Disimpan!"
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
        loopBtn.Text = "Loop: ON"
        loopBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 80)
    else
        loopBtn.Text = "Loop: OFF"
        loopBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 85)
    end
end)

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

    savePlaylistToLocal() -- Simpan urutan acak
    refreshPlaylistUI()
    statusLabel.Text = "Playlist diacak & Disimpan!"
end)

clearAllBtn.MouseButton1Click:Connect(function()
    if #playlist == 0 then
        statusLabel.Text = "Playlist kosong!"
        return
    end

    playlist = {}
    currentTrackIndex = 1
    sound:Stop()
    sound.SoundId = ""
    savePlaylistToLocal() -- Simpan status playlist kosong
    refreshPlaylistUI()
    statusLabel.Text = "Semua lagu dihapus!"
end)

-- Minimize & Restore Logic
minBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    miniIcon.Visible = true
end)

miniIcon.MouseButton1Click:Connect(function()
    miniIcon.Visible = false
    frame.Visible = true
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
    sliderKnob.Position = UDim2.new(relativeX, -6, 0.5, -6)

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
