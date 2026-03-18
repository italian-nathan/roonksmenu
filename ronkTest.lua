-- r0onk's Menu
-- T = Open / Close
-- F = Toggle Fly
-- N = Toggle Noclip
-- J = Toggle Infinite Jump
-- Fly / Ghost: WASD + Space / LeftAlt
-- Ghost boost: Shift
-- Ghost slow: Ctrl

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== DEBUG HUD =====
local debugGui = Instance.new("ScreenGui")
debugGui.Name = "r0onk_Debug"
debugGui.ResetOnSpawn = false
debugGui.IgnoreGuiInset = true
debugGui.DisplayOrder = 2147483647
debugGui.Parent = playerGui

local debugLabel = Instance.new("TextLabel")
debugLabel.Size = UDim2.new(0, 420, 0, 28)
debugLabel.Position = UDim2.new(0, 10, 0, 10)
debugLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
debugLabel.BackgroundTransparency = 0.25
debugLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
debugLabel.Font = Enum.Font.Code
debugLabel.TextSize = 16
debugLabel.TextXAlignment = Enum.TextXAlignment.Left
debugLabel.BorderSizePixel = 0
debugLabel.Text = "BOOT: start"
debugLabel.Parent = debugGui
Instance.new("UICorner", debugLabel).CornerRadius = UDim.new(0, 8)

local function debugStage(msg)
	debugLabel.Text = "BOOT: " .. tostring(msg)
end

local function debugError(where, err)
	debugLabel.Text = "ERROR @ " .. tostring(where) .. " :: " .. tostring(err)
	warn("r0onk menu error @", where, err)
end

local menuAlive = true
local shuttingDown = false

local spawnWalkSpeed = 16

local characterAddedConn = nil
local playersAddedConn = nil
local playersRemovingConn = nil
local playerTeamConn = nil
local playerNeutralConn = nil

local function typingInTextBox()
	return UserInputService:GetFocusedTextBox() ~= nil
end

-- ===== SETTINGS =====
local OPEN_KEY = Enum.KeyCode.T
local FLY_KEY = Enum.KeyCode.F

local MIN_SPEED = 1
local MAX_SPEED = 999
local speed = 60

local WALK_MIN = 1
local WALK_MAX = 999
local walkSpeed = 16

local TP_OFFSET = CFrame.new(0, 0, -3)
local BRING_OFFSET = CFrame.new(0, 0, -4)

local PANEL_SIZE = 420
local HEADER_H = 72

local INF_COOLDOWN = 0.18
local INF_IMPULSE = 52

-- ===== THEME =====
local THEME = {
	BG = Color3.fromRGB(32, 34, 40),
	PANEL = Color3.fromRGB(42, 45, 54),
	BUTTON = Color3.fromRGB(52, 56, 68),
	BUTTON_ACTIVE = Color3.fromRGB(0, 140, 255),
	TEXT = Color3.fromRGB(235, 235, 235),
	SUBTEXT = Color3.fromRGB(170, 170, 170),
	ACCENT = Color3.fromRGB(0, 255, 120),
	OUTLINE = Color3.fromRGB(70, 70, 80),
	WARN = Color3.fromRGB(255, 190, 70),
	DANGER = Color3.fromRGB(220, 60, 60)
}

-- ===== FORWARD DECLARATIONS =====
local refreshAllButtons
local rebuildList
local updateBringStatus
local setNoclip
local setFlying
local ghostSetState
local ghostHardCleanup
local updateESPButtons
local showToast
local refreshGhostUI
local refreshStatusLine

-- ===== CORE STATE =====
local character = nil
local humanoid = nil
local hrp = nil
local humWalkConn = nil

local flying = false
local flyAttachment = nil
local flyVelocity = nil
local flyOrientation = nil

local noclip = false
local noclipConn = nil
local savedCollide = {}

local infJump = false
local infLast = 0
local infArmed = true

local espEnabled = false
local espMode = "ENEMIES"
local espByPlayer = {}
local espPlayerHooks = {}

local bringingTargets = {}
local bringConn = nil
local bringStatusLabel = nil

local ghostState = "OFF" -- OFF | GHOST | BODY
local ghostModel = nil
local ghostHum = nil
local ghostRoot = nil
local ghostMoveConn = nil
local ghostHeartbeatConn = nil
local ghostSafeBodyCF = nil
local ghostSavedAutoRotate = nil
local ghostVelocity = Vector3.zero

local GHOST_ACCEL = 16
local GHOST_DECEL = 20
local GHOST_BOOST_MULT = 2
local GHOST_SLOW_MULT = 0.35

local notificationsEnabled = true
local playerSearchText = ""

-- ===== HELPERS =====
local function getHumanoid()
	return character and character:FindFirstChildOfClass("Humanoid") or nil
end

local function getHRP()
	return character and character:FindFirstChild("HumanoidRootPart") or nil
end

local function getTorso(char)
	return char and (
		char:FindFirstChild("UpperTorso")
		or char:FindFirstChild("Torso")
		or char:FindFirstChild("LowerTorso")
	)
end

local function teamsInUse()
	return #Teams:GetTeams() > 0
end

local function isEnemy(other)
	if other == player then return false end
	if not teamsInUse() then return true end
	if player.Neutral or other.Neutral then return true end
	return other.Team ~= player.Team
end

local function isTeammate(other)
	if other == player then return false end
	if not teamsInUse() then return false end
	if player.Neutral or other.Neutral then return false end
	return other.Team == player.Team
end

local function setToggleButton(btn, on, onText, offText)
	if not btn then return end
	btn.Text = on and onText or offText
	btn.BackgroundColor3 = on and THEME.BUTTON_ACTIVE or THEME.BUTTON
end

local function applyWalkSpeed()
	local hum = getHumanoid()
	if hum then
		hum.WalkSpeed = walkSpeed
	end
end

local function matchesSearch(name, query)
	if query == "" then return true end
	return string.find(string.lower(name), string.lower(query), 1, true) ~= nil
end

-- ===== UI ROOT =====
local oldGui = playerGui:FindFirstChild("r0onk_Menu")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "r0onk_Menu"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
gui.Enabled = true
gui.Parent = playerGui

local espFolder = Instance.new("Folder")
espFolder.Name = "r0onk_ESP"
espFolder.Parent = gui

-- ===== MAIN WINDOW =====
local window = Instance.new("Frame")
window.Name = "Window"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.new(0.5, 0, 0.5, 0)
window.Size = UDim2.new(0, PANEL_SIZE, 0, PANEL_SIZE)
window.BackgroundColor3 = THEME.BG
window.BorderSizePixel = 0
window.Visible = false
window.Active = true
window.ClipsDescendants = true
window.ZIndex = 100
window.Parent = gui

task.defer(function()
	if window and window.Parent then
		window.Visible = true
		window.Size = UDim2.new(0, 420, 0, 420)
		task.wait(1)
		if window and window.Parent then
			window.Visible = false
			window.Size = UDim2.new(0, 0, 0, 0)
		end
	end
end)

Instance.new("UICorner", window).CornerRadius = UDim.new(0, 14)

local windowStroke = Instance.new("UIStroke")
windowStroke.Color = THEME.OUTLINE
windowStroke.Thickness = 1
windowStroke.Parent = window

local OPEN_TWEEN = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local CLOSE_TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local menuOpen = false
local currentWindowTween = nil

local function stopWindowTween()
	if currentWindowTween then
		currentWindowTween:Cancel()
		currentWindowTween = nil
	end
end

local function animateOpen()
	stopWindowTween()

	menuOpen = true
	window.Visible = true
	window.Size = UDim2.new(0, 0, 0, 0)

	currentWindowTween = TweenService:Create(window, OPEN_TWEEN, {
		Size = UDim2.new(0, PANEL_SIZE, 0, PANEL_SIZE)
	})
	currentWindowTween:Play()
