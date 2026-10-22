-- Raff Musik - Universal (Android & iOS)
-- Pemutar musik: cari lagu online (NexaDev API), simpan ke playlist, shuffle & auto-next.
-- Fitur: drag halus via RenderStepped, CoreGui persistence, seek/scrubbing stabil,
--        playlist dengan sort & filter, folder lagu manual (imports), panduan pengguna.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

--------------------------------------------------------------------------------
-- 1. KONFIGURASI
--------------------------------------------------------------------------------
-- Alamat API pencarian lagu. Judul/kata kunci lagu ditambahkan setelah "q=".
-- Contoh: https://api.nexadev.my.id/api/spotifyplay?q=starboy
local API_URL = "https://api.nexadev.my.id/api/spotifyplay?q="

-- Batas waktu menunggu server (dalam detik). Ubah sesuai kebutuhan.
-- Jika lewat dari batas ini, muncul pesan "Server tidak merespon...".
local SEARCH_TIMEOUT = 15   -- batas waktu pencarian lagu
local DOWNLOAD_TIMEOUT = 60 -- batas waktu seluruh proses download lagu

-- Folder utama proyek di dalam workspace executor
local PROJECT_FOLDER = "SpotiRaff"

-- Subfolder di dalam folder utama (tiap jenis penyimpanan punya folder sendiri)
local DATA_FOLDER = "data"       -- berisi playlist.json
local SONGS_FOLDER = "songs"     -- mp3 hasil download
local COVERS_FOLDER = "covers"   -- thumbnail/cover lagu
local IMPORTS_FOLDER = "imports" -- mp3/ogg milik user (dimasukkan manual)
local ICONS_FOLDER = "icons"     -- ikon tombol toggle

-- Nama file daftar lagu (playlist) di dalam folder data
local PLAYLIST_FILE_NAME = "playlist.json"

-- Link gambar ikon untuk tombol toggle (diunduh sekali lalu disimpan lokal).
-- Ikon ini juga dipakai sebagai gambar cadangan jika cover lagu gagal dimuat.
local TOGGLE_IMAGE_URL = "https://mvlrfq.github.io/Rafa/image/spotiraff.png"

-- Pesan standar jika server tidak mengirim data apa pun
local MSG_NO_RESPONSE = "Server tidak merespon, coba lagi setelah beberapa saat!"

-- Palet warna (selaras dengan UI utama)
local C = {
    bg = Color3.fromRGB(15, 20, 30),
    panel = Color3.fromRGB(20, 26, 38),
    card = Color3.fromRGB(20, 28, 42),
    field = Color3.fromRGB(22, 30, 45),
    accent = Color3.fromRGB(41, 158, 239),
    accentSoft = Color3.fromRGB(120, 190, 245),
    btn = Color3.fromRGB(40, 52, 75),
    btnDark = Color3.fromRGB(28, 38, 56),
    stroke = Color3.fromRGB(40, 55, 80),
    track = Color3.fromRGB(35, 48, 70),
    text = Color3.fromRGB(240, 245, 255),
    sub = Color3.fromRGB(150, 170, 200),
    dim = Color3.fromRGB(120, 135, 165),
    ok = Color3.fromRGB(80, 220, 120),
    warn = Color3.fromRGB(255, 200, 80),
    err = Color3.fromRGB(240, 80, 80),
    play = Color3.fromRGB(46, 170, 104),
    rowActive = Color3.fromRGB(28, 40, 60),
}

--------------------------------------------------------------------------------
-- 2. SIKLUS HIDUP (BERSIH-BERSIH SAAT DITUTUP / DIJALANKAN ULANG)
--------------------------------------------------------------------------------
-- Tempat menyimpan fungsi penutup agar script lama berhenti total jika dijalankan ulang
local GlobalEnv = (getgenv and getgenv()) or _G
if GlobalEnv.RaffMusikShutdown then
    pcall(GlobalEnv.RaffMusikShutdown)
    GlobalEnv.RaffMusikShutdown = nil
end

-- Sisa instance lama (jika ada) dibersihkan agar UI/suara tidak bertumpuk
do
    local oldSound = SoundService:FindFirstChild("RaffMusikSound")
    if oldSound then
        oldSound:Stop() -- hentikan lagu lama agar tidak bertumpuk
        oldSound:Destroy()
    end
    if CoreGui:FindFirstChild("RaffMusikUI") then CoreGui.RaffMusikUI:Destroy() end
    if PlayerGui:FindFirstChild("RaffMusikUI") then PlayerGui.RaffMusikUI:Destroy() end
end

-- true setelah user menutup UI lewat tombol X (semua proses berhenti)
local isClosed = false
-- Semua koneksi event global dicatat di sini supaya bisa diputus saat ditutup
local trackedConnections = {}
local function Track(conn)
    table.insert(trackedConnections, conn)
    return conn
end

-- Helper pembuat instance: Create("Frame", { properti... }, parent)
local function Create(className, props, parent)
    local inst = Instance.new(className)
    if props then
        for key, value in pairs(props) do inst[key] = value end
    end
    if parent then inst.Parent = parent end
    return inst
end

-- Helper: sudut membulat
local function AddCorner(parent, radius)
    return Create("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
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
-- 3. MAIN FRAME & HEADER
--------------------------------------------------------------------------------
local MainFrame = Create("Frame", {
    Size = UDim2.new(0, 580, 0, 330),
    Position = UDim2.new(0.5, -290, 0.5, -165),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    Active = true,
    ClipsDescendants = false,
}, ScreenGui)
AddCorner(MainFrame, 10)

-- Garis tepi jendela utama
Create("UIStroke", { Color = C.stroke, Thickness = 1.5 }, MainFrame)

-- Bar atas (area untuk menggeser jendela). Lebarnya disisakan untuk tombol di kanan.
local TopBar = Create("Frame", {
    Size = UDim2.new(1, -70, 0, 32),
    BackgroundTransparency = 1,
    Active = true,
}, MainFrame)

-- Judul jendela "Raff Musik"
local Title = Create("TextLabel", {
    Size = UDim2.new(1, -20, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    RichText = true, -- agar tag <i> (italic) bisa dipakai
    Text = "<i>🎵 Raff Musik</i>",
    TextColor3 = C.text,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, TopBar)

-- Tombol "i" (panduan pengguna), posisinya mengikuti lebar teks judul
local InfoBtn = Create("TextButton", {
    Size = UDim2.new(0, 20, 0, 20),
    Position = UDim2.new(0, 160, 0, 6),
    BackgroundColor3 = C.btnDark,
    Text = "i",
    TextColor3 = C.accentSoft,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
}, MainFrame)
AddCorner(InfoBtn, 10)
Create("UIStroke", { Color = C.stroke, Thickness = 1 }, InfoBtn)

do
    local function PositionInfoBtn()
        InfoBtn.Position = UDim2.new(0, 12 + Title.TextBounds.X + 8, 0, 6)
    end
    Title:GetPropertyChangedSignal("TextBounds"):Connect(PositionInfoBtn)
    PositionInfoBtn()
end

-- Tombol minimize (menyembunyikan jendela)
local MinBtn = Create("TextButton", {
    Size = UDim2.new(0, 24, 0, 24),
    Position = UDim2.new(1, -62, 0, 4),
    BackgroundColor3 = C.btnDark,
    Text = "-",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
}, MainFrame)
AddCorner(MinBtn, 12)

-- Tombol X (menutup UI setelah konfirmasi)
local CloseBtn = Create("TextButton", {
    Size = UDim2.new(0, 24, 0, 24),
    Position = UDim2.new(1, -34, 0, 4),
    BackgroundColor3 = C.btnDark,
    Text = "X",
    TextColor3 = Color3.fromRGB(255, 120, 120),
    TextSize = 12,
    Font = Enum.Font.GothamBold,
}, MainFrame)
AddCorner(CloseBtn, 12)

-- Tombol ikon untuk membuka kembali jendela setelah di-minimize
local ToggleBtn = Create("ImageButton", {
    Size = UDim2.new(0, 44, 0, 44),
    Position = UDim2.new(0, 12, 0.4, 0),
    BackgroundColor3 = C.accent,
    Image = "",
    ScaleType = Enum.ScaleType.Crop,
    Visible = false,
}, ScreenGui)
AddCorner(ToggleBtn, 8)

-- emoji cadangan, disembunyikan otomatis jika gambar berhasil dimuat
Create("TextLabel", {
    Name = "ToggleText",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "🎵",
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 255, 255),
}, ToggleBtn)

-- Pegangan di pojok kanan bawah untuk mengubah ukuran jendela
local ResizeHandle = Create("TextButton", {
    Size = UDim2.new(0, 16, 0, 16),
    Position = UDim2.new(1, -16, 1, -16),
    BackgroundColor3 = C.accent,
    Text = "↘",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 10,
    Font = Enum.Font.GothamBold,
}, MainFrame)
AddCorner(ResizeHandle, 4)

--------------------------------------------------------------------------------
-- 4. FIX ABSOLUT DRAG (RENDERSTEPPED - TANPA LONCAT/PERGESERAN SAMA SEKALI)
--------------------------------------------------------------------------------
-- Fungsi: membuat "frame" bisa digeser dengan menekan/menyentuh "handle".
-- Posisi dihitung tiap frame (RenderStepped) dari selisih posisi pointer,
-- lalu dibatasi agar jendela tidak keluar dari layar.
do
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

            renderConn = Track(RunService.RenderStepped:Connect(function()
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
            end))

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
end

-- LOGIKA RESIZE: ubah ukuran jendela dengan menyeret ResizeHandle (min 480x280, maks 850x550)
do
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
Track(UserInputService.InputChanged:Connect(function(input)
    if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - startMousePos
        local newWidth = math.clamp(startSize.X.Offset + delta.X, 580, 650)
        local newHeight = math.clamp(startSize.Y.Offset + delta.Y, 330, 550)
        MainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
end))

-- Event: lepas pointer -> berhenti resize
Track(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = false
    end
end))
end

--------------------------------------------------------------------------------
-- 5. SIDEBAR KIRI
--------------------------------------------------------------------------------
local Sidebar = Create("Frame", {
    Size = UDim2.new(0, 150, 1, -40),
    Position = UDim2.new(0, 10, 0, 34),
    BackgroundColor3 = C.panel,
}, MainFrame)
AddCorner(Sidebar, 8)

-- Susunan vertikal otomatis untuk isi sidebar (urutan ditentukan LayoutOrder)
Create("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, Sidebar)

-- Jarak dalam (padding) sidebar
Create("UIPadding", {
    PaddingTop = UDim.new(0, 8),
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
    PaddingBottom = UDim.new(0, 8),
}, Sidebar)

-- Kotak teks berjalan (marquee) "Raff Musik" di bagian atas sidebar
local MarqueeBox = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 55),
    BackgroundColor3 = C.bg,
    ClipsDescendants = true,
    LayoutOrder = 1,
}, Sidebar)
AddCorner(MarqueeBox, 6)

-- Teks berjalan versi ringan: beberapa salinan teks disusun dalam satu wadah (Strip),
-- lalu wadah itu digeser oleh SATU Tween yang dihitung engine Roblox (tanpa kode Lua per frame).
-- Setelah bergeser sejauh satu siklus, tampilannya identik sehingga loop terlihat mulus.
do
    local MARQUEE_SPEED = 38 -- kecepatan gerak (piksel per detik)
    local MARQUEE_GAP = 36   -- jarak antar teks (piksel)

    -- Wadah yang digeser; lebarnya otomatis mengikuti isi
    local Strip = Create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
    }, MarqueeBox)

    -- Susunan mendatar otomatis untuk salinan teks
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, MARQUEE_GAP),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, Strip)

    -- 4 salinan teks agar kotak selalu terisi saat wadah bergeser
    local firstLabel
    for i = 1, 4 do
        local lbl = Create("TextLabel", {
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            RichText = true,
            Text = "<i>Raff Musik</i>", -- teks berjalan (italic)
            TextColor3 = C.accent,
            TextSize = 15,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = i,
        }, Strip)
        if i == 1 then firstLabel = lbl end
    end

    -- Membuat (ulang) Tween sesuai lebar teks: geser sejauh satu siklus lalu ulang tanpa henti
    local marqueeTween = nil
    local lastWidth = 0
    local function rebuild()
        local w = firstLabel.AbsoluteSize.X
        if w < 10 or w == lastWidth then return end
        lastWidth = w
        local cycle = w + MARQUEE_GAP
        if marqueeTween then marqueeTween:Cancel() end
        Strip.Position = UDim2.new(0, 0, 0, 0)
        marqueeTween = TweenService:Create(
            Strip,
            TweenInfo.new(cycle / MARQUEE_SPEED, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1, false, 0),
            { Position = UDim2.new(0, -cycle, 0, 0) }
        )
        if MainFrame.Visible then marqueeTween:Play() end
    end
    firstLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(rebuild)
    rebuild()

    -- Jeda saat jendela di-minimize, lanjut saat dibuka lagi
    MainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
        if not marqueeTween then return end
        if MainFrame.Visible then marqueeTween:Play() else marqueeTween:Pause() end
    end)

    -- Hentikan Tween saat UI dihapus (tombol X)
    MarqueeBox.AncestryChanged:Connect(function()
        if marqueeTween and not MarqueeBox:IsDescendantOf(game) then
            marqueeTween:Cancel()
            marqueeTween = nil
        end
    end)
