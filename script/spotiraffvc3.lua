-- Raff Musik - Universal (Android & iOS)
-- Pemutar musik: cari lagu online, simpan ke playlist lokal, shuffle & auto-next.
-- Fitur: drag halus via RenderStepped, CoreGui persistence, seek/scrubbing stabil.
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
-- Alamat server (tunnel) tempat pencarian & download lagu diproses.
-- Ganti nilai ini jika alamat tunnel server berubah.
local SERVER_URL = "https://till-however-arts-zinc.trycloudflare.com"

-- Folder khusus proyek di dalam workspace executor (semua file Raff Musik disimpan di sini)
local PROJECT_FOLDER = "SpotiRaff"

-- Nama file daftar lagu (playlist) di dalam folder proyek
local PLAYLIST_FILE_NAME = "playlist.json"

-- Nama file playlist versi lama di root workspace (hanya dipakai untuk migrasi otomatis)
local OLD_JSON_FILE = "navyspotify_playlist.json"

-- Link gambar ikon untuk tombol toggle (diunduh sekali lalu disimpan lokal)
local TOGGLE_IMAGE_URL = "https://mvlrfq.github.io/Rafa/image/spotiraff.png"

-- Bersihkan instance lama jika script dijalankan ulang (termasuk nama lama dari versi sebelumnya)
for _, soundName in ipairs({ "RaffMusikSound", "NavySpotifySound" }) do
    local oldSound = SoundService:FindFirstChild(soundName)
    if oldSound then
        oldSound:Stop() -- hentikan lagu lama agar tidak bertumpuk
        oldSound:Destroy()
    end
end

for _, guiName in ipairs({ "RaffMusikUI", "NavySpotifyUI" }) do
    if CoreGui:FindFirstChild(guiName) then CoreGui[guiName]:Destroy() end
    if PlayerGui:FindFirstChild(guiName) then PlayerGui[guiName]:Destroy() end
end

-- Wadah utama seluruh UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RaffMusikUI"
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

-- Sudut membulat
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- Garis tepi jendela utama
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(40, 55, 80)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Bar atas (area untuk menggeser jendela)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, -40, 0, 32)
TopBar.BackgroundTransparency = 1
TopBar.Active = true
TopBar.Parent = MainFrame

-- Judul jendela "Raff Musik"
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.RichText = true -- agar tag <i> (italic) bisa dipakai
Title.Text = "<i>🎵 Raff Musik</i>"
Title.TextColor3 = Color3.fromRGB(240, 245, 255)
Title.TextSize = 12
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextTruncate = Enum.TextTruncate.AtEnd
Title.Parent = TopBar

-- Tombol minimize (menyembunyikan jendela)
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 24, 0, 24)
MinBtn.Position = UDim2.new(1, 6, 0, 4)
MinBtn.BackgroundColor3 = Color3.fromRGB(28, 38, 56)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 14
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = TopBar

-- Sudut membulat
local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1, 0)
MinCorner.Parent = MinBtn

-- Tombol ikon untuk membuka kembali jendela setelah di-minimize
local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Size = UDim2.new(0, 44, 0, 44)
ToggleBtn.Position = UDim2.new(0, 12, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
ToggleBtn.Image = ""
ToggleBtn.ScaleType = Enum.ScaleType.Crop
ToggleBtn.Visible = false
ToggleBtn.Parent = ScreenGui

-- Sudut membulat
local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleBtn

do -- emoji cadangan, disembunyikan otomatis jika gambar berhasil dimuat
    local ToggleText = Instance.new("TextLabel")
    ToggleText.Name = "ToggleText"
    ToggleText.Size = UDim2.new(1, 0, 1, 0)
    ToggleText.BackgroundTransparency = 1
    ToggleText.Text = "🎵"
    ToggleText.TextSize = 20
    ToggleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleText.Parent = ToggleBtn
end

-- Pegangan di pojok kanan bawah untuk mengubah ukuran jendela
local ResizeHandle = Instance.new("TextButton")
ResizeHandle.Size = UDim2.new(0, 16, 0, 16)
ResizeHandle.Position = UDim2.new(1, -16, 1, -16)
ResizeHandle.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
ResizeHandle.Text = "↘"
ResizeHandle.TextColor3 = Color3.fromRGB(255, 255, 255)
ResizeHandle.TextSize = 10
ResizeHandle.Font = Enum.Font.GothamBold
ResizeHandle.Parent = MainFrame

-- Sudut membulat
local ResizeCorner = Instance.new("UICorner")
ResizeCorner.CornerRadius = UDim.new(0, 4)
ResizeCorner.Parent = ResizeHandle

--------------------------------------------------------------------------------
-- 3. FIX ABSOLUT DRAG (RENDERSTEPPED - TANPA LONCAT/PERGESERAN SAMA SEKALI)
--------------------------------------------------------------------------------
-- Fungsi: membuat "frame" bisa digeser dengan menekan/menyentuh "handle".
-- Posisi dihitung tiap frame (RenderStepped) dari selisih posisi pointer,
-- lalu dibatasi agar jendela tidak keluar dari layar.
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

-- Aktifkan drag: jendela utama digeser lewat TopBar
SetupSmoothDrag(MainFrame, TopBar)
-- Aktifkan drag: tombol toggle bisa digeser langsung
SetupSmoothDrag(ToggleBtn, ToggleBtn)

-- LOGIKA RESIZE: ubah ukuran jendela dengan menyeret ResizeHandle (min 480x280, maks 850x550)
-- Resizing Logic
local isResizing = false
local startSize, startMousePos

-- Event: mulai resize saat pegangan ditekan (simpan ukuran & posisi awal)
ResizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = true
        startSize = MainFrame.Size
        startMousePos = input.Position
    end
end)

-- Event: saat pointer bergerak, hitung ukuran baru jendela
UserInputService.InputChanged:Connect(function(input)
    if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - startMousePos
        local newWidth = math.clamp(startSize.X.Offset + delta.X, 480, 850)
        local newHeight = math.clamp(startSize.Y.Offset + delta.Y, 280, 550)
        MainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
end)

-- Event: lepas pointer -> berhenti resize
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

-- Sudut membulat
local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 8)
SidebarCorner.Parent = Sidebar

-- Susunan vertikal otomatis untuk isi sidebar
local MenuLayout = Instance.new("UIListLayout")
MenuLayout.Padding = UDim.new(0, 6)
MenuLayout.Parent = Sidebar

-- Jarak dalam (padding) sidebar
local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 8)
SidebarPadding.PaddingLeft = UDim.new(0, 8)
SidebarPadding.PaddingRight = UDim.new(0, 8)
SidebarPadding.PaddingBottom = UDim.new(0, 8)
SidebarPadding.Parent = Sidebar

-- Tombol tab "Cari Lagu Online"
local TabSearchBtn = Instance.new("TextButton")
TabSearchBtn.Size = UDim2.new(1, 0, 0, 36)
TabSearchBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
TabSearchBtn.Text = "🔍 Cari Lagu Online"
TabSearchBtn.TextTruncate = Enum.TextTruncate.AtEnd
TabSearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TabSearchBtn.TextSize = 11
TabSearchBtn.Font = Enum.Font.GothamBold
TabSearchBtn.Parent = Sidebar

-- Sudut membulat
local TabSearchCorner = Instance.new("UICorner")
TabSearchCorner.CornerRadius = UDim.new(0, 6)
TabSearchCorner.Parent = TabSearchBtn

-- Tombol tab "Lagu Lokal" (playlist)
local TabLocalBtn = Instance.new("TextButton")
TabLocalBtn.Size = UDim2.new(1, 0, 0, 36)
TabLocalBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 58)
TabLocalBtn.Text = "💾 Lagu Lokal"
TabLocalBtn.TextTruncate = Enum.TextTruncate.AtEnd
TabLocalBtn.TextColor3 = Color3.fromRGB(180, 200, 220)
TabLocalBtn.TextSize = 11
TabLocalBtn.Font = Enum.Font.GothamBold
TabLocalBtn.Parent = Sidebar

