-- r0onk's Fish Mutation ESP (LOCK LAST VALID / EVENT-DRIVEN / REBIND SAFE) - OPTIMIZED FULL COPY/PASTE
-- For your own game/admin debugging.
-- Y = Open / Close UI
-- U = Toggle ESP ON/OFF
-- Click mutation tiles to enable/disable per mutation

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local function typingInTextBox()
	return UserInputService:GetFocusedTextBox() ~= nil
end

-- ===== THEME (darker lilac) =====
local THEME = {
	BG = Color3.fromRGB(36, 34, 46),
	PANEL = Color3.fromRGB(48, 44, 62),
	BUTTON = Color3.fromRGB(58, 54, 76),
	BUTTON_ACTIVE = Color3.fromRGB(142, 96, 255),
	TEXT = Color3.fromRGB(240,240,245),
	SUBTEXT = Color3.fromRGB(185,185,200),
	ACCENT = Color3.fromRGB(175, 135, 255),
	OUTLINE = Color3.fromRGB(92, 86, 116)
}

-- ===== KEYS =====
local OPEN_KEY = Enum.KeyCode.Y
local TOGGLE_KEY = Enum.KeyCode.U

-- ===== PATH =====
local fishClient = workspace:WaitForChild("Game"):WaitForChild("Fish"):WaitForChild("client")

-- ===== Highlight behavior =====
local ALWAYS_ON_TOP = true

-- smoothness settings
local HIDE_GRACE = 0.60
local FADE_TWEEN = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- tag sizing
local TAG_SIZE_PIXELS = 32
local TAG_MAX_DISTANCE = 800

-- shadow eyes sizing
local EYES_W = 26
local EYES_H = 12
local EYES_MAX_DISTANCE = 300

local DEFAULT_FILL_T = 0.85
local DEFAULT_OUTLINE_T = 0.0

local INVISIBLE_FILL_T = 0.90
local INVISIBLE_OUTLINE_T = 0.35

local TRANSPARENT_FILL_T = 0.92
local TRANSPARENT_OUTLINE_T = 0.25

-- ===== SELF-HEAL SETTINGS =====
local SELF_HEAL_INTERVAL = 0.25

-- ===== LOCK LAST VALID =====
local LOCK_LAST_VALID = true

-- ===== multipliers (rarity intensity) =====
local MULT = {
	Abyssal=8.5, Albino=1.3, Angelic=7.77, Banana=1.5, Cactus=1.45, Coral=1.3,
	Fairy=2.3, Fossil=1.75, Golden=2.0, Grounded=2.8, Invisible=2.4, Jade=4.0,
	Liquid=2.5, Metal=1.2, Moss=1.1, Negative=2.0, Neon=2.8, Poop=0.333,
	Rock=1.0,
	Rooted=4.2, Sand=1.25, Shadow=8.06, Spirit=1.7, Toxic=3.75, Transparent=1.35,
	Ultraviolet=3.6,
}

-- ===== mutation styles =====
local STYLE = {
	Abyssal     = { fill = Color3.fromRGB(10, 25, 70),    outline = Color3.fromRGB(5, 12, 40) },
	Albino      = { fill = Color3.fromRGB(255,255,255),   outline = Color3.fromRGB(255,255,255), fillT = 0.20 },
	Angelic     = { fill = Color3.fromRGB(255,245,170),   outline = Color3.fromRGB(210,190,85) },
	Banana      = { fill = Color3.fromRGB(255,225,40),    outline = Color3.fromRGB(165,125,35) },
	Cactus      = { fill = Color3.fromRGB(35,120,55),     outline = Color3.fromRGB(95,85,45) },
	Coral       = { fill = Color3.fromRGB(140,225,255),   outline = Color3.fromRGB(255,120,160) },
	Fairy       = { fill = Color3.fromRGB(255,150,230),   outline = Color3.fromRGB(190,60,150) },
	Fossil      = { fill = Color3.fromRGB(165,155,135),   outline = Color3.fromRGB(85,75,60) },
	Golden      = { fill = Color3.fromRGB(210,170,35),    outline = Color3.fromRGB(255,130,40) },
	Grounded    = { fill = Color3.fromRGB(120,120,120),   outline = Color3.fromRGB(25,25,25) },
	Invisible   = { fill = Color3.fromRGB(190,205,220),   outline = Color3.fromRGB(35,35,35), fillT = INVISIBLE_FILL_T, outlineT = INVISIBLE_OUTLINE_T },
	Jade        = { fill = Color3.fromRGB(20,110,60),     outline = Color3.fromRGB(130,255,160) },
	Liquid      = { fill = Color3.fromRGB(70,180,255),    outline = Color3.fromRGB(20,90,170) },
	Metal       = { fill = Color3.fromRGB(205,205,205),   outline = Color3.fromRGB(65,65,65) },
	Moss        = { fill = Color3.fromRGB(80,80,80),      outline = Color3.fromRGB(70,200,110) },
	Negative    = { fill = Color3.fromRGB(45,45,45),      outline = Color3.fromRGB(12,12,12) },
	Neon        = { fill = Color3.fromRGB(60,255,235),    outline = Color3.fromRGB(255,255,255) },
	Poop        = { fill = Color3.fromRGB(120,80,45),     outline = Color3.fromRGB(120,80,45) },
	Rock        = { fill = Color3.fromRGB(125, 120, 110), outline = Color3.fromRGB(50, 50, 50) },
	Rooted      = { fill = Color3.fromRGB(20,85,95),      outline = Color3.fromRGB(10,45,55) },
	Sand        = { fill = Color3.fromRGB(230,205,155),   outline = Color3.fromRGB(160,135,95) },
	Shadow      = { fill = Color3.fromRGB(18,18,18),      outline = Color3.fromRGB(10,10,10), eyes = true },
	Spirit      = { fill = Color3.fromRGB(0,255,200),     outline = Color3.fromRGB(0,255,200), fillT = 0.92, outlineT = 0.10 },
	Toxic       = { fill = Color3.fromRGB(150,255,60),    outline = Color3.fromRGB(55,120,20) },
	Transparent = { fill = Color3.fromRGB(210,230,255),   outline = Color3.fromRGB(120,170,210), fillT = TRANSPARENT_FILL_T, outlineT = TRANSPARENT_OUTLINE_T },
	Ultraviolet = { fill = Color3.fromRGB(120, 60, 255),  outline = Color3.fromRGB(210,170,255), fillT = 0.82, outlineT = 0.05 },
}

