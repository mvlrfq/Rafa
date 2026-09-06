-- Load Library Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local HttpService = game:GetService("HttpService")

local Window = Rayfield:CreateWindow({
   Name = "Gunung Explorer Script + Save Config",
   LoadingTitle = "Loading Script...",
   LoadingSubtitle = "by Assistant",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

-- Service & Player References
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Nama file penyimpanan lokal (berdasarkan PlaceId agar tidak bentrok antar map)
local fileName = "Gunung_Waypoints_" .. tostring(game.PlaceId) .. ".json"

-- Variables State
local checkpoints = {}
local customWaypoints = {} -- Menyimpan Vector3/CFrame dalam format angka
local autoCPActive = false
local autoCustomActive = false
local loopDelay = 2

-- Function: Teleport ke Posisi CFrame
local function teleportTo(cframe)
   if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
      LocalPlayer.Character.HumanoidRootPart.CFrame = cframe + Vector3.new(0, 3, 0)
   end
end

-- Function: Simpan Custom Waypoint ke File Lokal HP
local function saveWaypointsToFile()
   local dataToSave = {}
   for _, cf in ipairs(customWaypoints) do
      local pos = cf.Position
      table.insert(dataToSave, {pos.X, pos.Y, pos.Z})
   end
   
   local success, err = pcall(function()
      writefile(fileName, HttpService:JSONEncode(dataToSave))
   end)
   
   if success then
      Rayfield:Notify({
         Title = "Config Tersimpan!",
         Content = "Berhasil menyimpan " .. #customWaypoints .. " waypoint ke penyimpanan lokal.",
         Duration = 3
      })
   else
      Rayfield:Notify({
         Title = "Gagal Menyimpan",
         Content = "Executor kamu mungkin tidak mendukung writefile.",
         Duration = 3
      })
   end
end

-- Function: Memuat Custom Waypoint dari File Lokal HP
local function loadWaypointsFromFile()
   if readfile and isfile and isfile(fileName) then
      local success, result = pcall(function()
         local rawData = readfile(fileName)
         local decoded = HttpService:JSONDecode(rawData)
         customWaypoints = {}
         for _, pos in ipairs(decoded) do
            table.insert(customWaypoints, CFrame.new(pos[1], pos[2], pos[3]))
         end
      end)
      
      if success then
         Rayfield:Notify({
            Title = "Config Dimuat!",
            Content = "Otomatis memuat " .. #customWaypoints .. " waypoint tersimpan.",
            Duration = 4
         })
      end
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
local MainTab = Window:CreateTab("Main Teleport", 4483362458)
local CustomTab = Window:CreateTab("Custom Waypoint", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

-- ---------------- TAB 1: CHECKPOINT MAP ----------------
MainTab:CreateSection("Detection & Auto Teleport")

MainTab:CreateButton({
   Name = "Scan / Load Checkpoints Map",
   Callback = function()
      scanCheckpoints()
      Rayfield:Notify({
         Title = "Scan Selesai",
         Content = "Ditemukan " .. #checkpoints .. " Checkpoint di map.",
         Duration = 4
      })
   end,
})

MainTab:CreateToggle({
   Name = "Auto Teleport CP Berurutan (Looping)",
   CurrentValue = false,
   Flag = "AutoCP",
   Callback = function(Value)
      autoCPActive = Value
      task.spawn(function()
         while autoCPActive do
            if #checkpoints == 0 then scanCheckpoints() end
            
            for i, cp in ipairs(checkpoints) do
               if not autoCPActive then break end
               local targetCF = cp:IsA("Model") and cp:GetPivot() or cp.CFrame
               teleportTo(targetCF)
               task.wait(loopDelay)
            end
            task.wait(0.5)
         end
      end)
   end,
})

MainTab:CreateSection("Teleport Manual CP")

MainTab:CreateInput({
   Name = "Teleport ke CP Nomor (Misal: 1, 2, 3)",
   PlaceholderText = "Masukkan nomor CP...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      local cpIndex = tonumber(Text)
      if cpIndex and checkpoints[cpIndex] then
         local cp = checkpoints[cpIndex]
         local targetCF = cp:IsA("Model") and cp:GetPivot() or cp.CFrame
         teleportTo(targetCF)
      else
         Rayfield:Notify({
            Title = "Gagal Teleport",
            Content = "CP Nomor " .. tostring(Text) .. " tidak ditemukan.",
            Duration = 3
         })
      end
   end,
})

-- ---------------- TAB 2: CUSTOM WAYPOINT ----------------
CustomTab:CreateSection("Tambah & Kelola Waypoint Manual")

CustomTab:CreateButton({
   Name = "Tambah Waypoint di Posisi Saat Ini",
   Callback = function()
      if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
         local currentCF = LocalPlayer.Character.HumanoidRootPart.CFrame
         table.insert(customWaypoints, currentCF)
         
         -- Otomatis simpan setiap kali menambah waypoint baru
         saveWaypointsToFile()
      end
   end,
})

CustomTab:CreateButton({
   Name = "Simpan Waypoint ke File Lokal HP (Manual Save)",
   Callback = function()
      saveWaypointsToFile()
   end,
})

CustomTab:CreateButton({
   Name = "Muat Ulang Waypoint dari File (Manual Load)",
   Callback = function()
      loadWaypointsFromFile()
   end,
})

CustomTab:CreateButton({
   Name = "Hapus Semua Custom Waypoint & File Saved",
   Callback = function()
      customWaypoints = {}
      if delfile and isfile and isfile(fileName) then
         delfile(fileName)
      end
      Rayfield:Notify({
         Title = "Reset",
         Content = "Semua custom waypoint & file simpanan telah dihapus.",
         Duration = 3
      })
   end,
})

CustomTab:CreateSection("Auto Teleport Custom")

CustomTab:CreateToggle({
   Name = "Auto Teleport Custom Waypoint (Looping)",
   CurrentValue = false,
   Flag = "AutoCustom",
   Callback = function(Value)
      autoCustomActive = Value
      task.spawn(function()
         while autoCustomActive do
            if #customWaypoints == 0 then
               Rayfield:Notify({
                  Title = "Peringatan",
                  Content = "Tidak ada waypoint! Silakan tambah atau muat file simpanan.",
                  Duration = 3
               })
               break
            end
            
            for i, cf in ipairs(customWaypoints) do
               if not autoCustomActive then break end
               teleportTo(cf)
               task.wait(loopDelay)
            end
            task.wait(0.5)
         end
      end)
   end,
})

-- ---------------- TAB 3: SETTINGS & CLEANUP ----------------
SettingsTab:CreateSlider({
   Name = "Jeda Teleport / Delay (Detik)",
   Range = {1, 10},
   Increment = 1,
   Suffix = "Detik",
   CurrentValue = 2,
   Flag = "DelaySlider",
   Callback = function(Value)
      loopDelay = Value
   end,
})

SettingsTab:CreateSection("Close & Normalize")

SettingsTab:CreateButton({
   Name = "Close Script & Normalkan Semua Status",
   Callback = function()
      autoCPActive = false
      autoCustomActive = false
      checkpoints = {}
      customWaypoints = {}
      
      Rayfield:Destroy()
   end,
})

-- ================= AUTO RUN ON START =================
-- Otomatis muat file waypoint saat skrip pertama kali dijalankan di map ini
loadWaypointsFromFile()
