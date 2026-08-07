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

-- HELPER: PARSE VECTOR3 OFFSET
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

-- 2. GUI UTAMA
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CompleteStickyGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 250, 0, 300)
MainFrame.Position = UDim2.new(0.5, -125, 0.2, 0)
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
Title.Text = "   📌 Sticky & Patrol Control"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 14
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

makeDraggable(MainFrame, Title)

-- Minimize Button
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

makeDraggable(MiniIcon)

-- 3. CONTAINER
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

-- Target Name Box
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

-- Tombol Toggle Sticky
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

-- Tombol Lock Kepala
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

-- Tombol Spectate
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

-- Separator 1
local Sep1 = Instance.new("Frame")
Sep1.LayoutOrder = 5
Sep1.Size = UDim2.new(1, 0, 0, 2)
Sep1.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
Sep1.BorderSizePixel = 0
Sep1.Parent = ScrollFrame

-- 4. KONTROL MANUAL SUMBU X, Y, Z & ROTASI
local offsetX, offsetY, offsetZ = 0, 0, -1.5
local rotationY = 180
local rotationX = 0

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

createControl(6, "Tinggi (Y):", function() return tostring(offsetY) end, 
	function() offsetY = offsetY - 0.5 end, 
	function() offsetY = offsetY + 0.5 end)

createControl(7, "Samping (X):", function() return tostring(offsetX) end, 
	function() offsetX = offsetX - 0.5 end, 
	function() offsetX = offsetX + 0.5 end)

createControl(8, "Jarak (Z):", function() return tostring(-offsetZ) end, 
	function() offsetZ = offsetZ + 0.5 end, 
	function() offsetZ = offsetZ - 0.5 end)

createControl(9, "Putar H (Y):", function() return tostring(rotationY) .. "°" end, 
	function() rotationY = (rotationY - 15) % 360 end, 
	function() rotationY = (rotationY + 15) % 360 end)

createControl(10, "Putar V (X):", function() return tostring(rotationX) .. "°" end, 
	function() rotationX = (rotationX - 15) % 360 end, 
	function() rotationX = (rotationX + 15) % 360 end)

local ResetBtn = Instance.new("TextButton")
ResetBtn.LayoutOrder = 11
ResetBtn.Size = UDim2.new(1, 0, 0, 22)
ResetBtn.Text = "Reset Custom Offset"
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

-- Separator 2
local Sep2 = Instance.new("Frame")
Sep2.LayoutOrder = 12
Sep2.Size = UDim2.new(1, 0, 0, 2)
Sep2.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
Sep2.BorderSizePixel = 0
Sep2.Parent = ScrollFrame

-- 5. TITIK KOORDINAT RELATIF SET A & SET B (PATROLI)
local function createRelativeCoordInput(order, placeholder, setBtnText)
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

	-- AMBIL OFFSET SAAT INI (BISA MENGGUNAKAN POPULASI MANUAL X,Y,Z JIKA SEDANG MENEMPEL)
	setBtn.MouseButton1Click:Connect(function()
		local targetPlayer = findTargetPlayer(NameBox.Text)
		local myChar = LocalPlayer.Character
		
		if not targetPlayer or not targetPlayer.Character then
			-- Jika belum kunci target, simpan berdasarkan settingan X, Y, Z manual saat ini
			box.Text = string.format("%.1f, %.1f, %.1f", offsetX, offsetY, offsetZ)
			return
		end

		local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
		local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")

		if myHRP and targetHRP then
			local relativeVector = targetHRP.CFrame:PointToObjectSpace(myHRP.Position)
			box.Text = string.format("%.1f, %.1f, %.1f", relativeVector.X, relativeVector.Y, relativeVector.Z)
		end
	end)

	return box
end

local OffsetABox = createRelativeCoordInput(13, "Offset A (X,Y,Z)", "📍 Set A")
local OffsetBBox = createRelativeCoordInput(14, "Offset B (X,Y,Z)", "📍 Set B")

local patrolSpeed = 2.0
createControl(15, "Kecepatan Patrol:", function() return string.format("%.1f", patrolSpeed) end,
	function() patrolSpeed = math.max(0.2, patrolSpeed - 0.5) end,
	function() patrolSpeed = math.min(20.0, patrolSpeed + 0.5) end
)

local LoopPatrolBtn = Instance.new("TextButton")
LoopPatrolBtn.LayoutOrder = 16
LoopPatrolBtn.Size = UDim2.new(1, 0, 0, 26)
LoopPatrolBtn.Text = "Patroli Target (A <-> B): OFF"
LoopPatrolBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
LoopPatrolBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LoopPatrolBtn.Font = Enum.Font.SourceSansBold
LoopPatrolBtn.TextSize = 12
LoopPatrolBtn.Parent = ScrollFrame

local LoopCorner = Instance.new("UICorner")
LoopCorner.CornerRadius = UDim.new(0, 5)
LoopCorner.Parent = LoopPatrolBtn

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

