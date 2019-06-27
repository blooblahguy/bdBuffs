local addon = CreateFrame("frame",nil,UIParent)

local defaults = {}
-- Buffs
defaults[#defaults+1] = {tab = {
	type="tab",
	value="Buffs",
}}
defaults[#defaults+1] = {decimalprec = {
	type = "checkbox",
	value = true,
	label = "Show decimals on durations under 10 seconds",
}}
defaults[#defaults+1] = {buffsize = {
	type="slider",
	min=16,
	max=60,
	step=2,
	value=34,
	label="Buff Size",
}}
defaults[#defaults+1] = {buffspacing = {
	type="slider",
	min=0,
	max=10,
	step=2,
	value=0,
	label="Buff Spacing",
}}
defaults[#defaults+1] = {buffperrow = {
	type="slider",
	min=1,
	max=20,
	step=1,
	value=20,
	label="Buff Per Row",
}}
defaults[#defaults+1] = {bufffontsize = {
	type="slider",
	min=8,
	max=30,
	step=2,
	value=14,
	label="Buff Font Size",
}}
defaults[#defaults+1] = {buffhgrowth = {
	type="dropdown",
	value="Left",
	options={"Left","Right"},
	label="Buff Horizontal Growth",
}}
defaults[#defaults+1] = {buffvgrowth = {
	type="dropdown",
	value="Downwards",
	options={"Upwards","Downwards"},
	label="Buff Vertical Growth",
}}
defaults[#defaults+1] = {bufftimer = {
	type="dropdown",
	value="BOTTOM",
	options={"BOTTOM","TOP","LEFT","RIGHT"},
	label="Buff Timer Position",
}}

-- Debuffs
defaults[#defaults+1] = {tab = {
	type="tab",
	value="Debuffs",
}}
defaults[#defaults+1] = {debuffsize = {
	type="slider",
	min=16,
	max=60,
	step=2,
	value=32,
	label="Debuff Size",
}}
defaults[#defaults+1] = {debuffspacing = {
	type="slider",
	min=0,
	max=10,
	step=2,
	value=0,
	label="Debuff Spacing",
}}
defaults[#defaults+1] = {debuffperrow = {
	type="slider",
	min=1,
	max=10,
	step=1,
	value=2,
	label="Debuff Per Row",
}}
defaults[#defaults+1] = {debufffontsize = {
	type="slider",
	min=8,
	max=30,
	step=2,
	value=14,
	label="Debuff Font Size",
}}
defaults[#defaults+1] = {debuffhgrowth = {
	type="dropdown",
	value="Right",
	options={"Left","Right"},
	label="Debuff Horizontal Growth",
}}
defaults[#defaults+1] = {debuffvgrowth = {
	type="dropdown",
	value="Downwards",
	options={"Upwards","Downwards"},
	label="Debuff Vertical Growth",
}}
defaults[#defaults+1] = {debufftimer = {
	type="dropdown",
	value="BOTTOM",
	options={"BOTTOM","TOP","LEFT","RIGHT"},
	label="Debuff Timer Position",
}}

-- Blacklist
-- defaults[#defaults+1] = {tab = {
-- 	type="tab",
-- 	value="Aura Blacklist",
-- }}
-- defaults[#defaults+1] = {debuffblacklist = {
-- 	type = "list",
-- 	value = {},
-- 	label = "Blacklisted Debuffs",
-- }}
-- defaults[#defaults+1] = {buffblacklist = {
-- 	type = "list",
-- 	value = {},
-- 	label = "Blacklisted Buffs",
-- }}



local config = bdConfigLib:RegisterModule({
	name = "Buffs",
	callback = function() addon:config_changed() end
}, defaults, "BD_persistent")

local bufffont = CreateFont("BD_BUFFS_FONT")
bufffont:SetFont(bdCore.media.font, config.bufffontsize)
bufffont:SetShadowColor(0, 0, 0)
bufffont:SetShadowOffset(1, -1)

