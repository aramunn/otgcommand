-----------------------------------------------------------------------------------------------
-- OTGCommand
--
-- MIT License
-- 
-- Copyright (c) 2016 Richard Ashwell
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-- Required Libraries
----------------------------------------------------------------------------------------------- 
require "Window"
require "Apollo"
require "GuildLib"
require "GameLib"
require "PlayerPathLib"
require "ChatSystemLib"
 
-----------------------------------------------------------------------------------------------
-- OTGCommand Module Definition
-----------------------------------------------------------------------------------------------
local OTGCommand = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local kcrSelectedText = ApolloColor.new("UI_BtnTextHoloPressedFlyby")
local kcrNormalText = ApolloColor.new("UI_BtnTextHoloNormal")
local kVersion = "0.5-beta"
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function OTGCommand:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

	o.tPlayers = {} 
	o.tGuildTable = {}
	o.tPlayersCount = 0
	o.wndSelectedPlayer = nil 
	o.wndSelectedToon = nil
	o.bDocLoaded = false
	o.bResetData = false
		
    return o
end

function OTGCommand:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

-----------------------------------------------------------------------------------------------
-- Save and Restore
-----------------------------------------------------------------------------------------------
function OTGCommand:OnSave(eType) 
	if eType ~= GameLib.CodeEnumAddonSaveLevel.General then
		return
	end
	
	tSave = {}
	if self.bResetData == false then
		tSave["tPlayers"] = self.tPlayers
		tSave["tGuildTable"] = self.tGuildTable
		tSave["tPlayersCount"] = self.tPlayersCount	
		tSave["VERSION"] = kVersion
	else
		tSave["tPlayers"] = {}
		tSave["tGuildTable"] = {}
		tSave["tPlayersCount"] = 0
		tSave["VERSION"] = kVersion
	end		
	return tSave	
end

function OTGCommand:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.General then return nil end
	if not tSavedData then return end
	if tSavedData.tPlayers ~= nil then
    	self.tPlayers = tSavedData.tPlayers
	end
	if tSavedData.tGuildTable ~= nil then
		self.tGuildTable = tSavedData.tGuildTable
	end
	if tSavedData.tPlayersCount ~= nil then
		self.tPlayersCount = tSavedData.tPlayersCount		
	end
end


-----------------------------------------------------------------------------------------------
-- OTGCommand OnLoad
-----------------------------------------------------------------------------------------------
function OTGCommand:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("OTGCommand.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- OTGCommand OnDocLoaded
-----------------------------------------------------------------------------------------------
function OTGCommand:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "OTGCommandForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
		-- item list
		self.wndItemList = self.wndMain:FindChild("ItemList")
		self.wndMain:FindChild("LabelVersion"):SetText(kVersion)
	    self.wndMain:Show(false, true)

		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("otg", "OnOTGCommandOn", self)
 		Apollo.RegisterSlashCommand("otgreset", "OnOTGCommandResetOn", self)
		Apollo.RegisterEventHandler("GuildRoster", "OnGuildRoster", self)

		-- self.timer = ApolloTimer.Create(10.0, true, "OnTimer", self)

		-- Do additional Addon initialization here
		self:PopulateGuildList()
 	    ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, string.format("OTGCommand %s loaded.", kVersion))
	end
end

-----------------------------------------------------------------------------------------------
-- OTGCommand Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/otg"
function OTGCommand:OnOTGCommandOn()
	self.wndMain:Invoke() -- show the window
end

-- on SlashCommand "/otgreset"
function OTGCommand:OnOTGCommandResetOn()
	self.bResetData = true
end

-- on timer
function OTGCommand:OnTimer()
	-- Do your timer-related stuff here.
end

-----------------------------------------------------------------------------------------------
-- OTGCommandForm Functions
-----------------------------------------------------------------------------------------------
function OTGCommand:OnCancel()
	self.wndMain:Close()
end

function OTGCommand:OnCloseExport( wndHandler, wndControl, eMouseButton )
  wndHandler:GetParent():Show(false)
  wndHandler:GetParent():Destroy()
  self.wndExport = nil
