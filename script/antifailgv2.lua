--[[ 
    Violence District: Anti-Fail Generator v2
    Optimized for Delta Executor
]]

-- 1. Memuat Library Visual (UI)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Violence District - Fix", 0x2F8F17, "Arial")

-- Variabel kontrol agar tidak berat
getgenv().AntiFail = false 

local MainTab = Window:NewTab("Generator")
local Section = MainTab:NewSection("Main Settings")

-- Tombol On/Off Anti-Gagal
Section:NewToggle("Anti-Fail Generator", "Mencegah ledakan saat skill check meleset", function(state)
    getgenv().AntiFail = state
end)

-- Pengatur Kecepatan Jalan
Section:NewSlider("WalkSpeed", "Cepat sampai ke generator", 16, 250, function(s)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = s
end)

-- LOGIKA UTAMA (Berjalan di background)
task.spawn(function() 
    while true do 
        task.wait(0.1) -- Cek setiap 0,1 detik agar tidak lag
        if getgenv().AntiFail == true then 
            for _, v in pairs(game.Workspace.Generators:GetChildren()) do 
                -- Jika generator berstatus 'Failed', ubah jadi 'False' (Berhasil) secara instan
                if v:FindFirstChild("Failed") and v.Failed.Value == true then 
                    v.Failed.Value = false 
                end 
            end 
        end 
    end 
end)

print("Script Violence District Berhasil Dieksekusi!")