local debufffont = CreateFont("BD_DEBUFFS_FONT")
debufffont:SetFont(bdCore.media.font, config.debufffontsize)
debufffont:SetShadowColor(0, 0, 0)
debufffont:SetShadowOffset(1, -1)

local bdBuffs = CreateFrame("frame","bdBuffs",UIParent,"SecureAuraHeaderTemplate")
bdBuffs:SetPoint('TOPRIGHT', UIParent, "TOPRIGHT", -10, -10)
local bdDebuffs = CreateFrame("frame","bdDebuffs",UIParent,"SecureAuraHeaderTemplate")
bdDebuffs:SetPoint('LEFT', UIParent, "CENTER", 200, 0)

local function UpdateTime(self, elapsed)
	self.total = self.total + elapsed
	if (self.total > 0.1) then
		if(self.expiration) then
			self.expiration = math.max(self.expiration - self.total, 0)
			local seconds = self.expiration

			if(self.expiration <= 0) then
				self.duration:SetText('')
			else
				if (seconds < 10 or not config.decimalprec) then
					seconds = bdCore:round(seconds, 1)
				else
					seconds = math.floor(seconds)
				end
				local mins = math.floor(seconds/60);
				local hours = bdCore:round(mins/60, 1);

				if (hours and hours > 1) then
					self.duration:SetText(hours.."h")
				elseif (mins and mins > 0) then
					self.duration:SetText(mins.."m")
				else			
					self.duration:SetText(seconds.."s")
				end
			
			end
		end
		self.total = 0
	end
end

local function UpdateAura(self, index, filter)
	local unit = self:GetParent():GetAttribute('unit')
	local filter = self:GetParent():GetAttribute('filter')
	local name, texture, count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID, canApply, isBossDebuff, casterIsPlayer, nameplateShowAll, timeMod, effect1, effect2, effect3 = UnitAura(unit, index, filter)
	if(name) then
		self.texture:SetTexture(texture)
		if (not count) then
			count = 0
		end
		self.total = 0
		self.name = name
		self.count:SetText(count > 1 and count or '')
		self.expiration = expiration - GetTime()

		if (filter == "HARMFUL") then
			if debuffType then
				color = DebuffTypeColor[debuffType]
			else
				color = bdCore.media.red
			end
			local r, g, b = unpack(color)
			self.border:SetVertexColor(r * 0.6, g * 0.6, b * 0.6)
		end

	end
end

local function OnAttributeChanged(self, attribute, value)
	if(attribute == 'index') then
		UpdateAura(self, value)
	end
end

local counterAnchor = {}
counterAnchor['BOTTOM'] = "TOP"
counterAnchor['LEFT'] = "RIGHT"
counterAnchor['TOP'] = "BOTTOM"
counterAnchor['RIGHT'] = "LEFT"
counterSpacing = {}
counterSpacing["TOP"] = {0, 4}
counterSpacing["LEFT"] = {-4, 0}
counterSpacing["RIGHT"] = {4, 0}
counterSpacing["BOTTOM"] = {0, -4}

local function InitiateAura(self, name, button)
	if(not string.match(name, '^child')) then return end
	local filter = button:GetParent():GetAttribute("filter")
	
	button.filter = filter
	button:SetScript('OnUpdate', UpdateTime)
	button:SetScript('OnAttributeChanged', OnAttributeChanged)
	
	bdCore:setBackdrop(button)
	
	if (filter == "HARMFUL") then
		button.border:SetVertexColor(.7,0,0,1)
	end
	
	if (not button.texture) then
		button.texture = button:CreateTexture(nil, 'BORDER')
		button.texture:SetAllPoints()
		button.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end

	if (not button.count) then
		button.count = button:CreateFontString()
		button.count:SetPoint('BOTTOMRIGHT', -2, 2)
		button.count:SetFont(bdCore.media.font, 12, "OUTLINE")
		button.count:SetJustifyH("LEFT")
	end

	if (not button.duration) then
		button.duration = button:CreateFontString()
		button.duration:SetJustifyH("CENTER")
	end

	if (filter == "HARMFUL") then
		button.duration:SetFontObject("BD_DEBUFFS_FONT")
		button.count:SetFontObject("BD_DEBUFFS_FONT")
		button.duration:SetPoint(counterAnchor[config.debufftimer], button, config.debufftimer, unpack(counterSpacing[config.debufftimer]))
	else
		button.duration:SetFontObject("BD_BUFFS_FONT")
		button.count:SetFontObject("BD_BUFFS_FONT")
		button.duration:SetPoint(counterAnchor[config.bufftimer], button, config.bufftimer, unpack(counterSpacing[config.bufftimer]))
	end
	
	UpdateAura(button, button:GetID(), filter)
