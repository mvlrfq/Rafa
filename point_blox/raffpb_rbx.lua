--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
-- ==========================================
-- 🎯 LITE HACK + ULTIMATE MODS (ANTI-GM/MOD + RPM + NO RELOAD)
-- (UPDATED: DEEP MEMORY SCAN GUN MODS + CONFIG SAVE)
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local ScriptContext = game:GetService("ScriptContext")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- AUTO BYPASS ANTI-CHEAT
-- ==========================================
task.spawn(function()
    pcall(function()
        if setreadonly then
            pcall(function() setreadonly(getrenv(), false); setreadonly(getreg(), false); setreadonly(getgc(), false) end)
        end
        if make_writeable then pcall(function() make_writeable(getreg()) end) end
        if detour_function then detour_function = function(...) return true end end
        if getconnections then
            pcall(function() for _, connection in ipairs(getconnections(ScriptContext.Error)) do connection:Disable() end end)
        end
        if getcallingscript then pcall(function() getcallingscript = function() return nil end end) end
        for _, tableName in ipairs({"_G", "shared"}) do
            pcall(function()
                local target = getgenv()[tableName]
                if target and type(target) == "table" then
                    for key, _ in pairs(target) do
                        local strKey = tostring(key):lower()
                        if strKey:find("signature") or strKey:find("checksum") or strKey:find("hash") then target[key] = nil end
                    end
                end
            end)
        end
        for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                local name = remote.Name:lower()
                if name:find("handshake") or name:find("validate") or name:find("verify") or name:find("integrity") or name:find("anti") then
                    pcall(function()
                        if remote:IsA("RemoteEvent") then remote.FireServer = function(...) return true end
                        elseif remote:IsA("RemoteFunction") then remote.InvokeServer = function(...) return true end end
                    end)
                end
            end
        end
    end)
end)

local Camera = workspace.CurrentCamera
if Camera.ViewportSize.Y > Camera.ViewportSize.X then
    repeat task.wait(0.5) until Camera.ViewportSize.X > Camera.ViewportSize.Y
    task.wait(1)
end

-- ==========================================
-- LOAD UI RAYFIELD
-- ==========================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "Rafiqi blox",
   LoadingTitle = "Memuat Cheat...",
   LoadingSubtitle = "Deep Memory Gun Mods Aktif!",
   ConfigurationSaving = { Enabled = false },
   Keybind = Enum.KeyCode.LeftControl, 
   KeySystem = false
})

Rayfield:Notify({
    Title = "🛡️ Update Aktif",
    Content = "Gun Mods sekarang menggunakan Deep Memory Scan.",
    Duration = 4,
    Image = 4483362458
})

-- ==========================================
-- VARIABEL SISTEM
-- ==========================================
local MainTab   = Window:CreateTab("🚀 Main Features", 4483362458)
local PlayerTab = Window:CreateTab("🏃 Player Hacks", 4483362458)
local GunTab    = Window:CreateTab("🔫 Gun Mods", 4483362458)
local ConfigTab = Window:CreateTab("💾 Config & Save", 4483362458)

local AimbotAktif = false
local AimbotMode = "POV Kamera (FOV)" 
local AimTargetMode = "Head" 
local AimbotSmoothness = 15

local ESPAktif = false
local FFAModeAktif = false
local SpeedAktif, JumpAktif = false, false
local AntiFallDamageAktif = false
local CustomSpeed, CustomJump = 50, 100
local GunModsAktif = false
local CustomFireRate = 800
local AntiAdminAktif = false 

-- Variabel FOV UI
local ShowFOV = false
local FOVRadius = 150
local FOVGui, FOVFrame