local ORDER = {
	"Abyssal","Albino","Angelic","Banana","Cactus","Coral",
	"Fairy","Fossil","Golden","Grounded","Invisible","Jade",
	"Liquid","Metal","Moss","Negative","Neon","Poop","Rock",
	"Rooted","Sand","Shadow","Spirit","Toxic","Transparent","Ultraviolet"
}

local DISPLAY = {
	Transparent = "Transparent",
	Ultraviolet = "Ultraviolet",
	Grounded = "Grounded",
	Invisible = "Invisible",
}

-- ===== helpers =====
local function clamp(x,a,b) if x<a then return a elseif x>b then return b else return x end end
local function isAlive(inst) return inst and inst.Parent ~= nil end

local function applyRarity(mutation, fillT, outlineT)
	local m = MULT[mutation] or 1
	local r = clamp((m - 1) / 8, 0, 1)
	local newFillT = fillT - (r * 0.18)
	local newOutlineT = outlineT + (0 - outlineT) * (0.6 + 0.4 * r)
	return clamp(newFillT, 0.12, 0.95), clamp(newOutlineT, 0, 0.6)
end

local function tweenObj(obj, props)
	if not obj then return end
	local ok, tw = pcall(function()
		return TweenService:Create(obj, FADE_TWEEN, props)
	end)
	if ok and tw then tw:Play() end
end

local function normalizeMutationText(t)
	if type(t) ~= "string" then return nil end
	t = t:gsub("%c", "")
	t = t:gsub("^%s+", ""):gsub("%s+$", "")
	t = t:gsub("%s+", " ")
	t = t:gsub("%b()", "")
	t = t:gsub("%b[]", "")
	t = t:gsub("[^%a]", "")
	t = t:lower()
	if t == "" then return nil end

	if t == "uv" or t == "ultra" or t == "ultraviolet" or t:find("ultra") or t:find("violet") then
		return "Ultraviolet"
	end
	if t:find("trans") then return "Transparent" end
	if t:find("invis") then return "Invisible" end
	if t:find("spirit") then return "Spirit" end
	if t:find("shadow") then return "Shadow" end

	return t:sub(1,1):upper() .. t:sub(2)
end

local function getAnchorPart(fishModel)
	if not fishModel then return nil end
	local hrp = fishModel:FindFirstChild("HumanoidRootPart", true)
	if hrp and hrp:IsA("BasePart") then return hrp end
	local root = fishModel:FindFirstChild("RootPart", true)
	if root and root:IsA("BasePart") then return root end
	if fishModel.PrimaryPart and fishModel.PrimaryPart:IsA("BasePart") then return fishModel.PrimaryPart end
	local head = fishModel:FindFirstChild("Head", true)
	if head and head:IsA("BasePart") then return head end
	return fishModel:FindFirstChildWhichIsA("BasePart", true)
end

local function isMutationLabel(inst)
	return inst
		and inst:IsA("TextLabel")
		and inst.Name == "Label"
		and inst.Parent
		and inst.Parent.Name == "Mutation"
end

-- ===== Workspace Mutation Scan (BUTTON FEATURE) =====
local function scanWorkspaceForMutations(onProgress)
	local counts = {}
	local all = workspace:GetDescendants()
	local total = #all

	-- tweak: bigger = faster but more hitch, smaller = smoother but slower
	local YIELD_EVERY = 2500
	local lastYield = 0

	for i = 1, total do
		local inst = all[i]

		-- fast filter: only Label TextLabels under Mutation
		if inst:IsA("TextLabel") and inst.Name == "Label" then
			local p = inst.Parent
			if p and p.Name == "Mutation" then
				local mut = normalizeMutationText(inst.Text)
				if mut and STYLE[mut] then
					counts[mut] = (counts[mut] or 0) + 1
				end
			end
		end

		if onProgress and (i % 1000 == 0 or i == total) then
			onProgress(i, total)
		end

		if i - lastYield >= YIELD_EVERY then
			lastYield = i
			RunService.Heartbeat:Wait()
		end
	end

	return counts, total
