-- Load Library Fluent UI (Stabil di HP/Executor)
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Gunung Explorer Script",
    SubTitle = "by Assistant",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 340),
    Acrylic = false,
    Theme = "Dark"
})

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- File Simpanan berdasarkan ID Map
local fileName = "Gunung_Waypoints_" .. tostring(game.PlaceId) .. ".json"

-- Variable States
local checkpoints = {}
local customWaypoints = {}
local autoCPActive = false
local autoCustomActive = false
local loopDelay = 2
local selectedWaypointName = ""

-- Function: Teleport
local function teleportTo(cframe)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cframe + Vector3.new(0, 3, 0)
    end
end

-- Function: Save & Load
local function saveWaypointsToFile()
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

-- Tabs UI
local Tabs = {
    Main = Window:AddTab({ Title = "Main Teleport", Icon = "map-pin" }),
    Custom = Window:AddTab({ Title = "Custom Waypoint", Icon = "bookmark" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- Dropdown Reference
local WaypointDropdown = Tabs.Custom:AddDropdown("WpDropdown", {
    Title = "Pilih Waypoint dari List",
    Values = {},
    Multi = false,
    Default = "",
    Callback = function(Value)
        selectedWaypointName = Value
    end
})

local function refreshDropdown()
    local names = {}
    for _, wp in ipairs(customWaypoints) do
        table.insert(names, wp.Name)
    end
    WaypointDropdown:SetValues(names)
end

local function loadWaypointsFromFile()
    if readfile and isfile and isfile(fileName) then
        pcall(function()
            local rawData = readfile(fileName)
            local decoded = HttpService:JSONDecode(rawData)
            customWaypoints = {}
            for _, item in ipairs(decoded) do
                table.insert(customWaypoints, {
                    Name = item.Name,
                    CF = CFrame.new(item.Pos[1], item.Pos[2], item.Pos[3])
                })
            end
            refreshDropdown()
        end)
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
Tabs.Main:AddButton({
    Title = "Scan Checkpoints Map",
    Callback = function()
        scanCheckpoints()
        Fluent:Notify({ Title = "Scan Selesai", Content = "Ditemukan " .. #checkpoints .. " Checkpoint.", Duration = 3 })
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
    Title = "Teleport Manual ke CP Nomor",
    Default = "",
    Placeholder = "Contoh: 1, 2, 3...",
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
Tabs.Custom:AddButton({
    Title = "Tambah Waypoint di Posisi Saat Ini",
    Callback = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local currentCF = LocalPlayer.Character.HumanoidRootPart.CFrame
            local wpName = "Waypoint " .. (#customWaypoints + 1)
            table.insert(customWaypoints, {Name = wpName, CF = currentCF})
            saveWaypointsToFile()
            refreshDropdown()
            Fluent:Notify({ Title = "Berhasil", Content = wpName .. " tersimpan!", Duration = 3 })
        end
    end
})

Tabs.Custom:AddButton({
    Title = "Teleport ke Waypoint Terpilih",
    Callback = function()
        if selectedWaypointName == "" then return end
        for _, wp in ipairs(customWaypoints) do
            if wp.Name == selectedWaypointName then
                teleportTo(wp.CF)
                break
            end
        end
    end
})

Tabs.Custom:AddToggle("AutoCustomToggle", {
    Title = "Auto Teleport Custom (Looping)",
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

Tabs.Custom:AddButton({
    Title = "Hapus Semua Waypoint & Saved File",
    Callback = function()
        customWaypoints = {}
        if delfile and isfile and isfile(fileName) then
            delfile(fileName)
        end
        refreshDropdown()
        Fluent:Notify({ Title = "Reset", Content = "Semua waypoint telah dihapus.", Duration = 3 })
    end
})

-- ================= TAB 3: SETTINGS =================
Tabs.Settings:AddSlider("DelaySlider", {
    Title = "Jeda Teleport (Detik)",
    Default = 2,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Callback = function(Value)
        loopDelay = Value
    end
})

Tabs.Settings:AddButton({
    Title = "Close Script & Normalkan",
    Callback = function()
        autoCPActive = false
        autoCustomActive = false
        checkpoints = {}
        customWaypoints = {}
        
        local sg = LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("DraggableToggle_Gunung")
        if sg then sg:Destroy() end
        
        Fluent:Destroy()
    end
})

-- ================= DRAGGABLE TOGGLE BUTTON =================
local function createDraggableButton()
    local pGui = LocalPlayer:WaitForChild("PlayerGui")
    if pGui:FindFirstChild("DraggableToggle_Gunung") then
        pGui.DraggableToggle_Gunung:Destroy()
    end

    local sg = Instance.new("ScreenGui")
    sg.Name = "DraggableToggle_Gunung"
    sg.Parent = pGui

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 50)
    btn.Position = UDim2.new(0.1, 0, 0.2, 0)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.Text = "MENU"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 13
    btn.Active = true
    btn.Draggable = true -- BISA DIGESER DI HP
    btn.Parent = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 25)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        local mainGui = pGui:FindFirstChild("FluentUI")
        if mainGui then
            mainGui.Enabled = not mainGui.Enabled
        end
    end)
end

-- Init
loadWaypointsFromFile()
createDraggableButton()
