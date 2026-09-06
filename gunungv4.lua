-- Load Library Fluent UI
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Ukuran UI Sedang
local Window = Fluent:CreateWindow({
    Title = "Gunung Teleport",
    SubTitle = "v4.4 Fixed Toggle Visibility",
    TabWidth = 120,
    Size = UDim2.fromOffset(460, 320),
    Acrylic = false,
    Theme = "Dark"
})

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Pengelolaan Folder Khusus
local folderName = "GunungTeleportConfigs"
local fileName = folderName .. "/Gunung_Waypoints_" .. tostring(game.PlaceId) .. ".json"

local function ensureFolderExists()
    if makefolder and isfolder then
        if not isfolder(folderName) then
            makefolder(folderName)
        end
    end
end

-- Variable States
local checkpoints = {}
local customWaypoints = {}
local waypointButtons = {}
local autoCPActive = false
local autoCustomActive = false
local loopDelay = 2

-- Function: Teleport
local function teleportTo(cframe)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cframe + Vector3.new(0, 3, 0)
    end
end

-- Tabs UI
local Tabs = {
    Main = Window:AddTab({ Title = "Main CP", Icon = "map-pin" }),
    Custom = Window:AddTab({ Title = "Waypoint", Icon = "bookmark" }),
    Settings = Window:AddTab({ Title = "Setting", Icon = "settings" })
}

-- Save Functions
local function saveWaypointsToFile()
    ensureFolderExists()
    local dataToSave = {}
    for _, wp in ipairs(customWaypoints) do
        local pos = wp.CF.Position
        table.insert(dataToSave, {
            Name = wp.Name,
            Pos = {pos.X, pos.Y, pos.Z}
        })
    end
    pcall(function()
        writefile(fileName, HttpService:JSONEncode(dataToSave))
    end)
end

-- Fungsi Menghapus Seluruh Tombol List Waypoint di UI
local function clearWaypointUIList()
    for _, btnElement in ipairs(waypointButtons) do
        pcall(function()
            if btnElement and btnElement.Destroy then
                btnElement:Destroy()
            end
        end)
    end
    waypointButtons = {}
end

-- Fungsi Menambahkan & Menampilkan List Waypoint ke UI
local function renderWaypointListUI()
    clearWaypointUIList()
    
    for i, wp in ipairs(customWaypoints) do
        local newBtn = Tabs.Custom:AddButton({
            Title = "Teleport ke " .. wp.Name,
            Callback = function()
                teleportTo(wp.CF)
                Fluent:Notify({ Title = "Teleport", Content = "Pindah ke " .. wp.Name, Duration = 1.5 })
            end
        })
        table.insert(waypointButtons, newBtn)
    end
end

local function loadWaypointsFromFile()
    ensureFolderExists()
    if readfile and isfile and isfile(fileName) then
        local success = pcall(function()
            local rawData = readfile(fileName)
            local decoded = HttpService:JSONDecode(rawData)
            customWaypoints = {}
            for _, item in ipairs(decoded) do
                table.insert(customWaypoints, {
                    Name = item.Name,
                    CF = CFrame.new(item.Pos[1], item.Pos[2], item.Pos[3])
                })
            end
        end)

        if success and #customWaypoints > 0 then
            renderWaypointListUI()
            Fluent:Notify({ 
                Title = "Config Dimuat", 
                Content = "Berhasil memuat " .. #customWaypoints .. " waypoint tersimpan.", 
                Duration = 3 
            })
        else
            Fluent:Notify({ Title = "Peringatan", Content = "File config kosong atau tidak valid.", Duration = 2 })
        end
    else
        Fluent:Notify({ Title = "Gagal Load", Content = "Belum ada config tersimpan di map ini.", Duration = 2.5 })
    end
end

-- Scan Checkpoints Map
local function scanCheckpoints()
    checkpoints = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local nameLower = obj.Name:lower()
            if nameLower:find("cp") or nameLower:find("checkpoint") or nameLower:find("stage") or nameLower:find("pos") then
                table.insert(checkpoints, obj)
            end
        end
    end
    table.sort(checkpoints, function(a, b)
        local numA = tonumber(a.Name:match("%d+")) or 0
        local numB = tonumber(b.Name:match("%d+")) or 0
        return numA < numB
    end)
end

-- ================= TAB 1: MAIN TELEPORT =================
Tabs.Main:AddSection("Fitur Deteksi & Auto Checkpoint")