pcall(function()
    local TargetParent = (gethui and gethui()) or game:GetService("CoreGui")
    FOVGui = Instance.new("ScreenGui")
    FOVGui.Name = "Universal_FOV_System"
    FOVGui.Parent = TargetParent
    FOVGui.IgnoreGuiInset = true
    
    FOVFrame = Instance.new("Frame")
    FOVFrame.Parent = FOVGui
    FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    FOVFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    FOVFrame.Size = UDim2.new(0, FOVRadius * 2, 0, FOVRadius * 2)
    FOVFrame.BackgroundTransparency = 1
    FOVFrame.Visible = false
    
    local FOVStroke = Instance.new("UIStroke")
    FOVStroke.Parent = FOVFrame
    FOVStroke.Color = Color3.fromRGB(255, 255, 255)
    FOVStroke.Thickness = 1.5
    FOVStroke.Transparency = 0.5
    
    local FOVCorner = Instance.new("UICorner")
    FOVCorner.Parent = FOVFrame
    FOVCorner.CornerRadius = UDim.new(1, 0)
end)

-- ==========================================
-- 🛡️ LOGIKA ANTI-GM/MOD
-- ==========================================
local function CheckIfAdmin(p)
    if p == LocalPlayer then return false end
    local nameRaw = string.upper(p.Name .. " " .. p.DisplayName)
    if string.find(nameRaw, "%[GM%]") or string.find(nameRaw, "%[MOD%]") or string.find(nameRaw, "GAME MASTER") or string.find(nameRaw, "MODERATOR") or string.find(nameRaw, "DEWAKASAPUTRA") or string.find(nameRaw, "DEWA PROJECT") then return true end
    local ls = p:FindFirstChild("leaderstats")
    if ls then
        for _, stat in pairs(ls:GetChildren()) do
            local statValue = string.upper(tostring(stat.Value))
            if statValue == "GM" or statValue == "MOD" or statValue == "GAME MASTER" or statValue == "MODERATOR" then return true end
        end
    end
    return false
end

local function SendAdminWarning(p)
    Rayfield:Notify({
        Title = "⚠️ GM TERDETEKSI!",
        Content = "Admin/Moderator ["..p.Name.."] ada di room ini! Hati-hati.",
        Duration = 8,
        Image = 4483362458
    })
end

Players.PlayerAdded:Connect(function(p)
    if AntiAdminAktif then task.wait(1); if CheckIfAdmin(p) then SendAdminWarning(p) end end
end)

task.spawn(function()
    while task.wait(5) do
        if AntiAdminAktif then
            for _, p in pairs(Players:GetPlayers()) do if CheckIfAdmin(p) then SendAdminWarning(p) end end
        end
    end
end)

-- ==========================================
-- WADAH ELEMEN UI
-- ==========================================
local Toggles = {}
local Sliders = {}
local Dropdowns = {}

-- ==========================================
-- 1. MENU MAIN FEATURES
-- ==========================================
Toggles.AntiAdmin = MainTab:CreateToggle({ Name = "🚨 Peringatan Admin (Popup Warning)", CurrentValue = false, Flag = "AntiAdminToggle", Callback = function(Value) AntiAdminAktif = Value end })
Toggles.Aimbot = MainTab:CreateToggle({ Name = "🎯 Aktifkan Auto Aim (Kunci Layar)", CurrentValue = false, Flag = "AimbotToggle", Callback = function(Value) AimbotAktif = Value end })
Dropdowns.AimbotMode = MainTab:CreateDropdown({ Name = "⚙️ Mode Aimbot", Options = {"POV Kamera (FOV)", "360° (Brutal)"}, CurrentOption = "POV Kamera (FOV)", MultipleOptions = false, Flag = "AimbotModeList", Callback = function(Option) AimbotMode = Option[1] end })
Dropdowns.AimTarget = MainTab:CreateDropdown({ Name = "🎯 Target Bagian Tubuh", Options = {"Head", "Body"}, CurrentOption = "Head", MultipleOptions = false, Flag = "AimTarget", Callback = function(Option) AimTargetMode = Option[1] end })
Sliders.Smoothness = MainTab:CreateSlider({ Name = "🧲 Kelengketan Aim POV (Smoothness)", Range = {1, 100}, Increment = 1, Suffix = "%", CurrentValue = 15, Flag = "SmoothSlider", Callback = function(Value) AimbotSmoothness = Value end })
Toggles.FOV = MainTab:CreateToggle({ Name = "⭕ Tampilkan Lingkaran FOV", CurrentValue = false, Flag = "FOVTOGGLE", Callback = function(Value) ShowFOV = Value end })
Sliders.FOV = MainTab:CreateSlider({ Name = "📏 Lebar Lingkaran FOV", Range = {10, 600}, Increment = 5, Suffix = " Px", CurrentValue = 150, Flag = "FOVSlider", Callback = function(Value) FOVRadius = Value end })
Toggles.ESP = MainTab:CreateToggle({ Name = "👁️ Enemy ESP (Melihat Musuh)", CurrentValue = false, Flag = "ESPToggle", Callback = function(Value) ESPAktif = Value end })

