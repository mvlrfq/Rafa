local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- 1. UTILITY: DRAGGABLE DENGAN BATAS LAYAR
local function makeDraggable(guiObject, dragHandle)
	dragHandle = dragHandle or guiObject
	local dragging, dragInput, dragStart, startPos

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = guiObject.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	dragHandle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			local viewportSize = Camera.ViewportSize
			
			local newX = startPos.X.Offset + delta.X
			local newY = startPos.Y.Offset + delta.Y
			
			local absoluteX = startPos.X.Scale * viewportSize.X + newX
			local absoluteY = startPos.Y.Scale * viewportSize.Y + newY
			
			local clampedX = math.clamp(absoluteX, 0, viewportSize.X - guiObject.AbsoluteSize.X)
			local clampedY = math.clamp(absoluteY, 0, viewportSize.Y - guiObject.AbsoluteSize.Y)
			
			guiObject.Position = UDim2.new(0, clampedX, 0, clampedY)
		end
	end)
end

-- HELPER: PARSE STRING KOORDINAT (Contoh: "100, 50, -200" atau "100 50 -200")
local function parseVector3(str)
	if not str or str == "" then return nil end
	local nums = {}
	for num in string.gmatch(str, "[-%d%.]+") do
		table.insert(nums, tonumber(num))
	end
	if #nums >= 3 then
		return Vector3.new(nums[1], nums[2], nums[3])
	end
	return nil
end

-- 2. PEMBUATAN GUI UTAMA
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StickyMenuGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 370)
MainFrame.Position = UDim2.new(0.5, -120, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

-- Title Bar
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 32)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
Title.Text = "   📌 Sticky & Patrol Menu"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 15
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

makeDraggable(MainFrame, Title)

-- Tombol Minimize (-)
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 24, 0, 24)
MinimizeBtn.Position = UDim2.new(1, -28, 0, 4)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.TextSize = 18
MinimizeBtn.Parent = Title

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 4)
MinCorner.Parent = MinimizeBtn

-- FLOATING ICON MINIMIZE
local MiniIcon = Instance.new("TextButton")
MiniIcon.Name = "MiniIcon"
MiniIcon.Size = UDim2.new(0, 45, 0, 45)
MiniIcon.Position = UDim2.new(0.1, 0, 0.2, 0)
MiniIcon.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
MiniIcon.Text = "📌"
MiniIcon.TextSize = 22
MiniIcon.Visible = false
MiniIcon.Active = true
MiniIcon.Parent = ScreenGui

local MiniCorner = Instance.new("UICorner")
MiniCorner.CornerRadius = UDim.new(0, 22)
MiniCorner.Parent = MiniIcon

local MiniStroke = Instance.new("UIStroke")
MiniStroke.Color = Color3.fromRGB(80, 80, 110)
MiniStroke.Thickness = 2
MiniStroke.Parent = MiniIcon

makeDraggable(MiniIcon)

-- 3. SCROLLING FRAME UNTUK KONTEN MENU
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "ScrollContainer"
ScrollFrame.Size = UDim2.new(1, -12, 1, -64)
ScrollFrame.Position = UDim2.new(0, 6, 0, 36)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 5
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 130)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 6)
UIList.Parent = ScrollFrame

local UIPad = Instance.new("UIPadding")
UIPad.PaddingRight = UDim.new(0, 6)
UIPad.PaddingLeft = UDim.new(0, 2)
UIPad.PaddingTop = UDim.new(0, 4)
UIPad.Parent = ScrollFrame

