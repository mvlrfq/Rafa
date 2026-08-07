if getgenv().Invisible_MainLoaded then return end
getgenv().Invisible_MainLoaded = true

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

task.spawn(function()
    local gui = player:WaitForChild("PlayerGui")

    -- 1. Penentuan Parent Aman (CoreGui / gethui agar Anti-Respawn Delete)
    local targetParent = gui
    pcall(function()
        if gethui then
            targetParent = gethui()
        elseif game:GetService("CoreGui") then
            targetParent = game:GetService("CoreGui")
        end
    end)

    -- Bersihkan UI lama jika ada
    if targetParent:FindFirstChild("InvisibleFloatingUI") then 
        targetParent:FindFirstChild("InvisibleFloatingUI"):Destroy() 
    end

    local hiddenPastebinButton = nil
    local isInvisibleActive = false

    -- Fungsi pencari tombol Pastebin
    local function findAndHidePastebinUI()
        local containers = {gui}
        pcall(function()
            if gethui then table.insert(containers, gethui()) end
            if game:GetService("CoreGui") then table.insert(containers, game:GetService("CoreGui")) end
        end)

        for _, container in ipairs(containers) do
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("ScreenGui") and child.Name ~= "InvisibleFloatingUI" then
                    for _, desc in ipairs(child:GetDescendants()) do
                        if desc:IsA("TextButton") and (desc.Text == "Invisible" or desc.Name == "Invisible") then
                            child.Enabled = false
                            return desc
                        end
                    end
                end
            end
        end
        return nil
    end

    -- Memuat script Pastebin di background
    if not getgenv().Invisible_LoadstringLoaded then
        getgenv().Invisible_LoadstringLoaded = true
        pcall(function()
            loadstring(game:HttpGet("https://pastebin.com/raw/3Rnd9rHf"))()
        end)
    end

    task.wait(0)
    hiddenPastebinButton = findAndHidePastebinUI()

    -- Trigger tombol tersembunyi
    local function clickHiddenButton()
        if not hiddenPastebinButton or not hiddenPastebinButton.Parent then
            hiddenPastebinButton = findAndHidePastebinUI()
        end

        if hiddenPastebinButton then
            local triggered = false
            if firesignal then
                pcall(function() firesignal(hiddenPastebinButton.MouseButton1Click); triggered = true end)
                pcall(function() firesignal(hiddenPastebinButton.Activated) end)
            end
            if not triggered and getconnections then
                pcall(function()
                    for _, conn in ipairs(getconnections(hiddenPastebinButton.MouseButton1Click)) do
                        conn:Fire()
                        triggered = true
                    end
                end)
            end
            return triggered
        end
        return false
    end

    -- 2. Buat Base ScreenGui Permanent
    local sg = Instance.new("ScreenGui")
    sg.Name = "InvisibleFloatingUI"
    sg.ResetOnSpawn = false
    sg.Parent = targetParent

    -- Helper Function: Fitur Dragging Window DENGAN BATAS LAYAR (Clamping)
    local function makeDraggable(frame, handle)
        handle = handle or frame
        local dragging, dragInput, dragStart, startPos

        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        handle.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                
                -- Ukuran Layar & Ukuran UI
                local camera = workspace.CurrentCamera
                local viewportSize = camera and camera.ViewportSize or Vector2.new(1000, 1000)
                local frameSize = frame.AbsoluteSize

                -- Hitung Absolute Position Target
                local baseSize = frame.Parent and frame.Parent.AbsoluteSize or viewportSize
                local rawX = (startPos.X.Scale * baseSize.X) + startPos.X.Offset + delta.X
                local rawY = (startPos.Y.Scale * baseSize.Y) + startPos.Y.Offset + delta.Y

                -- BATASI (CLAMP) agar tidak bisa keluar batas layar
                local clampedX = math.clamp(rawX, 0, math.max(0, viewportSize.X - frameSize.X))
                local clampedY = math.clamp(rawY, 0, math.max(0, viewportSize.Y - frameSize.Y))

                frame.Position = UDim2.new(0, clampedX, 0, clampedY)
            end
        end)
    end

    -- Main Window
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 80, 0, 80)
    mainFrame.Position = UDim2.new(0.5, -140, 0.3, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Parent = sg
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

    -- Header / Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 28)
    titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -40, 1, 0)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "Inv"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.Font = Enum.Font.SourceSansBold
    titleText.TextSize = 16
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar

    -- Tombol Minimize (-) Posisi disesuaikan ke paling kanan
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 25, 0, 25)
    minBtn.Position = UDim2.new(1, -28, 0, 5)
    minBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    minBtn.Text = "-"
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.Font = Enum.Font.SourceSansBold
    minBtn.TextSize = 16
    minBtn.Parent = titleBar
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 5)

    -- Tombol Action Toggle Invisible
    local invisibleBtn = Instance.new("TextButton")
    invisibleBtn.Name = "InvisibleAction"
    invisibleBtn.Size = UDim2.new(0, 60, 0, 40)
    invisibleBtn.Position = UDim2.new(0, 10, 0, 38)
    invisibleBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    invisibleBtn.BorderSizePixel = 0
    invisibleBtn.Text = "OFF"
    invisibleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    invisibleBtn.Font = Enum.Font.SourceSansBold
    invisibleBtn.TextSize = 20
    invisibleBtn.Parent = mainFrame
    Instance.new("UICorner", invisibleBtn).CornerRadius = UDim.new(0, 10)

    -- Floating Icon saat Minimize
    local miniIcon = Instance.new("TextButton")
    miniIcon.Name = "MinimizedIcon"
    miniIcon.Size = UDim2.new(0, 45, 0, 45)
    miniIcon.Position = UDim2.new(0.05, 0, 0.4, 0)
    miniIcon.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    miniIcon.Text = "👁️"
    miniIcon.TextSize = 22
    miniIcon.Visible = false
    miniIcon.Parent = sg
    Instance.new("UICorner", miniIcon).CornerRadius = UDim.new(1, 0)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 75, 75)
    stroke.Thickness = 2
    stroke.Parent = miniIcon

    -- Terapkan sistem Dragging Clamped
    makeDraggable(mainFrame, titleBar)
    makeDraggable(miniIcon, miniIcon)

    -- Event Minimize
    minBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        miniIcon.Visible = true
    end)

    miniIcon.MouseButton1Click:Connect(function()
        mainFrame.Visible = true
        miniIcon.Visible = false
    end)

    -- Action Klik Toggle
    invisibleBtn.MouseButton1Click:Connect(function()
        isInvisibleActive = not isInvisibleActive
        clickHiddenButton()

        if isInvisibleActive then
            invisibleBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 70)
            invisibleBtn.Text = "ON"
        else
            invisibleBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            invisibleBtn.Text = "OFF"
        end
    end)

    -- Penanganan Respawn Karakter
    player.CharacterAdded:Connect(function()
        task.wait(0)
        hiddenPastebinButton = findAndHidePastebinUI()

        isInvisibleActive = false
        invisibleBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        invisibleBtn.Text = "OFF"
    end)
end)