end

-- Tombol tab "Cari Lagu Online"
local TabSearchBtn = Create("TextButton", {
    Size = UDim2.new(1, 0, 0, 36),
    BackgroundColor3 = C.accent,
    Text = "🔍 Cari Lagu Online",
    TextTruncate = Enum.TextTruncate.AtEnd,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    LayoutOrder = 2,
}, Sidebar)
AddCorner(TabSearchBtn, 6)

-- Tombol tab "Playlist"
local TabLocalBtn = Create("TextButton", {
    Size = UDim2.new(1, 0, 0, 36),
    BackgroundColor3 = Color3.fromRGB(30, 40, 58),
    Text = "💾 Playlist",
    TextTruncate = Enum.TextTruncate.AtEnd,
    TextColor3 = Color3.fromRGB(180, 200, 220),
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    LayoutOrder = 3,
}, Sidebar)
AddCorner(TabLocalBtn, 6)

--------------------------------------------------------------------------------
-- 6. KONTEN UTAMA KANAN
--------------------------------------------------------------------------------
local ContentArea = Create("Frame", {
    Size = UDim2.new(1, -170, 1, -40),
    Position = UDim2.new(0, 164, 0, 34),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
}, MainFrame)

-- TAB 1: CARI LAGU ONLINE
local SearchView = Create("Frame", {
    Size = UDim2.new(1, 0, 1, -95),
    BackgroundTransparency = 1,
    Visible = true,
}, ContentArea)

-- Kotak input kata kunci pencarian
local SearchBox = Create("TextBox", {
    Size = UDim2.new(1, -58, 0, 32),
    BackgroundColor3 = C.field,
    PlaceholderText = "Cari lagu online...",
    PlaceholderColor3 = C.dim,
    Text = "",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 11,
    Font = Enum.Font.Gotham,
}, SearchView)
AddCorner(SearchBox, 6)

-- Tombol "Cari" (satu-satunya pemicu pencarian)
local SearchBtn = Create("TextButton", {
    Size = UDim2.new(0, 50, 0, 32),
    Position = UDim2.new(1, -50, 0, 0),
    BackgroundColor3 = C.accent,
    Text = "Cari",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 11,
    Font = Enum.Font.GothamBold,
}, SearchView)
AddCorner(SearchBtn, 6)

-- Teks status pencarian
local SearchStatusLabel = Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 16),
    Position = UDim2.new(0, 0, 0, 36),
    BackgroundTransparency = 1,
    Text = "Status Pencarian: Siap mencari...",
    TextColor3 = C.sub,
    TextSize = 9,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    ClipsDescendants = true,
}, SearchView)

-- Area hasil pencarian: satu kartu hasil yang memenuhi lebar & sisa tinggi area ini
local ResultHolder = Create("Frame", {
    Size = UDim2.new(1, 0, 1, -56),
    Position = UDim2.new(0, 0, 0, 56),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
}, SearchView)

-- Teks petunjuk saat belum ada hasil
local EmptyHint = Create("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "🔍 Ketik judul lagu lalu tekan Cari",
    TextColor3 = C.dim,
    TextSize = 11,
    Font = Enum.Font.Gotham,
}, ResultHolder)

-- TAB 2: PLAYLIST
local LocalView = Create("Frame", {
    Size = UDim2.new(1, 0, 1, -95),
    BackgroundTransparency = 1,
    Visible = false,
}, ContentArea)

-- Bar judul playlist (judul + tombol segarkan)
local LocalActionBar = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 22),
    BackgroundTransparency = 1,
}, LocalView)

-- Teks judul playlist + jumlah lagu
local LocalTitle = Create("TextLabel", {
    Size = UDim2.new(1, -78, 1, 0),
    BackgroundTransparency = 1,
    Text = "💾 Playlist (Kosong)",
    TextColor3 = C.ok,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, LocalActionBar)

-- Tombol "Segarkan": memindai folder imports untuk lagu yang dimasukkan manual
local RefreshBtn = Create("TextButton", {
    Size = UDim2.new(0, 74, 0, 20),
    Position = UDim2.new(1, -74, 0, 1),
    BackgroundColor3 = C.btnDark,
    Text = "🔄 Segarkan",
    TextColor3 = C.accentSoft,
    TextSize = 9,
    Font = Enum.Font.GothamBold,
}, LocalActionBar)
AddCorner(RefreshBtn, 5)

-- Bar filter & urutan
local LocalControlBar = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 24),
    Position = UDim2.new(0, 0, 0, 26),
    BackgroundTransparency = 1,
}, LocalView)

-- Kotak filter: ketik judul/artis untuk menyaring daftar lagu
local FilterBox = Create("TextBox", {
    Size = UDim2.new(1, -136, 1, 0),
    BackgroundColor3 = C.field,
    PlaceholderText = "🔎 Cari nama lagu...",
    PlaceholderColor3 = C.dim,
    Text = "",
    ClearTextOnFocus = false,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
}, LocalControlBar)
AddCorner(FilterBox, 6)
Create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, FilterBox)

-- Tombol urut berdasarkan nama (A-Z / Z-A)
local SortNameBtn = Create("TextButton", {
    Size = UDim2.new(0, 64, 1, 0),
    Position = UDim2.new(1, -132, 0, 0),
    BackgroundColor3 = C.accent,
    Text = "Nama A-Z",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 9,
    Font = Enum.Font.GothamBold,
}, LocalControlBar)
AddCorner(SortNameBtn, 6)

-- Tombol urut berdasarkan waktu download/masuk (terbaru / terlama)
local SortTimeBtn = Create("TextButton", {
    Size = UDim2.new(0, 64, 1, 0),
    Position = UDim2.new(1, -64, 0, 0),
    BackgroundColor3 = C.btn,
    Text = "Terbaru",
    TextColor3 = Color3.fromRGB(180, 200, 220),
    TextSize = 9,
    Font = Enum.Font.GothamBold,
}, LocalControlBar)
AddCorner(SortTimeBtn, 6)

-- Daftar lagu di playlist (bisa di-scroll)
local LocalScroll = Create("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -54),
    Position = UDim2.new(0, 0, 0, 54),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
}, LocalView)

-- Susunan vertikal otomatis untuk daftar lagu playlist
Create("UIListLayout", {
    Padding = UDim.new(0, 2),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, LocalScroll)

--------------------------------------------------------------------------------
-- 7. ACTIVE PLAYER PANEL
--------------------------------------------------------------------------------
local PlayerBar = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 85),
    Position = UDim2.new(0, 0, 1, -85),
    BackgroundColor3 = Color3.fromRGB(22, 30, 46),
    ClipsDescendants = true,
}, ContentArea)
AddCorner(PlayerBar, 8)

-- Judul lagu yang sedang diputar
local TrackTitle = Create("TextLabel", {
    Size = UDim2.new(1, -12, 0, 16),
    Position = UDim2.new(0, 6, 0, 4),
    BackgroundTransparency = 1,
    Text = "Belum ada lagu diputar",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    TextTruncate = Enum.TextTruncate.AtEnd,
    TextXAlignment = Enum.TextXAlignment.Left,
}, PlayerBar)

-- Teks status player
local PlayerStatusLabel = Create("TextLabel", {
    Size = UDim2.new(1, -12, 0, 12),
    Position = UDim2.new(0, 6, 0, 20),
    BackgroundTransparency = 1,
    Text = "Status: Siaga",
    TextColor3 = Color3.fromRGB(140, 160, 190),
    TextSize = 8,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, PlayerBar)

-- Progress bar yang bisa di-seek
local ProgressBg = Create("TextButton", {
    Size = UDim2.new(1, -12, 0, 6),
    Position = UDim2.new(0, 6, 0, 36),
    BackgroundColor3 = C.track,
    Text = "",
    AutoButtonColor = false,
}, PlayerBar)
AddCorner(ProgressBg, 3)

-- Isi progress bar (menunjukkan posisi lagu)
local ProgressFill = Create("Frame", {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0,
}, ProgressBg)
AddCorner(ProgressFill, 3)

local PrevBtn, PlayBtn, NextBtn, StopBtn, LoopBtn, ShuffleBtn
do
-- Helper: tombol kontrol kecil di panel player
local function ControlButton(text, x, width, textSize, color)
    local b = Create("TextButton", {
        Size = UDim2.new(0, width, 0, 24),
        Position = UDim2.new(0, x, 0, 52),
        BackgroundColor3 = color or C.btn,
        Text = text,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = textSize,
        Font = Enum.Font.GothamBold,
    }, PlayerBar)
    AddCorner(b, 5)
    return b
end

PrevBtn = ControlButton("⏮", 6, 24, 10)          -- lagu sebelumnya
PlayBtn = ControlButton("▶", 34, 26, 10, C.accent) -- play/pause
NextBtn = ControlButton("⏭", 64, 24, 10)          -- lagu berikutnya
StopBtn = ControlButton("◼", 92, 24, 9)           -- stop
LoopBtn = ControlButton("🔁", 120, 24, 10)        -- ulang lagu (loop)
ShuffleBtn = ControlButton("🔀", 148, 24, 10)     -- acak urutan lagu
end

-- Label waktu
local TimeLabel = Create("TextLabel", {
    Size = UDim2.new(0, 75, 0, 12),
    Position = UDim2.new(1, -210, 0, 48),
    BackgroundTransparency = 1,
    Text = "00:00/00:00",
    TextColor3 = C.sub,
    TextSize = 8,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Right,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, PlayerBar)

-- Ikon volume
Create("TextLabel", {
    Size = UDim2.new(0, 14, 0, 24),
    Position = UDim2.new(1, -128, 0, 52),
    BackgroundTransparency = 1,
    Text = "🔊",
    TextSize = 10,
}, PlayerBar)

-- Latar slider volume (bisa digeser)
local VolBg = Create("TextButton", {
    Size = UDim2.new(0, 70, 0, 5),
    Position = UDim2.new(1, -110, 0, 61),
    BackgroundColor3 = C.track,
    Text = "",
}, PlayerBar)
AddCorner(VolBg, 3)

-- Isi slider volume (default 100%)
local VolFill = Create("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0,
}, VolBg)

-- Kotak angka volume (0-100)
local VolInputBox = Create("TextBox", {
    Size = UDim2.new(0, 32, 0, 20),
    Position = UDim2.new(1, -36, 0, 54),
    BackgroundColor3 = C.btnDark,
    Text = "100",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 9,
    Font = Enum.Font.GothamBold,
}, PlayerBar)
AddCorner(VolInputBox, 4)

--------------------------------------------------------------------------------
-- 8. MODAL (KONFIRMASI HAPUS, KONFIRMASI TUTUP, PANDUAN PENGGUNA)
--------------------------------------------------------------------------------
-- Helper: membuat modal standar (lapisan gelap penutup + kotak di tengah + judul).
-- z = ZIndex dasar modal. Mengembalikan: overlay, modal, label judul.
local function CreateModal(z, width, height, titleText, titleColor)
    -- Lapisan gelap penutup (menghalangi klik ke UI di belakang modal)
    local overlay = Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.4,
        AutoButtonColor = false,
        Text = "",
        Visible = false,
        ZIndex = z,
    }, MainFrame)

    -- Kotak modal di tengah
    local modal = Create("Frame", {
        Size = UDim2.new(0, width, 0, height),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundColor3 = Color3.fromRGB(20, 28, 42),
        ZIndex = z + 1,
    }, overlay)
    AddCorner(modal, 8)
    Create("UIStroke", { Color = C.stroke, Thickness = 1 }, modal)

    -- Judul modal
    local titleLabel = Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        Text = titleText,
        TextColor3 = titleColor,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = z + 2,
    }, modal)

    return overlay, modal, titleLabel