-- Sudut membulat
local TabLocalCorner = Instance.new("UICorner")
TabLocalCorner.CornerRadius = UDim.new(0, 6)
TabLocalCorner.Parent = TabLocalBtn

-- Kotak indikator status server
local PingWidget = Instance.new("Frame")
PingWidget.Size = UDim2.new(1, 0, 0, 55)
PingWidget.Position = UDim2.new(0, 0, 1, -55)
PingWidget.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
PingWidget.ClipsDescendants = true
PingWidget.Parent = Sidebar

-- Sudut membulat
local PingCorner = Instance.new("UICorner")
PingCorner.CornerRadius = UDim.new(0, 6)
PingCorner.Parent = PingWidget

-- Judul kotak ping
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

-- Teks status server (Online/Terputus + ping), diperbarui oleh ping loop
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
ServerPingLabel.TextTruncate = Enum.TextTruncate.AtEnd
ServerPingLabel.Parent = PingWidget

--------------------------------------------------------------------------------
-- 5. KONTEN UTAMA KANAN
--------------------------------------------------------------------------------
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -170, 1, -40)
ContentArea.Position = UDim2.new(0, 164, 0, 34)
ContentArea.BackgroundTransparency = 1
ContentArea.ClipsDescendants = true
ContentArea.Parent = MainFrame

-- TAB 1: CARI LAGU ONLINE
local SearchView = Instance.new("Frame")
SearchView.Size = UDim2.new(1, 0, 1, -95)
SearchView.BackgroundTransparency = 1
SearchView.Visible = true
SearchView.Parent = ContentArea

-- Kotak input kata kunci pencarian
local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -58, 0, 32)
SearchBox.BackgroundColor3 = Color3.fromRGB(22, 30, 45)
SearchBox.PlaceholderText = "Cari lagu online..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(120, 135, 165)
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.TextSize = 11
SearchBox.Font = Enum.Font.Gotham
SearchBox.Parent = SearchView

-- Sudut membulat
local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 6)
SearchCorner.Parent = SearchBox

-- Tombol "Cari"
local SearchBtn = Instance.new("TextButton")
SearchBtn.Size = UDim2.new(0, 50, 0, 32)
SearchBtn.Position = UDim2.new(1, -50, 0, 0)
SearchBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
SearchBtn.Text = "Cari"
SearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBtn.TextSize = 11
SearchBtn.Font = Enum.Font.GothamBold
SearchBtn.Parent = SearchView

-- Sudut membulat
local SearchBtnCorner = Instance.new("UICorner")
SearchBtnCorner.CornerRadius = UDim.new(0, 6)
SearchBtnCorner.Parent = SearchBtn

-- Teks status pencarian/download
local SearchStatusLabel = Instance.new("TextLabel")
SearchStatusLabel.Size = UDim2.new(1, 0, 0, 16)
SearchStatusLabel.Position = UDim2.new(0, 0, 0, 36)
SearchStatusLabel.BackgroundTransparency = 1
SearchStatusLabel.Text = "Status Pencarian: Siap mencari..."
SearchStatusLabel.TextColor3 = Color3.fromRGB(150, 170, 200)
SearchStatusLabel.TextSize = 9
SearchStatusLabel.Font = Enum.Font.Gotham
SearchStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
SearchStatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
SearchStatusLabel.ClipsDescendants = true
SearchStatusLabel.Parent = SearchView

-- Daftar hasil pencarian (bisa di-scroll)
local SearchScroll = Instance.new("ScrollingFrame")
SearchScroll.Size = UDim2.new(1, 0, 1, -56)
SearchScroll.Position = UDim2.new(0, 0, 0, 56)
SearchScroll.BackgroundTransparency = 1
SearchScroll.BorderSizePixel = 0
SearchScroll.ScrollBarThickness = 3
SearchScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
SearchScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SearchScroll.Parent = SearchView

-- Susunan vertikal otomatis untuk hasil pencarian
local SearchScrollList = Instance.new("UIListLayout")
SearchScrollList.Padding = UDim.new(0, 4)
SearchScrollList.Parent = SearchScroll

-- TAB 2: LOCAL PLAYLIST
local LocalView = Instance.new("Frame")
LocalView.Size = UDim2.new(1, 0, 1, -95)
LocalView.BackgroundTransparency = 1
LocalView.Visible = false
LocalView.Parent = ContentArea

-- Bar judul playlist
local LocalActionBar = Instance.new("Frame")
LocalActionBar.Size = UDim2.new(1, 0, 0, 26)
LocalActionBar.BackgroundTransparency = 1
LocalActionBar.Parent = LocalView

-- Teks judul playlist + jumlah lagu
local LocalTitle = Instance.new("TextLabel")
LocalTitle.Size = UDim2.new(1, 0, 1, 0)
LocalTitle.BackgroundTransparency = 1
LocalTitle.Text = "💾 Playlist Lokal:"
LocalTitle.TextColor3 = Color3.fromRGB(80, 220, 120)
LocalTitle.TextSize = 10
LocalTitle.Font = Enum.Font.GothamBold
LocalTitle.TextXAlignment = Enum.TextXAlignment.Left
LocalTitle.TextTruncate = Enum.TextTruncate.AtEnd
LocalTitle.Parent = LocalActionBar

-- Daftar lagu di playlist (bisa di-scroll)
local LocalScroll = Instance.new("ScrollingFrame")
LocalScroll.Size = UDim2.new(1, 0, 1, -30)
LocalScroll.Position = UDim2.new(0, 0, 0, 30)
LocalScroll.BackgroundTransparency = 1
LocalScroll.BorderSizePixel = 0
LocalScroll.ScrollBarThickness = 3
LocalScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
LocalScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
LocalScroll.Parent = LocalView

-- Susunan vertikal otomatis untuk daftar lagu playlist
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
PlayerBar.ClipsDescendants = true
PlayerBar.Parent = ContentArea

-- Sudut membulat
local PlayerCorner = Instance.new("UICorner")
PlayerCorner.CornerRadius = UDim.new(0, 8)
PlayerCorner.Parent = PlayerBar

-- Judul lagu yang sedang diputar
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

-- Teks status player
local PlayerStatusLabel = Instance.new("TextLabel")
PlayerStatusLabel.Size = UDim2.new(1, -12, 0, 12)
PlayerStatusLabel.Position = UDim2.new(0, 6, 0, 20)
PlayerStatusLabel.BackgroundTransparency = 1
PlayerStatusLabel.Text = "Status: Standby"
PlayerStatusLabel.TextColor3 = Color3.fromRGB(140, 160, 190)
PlayerStatusLabel.TextSize = 8
PlayerStatusLabel.Font = Enum.Font.Gotham
PlayerStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
PlayerStatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
PlayerStatusLabel.Parent = PlayerBar

-- Seekable Progress Bar
local ProgressBg = Instance.new("TextButton")
ProgressBg.Size = UDim2.new(1, -12, 0, 6)
ProgressBg.Position = UDim2.new(0, 6, 0, 36)
ProgressBg.BackgroundColor3 = Color3.fromRGB(35, 48, 70)
ProgressBg.Text = ""
ProgressBg.AutoButtonColor = false
ProgressBg.Parent = PlayerBar

-- Sudut membulat
local ProgressBgCorner = Instance.new("UICorner")
ProgressBgCorner.CornerRadius = UDim.new(1, 0)
ProgressBgCorner.Parent = ProgressBg