end

function OTGCommand:DoOpenExport( wndHandler, wndControl, eMouseButton )
  if not self.wndExport then
    -- self:RebuildExportList()
    self.wndExport = Apollo.LoadForm(self.xmlDoc, "ExportWindow", nil, self)
    local copybtn = self.wndExport:FindChild("CopyToClipboard")
	local exportStr = "Player\tCurrent DKP\n"
	for player, playerdata in self:PairsByKeys(self.tGuildTable) do			
		exportStr = (exportStr .. player .. "\t" .. playerdata.dkp .. "\n") 
	end	
    copybtn:SetActionData(GameLib.CodeEnumConfirmButtonType.CopyToClipboard, exportStr)
    self.wndExport:FindChild("ExportString"):SetText(exportStr)
    self.wndExport:Show(true)
  end
end


function OTGCommand:DoSuicideDKP(wndHandler, wndControl)
	local playerandrank = wndHandler:GetParent():FindChild("PlayerName"):GetText()
	local player = string.gsub(playerandrank , "^(.*)%s%[.*$", "%1") 
	wndHandler:GetParent():FindChild("PlayerDKP"):SetText(0)
	self.tGuildTable[player].dkp = 0
end

function OTGCommand:DoChangeDKP(wndHandler, wndControl)
	local dkp = wndHandler:GetText()
	local playerandrank = wndHandler:GetParent():FindChild("PlayerName"):GetText()
	local player = string.gsub(playerandrank , "^(.*)%s%[.*$", "%1") 
	self.tGuildTable[player].dkp = dkp
	return
end

function OTGCommand:GetGuild()
	local tGuild = nil
	for k,g in pairs(GuildLib.GetGuilds()) do
		if g:GetType() == GuildLib.GuildType_Guild then
			tGuild = g
		elseif g:GetName() == GameLib:GetPlayerUnit():GetGuildName() then
			tGuild = g
		end
	end
	return tGuild
end

-- Borrowed from Addon GuildRoster Tools by NCSoft
function OTGCommand:HelperConvertPathToString(ePath)
	local strResult = ""
	if ePath == PlayerPathLib.PlayerPathType_Soldier then
		strResult = Apollo.GetString("PlayerPathSoldier")
	elseif ePath == PlayerPathLib.PlayerPathType_Settler then
		strResult = Apollo.GetString("PlayerPathSettler")
	elseif ePath == PlayerPathLib.PlayerPathType_Explorer then
		strResult = Apollo.GetString("PlayerPathExplorer")
	elseif ePath == PlayerPathLib.PlayerPathType_Scientist then
		strResult = Apollo.GetString("PlayerPathScientist")
	end
	return strResult
end

-- Borrowed from Addon GuildRoster Tools by NCSoft
function OTGCommand:HelperConvertToTime(fDays)
	if fDays == 0 then
		return Apollo.GetString("ArenaRoster_Online")
	end

	if fDays == nil then
		return ""
	end

	local tTimeInfo = {["name"] = "", ["count"] = nil}

	if fDays >= 365 then -- Years
		tTimeInfo["name"] = Apollo.GetString("CRB_Year")
		tTimeInfo["count"] = math.floor(fDays / 365)
	elseif fDays >= 30 then -- Months
		tTimeInfo["name"] = Apollo.GetString("CRB_Month")
		tTimeInfo["count"] = math.floor(fDays / 30)
	elseif fDays >= 7 then
		tTimeInfo["name"] = Apollo.GetString("CRB_Week")
		tTimeInfo["count"] = math.floor(fDays / 7)
	elseif fDays >= 1 then -- Days
		tTimeInfo["name"] = Apollo.GetString("CRB_Day")
		tTimeInfo["count"] = math.floor(fDays)
	else
		local fHours = fDays * 24
		local nHoursRounded = math.floor(fHours)
		local nMin = math.floor(fHours*60)

		if nHoursRounded > 0 then
			tTimeInfo["name"] = Apollo.GetString("CRB_Hour")
			tTimeInfo["count"] = nHoursRounded
		elseif nMin > 0 then
			tTimeInfo["name"] = Apollo.GetString("CRB_Min")
			tTimeInfo["count"] = nMin
		else
			tTimeInfo["name"] = Apollo.GetString("CRB_Min")
			tTimeInfo["count"] = 1
		end
	end

	return String_GetWeaselString(Apollo.GetString("CRB_TimeOffline"), tTimeInfo)