-- ==========================================
-- 2. MENU PLAYER HACKS
-- ==========================================
Toggles.AntiFall = PlayerTab:CreateToggle({ Name = "🛡️ No Fall Damage", CurrentValue = false, Flag = "AntiFallToggle", Callback = function(Value) AntiFallDamageAktif = Value end })
Toggles.Speed = PlayerTab:CreateToggle({ Name = "⚡ Kecepatan Lari", CurrentValue = false, Flag = "SpeedToggle", Callback = function(Value) SpeedAktif = Value; if not Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = 16 end end })
Sliders.Speed = PlayerTab:CreateSlider({ Name = "⚙️ Set Speed", Range = {16, 250}, Increment = 1, Suffix = " Spd", CurrentValue = 50, Flag = "SpeedSlider", Callback = function(Value) CustomSpeed = Value end })
Toggles.Jump = PlayerTab:CreateToggle({ Name = "🚀 Lompat Tinggi", CurrentValue = false, Flag = "JumpToggle", Callback = function(Value) JumpAktif = Value; if not Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.UseJumpPower = true; LocalPlayer.Character.Humanoid.JumpPower = 50 end end })
Sliders.Jump = PlayerTab:CreateSlider({ Name = "⚙️ Set Power", Range = {50, 250}, Increment = 1, Suffix = " Pwr", CurrentValue = 100, Flag = "JumpSlider", Callback = function(Value) CustomJump = Value end })

-- ==========================================
-- 3. MENU GUN MODS
-- ==========================================
Toggles.GunMods = GunTab:CreateToggle({ Name = "🔫 Gun Mods (Infinite Ammo & RPM)", CurrentValue = false, Flag = "GunModsToggle", Callback = function(Value) GunModsAktif = Value end })
Sliders.FireRate = GunTab:CreateSlider({ Name = "⚡ RPM Fire Rate", Range = {400, 2500}, Increment = 50, Suffix = " RPM", CurrentValue = 800, Flag = "FireRateSlider", Callback = function(Value) CustomFireRate = Value end })

-- ==========================================
-- 💾 MENU CONFIG & SAVE SYSTEM
-- ==========================================
local ConfigFileName = "LiteHack_Config.json"

local function SaveSettings()
    local settings = {
        AntiAdmin = AntiAdminAktif, Aimbot = AimbotAktif, AimbotMode = AimbotMode, AimTargetMode = AimTargetMode,
        AimbotSmoothness = AimbotSmoothness, ShowFOV = ShowFOV, FOVRadius = FOVRadius, ESPAktif = ESPAktif,
        AntiFallDamageAktif = AntiFallDamageAktif, SpeedAktif = SpeedAktif, CustomSpeed = CustomSpeed,
        JumpAktif = JumpAktif, CustomJump = CustomJump, GunModsAktif = GunModsAktif, CustomFireRate = CustomFireRate
    }
    if writefile then
        pcall(function()
            local json = HttpService:JSONEncode(settings)
            writefile(ConfigFileName, json)
        end)
        return true
    end
    return false