-- Isi progress bar (menunjukkan posisi lagu)
local ProgressFill = Instance.new("Frame")
ProgressFill.Size = UDim2.new(0, 0, 1, 0)
ProgressFill.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
ProgressFill.BorderSizePixel = 0
ProgressFill.Parent = ProgressBg

-- Sudut membulat
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

-- Sudut membulat
local PrevCorner = Instance.new("UICorner")
PrevCorner.CornerRadius = UDim.new(0, 5)
PrevCorner.Parent = PrevBtn

-- Tombol play/pause
local PlayBtn = Instance.new("TextButton")
PlayBtn.Size = UDim2.new(0, 26, 0, 24)
PlayBtn.Position = UDim2.new(0, 34, 0, 52)
PlayBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
PlayBtn.Text = "▶"
PlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayBtn.TextSize = 10
PlayBtn.Font = Enum.Font.GothamBold
PlayBtn.Parent = PlayerBar

-- Sudut membulat
local PlayCorner = Instance.new("UICorner")
PlayCorner.CornerRadius = UDim.new(0, 5)
PlayCorner.Parent = PlayBtn

-- Tombol lagu berikutnya
local NextBtn = Instance.new("TextButton")
NextBtn.Size = UDim2.new(0, 24, 0, 24)
NextBtn.Position = UDim2.new(0, 64, 0, 52)
NextBtn.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
NextBtn.Text = "⏭"
NextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
NextBtn.TextSize = 10
NextBtn.Font = Enum.Font.GothamBold
NextBtn.Parent = PlayerBar

-- Sudut membulat
local NextCorner = Instance.new("UICorner")
NextCorner.CornerRadius = UDim.new(0, 5)
NextCorner.Parent = NextBtn

-- Tombol stop
local StopBtn = Instance.new("TextButton")
StopBtn.Size = UDim2.new(0, 24, 0, 24)
StopBtn.Position = UDim2.new(0, 92, 0, 52)
StopBtn.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
StopBtn.Text = "◼"
StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StopBtn.TextSize = 9
StopBtn.Font = Enum.Font.GothamBold
StopBtn.Parent = PlayerBar

-- Sudut membulat
local StopCorner = Instance.new("UICorner")
StopCorner.CornerRadius = UDim.new(0, 5)
StopCorner.Parent = StopBtn

-- Tombol ulang lagu (loop)
local LoopBtn = Instance.new("TextButton")
LoopBtn.Size = UDim2.new(0, 24, 0, 24)
LoopBtn.Position = UDim2.new(0, 120, 0, 52)
LoopBtn.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
LoopBtn.Text = "🔁"
LoopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LoopBtn.TextSize = 10
LoopBtn.Font = Enum.Font.GothamBold
LoopBtn.Parent = PlayerBar

-- Sudut membulat
local LoopCorner = Instance.new("UICorner")
LoopCorner.CornerRadius = UDim.new(0, 5)
LoopCorner.Parent = LoopBtn

-- Tombol acak urutan lagu (shuffle)
local ShuffleBtn = Instance.new("TextButton")
ShuffleBtn.Size = UDim2.new(0, 24, 0, 24)
ShuffleBtn.Position = UDim2.new(0, 148, 0, 52)
ShuffleBtn.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
ShuffleBtn.Text = "🔀"
ShuffleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ShuffleBtn.TextSize = 10
ShuffleBtn.Font = Enum.Font.GothamBold
ShuffleBtn.Parent = PlayerBar

-- Sudut membulat
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
TimeLabel.TextTruncate = Enum.TextTruncate.AtEnd
TimeLabel.Parent = PlayerBar

-- Volume Section
local VolIcon = Instance.new("TextLabel")
VolIcon.Size = UDim2.new(0, 14, 0, 24)
VolIcon.Position = UDim2.new(1, -128, 0, 52)
VolIcon.BackgroundTransparency = 1
VolIcon.Text = "🔊"
VolIcon.TextSize = 10
VolIcon.Parent = PlayerBar

-- Latar slider volume (bisa digeser)
local VolBg = Instance.new("TextButton")
VolBg.Size = UDim2.new(0, 70, 0, 5)
VolBg.Position = UDim2.new(1, -110, 0, 61)
VolBg.BackgroundColor3 = Color3.fromRGB(35, 48, 70)
VolBg.Text = ""
VolBg.Parent = PlayerBar

-- Sudut membulat
local VolBgCorner = Instance.new("UICorner")
VolBgCorner.CornerRadius = UDim.new(1, 0)
VolBgCorner.Parent = VolBg

-- Isi slider volume
local VolFill = Instance.new("Frame")
VolFill.Size = UDim2.new(0.5, 0, 1, 0)
VolFill.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
VolFill.BorderSizePixel = 0
VolFill.Parent = VolBg

-- Kotak angka volume (0-200)
local VolInputBox = Instance.new("TextBox")
VolInputBox.Size = UDim2.new(0, 32, 0, 20)
VolInputBox.Position = UDim2.new(1, -36, 0, 54)
VolInputBox.BackgroundColor3 = Color3.fromRGB(28, 38, 56)
VolInputBox.Text = "100"
VolInputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
VolInputBox.TextSize = 9
VolInputBox.Font = Enum.Font.GothamBold
VolInputBox.Parent = PlayerBar

-- Sudut membulat
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

-- Kotak modal konfirmasi hapus lagu
local ConfirmModal = Instance.new("Frame")
ConfirmModal.Size = UDim2.new(0, 260, 0, 120)
ConfirmModal.Position = UDim2.new(0.5, -130, 0.5, -60)
ConfirmModal.BackgroundColor3 = Color3.fromRGB(20, 28, 42)
ConfirmModal.ZIndex = 1001
ConfirmModal.Parent = ConfirmOverlay

-- Sudut membulat
local ConfirmCorner = Instance.new("UICorner")
ConfirmCorner.CornerRadius = UDim.new(0, 8)
ConfirmCorner.Parent = ConfirmModal

-- Judul modal konfirmasi hapus
local ConfirmTitle = Instance.new("TextLabel")
ConfirmTitle.Size = UDim2.new(1, -20, 0, 20)
ConfirmTitle.Position = UDim2.new(0, 10, 0, 10)
ConfirmTitle.BackgroundTransparency = 1
ConfirmTitle.Text = "⚠️ Konfirmasi Hapus"
ConfirmTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
ConfirmTitle.TextSize = 11
ConfirmTitle.Font = Enum.Font.GothamBold
ConfirmTitle.TextTruncate = Enum.TextTruncate.AtEnd
ConfirmTitle.TextXAlignment = Enum.TextXAlignment.Left
ConfirmTitle.ZIndex = 1002
ConfirmTitle.Parent = ConfirmModal

-- Isi pesan modal konfirmasi hapus
local ConfirmDesc = Instance.new("TextLabel")
ConfirmDesc.Size = UDim2.new(1, -20, 0, 36)
ConfirmDesc.Position = UDim2.new(0, 10, 0, 32)
ConfirmDesc.BackgroundTransparency = 1
ConfirmDesc.Text = "Apakah Anda yakin ingin menghapus lagu ini secara permanen dari perangkat?"
ConfirmDesc.TextColor3 = Color3.fromRGB(200, 210, 230)
ConfirmDesc.TextSize = 9
ConfirmDesc.Font = Enum.Font.Gotham
ConfirmDesc.TextWrapped = true
ConfirmDesc.TextTruncate = Enum.TextTruncate.AtEnd
ConfirmDesc.ZIndex = 1002
ConfirmDesc.Parent = ConfirmModal

-- Tombol "Batal" pada modal hapus
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

-- Sudut membulat
local CancelCorner = Instance.new("UICorner")
CancelCorner.CornerRadius = UDim.new(0, 5)
CancelCorner.Parent = CancelBtn