end

function OTGCommand:PairsByKeys (t, f)
      local a = {}
      for n in pairs(t) do table.insert(a, n) end
      table.sort(a, f)
      local i = 0      -- iterator variable
      local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
      end
      return iter
    end

-- Based on addon GuildRoster Tools by NCSoft
function OTGCommand:OnGuildRoster(guildCurr, tGuildRoster)	
		tDataExport = {}
		local nDate= os.date("%m/%d/%y")
		local nTime= os.date("%H:%M")
		local strRealmName = GameLib.GetRealmName()
		local tGuild = self:GetGuild()
		strPlayerName = GameLib.GetPlayerUnit():GetName()
		strGuildName = tGuild:GetName()
		local tRanks = guildCurr:GetRanks()
		local strPlayerDataRow = ""
		local strPath = "Wildstar Addon Save Data for "..strPlayerName
		local timeStamp = (nTime.. " " ..nDate) 
		strTimeExported = timeStamp
		strHeaders = ("Server"..",".."Guild"..",".."Forum Name"..",".."Player Name"..",".."Level"..",".."Rank"..",".."Class"..",".."Path"..",".."Last Online"..",".."Days Offline")
	

		for key, tCurr in pairs(tGuildRoster) do		
			 if tRanks[tCurr.nRank] and tRanks[tCurr.nRank].strName then
				strRank = tRanks[tCurr.nRank].strName
				strRank = FixXMLString(strRank)	
			 end
	
			--map tRoster values
			local strRealm = strRealmName
			local strNote = tCurr.strNote
			local strName = tCurr.strName
			local nLevel = tCurr.nLevel
			local strClass = tCurr.strClass
			local strPlayerPath = self:HelperConvertPathToString(tCurr.ePathType)
			local strLastOnline = self:HelperConvertToTime(tCurr.fLastOnline)
			local nRawLastOnline = tCurr.fLastOnline
			strAttributes = (strClass .. ", " .. nLevel .. ", " .. strPlayerPath)  
			
			if self.tGuildTable[strNote] == nil then
				self.tPlayersCount = self.tPlayersCount + 1
				self.tGuildTable[strNote] = {				
				   	rank = strRank,
					dkp = 0,
				   	toons = {},
				   	tooncount = 1
				}				
				self.tGuildTable[strNote].toons[strName] = {
				    class = strClass,
				    level = nLevel,
					path = strPlayerPath
				}			
			else
				if self.tGuildTable[strNote].toons[strName] == nil then
				    self.tGuildTable[strNote].tooncount = self.tGuildTable[strNote].tooncount+1			
				end
				self.tGuildTable[strNote].toons[strName] = {
				    class = strClass,
				    level = nLevel,
					path = strPlayerPath
				}	
			end
		end
		self:PopulateGuildList()
end

function OTGCommand:PopulateGuildList()
	self:DestroyItemList()
	for player, playerdata in self:PairsByKeys(self.tGuildTable) do			
		self:AddGuildie(player, playerdata)
	end		
	self.wndItemList:ArrangeChildrenVert()
end

function OTGCommand:DestroyItemList()
	-- destroy all the wnd inside the list
	for idx,wnd in ipairs(self.tPlayers) do
		wnd:Destroy()
	end

	-- clear the list item array
	self.tPlayers = {}
	self.wndSelectedPlayer = nil
	self.wndSelectedToon = nil
end