end


-- Set secure header attributes
local function setHeaderAttributes(header, template, isBuff)
	local s = function(...) header:SetAttribute(...) end
    header.filter = isBuff and "HELPFUL" or "HARMFUL"
	
	if (isBuff) then
		header:SetAttribute('includeWeapons', 1)
		header:SetAttribute('weaponTemplate', "bdBuffsTemplate")
	end
	
	bdCore:makeMovable(header)
	s('unit', 'player')
	s("filter", header.filter)
	s("separateOwn", 0)
	s('sortMethod', 'TIME')
    header:HookScript("OnAttributeChanged", InitiateAura)

	header:Show()
end

local function loopChildren(header,size)
	local c = {header:GetChildren()}
	for i = 1, #c do
		local child = c[i]
		child:SetSize(size,size)
	end
end

function addon:config_changed()
	if (InCombatLockdown()) then return end

	-- font sizes
	bufffont:SetFont(bdCore.media.font, config.bufffontsize)
	debufffont:SetFont(bdCore.media.font, config.debufffontsize)

	local buffrows = math.ceil(20/config.buffperrow)
	bdBuffs:SetSize((config.buffsize+config.buffspacing+2)*config.buffperrow, (config.buffsize+config.buffspacing+2)*buffrows)
	bdBuffs:SetAttribute("template", ("bdBuffsTemplate%d"):format(config.buffsize))
	bdBuffs:SetAttribute("style-width", config.buffsize)
	bdBuffs:SetAttribute("style-height", config.buffsize)
	bdBuffs:SetAttribute('wrapAfter', config.buffperrow)
	bdBuffs:SetAttribute("minWidth", (config.buffsize+config.buffspacing+2)*config.buffperrow)
	bdBuffs:SetAttribute("minHeight", (config.buffsize+config.buffspacing+2)*buffrows)
	bdBuffs:SetAttribute('weaponTemplate', ("bdBuffsTemplate%d"):format(config.buffsize))
	if (config.buffhgrowth == "Left") then
		bdBuffs:SetAttribute('xOffset', -(config.buffsize+config.buffspacing+2))
		bdBuffs:SetAttribute('sortDirection', "-")
		bdBuffs:SetAttribute('point', "TOPRIGHT")
	else
		bdBuffs:SetAttribute('xOffset', (config.buffsize+config.buffspacing+2))
		bdBuffs:SetAttribute('sortDirection', "+")
		bdBuffs:SetAttribute('point', "TOPLEFT")
	end

	local yspacing = 2
	if (config.bufftimer == "LEFT" or config.bufftimer == "RIGHT") then
		yspacing = yspacing + config.buffsize + config.buffspacing
	else
		yspacing = yspacing + config.buffsize + config.buffspacing + config.bufffontsize + 6
	end
	
	if (config.buffvgrowth == "Upwards") then
		bdBuffs:SetAttribute('wrapYOffset', yspacing)

		if (config.buffhgrowth == "Left") then
			bdBuffs:SetAttribute('point', "BOTTOMRIGHT")
		else
			bdBuffs:SetAttribute('point', "BOTTOMLEFT")
		end
	else
		bdBuffs:SetAttribute('wrapYOffset', -yspacing)
	end

	loopChildren(bdBuffs,config.buffsize)

	local debuffrows = math.ceil(10/config.debuffperrow)
	bdDebuffs:SetSize((config.debuffsize+config.debuffspacing+2)*config.debuffperrow, (config.debuffsize+config.debuffspacing+2)*debuffrows)
	bdDebuffs:SetAttribute("template", ("bdDebuffsTemplate%d"):format(config.debuffsize))
	bdDebuffs:SetAttribute("style-width", config.debuffsize)
	bdDebuffs:SetAttribute("style-height", config.debuffsize)
	bdDebuffs:SetAttribute('wrapAfter', config.debuffperrow)
	bdDebuffs:SetAttribute("minWidth", (config.debuffsize+config.debuffspacing+2)*config.debuffperrow)
	bdDebuffs:SetAttribute("minHeight", (config.debuffsize+config.debuffspacing+2)*debuffrows)
	if (config.debuffhgrowth == "Left") then
		bdDebuffs:SetAttribute('xOffset', -(config.debuffsize+config.debuffspacing+2))
		bdDebuffs:SetAttribute('sortDirection', "-")
		bdDebuffs:SetAttribute('point', "TOPRIGHT")
	else
		bdDebuffs:SetAttribute('xOffset', (config.debuffsize+config.debuffspacing+2))
		bdDebuffs:SetAttribute('sortDirection', "+")
		bdDebuffs:SetAttribute('point', "TOPLEFT")
	end

	local yspacing = 2
	if (config.debufftimer == "LEFT" or config.debufftimer == "RIGHT") then
		yspacing = yspacing + config.debuffsize + config.debuffspacing
	else
		yspacing = yspacing + config.debuffsize + config.debuffspacing + config.debufffontsize + 6
	end
	

	if (config.debuffvgrowth == "Upwards") then
		bdDebuffs:SetAttribute('wrapYOffset', yspacing)

		if (config.debuffhgrowth == "Left") then
			bdDebuffs:SetAttribute('point', "BOTTOMRIGHT")
		else
			bdDebuffs:SetAttribute('point', "BOTTOMLEFT")
		end
	else
		bdDebuffs:SetAttribute('wrapYOffset', -yspacing)
	end
	loopChildren(bdDebuffs,config.debuffsize)
	-- bdDebuffs:EnableMouse(0)
	-- bdDebuffs:SetAttribute('enableMouse', 0)