-- Tombol "Hapus" pada modal hapus
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

-- Sudut membulat
local ConfirmDelCorner = Instance.new("UICorner")
ConfirmDelCorner.CornerRadius = UDim.new(0, 5)
ConfirmDelCorner.Parent = ConfirmDeleteBtn

--------------------------------------------------------------------------------
-- 7B. MODAL INFO DOWNLOAD SELESAI
-- Muncul setelah lagu selesai didownload: tanya apakah lagu langsung diputar.
--------------------------------------------------------------------------------
-- Lapisan gelap penutup (menghalangi klik ke UI di belakang modal)
local DownloadOverlay = Instance.new("TextButton")
DownloadOverlay.Size = UDim2.new(1, 0, 1, 0)
DownloadOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
DownloadOverlay.BackgroundTransparency = 0.4
DownloadOverlay.AutoButtonColor = false
DownloadOverlay.Text = ""
DownloadOverlay.Visible = false
DownloadOverlay.ZIndex = 1100
DownloadOverlay.Parent = MainFrame

-- Kotak modal di tengah layar
local DownloadModal = Instance.new("Frame")
DownloadModal.Size = UDim2.new(0, 270, 0, 150)
DownloadModal.Position = UDim2.new(0.5, -135, 0.5, -75)
DownloadModal.BackgroundColor3 = Color3.fromRGB(20, 28, 42)
DownloadModal.ZIndex = 1101
DownloadModal.Parent = DownloadOverlay

-- Sudut membulat modal
local DownloadCorner = Instance.new("UICorner")
DownloadCorner.CornerRadius = UDim.new(0, 8)
DownloadCorner.Parent = DownloadModal

-- Judul modal (diubah lewat ShowDownloadModal)
local DownloadTitle = Instance.new("TextLabel")
DownloadTitle.Size = UDim2.new(1, -20, 0, 20)
DownloadTitle.Position = UDim2.new(0, 10, 0, 10)
DownloadTitle.BackgroundTransparency = 1
DownloadTitle.Text = "✅ Download Selesai"
DownloadTitle.TextColor3 = Color3.fromRGB(80, 220, 120)
DownloadTitle.TextSize = 11
DownloadTitle.Font = Enum.Font.GothamBold
DownloadTitle.TextTruncate = Enum.TextTruncate.AtEnd
DownloadTitle.TextXAlignment = Enum.TextXAlignment.Left
DownloadTitle.ZIndex = 1102
DownloadTitle.Parent = DownloadModal

-- Isi pesan modal: nama lagu + pertanyaan putar sekarang atau nanti
local DownloadDesc = Instance.new("TextLabel")
DownloadDesc.Size = UDim2.new(1, -20, 0, 66)
DownloadDesc.Position = UDim2.new(0, 10, 0, 34)
DownloadDesc.BackgroundTransparency = 1
DownloadDesc.Text = ""
DownloadDesc.TextColor3 = Color3.fromRGB(200, 210, 230)
DownloadDesc.TextSize = 9
DownloadDesc.Font = Enum.Font.Gotham
DownloadDesc.TextWrapped = true
DownloadDesc.TextTruncate = Enum.TextTruncate.AtEnd
DownloadDesc.TextXAlignment = Enum.TextXAlignment.Left
DownloadDesc.TextYAlignment = Enum.TextYAlignment.Top
DownloadDesc.ZIndex = 1102
DownloadDesc.Parent = DownloadModal

-- Tombol "Nanti" (tutup modal tanpa memutar)
local LaterBtn = Instance.new("TextButton")
LaterBtn.Size = UDim2.new(0, 110, 0, 26)
LaterBtn.Position = UDim2.new(0, 15, 1, -34)
LaterBtn.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
LaterBtn.Text = "Nanti"
LaterBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LaterBtn.TextSize = 10
LaterBtn.Font = Enum.Font.GothamBold
LaterBtn.ZIndex = 1102
LaterBtn.Parent = DownloadModal

-- Sudut membulat tombol "Nanti"
local LaterCorner = Instance.new("UICorner")
LaterCorner.CornerRadius = UDim.new(0, 5)
LaterCorner.Parent = LaterBtn

-- Tombol "Putar Sekarang" (putar lagu yang baru didownload)
local PlayNowBtn = Instance.new("TextButton")
PlayNowBtn.Size = UDim2.new(0, 110, 0, 26)
PlayNowBtn.Position = UDim2.new(1, -125, 1, -34)
PlayNowBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
PlayNowBtn.Text = "▶ Putar Sekarang"
PlayNowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayNowBtn.TextSize = 10
PlayNowBtn.Font = Enum.Font.GothamBold
PlayNowBtn.TextTruncate = Enum.TextTruncate.AtEnd
PlayNowBtn.ZIndex = 1102
PlayNowBtn.Parent = DownloadModal

-- Sudut membulat tombol "Putar Sekarang"
local PlayNowCorner = Instance.new("UICorner")
PlayNowCorner.CornerRadius = UDim.new(0, 5)
PlayNowCorner.Parent = PlayNowBtn

--------------------------------------------------------------------------------
-- 8. ANIMASI SKELETON LOADING
--------------------------------------------------------------------------------
-- Daftar animasi skeleton yang sedang berjalan (agar bisa dihentikan)
local activeSkeletonTweens = {}

-- Fungsi: menampilkan 4 kartu kerangka berkedip di "container" sebagai animasi loading
local function ShowSkeletonLoading(container)
    for _, child in pairs(container:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    activeSkeletonTweens = {}
    
    for i = 1, 4 do
        -- Kartu kerangka (skeleton) saat loading
        local SkelCard = Instance.new("Frame")
        SkelCard.Name = "SkeletonCard"
        SkelCard.Size = UDim2.new(1, 0, 0, 28)
        SkelCard.BackgroundColor3 = Color3.fromRGB(25, 33, 48)
        SkelCard.Parent = container
        
        -- Sudut membulat
        local SkelCorner = Instance.new("UICorner")
        SkelCorner.CornerRadius = UDim.new(0, 5)
        SkelCorner.Parent = SkelCard
        
        -- Garis berkedip di dalam kartu skeleton
        local PulseFrame = Instance.new("Frame")
        PulseFrame.Size = UDim2.new(0.6, 0, 0.5, 0)
        PulseFrame.Position = UDim2.new(0, 8, 0.25, 0)
        PulseFrame.BackgroundColor3 = Color3.fromRGB(40, 52, 75)
        PulseFrame.BorderSizePixel = 0
        PulseFrame.Parent = SkelCard
        
        -- Sudut membulat
        local PulseCorner = Instance.new("UICorner")
        PulseCorner.CornerRadius = UDim.new(0, 3)
        PulseCorner.Parent = PulseFrame
        
        local tweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
        local tween = TweenService:Create(PulseFrame, tweenInfo, { BackgroundTransparency = 0.7 })
        tween:Play()
        table.insert(activeSkeletonTweens, tween)
    end
end

-- Fungsi: menghentikan animasi skeleton dan menghapus kartunya dari "container"
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
-- Event: klik tab "Cari Lagu Online" -> tampilkan SearchView, sembunyikan LocalView, ubah warna tab
TabSearchBtn.MouseButton1Click:Connect(function()
    SearchView.Visible = true
    LocalView.Visible = false
    TabSearchBtn.BackgroundColor3 = Color3.fromRGB(41, 158, 239)
    TabSearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TabLocalBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 58)
    TabLocalBtn.TextColor3 = Color3.fromRGB(180, 200, 220)
end)