Tabs.Main:AddButton({
    Title = "Scan Checkpoints Map",
    Callback = function()
        scanCheckpoints()
        Fluent:Notify({ Title = "Scan Selesai", Content = "Ditemukan " .. #checkpoints .. " Checkpoint.", Duration = 2 })
    end
})

Tabs.Main:AddToggle("AutoCPToggle", {
    Title = "Auto Teleport CP (Looping)",
    Default = false,
    Callback = function(Value)
        autoCPActive = Value
        task.spawn(function()
            while autoCPActive do
                if #checkpoints == 0 then scanCheckpoints() end
                for _, cp in ipairs(checkpoints) do
                    if not autoCPActive then break end
                    local targetCF = cp:IsA("Model") and cp:GetPivot() or cp.CFrame
                    teleportTo(targetCF)
                    task.wait(loopDelay)
                end
                task.wait(0.5)
            end
        end)
    end
})

Tabs.Main:AddInput("CPInput", {
    Title = "Teleport Manual CP",
    Default = "",
    Placeholder = "Ketik Angka CP (Misal: 1, 2)",
    Numeric = true,
    Finished = true,
    Callback = function(Text)
        local cpIndex = tonumber(Text)
        if cpIndex and checkpoints[cpIndex] then
            local cp = checkpoints[cpIndex]
            local targetCF = cp:IsA("Model") and cp:GetPivot() or cp.CFrame
            teleportTo(targetCF)
        end
    end
})

-- ================= TAB 2: CUSTOM WAYPOINT =================
Tabs.Custom:AddSection("Pengaturan Custom Waypoint")

Tabs.Custom:AddButton({
    Title = "Tambah Waypoint di Posisi Ini",
    Callback = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local currentCF = LocalPlayer.Character.HumanoidRootPart.CFrame
            local wpIndex = #customWaypoints + 1
            local wpName = "Waypoint " .. wpIndex
            table.insert(customWaypoints, {Name = wpName, CF = currentCF})
            saveWaypointsToFile()
            
            renderWaypointListUI()

            Fluent:Notify({ Title = "Tersimpan", Content = wpName .. " berhasil ditambahkan!", Duration = 2 })
        end
    end
})

Tabs.Custom:AddButton({
    Title = "Load Config Waypoint Tersimpan",
    Callback = function()
        loadWaypointsFromFile()
    end
})

Tabs.Custom:AddToggle("AutoCustomToggle", {
    Title = "Auto Custom Teleport (Looping)",
    Default = false,
    Callback = function(Value)
        autoCustomActive = Value
        task.spawn(function()
            while autoCustomActive do
                if #customWaypoints == 0 then break end
                for _, wp in ipairs(customWaypoints) do
                    if not autoCustomActive me break end
                    teleportTo(wp.CF)
                    task.wait(loopDelay)
                end
                task.wait(0.5)
            end
        end)
    end
})

Tabs.Custom:AddButton({
    Title = "Hapus Semua Waypoint & Saved File",
    Callback = function()
        Window:Dialog({
            Title = "Konfirmasi Hapus",
            Content = "Apakah kamu yakin ingin menghapus semua file simpanan waypoint untuk map ini?",
            Buttons = {
                {
                    Title = "Ya, Hapus",
                    Callback = function()
                        customWaypoints = {}
                        clearWaypointUIList()
                        
                        if delfile and isfile and isfile(fileName) then
                            delfile(fileName)
                        end
                        Fluent:Notify({ Title = "Reset", Content = "Semua waypoint berhasil dihapus dari file & UI.", Duration = 2 })
                    end
                },
                {
                    Title = "Batal",
                    Callback = function() end
                }
            }
        })
    end
})

Tabs.Custom:AddSection("Daftar List Waypoint Tersimpan")

-- ================= TAB 3: SETTINGS =================
Tabs.Settings:AddSection("Pengaturan UI & Delay")

Tabs.Settings:AddSlider("DelaySlider", {
    Title = "Jeda Teleport / Delay (Detik)",
    Default = 2,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Callback = function(Value)
        loopDelay = Value
    end
})

-- Fungsi Pembersihan saat Script ditutup total
local function cleanupAll()
    autoCPActive = false
    autoCustomActive = false
    checkpoints = {}
    customWaypoints = {}
    clearWaypointUIList()
    
    local parentGui = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    if parentGui:FindFirstChild("ToggleGui_Gunung_Fix") then
        parentGui.ToggleGui_Gunung_Fix:Destroy()
    end
end

Tabs.Settings:AddButton({
    Title = "Close Script & Reset Status",
    Callback = function()
        cleanupAll()
        Fluent:Destroy()
    end
})

-- Jika tombol SILANG diklik -> Hapus Toggle & Reset
Window.OnClose:Connect(function()
    cleanupAll()
end)

-- ================= DRAGGABLE TOGGLE BUTTON (DIRECT FLUENT REF) =================
local function createDraggableButton()
    local parentGui = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")

    if parentGui:FindFirstChild("ToggleGui_Gunung_Fix") then
        parentGui.ToggleGui_Gunung_Fix:Destroy()
    end

    local sg = Instance.new("ScreenGui")
    sg.Name = "ToggleGui_Gunung_Fix"
    sg.Parent = parentGui
    sg.ResetOnSpawn = false

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 35, 0, 35)
    btn.Position = UDim2.new(0.05, 0, 0.15, 0)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.Text = "MENU"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 10
    btn.Active = true
    btn.Draggable = true
    btn.Parent = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 18)
    corner.Parent = btn

    -- Mengontrol langsung ScreenGui bawaan Fluent UI lewat objek internal
    local isShown = true
    btn.MouseButton1Click:Connect(function()
        isShown = not isShown
        
        -- Akses langsung pointer GUI bawaan Fluent UI
        if Window and Window.Root then
            Window.Root.Enabled = isShown
        elseif Fluent and Fluent.GUI then
            Fluent.GUI.Enabled = isShown
        end
    end)
end

createDraggableButton()