end

-- Helper: tombol di dasar modal. side = "left" / "right" / "full"
local function ModalButton(modal, z, text, color, side)
    local b = Create("TextButton", {
        Size = side == "full" and UDim2.new(1, -32, 0, 26) or UDim2.new(0.5, -24, 0, 26),
        Position = side == "right" and UDim2.new(0.5, 8, 1, -34) or UDim2.new(0, 16, 1, -34),
        BackgroundColor3 = color,
        Text = text,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        ZIndex = z + 2,
    }, modal)
    AddCorner(b, 5)
    return b
end

-- Helper: teks isi modal
local function ModalText(modal, z, height)
    return Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, height),
        Position = UDim2.new(0, 10, 0, 34),
        BackgroundTransparency = 1,
        RichText = true,
        Text = "",
        TextColor3 = Color3.fromRGB(200, 210, 230),
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = z + 2,
    }, modal)
end

-- MODAL KONFIRMASI HAPUS LAGU -------------------------------------------------
local ConfirmOverlay, ConfirmDesc, CancelBtn, ConfirmDeleteBtn
do
    local ConfirmModal
    ConfirmOverlay, ConfirmModal = CreateModal(1000, 270, 140, "⚠️ Konfirmasi Hapus", Color3.fromRGB(255, 100, 100))
    -- Isi pesan: nama lagu yang akan dihapus diisi saat tombol hapus ditekan
    ConfirmDesc = ModalText(ConfirmModal, 1000, 64)
    ConfirmDesc.Text = "Apakah Anda yakin ingin menghapus lagu ini secara permanen dari perangkat?"
    CancelBtn = ModalButton(ConfirmModal, 1000, "Batal", C.btn, "left")
    ConfirmDeleteBtn = ModalButton(ConfirmModal, 1000, "Hapus", Color3.fromRGB(190, 40, 50), "right")
end

-- MODAL KONFIRMASI TUTUP UI ---------------------------------------------------
local CloseOverlay, CloseCancelBtn, CloseConfirmBtn
do
    local CloseModal
    CloseOverlay, CloseModal = CreateModal(1200, 270, 130, "⚠️ Tutup Raff Musik?", Color3.fromRGB(255, 100, 100))
    local CloseDesc = ModalText(CloseModal, 1200, 54)
    CloseDesc.Text = "Musik akan berhenti dan jendela ditutup sepenuhnya. Playlist dan lagu yang sudah tersimpan tetap aman."
    CloseCancelBtn = ModalButton(CloseModal, 1200, "Batal", C.btn, "left")
    CloseConfirmBtn = ModalButton(CloseModal, 1200, "Tutup", Color3.fromRGB(190, 40, 50), "right")
end

-- MODAL PANDUAN PENGGUNA ------------------------------------------------------
local InfoOverlay, InfoCloseBtn
do
local InfoModal
InfoOverlay, InfoModal = CreateModal(1100, 400, 250, "ℹ️ Panduan Pengguna", C.accentSoft)
-- Ukuran modal panduan menyesuaikan jendela (maks 440x300) agar tidak keluar bingkai
InfoModal.Size = UDim2.new(1, -40, 1, -30)
Create("UISizeConstraint", { MaxSize = Vector2.new(440, 300) }, InfoModal)

local GuideScroll = Create("ScrollingFrame", {
    Size = UDim2.new(1, -20, 1, -78),
    Position = UDim2.new(0, 10, 0, 34),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ZIndex = 1102,
}, InfoModal)
Create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, GuideScroll)
Create("UIPadding", { PaddingRight = UDim.new(0, 6) }, GuideScroll)

InfoCloseBtn = ModalButton(InfoModal, 1100, "Mengerti", C.accent, "full")

-- Helper: menambah satu bagian panduan (judul bagian + isi teksnya)
local guideOrder = 0
local function AddGuide(header, body)
    guideOrder = guideOrder + 1
    Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = header,
        TextColor3 = C.accentSoft,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        LayoutOrder = guideOrder * 3,
        ZIndex = 1103,
    }, GuideScroll)
    Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        RichText = true,
        Text = body,
        TextColor3 = Color3.fromRGB(200, 210, 230),
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        LayoutOrder = guideOrder * 3 + 1,
        ZIndex = 1103,
    }, GuideScroll)
    -- jarak antar bagian
    Create("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        BackgroundTransparency = 1,
        LayoutOrder = guideOrder * 3 + 2,
        ZIndex = 1103,
    }, GuideScroll)
end

-- Isi panduan pengguna ---------------------------------------------------------
AddGuide("👋 Selamat datang di Raff Musik",
    "Pemutar musik untuk mencari lagu online, menyimpannya ke playlist, lalu memutarnya kapan saja. Panduan singkat di bawah ini membantu kamu memakai semua fitur.")

AddGuide("🔍 1. Mencari & mendownload lagu",
    "• Buka menu <b>Cari Lagu Online</b> di sisi kiri.\n" ..
    "• Ketik judul lagu (boleh ditambah nama artis agar lebih tepat), lalu tekan tombol <b>Cari</b>. Pencarian hanya berjalan saat tombol Cari ditekan.\n" ..
    "• Kartu hasil menampilkan cover, judul, artis, album, tahun, dan durasi.\n" ..
    "• Tekan <b>Download</b>. Bar progres dan persentase menunjukkan prosesnya.\n" ..
    "• Setelah muncul <b>Berhasil tersimpan di playlist kamu</b>, tombol berubah menjadi <b>Putar lagu</b>. Tekan untuk memutar, lagu berikutnya di playlist akan lanjut otomatis.")

AddGuide("💾 2. Playlist",
    "• Ketuk lagu untuk memutarnya. Next, prev, auto-next, dan acak mengikuti urutan lagu yang tampil di layar.\n" ..
    "• Tombol <b>Nama</b> mengurutkan A-Z / Z-A, tombol <b>Waktu</b> mengurutkan terbaru / terlama. Ketuk tombol yang sedang aktif untuk membalik urutan.\n" ..
    "• Ketik di kotak filter untuk menyaring lagu berdasarkan judul atau artis. Kosongkan kotak untuk menampilkan semua lagu.\n" ..
    "• Ikon 🗑️ menghapus lagu secara permanen dari perangkat (file lagu dan cover ikut terhapus).")

AddGuide("📁 3. Memasukkan lagu milikmu sendiri",
    "• Salin file <b>.mp3</b> atau <b>.ogg</b> ke folder <b>SpotiRaff/imports</b> di folder workspace executor kamu.\n" ..
    "• Buka tab Playlist lalu tekan <b>🔄 Segarkan</b>. Lagu akan muncul di playlist yang sama dengan lagu hasil download.\n" ..
    "• Format lain (m4a, wav, flac) tidak bisa diputar oleh Roblox.\n" ..
    "• Menghapus lagu manual dari playlist juga menghapus file aslinya dari folder imports.\n" ..
    "• Fitur ini butuh executor yang mendukung pemindaian folder (listfiles).")

AddGuide("🎛️ 4. Kontrol pemutar",
    "• ⏮ sebelumnya, ▶/⏸ putar/jeda, ⏭ berikutnya, ◼ stop.\n" ..
    "• 🔁 mengulang lagu yang sama, 🔀 mengacak urutan (tombol menyala biru saat aktif).\n" ..
    "• Ketuk atau geser progress bar untuk maju/mundur. Volume bisa digeser atau diketik (0-100).")

AddGuide("🪟 5. Jendela",
    "• Geser jendela lewat bar atas, ubah ukuran lewat pojok kanan bawah.\n" ..
    "• Tombol <b>-</b> menyembunyikan jendela menjadi ikon kecil (ketuk ikon untuk membukanya lagi).\n" ..
    "• Tombol <b>X</b> menutup Raff Musik sepenuhnya dan menghentikan musik.")

AddGuide("❓ 6. Jika ada masalah",
    "• <b>Server tidak merespon</b>: tunggu beberapa saat lalu coba lagi.\n" ..
    "• Link download yang kedaluwarsa dicari ulang otomatis, kamu tidak perlu melakukan apa-apa.\n" ..
    "• Lagu tidak bersuara: cek volume, atau pastikan file lagu masih ada di folder SpotiRaff.")
end

--------------------------------------------------------------------------------
-- 9. TATA LETAK KARTU (dipakai kartu hasil & skeleton)
--------------------------------------------------------------------------------
-- Fungsi: mengatur thumbnail persegi di kiri dan kolom info di kanan agar selalu
-- pas di dalam kartu (ukuran mengikuti tinggi & lebar kartu).
local function BindCardLayout(card, thumb, info)
    local function relayout()
        local w, h = card.AbsoluteSize.X, card.AbsoluteSize.Y
        if w <= 0 or h <= 0 then return end
        local side = math.max(36, math.min(h - 16, math.floor(w * 0.42)))
        thumb.Size = UDim2.new(0, side, 0, side)
        thumb.Position = UDim2.new(0, 8, 0.5, -math.floor(side / 2))
        info.Position = UDim2.new(0, side + 18, 0, 8)
        info.Size = UDim2.new(1, -(side + 26), 1, -16)
    end
    card:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
    relayout()
end

--------------------------------------------------------------------------------
-- 10. ANIMASI SKELETON LOADING
--------------------------------------------------------------------------------
-- Daftar animasi skeleton yang sedang berjalan (agar bisa dihentikan)
local activeSkeletonTweens = {}

-- Fungsi: menampilkan kerangka kartu berkedip di "container" sebagai animasi loading
local function ShowSkeletonLoading(container)
    for _, child in pairs(container:GetChildren()) do
        if child.Name == "SkeletonCard" then child:Destroy() end
    end
    for _, tween in ipairs(activeSkeletonTweens) do tween:Cancel() end
    activeSkeletonTweens = {}

    -- Kartu kerangka (skeleton) saat loading, bentuknya mengikuti kartu hasil
    local SkelCard = Create("Frame", {
        Name = "SkeletonCard",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = C.card,
    }, container)
    AddCorner(SkelCard, 12)
    Create("UIStroke", { Color = C.stroke, Thickness = 1 }, SkelCard)

    -- Kerangka thumbnail
    local SkelThumb = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(40, 52, 75),
        BorderSizePixel = 0,
    }, SkelCard)
    AddCorner(SkelThumb, 10)

    -- Kolom garis-garis teks kerangka
    local SkelInfo = Create("Frame", { BackgroundTransparency = 1 }, SkelCard)
    Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, SkelInfo)

    local function pulse(frame)
        local tweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
        local tween = TweenService:Create(frame, tweenInfo, { BackgroundTransparency = 0.7 })
        tween:Play()
        table.insert(activeSkeletonTweens, tween)
    end

    pulse(SkelThumb)
    local lines = { { 0.85, 14 }, { 0.55, 11 }, { 0.4, 9 }, { 0.95, 8 }, { 0.5, 8 }, { 1, 24 } }
    for lineIdx, spec in ipairs(lines) do
        -- Garis berkedip di dalam kartu skeleton
        local line = Create("Frame", {
            LayoutOrder = lineIdx,
            Size = UDim2.new(spec[1], 0, 0, spec[2]),
            BackgroundColor3 = Color3.fromRGB(40, 52, 75),
            BorderSizePixel = 0,
        }, SkelInfo)
        AddCorner(line, 3)
        pulse(line)
    end

    BindCardLayout(SkelCard, SkelThumb, SkelInfo)
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
-- 11. FILE, FOLDER & DATA PLAYLIST
--------------------------------------------------------------------------------
-- Alias fungsi file milik executor (nama fungsinya beda-beda antar executor,
-- jadi dicari satu per satu; kalau tidak ada nilainya nil)
local writefileFn = writefile or (syn and syn.writefile) -- menulis file ke workspace
local readfileFn = readfile or (syn and syn.readfile) -- membaca file dari workspace
local isfileFn = isfile or (syn and syn.isfile) -- cek apakah file ada
local delfileFn = delfile or (syn and syn.delfile) -- menghapus file
local getcustomassetFn = getcustomasset or getsynasset or (syn and syn.getcustomasset) -- ubah file lokal jadi asset yang bisa diputar Sound / ditampilkan
local makefolderFn = makefolder or (syn and syn.makefolder) -- membuat folder
local isfolderFn = isfolder or (syn and syn.isfolder) -- cek apakah folder ada
local listfilesFn = listfiles or (syn and syn.listfiles) -- daftar isi folder (untuk folder imports)