end

local function animateClose()
	stopWindowTween()

	menuOpen = false

	currentWindowTween = TweenService:Create(window, CLOSE_TWEEN, {
		Size = UDim2.new(0, 0, 0, 0)
	})
	currentWindowTween:Play()

	currentWindowTween.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed and not menuOpen and window and window.Parent then
			window.Visible = false
		end
	end)
end

local function toggleWindow()
	if menuOpen then
		animateClose()
	else
		animateOpen()
		rebuildList()
	end
end

-- ===== HEADER =====
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, HEADER_H)
header.BackgroundColor3 = THEME.BG
header.BorderSizePixel = 0
header.ZIndex = 10
header.Active = true
header.Parent = window
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)

local headerLine = Instance.new("Frame")
headerLine.Size = UDim2.new(1, -20, 0, 1)
headerLine.Position = UDim2.new(0, 10, 1, -1)
headerLine.BackgroundColor3 = THEME.OUTLINE
headerLine.BorderSizePixel = 0
headerLine.ZIndex = 11
headerLine.Parent = header

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 12, 0, 8)
title.Size = UDim2.new(1, -56, 0, 22)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = THEME.TEXT
title.Text = "r0onk's Menu"
title.ZIndex = 11
title.Parent = header

local sub = Instance.new("TextLabel")
sub.BackgroundTransparency = 1
sub.Position = UDim2.new(0, 12, 0, 30)
sub.Size = UDim2.new(1, -56, 0, 16)
sub.Font = Enum.Font.Gotham
sub.TextSize = 12
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.TextColor3 = THEME.SUBTEXT
sub.Text = "T = Menu   |   F = Fly   |   N = Noclip   |   J = Infinite Jump"
sub.ZIndex = 11
sub.Parent = header

local statusLine = Instance.new("TextLabel")
statusLine.BackgroundTransparency = 1
statusLine.Position = UDim2.new(0, 12, 0, 46)
statusLine.Size = UDim2.new(1, -56, 0, 14)
statusLine.Font = Enum.Font.Gotham
statusLine.TextSize = 11
statusLine.TextXAlignment = Enum.TextXAlignment.Left
statusLine.TextColor3 = THEME.ACCENT
statusLine.Text = "Active: None"
statusLine.ZIndex = 11
statusLine.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -36, 0, 12)
closeBtn.BackgroundColor3 = THEME.BUTTON
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = THEME.DANGER
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 12
closeBtn.BorderSizePixel = 0
closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- ===== SCROLL CONTENT =====
local frame = Instance.new("ScrollingFrame")
frame.Size = UDim2.new(1, 0, 1, -HEADER_H)
frame.Position = UDim2.new(0, 0, 0, HEADER_H)
frame.BackgroundTransparency = 1
frame.BorderSizePixel = 0
frame.ScrollBarThickness = 6
frame.ScrollingDirection = Enum.ScrollingDirection.Y
frame.ElasticBehavior = Enum.ElasticBehavior.Never
frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
frame.CanvasSize = UDim2.new(0, 0, 0, 0)
frame.ClipsDescendants = true
frame.ZIndex = 2
frame.Parent = window

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 10)
pad.PaddingBottom = UDim.new(0, 14)
pad.PaddingLeft = UDim.new(0, 18)
pad.PaddingRight = UDim.new(0, 18)
pad.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 10)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Parent = frame

local ORDER = 0
local function nextOrder()
	ORDER += 1
	return ORDER
end

local function makeLabel(parent, text, color, sizeY, textSize)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 0, sizeY or 20)
	l.BackgroundTransparency = 1
	l.Text = text
	l.Font = Enum.Font.Gotham
	l.TextSize = textSize or 14
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextColor3 = color or THEME.TEXT
	l.ZIndex = 2
	l.Parent = parent
	return l
end

local function makeButton(parent, text, h)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, h or 36)
	b.BackgroundColor3 = THEME.BUTTON
	b.TextColor3 = THEME.TEXT
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 14
	b.Text = text
	b.AutoButtonColor = false
	b.ZIndex = 2
	b.BorderSizePixel = 0
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	return b
end

local function makeSpacer(parent, px)
	local s = Instance.new("Frame")
	s.Size = UDim2.new(1, 0, 0, px or 6)
	s.BackgroundTransparency = 1
	s.Parent = parent
	return s
end

local sectionStates = {}

local function createSection(titleText, defaultOpen)
	local outer = Instance.new("Frame")
	outer.BackgroundTransparency = 1
	outer.BorderSizePixel = 0
	outer.Size = UDim2.new(1, 0, 0, 0)
	outer.AutomaticSize = Enum.AutomaticSize.Y
	outer.LayoutOrder = nextOrder()
	outer.Parent = frame

	local headerBtn = Instance.new("TextButton")
	headerBtn.Size = UDim2.new(1, 0, 0, 30)
	headerBtn.BackgroundColor3 = THEME.PANEL
	headerBtn.BorderSizePixel = 0
	headerBtn.Text = ""
	headerBtn.AutoButtonColor = false
	headerBtn.Parent = outer
	Instance.new("UICorner", headerBtn).CornerRadius = UDim.new(0, 8)

	local arrow = Instance.new("TextLabel")
	arrow.BackgroundTransparency = 1
	arrow.Position = UDim2.new(0, 10, 0, 0)
	arrow.Size = UDim2.new(0, 18, 1, 0)
	arrow.Font = Enum.Font.GothamBold
	arrow.TextSize = 13
	arrow.TextColor3 = THEME.SUBTEXT
	arrow.TextXAlignment = Enum.TextXAlignment.Left
	arrow.Parent = headerBtn

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.new(0, 28, 0, 0)
	titleLabel.Size = UDim2.new(1, -38, 1, 0)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 13
	titleLabel.TextColor3 = THEME.TEXT
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = titleText
	titleLabel.Parent = headerBtn

	local content = Instance.new("Frame")
	content.BackgroundTransparency = 1
	content.Position = UDim2.new(0, 0, 0, 34)
	content.Size = UDim2.new(1, 0, 0, 0)
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.Parent = outer

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.Padding = UDim.new(0, 8)
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Parent = content

	sectionStates[outer] = defaultOpen ~= false

	local function refresh()
		local open = sectionStates[outer]
		arrow.Text = open and "−" or "+"
		content.Visible = open
	end

	headerBtn.MouseButton1Click:Connect(function()
		sectionStates[outer] = not sectionStates[outer]
		refresh()
	end)

	refresh()
	return content, outer
end

-- ===== TOAST / NOTIFICATION =====
local toastAnchor = Instance.new("Frame")
toastAnchor.Name = "ToastAnchor"
toastAnchor.Size = UDim2.new(0, 250, 0, 70)
toastAnchor.Position = UDim2.new(1, -270, 0, 30)
toastAnchor.BackgroundColor3 = THEME.BG
toastAnchor.BorderSizePixel = 0
toastAnchor.ZIndex = 50
toastAnchor.Visible = false
toastAnchor.Parent = gui
Instance.new("UICorner", toastAnchor).CornerRadius = UDim.new(0, 12)

local toastAnchorStroke = Instance.new("UIStroke")
toastAnchorStroke.Color = THEME.OUTLINE
toastAnchorStroke.Thickness = 1
toastAnchorStroke.Parent = toastAnchor

local toastDragBar = Instance.new("TextButton")
toastDragBar.Name = "DragBar"
toastDragBar.Size = UDim2.new(1, 0, 0, 12)
toastDragBar.BackgroundColor3 = THEME.PANEL
toastDragBar.BorderSizePixel = 0
toastDragBar.Text = ""
toastDragBar.AutoButtonColor = false
toastDragBar.Parent = toastAnchor
Instance.new("UICorner", toastDragBar).CornerRadius = UDim.new(0, 12)