end

local function LoadSettings()
    if isfile and readfile and isfile(ConfigFileName) then
        local success, json = pcall(function() return readfile(ConfigFileName) end)
        if success and json then
            local settings = HttpService:JSONDecode(json)
            if settings.AntiAdmin ~= nil then Toggles.AntiAdmin:Set(settings.AntiAdmin) end
            if settings.Aimbot ~= nil then Toggles.Aimbot:Set(settings.Aimbot) end
            if settings.AimbotMode ~= nil then Dropdowns.AimbotMode:Set({settings.AimbotMode}) end
            if settings.AimTargetMode ~= nil then Dropdowns.AimTarget:Set({settings.AimTargetMode}) end
            if settings.AimbotSmoothness ~= nil then Sliders.Smoothness:Set(settings.AimbotSmoothness) end
            if settings.ShowFOV ~= nil then Toggles.FOV:Set(settings.ShowFOV) end
            if settings.FOVRadius ~= nil then Sliders.FOV:Set(settings.FOVRadius) end
            if settings.ESPAktif ~= nil then Toggles.ESP:Set(settings.ESPAktif) end
            if settings.AntiFallDamageAktif ~= nil then Toggles.AntiFall:Set(settings.AntiFallDamageAktif) end
            if settings.SpeedAktif ~= nil then Toggles.Speed:Set(settings.SpeedAktif) end
            if settings.CustomSpeed ~= nil then Sliders.Speed:Set(settings.CustomSpeed) end
            if settings.JumpAktif ~= nil then Toggles.Jump:Set(settings.JumpAktif) end
            if settings.CustomJump ~= nil then Sliders.Jump:Set(settings.CustomJump) end
            if settings.GunModsAktif ~= nil then Toggles.GunMods:Set(settings.GunModsAktif) end
            if settings.CustomFireRate ~= nil then Sliders.FireRate:Set(settings.CustomFireRate) end
            return true
        end
    end
    return false
end

ConfigTab:CreateLabel("💡 Simpan settinganmu agar tidak perlu ngatur ulang saat pindah room.")
ConfigTab:CreateButton({ Name = "💾 Save Konfigurasi", Callback = function() if SaveSettings() then Rayfield:Notify({Title = "✅ Tersimpan", Content = "Settingan berhasil disimpan!", Duration = 3}) else Rayfield:Notify({Title = "❌ Gagal", Content = "Eksekutor tidak mendukung Save.", Duration = 3}) end end })
ConfigTab:CreateButton({ Name = "📂 Load Konfigurasi", Callback = function() if LoadSettings() then Rayfield:Notify({Title = "✅ Berhasil", Content = "Settingan dimuat!", Duration = 3}) else Rayfield:Notify({Title = "⚠️ Info", Content = "Belum ada Save.", Duration = 3}) end end })
ConfigTab:CreateButton({
    Name = "🔄 Reset Semua ke Default",
    Callback = function()
        Toggles.AntiAdmin:Set(false); Toggles.Aimbot:Set(false); Dropdowns.AimbotMode:Set({"POV Kamera (FOV)"}); Dropdowns.AimTarget:Set({"Head"})
        Sliders.Smoothness:Set(15); Toggles.FOV:Set(false); Sliders.FOV:Set(150); Toggles.ESP:Set(false)
        Toggles.AntiFall:Set(false); Toggles.Speed:Set(false); Sliders.Speed:Set(50)
        Toggles.Jump:Set(false); Sliders.Jump:Set(100); Toggles.GunMods:Set(false); Sliders.FireRate:Set(800)
        Rayfield:Notify({Title = "🔄 Di-Reset", Content = "Semua fitur dimatikan.", Duration = 3})
    end
})