-- Siapkan folder utama + subfolder (tiap jenis penyimpanan punya folder sendiri)
local folderReady = false
local subfolderReady = {}
do
    -- Fungsi: membuat folder jika belum ada, mengembalikan true jika folder siap dipakai
    local function EnsureFolder(path)
        if not makefolderFn then return false end
        if isfolderFn and isfolderFn(path) then return true end
        pcall(makefolderFn, path)
        return (not isfolderFn) or isfolderFn(path) == true
    end

    folderReady = EnsureFolder(PROJECT_FOLDER)
    if folderReady then
        for _, sub in ipairs({ DATA_FOLDER, SONGS_FOLDER, COVERS_FOLDER, IMPORTS_FOLDER, ICONS_FOLDER }) do
            subfolderReady[sub] = EnsureFolder(PROJECT_FOLDER .. "/" .. sub)
        end
    end
end

-- Fungsi: path file di dalam subfolder, contoh SubPath("songs", "a.mp3") -> "SpotiRaff/songs/a.mp3".
-- Jika subfolder gagal dibuat, dipakai folder utama; jika folder utama juga gagal, root workspace.
local function SubPath(folder, name)
    if folderReady and subfolderReady[folder] then
        return PROJECT_FOLDER .. "/" .. folder .. "/" .. name
    end
    if folderReady then return PROJECT_FOLDER .. "/" .. name end
    return name
end

-- Folder tempat user memasukkan lagu manual
local ImportsDir = PROJECT_FOLDER .. "/" .. IMPORTS_FOLDER