local toastBody = Instance.new("Frame")
toastBody.Size = UDim2.new(1, 0, 1, -12)
toastBody.Position = UDim2.new(0, 0, 0, 12)
toastBody.BackgroundTransparency = 1
toastBody.ZIndex = 50
toastBody.Parent = toastAnchor

local toastTitle = Instance.new("TextLabel")
toastTitle.BackgroundTransparency = 1
toastTitle.Position = UDim2.new(0, 10, 0, 8)
toastTitle.Size = UDim2.new(1, -20, 0, 16)
toastTitle.Font = Enum.Font.GothamBold
toastTitle.TextSize = 13
toastTitle.TextColor3 = THEME.TEXT
toastTitle.TextXAlignment = Enum.TextXAlignment.Left
toastTitle.Text = ""
toastTitle.ZIndex = 52
toastTitle.Parent = toastBody

local toastText = Instance.new("TextLabel")
toastText.BackgroundTransparency = 1
toastText.Position = UDim2.new(0, 10, 0, 28)
toastText.Size = UDim2.new(1, -20, 0, 16)
toastText.Font = Enum.Font.Gotham
toastText.TextSize = 11
toastText.TextColor3 = THEME.SUBTEXT
toastText.TextXAlignment = Enum.TextXAlignment.Left
toastText.Text = ""
toastText.ZIndex = 52
toastText.Parent = toastBody

local toastFadeToken = 0

showToast = function(titleText, bodyText, accentColor)
	if not notificationsEnabled then
		return
	end

	toastFadeToken += 1
	local token = toastFadeToken

	toastAnchor.Visible = true
	toastAnchor.BackgroundTransparency = 0
	toastDragBar.BackgroundTransparency = 0
	toastTitle.TextTransparency = 0
	toastText.TextTransparency = 0
	toastAnchorStroke.Transparency = 0

	toastTitle.Text = titleText or "Notice"
	toastText.Text = bodyText or ""
	toastTitle.TextColor3 = accentColor or THEME.TEXT

	task.spawn(function()
		task.wait(2.6)
		if token ~= toastFadeToken or not toastAnchor.Parent then
			return
		end

		local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local t1 = TweenService:Create(toastAnchor, tweenInfo, {BackgroundTransparency = 1})
		local t2 = TweenService:Create(toastDragBar, tweenInfo, {BackgroundTransparency = 1})
		local t3 = TweenService:Create(toastTitle, tweenInfo, {TextTransparency = 1})
		local t4 = TweenService:Create(toastText, tweenInfo, {TextTransparency = 1})
		local t5 = TweenService:Create(toastAnchorStroke, tweenInfo, {Transparency = 1})

				t1:Play(); t2:Play(); t3:Play(); t4:Play(); t5:Play()

		t1.Completed:Connect(function()
			if token == toastFadeToken and toastAnchor.Parent then
				toastAnchor.Visible = false
			end
		end)
	end)
end

do
	local dragging = false
	local dragStart
	local startPos

	toastDragBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = toastAnchor.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			toastAnchor.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
end

-- ===== FLY =====
local function cleanupFly()
	if flyVelocity then flyVelocity:Destroy() end
	if flyOrientation then flyOrientation:Destroy() end
	if flyAttachment then flyAttachment:Destroy() end
	flyVelocity = nil
	flyOrientation = nil
	flyAttachment = nil
end

local function setupFlyForCharacter()
	cleanupFly()

	local root = getHRP()
	if not root then return end

	flyAttachment = Instance.new("Attachment")
	flyAttachment.Parent = root

	flyVelocity = Instance.new("LinearVelocity")
	flyVelocity.Attachment0 = flyAttachment
	flyVelocity.MaxForce = math.huge
	flyVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	flyVelocity.Enabled = false
	flyVelocity.Parent = root

	flyOrientation = Instance.new("AlignOrientation")
	flyOrientation.Attachment0 = flyAttachment
	flyOrientation.MaxTorque = math.huge
	flyOrientation.Responsiveness = 200
	flyOrientation.Enabled = false
	flyOrientation.Parent = root
end

setFlying = function(on)
	if ghostState == "GHOST" or ghostState == "BODY" then
		on = false
	end

	flying = on
	if flyVelocity then flyVelocity.Enabled = flying end
	if flyOrientation then flyOrientation.Enabled = flying end
end

-- ===== NOCLIP =====
local function saveIfNeeded(part)
	if savedCollide[part] == nil then
		savedCollide[part] = {part.CanCollide, part.CanTouch, part.CanQuery}
	end
end

local function restorePart(part, old)
	if part and part.Parent then
		part.CanCollide = old[1]
		part.CanTouch = old[2]
		part.CanQuery = old[3]
	end
end

local function restoreAllCollisions()
	for part, old in pairs(savedCollide) do
		restorePart(part, old)
	end
	table.clear(savedCollide)
end

local function isCharPart(part)
	return character and part and part:IsDescendantOf(character)
end

local function getSeatPart()
	local hum = getHumanoid()
	return hum and hum.SeatPart or nil
end

local function getVehicleModelFromSeat(seat)
	if not seat then return nil end
	local m = seat:FindFirstAncestorOfClass("Model")
	if m and m ~= character then
		return m
	end
	return nil
end

local function pickFallbackRootPart(model)
	if not model then return nil end

	local vs = model:FindFirstChildWhichIsA("VehicleSeat", true)
	if vs then return vs end

	local s = model:FindFirstChildWhichIsA("Seat", true)
	if s then return s end

	if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
		return model.PrimaryPart
	end

	local best, bestMass = nil, -1
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local mass = d.AssemblyMass
			if mass > bestMass then
				bestMass = mass
				best = d
			end
		end
	end
	return best
end

local function markConnectedFrom(rootPart, touched)
	if not rootPart or not rootPart:IsA("BasePart") then return end

	for _, p in ipairs(rootPart:GetConnectedParts(true)) do
		if p:IsA("BasePart") and not isCharPart(p) then
			saveIfNeeded(p)
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
			touched[p] = true
		end
	end
end

local function markCharacterNoCollide(touched)
	if not character then return end
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") then
			saveIfNeeded(d)
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			touched[d] = true
		end
	end
end

local function pruneUntouched(touched)
	for part, old in pairs(savedCollide) do
		if not touched[part] then
			restorePart(part, old)
			savedCollide[part] = nil
		end
	end
end

local function applyNoCollide()
	if not character then return end

	local touched = {}
	markCharacterNoCollide(touched)

	local seat = getSeatPart()
	if seat and seat:IsA("BasePart") then
		markConnectedFrom(seat, touched)

		local vehicleModel = getVehicleModelFromSeat(seat)
		if vehicleModel then
			if vehicleModel.PrimaryPart and vehicleModel.PrimaryPart:IsA("BasePart") then
				markConnectedFrom(vehicleModel.PrimaryPart, touched)
			end

			local fallbackRoot = pickFallbackRootPart(vehicleModel)
			if fallbackRoot and fallbackRoot ~= seat and fallbackRoot ~= vehicleModel.PrimaryPart then
				markConnectedFrom(fallbackRoot, touched)
			end
		end
	end

	pruneUntouched(touched)
end

local function startNoclipLoop()
	if noclipConn then return end
	noclipConn = RunService.Stepped:Connect(function()
		if noclip and ghostState ~= "GHOST" then
			applyNoCollide()
		end
	end)
end

local function stopNoclipLoop()
	if noclipConn then
		noclipConn:Disconnect()
		noclipConn = nil
	end
end

setNoclip = function(on)
	noclip = on

	if noclip then
		table.clear(savedCollide)
		applyNoCollide()
		startNoclipLoop()
	else
		stopNoclipLoop()
		restoreAllCollisions()
	end
end

-- ===== ATTACK WINDOW =====
local ATTACK_WINDOW = 0.15
local attackDebounce = false