-- HELPER UNTUK MEMBUAT KONTROL (+ / -)
local function createControl(order, labelText, getValueText, onDec, onInc)
	local container = Instance.new("Frame")
	container.LayoutOrder = order
	container.Size = UDim2.new(1, 0, 0, 22)
	container.BackgroundTransparency = 1
	container.Parent = ScrollFrame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.44, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.Font = Enum.Font.SourceSansBold
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	local decBtn = Instance.new("TextButton")
	decBtn.Size = UDim2.new(0, 22, 1, 0)
	decBtn.Position = UDim2.new(0.44, 0, 0, 0)
	decBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	decBtn.Text = "-"
	decBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	decBtn.Font = Enum.Font.SourceSansBold
	decBtn.Parent = container

	local valLabel = Instance.new("TextLabel")
	valLabel.Size = UDim2.new(0.32, -44, 1, 0)
	valLabel.Position = UDim2.new(0.44, 22, 0, 0)
	valLabel.BackgroundTransparency = 1
	valLabel.Text = getValueText()
	valLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	valLabel.Font = Enum.Font.SourceSans
	valLabel.TextSize = 11
	valLabel.Parent = container

	local incBtn = Instance.new("TextButton")
	incBtn.Size = UDim2.new(0, 22, 1, 0)
	incBtn.Position = UDim2.new(1, -22, 0, 0)
	incBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	incBtn.Text = "+"
	incBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	incBtn.Font = Enum.Font.SourceSansBold
	incBtn.Parent = container

	decBtn.MouseButton1Click:Connect(function()
		onDec()
		valLabel.Text = getValueText()
	end)

	incBtn.MouseButton1Click:Connect(function()
		onInc()
		valLabel.Text = getValueText()
	end)
end

-- 4. INPUT & TOMBOL FITUR STICKY
local NameBox = Instance.new("TextBox")
NameBox.LayoutOrder = 1
NameBox.Size = UDim2.new(1, 0, 0, 26)
NameBox.PlaceholderText = "Ketik Username Target..."
NameBox.Text = ""
NameBox.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
NameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
NameBox.Font = Enum.Font.SourceSans
NameBox.TextSize = 12
NameBox.Parent = ScrollFrame

local BoxCorner = Instance.new("UICorner")
BoxCorner.CornerRadius = UDim.new(0, 5)
BoxCorner.Parent = NameBox

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.LayoutOrder = 2
ToggleBtn.Size = UDim2.new(1, 0, 0, 26)
ToggleBtn.Text = "Aktifkan Lengket: OFF"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 12
ToggleBtn.Parent = ScrollFrame

local BtnCorner1 = Instance.new("UICorner")
BtnCorner1.CornerRadius = UDim.new(0, 5)
BtnCorner1.Parent = ToggleBtn

local isHeadMode = false
local HeadModeBtn = Instance.new("TextButton")
HeadModeBtn.LayoutOrder = 3
HeadModeBtn.Size = UDim2.new(1, 0, 0, 26)
HeadModeBtn.Text = "Lock Ke Kepala: OFF"
HeadModeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
HeadModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HeadModeBtn.Font = Enum.Font.SourceSansBold
HeadModeBtn.TextSize = 12
HeadModeBtn.Parent = ScrollFrame

local HeadCorner = Instance.new("UICorner")
HeadCorner.CornerRadius = UDim.new(0, 5)
HeadCorner.Parent = HeadModeBtn

local SpectateBtn = Instance.new("TextButton")
SpectateBtn.LayoutOrder = 4
SpectateBtn.Size = UDim2.new(1, 0, 0, 26)
SpectateBtn.Text = "Spectate Target: OFF"
SpectateBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
SpectateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SpectateBtn.Font = Enum.Font.SourceSansBold
SpectateBtn.TextSize = 12
SpectateBtn.Parent = ScrollFrame

local BtnCorner2 = Instance.new("UICorner")
BtnCorner2.CornerRadius = UDim.new(0, 5)
BtnCorner2.Parent = SpectateBtn

-- 5. FITUR KOORDINAT LOOP DENGAN TOMBOL "AMBIL POSISI SAAT INI"
local Separator = Instance.new("Frame")
Separator.LayoutOrder = 5
Separator.Size = UDim2.new(1, 0, 0, 2)
Separator.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
Separator.BorderSizePixel = 0
Separator.Parent = ScrollFrame