-- Event: klik tab "Lagu Lokal" -> tampilkan LocalView, sembunyikan SearchView, ubah warna tab
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
-- Alias fungsi file milik executor (nama fungsinya beda-beda antar executor,
-- jadi dicari satu per satu; kalau tidak ada nilainya nil)
local writefileFn = writefile or (syn and syn.writefile) -- menulis file ke workspace
local readfileFn = readfile or (syn and syn.readfile) -- membaca file dari workspace
local isfileFn = isfile or (syn and syn.isfile) -- cek apakah file ada
local delfileFn = delfile or (syn and syn.delfile) -- menghapus file
local getcustomassetFn = getcustomasset or getsynasset or (syn and syn.getcustomasset) -- ubah file lokal jadi asset yang bisa diputar Sound
local makefolderFn = makefolder or (syn and syn.makefolder) -- membuat folder
local isfolderFn = isfolder or (syn and syn.isfolder) -- cek apakah folder ada

-- Siapkan folder proyek agar file musik tidak bercampur dengan script lain
local folderReady = false
if makefolderFn then
    if isfolderFn and isfolderFn(PROJECT_FOLDER) then
        folderReady = true -- folder sudah ada
    else
        -- buat folder baru, lalu pastikan benar-benar terbentuk
        local okMake = pcall(makefolderFn, PROJECT_FOLDER)
        folderReady = okMake and (not isfolderFn or isfolderFn(PROJECT_FOLDER))
    end
end

-- Fungsi: menghasilkan path file di dalam folder proyek, contoh "SpotiRaff/playlist.json".
-- Jika folder tidak bisa dibuat (executor tidak mendukung), pakai nama file biasa di root workspace.
local function ProjectPath(name)
    if folderReady then return PROJECT_FOLDER .. "/" .. name end
    return name
end

-- STATE PLAYER --------------------------------------------------------------
local currentLocalIndex = 1 -- nomor urut lagu yang sedang/terakhir diputar di playlist
local isPlaylistMode = false -- true = setelah lagu selesai otomatis lanjut ke lagu berikutnya
local isShuffleMode = false -- true = urutan lagu diacak

-- Antrian shuffle: urutan acak berisi SEMUA lagu (berdasarkan id, bukan index,
-- karena index bergeser saat lagu ditambah/dihapus). Tiap lagu diputar tepat
-- sekali per putaran; antrian baru dibuat hanya setelah antrian habis.
local shuffleQueue = {}
local shuffleRoundStarted = false
local currentTrackKey = nil -- id lagu yang sedang diputar (dipakai untuk melacak lagu aktif)
local isTransitioning = false -- true saat script sedang ganti lagu (supaya event Ended palsu diabaikan)

-- Fungsi: mengambil "kunci unik" sebuah lagu (id, atau nama file jika id tidak ada)
local function ItemKey(item)
    return item.id or item.fileName
end

-- Fungsi: mengosongkan antrian shuffle (dipanggil saat shuffle diubah atau user memilih lagu manual)
local function ResetShuffleHistory()
    shuffleQueue = {}
    shuffleRoundStarted = false
end

-- Fungsi: membaca daftar lagu dari file playlist.json di folder proyek.
-- Mengembalikan tabel kosong jika file belum ada / rusak.
local function LoadLocalPlaylist()
    local jsonPath = ProjectPath(PLAYLIST_FILE_NAME)
    if isfileFn and isfileFn(jsonPath) then
        local success, content = pcall(function() return readfileFn(jsonPath) end)
        if success and content then
            local pSuccess, data = pcall(function() return HttpService:JSONDecode(content) end)
            if pSuccess and type(data) == "table" then return data end
        end
    end
    return {}
end

-- Fungsi: menyimpan daftar lagu ke file playlist.json di folder proyek
local function SaveLocalPlaylist(playlist)
    if writefileFn then
        pcall(function() writefileFn(ProjectPath(PLAYLIST_FILE_NAME), HttpService:JSONEncode(playlist)) end)
    end
end

-- MIGRASI: pindahkan playlist & lagu lama (yang tersimpan di root workspace)
-- ke folder proyek. Hanya berjalan jika file lama masih ada, lalu file lama dihapus.
do
    if folderReady and isfileFn and readfileFn and writefileFn and isfileFn(OLD_JSON_FILE) then
        -- baca & decode playlist lama
        local okRead, content = pcall(readfileFn, OLD_JSON_FILE)
        local okDec, data = false, nil
        if okRead and content then
            okDec, data = pcall(function() return HttpService:JSONDecode(content) end)
        end
        if okDec and type(data) == "table" then
            -- salin tiap file lagu ke folder baru, hapus yang lama jika salinan berhasil
            for _, item in ipairs(data) do
                local old = item.fileName
                if old and isfileFn(old) then
                    local newPath = ProjectPath(old)
                    pcall(function()
                        if not isfileFn(newPath) then writefileFn(newPath, readfileFn(old)) end
                        if isfileFn(newPath) and delfileFn then delfileFn(old) end
                    end)
                end
            end
            -- simpan playlist ke lokasi baru (jangan timpa jika playlist baru sudah ada)
            if not isfileFn(ProjectPath(PLAYLIST_FILE_NAME)) then
                SaveLocalPlaylist(data)
            end
            -- hapus playlist lama setelah playlist baru dipastikan ada
            if isfileFn(ProjectPath(PLAYLIST_FILE_NAME)) and delfileFn then
                pcall(delfileFn, OLD_JSON_FILE)
            end
        end
    end
end

--------------------------------------------------------------------------------
-- KOMUNIKASI SERVER
-- Server yang dipakai (alamat di SERVER_URL):
--   GET  /api/status          -> cek server hidup + hitung ping
--   GET  /api/search?q=...    -> cari lagu online
--   POST /api/download        -> minta server menyiapkan file audio lagu
--   GET  /stream/<fileName>   -> ambil file audio hasil download dari server
--------------------------------------------------------------------------------

-- Fungsi: mengirim HTTP request memakai fungsi request milik executor.
-- Parameter reqData: tabel { Url=..., Method=..., Headers=..., Body=... }
-- Mengembalikan tabel response (StatusCode, Body, ...) atau nil jika gagal/tidak didukung.
local function customRequest(reqData)
    -- cari fungsi request yang tersedia di executor
    local req = (syn and syn.request) or request or http_request or (http and http.request)
    if not req then return nil end
    reqData.Headers = reqData.Headers or {}
    -- header ini dibutuhkan agar tunnel (Cloudflare/localtunnel) tidak menampilkan halaman peringatan
    reqData.Headers["bypass-tunnel-reminder"] = "true"
    -- pcall supaya error jaringan tidak mematikan script
    local success, response = pcall(function() return req(reqData) end)
    if not success then return nil end
    return response
end

-- Muat ikon tombol toggle dari link gambar (berjalan di background).
-- Gambar diunduh sekali, disimpan di folder proyek, lalu dipakai ulang tanpa download lagi.
task.spawn(function()
    if not (getcustomassetFn and writefileFn and isfileFn) then return end
    local iconPath = ProjectPath("toggle_icon.png")

    -- Fungsi: pasang file gambar lokal ke tombol toggle & sembunyikan emoji cadangan
    local function applyIcon()
        local ok, asset = pcall(getcustomassetFn, iconPath)
        if ok and asset and asset ~= "" then
            ToggleBtn.Image = asset
            local fallback = ToggleBtn:FindFirstChild("ToggleText")
            if fallback then fallback.Visible = false end
            return true
        end
        return false
    end

    -- jika gambar sudah pernah diunduh, langsung pakai
    if isfileFn(iconPath) and applyIcon() then return end

    -- SERVER: unduh gambar dari link, simpan, lalu pasang
    local res = customRequest({ Url = TOGGLE_IMAGE_URL, Method = "GET" })
    if res and res.StatusCode == 200 and res.Body and #res.Body > 0 then
        pcall(function() writefileFn(iconPath, res.Body) end)
        applyIcon()
    end
end)