local function hrpSafeToEnable()
	local root = getHRP()
	if not root then return false end

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}

	local touching = workspace:GetPartsInPart(root, params)
	return #touching == 0
end

local function doAttackWindow()
	if not noclip or attackDebounce then return end
	if ghostState == "GHOST" then return end

	local root = getHRP()
	if not root then return end
	if not hrpSafeToEnable() then return end

	attackDebounce = true

	local old = savedCollide[root]
	if not old then
		old = {root.CanCollide, root.CanTouch, root.CanQuery}
	end

	root.CanCollide = true
	root.CanTouch = true
	root.CanQuery = true

	task.delay(ATTACK_WINDOW, function()
		if noclip and root and root.Parent then
			root.CanCollide = false
			root.CanTouch = false
			root.CanQuery = false
		elseif root and root.Parent then
			root.CanCollide = old[1]
			root.CanTouch = old[2]
			root.CanQuery = old[3]
		end

		attackDebounce = false
	end)
end

local function hookTool(tool)
	if not tool:IsA("Tool") then return end
	tool.Activated:Connect(doAttackWindow)
end

local function hookCharacterTools(char)
	char.ChildAdded:Connect(hookTool)
	for _, c in ipairs(char:GetChildren()) do
		hookTool(c)
	end
end

-- ===== ESP =====
local function shouldShowESP(other)
	if other == player then return false end
	if not espEnabled then return false end
	if espMode == "ALL" then return true end
	if espMode == "ENEMIES" then return isEnemy(other) end
	if espMode == "TEAM" then return isTeammate(other) end
	return false
end

local function outlineColorFor(other)
	return other.TeamColor and other.TeamColor.Color or Color3.fromRGB(255, 255, 255)
end

local function removeESP(other)
	local h = espByPlayer[other]
	if h then
		h:Destroy()
		espByPlayer[other] = nil
	end
end

local function ensureESP(other)
	if not shouldShowESP(other) then
		removeESP(other)
		return
	end

	local char = other.Character
	if not char then
		removeESP(other)
		return
	end

	local h = espByPlayer[other]
	if not h then
		h = Instance.new("Highlight")
		h.Name = "ESP_" .. other.Name
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.FillTransparency = 1
		h.OutlineTransparency = 0
		h.Parent = espFolder
		espByPlayer[other] = h
	end

	h.Adornee = char
	h.OutlineColor = outlineColorFor(other)
end

local function refreshAllESP()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			ensureESP(p)
		end
	end
end

local function setESPEnabled(on)
	espEnabled = on
	if not espEnabled then
		for p in pairs(espByPlayer) do
			removeESP(p)
		end
	else
		refreshAllESP()
	end
end

local function setESPMode(mode)
	espMode = mode
	if espEnabled then
		refreshAllESP()
	end
end

local function unhookESPPlayer(plr)
	local bundle = espPlayerHooks[plr]
	if bundle then
		for _, conn in ipairs(bundle) do
			conn:Disconnect()
		end
		espPlayerHooks[plr] = nil
	end
	removeESP(plr)
end

local function hookESPPlayer(plr)
	if plr == player then return end
	if espPlayerHooks[plr] then return end

	espPlayerHooks[plr] = {
		plr.CharacterAdded:Connect(function()
			task.defer(function()
				ensureESP(plr)
			end)
		end),
		plr:GetPropertyChangedSignal("Team"):Connect(function()
			ensureESP(plr)
		end),
		plr:GetPropertyChangedSignal("Neutral"):Connect(function()
			ensureESP(plr)
		end),
		plr:GetPropertyChangedSignal("TeamColor"):Connect(function()
			ensureESP(plr)
		end),
	}

	ensureESP(plr)
end

task.spawn(function()
	while menuAlive do
		task.wait(1)
		if espEnabled then
			refreshAllESP()
		end
	end
end)

-- ===== BRING / TELEPORT =====
updateBringStatus = function()
	if not bringStatusLabel then return end

	local names = {}
	for plr in pairs(bringingTargets) do
		table.insert(names, plr.Name)
	end
	table.sort(names)

	if #names == 0 then
		bringStatusLabel.Text = "Bringing: None"
	elseif #names <= 4 then
		bringStatusLabel.Text = "Bringing: " .. table.concat(names, ", ")
	else
		bringStatusLabel.Text = "Bringing: " .. #names .. " players"
	end
end

local function ensureBringLoop()
	if bringConn then return end
	bringConn = RunService.RenderStepped:Connect(function()
		local myTorso = player.Character and getTorso(player.Character)
		if not myTorso then return end

		for plr in pairs(bringingTargets) do
			local char = plr.Character
			local torso = char and getTorso(char)
			if torso then
				char:PivotTo(
					(myTorso.CFrame * BRING_OFFSET)
					* torso.CFrame:Inverse()
					* char:GetPivot()
				)
			end
		end
	end)
end

local function toggleBringing(plr)
	if bringingTargets[plr] then
		bringingTargets[plr] = nil
		showToast("Bring", "Stopped bringing " .. plr.Name, THEME.SUBTEXT)
	else
		bringingTargets[plr] = true
		ensureBringLoop()
		showToast("Bring", "Bringing " .. plr.Name, THEME.ACCENT)
	end
	updateBringStatus()
end

local function stopBringingAll()
	if bringConn then
		bringConn:Disconnect()
		bringConn = nil
	end
	table.clear(bringingTargets)
	updateBringStatus()
end

local function bringAllPlayers()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			bringingTargets[plr] = true
		end
	end
	ensureBringLoop()
	updateBringStatus()
end

local function teleportToPlayer(plr)
	if not plr.Character or not character then return end
	if ghostState == "GHOST" then return end

	local myTorso = getTorso(character)
	local theirTorso = getTorso(plr.Character)
	if not myTorso or not theirTorso then return end

	local newPivot =
		(theirTorso.CFrame * TP_OFFSET)
		* myTorso.CFrame:Inverse()
		* character:GetPivot()

	character:PivotTo(newPivot)
	showToast("Teleport", "Teleported to " .. plr.Name, THEME.ACCENT)
end

local function giveTeleportTool()
	local backpack = player:WaitForChild("Backpack")

	local old = backpack:FindFirstChild("Teleport Tool")
	if old then old:Destroy() end

	local tool = Instance.new("Tool")
	tool.Name = "Teleport Tool"
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool.Parent = backpack

	local mouse = player:GetMouse()

	tool.Activated:Connect(function()
		if ghostState == "GHOST" then return end

		local char = player.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local pos = mouse.Hit.Position + Vector3.new(0, 3, 0)
		local rot = root.CFrame - root.CFrame.Position
		root.CFrame = CFrame.new(pos) * rot
	end)

	showToast("Tool", "Teleport Tool added.", THEME.ACCENT)
end

-- ===== GHOST =====
local function ghostIsActive()
	return ghostState ~= "OFF"
end

local function ghostControllingGhost()
	return ghostState == "GHOST"
end

local function ghostControllingBody()
	return ghostState == "BODY"
end

local function ghostSetCameraToBody()
	local cam = workspace.CurrentCamera
	local hum = getHumanoid()
	if cam and hum then
		cam.CameraType = Enum.CameraType.Custom
		cam.CameraSubject = hum
	end
end

local function ghostSetCameraToGhost()
	local cam = workspace.CurrentCamera
	if cam and ghostHum then
		cam.CameraType = Enum.CameraType.Custom
		cam.CameraSubject = ghostHum
	end
end

local function ghostDestroyRig()
	if ghostModel then
		ghostModel:Destroy()
	end
	ghostModel = nil
	ghostHum = nil
	ghostRoot = nil
	ghostVelocity = Vector3.zero
end