end

-- ===== state =====
do
	local pg = player:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild("r0onk_FishMutationESP_GUI")
	if old then pcall(function() old:Destroy() end) end
end

local gui = Instance.new("ScreenGui")
gui.Name = "r0onk_FishMutationESP_GUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local menuAlive = true
local espOn = false
local enabledByMutation = {}
for k in pairs(STYLE) do enabledByMutation[k] = true end

local tracked = {} -- [fishModel] = data

-- ===== incremental caches (no repeated GetDescendants scans) =====
local function addPartToCache(m, part)
	if not part or not part:IsA("BasePart") then return end
	if m.partCache[part] == nil then
		m.partCache[part] = part.Transparency
	end
end

local function addForeignHL(m, hl)
	if not hl or not hl:IsA("Highlight") then return end
	if hl.Name == "FishMutationESP" then return end
	m.foreignHL[hl] = m.foreignHL[hl] or hl.Enabled
	if espOn then hl.Enabled = false end
end

local function restoreForeignHL(m)
	for hl, old in pairs(m.foreignHL) do
		if hl and hl.Parent and hl:IsA("Highlight") then
			hl.Enabled = old
		else
			m.foreignHL[hl] = nil
		end
	end
end

-- ===== MODEL VISIBILITY OVERRIDE (if game fades parts) =====
local function restoreFishPartsIfNeeded(fishModel)
	local m = tracked[fishModel]
	if not m then return end

	local render = m.lastMutation
	local shouldRender = espOn and render and STYLE[render] and enabledByMutation[render]
	if not shouldRender then return end

	for part, baseT in pairs(m.partCache) do
		if part and part.Parent and part:IsA("BasePart") then
			if part.LocalTransparencyModifier ~= 0 then
				part.LocalTransparencyModifier = 0
			end
			if part.Transparency ~= baseT then
				part.Transparency = baseT
			end
		else
			m.partCache[part] = nil
		end
	end
end

-- ===== eyes =====
local function destroyEyes(fishModel)
	local m = tracked[fishModel]
	if not m then return end
	if m.eyes then pcall(function() m.eyes:Destroy() end) end
	m.eyes = nil
end

local function ensureEyes(fishModel)
	local m = tracked[fishModel]
	if not m then return end
	if m.eyes and isAlive(m.eyes) then return end
	if m.eyes and (not isAlive(m.eyes)) then pcall(function() m.eyes:Destroy() end) m.eyes = nil end

	local anchor = getAnchorPart(fishModel)
	if not anchor then return end

	local bb = Instance.new("BillboardGui")
	bb.Name = "ShadowEyes"
	bb.Adornee = anchor
	bb.Size = UDim2.new(0, EYES_W, 0, EYES_H)
	bb.StudsOffset = Vector3.new(0, 1.05, 0)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = EYES_MAX_DISTANCE
	bb.Parent = gui

	local l = Instance.new("Frame", bb)
	l.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
	l.BorderSizePixel = 0
	l.Size = UDim2.new(0, math.floor(EYES_W * 0.33), 0, math.floor(EYES_H * 0.45))
	l.Position = UDim2.new(0, math.floor(EYES_W * 0.18), 0, math.floor(EYES_H * 0.27))
	Instance.new("UICorner", l).CornerRadius = UDim.new(1, 0)

	local r = Instance.new("Frame", bb)
	r.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
	r.BorderSizePixel = 0
	r.Size = UDim2.new(0, math.floor(EYES_W * 0.33), 0, math.floor(EYES_H * 0.45))
	r.Position = UDim2.new(0, math.floor(EYES_W * 0.55), 0, math.floor(EYES_H * 0.27))
	Instance.new("UICorner", r).CornerRadius = UDim.new(1, 0)

	l.BackgroundTransparency = 1
	r.BackgroundTransparency = 1
	tweenObj(l, { BackgroundTransparency = 0 })
	tweenObj(r, { BackgroundTransparency = 0 })

	m.eyes = bb
end

-- ===== tag =====
local function destroyTag(fishModel)
	local m = tracked[fishModel]
	if not m then return end
	if m.tag then pcall(function() m.tag:Destroy() end) end
	m.tag = nil
end

