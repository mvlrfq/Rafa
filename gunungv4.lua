-- Load Library Orion UI (Mirror Repositori Aktif)
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()

-- Membuat Window Utama
local Window = OrionLib:MakeWindow({
    Name = "Gunung Teleport - v5.1",
    HidePremium = true,
    SaveConfig = false,
    ConfigFolder = "GunungTeleportConfigs",
    IntroEnabled = false
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
local TabMain = Window:MakeTab({ Name = "Main CP", Icon = "rbxassetid://4483345998" })
local TabCustom = Window:MakeTab({ Name = "Waypoint", Icon = "rbxassetid://4483345998" })
local TabSettings = Window:MakeTab({ Name = "Setting", Icon = "rbxassetid://4483345998" })

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

-- Render List Waypoint
local function renderWaypointListUI()
    for i, wp in ipairs(customWaypoints) do
        TabCustom:AddButton({
            Name = "Teleport ke " .. wp.Name,
            Callback = function()
                teleportTo(wp.CF)
                OrionLib:MakeNotification({
                    Name = "Teleport",
                    Content = "Pindah ke " .. wp.Name,
                    Image = "rbxassetid://4483345998",
                    Time = 1.5
                })
            end
        })
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
            OrionLib:MakeNotification({
                Name = "Config Dimuat",
                Content = "Berhasil memuat " .. #customWaypoints .. " waypoint tersimpan.",
                Image = "rbxassetid://4483345998",
                Time = 3
            })
        else
            OrionLib:MakeNotification({
                Name = "Peringatan",
                Content = "File config kosong atau tidak valid.",
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        end
    else
        OrionLib:MakeNotification({
            Name = "Gagal Load",
            Content = "Belum ada config tersimpan di map ini.",
            Image = "rbxassetid://4483345998",
            Time = 2.5
        })
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
TabMain:AddSection({ Name = "Fitur Deteksi & Auto Checkpoint" })

TabMain:AddButton({
    Name = "Scan Checkpoints Map",
    Callback = function()
        scanCheckpoints()
        OrionLib:MakeNotification({
            Name = "Scan Selesai",
            Content = "Ditemukan " .. #checkpoints .. " Checkpoint.",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

TabMain:AddToggle({
    Name = "Auto Teleport CP (Looping)",
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

TabMain:AddTextbox({
    Name = "Teleport Manual CP",
    Default = "",
    TextDisappear = true,
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
TabCustom:AddSection({ Name = "Pengaturan Custom Waypoint" })

TabCustom:AddButton({
    Name = "Tambah Waypoint di Posisi Ini",
    Callback = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local currentCF = LocalPlayer.Character.HumanoidRootPart.CFrame
            local wpIndex = #customWaypoints + 1
            local wpName = "Waypoint " .. wpIndex
            table.insert(customWaypoints, {Name = wpName, CF = currentCF})
            saveWaypointsToFile()
            
            TabCustom:AddButton({
                Name = "Teleport ke " .. wpName,
                Callback = function()
                    teleportTo(currentCF)
                    OrionLib:MakeNotification({
                        Name = "Teleport",
                        Content = "Pindah ke " .. wpName,
                        Image = "rbxassetid://4483345998",
                        Time = 1.5
                    })
                end
            })

            OrionLib:MakeNotification({
                Name = "Tersimpan",
                Content = wpName .. " berhasil ditambahkan!",
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        end
    end
})

TabCustom:AddButton({
    Name = "Load Config Waypoint Tersimpan",
    Callback = function()
        loadWaypointsFromFile()
    end
})

TabCustom:AddToggle({
    Name = "Auto Custom Teleport (Looping)",
    Default = false,
    Callback = function(Value)
        autoCustomActive = Value
        task.spawn(function()
            while autoCustomActive do
                if #customWaypoints == 0 then break end
                for _, wp in ipairs(customWaypoints) do
                    if not autoCustomActive then break end
                    teleportTo(wp.CF)
                    task.wait(loopDelay)
                end
                task.wait(0.5)
            end
        end)
    end
})

TabCustom:AddButton({
    Name = "Hapus Semua Waypoint & Saved File",
    Callback = function()
        customWaypoints = {}
        if delfile and isfile and isfile(fileName) then
            delfile(fileName)
        end
        OrionLib:MakeNotification({
            Name = "Reset",
            Content = "Semua waypoint berhasil dihapus dari file.",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

TabCustom:AddSection({ Name = "Daftar List Waypoint Tersimpan" })

-- ================= TAB 3: SETTINGS =================
TabSettings:AddSection({ Name = "Pengaturan UI & Delay" })

TabSettings:AddSlider({
    Name = "Jeda Teleport / Delay (Detik)",
    Min = 1,
    Max = 10,
    Default = 2,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "Detik",
    Callback = function(Value)
        loopDelay = Value
    end
})

local function cleanupAll()
    autoCPActive = false
    autoCustomActive = false
    checkpoints = {}
    customWaypoints = {}
    
    local parentGui = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    if parentGui:FindFirstChild("ToggleGui_Gunung_Fix") then
        parentGui.ToggleGui_Gunung_Fix:Destroy()
    end
end

TabSettings:AddButton({
    Name = "Close Script & Reset Status",
    Callback = function()
        cleanupAll()
        OrionLib:Destroy()
    end
})

-- ================= DRAGGABLE TOGGLE BUTTON =================
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
    btn.Size = UDim2.new(0, 40, 0, 40)
    btn.Position = UDim2.new(0.05, 0, 0.15, 0)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    btn.Text = "MENU"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 11
    btn.Active = true
    btn.Draggable = true
    btn.Parent = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = btn

    local isShown = true
    btn.MouseButton1Click:Connect(function()
        isShown = not isShown
        for _, gui in pairs(parentGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name == "Orion" then
                gui.Enabled = isShown
            end
        end
    end)
end

createDraggableButton()
OrionLib:Init()