local function ghostCreateRig(atCF)
	ghostDestroyRig()

	ghostModel = Instance.new("Model")
	ghostModel.Name = "r0onk_Ghost"

	ghostRoot = Instance.new("Part")
	ghostRoot.Name = "HumanoidRootPart"
	ghostRoot.Size = Vector3.new(2, 2, 1)
	ghostRoot.Transparency = 1
	ghostRoot.Anchored = true
	ghostRoot.CanCollide = false
	ghostRoot.CanTouch = false
	ghostRoot.CanQuery = false
	ghostRoot.CFrame = atCF
	ghostRoot.Parent = ghostModel

	ghostHum = Instance.new("Humanoid")
	ghostHum.Name = "Humanoid"
	ghostHum.WalkSpeed = 0
	ghostHum.JumpPower = 0
	ghostHum.AutoRotate = false
	ghostHum.Parent = ghostModel

	ghostModel.PrimaryPart = ghostRoot
	ghostModel.Parent = workspace
end

local function ghostSetBodyLocked(locked)
	local root = getHRP()
	local hum = getHumanoid()
	if not root or not hum then return end

	if locked then
		if ghostSavedAutoRotate == nil then
			ghostSavedAutoRotate = hum.AutoRotate
		end
		hum.AutoRotate = false
		root.Anchored = true
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	else
		root.Anchored = false
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		hum.AutoRotate = ghostSavedAutoRotate ~= nil and ghostSavedAutoRotate or true
	end
end

local function ghostStopLoops()
	if ghostMoveConn then
		ghostMoveConn:Disconnect()
		ghostMoveConn = nil
	end
	if ghostHeartbeatConn then
		ghostHeartbeatConn:Disconnect()
		ghostHeartbeatConn = nil
	end
end

local function ghostGetMoveSpeed()
	local moveSpeed = speed or 60

	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
		moveSpeed *= GHOST_BOOST_MULT
	end

	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
		moveSpeed *= GHOST_SLOW_MULT
	end

	return moveSpeed
end

local function ghostGetInputDirection(cam)
	local dir = Vector3.zero

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then dir -= Vector3.yAxis end

	if dir.Magnitude > 0 then
		dir = dir.Unit
	end

	return dir
end

ghostHardCleanup = function()
	ghostStopLoops()
	ghostDestroyRig()
	ghostSetBodyLocked(false)
	ghostSafeBodyCF = nil
	ghostSavedAutoRotate = nil
	ghostState = "OFF"
	ghostSetCameraToBody()
end

local function ghostStartLoops()
	ghostStopLoops()

	ghostHeartbeatConn = RunService.Heartbeat:Connect(function()
		if not menuAlive then
			ghostHardCleanup()
			return
		end

		if not ghostIsActive() then return end

		local root = getHRP()
		local hum = getHumanoid()
		if not root or not hum then
			ghostHardCleanup()
			return
		end

		if flying then
			setFlying(false)
			if refreshAllButtons then refreshAllButtons() end
		end

		if ghostControllingGhost() then
			if ghostSafeBodyCF then
				root.CFrame = ghostSafeBodyCF
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end
			ghostSetCameraToGhost()
		elseif ghostControllingBody() then
			if ghostRoot and ghostRoot.Parent then
				ghostRoot.CFrame = root.CFrame
			end
			ghostSetCameraToBody()
		end
	end)

	ghostMoveConn = RunService.RenderStepped:Connect(function(dt)
		if not ghostControllingGhost() then
			ghostVelocity = Vector3.zero
			return
		end

		if typingInTextBox() then
			ghostVelocity = Vector3.zero
			return
		end

		if not ghostRoot or not ghostRoot.Parent then
			ghostVelocity = Vector3.zero
			return
		end

		local cam = workspace.CurrentCamera
		if not cam then
			ghostVelocity = Vector3.zero
			return
		end

		local targetDir = ghostGetInputDirection(cam)
		local targetVelocity = targetDir * ghostGetMoveSpeed()
		local lerpAlpha = math.clamp(dt * (targetDir.Magnitude > 0 and GHOST_ACCEL or GHOST_DECEL), 0, 1)

		ghostVelocity = ghostVelocity:Lerp(targetVelocity, lerpAlpha)
		ghostRoot.CFrame = ghostRoot.CFrame + (ghostVelocity * dt)
	end)
end

ghostSetState = function(newState)
	if newState == ghostState then return end

	local root = getHRP()
	local hum = getHumanoid()

	if newState == "OFF" then
		ghostHardCleanup()
		showToast("Ghost", "Ghost mode disabled.", THEME.SUBTEXT)
		return
	end

	if not root or not hum then
		ghostHardCleanup()
		return
	end

	if newState == "GHOST" then
		if ghostState == "OFF" then
			ghostSafeBodyCF = root.CFrame
			ghostCreateRig(root.CFrame)
			ghostSetBodyLocked(true)
			ghostState = "GHOST"
			ghostSetCameraToGhost()
			ghostStartLoops()
			showToast("Ghost", "Ghost mode enabled.", THEME.ACCENT)
			return
		end

		if ghostState == "BODY" then
			if not ghostSafeBodyCF then
				ghostSafeBodyCF = root.CFrame
			end

			ghostSetBodyLocked(true)
			root.CFrame = ghostSafeBodyCF
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			ghostState = "GHOST"
			ghostSetCameraToGhost()
			showToast("Ghost", "Returned to ghost camera.", THEME.ACCENT)
			return
		end
	end

	if newState == "BODY" then
		if ghostState ~= "GHOST" then return end
		if not ghostRoot or not ghostRoot.Parent then
			ghostHardCleanup()
			return
		end

		ghostSetBodyLocked(false)
		root.CFrame = ghostRoot.CFrame
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		ghostState = "BODY"
		ghostSetCameraToBody()
		showToast("Ghost", "Swapped to body control.", THEME.WARN)
	end
end

-- ===== SECTIONS =====
local movementSection = createSection("Movement", true)
local visualsSection = createSection("Visuals", true)
local speedSection = createSection("Speed", true)
local actionsSection = createSection("Actions", true)
local playersSection = createSection("Players", true)

makeSpacer(movementSection, 2)
makeSpacer(visualsSection, 2)
makeSpacer(speedSection, 2)
makeSpacer(actionsSection, 2)
makeSpacer(playersSection, 2)

-- ===== UI BUTTONS =====
local flyBtn = makeButton(movementSection, "Fly: OFF", 42)
local noclipBtn = makeButton(movementSection, "Noclip: OFF", 36)
local infJumpBtn = makeButton(movementSection, "Infinite Jump: OFF", 36)