-- ==========================================
-- CACHE ENTITY & TEAM LOGIC
-- ==========================================
local ValidEntities = {}
task.spawn(function()
    while task.wait(0.5) do
        local currentList = {}
        for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character then table.insert(currentList, p.Character) end end
        for _, obj in pairs(workspace:GetChildren()) do if obj:IsA("Model") and obj ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(obj) and obj:FindFirstChildOfClass("Humanoid") then table.insert(currentList, obj) end end
        ValidEntities = currentList
    end
end)

local function IsEnemy(model)
    if FFAModeAktif then return true end
    local plr = Players:GetPlayerFromCharacter(model)
    if plr and plr.TeamColor == LocalPlayer.TeamColor then return false end
    return true
end

-- ==========================================
-- 👁️ LOGIKA ESP
-- ==========================================
local CoreGui = game:GetService("CoreGui")
local ESP_Folder = CoreGui:FindFirstChild("Universal_ESP_System") or Instance.new("Folder")
ESP_Folder.Name = "Universal_ESP_System"
ESP_Folder.Parent = CoreGui
local Active_ESP = {}

RunService.RenderStepped:Connect(function()
    if not ESPAktif then
        for _, data in pairs(Active_ESP) do data.Highlight.Enabled = false; data.Gui.Enabled = false end
        return
    end
    local EntitiesInFrame = {}
    for _, model in pairs(ValidEntities) do
        local hum = model:FindFirstChildOfClass("Humanoid")
        local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head") or model.PrimaryPart
        if model.Parent and hum and hum.Health > 0 and hrp and IsEnemy(model) then
            EntitiesInFrame[model] = true
            if not Active_ESP[model] then
                local esp_data = {}
                local hl = Instance.new("Highlight", ESP_Folder); hl.Name = "ESP_Highlight"; hl.Adornee = model; hl.FillTransparency = 0.5; hl.OutlineTransparency = 0.1; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                local bgui = Instance.new("BillboardGui", ESP_Folder); bgui.Name = "ESP_Tag"; bgui.Adornee = hrp; bgui.AlwaysOnTop = true; bgui.Size = UDim2.new(0, 200, 0, 50); bgui.ExtentsOffset = Vector3.new(0, 3, 0)
                local txt = Instance.new("TextLabel", bgui); txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1; txt.TextSize = 14; txt.Font = Enum.Font.Code; txt.TextStrokeTransparency = 0; txt.TextColor3 = Color3.fromRGB(255, 255, 255)
                esp_data.Highlight = hl; esp_data.Gui = bgui; esp_data.TextLabel = txt; Active_ESP[model] = esp_data
            end
            local data = Active_ESP[model]
            data.Highlight.Enabled = true; data.Gui.Enabled = true
            local jarak = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and math.floor((LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) or 0
            local isShielded = model:FindFirstChildOfClass("ForceField")
            data.Highlight.FillColor = isShielded and Color3.fromRGB(0, 0, 255) or Color3.fromRGB(255, 0, 0)
            data.TextLabel.Text = (model.Name or "Bot") .. (isShielded and " [KEBAL]" or "") .. " [" .. jarak .. "m]"
        end
    end
    for model, data in pairs(Active_ESP) do
        if not EntitiesInFrame[model] then data.Highlight:Destroy(); data.Gui:Destroy(); Active_ESP[model] = nil end
    end
end)

-- ==========================================
-- 🎯 LOGIKA AIMBOT & TARGETING
-- ==========================================
local LockedTarget = nil

local function IsVisible(targetPart)
    if not targetPart then return false end
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local rayResult = workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 5000, rayParams)
    return rayResult and rayResult.Instance:IsDescendantOf(targetPart.Parent) or false
end

local function GetDynamicTargetPart(char)
    if not char then return nil end
    local head = char:FindFirstChild("Head")
    local body = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
    if AimTargetMode == "Head" then
        if head and IsVisible(head) then return head end
        if body and IsVisible(body) then return body end
        return head or body
    elseif AimTargetMode == "Body" then
        if body and IsVisible(body) then return body end
        if head and IsVisible(head) then return head end 
        return body or head
    end
    return char:FindFirstChild("HumanoidRootPart")
