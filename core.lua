local addon = CreateFrame("frame",nil,UIParent)

local defaults = {}
-- Buffs
defaults[#defaults+1] = {tab = {
	type="tab",
	value="Buffs",
}}
defaults[#defaults+1] = {buffsize = {
	type="slider",
	min=16,
	max=60,
	step=2,
	value=34,
	label="Buff Size",
	callback = function() addon:config_changed() end
}}
defaults[#defaults+1] = {buffspacing = {
	type="slider",
	min=0,
	max=10,
	step=2,
	value=0,
	label="Buff Spacing",
	callback = function() addon:config_changed() end
}}
defaults[#defaults+1] = {buffperrow = {
	type="slider",
	min=1,
	max=20,
	step=1,
	value=20,
	label="Buff Per Row",
	callback = function() addon:config_changed() end
}}
defaults[#defaults+1] = {buffhgrowth = {
	type="dropdown",
	value="Left",
	options={"Left","Right"},
	label="Buff Horizontal Growth",
	callback = function() addon:config_changed() end
}}
defaults[#defaults+1] = {buffvgrowth = {
	type="dropdown",
	value="Downwards",
	options={"Upwards","Downwards"},
	label="Buff Vertical Growth",
	callback = function() addon:config_changed() end
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
	callback = function() addon:config_changed() end
}}
defaults[#defaults+1] = {debuffspacing = {
	type="slider",
	min=0,
	max=10,
	step=2,
	value=0,
	label="Debuff Spacing",
	callback = function() addon:config_changed() end
}}
defaults[#defaults+1] = {debuffperrow = {
	type="slider",
	min=1,
	max=10,
	step=1,
	value=2,
	label="Debuff Per Row",
	callback = function() addon:config_changed() end
}}
defaults[#defaults+1] = {debuffhgrowth = {
	type="dropdown",
	value="Right",
	options={"Left","Right"},
	label="Debuff Horizontal Growth",
	callback = function() addon:config_changed() end
}}
defaults[#defaults+1] = {debuffvgrowth = {
	type="dropdown",
	value="Downwards",
	options={"Upwards","Downwards"},
	label="Debuff Vertical Growth",
	callback = function() addon:config_changed() end
}}

-- Blacklist
defaults[#defaults+1] = {tab = {
	type="tab",
	value="Aura Blacklist",
}}
defaults[#defaults+1] = {debuffblacklist = {
	type = "list",
	value = {},
	label = "Blacklisted Debuffs",
}}
defaults[#defaults+1] = {buffblacklist = {
	type = "list",
	value = {},
	label = "Blacklisted Buffs",
}}

bdCore:addModule("Buffs/Debuffs", defaults)
local config = bdCore.config.profile['Buffs/Debuffs']



local bdBuffs = CreateFrame("frame","bdBuffs",UIParent,"SecureAuraHeaderTemplate")
bdBuffs:SetPoint('TOPRIGHT', UIParent, "TOPRIGHT", -10, -10)
local bdDebuffs = CreateFrame("frame","bdDebuffs",UIParent,"SecureAuraHeaderTemplate")
bdDebuffs:SetPoint('LEFT', UIParent, "CENTER", 200, 0)


local function UpdateTime(self, elapsed)
	if(self.expiration) then
		self.expiration = math.max(self.expiration - elapsed, 0)
		local seconds = self.expiration

		if(self.expiration <= 0) then
			self.duration:SetText('')
		else
			local secs = tonumber(math.floor(seconds))
			local mins = tonumber(math.floor(seconds/60));
			local hours = tonumber(round(mins/60,1));

			if (hours and hours > 1) then
				self.duration:SetText(hours.."h")
			elseif (mins and mins > 0) then
				self.duration:SetText(mins.."m")
			else			
				self.duration:SetText(secs.."s")
			end
		
		end
	end
end

local function UpdateAura(self, index, filter)
	local unit = self:GetParent():GetAttribute('unit')
	local filter = self:GetParent():GetAttribute('filter')
	local name, b1, texture, s0, b2, b3, sunit, s1, s1, expiration, b3, b4, b5, b6, count = UnitAura(unit, index, filter)
	if(name) then
		if(filter == 'HARMFUL' and config.debuffblacklist[name]) then
			self:SetSize(0,0);
		end

		if(filter == 'HELPFUL' and config.buffblacklist[name]) then
			self:SetSize(0,0);
		end

		self.texture:SetTexture(texture)
		if (not count) then
			count = 0
		end
		self.count:SetText(count > 1 and count or '')
		self.expiration = expiration - GetTime()
	end
end

local function OnAttributeChanged(self, attribute, value)
	if(attribute == 'index') then
		UpdateAura(self, value)
	end
end

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
		button.duration:SetPoint('TOP', button, "BOTTOM", 0, -4)
		button.duration:SetFont(bdCore.media.font, 12, "OUTLINE")
		button.duration:SetJustifyH("CENTER")
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

	config = bdCore.config.profile['Buffs/Debuffs']

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
	if (config.buffvgrowth == "Upwards") then
		bdBuffs:SetAttribute('wrapYOffset', (config.buffsize+config.buffspacing+16))
		if (config.buffhgrowth == "Left") then
			bdBuffs:SetAttribute('point', "BOTTOMRIGHT")
		else
			bdBuffs:SetAttribute('point', "BOTTOMLEFT")
		end
	else
		bdBuffs:SetAttribute('wrapYOffset', -(config.buffsize+config.buffspacing+16))
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
	if (config.debuffvgrowth == "Upwards") then
		bdDebuffs:SetAttribute('wrapYOffset', (config.debuffsize+config.debuffspacing+16))
		if (config.debuffhgrowth == "Left") then
			bdDebuffs:SetAttribute('point', "BOTTOMRIGHT")
		else
			bdDebuffs:SetAttribute('point', "BOTTOMLEFT")
		end
	else
		bdDebuffs:SetAttribute('wrapYOffset', -(config.debuffsize+config.debuffspacing+16))
	end
	loopChildren(bdDebuffs,config.debuffsize)
	bdDebuffs:EnableMouse(0)
	bdDebuffs:SetAttribute('enableMouse', 0)
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
		
		BuffFrame:UnregisterEvent("UNIT_AURA")
		addon:config_changed()
		local h = function(f) f.Show = f.Hide; f:Hide() end
		h(BuffFrame)
		h(TemporaryEnchantFrame)
		
		-- show who casts each buff
		hooksecurefunc(GameTooltip, "SetUnitAura", function(self, unit, index, filter)
			local caster = select(8, UnitAura(unit, index, filter))
			local name = caster and UnitName(caster)
			if name then
				self:AddDoubleLine("Cast by:", name, nil, nil, nil, 1, 1, 1)
				self:Show()
			end
		end)
		
		-- clean up
		setHeaderAttributes = nil
		collectgarbage("collect")
	else
		addon:config_changed()
	end
end)