local function makeGhostRow(parent, h)
	local outer = Instance.new("Frame")
	outer.Size = UDim2.new(1, 0, 0, h or 36)
	outer.BackgroundColor3 = THEME.BUTTON
	outer.BorderSizePixel = 0
	outer.ZIndex = 2
	outer.Parent = parent
	outer.ClipsDescendants = true
	Instance.new("UICorner", outer).CornerRadius = UDim.new(0, 10)

	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME.OUTLINE
	stroke.Thickness = 1
	stroke.Transparency = 0.25
	stroke.Parent = outer

	local left = Instance.new("TextButton")
	left.Name = "GhostSwitchArea"
	left.BackgroundTransparency = 1
	left.AutoButtonColor = false
	left.Selectable = false
	left.BorderSizePixel = 0
	left.ZIndex = 3
	left.Size = UDim2.new(0.72, 0, 1, 0)
	left.Position = UDim2.new(0, 0, 0, 0)
	left.Text = ""
	left.Parent = outer

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.TextColor3 = THEME.TEXT
	label.ZIndex = 4
	label.Size = UDim2.new(1, -86, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.Text = "Ghost Mode"
	label.Parent = left

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Size = UDim2.new(0, 46, 0, 22)
	track.Position = UDim2.new(1, -74, 0.5, -11)
	track.BorderSizePixel = 0
	track.ZIndex = 4
	track.Parent = left
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

	local thumb = Instance.new("Frame")
	thumb.Name = "Thumb"
	thumb.Size = UDim2.new(0, 18, 0, 18)
	thumb.Position = UDim2.new(0, 2, 0.5, -9)
	thumb.BorderSizePixel = 0
	thumb.ZIndex = 5
	thumb.Parent = track
	Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

	local divider = Instance.new("Frame")
	divider.BackgroundColor3 = THEME.OUTLINE
	divider.BorderSizePixel = 0
	divider.ZIndex = 3
	divider.Size = UDim2.new(0, 1, 0.70, 0)
	divider.Position = UDim2.new(0.72, 0, 0.15, 0)
	divider.Parent = outer

	local right = Instance.new("TextButton")
	right.Name = "SwapBtn"
	right.AutoButtonColor = false
	right.Selectable = false
	right.BorderSizePixel = 0
	right.ZIndex = 4
	right.Size = UDim2.new(0.28, -14, 1, -10)
	right.Position = UDim2.new(0.72, 7, 0, 5)
	right.Font = Enum.Font.GothamBold
	right.TextSize = 14
	right.Text = "SWAP"
	right.Parent = outer
	Instance.new("UICorner", right).CornerRadius = UDim.new(0, 8)

	local swapStroke = Instance.new("UIStroke")
	swapStroke.Color = THEME.OUTLINE
	swapStroke.Thickness = 1
	swapStroke.Transparency = 0.35
	swapStroke.Parent = right

	return outer, left, label, track, thumb, right
end

local ghostOuter, ghostLeftArea, ghostLabel, ghostTrack, ghostThumb, swapBtn = makeGhostRow(movementSection, 36)

local espBtn = makeButton(visualsSection, "ESP: OFF", 36)
local espModeBtn = makeButton(visualsSection, "ESP Mode: ENEMIES", 36)
local notifBtn = makeButton(visualsSection, "Notifications: ON", 36)

updateESPButtons = function()
	setToggleButton(espBtn, espEnabled, "ESP: ON", "ESP: OFF")
	espModeBtn.Text = "ESP Mode: " .. espMode
end

local modes = {"ENEMIES", "ALL", "TEAM"}
local modeIndex = 1

refreshGhostUI = function()
	local on = ghostState ~= "OFF"

	if ghostState == "OFF" then
		ghostLabel.Text = "Ghost Mode: OFF"
	elseif ghostState == "GHOST" then
		ghostLabel.Text = "Ghost Mode: GHOST"
	else
		ghostLabel.Text = "Ghost Mode: BODY"
	end

	ghostTrack.BackgroundColor3 = on and THEME.BUTTON_ACTIVE or THEME.PANEL
	ghostThumb.BackgroundColor3 = on and THEME.TEXT or THEME.SUBTEXT
	ghostThumb.Position = on and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)

	swapBtn.BackgroundColor3 = on and THEME.BUTTON or THEME.PANEL
	swapBtn.TextColor3 = on and THEME.TEXT or THEME.SUBTEXT
	swapBtn.Text = (ghostState == "BODY") and "RETURN" or "SWAP"
end

-- ===== SPEED UI =====
makeLabel(speedSection, "Fly Speed", THEME.SUBTEXT, 20, 14)
local currentSpeedLabel = makeLabel(speedSection, "Current Speed: " .. speed, THEME.ACCENT)

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(1, 0, 0, 32)
speedBox.BackgroundColor3 = THEME.PANEL
speedBox.TextColor3 = THEME.TEXT
speedBox.Font = Enum.Font.Gotham
speedBox.TextSize = 14
speedBox.Text = tostring(speed)
speedBox.BorderSizePixel = 0
speedBox.ZIndex = 2
speedBox.ClearTextOnFocus = false
speedBox.Parent = speedSection
Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0, 8)

local slider = Instance.new("Frame")
slider.Size = UDim2.new(1, 0, 0, 10)
slider.BackgroundColor3 = THEME.PANEL
slider.BorderSizePixel = 0
slider.ZIndex = 2
slider.Parent = speedSection
Instance.new("UICorner", slider).CornerRadius = UDim.new(1, 0)

local fill = Instance.new("Frame")
fill.BackgroundColor3 = THEME.ACCENT
fill.Size = UDim2.new(speed / MAX_SPEED, 0, 1, 0)
fill.BorderSizePixel = 0
fill.ZIndex = 3
fill.Parent = slider
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

local draggingSpeed = false
local function setSpeed(v)
	speed = math.clamp(math.floor(v), MIN_SPEED, MAX_SPEED)
	speedBox.Text = tostring(speed)
	fill.Size = UDim2.new(speed / MAX_SPEED, 0, 1, 0)
	currentSpeedLabel.Text = "Current Speed: " .. speed
end

slider.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSpeed = true
	end
end)

slider.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSpeed = false
	end
end)

makeSpacer(speedSection, 4)
makeLabel(speedSection, "Walk Speed", THEME.SUBTEXT, 20, 14)
local currentWalkLabel = makeLabel(speedSection, "Current Walk Speed: " .. walkSpeed, THEME.ACCENT)

local walkBox = Instance.new("TextBox")
walkBox.Size = UDim2.new(1, 0, 0, 32)
walkBox.BackgroundColor3 = THEME.PANEL
walkBox.TextColor3 = THEME.TEXT
walkBox.Font = Enum.Font.Gotham
walkBox.TextSize = 14
walkBox.Text = tostring(walkSpeed)
walkBox.BorderSizePixel = 0
walkBox.ZIndex = 2
walkBox.ClearTextOnFocus = false
walkBox.Parent = speedSection
Instance.new("UICorner", walkBox).CornerRadius = UDim.new(0, 8)

local walkSlider = Instance.new("Frame")
walkSlider.Size = UDim2.new(1, 0, 0, 10)
walkSlider.BackgroundColor3 = THEME.PANEL
walkSlider.BorderSizePixel = 0
walkSlider.ZIndex = 2
walkSlider.Parent = speedSection
Instance.new("UICorner", walkSlider).CornerRadius = UDim.new(1, 0)

local walkFill = Instance.new("Frame")
walkFill.BackgroundColor3 = THEME.ACCENT
walkFill.Size = UDim2.new((walkSpeed - WALK_MIN) / (WALK_MAX - WALK_MIN), 0, 1, 0)
walkFill.BorderSizePixel = 0
walkFill.ZIndex = 3
walkFill.Parent = walkSlider
Instance.new("UICorner", walkFill).CornerRadius = UDim.new(1, 0)

local draggingWalk = false
local function setWalkSpeed(v)
	walkSpeed = math.clamp(math.floor(v), WALK_MIN, WALK_MAX)
	walkBox.Text = tostring(walkSpeed)
	walkFill.Size = UDim2.new((walkSpeed - WALK_MIN) / (WALK_MAX - WALK_MIN), 0, 1, 0)
	currentWalkLabel.Text = "Current Walk Speed: " .. walkSpeed
	applyWalkSpeed()
end

walkSlider.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingWalk = true
	end
end)

walkSlider.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingWalk = false
	end
end)

-- ===== ACTIONS =====
local teleportBtn = makeButton(actionsSection, "Teleport")
local bringBtn = makeButton(actionsSection, "Bring")
local stopBtn = makeButton(actionsSection, "Stop Bringing")
local bringAllBtn = makeButton(actionsSection, "Bring ALL")
local teleportToolBtn = makeButton(actionsSection, "Give Teleport Tool")

local action = "TELEPORT"
local function refreshActionButtons()
	teleportBtn.BackgroundColor3 = action == "TELEPORT" and THEME.BUTTON_ACTIVE or THEME.BUTTON
	bringBtn.BackgroundColor3 = action == "BRING" and THEME.BUTTON_ACTIVE or THEME.BUTTON