-- UTILITAS --------------------------------------------------------------------
-- Fungsi: membuang spasi di awal & akhir teks
local function TrimStr(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Fungsi: mengamankan teks agar aman dipakai di RichText
local function EscapeRich(s)
    s = tostring(s or "")
    s = s:gsub("&", "&amp;")
    s = s:gsub("<", "&lt;")
    s = s:gsub(">", "&gt;")
    return s
end

-- Fungsi: detik -> "m:ss" (atau "h:mm:ss")
local function FormatTime(sec)
    sec = math.max(0, math.floor((tonumber(sec) or 0) + 0.5))
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
    return string.format("%d:%02d", m, s)
end

-- Fungsi: "3:50" -> 230 detik (nil jika format tidak dikenali)
local function ParseDuration(str)
    if type(str) == "number" then return str end
    local parts = {}
    for n in tostring(str or ""):gmatch("%d+") do table.insert(parts, tonumber(n)) end
    if #parts == 2 then return parts[1] * 60 + parts[2] end
    if #parts == 3 then return parts[1] * 3600 + parts[2] * 60 + parts[3] end
    return nil
end

-- Fungsi: mengambil id lagu dari link Spotify (".../track/<id>"); cadangan: dari judul+artis
local function ExtractTrackId(data)
    local id = tostring(data.spotify_url or ""):match("/track/(%w+)")
    if id then return id end
    local fallback = (tostring(data.title or "") .. tostring(data.artist or "")):lower():gsub("[^%w]", "")
    if fallback == "" then fallback = "lagu" .. tostring(os.time()) end
    return fallback:sub(1, 40)
end

-- Fungsi: decode Base64 (dipakai untuk membaca masa berlaku token link mp3)
local Mp3NeedsRefresh
do
local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function Base64Decode(data)
    data = data:gsub("[^" .. b64chars .. "=]", "")
    local bits = data:gsub(".", function(x)
        if x == "=" then return "" end
        local r, f = "", (b64chars:find(x, 1, true) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0") end
        return r
    end)
    return (bits:gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
        if #x ~= 8 then return "" end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0) end
        return string.char(c)
    end))
end

-- Fungsi: apakah link mp3 sudah/hampir kedaluwarsa? (token JWT di link berisi waktu "exp")
Mp3NeedsRefresh = function(url)
    local ok, expired = pcall(function()
        local token = tostring(url):match("token=([^&#]+)")
        if not token then return false end
        local payload = token:match("^[^.]+%.([^.]+)%.")
        if not payload then return false end
        payload = payload:gsub("%-", "+"):gsub("_", "/")
        payload = payload .. string.rep("=", (4 - #payload % 4) % 4)
        local decoded = HttpService:JSONDecode(Base64Decode(payload))
        local exp = tonumber(decoded.exp)
        if not exp then return false end
        return os.time() >= exp - 20
    end)
    return ok and expired == true
end
end

-- DATA PLAYLIST ---------------------------------------------------------------
-- Satu lagu di playlist berisi: id, title, artist, album, year, duration ("3:50"),
-- durationSec, fileName, coverFile, source ("download" / "import"), addedAt (waktu masuk).
local playlistCache = nil -- salinan playlist di memori (dibaca dari file sekali saja)

-- Fungsi: mengambil "kunci unik" sebuah lagu (id, atau nama file jika id tidak ada)
local function ItemKey(item)
    return item.id or item.fileName
end

-- Fungsi: membaca daftar lagu dari file playlist.json (kosong jika belum ada / rusak)
local function LoadLocalPlaylist()
    if playlistCache then return playlistCache end
    local result = {}
    local jsonPath = SubPath(DATA_FOLDER, PLAYLIST_FILE_NAME)
    if isfileFn and readfileFn and isfileFn(jsonPath) then
        local success, content = pcall(function() return readfileFn(jsonPath) end)
        if success and content then
            local pSuccess, data = pcall(function() return HttpService:JSONDecode(content) end)
            if pSuccess and type(data) == "table" then result = data end
        end
    end
    playlistCache = result
    return playlistCache
end

-- Fungsi: menyimpan daftar lagu ke file playlist.json
local function SaveLocalPlaylist(playlist)
    playlistCache = playlist
    if writefileFn then
        pcall(function() writefileFn(SubPath(DATA_FOLDER, PLAYLIST_FILE_NAME), HttpService:JSONEncode(playlist)) end)
    end
end

-- Fungsi: mencari lagu berdasarkan id (mengembalikan item dan nomor urutnya)
local function FindItemById(id)
    local playlist = LoadLocalPlaylist()
    for idx, item in ipairs(playlist) do
        if item.id == id then return item, idx end
    end
    return nil, nil
end

-- Fungsi: path file lagu (download -> songs, manual -> imports)
local function SongPath(item)
    if item.source == "import" then return ImportsDir .. "/" .. item.fileName end
    local path = SubPath(SONGS_FOLDER, item.fileName)
    if isfileFn and not isfileFn(path) then
        local legacy = folderReady and (PROJECT_FOLDER .. "/" .. item.fileName) or item.fileName
        if isfileFn(legacy) then return legacy end
    end
    return path
end

-- Fungsi: path file cover di folder covers
local function CoverPath(fileName)
    return SubPath(COVERS_FOLDER, fileName)
end

-- CACHE ASSET GAMBAR & IKON ---------------------------------------------------
local assetCache = {} -- path file -> asset id (hasil getcustomasset)
local iconAsset = nil -- asset ikon toggle (juga dipakai sebagai gambar cadangan cover)
local fallbackThumbs = {} -- thumbnail yang menunggu ikon cadangan siap

-- Fungsi: mengubah file gambar lokal jadi asset (hasilnya disimpan agar tidak diulang)
local function GetAssetCached(path)
    if assetCache[path] then return assetCache[path] end
    if getcustomassetFn and isfileFn and isfileFn(path) then
        local ok, asset = pcall(getcustomassetFn, path)
        if ok and asset and asset ~= "" then
            assetCache[path] = asset
            return asset
        end
    end
    return nil
end

-- Fungsi: memasang cover ke ImageLabel. Jika cover tidak ada/gagal dimuat -> pakai ikon toggle,
-- dan jika ikon juga belum siap -> emoji cadangan.
local function ApplyThumb(img, emojiLabel, coverFile)
    local asset = nil
    if coverFile then asset = GetAssetCached(CoverPath(coverFile)) end
    if asset then
        img.Image = asset
        emojiLabel.Visible = false
    elseif iconAsset then
        img.Image = iconAsset
        emojiLabel.Visible = false
    else
        img.Image = ""
        emojiLabel.Visible = true
        table.insert(fallbackThumbs, { img = img, emoji = emojiLabel })
    end
end

-- Muat ikon tombol toggle dari link gambar (berjalan di background).
-- Gambar diunduh sekali, disimpan di folder icons, lalu dipakai ulang tanpa download lagi.
task.spawn(function()
    if not (getcustomassetFn and writefileFn and isfileFn) then return end
    local iconPath = SubPath(ICONS_FOLDER, "toggle_icon.png")

    -- Fungsi: pasang file gambar lokal ke tombol toggle & sembunyikan emoji cadangan
    local function applyIcon()
        local ok, asset = pcall(getcustomassetFn, iconPath)
        if ok and asset and asset ~= "" then
            iconAsset = asset
            ToggleBtn.Image = asset
            local fallback = ToggleBtn:FindFirstChild("ToggleText")
            if fallback then fallback.Visible = false end
            -- thumbnail yang tadinya memakai emoji cadangan ikut diperbarui
            for _, entry in ipairs(fallbackThumbs) do
                if entry.img.Parent then
                    entry.img.Image = asset
                    entry.emoji.Visible = false
                end
            end
            fallbackThumbs = {}
            return true
        end
        return false
    end

    -- jika gambar sudah pernah diunduh, langsung pakai
    if isfileFn(iconPath) and applyIcon() then return end

    -- unduh gambar dari link, simpan, lalu pasang
    local okReq, res = pcall(function()
        local req = (syn and syn.request) or request or http_request or (http and http.request)
        if not req then return nil end
        return req({ Url = TOGGLE_IMAGE_URL, Method = "GET" })
    end)
    if isClosed then return end
    if okReq and res and res.StatusCode == 200 and res.Body and #res.Body > 0 then
        pcall(function() writefileFn(iconPath, res.Body) end)
        applyIcon()
    end
end)

--------------------------------------------------------------------------------
-- 12. JARINGAN (API NEXADEV)
--------------------------------------------------------------------------------
-- Fungsi: mengirim HTTP request memakai fungsi request milik executor.
-- Parameter reqData: tabel { Url=..., Method=..., Headers=..., Body=... }
-- Mengembalikan tabel response (StatusCode, Body, ...) atau nil jika gagal/tidak didukung.
local function customRequest(reqData)
    -- cari fungsi request yang tersedia di executor
    local req = (syn and syn.request) or request or http_request or (http and http.request)
    if not req then return nil end
    -- pcall supaya error jaringan tidak mematikan script
    local success, response = pcall(function() return req(reqData) end)
    if not success then return nil end
    return response
end

-- Fungsi: mengambil data biner (gambar/audio) dari sebuah URL. nil jika gagal.
local function DownloadBinary(url)
    url = tostring(url or ""):gsub("#.*$", "") -- bagian setelah # tidak dikirim ke server
    if url == "" then return nil end
    local res = customRequest({ Url = url, Method = "GET" })
    if res and res.StatusCode == 200 and res.Body and #res.Body > 0 then
        return res.Body
    end
    -- cadangan: HttpGet bawaan Roblox
    local okGet, body = pcall(function() return game:HttpGet(url) end)
    if okGet and body and #body > 0 then return body end
    return nil
end

-- Fungsi: mencari lagu lewat API. Mengembalikan:
--   "ok", dataLagu        -> lagu ditemukan
--   "notfound", pesan     -> server menjawab status false (pesan dari JSON "message")
--   "noresponse"          -> server tidak mengirim data yang bisa dibaca
local function FetchSongData(query)
    local res = customRequest({ Url = API_URL .. HttpService:UrlEncode(query), Method = "GET" })
    if not res or not res.Body or res.Body == "" then return "noresponse" end
    local okDec, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
    if not okDec or type(data) ~= "table" then return "noresponse" end
    if data.status == true and type(data.data) == "table" and data.data.mp3_url then
        return "ok", data.data
    end
    if data.status == false then
        return "notfound", tostring(data.message or "Lagu tidak ditemukan.")
    end
    return "noresponse"
end

--------------------------------------------------------------------------------
-- 13. AUDIO ENGINE & SCRUBBING
--------------------------------------------------------------------------------
-- STATE PLAYER ----------------------------------------------------------------
local isPlaylistMode = false -- true = setelah lagu selesai otomatis lanjut ke lagu berikutnya
local isShuffleMode = false -- true = urutan lagu diacak
local currentTrackKey = nil -- id lagu yang sedang diputar (dipakai untuk melacak lagu aktif)
local isTransitioning = false -- true saat script sedang ganti lagu (supaya event Ended palsu diabaikan)

-- Antrian shuffle: urutan acak berisi SEMUA lagu yang tampil (berdasarkan id, bukan index,
-- karena index bergeser saat lagu ditambah/dihapus). Tiap lagu diputar tepat
-- sekali per putaran; antrian baru dibuat hanya setelah antrian habis.
local shuffleQueue = {}
local shuffleRoundStarted = false

-- Urutan & filter playlist (default: nama A-Z)
local sortMode = "name" -- "name" atau "time"
local nameAscending = true -- true = A-Z, false = Z-A
local newestFirst = true -- true = terbaru dulu, false = terlama dulu

-- Fungsi yang didefinisikan di bagian playlist (dideklarasikan lebih dulu)
local RenderLocalPlaylist
local UpdateActiveRow
local UpdateRowDuration

-- Fungsi: mengosongkan antrian shuffle (dipanggil saat shuffle/filter/urutan diubah atau user memilih lagu manual)
local function ResetShuffleHistory()
    shuffleQueue = {}
    shuffleRoundStarted = false
end

-- Fungsi: daftar lagu yang sedang TAMPIL (sudah difilter & diurutkan).
-- Next, prev, auto-next, dan shuffle semuanya mengikuti daftar ini.
-- Mengembalikan array { item = lagu, idx = nomor urut asli di playlist }.
local function GetDisplayList()
    local playlist = LoadLocalPlaylist()
    local q = string.lower(TrimStr(FilterBox.Text))
    local list = {}
    for idx, item in ipairs(playlist) do
        local haystack = string.lower(tostring(item.title or "") .. " " .. tostring(item.artist or ""))
        if q == "" or string.find(haystack, q, 1, true) then
            table.insert(list, { item = item, idx = idx })
        end
    end
    table.sort(list, function(a, b)
        if sortMode == "name" then
            local ta, tb = string.lower(tostring(a.item.title or "")), string.lower(tostring(b.item.title or ""))
            if ta ~= tb then
                if nameAscending then return ta < tb end
                return ta > tb
            end
            return a.idx < b.idx
        end
        -- urut waktu: lagu lama tanpa data waktu dianggap lebih lama (urutan aslinya: indeks kecil = lebih baru)
        local xa, xb = a.item.addedAt or 0, b.item.addedAt or 0
        if xa ~= xb then
            if newestFirst then return xa > xb end
            return xa < xb
        end
        if newestFirst then return a.idx < b.idx end
        return a.idx > b.idx
    end)
    return list
end

-- Objek Sound tunggal yang dipakai untuk memutar semua lagu
local CurrentSound = Instance.new("Sound")
CurrentSound.Name = "RaffMusikSound"
CurrentSound.Volume = 1
CurrentSound.Parent = SoundService

-- Update progress bar & label waktu setiap frame saat lagu diputar
Track(RunService.RenderStepped:Connect(function()
    if isClosed then return end
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
end))

-- Fungsi: memilih nomor urut lagu berikutnya untuk mode shuffle dari daftar yang TAMPIL.
-- Semua lagu diacak jadi satu antrian; tiap lagu diputar sekali per putaran
-- sehingga tidak ada lagu yang berulang sebelum semua lagu kebagian.
local function PickShuffleIndex(displayList)
    local total = #displayList
    if total <= 1 then return 1 end

    -- cari nomor urut lagu (di daftar tampil) berdasarkan id-nya
    local function findIndex(key)
        for i, entry in ipairs(displayList) do
            if ItemKey(entry.item) == key then return i end
        end
        return nil
    end

    -- buat antrian acak baru (algoritma Fisher-Yates)
    local function rebuild(excludeCurrent)
        shuffleQueue = {}
        for _, entry in ipairs(displayList) do
            local key = ItemKey(entry.item)
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

    -- ambil dari antrian, lewati lagu yang sudah dihapus / tidak tampil / sedang diputar
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
    return (key and findIndex(key)) or 1
end

-- Fungsi: memutar sebuah lagu (item playlist).
-- Mengambil file dari folder penyimpanan, mengubahnya jadi asset, lalu memutarnya.
local function PlayItem(item)
    if not item then return end
    currentTrackKey = ItemKey(item)
    TrackTitle.Text = "🎵 " .. tostring(item.title)
    if UpdateActiveRow then UpdateActiveRow() end

    -- tandai sedang ganti lagu (agar event Ended palsu diabaikan)
    isTransitioning = true
    local ok = pcall(function()
        local path = SongPath(item)
        if isfileFn and isfileFn(path) then
            PlayerStatusLabel.Text = "Status: 📂 Memuat file..."
            local assetUrl = getcustomassetFn(path)

            -- hentikan lagu sebelumnya, pasang lagu baru
            CurrentSound:Stop()
            CurrentSound.TimePosition = 0
            CurrentSound.SoundId = assetUrl

            task.wait(0.1) -- beri waktu agar asset termuat
            CurrentSound:Play()
            PlayBtn.Text = "⏸"
            PlayerStatusLabel.Text = "Status: Memutar"
        else
            PlayerStatusLabel.Text = "Status: ❌ File lagu hilang!"
        end
    end)
    isTransitioning = false
    if not ok then
        PlayerStatusLabel.Text = "Status: ❌ Gagal memutar lagu"
        return
    end

    -- Lagu yang belum punya data durasi (misalnya lagu manual): catat durasinya setelah termuat
    if not item.durationSec and not item.duration then
        local key = ItemKey(item)
        task.spawn(function()
            local t0 = os.clock()
            while not isClosed and CurrentSound.TimeLength <= 0 and os.clock() - t0 < 5 do task.wait(0.2) end
            if not isClosed and CurrentSound.TimeLength > 0 and currentTrackKey == key then
                item.durationSec = math.floor(CurrentSound.TimeLength + 0.5)
                item.duration = FormatTime(item.durationSec)
                SaveLocalPlaylist(LoadLocalPlaylist())
                if UpdateRowDuration then UpdateRowDuration(key, item.duration) end
            end
        end)
    end
end

-- Fungsi: pindah lagu mengikuti urutan yang tampil. direction: 1 = berikutnya, -1 = sebelumnya.
-- Jika lagu aktif tidak ada di daftar tampil (misalnya terfilter), mulai dari ujung daftar.
local function StepTrack(direction)
    local list = GetDisplayList()
    if #list == 0 then return end
    local pos = nil
    for i, entry in ipairs(list) do
        if ItemKey(entry.item) == currentTrackKey then pos = i break end
    end
    local target
    if direction > 0 then
        target = pos and (pos % #list) + 1 or 1
    else
        target = pos and ((pos - 2) % #list) + 1 or #list
    end
    PlayItem(list[target].item)
end

-- Event: lagu selesai diputar -> otomatis lanjut ke lagu berikutnya jika mode playlist aktif
CurrentSound.Ended:Connect(function()
    -- abaikan Ended palsu yang muncul saat kita sendiri sedang Stop()/ganti lagu
    if isTransitioning or isClosed then return end
    PlayBtn.Text = "▶"
    PlayerStatusLabel.Text = "Status: Selesai"

    if isPlaylistMode then
        local list = GetDisplayList()
        if #list > 0 then
            if isShuffleMode then
                -- mode acak: ambil lagu berikutnya dari antrian shuffle
                PlayItem(list[PickShuffleIndex(list)].item)
            else
                -- mode biasa: lagu berikutnya, kembali ke lagu pertama setelah lagu terakhir
                StepTrack(1)
            end
        end
    end
end)

-- Event: tombol play/pause (pause jika sedang main, lanjut/putar jika sedang berhenti)
PlayBtn.MouseButton1Click:Connect(function()
    if CurrentSound.SoundId ~= "" then
        if CurrentSound.IsPlaying then
            CurrentSound:Pause()
            PlayBtn.Text = "▶"
            PlayerStatusLabel.Text = "Status: Dijeda"
        else
            if CurrentSound.IsPaused then
                CurrentSound:Resume()
            else
                CurrentSound:Play()
            end
            PlayBtn.Text = "⏸"
            PlayerStatusLabel.Text = "Status: Memutar"
        end
    end
end)

-- Event: tombol stop (hentikan lagu & reset progress bar)
StopBtn.MouseButton1Click:Connect(function()
    CurrentSound:Stop()
    CurrentSound.TimePosition = 0
    PlayBtn.Text = "▶"
    ProgressFill.Size = UDim2.new(0, 0, 1, 0)
    PlayerStatusLabel.Text = "Status: Dihentikan"
end)

-- Event: tombol lagu berikutnya (acak jika shuffle aktif, berurutan sesuai tampilan jika tidak)
NextBtn.MouseButton1Click:Connect(function()
    local list = GetDisplayList()
    if #list > 0 then
        isPlaylistMode = true
        if isShuffleMode then
            PlayItem(list[PickShuffleIndex(list)].item)
        else
            StepTrack(1)
        end
    end
end)

-- Event: tombol lagu sebelumnya (kembali ke lagu terakhir jika sudah di awal)
PrevBtn.MouseButton1Click:Connect(function()
    local list = GetDisplayList()
    if #list > 0 then
        isPlaylistMode = true
        StepTrack(-1)
    end
end)

-- Event: tombol loop (ulang lagu yang sama terus-menerus)
LoopBtn.MouseButton1Click:Connect(function()
    CurrentSound.Looped = not CurrentSound.Looped
    LoopBtn.BackgroundColor3 = CurrentSound.Looped and C.accent or C.btn
end)

-- Event: tombol shuffle -> nyalakan/matikan mode acak (antrian acak dibuat ulang)
ShuffleBtn.MouseButton1Click:Connect(function()
    isShuffleMode = not isShuffleMode
    ResetShuffleHistory()
    ShuffleBtn.BackgroundColor3 = isShuffleMode and C.accent or C.btn
end)

do
-- SEEK / SCRUBBING: klik atau geser progress bar untuk memajukan/memundurkan lagu
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
Track(UserInputService.InputChanged:Connect(function(input)
    if isSeeking and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateSeekPosition(input)
    end
end))

end

do
-- VOLUME: geser slider atau ketik angka 0-100 untuk mengatur volume
local settingVol = false

-- Fungsi: mengubah volume sesuai posisi pointer pada slider (0%-100%)
local function UpdateVol(input)
    local alpha = math.clamp((input.Position.X - VolBg.AbsolutePosition.X) / VolBg.AbsoluteSize.X, 0, 1)
    VolFill.Size = UDim2.new(alpha, 0, 1, 0)
    CurrentSound.Volume = alpha
    VolInputBox.Text = tostring(math.floor(alpha * 100 + 0.5))
end

-- Event: mulai atur volume saat slider ditekan
VolBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        settingVol = true
        UpdateVol(input)
    end
end)

-- Event: saat pointer digeser, perbarui volume
Track(UserInputService.InputChanged:Connect(function(input)
    if settingVol and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateVol(input)
    end
end))

-- Event: lepas pointer -> selesai mengatur volume
Track(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        settingVol = false
    end
end))

-- Event: setelah mengetik angka volume, validasi lalu terapkan (kembali ke nilai lama jika bukan angka)
VolInputBox.FocusLost:Connect(function()
    local num = tonumber(VolInputBox.Text)
    if num then
        num = math.clamp(num, 0, 100)
        local volVal = num / 100
        CurrentSound.Volume = volVal
        VolFill.Size = UDim2.new(volVal, 0, 1, 0)
        VolInputBox.Text = tostring(math.floor(num))
    else
        VolInputBox.Text = tostring(math.floor(CurrentSound.Volume * 100 + 0.5))
    end
end)

end

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
-- 14. PLAYLIST: TAMPILAN, URUTAN, FILTER, LAGU MANUAL & HAPUS
--------------------------------------------------------------------------------
-- Baris yang sedang tampil: id lagu -> { row, title, duration }
local rowsByKey = {}
-- id lagu yang menunggu konfirmasi hapus (nil = tidak ada)
local pendingDeleteKey = nil
-- true = saat tab Playlist dibuka, daftar menggulir ke lagu yang sedang diputar
local scrollPending = false

-- Fungsi dari bagian kartu hasil (dipakai saat lagu dihapus)
local RefreshCardAfterDelete

-- Fungsi: memperbarui teks judul playlist (jumlah lagu / hasil filter)
local function UpdateLocalTitle()
    local total = #LoadLocalPlaylist()
    if total == 0 then
        LocalTitle.Text = "💾 Playlist (Kosong)"
    else
        local shown = #GetDisplayList()
        if shown == total then
            LocalTitle.Text = string.format("💾 Playlist (%d lagu):", total)
        else
            LocalTitle.Text = string.format("💾 Playlist (%d dari %d lagu):", shown, total)
        end
    end
    LocalTitle.TextColor3 = C.ok
end

-- Fungsi: menampilkan pesan singkat di judul playlist lalu mengembalikannya
local FlashLocalTitle
do
    local flashToken = 0
    FlashLocalTitle = function(text, color)
        flashToken = flashToken + 1
        local myToken = flashToken
        LocalTitle.Text = text
        LocalTitle.TextColor3 = color or C.warn
        task.delay(2.5, function()
            if myToken == flashToken and not isClosed then UpdateLocalTitle() end
        end)
    end
end

-- Fungsi: menandai baris lagu yang sedang diputar (tanpa menggambar ulang seluruh daftar)
UpdateActiveRow = function()
    for key, info in pairs(rowsByKey) do
        local active = (key == currentTrackKey)
        info.row.BackgroundTransparency = active and 0 or 1
        info.title.TextColor3 = active and C.accent or C.text
    end
end

-- Fungsi: memperbarui teks durasi pada baris lagu tertentu
UpdateRowDuration = function(key, text)
    local info = rowsByKey[key]
    if info then info.duration.Text = text end
end

-- Fungsi: menggulirkan daftar playlist ke lagu yang sedang diputar
local function ScrollToCurrent()
    local info = rowsByKey[currentTrackKey]
    if not info then return end
    local y = info.row.AbsolutePosition.Y - LocalScroll.AbsolutePosition.Y + LocalScroll.CanvasPosition.Y
    LocalScroll.CanvasPosition = Vector2.new(0, math.max(0, y - 8))
end

do
-- Fungsi: membuat satu baris lagu bergaya daftar (thumbnail, judul, artis, durasi, hapus)
local function BuildRow(item, order)
    local key = ItemKey(item)
    local active = (key == currentTrackKey)

    -- Baris pembungkus satu lagu
    local Row = Create("Frame", {
        Name = "Row",
        Size = UDim2.new(1, -4, 0, 44),
        BackgroundColor3 = C.rowActive,
        BackgroundTransparency = active and 0 or 1,
        BorderSizePixel = 0,
        LayoutOrder = order,
    }, LocalScroll)
    AddCorner(Row, 8)

    -- Tombol transparan seluas baris (klik = putar lagu ini)
    local PlayRowBtn = Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    }, Row)

    -- Thumbnail persegi kecil
    local ThumbImg = Create("ImageLabel", {
        Size = UDim2.new(0, 36, 0, 36),
        Position = UDim2.new(0, 6, 0.5, -18),
        BackgroundColor3 = C.bg,
        BorderSizePixel = 0,
        ScaleType = Enum.ScaleType.Crop,
    }, Row)
    AddCorner(ThumbImg, 6)
    local ThumbEmoji = Create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "🎵",
        TextSize = 14,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Visible = false,
    }, ThumbImg)
    ApplyThumb(ThumbImg, ThumbEmoji, item.coverFile)

    -- Judul lagu
    local TitleLbl = Create("TextLabel", {
        Size = UDim2.new(1, -138, 0, 17),
        Position = UDim2.new(0, 50, 0, 6),
        BackgroundTransparency = 1,
        Text = tostring(item.title),
        TextColor3 = active and C.accent or C.text,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, Row)

    -- Nama artis
    Create("TextLabel", {
        Size = UDim2.new(1, -138, 0, 14),
        Position = UDim2.new(0, 50, 0, 24),
        BackgroundTransparency = 1,
        Text = tostring(item.artist or "Tidak diketahui"),
        TextColor3 = C.sub,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, Row)

    -- Durasi lagu
    local DurLbl = Create("TextLabel", {
        Size = UDim2.new(0, 44, 0, 16),
        Position = UDim2.new(1, -80, 0.5, -8),
        BackgroundTransparency = 1,
        Text = item.duration and tostring(item.duration) or "--:--",
        TextColor3 = C.dim,
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, Row)

    -- Tombol hapus lagu
    local DeleteBtn = Create("TextButton", {
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -32, 0.5, -13),
        BackgroundColor3 = Color3.fromRGB(70, 34, 44),
        Text = "🗑️",
        TextSize = 11,
    }, Row)
    AddCorner(DeleteBtn, 6)

    -- Klik baris: aktifkan mode playlist (lanjut otomatis ke lagu berikutnya) lalu putar lagu ini
    PlayRowBtn.MouseButton1Click:Connect(function()
        isPlaylistMode = true
        ResetShuffleHistory()
        PlayItem(item)
    end)

    -- Klik tombol hapus: simpan id lagu lalu tampilkan modal konfirmasi berisi nama lagunya
    DeleteBtn.MouseButton1Click:Connect(function()
        pendingDeleteKey = key
        ConfirmDesc.Text = string.format(
            "Apakah Anda yakin ingin menghapus lagu <b>%s</b> secara permanen dari perangkat?",
            EscapeRich(item.title)
        )
        ConfirmOverlay.Visible = true
    end)

    rowsByKey[key] = { row = Row, title = TitleLbl, duration = DurLbl }
end

-- Fungsi: menggambar ulang daftar lagu di tab Playlist (sudah difilter & diurutkan).
RenderLocalPlaylist = function()
    for _, child in pairs(LocalScroll:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
    rowsByKey = {}

    local total = #LoadLocalPlaylist()
    local list = GetDisplayList()
    UpdateLocalTitle()

    if #list == 0 then
        Create("TextLabel", {
            Name = "EmptyNote",
            Size = UDim2.new(1, 0, 0, 44),
            BackgroundTransparency = 1,
            Text = total == 0
                and "Playlist masih kosong. Download lagu lewat menu Cari Lagu Online, atau masukkan file ke folder imports."
                or "Tidak ada lagu yang cocok dengan filter.",
            TextColor3 = C.dim,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            TextWrapped = true,
        }, LocalScroll)
        return
    end

    for order, entry in ipairs(list) do
        BuildRow(entry.item, order)
    end
end
end

-- URUTAN & FILTER -------------------------------------------------------------
-- Fungsi: memperbarui tampilan tombol urut (yang aktif berwarna biru)
local function RefreshSortButtons()
    SortNameBtn.Text = nameAscending and "Nama A-Z" or "Nama Z-A"
    SortTimeBtn.Text = newestFirst and "Terbaru" or "Terlama"
    local nameOn = (sortMode == "name")
    SortNameBtn.BackgroundColor3 = nameOn and C.accent or C.btn
    SortNameBtn.TextColor3 = nameOn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 200, 220)
    SortTimeBtn.BackgroundColor3 = nameOn and C.btn or C.accent
    SortTimeBtn.TextColor3 = nameOn and Color3.fromRGB(180, 200, 220) or Color3.fromRGB(255, 255, 255)
end

-- Event: tombol urut nama (ketuk saat aktif = balik A-Z <-> Z-A)
SortNameBtn.MouseButton1Click:Connect(function()
    if sortMode == "name" then
        nameAscending = not nameAscending
    else
        sortMode = "name"
    end
    ResetShuffleHistory()
    RefreshSortButtons()
    RenderLocalPlaylist()
end)

-- Event: tombol urut waktu (ketuk saat aktif = balik terbaru <-> terlama)
SortTimeBtn.MouseButton1Click:Connect(function()
    if sortMode == "time" then
        newestFirst = not newestFirst
    else
        sortMode = "time"
    end
    ResetShuffleHistory()
    RefreshSortButtons()
    RenderLocalPlaylist()
end)

-- Event: isi kotak filter berubah -> daftar disaring langsung
FilterBox:GetPropertyChangedSignal("Text"):Connect(function()
    ResetShuffleHistory()
    RenderLocalPlaylist()
end)

-- LAGU MANUAL (FOLDER IMPORTS) ------------------------------------------------
-- Fungsi: memindai folder imports. Lagu .mp3/.ogg baru ditambahkan ke playlist,
-- lagu manual yang filenya sudah tidak ada dihapus dari playlist.
-- Mengembalikan: "ok", "unsupported", "nofolder", atau "error".
local function ScanImports()
    if not listfilesFn then return "unsupported" end
    if not (isfolderFn and isfolderFn(ImportsDir)) then return "nofolder" end
    local okList, files = pcall(listfilesFn, ImportsDir)
    if not okList or type(files) ~= "table" then return "error" end

    local playlist = LoadLocalPlaylist()
    local known, present = {}, {}
    for _, item in ipairs(playlist) do
        if item.source == "import" then known[item.fileName] = true end
    end

    -- urutkan nama agar lagu baru yang ditemukan bersamaan masuk dengan urutan rapi
    local names = {}
    for _, path in ipairs(files) do
        local name = tostring(path):match("([^/\\]+)$")
        if name then
            local lower = name:lower()
            if lower:match("%.mp3$") or lower:match("%.ogg$") then
                present[name] = true
                if not known[name] then table.insert(names, name) end
            end
        end
    end
    table.sort(names)

    local changed = false
    local now = os.time() -- waktu masuk = saat pertama kali terdeteksi
    for _, name in ipairs(names) do
        local title = name:gsub("%.[^.]*$", "")
        table.insert(playlist, 1, {
            id = "import_" .. name,
            title = title,
            artist = "Lokal",
            fileName = name,
            source = "import",
            addedAt = now,
        })
        changed = true
    end

    -- hapus lagu manual yang filenya sudah tidak ada di folder imports
    for i = #playlist, 1, -1 do
        local item = playlist[i]
        if item.source == "import" and not present[item.fileName] then
            table.remove(playlist, i)
            changed = true
        end
    end

    if changed then
        SaveLocalPlaylist(playlist)
        ResetShuffleHistory()
    end
    return "ok"
end

-- Event: tombol "Segarkan" -> pindai folder imports lalu gambar ulang daftar
RefreshBtn.MouseButton1Click:Connect(function()
    local status = ScanImports()
    RenderLocalPlaylist()
    if status == "ok" then
        FlashLocalTitle("🔄 Playlist disegarkan", C.ok)
    elseif status == "unsupported" then
        FlashLocalTitle("⚠️ Executor tidak mendukung pemindaian folder", C.warn)
    elseif status == "nofolder" then
        FlashLocalTitle("⚠️ Folder imports tidak ditemukan", C.warn)
    else
        FlashLocalTitle("⚠️ Gagal memindai folder imports", C.warn)
    end
end)

-- HAPUS LAGU ------------------------------------------------------------------
-- Event: "Batal" pada modal hapus -> tutup modal tanpa menghapus
CancelBtn.MouseButton1Click:Connect(function()
    pendingDeleteKey = nil
    ConfirmOverlay.Visible = false
end)

-- Event: "Hapus" pada modal hapus -> hapus file lagu & cover dari perangkat, lalu dari playlist
ConfirmDeleteBtn.MouseButton1Click:Connect(function()
    if pendingDeleteKey then
        local playlist = LoadLocalPlaylist()
        local removeIdx, item = nil, nil
        for idx, it in ipairs(playlist) do
            if ItemKey(it) == pendingDeleteKey then
                removeIdx, item = idx, it
                break
            end
        end

        if item then
            -- jika lagu yang dihapus sedang diputar, hentikan dulu
            if currentTrackKey == pendingDeleteKey then
                isTransitioning = true
                CurrentSound:Stop()
                CurrentSound.TimePosition = 0
                CurrentSound.SoundId = ""
                isTransitioning = false
                PlayBtn.Text = "▶"
                ProgressFill.Size = UDim2.new(0, 0, 1, 0)
                TrackTitle.Text = "Belum ada lagu diputar"
                TimeLabel.Text = "00:00/00:00"
                currentTrackKey = nil
            end

            -- hapus file lagu (download -> songs, manual -> imports)
            local songFile = SongPath(item)
            if delfileFn and isfileFn and isfileFn(songFile) then
                pcall(function() delfileFn(songFile) end)
            end

            -- hapus file cover agar tidak ada sampah yang tertinggal
            if item.coverFile then
                local coverFile = CoverPath(item.coverFile)
                assetCache[coverFile] = nil
                if delfileFn and isfileFn and isfileFn(coverFile) then
                    pcall(function() delfileFn(coverFile) end)
                end
            end

            table.remove(playlist, removeIdx)
            SaveLocalPlaylist(playlist)
            ResetShuffleHistory()
            RenderLocalPlaylist()
            if RefreshCardAfterDelete then RefreshCardAfterDelete(item.id) end
            PlayerStatusLabel.Text = "Status: 🗑️ Lagu dihapus dari lokal"
        end
        pendingDeleteKey = nil
    end
    ConfirmOverlay.Visible = false
end)

--------------------------------------------------------------------------------
-- 15. TAB NAVIGATION
--------------------------------------------------------------------------------
-- Event: klik tab "Cari Lagu Online" -> tampilkan SearchView, sembunyikan LocalView, ubah warna tab
TabSearchBtn.MouseButton1Click:Connect(function()
    SearchView.Visible = true
    LocalView.Visible = false
    TabSearchBtn.BackgroundColor3 = C.accent
    TabSearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TabLocalBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 58)
    TabLocalBtn.TextColor3 = Color3.fromRGB(180, 200, 220)
end)

-- Event: klik tab "Playlist" -> tampilkan LocalView, sembunyikan SearchView, ubah warna tab
TabLocalBtn.MouseButton1Click:Connect(function()
    SearchView.Visible = false
    LocalView.Visible = true
    TabLocalBtn.BackgroundColor3 = C.accent
    TabLocalBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TabSearchBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 58)
    TabSearchBtn.TextColor3 = Color3.fromRGB(180, 200, 220)

    -- setelah "Putar lagu" dari kartu hasil: gulir daftar ke lagu yang sedang diputar
    if scrollPending then
        scrollPending = false
        RenderLocalPlaylist()
        task.delay(0.1, function()
            if not isClosed then ScrollToCurrent() end
        end)
    end
end)