-- Ping loop (background): tiap 5 detik cek server lewat /api/status
-- lalu tampilkan status Online/Terputus beserta ping (ms) di kotak sidebar.
task.spawn(function()
    while task.wait(5) do
        -- ukur waktu respon server
        local startTime = os.clock()
        local res = customRequest({ Url = SERVER_URL .. "/api/status", Method = "GET" })
        local latency = math.floor((os.clock() - startTime) * 1000)

        if res and res.StatusCode == 200 then
            -- server merespons normal
            ServerPingLabel.Text = string.format("🟢 Online\nPing: %d ms", latency)
            ServerPingLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
        else
            -- server tidak merespons / error
            ServerPingLabel.Text = "🔴 Terputus!"
            ServerPingLabel.TextColor3 = Color3.fromRGB(240, 80, 80)
        end
    end
end)

--------------------------------------------------------------------------------
-- ENGINE SUARA
--------------------------------------------------------------------------------

-- Objek Sound tunggal yang dipakai untuk memutar semua lagu
local CurrentSound = Instance.new("Sound")
CurrentSound.Name = "RaffMusikSound"
CurrentSound.Volume = 1
CurrentSound.Parent = SoundService

-- Update progress bar & label waktu setiap frame saat lagu diputar
RunService.RenderStepped:Connect(function()
    if CurrentSound.IsPlaying and CurrentSound.TimeLength > 0 then
        -- hitung persentase lagu yang sudah diputar
        local alpha = math.clamp(CurrentSound.TimePosition / CurrentSound.TimeLength, 0, 1)
        ProgressFill.Size = UDim2.new(alpha, 0, 1, 0)
        -- ubah detik menjadi format mm:ss
        local m1, s1 = math.floor(CurrentSound.TimePosition / 60), math.floor(CurrentSound.TimePosition % 60)
        local m2, s2 = math.floor(CurrentSound.TimeLength / 60), math.floor(CurrentSound.TimeLength % 60)
        TimeLabel.Text = string.format("%02d:%02d/%02d:%02d", m1, s1, m2, s2)
    elseif not CurrentSound.IsPlaying and CurrentSound.TimePosition == 0 then
        -- tidak ada lagu berjalan: kosongkan progress bar
        ProgressFill.Size = UDim2.new(0, 0, 1, 0)
    end
end)

-- Deklarasi awal (forward declaration) supaya bisa dipakai di handler Ended sebelum fungsinya didefinisikan
local PlayLocalTrackIndex
local PickShuffleIndex

-- Event: lagu selesai diputar -> otomatis lanjut ke lagu berikutnya jika mode playlist aktif
CurrentSound.Ended:Connect(function()
    -- abaikan Ended palsu yang muncul saat kita sendiri sedang Stop()/ganti lagu
    if isTransitioning then return end
    PlayBtn.Text = "▶"
    PlayerStatusLabel.Text = "Status: Selesai"

    if isPlaylistMode then
        local playlist = LoadLocalPlaylist()
        if #playlist > 0 then
            if isShuffleMode then
                -- mode acak: ambil lagu berikutnya dari antrian shuffle
                currentLocalIndex = PickShuffleIndex(playlist)
            else
                -- mode biasa: lagu berikutnya, kembali ke lagu pertama setelah lagu terakhir
                currentLocalIndex = currentLocalIndex + 1
                if currentLocalIndex > #playlist then
                    currentLocalIndex = 1
                end
            end
            PlayLocalTrackIndex(currentLocalIndex)
        end
    end
end)

-- Fungsi: memilih nomor urut lagu berikutnya untuk mode shuffle.
-- Semua lagu diacak jadi satu antrian; tiap lagu diputar sekali per putaran
-- sehingga tidak ada lagu yang berulang sebelum semua lagu kebagian.
PickShuffleIndex = function(playlist)
    local total = #playlist
    if total <= 1 then return 1 end

    -- cari nomor urut lagu berdasarkan id-nya
    local function findIndex(key)
        for i, item in ipairs(playlist) do
            if ItemKey(item) == key then return i end
        end
        return nil
    end

    -- buat antrian acak baru (algoritma Fisher-Yates)
    local function rebuild(excludeCurrent)
        shuffleQueue = {}
        for _, item in ipairs(playlist) do
            local key = ItemKey(item)
            if not (excludeCurrent and key == currentTrackKey) then
                table.insert(shuffleQueue, key)
            end
        end
        for i = #shuffleQueue, 2, -1 do
            local j = math.random(1, i)
            shuffleQueue[i], shuffleQueue[j] = shuffleQueue[j], shuffleQueue[i]
        end
        -- putaran baru: jangan mulai dengan lagu yang baru saja selesai
        if not excludeCurrent and #shuffleQueue > 1 and shuffleQueue[1] == currentTrackKey then
            local j = math.random(2, #shuffleQueue)
            shuffleQueue[1], shuffleQueue[j] = shuffleQueue[j], shuffleQueue[1]
        end
    end

    if #shuffleQueue == 0 then
        -- pertama kali setelah reset: lagu yang sedang diputar dianggap sudah dimainkan
        rebuild(not shuffleRoundStarted)
        shuffleRoundStarted = true
    end

    -- ambil dari antrian, lewati lagu yang sudah dihapus / sedang diputar
    while #shuffleQueue > 0 do
        local key = table.remove(shuffleQueue, 1)
        local idx = findIndex(key)
        if idx and key ~= currentTrackKey then
            return idx
        end
    end

    -- antrian habis karena entri tidak valid: mulai putaran baru
    rebuild(false)
    local key = table.remove(shuffleQueue, 1)
    return (key and findIndex(key)) or ((currentLocalIndex % total) + 1)
end

-- Fungsi: memutar lagu ke-"index" dari playlist lokal.
-- Mengambil file dari folder proyek, mengubahnya jadi asset, lalu memutarnya.
PlayLocalTrackIndex = function(index)
    local playlist = LoadLocalPlaylist()
    if #playlist > 0 and playlist[index] then
        currentLocalIndex = index
        local item = playlist[index]
        currentTrackKey = ItemKey(item)

        TrackTitle.Text = "🎵 " .. item.title

        -- tandai sedang ganti lagu (agar event Ended palsu diabaikan)
        isTransitioning = true
        local ok = pcall(function()
            if isfileFn and isfileFn(ProjectPath(item.fileName)) then
                PlayerStatusLabel.Text = "Status: 📂 Memuat file..."
                local assetUrl = getcustomassetFn(ProjectPath(item.fileName))

                -- hentikan lagu sebelumnya, pasang lagu baru
                CurrentSound:Stop()
                CurrentSound.TimePosition = 0
                CurrentSound.SoundId = assetUrl

                task.wait(0.1) -- beri waktu agar asset termuat
                CurrentSound:Play()
                PlayBtn.Text = "⏸"
                PlayerStatusLabel.Text = "Status: 🟢 Memutar Lagu"
            else
                PlayerStatusLabel.Text = "Status: ❌ File lagu hilang!"
            end
        end)
        isTransitioning = false
        if not ok then
            PlayerStatusLabel.Text = "Status: ❌ Gagal memutar lagu"
        end
    end
end

-- Event: tombol play/pause (pause jika sedang main, lanjut/putar jika sedang berhenti)
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

-- Event: tombol stop (hentikan lagu & reset progress bar)
StopBtn.MouseButton1Click:Connect(function()
    CurrentSound:Stop()
    CurrentSound.TimePosition = 0
    PlayBtn.Text = "▶"
    ProgressFill.Size = UDim2.new(0, 0, 1, 0)
    PlayerStatusLabel.Text = "Status: Stopped"
end)

-- Event: tombol lagu berikutnya (acak jika shuffle aktif, berurutan jika tidak)
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

-- Event: tombol lagu sebelumnya (kembali ke lagu terakhir jika sudah di awal)
PrevBtn.MouseButton1Click:Connect(function()
    local playlist = LoadLocalPlaylist()
    if #playlist > 0 then
        isPlaylistMode = true
        currentLocalIndex = currentLocalIndex - 1
        if currentLocalIndex < 1 then currentLocalIndex = #playlist end
        PlayLocalTrackIndex(currentLocalIndex)
    end
end)

-- Event: tombol loop (ulang lagu yang sama terus-menerus)
LoopBtn.MouseButton1Click:Connect(function()
    CurrentSound.Looped = not CurrentSound.Looped
    LoopBtn.BackgroundColor3 = CurrentSound.Looped and Color3.fromRGB(41, 158, 239) or Color3.fromRGB(40, 52, 75)
end)

-- SEEK / SCRUBBING: klik atau geser progress bar untuk memajukan/memundurkan lagu
-- SCRUBBING FIX
local isSeeking = false
local wasPlayingBeforeSeek = false

-- Fungsi: mengubah posisi lagu sesuai posisi klik/geser pada progress bar
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

-- Event: mulai seek saat progress bar ditekan (lagu di-pause sementara agar tidak patah-patah)
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

-- Event: saat pointer digeser, perbarui posisi lagu
UserInputService.InputChanged:Connect(function(input)
    if isSeeking and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateSeekPosition(input)
    end
end)

-- VOLUME: geser slider atau ketik angka 0-200 untuk mengatur volume
-- Volume Dragging
local settingVol = false

-- Fungsi: mengubah volume sesuai posisi pointer pada slider (0%-200%)
local function UpdateVol(input)
    local alpha = math.clamp((input.Position.X - VolBg.AbsolutePosition.X) / VolBg.AbsoluteSize.X, 0, 1)
    VolFill.Size = UDim2.new(alpha, 0, 1, 0)
    local volVal = alpha * 2
    CurrentSound.Volume = volVal
    VolInputBox.Text = tostring(math.floor(volVal * 100))
end

-- Event: mulai atur volume saat slider ditekan
VolBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        settingVol = true
        UpdateVol(input)
    end
end)

