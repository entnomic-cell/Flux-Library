--[[
	ModernUI v2 - A clean, dark/purple Roblox UI library with vertical tabs,
	accent theming, a settings panel, minimize/close controls, a global
	show/hide keybind, and per-toggle keybinds.

	USAGE:
		local Library = loadstring(game:HttpGet("PATH_TO_THIS_FILE"))()

		local Window = Library:CreateWindow({
			Title         = "My Hub",
			SubTitle      = "v2.0.0",
			Icon          = "rbxassetid://0",      -- optional, shown left of title
			Accent        = "Purple",              -- "Purple" | "Blue" | "Pink" | "Green" | "Red" | Color3
			ToggleKeybind = Enum.KeyCode.Insert,   -- shows/hides the whole window
		})

		local Tab = Window:AddTab("Home", "rbxassetid://0")

		Tab:AddLabel("Section Title")
		Tab:AddButton("Click Me", function() print("clicked") end)
		Tab:AddToggle("Enable Thing", false, function(state) print(state) end, Enum.KeyCode.G)
		Tab:AddSlider("Speed", 0, 100, 16, function(value) print(value) end)
		Tab:AddDropdown("Mode", {"A","B","C"}, "A", function(choice) print(choice) end)
		Tab:AddKeybind("Toggle Feature", Enum.KeyCode.RightShift, function() print("bound") end)

		Library:Notify("Loaded", "Everything initialized correctly.", 4)

	The gear icon (top bar, next to minimize/close) opens a built-in
	Settings panel where the user can pick an accent color, rebind the
	menu's show/hide key, and adjust UI transparency — no extra code
	required on your end.
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-------------------------------------------------
-- THEME
-------------------------------------------------
local AccentPresets = {
	Purple = Color3.fromRGB(168, 85, 247),
	Blue   = Color3.fromRGB(90, 130, 255),
	Pink   = Color3.fromRGB(255, 90, 190),
	Green  = Color3.fromRGB(80, 220, 140),
	Red    = Color3.fromRGB(255, 90, 90),
}

local Theme = {
	Background   = Color3.fromRGB(13, 13, 17),
	Sidebar      = Color3.fromRGB(10, 10, 14),
	Surface      = Color3.fromRGB(20, 20, 26),
	SurfaceLight = Color3.fromRGB(29, 29, 37),
	Accent       = AccentPresets.Purple,
	AccentDim    = Color3.fromRGB(110, 55, 165),
	Text         = Color3.fromRGB(245, 245, 250),
	SubText      = Color3.fromRGB(150, 150, 165),
	Stroke       = Color3.fromRGB(42, 42, 52),
	Font         = Enum.Font.GothamMedium,
	FontBold     = Enum.Font.GothamBold,
}

local function tween(obj, props, time, style, dir)
	local info = TweenInfo.new(time or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Stroke
	s.Thickness = thickness or 1
	s.Parent = parent
	return s
end

local function padding(parent, all)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, all)
	p.PaddingBottom = UDim.new(0, all)
	p.PaddingLeft = UDim.new(0, all)
	p.PaddingRight = UDim.new(0, all)
	p.Parent = parent
	return p
end

local function make(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	if parent then inst.Parent = parent end
	return inst
end

-------------------------------------------------
-- ACCENT REGISTRY (so accent color can be live-swapped)
-------------------------------------------------
local AccentRegistry = {} -- { {inst=Instance, prop="BackgroundColor3"} , ... }

local function registerAccent(inst, prop)
	table.insert(AccentRegistry, {inst = inst, prop = prop})
	inst[prop] = Theme.Accent
	return inst
end

local function applyAccent(color)
	Theme.Accent = color
	Theme.AccentDim = Color3.new(color.R * 0.65, color.G * 0.65, color.B * 0.65)
	for _, entry in ipairs(AccentRegistry) do
		if entry.inst and entry.inst.Parent then
			tween(entry.inst, {[entry.prop] = color}, 0.2)
		end
	end
end

-------------------------------------------------
-- DRAGGABLE
-------------------------------------------------
local function makeDraggable(dragHandle, target)
	local dragging, dragStart, startPos = false, nil, nil

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	dragHandle.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-------------------------------------------------
-- SMALL KEYBIND CAPTURE BUTTON (reused by toggles, keybinds, settings panel)
-------------------------------------------------
local function makeKeyCaptureButton(parent, size, initialKey, onChanged)
	local Btn = make("TextButton", {
		Text = initialKey and initialKey.Name or "None",
		Font = Theme.Font,
		TextSize = 11,
		TextColor3 = Theme.Text,
		BackgroundColor3 = Theme.SurfaceLight,
		AutoButtonColor = false,
		Size = size,
	}, parent)
	corner(Btn, 6)

	local listening = false
	Btn.MouseButton1Click:Connect(function()
		if listening then return end
		listening = true
		Btn.Text = "..."
		local conn
		conn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				initialKey = input.KeyCode
				Btn.Text = initialKey.Name
				listening = false
				conn:Disconnect()
				onChanged(initialKey)
			end
		end)
	end)

	return Btn, function() return initialKey end
end

-------------------------------------------------
-- LIBRARY
-------------------------------------------------
local Library = {}
Library.__index = Library

function Library:SetAccentColor(color)
	if typeof(color) == "string" then
		color = AccentPresets[color] or Theme.Accent
	end
	applyAccent(color)
end

function Library:CreateWindow(config)
	config = config or {}
	local title = config.Title or "Modern UI"
	local subtitle = config.SubTitle or ""
	local menuKeybind = config.ToggleKeybind or Enum.KeyCode.Insert

	if config.Accent then
		local a = config.Accent
		Theme.Accent = (typeof(a) == "string") and (AccentPresets[a] or Theme.Accent) or a
	end

	-- Remove old instance if re-executed
	local existing = PlayerGui:FindFirstChild("ModernUI_ScreenGui")
	if existing then existing:Destroy() end
	AccentRegistry = {}

	local ScreenGui = make("ScreenGui", {
		Name = "ModernUI_ScreenGui",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, PlayerGui)

	local Main = make("Frame", {
		Name = "Main",
		Size = UDim2.fromOffset(640, 400),
		Position = UDim2.new(0.5, -320, 0.5, -200),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, ScreenGui)
	corner(Main, 12)
	stroke(Main, Theme.Stroke, 1)

	-- Top bar
	local TopBar = make("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		ZIndex = 5,
	}, Main)
	corner(TopBar, 12)
	make("Frame", {
		Size = UDim2.new(1, 0, 0, 12),
		Position = UDim2.new(0, 0, 1, -12),
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, TopBar)

	local titleOffset = 16
	if config.Icon and config.Icon ~= "" then
		local IconImg = make("ImageLabel", {
			Image = config.Icon,
			Size = UDim2.fromOffset(20, 20),
			Position = UDim2.fromOffset(16, 13),
			BackgroundTransparency = 1,
			ImageColor3 = Theme.Accent,
			ZIndex = 5,
		}, TopBar)
		registerAccent(IconImg, "ImageColor3")
		titleOffset = 44
	end

	make("TextLabel", {
		Text = title,
		Font = Theme.FontBold,
		TextSize = 15,
		TextColor3 = Theme.Text,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(titleOffset, 0),
		Size = UDim2.new(0, 240, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 5,
	}, TopBar)

	make("TextLabel", {
		Text = subtitle,
		Font = Theme.Font,
		TextSize = 12,
		TextColor3 = Theme.SubText,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -220, 0, 0),
		Size = UDim2.new(0, 100, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 5,
	}, TopBar)

	-- Window control cluster: Settings gear, Minimize, Close
	local function topBarIconButton(text, xOffset, textSize)
		local Btn = make("TextButton", {
			Text = text,
			Font = Theme.FontBold,
			TextSize = textSize or 16,
			TextColor3 = Theme.SubText,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(32, 32),
			Position = UDim2.new(1, xOffset, 0, 7),
			ZIndex = 5,
		}, TopBar)
		Btn.MouseEnter:Connect(function() tween(Btn, {TextColor3 = Theme.Text}, 0.12) end)
		Btn.MouseLeave:Connect(function() tween(Btn, {TextColor3 = Theme.SubText}, 0.12) end)
		return Btn
	end

	local CloseBtn = topBarIconButton("×", -40, 20)
	local MinimizeBtn = topBarIconButton("—", -72, 13)
	local GearBtn = topBarIconButton("⚙", -104, 15)

	makeDraggable(TopBar, Main)

	-- Sidebar (vertical tabs)
	local Sidebar = make("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 150, 1, -46),
		Position = UDim2.new(0, 0, 0, 46),
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
	}, Main)
	make("Frame", {
		Size = UDim2.new(0, 12, 1, 0),
		Position = UDim2.new(1, -12, 0, 0),
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
	}, Sidebar)
	corner(Sidebar, 12)

	local TabList = make("ScrollingFrame", {
		Name = "TabList",
		Size = UDim2.new(1, 0, 1, -10),
		Position = UDim2.fromOffset(0, 10),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, Sidebar)
	registerAccent(TabList, "ScrollBarImageColor3")
	make("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, TabList)
	padding(TabList, 8)

	-- Content area
	local Content = make("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -150, 1, -46),
		Position = UDim2.new(0, 150, 0, 46),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
	}, Main)

	------------------------------------------------------
	-- SETTINGS PANEL (opened by the gear icon)
	------------------------------------------------------
	local SettingsPanel = make("Frame", {
		Name = "SettingsPanel",
		Size = UDim2.fromOffset(240, 0),
		Position = UDim2.new(1, -252, 0, 52),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = false,
		ZIndex = 10,
	}, Main)
	corner(SettingsPanel, 10)
	stroke(SettingsPanel, Theme.Stroke, 1)
	padding(SettingsPanel, 14)

	make("UIListLayout", {
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, SettingsPanel)

	make("TextLabel", {
		Text = "Accent Color",
		Font = Theme.FontBold,
		TextSize = 12,
		TextColor3 = Theme.SubText,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		ZIndex = 10,
	}, SettingsPanel)

	local SwatchRow = make("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		ZIndex = 10,
	}, SettingsPanel)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, SwatchRow)

	local orderedPresets = {"Purple", "Blue", "Pink", "Green", "Red"}
	for i, name in ipairs(orderedPresets) do
		local color = AccentPresets[name]
		local Swatch = make("TextButton", {
			Text = "",
			Size = UDim2.fromOffset(24, 24),
			BackgroundColor3 = color,
			AutoButtonColor = false,
			LayoutOrder = i,
			ZIndex = 10,
		}, SwatchRow)
		corner(Swatch, 12)
		stroke(Swatch, Theme.Stroke, 1)
		Swatch.MouseButton1Click:Connect(function()
			Library:SetAccentColor(color)
		end)
	end

	make("TextLabel", {
		Text = "Menu Keybind",
		Font = Theme.FontBold,
		TextSize = 12,
		TextColor3 = Theme.SubText,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 3,
		ZIndex = 10,
	}, SettingsPanel)

	local KeybindRow = make("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		LayoutOrder = 4,
		ZIndex = 10,
	}, SettingsPanel)
	make("TextLabel", {
		Text = "Show / Hide UI",
		Font = Theme.Font,
		TextSize = 12,
		TextColor3 = Theme.Text,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -80, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 10,
	}, KeybindRow)
	local keyBtn = makeKeyCaptureButton(
		KeybindRow,
		UDim2.new(0, 76, 0, 26),
		menuKeybind,
		function(newKey) menuKeybind = newKey end
	)
	keyBtn.Position = UDim2.new(1, -76, 0, 1)
	keyBtn.ZIndex = 10

	make("TextLabel", {
		Text = "UI Transparency",
		Font = Theme.FontBold,
		TextSize = 12,
		TextColor3 = Theme.SubText,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 5,
		ZIndex = 10,
	}, SettingsPanel)

	local TransTrack = make("Frame", {
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = Theme.SurfaceLight,
		LayoutOrder = 6,
		ZIndex = 10,
	}, SettingsPanel)
	corner(TransTrack, 3)
	local TransFill = make("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Theme.Accent,
		ZIndex = 10,
	}, TransTrack)
	corner(TransFill, 3)
	registerAccent(TransFill, "BackgroundColor3")

	local transDragging = false
	local function updateTrans(xPos)
		local rel = math.clamp((xPos - TransTrack.AbsolutePosition.X) / TransTrack.AbsoluteSize.X, 0, 0.6)
		TransFill.Size = UDim2.new(rel / 0.6, 0, 1, 0)
		Main.BackgroundTransparency = rel
		TopBar.BackgroundTransparency = rel
		Sidebar.BackgroundTransparency = rel
		Content.BackgroundTransparency = rel
	end
	TransTrack.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			transDragging = true
			updateTrans(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			transDragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if transDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateTrans(input.Position.X)
		end
	end)

	local settingsOpen = false
	GearBtn.MouseButton1Click:Connect(function()
		settingsOpen = not settingsOpen
		if settingsOpen then
			SettingsPanel.Visible = true
			SettingsPanel.AutomaticSize = Enum.AutomaticSize.Y
			tween(SettingsPanel, {BackgroundTransparency = 0}, 0.15)
		else
			SettingsPanel.AutomaticSize = Enum.AutomaticSize.None
			tween(SettingsPanel, {Size = UDim2.new(0, 240, 0, 0)}, 0.15)
			task.delay(0.15, function()
				if not settingsOpen then SettingsPanel.Visible = false end
			end)
		end
	end)

	------------------------------------------------------
	-- MINIMIZE
	------------------------------------------------------
	local minimized = false
	local fullHeight = Main.Size.Y.Offset
	MinimizeBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		if minimized then
			SettingsPanel.Visible = false
			settingsOpen = false
			tween(Main, {Size = UDim2.new(Main.Size.X.Scale, Main.Size.X.Offset, 0, 46)}, 0.2)
			MinimizeBtn.Text = "▢"
		else
			tween(Main, {Size = UDim2.new(Main.Size.X.Scale, Main.Size.X.Offset, 0, fullHeight)}, 0.2)
			MinimizeBtn.Text = "—"
		end
	end)

	------------------------------------------------------
	-- CLOSE
	------------------------------------------------------
	CloseBtn.MouseButton1Click:Connect(function()
		tween(Main, {Size = UDim2.new(Main.Size.X.Scale, Main.Size.X.Offset, 0, 0)}, 0.2)
		task.wait(0.2)
		ScreenGui.Enabled = false
	end)

	------------------------------------------------------
	-- GLOBAL SHOW/HIDE KEYBIND
	------------------------------------------------------
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == menuKeybind then
			Main.Visible = not Main.Visible
		end
	end)

	local Window = setmetatable({
		ScreenGui = ScreenGui,
		Main = Main,
		TabList = TabList,
		Content = Content,
		Tabs = {},
		_activeTab = nil,
	}, {__index = Library.WindowMethods})

	return Window
