-- Load Library Orion UI
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

local Window = OrionLib:MakeWindow({
   Name = "Gunung Explorer Script + Save Config", 
   HidePremium = true, 
   SaveConfig = false, 
   IntroText = "Gunung Explorer"
})

-- Service & Player References
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- Nama file penyimpanan lokal berdasarkan ID Map (PlaceId)
local fileName = "Gunung_Waypoints_" .. tostring(game.PlaceId) .. ".json"

-- Variables State
local checkpoints = {}
local customWaypoints = {} -- Format: {{Name = "Waypoint 1", CF = CFrame}}
local autoCPActive = false
local autoCustomActive = false
local loopDelay = 2
local selectedWaypointName = ""

-- Function: Teleport ke Posisi CFrame
local function teleportTo(cframe)
   if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
      LocalPlayer.Character.HumanoidRootPart.CFrame = cframe + Vector3.new(0, 3, 0)
   end
end

-- Helper: Update Opsi Dropdown List Waypoint
local WaypointDropdown

local function updateDropdownOptions()
   local names = {}
   for _, wp in ipairs(customWaypoints) do
      table.insert(names, wp.Name)
   end
   if WaypointDropdown then
      WaypointDropdown:Refresh(names, true)
   end
end

-- Function: Simpan Custom Waypoint ke File Lokal HP
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

-- Function: Memuat Custom Waypoint dari File Lokal HP
local function loadWaypointsFromFile()
   if readfile and isfile and isfile(fileName) then
      pcall(function()
         local rawData = readfile(fileName)
         local decoded = HttpService:JSONEncode(rawData) -- Safety parse
         decoded = HttpService:JSONDecode(rawData)
         customWaypoints = {}
         for _, item in ipairs(decoded) do
            table.insert(customWaypoints, {
               Name = item.Name,
               CF = CFrame.new(item.Pos[1], item.Pos[2], item.Pos[3])
            })
         end
         updateDropdownOptions()
      end)
   end
end

-- Function: Pindai & Dapatkan Checkpoint di Map
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

-- ================= TAB MENU =================
local MainTab = OrionLib:MakeTab({Name = "Main Teleport", Icon = "rbxassetid://4483362458", PremiumOnly = false})
local CustomTab = OrionLib:MakeTab({Name = "Custom Waypoint", Icon = "rbxassetid://4483362458", PremiumOnly = false})
local SettingsTab = OrionLib:MakeTab({Name = "Settings", Icon = "rbxassetid://4483362458", PremiumOnly = false})

-- ---------------- TAB 1: CHECKPOINT MAP ----------------
MainTab:AddSection({Name = "Detection & Auto Teleport"})

MainTab:AddButton({
   Name = "Scan / Load Checkpoints Map",
   Callback = function()
      scanCheckpoints()
      OrionLib:MakeNotification({
         Name = "Scan Selesai",
         Content = "Ditemukan " .. #checkpoints .. " Checkpoint di map.",
         Time = 3
      })
   end
})