--------------------------------------------------------------------------------
-- 16. KARTU HASIL PENCARIAN, DOWNLOAD & PENCARIAN LAGU ONLINE
--------------------------------------------------------------------------------
local DeletePreviewCover
do
local currentResult = nil -- kartu hasil yang sedang tampil: { id, data, query, state, ui, coverBytes }
local activeDownloads = {} -- id lagu yang sedang didownload
local previewCoverPath = nil -- file cover sementara untuk pratinjau kartu
local previewCounter = 0
local activeSpinners = {} -- gradient spinner yang sedang berputar

-- Animasi putar spinner pada tombol download (satu loop untuk semua spinner)
Track(RunService.Heartbeat:Connect(function()
    if isClosed then return end
    local rot = (os.clock() * 540) % 360
    for i = #activeSpinners, 1, -1 do
        local sp = activeSpinners[i]
        if sp.Parent then
            sp.Rotation = rot
        else
            table.remove(activeSpinners, i)
        end
    end
end))

-- Fungsi: menghapus file cover pratinjau (delaySec = jeda sebelum dihapus)
DeletePreviewCover = function(delaySec)
    local path = previewCoverPath
    previewCoverPath = nil
    if not path then return end
    assetCache[path] = nil
    local function doDelete()
        if delfileFn and isfileFn and isfileFn(path) then pcall(delfileFn, path) end
    end
    if delaySec and delaySec > 0 then
        task.delay(delaySec, doDelete)
    else
        doDelete()
    end