-- 6. LOGIKA FITUR
local isSticking = false
local isPatrolling = false
local isSpectating = false
local isHeadMode = false

local renderConnection = nil
local patrolConnection = nil

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
	if animateScript then animateScript.Disabled = freeze end
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

-- LOGIKA STICKY MANUAL (MENGGUNAKAN X, Y, Z & ROTASI CONTROL)
local function toggleSticky()
	isSticking = not isSticking

	if isSticking then
		if isPatrolling then togglePatrol() end

		local targetPlayer = findTargetPlayer(NameBox.Text)
		if not targetPlayer then
			StatusLabel.Text = "Target tidak ditemukan!"
			StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			isSticking = false
			return
		end

		ToggleBtn.Text = "Aktifkan Lengket: ON"
		ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		StatusLabel.Text = "Menempel pada: " .. targetPlayer.DisplayName
		StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)

		renderConnection = RunService.RenderStepped:Connect(function()
			if not isSticking then return end

			local myChar = LocalPlayer.Character
			local targetChar = targetPlayer.Character

			if myChar and targetChar then
				local myHRP = myChar:FindFirstChild("HumanoidRootPart")
				local targetPart = isHeadMode and targetChar:FindFirstChild("Head") or targetChar:FindFirstChild("HumanoidRootPart")
				local myHumanoid = myChar:FindFirstChildOfClass("Humanoid")

				if myHRP and targetPart then
					applyStateProtections(myHumanoid, true)
					setNoCollision(myChar, true)
					manageAnimations(myChar, true)

					myHRP.AssemblyLinearVelocity = Vector3.zero
					myHRP.AssemblyAngularVelocity = Vector3.zero

					-- Posisi berdasarkan offset & rotasi manual
					myHRP.CFrame = targetPart.CFrame 
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

		local myChar = LocalPlayer.Character
		if myChar then
			local myHumanoid = myChar:FindFirstChildOfClass("Humanoid")
			applyStateProtections(myHumanoid, false)
			setNoCollision(myChar, false)
			manageAnimations(myChar, false)
		end

		ToggleBtn.Text = "Aktifkan Lengket: OFF"
		ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		StatusLabel.Text = "Status: Tidak Aktif"
		StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
	end
end

-- LOGIKA PATROLI TARGET (A <-> B)
function togglePatrol()
	isPatrolling = not isPatrolling

	if isPatrolling then
		if isSticking then toggleSticky() end

		local targetPlayer = findTargetPlayer(NameBox.Text)
		if not targetPlayer then
			StatusLabel.Text = "Target tidak ditemukan!"
			StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			isPatrolling = false
			return
		end

		local offsetA = parseVector3(OffsetABox.Text) or Vector3.new(-5, 0, -2)
		local offsetB = parseVector3(OffsetBBox.Text) or Vector3.new(5, 0, -2)

		LoopPatrolBtn.Text = "Patroli Target (A <-> B): ON"
		LoopPatrolBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		StatusLabel.Text = "Patroli di sekitar: " .. targetPlayer.DisplayName
		StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)

		patrolConnection = RunService.RenderStepped:Connect(function()
			if not isPatrolling then return end

			local myChar = LocalPlayer.Character
			local targetChar = targetPlayer.Character

			if myChar and targetChar then
				local myHRP = myChar:FindFirstChild("HumanoidRootPart")
				local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
				local myHumanoid = myChar:FindFirstChildOfClass("Humanoid")

				if myHRP and targetHRP then
					applyStateProtections(myHumanoid, true)
					setNoCollision(myChar, true)
					manageAnimations(myChar, true)

					myHRP.AssemblyLinearVelocity = Vector3.zero
					myHRP.AssemblyAngularVelocity = Vector3.zero

					local alpha = (math.sin(tick() * patrolSpeed) + 1) / 2
					local currentOffset = offsetA:Lerp(offsetB, alpha)

					myHRP.CFrame = targetHRP.CFrame * CFrame.new(currentOffset) * CFrame.Angles(0, math.rad(180), 0)
				end
			end
		end)
	else
		if patrolConnection then
			patrolConnection:Disconnect()
			patrolConnection = nil
		end

		local myChar = LocalPlayer.Character
		if myChar then
			local myHumanoid = myChar:FindFirstChildOfClass("Humanoid")
			applyStateProtections(myHumanoid, false)
			setNoCollision(myChar, false)
			manageAnimations(myChar, false)
		end

		LoopPatrolBtn.Text = "Patroli Target (A <-> B): OFF"
		LoopPatrolBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		StatusLabel.Text = "Status: Tidak Aktif"
		StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
	end
end

local function toggleSpectate()
	isSpectating = not isSpectating
	
	if isSpectating then
		local targetPlayer = findTargetPlayer(NameBox.Text)
		if not targetPlayer or not targetPlayer.Character then
			StatusLabel.Text = "Target tidak ditemukan!"
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
LoopPatrolBtn.MouseButton1Click:Connect(togglePatrol)
SpectateBtn.MouseButton1Click:Connect(toggleSpectate)