end

local function GetNewTarget3D()
    local closest, shortestDist = nil, math.huge
    for _, item in pairs(ValidEntities) do
        local hum = item:FindFirstChildOfClass("Humanoid")
        if item.Parent and hum and hum.Health > 0 and IsEnemy(item) and not item:FindFirstChildOfClass("ForceField") then
            local targetPart = GetDynamicTargetPart(item)
            if targetPart and IsVisible(targetPart) then
                local dist = (Camera.CFrame.Position - targetPart.Position).Magnitude
                if dist < shortestDist then shortestDist = dist; closest = item end
            end
        end
    end
    return closest
end

local function GetClosestEnemy2D()
    local closest, shortestDist = nil, FOVRadius 
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, item in pairs(ValidEntities) do
        local hum = item:FindFirstChildOfClass("Humanoid")
        if item.Parent and hum and hum.Health > 0 and IsEnemy(item) and not item:FindFirstChildOfClass("ForceField") then
            local targetPart = GetDynamicTargetPart(item)
            if targetPart and IsVisible(targetPart) then
                local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (center - Vector2.new(pos.X, pos.Y)).Magnitude
                    if dist < shortestDist then shortestDist = dist; closest = item end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if FOVFrame then
        FOVFrame.Size = UDim2.new(0, FOVRadius * 2, 0, FOVRadius * 2)
        FOVFrame.Visible = ShowFOV and (AimbotAktif and AimbotMode == "POV Kamera (FOV)")
    end

    if AimbotAktif then
        local targetValid = false
        local partToAim = nil

        if LockedTarget and LockedTarget.Parent then
            local hum = LockedTarget:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and IsEnemy(LockedTarget) and not LockedTarget:FindFirstChildOfClass("ForceField") then
                partToAim = GetDynamicTargetPart(LockedTarget)
                if partToAim and IsVisible(partToAim) then
                    if AimbotMode == "POV Kamera (FOV)" then
                        local pos, onScreen = Camera:WorldToViewportPoint(partToAim.Position)
                        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                        local dist = (center - Vector2.new(pos.X, pos.Y)).Magnitude
                        if onScreen and dist <= FOVRadius then targetValid = true end
                    else targetValid = true end
                end
            end
        end
        
        if not targetValid then
            if AimbotMode == "360° (Brutal)" then LockedTarget = GetNewTarget3D()
            elseif AimbotMode == "POV Kamera (FOV)" then LockedTarget = GetClosestEnemy2D() end
            if LockedTarget then partToAim = GetDynamicTargetPart(LockedTarget) end
        end
        
        if LockedTarget and partToAim then
            if AimbotMode == "360° (Brutal)" then Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, partToAim.Position)
            else local smoothFactor = AimbotSmoothness / 100; Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, partToAim.Position), smoothFactor) end
        end
    else
        LockedTarget = nil
    end
end)

-- ==========================================
-- LOGIKA FISIKA
-- ==========================================
pcall(function() local mt = getrawmetatable(game); if mt and mt.__index then local oldIndex = mt.__index; setreadonly(mt, false); mt.__index = newcclosure(function(t, k) if not checkcaller() and t:IsA("BasePart") and tostring(k) == "CanCollide" then return true end; return oldIndex(t, k) end); setreadonly(mt, true) end end)

RunService.Stepped:Connect(function()
    if LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if hrp and AntiFallDamageAktif and hrp.Velocity.Y < -40 then local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -20, 0), RaycastParams.new()); if hit then hrp.Velocity = Vector3.new(hrp.Velocity.X, -10, hrp.Velocity.Z) end end
        if hum then if SpeedAktif then hum.WalkSpeed = CustomSpeed end; if JumpAktif then hum.UseJumpPower = true; hum.JumpPower = CustomJump end end
    end
