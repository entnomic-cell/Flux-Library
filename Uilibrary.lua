--[[
	ModernUI v4 (IDE / Code-Editor Edition)
	
	FEATURES & IMPROVEMENTS:
	  • Lucide & Web Icons: Full Lucide icon support via web fetching (Fluent style) with offline fallback mappings.
	  • IDE / Code-Editor Aesthetics: Styled after modern code editors (VS Code, Tokyo Night, Catppuccin, One Dark, Dracula).
	  • Full Dynamic Theme Engine: Live-swapping theme properties across all active UI components.
	  • Bug Fixes: Fixed dropdown z-index/clipping issues, slicker non-sticky window dragging, smooth slider precision, isolated keybind listeners.
	  • New Components: Added Textbox, Colorpicker, Section headers, and Input-editable Sliders.

	USAGE:
		local Library = loadstring(game:HttpGet("PATH_TO_THIS_FILE"))()

		local Window = Library:CreateWindow({
			Title    = "Studio IDE Hub",
			SubTitle = "v4.0.0 • workspace.lua",
			Icon     = "code", -- Lucide icon name, web URL, or "rbxassetid://"
			Theme    = "TokyoNight", -- "TokyoNight" | "VSCode" | "Catppuccin" | "OneDark" | "Dracula"
			ToggleKeybind = Enum.KeyCode.Insert,
		})

		local Tab = Window:AddTab("Editor", "terminal")

		Tab:AddSection("// Configuration Controls")
		Tab:AddButton("Execute Script", function() print("Executed!") end, "play")
		Tab:AddToggle("Auto-Save", true, function(state) print("Auto-save:", state) end, Enum.KeyCode.G)
		Tab:AddSlider("Compile Speed", 0, 100, 50, function(val) print("Speed:", val) end)
		Tab:AddDropdown("Language", {"Lua", "TypeScript", "Python", "C++"}, "Lua", function(choice) print(choice) end)
		Tab:AddTextbox("File Path", "C:/Scripts/main.lua", function(txt) print("Path:", txt) end)
		Tab:AddColorpicker("Syntax Color", Color3.fromRGB(187, 154, 247), function(color) print("Color:", color) end)

		Library:Notify("IDE Initialized", "Loaded TokyoNight environment successfully.", 4, "check-circle")
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-------------------------------------------------
-- ICON ENGINE (Lucide Web API + Fallback Map)
-------------------------------------------------
local IconEngine = {
	Cache = {},
	-- Pre-defined fallback Lucide asset IDs for offline / HTTP-restricted environments
	FallbackMap = {
		["home"]         = "rbxassetid://10723407389",
		["settings"]     = "rbxassetid://10734950309",
		["code"]         = "rbxassetid://10723345749",
		["terminal"]     = "rbxassetid://10734982144",
		["user"]         = "rbxassetid://10747373176",
		["play"]         = "rbxassetid://10734923549",
		["shield"]       = "rbxassetid://10734975692",
		["zap"]          = "rbxassetid://10747384183",
		["file"]         = "rbxassetid://10723387563",
		["folder"]       = "rbxassetid://10723387893",
		["check-circle"] = "rbxassetid://10723344686",
		["alert-circle"] = "rbxassetid://10723342921",
		["palette"]      = "rbxassetid://10734950873",
		["sliders"]      = "rbxassetid://10734977262",
		["chevron-down"] = "rbxassetid://10709790948",
		["key"]          = "rbxassetid://10723392005",
		["search"]       = "rbxassetid://10734953745",
		["edit"]         = "rbxassetid://10723346959",
	}
}

-- Async fetch Lucide manifest like Fluent UI library
task.spawn(function()
	pcall(function()
		local response = game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/main/icons.json")
		if response and #response > 0 then
			local decoded = HttpService:JSONDecode(response)
			for name, id in pairs(decoded) do
				IconEngine.Cache[string.lower(name)] = "rbxassetid://" .. tostring(id)
			end
		end
	end)
end)

function IconEngine:GetIcon(iconName)
	if not iconName or iconName == "" then return "" end
	if string.find(iconName, "rbxassetid://") or string.find(iconName, "http") then
		return iconName
	end
	
	local cleanName = string.lower(iconName):gsub("lucide%-", "")
	if IconEngine.Cache[cleanName] then
		return IconEngine.Cache[cleanName]
	elseif IconEngine.FallbackMap[cleanName] then
		return IconEngine.FallbackMap[cleanName]
	end
	return "rbxassetid://10723345749" -- Default fallback to code icon
end

-------------------------------------------------
-- CODE EDITOR THEME PRESETS
-------------------------------------------------
local ThemePresets = {
	TokyoNight = {
		Background      = Color3.fromRGB(26, 27, 38),
		BackgroundAlt   = Color3.fromRGB(22, 22, 30),
		Sidebar         = Color3.fromRGB(18, 19, 27),
		Surface         = Color3.fromRGB(31, 35, 53),
		SurfaceLight    = Color3.fromRGB(41, 46, 66),
		Accent          = Color3.fromRGB(187, 154, 247), -- Neon Purple
		AccentSecondary = Color3.fromRGB(125, 207, 255), -- Neon Cyan
		Text            = Color3.fromRGB(192, 202, 245),
		SubText         = Color3.fromRGB(86, 95, 137),
		Stroke          = Color3.fromRGB(41, 46, 66),
		StrokeHighlight = Color3.fromRGB(122, 162, 247),
		SyntaxKeyword   = Color3.fromRGB(27, 209, 162),
		SyntaxString    = Color3.fromRGB(158, 206, 106),
		SyntaxNumber    = Color3.fromRGB(255, 158, 100),
		Font            = Enum.Font.Code,
		FontBold        = Enum.Font.Code,
	},
	VSCode = {
		Background      = Color3.fromRGB(30, 30, 30),
		BackgroundAlt   = Color3.fromRGB(24, 24, 24),
		Sidebar         = Color3.fromRGB(37, 37, 38),
		Surface         = Color3.fromRGB(45, 45, 48),
		SurfaceLight    = Color3.fromRGB(60, 60, 65),
		Accent          = Color3.fromRGB(86, 156, 214), -- VS Code Blue
		AccentSecondary = Color3.fromRGB(78, 201, 176), -- VS Code Cyan
		Text            = Color3.fromRGB(220, 220, 220),
		SubText         = Color3.fromRGB(130, 130, 130),
		Stroke          = Color3.fromRGB(51, 51, 55),
		StrokeHighlight = Color3.fromRGB(0, 122, 204),
		SyntaxKeyword   = Color3.fromRGB(198, 120, 221),
		SyntaxString    = Color3.fromRGB(206, 145, 120),
		SyntaxNumber    = Color3.fromRGB(181, 206, 168),
		Font            = Enum.Font.Code,
		FontBold        = Enum.Font.Code,
	},
	Catppuccin = {
		Background      = Color3.fromRGB(30, 30, 46),
		BackgroundAlt   = Color3.fromRGB(24, 24, 37),
		Sidebar         = Color3.fromRGB(17, 17, 27),
		Surface         = Color3.fromRGB(49, 50, 68),
		SurfaceLight    = Color3.fromRGB(69, 71, 90),
		Accent          = Color3.fromRGB(180, 190, 254), -- Lavender
		AccentSecondary = Color3.fromRGB(245, 194, 231), -- Pink
		Text            = Color3.fromRGB(205, 214, 244),
		SubText         = Color3.fromRGB(147, 153, 178),
		Stroke          = Color3.fromRGB(49, 50, 68),
		StrokeHighlight = Color3.fromRGB(137, 180, 250),
		SyntaxKeyword   = Color3.fromRGB(203, 166, 247),
		SyntaxString    = Color3.fromRGB(166, 227, 161),
		SyntaxNumber    = Color3.fromRGB(250, 179, 135),
		Font            = Enum.Font.Code,
		FontBold        = Enum.Font.Code,
	},
	OneDark = {
		Background      = Color3.fromRGB(40, 44, 52),
		BackgroundAlt   = Color3.fromRGB(33, 37, 43),
		Sidebar         = Color3.fromRGB(33, 37, 43),
		Surface         = Color3.fromRGB(44, 49, 58),
		SurfaceLight    = Color3.fromRGB(53, 59, 69),
		Accent          = Color3.fromRGB(97, 175, 239), -- OneDark Blue
		AccentSecondary = Color3.fromRGB(224, 108, 117), -- OneDark Coral
		Text            = Color3.fromRGB(171, 178, 191),
		SubText         = Color3.fromRGB(92, 99, 112),
		Stroke          = Color3.fromRGB(53, 59, 69),
		StrokeHighlight = Color3.fromRGB(97, 175, 239),
		SyntaxKeyword   = Color3.fromRGB(198, 120, 221),
		SyntaxString    = Color3.fromRGB(152, 195, 121),
		SyntaxNumber    = Color3.fromRGB(209, 154, 102),
		Font            = Enum.Font.Code,
		FontBold        = Enum.Font.Code,
	},
	Dracula = {
		Background      = Color3.fromRGB(40, 42, 54),
		BackgroundAlt   = Color3.fromRGB(33, 34, 44),
		Sidebar         = Color3.fromRGB(33, 34, 44),
		Surface         = Color3.fromRGB(68, 71, 90),
		SurfaceLight    = Color3.fromRGB(98, 101, 120),
		Accent          = Color3.fromRGB(255, 121, 198), -- Dracula Pink
		AccentSecondary = Color3.fromRGB(189, 147, 249), -- Dracula Purple
		Text            = Color3.fromRGB(248, 248, 242),
		SubText         = Color3.fromRGB(98, 114, 164),
		Stroke          = Color3.fromRGB(68, 71, 90),
		StrokeHighlight = Color3.fromRGB(189, 147, 249),
		SyntaxKeyword   = Color3.fromRGB(255, 121, 198),
		SyntaxString    = Color3.fromRGB(241, 250, 140),
		SyntaxNumber    = Color3.fromRGB(189, 147, 249),
		Font            = Enum.Font.Code,
		FontBold        = Enum.Font.Code,
	}
}

local CurrentTheme = ThemePresets.TokyoNight

-------------------------------------------------
-- DYNAMIC THEME ENGINE REGISTRY
-------------------------------------------------
local ThemeRegistry = {}

local function bindTheme(inst, property, themeKey)
	table.insert(ThemeRegistry, {Inst = inst, Prop = property, Key = themeKey})
	if CurrentTheme[themeKey] then
		inst[property] = CurrentTheme[themeKey]
	end
	return inst
end

local function applyTheme(themeNameOrTable)
	if typeof(themeNameOrTable) == "string" and ThemePresets[themeNameOrTable] then
		CurrentTheme = ThemePresets[themeNameOrTable]
	elseif typeof(themeNameOrTable) == "table" then
		CurrentTheme = themeNameOrTable
	end

	for i = #ThemeRegistry, 1, -1 do
		local entry = ThemeRegistry[i]
		if entry.Inst and entry.Inst.Parent then
			local targetVal = CurrentTheme[entry.Key]
			if targetVal then
				TweenService:Create(entry.Inst, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {[entry.Prop] = targetVal}):Play()
			end
		else
			table.remove(ThemeRegistry, i)
		end
	end
end

-------------------------------------------------
-- UTILITY CREATORS
-------------------------------------------------
local function tween(obj, props, time, style, dir)
	local info = TweenInfo.new(time or 0.18, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function make(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	if parent then inst.Parent = parent end
	return inst
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = parent
	return c
end

local function stroke(parent, themeKey, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	bindTheme(s, "Color", themeKey or "Stroke")
	return s
end

local function padding(parent, top, bottom, left, right)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, top or 8)
	p.PaddingBottom = UDim.new(0, bottom or top or 8)
	p.PaddingLeft = UDim.new(0, left or top or 8)
	p.PaddingRight = UDim.new(0, right or left or top or 8)
	p.Parent = parent
	return p
end

-- Smooth Non-Sticky Draggable Implementation
local function makeDraggable(dragHandle, target)
	local dragging, dragStart, startPos = false, nil, nil

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

-------------------------------------------------
-- KEYBIND CAPTURE COMPONENT
-------------------------------------------------
local function makeKeyCaptureButton(parent, size, initialKey, onChanged)
	local Btn = make("TextButton", {
		Text = initialKey and "[" .. initialKey.Name .. "]" or "[None]",
		TextSize = 11,
		AutoButtonColor = false,
		Size = size,
	}, parent)
	bindTheme(Btn, "TextColor3", "SyntaxKeyword")
	bindTheme(Btn, "BackgroundColor3", "SurfaceLight")
	bindTheme(Btn, "Font", "FontBold")
	corner(Btn, 4)
	stroke(Btn, "Stroke", 1)

	local listening = false
	Btn.MouseButton1Click:Connect(function()
		if listening then return end
		listening = true
		Btn.Text = "[...]"
		local conn
		conn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				initialKey = input.KeyCode
				Btn.Text = "[" .. initialKey.Name .. "]"
				listening = false
				conn:Disconnect()
				if onChanged then onChanged(initialKey) end
			end
		end)
	end)

	return Btn
end

-------------------------------------------------
-- MAIN LIBRARY
-------------------------------------------------
local Library = {}
Library.__index = Library

function Library:SetTheme(themeNameOrTable)
	applyTheme(themeNameOrTable)
end

function Library:CreateWindow(config)
	config = config or {}
	local title = config.Title or "IDE Hub"
	local subtitle = config.SubTitle or "workspace.lua"
	local menuKeybind = config.ToggleKeybind or Enum.KeyCode.Insert

	if config.Theme then
		applyTheme(config.Theme)
	end

	local existing = PlayerGui:FindFirstChild("ModernIDE_Gui")
	if existing then existing:Destroy() end

	local ScreenGui = make("ScreenGui", {
		Name = "ModernIDE_Gui",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, PlayerGui)

	-- Floating Top Overlay for Dropdowns & Tooltips to fix Z-Index Clipping Bugs
	local OverlayContainer = make("Frame", {
		Name = "OverlayContainer",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 100,
	}, ScreenGui)

	local Main = make("Frame", {
		Name = "MainFrame",
		Size = UDim2.fromOffset(680, 430),
		Position = UDim2.new(0.5, -340, 0.5, -215),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 2,
	}, ScreenGui)
	bindTheme(Main, "BackgroundColor3", "Background")
	corner(Main, 8)
	stroke(Main, "StrokeHighlight", 1)

	makeDraggable(Main, Main)

	-- Top Window Bar / IDE Header
	local TopBar = make("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 38),
		BorderSizePixel = 0,
		ZIndex = 5,
	}, Main)
	bindTheme(TopBar, "BackgroundColor3", "BackgroundAlt")

	-- Syntax Accent Line under Header
	local AccentLine = make("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BorderSizePixel = 0,
		ZIndex = 6,
	}, TopBar)
	bindTheme(AccentLine, "BackgroundColor3", "Accent")

	local titleOffset = 12
	if config.Icon and config.Icon ~= "" then
		local IconImg = make("ImageLabel", {
			Image = IconEngine:GetIcon(config.Icon),
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.fromOffset(12, 11),
			BackgroundTransparency = 1,
			ZIndex = 6,
		}, TopBar)
		bindTheme(IconImg, "ImageColor3", "Accent")
		titleOffset = 36
	end

	local TitleLbl = make("TextLabel", {
		Text = title,
		TextSize = 13,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(titleOffset, 10),
		Size = UDim2.new(0, 200, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
	}, TopBar)
	bindTheme(TitleLbl, "TextColor3", "Text")
	bindTheme(TitleLbl, "Font", "FontBold")

	local SubTitleLbl = make("TextLabel", {
		Text = "// " .. subtitle,
		TextSize = 11,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(titleOffset + TitleLbl.TextBounds.X + 10, 10),
		Size = UDim2.new(0, 200, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
	}, TopBar)
	bindTheme(SubTitleLbl, "TextColor3", "SubText")
	bindTheme(SubTitleLbl, "Font", "Font")

	local function topBarIconButton(symbol, xOffset)
		local Btn = make("TextButton", {
			Text = symbol,
			TextSize = 13,
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Size = UDim2.fromOffset(28, 28),
			Position = UDim2.new(1, xOffset, 0, 5),
			ZIndex = 6,
		}, TopBar)
		bindTheme(Btn, "TextColor3", "SubText")
		bindTheme(Btn, "Font", "FontBold")
		corner(Btn, 4)
		Btn.MouseEnter:Connect(function()
			tween(Btn, {BackgroundTransparency = 0.8}, 0.12)
			bindTheme(Btn, "BackgroundColor3", "SurfaceLight")
		end)
		Btn.MouseLeave:Connect(function()
			tween(Btn, {BackgroundTransparency = 1}, 0.12)
		end)
		return Btn
	end

	local CloseBtn = topBarIconButton("✕", -32)
	local MinimizeBtn = topBarIconButton("—", -62)
	local ThemeBtn = topBarIconButton("🎨", -92)

	-- Sidebar Navigation
	local Sidebar = make("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 160, 1, -38),
		Position = UDim2.new(0, 0, 0, 38),
		BorderSizePixel = 0,
		ZIndex = 3,
	}, Main)
	bindTheme(Sidebar, "BackgroundColor3", "Sidebar")

	local SidebarBorder = make("Frame", {
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.new(1, -1, 0, 0),
		BorderSizePixel = 0,
		ZIndex = 4,
	}, Sidebar)
	bindTheme(SidebarBorder, "BackgroundColor3", "Stroke")

	local TabList = make("ScrollingFrame", {
		Name = "TabList",
		Size = UDim2.new(1, 0, 1, -30),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, Sidebar)
	bindTheme(TabList, "ScrollBarImageColor3", "Accent")
	padding(TabList, 8, 8, 6, 6)
	make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, TabList)

	-- Status Bar (IDE Bottom Bar Aesthetic)
	local StatusBar = make("Frame", {
		Name = "StatusBar",
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 1, -22),
		BorderSizePixel = 0,
		ZIndex = 5,
	}, Main)
	bindTheme(StatusBar, "BackgroundColor3", "BackgroundAlt")

	local StatusText = make("TextLabel", {
		Text = " READY • UTF-8 • Lua Studio",
		TextSize = 10,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -10, 1, 0),
		Position = UDim2.fromOffset(8, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
	}, StatusBar)
	bindTheme(StatusText, "TextColor3", "SubText")
	bindTheme(StatusText, "Font", "Font")

	-- Content Area
	local Content = make("Frame", {
		Name = "ContentArea",
		Size = UDim2.new(1, -160, 1, -60),
		Position = UDim2.new(0, 160, 0, 38),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, Main)

	------------------------------------------------------
	-- THEME SELECTOR MODAL PANEL
	------------------------------------------------------
	local ThemePanel = make("Frame", {
		Name = "ThemePanel",
		Size = UDim2.fromOffset(220, 210),
		Position = UDim2.new(1, -230, 0, 44),
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 20,
	}, Main)
	bindTheme(ThemePanel, "BackgroundColor3", "Surface")
	corner(ThemePanel, 6)
	stroke(ThemePanel, "StrokeHighlight", 1)
	padding(ThemePanel, 10)
	make("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, ThemePanel)

	local panelTitle = make("TextLabel", {
		Text = "// SELECT THEME",
		TextSize = 11,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 21,
	}, ThemePanel)
	bindTheme(panelTitle, "TextColor3", "SyntaxKeyword")
	bindTheme(panelTitle, "Font", "FontBold")

	for themeName, _ in pairs(ThemePresets) do
		local TBtn = make("TextButton", {
			Text = " > " .. themeName,
			TextSize = 12,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 26),
			TextXAlignment = Enum.TextXAlignment.Left,
			AutoButtonColor = false,
			ZIndex = 21,
		}, ThemePanel)
		bindTheme(TBtn, "TextColor3", "Text")
		bindTheme(TBtn, "Font", "Font")
		corner(TBtn, 4)

		TBtn.MouseEnter:Connect(function()
			tween(TBtn, {BackgroundTransparency = 0.8}, 0.1)
			bindTheme(TBtn, "BackgroundColor3", "SurfaceLight")
		end)
		TBtn.MouseLeave:Connect(function()
			tween(TBtn, {BackgroundTransparency = 1}, 0.1)
		end)
		TBtn.MouseButton1Click:Connect(function()
			applyTheme(themeName)
			ThemePanel.Visible = false
		end)
	end

	ThemeBtn.MouseButton1Click:Connect(function()
		ThemePanel.Visible = not ThemePanel.Visible
	end)

	------------------------------------------------------
	-- MINIMIZE & CLOSE CONTROL
	------------------------------------------------------
	local minimized = false
	MinimizeBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		if minimized then
			ThemePanel.Visible = false
			tween(Main, {Size = UDim2.new(Main.Size.X.Scale, Main.Size.X.Offset, 0, 38)}, 0.2)
		else
			tween(Main, {Size = UDim2.fromOffset(680, 430)}, 0.2)
		end
	end)

	CloseBtn.MouseButton1Click:Connect(function()
		tween(Main, {Size = UDim2.new(Main.Size.X.Scale, Main.Size.X.Offset, 0, 0)}, 0.2)
		task.wait(0.2)
		ScreenGui.Enabled = false
	end)

	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == menuKeybind then
			Main.Visible = not Main.Visible
		end
	end)

	local Window = setmetatable({
		ScreenGui = ScreenGui,
		OverlayContainer = OverlayContainer,
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

function Library.WindowMethods:AddTab(name, iconName)
	local self_ = self
	local order = #self_.Tabs + 1

	local TabButton = make("TextButton", {
		Name = name .. "Tab",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = order,
	}, self_.TabList)
	corner(TabButton, 4)

	local Indicator = make("Frame", {
		Size = UDim2.new(0, 3, 0, 16),
		Position = UDim2.new(0, 2, 0.5, -8),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, TabButton)
	bindTheme(Indicator, "BackgroundColor3", "Accent")
	corner(Indicator, 2)

	local iconOffset = 10
	if iconName and iconName ~= "" then
		local TabIcon = make("ImageLabel", {
			Image = IconEngine:GetIcon(iconName),
			Size = UDim2.fromOffset(14, 14),
			Position = UDim2.fromOffset(10, 8),
			BackgroundTransparency = 1,
		}, TabButton)
		bindTheme(TabIcon, "ImageColor3", "SubText")
		iconOffset = 30
	end

	local TabLabel = make("TextLabel", {
		Text = name,
		TextSize = 12,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(iconOffset, 0),
		Size = UDim2.new(1, -iconOffset, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, TabButton)
	bindTheme(TabLabel, "TextColor3", "SubText")
	bindTheme(TabLabel, "Font", "Font")

	local Page = make("ScrollingFrame", {
		Name = name .. "Page",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = order == 1,
	}, self_.Content)
	bindTheme(Page, "ScrollBarImageColor3", "Accent")
	padding(Page, 12, 12, 12, 12)
	make("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, Page)

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
			bindTheme(t.Label, "TextColor3", "SubText")
		end
		Tab.Page.Visible = true
		bindTheme(TabButton, "BackgroundColor3", "Surface")
		tween(TabButton, {BackgroundTransparency = 0.5}, 0.15)
		tween(Indicator, {BackgroundTransparency = 0}, 0.15)
		bindTheme(TabLabel, "TextColor3", "Text")
		self_._activeTab = Tab
	end

	TabButton.MouseEnter:Connect(function()
		if self_._activeTab ~= Tab then
			tween(TabButton, {BackgroundTransparency = 0.8}, 0.12)
			bindTheme(TabButton, "BackgroundColor3", "SurfaceLight")
		end
	end)
	TabButton.MouseLeave:Connect(function()
		if self_._activeTab ~= Tab then
			tween(TabButton, {BackgroundTransparency = 1}, 0.12)
		end
	end)
	TabButton.MouseButton1Click:Connect(selectTab)

	if order == 1 then selectTab() end

	return Tab
end

-------------------------------------------------
-- CONTROL BUILDERS
-------------------------------------------------
Library.TabMethods = {}

local function createCard(parent, height)
	local Card = make("Frame", {
		Size = UDim2.new(1, 0, 0, height or 36),
		BorderSizePixel = 0,
	}, parent)
	bindTheme(Card, "BackgroundColor3", "Surface")
	corner(Card, 5)
	stroke(Card, "Stroke", 1)
	return Card
end

function Library.TabMethods:AddSection(text)
	local Sec = make("Frame", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
	}, self.Page)
	
	local Lbl = make("TextLabel", {
		Text = text,
		TextSize = 11,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, Sec)
	bindTheme(Lbl, "TextColor3", "SyntaxKeyword")
	bindTheme(Lbl, "Font", "FontBold")
	return Sec
end

function Library.TabMethods:AddLabel(text)
	local Lbl = make("TextLabel", {
		Text = text,
		TextSize = 12,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, self.Page)
	bindTheme(Lbl, "TextColor3", "SubText")
	bindTheme(Lbl, "Font", "Font")
	return Lbl
end

function Library.TabMethods:AddButton(text, callback, iconName)
	callback = callback or function() end
	local Card = createCard(self.Page, 34)

	local iconOffset = 12
	if iconName and iconName ~= "" then
		local BtnIcon = make("ImageLabel", {
			Image = IconEngine:GetIcon(iconName),
			Size = UDim2.fromOffset(14, 14),
			Position = UDim2.fromOffset(10, 10),
			BackgroundTransparency = 1,
		}, Card)
		bindTheme(BtnIcon, "ImageColor3", "AccentSecondary")
		iconOffset = 30
	end

	local Lbl = make("TextLabel", {
		Text = text,
		TextSize = 12,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(iconOffset, 0),
		Size = UDim2.new(1, -iconOffset, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, Card)
	bindTheme(Lbl, "TextColor3", "Text")
	bindTheme(Lbl, "Font", "Font")

	local Click = make("TextButton", {
		Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
	}, Card)

	Click.MouseEnter:Connect(function() bindTheme(Card, "BackgroundColor3", "SurfaceLight") end)
	Click.MouseLeave:Connect(function() bindTheme(Card, "BackgroundColor3", "Surface") end)
	Click.MouseButton1Click:Connect(function()
		bindTheme(Card, "BackgroundColor3", "Accent")
		task.wait(0.08)
		bindTheme(Card, "BackgroundColor3", "Surface")
		callback()
	end)

	return Card
end

function Library.TabMethods:AddToggle(text, default, callback, keybind)
	callback = callback or function() end
	local state = default or false
	local boundKey = keybind

	local Card = createCard(self.Page, 36)

	local Lbl = make("TextLabel", {
		Text = text,
		TextSize = 12,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -120, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, Card)
	bindTheme(Lbl, "TextColor3", "Text")
	bindTheme(Lbl, "Font", "Font")

	local Switch = make("Frame", {
		Size = UDim2.fromOffset(36, 18),
		Position = UDim2.new(1, -46, 0.5, -9),
	}, Card)
	bindTheme(Switch, "BackgroundColor3", state and "Accent" or "SurfaceLight")
	corner(Switch, 9)

	local Knob = make("Frame", {
		Size = UDim2.fromOffset(14, 14),
		Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	}, Switch)
	corner(Knob, 7)

	local Click = make("TextButton", {
		Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
	}, Switch)

	local function render()
		bindTheme(Switch, "BackgroundColor3", state and "Accent" or "SurfaceLight")
		tween(Knob, {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}, 0.15)
	end

	Click.MouseButton1Click:Connect(function()
		state = not state
		render()
		callback(state)
	end)

	if boundKey ~= nil then
		local capBtn = makeKeyCaptureButton(
			Card, UDim2.new(0, 56, 0, 20), boundKey,
			function(newKey) boundKey = newKey end
		)
		capBtn.Position = UDim2.new(1, -108, 0.5, -10)

		UserInputService.InputBegan:Connect(function(input, gpe)
			if gpe then return end
			if boundKey and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == boundKey then
				state = not state
				render()
				callback(state)
			end
		end)
	end

	return {
		Set = function(_, val) state = val; render(); callback(state) end,
		Get = function() return state end,
	}
end

function Library.TabMethods:AddSlider(text, min, max, default, callback)
	callback = callback or function() end
	min, max = min or 0, max or 100
	default = math.clamp(default or min, min, max)

	local Card = createCard(self.Page, 48)
	padding(Card, 8, 8, 12, 12)

	local Lbl = make("TextLabel", {
		Text = text,
		TextSize = 12,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -60, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, Card)
	bindTheme(Lbl, "TextColor3", "Text")
	bindTheme(Lbl, "Font", "Font")

	local ValInput = make("TextBox", {
		Text = tostring(default),
		TextSize = 12,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -50, 0, 0),
		Size = UDim2.new(0, 50, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Right,
	}, Card)
	bindTheme(ValInput, "TextColor3", "SyntaxNumber")
	bindTheme(ValInput, "Font", "FontBold")

	local Track = make("Frame", {
		Size = UDim2.new(1, 0, 0, 4),
		Position = UDim2.new(0, 0, 1, -6),
	}, Card)
	bindTheme(Track, "BackgroundColor3", "SurfaceLight")
	corner(Track, 2)

	local function pctFor(v) return (v - min) / (max - min) end

	local Fill = make("Frame", {
		Size = UDim2.new(pctFor(default), 0, 1, 0),
	}, Track)
	bindTheme(Fill, "BackgroundColor3", "Accent")
	corner(Fill, 2)

	local Thumb = make("Frame", {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(pctFor(default), -6, 0.5, -6),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	}, Track)
	corner(Thumb, 6)

	local dragging = false
	local function updateFromX(xPos)
		local rel = math.clamp((xPos - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
		local val = math.floor(min + (max - min) * rel + 0.5)
		Fill.Size = UDim2.new(rel, 0, 1, 0)
		Thumb.Position = UDim2.new(rel, -6, 0.5, -6)
		ValInput.Text = tostring(val)
		callback(val)
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

	ValInput.FocusLost:Connect(function()
		local num = tonumber(ValInput.Text)
		if num then
			num = math.clamp(num, min, max)
			local rel = pctFor(num)
			Fill.Size = UDim2.new(rel, 0, 1, 0)
			Thumb.Position = UDim2.new(rel, -6, 0.5, -6)
			ValInput.Text = tostring(num)
			callback(num)
		else
			ValInput.Text = tostring(default)
		end
	end)

	return {
		Set = function(_, val)
			val = math.clamp(val, min, max)
			local rel = pctFor(val)
			Fill.Size = UDim2.new(rel, 0, 1, 0)
			Thumb.Position = UDim2.new(rel, -6, 0.5, -6)
			ValInput.Text = tostring(val)
			callback(val)
		end,
	}
end

function Library.TabMethods:AddDropdown(text, options, default, callback)
	callback = callback or function() end
	options = options or {}
	local selected = default or options[1] or "None"
	local open = false

	local Card = createCard(self.Page, 36)

	local Lbl = make("TextLabel", {
		Text = text,
		TextSize = 12,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(0.5, -12, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, Card)
	bindTheme(Lbl, "TextColor3", "Text")
	bindTheme(Lbl, "Font", "Font")

	local SelectedLbl = make("TextLabel", {
		Text = tostring(selected),
		TextSize = 12,
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(0.5, -30, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
	}, Card)
	bindTheme(SelectedLbl, "TextColor3", "SyntaxString")
	bindTheme(SelectedLbl, "Font", "FontBold")

	local Arrow = make("ImageLabel", {
		Image = IconEngine:GetIcon("chevron-down"),
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(1, -22, 0.5, -7),
		BackgroundTransparency = 1,
	}, Card)
	bindTheme(Arrow, "ImageColor3", "SubText")

	-- Floating List attached to OverlayContainer to completely prevent clipping
	local OverlayList = make("Frame", {
		Size = UDim2.new(0, 180, 0, #options * 26 + 6),
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 105,
	}, self.Window.OverlayContainer)
	bindTheme(OverlayList, "BackgroundColor3", "Surface")
	corner(OverlayList, 4)
	stroke(OverlayList, "StrokeHighlight", 1)
	padding(OverlayList, 3, 3, 3, 3)
	make("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, OverlayList)

	for i, opt in ipairs(options) do
		local OptBtn = make("TextButton", {
			Text = "  " .. tostring(opt),
			TextSize = 11,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 24),
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = i,
			AutoButtonColor = false,
			ZIndex = 106,
		}, OverlayList)
		bindTheme(OptBtn, "TextColor3", "Text")
		bindTheme(OptBtn, "Font", "Font")
		corner(OptBtn, 3)

		OptBtn.MouseEnter:Connect(function()
			tween(OptBtn, {BackgroundTransparency = 0.8}, 0.1)
			bindTheme(OptBtn, "BackgroundColor3", "SurfaceLight")
		end)
		OptBtn.MouseLeave:Connect(function()
			tween(OptBtn, {BackgroundTransparency = 1}, 0.1)
		end)
		OptBtn.MouseButton1Click:Connect(function()
			selected = opt
			SelectedLbl.Text = tostring(opt)
			callback(opt)
			open = false
			OverlayList.Visible = false
			tween(Arrow, {Rotation = 0}, 0.15)
		end)
	end

	local Click = make("TextButton", {
		Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
	}, Card)

	Click.MouseButton1Click:Connect(function()
		open = not open
		if open then
			local pos = Card.AbsolutePosition
			OverlayList.Position = UDim2.fromOffset(pos.X + Card.AbsoluteSize.X - 180, pos.Y + Card.AbsoluteSize.Y + 4)
			OverlayList.Visible = true
			tween(Arrow, {Rotation = 180}, 0.15)
		else
			OverlayList.Visible = false
			tween(Arrow, {Rotation = 0}, 0.15)
		end
	end)

	return {
		Set = function(_, val) selected = val; SelectedLbl.Text = tostring(val); callback(val) end,
		Get = function() return selected end,
	}
end

function Library.TabMethods:AddTextbox(text, placeholder, callback)
	callback = callback or function() end

	local Card = createCard(self.Page, 36)

	local Lbl = make("TextLabel", {
		Text = text,
		TextSize = 12,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(0.4, -12, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, Card)
	bindTheme(Lbl, "TextColor3", "Text")
	bindTheme(Lbl, "Font", "Font")

	local Input = make("TextBox", {
		Text = "",
		PlaceholderText = placeholder or "Type here...",
		TextSize = 11,
		Position = UDim2.new(0.4, 0, 0.5, -11),
		Size = UDim2.new(0.6, -10, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
	}, Card)
	bindTheme(Input, "TextColor3", "SyntaxString")
	bindTheme(Input, "PlaceholderColor3", "SubText")
	bindTheme(Input, "BackgroundColor3", "SurfaceLight")
	bindTheme(Input, "Font", "Font")
	corner(Input, 4)
	padding(Input, 0, 0, 6, 6)

	Input.FocusLost:Connect(function(enterPressed)
		callback(Input.Text, enterPressed)
	end)

	return Input
end

function Library.TabMethods:AddColorpicker(text, defaultColor, callback)
	callback = callback or function() end
	local currentColor = defaultColor or Color3.fromRGB(187, 154, 247)

	local Card = createCard(self.Page, 36)

	local Lbl = make("TextLabel", {
		Text = text,
		TextSize = 12,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -60, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, Card)
	bindTheme(Lbl, "TextColor3", "Text")
	bindTheme(Lbl, "Font", "Font")

	local Swatch = make("Frame", {
		Size = UDim2.fromOffset(24, 18),
		Position = UDim2.new(1, -36, 0.5, -9),
		BackgroundColor3 = currentColor,
	}, Card)
	corner(Swatch, 4)
	stroke(Swatch, "StrokeHighlight", 1)

	local Click = make("TextButton", {
		Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
	}, Swatch)

	-- Color Picker Preset Cycle Quick Action
	local palette = {
		Color3.fromRGB(187, 154, 247),
		Color3.fromRGB(125, 207, 255),
		Color3.fromRGB(158, 206, 106),
		Color3.fromRGB(255, 158, 100),
		Color3.fromRGB(247, 118, 142),
	}
	local pIndex = 1

	Click.MouseButton1Click:Connect(function()
		pIndex = (pIndex % #palette) + 1
		currentColor = palette[pIndex]
		Swatch.BackgroundColor3 = currentColor
		callback(currentColor)
	end)

	return {
		Set = function(_, color) currentColor = color; Swatch.BackgroundColor3 = color; callback(color) end,
		Get = function() return currentColor end,
	}
end

-------------------------------------------------
-- TOAST NOTIFICATIONS SYSTEM
-------------------------------------------------
function Library:Notify(title, text, duration, iconName)
	duration = duration or 4

	local gui = PlayerGui:FindFirstChild("ModernIDE_Gui")
	if not gui then return end

	local holder = gui:FindFirstChild("NotifHolder")
	if not holder then
		holder = make("Frame", {
			Name = "NotifHolder",
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 260, 1, -40),
			Position = UDim2.new(1, -270, 0, 20),
			ZIndex = 200,
		}, gui)
		make("UIListLayout", {
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, holder)
	end

	local Notif = make("Frame", {
		Size = UDim2.new(1, 0, 0, 50),
		BorderSizePixel = 0,
		ZIndex = 201,
	}, holder)
	bindTheme(Notif, "BackgroundColor3", "Surface")
	corner(Notif, 6)
	stroke(Notif, "StrokeHighlight", 1)
	padding(Notif, 8, 8, 10, 10)

	local accentBar = make("Frame", {
		Size = UDim2.new(0, 3, 1, 0),
		Position = UDim2.new(0, -10, 0, 0),
		BorderSizePixel = 0,
	}, Notif)
	bindTheme(accentBar, "BackgroundColor3", "Accent")
	corner(accentBar, 2)

	local titleOffset = 0
	if iconName and iconName ~= "" then
		local NIcon = make("ImageLabel", {
			Image = IconEngine:GetIcon(iconName),
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.fromOffset(0, 2),
			BackgroundTransparency = 1,
		}, Notif)
		bindTheme(NIcon, "ImageColor3", "AccentSecondary")
		titleOffset = 22
	end

	local TitleLbl = make("TextLabel", {
		Text = title,
		TextSize = 12,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(titleOffset, 0),
		Size = UDim2.new(1, -titleOffset, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, Notif)
	bindTheme(TitleLbl, "TextColor3", "Text")
	bindTheme(TitleLbl, "Font", "FontBold")

	local TextLbl = make("TextLabel", {
		Text = text,
		TextSize = 11,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(titleOffset, 16),
		Size = UDim2.new(1, -titleOffset, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, Notif)
	bindTheme(TextLbl, "TextColor3", "SubText")
	bindTheme(TextLbl, "Font", "Font")

	task.delay(duration, function()
		tween(Notif, {BackgroundTransparency = 1}, 0.2)
		tween(TitleLbl, {TextTransparency = 1}, 0.2)
		tween(TextLbl, {TextTransparency = 1}, 0.2)
		task.wait(0.2)
		Notif:Destroy()
	end)
end

return Library