MainTab:AddToggle({
   Name = "Auto Teleport CP Berurutan (Looping)",
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

MainTab:AddSection({Name = "Teleport Manual CP"})

MainTab:AddTextbox({
   Name = "Teleport ke CP Nomor (Misal: 1, 2, 3)",
   Default = "",
   TextDisappear = false,
   Callback = function(Text)
      local cpIndex = tonumber(Text)
      if cpIndex and checkpoints[cpIndex] then
         local cp = checkpoints[cpIndex]
         local targetCF = cp:IsA("Model") and cp:GetPivot() or cp.CFrame
         teleportTo(targetCF)
      end
   end
})

-- ---------------- TAB 2: CUSTOM WAYPOINT ----------------
CustomTab:AddSection({Name = "Tambah Waypoint Manual"})

CustomTab:AddButton({
   Name = "Tambah Waypoint di Posisi Saat Ini",
   Callback = function()
      if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
         local currentCF = LocalPlayer.Character.HumanoidRootPart.CFrame
         local count = #customWaypoints + 1
         local wpName = "Waypoint " .. count
         
         table.insert(customWaypoints, {Name = wpName, CF = currentCF})
         saveWaypointsToFile()
         updateDropdownOptions()
         
         OrionLib:MakeNotification({
            Name = "Waypoint Ditambahkan",
            Content = wpName .. " berhasil disimpan!",
            Time = 3
         })
      end
   end
})

CustomTab:AddSection({Name = "Daftar Waypoint Tersimpan"})

-- Dropdown Daftar List Waypoint
WaypointDropdown = CustomTab:AddDropdown({
   Name = "Pilih Waypoint dari List:",
   Default = "",
   Options = {},
   Callback = function(Value)
      selectedWaypointName = Value
   end
})

-- Tombol Teleport ke Waypoint Pilihan dari List
CustomTab:AddButton({
   Name = "Teleport ke Waypoint Terpilih",
   Callback = function()
      if selectedWaypointName == "" then
         OrionLib:MakeNotification({
            Name = "Peringatan",
            Content = "Pilih waypoint dari list terlebih dahulu!",
            Time = 3
         })
         return
      end
      
      for _, wp in ipairs(customWaypoints) do
         if wp.Name == selectedWaypointName then
            teleportTo(wp.CF)
            break
         end
      end
   end
})

CustomTab:AddSection({Name = "Auto Teleport Custom"})

CustomTab:AddToggle({
   Name = "Auto Teleport Custom Waypoint (Looping)",
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

CustomTab:AddButton({
   Name = "Hapus Semua Custom Waypoint & File Saved",
   Callback = function()
      customWaypoints = {}
      if delfile and isfile and isfile(fileName) then
         delfile(fileName)
      end
      updateDropdownOptions()
      OrionLib:MakeNotification({
         Name = "Reset",
         Content = "Semua custom waypoint telah dihapus.",
         Time = 3
      })
   end
})

-- ---------------- TAB 3: SETTINGS & CLEANUP ----------------
SettingsTab:AddSlider({
   Name = "Jeda Teleport / Delay (Detik)",
   Min = 1,
   Max = 10,
   Default = 2,
   Color = Color3.fromRGB(255,255,255),
   Increment = 1,
   ValueName = "Detik",
   Callback = function(Value)
      loopDelay = Value
   end
})

SettingsTab:AddSection({Name = "Close & Normalize"})

SettingsTab:AddButton({
   Name = "Close Script & Normalkan Semua Status",
   Callback = function()
      autoCPActive = false
      autoCustomActive = false
      checkpoints = {}
      customWaypoints = {}
      
      -- Menghapus tombol floating & mematikan UI
      local screenGui = LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("ToggleGui_Gunung")
      if screenGui then screenGui:Destroy() end
      
      OrionLib:Destroy()
   end
})

-- ================= TOMBOL FLOATING / TOGGLE BISA DIGESER (DRAGGABLE) =================
local function createDraggableToggleButton()
   local playerGui = LocalPlayer:WaitForChild("PlayerGui")
   
   -- Hapus jika sudah ada sebelumnya
   if playerGui:FindFirstChild("ToggleGui_Gunung") then
      playerGui.ToggleGui_Gunung:Destroy()
   end

   local ScreenGui = Instance.new("ScreenGui")
   ScreenGui.Name = "ToggleGui_Gunung"
   ScreenGui.Parent = playerGui
   ScreenGui.ResetOnSpawn = false

   local Frame = Instance.new("Frame")
   Frame.Size = UDim2.new(0, 60, 0, 60)
   Frame.Position = UDim2.new(0.1, 0, 0.2, 0)
   Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
   Frame.BorderSizePixel = 0
   Frame.Active = true
   Frame.Draggable = true -- MEMBUAT TOMBOL BISA DIGESER BEBAS
   Frame.Parent = ScreenGui

   local UICorner = Instance.new("UICorner")
   UICorner.CornerRadius = UDim.new(0, 30)
   UICorner.Parent = Frame

   local TextButton = Instance.new("TextButton")
   TextButton.Size = UDim2.new(1, 0, 1, 0)
   TextButton.BackgroundTransparency = 1
   TextButton.Text = "MENU"
   TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
   TextButton.TextSize = 14
   TextButton.Font = Enum.Font.SourceSansBold
   TextButton.Parent = Frame

   -- Event Buka/Tutup UI saat tombol melayang diklik
   local isMenuVisible = true
   TextButton.MouseButton1Click:Connect(function()
      isMenuVisible = not isMenuVisible
      local mainUI = playerGui:FindFirstChild("Orion")
      if mainUI then
         mainUI.Enabled = isMenuVisible
      end
   end)
end

-- ================= INITIALIZATION =================
loadWaypointsFromFile()
createDraggableToggleButton()