-- Event: saat pointer digeser, perbarui volume
UserInputService.InputChanged:Connect(function(input)
    if settingVol and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateVol(input)
    end
end)

-- Event: lepas pointer -> selesai mengatur volume
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        settingVol = false
    end
end)

-- Event: setelah mengetik angka volume, validasi lalu terapkan (kembali ke nilai lama jika bukan angka)
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

-- Event: minimize -> sembunyikan jendela, tampilkan tombol toggle
MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    ToggleBtn.Visible = true
end)

-- Event: klik tombol toggle -> tampilkan kembali jendela
ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    ToggleBtn.Visible = false
end)

--------------------------------------------------------------------------------
-- 11. RENDER LOCAL PLAYLIST & DIALOG KONFIRMASI HAPUS
--------------------------------------------------------------------------------
-- Deklarasi awal fungsi RenderLocalPlaylist (dipakai oleh fungsi lain sebelum didefinisikan)
local RenderLocalPlaylist
-- Nomor urut lagu yang menunggu konfirmasi hapus (nil = tidak ada)
local pendingDeleteIndex = nil

-- Fungsi: menggambar ulang daftar lagu di tab "Lagu Lokal" dari file playlist.
-- Setiap lagu punya tombol putar dan tombol hapus.
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
        -- Kartu pembungkus satu lagu
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, 28)
        Card.BackgroundColor3 = Color3.fromRGB(22, 34, 48)
        Card.Parent = LocalScroll
        
        -- Sudut membulat
        local CardCorner = Instance.new("UICorner")
        CardCorner.CornerRadius = UDim.new(0, 5)
        CardCorner.Parent = Card
        
        -- Tombol judul lagu (klik = putar lagu ini)
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
        
        -- Tombol hapus lagu
        local DeleteBtn = Instance.new("TextButton")
        DeleteBtn.Size = UDim2.new(0, 22, 0, 20)
        DeleteBtn.Position = UDim2.new(1, -24, 0, 4)
        DeleteBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 60)
        DeleteBtn.Text = "🗑️"
        DeleteBtn.TextSize = 9
        DeleteBtn.Parent = Card
        
        -- Sudut membulat
        local DelCorner = Instance.new("UICorner")
        DelCorner.CornerRadius = UDim.new(0, 4)
        DelCorner.Parent = DeleteBtn
        
        -- Klik judul lagu: aktifkan mode playlist (lanjut otomatis ke lagu berikutnya) lalu putar lagu ini
        PlayLocalBtn.MouseButton1Click:Connect(function()
            isPlaylistMode = true
            ResetShuffleHistory()
            PlayLocalTrackIndex(idx)
        end)
        
        -- Klik tombol hapus: simpan nomor lagu lalu tampilkan modal konfirmasi
        DeleteBtn.MouseButton1Click:Connect(function()
            pendingDeleteIndex = idx
            ConfirmOverlay.Visible = true
        end)
    end
end

-- Event: "Batal" pada modal hapus -> tutup modal tanpa menghapus
CancelBtn.MouseButton1Click:Connect(function()
    pendingDeleteIndex = nil
    ConfirmOverlay.Visible = false
end)