end

-- Fungsi: mengubah teks status pencarian (di atas kartu hasil)
local function SetSearchStatus(text, color)
    SearchStatusLabel.Text = "Status Pencarian: " .. text
    SearchStatusLabel.TextColor3 = color or C.sub
end

-- Fungsi: membersihkan area hasil (kartu lama, skeleton, petunjuk)
local function ClearResultArea()
    ClearSkeletonLoading(ResultHolder)
    local old = ResultHolder:FindFirstChild("ResultCard")
    if old then old:Destroy() end
    currentResult = nil
    DeletePreviewCover(0)
    EmptyHint.Visible = false
end

-- Fungsi: menampilkan teks petunjuk saat tidak ada hasil
local function ShowEmptyHint()
    EmptyHint.Visible = true
end

-- Fungsi: mengambil kartu hasil jika masih untuk lagu yang dimaksud (nil jika sudah diganti)
local function CardFor(id)
    local r = currentResult
    if r and r.id == id and r.ui and r.ui.Btn.Parent then return r end
    return nil
end

-- Fungsi: memperbarui tampilan tombol sesuai state kartu (idle / loading / ready)
local function ApplyCardState(result)
    local ui = result.ui
    if not ui or not ui.Btn.Parent then return end
    if result.state == "loading" then
        ui.Btn.Text = "Mendownload…"
        ui.Btn.BackgroundColor3 = Color3.fromRGB(35, 70, 105)
        ui.Spinner.Visible = true
    elseif result.state == "ready" then
        ui.Btn.Text = "▶ Putar lagu"
        ui.Btn.BackgroundColor3 = C.play
        ui.Spinner.Visible = false
    else
        ui.Btn.Text = "⬇ Download"
        ui.Btn.BackgroundColor3 = C.accent
        ui.Spinner.Visible = false
    end
end

-- Fungsi: mengubah teks status download pada kartu
local function SetCardStatus(id, text, color)
    local r = CardFor(id)
    if not r then return end
    r.ui.Status.Text = text
    r.ui.Status.TextColor3 = color or C.sub
end

-- Fungsi: mengubah progres download pada kartu (0-100, nil = kosongkan)
local function SetCardProgress(id, p)
    local r = CardFor(id)
    if not r then return end
    if p == nil then
        r.ui.Percent.Text = ""
        TweenService:Create(r.ui.Fill, TweenInfo.new(0.2), { Size = UDim2.new(0, 0, 1, 0) }):Play()
    else
        p = math.clamp(p, 0, 100)
        r.ui.Percent.Text = string.format("%d%%", math.floor(p))
        TweenService:Create(r.ui.Fill, TweenInfo.new(0.25), { Size = UDim2.new(p / 100, 0, 1, 0) }):Play()
    end
end

-- Fungsi: dipanggil setelah sebuah lagu dihapus; jika kartu yang tampil lagu itu, kembalikan ke "Download"
RefreshCardAfterDelete = function(id)
    local r = CardFor(id)
    if r and r.state == "ready" then
        r.state = "idle"
        ApplyCardState(r)
        SetCardStatus(id, "Siap didownload", C.sub)
        SetCardProgress(id, nil)
    end
end

-- Fungsi: apakah data hasil download kemungkinan berisi audio (bukan halaman/JSON error)?
local function LooksLikeAudio(body)
    if not body or #body < 10240 then return false end
    local head = body:sub(1, 1)
    if head == "{" or head == "<" then return false end
    return true
end

-- Fungsi: memutar lagu dari tombol "Putar lagu" pada kartu (lanjut ke lagu berikutnya setelah selesai)
local function PlayFromCard(result)
    local item = FindItemById(result.id)
    if not item then
        result.state = "idle"
        ApplyCardState(result)
        SetCardStatus(result.id, "Siap didownload", C.sub)
        SetCardProgress(result.id, nil)
        return
    end
    isPlaylistMode = true -- setelah selesai lanjut ke lagu berikutnya di playlist
    ResetShuffleHistory()
    scrollPending = true -- saat tab Playlist dibuka, gulir ke lagu ini
    PlayItem(item)
end

-- Fungsi: download lagu dari kartu hasil lalu simpan ke playlist.
-- Alur: cek link -> download audio -> simpan lagu -> simpan cover -> masuk playlist.
-- Jika link kedaluwarsa/gagal, lagu dicari ulang otomatis untuk mendapat link baru.
local function StartDownload(result)
    local id = result.id
    local data = result.data
    if activeDownloads[id] then return end

    -- jika lagu sudah ada di playlist, tidak perlu download ulang
    if FindItemById(id) then
        result.state = "ready"
        ApplyCardState(result)
        SetCardStatus(id, "Lagu sudah ada di playlist kamu.", C.warn)
        return
    end

    activeDownloads[id] = true
    result.state = "loading"
    ApplyCardState(result)
    SetCardStatus(id, "Mendownload…", C.warn)
    SetCardProgress(id, 5)

    local finished = false
    local creeping = false

    -- Fungsi: menghentikan proses dengan pesan gagal
    local function fail(msg)
        if finished then return end
        finished = true
        creeping = false
        activeDownloads[id] = nil
        if isClosed then return end
        local r = CardFor(id)
        if r then
            r.state = "idle"
            ApplyCardState(r)
            SetCardStatus(id, msg, C.err)
            SetCardProgress(id, nil)
        end
    end

    -- Batas waktu seluruh proses download
    task.delay(DOWNLOAD_TIMEOUT, function()
        if not finished and not isClosed then fail(MSG_NO_RESPONSE) end
    end)

    -- Fungsi: progres bergerak pelan selama audio diunduh (executor tidak memberi progres byte asli)
    local function startCreep()
        creeping = true
        task.spawn(function()
            local p = 30
            while creeping and not finished and not isClosed do
                task.wait(0.5)
                if not creeping or finished or isClosed then break end
                p = math.min(65, p + 1.5)
                SetCardProgress(id, p)
            end
        end)
    end

    task.spawn(function()
        local mp3Url = data.mp3_url
        local refreshed = false

        -- Fungsi: cari ulang lagu lewat API untuk mendapat link mp3 baru.
        -- Mengembalikan link baru, atau nil beserta pesan kegagalan.
        local function refreshLink()
            SetCardStatus(id, "Mencari link baru…", C.warn)
            SetCardProgress(id, 10)
            local st, fresh = FetchSongData(result.query)
            if finished or isClosed then return nil end
            if st == "ok" then
                if ExtractTrackId(fresh) == id then return fresh.mp3_url end
                return nil, "Link lagu kedaluwarsa, silakan cari ulang."
            end
            if st == "notfound" then return nil, tostring(fresh) end
            return nil, MSG_NO_RESPONSE
        end

        -- 1) Link sudah kedaluwarsa? Cari ulang dulu
        if Mp3NeedsRefresh(mp3Url) then
            local newUrl, why = refreshLink()
            if finished or isClosed then return end
            if not newUrl then fail(why or MSG_NO_RESPONSE) return end
            mp3Url = newUrl
            refreshed = true
        end

        -- 2) Download audio
        SetCardStatus(id, "Mendownload…", C.warn)
        SetCardProgress(id, 30)
        startCreep()
        local body = DownloadBinary(mp3Url)

        -- gagal / bukan audio -> kemungkinan link kedaluwarsa, cari ulang sekali lalu coba lagi
        if not LooksLikeAudio(body) and not refreshed then
            creeping = false
            local newUrl, why = refreshLink()
            if finished or isClosed then return end
            if not newUrl then fail(why or MSG_NO_RESPONSE) return end
            refreshed = true
            SetCardStatus(id, "Mendownload…", C.warn)
            SetCardProgress(id, 30)
            startCreep()
            body = DownloadBinary(newUrl)
        end
        creeping = false
        if finished or isClosed then return end
        if not LooksLikeAudio(body) then fail(MSG_NO_RESPONSE) return end

        -- 3) Simpan file lagu ke folder songs
        SetCardStatus(id, "Menyimpan lagu…", C.warn)
        SetCardProgress(id, 70)
        local fileName = "raff_song_" .. id .. ".mp3"
        local songPath = SubPath(SONGS_FOLDER, fileName)
        local wrote = writefileFn ~= nil and pcall(function() writefileFn(songPath, body) end)
        if not wrote or (isfileFn and not isfileFn(songPath)) then
            fail("Gagal menyimpan lagu ke perangkat.")
            return
        end
        if finished or isClosed then
            -- proses sudah dibatalkan (timeout / UI ditutup): bersihkan file yang terlanjur tertulis
            if delfileFn and isfileFn and isfileFn(songPath) then pcall(delfileFn, songPath) end
            return
        end

        -- 4) Simpan cover ke folder covers (gunakan hasil pratinjau jika sudah ada)
        SetCardProgress(id, 85)
        local coverFile = nil
        local bytes = result.coverBytes or DownloadBinary(data.cover)
        if bytes and #bytes > 0 and writefileFn then
            local cf = "cover_" .. id .. ".jpg"
            local okCover = pcall(function() writefileFn(CoverPath(cf), bytes) end)
            if okCover and ((not isfileFn) or isfileFn(CoverPath(cf))) then coverFile = cf end
        end
        if finished or isClosed then
            if delfileFn and isfileFn then
                if isfileFn(songPath) then pcall(delfileFn, songPath) end
                if coverFile and isfileFn(CoverPath(coverFile)) then pcall(delfileFn, CoverPath(coverFile)) end
            end
            return
        end

        -- 5) Masukkan ke playlist (waktu masuk = saat selesai didownload)
        SetCardProgress(id, 95)
        local playlist = LoadLocalPlaylist()
        local durText = data.duration ~= nil and tostring(data.duration) or nil
        table.insert(playlist, 1, {
            id = id,
            title = tostring(data.title or "Tanpa judul"),
            artist = tostring(data.artist or "Tidak diketahui"),
            album = data.album,
            year = data.year,
            duration = durText,
            durationSec = ParseDuration(durText),
            fileName = fileName,
            coverFile = coverFile,
            source = "download",
            addedAt = os.time(),
        })
        SaveLocalPlaylist(playlist)
        ResetShuffleHistory()
        RenderLocalPlaylist()

        -- 6) Selesai
        finished = true
        activeDownloads[id] = nil
        local r = CardFor(id)
        if r then
            r.state = "ready"
            ApplyCardState(r)
            SetCardProgress(id, 100)
            SetCardStatus(id, "Berhasil tersimpan di playlist kamu.", C.ok)
            -- pakai cover yang sudah tersimpan permanen, lalu hapus file pratinjau
            if coverFile then
                local asset = GetAssetCached(CoverPath(coverFile))
                if asset then
                    r.ui.Thumb.Image = asset
                    r.ui.ThumbEmoji.Visible = false
                end
            end
            DeletePreviewCover(3)
        end
    end)