local function ensureTag(fishModel, letter, color)
	local m = tracked[fishModel]
	if not m then return end

	if m.tag and isAlive(m.tag) then
		local txt = m.tag:FindFirstChild("Letter")
		local glow = m.tag:FindFirstChild("Glow")
		if txt and txt:IsA("TextLabel") then
			txt.Text = letter
			txt.TextColor3 = color
			txt.TextStrokeColor3 = color
		end
		if glow and glow:IsA("TextLabel") then
			glow.Text = letter
			glow.TextColor3 = color
		end
		return
	end

	if m.tag and (not isAlive(m.tag)) then pcall(function() m.tag:Destroy() end) m.tag = nil end

	local anchor = getAnchorPart(fishModel)
	if not anchor then return end

	local bb = Instance.new("BillboardGui")
	bb.Name = "FishStateTag"
	bb.Adornee = anchor
	bb.Size = UDim2.new(0, TAG_SIZE_PIXELS, 0, TAG_SIZE_PIXELS)
	bb.StudsOffset = Vector3.new(0, 1.85, 0)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = TAG_MAX_DISTANCE
	bb.Parent = gui

	local txt = Instance.new("TextLabel")
	txt.Name = "Letter"
	txt.BackgroundTransparency = 1
	txt.Size = UDim2.new(1, 0, 1, 0)
	txt.Font = Enum.Font.GothamBlack
	txt.TextScaled = true
	txt.Text = letter
	txt.TextColor3 = color
	txt.TextStrokeColor3 = color
	txt.TextStrokeTransparency = 0.15
	txt.Parent = bb

	local glow = txt:Clone()
	glow.Name = "Glow"
	glow.TextTransparency = 0.45
	glow.TextStrokeTransparency = 1
	glow.Size = UDim2.new(1.25, 0, 1.25, 0)
	glow.Position = UDim2.new(-0.125, 0, -0.125, 0)
	glow.Parent = bb

	txt.TextTransparency = 1
	txt.TextStrokeTransparency = 1
	glow.TextTransparency = 1
	glow.TextStrokeTransparency = 1
	tweenObj(txt, { TextTransparency = 0, TextStrokeTransparency = 0.15 })
	tweenObj(glow, { TextTransparency = 0.45, TextStrokeTransparency = 1 })

	m.tag = bb
end

-- ===== visuals =====
local function removeVisualsOnly(fishModel)
	local m = tracked[fishModel]
	if not m then return end

	if m.hl and isAlive(m.hl) then
		tweenObj(m.hl, { FillTransparency = 1, OutlineTransparency = 1 })
		m.hl.Enabled = false
	end

	if m.eyes and isAlive(m.eyes) then
		for _, d in ipairs(m.eyes:GetDescendants()) do
			if d:IsA("Frame") then tweenObj(d, { BackgroundTransparency = 1 }) end
		end
	end

	if m.tag and isAlive(m.tag) then
		for _, d in ipairs(m.tag:GetDescendants()) do
			if d:IsA("TextLabel") then tweenObj(d, { TextTransparency = 1, TextStrokeTransparency = 1 }) end
		end
	end

	m.fadeToken = (m.fadeToken or 0) + 1
end

local function fadeRemoveFull(fishModel)
	local m = tracked[fishModel]
	if not m then return end

	restoreForeignHL(m)

	if m.labelConn then pcall(function() m.labelConn:Disconnect() end) end
	m.labelConn = nil
	m.labelObj = nil

	if m.hl then tweenObj(m.hl, { FillTransparency = 1, OutlineTransparency = 1 }) end

	if m.eyes then
		for _, d in ipairs(m.eyes:GetDescendants()) do
			if d:IsA("Frame") then tweenObj(d, { BackgroundTransparency = 1 }) end
		end
	end

	if m.tag then
		for _, d in ipairs(m.tag:GetDescendants()) do
			if d:IsA("TextLabel") then tweenObj(d, { TextTransparency = 1, TextStrokeTransparency = 1 }) end
		end
	end

	task.delay(FADE_TWEEN.Time, function()
		local mm = tracked[fishModel]
		if not mm then return end

		if mm.hl then pcall(function() mm.hl:Destroy() end) end
		if mm.eyes then pcall(function() mm.eyes:Destroy() end) end
		if mm.tag then pcall(function() mm.tag:Destroy() end) end

		if mm.conns then
			for _, c in ipairs(mm.conns) do pcall(function() c:Disconnect() end) end
		end

		tracked[fishModel] = nil
	end)
end

local function clearAll()
	for fish in pairs(tracked) do
		removeVisualsOnly(fish)
	end
end

-- ===== core highlight =====
local function ensureHL(fishModel)
	local m = tracked[fishModel]
	if not m then return nil end

	if m.hl and isAlive(m.hl) then
		m.hl.Enabled = true
		if m.hl.Parent ~= gui then m.hl.Parent = gui end
		if m.hl.Adornee ~= fishModel then m.hl.Adornee = fishModel end
		m.hl.DepthMode = ALWAYS_ON_TOP and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
		return m.hl
	end

	if m.hl and (not isAlive(m.hl)) then pcall(function() m.hl:Destroy() end) m.hl = nil end

	local hl = Instance.new("Highlight")
	hl.Name = "FishMutationESP"
	hl.DepthMode = ALWAYS_ON_TOP and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
	hl.Parent = gui
	hl.Adornee = fishModel
	hl.Enabled = true
	hl.FillTransparency = 1
	hl.OutlineTransparency = 1

	m.hl = hl
	return hl
end

local function scheduleFadeIfNoValid(fishModel)
	local m = tracked[fishModel]
	if not m then return end

	m.fadeToken = (m.fadeToken or 0) + 1
	local token = m.fadeToken

	task.delay(HIDE_GRACE, function()
		local mm = tracked[fishModel]
		if not mm then return end
		if mm.fadeToken ~= token then return end

		if LOCK_LAST_VALID and mm.lastMutation and STYLE[mm.lastMutation] and enabledByMutation[mm.lastMutation] and espOn then
			return
		end

		removeVisualsOnly(fishModel)
	end)
end

