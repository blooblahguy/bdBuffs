local watcher = CreateFrame('frame',"bdWatcher",UIParent)
local watch = {
	['Food TIME'] = {
		160883, 
		160889, 
		160894, 
		160898, 
		160901, 
		160903, 
		160846, 
		160506, 
		160869, 
		174303, 
		160872, 
		174304, 
		160879, 
		174305, 
		160880, 
		174306, 
		160881,
		174307,
	},
	['Flask TIME'] = {
		156064, -- Greater Draenic Agility Flask
		156079, -- Greater Draenic Intellect Flask
		156084, -- Greater Draenic Stamina Flask
		156080, -- Greater Draenic Strength Flask
		156073, -- Draenic Agility Flask
		156070, -- Draenic Intellect Flask
		156077, -- Draenic Stamina Flask
		156071, -- Draenic Strength Flask
	},
	['Rune TIME'] = {
		142102,
		142103,
		142101,
		128988,
		128987,
		128991,
		128993,
		128995,
		128990,
		128992,
		129002,
		129003,
		128999,
		128989,
		129000,
		142101,
		128994,
		128997,
		129001,
		128998,
		128996,
		128991,
	}
}
local defaults = {}

defaults[#defaults+1] = {hideuntilmo = {
	type = "checkbox",
	value = false,
	label = "Hide until mouseover",
	callback = function() watcher:Update() end
}} 
defaults[#defaults+1] = {hideifbuffed = {
	type = "checkbox",
	value = false,
	label = "Hide if fully buffed",
	callback = function() watcher:buffLoop() end
}} 
defaults[#defaults+1] = {sep = {
	type = "text",
	value = "Track"
}}
defaults[#defaults+1] = {track_food = {
	type = "checkbox",
	value = true,
	label = "Food",
	callback = function() watcher:Update() end
}}
defaults[#defaults+1] = {track_flask= {
	type = "checkbox",
	value = true,
	label = "Flask",
	callback = function() watcher:Update() end
}}
defaults[#defaults+1] = {track_rune= {
	type = "checkbox",
	value = true,
	label = "Rune",
	callback = function() watcher:Update() end
}}

watcher:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -6, -2)
watcher:SetSize(700, 20)
bdCore:makeMovable(watcher)

bdCore:addModule("Buff Watcher", defaults)
local config = bdCore.config['Buff Watcher']


local frames = {}
function watcher:Update()
	local lastframe = nil
	for i = 1, 12 do
		for k, v in pairs(watch[i]) do
			local frame = frames[k]
			if (not lastframe) then
				frame:SetPoint("RIGHT", watcher, "RIGHT", 0, 0)
			else
				frame:SetPoint("RIGHT", lastframe, "LEFT", -10, 0)
			end
			frame:Hide()
			
			if (config['track_'..frame.name]) then
				frame:Show()
				lastframe = frame
			end
		end
	end
	
	if (config.hideuntilmo) then
		watcher:SetAlpha(0)
		watcher:EnableMouse(true)
		watcher:SetScript("OnEnter", function() watcher:SetAlpha(1) end)
		watcher:SetScript("OnLeave", function() watcher:SetAlpha(0) end)
	else
		watcher:SetAlpha(1)
		watcher:EnableMouse(false)
		watcher:SetScript("OnEnter", function() return end)
		watcher:SetScript("OnLeave", function() return end)
	end
end

for i = 1, 12 do
	for k, v in pairs(watch[i]) do
		local frame = CreateFrame("frame", nil, watcher)
		frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		frame.text:SetFont(bdCore.media.font, 14, "OUTLINE")
		frame.text:SetTextColor(.4, .4, .4)
		frame.text:SetShadowColor(0,0,0,0)
		local strfind = string.find(k, " TIME")
		local newtext = string.gsub(k, " TIME", "")
		local configtext = string.lower(string.gsub(newtext, "%s+", ""))
		frame.text:SetText(newtext)
		frame.text:SetPoint("CENTER")
		frame.text.updateTime = false
		frame:SetSize(frame.text:GetWidth(), 20)
		if (strfind) then frame.text.updateTime = true end
		frame.name = configtext
		
		frames[k] = frame
	end
end


watcher:Update()
function watcher:buffLoop()
	for w = 1, #watch do for k, v in pairs(watch[w]) do
		if (config['track_'..frames[k].name]) then
			frames[k]:Show()
			local found = false
			local spell = 0

			for i = 1, #v do
				local buff = v[i]
				local name, rank, icon = GetSpellInfo(buff)
				local buffname, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff, value1, value2, value3 = select(1, UnitBuff('player', name))
				
				if (buffname) then
					found = expires
					spell = spellID
				end
			end
			
			if (found) then
				frames[k].text:SetTextColor(1, 1, 1)
				frames[k].text.active = true
				frames[k].total = 0
				if (frames[k].text.updateTime) then
					frames[k]:SetScript("OnUpdate", function(self, elapsed)
						frames[k].total = frames[k].total + elapsed
						if (frames[k].total > 1) then
							frames[k].total = 0
							local newtext = string.gsub(k, " TIME", "")
							local timeLeft = math.floor(found - GetTime())
							if (timeLeft > 3600 ) then
								timeLeft = math.floor((timeLeft / 60) / 60).."h"
							elseif (timeLeft > 60) then
								timeLeft = math.floor(timeLeft / 60).."m"
							else
								timeLeft = timeLeft.."s"
							end
							frames[k].text:SetText(newtext.." ("..timeLeft..")")
							frames[k]:SetWidth(frames[k].text:GetWidth())
						end
					end)
				end
			else
				local start, ending = string.find(frames[k].text:GetText(), "%(")
				if (start) then
					local newtext = string.sub(frames[k].text:GetText(), 0, start-1)
					frames[k].text:SetText(newtext)
				end
				frames[k].text:SetTextColor(.4, .4, .4)
				frames[k].text.active = false
				frames[k]:SetWidth(frames[k].text:GetWidth())						
				frames[k]:SetScript("OnUpdate", function() return end)
				buffed = false
			end
		end
		
	end end
	
	if (config.hideifbuffed and buffed == true) then
		watcher:SetAlpha(0)
		watcher:EnableMouse(true)
		watcher:SetScript("OnEnter", function() watcher:SetAlpha(1) end)
		watcher:SetScript("OnLeave", function() watcher:SetAlpha(0) end)
	else
		watcher:SetAlpha(1)
		watcher:EnableMouse(false)
		watcher:SetScript("OnEnter", function() return end)
		watcher:SetScript("OnLeave", function() return end)
	end
end

-- I would attach this to UNIT_AURA and filter player, but that actually fires like crazy in combat
local total = 0
watcher:SetScript("OnUpdate",function(self, e)
	total = total + e
	if (total > 1) then
		total = 0
		watcher:buffLoop()
	end
end)