end

-- Fungsi: membuat kartu hasil pencarian (satu kartu penuh mengikuti ukuran area hasil).
-- Isi kartu: thumbnail, judul, artis, album & tahun, durasi, status download + progres, tombol.
local function ShowResultCard(data, query)
    ClearResultArea()
    local id = ExtractTrackId(data)
    local result = { id = id, data = data, query = query, state = "idle" }
    currentResult = result

    -- Kartu pembungkus
    local Card = Create("Frame", {
        Name = "ResultCard",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = C.card,
    }, ResultHolder)
    AddCorner(Card, 12)
    Create("UIStroke", { Color = C.stroke, Thickness = 1 }, Card)

    -- Thumbnail (cover lagu)
    local Thumb = Create("ImageLabel", {
        BackgroundColor3 = C.bg,
        BorderSizePixel = 0,
        ScaleType = Enum.ScaleType.Crop,
    }, Card)
    AddCorner(Thumb, 10)
    local ThumbEmoji = Create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "🎵",
        TextSize = 28,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Visible = false,
    }, Thumb)
    ApplyThumb(Thumb, ThumbEmoji, nil) -- sementara pakai ikon cadangan sampai cover selesai dimuat

    -- Kolom info di kanan (bisa digulir jika jendela dikecilkan)
    local Info = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, Card)
    Create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, Info)
    BindCardLayout(Card, Thumb, Info)

    -- Judul lagu
    Create("TextLabel", {
        Size = UDim2.new(1, -6, 0, 17),
        BackgroundTransparency = 1,
        Text = tostring(data.title or "Tanpa judul"),
        TextColor3 = C.text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 1,
    }, Info)

    -- Artis
    Create("TextLabel", {
        Size = UDim2.new(1, -6, 0, 14),
        BackgroundTransparency = 1,
        Text = tostring(data.artist or "Tidak diketahui"),
        TextColor3 = C.accentSoft,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 2,
    }, Info)

    -- Album & tahun
    local metaParts = {}
    if data.album and tostring(data.album) ~= "" then table.insert(metaParts, tostring(data.album)) end
    if data.year then table.insert(metaParts, tostring(data.year)) end
    Create("TextLabel", {
        Size = UDim2.new(1, -6, 0, 12),
        BackgroundTransparency = 1,
        Text = table.concat(metaParts, " • "),
        TextColor3 = C.dim,
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 3,
    }, Info)

    -- Garis pemisah atas
    Create("Frame", {
        Size = UDim2.new(1, -6, 0, 1),
        BackgroundColor3 = C.stroke,
        BorderSizePixel = 0,
        LayoutOrder = 4,
    }, Info)

    -- Durasi
    Create("TextLabel", {
        Size = UDim2.new(1, -6, 0, 13),
        BackgroundTransparency = 1,
        Text = "⏱ " .. tostring(data.duration or "--:--"),
        TextColor3 = Color3.fromRGB(200, 215, 235),
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 5,
    }, Info)

    -- Baris status download + persentase
    local StatusRow = Create("Frame", {
        Size = UDim2.new(1, -6, 0, 13),
        BackgroundTransparency = 1,
        LayoutOrder = 6,
    }, Info)
    local StatusLbl = Create("TextLabel", {
        Size = UDim2.new(1, -36, 1, 0),
        BackgroundTransparency = 1,
        Text = "Siap didownload",
        TextColor3 = C.sub,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, StatusRow)
    local PercentLbl = Create("TextLabel", {
        Size = UDim2.new(0, 34, 1, 0),
        Position = UDim2.new(1, -34, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = C.accentSoft,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, StatusRow)

    -- Garis pemisah bawah = jalur progres download (terisi biru saat mendownload)
    local Track2 = Create("Frame", {
        Size = UDim2.new(1, -6, 0, 4),
        BackgroundColor3 = C.track,
        BorderSizePixel = 0,
        LayoutOrder = 7,
    }, Info)
    AddCorner(Track2, 2)
    local Fill = Create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
    }, Track2)
    AddCorner(Fill, 2)

    -- Tombol download / putar lagu
    local Btn = Create("TextButton", {
        Size = UDim2.new(1, -6, 0, 26),
        BackgroundColor3 = C.accent,
        Text = "⬇ Download",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = true,
        LayoutOrder = 8,
    }, Info)
    AddCorner(Btn, 6)

    -- Spinner kecil (cincin berputar) di sisi kiri teks tombol saat mendownload
    local Spinner = Create("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        BackgroundTransparency = 1,
        Visible = false,
    }, Btn)
    AddCorner(Spinner, 6)
    local SpinStroke = Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 2 }, Spinner)
    local SpinGradient = Create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.5, 0.15),
            NumberSequenceKeypoint.new(0.51, 1),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, SpinStroke)
    table.insert(activeSpinners, SpinGradient)

    local function placeSpinner()
        Spinner.Position = UDim2.new(0.5, -math.floor(Btn.TextBounds.X / 2) - 20, 0.5, -6)
    end
    Btn:GetPropertyChangedSignal("TextBounds"):Connect(placeSpinner)
    placeSpinner()

    result.ui = {
        Btn = Btn, Spinner = Spinner, Status = StatusLbl, Percent = PercentLbl,
        Fill = Fill, Thumb = Thumb, ThumbEmoji = ThumbEmoji,
    }

    -- Keadaan awal: sudah ada di playlist / sedang didownload / belum didownload
    if FindItemById(id) then
        result.state = "ready"
        StatusLbl.Text = "Lagu sudah ada di playlist kamu."
        StatusLbl.TextColor3 = C.warn
    elseif activeDownloads[id] then
        result.state = "loading"
        StatusLbl.Text = "Mendownload…"
        StatusLbl.TextColor3 = C.warn
    end
    ApplyCardState(result)

    -- Klik tombol: download (idle) atau putar (ready); saat loading diabaikan
    Btn.MouseButton1Click:Connect(function()
        if result.state == "idle" then
            StartDownload(result)
        elseif result.state == "ready" then
            PlayFromCard(result)
        end
    end)

    -- Muat cover di background: simpan sebagai file pratinjau sementara lalu tampilkan
    task.spawn(function()
        if not data.cover then return end
        local bytes = DownloadBinary(data.cover)
        if isClosed or currentResult ~= result or not bytes then return end
        result.coverBytes = bytes
        if writefileFn then
            previewCounter = previewCounter + 1
            local path = CoverPath(string.format("preview_%d_%d.jpg", os.time(), previewCounter))
            if pcall(function() writefileFn(path, bytes) end) then
                previewCoverPath = path
                local asset = GetAssetCached(path)
                if asset and Thumb.Parent and currentResult == result then
                    Thumb.Image = asset
                    ThumbEmoji.Visible = false
                end
            end
        end
    end)
end

-- PENCARIAN -------------------------------------------------------------------
local isSearching = false
local searchToken = 0

-- Fungsi: mencari lagu lewat API dan menampilkan hasilnya sebagai satu kartu.
-- Hanya dipanggil oleh tombol "Cari".
local function ExecuteSearch()
    local query = TrimStr(SearchBox.Text)
    -- jangan cari jika kotak pencarian kosong
    if query == "" then
        SetSearchStatus("⚠️ Ketik judul lagu dulu", C.warn)
        return
    end
    if isSearching then return end

    isSearching = true
    searchToken = searchToken + 1
    local myToken = searchToken

    -- tampilkan animasi loading sambil menunggu server
    ClearResultArea()
    ShowSkeletonLoading(ResultHolder)
    SetSearchStatus("⏳ Mencari lagu online...", C.warn)

    local finished = false
    local function finish()
        finished = true
        isSearching = false
        ClearSkeletonLoading(ResultHolder)
    end

    -- Batas waktu pencarian: jika server tidak menjawab, tampilkan pesan & izinkan mencari lagi
    task.delay(SEARCH_TIMEOUT, function()
        if finished or isClosed or searchToken ~= myToken then return end
        finish()
        ShowEmptyHint()
        SetSearchStatus("❌ " .. MSG_NO_RESPONSE, C.err)
    end)

    -- Proses jaringan dijalankan di thread terpisah agar UI tidak membeku
    task.spawn(function()
        local status, result = FetchSongData(query)
        if finished or isClosed or searchToken ~= myToken then return end
        finish()

        if status == "ok" then
            ShowResultCard(result, query)
            SetSearchStatus("🟢 Lagu ditemukan", C.ok)
        elseif status == "notfound" then
            ShowEmptyHint()
            SetSearchStatus("⚠️ " .. tostring(result), C.err) -- pesan dari JSON "message"
        else
            ShowEmptyHint()
            SetSearchStatus("❌ " .. MSG_NO_RESPONSE, C.err)
        end
    end)
end

-- Jalankan pencarian HANYA saat tombol "Cari" ditekan
SearchBtn.MouseButton1Click:Connect(ExecuteSearch)
end

--------------------------------------------------------------------------------
-- 17. TUTUP UI (X) & PANDUAN (i)
--------------------------------------------------------------------------------
-- Fungsi: menutup Raff Musik sepenuhnya: hentikan musik, putus semua event/loop/animasi,
-- batalkan proses yang berjalan, hapus file pratinjau, lalu hapus UI.
local function Shutdown()
    if isClosed then return end
    isClosed = true
    for _, conn in ipairs(trackedConnections) do
        pcall(function() conn:Disconnect() end)
    end
    trackedConnections = {}
    for _, tween in ipairs(activeSkeletonTweens) do
        pcall(function() tween:Cancel() end)
    end
    activeSkeletonTweens = {}
    pcall(function()
        CurrentSound:Stop()
        CurrentSound:Destroy()
    end)
    DeletePreviewCover(0)
    pcall(function() ScreenGui:Destroy() end)
    if GlobalEnv.RaffMusikShutdown == Shutdown then GlobalEnv.RaffMusikShutdown = nil end
end

-- Event: tombol "i" -> tampilkan panduan pengguna
InfoBtn.MouseButton1Click:Connect(function()
    InfoOverlay.Visible = true
end)

-- Event: tombol "Mengerti" -> tutup panduan
InfoCloseBtn.MouseButton1Click:Connect(function()
    InfoOverlay.Visible = false
end)

-- Event: tombol X -> tampilkan modal konfirmasi tutup
CloseBtn.MouseButton1Click:Connect(function()
    CloseOverlay.Visible = true
end)

-- Event: "Batal" pada modal tutup
CloseCancelBtn.MouseButton1Click:Connect(function()
    CloseOverlay.Visible = false
end)

-- Event: "Tutup" pada modal tutup -> hentikan semuanya
CloseConfirmBtn.MouseButton1Click:Connect(Shutdown)

--------------------------------------------------------------------------------
-- 18. INISIALISASI
--------------------------------------------------------------------------------
-- Daftarkan fungsi penutup supaya script lama berhenti total jika script dijalankan ulang
GlobalEnv.RaffMusikShutdown = Shutdown

-- Bersihkan sisa file pratinjau cover dari sesi sebelumnya (jika ada)
if listfilesFn and delfileFn and subfolderReady[COVERS_FOLDER] then
    pcall(function()
        for _, path in ipairs(listfilesFn(PROJECT_FOLDER .. "/" .. COVERS_FOLDER)) do
            local name = tostring(path):match("([^/\\]+)$") or ""
            if name:match("^preview_") then pcall(delfileFn, path) end
        end
    end)
end

-- Pindai folder imports (lagu manual), lalu tampilkan playlist saat script pertama kali dijalankan
pcall(ScanImports)
RefreshSortButtons()
RenderLocalPlaylist()