-- HELPER: DUA INPUT BARIS (TEXTBOX + TOMBOL SET POSISI SAAT INI)
local function createCoordInput(order, placeholder, setBtnText)
	local container = Instance.new("Frame")
	container.LayoutOrder = order
	container.Size = UDim2.new(1, 0, 0, 26)
	container.BackgroundTransparency = 1
	container.Parent = ScrollFrame

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0.72, 0, 1, 0)
	box.PlaceholderText = placeholder
	box.Text = ""
	box.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.Font = Enum.Font.SourceSans
	box.TextSize = 11
	box.Parent = container

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 5)
	boxCorner.Parent = box

	local setBtn = Instance.new("TextButton")
	setBtn.Size = UDim2.new(0.26, 0, 1, 0)
	setBtn.Position = UDim2.new(0.74, 0, 0, 0)
	setBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 150)
	setBtn.Text = setBtnText
	setBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	setBtn.Font = Enum.Font.SourceSansBold
	setBtn.TextSize = 11
	setBtn.Parent = container

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 5)
	btnCorner.Parent = setBtn

	setBtn.MouseButton1Click:Connect(function()
		local char = LocalPlayer.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local pos = char.HumanoidRootPart.Position
			box.Text = string.format("%.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z)
		end
	end)

	return box
end

local CoordABox = createCoordInput(6, "Titik A: X, Y, Z", "📍 Set A")
local CoordBBox = createCoordInput(7, "Titik B: X, Y, Z", "📍 Set B")

-- VAR KECEPATAN PATROLI
local loopSpeed = 2.0

createControl(8, "Kecepatan Patrol:", function() return string.format("%.1f", loopSpeed) end,
	function() loopSpeed = math.max(0.2, loopSpeed - 0.5) end,
	function() loopSpeed = math.min(20.0, loopSpeed + 0.5) end
)

local LoopCoordBtn = Instance.new("TextButton")
LoopCoordBtn.LayoutOrder = 9
LoopCoordBtn.Size = UDim2.new(1, 0, 0, 26)
LoopCoordBtn.Text = "Loop Koordinat (A <-> B): OFF"
LoopCoordBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
LoopCoordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LoopCoordBtn.Font = Enum.Font.SourceSansBold
LoopCoordBtn.TextSize = 12
LoopCoordBtn.Parent = ScrollFrame

local LoopCorner = Instance.new("UICorner")
LoopCorner.CornerRadius = UDim.new(0, 5)
LoopCorner.Parent = LoopCoordBtn

local Separator2 = Instance.new("Frame")
Separator2.LayoutOrder = 10
Separator2.Size = UDim2.new(1, 0, 0, 2)
Separator2.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
Separator2.BorderSizePixel = 0
Separator2.Parent = ScrollFrame

-- 6. KONTROL OFFSET & ROTASI STICKY
local offsetX, offsetY, offsetZ = 0, 0, -1.5
local rotationY = 180
local rotationX = 0

createControl(11, "Tinggi (Y):", function() return tostring(offsetY) end, 
	function() offsetY = offsetY - 0.5 end, 
	function() offsetY = offsetY + 0.5 end)

createControl(12, "Samping (X):", function() return tostring(offsetX) end, 
	function() offsetX = offsetX - 0.5 end, 
	function() offsetX = offsetX + 0.5 end)

createControl(13, "Jarak (Z):", function() return tostring(-offsetZ) end, 
	function() offsetZ = offsetZ + 0.5 end, 
	function() offsetZ = offsetZ - 0.5 end)

createControl(14, "Putar H (Y):", function() return tostring(rotationY) .. "°" end, 
	function() rotationY = (rotationY - 15) % 360 end, 
	function() rotationY = (rotationY + 15) % 360 end)

createControl(15, "Putar V (X):", function() return tostring(rotationX) .. "°" end, 
	function() rotationX = (rotationX - 15) % 360 end, 
	function() rotationX = (rotationX + 15) % 360 end)

local ResetBtn = Instance.new("TextButton")
ResetBtn.LayoutOrder = 16
ResetBtn.Size = UDim2.new(1, 0, 0, 22)
ResetBtn.Text = "Reset Offset & Rotasi"
ResetBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
ResetBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
ResetBtn.Font = Enum.Font.SourceSans
ResetBtn.TextSize = 11
ResetBtn.Parent = ScrollFrame

ResetBtn.MouseButton1Click:Connect(function()
	offsetX, offsetY, offsetZ = 0, 0, -1.5
	rotationY = 180
	rotationX = 0
end)

-- Status Bar
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -12, 0, 22)
StatusLabel.Position = UDim2.new(0, 6, 1, -24)
StatusLabel.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
StatusLabel.Text = "Status: Tidak Aktif"
StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
StatusLabel.Font = Enum.Font.SourceSansItalic
StatusLabel.TextSize = 12
StatusLabel.Parent = MainFrame

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 4)
StatusCorner.Parent = StatusLabel

MinimizeBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = false
	MiniIcon.Visible = true
end)

MiniIcon.MouseButton1Click:Connect(function()
	MiniIcon.Visible = false
	MainFrame.Visible = true
end)

-- 7. LOGIKA KONTROL FITUR
local isSticking = false
local isSpectating = false
local isLoopingCoord = false

local renderConnection = nil
local loopConnection = nil

local function findTargetPlayer(name)
	if name == "" then return nil end
	name = string.lower(name)
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			if string.find(string.lower(player.Name), name) or string.find(string.lower(player.DisplayName), name) then
				return player
			end
		end
	end
	return nil
end

HeadModeBtn.MouseButton1Click:Connect(function()
	isHeadMode = not isHeadMode
	if isHeadMode then
		HeadModeBtn.Text = "Lock Ke Kepala: ON"
		HeadModeBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 180)
	else
		HeadModeBtn.Text = "Lock Ke Kepala: OFF"
		HeadModeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
	end
end)

local function manageAnimations(character, freeze)
	if not character then return end
	local animateScript = character:FindFirstChild("Animate")
	if animateScript then
		animateScript.Disabled = freeze
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		local tracks = animator and animator:GetPlayingAnimationTracks() or humanoid:GetPlayingAnimationTracks()
		for _, track in pairs(tracks) do
			if freeze then track:Stop(0) end
		end
	end
end

local function applyStateProtections(humanoid, enable)
	if not humanoid then return end
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, not enable)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not enable)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, not enable)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, not enable)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, not enable)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
	if enable and humanoid.Sit then humanoid.Sit = false end
end

local function setNoCollision(character, enabled)
	if not character then return end
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = not enabled
		end
	end
end

-- LOGIKA LOOP KOORDINAT
local function toggleLoopCoord()
	isLoopingCoord = not isLoopingCoord
	
	if isLoopingCoord then
		local posA = parseVector3(CoordABox.Text)
		local posB = parseVector3(CoordBBox.Text)
		
		if not posA or not posB then
			StatusLabel.Text = "Tekan [Set A] & [Set B] dulu!"
			StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			isLoopingCoord = false
			return
		end
		
		if isSticking then
			if toggleSticky then toggleSticky() end
		end
		
		LoopCoordBtn.Text = "Loop Koordinat (A <-> B): ON"
		LoopCoordBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		StatusLabel.Text = "Status: Loop Koordinat Aktif"
		StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		
		loopConnection = RunService.RenderStepped:Connect(function()
			if not isLoopingCoord then return end
			local char = LocalPlayer.Character
			if char then
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp then
					local alpha = (math.sin(tick() * loopSpeed) + 1) / 2
					local currentPos = posA:Lerp(posB, alpha)
					
					hrp.AssemblyLinearVelocity = Vector3.zero
					hrp.AssemblyAngularVelocity = Vector3.zero
					hrp.CFrame = CFrame.new(currentPos)
				end
			end
		end)
	else
		if loopConnection then
			loopConnection:Disconnect()
			loopConnection = nil
		end
		
		LoopCoordBtn.Text = "Loop Koordinat (A <-> B): OFF"
		LoopCoordBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		StatusLabel.Text = "Status: Tidak Aktif"
		StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
	end