end)

-- ==========================================
-- 🔫 DEEP MEMORY SCAN GUN MODS
-- ==========================================

-- 1. Scan Values & Attributes (Fallback)
local function ScanValueMods(tool)
    pcall(function()
        -- Atribut
        local function SetSafe(attr, value) if tool:GetAttribute(attr) ~= nil and tool:GetAttribute(attr) ~= value then tool:SetAttribute(attr, value) end end
        SetSafe("TotalAmmo", 999999); SetSafe("NewMax", 999999); SetSafe("magazineSize", 999999); SetSafe("_ammo", 999999)
        SetSafe("spread", 0); SetSafe("recoilMax", 0); SetSafe("recoilMin", 0); SetSafe("reloadTime", 0.05); SetSafe("rateOfFire", CustomFireRate)
        
        -- ValueBases (IntValue/NumberValue)
        for _, obj in pairs(tool:GetDescendants()) do
            if obj:IsA("IntValue") or obj:IsA("NumberValue") then
                local name = obj.Name:lower()
                if name:find("ammo") or name:find("clip") or name:find("mag") then obj.Value = 999999
                elseif name:find("firerate") or name:find("rpm") or name:find("rate") then
                    if name:find("rpm") then obj.Value = CustomFireRate else obj.Value = 60 / CustomFireRate end
                end
            end
        end
    end)
end

RunService.RenderStepped:Connect(function()
    if GunModsAktif then
        if LocalPlayer.Character then for _, t in pairs(LocalPlayer.Character:GetChildren()) do if t:IsA("Tool") or t:IsA("Model") then ScanValueMods(t) end end end
        for _, v in pairs(Camera:GetChildren()) do if v:IsA("Model") then ScanValueMods(v) end end
    end
end)

-- 2. DEEP MEMORY GC SCANNER (Untuk Game Modern / ModuleScripts)
task.spawn(function()
    while task.wait(1) do
        if GunModsAktif then
            pcall(function()
                for _, v in pairs(getgc(true)) do
                    if type(v) == "table" then
                        -- Cek apakah tabel ini adalah tabel config senjata
                        if rawget(v, "Ammo") or rawget(v, "MaxAmmo") or rawget(v, "ClipSize") or rawget(v, "RPM") or rawget(v, "FireRate") or rawget(v, "rateOfFire") then
                            
                            -- Hajar Peluru
                            if rawget(v, "Ammo") and type(v.Ammo) == "number" then v.Ammo = 999999 end
                            if rawget(v, "CurrentAmmo") and type(v.CurrentAmmo) == "number" then v.CurrentAmmo = 999999 end
                            if rawget(v, "MaxAmmo") and type(v.MaxAmmo) == "number" then v.MaxAmmo = 999999 end
                            if rawget(v, "StoredAmmo") and type(v.StoredAmmo) == "number" then v.StoredAmmo = 999999 end
                            if rawget(v, "ClipSize") and type(v.ClipSize) == "number" then v.ClipSize = 999999 end
                            if rawget(v, "Magazine") and type(v.Magazine) == "number" then v.Magazine = 999999 end
                            
                            -- Hajar Fire Rate / RPM
                            if rawget(v, "RPM") and type(v.RPM) == "number" then v.RPM = CustomFireRate end
                            if rawget(v, "FireRate") and type(v.FireRate) == "number" then v.FireRate = 60 / CustomFireRate end
                            if rawget(v, "rateOfFire") and type(v.rateOfFire) == "number" then v.rateOfFire = CustomFireRate end
                            
                            -- Hajar Recoil
                            if rawget(v, "Spread") then v.Spread = 0 end
                            if rawget(v, "MaxSpread") then v.MaxSpread = 0 end
                            if rawget(v, "Recoil") then v.Recoil = 0 end
                            if rawget(v, "Kickback") then v.Kickback = 0 end
                        end
                    end
                end
            end)
        end
    end
end)