end
refreshActionButtons()

bringStatusLabel = makeLabel(actionsSection, "Bringing: None", THEME.ACCENT)

-- ===== PLAYERS =====
local playerSearchBox = Instance.new("TextBox")
playerSearchBox.Size = UDim2.new(1, 0, 0, 32)
playerSearchBox.BackgroundColor3 = THEME.PANEL
playerSearchBox.TextColor3 = THEME.TEXT
playerSearchBox.Font = Enum.Font.Gotham
playerSearchBox.TextSize = 14
playerSearchBox.PlaceholderText = "Search player..."
playerSearchBox.Text = ""
playerSearchBox.BorderSizePixel = 0
playerSearchBox.ZIndex = 2
playerSearchBox.ClearTextOnFocus = false
playerSearchBox.Parent = playersSection
Instance.new("UICorner", playerSearchBox).CornerRadius = UDim.new(0, 8)

local list = Instance.new("Frame")
list.Size = UDim2.new(1, 0, 0, 10)
list.BackgroundColor3 = THEME.PANEL
list.BorderSizePixel = 0
list.Parent = playersSection
Instance.new("UICorner", list).CornerRadius = UDim.new(0, 10)

local listPad = Instance.new("UIPadding")
listPad.PaddingTop = UDim.new(0, 8)
listPad.PaddingBottom = UDim.new(0, 8)
listPad.PaddingLeft = UDim.new(0, 8)
listPad.PaddingRight = UDim.new(0, 8)
listPad.Parent = list

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

rebuildList = function()
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player and matchesSearch(plr.Name, playerSearchText) then
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1, 0, 0, 34)
			b.Text = plr.Name
			b.Font = Enum.Font.Gotham
			b.TextSize = 14
			b.TextColor3 = THEME.TEXT
			b.BackgroundColor3 = bringingTargets[plr] and THEME.BUTTON_ACTIVE or THEME.BUTTON
			b.BorderSizePixel = 0
			b.ZIndex = 3
			b.Parent = list
			Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)

			b.MouseButton1Click:Connect(function()
				if action == "TELEPORT" then
					teleportToPlayer(plr)
				else
					toggleBringing(plr)
					rebuildList()
				end
			end)
		end
	end

	task.defer(function()
		if list and list.Parent then
			list.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 16)
		end
	end)
end

-- ===== STATUS / REFRESH =====
refreshStatusLine = function()
	local active = {}

	if flying then table.insert(active, "Fly") end
	if noclip then table.insert(active, "Noclip") end
	if infJump then table.insert(active, "InfJump") end
	if espEnabled then table.insert(active, "ESP:" .. espMode) end
	if ghostState ~= "OFF" then table.insert(active, "Ghost:" .. ghostState) end
	if next(bringingTargets) then table.insert(active, "Bring") end

	statusLine.Text = (#active == 0) and "Active: None" or ("Active: " .. table.concat(active, "  |  "))
end

refreshAllButtons = function()
	setToggleButton(flyBtn, flying, "Fly: ON", "Fly: OFF")
	setToggleButton(noclipBtn, noclip, "Noclip: ON", "Noclip: OFF")
	setToggleButton(infJumpBtn, infJump, "Infinite Jump: ON", "Infinite Jump: OFF")
	setToggleButton(notifBtn, notificationsEnabled, "Notifications: ON", "Notifications: OFF")
	updateESPButtons()
	refreshGhostUI()
	refreshActionButtons()
	updateBringStatus()
	refreshStatusLine()
end

-- ===== CLEANUP / SHUTDOWN =====
local function stopAllFeatures()
	setFlying(false)
	setNoclip(false)
	infJump = false
	stopBringingAll()
	ghostSetState("OFF")
end

local function hardShutdown()
	if shuttingDown then return end
	shuttingDown = true
	menuAlive = false

	local hum = getHumanoid()
	if humWalkConn then
		humWalkConn:Disconnect()
		humWalkConn = nil
	end

	if hum then
		hum.WalkSpeed = spawnWalkSpeed or 16
	end

	walkSpeed = spawnWalkSpeed or 16

	stopAllFeatures()
	setESPEnabled(false)
	cleanupFly()

	for plr in pairs(espPlayerHooks) do
		unhookESPPlayer(plr)
	end

	if characterAddedConn then
		characterAddedConn:Disconnect()
		characterAddedConn = nil
	end
	if playersAddedConn then
		playersAddedConn:Disconnect()
		playersAddedConn = nil
	end
	if playersRemovingConn then
		playersRemovingConn:Disconnect()
		playersRemovingConn = nil
	end
	if playerTeamConn then
		playerTeamConn:Disconnect()
		playerTeamConn = nil
	end
	if playerNeutralConn then
		playerNeutralConn:Disconnect()
		playerNeutralConn = nil
	end

	if window and window.Parent then
		window.Visible = false
		window:Destroy()
	end

	if toastAnchor and toastAnchor.Parent then
		toastAnchor:Destroy()
	end

	if gui and gui.Parent then
		gui:Destroy()
	end
end

closeBtn.MouseButton1Click:Connect(hardShutdown)

-- ===== BUTTON ACTIONS =====
flyBtn.MouseButton1Click:Connect(function()
	setFlying(not flying)
	refreshAllButtons()
	showToast("Fly", flying and "Fly enabled." or "Fly disabled.", flying and THEME.ACCENT or THEME.SUBTEXT)
end)

noclipBtn.MouseButton1Click:Connect(function()
	setNoclip(not noclip)
	refreshAllButtons()
	showToast("Noclip", noclip and "Noclip enabled." or "Noclip disabled.", noclip and THEME.ACCENT or THEME.SUBTEXT)
end)

infJumpBtn.MouseButton1Click:Connect(function()
	infJump = not infJump
	refreshAllButtons()
	showToast("Infinite Jump", infJump and "Infinite Jump enabled." or "Infinite Jump disabled.", infJump and THEME.ACCENT or THEME.SUBTEXT)
end)

espBtn.MouseButton1Click:Connect(function()
	setESPEnabled(not espEnabled)
	updateESPButtons()
	refreshStatusLine()
	showToast("ESP", espEnabled and "ESP enabled." or "ESP disabled.", espEnabled and THEME.ACCENT or THEME.SUBTEXT)
end)

espModeBtn.MouseButton1Click:Connect(function()
	modeIndex += 1
	if modeIndex > #modes then modeIndex = 1 end
	setESPMode(modes[modeIndex])
	updateESPButtons()
	refreshStatusLine()
	showToast("ESP", "Mode: " .. espMode, THEME.WARN)
end)

notifBtn.MouseButton1Click:Connect(function()
	local wasEnabled = notificationsEnabled
	notificationsEnabled = not notificationsEnabled
	refreshAllButtons()

	if wasEnabled and not notificationsEnabled then
		toastAnchor.Visible = false
	elseif notificationsEnabled then
		showToast("Notifications", "Notifications enabled.", THEME.ACCENT)
	end
end)

ghostLeftArea.MouseButton1Click:Connect(function()
	if ghostState == "OFF" then
		ghostSetState("GHOST")
	else
		ghostSetState("OFF")
	end
	refreshAllButtons()
end)

swapBtn.MouseButton1Click:Connect(function()
	if ghostState == "GHOST" then
		ghostSetState("BODY")
	elseif ghostState == "BODY" then
		ghostSetState("GHOST")
	end
	refreshAllButtons()
end)

teleportToolBtn.MouseButton1Click:Connect(giveTeleportTool)

teleportBtn.MouseButton1Click:Connect(function()
	action = "TELEPORT"
	refreshActionButtons()
	showToast("Action", "Teleport selected.", THEME.ACCENT)
end)

bringBtn.MouseButton1Click:Connect(function()
	action = "BRING"
	refreshActionButtons()
	showToast("Action", "Bring selected.", THEME.WARN)
end)

stopBtn.MouseButton1Click:Connect(function()
	stopBringingAll()
	refreshAllButtons()
	rebuildList()
	showToast("Bring", "Stopped bringing all players.", THEME.SUBTEXT)
end)

bringAllBtn.MouseButton1Click:Connect(function()
	bringAllPlayers()
	refreshAllButtons()
	rebuildList()
	showToast("Bring", "Bringing all players.", THEME.ACCENT)
end)

speedBox.FocusLost:Connect(function()
	local n = tonumber(speedBox.Text)
	if n then
		setSpeed(n)
		showToast("Speed", "Fly/Ghost speed set to " .. speed, THEME.ACCENT)
	else
		speedBox.Text = tostring(speed)
	end
end)

walkBox.FocusLost:Connect(function()
	local n = tonumber(walkBox.Text)
	if n then
		setWalkSpeed(n)
		showToast("Walk Speed", "Walk speed set to " .. walkSpeed, THEME.ACCENT)
	else
		walkBox.Text = tostring(walkSpeed)
	end
end)

playerSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	playerSearchText = playerSearchBox.Text or ""
	rebuildList()
end)