function OTGCommand:AddGuildie(guildie, guildiedata)
	local wnd = Apollo.LoadForm(self.xmlDoc, "PlayerItem", self.wndItemList, self)
	local playerrank = guildiedata.rank
	local toons = guildiedata.toons
	local rank = guildiedata.rank
	local tooncount = guildiedata.tooncount
	local dkp = guildiedata.dkp

	self.tPlayers[guildie] = wnd
				
	local wndPlayerText = wnd:FindChild("PlayerName")
	if wndPlayerText then -- make sure the text wnd exist
		wndPlayerText:SetText(guildie)
		wndPlayerText:SetTextColor(kcrNormalText)
	end	
	
	local wndRankText = wnd:FindChild("PlayerRank")
	if wndRankText then 
		wndRankText:SetText(rank)
	end	

	if dkp ~= nil then
		wnd:FindChild("PlayerDKP"):SetText(dkp)
	end
			
	wnd:SetData(guildie)	

	local toonslist = wnd:FindChild("ToonsList")
	for toon, toondata in pairs(toons) do
		local toonwnd = Apollo.LoadForm(self.xmlDoc, "ToonItem", toonslist, self)
		
		local wndItemText = toonwnd:FindChild("ToonName")
		if wndItemText then 
			wndItemText:SetText(toon)
			wndItemText:SetTextColor(kcrNormalText)
		end
		
		wndItemText = toonwnd:FindChild("ToonLevel")
		if wndItemText then 
			wndItemText:SetText(toondata.level)
		end
	
		toonwnd:FindChild("ToonClass"):SetSprite("IconSprites:Icon_Windows_UI_CRB_" .. toondata.class)
		toonwnd:FindChild("ToonClass"):SetTooltip(string.format("<P Font=\"CRB_InterfaceSmall\" TextColor=\"white\">%s</P>", toondata.class))
		
		toonwnd:FindChild("ToonPath"):SetSprite("CRB_PlayerPathSprites:spr_Path_" .. toondata.path .. "_Stretch")
		toonwnd:FindChild("ToonPath"):SetTooltip(string.format("<P Font=\"CRB_InterfaceSmall\" TextColor=\"white\">%s</P>", toondata.path))

		toonwnd:SetData(toon)		
	end
	local nContainerLeft, nContainerTop, nContainerRight, nContainerBottom = wnd:GetAnchorOffsets()
	wnd:SetAnchorOffsets(nContainerLeft, nContainerTop, nContainerRight, (tooncount * 39)+25)
		
	nContainerLeft, nContainerTop, nContainerRight, nContainerBottom = toonslist:GetAnchorOffsets()
	toonslist:SetAnchorOffsets(nContainerLeft, nContainerTop, nContainerRight, tooncount * 39)	
	
	toonslist:ArrangeChildrenVert()
	self.wndItemList:ArrangeChildrenVert()  
end

function OTGCommand:OnPlayerSelected(wndHandler, wndControl)
    if wndHandler ~= wndControl then
        return
    end
    
    local wndItemText
    if self.wndSelectedPlayer ~= nil then
        wndItemText = self.wndSelectedPlayer:FindChild("PlayerName")
        wndItemText:SetTextColor(kcrNormalText)
    end
    
	self.wndSelectedPlayer = wndControl
	wndItemText = self.wndSelectedPlayer:FindChild("PlayerName")
    wndItemText:SetTextColor(kcrSelectedText)
    
	Print( "Player " ..  self.wndSelectedPlayer:GetData() .. " is selected.")
end

function OTGCommand:OnToonSelected(wndHandler, wndControl)
    if wndHandler ~= wndControl then
        return
    end

	local wndItemText
    if self.wndSelectedToon ~= nil then
        wndItemText = self.wndSelectedToon:FindChild("ToonName")
        wndItemText:SetTextColor(kcrNormalText)
    end

	self.wndSelectedToon = wndControl
	wndItemText = self.wndSelectedToon:FindChild("ToonName")
    wndItemText:SetTextColor(kcrSelectedText)

	Print( "Toon " ..  self.wndSelectedToon:GetData() .. " is selected.")
end

-----------------------------------------------------------------------------------------------
-- OTGCommand Instance
-----------------------------------------------------------------------------------------------
local OTGCommandInst = OTGCommand:new()
OTGCommandInst:Init()