-- Event: "Hapus" pada modal hapus -> hapus file lagu dari folder proyek & dari playlist
ConfirmDeleteBtn.MouseButton1Click:Connect(function()
    if pendingDeleteIndex then
        local playlist = LoadLocalPlaylist()
        local item = playlist[pendingDeleteIndex]
        if item then
            if delfileFn and isfileFn and isfileFn(ProjectPath(item.fileName)) then
                pcall(function() delfileFn(ProjectPath(item.fileName)) end)
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

-- Event: tombol shuffle -> nyalakan/matikan mode acak (antrian acak dibuat ulang)
ShuffleBtn.MouseButton1Click:Connect(function()
    isShuffleMode = not isShuffleMode
    ResetShuffleHistory()
    ShuffleBtn.BackgroundColor3 = isShuffleMode and Color3.fromRGB(41, 158, 239) or Color3.fromRGB(40, 52, 75)
end)

--------------------------------------------------------------------------------
-- 12. DOWNLOAD & PENCARIAN LAGU ONLINE
--------------------------------------------------------------------------------

-- id lagu yang akan diputar jika user menekan "Putar Sekarang" di modal download
local pendingPlayId = nil

-- Fungsi: menampilkan modal info download.
-- title/desc = teks yang ditampilkan, id = id lagu yang ditawarkan untuk diputar.
local function ShowDownloadModal(title, desc, id)
    pendingPlayId = id
    DownloadTitle.Text = title
    DownloadDesc.Text = desc
    DownloadOverlay.Visible = true
end

-- Tombol "Nanti": tutup modal, lagu yang sedang berjalan tidak terganggu
LaterBtn.MouseButton1Click:Connect(function()
    pendingPlayId = nil
    DownloadOverlay.Visible = false
end)

-- Tombol "Putar Sekarang": tutup modal lalu putar lagu yang baru didownload
PlayNowBtn.MouseButton1Click:Connect(function()
    local id = pendingPlayId
    pendingPlayId = nil
    DownloadOverlay.Visible = false
    if not id then return end

    -- cari lagu tersebut di playlist lalu putar
    local playlist = LoadLocalPlaylist()
    for idx, item in ipairs(playlist) do
        if item.id == id then
            isPlaylistMode = true -- setelah selesai lanjut ke lagu berikutnya
            ResetShuffleHistory()
            PlayLocalTrackIndex(idx)
            return
        end
    end
end)

-- Fungsi: download lagu dari server lalu simpan ke playlist lokal.
-- Lagu TIDAK langsung diputar; setelah selesai muncul modal yang menanyakan
-- apakah ingin diputar sekarang, supaya lagu yang sedang berjalan tidak terganggu.
-- Parameter: id = id lagu dari hasil pencarian, name = judul lagu.
local function DownloadSong(id, name)
    -- 1) Jika lagu sudah ada di playlist, tidak perlu download ulang
    local existing = LoadLocalPlaylist()
    for _, p in ipairs(existing) do
        if p.id == id then
            SearchStatusLabel.Text = "Status Pencarian: ℹ️ Lagu sudah ada di playlist"
            SearchStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
            ShowDownloadModal("ℹ️ Lagu Sudah Ada", "\"" .. tostring(name) .. "\" sudah ada di playlist. Putar sekarang?", id)
            return
        end
    end

    SearchStatusLabel.Text = "Status Pencarian: ⏳ Mendownload " .. tostring(name) .. "..."
    SearchStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)

    -- Proses jaringan dijalankan di thread terpisah agar UI tidak membeku
    task.spawn(function()
        -- 2) SERVER: minta server menyiapkan file audio (POST /api/download)
        local body = HttpService:JSONEncode({ videoId = id, title = name })
        local res = customRequest({
            Url = SERVER_URL .. "/api/download",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body
        })

        if res and res.Body then
            -- 3) Baca jawaban server (JSON berisi success & fileName)
            local success, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
            if success and data and data.success and data.fileName then
                SearchStatusLabel.Text = "Status Pencarian: 💾 Menyimpan file lokal..."

                -- 4) SERVER: ambil file audio hasil download (GET /stream/<fileName>)
                local streamUrl = SERVER_URL .. "/stream/" .. data.fileName
                local okGet, audioBinary = pcall(function() return game:HttpGet(streamUrl) end)
                if not okGet or not audioBinary or #audioBinary == 0 then
                    SearchStatusLabel.Text = "Status Pencarian: ❌ Gagal mengambil file audio"
                    SearchStatusLabel.TextColor3 = Color3.fromRGB(240, 80, 80)
                    return
                end

                -- 5) Simpan file audio ke folder proyek
                local safeLocalFileName = "raff_song_" .. id .. ".mp3"
                if writefileFn then
                    pcall(function() writefileFn(ProjectPath(safeLocalFileName), audioBinary) end)
                end

                -- 6) Tambahkan ke playlist (di urutan paling atas)
                local playlist = LoadLocalPlaylist()
                table.insert(playlist, 1, { id = id, title = name, fileName = safeLocalFileName })
                SaveLocalPlaylist(playlist)

                -- karena lagu baru disisipkan di urutan 1, geser nomor urut lagu yang sedang aktif
                if currentTrackKey ~= nil then currentLocalIndex = currentLocalIndex + 1 end
                if pendingDeleteIndex then pendingDeleteIndex = pendingDeleteIndex + 1 end
                RenderLocalPlaylist()

                SearchStatusLabel.Text = "Status Pencarian: 🟢 Berhasil terdownload & disimpan!"
                SearchStatusLabel.TextColor3 = Color3.fromRGB(80, 220, 120)

                -- 7) Tanyakan ke user: putar sekarang atau nanti (audio yang berjalan tidak diganggu)
                ShowDownloadModal(
                    "✅ Download Selesai",
                    "\"" .. tostring(name) .. "\" sudah masuk ke playlist. Putar sekarang? Pilih Nanti agar lagu yang sedang berjalan tidak terganggu.",
                    id
                )
            else
                -- server membalas tapi gagal memproses
                SearchStatusLabel.Text = "Status Pencarian: ❌ Gagal memproses server"
                SearchStatusLabel.TextColor3 = Color3.fromRGB(240, 80, 80)
            end
        else
            -- tidak ada balasan dari server
            SearchStatusLabel.Text = "Status Pencarian: ❌ Koneksi server gagal"
            SearchStatusLabel.TextColor3 = Color3.fromRGB(240, 80, 80)
        end
    end)
end

-- Fungsi: mencari lagu online lewat server dan menampilkan hasilnya sebagai daftar.
-- Mengklik salah satu hasil akan men-download lagu tersebut (DownloadSong).
local function ExecuteSearch()
    -- jangan cari jika kotak pencarian kosong
    if SearchBox.Text == "" then return end

    -- tampilkan animasi loading sambil menunggu server
    ShowSkeletonLoading(SearchScroll)
    SearchStatusLabel.Text = "Status Pencarian: ⏳ Mencari lagu online..."
    SearchStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)

    -- Proses jaringan dijalankan di thread terpisah agar UI tidak membeku
    task.spawn(function()
        -- SERVER: cari lagu (GET /api/search?q=kata_kunci)
        local searchUrl = SERVER_URL .. "/api/search?q=" .. HttpService:UrlEncode(SearchBox.Text)
        local res = customRequest({ Url = searchUrl, Method = "GET" })

        -- hentikan animasi loading
        ClearSkeletonLoading(SearchScroll)

        if res and res.Body then
            -- baca jawaban server (JSON berisi daftar results)
            local success, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
            if success and data and data.success and data.results and #data.results > 0 then
                -- buat satu kartu untuk setiap lagu hasil pencarian
                for _, song in ipairs(data.results) do
                    -- kartu pembungkus satu hasil lagu
                    local Card = Instance.new("Frame")
                    Card.Size = UDim2.new(1, 0, 0, 28)
                    Card.BackgroundColor3 = Color3.fromRGB(26, 36, 54)
                    Card.Parent = SearchScroll

                    -- sudut membulat kartu
                    local CardCorner = Instance.new("UICorner")
                    CardCorner.CornerRadius = UDim.new(0, 5)
                    CardCorner.Parent = Card

                    -- tombol judul lagu (klik = download ke playlist)
                    local SongBtn = Instance.new("TextButton")
                    SongBtn.Size = UDim2.new(1, -6, 1, 0)
                    SongBtn.Position = UDim2.new(0, 4, 0, 0)
                    SongBtn.BackgroundTransparency = 1
                    -- tampilkan nama pengunggah hanya jika datanya ada
                    SongBtn.Text = "⬇ " .. tostring(song.title) .. (song.uploader and (" (" .. tostring(song.uploader) .. ")") or "")
                    SongBtn.TextColor3 = Color3.fromRGB(220, 235, 255)
                    SongBtn.TextXAlignment = Enum.TextXAlignment.Left
                    SongBtn.TextSize = 10
                    SongBtn.Font = Enum.Font.Gotham
                    SongBtn.TextTruncate = Enum.TextTruncate.AtEnd
                    SongBtn.Parent = Card

                    -- klik hasil -> download lagu ke playlist lokal
                    SongBtn.MouseButton1Click:Connect(function()
                        DownloadSong(song.id, song.title)
                    end)
                end
                SearchStatusLabel.Text = string.format("Status Pencarian: 🟢 Ditemukan %d lagu", #data.results)
                SearchStatusLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
            else
                -- server membalas tapi tidak ada hasil
                SearchStatusLabel.Text = "Status Pencarian: ⚠️ Lagu tidak ditemukan!"
                SearchStatusLabel.TextColor3 = Color3.fromRGB(240, 80, 80)
            end
        else
            -- tidak ada balasan dari server
            SearchStatusLabel.Text = "Status Pencarian: ❌ Server tidak merespons!"
            SearchStatusLabel.TextColor3 = Color3.fromRGB(240, 80, 80)
        end
    end)
end

-- Jalankan pencarian saat tombol "Cari" ditekan atau saat menekan Enter di kotak pencarian
SearchBtn.MouseButton1Click:Connect(ExecuteSearch)
SearchBox.FocusLost:Connect(ExecuteSearch)

-- Tampilkan playlist lokal saat script pertama kali dijalankan
RenderLocalPlaylist()