local function applyMutationNow(fishModel, mutation)
	local m = tracked[fishModel]
	if not m then return end

	if mutation and STYLE[mutation] then
		m.lastMutation = mutation
	end

	local render = m.lastMutation
	local canRender = espOn and render and STYLE[render] and enabledByMutation[render]

	if not canRender then
		restoreForeignHL(m)
		scheduleFadeIfNoValid(fishModel)
		return
	end

	for hl in pairs(m.foreignHL) do
		if hl and hl.Parent and hl:IsA("Highlight") then
			hl.Enabled = false
		else
			m.foreignHL[hl] = nil
		end
	end

	restoreFishPartsIfNeeded(fishModel)
	m.fadeToken = (m.fadeToken or 0) + 1

	local st = STYLE[render]
	local fillT = st.fillT or DEFAULT_FILL_T
	local outlineT = st.outlineT or DEFAULT_OUTLINE_T
	fillT, outlineT = applyRarity(render, fillT, outlineT)

	local hl = ensureHL(fishModel)
	if not hl then return end

	hl.Enabled = true
	hl.Adornee = fishModel
	hl.FillColor = st.fill
	hl.OutlineColor = st.outline
	hl.DepthMode = ALWAYS_ON_TOP and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
	if hl.Parent ~= gui then hl.Parent = gui end

	tweenObj(hl, { FillTransparency = fillT, OutlineTransparency = outlineT })
	hl.Enabled = true
	hl.FillTransparency = fillT
	hl.OutlineTransparency = outlineT

	if st.eyes then ensureEyes(fishModel) else destroyEyes(fishModel) end

	if render == "Transparent" then
		ensureTag(fishModel, "T", THEME.ACCENT)
	elseif render == "Invisible" then
		ensureTag(fishModel, "I", Color3.fromRGB(255, 80, 80))
	elseif render == "Spirit" then
		ensureTag(fishModel, "S", Color3.fromRGB(0, 255, 200))
	else
		destroyTag(fishModel)
	end
end

local function refreshAllNow()
	if not espOn then return end
	for fish, m in pairs(tracked) do
		local label = m.labelObj
		local text = normalizeMutationText(label and label.Text)
		applyMutationNow(fish, text)
	end
end

-- ===== fish tracking (REBIND SAFE + CACHED LABEL + INCREMENTAL CACHES) =====
local function findMutationLabelFast(fishModel)
	local head = fishModel:FindFirstChild("Head")
	if head then
		local stats = head:FindFirstChild("stats")
		if stats then
			local mutation = stats:FindFirstChild("Mutation")
			if mutation then
				local label = mutation:FindFirstChild("Label")
				if label and label:IsA("TextLabel") then return label end
			end
		end
	end
	for _, d in ipairs(fishModel:GetDescendants()) do
		if d.Name == "Mutation" then
			local label = d:FindFirstChild("Label")
			if label and label:IsA("TextLabel") then return label end
		end
	end
	return nil
end

local function hookFish(fishModel)
	if tracked[fishModel] then return end
	if not fishModel:IsA("Model") then return end
	if not fishModel:FindFirstChildWhichIsA("BasePart", true) then return end

	tracked[fishModel] = {
		hl=nil, eyes=nil, tag=nil,
		lastMutation=nil,
		fadeToken=0,
		conns={},
		labelObj=nil, labelConn=nil,
		foreignHL = {},
		partCache = {},
		_bind=nil,
	}
	local m = tracked[fishModel]

	for _, d in ipairs(fishModel:GetDescendants()) do
		if d:IsA("BasePart") then
			addPartToCache(m, d)
		elseif d:IsA("Highlight") then
			addForeignHL(m, d)
		end
	end

	table.insert(m.conns, fishModel.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			fadeRemoveFull(fishModel)
		end
	end))

	table.insert(m.conns, fishModel.DescendantAdded:Connect(function(inst)
		if inst:IsA("BasePart") then
			addPartToCache(m, inst)
		elseif inst:IsA("Highlight") then
			addForeignHL(m, inst)
		end

		if isMutationLabel(inst) or inst.Name == "Mutation" then
			task.defer(function()
				if tracked[fishModel] and tracked[fishModel]._bind then
					tracked[fishModel]._bind()
				end
			end)
		end
	end))

	table.insert(m.conns, fishModel.DescendantRemoving:Connect(function(inst)
		if inst:IsA("Highlight") then
			m.foreignHL[inst] = nil
		elseif inst:IsA("BasePart") then
			m.partCache[inst] = nil
		end

		if m.labelObj and inst == m.labelObj then
			task.defer(function()
				if tracked[fishModel] and tracked[fishModel]._bind then
					tracked[fishModel]._bind()
				end
			end)
		end
	end))

	local function bindToCurrentLabel()
		local mm = tracked[fishModel]
		if not mm then return end

		if mm.labelConn then pcall(function() mm.labelConn:Disconnect() end) end
		mm.labelConn = nil
		mm.labelObj = nil

		local label = findMutationLabelFast(fishModel)
		if not label then
			scheduleFadeIfNoValid(fishModel)
			return
		end

		mm.labelObj = label

		local now = normalizeMutationText(label.Text)
		if now and STYLE[now] then
			mm.lastMutation = now
		end

		applyMutationNow(fishModel, nil)

		mm.labelConn = label:GetPropertyChangedSignal("Text"):Connect(function()
			local m2 = tracked[fishModel]
			if not m2 then return end
			local t = normalizeMutationText(label.Text)
			if t and STYLE[t] then
				m2.lastMutation = t
			end
			applyMutationNow(fishModel, nil)
		end)

		table.insert(mm.conns, label.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				task.defer(function()
					if tracked[fishModel] then bindToCurrentLabel() end
				end)
			end
		end))
	end

	m._bind = bindToCurrentLabel
	bindToCurrentLabel()

	if espOn then
		applyMutationNow(fishModel, nil)
	end

	scheduleFadeIfNoValid(fishModel)
