--[[ 
    Violence District: Anti-Fail Generator Script
    Dibuat untuk: Delta Executor
    Fitur Utama: Anti-Gagal Repair (Generator tidak meledak jika skill check meleset)
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Violence District - Generator Fix", 0x2F8F17, "Arial")

-- Variabel Utama
local AntiFailEnabled = false
local AutoRepairSpeed = 16

-- Tab Utama
local MainTab = Window:NewTab("Generator Settings")
local Section = MainTab:NewSection("Repair Logic")

-- Toggle Anti-Gagal
Section:NewToggle("Anti-Fail Generator", "Mencegah generator meledak saat skill check meleset", function(state)
    AntiFailEnabled = state
end)

-- Slider Kecepatan (Opsional jika ingin lebih cepat jalan ke generator)
Section:NewSlider("WalkSpeed", "Kecepatan jalan menuju generator", 16, 250, function(s)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = s
end)

-- LOGIKA ANTI-GAGAL (The Core Engine)
spawn(function() 
    while wait(0.1) do 
        -- Jika Anti-Fail aktif DAN pemain gagal melakukan skill check (meleset)
        -- Script akan memaksa status 'Success' kembali setelah jeda singkat jika ledakan terjadi
        if AntiFailEnabled then 
            local gen = game.Workspace.Generators:GetChildren() -- Mengambil semua generator di map
            for _, v in pairs(gen) do 
                if v:FindFirstChild("Failed") and v.Failed.Value == true then 
                    v.Failed.Value = false -- Mengubah status Gagal menjadi Berhasil secara instan
                end 
            end 
        end 
    end 
end)

print("Violence District Script Loaded Successfully!")
