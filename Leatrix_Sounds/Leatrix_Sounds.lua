
	----------------------------------------------------------------------
	-- Leatrix Sounds 1.15.166 (11th November 2026)
	----------------------------------------------------------------------

	--  Create global table
	_G.LeaSoundsDB = _G.LeaSoundsDB or {}

	-- Create local tables
	local LeaSoundsLC, LeaSoundsCB = {}, {}

	-- Version
	LeaSoundsLC["AddonVer"] = "1.15.166"

	-- Get locale table
	local void, Leatrix_Sounds = ...
	local L = Leatrix_Sounds.L

	-- Find out which game version this is (the same file is used for every game version)
	do
		local gameversion, gamebuild, gamedate, gametocversion = GetBuildInfo()
		-- Supported game versions (lowest interface version, highest interface version, game version name, text shown after the version in the help)
		local gameVersions = {
			{10000, 15999, L["World of Warcraft Classic"]},
			{16000, 19999, L["Forever"], L["for World of Warcraft Forever"]},
			{20000, 29999, L["Burning Crusade Anniversary"]},
			{30000, 39999, L["Titan Reforged Classic"]},
			{50000, 59999, L["Mists of Pandaria Classic"]},
			{120000, 129999, L["Midnight"]},
		}
		for void, v in ipairs(gameVersions) do
			if gametocversion and gametocversion >= v[1] and gametocversion <= v[2] then
				LeaSoundsLC.GameTitle = v[3]
				LeaSoundsLC.GameHelpTitle = v[4]
				break
			end
		end
		if not LeaSoundsLC.GameTitle then
			-- Game client is not a supported game version
			C_Timer.After(2, function()
				print(L["LEATRIX SOUNDS: WRONG VERSION INSTALLED!"])
			end)
			return
		end
	end

	-- Set bindings translations

	-- if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then LeaSoundsLC.GameVersion = L["The War Within"]
	-- elseif WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC then LeaSoundsLC.GameVersion = L["Cataclysm"]
	-- elseif WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then LeaSoundsLC.GameVersion = L["Classic Era"]
	-- end

	-- LeaSoundsLC["AddonVer"] = LeaSoundsLC["AddonVer"] .. " (" .. LeaSoundsLC.GameVersion .. ")"

	----------------------------------------------------------------------
	--	L00: Leatrix Sounds
	----------------------------------------------------------------------

	-- Initialise variables
	local frameWidth = 800
	local frameHeight = 616
	-- Smallest and largest panel size (the panel can be resized with the grip in the bottom-right corner)
	local minWidth, minHeight = 550, 220

	-- Sound categories shown in the Music and Effects submenus (key, label, file path prefixes)
	-- Categories with no sounds in this game version are hidden when the sounds are loaded
	-- The listings are sorted by path so each prefix is one block of tracks
	-- Anything not matched by a prefix goes in the last category (Other)
	local musicCategories = {
		{"forever", L["Forever"], {"sound/music/forever/"}},
		{"zone", L["Zone music"], {"sound/music/zonemusic/"}},
		{"city", L["City music"], {"sound/music/citymusic/"}},
		{"moments", L["Musical moments"], {"sound/music/musical moments/"}},
		{"expansions", L["Expansions"], {"sound/music/battleforazeroth/", "sound/music/cataclysm/", "sound/music/draenor/", "sound/music/dragonflight/", "sound/music/legion/", "sound/music/midnight/", "sound/music/pandaria/", "sound/music/shadowlands/", "sound/music/warwithin/"}},
		{"events", L["Events"], {"sound/music/event/", "sound/music/worldevents/"}},
		{"cinematics", L["Cinematics"], {"interface/cinematics/", "sound/cinematicvoices/", "streaming/sound/cinematicvoices/"}},
		{"other", L["Other"], {}},
	}
	local effectCategories = {
		{"creatures", L["Creatures"], {"sound/creature/"}},
		{"characters", L["Characters"], {"sound/character/"}},
		{"spells", L["Spells"], {"sound/spells/", "sound/spell/", "spells/"}},
		{"ambience", L["Ambience"], {"sound/ambience/", "sound/emitters/"}},
		{"objects", L["World objects"], {"sound/doodad/"}},
		{"items", L["Items"], {"sound/item/"}},
		{"interface", L["Interface"], {"sound/interface/", "sound/ui/", "interface/"}},
		{"events", L["Events"], {"sound/event/", "sound/events/", "sound/event sounds/"}},
		{"vehicles", L["Vehicles"], {"sound/vehicles/"}},
		{"other", L["Other"], {}},
	}

	----------------------------------------------------------------------
	-- L10: Functions
	----------------------------------------------------------------------

	-- Create a random global name that changes every time the addon loads
	function LeaSoundsLC:CreateRandomName()
		local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		local name
		repeat
			local parts = {"F"} -- Start with a letter
			for i = 1, 16 do
				local n = math.random(#chars)
				parts[#parts + 1] = chars:sub(n, n)
			end
			name = table.concat(parts)
		until not _G[name] -- Make sure the name is not already in use
		return name
	end

	-- Print text
	function LeaSoundsLC:Print(text)
		DEFAULT_CHAT_FRAME:AddMessage(L[text], 1.0, 0.85, 0.0)
	end

	-- Create a close button without using a template
	function LeaSoundsLC:CreateCloseButton(parent, w, h, anchor, x, y)
		local btn = CreateFrame("BUTTON", nil, parent)
		btn:SetSize(w, h)
		btn:SetPoint(anchor, x, y)
		btn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
		btn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
		btn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
		btn:SetDisabledTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Disabled")
		return btn
	end

	-- Load a numeric variable and set it to default if it's not within a given range
	function LeaSoundsLC:LoadVarNum(var, def, valmin, valmax)
		if LeaSoundsDB[var] and type(LeaSoundsDB[var]) == "number" and LeaSoundsDB[var] >= valmin and LeaSoundsDB[var] <= valmax then
			LeaSoundsLC[var] = LeaSoundsDB[var]
		else
			LeaSoundsLC[var] = def
			LeaSoundsDB[var] = def
		end
	end

	-- Load an anchor point variable and set it to default if the anchor point is invalid
	function LeaSoundsLC:LoadVarAnc(var, def)
		if LeaSoundsDB[var] and type(LeaSoundsDB[var]) == "string" and LeaSoundsDB[var] == "CENTER" or LeaSoundsDB[var] == "TOP" or LeaSoundsDB[var] == "BOTTOM" or LeaSoundsDB[var] == "LEFT" or LeaSoundsDB[var] == "RIGHT" or LeaSoundsDB[var] == "TOPLEFT" or LeaSoundsDB[var] == "TOPRIGHT" or LeaSoundsDB[var] == "BOTTOMLEFT" or LeaSoundsDB[var] == "BOTTOMRIGHT" then
			LeaSoundsLC[var] = LeaSoundsDB[var]
		else
			LeaSoundsLC[var] = def
			LeaSoundsDB[var] = def
		end
	end

	-- Load a string variable or set it to default if it's not set to "On" or "Off"
	function LeaSoundsLC:LoadVarChk(var, def)
		if LeaSoundsDB[var] and type(LeaSoundsDB[var]) == "string" and LeaSoundsDB[var] == "On" or LeaSoundsDB[var] == "Off" then
			LeaSoundsLC[var] = LeaSoundsDB[var]
		else
			LeaSoundsLC[var] = def
			LeaSoundsDB[var] = def
		end
	end

	-- Show tooltips for buttons (the addon has its own tooltip so the game tooltip is never touched and can't be tainted)
	function LeaSoundsLC:TipSee()
		local tip = LeaSoundsLC.Tooltip
		if not tip then
			tip = CreateFrame("GameTooltip", LeaSoundsLC:CreateRandomName(), UIParent, "GameTooltipTemplate")
			tip:SetFrameStrata("TOOLTIP")
			LeaSoundsLC.Tooltip = tip
		end
		tip:SetOwner(self, "ANCHOR_NONE")
		local parent = self:GetParent()
		local pscale = parent:GetEffectiveScale()
		local gscale = UIParent:GetEffectiveScale()
		local tscale = tip:GetEffectiveScale()
		local gap = ((UIParent:GetRight() * gscale) - (parent:GetRight() * pscale))
		if gap < (250 * tscale) then
			tip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
		else
			tip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
		end
		tip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end

	-- Hide the tooltip
	function LeaSoundsLC:TipHide()
		if LeaSoundsLC.Tooltip then LeaSoundsLC.Tooltip:Hide() end
	end

	-- Lock and unlock an item
	function LeaSoundsLC:LockItem(item, lock)
		if lock then
			item:Disable()
			item:SetAlpha(0.3)
		else
			item:Enable()
			item:SetAlpha(1.0)
		end
	end

	-- Create an editbox
	function LeaSoundsLC:CreateEditBox(frame, parent, width, maxchars, anchor, x, y)

		-- Create editbox
		local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
		eb:SetPoint(anchor, x, y)
		eb:SetWidth(width)
		eb:SetHeight(24)
		eb:SetFontObject("GameFontNormal")
		eb:SetTextColor(1.0, 1.0, 1.0)
		eb:SetAutoFocus(false)
		eb:SetMaxLetters(maxchars)
		eb:SetScript("OnEscapePressed", eb.ClearFocus)
		eb:SetScript("OnEnterPressed", eb.ClearFocus)

		-- Add editbox border and backdrop
		eb.f = CreateFrame("FRAME", nil, eb, "BackdropTemplate")
		eb.f:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 }})
		eb.f:SetPoint("LEFT", -6, 0)
		eb.f:SetWidth(eb:GetWidth()+6)
		eb.f:SetHeight(eb:GetHeight())
		eb.f:SetBackdropColor(1.0, 1.0, 1.0, 0.3)

		return eb

	end

	-- Create a button
	function LeaSoundsLC:CreateButton(name, frame, label, anchor, x, y, width, height, tip)
		local mbtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		LeaSoundsCB[name] = mbtn
		mbtn:SetSize(width, height)
		mbtn:SetPoint(anchor, x, y)
		mbtn:SetHitRectInsets(0, 0, 0, 0)
		mbtn:SetText(L[label])

		-- Tooltip handler
		if tip then
			mbtn.tiptext = L[tip]
			mbtn:SetScript("OnEnter", LeaSoundsLC.TipSee)
			mbtn:SetScript("OnLeave", LeaSoundsLC.TipHide)
		end

		-- Create fontstring and set button width based on it
		mbtn.f = mbtn:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		mbtn.f:SetText(L[label])
		if width > 0 then
			-- Button should have static width
			mbtn:SetWidth(width)
			local buttonText = mbtn:GetFontString()
			buttonText:SetWidth(width - 10)
			buttonText:SetNonSpaceWrap(false)
			buttonText:SetWordWrap(false)
			buttonText:SetJustifyH("CENTER")
		else
			-- Button should have variable width
			mbtn:SetWidth(mbtn.f:GetStringWidth() + 20)
		end

		-- Set skinned button textures
		mbtn:SetNormalTexture("Interface\\AddOns\\Leatrix_Sounds\\Leatrix_Sounds.blp")
		mbtn:GetNormalTexture():SetTexCoord(0.5, 1, 0, 1)
		mbtn:SetHighlightTexture("Interface\\AddOns\\Leatrix_Sounds\\Leatrix_Sounds.blp")
		mbtn:GetHighlightTexture():SetTexCoord(0, 0.5, 0, 1)

		-- Hide the default textures
		mbtn:HookScript("OnShow", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)
		mbtn:HookScript("OnEnable", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)
		mbtn:HookScript("OnDisable", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)
		mbtn:HookScript("OnMouseDown", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)
		mbtn:HookScript("OnMouseUp", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)

		return mbtn
	end

	-- Create a subheading
	function LeaSoundsLC:MakeTx(frame, title, x, y)
		local text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		text:SetPoint("TOPLEFT", x, y)
		text:SetText(L[title])
		return text
	end

	-- Create a checkbox
	function LeaSoundsLC:MakeCB(field, caption, x, y, tip)

		-- Create the checkbox
		local Cbox = CreateFrame("CheckButton", nil, LeaSoundsLC["PageF"], "ChatConfigCheckButtonTemplate")
		LeaSoundsCB[field] = Cbox
		Cbox:SetPoint("TOPLEFT",x, y)
		Cbox:SetScript("OnEnter", LeaSoundsLC.TipSee)
		Cbox:SetScript("OnLeave", LeaSoundsLC.TipHide)

		-- Add label and tooltip
		Cbox.f = Cbox:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
		Cbox.f:SetPoint('LEFT', 20, 0)
		Cbox.f:SetText(L[caption])
		Cbox.tiptext = L[tip]

		-- Set label parameters
		Cbox.f:SetJustifyH("LEFT")
		Cbox.f:SetWordWrap(false)

		-- Set maximum label width
		if Cbox.f:GetWidth() > 60 then
			Cbox.f:SetWidth(60 - 10)
		end

		-- Set checkbox click width
		if Cbox.f:GetStringWidth() > 60 then
			Cbox:SetHitRectInsets(0, -50, 0, 0)
		else
			Cbox:SetHitRectInsets(0, -Cbox.f:GetStringWidth() + 4, 0, 0)
		end

		-- Set default checkbox state
		Cbox:SetScript('OnShow', function(self)
			if LeaSoundsLC[field] == "On" then
				self:SetChecked(true)
			else
				self:SetChecked(false)
			end
		end)

		-- Process clicks
		Cbox:SetScript('OnClick', function()
			if Cbox:GetChecked() then
				LeaSoundsLC[field] = "On"
			else
				LeaSoundsLC[field] = "Off"
			end
		end)
	end

	----------------------------------------------------------------------
	-- L20: Player
	----------------------------------------------------------------------

	function LeaSoundsLC:Player()

		-- Create music table
		Leatrix_Sounds["Listing"] = {}

		-- Create panel
		local PageF = CreateFrame("Frame", LeaSoundsLC:CreateRandomName(), UIParent)

		-- Make it a system frame
		table.insert(UISpecialFrames, PageF:GetName())

		-- Set frame parameters
		LeaSoundsLC["PageF"] = PageF
		frameWidth, frameHeight = LeaSoundsLC["MainPanelW"], LeaSoundsLC["MainPanelH"]
		PageF:SetSize(frameWidth, frameHeight)
		PageF:SetScale(1.1)
		PageF:Hide()
		PageF:SetFrameStrata("FULLSCREEN_DIALOG")
		PageF:SetFrameLevel(40)
		PageF:SetClampedToScreen(true)
		PageF:SetClampRectInsets(550, -550, -200, 200)
		PageF:ClearAllPoints()
		PageF:SetPoint("CENTER", 0, 0)
		PageF:EnableMouse(true)
		PageF:SetMovable(true)
		PageF:RegisterForDrag("LeftButton")
		PageF:SetScript("OnDragStart", PageF.StartMoving)
		PageF:SetScript("OnDragStop", function()
			PageF:StopMovingOrSizing()
			PageF:SetUserPlaced(false)
			-- Save panel position
			LeaSoundsLC["MainPanelA"], void, LeaSoundsLC["MainPanelR"], LeaSoundsLC["MainPanelX"], LeaSoundsLC["MainPanelY"] = PageF:GetPoint()
		end)

		-- Add background color
		PageF.t = PageF:CreateTexture(nil, "BACKGROUND")
		PageF.t:SetAllPoints()
		PageF.t:SetColorTexture(0.05, 0.05, 0.05, 0.9)

		-- Add textures
		PageF.mainTex = PageF:CreateTexture(nil, "BORDER")
		PageF.mainTex:SetTexture("Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated.png")
		PageF.mainTex:SetPoint("TOPLEFT")
		PageF.mainTex:SetPoint("BOTTOMRIGHT", 0, 35)
		PageF.mainTex:SetVertexColor(0.7, 0.7, 0.7, 0.7)
		PageF.mainTex:SetTexCoord(0.09, 1, 0, 1)

		PageF.footTex = PageF:CreateTexture(nil, "BORDER")
		PageF.footTex:SetTexture("Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment-Horizontal-Desaturated.png")
		PageF.footTex:SetHeight(48)
		PageF.footTex:SetPoint("BOTTOMLEFT")
		PageF.footTex:SetPoint("BOTTOMRIGHT")
		PageF.footTex:SetVertexColor(0.5, 0.5, 0.5, 1.0)

		-- Add close Button
		PageF.cb = LeaSoundsLC:CreateCloseButton(PageF, 30, 30, "TOPRIGHT", 0, 0)
		PageF.cb:SetScript("OnClick", function() PageF:Hide() end)

		-- Set panel position when shown
		PageF:SetScript("OnShow", function()
			PageF:ClearAllPoints()
			PageF:SetPoint(LeaSoundsLC["MainPanelA"], UIParent, LeaSoundsLC["MainPanelR"], LeaSoundsLC["MainPanelX"], LeaSoundsLC["MainPanelY"])
		end)

		-- Create locals
		local ListData, searchTable = {}, {}
		local scrollFrame, musicHandle, lastPlayed, playScroll, void
		-- The sound kit listing (nil when the normal listing is shown) and the function which closes it
		local kitView, EndKitView
		-- How far the listing is moved right to make room for the sound kit list (0 when it isn't shown)
		local listIndent = 0
		-- Number of visible rows (13 at a panel height of 308, changes when the panel is resized)
		local numButtons = 13
		-- The first rows of the listing (the title, the number of results and a blank row) are shown in a header above the listing which doesn't scroll
		local headerRows = 3
		-- The Sound Files heading after them isn't shown either (the header shows what the listing is), but messages such as No search results found are
		local soundFilesHeading = "|cffffd800" .. L["Sound Files"]
		local function ListStart()
			if ListData[headerRows + 1] == soundFilesHeading then return headerRows + 1 end
			return headerRows
		end
		-- The sound files are split into tables the first time the panel is shown (nothing is listed until then)
		local dataLoaded
		-- Sound files which can't be played in this game version (track string = true, marked by the R script in the data file)
		local unplayableSet = {}

		-- Muted sounds table (sound file ID = track string), saved in LeaSoundsDB
		local MutedSounds = LeaSoundsLC["MutedSounds"]

		-- Get the numeric sound file ID from a track string
		local function GetTrackID(track)
			if not track or track == "" or strfind(track, "|c") then return end
			return tonumber(track:match("#(%d+)$"))
		end

		-- Check if a track is muted
		local function IsTrackMuted(track)
			local id = GetTrackID(track)
			return id and MutedSounds[id] and true or false
		end

		----------------------------------------------------------------------
		-- Selection (click to select one, CONTROL to add or remove, SHIFT for a range)
		----------------------------------------------------------------------

		local selected, anchor = {}, nil

		-- Clear the selection
		local function ClearSelection()
			wipe(selected)
			anchor = nil
		end

		-- Select only one track
		local function SelectOnly(track)
			wipe(selected)
			selected[track] = true
			anchor = track
		end

		-- Add or remove a track from the selection
		local function ToggleSelected(track)
			selected[track] = not selected[track] or nil
			anchor = track
		end

		-- Select the range of tracks between the anchor and the clicked track (add keeps the current selection)
		local function SelectRange(track, add)
			local a, b
			if anchor then
				for i = 1, #ListData do
					if ListData[i] == anchor then a = i end
					if ListData[i] == track then b = i end
				end
			end
			if not add then wipe(selected) end
			if not a or not b then
				-- No anchor in the listing so select just the clicked track
				selected[track] = true
				anchor = track
				return
			end
			if a > b then a, b = b, a end
			for i = a, b do
				if GetTrackID(ListData[i]) then selected[ListData[i]] = true end
			end
		end

		-- Get the selected tracks in listing order
		local function GetSelectedTracks()
			local tracks = {}
			for i = 1, #ListData do
				if selected[ListData[i]] then tinsert(tracks, ListData[i]) end
			end
			return tracks
		end

		-- Remove tracks from the selection which are no longer in the listing
		local function PruneSelection()
			local listed, anchorListed = {}, false
			for i = 1, #ListData do
				local track = ListData[i]
				if selected[track] then listed[track] = true end
				if track == anchor then anchorListed = true end
			end
			for track in pairs(selected) do
				if not listed[track] then selected[track] = nil end
			end
			if not anchorListed then anchor = nil end
		end

		-- Muted sound preview (a muted sound is unmuted while it's previewed then muted again)
		local previewID, previewHandle, previewTicker

		-- End the preview and mute the sound again if it's still on the muted list
		local function EndPreview()
			if previewTicker then previewTicker:Cancel(); previewTicker = nil end
			if previewID and MutedSounds[previewID] and MuteSoundFile then MuteSoundFile(previewID) end
			previewID, previewHandle = nil, nil
		end

		-- Play a muted sound so the user can hear it while keeping it muted in the game
		local function PreviewMutedSound(id)
			EndPreview()
			if UnmuteSoundFile then UnmuteSoundFile(id) end
			local willPlay, handle = PlaySoundFile(id, "Master")
			if not willPlay or not handle or not (C_Sound and C_Sound.IsPlaying) then
				-- Can't tell when the sound finishes so mute it again straight away
				if MuteSoundFile then MuteSoundFile(id) end
				return handle
			end
			previewID, previewHandle = id, handle
			-- Mute the sound again when the preview finishes
			previewTicker = C_Timer.NewTicker(0.25, function()
				if not previewHandle or not C_Sound.IsPlaying(previewHandle) then EndPreview() end
			end)
			return handle
		end


		----------------------------------------------------------------------
		-- Back and forward buttons (play the previous or next track)
		----------------------------------------------------------------------

		local prevBtn, nextBtn
		-- Position of the current track (lastPlayed) in the listing, cached until the listing changes
		local listVersion, cacheVersion, cacheTrack, currentIndex = 0, nil, nil, nil

		-- The listing has changed so the current track position needs finding again
		local function ListChanged()
			listVersion = listVersion + 1
		end

		-- Get the position of the current track in the listing (nil if it isn't there)
		local function GetCurrentIndex()
			if not lastPlayed or lastPlayed == "" then return nil end
			if cacheVersion ~= listVersion or cacheTrack ~= lastPlayed then
				currentIndex = nil
				for i = 1, #ListData do
					if ListData[i] == lastPlayed then currentIndex = i; break end
				end
				cacheVersion, cacheTrack = listVersion, lastPlayed
			end
			return currentIndex
		end

		-- Lock the back and forward buttons when they can't be used
		-- Find the track before (step -1) or after (step 1) a listing position, going round to the other end of the listing
		-- (headings and messages are skipped, nil if there are no tracks)
		local function FindAdjacentTrack(index, step)
			local count = #ListData
			local i = index
			for void = 1, count do
				i = i + step
				if i > count then i = 1 elseif i < 1 then i = count end
				if GetTrackID(ListData[i]) then return i end
			end
		end

		-- They can be used whenever a sound is playing (whatever is selected) as long as the playing sound is in the listing
		local function UpdateNavButtons()
			if not prevBtn then return end
			local index = not LeaSoundsLC.SettingsShown and musicHandle and GetCurrentIndex()
			LeaSoundsLC:LockItem(prevBtn, not (index and FindAdjacentTrack(index, -1)))
			LeaSoundsLC:LockItem(nextBtn, not (index and FindAdjacentTrack(index, 1)))
		end

		-- Show list items
		local function UpdateList()
			-- Keep the listing hidden while settings or the mounts list are showing
			if LeaSoundsLC.SettingsShown or LeaSoundsLC.MountsShown then
				scrollFrame.header:Hide()
				for i, button in ipairs(scrollFrame.buttons) do button:Hide() end
				UpdateNavButtons()
				return
			end
			-- Nothing to list until the sound files have loaded
			scrollFrame.header:Show()
			if not dataLoaded or not ListData[1] then
				scrollFrame.header.title:SetText("|cffffd800" .. L["Leatrix Sounds"])
				scrollFrame.header.results:SetText("")
				for i, button in ipairs(scrollFrame.buttons) do button:Hide() end
				scrollFrame.child:SetSize(200, 1)
				UpdateNavButtons()
				return
			end
			-- Add headers to ListData if needed
			if not strfind(ListData[1], "|c") then
				tinsert(ListData, 1, "|cffffd800" .. L["Leatrix Sounds"] .. " " .. LeaSoundsLC["AddonVer"])
				tinsert(ListData, 2, "|cffffffaa{" .. #Leatrix_Sounds["Listing"] - 1 .. " " .. L["results"] .. "}")
				tinsert(ListData, 3, "|cffffffff")
				tinsert(ListData, 4, "|cffffd800" .. L["Sound Files"])
			end
			-- Title and number of results go in the header
			-- (the version is shown at the top of the help instead)
			scrollFrame.header.title:SetText("|cffffd800" .. L["Leatrix Sounds"])
			-- The number of results is shown without the brackets and with thousands separators (such as 240,412 results)
			local count, word = strmatch(ListData[2] or "", "{(%d+) (.-)}")
			if count then
				count = BreakUpLargeNumbers and BreakUpLargeNumbers(tonumber(count)) or count
				scrollFrame.header.results:SetText("|cffffffaa" .. count .. " " .. word)
			else
				scrollFrame.header.results:SetText(ListData[2] or "")
			end
			-- Update the sound kit title and list (this also sets how far the listing is moved right)
			if LeaSoundsLC.UpdateKitNav then LeaSoundsLC.UpdateKitNav() end
			-- Update buttons (the listing starts after the header rows)
			local offset = max(0, floor(scrollFrame:GetVerticalScroll() + 0.5))
			local start = ListStart()
			-- Width for the track text (narrower while the sound kit list is shown)
			local textWidth = frameWidth - 60 - listIndent
			for i, button in ipairs(scrollFrame.buttons) do
				local index = start + offset + i
				if index <= #ListData and i <= numButtons then
					-- Move the row right while the sound kit list is shown
					if button.indent ~= listIndent then
						button.indent = listIndent
						button:ClearAllPoints()
						button:SetPoint("TOPLEFT", 16 + listIndent, -44 - (i - 1) * 16)
					end
					-- Show track listing
					button:SetText(ListData[index])
					button.listIndex = index
					-- Show muted tracks in red, the playing track in gold and unplayable tracks in grey
					local playing = musicHandle and ListData[index] == lastPlayed
					if IsTrackMuted(ListData[index]) then
						button:GetFontString():SetTextColor(1.0, 0.35, 0.35)
					elseif playing then
						button:GetFontString():SetTextColor(1.0, 0.82, 0.0)
					elseif unplayableSet[ListData[index]] then
						button:GetFontString():SetTextColor(0.5, 0.5, 0.5)
					else
						button:GetFontString():SetTextColor(1.0, 1.0, 1.0)
					end
					-- Set width of highlight texture
					if button:GetTextWidth() > textWidth then
						button.t:SetSize(textWidth, 16)
					else
						button.t:SetSize(button:GetTextWidth(), 16)
					end
					-- Show the button
					button:Show()
					-- Hide highlight bar texture by default
					button.s:Hide()
					-- Hide highlight bar if the button is a heading
					if strfind(button:GetText(), "|c") then button.t:Hide() end
					-- Show selected tracks highlight bar texture
					if selected[ListData[index]] then
						button.s:Show()
					end
					-- Set width of highlight bar
					if button:GetTextWidth() > textWidth then
						button.s:SetSize(textWidth, 16)
					else
						button.s:SetSize(button:GetTextWidth(), 16)
					end
					-- Limit click to label width
					local bWidth = button:GetFontString():GetStringWidth() or 0
					if bWidth > textWidth then bWidth = textWidth end
					button:SetHitRectInsets(0, 454 - bWidth, 0, 0)
					-- Disable label click movement
					button:SetPushedTextOffset(0, 0)
					-- Disable word wrap and set width
					button:GetFontString():SetWidth(textWidth)
					button:GetFontString():SetWordWrap(false)
				else
					button:Hide()
				end
			end
			-- Scroll range is one step per row (the listing can scroll until the last track is in the bottom row)
			scrollFrame.child:SetSize(200, max(1, #ListData - start + floor(scrollFrame:GetHeight() + 0.5) - numButtons)) --++ LeaSoundsLC.NewPatch
			-- Lock the back and forward buttons when they can't be used
			UpdateNavButtons()
		end

		-- Create scroll frame
		scrollFrame = CreateFrame("ScrollFrame", nil, LeaSoundsLC["PageF"], "LeaSoundsConfigurationPanelScrollFrameTemplate")
		scrollFrame:SetPoint("TOPLEFT", 0, -42)
		scrollFrame:SetPoint("BOTTOMRIGHT", -30, 52)

		-- Header above the listing with the title on the left, the number of results on the right and a line under it (it doesn't scroll)
		scrollFrame.header = CreateFrame("Frame", nil, LeaSoundsLC["PageF"])
		scrollFrame.header:SetPoint("TOPLEFT", 16, -14)
		scrollFrame.header:SetPoint("TOPRIGHT", -34, -14)
		scrollFrame.header:SetHeight(26)
		-- (the same size font as the settings and help titles, and the line is level with theirs)
		-- The number of results is in smaller text than the title (moved down so the bottoms of the two line up)
		scrollFrame.header.results = scrollFrame.header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		scrollFrame.header.results:SetPoint("TOPRIGHT", 0, -4)
		scrollFrame.header.results:SetJustifyH("RIGHT")
		scrollFrame.header.results:SetWordWrap(false)
		scrollFrame.header.title = scrollFrame.header:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		scrollFrame.header.title:SetJustifyH("LEFT")
		scrollFrame.header.title:SetPoint("TOPLEFT", 0, 0)
		scrollFrame.header.title:SetPoint("RIGHT", scrollFrame.header.results, "LEFT", -10, 0)
		scrollFrame.header.title:SetWordWrap(false)
		scrollFrame.header.line = scrollFrame.header:CreateTexture(nil, "ARTWORK")
		scrollFrame.header.line:SetColorTexture(0.6, 0.6, 0.6, 0.5)
		scrollFrame.header.line:SetHeight(1)
		scrollFrame.header.line:SetPoint("TOPLEFT", 0, -24)
		scrollFrame.header.line:SetPoint("TOPRIGHT", 0, -24)
		scrollFrame:SetPanExtent(1)
		-- Hooked so the template keeps its own handler, which moves the scroll bar thumb when the listing is scrolled
		scrollFrame:HookScript("OnVerticalScroll", UpdateList)

		-- Mousewheel: hold SHIFT to scroll a page at a time
		local defaultWheel = scrollFrame:GetScript("OnMouseWheel")
		scrollFrame:SetScript("OnMouseWheel", function(self, delta, ...)
			if IsShiftKeyDown() then
				local range = self:GetVerticalScrollRange()
				self:SetVerticalScroll(max(0, min(range, floor(self:GetVerticalScroll() + 0.5) - delta * numButtons)))
			elseif defaultWheel then
				defaultWheel(self, delta, ...)
			end
		end)

		-- Create the scroll child
		scrollFrame.child = CreateFrame("Frame", nil, scrollFrame)
		scrollFrame:SetScrollChild(scrollFrame.child)

		-- Give scroll frame file level scope
		LeaSoundsLC.scrollFrame = scrollFrame

		-- Add stop button
		local stopBtn = LeaSoundsLC:CreateButton("StopPlaybackButton", LeaSoundsLC["PageF"], "Stop", "BOTTOMRIGHT", -16, 12, 40, 25)
		stopBtn:Hide(); stopBtn:Show()
		LeaSoundsLC:LockItem(stopBtn, true)

		-- Watch the playing sound and run OnPlaybackFinished when it finishes
		local playTicker, OnPlaybackFinished
		local function WatchPlayback()
			if playTicker then playTicker:Cancel(); playTicker = nil end
			if not musicHandle then
				-- Nothing is playing (such as a sound that can't be played) so lock it now
				LeaSoundsLC:LockItem(stopBtn, true)
				return
			end
			-- Can't tell when the sound finishes so leave the stop button unlocked
			if not (C_Sound and C_Sound.IsPlaying) then return end
			local ticker
			ticker = C_Timer.NewTicker(0.25, function()
				if not musicHandle or not C_Sound.IsPlaying(musicHandle) then
					ticker:Cancel()
					if playTicker == ticker then playTicker = nil end
					OnPlaybackFinished()
				end
			end)
			playTicker = ticker
		end
		stopBtn:SetScript("OnClick", function()
			-- (The chat editbox is left alone because changing its focus runs the game's chat code from the addon, which taints it)
			-- Stop currently playing track
			if musicHandle then
				StopSound(musicHandle)
				musicHandle = nil
			end
			-- Mute the previewed sound again
			EndPreview()
			UpdateList()
			-- Lock button
			LeaSoundsLC:LockItem(stopBtn, true)
		end)

		-- Create editbox for search
		-- Button widths for the bottom bar
		local searchWidth, stopWidth, prevWidth, nextWidth, menuBtnWidth = 400, 64, 86, 60, 70

		local sBox = LeaSoundsLC:CreateEditBox("SearchBox", LeaSoundsLC["PageF"], searchWidth, 100, "BOTTOMLEFT", 16, 12)
		LeaSoundsCB["sBox"] = sBox

		-- Reposition stop button so its next to the search box
		stopBtn:ClearAllPoints()
		stopBtn:SetPoint("LEFT", sBox, "RIGHT", 10, 0)

		-- Add a gold icon to a button next to its text
		-- kind is "stop" (square), "previous" (left arrow), "next" (right arrow, after the text) or "menu" (three lines)
		local iconGold = {1.0, 0.82, 0.0}
		local function AddButtonIcon(btn, width, kind)
			btn:SetPushedTextOffset(0, 0)
			-- The icon texture (or an empty texture holding the menu lines) sized for the layout
			local icon = btn:CreateTexture(nil, "ARTWORK")
			btn.icon = icon
			local iconW, iconH
			if kind == "stop" then
				iconW, iconH = 8, 8
				icon:SetColorTexture(iconGold[1], iconGold[2], iconGold[3])
			elseif kind == "previous" or kind == "next" then
				-- Draw a triangle by pulling two corners of a square into a point
				iconW, iconH = 7, 10
				if icon.SetVertexOffset then
					icon:SetColorTexture(iconGold[1], iconGold[2], iconGold[3])
					if kind == "next" then
						icon:SetVertexOffset(UPPER_RIGHT_VERTEX or 3, 0, -iconH / 2)
						icon:SetVertexOffset(LOWER_RIGHT_VERTEX or 4, 0, iconH / 2)
					else
						icon:SetVertexOffset(UPPER_LEFT_VERTEX or 1, 0, -iconH / 2)
						icon:SetVertexOffset(LOWER_LEFT_VERTEX or 2, 0, iconH / 2)
					end
				else
					-- Game can't draw triangles so use the chat arrow (it points right so flip it for previous)
					iconW, iconH = 12, 12
					icon:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
					if kind == "previous" then icon:SetTexCoord(1, 0, 0, 1) end
				end
			elseif kind == "reset" then
				-- Round arrow (in gold like the other icons)
				iconW, iconH = 12, 12
				icon:SetTexture("Interface\\Buttons\\UI-RefreshButton")
				icon:SetDesaturated(true)
				icon:SetVertexColor(iconGold[1], iconGold[2], iconGold[3])
			elseif kind == "menu" then
				-- Three lines
				iconW, iconH = 10, 8
				for i = 1, 3 do
					local line = btn:CreateTexture(nil, "ARTWORK")
					line:SetColorTexture(iconGold[1], iconGold[2], iconGold[3])
					line:SetSize(iconW, 2)
					line:SetPoint("TOP", icon, "TOP", 0, -(i - 1) * 3)
				end
			end
			icon:SetSize(iconW, iconH)
			-- Center the icon and text together in the button (icon after the text for next)
			local fs = btn:GetFontString()
			fs:ClearAllPoints()
			fs:SetWidth(0)
			fs:SetJustifyH("LEFT")
			local gap = 5
			-- Make the button wider if the (translated) text doesn't fit
			width = max(width, ceil(iconW + gap + fs:GetStringWidth() + 20))
			btn:SetWidth(width)
			local left = floor((width - (iconW + gap + fs:GetStringWidth())) / 2 + 0.5)
			if kind == "next" then
				fs:SetPoint("LEFT", btn, "LEFT", left, 0)
				icon:SetPoint("LEFT", fs, "RIGHT", gap, 0)
			else
				icon:SetPoint("LEFT", btn, "LEFT", left, 0)
				fs:SetPoint("LEFT", icon, "RIGHT", gap, 0)
			end
			return icon
		end

		-- Stop button gets a stop (square) icon
		AddButtonIcon(stopBtn, stopWidth, "stop")
		stopWidth = stopBtn:GetWidth()

		-- Previous and next buttons are centered in the gap between the stop button and the menu button
		prevBtn = LeaSoundsLC:CreateButton("PrevTrackButton", PageF, "Previous", "BOTTOMRIGHT", -16, 12, prevWidth, 25)
		AddButtonIcon(prevBtn, prevWidth, "previous")
		prevWidth = prevBtn:GetWidth()
		nextBtn = LeaSoundsLC:CreateButton("NextTrackButton", PageF, "Next", "BOTTOMRIGHT", -16, 12, nextWidth, 25)
		AddButtonIcon(nextBtn, nextWidth, "next")
		nextWidth = nextBtn:GetWidth()
		-- Size the search box to the panel width and center the previous and next buttons (run again when the panel is resized)
		local function LayoutBottomBar()
			searchWidth = min(400, max(150, frameWidth - 400 - max(0, stopWidth + prevWidth + nextWidth + menuBtnWidth - 280)))
			sBox:SetWidth(searchWidth)
			sBox.f:SetWidth(searchWidth + 6)
			local stopRight = 16 + searchWidth + 10 + stopWidth
			local menuLeft = frameWidth - 10 - menuBtnWidth
			local pairWidth = prevWidth + 6 + nextWidth
			prevBtn:ClearAllPoints()
			prevBtn:SetPoint("LEFT", stopBtn, "RIGHT", max(6, floor((menuLeft - stopRight - pairWidth) / 2)), 0)
		end
		LayoutBottomBar()
		nextBtn:ClearAllPoints()
		nextBtn:SetPoint("LEFT", prevBtn, "RIGHT", 6, 0)
		LeaSoundsLC:LockItem(prevBtn, true)
		LeaSoundsLC:LockItem(nextBtn, true)

		-- Function to show search results
		-- Check once if any sound file names have capital letters (they are normally all lower case so they don't need lowering for every search)
		local sourcesNeedLower
		local function CheckSourcesNeedLower()
			if sourcesNeedLower ~= nil then return end
			sourcesNeedLower = false
			for void, key in ipairs({"MP3", "OGG", "EXT"}) do
				local source = Leatrix_Sounds[key]
				for i = 1, #source do
					if strfind(source[i], "%u") then sourcesNeedLower = true; return end
				end
			end
		end

		-- The last search, so typing more letters can search the current results instead of the whole listing
		local lastSearch, lastSearchValid, lastResultCount

		-- Forget the last search (used when the listing changes)
		local function ResetLastSearch()
			lastSearch, lastSearchValid, lastResultCount = nil, nil, nil
		end

		-- Check if the new search can only match tracks which the last search matched
		local function CanNarrow(old, new)
			if not old or not lastSearchValid or #new <= #old or strsub(new, 1, #old) ~= old then return false end
			-- Extending an exclude keyword (such as !dea to !death) excludes fewer tracks so needs a full search
			local lastWord = old:match("(%S+)$")
			if lastWord and not strfind(strsub(new, #old + 1), "^%s") then
				if strsub(lastWord, 1, 1) == "!" and lastWord ~= "!" then return false end
			end
			return true
		end

		local function ShowSearchResults()

			-- Searches made while the sound files are loading are run when loading finishes
			if not dataLoaded then return end

			playScroll = nil

			local Listing = Leatrix_Sounds["Listing"]
			local searchText = strlower(sBox:GetText())

			-- The displayed listing is changing
			ListChanged()

			-- Empty search shows the whole listing
			if searchText == "" then
				ResetLastSearch()
				ListData = Listing
				UpdateList()
				scrollFrame:SetVerticalScroll(0)
				return
			end

			-- Results are written over the previous results and trimmed at the end (faster than wiping)
			local results = searchTable
			ListData = results
			local oldCount = #results

			-- Set headings
			results[1] = "|cffffd800" .. L["Leatrix Sounds"] .. " " .. LeaSoundsLC["AddonVer"]
			results[2] = ""
			results[3] = "|cffffffff"
			results[4] = "|cffffd800" .. L["Sound Files"]
			local n = 4

			-- Split search into up to 10 keywords (keywords starting with ! are excluded, ! on its own is ignored)
			local words = {strsplit(" ", (strtrim(searchText):gsub("%s+", " ")))}
			local include, exclude, valid = {}, {}, true
			for i = 1, min(#words, 10) do
				local word = words[i]
				if word == "" then
					-- Search was only spaces
					valid = false
				elseif word ~= "!" then
					if strsub(word, 1, 1) == "!" then
						tinsert(exclude, strsub(word, 2))
					else
						tinsert(include, word)
					end
				end
			end

			-- Traverse listing and add matching tracks (plain text search, no patterns)
			if valid then
				CheckSourcesNeedLower()
				local needLower = sourcesNeedLower
				local ni, ne = #include, #exclude
				-- Search the last results if more letters were typed, otherwise search the whole listing
				-- (searching the last results in place is safe because results are only ever written at or before the position being read)
				local source, first, last
				if CanNarrow(lastSearch, searchText) then
					source, first, last = results, 5, 4 + lastResultCount
				else
					-- Tracks start after the 4 headings (if there are no tracks, there is a message line instead)
					source, first, last = Listing, 5, #Listing
					if Listing[5] and strfind(Listing[5], "|c", 1, true) then first = 6 end
				end
				for k = first, last do
					local track = source[k]
					local v = needLower and strlower(track) or track
					local match = true
					for i = 1, ni do
						if not strfind(v, include[i], 1, true) then match = false; break end
					end
					if match then
						for i = 1, ne do
							if strfind(v, exclude[i], 1, true) then match = false; break end
						end
					end
					if match then n = n + 1; results[n] = track end
				end
			end

			-- Set results tag
			if n == 5 then
				results[2] = "|cffffffaa{" .. (n - 4) .. " " .. L["result"] .. "}"
			else
				results[2] = "|cffffffaa{" .. (n - 4) .. " " .. L["results"] .. "}"
			end
			local count = n
			-- Show message if no results found
			if n == 4 then
				results[4] = "|cffffd800" .. L["No search results found"]
				results[5] = "|cffffffff" .. L["So I guess there's nothing to see here."]
				count = 5
			end
			-- Show message if no sound categories are checked
			if LeaSoundsLC["SoundMuted"] == "Off" and LeaSoundsLC["SoundMusic"] == "Off" and LeaSoundsLC["SoundSFX"] == "Off" and LeaSoundsLC["SoundUnknown"] == "Off" and LeaSoundsLC["SoundUnplayable"] == "Off" then
				results[4] = "|cffffd800" .. L["Oops!"]
				results[5] = "|cffffffff" .. L["You need to select at least one sound category."]
				if count < 5 then count = 5 end
			end
			-- Remember this search
			lastSearch, lastSearchValid, lastResultCount = searchText, valid, n - 4
			-- Remove the rest of the previous results
			for i = count + 1, oldCount do
				results[i] = nil
			end
			-- Refresh the track listing
			UpdateList()
			-- Set track listing to top
			scrollFrame:SetVerticalScroll(0)
		end

		-- When editbox is changed by user, show search results
		sBox:HookScript("OnTextChanged", function(self, userInput)
			if userInput then
				-- Typing a search closes settings
				if LeaSoundsLC.SettingsShown and LeaSoundsLC.CloseSettings then LeaSoundsLC.CloseSettings() end
				if LeaSoundsLC.Timer then LeaSoundsLC.Timer:Cancel() end
				LeaSoundsLC.Timer = C_Timer.NewTimer(0.2, function()
					-- Searching closes the sound kit listing
					if kitView then EndKitView() end
					ClearSelection()
					ListData = searchTable
					ShowSearchResults()
				end)
			end
		end)

		-- When enter key is pressed, show search results
		sBox:HookScript("OnEnterPressed", function()
			if kitView then EndKitView() end
			ClearSelection()
			ListData = searchTable
			ShowSearchResults()
		end)

		-- Clear search button (the usual cross inside the right end of the editbox)
		local clearBtn = CreateFrame("Button", nil, sBox)
		LeaSoundsCB["SearchClearButton"] = clearBtn
		clearBtn:SetSize(17, 17)
		clearBtn:SetPoint("RIGHT", sBox, "RIGHT", -2, 0)
		clearBtn.tex = clearBtn:CreateTexture(nil, "ARTWORK")
		clearBtn.tex:SetTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
		clearBtn.tex:SetAllPoints()
		clearBtn.tex:SetAlpha(0.5)
		clearBtn:SetScript("OnEnter", function() clearBtn.tex:SetAlpha(1.0) end)
		clearBtn:SetScript("OnLeave", function() clearBtn.tex:SetAlpha(0.5) end)
		clearBtn:SetScript("OnMouseDown", function() clearBtn.tex:SetPoint("TOPLEFT", 1, -1) end)
		clearBtn:SetScript("OnMouseUp", function() clearBtn.tex:SetPoint("TOPLEFT", 0, 0) end)
		clearBtn:Hide()

		-- Keep typed text clear of the cross
		sBox:SetTextInsets(0, 20, 0, 0)

		-- Only show the cross when there is text to clear
		sBox:HookScript("OnTextChanged", function(self)
			if self:GetText() ~= "" then clearBtn:Show() else clearBtn:Hide() end
		end)

		-- Clear the search and show the full listing
		clearBtn:SetScript("OnClick", function()
			if LeaSoundsLC.Timer then LeaSoundsLC.Timer:Cancel() end
			sBox:SetText("")
			sBox:ClearFocus()
			clearBtn:Hide()
			if kitView then EndKitView() end
			ClearSelection()
			ListData = searchTable
			ShowSearchResults()
		end)

		-- Check a table is in order
		local function IsSorted(t)
			for i = 2, #t do
				if t[i] < t[i - 1] then return false end
			end
			return true
		end

		-- Make sure the music and effects tables are in order (done once)
		local sourcesSorted

		-- Find the first position in a sorted table where the entry is not less than value
		local function LowerBound(source, value)
			local lo, hi = 1, #source + 1
			while lo < hi do
				local mid = floor((lo + hi) / 2)
				if source[mid] < value then lo = mid + 1 else hi = mid end
			end
			return lo
		end

		-- Split a sorted table into blocks of tracks by category ({first, last, category number} for each block)
		-- Each path prefix is found with a binary search so the tracks don't need checking one by one
		local function BuildCategoryRuns(source, categories)
			local runs = {}
			for c, cat in ipairs(categories) do
				for void, prefix in ipairs(cat[3]) do
					local first = LowerBound(source, prefix)
					local last = LowerBound(source, prefix .. "\255") - 1
					if last >= first then tinsert(runs, {first, last, c}) end
				end
			end
			table.sort(runs, function(a, b) return a[1] < b[1] end)
			-- Tracks between the blocks go in the last category (Other)
			local all, pos = {}, 1
			for void, run in ipairs(runs) do
				if run[1] > pos then tinsert(all, {pos, run[1] - 1, #categories}) end
				tinsert(all, run)
				pos = run[2] + 1
			end
			if pos <= #source then tinsert(all, {pos, #source, #categories}) end
			return all
		end

		local mp3Runs, oggRuns
		local function EnsureSourcesSorted()
			if sourcesSorted then return end
			if not IsSorted(Leatrix_Sounds["MP3"]) then table.sort(Leatrix_Sounds["MP3"]) end
			if not IsSorted(Leatrix_Sounds["OGG"]) then table.sort(Leatrix_Sounds["OGG"]) end
			-- Also check for capital letters now (at login) so the first search isn't slow
			CheckSourcesNeedLower()
			-- Work out where each music and effects category is in the sorted tables
			mp3Runs = BuildCategoryRuns(Leatrix_Sounds["MP3"], musicCategories)
			oggRuns = BuildCategoryRuns(Leatrix_Sounds["OGG"], effectCategories)
			sourcesSorted = true
		end

		-- Function to show sound listing
		local function SetListingFunc(keepPlaying)

			-- Category changes made while the sound files are loading are used when loading finishes
			if not dataLoaded then return end

			-- While the sound kit listing is shown, the listing is rebuilt when going back to it (such as after muting a sound in the sound kit listing)
			if kitView then
				if keepPlaying then kitView.rebuild = true; return end
				EndKitView()
				ListData = Leatrix_Sounds["Listing"]
			end

			-- The listing is changing so the next search needs to search all of it
			ResetLastSearch()
			ListChanged()

			-- The listing is overwritten in place and trimmed at the end (faster than wiping hundreds of thousands of entries)
			local Listing = Leatrix_Sounds["Listing"]
			local oldCount = #Listing

			-- A new listing clears the selection (the caller keeps what it can when keepPlaying is set)
			if not keepPlaying then ClearSelection() end

			-- Make sure the sound files are in order (only checked once, they are normally already in order)
			-- This means the listing can be built by merging the sound files instead of sorting hundreds of thousands of tracks every time
			EnsureSourcesSorted()

			local musicOn = LeaSoundsLC["SoundMusic"] == "On"
			local sfxOn = LeaSoundsLC["SoundSFX"] == "On"

			-- Music and effects categories (shown unless unchecked in the submenus)
			local musicCatOn, sfxCatOn, anyMusicCat, anySfxCat = {}, {}, false, false
			for c, cat in ipairs(musicCategories) do
				musicCatOn[c] = not LeaSoundsLC["MusicCatOff"][cat[1]]
				anyMusicCat = anyMusicCat or musicCatOn[c]
			end
			for c, cat in ipairs(effectCategories) do
				sfxCatOn[c] = not LeaSoundsLC["SFXCatOff"][cat[1]]
				anySfxCat = anySfxCat or sfxCatOn[c]
			end
			-- Music or Effects with every category unchecked shows nothing
			musicOn = musicOn and anyMusicCat
			sfxOn = sfxOn and anySfxCat
			local unknownOn = LeaSoundsLC["SoundUnknown"] == "On"

			-- Muted sounds belong to the Muted category instead of their own category
			local mutedOn = LeaSoundsLC["SoundMuted"] == "On"
			local mutedSet, hasMuted, found = {}, false, {}
			for id, track in pairs(MutedSounds) do
				mutedSet[track] = true
				hasMuted = true
			end

			-- Unplayable sounds belong to the Unplayable category instead of their own category (unless they're muted)
			local unplayableOn = LeaSoundsLC["SoundUnplayable"] == "On"
			local hasUnplayable = next(unplayableSet) ~= nil

			-- Source tables only need to be scanned if their category is on or muted or unplayable sounds are shown
			local scanMuted = (hasMuted and mutedOn) or (hasUnplayable and unplayableOn)

			-- Headings go first (results count is set at the end)
			Listing[1] = "|cffffd800" .. L["Leatrix Sounds"] .. " " .. LeaSoundsLC["AddonVer"]
			Listing[2] = ""
			Listing[3] = "|cffffffff"
			Listing[4] = "|cffffd800" .. L["Sound Files"]
			local n = 4
			-- Sounds in a checked category which are left out because they're muted or unplayable (to say why the listing is empty)
			local hiddenMuted, hiddenUnplayable = 0, 0

			-- Add tracks from source[first] to source[last] which should be shown (muted tracks follow the Muted category and unplayable tracks follow the Unplayable category)
			local function AddRange(source, first, last, catOn)
				if hasMuted or hasUnplayable then
					for i = first, last do
						local track = source[i]
						if mutedSet[track] then
							found[track] = true
							if mutedOn then n = n + 1; Listing[n] = track elseif catOn then hiddenMuted = hiddenMuted + 1 end
						elseif unplayableSet[track] then
							if unplayableOn then n = n + 1; Listing[n] = track elseif catOn then hiddenUnplayable = hiddenUnplayable + 1 end
						elseif catOn then
							n = n + 1; Listing[n] = track
						end
					end
				elseif catOn then
					-- No muted or unplayable sounds so this is a straight copy
					for i = first, last do
						n = n + 1; Listing[n] = source[i]
					end
				end
			end

			-- Add tracks from source[first] to source[last], each block also needing its category to be checked
			local function AddCategoryRange(source, runs, catOn, first, last, on)
				for r = 1, #runs do
					local run = runs[r]
					if run[1] > last then break end
					if run[2] >= first then
						AddRange(source, max(first, run[1]), min(last, run[2]), on and catOn[run[3]])
					end
				end
			end

			-- Find the first position in a sorted table where the entry is greater than track
			local function UpperBound(source, track)
				local lo, hi = 1, #source + 1
				while lo < hi do
					local mid = floor((lo + hi) / 2)
					if source[mid] > track then hi = mid else lo = mid + 1 end
				end
				return lo
			end

			-- Music and effects tracks are merged in order (both tables are in order so no sort is needed)
			local mp3, ogg = Leatrix_Sounds["MP3"], Leatrix_Sounds["OGG"]
			local scanMusic, scanSFX = musicOn or scanMuted, sfxOn or scanMuted
			local oi = 1
			if scanMusic then
				for i = 1, #mp3 do
					local track = mp3[i]
					if scanSFX then
						-- Add the effects tracks which come before this music track
						local upto = UpperBound(ogg, track) - 1
						if upto >= oi then
							AddCategoryRange(ogg, oggRuns, sfxCatOn, oi, upto, sfxOn)
							oi = upto + 1
						end
					end
					AddCategoryRange(mp3, mp3Runs, musicCatOn, i, i, musicOn)
				end
			end
			-- Add the remaining effects tracks
			if scanSFX and oi <= #ogg then
				AddCategoryRange(ogg, oggRuns, sfxCatOn, oi, #ogg, sfxOn)
			end

			-- Unknown tracks are added after the named tracks
			if unknownOn or scanMuted then
				AddRange(Leatrix_Sounds["EXT"], 1, #Leatrix_Sounds["EXT"], unknownOn)
			end

			-- Add muted sounds which are no longer in the sound files (so they can still be unmuted)
			if mutedOn then
				local missing = {}
				for track in pairs(mutedSet) do
					if not found[track] then tinsert(missing, track) end
				end
				table.sort(missing)
				for i = 1, #missing do
					n = n + 1; Listing[n] = missing[i]
				end
			end

			-- Set results count or show a message if there is nothing to show
			Listing[2] = "|cffffffaa{" .. (n - 4) .. " " .. L["results"] .. "}"
			local count = n
			if n == 4 then
				count = 5
				if not musicOn and not sfxOn and not unknownOn and not mutedOn and not unplayableOn then
					Listing[4] = "|cffffd800" .. L["Oops!"]
					Listing[5] = "|cffffffff" .. L["You need to select at least one sound category."]
				elseif mutedOn and not musicOn and not sfxOn and not unknownOn and not unplayableOn then
					Listing[4] = "|cffffd800" .. L["No muted sounds"]
					Listing[5] = "|cffffffff" .. L["To mute a sound, right-click it and choose Mute sound."]
				else
					-- Say why nothing is shown (sounds in the checked categories which are muted or unplayable are left out unless those are checked too)
					Listing[4] = "|cffffd800" .. L["No sounds to show"]
					if hiddenMuted > 0 and hiddenUnplayable > 0 then
						Listing[5] = "|cffffffff" .. L["All sounds in the selected categories are muted or unplayable.  Check Muted and Unplayable in the Menu to show them."]
					elseif hiddenMuted > 0 then
						Listing[5] = "|cffffffff" .. L["All sounds in the selected categories are muted.  Check Muted in the Menu to show them."]
					elseif hiddenUnplayable > 0 then
						Listing[5] = "|cffffffff" .. L["All sounds in the selected categories are unplayable.  Check Unplayable in the Menu to show them."]
					else
						Listing[5] = "|cffffffff" .. L["There are no sounds in the selected categories."]
					end
				end
			end

			-- Remove the rest of the previous listing
			for i = count + 1, oldCount do
				Listing[i] = nil
			end

			-- If editbox is not empty, show search results
			if LeaSoundsCB["sBox"]:GetText() ~= "" then
				ListData = searchTable
				ShowSearchResults()
			end

			-- Clear editbox focus
			sBox:ClearFocus()

			-- Update listing buttons
			UpdateList()

			-- Set list to top and stop any playing track (unless the caller handles it)
			if not keepPlaying then
				scrollFrame:SetVerticalScroll(0)
				stopBtn:Click()
			end

		end

		----------------------------------------------------------------------
		-- Settings (shown in place of the listing, settings on the left and help on the right)
		----------------------------------------------------------------------

		local settingsFrame = CreateFrame("Frame", nil, PageF)
		LeaSoundsLC["SettingsFrame"] = settingsFrame
		settingsFrame:SetPoint("TOPLEFT", 16, -10)
		settingsFrame:SetPoint("BOTTOMRIGHT", -16, 52)
		settingsFrame:Hide()

		-- Width of the settings column (set again when the panel is resized)
		local columnGap = 24
		-- Settings get 40% of the panel (but at least 200) and the help gets the rest, as the help text is longer
		local function SettingsColumnWidth()
			return max(200, floor((frameWidth - 32 - columnGap) * 0.4))
		end
		local settingsWidth = SettingsColumnWidth()
		local helpGold = "|cffffd800"

		-- Settings column title
		settingsFrame.title = settingsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		settingsFrame.title:SetPoint("TOPLEFT", 0, -4)
		settingsFrame.title:SetText(L["Settings"])

		-- Line under the settings column title (the same as the help one)
		settingsFrame.settingsLine = settingsFrame:CreateTexture(nil, "ARTWORK")
		settingsFrame.settingsLine:SetColorTexture(0.6, 0.6, 0.6, 0.5)
		settingsFrame.settingsLine:SetHeight(1)
		-- (ends where the settings end so it stays clear of the scroll bar)
		settingsFrame.settingsLine:SetPoint("TOPLEFT", 0, -28)
		settingsFrame.settingsLine:SetWidth(settingsWidth - 4)

		-- Help column title
		settingsFrame.helpTitle = settingsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		settingsFrame.helpTitle:SetPoint("TOPLEFT", settingsWidth + columnGap, -4)
		settingsFrame.helpTitle:SetText(L["Help"])

		-- Line under the help column title
		settingsFrame.helpLine = settingsFrame:CreateTexture(nil, "ARTWORK")
		settingsFrame.helpLine:SetColorTexture(0.6, 0.6, 0.6, 0.5)
		settingsFrame.helpLine:SetHeight(1)
		-- (ends where the help text ends so it stays clear of the scroll bar)
		settingsFrame.helpLine:SetPoint("TOPLEFT", settingsWidth + columnGap, -28)
		settingsFrame.helpLine:SetPoint("TOPRIGHT", -18, -28)

		-- Back button in the bottom-right corner, in place of the Menu button while the settings or the mounts list are showing
		-- (labelled Back, the same as the Back button in the sound kit listing)
		local backBtn = LeaSoundsLC:CreateButton("BackToMainMenuButton", PageF, "Back", "BOTTOMRIGHT", -10, 10, 70, 25)
		AddButtonIcon(backBtn, 70, "previous")
		backBtn:Hide()

		-- Dividing line between the columns
		settingsFrame.divider = settingsFrame:CreateTexture(nil, "ARTWORK")
		settingsFrame.divider:SetColorTexture(0.6, 0.6, 0.6, 0.3)
		settingsFrame.divider:SetWidth(1)
		settingsFrame.divider:SetPoint("TOPLEFT", settingsWidth + columnGap / 2, -4)
		settingsFrame.divider:SetPoint("BOTTOMLEFT", settingsWidth + columnGap / 2, 0)

		----------------------------------------------------------------------
		-- Settings column (in a scroll frame so it can be scrolled when the panel is short or the text is longer)
		----------------------------------------------------------------------

		-- Width of the settings (leaves the same gap before the dividing line as the help leaves before its scroll bar)
		local settingsInner = settingsWidth - 4

		local settingsScroll = CreateFrame("ScrollFrame", nil, settingsFrame, "LeaSoundsConfigurationPanelScrollFrameTemplate")
		-- Starts below the line under the settings title, the same as the help
		settingsScroll:SetPoint("TOPLEFT", PageF, "TOPLEFT", 16, -46)
		settingsScroll:SetPoint("BOTTOMLEFT", PageF, "BOTTOMLEFT", 16, 52)
		settingsScroll:SetWidth(settingsInner)
		if settingsScroll.SetPanExtent then settingsScroll:SetPanExtent(30) end
		-- Scroll bar is the same height as the help scroll bar
		if settingsScroll.ScrollBar then
			settingsScroll.ScrollBar:ClearAllPoints()
			settingsScroll.ScrollBar:SetPoint("TOPLEFT", settingsScroll, "TOPRIGHT", 6, 14)
			settingsScroll.ScrollBar:SetPoint("BOTTOMLEFT", settingsScroll, "BOTTOMRIGHT", 6, -2)
			-- Only show the scroll bar when the settings don't fit
			if settingsScroll.ScrollBar.SetHideIfUnscrollable then settingsScroll.ScrollBar:SetHideIfUnscrollable(true) end
		end
		local settingsChild = CreateFrame("Frame", nil, settingsScroll)
		settingsChild:SetSize(settingsInner, 1)
		settingsScroll:SetScrollChild(settingsChild)

		----------------------------------------------------------------------
		-- Language dropdown (choosing a language reloads the UI so only one language is set up at login)
		----------------------------------------------------------------------

		local langLabel = settingsChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		langLabel:SetPoint("TOPLEFT", 0, -4)
		langLabel:SetText(L["Language"])

		-- Languages in the same order as Leatrix Plus (the number is the AddonLanguage setting)
		local langList = {{L["Automatic"], 1}, {L["English"], 2}, {L["Deutsch"], 3}, {L["Español (EU)"], 4}, {L["Español (AL)"], 5}, {L["Français"], 6}, {L["Italiano"], 7}, {L["Português"], 8}, {L["Русский"], 9}, {L["한국어"], 10}, {L["简体中文"], 11}, {L["繁體中文"], 12}}

		-- Dropdown uses the standard dropdown template and menu system (the same as Leatrix Plus, so nothing is tainted)
		local langDrop = CreateFrame("DropdownButton", nil, settingsChild, "WowStyle1DropdownTemplate")
		LeaSoundsCB["LanguageDropdown"] = langDrop
		langDrop:SetPoint("TOPLEFT", langLabel, "BOTTOMLEFT", 0, -6)
		-- (the same width at any panel size)
		langDrop:SetWidth(196)

		local function IsLanguageSelected(value)
			return value == LeaSoundsLC["AddonLanguage"]
		end

		local function SetLanguageSelected(value)
			-- Nothing to do if the language is already chosen
			if value == LeaSoundsLC["AddonLanguage"] then return end
			-- Save the new language and reload the UI so it's used from login
			LeaSoundsLC["AddonLanguage"] = value
			LeaSoundsDB["AddonLanguage"] = value
			ReloadUI()
		end

		MenuUtil.CreateRadioMenu(langDrop, IsLanguageSelected, SetLanguageSelected, unpack(langList))

		----------------------------------------------------------------------
		-- Click to play checkbox (when unchecked, clicking a sound selects it and double-clicking plays it)
		----------------------------------------------------------------------

		local clickBox = CreateFrame("CheckButton", nil, settingsChild, "ChatConfigCheckButtonTemplate")
		LeaSoundsCB["ClickToPlay"] = clickBox
		clickBox:SetPoint("TOPLEFT", langDrop, "BOTTOMLEFT", -4, -14)
		clickBox.f = clickBox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		clickBox.f:SetPoint("LEFT", 24, 0)
		clickBox.f:SetJustifyH("LEFT")
		clickBox.f:SetWidth(settingsInner - 20)
		clickBox.f:SetText(L["Play sounds with a single click"])
		clickBox:SetHitRectInsets(0, -(settingsInner - 24), 0, 0)

		-- Description below the checkbox
		clickBox.desc = settingsChild:CreateFontString(nil, "ARTWORK", "GameFontDisable")
		clickBox.desc:SetPoint("TOPLEFT", clickBox, "BOTTOMLEFT", 4, -2)
		clickBox.desc:SetWidth(settingsInner)
		clickBox.desc:SetJustifyH("LEFT")
		clickBox.desc:SetJustifyV("TOP")
		clickBox.desc:SetSpacing(2)
		clickBox.desc:SetText(L["If unchecked, clicking a sound selects it and double-clicking a sound plays it."])

		----------------------------------------------------------------------
		-- Play next checkbox (when checked, the next sound in the listing is played when a sound finishes)
		----------------------------------------------------------------------

		local nextBox = CreateFrame("CheckButton", nil, settingsChild, "ChatConfigCheckButtonTemplate")
		LeaSoundsCB["AutoPlayNext"] = nextBox
		nextBox:SetPoint("TOPLEFT", clickBox.desc, "BOTTOMLEFT", -4, -10)
		nextBox.f = nextBox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		nextBox.f:SetPoint("LEFT", 24, 0)
		nextBox.f:SetJustifyH("LEFT")
		nextBox.f:SetWidth(settingsInner - 20)
		nextBox.f:SetText(L["Play the next sound automatically"])
		nextBox:SetHitRectInsets(0, -(settingsInner - 24), 0, 0)

		-- Description below the checkbox
		nextBox.desc = settingsChild:CreateFontString(nil, "ARTWORK", "GameFontDisable")
		nextBox.desc:SetPoint("TOPLEFT", nextBox, "BOTTOMLEFT", 4, -2)
		nextBox.desc:SetWidth(settingsInner)
		nextBox.desc:SetJustifyH("LEFT")
		nextBox.desc:SetJustifyV("TOP")
		nextBox.desc:SetSpacing(2)
		nextBox.desc:SetText(L["If checked, when a sound finishes, the next sound in the listing is played (unplayable sounds are skipped)."])

		nextBox:SetScript("OnShow", function(self)
			self:SetChecked(LeaSoundsLC["AutoPlayNext"] == "On")
		end)
		nextBox:SetScript("OnClick", function(self)
			LeaSoundsLC["AutoPlayNext"] = self:GetChecked() and "On" or "Off"
		end)

		----------------------------------------------------------------------
		-- Play in background checkbox (when unchecked, closing the panel stops the playing sound)
		----------------------------------------------------------------------

		local bgBox = CreateFrame("CheckButton", nil, settingsChild, "ChatConfigCheckButtonTemplate")
		LeaSoundsCB["PlayInBackground"] = bgBox
		bgBox:SetPoint("TOPLEFT", nextBox.desc, "BOTTOMLEFT", -4, -10)
		bgBox.f = bgBox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		bgBox.f:SetPoint("LEFT", 24, 0)
		bgBox.f:SetJustifyH("LEFT")
		bgBox.f:SetWidth(settingsInner - 20)
		bgBox.f:SetText(L["Play in background"])
		bgBox:SetHitRectInsets(0, -(settingsInner - 24), 0, 0)

		-- Description below the checkbox
		bgBox.desc = settingsChild:CreateFontString(nil, "ARTWORK", "GameFontDisable")
		bgBox.desc:SetPoint("TOPLEFT", bgBox, "BOTTOMLEFT", 4, -2)
		bgBox.desc:SetWidth(settingsInner)
		bgBox.desc:SetJustifyH("LEFT")
		bgBox.desc:SetJustifyV("TOP")
		bgBox.desc:SetSpacing(2)
		bgBox.desc:SetText(L["If checked, sounds keep playing when you close the panel.  If unchecked, closing the panel stops the sound."])

		bgBox:SetScript("OnShow", function(self)
			self:SetChecked(LeaSoundsLC["PlayInBackground"] == "On")
		end)
		bgBox:SetScript("OnClick", function(self)
			LeaSoundsLC["PlayInBackground"] = self:GetChecked() and "On" or "Off"
		end)

		----------------------------------------------------------------------
		-- Mob sounds checkbox (when checked, the target frame menu has a Show target sounds option)
		----------------------------------------------------------------------

		local mobBox = CreateFrame("CheckButton", nil, settingsChild, "ChatConfigCheckButtonTemplate")
		LeaSoundsCB["MobSoundsMenu"] = mobBox
		mobBox:SetPoint("TOPLEFT", bgBox.desc, "BOTTOMLEFT", -4, -10)
		mobBox.f = mobBox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		mobBox.f:SetPoint("LEFT", 24, 0)
		mobBox.f:SetJustifyH("LEFT")
		mobBox.f:SetWidth(settingsInner - 20)
		mobBox.f:SetText(L["Show target sounds in the target menu"])
		mobBox:SetHitRectInsets(0, -(settingsInner - 24), 0, 0)

		-- Description below the checkbox
		mobBox.desc = settingsChild:CreateFontString(nil, "ARTWORK", "GameFontDisable")
		mobBox.desc:SetPoint("TOPLEFT", mobBox, "BOTTOMLEFT", 4, -2)
		mobBox.desc:SetWidth(settingsInner)
		mobBox.desc:SetJustifyH("LEFT")
		mobBox.desc:SetJustifyV("TOP")
		mobBox.desc:SetSpacing(2)

		mobBox:SetScript("OnShow", function(self)
			self:SetChecked(LeaSoundsLC["MobSoundsMenu"] == "On")
		end)
		mobBox:SetScript("OnClick", function(self)
			LeaSoundsLC["MobSoundsMenu"] = self:GetChecked() and "On" or "Off"
		end)

		-- The setting can't be used if this game version has no mob sound data
		if type(Leatrix_Sounds["CREATURE_ROLES"]) == "string" and type(Leatrix_Sounds["CREATURE_SETS"]) == "string" and type(Leatrix_Sounds["CREATURE_MODELS"]) == "string" then
			mobBox.desc:SetText(L["If checked, right-clicking the target frame of a mob, NPC or player shows a Show target sounds option which lists the sounds they make, including what NPCs say, the emotes players make and the mount a player is riding."])
		else
			mobBox.desc:SetText(L["Target sound data is not available for this game version."])
			LeaSoundsLC:LockItem(mobBox, true)
		end

		----------------------------------------------------------------------
		-- Toggle panel key (the key is bound in the addon code so the game keybindings menu is not tainted)
		----------------------------------------------------------------------

		local keyDesc -- Description below the key button (the set defaults button goes below it)

		-- (in a do block so its locals don't count towards the limit for the rest of this function)
		do

			local keyLabel = settingsChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			keyLabel:SetPoint("TOPLEFT", mobBox.desc, "BOTTOMLEFT", 0, -14)
			keyLabel:SetText(L["Toggle panel key"])

			local keyBtn = LeaSoundsLC:CreateButton("ToggleKeyButton", settingsChild, "None", "TOPLEFT", 0, 0, 196, 22)
			keyBtn:ClearAllPoints()
			keyBtn:SetPoint("TOPLEFT", keyLabel, "BOTTOMLEFT", 0, -6)
			keyBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

			keyDesc = settingsChild:CreateFontString(nil, "ARTWORK", "GameFontDisable")
			keyDesc:SetPoint("TOPLEFT", keyBtn, "BOTTOMLEFT", 0, -4)
			keyDesc:SetWidth(settingsInner)
			keyDesc:SetJustifyH("LEFT")
			keyDesc:SetJustifyV("TOP")
			keyDesc:SetSpacing(2)
			keyDesc:SetText(L["Open or close the Leatrix Sounds panel with a key.  Click the button, then press a key (you can include Shift, Ctrl or Alt).  Press Escape to cancel or right-click to remove the key."])

			-- Hidden button that the key clicks
			local toggleBtn = CreateFrame("Button", "LeaSoundsGlobalKeyToggle", UIParent)
			toggleBtn:Hide()
			toggleBtn:RegisterForClicks("AnyDown")
			toggleBtn:SetScript("OnClick", function() SlashCmdList["Leatrix_Sounds"]("") end)

			local function KeyName(key)
				return GetBindingText and GetBindingText(key) or key
			end

			local listening = false
			local applyPending = false

			-- Apply the key
			local function ApplyKey()
				if InCombatLockdown() then
					applyPending = true
					return
				end
				applyPending = false
				ClearOverrideBindings(keyBtn)
				if LeaSoundsLC["ToggleKey"] ~= "" then
					SetOverrideBindingClick(keyBtn, false, LeaSoundsLC["ToggleKey"], "LeaSoundsGlobalKeyToggle", "LeftButton")
				end
			end

			-- Show the key
			local function Refresh()
				if listening then
					keyBtn:SetText(L["Press a key"])
				elseif LeaSoundsLC["ToggleKey"] ~= "" then
					keyBtn:SetText("|cff00ff00" .. KeyName(LeaSoundsLC["ToggleKey"]) .. "|r")
				else
					keyBtn:SetText("|cff808080" .. L["None"] .. "|r")
				end
			end

			local function StopListening()
				if listening then
					keyBtn:EnableKeyboard(false)
					listening = false
				end
				Refresh()
			end

			local modifierKeys = {LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true, LMETA = true, RMETA = true}

			-- Capture the next key pressed
			keyBtn:SetScript("OnKeyDown", function(self, key)
				if not listening then return end
				if modifierKeys[key] then return end
				if key == "ESCAPE" then
					StopListening()
					return
				end
				if InCombatLockdown() then
					StopListening()
					LeaSoundsLC:Print("You cannot do that in combat.")
					return
				end
				LeaSoundsLC["ToggleKey"] = (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "") .. (IsShiftKeyDown() and "SHIFT-" or "") .. (IsMetaKeyDown and IsMetaKeyDown() and "META-" or "") .. key
				ApplyKey()
				StopListening()
			end)

			-- Setting a key script turns keyboard input on by itself, so turn it off until the button is clicked
			keyBtn:EnableKeyboard(false)

			keyBtn:SetScript("OnClick", function(self, mouseButton)
				if InCombatLockdown() then
					StopListening()
					LeaSoundsLC:Print("You cannot do that in combat.")
					return
				end
				if mouseButton == "RightButton" then
					-- Remove the key
					StopListening()
					LeaSoundsLC["ToggleKey"] = ""
					ApplyKey()
					Refresh()
					return
				end
				if listening then
					StopListening()
				else
					listening = true
					keyBtn:EnableKeyboard(true)
					keyBtn:SetPropagateKeyboardInput(false)
					Refresh()
				end
			end)

			keyBtn:HookScript("OnShow", Refresh)
			keyBtn:HookScript("OnHide", StopListening)
			keyBtn:RegisterEvent("PLAYER_REGEN_DISABLED")
			keyBtn:RegisterEvent("PLAYER_REGEN_ENABLED")
			keyBtn:SetScript("OnEvent", function(self, event)
				if event == "PLAYER_REGEN_DISABLED" then
					-- Entering combat, stop listening so key presses reach the game
					if listening then StopListening() end
				elseif event == "PLAYER_REGEN_ENABLED" then
					-- Set the key if it could not be set during combat
					if applyPending then ApplyKey() end
				end
			end)

			-- Set the key now
			ApplyKey()
			Refresh()

		end

		----------------------------------------------------------------------
		-- Set defaults button (puts every setting back to its default, the language and muted sounds are not changed)
		-- Clicking it shows Are you sure? with Yes and No buttons in its place
		----------------------------------------------------------------------

		local defaultsBtn = LeaSoundsLC:CreateButton("SetDefaultsButton", settingsChild, "Set defaults", "TOPLEFT", 0, 0, 0, 22)
		defaultsBtn:ClearAllPoints()
		defaultsBtn:SetPoint("TOPLEFT", keyDesc, "BOTTOMLEFT", 0, -14)
		AddButtonIcon(defaultsBtn, 0, "reset")

		-- Confirmation shown in place of the button
		local confirm = CreateFrame("Frame", nil, settingsChild)
		confirm:SetPoint("TOPLEFT", defaultsBtn, "TOPLEFT", 0, 0)
		confirm:SetSize(settingsInner, 22)
		confirm:Hide()
		confirm.text = confirm:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		confirm.text:SetPoint("LEFT", 0, 0)
		confirm.text:SetText(L["Are you sure?"])
		local yesBtn = LeaSoundsLC:CreateButton("SetDefaultsYesButton", confirm, "Yes", "LEFT", 0, 0, 0, 22)
		yesBtn:ClearAllPoints()
		yesBtn:SetPoint("LEFT", confirm.text, "RIGHT", 8, 0)
		local noBtn = LeaSoundsLC:CreateButton("SetDefaultsNoButton", confirm, "No", "LEFT", 0, 0, 0, 22)
		noBtn:ClearAllPoints()
		noBtn:SetPoint("LEFT", yesBtn, "RIGHT", 6, 0)

		-- Show the button again (used by No, Yes and when the settings are closed)
		local function CancelDefaults()
			confirm:Hide()
			defaultsBtn:Show()
		end
		defaultsBtn:SetScript("OnClick", function()
			defaultsBtn:Hide()
			confirm:Show()
		end)
		noBtn:SetScript("OnClick", CancelDefaults)
		yesBtn:SetScript("OnClick", function()
			CancelDefaults()
			if LeaSoundsLC.SetDefaults then LeaSoundsLC.SetDefaults() end
		end)
		settingsFrame:HookScript("OnHide", CancelDefaults)

		-- Description below the button
		defaultsBtn.desc = settingsChild:CreateFontString(nil, "ARTWORK", "GameFontDisable")
		defaultsBtn.desc:SetPoint("TOPLEFT", defaultsBtn, "BOTTOMLEFT", 0, -4)
		defaultsBtn.desc:SetWidth(settingsInner)
		defaultsBtn.desc:SetJustifyH("LEFT")
		defaultsBtn.desc:SetJustifyV("TOP")
		defaultsBtn.desc:SetSpacing(2)
		defaultsBtn.desc:SetText(L["Set all settings back to their defaults, including the menu categories and the panel size and position.  The language, muted sounds and toggle panel key are not changed."])

		-- Fit the scroll area to the settings (done when the settings are shown, once the text has been laid out)
		local function SetSettingsHeight()
			local top, bottom = settingsChild:GetTop(), defaultsBtn.desc:GetBottom()
			if top and bottom then settingsChild:SetHeight(top - bottom + 8) end
		end
		settingsFrame:HookScript("OnShow", function()
			settingsScroll:SetVerticalScroll(0)
			C_Timer.After(0, SetSettingsHeight)
		end)

		----------------------------------------------------------------------
		-- Help (right column)
		----------------------------------------------------------------------

		-- Help text is in a scroll frame so longer (translated) text can be scrolled
		local helpScroll = CreateFrame("ScrollFrame", nil, settingsFrame, "LeaSoundsConfigurationPanelScrollFrameTemplate")
		-- Starts below the line under the help title so scrolled text never overlaps the line or the title
		helpScroll:SetPoint("TOPLEFT", PageF, "TOPLEFT", 16 + settingsWidth + columnGap, -46)
		helpScroll:SetPoint("BOTTOMRIGHT", PageF, "BOTTOMRIGHT", -30, 52)
		if helpScroll.SetPanExtent then helpScroll:SetPanExtent(30) end
		-- Scroll bar is the same height as the listing scroll bar (it starts higher than the help text, level with the listing's)
		if helpScroll.ScrollBar then
			helpScroll.ScrollBar:ClearAllPoints()
			helpScroll.ScrollBar:SetPoint("TOPLEFT", helpScroll, "TOPRIGHT", 12, 14)
			helpScroll.ScrollBar:SetPoint("BOTTOMLEFT", helpScroll, "BOTTOMRIGHT", 12, -2)
		end
		-- Only show the scroll bar when the text doesn't fit
		if helpScroll.ScrollBar and helpScroll.ScrollBar.SetHideIfUnscrollable then helpScroll.ScrollBar:SetHideIfUnscrollable(true) end
		helpScroll.child = CreateFrame("Frame", nil, helpScroll)
		helpScroll.child:SetSize(max(100, frameWidth - 46 - settingsWidth - columnGap), 1)
		helpScroll:SetScrollChild(helpScroll.child)

		local helpText = helpScroll.child:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		helpText:SetPoint("TOPLEFT", 0, -4)
		helpText:SetWidth(helpScroll.child:GetWidth() - 4)
		helpText:SetJustifyH("LEFT")
		helpText:SetJustifyV("TOP")
		helpText:SetSpacing(2)

		-- Help text (the playing section follows the click to play setting)
		local function SetHelpText()
			local playText
			if LeaSoundsLC["ClickToPlay"] == "On" then
				playText = L["Click a sound to play it.  Use the Previous and Next buttons to play the sound before or after it."]
			else
				playText = L["Double-click a sound to play it.  Use the Previous and Next buttons to play the sound before or after it."]
			end
			-- Target sounds are only explained if this game version has mob sound data and the setting is on
			local mobHelp = ""
			if mobBox:IsEnabled() and LeaSoundsLC["MobSoundsMenu"] == "On" then
				mobHelp = helpGold .. L["Target sounds"] .. "|r|n" ..
				L["Right-click the target frame of a mob, NPC or player and click show target sounds to see the sounds they make.  If a player is riding a mount, the mount sounds are shown too.  Sound kits in grey are only used by some of the mobs which share that model."] .. "|n|n"
			end
			-- The mounts list is only explained if this game version has it
			if LeaSoundsLC.MountsItem and LeaSoundsLC.HasPets then
				mobHelp = mobHelp .. helpGold .. L["Mount and pet sounds"] .. "|r|n" ..
				L["Choose mounts & pets in the menu, pick the Mounts or Pets tab at the top and click any mount or pet to see the sounds it makes."] .. "|n|n"
			elseif LeaSoundsLC.MountsItem then
				mobHelp = mobHelp .. helpGold .. L["Mount sounds"] .. "|r|n" ..
				L["Choose mounts in the menu and click any mount to see the sounds it makes."] .. "|n|n"
			end
			helpText:SetText(
				helpGold .. L["Leatrix Sounds"] .. "|r|n" ..
				L["Version"] .. " " .. LeaSoundsLC["AddonVer"] .. (LeaSoundsLC.GameHelpTitle and (" " .. LeaSoundsLC.GameHelpTitle) or "") .. "|n|n" ..
				helpGold .. L["Searching"] .. "|r|n" ..
				L["Type up to 10 keywords to search.  Keywords starting with ! are excluded from search results, for example: orc !death"] .. "|n|n" ..
				helpGold .. L["Playing sounds"] .. "|r|n" ..
				playText .. "|n|n" ..
				helpGold .. L["Categories"] .. "|r|n" ..
				L["You can filter what type of music and effects you want to see in the listing.  A cross shows in the menu to remind you when filters are active.  You can click the cross to remove all of the filters."] .. "|n|n" ..
				helpGold .. L["Selecting more than one sound"] .. "|r|n" ..
				L["By holding control when you click a sound, you can select multiple sounds.  By holding shift when you click a sound, you can select a range of sounds."] .. "|n|n" ..
				helpGold .. L["Scrolling the list"] .. "|r|n" ..
				L["Normal scrolling jumps a line at a time.  By holding shift when you scroll, you can jump a page at a time."] .. "|n|n" ..
				helpGold .. L["Right-click menu"] .. "|r|n" ..
				L["Right-click a sound to open the context menu.  From there you can play the sound, mute or unmute it, see what sound kits contain it or print the listing entry in chat.  If you have multiple sounds selected, these actions apply to all sounds you have selected."] .. "|n|n" ..
				mobHelp ..
				helpGold .. L["Muting"] .. "|r|n" ..
				L["Muted sounds are shown in red and stay muted until you unmute them.  Clicking a muted sound still plays it in the addon so you can hear what you have muted, but it stays muted in the game."] .. "|n|n" ..
				helpGold .. L["Unknown sounds"] .. "|r|n" ..
				L["Unknown sounds are typically newer sound files that do not have names yet."] .. "|n|n" ..
				helpGold .. L["Unplayable sounds"] .. "|r|n" ..
				L["Unplayable sounds are shown in grey.  They are either locked, missing or have no audio."] .. "|n|n" ..
				helpGold .. L["Updates"] .. "|r|n" ..
				L["The sound listing is updated every week so keep the addon updated with CurseForge App."]
			)
		end

		-- Size the scroll area to fit the help text
		local function SetHelpHeight()
			helpScroll.child:SetHeight((helpText:GetStringHeight() or 0) + 8)
		end

		-- Checkbox updates the setting and the help text
		clickBox:SetScript("OnShow", function(self)
			self:SetChecked(LeaSoundsLC["ClickToPlay"] == "On")
		end)
		clickBox:SetScript("OnClick", function(self)
			LeaSoundsLC["ClickToPlay"] = self:GetChecked() and "On" or "Off"
			SetHelpText()
			SetHelpHeight()
		end)

		-- The target sounds checkbox also updates the help text (the target sounds section is only shown while it's checked)
		mobBox:HookScript("OnClick", function()
			SetHelpText()
			SetHelpHeight()
		end)

		-- Refresh everything and start the help at the top when settings are shown
		settingsFrame:SetScript("OnShow", function()
			clickBox:SetChecked(LeaSoundsLC["ClickToPlay"] == "On")
			SetHelpText()
			SetHelpHeight()
			helpScroll:SetVerticalScroll(0)
		end)

		-- Fit the settings and help columns to the panel width (run when the panel is resized)
		local function LayoutSettings()
			settingsWidth = SettingsColumnWidth()
			local inner = settingsWidth - 4
			-- Settings column
			settingsFrame.settingsLine:SetWidth(inner)
			settingsScroll:SetWidth(inner)
			settingsChild:SetWidth(inner)
			for void, box in ipairs({clickBox, nextBox, bgBox, mobBox}) do
				box.f:SetWidth(inner - 20)
				box:SetHitRectInsets(0, -(inner - 24), 0, 0)
				box.desc:SetWidth(inner)
			end
			confirm:SetWidth(inner)
			defaultsBtn.desc:SetWidth(inner)
			keyDesc:SetWidth(inner)
			-- Dividing line between the columns
			settingsFrame.divider:ClearAllPoints()
			settingsFrame.divider:SetPoint("TOPLEFT", settingsWidth + columnGap / 2, -4)
			settingsFrame.divider:SetPoint("BOTTOMLEFT", settingsWidth + columnGap / 2, 0)
			-- Help column
			settingsFrame.helpTitle:ClearAllPoints()
			settingsFrame.helpTitle:SetPoint("TOPLEFT", settingsWidth + columnGap, -4)
			settingsFrame.helpLine:ClearAllPoints()
			settingsFrame.helpLine:SetPoint("TOPLEFT", settingsWidth + columnGap, -28)
			settingsFrame.helpLine:SetPoint("TOPRIGHT", -18, -28)
			helpScroll:ClearAllPoints()
			helpScroll:SetPoint("TOPLEFT", PageF, "TOPLEFT", 16 + settingsWidth + columnGap, -46)
			helpScroll:SetPoint("BOTTOMRIGHT", PageF, "BOTTOMRIGHT", -30, 52)
			local w = max(100, frameWidth - 46 - settingsWidth - columnGap)
			helpScroll.child:SetWidth(w)
			helpText:SetWidth(w - 4)
			if settingsFrame:IsShown() then
				SetHelpHeight()
				helpScroll:SetVerticalScroll(min(helpScroll:GetVerticalScroll(), helpScroll:GetVerticalScrollRange()))
				C_Timer.After(0, SetSettingsHeight)
			end
		end

		----------------------------------------------------------------------
		-- Menu (sound categories and settings)
		----------------------------------------------------------------------

		local catBtn = LeaSoundsLC:CreateButton("CategoryButton", LeaSoundsLC["PageF"], "Menu", "BOTTOMRIGHT", -10, 10, menuBtnWidth, 25)
		AddButtonIcon(catBtn, menuBtnWidth, "menu")
		menuBtnWidth = catBtn:GetWidth()
		LayoutBottomBar()

		-- Dropdown frame is a child of the main panel so it looks like part of it
		local catMenu = CreateFrame("Frame", nil, PageF, "BackdropTemplate")
		LeaSoundsLC["CategoryMenu"] = catMenu
		catMenu:SetPoint("BOTTOMRIGHT", catBtn, "TOPRIGHT", 0, 4)
		catMenu:SetSize(130, 5 * 22 + 14 + 8 + 8 + 30)
		catMenu:SetFrameLevel(PageF:GetFrameLevel() + 20)
		catMenu:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, tileSize = 16, edgeSize = 14, insets = { left = 4, right = 4, top = 4, bottom = 4 }})
		catMenu:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
		catMenu:SetBackdropBorderColor(0.6, 0.6, 0.6, 1.0)
		catMenu:EnableMouse(true)
		catMenu:Hide()

		local catItems = {
			{"SoundMusic", "Music"},
			{"SoundSFX", "Effects"},
			{"SoundUnknown", "Unknown"},
			{"SoundUnplayable", "Unplayable"},
			{"SoundMuted", "Muted"},
		}

		-- Dividing line between Music and Effects (which have categories) and Unknown and Unplayable (which don't)
		catMenu.divider0 = catMenu:CreateTexture(nil, "ARTWORK")
		catMenu.divider0:SetColorTexture(0.6, 0.6, 0.6, 0.5)
		catMenu.divider0:SetHeight(1)
		catMenu.divider0:SetPoint("TOPLEFT", 10, -7 - 2 * 22 - 2)
		catMenu.divider0:SetPoint("TOPRIGHT", -10, -7 - 2 * 22 - 2)

		-- Dividing line between Unplayable and Muted
		catMenu.divider = catMenu:CreateTexture(nil, "ARTWORK")
		catMenu.divider:SetColorTexture(0.6, 0.6, 0.6, 0.5)
		catMenu.divider:SetHeight(1)
		catMenu.divider:SetPoint("TOPLEFT", 10, -7 - 4 * 22 - 8 - 2)
		catMenu.divider:SetPoint("TOPRIGHT", -10, -7 - 4 * 22 - 8 - 2)

		for i, item in ipairs(catItems) do
			local field, caption = item[1], item[2]
			local Cbox = CreateFrame("CheckButton", nil, catMenu, "ChatConfigCheckButtonTemplate")
			LeaSoundsCB[field] = Cbox
			-- Unknown and Unplayable go below the first dividing line, Muted goes below the second one
			Cbox:SetPoint("TOPLEFT", 8, -7 - (i - 1) * 22 - (i >= 3 and 8 or 0) - (field == "SoundMuted" and 8 or 0))
			-- Hover bar across the whole row (same as the Settings item)
			Cbox.t = Cbox:CreateTexture(nil, "BACKGROUND")
			Cbox.t:SetPoint("LEFT", 0, 0)
			Cbox.t:SetSize(130 - 16, 20)
			Cbox.t:SetColorTexture(0.3, 0.3, 0.0, 0.8)
			Cbox.t:SetAlpha(0.7)
			Cbox.t:Hide()
			Cbox:SetScript("OnEnter", function(self) self.t:Show() end)
			Cbox:SetScript("OnLeave", function(self) self.t:Hide() end)
			Cbox.f = Cbox:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
			Cbox.f:SetPoint('LEFT', 24, 0)
			Cbox.f:SetJustifyH("LEFT")
			Cbox.f:SetWordWrap(false)
			Cbox.f:SetWidth(90)
			Cbox.f:SetText(L[caption])
			Cbox:SetHitRectInsets(0, -90, 0, 0)
			Cbox:SetScript("OnShow", function(self)
				self:SetChecked(LeaSoundsLC[field] == "On")
			end)
			Cbox:SetScript("OnClick", function(self)
				LeaSoundsLC[field] = self:GetChecked() and "On" or "Off"
				playScroll = nil
				-- Changing categories closes settings so the listing can be seen
				if LeaSoundsLC.SettingsShown then LeaSoundsLC.CloseSettings() end
				C_Timer.After(0.001, SetListingFunc)
			end)
		end

		-- Dividing line between Muted and Settings
		catMenu.divider2 = catMenu:CreateTexture(nil, "ARTWORK")
		catMenu.divider2:SetColorTexture(0.6, 0.6, 0.6, 0.5)
		catMenu.divider2:SetHeight(1)
		catMenu.divider2:SetPoint("TOPLEFT", 10, -7 - 5 * 22 - 16 - 2)
		catMenu.divider2:SetPoint("TOPRIGHT", -10, -7 - 5 * 22 - 16 - 2)

		----------------------------------------------------------------------
		-- Submenus (Music and Effects categories)
		----------------------------------------------------------------------

		local subMenus = {}

		-- Show a submenu beside the menu (to the right if there is room, otherwise to the left) and close the others
		-- (nil closes them all)
		local function ShowSubMenu(menu)
			for void, m in ipairs(subMenus) do
				if m ~= menu then m:Hide() end
			end
			if not menu then return end
			if menu.Refresh then menu:Refresh() end
			menu:ClearAllPoints()
			local scale = catMenu:GetEffectiveScale() / UIParent:GetEffectiveScale()
			if (catMenu:GetRight() + menu:GetWidth()) * scale < UIParent:GetRight() then
				menu:SetPoint("BOTTOMLEFT", catMenu, "BOTTOMRIGHT", -2, 0)
			else
				menu:SetPoint("BOTTOMRIGHT", catMenu, "BOTTOMLEFT", 2, 0)
			end
			menu:Show()
		end

		-- Check if the mouse is over any submenu
		local function IsMouseOverSubMenu()
			for void, m in ipairs(subMenus) do
				if m:IsShown() and m:IsMouseOver() then return true end
			end
		end

		-- Create a submenu frame (a child of the menu so it closes with it)
		local function CreateSubMenu()
			local menu = CreateFrame("Frame", nil, catMenu, "BackdropTemplate")
			menu:SetFrameLevel(catMenu:GetFrameLevel() + 10)
			menu:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, tileSize = 16, edgeSize = 14, insets = { left = 4, right = 4, top = 4, bottom = 4 }})
			menu:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
			menu:SetBackdropBorderColor(0.6, 0.6, 0.6, 1.0)
			menu:EnableMouse(true)
			menu:SetClampedToScreen(true)
			menu:Hide()
			tinsert(subMenus, menu)
			return menu
		end

		-- Create a submenu with a checkbox for each category (offVar is the table of unchecked categories)
		local function CreateCategoryMenu(categories, offVar)
			local menu = CreateSubMenu()
			local rows, textWidth = {}, 0
			for i, cat in ipairs(categories) do
				local key = cat[1]
				local Cbox = CreateFrame("CheckButton", nil, menu, "ChatConfigCheckButtonTemplate")
				rows[i] = Cbox
				-- Hover bar across the whole row
				Cbox.t = Cbox:CreateTexture(nil, "BACKGROUND")
				Cbox.t:SetPoint("LEFT", 0, 0)
				Cbox.t:SetColorTexture(0.3, 0.3, 0.0, 0.8)
				Cbox.t:SetAlpha(0.7)
				Cbox.t:Hide()
				Cbox:SetScript("OnEnter", function(self) self.t:Show() end)
				Cbox:SetScript("OnLeave", function(self) self.t:Hide() end)
				Cbox.f = Cbox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
				Cbox.f:SetPoint("LEFT", 24, 0)
				Cbox.f:SetJustifyH("LEFT")
				Cbox.f:SetWordWrap(false)
				Cbox.f:SetText(cat[2])
				Cbox:SetScript("OnClick", function(self)
					LeaSoundsLC[offVar][key] = not self:GetChecked() or nil
					-- Music or Effects is checked while any of its categories is checked
					if menu.SyncMain then menu:SyncMain() end
					playScroll = nil
					-- Changing categories closes settings so the listing can be seen
					if LeaSoundsLC.SettingsShown then LeaSoundsLC.CloseSettings() end
					C_Timer.After(0.001, SetListingFunc)
				end)
				textWidth = max(textWidth, Cbox.f:GetStringWidth() or 0)
			end

			textWidth = ceil(textWidth)
			local width = 24 + textWidth + 24
			for i, Cbox in ipairs(rows) do
				Cbox.t:SetSize(width - 16, 20)
				Cbox.f:SetWidth(textWidth)
				Cbox:SetHitRectInsets(0, -textWidth, 0, 0)
			end
			menu:SetWidth(width)

			-- Show the categories which are shown (all of them until the sounds are loaded) and fit the submenu to them
			menu.shown = {}
			for i = 1, #categories do menu.shown[i] = true end
			local function Layout()
				local n = 0
				for i, Cbox in ipairs(rows) do
					Cbox:ClearAllPoints()
					if menu.shown[i] then
						Cbox:SetPoint("TOPLEFT", 8, -7 - n * 22)
						Cbox:Show()
						n = n + 1
					else
						Cbox:Hide()
					end
				end
				menu:SetHeight(14 + n * 22)
			end
			Layout()

			-- Hide the categories which have no sounds in this game version (present is category number = true)
			function menu:SetAvailable(present)
				for i = 1, #categories do menu.shown[i] = present[i] and true or false end
				Layout()
			end
			-- Tick the checked categories when the submenu is shown
			function menu:Refresh()
				for i, cat in ipairs(categories) do
					rows[i]:SetChecked(not LeaSoundsLC[offVar][cat[1]])
				end
			end
			return menu
		end

		local musicMenu = CreateCategoryMenu(musicCategories, "MusicCatOff")
		local sfxMenu = CreateCategoryMenu(effectCategories, "SFXCatOff")

		-- Music and Effects check or uncheck all of their categories, and are checked while any of their categories is checked
		for field, info in pairs({SoundMusic = {musicMenu, musicCategories, "MusicCatOff"}, SoundSFX = {sfxMenu, effectCategories, "SFXCatOff"}}) do
			local menu, categories, offVar = info[1], info[2], info[3]
			local Cbox = LeaSoundsCB[field]
			-- Check Music or Effects if any of its shown categories is checked, otherwise uncheck it
			function menu:SyncMain()
				local anyOn = false
				for i, cat in ipairs(categories) do
					if menu.shown[i] and not LeaSoundsLC[offVar][cat[1]] then anyOn = true; break end
				end
				LeaSoundsLC[field] = anyOn and "On" or "Off"
				Cbox:SetChecked(anyOn)
				if menu.UpdateIndicator then menu:UpdateIndicator() end
			end
			-- Check or uncheck all of the shown categories to match Music or Effects
			function menu:SyncCategories()
				local off = LeaSoundsLC[field] ~= "On"
				for i, cat in ipairs(categories) do
					if menu.shown[i] then LeaSoundsLC[offVar][cat[1]] = off or nil end
				end
				if menu:IsShown() then menu:Refresh() end
				if menu.UpdateIndicator then menu:UpdateIndicator() end
			end
			-- When the sounds have loaded, make saved settings agree (unchecked Music or Effects unchecks its categories,
			-- and checked Music or Effects with none of its categories checked is unchecked)
			function menu:SyncOnLoad()
				if LeaSoundsLC[field] == "On" then menu:SyncMain() else menu:SyncCategories() end
			end
			Cbox:SetScript("OnClick", function(self)
				LeaSoundsLC[field] = self:GetChecked() and "On" or "Off"
				menu:SyncCategories()
				playScroll = nil
				-- Changing categories closes settings so the listing can be seen
				if LeaSoundsLC.SettingsShown then LeaSoundsLC.CloseSettings() end
				C_Timer.After(0.001, SetListingFunc)
			end)
		end

		-- Music and Effects rows open their category submenus (the arrow shows this)
		for field, info in pairs({SoundMusic = {musicMenu, musicCategories, "MusicCatOff"}, SoundSFX = {sfxMenu, effectCategories, "SFXCatOff"}}) do
			local menu, categories, offVar = info[1], info[2], info[3]
			local Cbox = LeaSoundsCB[field]
			Cbox.arrow = Cbox:CreateTexture(nil, "ARTWORK")
			Cbox.arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
			Cbox.arrow:SetSize(12, 12)
			Cbox.arrow:SetPoint("RIGHT", Cbox.t, "RIGHT", -2, 0)
			Cbox:SetScript("OnEnter", function(self) self.t:Show(); ShowSubMenu(menu) end)
			Cbox:SetScript("OnLeave", function(self) self.t:Hide() end)

			-- Small gold cross beside the arrow when Music or Effects is checked but some of its categories are not
			-- (like the world map filter dropdown, clicking it checks all of the categories again)
			local reset = CreateFrame("Button", nil, Cbox)
			Cbox.reset = reset
			reset:SetSize(14, 14)
			reset:SetPoint("RIGHT", Cbox.arrow, "LEFT", -2, 0)
			-- The cross is drawn in the same gold as the button icons (white while the mouse is over it)
			-- It's made of small squares placed on whole screen pixels (like pixel art) so it looks exactly the same on every row
			local crossBlocks, crossColor = {}, {iconGold[1], iconGold[2], iconGold[3]}
			local function SetCrossColor(r, g, b)
				crossColor[1], crossColor[2], crossColor[3] = r, g, b
				for void, block in ipairs(crossBlocks) do block:SetColorTexture(r, g, b) end
			end
			local function DrawCross()
				local cx, cy = reset:GetCenter()
				if not cx then return end
				-- Screen pixels per unit of this frame (the UI scale and the screen resolution both count)
				local unitFactor = PixelUtil and PixelUtil.GetPixelToUIUnitFactor and PixelUtil.GetPixelToUIUnitFactor()
				if not unitFactor then
					local void, screenHeight = GetPhysicalScreenSize()
					unitFactor = 768 / screenHeight
				end
				local ppu = reset:GetEffectiveScale() / unitFactor
				-- Cross size and line thickness in whole screen pixels (about 6 units across with lines about 1.5 units thick)
				local size = max(5, floor(6 * ppu + 0.5))
				local thick = max(1, floor(1.5 * ppu + 0.5))
				-- Top-left corner of the cross on the nearest whole screen pixel, as an offset from the button's center
				local left = floor(cx * ppu - size / 2 + 0.5)
				local top = floor(cy * ppu + size / 2 + 0.5)
				local offsetX, offsetY = left / ppu - cx, top / ppu - cy
				-- Two diagonals of squares, each square one pixel along from the last
				local steps = size - thick + 1
				local count = 0
				for i = 0, steps - 1 do
					for void, column in ipairs({i, steps - 1 - i}) do
						count = count + 1
						local block = crossBlocks[count]
						if not block then
							block = reset:CreateTexture(nil, "ARTWORK")
							crossBlocks[count] = block
						end
						block:SetColorTexture(crossColor[1], crossColor[2], crossColor[3])
						block:SetSize(thick / ppu, thick / ppu)
						block:ClearAllPoints()
						block:SetPoint("TOPLEFT", reset, "CENTER", offsetX + column / ppu, offsetY - i / ppu)
						block:Show()
					end
				end
				for i = count + 1, #crossBlocks do crossBlocks[i]:Hide() end
			end
			-- Draw the cross when it's shown (the menu's position and the UI scale are known then)
			reset:HookScript("OnShow", DrawCross)
			reset:HookScript("OnSizeChanged", DrawCross)
			SetCrossColor(iconGold[1], iconGold[2], iconGold[3])
			reset:Hide()
			reset:SetScript("OnEnter", function()
				Cbox.t:Show()
				ShowSubMenu(menu)
				SetCrossColor(1, 1, 1)
			end)
			reset:SetScript("OnLeave", function()
				Cbox.t:Hide()
				SetCrossColor(iconGold[1], iconGold[2], iconGold[3])
			end)
			reset:SetScript("OnClick", function()
				LeaSoundsLC[field] = "On"
				Cbox:SetChecked(true)
				menu:SyncCategories()
				playScroll = nil
				if LeaSoundsLC.SettingsShown then LeaSoundsLC.CloseSettings() end
				C_Timer.After(0.001, SetListingFunc)
			end)

			-- Show the cross if Music or Effects is checked and any of its shown categories is unchecked
			function menu:UpdateIndicator()
				local partial = false
				if LeaSoundsLC[field] == "On" then
					for i, cat in ipairs(categories) do
						if menu.shown[i] and LeaSoundsLC[offVar][cat[1]] then partial = true; break end
					end
				end
				reset:SetShown(partial)
			end
			menu:UpdateIndicator()
		end

		-- Hovering a row without a submenu closes any open submenu
		for void, field in ipairs({"SoundUnknown", "SoundUnplayable", "SoundMuted"}) do
			LeaSoundsCB[field]:HookScript("OnEnter", function() ShowSubMenu(nil) end)
		end

		----------------------------------------------------------------------
		-- Settings item in the menu
		----------------------------------------------------------------------

		-- Settings item (no checkbox, label lines up with the category labels)
		local settingsItem = CreateFrame("Button", nil, catMenu)
		settingsItem:SetSize(130 - 16, 20)
		settingsItem:SetPoint("TOPLEFT", 8, -7 - 5 * 22 - 16 - 6)
		settingsItem:SetNormalFontObject("GameFontHighlightLeft")
		settingsItem:SetText(L["Settings"])
		settingsItem:GetFontString():ClearAllPoints()
		settingsItem:GetFontString():SetPoint("LEFT", 24, 0)
		settingsItem:SetPushedTextOffset(0, 0)
		-- Cogwheel in place of a checkbox (same texture and colour as the Leatrix Plus configuration buttons)
		settingsItem.icon = settingsItem:CreateTexture(nil, "ARTWORK")
		settingsItem.icon:SetTexture("Interface\\WorldMap\\Gear_64.png")
		settingsItem.icon:SetTexCoord(0, 0.50, 0, 0.50)
		settingsItem.icon:SetVertexColor(1.0, 0.82, 0, 1.0)
		settingsItem.icon:SetSize(20, 20)
		settingsItem.icon:SetPoint("LEFT", 2, 0)
		settingsItem.t = settingsItem:CreateTexture(nil, "BACKGROUND")
		settingsItem.t:SetAllPoints()
		settingsItem.t:SetColorTexture(0.3, 0.3, 0.0, 0.8)
		settingsItem.t:SetAlpha(0.7)
		settingsItem.t:Hide()
		settingsItem:SetScript("OnEnter", function() settingsItem.t:Show(); ShowSubMenu(nil) end)
		settingsItem:SetScript("OnLeave", function() settingsItem.t:Hide() end)

		----------------------------------------------------------------------
		-- Mounts item in the menu (lists the mounts so their sounds can be shown, as this game version has no mount journal)
		----------------------------------------------------------------------

		local mountsItem
		if type(Leatrix_Sounds["MOUNT_SPELLS"]) == "string" and ScrollUtil and ScrollUtil.InitScrollBoxListWithScrollBar and CreateScrollBoxListLinearView then
			-- Settings moves down to make room (with a dividing line between Mounts and Settings) and the menu gets taller
			catMenu:SetHeight(catMenu:GetHeight() + 22 + 8)
			settingsItem:ClearAllPoints()
			settingsItem:SetPoint("TOPLEFT", 8, -7 - 5 * 22 - 16 - 6 - 22 - 8)
			catMenu.divider3 = catMenu:CreateTexture(nil, "ARTWORK")
			catMenu.divider3:SetColorTexture(0.6, 0.6, 0.6, 0.5)
			catMenu.divider3:SetHeight(1)
			catMenu.divider3:SetPoint("TOPLEFT", 10, -7 - 5 * 22 - 16 - 6 - 22 - 4)
			catMenu.divider3:SetPoint("TOPRIGHT", -10, -7 - 5 * 22 - 16 - 6 - 22 - 4)
			mountsItem = CreateFrame("Button", nil, catMenu)
			mountsItem:SetSize(130 - 16, 20)
			mountsItem:SetPoint("TOPLEFT", 8, -7 - 5 * 22 - 16 - 6)
			mountsItem:SetNormalFontObject("GameFontHighlightLeft")
			-- The list has a Pets tab too if there is pet data (Leatrix_Sounds["PET_SPELLS"], made by the R script with the mob sound data)
			LeaSoundsLC.HasPets = type(Leatrix_Sounds["PET_SPELLS"]) == "string" and strfind(Leatrix_Sounds["PET_SPELLS"], "%d") and true or false
			mountsItem:SetText(LeaSoundsLC.HasPets and L["Mounts & Pets"] or L["Mounts"])
			mountsItem:GetFontString():ClearAllPoints()
			mountsItem:GetFontString():SetPoint("LEFT", 24, 0)
			mountsItem:SetPushedTextOffset(0, 0)
			-- Horse icon in place of a checkbox
			mountsItem.icon = mountsItem:CreateTexture(nil, "ARTWORK")
			mountsItem.icon:SetTexture("Interface\\Icons\\Ability_Mount_RidingHorse")
			mountsItem.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
			mountsItem.icon:SetSize(16, 16)
			mountsItem.icon:SetPoint("LEFT", 4, 0)
			mountsItem.t = mountsItem:CreateTexture(nil, "BACKGROUND")
			mountsItem.t:SetAllPoints()
			mountsItem.t:SetColorTexture(0.3, 0.3, 0.0, 0.8)
			mountsItem.t:SetAlpha(0.7)
			mountsItem.t:Hide()
			mountsItem:SetScript("OnEnter", function() mountsItem.t:Show(); ShowSubMenu(nil) end)
			mountsItem:SetScript("OnLeave", function() mountsItem.t:Hide() end)
			-- The mounts list shows above the Menu button (it's set up with the mount sounds)
			-- Clicking it while the list is showing closes the list
			mountsItem:SetScript("OnClick", function()
				catMenu:Hide()
				if LeaSoundsLC.ShowMountList then LeaSoundsLC.ShowMountList(catBtn) end
			end)
			LeaSoundsLC.MountsItem = mountsItem
		end

		-- Make the menu wider if any (translated) label doesn't fit
		do
			local labelWidth = 90
			for void, field in ipairs({"SoundMusic", "SoundSFX", "SoundUnknown", "SoundUnplayable", "SoundMuted"}) do
				-- Music and Effects have an arrow for their submenus
				-- (and room for the red cross shown when some of their categories are unchecked)
				local arrow = LeaSoundsCB[field].arrow and 32 or 0
				labelWidth = max(labelWidth, (LeaSoundsCB[field].f:GetStringWidth() or 0) + arrow)
			end
			labelWidth = max(labelWidth, settingsItem:GetFontString():GetStringWidth() or 0)
			if mountsItem then labelWidth = max(labelWidth, mountsItem:GetFontString():GetStringWidth() or 0) end
			labelWidth = ceil(labelWidth)
			local menuWidth = 130 + labelWidth - 90
			catMenu:SetWidth(menuWidth)
			for void, field in ipairs({"SoundMusic", "SoundSFX", "SoundUnknown", "SoundUnplayable", "SoundMuted"}) do
				local Cbox = LeaSoundsCB[field]
				Cbox.t:SetWidth(menuWidth - 16)
				Cbox.f:SetWidth(labelWidth)
				Cbox:SetHitRectInsets(0, -labelWidth, 0, 0)
			end
			settingsItem:SetWidth(menuWidth - 16)
			if mountsItem then mountsItem:SetWidth(menuWidth - 16) end
		end

		-- The search box and playback buttons are hidden while settings are showing
		local bottomBar = {sBox, stopBtn, prevBtn, nextBtn}
		local function ShowBottomBar(show)
			for void, item in ipairs(bottomBar) do item:SetShown(show) end
		end

		-- Show settings in place of the listing
		local function ShowSettings()
			if LeaSoundsLC.SettingsShown then return end
			LeaSoundsLC.SettingsShown = true
			catMenu:Hide()
			if LeaSoundsLC["TrackMenu"] then LeaSoundsLC["TrackMenu"]:Hide() end
			sBox:ClearFocus()
			scrollFrame:Hide()
			UpdateList()
			ShowBottomBar(false)
			-- Back replaces the Menu button
			catBtn:Hide()
			backBtn:Show()
			settingsFrame:Show()
		end

		-- Close settings and show the listing again
		local function CloseSettings()
			if not LeaSoundsLC.SettingsShown then return end
			LeaSoundsLC.SettingsShown = false
			-- Close the language dropdown if it's open
			if langDrop.IsMenuOpen and langDrop:IsMenuOpen() then langDrop:CloseMenu() end
			settingsFrame:Hide()
			ShowBottomBar(true)
			backBtn:Hide()
			catBtn:Show()
			scrollFrame:Show()
			UpdateList()
		end
		LeaSoundsLC.CloseSettings = CloseSettings

		settingsItem:SetScript("OnClick", function()
			catMenu:Hide()
			if LeaSoundsLC.SettingsShown then CloseSettings() else ShowSettings() end
		end)
		backBtn:SetScript("OnClick", CloseSettings)
		-- Close settings properly if the settings frame is hidden (such as when the panel is closed)
		-- (hooked so it does not replace the earlier hide handlers, such as the one that cancels Are you sure?)
		settingsFrame:HookScript("OnHide", CloseSettings)
		-- Close settings when the panel is closed so the listing shows next time
		PageF:HookScript("OnHide", CloseSettings)


		-- Toggle dropdown
		catBtn:SetScript("OnClick", function()
			-- Clicking it while the mounts list is showing closes the list
			if LeaSoundsLC.HideMountList and LeaSoundsLC.HideMountList() then return end
			if catMenu:IsShown() then catMenu:Hide() else catMenu:Show() end
		end)

		-- Close dropdown when clicking anywhere else
		catMenu:SetScript("OnShow", function(self) pcall(self.RegisterEvent, self, "GLOBAL_MOUSE_DOWN") end)
		catMenu:SetScript("OnHide", function(self) self:UnregisterAllEvents(); ShowSubMenu(nil) end)
		catMenu:SetScript("OnEvent", function(self)
			if not self:IsMouseOver() and not catBtn:IsMouseOver() and not IsMouseOverSubMenu() then self:Hide() end
		end)
		PageF:HookScript("OnHide", function() catMenu:Hide() end)

		----------------------------------------------------------------------
		-- Set defaults (the button is in the settings, this is here so it can use the menus)
		----------------------------------------------------------------------

		LeaSoundsLC.SetDefaults = function()
			-- Menu categories (every music and effects category is checked)
			LeaSoundsLC["SoundMusic"], LeaSoundsLC["SoundSFX"], LeaSoundsLC["SoundUnknown"] = "On", "On", "On"
			LeaSoundsLC["SoundUnplayable"], LeaSoundsLC["SoundMuted"] = "Off", "On"
			wipe(LeaSoundsLC["MusicCatOff"])
			wipe(LeaSoundsLC["SFXCatOff"])
			for void, field in ipairs({"SoundMusic", "SoundSFX", "SoundUnknown", "SoundUnplayable", "SoundMuted"}) do
				LeaSoundsCB[field]:SetChecked(LeaSoundsLC[field] == "On")
			end
			for void, menu in ipairs({musicMenu, sfxMenu}) do
				if menu.SyncCategories then menu:SyncCategories() end
			end
			-- Settings (clicking the click to play checkbox also updates the help text)
			LeaSoundsLC["AutoPlayNext"], LeaSoundsLC["PlayInBackground"] = "Off", "On"
			LeaSoundsCB["AutoPlayNext"]:SetChecked(false)
			LeaSoundsCB["PlayInBackground"]:SetChecked(true)
			LeaSoundsLC["MobSoundsMenu"] = "On"
			LeaSoundsCB["MobSoundsMenu"]:SetChecked(true)
			LeaSoundsCB["ClickToPlay"]:SetChecked(true)
			LeaSoundsCB["ClickToPlay"]:GetScript("OnClick")(LeaSoundsCB["ClickToPlay"])
			-- Panel size and position
			LeaSoundsLC["MainPanelA"], LeaSoundsLC["MainPanelR"], LeaSoundsLC["MainPanelX"], LeaSoundsLC["MainPanelY"] = "CENTER", "CENTER", 0, 0
			PageF:ClearAllPoints()
			PageF:SetPoint(LeaSoundsLC["MainPanelA"], UIParent, LeaSoundsLC["MainPanelR"], LeaSoundsLC["MainPanelX"], LeaSoundsLC["MainPanelY"])
			if LeaSoundsLC.SetPanelSize then LeaSoundsLC:SetPanelSize(800, 616) end
			-- Refresh the listing with the default categories (the language is not changed)
			playScroll = nil
			C_Timer.After(0.001, SetListingFunc)
		end

		----------------------------------------------------------------------
		-- Muting
		----------------------------------------------------------------------

		-- Mute (mute is true) or unmute a list of tracks
		local function SetTracksMuted(tracks, mute)
			sBox:ClearFocus()
			for void, track in ipairs(tracks) do
				local id = GetTrackID(track)
				if id then
					if mute and not MutedSounds[id] then
						-- Stop the track if it's playing, then mute it
						if track == lastPlayed and musicHandle then
							StopSound(musicHandle)
							musicHandle = nil
						end
						if MuteSoundFile then MuteSoundFile(id) end
						MutedSounds[id] = track
					elseif not mute and MutedSounds[id] then
						-- Unmute (removing it from the list first so ending any preview leaves it unmuted)
						MutedSounds[id] = nil
						if previewID == id then EndPreview() end
						if UnmuteSoundFile then UnmuteSoundFile(id) end
					end
				end
			end
			-- If every category is shown, the track stays in the listing so just refresh it
			if LeaSoundsLC["SoundMusic"] == "On" and LeaSoundsLC["SoundSFX"] == "On" and LeaSoundsLC["SoundUnknown"] == "On" and LeaSoundsLC["SoundUnplayable"] == "On" and LeaSoundsLC["SoundMuted"] == "On" then
				UpdateList()
				return
			end
			-- Otherwise the track may have moved in or out of the listing so rebuild it and keep the scroll position
			local oldScroll = scrollFrame:GetVerticalScroll()
			SetListingFunc(true)
			scrollFrame:SetVerticalScroll(min(oldScroll, scrollFrame:GetVerticalScrollRange()))
			-- Keep the selection for tracks which are still in the listing
			PruneSelection()
			-- Keep the playing track if it's still in the listing, otherwise stop it
			local stillListed = false
			if lastPlayed and lastPlayed ~= "" then
				for i = 1, #ListData do
					if ListData[i] == lastPlayed then stillListed = true; break end
				end
			end
			if stillListed then
				UpdateList()
			else
				stopBtn:Click()
			end
		end

		----------------------------------------------------------------------
		-- Playing
		----------------------------------------------------------------------

		-- Queue of tracks for playing selected sounds one after another
		local playQueue, queueIndex

		-- Play a track (fromQueue is set when the track is part of the play queue)
		local function PlayTrack(item, fromQueue, index)
			-- Playing a single track ends the play queue
			if not fromQueue then playQueue = nil end
			-- Enable sound if required (C_CVar is used directly so the game's own CVar code isn't run by the addon, which would taint it)
			if C_CVar.GetCVar("Sound_EnableAllSound") == "0" then C_CVar.SetCVar("Sound_EnableAllSound", "1") end
			-- Disable music if it's currently enabled
			if C_CVar.GetCVar("Sound_EnableMusic") == "1" then C_CVar.SetCVar("Sound_EnableMusic", "0") end
			-- Enable the stop button
			LeaSoundsLC:LockItem(stopBtn, false)
			-- Store the track we are about to play (and its position if known)
			lastPlayed = item
			if index and ListData[index] == item then
				currentIndex, cacheVersion, cacheTrack = index, listVersion, item
			end
			-- Stop currently playing track if there is one
			if musicHandle then StopSound(musicHandle) end
			musicHandle = nil
			EndPreview()
			-- Play track
			local file, soundID = item:match("([^,]+)%#([^,]+)")
			if IsTrackMuted(item) then
				-- Muted tracks are previewed but stay muted in the game
				musicHandle = PreviewMutedSound(GetTrackID(item))
			elseif file and (strfind(file, ".mp3") or strfind(file, ".ogg")) then
				-- Play sound file
				void, musicHandle = PlaySoundFile(soundID, "Master")
			end
			-- Lock the stop button (or play the next queued track) when the sound finishes
			WatchPlayback()
			-- Show selection highlight bars
			UpdateList()
		end

		-- Scroll the listing so the track at a listing position can be seen
		local function ScrollToIndex(target)
			if not target then return end
			-- Row in the scrolling part of the listing (the header rows and the Sound Files heading aren't in it)
			local row = target - ListStart()
			if row < 1 then return end
			local offset = max(0, floor(scrollFrame:GetVerticalScroll() + 0.5))
			if row <= offset then
				scrollFrame:SetVerticalScroll(row - 1)
			elseif row > offset + numButtons then
				scrollFrame:SetVerticalScroll(row - numButtons)
			end
		end

		-- Play the next track in the queue (skipping any which can't be played)
		-- After the last track the queue starts again from the first track, so it keeps playing until stopped
		local function PlayNextInQueue()
			if not playQueue then return end
			-- Try each track at most once (so a queue with nothing playable doesn't go round forever)
			for attempt = 1, #playQueue do
				queueIndex = queueIndex % #playQueue + 1
				PlayTrack(playQueue[queueIndex], true)
				if musicHandle then
					-- Keep the playing track in view
					ScrollToIndex(GetCurrentIndex())
					return
				end
			end
			-- Nothing in the queue can be played
			playQueue = nil
			musicHandle = nil
			LeaSoundsLC:LockItem(stopBtn, true)
			UpdateList()
		end

		-- Play a list of tracks one after another, starting with startTrack (the right-clicked track) and repeating until stopped
		local function PlayTracks(tracks, startTrack)
			if #tracks == 1 then
				PlayTrack(tracks[1])
				return
			end
			local startIndex = 1
			for i = 1, #tracks do
				if tracks[i] == startTrack then startIndex = i; break end
			end
			playQueue, queueIndex = tracks, startIndex - 1
			PlayNextInQueue()
		end

		-- Play the next sound in the listing after the one which just finished (unplayable sounds are skipped)
		-- Returns true if a sound was played (nothing is played after the last sound in the listing)
		local function PlayNextInListing()
			local index = GetCurrentIndex()
			if not index then return false end
			for i = index + 1, #ListData do
				local track = ListData[i]
				if GetTrackID(track) and not unplayableSet[track] then
					SelectOnly(track)
					ScrollToIndex(i)
					PlayTrack(track, false, i)
					if musicHandle then return true end
				end
			end
			return false
		end

		-- When a sound finishes, play the next queued track, the next sound in the listing (if Play the next sound automatically is checked) or lock the stop button
		-- (musicHandle is only cleared before this runs if the sound was stopped, so a stopped sound doesn't play the next one)
		OnPlaybackFinished = function()
			if playQueue then
				PlayNextInQueue()
			elseif musicHandle and LeaSoundsLC["AutoPlayNext"] == "On" and PlayNextInListing() then
				return
			else
				-- Nothing is playing now so remove the playing icon
				musicHandle = nil
				LeaSoundsLC:LockItem(stopBtn, true)
				UpdateList()
			end
		end

		-- Stopping playback ends the play queue
		stopBtn:HookScript("OnClick", function() playQueue = nil end)

		-- Closing the panel stops the playing sound unless Play in background is checked
		-- (not when the whole interface is hidden, such as with ALT+Z)
		PageF:HookScript("OnHide", function()
			if LeaSoundsLC["PlayInBackground"] ~= "On" and UIParent:IsShown() and (musicHandle or playQueue) then
				stopBtn:Click()
			end
		end)

		-- Play the track before (step -1) or after (step 1) the current track
		local function PlayAdjacent(step)
			local index = GetCurrentIndex()
			if not index then return end
			-- After the last track go back to the first, and before the first go to the last
			local target = FindAdjacentTrack(index, step)
			if not target then return end
			local track = ListData[target]
			sBox:ClearFocus()
			SelectOnly(track)
			-- Scroll the listing so the track can be seen
			ScrollToIndex(target)
			PlayTrack(track, false, target)
		end
		prevBtn:SetScript("OnClick", function() PlayAdjacent(-1) end)
		nextBtn:SetScript("OnClick", function() PlayAdjacent(1) end)

		----------------------------------------------------------------------
		-- Right-click menu for tracks
		----------------------------------------------------------------------

		local menuWidth, menuRowHeight = 180, 18

		-- Menu frame is a child of the main panel so it looks like part of it
		local trackMenu = CreateFrame("Frame", nil, PageF, "BackdropTemplate")
		LeaSoundsLC["TrackMenu"] = trackMenu
		trackMenu:SetFrameLevel(PageF:GetFrameLevel() + 30)
		trackMenu:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, tileSize = 16, edgeSize = 14, insets = { left = 4, right = 4, top = 4, bottom = 4 }})
		trackMenu:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
		trackMenu:SetBackdropBorderColor(0.6, 0.6, 0.6, 1.0)
		trackMenu:EnableMouse(true)
		trackMenu:SetClampedToScreen(true)
		trackMenu:Hide()

		-- Menu title shows the sound file name
		trackMenu.title = trackMenu:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		trackMenu.title:SetPoint("TOPLEFT", 12, -9)
		trackMenu.title:SetWidth(menuWidth - 24)
		trackMenu.title:SetJustifyH("LEFT")
		trackMenu.title:SetWordWrap(false)

		----------------------------------------------------------------------
		-- Sound kits
		----------------------------------------------------------------------

		-- The sound kit data is Leatrix_Sounds["KIT"] in Leatrix_Sounds_Kits.lua, a string with one line for each sound file in a sound kit, sorted by sound file ID
		-- Each line is how much the sound file ID goes up from the line before (empty means 1), a |, then the sound kits it's in (empty means the same as the line before)
		-- The first sound kit is the sound kit ID and each one after it is how much the sound kit ID goes up from the one before
		-- (so "53183|10804,3018" then "|" means sound files 53183 and 53184 are both in sound kits 10804 and 13822)
		-- Nothing is built from the string until sound kits are shown, and only the selected sound files are kept

		-- Get the sound kits for the sound file IDs in wanted (a table of sound file ID = true) in one pass through the string
		-- Returns a table of sound file ID = sound kit text (sound files which aren't in a sound kit are left out), or nil if there is no sound kit data
		local function FindFileKits(wanted)
			local data = Leatrix_Sounds["KIT"]
			if type(data) ~= "string" then return end
			local maxID = 0
			for id in pairs(wanted) do if id > maxID then maxID = id end end
			local found, pos, len, fid, kits = {}, 1, #data, 0, ""
			while pos <= len do
				local s, e, step, k = strfind(data, "^(%d*)|([^\n]*)", pos)
				if e then
					fid = fid + (tonumber(step) or 1)
					if k ~= "" then kits = k end
					-- The lines are sorted so stop after the highest sound file ID being looked for
					if fid > maxID then break end
					if wanted[fid] then found[fid] = kits end
					pos = e + 2
				else
					-- Skip a line which isn't in the right format (such as an empty line)
					pos = (strfind(data, "\n", pos, true) or len) + 1
				end
			end
			return found
		end

		-- Get the sound kits which contain every one of the tracks (sorted by sound kit ID)
		-- Returns nil if there is no sound kit data
		local function GetSharedKits(tracks)
			local wanted = {}
			for void, track in ipairs(tracks) do
				local id = GetTrackID(track)
				if id then wanted[id] = true end
			end
			local found = FindFileKits(wanted)
			if not found then return end
			local shared
			for id in pairs(wanted) do
				local kits = found[id]
				-- A sound file in no sound kits means no sound kit has every track
				if not kits then return {} end
				local here, kit = {}, 0
				for step in gmatch(kits, "%d+") do
					kit = kit + tonumber(step)
					here[kit] = true
				end
				if not shared then
					shared = here
				else
					for k in pairs(shared) do
						if not here[k] then shared[k] = nil end
					end
				end
				-- Stop as soon as no sound kits are left
				if not next(shared) then return {} end
			end
			local result = {}
			for kit in pairs(shared or {}) do tinsert(result, kit) end
			table.sort(result)
			return result
		end

		-- Get the tracks in each of a list of sound kits (returns a table of sound kit ID = list of tracks)
		-- Every sound kit is done at once (one pass through the sound kit data and one through the sound files) so choosing between them is instant
		-- Each list is in the same order as the listing (named sounds first then unknown sounds)
		local function GetKitTracks(kits)
			local result, named, unknown, want = {}, {}, {}, {}
			for void, kit in ipairs(kits) do
				want[kit] = true
				result[kit], named[kit], unknown[kit] = {}, {}, {}
			end
			local data = Leatrix_Sounds["KIT"]
			if type(data) ~= "string" or #kits == 0 then return result end
			-- Find the sound files in the sound kits (sound file ID = list of the sound kits it's in, sound kit text is only decoded when it changes)
			local fileKits, pos, len, fid, current = {}, 1, #data, 0, nil
			while pos <= len do
				local s, e, step, k = strfind(data, "^(%d*)|([^\n]*)", pos)
				if e then
					fid = fid + (tonumber(step) or 1)
					if k ~= "" then
						current = nil
						local v = 0
						for step in gmatch(k, "%d+") do
							v = v + tonumber(step)
							if want[v] then
								current = current or {}
								current[#current + 1] = v
							end
						end
					end
					if current then fileKits[fid] = current end
					pos = e + 2
				else
					pos = (strfind(data, "\n", pos, true) or len) + 1
				end
			end
			-- Find their tracks in the sound files
			-- The sound file ID after the # (in the last 9 characters) is worked out from its bytes, which is much faster than making a string for every track
			for void, key in ipairs({"MP3", "OGG", "EXT"}) do
				local source = Leatrix_Sounds[key]
				if type(source) == "table" then
					local into = key == "EXT" and unknown or named
					for i = 1, #source do
						local track = source[i]
						local hash = strfind(track, "#", -9, true)
						if hash then
							local b1, b2, b3, b4, b5, b6, b7, b8 = strbyte(track, hash + 1, -1)
							local id = b1 and b1 - 48
							if b2 then id = id * 10 + b2 - 48
							if b3 then id = id * 10 + b3 - 48
							if b4 then id = id * 10 + b4 - 48
							if b5 then id = id * 10 + b5 - 48
							if b6 then id = id * 10 + b6 - 48
							if b7 then id = id * 10 + b7 - 48
							if b8 then id = id * 10 + b8 - 48
							end end end end end end end
							local inKits = id and fileKits[id]
							if inKits then
								for j = 1, #inKits do tinsert(into[inKits[j]], track) end
							end
						end
					end
				end
			end
			for void, kit in ipairs(kits) do
				local list = result[kit]
				table.sort(named[kit])
				table.sort(unknown[kit])
				for void, track in ipairs(named[kit]) do list[#list + 1] = track end
				for void, track in ipairs(unknown[kit]) do list[#list + 1] = track end
			end
			return result
		end

		-- Back button (replaces the Menu button while the sound kit listing is shown)
		local kitBackBtn = LeaSoundsLC:CreateButton("KitBackButton", PageF, "Back", "BOTTOMRIGHT", -10, 10, menuBtnWidth, 25, "Go back to the sound listing where you left it.")
		AddButtonIcon(kitBackBtn, menuBtnWidth, "previous")
		kitBackBtn:Hide()

		local SelectKit

		-- Sound kit text after the title while the sound kit listing is shown (such as Sound kit 7319 (1 of 6 sound kits containing 53194))
		-- It's the same size as the number of results and lined up with it
		local header = scrollFrame.header
		local kitTitle = header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		kitTitle:SetJustifyH("LEFT")
		kitTitle:SetWordWrap(false)
		kitTitle:Hide()

		-- Sound kit list (on the left of the listing while the sound kit listing is shown, click a sound kit to show its sounds)
		-- Each row is the sound kit ID and the number of sounds in it, such as 1234567 (123)
		-- The rows line up with the listing rows and it scrolls in the same way, one row at a time
		local navRows = {}
		-- The rows in the sound kit list (reused each time the list is updated)
		local navItems = {}
		local navMeasure = PageF:CreateFontString(nil, "ARTWORK", "GameFontHighlightLeft")
		navMeasure:Hide()
		-- Width of the widest row text (sound kit IDs have up to 7 digits and sound kits have up to 3 digits of sounds)
		navMeasure:SetText("8888888 (888)")
		local navTextWidth = ceil(navMeasure:GetStringWidth()) + 2

		local navScroll = CreateFrame("ScrollFrame", nil, PageF, "LeaSoundsConfigurationPanelScrollFrameTemplate")
		navScroll:SetPoint("TOPLEFT", PageF, "TOPLEFT", 0, -42)
		navScroll:SetPoint("BOTTOMLEFT", PageF, "BOTTOMLEFT", 0, 52)
		navScroll:SetWidth(16 + navTextWidth)
		navScroll:SetPanExtent(1)
		-- Above the listing's scroll frame (which it overlaps) so the mouse wheel scrolls the list and not the listing
		navScroll:SetFrameLevel(scrollFrame:GetFrameLevel() + 2)
		-- The scroll bar goes just to the right of the list (closer than the scroll frame template puts it)
		if navScroll.ScrollBar then
			navScroll.ScrollBar:ClearAllPoints()
			navScroll.ScrollBar:SetPoint("TOPLEFT", navScroll, "TOPRIGHT", 2, 0)
			navScroll.ScrollBar:SetPoint("BOTTOMLEFT", navScroll, "BOTTOMRIGHT", 2, -2)
		end
		navScroll.child = CreateFrame("Frame", nil, navScroll)
		navScroll:SetScrollChild(navScroll.child)
		navScroll:Hide()
		-- The listing is moved right by the list, its scroll bar and a gap (the space for the scroll bar is kept when it's hidden so the listing doesn't move)
		local navIndent = navTextWidth + 24

		-- Line between the sound kit list and the listing
		local navLine = PageF:CreateTexture(nil, "ARTWORK")
		navLine:SetColorTexture(0.6, 0.6, 0.6, 0.3)
		navLine:SetWidth(1)
		navLine:SetPoint("TOPLEFT", PageF, "TOPLEFT", 16 + navIndent - 10, -44)
		navLine:SetPoint("BOTTOMLEFT", PageF, "BOTTOMLEFT", 16 + navIndent - 10, 54)
		navLine:Hide()

		-- Width of the list text (wider for mob sounds, where each row says what the mob does, such as Aggro)
		local navWidth = navTextWidth
		local function SetNavWidth(width)
			if width == navWidth then return end
			navWidth = width
			navScroll:SetWidth(16 + width)
			navIndent = width + 24
			navLine:ClearAllPoints()
			navLine:SetPoint("TOPLEFT", PageF, "TOPLEFT", 16 + navIndent - 10, -44)
			navLine:SetPoint("BOTTOMLEFT", PageF, "BOTTOMLEFT", 16 + navIndent - 10, 54)
			for void, row in ipairs(navRows) do row:SetWidth(width) end
		end

		-- Right-click menu for the sound kits in the list (play the sounds in the sound kit one after another or print them in chat)
		local navMenu = CreateFrame("Frame", nil, PageF, "BackdropTemplate")
		navMenu:SetFrameLevel(PageF:GetFrameLevel() + 30)
		navMenu:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, tileSize = 16, edgeSize = 14, insets = { left = 4, right = 4, top = 4, bottom = 4 }})
		navMenu:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
		navMenu:SetBackdropBorderColor(0.6, 0.6, 0.6, 1.0)
		navMenu:EnableMouse(true)
		navMenu:SetClampedToScreen(true)
		navMenu:Hide()

		-- Menu title shows the sound kit
		navMenu.title = navMenu:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		navMenu.title:SetPoint("TOPLEFT", 12, -9)
		navMenu.title:SetWidth(menuWidth - 24)
		navMenu.title:SetJustifyH("LEFT")
		navMenu.title:SetWordWrap(false)

		-- Menu items (label, function given the sound kit and its tracks)
		local navMenuItems = {
			{"Play sounds", function(kit, tracks) PlayTracks(tracks, tracks[1]) end},
			{"Print links in chat", function(kit, tracks)
				DEFAULT_CHAT_FRAME:AddMessage(L["Sound kit"] .. " " .. kit .. " (" .. format(#tracks == 1 and L["%d sound"] or L["%d sounds"], #tracks) .. ")")
				for void, track in ipairs(tracks) do DEFAULT_CHAT_FRAME:AddMessage(track) end
			end},
		}
		for i, item in ipairs(navMenuItems) do
			local mb = CreateFrame("Button", nil, navMenu)
			mb:SetSize(menuWidth - 16, menuRowHeight)
			mb:SetPoint("TOPLEFT", 8, -26 - (i - 1) * menuRowHeight)
			mb:SetNormalFontObject("GameFontHighlightLeft")
			mb:SetText(L[item[1]])
			mb:GetFontString():ClearAllPoints()
			mb:GetFontString():SetPoint("LEFT", 4, 0)
			mb:SetPushedTextOffset(0, 0)
			mb.t = mb:CreateTexture(nil, "BACKGROUND")
			mb.t:SetAllPoints()
			mb.t:SetColorTexture(0.3, 0.3, 0.0, 0.8)
			mb.t:SetAlpha(0.7)
			mb.t:Hide()
			mb:SetScript("OnEnter", function() mb.t:Show() end)
			mb:SetScript("OnLeave", function() mb.t:Hide() end)
			mb:SetScript("OnClick", function()
				local kit = navMenu.kit
				navMenu:Hide()
				local tracks = kit and kitView and kitView.tracks[kit]
				if tracks and #tracks > 0 then item[2](kit, tracks) end
			end)
		end
		navMenu:SetSize(menuWidth, 26 + #navMenuItems * menuRowHeight + 8)

		-- Show the menu for a sound kit at the cursor (the sound kit is shown in the listing first so the sounds being played can be seen)
		local function ShowNavMenu(index)
			if not kitView or not kitView.kits[index] then return end
			trackMenu:Hide()
			if index ~= kitView.index then SelectKit(index) end
			navMenu.kit = kitView.kits[index]
			navMenu.title:SetText(L["Sound kit"] .. " " .. navMenu.kit)
			local x, y = GetCursorPosition()
			local scale = navMenu:GetEffectiveScale()
			navMenu:ClearAllPoints()
			navMenu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale - 4, y / scale + 4)
			navMenu:Show()
		end

		-- Close the menu when clicking anywhere else, scrolling the list, going back to the listing or closing the panel
		navMenu:SetScript("OnShow", function(self) pcall(self.RegisterEvent, self, "GLOBAL_MOUSE_DOWN") end)
		navMenu:SetScript("OnHide", function(self) self:UnregisterAllEvents(); self.kit = nil end)
		navMenu:SetScript("OnEvent", function(self)
			if not self:IsMouseOver() then self:Hide() end
		end)
		navScroll:HookScript("OnVerticalScroll", function() navMenu:Hide() end)
		PageF:HookScript("OnHide", function() navMenu:Hide() end)

		-- Make a row (rows are made when needed, such as when the panel is made taller)
		local function GetNavRow(i)
			if navRows[i] then return navRows[i] end
			local row = CreateFrame("Button", nil, PageF)
			row:SetFrameLevel(navScroll:GetFrameLevel() + 1)
			row:SetSize(navWidth, 16)
			row:SetPoint("TOPLEFT", PageF, "TOPLEFT", 16, -44 - (i - 1) * 16)
			row:SetNormalFontObject("GameFontHighlightLeft")
			row:SetText(" ")
			row:GetFontString():ClearAllPoints()
			row:GetFontString():SetPoint("LEFT", 0, 0)
			-- Long mob sound labels are cut short instead of running into the listing
			row:GetFontString():SetWordWrap(false)
			row:SetPushedTextOffset(0, 0)
			-- Hover and chosen highlight bars (the same colors as the listing)
			row.t = row:CreateTexture(nil, "BACKGROUND")
			row.t:SetAllPoints()
			row.t:SetColorTexture(0.3, 0.3, 0.0, 0.8)
			row.t:SetAlpha(0.7)
			row.t:Hide()
			row.s = row:CreateTexture(nil, "BACKGROUND")
			row.s:SetAllPoints()
			row.s:SetColorTexture(0.3, 0.4, 0.00, 0.6)
			row.s:Hide()
			-- (heading rows aren't highlighted as they can't be clicked)
			row:SetScript("OnEnter", function() if row.index then row.t:Show() end end)
			row:SetScript("OnLeave", function() row.t:Hide() end)
			-- Left-click shows the sound kit's sounds and right-click opens the menu for it
			row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			row:SetScript("OnClick", function(self, btn)
				if not row.index or not kitView then return end
				if btn == "RightButton" then
					ShowNavMenu(row.index)
				elseif row.index ~= kitView.index then
					SelectKit(row.index)
				end
			end)
			navRows[i] = row
			return row
		end

		-- Update the sound kit title and list
		local function UpdateKitNav()
			local kits = kitView and kitView.kits or {}
			local show = kitView and #kits > 0
			local mob = kitView and kitView.mob
			SetNavWidth(mob and mob.navWidth or navTextWidth)
			listIndent = show and navIndent or 0
			-- Sound kit text after the title
			if not kitView then
				kitTitle:Hide()
			elseif mob then
				-- Mob sounds show the mob's name, what the chosen sound kit is for and whether only other mobs using the model have it
				local name = "|cffffffff" .. mob.name .. "|r  |cffaaaaaa("
				if #kits == 0 then
					kitTitle:SetText(name .. L["no sounds found"] .. ")")
				else
					-- (the first sound kit is used if the chosen one isn't in the list)
					local i = kitView.index
					if not i or not kits[i] then i = 1 end
					local text = (mob.labels[i] or "") .. ", " .. L["Sound kit"] .. " " .. kits[i] .. ", " .. format(L["%d of %d"], i, #kits)
					if mob.others[i] == "voice" then
						text = text .. ", " .. L["a voice some mobs with this model have"]
					elseif mob.others[i] then
						text = text .. ", " .. L["used by other mobs with this model"]
					end
					kitTitle:SetText(name .. text .. ")")
				end
				kitTitle:ClearAllPoints()
				kitTitle:SetPoint("TOPLEFT", header, "TOPLEFT", ceil(header.title:GetStringWidth()) + 10, -4)
				-- Cut the text short so it doesn't run into the number of results
				kitTitle:SetWidth(max(40, floor(header:GetWidth() - ceil(header.title:GetStringWidth()) - 10 - header.results:GetStringWidth() - 16)))
				kitTitle:Show()
			else
				-- What the sound kits contain (the right-clicked sound file ID or the number of selected sounds)
				local what = kitView.multi and format(L["all %d selected sounds"], kitView.count) or tostring(kitView.fileID or "?")
				if #kits == 0 then
					kitTitle:SetText("|cffffffff" .. format(L["No sound kits containing %s"], what))
				elseif #kits == 1 then
					kitTitle:SetText("|cffffffff" .. L["Sound kit"] .. " " .. kits[1] .. "|r  |cffaaaaaa(" .. format(L["the only sound kit containing %s"], what) .. ")")
				else
					local i = kits[kitView.index] and kitView.index or 1
					kitTitle:SetText("|cffffffff" .. L["Sound kit"] .. " " .. kits[i] .. "|r  |cffaaaaaa(" .. format(L["%d of %d sound kits containing %s"], i, #kits, what) .. ")")
				end
				kitTitle:ClearAllPoints()
				kitTitle:SetPoint("TOPLEFT", header, "TOPLEFT", ceil(header.title:GetStringWidth()) + 10, -4)
				-- Cut the text short so it doesn't run into the number of results
				kitTitle:SetWidth(max(40, floor(header:GetWidth() - ceil(header.title:GetStringWidth()) - 10 - header.results:GetStringWidth() - 16)))
				kitTitle:Show()
			end
			-- List
			navScroll:SetShown(show)
			navLine:SetShown(show)
			if not show then
				for void, row in ipairs(navRows) do row:Hide() end
				return
			end
			-- The rows (mob sounds have a heading row above each group of sound kits, such as Combat)
			-- Each row is a sound kit's position in the sound kit list, or a heading's text
			local items = navItems
			wipe(items)
			local headings = mob and mob.headings
			for index = 1, #kits do
				if headings and headings[index] then items[#items + 1] = headings[index] end
				items[#items + 1] = index
			end
			-- Scroll range is one step per row (the list can scroll until the last row is in the bottom row)
			navScroll.child:SetSize(navWidth, max(1, #items + floor(navScroll:GetHeight() + 0.5) - numButtons))
			-- The scroll bar is only shown if the list is too long to fit
			if navScroll.ScrollBar then navScroll.ScrollBar:SetShown(#items > numButtons) end
			local offset = max(0, floor(navScroll:GetVerticalScroll() + 0.5))
			for i = 1, max(numButtons, #navRows) do
				local row = GetNavRow(i)
				local item = i <= numButtons and items[offset + i]
				local index = type(item) == "number" and item or nil
				local kit = index and kits[index]
				row.index = kit and index
				if type(item) == "string" then
					-- A heading (it can't be clicked)
					row:SetText(item)
					row:GetFontString():SetWidth(navWidth)
					row:GetFontString():SetTextColor(0.4, 0.78, 1.0)
					row.s:Hide()
					row.t:Hide()
					row:Show()
				elseif kit then
					local count = " |cffaaaaaa(" .. #(kitView.tracks[kit] or {}) .. ")"
					if mob then
						-- Mob sounds say what the mob does instead of the sound kit ID (cut short to fit the list)
						row:SetText(mob.labels[index] .. count)
						row:GetFontString():SetWidth(navWidth)
					else
						row:SetText(kit .. count)
						row:GetFontString():SetWidth(0)
					end
					-- The chosen sound kit is in gold with the chosen highlight bar
					-- (sound kits which only other mobs using the model have are in grey)
					local chosen = index == kitView.index
					if chosen then
						row:GetFontString():SetTextColor(1.0, 0.82, 0.0)
					elseif mob and mob.others[index] then
						row:GetFontString():SetTextColor(0.6, 0.6, 0.6)
					else
						row:GetFontString():SetTextColor(1.0, 1.0, 1.0)
					end
					row.s:SetShown(chosen)
					row:Show()
				else
					row:Hide()
				end
			end
		end
		LeaSoundsLC.UpdateKitNav = UpdateKitNav
		navScroll:HookScript("OnVerticalScroll", UpdateKitNav)
		-- (checked again when the scroll range changes, in case the scroll frame template shows the scroll bar itself)
		navScroll:HookScript("OnScrollRangeChanged", function(self)
			if self.ScrollBar then self.ScrollBar:SetShown(self:GetVerticalScrollRange() > 0.5) end
		end)

		-- Show the sound kits which contain every one of the tracks, with the sounds of the first one in place of the listing
		-- The listing, its scroll position and selection are kept so going back returns to the same place
		-- (showing sound kits from the sound kit listing keeps the listing from before the first time)
		local function ShowKits(tracks)
			if not dataLoaded then return end
			sBox:ClearFocus()
			local kits = GetSharedKits(tracks)
			if not kitView then
				local saved = {}
				for track in pairs(selected) do saved[track] = true end
				kitView = {list = ListData, scroll = scrollFrame:GetVerticalScroll(), selected = saved, anchor = anchor}
			end
			kitView.kits = kits or {}
			-- (the chosen sound kit goes back to the first one now, as the list is updated before it's chosen and a longer list could have been showing)
			kitView.index = 1
			kitView.tracks = GetKitTracks(kitView.kits)
			kitView.missing = not kits
			kitView.multi = #tracks > 1
			kitView.mob = nil
			-- The sound file ID (or the number of sounds) for the text after the title
			kitView.count = #tracks
			kitView.fileID = GetTrackID(tracks[1])
			-- The sound kit list starts at the top
			navScroll:SetVerticalScroll(0)
			catBtn:Hide()
			kitBackBtn:Show()
			-- Nothing is selected when the sound kit listing opens (the listing's selection is kept for going back)
			ClearSelection()
			SelectKit(1)
		end

		-- Show the sounds in a sound kit (index is its position in the sound kit bar)
		SelectKit = function(index)
			if not kitView then return end
			kitView.index = index
			local kit = kitView.kits[index]
			local tracks = kit and kitView.tracks[kit] or {}
			local t = {}
			t[1] = "|cffffd800" .. L["Leatrix Sounds"] .. " " .. LeaSoundsLC["AddonVer"]
			t[2] = "|cffffffaa{" .. #tracks .. " " .. (#tracks == 1 and L["result"] or L["results"]) .. "}"
			t[3] = "|cffffffff"
			if not kit then
				if kitView.mob and kitView.missing then
					t[4] = "|cffffd800" .. L["No target sound data"]
					t[5] = "|cffffffff" .. L["Target sound data is not available."]
				elseif kitView.mob then
					t[4] = "|cffffd800" .. L["No sounds found"]
					t[5] = "|cffffffff" .. L["No sounds were found for this target."]
				elseif kitView.missing then
					t[4] = "|cffffd800" .. L["No sound kit data"]
					t[5] = "|cffffffff" .. L["Sound kit data is not available."]
				else
					t[4] = "|cffffd800" .. L["No sound kits"]
					t[5] = "|cffffffff" .. (kitView.multi and L["No sound kit contains all of the selected sounds."] or L["This sound is not in any sound kits."])
				end
			elseif #tracks == 0 then
				t[4] = "|cffffd800" .. L["No sounds to show"]
				t[5] = "|cffffffff" .. L["None of the sounds in this sound kit are in the sound listing."]
			else
				t[4] = soundFilesHeading
				for i = 1, #tracks do t[4 + i] = tracks[i] end
			end
			ListData = t
			ListChanged()
			-- The selection is kept when changing sound kits, so a selected sound which is in both sound kits stays selected
			scrollFrame:SetVerticalScroll(0)
			UpdateList()
		end

		-- Go back from the sound kit listing to the listing where it was left
		EndKitView = function(restore)
			if not kitView then return end
			local saved = kitView
			kitView = nil
			kitBackBtn:Hide()
			catBtn:Show()
			navMenu:Hide()
			UpdateKitNav()
			if LeaSoundsLC["TrackMenu"] then LeaSoundsLC["TrackMenu"]:Hide() end
			if not restore then return end
			ListData = saved.list
			ListChanged()
			wipe(selected)
			for track in pairs(saved.selected) do selected[track] = true end
			anchor = saved.anchor
			-- Rebuild the listing if a sound was muted or unmuted in the sound kit listing
			if saved.rebuild then
				SetListingFunc(true)
				PruneSelection()
			end
			UpdateList()
			scrollFrame:SetVerticalScroll(min(saved.scroll, scrollFrame:GetVerticalScrollRange()))
			UpdateList()
			-- The scroll range isn't updated for the restored listing until the next frame, so the scroll position is set again then
			-- (otherwise the listing could go back to the top instead of where it was left)
			C_Timer.After(0, function()
				if kitView or ListData ~= saved.list then return end
				scrollFrame:SetVerticalScroll(min(saved.scroll, scrollFrame:GetVerticalScrollRange()))
				UpdateList()
			end)
			-- Mount sounds opened from the mounts list go back to the list where it was left
			if saved.fromMounts and LeaSoundsLC.ReopenMountList then LeaSoundsLC.ReopenMountList() end
		end
		kitBackBtn:SetScript("OnClick", function() EndKitView(true) end)

		-- (the target sounds are in a do block so their locals don't count towards the limit for the rest of this function)
		do
		-- (the mob sound data functions are in their own do block, only the ones used further down are kept, so the rest of this function has room for its locals)
		local HasMobData, ReadNumbers, FindPlayer, GetMobKits
		do
		----------------------------------------------------------------------
		-- Mob sounds
		----------------------------------------------------------------------

		-- The mob sound data is in Leatrix_Sounds_Creatures.lua (made by the R script for each game version)
		-- Leatrix_Sounds["CREATURE_ROLES"] is what each sound kit in a sound set is for (such as soundaggroid), in order
		-- Leatrix_Sounds["CREATURE_SETS"] has one line for each sound set, sorted by sound set ID
		-- Each line is how much the sound set ID goes up from the line before (empty means 1), a |, then the sound kit for each role in order (empty means none)
		-- Leatrix_Sounds["CREATURE_MODELS"] has one line for each model, sorted by model file ID
		-- Each line is how much the model file ID goes up from the line before (empty means 1), a |, then the model's own sound sets, then a ; and the sound sets which other mobs using the model have instead (if there are any)
		-- A mob's sounds are found from its model as the game doesn't give addons anything more exact
		-- Voices (what NPCs say when clicked, such as greetings) are optional and are in two more entries:
		-- Leatrix_Sounds["CREATURE_VOICES"] has one line for each voice, sorted by voice ID
		-- Each line is how much the voice ID goes up from the line before (empty means 1), a |, then the greeting, farewell, annoyed and acknowledge sound kits (empty means none), then for rare voices a | and the voice's name
		-- Leatrix_Sounds["CREATURE_MODEL_VOICES"] has one line for each model, sorted by model file ID
		-- Each line is how much the model file ID goes up from the line before (empty means 1), a |, then the voices every mob using the model has, then a ; and the common voices some mobs using the model have, then a ; and the rare voices (if there are any)
		-- A rare voice (such as Thrall's) is only shown if its name (such as thrall) is in the mob's name in lower case with only the letters

		-- Names for what each sound kit in a voice is for, in order
		local mobVoiceNames = {"Greeting", "Farewell", "Annoyed", "Acknowledge"}

		-- Headings in the sound kit list, in the order they're shown (each sound kit is put under one of them)
		local mobGroupNames = {"Summon and special", "Combat", "Idle and movement", "Pet commands", "Voice", "Emotes", "Error messages", "Other", "Other mobs with this model"}
		-- (a mounted player's mount has the same headings after the player's, RIDDEN higher, with the mount's name in front, such as Swift Palomino: Combat)
		-- (kept in one table as the function these are in has a lot of locals)
		local mobGroup = {MOUNT = 1, COMBAT = 2, IDLE = 3, PET = 4, VOICE = 5, EMOTE = 6, ERROR = 7, OTHER = 8, OTHERMOBS = 9, RIDDEN = 100}

		-- The heading for each role in a sound set (a role which isn't here goes under Other)
		local mobRoleGroups = {
			soundexertionid = mobGroup.COMBAT, soundexertioncriticalid = mobGroup.COMBAT, soundinjuryid = mobGroup.COMBAT, soundinjurycriticalid = mobGroup.COMBAT,
			soundinjurycrushingblowid = mobGroup.COMBAT, sounddeathid = mobGroup.COMBAT, soundstunid = mobGroup.COMBAT, soundaggroid = mobGroup.COMBAT,
			soundalertid = mobGroup.COMBAT, customattack = mobGroup.COMBAT, spellcastdirectedsoundid = mobGroup.COMBAT, windupsoundid = mobGroup.COMBAT,
			windupcriticalsoundid = mobGroup.COMBAT, chargesoundid = mobGroup.COMBAT, chargecriticalsoundid = mobGroup.COMBAT, battleshoutsoundid = mobGroup.COMBAT,
			battleshoutcriticalsoundid = mobGroup.COMBAT, tauntsoundid = mobGroup.COMBAT,
			soundstandid = mobGroup.IDLE, soundwingflapid = mobGroup.IDLE, soundwingglideid = mobGroup.IDLE, soundjumpstartid = mobGroup.IDLE, soundjumpendid = mobGroup.IDLE,
			loopsoundid = mobGroup.IDLE, soundfidget = mobGroup.IDLE, birthsoundid = mobGroup.IDLE, submergesoundid = mobGroup.IDLE, submergedsoundid = mobGroup.IDLE,
			soundfootstepid = mobGroup.IDLE,
			soundpetattackid = mobGroup.PET, soundpetorderid = mobGroup.PET, soundpetdismissid = mobGroup.PET,
		}

		-- Names for the roles (a role which isn't here is shown as it is in the data)
		local mobRoleNames = {
			soundexertionid = "Attack", soundexertioncriticalid = "Critical attack",
			soundinjuryid = "Wound", soundinjurycriticalid = "Critical wound", soundinjurycrushingblowid = "Crushing blow wound",
			sounddeathid = "Death", soundstunid = "Stun", soundstandid = "Stand", soundfootstepid = "Footstep", soundaggroid = "Aggro",
			soundwingflapid = "Wing flap", soundwingglideid = "Wing glide", soundalertid = "Alert", soundfidget = "Fidget",
			customattack = "Custom attack", soundjumpstartid = "Jump start", soundjumpendid = "Jump end",
			soundpetattackid = "Pet attack", soundpetorderid = "Pet order", soundpetdismissid = "Pet dismiss",
			loopsoundid = "Loop", birthsoundid = "Birth", spellcastdirectedsoundid = "Spell cast",
			submergesoundid = "Submerge", submergedsoundid = "Submerged", windupsoundid = "Wind up", windupcriticalsoundid = "Critical wind up",
			chargesoundid = "Charge", chargecriticalsoundid = "Critical charge", battleshoutsoundid = "Battle shout",
			battleshoutcriticalsoundid = "Critical battle shout", tauntsoundid = "Taunt",
		}

		-- Check the mob sound data is available
		function HasMobData()
			return type(Leatrix_Sounds["CREATURE_ROLES"]) == "string" and type(Leatrix_Sounds["CREATURE_SETS"]) == "string" and type(Leatrix_Sounds["CREATURE_MODELS"]) == "string"
		end

		-- Read a list of numbers separated by commas
		function ReadNumbers(text)
			local t = {}
			for n in gmatch(text or "", "%d+") do t[#t + 1] = tonumber(n) end
			return t
		end

		-- Get the sound sets for a model file ID (the model's own sound sets and the ones which other mobs using the model have instead)
		-- key is the data to look in (CREATURE_MODELS for sound sets or CREATURE_MODEL_VOICES for voices, which has the same layout)
		local function FindModelSets(modelID, key)
			local data = Leatrix_Sounds[key or "CREATURE_MODELS"]
			if type(data) ~= "string" then return {}, {}, {} end
			local pos, len, id = 1, #data, 0
			while pos <= len do
				local s, e, step, rest = strfind(data, "^(%d*)|([^\n]*)", pos)
				if e then
					id = id + (tonumber(step) or 1)
					if id == modelID then
						-- (voices can have a third list, the rare voices)
						local own, other, rare = strmatch(rest, "^([^;]*);?([^;]*);?(.*)$")
						return ReadNumbers(own), ReadNumbers(other), ReadNumbers(rare)
					end
					-- The lines are sorted so stop after the model file ID being looked for
					if id > modelID then break end
					pos = e + 2
				else
					-- Skip a line which isn't in the right format (such as an empty line)
					pos = (strfind(data, "\n", pos, true) or len) + 1
				end
			end
			return {}, {}, {}
		end

		-- Get the sound kit for each role in the wanted sound sets (a table of sound set ID = true)
		-- Returns a table of sound set ID = {role position = sound kit ID}
		-- key is the data to look in (CREATURE_SETS for sound sets or CREATURE_VOICES for voices, which has the same layout)
		local function FindSetKits(wanted, key)
			local data = Leatrix_Sounds[key or "CREATURE_SETS"]
			if type(data) ~= "string" then return {} end
			local maxID = 0
			for id in pairs(wanted) do if id > maxID then maxID = id end end
			local found, pos, len, id = {}, 1, #data, 0
			while pos <= len do
				local s, e, step, rest = strfind(data, "^(%d*)|([^\n]*)", pos)
				if e then
					id = id + (tonumber(step) or 1)
					-- The lines are sorted so stop after the highest sound set ID being looked for
					if id > maxID then break end
					if wanted[id] then
						-- (a voice has its name and type after the sound kits, which are kept as kits.name and kits.tag)
						local kitText, name, tag = strmatch(rest, "^([^|]*)|?([^|]*)|?(.*)$")
						local kits, i = {}, 0
						for kit in gmatch(kitText .. ",", "([^,]*),") do
							i = i + 1
							if kit ~= "" then kits[i] = tonumber(kit) end
						end
						if name ~= "" then kits.name = name end
						if tag ~= "" then kits.tag = tag end
						found[id] = kits
					end
					pos = e + 2
				else
					pos = (strfind(data, "\n", pos, true) or len) + 1
				end
			end
			return found
		end

		-- Get the sound set and voice of a creature display (nil if it's not in the data)
		local function FindDisplay(displayID)
			local data = Leatrix_Sounds["CREATURE_DISPLAYS"]
			if type(data) ~= "string" or type(displayID) ~= "number" or displayID <= 0 then return end
			local pos, len, id = 1, #data, 0
			while pos <= len do
				local s, e, step, rest = strfind(data, "^(%d*)|([^\n]*)", pos)
				if e then
					id = id + (tonumber(step) or 1)
					if id == displayID then
						local set, voice = strmatch(rest, "^(%d*),?(%d*)")
						return true, tonumber(set), tonumber(voice)
					end
					-- The lines are sorted so stop after the display ID being looked for
					if id > displayID then break end
					pos = e + 2
				else
					pos = (strfind(data, "\n", pos, true) or len) + 1
				end
			end
		end

		-- Get the sounds of a player character from their race, sex (0 male, 1 female) and class (nil if they're not in the data)
		-- Leatrix_Sounds["CREATURE_PLAYERS"] has one line for each player race and sex
		-- Each line is the race ID, a comma and the sex, a |, the model file ID, a |, the sound set, a |, then the sound kits separated by commas
		-- Each sound kit is its ID, a =, its type (e emote, a animation, r error message), a : and what it is (such as hello), then a : and the class ID if it's only for one class
		-- Returns the model file ID, the sound set and a list of {sound kit, label, heading} (emotes first, then error messages)
		function FindPlayer(raceID, sex, classID)
			local data = Leatrix_Sounds["CREATURE_PLAYERS"]
			if type(data) ~= "string" then return end
			-- (a new line is put in front so race 1 can't match the end of race 11)
			local fid, set, entries = strmatch("\n" .. data, "\n" .. raceID .. "," .. sex .. "|(%d*)|(%d*)|([^\n]*)")
			if not entries then return end
			local emotes, errors = {}, {}
			-- (what it is can have digits and a / between more than one thing, such as cantequiplevel/cantequipskill)
			for kit, kind, word, cls in gmatch(entries, "(%d+)=(%a):([%w/]*):?(%d*)") do
				if cls == "" or tonumber(cls) == classID then
					if kind == "r" then
						errors[#errors + 1] = {tonumber(kit), word ~= "" and word or L["Error"], mobGroup.ERROR}
					else
						emotes[#emotes + 1] = {tonumber(kit), word ~= "" and ("/" .. word) or L["Animation"], mobGroup.EMOTE}
					end
				end
			end
			local function ByLabel(a, b) return a[2] < b[2] end
			table.sort(emotes, ByLabel)
			table.sort(errors, ByLabel)
			for void, e in ipairs(errors) do emotes[#emotes + 1] = e end
			return tonumber(fid), tonumber(set), emotes
		end

		-- Get the sound kits a model uses in role order (the model's own sound sets first, then the ones which other mobs using it have instead)
		-- A sound kit used for more than one thing is listed once with all of them (such as Attack, Critical attack)
		-- Returns the sound kits, a label for each one and whether each one is only used by other mobs using the model (or nil if there is no mob sound data)
		-- extra is an optional list of {sound kit, label} shown first (such as a mount's summon sounds) and modelID can be nil if there's only extra
		-- mobName is the mob's name (optional), used to find a rare voice which only that mob has (such as Thrall's)
		-- displayID is the mob's creature display (optional), which gives its exact sound set and voice if it's in the data
		-- player is a player character's sounds (optional, {fid, set, kits} from FindPlayer), which are shown instead of a mob's voices
		-- mount is the mount a player is riding (optional, {name, modelID, extra}), whose sounds are shown after the player's
		function GetMobKits(modelID, extra, mobName, displayID, player, mount)
			if not HasMobData() then return end
			local roles, roleGroups = {}, {}
			for key in gmatch(Leatrix_Sounds["CREATURE_ROLES"], "[^,]+") do
				roles[#roles + 1] = L[mobRoleNames[key] or key]
				roleGroups[#roles] = mobRoleGroups[key] or mobGroup.OTHER
			end
			local voiceRoles, voiceGroups = {}, {}
			for i, key in ipairs(mobVoiceNames) do voiceRoles[i], voiceGroups[i] = L[key], mobGroup.VOICE end
			local own, other, ownVoices, otherVoices, rareVoices = {}, {}, {}, {}, {}
			local found, displaySet, displayVoice = FindDisplay(displayID)
			if player then
				-- A player character's own sound set, unless they look like something else (such as a druid in bear form)
				if player[2] and (not modelID or modelID == player[1]) then
					own = {player[2]}
				elseif modelID then
					own = FindModelSets(modelID)
				end
			elseif found then
				-- The mob's display is known so only its own sound set and voice are shown
				own, ownVoices = {displaySet}, {displayVoice}
			elseif modelID then
				own, other = FindModelSets(modelID)
				ownVoices, otherVoices, rareVoices = FindModelSets(modelID, "CREATURE_MODEL_VOICES")
			end
			local wanted, wantedVoices = {}, {}
			for void, id in ipairs(own) do wanted[id] = true end
			for void, id in ipairs(other) do wanted[id] = true end
			for void, id in ipairs(ownVoices) do wantedVoices[id] = true end
			for void, id in ipairs(otherVoices) do wantedVoices[id] = true end
			-- Rare voices are only looked at if there's a name to match them with
			local nameKey = type(mobName) == "string" and gsub(strlower(mobName), "[^a-z]", "") or ""
			if nameKey ~= "" then
				for void, id in ipairs(rareVoices) do wantedVoices[id] = true end
			end
			local setKits = FindSetKits(wanted)
			local voiceKits = next(wantedVoices) and FindSetKits(wantedVoices, "CREATURE_VOICES") or {}
			-- The rare voices whose name is in the mob's name (the mob's own voice, so the common voices aren't shown)
			local namedVoices = {}
			if nameKey ~= "" then
				for void, id in ipairs(rareVoices) do
					local voiceName = voiceKits[id] and voiceKits[id].name
					if voiceName and strfind(nameKey, voiceName, 1, true) then namedVoices[#namedVoices + 1] = id end
				end
			end
			if #namedVoices > 0 then otherVoices = {} end
			local kits, names, others, where, groups = {}, {}, {}, {}, {}
			-- isOther is false for the model's own sounds, true for sounds only other mobs using the model have
			-- and "voice" for voices only some mobs using the model have (shown in grey like other mobs' sounds)
			-- roleGroups is the heading for each role (sound kits only other mobs using the model have go under their own heading)
			local function AddSets(sets, isOther, kitsBySet, roleNames, roleGroups)
				for void, id in ipairs(sets) do
					local roleKits = kitsBySet[id]
					if roleKits then
						for i = 1, #roleNames do
							local kit = roleKits[i]
							if kit then
								-- (a voice's type is shown after the label, such as Greeting (official))
								local name = roleKits.tag and (roleNames[i] .. " (" .. roleKits.tag .. ")") or roleNames[i]
								local n = where[kit]
								if not n then
									n = #kits + 1
									kits[n], names[n], others[n], where[kit] = kit, {name}, isOther, n
									groups[n] = isOther == true and mobGroup.OTHERMOBS or roleGroups[i]
								elseif others[n] == isOther and not tContains(names[n], name) then
									tinsert(names[n], name)
								end
							end
						end
					end
				end
			end
			-- Extra sound kits first (a sound kit which is also in the model's sound sets is listed once with both labels)
			for void, e in ipairs(extra or {}) do
				local kit, name = e[1], e[2]
				local n = where[kit]
				if not n then
					n = #kits + 1
					kits[n], names[n], others[n], where[kit] = kit, {name}, false, n
					groups[n] = mobGroup.MOUNT
				elseif not tContains(names[n], name) then
					tinsert(names[n], name)
				end
			end
			-- The model's own sounds, then its voices, then the sounds only other mobs using the model have
			AddSets(own, false, setKits, roles, roleGroups)
			-- A player character's emotes and error messages
			for void, e in ipairs(player and player[3] or {}) do
				local kit, name = e[1], e[2]
				local n = where[kit]
				if not n then
					n = #kits + 1
					kits[n], names[n], others[n], where[kit] = kit, {name}, false, n
					groups[n] = e[3] or mobGroup.OTHER
				elseif not tContains(names[n], name) then
					tinsert(names[n], name)
				end
			end
			AddSets(namedVoices, false, voiceKits, voiceRoles, voiceGroups)
			AddSets(ownVoices, false, voiceKits, voiceRoles, voiceGroups)
			AddSets(otherVoices, "voice", voiceKits, voiceRoles, voiceGroups)
			AddSets(other, true, setKits, roles, roleGroups)
			-- The mount a player is riding (its own sounds, then the sounds from its model)
			if mount then
				for void, e in ipairs(mount.extra or {}) do
					local kit, name = e[1], e[2]
					local n = where[kit]
					if not n then
						n = #kits + 1
						kits[n], names[n], others[n], where[kit] = kit, {name}, false, n
						groups[n] = mobGroup.RIDDEN + mobGroup.MOUNT
					elseif not tContains(names[n], name) then
						tinsert(names[n], name)
					end
				end
				if mount.modelID then
					local mountSets = FindModelSets(mount.modelID)
					local wantedMount = {}
					for void, id in ipairs(mountSets) do wantedMount[id] = true end
					local mountGroups = {}
					for i, g in ipairs(roleGroups) do mountGroups[i] = mobGroup.RIDDEN + g end
					AddSets(mountSets, false, FindSetKits(wantedMount), roles, mountGroups)
				end
			end
			-- Put the sound kits in heading order (keeping their order under each heading) and note where each heading goes
			local order = {}
			for n = 1, #kits do order[n] = n end
			table.sort(order, function(a, b)
				if groups[a] ~= groups[b] then return groups[a] < groups[b] end
				return a < b
			end)
			local sortedKits, labels, sortedOthers, headings = {}, {}, {}, {}
			for i, n in ipairs(order) do
				sortedKits[i], labels[i], sortedOthers[i] = kits[n], table.concat(names[n], ", "), others[n]
				if i == 1 or groups[n] ~= groups[order[i - 1]] then
					local g = groups[n]
					if g > mobGroup.RIDDEN then
						headings[i] = mount.name .. ": " .. L[mobGroupNames[g - mobGroup.RIDDEN]]
					else
						headings[i] = L[mobGroupNames[g]]
					end
				end
			end
			return sortedKits, labels, sortedOthers, headings
		end

		end
		-- Leave out sound kits which have exactly the same sound files as one listed before them (such as a mount with several fidget sound kits which are copies)
		-- A left out sound kit's label is added to the one kept if it's different (such as Wound, Critical wound)
		-- headings is moved to the first sound kit kept under it (a heading whose sound kits are all left out is dropped)
		-- Returns the sound kits, labels, others and headings without the copies
		-- (kept in LeaSoundsLC so it doesn't count towards the limit for locals in this function)
		LeaSoundsLC.MergeSameKits = function(kits, labels, others, headings, tracks)
			local newKits, newLabels, newOthers, newHeadings, seen = {}, {}, {}, {}, {}
			local pending
			for i = 1, #kits do
				if headings[i] then pending = headings[i] end
				local list = tracks[kits[i]]
				local key
				if list and #list > 0 then
					local sorted = {}
					for n = 1, #list do sorted[n] = list[n] end
					table.sort(sorted)
					key = table.concat(sorted, "\n")
				end
				local n = key and seen[key]
				if n then
					-- A copy of an earlier sound kit, so only its label is kept (if it's not already there)
					local label = labels[i]
					if label and label ~= "" and not strfind(", " .. newLabels[n] .. ", ", ", " .. label .. ", ", 1, true) then
						newLabels[n] = newLabels[n] .. ", " .. label
					end
				else
					n = #newKits + 1
					newKits[n], newLabels[n], newOthers[n] = kits[i], labels[i] or "", others[i]
					if pending then newHeadings[n] = pending; pending = nil end
					if key then seen[key] = n end
				end
			end
			return newKits, newLabels, newOthers, newHeadings
		end

		-- Mob sounds asked for while the sound files are loading (shown when loading finishes)
		local pendingMob

		-- Show the sounds a mob makes in the sound kit listing (one sound kit for each thing the mob does, such as Aggro)
		local function ShowMobSounds(modelID, name, extra, displayID, player, mount)
			if not dataLoaded then
				pendingMob = {modelID, name, extra, displayID, player, mount}
				return
			end
			pendingMob = nil
			if LeaSoundsLC.SettingsShown then CloseSettings() end
			catMenu:Hide()
			trackMenu:Hide()
			sBox:ClearFocus()
			local kits, labels, others, headings = GetMobKits(modelID, extra, name, displayID, player, mount)
			if not kitView then
				local saved = {}
				for track in pairs(selected) do saved[track] = true end
				kitView = {list = ListData, scroll = scrollFrame:GetVerticalScroll(), selected = saved, anchor = anchor}
			end
			kitView.kits = kits or {}
			-- (the chosen sound kit goes back to the first one now, as the list is updated before it's chosen and a longer list could have been showing)
			kitView.index = 1
			kitView.tracks = GetKitTracks(kitView.kits)
			-- Sound kits which are copies of one listed before them are left out
			if kits then
				kits, labels, others, headings = LeaSoundsLC.MergeSameKits(kits, labels or {}, others or {}, headings or {}, kitView.tracks)
				kitView.kits = kits
			end
			kitView.missing = not kits
			kitView.multi = false
			kitView.count = 0
			kitView.fileID = nil
			-- The list is made wide enough for the labels (up to a limit, longer labels are cut short)
			local width = navTextWidth
			for void, label in ipairs(labels or {}) do
				navMeasure:SetText(label .. " (888)")
				width = max(width, ceil(navMeasure:GetStringWidth()) + 2)
			end
			for void, heading in pairs(headings or {}) do
				navMeasure:SetText(heading)
				width = max(width, ceil(navMeasure:GetStringWidth()) + 2)
			end
			kitView.mob = {name = name or L["This target"], labels = labels or {}, others = others or {}, headings = headings or {}, navWidth = min(width, 220)}
			-- Remember if this was opened from the mounts list so Back goes back to it
			kitView.fromMounts = LeaSoundsLC.MountReturn
			LeaSoundsLC.MountReturn = nil
			-- The sound kit list starts at the top
			navScroll:SetVerticalScroll(0)
			catBtn:Hide()
			kitBackBtn:Show()
			-- Nothing is selected when the sound kit listing opens (the listing's selection is kept for going back)
			ClearSelection()
			SelectKit(1)
		end

		-- Show target sounds asked for while the sound files were loading (run when loading finishes)
		LeaSoundsLC.ShowPendingMobSounds = function()
			if pendingMob then ShowMobSounds(pendingMob[1], pendingMob[2], pendingMob[3], pendingMob[4], pendingMob[5], pendingMob[6]) end
		end

		-- Target frame menu (right-click the target frame and choose Show target sounds)
		-- It's only added if this game version has mob sound data
		if Menu and Menu.ModifyMenu and HasMobData() then

			-- Check a value can be used (the game can hide values from addons, such as in instances)
			local function IsSecret(value)
				return issecretvalue and issecretvalue(value)
			end

			-- Model frame used to find out which model file the target uses
			-- The target is only put in it when the menu opens (the model file is known straight away) and it's cleared straight after
			local targetModel = CreateFrame("PlayerModel", nil, UIParent)
			targetModel:SetSize(1, 1)
			targetModel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
			targetModel:EnableMouse(false)

			-- Model frame only used to read the target's model file and display (it never has a display set by the addon,
			-- so the display it gives is always the target's own and never one left over from the mount sounds)
			local unitModel = CreateFrame("PlayerModel", nil, UIParent)
			unitModel:SetSize(1, 1)
			unitModel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
			unitModel:EnableMouse(false)

			-- Check the target is a mob (players aren't, but anything the game won't say is treated as a mob)
			local function IsTargetMob(unit)
				unit = unit or "target"
				if not UnitExists(unit) then return false end
				local isPlayer = UnitIsPlayer(unit)
				if IsSecret(isPlayer) then return true end
				return not isPlayer
			end

			-- Get the creature ID from the target's GUID (nil if the target isn't a creature)
			local function GetTargetCreatureID(unit)
				local guid = UnitGUID(unit or "target")
				if IsSecret(guid) or type(guid) ~= "string" then return end
				local unitType, void, void, void, void, creatureID = strsplit("-", guid)
				creatureID = tonumber(creatureID)
				if (unitType ~= "Creature" and unitType ~= "Vehicle") or not creatureID then return end
				return creatureID
			end

			-- Find a creature's display from its creature ID, which gives the mob's exact sounds and voice
			-- SetUnit doesn't give the display, but SetCreature with the creature ID from the target's GUID does
			-- modelID is the target's model file, and the display is only used if it has the same model file
			-- (a creature can have more than one display, and SetCreature may not pick the one the target has)
			-- The creature's model can take a few frames to load, and SetCreature can pick another of the creature's displays, so it's tried again a few times
			-- callback gets the display, or nil if it can't be found
			local function FindCreatureDisplay(creatureID, modelID, callback, tries)
				if not creatureID or not unitModel.SetCreature or not unitModel.GetDisplayInfo then callback(nil) return end
				unitModel:SetCreature(creatureID)
				local displayID = unitModel:GetDisplayInfo()
				local displayModel = unitModel:GetModelFileID()
				unitModel:ClearModel()
				if IsSecret(displayID) or IsSecret(displayModel) then callback(nil) return end
				if type(displayID) == "number" and displayID > 0 and type(displayModel) == "number" and displayModel == modelID then
					-- The model has loaded and it's the target's model file, so the display is the target's (or one which looks the same)
					callback(displayID)
				elseif (tries or 0) < 20 then
					-- The model hasn't loaded yet, or the game picked another of the creature's displays (such as a female guard
					-- when the target is a male one), so it's tried again (the game can pick a different display each time)
					C_Timer.After(0.05, function() FindCreatureDisplay(creatureID, modelID, callback, (tries or 0) + 1) end)
				else
					callback(nil)
				end
			end

			-- Get the target's model file ID (nil if the game won't say, such as in instances)
			local function GetTargetModelID(unit)
				unitModel:SetUnit(unit or "target")
				local id = unitModel:GetModelFileID()
				unitModel:ClearModel()
				if IsSecret(id) or type(id) ~= "number" or id <= 0 then return end
				return id
			end

			-- Open the panel with the mob's sounds
			local function OpenMobSounds(modelID, name, extra, displayID)
				-- Prevent panel from showing if Blizzard Store is showing
				if StoreFrame and StoreFrame:GetAttribute("isshown") then return end
				if not PageF:IsShown() then PageF:Show() end
				ShowMobSounds(modelID, name, extra, displayID)
			end

			Menu.ModifyMenu("MENU_UNIT_TARGET", function(owner, rootDescription, contextData)
				-- Nothing is added if the option is turned off in the settings or the target isn't a mob
				if LeaSoundsLC["MobSoundsMenu"] ~= "On" or not IsTargetMob() then return end
				-- The game holds back section headings (such as Other Options) until something is added after them
				-- Throw away any that are still held back so an empty heading isn't shown above ours
				if rootDescription.ClearQueuedDescriptions then rootDescription:ClearQueuedDescriptions() end
				rootDescription:CreateDivider()
				rootDescription:CreateTitle(L["Leatrix Sounds"])
				local modelID = GetTargetModelID()
				if modelID then
					-- The name is read now as the target may change before the button is clicked
					local name = UnitName("target")
					if IsSecret(name) or type(name) ~= "string" or name == "" then name = nil end
					if name then name = gsub(name, "|", "||") end
					-- The creature ID is read now too, and its display is found when the button is clicked (its model can take a few frames to load)
					local creatureID = GetTargetCreatureID()
					rootDescription:CreateButton(L["Show target sounds"], function()
						FindCreatureDisplay(creatureID, modelID, function(displayID) OpenMobSounds(modelID, name, nil, displayID) end)
					end)
				else
					-- The game won't say which model the mob uses (such as in instances) so the button can't be used
					local button = rootDescription:CreateButton(L["Target sounds are not available here"], function() end)
					button:SetEnabled(false)
				end
			end)

			-- Check the game is hiding a unit's details (such as in a restricted instance), or its auras too if needAuras is set
			-- (it's kept in LeaSoundsLC so it doesn't count towards the limit for locals in this function)
			LeaSoundsLC.UnitHidden = function(unit, needAuras)
				if C_Secrets then
					local ok, hidden = pcall(function()
						if C_Secrets.ShouldUnitIdentityBeSecret and C_Secrets.ShouldUnitIdentityBeSecret(unit) then return true end
						if needAuras and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret() then return true end
						return false
					end)
					if not ok or hidden then return true end
				end
				return false
			end

			-- Get a function which opens the panel with a mob's sounds (nil if the game won't say which model the mob uses)
			-- The model, name and creature ID are read now as the unit may change before the function is called,
			-- and the mob's display is found when it's called (its model can take a few frames to load)
			LeaSoundsLC.MobOpener = function(unit)
				local ok, modelID = pcall(GetTargetModelID, unit)
				if not ok then pcall(unitModel.ClearModel, unitModel) return end
				if not modelID then return end
				local okName, name = pcall(UnitName, unit)
				if not okName or IsSecret(name) or type(name) ~= "string" or name == "" then name = nil end
				if name then name = gsub(name, "|", "||") end
				local okID, creatureID = pcall(GetTargetCreatureID, unit)
				if not okID then creatureID = nil end
				return function()
					FindCreatureDisplay(creatureID, modelID, function(displayID) OpenMobSounds(modelID, name, nil, displayID) end)
				end
			end

			-- Get the model file a creature display uses, or a creature uses if isCreature is set (the model may take a few frames to load so it's tried again a few times)
			-- callback gets the model file ID (or nil if it can't be found)
			LeaSoundsLC.FindModelFile = function(id, isCreature, callback, tries)
				local ok, modelID = pcall(function()
					if isCreature then targetModel:SetCreature(id) else targetModel:SetDisplayInfo(id) end
					local modelID = targetModel:GetModelFileID()
					targetModel:ClearModel()
					if IsSecret(modelID) or type(modelID) ~= "number" or modelID <= 0 then return end
					return modelID
				end)
				if not ok then pcall(targetModel.ClearModel, targetModel) callback(nil) return end
				if modelID then
					callback(modelID)
				elseif (tries or 0) < 10 then
					C_Timer.After(0.05, function() LeaSoundsLC.FindModelFile(id, isCreature, callback, (tries or 0) + 1) end)
				else
					callback(nil)
				end
			end

			-- Get a function which opens the panel with a creature's sounds when there's no unit for it (such as a boss on a dungeon map)
			-- displayID gives the creature's exact sounds, otherwise its display is found from the creature ID (nil if there's neither)
			LeaSoundsLC.CreatureOpener = function(creatureID, displayID, name)
				if IsSecret(creatureID) or type(creatureID) ~= "number" or creatureID <= 0 then creatureID = nil end
				if IsSecret(displayID) or type(displayID) ~= "number" or displayID <= 0 then displayID = nil end
				if not creatureID and not displayID then return end
				if not displayID and not targetModel.SetCreature then return end
				if IsSecret(name) or type(name) ~= "string" or name == "" then name = nil end
				if name then name = gsub(name, "|", "||") end
				return function()
					local function NotFound() LeaSoundsLC:Print(L["Target sounds are not available for this target."]) end
					if displayID then
						LeaSoundsLC.FindModelFile(displayID, false, function(modelID)
							if modelID then OpenMobSounds(modelID, name, nil, displayID) else NotFound() end
						end)
					else
						LeaSoundsLC.FindModelFile(creatureID, true, function(modelID)
							if not modelID then NotFound() return end
							FindCreatureDisplay(creatureID, modelID, function(display) OpenMobSounds(modelID, name, nil, display) end)
						end)
					end
				end
			end

			----------------------------------------------------------------------
			-- Player sounds (right-click a player's target frame and choose Show target sounds)
			----------------------------------------------------------------------

			-- Get a player's sounds from their race, sex and class (nil if the game won't say or they're not in the data)
			-- Returns {model file ID, sound set, list of {sound kit, label}} for GetMobKits and the player's model file ID
			local function GetPlayerSounds(unit)
				local void, void, raceID = UnitRace(unit)
				local sex = UnitSex(unit)
				local void, void, classID = UnitClass(unit)
				if IsSecret(raceID) or IsSecret(sex) or IsSecret(classID) then return end
				if type(raceID) ~= "number" or (sex ~= 2 and sex ~= 3) then return end
				if type(classID) ~= "number" then classID = nil end
				-- (UnitSex is 2 for male and 3 for female, the data uses 0 and 1)
				local fid, set, kits = FindPlayer(raceID, sex - 2, classID)
				if not kits then return end
				-- The model the player has now (such as a druid in bear form), which is only used if it's not their race's model
				unitModel:SetUnit(unit)
				local modelID = unitModel:GetModelFileID()
				unitModel:ClearModel()
				if IsSecret(modelID) or type(modelID) ~= "number" or modelID <= 0 then modelID = nil end
				return {fid, set, kits}, modelID
			end

			-- Add the player sounds and mount sounds buttons to the menus the game uses for players (the target frame uses one of these depending on who the player is)
			local function AddPlayerMenu(owner, rootDescription, contextData)
				local unit = contextData and contextData.unit or "target"
				if IsSecret(unit) or type(unit) ~= "string" or not UnitExists(unit) then return end
				local isPlayer = UnitIsPlayer(unit)
				if IsSecret(isPlayer) or not isPlayer then return end
				if LeaSoundsLC["MobSoundsMenu"] ~= "On" then return end
				-- The player's sounds and mount are read now as the target may change before the button is clicked
				local player, modelID = GetPlayerSounds(unit)
				local mount = LeaSoundsLC.GetUnitMountInfo and LeaSoundsLC.GetUnitMountInfo(unit)
				if not player and not mount then return end
				-- (a player who isn't in the data still gets their model's sounds, but never the voices mobs with that model have)
				player = player or {nil, nil, {}}
				-- The game holds back section headings until something is added after them, so throw away any that are still held back
				if rootDescription.ClearQueuedDescriptions then rootDescription:ClearQueuedDescriptions() end
				rootDescription:CreateDivider()
				rootDescription:CreateTitle(L["Leatrix Sounds"])
				local name = UnitName(unit)
				if IsSecret(name) or type(name) ~= "string" or name == "" then name = L["This target"] end
				name = gsub(name, "|", "||")
				rootDescription:CreateButton(L["Show target sounds"], function()
					-- Prevent panel from showing if Blizzard Store is showing
					if StoreFrame and StoreFrame:GetAttribute("isshown") then return end
					local function Show(mountSounds)
						if not PageF:IsShown() then PageF:Show() end
						ShowMobSounds(modelID, name, nil, nil, player, mountSounds)
					end
					-- The mount's sounds are shown after the player's (its model can take a few frames to find)
					if mount and LeaSoundsLC.ResolveMount then
						LeaSoundsLC.ResolveMount(mount[1], mount[3], mount[4], function(mountModel, extra)
							if mountModel or #extra > 0 then
								Show({name = mount[2], modelID = mountModel, extra = extra})
							else
								Show(nil)
							end
						end)
					else
						Show(nil)
					end
				end)
			end

			for void, tag in ipairs({"MENU_UNIT_SELF", "MENU_UNIT_PLAYER", "MENU_UNIT_ENEMY_PLAYER", "MENU_UNIT_PARTY", "MENU_UNIT_RAID_PLAYER", "MENU_UNIT_TARGET"}) do
				Menu.ModifyMenu(tag, AddPlayerMenu)
			end

			-- Get a function which opens the panel with a player's sounds and the mount they're riding (nil if there are no sounds for them)
			-- The player's sounds and mount are read now as the unit may change before the function is called
			-- (it's kept in LeaSoundsLC so it doesn't count towards the limit for locals in this function)
			LeaSoundsLC.PlayerOpener = function(unit)
				local ok, player, modelID = pcall(GetPlayerSounds, unit)
				if not ok then pcall(unitModel.ClearModel, unitModel) player, modelID = nil, nil end
				local okMount, mount = pcall(function() return not LeaSoundsLC.UnitHidden(unit, true) and LeaSoundsLC.GetUnitMountInfo and LeaSoundsLC.GetUnitMountInfo(unit) end)
				if not okMount then mount = nil end
				if not player and not mount then return end
				-- (a player who isn't in the data still gets their model's sounds, but never the voices mobs with that model have)
				player = player or {nil, nil, {}}
				local okName, name = pcall(UnitName, unit)
				if not okName or IsSecret(name) or type(name) ~= "string" or name == "" then name = L["This target"] end
				name = gsub(name, "|", "||")
				return function()
					-- Prevent panel from showing if Blizzard Store is showing
					if StoreFrame and StoreFrame:GetAttribute("isshown") then return end
					local function Show(mountSounds)
						if not PageF:IsShown() then PageF:Show() end
						ShowMobSounds(modelID, name, nil, nil, player, mountSounds)
					end
					-- The mount's sounds are shown after the player's (its model can take a few frames to find)
					if mount and LeaSoundsLC.ResolveMount then
						LeaSoundsLC.ResolveMount(mount[1], mount[3], mount[4], function(mountModel, extra)
							if mountModel or #extra > 0 then
								Show({name = mount[2], modelID = mountModel, extra = extra})
							else
								Show(nil)
							end
						end)
					else
						Show(nil)
					end
				end
			end

			-- Get a function which opens the panel with a unit's sounds (a player or mob), or nil if there are none or the game is hiding the unit
			LeaSoundsLC.UnitOpener = function(unit)
				if IsSecret(unit) or type(unit) ~= "string" or LeaSoundsLC.UnitHidden(unit) then return end
				local ok, exists, isPlayer = pcall(function() return UnitExists(unit), UnitIsPlayer(unit) end)
				if not ok or IsSecret(exists) or not exists or IsSecret(isPlayer) then return end
				if isPlayer then return LeaSoundsLC.PlayerOpener(unit) end
				return LeaSoundsLC.MobOpener(unit)
			end

			----------------------------------------------------------------------
			-- Mount sounds (right-click the target frame of a mounted player and choose Show mount sounds)
			----------------------------------------------------------------------

			-- The mount sounds are set up in their own function so their locals don't count towards the limit for this one
			local function SetupMountSounds()

			-- Mounts are found from a player's buffs with Leatrix_Sounds["MOUNT_SPELLS"] (made by the R script with the mob sound data)
			-- The mount journal is used for mounts which aren't in it (if this game version has one)
			local hasJournal = C_MountJournal and C_MountJournal.GetMountFromSpell
			local hasAuras = (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) or UnitBuff

			if (hasJournal or type(Leatrix_Sounds["MOUNT_SPELLS"]) == "string") and hasAuras then

				-- Leatrix_Sounds["MOUNT_SPELLS"] has one line for each mount spell, sorted by spell ID
				-- Each line is how much the spell ID goes up from the line before (empty means 1), a |, then the mount ID (empty if it's the same as the spell ID), the model file ID of the mount's first display and (if the model file isn't known) the mount's creature ID, separated by commas
				-- It's read into a table the first time it's needed (spell ID = {mount ID, model file ID, creature ID})
				local mountSpells

				-- Get the mount ID, model file ID and creature ID for a spell (nil if it's not a mount spell in the data)
				local function FindMountSpell(spellID)
					if not mountSpells then
						mountSpells = {}
						local data = Leatrix_Sounds["MOUNT_SPELLS"]
						if type(data) == "string" then
							local id = 0
							for step, mount, fid, creature in gmatch(data, "(%d*)|(%d*),?(%d*),?(%d*)") do
								id = id + (tonumber(step) or 1)
								mountSpells[id] = {tonumber(mount) or id, tonumber(fid), tonumber(creature)}
							end
						end
					end
					local entry = mountSpells[spellID]
					if entry then return entry[1], entry[2], entry[3] end
				end

				-- Get a unit's buff (returns false if the game won't say and nil after the last one, otherwise true, the spell ID and the name)
				local function GetBuff(unit, i)
					if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
						local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
						if not aura then return end
						if IsSecret(aura) or IsSecret(aura.spellId) then return false end
						return true, aura.spellId, aura.name
					end
					local name, void1, void2, void3, void4, void5, void6, void7, void8, spellID = UnitBuff(unit, i)
					if not name then return end
					if IsSecret(spellID) then return false end
					return true, spellID, name
				end

				-- Find the mount a unit is riding from its buffs (nil if it isn't mounted or the game won't say, such as in instances)
				-- Returns the mount ID, the model file ID (if it's known), the buff name and the creature ID (if the model file isn't known)
				local function GetUnitMount(unit)
					for i = 1, 255 do
						local ok, spellID, buffName = GetBuff(unit, i)
						if not ok then return end
						if spellID then
							local mountID, fid, creature = FindMountSpell(spellID)
							if mountID then return mountID, fid, buffName, creature end
							if hasJournal then
								mountID = C_MountJournal.GetMountFromSpell(spellID)
								if mountID and not IsSecret(mountID) then return mountID, nil, buffName end
							end
						end
					end
				end

				-- Get the creature display a mount uses from the mount journal (mounts with more than one look use the first one)
				local function GetMountDisplayID(mountID)
					if not hasJournal then return end
					local displayID = C_MountJournal.GetMountInfoExtraByID and C_MountJournal.GetMountInfoExtraByID(mountID)
					if (not displayID or displayID == 0) and C_MountJournal.GetMountAllCreatureDisplayInfoByID then
						local all = C_MountJournal.GetMountAllCreatureDisplayInfoByID(mountID)
						if all and all[1] then displayID = all[1].creatureDisplayID end
					end
					if displayID and displayID > 0 then return displayID end
				end

				-- Get the model file a creature display uses (the model may take a few frames to load so it's tried again a few times)
				-- (if isCreature is set, displayID is a creature ID instead, which works if the game has the creature's details)
				local function FindDisplayModel(displayID, callback, tries, isCreature)
					if isCreature then targetModel:SetCreature(displayID) else targetModel:SetDisplayInfo(displayID) end
					local id = targetModel:GetModelFileID()
					targetModel:ClearModel()
					if not IsSecret(id) and type(id) == "number" and id > 0 then
						callback(id)
					elseif (tries or 0) < 10 then
						C_Timer.After(0.05, function() FindDisplayModel(displayID, callback, (tries or 0) + 1, isCreature) end)
					else
						callback(nil)
					end
				end

				-- The mount's own sounds are in Leatrix_Sounds["MOUNT_KITS"] (made by the R script with the mob sound data)
				-- It has one line for each mount, sorted by mount ID
				-- Each line is how much the mount ID goes up from the line before (empty means 1), a |, then the summon, special, mount poof and shared summon sound kits, separated by |
				local mountKitNames = {"Summon", "Special", "Mount poof", "Summon (shared by many mounts)"}

				-- Get a mount's own sound kits as a list of {sound kit, label} (an empty list if there are none)
				local function GetMountOwnKits(mountID)
					local extra = {}
					local data = Leatrix_Sounds["MOUNT_KITS"]
					if type(data) ~= "string" then return extra end
					local pos, len, id = 1, #data, 0
					while pos <= len do
						local s, e, step, rest = strfind(data, "^(%d*)|([^\n]*)", pos)
						if e then
							id = id + (tonumber(step) or 1)
							if id == mountID then
								local fields = {strsplit("|", rest)}
								for i, label in ipairs(mountKitNames) do
									for void, kit in ipairs(ReadNumbers(fields[i])) do
										extra[#extra + 1] = {kit, L[label]}
									end
								end
								return extra
							end
							-- The lines are sorted so stop after the mount ID being looked for
							if id > mountID then break end
							pos = e + 2
						else
							pos = (strfind(data, "\n", pos, true) or len) + 1
						end
					end
					return extra
				end

				-- Get a mount's model file ID and its own sound kits, then call callback(modelID, extra)
				-- (modelID is nil if it can't be found and extra is a list of {sound kit, label}, which can be empty)
				-- The model file is known straight away if the mount is in the data, otherwise it's found from the mount's creature or the mount journal
				-- (which can take a few frames, so callback may be called later)
				local function ResolveMount(mountID, fid, creature, callback)
					local extra = GetMountOwnKits(mountID)
					local function Done(modelID) callback(modelID, extra) end
					if fid then
						Done(fid)
						return
					end
					if creature and targetModel.SetCreature then
						FindDisplayModel(creature, Done, 0, true)
						return
					end
					local displayID = GetMountDisplayID(mountID)
					if displayID then
						FindDisplayModel(displayID, Done)
					else
						Done(nil)
					end
				end
				LeaSoundsLC.ResolveMount = ResolveMount

				-- Open the panel with the mount's sounds (its own sounds first, then the sounds from its model)
				local function OpenMountSounds(mountID, name, fid, creature)
					ResolveMount(mountID, fid, creature, function(modelID, extra)
						if modelID or #extra > 0 then
							OpenMobSounds(modelID, name, extra)
						else
							LeaSoundsLC:Print(L["Mount sounds are not available for this mount."])
							-- (nothing was opened, so the list comes back)
							if LeaSoundsLC.MountReturn then
								LeaSoundsLC.MountReturn = nil
								if LeaSoundsLC.ReopenMountList then LeaSoundsLC.ReopenMountList() end
							end
						end
					end)
				end

				-- Get a function which opens the panel with a mount's sounds from the mount's spell or buff (nil if it isn't a mount spell)
				-- (it's kept in LeaSoundsLC so it doesn't count towards the limit for locals in this function)
				LeaSoundsLC.MountSpellOpener = function(spellID)
					if IsSecret(spellID) or type(spellID) ~= "number" or spellID <= 0 then return end
					local mountID, fid, creature = FindMountSpell(spellID)
					if not mountID and hasJournal then
						mountID = C_MountJournal.GetMountFromSpell(spellID)
						if IsSecret(mountID) or type(mountID) ~= "number" or mountID <= 0 then mountID = nil end
					end
					if not mountID then return end
					-- The mount journal name is used if there is one, otherwise the spell name
					local name = hasJournal and C_MountJournal.GetMountInfoByID and C_MountJournal.GetMountInfoByID(mountID)
					if IsSecret(name) or type(name) ~= "string" or name == "" then
						name = (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)) or (GetSpellInfo and GetSpellInfo(spellID))
					end
					if IsSecret(name) or type(name) ~= "string" or name == "" then name = L["This mount"] end
					name = gsub(name, "|", "||")
					return function() OpenMountSounds(mountID, name, fid, creature) end
				end

				-- Get a function which opens the panel with a mount's sounds from an item which teaches the mount (nil if it doesn't teach one or the game can't say)
				LeaSoundsLC.MountItemOpener = function(itemID)
					if not hasJournal or not C_MountJournal.GetMountFromItem or not C_MountJournal.GetMountInfoByID then return end
					if IsSecret(itemID) or type(itemID) ~= "number" or itemID <= 0 then return end
					local mountID = C_MountJournal.GetMountFromItem(itemID)
					if IsSecret(mountID) or type(mountID) ~= "number" or mountID <= 0 then return end
					local void, spellID = C_MountJournal.GetMountInfoByID(mountID)
					return LeaSoundsLC.MountSpellOpener(spellID)
				end

				-- Check a unit is a mounted player (anything the game won't say is treated as not)
				local function IsUnitPlayer(unit)
					if not unit or not UnitExists(unit) then return false end
					local isPlayer = UnitIsPlayer(unit)
					if IsSecret(isPlayer) then return false end
					return isPlayer
				end

				-- Get the mount a player is riding as {mount ID, name, model file ID, creature ID} (nil if they're not mounted or the game won't say)
				-- The player menus (with the Show target sounds button) are set up with the mob sounds and use this to add the mount's sounds
				LeaSoundsLC.GetUnitMountInfo = function(unit)
					if not IsUnitPlayer(unit) then return end
					local mountID, fid, buffName, creature = GetUnitMount(unit)
					if not mountID then return end
					-- The mount name is read now as the target may change before the button is clicked
					-- (the mount journal name is used if there is one, otherwise the buff name)
					local name = hasJournal and C_MountJournal.GetMountInfoByID and C_MountJournal.GetMountInfoByID(mountID)
					if IsSecret(name) or type(name) ~= "string" or name == "" then name = buffName end
					if IsSecret(name) or type(name) ~= "string" or name == "" then name = L["This mount"] end
					name = gsub(name, "|", "||")
					return {mountID, name, fid, creature}
				end

				----------------------------------------------------------------------
				-- Mounts list (choose Mounts in the panel's menu, then a mount to see its sounds)
				----------------------------------------------------------------------

				-- Get a spell's name and icon
				local function GetSpellNameAndIcon(spellID)
					if C_Spell and C_Spell.GetSpellName then
						return C_Spell.GetSpellName(spellID), C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID)
					end
					local name, void, icon = GetSpellInfo(spellID)
					return name, icon
				end

				-- Give each entry in a list its label (entries with the same name show their spell ID so they can be told apart) and sort it by name
				local function LabelAndSort(list)
					local count = {}
					for void, m in ipairs(list) do count[m.name] = (count[m.name] or 0) + 1 end
					for void, m in ipairs(list) do
						m.label = count[m.name] > 1 and (m.name .. " (" .. m.spellID .. ")") or m.name
						m.search = strlower(m.label)
					end
					table.sort(list, function(a, b)
						if a.label ~= b.label then return a.label < b.label end
						return a.spellID < b.spellID
					end)
				end

				-- The list of pets is made the first time the Pets tab is opened (every companion pet in the data, sorted by name)
				-- Leatrix_Sounds["PET_SPELLS"] (made by the R script with the mob sound data) has one line for each companion pet, sorted by summon spell ID
				-- Each line is the summon spell ID, the items which cast it (separated by commas), the creature display, the display's model file ID (empty if they aren't known) and the creature ID, separated by |
				local petList
				local function BuildPetList()
					if petList then return end
					petList = {}
					local data = Leatrix_Sounds["PET_SPELLS"]
					if type(data) ~= "string" then return end
					-- Only pets which can be got are listed (the game data also has test, unused, removed and promotional pets,
					-- and items such as quest items which summon a creature for a while)
					-- These are the items in Wowhead's Classic companions list (item=creature display), without the unused ones, the trading card game,
					-- BlizzCon, collector's edition and other promotional pets and the Season of Mastery pet, and with the engineering pets
					-- (which Wowhead doesn't list as companions in Classic)
					-- (the display is used if the pet data doesn't have one, as most creature data in Classic is on the server)
					local obtainable = {}
					for id, display in gmatch("4401=7937,5332=4472,8485=5556,8486=5586,8487=5554,8488=5555,8489=9989,8490=5585,8491=5448,8492=5207,8494=6192,8495=6190,8496=6191,8497=328,8498=6291,8499=6290,8500=4615,8501=6299,10360=1206,10361=2957,10392=6303,10393=2177,10394=1072,10398=7920,10822=6288,11023=5369,11026=6295,11027=901,11110=304,11474=6294,11825=8909,11826=8910,12264=9563,12529=9997,12565=9990,15996=901,19450=14938,20769=15436,21277=10269,21301=,21305=,21308=,21309=,22235=15992,23002=16259,23007=16257,23015=2176,23083=16587", "(%d+)=(%d*)") do
						obtainable[tonumber(id)] = tonumber(display) or true
					end
					-- Season of Discovery pets (marked as Season of Discovery on Wowhead, and the Black Murloc Egg trinket from Gelihast) are only listed on Season of Discovery realms
					-- (Classic Era, Hardcore and Season of Discovery share the game data and the addon, so the realm is checked when the list is made)
					if C_Seasons and C_Seasons.GetActiveSeason and C_Seasons.GetActiveSeason() == (Enum and Enum.SeasonID and Enum.SeasonID.SeasonOfDiscovery or 2) then
						for id, display in gmatch("205961=1933,207590=9953,208192=2378,208608=2378,209681=114202,211527=116110,220620=119154,228130=2030,228131=2030", "(%d+)=(%d*)") do
							obtainable[tonumber(id)] = tonumber(display) or true
						end
					end
					for line in gmatch(data, "[^\n]+") do
						local spellID, items, displayID, fid, creature = strmatch(line, "^(%d+)|([%d,]*)|(%d*)|(%d*)|(%d*)")
						spellID = tonumber(spellID)
						-- The pet is listed if any of the items which cast it can be got (that item's icon is used)
						local itemID
						for id in gmatch(items or "", "%d+") do
							if obtainable[tonumber(id)] then itemID = tonumber(id); break end
						end
						if spellID and itemID then
							-- The name is the summon spell's name, which is the pet's name in the game's language
							local name, icon = GetSpellNameAndIcon(spellID)
							-- The item's icon is used if there is one as most companion spells have the same icon
							local itemIcon
							if itemID then
								if C_Item and C_Item.GetItemIconByID then itemIcon = C_Item.GetItemIconByID(itemID)
								elseif GetItemIcon then itemIcon = GetItemIcon(itemID) end
							end
							if type(name) == "string" and name ~= "" then
								-- (the display from Wowhead's list is used if the pet data doesn't have one)
								local wowheadDisplay = obtainable[itemID] ~= true and obtainable[itemID] or nil
								petList[#petList + 1] = {pet = true, spellID = spellID, displayID = tonumber(displayID) or wowheadDisplay, fid = tonumber(fid), creature = tonumber(creature), name = gsub(name, "|", "||"), icon = itemIcon or icon}
							end
						end
					end
					LabelAndSort(petList)
				end

				-- The list of mounts is made the first time it's opened (every mount spell in the data, sorted by name)
				local mountList
				local function BuildMountList()
					if mountList then return end
					FindMountSpell(0)
					mountList = {}
					-- Test and unused mount spells are left out (Leatrix_Sounds["MOUNT_HIDDEN"] is made by the R script)
					local hidden = {}
					if type(Leatrix_Sounds["MOUNT_HIDDEN"]) == "string" then
						for id in gmatch(Leatrix_Sounds["MOUNT_HIDDEN"], "%d+") do hidden[tonumber(id)] = true end
					end
					-- Mounts which were never obtainable or were removed, such as test, unused and promotional mounts (no source on Wowhead), are left out too
					for id in gmatch("459,468,471,578,579,581,3363,6896,6897,8980,10787,10788,10790,10792,10795,10798,15779,16055,16056,16058,16059,16060,16081,16082,16084,17455,17456,17459,17460,18363,18991,18992,23220,24576,29059,30174", "%d+") do
						hidden[tonumber(id)] = true
					end
					-- Season of Discovery mounts (marked as Season of Discovery on Wowhead) are only listed on Season of Discovery realms, under their own heading at the end
					-- (Classic Era, Hardcore and Season of Discovery share the game data and the addon, so the realm is checked when the list is made)
					local sodMounts = {}
					for id in gmatch("429856,429857,436288,436327,461607,473900,1214283,1215378,1215380,1220565,1220566,1220567,1220568,1229305,1229308", "%d+") do
						sodMounts[tonumber(id)] = true
					end
					local isSoD = C_Seasons and C_Seasons.GetActiveSeason and C_Seasons.GetActiveSeason() == (Enum and Enum.SeasonID and Enum.SeasonID.SeasonOfDiscovery or 2)
					if not isSoD then
						for id in pairs(sodMounts) do hidden[id] = true end
					end
					-- (on Season of Discovery realms the other mounts go under a Classic heading)
					mountList.isSoD = isSoD
					local count = {}
					for spellID in pairs(mountSpells) do
						local name, icon
						if not hidden[spellID] then name, icon = GetSpellNameAndIcon(spellID) end
						if type(name) == "string" and name ~= "" then
							mountList[#mountList + 1] = {spellID = spellID, name = gsub(name, "|", "||"), icon = icon, sod = sodMounts[spellID]}
							count[name] = (count[name] or 0) + 1
						end
					end
					-- Mounts with the same name show their spell ID so they can be told apart
					for void, m in ipairs(mountList) do
						m.label = count[gsub(m.name, "||", "|")] > 1 and (m.name .. " (" .. m.spellID .. ")") or m.name
						m.search = strlower(m.label)
					end
					table.sort(mountList, function(a, b)
						if (a.sod or false) ~= (b.sod or false) then return not a.sod end
						if a.label ~= b.label then return a.label < b.label end
						return a.spellID < b.spellID
					end)
				end

				-- Open the panel with a pet's sounds (the sounds from its model, with its exact sound set and voice if its display is in the data)
				-- The model file is in the pet data if it's known, otherwise it's found from the pet's display (or its creature if there's no display), which can take a few frames
				local function OpenPetSounds(p)
					local function Done(modelID)
						if modelID then
							OpenMobSounds(modelID, p.name, nil, p.displayID)
						else
							LeaSoundsLC:Print(L["Pet sounds are not available for this pet."])
							-- (nothing was opened, so the list comes back)
							if LeaSoundsLC.MountReturn then
								LeaSoundsLC.MountReturn = nil
								if LeaSoundsLC.ReopenMountList then LeaSoundsLC.ReopenMountList() end
							end
						end
					end
					if p.fid then
						Done(p.fid)
					elseif p.displayID then
						FindDisplayModel(p.displayID, Done)
					elseif p.creature and targetModel.SetCreature then
						FindDisplayModel(p.creature, Done, 0, true)
					else
						Done(nil)
					end
				end

				-- Creature display for each mount spell (spell ID=display ID), used by the model preview
				-- A display has the mount's textures (the model file on its own shows the mount in white)
				-- Made from the game's CreatureDisplayInfo with Wowhead for the mount creatures, checked against the model files in Leatrix_Sounds["MOUNT_SPELLS"]
				local mountDisplayData = [[
458=2404 459=2320 468=2410 470=2402 471=2408 472=2409 578=207 579=2326 580=247 581=1166
3363=15293 5784=2346 6648=2405 6653=2327 6654=2328 6777=2736 6896=2784 6897=2787 6898=2786 6899=2785
8394=6080 8395=4806 8980=5228 10787=9991 10788=4805 10789=6444 10790=6443 10792=6447 10793=6448 10795=6471
10796=6472 10798=6468 10799=6473 10873=9473 10969=6569 13819=8469 15779=9474 16055=9991 16056=9695 16058=4805
16059=6442 16060=9714 16081=1166 16082=2408 16084=6469 17229=10426 17453=10661 17454=9476 17455=10662 17456=10664
17458=9475 17459=10666 17460=2787 17462=10670 17463=10671 17464=10672 17465=10720 17481=10718 18363=11641 18989=12246
18990=11641 18991=12245 18992=12242 22717=14337 22718=14348 22719=14372 22720=14577 22721=14388 22722=10719 22723=14330
22724=14334 23161=14554 23214=14584 23219=14332 23220=14329 23221=14331 23222=14377 23223=14376 23225=14374 23227=14582
23228=14338 23229=14583 23238=14347 23239=14576 23240=14346 23241=14339 23242=14344 23243=14342 23246=10721 23247=14349
23248=14579 23249=14578 23250=14573 23251=14575 23252=14574 23338=14632 23509=14776 23510=14777 24242=15289 24252=15290
24576=15293 25953=15678 26054=15681 26055=15680 26056=15679 29059=10718 30174=17158 429856=9991 429857=2326 436288=6469
436327=6443 461607=14584 473900=124519 1214283=124765 1215378=125139 1215380=125138 1220565=126452 1220566=126453 1220567=126454 1220568=126455
1229305=128204 1229308=128209
]]
				local mountDisplays
				local function GetMountSpellDisplay(spellID)
					if not mountDisplays then
						mountDisplays = {}
						for spell, display in gmatch(mountDisplayData, "(%d+)=(%d+)") do
							mountDisplays[tonumber(spell)] = tonumber(display)
						end
					end
					return mountDisplays[spellID]
				end

				-- The mounts list frame (a search box above a scrolling list, shown above the Menu button like the menu)
				-- A model preview is shown to the right of the list (hover over a mount to see it)
				local mountFrame
				local function CreateMountFrame(owner)
					local listW, previewW = 280, 420
					-- The list is part of the panel, shown in place of the sound listing (the same as the settings)
					local f = CreateFrame("Frame", nil, PageF)
					f:SetPoint("TOPLEFT", PageF, "TOPLEFT", 4, -4)
					f:SetPoint("BOTTOMRIGHT", PageF, "BOTTOMRIGHT", -4, 46)
					-- (the frame itself doesn't take the mouse so the panel can still be dragged by its title area, the list, search box and preview take the mouse themselves)
					f:EnableMouse(false)
					f:Hide()

					-- Which list is showing (mounts or pets) and the text for each one
					f.mode = "mounts"
					local modeText = {
						mounts = {hint = L["Drag to rotate, scroll to zoom.  Click a mount for its sounds."], hover = L["Hover over a mount to see it"], noModel = L["No model available for this mount"], empty = L["No mounts found"]},
						pets = {hint = L["Drag to rotate, scroll to zoom.  Click a pet for its sounds."], hover = L["Hover over a pet to see it"], noModel = L["No model available for this pet"], empty = L["No pets found"]},
					}
					-- The search text for each tab is kept while switching between them
					f.searchText = {mounts = "", pets = ""}

					-- Title (Mounts and Pets tabs if there is pet data, otherwise just Mounts)
					if LeaSoundsLC.HasPets then
						f.tabs = {}
						local function MakeTab(label, mode)
							local tab = CreateFrame("Button", nil, f)
							tab:SetHeight(20)
							tab:SetNormalFontObject("GameFontNormal")
							tab:SetText(label)
							tab:SetPushedTextOffset(0, 0)
							tab:SetWidth(ceil(tab:GetFontString():GetStringWidth()) + 16)
							-- Highlight when hovering (the same as the menu items)
							tab.hl = tab:CreateTexture(nil, "BACKGROUND")
							tab.hl:SetAllPoints()
							tab.hl:SetColorTexture(0.3, 0.3, 0.0, 0.8)
							tab.hl:SetAlpha(0.7)
							tab.hl:Hide()
							-- Gold line under the chosen tab
							tab.line = tab:CreateTexture(nil, "ARTWORK")
							tab.line:SetColorTexture(1, 0.82, 0, 1)
							tab.line:SetHeight(2)
							tab.line:SetPoint("BOTTOMLEFT", 4, 0)
							tab.line:SetPoint("BOTTOMRIGHT", -4, 0)
							tab:SetScript("OnEnter", function() tab.hl:Show() end)
							tab:SetScript("OnLeave", function() tab.hl:Hide() end)
							tab:SetScript("OnClick", function() f.SetMode(mode) end)
							f.tabs[mode] = tab
							return tab
						end
						local mountsTab = MakeTab(L["Mounts"], "mounts")
						mountsTab:SetPoint("TOPLEFT", 4, -4)
						local petsTab = MakeTab(L["Pets"], "pets")
						petsTab:SetPoint("LEFT", mountsTab, "RIGHT", 2, 0)
					else
						f.title = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
						f.title:SetPoint("TOPLEFT", 12, -10)
						f.title:SetText(L["Mounts"])
					end

					-- Number of mounts listed (the ones which match the search)
					f.count = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
					f.count:SetPoint("TOPRIGHT", f, "TOPLEFT", listW - 12, -10)
					-- Shows the previewed mount's position in the list and the number of mounts listed, such as 12/193 (just the number listed if nothing is previewed or it isn't listed)
					function f.UpdateCount()
						local shown = f.shown or {}
						local pos
						if f.previewed then
							for i, m in ipairs(shown) do
								if m == f.previewed then pos = i; break end
							end
						end
						f.count:SetText(pos and (pos .. "/" .. #shown) or #shown)
					end

					-- Search box
					local search = CreateFrame("EditBox", nil, f, "SearchBoxTemplate")
					search:SetHeight(20)
					search:SetPoint("TOPLEFT", 18, -28)
					search:SetPoint("TOPRIGHT", f, "TOPLEFT", listW - 10, -28)
					search:SetAutoFocus(false)
					f.search = search

					-- Model preview (to the right of the list, drag to rotate and scroll to zoom)
					local preview = CreateFrame("Frame", nil, f)
					-- (it starts level with the search box so it stays clear of the panel's close button in the top-right corner)
					preview:SetPoint("TOPLEFT", f, "TOPLEFT", listW + 4, -28)
					preview:SetPoint("BOTTOMRIGHT", -10, 10)
					preview.bg = preview:CreateTexture(nil, "BACKGROUND")
					preview.bg:SetAllPoints()
					preview.bg:SetColorTexture(0.12, 0.12, 0.12, 1)
					preview.line = f:CreateTexture(nil, "ARTWORK")
					preview.line:SetColorTexture(0.4, 0.4, 0.4, 0.8)
					preview.line:SetWidth(1)
					preview.line:SetPoint("TOPRIGHT", preview, "TOPLEFT", -2, 0)
					preview.line:SetPoint("BOTTOMRIGHT", preview, "BOTTOMLEFT", -2, 0)

					-- Mount name and help text at the bottom of the preview
					preview.hint = preview:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
					preview.hint:SetPoint("BOTTOMLEFT", 6, 6)
					preview.hint:SetPoint("BOTTOMRIGHT", -6, 6)
					preview.hint:SetSpacing(2)
					preview.name = preview:CreateFontString(nil, "ARTWORK", "GameFontNormal")
					preview.name:SetPoint("BOTTOMLEFT", preview.hint, "TOPLEFT", 0, 6)
					preview.name:SetPoint("BOTTOMRIGHT", preview.hint, "TOPRIGHT", 0, 6)
					preview.name:SetWordWrap(false)
					preview.hint:SetText(modeText.mounts.hint)

					-- Shown when nothing is being previewed or the mount or pet has no model
					preview.empty = preview:CreateFontString(nil, "ARTWORK", "GameFontDisable")
					preview.empty:SetPoint("CENTER", 0, 20)
					preview.empty:SetWidth(previewW - 40)
					preview.empty:SetText(modeText.mounts.hover)

					local model = CreateFrame("PlayerModel", nil, preview)
					model:SetPoint("TOPLEFT", 2, -2)
					model:SetPoint("TOPRIGHT", -2, -2)
					model:SetPoint("BOTTOM", preview.name, "TOP", 0, 6)
					model:EnableMouse(true)
					model:EnableMouseWheel(true)
					-- (the camera starts further out than the game's default so the whole mount fits in the preview)
					local defaultZoom = 1.8
					local facing, zoom, dragX = 0, defaultZoom, nil
					local function ApplyCamera()
						if model.SetPortraitZoom then model:SetPortraitZoom(0) end
						if model.SetCamDistanceScale then model:SetCamDistanceScale(zoom) end
						-- (mounts are moved a little to the left as the head sticks out to the right when the mount is turned)
						-- (pets aren't moved as they're much smaller, so the same distance would push them off to the side)
						if model.SetPosition then model:SetPosition(0, (f.previewed and f.previewed.pet) and 0 or -0.3, 0) end
						model:SetFacing(facing)
					end
					-- Dragging rotates the model
					model:SetScript("OnMouseDown", function(self, button)
						if button == "LeftButton" then dragX = GetCursorPosition() end
					end)
					model:SetScript("OnMouseUp", function() dragX = nil end)
					model:SetScript("OnHide", function() dragX = nil end)
					model:SetScript("OnUpdate", function(self, elapsed)
						if dragX then
							local x = GetCursorPosition()
							facing = facing + (x - dragX) * 0.015
							dragX = x
							self:SetFacing(facing)
						end
					end)
					-- Scrolling zooms in and out
					model:SetScript("OnMouseWheel", function(self, delta)
						zoom = min(5, max(0.6, zoom - delta * 0.15))
						if self.SetCamDistanceScale then self:SetCamDistanceScale(zoom) end
					end)

					-- Show a mount in the preview (a display is used if one is known as it has the right textures, then the creature, then the model file)
					local function ShowPreview(m)
						if f.previewed == m then return end
						f.previewed = m
						f.UpdateCount()
						model:ClearModel()
						-- Mounts face the same way as in the mount journal (turned 30 degrees from the front, facing towards the bottom-right)
						facing, zoom = math.rad(30), defaultZoom
						preview.name:SetText(m and m.label or "")
						-- The model frame is hidden when nothing is previewed (a model frame shows its last model again when it's shown, even if it was cleared while hidden)
						if not m then
							model:Hide()
							preview.empty:SetText(modeText[f.mode].hover)
							preview.empty:Show()
							return
						end
						model:Show()
						-- Pets have their display (and creature) in the pet data, mounts are found from the mount data
						local displayID, creature, fid
						if m.pet then
							displayID, creature, fid = m.displayID, m.creature, m.fid
						else
							local mountID
							mountID, fid, creature = FindMountSpell(m.spellID)
							displayID = GetMountSpellDisplay(m.spellID) or (mountID and GetMountDisplayID(mountID))
						end
						if displayID then
							model:SetDisplayInfo(displayID)
						elseif creature and model.SetCreature then
							model:SetCreature(creature)
						elseif fid then
							model:SetModel(fid)
						else
							model:Hide()
							preview.empty:SetText(modeText[m.pet and "pets" or "mounts"].noModel)
							preview.empty:Show()
							return
						end
						preview.empty:Hide()
						ApplyCamera()
						-- Models can take a few frames to load so the camera is set again a few times
						-- (a display is never swapped for the model file as the model file has no textures and shows in white)
						-- (only a creature which the game has no details for falls back to the model file)
						local function Check(tries)
							if f.previewed ~= m then return end
							ApplyCamera()
							if tries < 5 then
								C_Timer.After(0.1, function() Check(tries + 1) end)
							elseif not displayID and creature and fid then
								local id = model:GetModelFileID()
								if IsSecret(id) or type(id) ~= "number" or id <= 0 then model:SetModel(fid); ApplyCamera() end
							end
						end
						C_Timer.After(0.1, function() Check(0) end)
					end
					f.ShowPreview = ShowPreview

					-- Scrolling list (one row for each mount, clicking one shows its sounds)
					local scrollBox = CreateFrame("Frame", nil, f, "WowScrollBoxList")
					scrollBox:SetPoint("TOPLEFT", 8, -54)
					scrollBox:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", listW - 24, 8)
					local scrollBar = CreateFrame("EventFrame", nil, f, "MinimalScrollBar")
					scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 6, 0)
					scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 6, 0)
					local view = CreateScrollBoxListLinearView()
					view:SetElementExtent(20)
					view:SetElementInitializer("Button", function(button, m)
						if not button.text then
							button.hl = button:CreateTexture(nil, "BACKGROUND")
							button.hl:SetAllPoints()
							button.hl:SetColorTexture(0.3, 0.3, 0.0, 0.8)
							button.hl:SetAlpha(0.7)
							button.hl:Hide()
							-- The mount being previewed stays highlighted
							button.sel = button:CreateTexture(nil, "BACKGROUND")
							button.sel:SetAllPoints()
							button.sel:SetColorTexture(0.2, 0.4, 0.8, 0.35)
							button.sel:Hide()
							button.icon = button:CreateTexture(nil, "ARTWORK")
							button.icon:SetSize(16, 16)
							button.icon:SetPoint("LEFT", 4, 0)
							button.text = button:CreateFontString(nil, "ARTWORK", "GameFontHighlightLeft")
							button.text:SetPoint("LEFT", 26, 0)
							button.text:SetPoint("RIGHT", -4, 0)
							button.text:SetWordWrap(false)
							button:SetScript("OnEnter", function(self)
								if self.mount.header then return end
								self.hl:Show()
								ShowPreview(self.mount)
								if scrollBox.ForEachFrame then
									scrollBox:ForEachFrame(function(b) if b.sel then b.sel:SetShown(b.mount == f.previewed) end end)
								end
							end)
							button:SetScript("OnLeave", function(self) self.hl:Hide() end)
							button:SetScript("OnClick", function(self)
								local d = self.mount
								if d.header then return end
								f:Hide()
								-- (so Back in the mount or pet sounds comes back to the list, on the same tab)
								LeaSoundsLC.MountReturn = true
								if d.pet then
									OpenPetSounds(d)
								else
									local mountID, fid, creature = FindMountSpell(d.spellID)
									OpenMountSounds(mountID, d.name, fid, creature)
								end
							end)
						end
						button.mount = m
						button.sel:SetShown(m == f.previewed)
						-- Headings are in gold with no icon
						if m.header then
							button.icon:Hide()
							button.text:SetPoint("LEFT", 4, 0)
							button.text:SetFontObject("GameFontNormal")
							button.text:SetText(m.label)
							return
						end
						button.icon:Show()
						button.text:SetPoint("LEFT", 26, 0)
						button.text:SetFontObject("GameFontHighlightLeft")
						-- (a question mark is shown if the mount has no icon)
						button.icon:SetTexture(m.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
						button.text:SetText(m.label)
					end)
					ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

					-- Shown when no mount or pet matches the search
					f.empty = f:CreateFontString(nil, "ARTWORK", "GameFontDisable")
					f.empty:SetPoint("TOP", scrollBox, "TOP", 0, -10)
					f.empty:SetText(modeText.mounts.empty)
					f.empty:Hide()

					-- Show the mounts or pets which match the search (the text can be anywhere in the name)
					function f.Refresh()
						local text = strlower(strtrim(search:GetText() or ""))
						local shown, rows = {}, {}
						f.empty:SetText(modeText[f.mode].empty)
						-- (the Season of Discovery headings are only for mounts)
						local isPets = f.mode == "pets"
						for void, m in ipairs((isPets and petList) or mountList) do
							if text == "" or strfind(m.search, text, 1, true) then
								-- On Season of Discovery realms, the Classic heading goes before the first other mount and the Season of Discovery heading goes before the first Season of Discovery mount (headings aren't counted)
								if not isPets and mountList.isSoD and not m.sod and not shown.classic then
									shown.classic = true
									rows[#rows + 1] = {header = true, label = L["Classic"]}
								end
								if m.sod and not shown.sod then
									shown.sod = true
									rows[#rows + 1] = {header = true, label = L["Season of Discovery"]}
								end
								shown[#shown + 1] = m
								rows[#rows + 1] = m
							end
						end
						scrollBox:SetDataProvider(CreateDataProvider(rows))
						f.empty:SetShown(#shown == 0)
						f.shown = shown
						f.UpdateCount()
					end
					search:HookScript("OnTextChanged", f.Refresh)
					-- Escape in the search box closes the list
					search:HookScript("OnEscapePressed", function() f:Hide() end)

					-- Show the Mounts or Pets tab (each tab keeps its own search text, the list goes back to the top and nothing is previewed)
					function f.SetMode(mode)
						if mode == "pets" and not LeaSoundsLC.HasPets then mode = "mounts" end
						if mode == "pets" then BuildPetList() end
						if f.mode ~= mode then
							f.searchText[f.mode] = search:GetText() or ""
							f.mode = mode
							-- (setting the text runs Refresh for the new list)
							search:SetText(f.searchText[mode] or "")
						end
						if f.tabs then
							for tabMode, tab in pairs(f.tabs) do
								local chosen = tabMode == mode
								tab.line:SetShown(chosen)
								-- The chosen tab is gold and the other is grey
								tab:GetFontString():SetTextColor(chosen and 1 or 0.6, chosen and 0.82 or 0.6, chosen and 0 or 0.6)
							end
						end
						preview.hint:SetText(modeText[mode].hint)
						ShowPreview(nil)
						-- (ShowPreview does nothing if nothing was previewed already, so the text for the tab is set here too)
						preview.empty:SetText(modeText[mode].hover)
						f.Refresh()
						scrollBox:ScrollToBegin()
					end

					-- The sound listing and the bottom bar are hidden while the list is shown and come back when it's closed
					-- (the list is closed with the Menu button, the Mounts item in the menu, Escape in the search box or by choosing a mount)
					-- (MountsShown keeps the listing hidden when it's updated, such as when the panel is resized or a sound finishes)
					f:SetScript("OnShow", function()
						LeaSoundsLC.MountsShown = true
						scrollFrame:Hide()
						UpdateList()
						ShowBottomBar(false)
						-- Back replaces the Menu button (the same as the settings)
						catBtn:Hide()
						backBtn:Show()
					end)
					f:SetScript("OnHide", function()
						LeaSoundsLC.MountsShown = false
						search:ClearFocus()
						if not LeaSoundsLC.SettingsShown then
							backBtn:Hide()
							catBtn:Show()
						end
						scrollFrame:Show()
						ShowBottomBar(not LeaSoundsLC.SettingsShown)
						UpdateList()
					end)
					PageF:HookScript("OnHide", function() f:Hide() end)
					-- Back closes the list
					backBtn:HookScript("OnClick", function() f:Hide() end)
					return f
				end

				-- Show the mounts list again as it was left (the same search, scroll position and previewed mount)
				LeaSoundsLC.ReopenMountList = function()
					if mountFrame and PageF:IsShown() then mountFrame:Show() end
				end

				-- Close the mounts list if it's open (returns true if it was open)
				LeaSoundsLC.HideMountList = function()
					if mountFrame and mountFrame:IsShown() then
						mountFrame:Hide()
						return true
					end
				end

				-- Show the mounts list (or close it if it's open)
				LeaSoundsLC.ShowMountList = function(owner)
					BuildMountList()
					if not mountFrame then mountFrame = CreateMountFrame(owner) end
					if mountFrame:IsShown() then
						mountFrame:Hide()
						return
					end
					-- The list opens on the tab it was last left on, with both search boxes cleared
					mountFrame.searchText.mounts, mountFrame.searchText.pets = "", ""
					mountFrame.search:SetText("")
					mountFrame.SetMode(mountFrame.mode)
					mountFrame:Show()
					-- (the search box isn't given the keyboard focus when the list opens, so key bindings still work until it's clicked)
				end

			end

			end
			SetupMountSounds()

			----------------------------------------------------------------------
			-- Sounds for other addons (such as the Leatrix Plus info cards)
			----------------------------------------------------------------------

			-- Get a function which opens the panel with the sounds for something (nil if there are no sounds for it)
			-- what is a table with any of: unit (a player, mob or pet), npcID and displayID (a creature with no unit, such as a boss on a dungeon map),
			-- name (used with npcID), spellID (a mount spell or buff) and itemID (an item which teaches a mount or pet)
			-- Everything is read straight away (the unit may change before the function is called), so call this when the thing is shown, not when it's clicked
			-- Nothing is changed until the returned function is called, so it can be called at any time, including in combat
			-- It never errors into the addon asking (the game can hide values from addons, and anything missed by the checks means no sounds rather than an error)
			_G.LeaSoundsGlobalGetSounds = function(what)
				if type(what) ~= "table" then return end
				local ok, open = pcall(function()
					local open = what.unit and LeaSoundsLC.UnitOpener(what.unit)
					if not open and what.npcID then open = LeaSoundsLC.CreatureOpener(tonumber(what.npcID), tonumber(what.displayID), what.name) end
					if not open and what.spellID and LeaSoundsLC.MountSpellOpener then open = LeaSoundsLC.MountSpellOpener(what.spellID) end
					if not open and what.itemID and LeaSoundsLC.MountItemOpener then open = LeaSoundsLC.MountItemOpener(what.itemID) end
					if not open and what.itemID and LeaSoundsLC.PetItemOpener then open = LeaSoundsLC.PetItemOpener(what.itemID) end
					return open
				end)
				if ok and type(open) == "function" then return open end
			end

		end
		end

		-- Menu items (label for one track, label for more than one track, function)
		-- The mute item labels are set when the menu is shown (Mute or Unmute)
		local menuItems = {
			{"Play sound", "Play sounds", function(tracks, clicked) PlayTracks(tracks, clicked) end},
			{"Mute sound", "Mute sounds", function(tracks) SetTracksMuted(tracks, not trackMenu.allMuted) end},
			{"Show sound kits", "Show shared sound kits", function(tracks) ShowKits(tracks) end},
			{"Print link in chat", "Print links in chat", function(tracks) for void, track in ipairs(tracks) do DEFAULT_CHAT_FRAME:AddMessage(track) end end},
		}

		local menuButtons = {}
		for i, item in ipairs(menuItems) do
			local mb = CreateFrame("Button", nil, trackMenu)
			menuButtons[i] = mb
			mb:SetSize(menuWidth - 16, menuRowHeight)
			mb:SetPoint("TOPLEFT", 8, -26 - (i - 1) * menuRowHeight)
			mb:SetNormalFontObject("GameFontHighlightLeft")
			-- Items which can't be used are in grey (such as Show sound kits for a sound which isn't in any)
			mb:SetDisabledFontObject("GameFontDisableLeft")
			mb:SetText(L[item[1]])
			mb:GetFontString():ClearAllPoints()
			mb:GetFontString():SetPoint("LEFT", 4, 0)
			mb:SetPushedTextOffset(0, 0)
			mb.t = mb:CreateTexture(nil, "BACKGROUND")
			mb.t:SetAllPoints()
			mb.t:SetColorTexture(0.3, 0.3, 0.0, 0.8)
			mb.t:SetAlpha(0.7)
			mb.t:Hide()
			mb:SetScript("OnEnter", function() if mb:IsEnabled() then mb.t:Show() end end)
			mb:SetScript("OnLeave", function() mb.t:Hide() end)
			mb:SetScript("OnClick", function()
				local tracks, clicked = trackMenu.tracks, trackMenu.clicked
				trackMenu:Hide()
				if tracks and #tracks > 0 then item[3](tracks, clicked) end
			end)
		end
		trackMenu:SetSize(menuWidth, 26 + #menuItems * menuRowHeight + 8)

		-- Show the menu for the selected tracks at the cursor
		local function ShowTrackMenu(track)
			catMenu:Hide()
			-- Right-clicking a track which isn't selected selects only that track
			if not selected[track] then
				SelectOnly(track)
				UpdateList()
			end
			local tracks = GetSelectedTracks()
			trackMenu.tracks = tracks
			-- Remember the right-clicked track (Play sounds starts with it)
			trackMenu.clicked = track
			local multi = #tracks > 1
			-- Title shows the file name or the number of selected sounds
			if multi then
				trackMenu.title:SetText(format(L["%d sounds selected"], #tracks))
			else
				trackMenu.title:SetText(track:match("([^/]+)#") or track)
			end
			-- Mute item says Unmute if every selected track is muted
			local allMuted = true
			for void, t in ipairs(tracks) do
				if not IsTrackMuted(t) then allMuted = false; break end
			end
			trackMenu.allMuted = allMuted
			for i = 1, #menuItems do
				menuButtons[i]:SetText(L[multi and menuItems[i][2] or menuItems[i][1]])
			end
			if allMuted then
				menuButtons[2]:SetText(L[multi and "Unmute sounds" or "Unmute sound"])
			end
			-- Show sound kits says so (in grey) if the sounds aren't in any sound kits, so there's no need to open the sound kit listing to find out
			local kits = GetSharedKits(tracks)
			local kitButton = menuButtons[3]
			kitButton.t:Hide()
			if not kits then
				kitButton:SetText(L["No sound kit data"])
				kitButton:Disable()
			elseif #kits == 0 then
				kitButton:SetText(L[multi and "No shared sound kits" or "Not in any sound kits"])
				kitButton:Disable()
			else
				kitButton:Enable()
			end
			local x, y = GetCursorPosition()
			local scale = trackMenu:GetEffectiveScale()
			trackMenu:ClearAllPoints()
			trackMenu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale - 4, y / scale + 4)
			trackMenu:Show()
		end

		-- Close menu when clicking anywhere else, scrolling, opening categories or closing the panel
		trackMenu:SetScript("OnShow", function(self) pcall(self.RegisterEvent, self, "GLOBAL_MOUSE_DOWN") end)
		trackMenu:SetScript("OnHide", function(self) self:UnregisterAllEvents(); self.tracks = nil; self.clicked = nil end)
		trackMenu:SetScript("OnEvent", function(self)
			if not self:IsMouseOver() then self:Hide() end
		end)
		scrollFrame:HookScript("OnVerticalScroll", function() trackMenu:Hide() end)
		catBtn:HookScript("OnClick", function() trackMenu:Hide() end)
		PageF:HookScript("OnHide", function() trackMenu:Hide() end)

		-- Last clicked track and when it was clicked (used for double-clicking when click to play is off)
		local lastClickItem, lastClickTime = nil, 0

		-- Create list items (more are created when the panel is made taller)
		scrollFrame.buttons = {}
		local function CreateListButton(i)
			scrollFrame.buttons[i] = CreateFrame("Button", nil, LeaSoundsLC["PageF"])
			local button = scrollFrame.buttons[i]

			button:SetSize(470 - 14, 16)
			button:SetNormalFontObject("GameFontHighlightLeft")
			button:SetPoint("TOPLEFT", 16, -44 - (i - 1) * 16)

			-- Create highlight bar texture
			button.t = button:CreateTexture(nil, "BACKGROUND")
			button.t:SetPoint("TOPLEFT", button, 0, 0)
			button.t:SetSize(516, 16)

			button.t:SetColorTexture(0.3, 0.3, 0.0, 0.8)
			button.t:SetAlpha(0.7)
			button.t:Hide()

			-- Create last playing highlight bar texture
			button.s = button:CreateTexture(nil, "BACKGROUND")
			button.s:SetPoint("TOPLEFT", button, 0, 0)
			button.s:SetSize(516, 16)

			button.s:SetColorTexture(0.3, 0.4, 0.00, 0.6)
			button.s:Hide()

			button:SetScript("OnEnter", function()
				-- Highlight links only
				if not string.match(button:GetText() or "", "|c") then
					button.t:Show()
				end
			end)

			button:SetScript("OnLeave", function()
				button.t:Hide()
			end)

			button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

			-- Click handler for track
			button:SetScript("OnClick", function(self, btn)
				-- Get clicked track text
				local item = self:GetText()
				-- Do nothing if its a blank line or informational heading
				if not item or strfind(item, "|c") or not strfind(item, "#") then return end
				-- Remove focus from search box
				sBox:ClearFocus()
				if btn == "LeftButton" then
					-- Hold SHIFT to select a range (hold CONTROL as well to add the range to the selection)
					if IsShiftKeyDown() then
						SelectRange(item, IsControlKeyDown())
						UpdateList()
						return
					end
					-- Hold CONTROL to add or remove a track from the selection
					if IsControlKeyDown() then
						ToggleSelected(item)
						UpdateList()
						return
					end
					-- Select only this track
					SelectOnly(item)
					if LeaSoundsLC["ClickToPlay"] == "On" then
						-- Play it straight away
						lastClickItem = nil
						PlayTrack(item, false, self.listIndex)
					else
						-- Play it if it was double-clicked, otherwise just select it
						local now = GetTime()
						if lastClickItem == item and now - lastClickTime < 0.4 then
							lastClickItem = nil
							PlayTrack(item, false, self.listIndex)
						else
							lastClickItem, lastClickTime = item, now
							UpdateList()
						end
					end
				elseif btn == "RightButton" then
					-- Show the menu for the selected tracks
					ShowTrackMenu(item)
				end
			end)
		end

		----------------------------------------------------------------------
		-- Resizing
		----------------------------------------------------------------------

		-- Fit everything to the panel size
		local function LayoutPanel()
			frameWidth, frameHeight = floor(PageF:GetWidth() + 0.5), floor(PageF:GetHeight() + 0.5)
			-- Keep part of the panel on the screen (same as the default size)
			-- (not while the panel is being resized, so the panel isn't moved around under the mouse)
			if not PageF.isSizing then
				PageF:SetClampRectInsets(frameWidth - 250, -(frameWidth - 250), -(frameHeight - 108), frameHeight - 108)
			end
			-- Number of rows which fit in the listing (13 at a panel height of 308)
			numButtons = max(1, 13 + floor((frameHeight - 308) / 16))
			for i = #scrollFrame.buttons + 1, numButtons do CreateListButton(i) end
			LayoutBottomBar()
			LayoutSettings()
			-- Refresh the listing and keep the scroll position within range
			if ListData and ListData[1] then
				UpdateList()
				scrollFrame:SetVerticalScroll(min(scrollFrame:GetVerticalScroll(), scrollFrame:GetVerticalScrollRange()))
			end
		end

		-- Panel can be resized (not scaled) by dragging the grip in the bottom-right corner
		PageF:SetResizable(true)
		local maxWidth = max(minWidth, floor(UIParent:GetWidth() / PageF:GetScale()))
		local maxHeight = max(minHeight, floor(UIParent:GetHeight() / PageF:GetScale()))
		if PageF.SetResizeBounds then
			PageF:SetResizeBounds(minWidth, minHeight, maxWidth, maxHeight)
		else
			PageF:SetMinResize(minWidth, minHeight)
			PageF:SetMaxResize(maxWidth, maxHeight)
		end

		local grip = CreateFrame("Button", nil, PageF)
		LeaSoundsCB["ResizeGrip"] = grip
		grip:SetSize(14, 14)
		grip:SetPoint("BOTTOMRIGHT", -1, 1)
		grip:SetFrameLevel(PageF:GetFrameLevel() + 10)
		grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
		grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
		grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
		grip:SetScript("OnMouseDown", function(self, btn)
			if btn ~= "LeftButton" then return end
			if LeaSoundsLC["CategoryMenu"] then LeaSoundsLC["CategoryMenu"]:Hide() end
			if LeaSoundsLC["TrackMenu"] then LeaSoundsLC["TrackMenu"]:Hide() end
			-- Anchor the panel by its top-left corner where it is now so only the bottom-right corner moves
			local left, top = PageF:GetLeft(), PageF:GetTop()
			if not left or not top then return end
			PageF:ClearAllPoints()
			PageF:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
			-- Resize by hand (the size follows how far the mouse has moved since the grip was pressed)
			local scale = PageF:GetEffectiveScale()
			local cx, cy = GetCursorPosition()
			local startX, startY = cx / scale, cy / scale
			local startW, startH = PageF:GetWidth(), PageF:GetHeight()
			PageF.isSizing = true
			self:SetScript("OnUpdate", function()
				local x, y = GetCursorPosition()
				local s = PageF:GetEffectiveScale()
				local w = max(minWidth, min(maxWidth, startW + x / s - startX))
				local h = max(minHeight, min(maxHeight, startH + startY - y / s))
				PageF:SetSize(w, h)
			end)
		end)

		-- Stop resizing, then save the panel size and position
		local function StopSizing()
			if not PageF.isSizing then return end
			grip:SetScript("OnUpdate", nil)
			PageF.isSizing = nil
			LeaSoundsLC["MainPanelW"], LeaSoundsLC["MainPanelH"] = floor(PageF:GetWidth() + 0.5), floor(PageF:GetHeight() + 0.5)
			PageF:SetSize(LeaSoundsLC["MainPanelW"], LeaSoundsLC["MainPanelH"])
			-- Update the screen clamp now resizing has finished
			LayoutPanel()
			PageF:SetUserPlaced(false)
			LeaSoundsLC["MainPanelA"], void, LeaSoundsLC["MainPanelR"], LeaSoundsLC["MainPanelX"], LeaSoundsLC["MainPanelY"] = PageF:GetPoint()
		end
		grip:SetScript("OnMouseUp", StopSizing)

		-- Make sure resizing stops if the panel is hidden while dragging
		PageF:HookScript("OnHide", StopSizing)

		PageF:SetScript("OnSizeChanged", LayoutPanel)

		-- Set the panel size (used by the reset command)
		function LeaSoundsLC:SetPanelSize(w, h)
			LeaSoundsLC["MainPanelW"], LeaSoundsLC["MainPanelH"] = w, h
			PageF:SetSize(w, h)
			LayoutPanel()
		end

		-- Create the rows and fit everything to the saved size
		LayoutPanel()

		-- Manage events
		LeaSoundsLC["PageF"]:RegisterEvent("PLAYER_LOGOUT")
		LeaSoundsLC["PageF"]:RegisterEvent("UI_SCALE_CHANGED")
		LeaSoundsLC["PageF"]:SetScript("OnEvent", function(self, event)
			if event == "PLAYER_LOGOUT" then
				-- Stop playing at reload or logout
				if musicHandle then
					StopSound(musicHandle)
				end
				-- Make sure a previewed sound is muted again
				EndPreview()
			elseif event == "UI_SCALE_CHANGED" then
				-- Refresh list
				UpdateList()
			end
		end)

		----------------------------------------------------------------------
		-- Loading the sound files (done the first time the panel is shown)
		----------------------------------------------------------------------

		-- Each sound file listing is stored as one string with one sound file per line (a single string loads much faster at login
		-- than a table of hundreds of thousands of strings, and each line only stores the part which is different from the line before
		-- so the string is much smaller).  The strings are split into tables the first time the panel is shown,
		-- a few thousand lines at a time so the game doesn't freeze, with a progress bar showing how far it has got.
		-- (Everything is in this function so the panel function doesn't get any more locals.)
		local function CreateLoader()

			-- Loading panel (shown over the listing while the sound files load)
			local loadFrame = CreateFrame("Frame", nil, scrollFrame)
			loadFrame:SetAllPoints()
			loadFrame:SetFrameLevel(scrollFrame:GetFrameLevel() + 20)
			loadFrame:EnableMouse(true)
			loadFrame:Hide()

			-- Progress bar
			local bar = CreateFrame("StatusBar", nil, loadFrame)
			bar:SetSize(320, 18)
			bar:SetPoint("TOP", loadFrame, "CENTER", 15, 0)
			bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
			bar:SetStatusBarColor(1.0, 0.82, 0.0)
			bar:SetMinMaxValues(0, 1)
			bar:SetValue(0)

			bar.bg = bar:CreateTexture(nil, "BACKGROUND")
			bar.bg:SetAllPoints()
			bar.bg:SetColorTexture(0, 0, 0, 0.6)

			local border = CreateFrame("Frame", nil, bar, BackdropTemplateMixin and "BackdropTemplate")
			border:SetPoint("TOPLEFT", -3, 3)
			border:SetPoint("BOTTOMRIGHT", 3, -3)
			if border.SetBackdrop then
				border:SetBackdrop({edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12})
				border:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
			end

			bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			bar.text:SetPoint("CENTER")

			-- Loading message (above the progress bar)
			local title = loadFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			title:SetPoint("BOTTOM", bar, "TOP", 0, 12)

			-- Split the sound file strings into tables (runs as a coroutine, yielding the progress from 0 to 1 when a frame's time is used up)
			local function LoadSources()
				local sources = {"MP3", "OGG", "EXT"}
				-- Total length of the strings (for the progress bar)
				local total, done = 0, 0
				for void, key in ipairs(sources) do
					if type(Leatrix_Sounds[key]) == "string" then total = total + #Leatrix_Sounds[key] end
				end
				total = max(total, 1)
				-- Capital letters and the order are checked while splitting so it doesn't need doing afterwards
				local allStrings, needLower, unsorted = true, false, {}
				local start = debugprofilestop()
				for void, key in ipairs(sources) do
					local raw = Leatrix_Sounds[key]
					if type(raw) == "string" then
						-- Each line is the number of characters the sound file shares with the one before it, a |, then the rest of it
						-- (so "sound/creature/bear/bearattack.ogg#1" followed by "sound/creature/bear/beardeath.ogg#2" is stored as "0|sound/creature/bear/bearattack.ogg#1" and "24|death.ogg#2")
						-- A ! after the number means the sound file can't be played in this game version (such as "24!|death.ogg#2")
						local t, n, pos, len, prev = {}, 0, 1, #raw, ""
						while pos <= len do
							local s, e, k, flag, rest = strfind(raw, "^(%d+)(!?)|([^\n]*)", pos)
							if e then
								local line = strsub(prev, 1, tonumber(k)) .. rest
								n = n + 1; t[n] = line
								if flag ~= "" then unplayableSet[line] = true end
								if not needLower and strfind(line, "%u") then needLower = true end
								if line < prev then unsorted[key] = true end
								prev = line
								pos = e + 2
								-- Give the game its frame back when this frame's time is used up (checked every 500 lines)
								if n % 500 == 0 and debugprofilestop() - start > 8 then
									coroutine.yield((done + pos) / total)
									start = debugprofilestop()
								end
							else
								-- Skip a line which isn't in the right format (such as an empty line)
								pos = (strfind(raw, "\n", pos, true) or len) + 1
							end
						end
						done = done + len
						-- Replacing the string with the table lets the string be garbage collected
						Leatrix_Sounds[key] = t
					elseif type(raw) == "table" then
						-- Listing is already a table (older listing file format) so it gets checked by EnsureSourcesSorted instead
						allStrings = false
					else
						-- Listing is missing
						Leatrix_Sounds[key] = {}
					end
				end
				-- Show the bar as full while the listing is built
				coroutine.yield(1)
				if allStrings then
					-- Do what EnsureSourcesSorted would do (the order and capital letters have already been checked)
					if unsorted["MP3"] then table.sort(Leatrix_Sounds["MP3"]) end
					if unsorted["OGG"] then table.sort(Leatrix_Sounds["OGG"]) end
					sourcesNeedLower = needLower
					mp3Runs = BuildCategoryRuns(Leatrix_Sounds["MP3"], musicCategories)
					oggRuns = BuildCategoryRuns(Leatrix_Sounds["OGG"], effectCategories)
					sourcesSorted = true
				end
			end

			-- Messages shown while loading (one is picked at random, like the loading screens in old games)
			local loadingMessages = {
				L["Tuning the murloc choir..."],
				L["Polishing the hearthstone chimes..."],
				L["Untangling the bard's lute strings..."],
				L["Asking the gnomes to stop banging things..."],
				L["Teaching the kodo to hum in tune..."],
				L["Collecting echoes from the Deeprun Tram..."],
				L["Counting the footsteps in Ironforge..."],
				L["Gently waking the sleeping dragons..."],
				L["Sweeping up stray spell sounds..."],
				L["Asking the innkeeper to turn the music down..."],
			}

			-- Pick a random message (not the one at index notIndex) and remember which one it was
			local function RandomLoadingMessage(notIndex)
				local i
				repeat i = random(#loadingMessages) until i ~= notIndex or #loadingMessages < 2
				title.messageIndex = i
				return loadingMessages[i]
			end

			-- Run the coroutine once per frame until it's finished
			local co
			local ticker = CreateFrame("Frame")
			ticker:Hide()
			ticker:SetScript("OnUpdate", function()
				local ok, progress = coroutine.resume(co)
				if not ok then
					-- Something went wrong so show a message and report the error
					ticker:Hide()
					bar:Hide()
					title:SetText(L["The sound files could not be loaded."])
					geterrorhandler()(progress)
					return
				end
				if coroutine.status(co) == "dead" then
					-- Finished so show the listing (this also runs any search typed while loading)
					ticker:Hide()
					loadFrame:Hide()
					dataLoaded = true
					ListData = Leatrix_Sounds["Listing"]
					SetListingFunc()
					-- Hide music and effects categories which have no sounds in this game version
					for void, m in ipairs({{musicMenu, mp3Runs}, {sfxMenu, oggRuns}}) do
						local present = {}
						for void, run in ipairs(m[2] or {}) do present[run[3]] = true end
						m[1]:SetAvailable(present)
						m[1]:SyncOnLoad()
					end
					-- Show target sounds if they were asked for while loading
					if LeaSoundsLC.ShowPendingMobSounds then LeaSoundsLC.ShowPendingMobSounds() end
					return
				end
				bar:SetValue(progress)
				bar.text:SetText(floor(progress * 100) .. "%")
				-- Show a different message while the listing is built
				if progress >= 1 and not title.building then
					title.building = true
					title:SetText(RandomLoadingMessage(title.messageIndex))
				end
			end)

			-- Start loading (only does anything the first time)
			return function()
				if co then return end
				co = coroutine.create(LoadSources)
				title:SetText(RandomLoadingMessage())
				bar.text:SetText("0%")
				loadFrame:Show()
				ticker:Show()
			end

		end

		-- Load the sound files when the panel is shown for the first time
		ListData = Leatrix_Sounds["Listing"]
		PageF:HookScript("OnShow", CreateLoader())

		-- Release memory
		LeaSoundsLC.Player = nil

	end

	----------------------------------------------------------------------
	-- L30: Events
	----------------------------------------------------------------------

	-- Create event frame
	local eventFrame = CreateFrame("FRAME")
	eventFrame:RegisterEvent("ADDON_LOADED")
	eventFrame:RegisterEvent("PLAYER_LOGIN")
	eventFrame:RegisterEvent("PLAYER_LOGOUT")
	eventFrame:SetScript("OnEvent", function(self, event, arg1)

		if event == "ADDON_LOADED" and arg1 == "Leatrix_Sounds" then
			-- Load settings or set defaults
			LeaSoundsLC:LoadVarAnc("MainPanelA", "CENTER")
			LeaSoundsLC:LoadVarAnc("MainPanelR", "CENTER")
			LeaSoundsLC:LoadVarNum("MainPanelX", 0, -5000, 5000)
			LeaSoundsLC:LoadVarNum("MainPanelY", 0, -5000, 5000)
			LeaSoundsLC:LoadVarNum("MainPanelW", 800, minWidth, 5000)
			LeaSoundsLC:LoadVarNum("MainPanelH", 616, minHeight, 5000)
			LeaSoundsLC:LoadVarChk("SoundMusic", "On")
			LeaSoundsLC:LoadVarChk("SoundSFX", "On")
			LeaSoundsLC:LoadVarChk("SoundUnknown", "On")
			LeaSoundsLC:LoadVarChk("SoundUnplayable", "Off")
			LeaSoundsLC:LoadVarChk("SoundMuted", "On")
			LeaSoundsLC:LoadVarNum("AddonLanguage", 1, 1, 12)
			LeaSoundsLC:LoadVarChk("ClickToPlay", "On")
			LeaSoundsLC:LoadVarChk("AutoPlayNext", "Off")
			LeaSoundsLC:LoadVarChk("PlayInBackground", "On")
			LeaSoundsLC:LoadVarChk("MobSoundsMenu", "On")
			if type(LeaSoundsDB["ToggleKey"]) == "string" then
				LeaSoundsLC["ToggleKey"] = LeaSoundsDB["ToggleKey"]
			else
				LeaSoundsLC["ToggleKey"] = ""
			end

			-- Load the unchecked music and effects categories (category key = true), saved in LeaSoundsDB
			for void, var in ipairs({"MusicCatOff", "SFXCatOff"}) do
				if type(LeaSoundsDB[var]) ~= "table" then LeaSoundsDB[var] = {} end
				for k, v in pairs(LeaSoundsDB[var]) do
					if type(k) ~= "string" or v ~= true then LeaSoundsDB[var][k] = nil end
				end
				LeaSoundsLC[var] = LeaSoundsDB[var]
			end

			-- Load muted sounds and mute them (sound file ID = track string)
			if type(LeaSoundsDB["MutedSounds"]) ~= "table" then LeaSoundsDB["MutedSounds"] = {} end
			LeaSoundsLC["MutedSounds"] = LeaSoundsDB["MutedSounds"]
			for id, track in pairs(LeaSoundsLC["MutedSounds"]) do
				if type(id) == "number" and type(track) == "string" then
					if MuteSoundFile then MuteSoundFile(id) end
				else
					LeaSoundsLC["MutedSounds"][id] = nil
				end
			end

		elseif event == "PLAYER_LOGIN" then
			-- Run main function
			LeaSoundsLC:Player()

		elseif event == "PLAYER_LOGOUT" then
			-- Save settings
			LeaSoundsDB["MainPanelA"] = LeaSoundsLC["MainPanelA"]
			LeaSoundsDB["MainPanelR"] = LeaSoundsLC["MainPanelR"]
			LeaSoundsDB["MainPanelX"] = LeaSoundsLC["MainPanelX"]
			LeaSoundsDB["MainPanelY"] = LeaSoundsLC["MainPanelY"]
			LeaSoundsDB["MainPanelW"] = LeaSoundsLC["MainPanelW"]
			LeaSoundsDB["MainPanelH"] = LeaSoundsLC["MainPanelH"]
			LeaSoundsDB["SoundMusic"] = LeaSoundsLC["SoundMusic"]
			LeaSoundsDB["SoundSFX"] = LeaSoundsLC["SoundSFX"]
			LeaSoundsDB["SoundUnknown"] = LeaSoundsLC["SoundUnknown"]
			LeaSoundsDB["SoundUnplayable"] = LeaSoundsLC["SoundUnplayable"]
			LeaSoundsDB["SoundMuted"] = LeaSoundsLC["SoundMuted"]
			LeaSoundsDB["AddonLanguage"] = LeaSoundsLC["AddonLanguage"]
			LeaSoundsDB["ClickToPlay"] = LeaSoundsLC["ClickToPlay"]
			LeaSoundsDB["AutoPlayNext"] = LeaSoundsLC["AutoPlayNext"]
			LeaSoundsDB["PlayInBackground"] = LeaSoundsLC["PlayInBackground"]
			LeaSoundsDB["MobSoundsMenu"] = LeaSoundsLC["MobSoundsMenu"]
			LeaSoundsDB["ToggleKey"] = LeaSoundsLC["ToggleKey"]
			-- (the mount sounds setting was merged into the target sounds setting)
			LeaSoundsDB["MountSoundsMenu"] = nil

		end

	end)

	----------------------------------------------------------------------
	-- L40: Commands
	----------------------------------------------------------------------

	-- Slash command function
	local function SlashFunc(str)
		local str = string.lower(str)
		if str and str == "leatrix_sounds" then str = "" end -- Compartment menu
		if str and str ~= "" then
			-- Traverse parameters
			if str == "ver" then
				-- Print addon version
				LeaSoundsLC:Print("Leatrix Sounds " .. LeaSoundsLC["AddonVer"])
				return
			elseif str == "rsnd" then
				-- Restart the sound system
				if LeaSoundsCB["StopPlaybackButton"] then LeaSoundsCB["StopPlaybackButton"]:Click() end
				Sound_GameSystem_RestartSoundSystem()
				LeaSoundsLC:Print("Sound system restarted.")
				return
			elseif str == "reset" then
				-- Reset layout
				LeaSoundsLC["MainPanelA"], LeaSoundsLC["MainPanelR"], LeaSoundsLC["MainPanelX"], LeaSoundsLC["MainPanelY"] = "CENTER", "CENTER", 0, 0
				LeaSoundsLC["PageF"]:ClearAllPoints()
				LeaSoundsLC["PageF"]:SetPoint(LeaSoundsLC["MainPanelA"], UIParent, LeaSoundsLC["MainPanelR"], LeaSoundsLC["MainPanelX"], LeaSoundsLC["MainPanelY"])
				if LeaSoundsLC.SetPanelSize then LeaSoundsLC:SetPanelSize(800, 616) end
				return
			elseif str == "wipe" or strfind(str, "^wipe%s+all%s*$") then
				-- Keep the toggle panel key unless wipe all is used
				local keepKey
				if str == "wipe" then keepKey = LeaSoundsLC["ToggleKey"] end
				-- Unmute any sounds muted by the addon
				if LeaSoundsLC["MutedSounds"] and UnmuteSoundFile then
					for id in pairs(LeaSoundsLC["MutedSounds"]) do UnmuteSoundFile(id) end
				end
				-- Wipe settings
				wipe(LeaSoundsDB)
				-- Put back the toggle panel key
				if keepKey then LeaSoundsDB["ToggleKey"] = keepKey end
				eventFrame:UnregisterAllEvents()
				ReloadUI()
			elseif str == "admin" then
				-- Preset profile (reload required)
				-- Unmute any sounds muted by the addon
				if LeaSoundsLC["MutedSounds"] and UnmuteSoundFile then
					for id in pairs(LeaSoundsLC["MutedSounds"]) do UnmuteSoundFile(id) end
				end
				-- Wipe settings
				wipe(LeaSoundsDB)
				eventFrame:UnregisterAllEvents()
				-- Settings
				LeaSoundsDB["ToggleKey"] = "CTRL-F"
				ReloadUI()
			else
				-- Invalid command entered
				LeaSoundsLC:Print("Invalid command.")
				return
			end
		else
			-- Prevent panel from showing if Blizzard Store is showing
			if StoreFrame and StoreFrame:GetAttribute("isshown") then return end
			-- Toggle the main panel
			if LeaSoundsLC["PageF"]:IsShown() then
				LeaSoundsLC["PageF"]:Hide()
			else
				LeaSoundsLC["PageF"]:Show()
			end
		end
	end

	-- Add slash commands
	_G.SLASH_Leatrix_Sounds1 = "/lts"
	_G.SLASH_Leatrix_Sounds2 = "/leasounds"

	SlashCmdList["Leatrix_Sounds"] = function(self)
		-- Run slash command function
		SlashFunc(self)
	end

	-- Add to compartment menu
	_G.LeaSoundsGlobalSlashFunc = SlashFunc

	----------------------------------------------------------------------
	-- Create panel in game options panel
	----------------------------------------------------------------------

	do

		local interPanel = CreateFrame("FRAME")
		interPanel.name = "Leatrix Sounds"

		local maintitle = LeaSoundsLC:MakeTx(interPanel, "Leatrix Sounds", 0, 0)
		maintitle:SetFont(maintitle:GetFont(), 72)
		maintitle:ClearAllPoints()
		maintitle:SetPoint("TOP", 0, -72)

		local expTitle = LeaSoundsLC:MakeTx(interPanel, LeaSoundsLC.GameTitle, 0, 0)
		expTitle:SetFont(expTitle:GetFont(), 32)
		expTitle:ClearAllPoints()
		expTitle:SetPoint("TOP", 0, -152)

		local subTitle = LeaSoundsLC:MakeTx(interPanel, "curseforge.com/wow/addons/leatrix-sounds", 0, 0)
		subTitle:SetFont(subTitle:GetFont(), 20)
		subTitle:ClearAllPoints()
		subTitle:SetPoint("BOTTOM", 0, 72)

		local slashTitle = LeaSoundsLC:MakeTx(interPanel, "/lts", 0, 0)
		slashTitle:SetFont(slashTitle:GetFont(), 72)
		slashTitle:ClearAllPoints()
		slashTitle:SetPoint("BOTTOM", subTitle, "TOP", 0, 40)
		slashTitle:SetScript("OnMouseUp", function(self, button)
			if button == "LeftButton" then
				SlashCmdList["Leatrix_Sounds"]("")
			end
		end)
		slashTitle:SetScript("OnEnter", function()
			slashTitle.r,  slashTitle.g, slashTitle.b = slashTitle:GetTextColor()
			slashTitle:SetTextColor(1, 1, 0)
		end)
		slashTitle:SetScript("OnLeave", function()
			slashTitle:SetTextColor(slashTitle.r, slashTitle.g, slashTitle.b)
		end)

		local pTex = interPanel:CreateTexture(nil, "BACKGROUND")
		pTex:SetAllPoints()
		pTex:SetTexture("Interface\\GLUES\\Models\\UI_MainMenu\\swordgradient2")
		pTex:SetAlpha(0.2)
		pTex:SetTexCoord(0, 1, 1, 0)

		local category = Settings.RegisterCanvasLayoutCategory(interPanel, "Leatrix Sounds")
		Settings.RegisterAddOnCategory(category)

	end