local function setupCharacter(char)
	if not menuAlive then return end

	character = char
	humanoid = char:WaitForChild("Humanoid", 10)
	hrp = char:WaitForChild("HumanoidRootPart", 10)

	if humWalkConn then
		humWalkConn:Disconnect()
		humWalkConn = nil
	end

	local hum = getHumanoid()
	if hum then
		spawnWalkSpeed = hum.WalkSpeed

		humWalkConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			if menuAlive and hum.WalkSpeed ~= walkSpeed then
				hum.WalkSpeed = walkSpeed
			end
		end)
	end

	setupFlyForCharacter()
	applyWalkSpeed()
	hookCharacterTools(char)

	if noclip then
		task.defer(function()
			if menuAlive then
				table.clear(savedCollide)
				applyNoCollide()
			end
		end)
	end

	if ghostState ~= "OFF" then
		task.defer(function()
			if menuAlive then
				ghostHardCleanup()
				ghostSetState("GHOST")
				refreshAllButtons()
			end
		end)
	else
		task.defer(function()
			if menuAlive then
				ghostSetCameraToBody()
			end
		end)
	end
end

if player.Character then
	local ok, err = xpcall(function()
		debugStage("setupCharacter initial")
		setupCharacter(player.Character)
	end, debug.traceback)

	if not ok then
		debugError("setupCharacter initial", err)
	end
end

characterAddedConn = player.CharacterAdded:Connect(function(char)
	local ok, err = xpcall(function()
		debugStage("setupCharacter CharacterAdded")
		setupCharacter(char)
	end, debug.traceback)

	if not ok then
		debugError("setupCharacter CharacterAdded", err)
	end
end)

for _, plr in ipairs(Players:GetPlayers()) do
	if plr ~= player then
		local ok, err = xpcall(function()
			debugStage("hookESPPlayer " .. plr.Name)
			hookESPPlayer(plr)
		end, debug.traceback)

		if not ok then
			debugError("hookESPPlayer " .. plr.Name, err)
		end
	end
end

playersAddedConn = Players.PlayerAdded:Connect(function(plr)
	hookESPPlayer(plr)
	if window.Visible then
		rebuildList()
	end
end)

playersRemovingConn = Players.PlayerRemoving:Connect(function(plr)
	unhookESPPlayer(plr)

	if bringingTargets[plr] then
		bringingTargets[plr] = nil
		updateBringStatus()
	end

	if window.Visible then
		rebuildList()
	end
	refreshStatusLine()
end)

playerTeamConn = player:GetPropertyChangedSignal("Team"):Connect(function()
	if espEnabled then refreshAllESP() end
end)

playerNeutralConn = player:GetPropertyChangedSignal("Neutral"):Connect(function()
	if espEnabled then refreshAllESP() end
end)

-- ===== INPUT =====
UserInputService.InputBegan:Connect(function(i, gp)
	if not menuAlive then return end
	if gp then return end

	if typingInTextBox() and i.KeyCode ~= OPEN_KEY then
		return
	end

			if i.KeyCode == OPEN_KEY then
		toggleWindow()
		return
	end

	if i.KeyCode == FLY_KEY then
		if ghostState == "OFF" then
			setFlying(not flying)
			refreshAllButtons()
			showToast("Fly", flying and "Fly enabled." or "Fly disabled.", flying and THEME.ACCENT or THEME.SUBTEXT)
		end
		return
	end

	if i.KeyCode == Enum.KeyCode.N then
		setNoclip(not noclip)
		refreshAllButtons()
		showToast("Noclip", noclip and "Noclip enabled." or "Noclip disabled.", noclip and THEME.ACCENT or THEME.SUBTEXT)
		return
	end

	if i.KeyCode == Enum.KeyCode.J then
		if ghostState ~= "GHOST" then
			infJump = not infJump
			refreshAllButtons()
			showToast("Infinite Jump", infJump and "Infinite Jump enabled." or "Infinite Jump disabled.", infJump and THEME.ACCENT or THEME.SUBTEXT)
		end
		return
	end
end)

UserInputService.InputChanged:Connect(function(i)
	if draggingSpeed and i.UserInputType == Enum.UserInputType.MouseMovement then
		local a = math.clamp((i.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
		setSpeed(MIN_SPEED + a * (MAX_SPEED - MIN_SPEED))
	end

	if draggingWalk and i.UserInputType == Enum.UserInputType.MouseMovement then
		local a = math.clamp((i.Position.X - walkSlider.AbsolutePosition.X) / walkSlider.AbsoluteSize.X, 0, 1)
		setWalkSpeed(WALK_MIN + a * (WALK_MAX - WALK_MIN))
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSpeed = false
		draggingWalk = false
	end

	if input.KeyCode == Enum.KeyCode.Space then
		infArmed = true
	end
end)

UserInputService.JumpRequest:Connect(function()
	if not infJump then return end
	if ghostState == "GHOST" then return end
	if not infArmed then return end
	infArmed = false

	local now = os.clock()
	if now - infLast < INF_COOLDOWN then return end
	infLast = now

	local root = getHRP()
	if not root then return end

	local v = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(v.X, INF_IMPULSE, v.Z)

	task.delay(0.12, function()
		infArmed = true
	end)
end)

-- ===== FLY LOOP =====
RunService.RenderStepped:Connect(function()
	if not menuAlive then return end

	if typingInTextBox() then
		if flying and flyVelocity then
			flyVelocity.VectorVelocity = Vector3.zero
		end
		return
	end

	if ghostState ~= "OFF" then
		if flying and flyVelocity then
			flyVelocity.VectorVelocity = Vector3.zero
		end
		return
	end

	local root = getHRP()
	if not flying or not root or not flyVelocity or not flyOrientation then return end

	local cam = workspace.CurrentCamera
	local dir = Vector3.zero

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then dir -= Vector3.yAxis end

	if dir.Magnitude > 0 then
		dir = dir.Unit
	end

	flyVelocity.VectorVelocity = dir * speed
	flyOrientation.CFrame = cam.CFrame
end)

-- ===== DRAG WINDOW =====
do
	local dragging = false
	local dragStart
	local startPos

	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = window.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			window.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
end

-- ===== INITIAL UI STATE =====
local ok1, err1 = xpcall(function()
	debugStage("refreshAllButtons")
	refreshAllButtons()
end, debug.traceback)

if not ok1 then
	debugError("refreshAllButtons", err1)
end

local ok2, err2 = xpcall(function()
	debugStage("rebuildList")
	rebuildList()
end, debug.traceback)

if not ok2 then
	debugError("rebuildList", err2)
end

debugStage("input ready")