end

bdCore:hookEvent("bd_reconfig", function() addon:config_changed() end)

addon:RegisterEvent("PLAYER_REGEN_ENABLED")
addon:RegisterEvent("ADDON_LOADED")
addon:SetScript("OnEvent",function(self,event,name)
	if (event == "ADDON_LOADED") then
		if (name ~= 'bdBuffs') then return end
		self:UnregisterEvent(event)

		setHeaderAttributes(bdBuffs,"bdBuffsTemplate",true)
		setHeaderAttributes(bdDebuffs,"bdDebuffsTemplate",false)
		addon:config_changed()
		
		-- show who casts each buff
		hooksecurefunc(GameTooltip, "SetUnitAura", function(self, unit, index, filter)
			local caster = select(7, UnitAura(unit, index, filter))
			
			local name = caster and UnitName(caster)
			if name then
				self:AddDoubleLine("Cast by:", name, nil, nil, nil, 1, 1, 1)
				self:Show()
			end
		end)
		
		-- clean up
		setHeaderAttributes = nil
	else
		addon:config_changed()
	end
end)

local addonDisabler = CreateFrame("Frame", nil)
addonDisabler:RegisterEvent("ADDON_LOADED")
addonDisabler:SetScript("OnEvent", function(self, event, addon)
	BuffFrame:UnregisterAllEvents("UNIT_AURA")
	BuffFrame:Hide()
	-- if (IsAddOnLoaded("Blizzard_BuffFrane")) then
	-- 	DisableAddOn("Blizzard_BuffFrane")
	-- end
end)

addon:config_changed()