end

-- LOGIKA STICKY TARGET
function toggleSticky()
	isSticking = not isSticking
	
	if isSticking then
		if isLoopingCoord then
			toggleLoopCoord()
		end

		local targetPlayer = findTargetPlayer(NameBox.Text)
		if not targetPlayer then
			StatusLabel.Text = "Player tidak ditemukan!"
			StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			isSticking = false
			return
		end
		
		ToggleBtn.Text = "Aktifkan Lengket: ON"
		ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		StatusLabel.Text = "Lock Target: " .. targetPlayer.DisplayName
		StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		
		if LocalPlayer.Character then
			manageAnimations(LocalPlayer.Character, true)
		end
		
		renderConnection = RunService.RenderStepped:Connect(function()
			if not isSticking then return end
			
			local localChar = LocalPlayer.Character
			local targetChar = targetPlayer.Character
			
			if localChar and targetChar then
				local localHRP = localChar:FindFirstChild("HumanoidRootPart")
				local targetPart = isHeadMode and targetChar:FindFirstChild("Head") or targetChar:FindFirstChild("HumanoidRootPart")
				local localHumanoid = localChar:FindFirstChildOfClass("Humanoid")
				local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
				
				if localHumanoid then applyStateProtections(localHumanoid, true) end
				
				if localHRP and targetPart then
					setNoCollision(localChar, true)
					localHRP.AssemblyLinearVelocity = Vector3.zero
					localHRP.AssemblyAngularVelocity = Vector3.zero
					
					manageAnimations(localChar, true)
					
					if targetHumanoid and localHumanoid then
						if targetHumanoid:GetState() == Enum.HumanoidStateType.Swimming then
							localHumanoid:ChangeState(Enum.HumanoidStateType.Swimming)
						end
					end
					
					localHRP.CFrame = targetPart.CFrame 
						* CFrame.new(offsetX, offsetY, offsetZ) 
						* CFrame.Angles(math.rad(rotationX), math.rad(rotationY), 0)
				end
			end
		end)
	else
		if renderConnection then
			renderConnection:Disconnect()
			renderConnection = nil
		end
		
		local localChar = LocalPlayer.Character
		if localChar then
			local localHumanoid = localChar:FindFirstChildOfClass("Humanoid")
			if localHumanoid then applyStateProtections(localHumanoid, false) end
			setNoCollision(localChar, false)
			manageAnimations(localChar, false)
		end
		
		ToggleBtn.Text = "Aktifkan Lengket: OFF"
		ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		StatusLabel.Text = "Status: Tidak Aktif"
		StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
	end
end

local function toggleSpectate()
	isSpectating = not isSpectating
	
	if isSpectating then
		local targetPlayer = findTargetPlayer(NameBox.Text)
		if not targetPlayer or not targetPlayer.Character then
			StatusLabel.Text = "Target/Karakter tidak ada!"
			StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			isSpectating = false
			return
		end
		
		local targetHumanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
		if targetHumanoid then
			Camera.CameraSubject = targetHumanoid
			SpectateBtn.Text = "Spectate Target: ON"
			SpectateBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
			StatusLabel.Text = "Mengawasi: " .. targetPlayer.DisplayName
			StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		end
	else
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
			Camera.CameraSubject = LocalPlayer.Character.Humanoid
		end
		SpectateBtn.Text = "Spectate Target: OFF"
		SpectateBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		StatusLabel.Text = "Status: Tidak Aktif"
		StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
	end
end

ToggleBtn.MouseButton1Click:Connect(toggleSticky)
SpectateBtn.MouseButton1Click:Connect(toggleSpectate)
LoopCoordBtn.MouseButton1Click:Connect(toggleLoopCoord)