end

for _, c in ipairs(fishClient:GetChildren()) do
	hookFish(c)
end
fishClient.ChildAdded:Connect(hookFish)

-- ===== SELF-HEAL LOOP (lightweight: no descendant scanning) =====
local _healAcc = 0
RunService.Heartbeat:Connect(function(dt)
	if not menuAlive or not espOn then return end
	_healAcc += dt
	if _healAcc < SELF_HEAL_INTERVAL then return end
	_healAcc = 0

	for fish, m in pairs(tracked) do
		if not isAlive(fish) then
			continue
		end

		local label = m.labelObj
		if label and label.Parent then
			local mut = normalizeMutationText(label.Text)
			if mut and STYLE[mut] then
				m.lastMutation = mut
			end
		end

		if m.lastMutation and STYLE[m.lastMutation] and enabledByMutation[m.lastMutation] then
			applyMutationNow(fish, nil)
		else
			restoreForeignHL(m)
		end
	end
end)

-- ===== UI (same as your version) =====
local PANEL_W = 360
local PANEL_H = 340
local HEADER_H = 56

local window = Instance.new("Frame", gui)
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.new(0.5, 0, 0.5, 0)
window.BackgroundColor3 = THEME.BG
window.BorderSizePixel = 0
window.Visible = false
window.ClipsDescendants = true
Instance.new("UICorner", window).CornerRadius = UDim.new(0,14)

local stroke = Instance.new("UIStroke", window)
stroke.Color = THEME.OUTLINE
stroke.Thickness = 1

local OPEN_TWEEN = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local CLOSE_TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

window.Size = UDim2.new(0, 0, 0, 0)

local function animateOpen()
	window.Visible = true
	window.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(window, OPEN_TWEEN, { Size = UDim2.new(0, PANEL_W, 0, PANEL_H) }):Play()
end

local function animateClose()
	local tween = TweenService:Create(window, CLOSE_TWEEN, { Size = UDim2.new(0, 0, 0, 0) })
	tween:Play()
	tween.Completed:Once(function()
		if window then window.Visible = false end
	end)
end

local header = Instance.new("Frame", window)
header.Size = UDim2.new(1, 0, 0, HEADER_H)
header.BackgroundColor3 = THEME.BG
header.BorderSizePixel = 0
header.ZIndex = 10
header.Active = true
Instance.new("UICorner", header).CornerRadius = UDim.new(0,14)

local headerLine = Instance.new("Frame", header)
headerLine.Size = UDim2.new(1, -20, 0, 1)
headerLine.Position = UDim2.new(0, 10, 1, -1)
headerLine.BackgroundColor3 = THEME.OUTLINE
headerLine.BorderSizePixel = 0
headerLine.ZIndex = 11

local title = Instance.new("TextLabel", header)
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 12, 0, 8)
title.Size = UDim2.new(1, -60, 0, 22)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = THEME.TEXT
title.Text = "r0onk's Mutation ESP"
title.ZIndex = 11

local sub = Instance.new("TextLabel", header)
sub.BackgroundTransparency = 1
sub.Position = UDim2.new(0, 12, 0, 30)
sub.Size = UDim2.new(1, -60, 0, 18)
sub.Font = Enum.Font.Gotham
sub.TextSize = 12
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.TextColor3 = THEME.SUBTEXT
sub.Text = "Y = Open/Close  |  U = Toggle"
sub.ZIndex = 11

local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -36, 0, 12)
closeBtn.BackgroundColor3 = THEME.BUTTON
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(220, 60, 60)
closeBtn.BackgroundTransparency = 0
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 12
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

local frame = Instance.new("ScrollingFrame", window)
frame.Size = UDim2.new(1, 0, 1, -HEADER_H)
frame.Position = UDim2.new(0, 0, 0, HEADER_H)
frame.BackgroundTransparency = 1
frame.BorderSizePixel = 0
frame.ScrollBarThickness = 6
frame.ScrollingDirection = Enum.ScrollingDirection.Y
frame.ElasticBehavior = Enum.ElasticBehavior.Never
frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
frame.CanvasSize = UDim2.new(0,0,0,0)
frame.ZIndex = 2

local pad = Instance.new("UIPadding", frame)
pad.PaddingTop = UDim.new(0, 10)
pad.PaddingBottom = UDim.new(0, 14)
pad.PaddingLeft = UDim.new(0, 20)
pad.PaddingRight = UDim.new(0, 20)

local listLayout = Instance.new("UIListLayout", frame)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 10)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local ORDER_I = 0
local function nextOrder()
	ORDER_I += 1
	return ORDER_I
end