end

-------------------------------------------------
-- WINDOW METHODS
-------------------------------------------------
Library.WindowMethods = {}

function Library.WindowMethods:AddTab(name, iconId)
	local self_ = self
	local order = #self_.Tabs + 1

	local TabButton = make("TextButton", {
		Name = name .. "Tab",
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = order,
	}, self_.TabList)
	corner(TabButton, 8)
	registerAccent(TabButton, "BackgroundColor3")

	local Indicator = make("Frame", {
		Size = UDim2.new(0, 3, 0, 16),
		Position = UDim2.new(0, 0, 0.5, -8),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, TabButton)
	corner(Indicator, 2)
	registerAccent(Indicator, "BackgroundColor3")

	if iconId and iconId ~= "" then
		make("ImageLabel", {
			Image = iconId,
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.fromOffset(14, 9),
			BackgroundTransparency = 1,
			ImageColor3 = Theme.SubText,
		}, TabButton)
	end

	local TabLabel = make("TextLabel", {
		Text = name,
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Theme.SubText,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(iconId and 38 or 16, 0),
		Size = UDim2.new(1, -50, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, TabButton)

	-- Page
	local Page = make("ScrollingFrame", {
		Name = name .. "Page",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = order == 1,
	}, self_.Content)
	registerAccent(Page, "ScrollBarImageColor3")
	padding(Page, 16)
	make("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, Page)

	local Tab = setmetatable({
		Button = TabButton,
		Label = TabLabel,
		Indicator = Indicator,
		Page = Page,
		Window = self_,
	}, {__index = Library.TabMethods})

	table.insert(self_.Tabs, Tab)

	local function selectTab()
		for _, t in ipairs(self_.Tabs) do
			t.Page.Visible = false
			tween(t.Button, {BackgroundTransparency = 1}, 0.15)
			tween(t.Indicator, {BackgroundTransparency = 1}, 0.15)
			tween(t.Label, {TextColor3 = Theme.SubText}, 0.15)
		end
		Tab.Page.Visible = true
		tween(TabButton, {BackgroundTransparency = 0}, 0.15)
		tween(Indicator, {BackgroundTransparency = 0}, 0.15)
		tween(TabLabel, {TextColor3 = Theme.Text}, 0.15)
		self_._activeTab = Tab
	end

	TabButton.MouseButton1Click:Connect(selectTab)

	if order == 1 then
		selectTab()
	end

	return Tab
end

-------------------------------------------------
-- TAB (CONTROL BUILDERS)
-------------------------------------------------
Library.TabMethods = {}

function Library.TabMethods:AddLabel(text)
	return make("TextLabel", {
		Text = text,
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = Theme.SubText,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, self.Page)
end

function Library.TabMethods:AddButton(text, callback)
	callback = callback or function() end
	local Btn = make("TextButton", {
		Text = text,
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Theme.Text,
		BackgroundColor3 = Theme.Surface,
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 36),
	}, self.Page)
	corner(Btn, 8)
	stroke(Btn, Theme.Stroke, 1)

	Btn.MouseEnter:Connect(function() tween(Btn, {BackgroundColor3 = Theme.SurfaceLight}, 0.12) end)
	Btn.MouseLeave:Connect(function() tween(Btn, {BackgroundColor3 = Theme.Surface}, 0.12) end)
	Btn.MouseButton1Click:Connect(function()
		tween(Btn, {BackgroundColor3 = Theme.AccentDim}, 0.08)
		task.wait(0.08)
		tween(Btn, {BackgroundColor3 = Theme.Surface}, 0.12)
		callback()
	end)

	return Btn
end

-- keybind (optional) lets the toggle also be flipped by a hotkey
function Library.TabMethods:AddToggle(text, default, callback, keybind)
	callback = callback or function() end
	local state = default or false
	local boundKey = keybind

	local Holder = make("Frame", {
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(1, 0, 0, 36),
	}, self.Page)
	corner(Holder, 8)
	stroke(Holder, Theme.Stroke, 1)

	local labelRightPad = boundKey ~= nil and 118 or 70

	make("TextLabel", {
		Text = text,
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Theme.Text,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -labelRightPad, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, Holder)

	local Switch = make("TextButton", {
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromOffset(40, 22),
		Position = UDim2.new(1, -52, 0.5, -11),
		BackgroundColor3 = state and Theme.Accent or Theme.SurfaceLight,
	}, Holder)
	corner(Switch, 11)

	local Knob = make("Frame", {
		Size = UDim2.fromOffset(16, 16),
		Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	}, Switch)
	corner(Knob, 8)

	local function render()
		tween(Switch, {BackgroundColor3 = state and Theme.Accent or Theme.SurfaceLight}, 0.15)
		tween(Knob, {Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}, 0.15)
	end

	Switch.MouseButton1Click:Connect(function()
		state = not state
		render()
		callback(state)
	end)

	if boundKey ~= nil then
		local capBtn = makeKeyCaptureButton(
			Holder,
			UDim2.new(0, 60, 0, 22),
			boundKey,
			function(newKey) boundKey = newKey end
		)
		capBtn.Position = UDim2.new(1, -110, 0.5, -11)

		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if boundKey and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == boundKey then
				state = not state
				render()
				callback(state)
			end
		end)
	end

	return {
		Set = function(_, value)
			state = value
			render()
			callback(state)
		end,
		Get = function() return state end,
	}
end

function Library.TabMethods:AddSlider(text, min, max, default, callback)
	callback = callback or function() end
	min, max = min or 0, max or 100
	default = math.clamp(default or min, min, max)

	local Holder = make("Frame", {
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(1, 0, 0, 50),
	}, self.Page)
	corner(Holder, 8)
	stroke(Holder, Theme.Stroke, 1)
	padding(Holder, 10)

	make("TextLabel", {
		Text = text,
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Theme.Text,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -50, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, Holder)

	local ValueLabel = make("TextLabel", {
		Text = tostring(default),
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Theme.SubText,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -40, 0, 0),
		Size = UDim2.new(0, 40, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Right,
	}, Holder)

	local Track = make("Frame", {
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.new(0, 0, 1, -12),
		BackgroundColor3 = Theme.SurfaceLight,
	}, Holder)
	corner(Track, 3)

	local function pctFor(v) return (v - min) / (max - min) end

	local Fill = make("Frame", {
		Size = UDim2.new(pctFor(default), 0, 1, 0),
		BackgroundColor3 = Theme.Accent,
	}, Track)
	corner(Fill, 3)
	registerAccent(Fill, "BackgroundColor3")

	local dragging = false
	local function updateFromX(xPos)
		local rel = math.clamp((xPos - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
		local value = math.floor(min + (max - min) * rel + 0.5)
		Fill.Size = UDim2.new(rel, 0, 1, 0)
		ValueLabel.Text = tostring(value)
		callback(value)
		return value
	end

	Track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromX(input.Position.X)
		end
	end)

	return {
		Set = function(_, value)
			value = math.clamp(value, min, max)
			Fill.Size = UDim2.new(pctFor(value), 0, 1, 0)
			ValueLabel.Text = tostring(value)
			callback(value)
		end,
	}
end

function Library.TabMethods:AddDropdown(text, options, default, callback)
	callback = callback or function() end
	options = options or {}
	local selected = default or options[1]
	local open = false

	local Holder = make("Frame", {
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(1, 0, 0, 36),
		ClipsDescendants = true,
		ZIndex = 2,
	}, self.Page)
	corner(Holder, 8)
	stroke(Holder, Theme.Stroke, 1)

	local Header = make("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
		ZIndex = 2,
	}, Holder)

	make("TextLabel", {
		Text = text,
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Theme.Text,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 2,
	}, Header)

	local SelectedLabel = make("TextLabel", {
		Text = tostring(selected),
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Theme.SubText,
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(0.5, -28, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 2,
	}, Header)

	local Arrow = make("TextLabel", {
		Text = "v",
		Font = Theme.FontBold,
		TextSize = 11,
		TextColor3 = Theme.SubText,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -24, 0, 0),
		Size = UDim2.fromOffset(20, 36),
		ZIndex = 2,
	}, Header)

	local OptionsFrame = make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 36),
		Size = UDim2.new(1, 0, 0, #options * 30),
		ZIndex = 2,
	}, Holder)
	make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, OptionsFrame)

	for i, opt in ipairs(options) do
		local OptBtn = make("TextButton", {
			Text = tostring(opt),
			Font = Theme.Font,
			TextSize = 12,
			TextColor3 = Theme.SubText,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 30),
			LayoutOrder = i,
			ZIndex = 2,
		}, OptionsFrame)
		OptBtn.MouseEnter:Connect(function() tween(OptBtn, {TextColor3 = Theme.Text}, 0.1) end)
		OptBtn.MouseLeave:Connect(function() tween(OptBtn, {TextColor3 = Theme.SubText}, 0.1) end)
		OptBtn.MouseButton1Click:Connect(function()
			selected = opt
			SelectedLabel.Text = tostring(opt)
			callback(opt)
			open = false
			tween(Holder, {Size = UDim2.new(1, 0, 0, 36)}, 0.15)
			tween(Arrow, {Rotation = 0}, 0.15)
		end)
	end

	Header.MouseButton1Click:Connect(function()
		open = not open
		local targetHeight = open and (36 + #options * 30) or 36
		tween(Holder, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.18)
		tween(Arrow, {Rotation = open and 180 or 0}, 0.18)
	end)

	return {
		Set = function(_, value)
			selected = value
			SelectedLabel.Text = tostring(value)
			callback(value)
		end,
		Get = function() return selected end,
	}
end

function Library.TabMethods:AddKeybind(text, defaultKey, callback)
	callback = callback or function() end

	local Holder = make("Frame", {
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(1, 0, 0, 36),
	}, self.Page)
	corner(Holder, 8)
	stroke(Holder, Theme.Stroke, 1)

	make("TextLabel", {
		Text = text,
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Theme.Text,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -110, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, Holder)

	local currentKey = defaultKey
	local capBtn = makeKeyCaptureButton(
		Holder,
		UDim2.fromOffset(90, 26),
		defaultKey,
		function(newKey) currentKey = newKey end
	)
	capBtn.Position = UDim2.new(1, -100, 0.5, -13)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if currentKey and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentKey then
			callback(currentKey)
		end
	end)

	return {
		Get = function() return currentKey end,
	}
end

-------------------------------------------------
-- NOTIFICATIONS
-------------------------------------------------
function Library:Notify(title, text, duration)
	duration = duration or 4

	local gui = PlayerGui:FindFirstChild("ModernUI_ScreenGui")
	if not gui then
		gui = make("ScreenGui", {Name = "ModernUI_ScreenGui", ResetOnSpawn = false}, PlayerGui)
	end

	local holder = gui:FindFirstChild("NotifHolder")
	if not holder then
		holder = make("Frame", {
			Name = "NotifHolder",
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 260, 1, -20),
			Position = UDim2.new(1, -280, 0, 10),
		}, gui)
		make("UIListLayout", {
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, holder)
	end

	local Notif = make("Frame", {
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		BackgroundTransparency = 1,
	}, holder)
	corner(Notif, 8)
	local accentBar = make("Frame", {
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
	}, Notif)
	corner(accentBar, 2)
	registerAccent(accentBar, "BackgroundColor3")
	stroke(Notif, Theme.Stroke, 1)
	padding(Notif, 12)

	make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, Notif)

	local TitleLbl = make("TextLabel", {
		Text = title,
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = Theme.Text,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTransparency = 1,
	}, Notif)

	local TextLbl = make("TextLabel", {
		Text = text,
		Font = Theme.Font,
		TextSize = 12,
		TextColor3 = Theme.SubText,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTransparency = 1,
	}, Notif)

	tween(Notif, {BackgroundTransparency = 0}, 0.2)
	tween(TitleLbl, {TextTransparency = 0}, 0.2)
	tween(TextLbl, {TextTransparency = 0}, 0.2)

	task.delay(duration, function()
		tween(Notif, {BackgroundTransparency = 1}, 0.2)
		tween(TitleLbl, {TextTransparency = 1}, 0.2)
		tween(TextLbl, {TextTransparency = 1}, 0.2)
		task.wait(0.2)
		Notif:Destroy()
	end)
end

return Library