local function makeLabel(txt, color, sizeY, textSize)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 0, sizeY or 20)
	l.BackgroundTransparency = 1
	l.Text = txt
	l.Font = Enum.Font.Gotham
	l.TextSize = textSize or 14
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextColor3 = color or THEME.TEXT
	l.ZIndex = 2
	l.LayoutOrder = nextOrder()
	l.Parent = frame
	return l
end

local function makeButton(txt, h)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, h or 36)
	b.BackgroundColor3 = THEME.BUTTON
	b.TextColor3 = THEME.TEXT
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 14
	b.Text = txt
	b.AutoButtonColor = false
	b.ZIndex = 2
	b.BorderSizePixel = 0
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	b.LayoutOrder = nextOrder()
	b.Parent = frame
	return b
end

local function setToggleButton(btn, on, onText, offText)
	btn.Text = on and onText or offText
	btn.BackgroundColor3 = on and THEME.BUTTON_ACTIVE or THEME.BUTTON
end

makeLabel("Mutation ESP", THEME.SUBTEXT, 20, 14)
local masterBtn = makeButton("Mutation ESP: OFF", 40)
setToggleButton(masterBtn, espOn, "Mutation ESP: ON", "Mutation ESP: OFF")

masterBtn.MouseButton1Click:Connect(function()
	espOn = not espOn
	setToggleButton(masterBtn, espOn, "Mutation ESP: ON", "Mutation ESP: OFF")

	if not espOn then
		clearAll()
		for _, m in pairs(tracked) do
			restoreForeignHL(m)
		end
	else
		for _, m in pairs(tracked) do
			for hl in pairs(m.foreignHL) do
				if hl and hl.Parent and hl:IsA("Highlight") then
					m.foreignHL[hl] = m.foreignHL[hl] or hl.Enabled
					hl.Enabled = false
				else
					m.foreignHL[hl] = nil
				end
			end
		end
		refreshAllNow()
	end
end)

-- ===== SCAN BUTTON + RESULTS (ADDED) =====
local scanBtn = makeButton("Scan Workspace (counts mutations)", 40)
local scanStatus = makeLabel("Scan: idle", THEME.SUBTEXT, 18, 13)

local resultsWrap = Instance.new("Frame")
resultsWrap.Size = UDim2.new(1, 0, 0, 10)
resultsWrap.BackgroundColor3 = THEME.PANEL
resultsWrap.BorderSizePixel = 0
resultsWrap.LayoutOrder = nextOrder()
resultsWrap.ZIndex = 2
resultsWrap.Parent = frame
resultsWrap.ClipsDescendants = true
Instance.new("UICorner", resultsWrap).CornerRadius = UDim.new(0, 12)

local rPad = Instance.new("UIPadding", resultsWrap)
rPad.PaddingTop = UDim.new(0, 10)
rPad.PaddingBottom = UDim.new(0, 10)
rPad.PaddingLeft = UDim.new(0, 10)
rPad.PaddingRight = UDim.new(0, 10)

local resultsList = Instance.new("UIListLayout", resultsWrap)
resultsList.SortOrder = Enum.SortOrder.LayoutOrder
resultsList.Padding = UDim.new(0, 6)

local function clearResults()
	for _, c in ipairs(resultsWrap:GetChildren()) do
		if c:IsA("TextLabel") then
			c:Destroy()
		end
	end
	resultsWrap.Size = UDim2.new(1, 0, 0, 10)
end

local function addResultLine(text, color)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, 0, 0, 18)
	l.Font = Enum.Font.Gotham
	l.TextSize = 13
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextColor3 = color or THEME.TEXT
	l.Text = text
	l.ZIndex = 3
	l.Parent = resultsWrap
end

local scanning = false

scanBtn.MouseButton1Click:Connect(function()
	if scanning then return end
	scanning = true

	scanBtn.Text = "Scanning..."
	scanBtn.BackgroundColor3 = THEME.BUTTON_ACTIVE
	scanStatus.Text = "Scan: starting..."
	clearResults()

	task.spawn(function()
		local counts, totalScanned
		local startClock = os.clock()

		local ok, err = pcall(function()
			counts, totalScanned = scanWorkspaceForMutations(function(done, total)
				local pct = math.floor((done / math.max(total, 1)) * 100 + 0.5)
				scanStatus.Text = ("Scan: %d%% (%d/%d)"):format(pct, done, total)
			end)
		end)

		if not ok then
			scanStatus.Text = "Scan: error - " .. tostring(err)
			scanBtn.Text = "Scan Workspace (counts mutations)"
			scanBtn.BackgroundColor3 = THEME.BUTTON
			scanning = false
			return
		end

		local elapsed = os.clock() - startClock
		scanStatus.Text = ("Scan: done (%.2fs), scanned %d instances"):format(elapsed, totalScanned or 0)

		local any = false

		for _, name in ipairs(ORDER) do
			local n = counts[name]
			if n and n > 0 then
				any = true
				local st = STYLE[name]
				addResultLine(("%s: %d"):format(DISPLAY[name] or name, n), st and st.fill or THEME.TEXT)
			end
		end

		for name, n in pairs(counts) do
			if n and n > 0 then
				local inOrder = false
				for _, oname in ipairs(ORDER) do
					if oname == name then inOrder = true break end
				end
				if not inOrder then
					any = true
					addResultLine(("%s: %d"):format(name, n), THEME.TEXT)
				end
			end
		end

		if not any then
			addResultLine("No mutations found in workspace.", THEME.SUBTEXT)
		end

		task.defer(function()
			task.wait()
			resultsWrap.Size = UDim2.new(1, 0, 0, resultsList.AbsoluteContentSize.Y + 20)
		end)

		scanBtn.Text = "Scan Workspace (counts mutations)"
		scanBtn.BackgroundColor3 = THEME.BUTTON
		scanning = false
	end)
end)

makeLabel("Click to toggle mutations", THEME.SUBTEXT, 18, 13)

local gridWrap = Instance.new("Frame")
gridWrap.Size = UDim2.new(1, 0, 0, 10)
gridWrap.BackgroundColor3 = THEME.PANEL
gridWrap.BorderSizePixel = 0
gridWrap.LayoutOrder = nextOrder()
gridWrap.ZIndex = 2
gridWrap.Parent = frame
gridWrap.ClipsDescendants = true
Instance.new("UICorner", gridWrap).CornerRadius = UDim.new(0, 12)

local gPad = Instance.new("UIPadding", gridWrap)
gPad.PaddingTop = UDim.new(0, 10)
gPad.PaddingBottom = UDim.new(0, 10)
gPad.PaddingLeft = UDim.new(0, 10)
gPad.PaddingRight = UDim.new(0, 10)

local grid = Instance.new("UIGridLayout", gridWrap)
grid.CellSize = UDim2.new(0, 86, 0, 44)
grid.CellPadding = UDim2.new(0, 10, 0, 10)
grid.FillDirectionMaxCells = 3
grid.SortOrder = Enum.SortOrder.LayoutOrder

local function styleTile(btn, name)
	local st = STYLE[name]
	local on = enabledByMutation[name]
	btn.BackgroundColor3 = st.fill
	btn.BackgroundTransparency = on and 0.10 or 0.75
	btn.TextTransparency = on and 0.0 or 0.25
	local stroke2 = btn:FindFirstChild("UIStroke")
	if stroke2 then
		stroke2.Color = st.outline
		stroke2.Transparency = on and 0.20 or 0.60
	end
end

for i, name in ipairs(ORDER) do
	local st = STYLE[name]
	if st then
		local b = Instance.new("TextButton")
		b.Name = name.."_Tile"
		b.LayoutOrder = i
		b.AutoButtonColor = false
		b.BorderSizePixel = 0
		b.ZIndex = 3
		b.Parent = gridWrap
		b.ClipsDescendants = true

		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)

		local bs = Instance.new("UIStroke", b)
		bs.Thickness = 1
		bs.Transparency = 0.25

		b.Text = DISPLAY[name] or name
		b.TextColor3 = THEME.TEXT
		b.Font = Enum.Font.GothamBold
		b.TextScaled = true
		b.TextWrapped = false
		b.TextTruncate = Enum.TextTruncate.AtEnd

		local pad2 = Instance.new("UIPadding", b)
		pad2.PaddingLeft = UDim.new(0, 8)
		pad2.PaddingRight = UDim.new(0, 8)
		pad2.PaddingTop = UDim.new(0, 4)
		pad2.PaddingBottom = UDim.new(0, 4)

		local cap = Instance.new("UITextSizeConstraint", b)
		cap.MaxTextSize = 16
		cap.MinTextSize = 12

		styleTile(b, name)

		b.MouseButton1Click:Connect(function()
			enabledByMutation[name] = not enabledByMutation[name]
			styleTile(b, name)
			refreshAllNow()
		end)
	end
end

task.defer(function()
	task.wait()
	gridWrap.Size = UDim2.new(1, 0, 0, grid.AbsoluteContentSize.Y + 20)
end)
grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	gridWrap.Size = UDim2.new(1, 0, 0, grid.AbsoluteContentSize.Y + 20)
end)

local function terminate()
	menuAlive = false
	espOn = false
	clearAll()
	for _, m in pairs(tracked) do
		restoreForeignHL(m)
	end
	if window then pcall(function() window:Destroy() end) end
	if gui then pcall(function() gui:Destroy() end) end
end
closeBtn.MouseButton1Click:Connect(terminate)

-- ===== DRAG (HEADER ONLY) =====
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

-- ===== INPUT =====
UserInputService.InputBegan:Connect(function(i, gp)
	if not menuAlive then return end
	if gp then return end

	if typingInTextBox() and i.KeyCode ~= OPEN_KEY then
		return
	end

	if i.KeyCode == OPEN_KEY then
		if not window.Visible then animateOpen() else animateClose() end
		return
	end

	if i.KeyCode == TOGGLE_KEY then
		espOn = not espOn
		setToggleButton(masterBtn, espOn, "Mutation ESP: ON", "Mutation ESP: OFF")

		if not espOn then
			clearAll()
			for _, m in pairs(tracked) do
				restoreForeignHL(m)
			end
		else
			for _, m in pairs(tracked) do
				for hl in pairs(m.foreignHL) do
					if hl and hl.Parent and hl:IsA("Highlight") then
						m.foreignHL[hl] = m.foreignHL[hl] or hl.Enabled
						hl.Enabled = false
					else
						m.foreignHL[hl] = nil
					end
				end
			end
			refreshAllNow()
		end
		return
	end
end)
