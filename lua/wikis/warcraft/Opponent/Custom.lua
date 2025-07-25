---
-- @Liquipedia
-- page=Module:Opponent/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Faction = Lua.import('Module:Faction')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local Opponent = Lua.import('Module:Opponent')
local PlayerExt = Lua.import('Module:Player/Ext/Custom')

local CustomOpponent = Table.deepCopy(Opponent)

---@class WarcraftStandardPlayer:standardPlayer
---@field faction string?

---@class WarcraftStandardOpponent:standardOpponent
---@field players WarcraftStandardPlayer[]
---@field extradata table

---@param args table
---@return WarcraftStandardOpponent?
function CustomOpponent.readOpponentArgs(args)
	local opponent = Opponent.readOpponentArgs(args) --[[@as WarcraftStandardOpponent?]]
	local partySize = Opponent.partySize((opponent or {}).type)

	if not opponent then
		return nil
	end

	if partySize == 1 then
		opponent.players[1].faction = Faction.read(args.faction or args.race or args.p1race)
	elseif partySize then
		for playerIx, player in ipairs(opponent.players) do
			player.faction = Faction.read(args['p' .. playerIx .. 'faction'] or args['p' .. playerIx .. 'race'])
		end
	end

	return opponent
end

---@param type OpponentType?
---@return WarcraftStandardOpponent
function CustomOpponent.blank(type)
	local opponent = Opponent.blank(type) --[[@as WarcraftStandardOpponent]]

	opponent.extradata = {}

	return opponent
end

---@param type OpponentType?
---@return WarcraftStandardOpponent
function CustomOpponent.tbd(type)
	local opponent = Opponent.tbd(type) --[[@as WarcraftStandardOpponent]]

	opponent.extradata = {}

	return opponent
end

---@param record table
---@return WarcraftStandardOpponent?
function CustomOpponent.fromMatch2Record(record)
	local opponent = Opponent.fromMatch2Record(record) --[[@as WarcraftStandardOpponent?]]

	if not opponent then
		return nil
	end

	if Opponent.typeIsParty(opponent.type) then
		for playerIx, player in ipairs(opponent.players) do
			local playerRecord = record.match2players[playerIx]
			player.faction = Faction.read(playerRecord.extradata.faction) or Faction.defaultFaction
		end
	end

	return opponent
end

---@param opponent WarcraftStandardOpponent
---@return table?
function CustomOpponent.toLpdbStruct(opponent)
	local storageStruct = Opponent.toLpdbStruct(opponent)

	if Opponent.typeIsParty(opponent.type) then
		for playerIndex, player in pairs(opponent.players) do
			storageStruct.opponentplayers['p' .. playerIndex .. 'faction'] = player.faction
		end
	end

	return storageStruct
end

---@param storageStruct table
---@return WarcraftStandardOpponent?
function CustomOpponent.fromLpdbStruct(storageStruct)
	local opponent = Opponent.fromLpdbStruct(storageStruct) --[[@as WarcraftStandardOpponent?]]

	if not opponent then
		return nil
	end

	if Opponent.partySize(storageStruct.opponenttype) then
		for playerIndex, player in pairs(opponent.players) do
			player.faction = storageStruct.opponentplayers['p' .. playerIndex .. 'faction']
		end
	end

	return opponent
end

---@param opponent WarcraftStandardOpponent
---@param date string|number|nil
---@param options {syncPlayer: boolean?, overwritePageVars: boolean?}?
---@return WarcraftStandardOpponent
function CustomOpponent.resolve(opponent, date, options)
	options = options or {}
	if opponent.type == Opponent.team then
		return Opponent.resolve(opponent --[[@as standardOpponent]], date, options) --[[@as WarcraftStandardOpponent]]
	elseif Opponent.typeIsParty(opponent.type) then
		for _, player in ipairs(opponent.players) do
			if options.syncPlayer then
				local hasFaction = String.isNotEmpty(player.faction)
				local savePageVar = not Opponent.playerIsTbd(player)
				PlayerExt.syncPlayer(player, {
					savePageVar = savePageVar,
					date = date,
					overwritePageVars = options.overwritePageVars,
				})
				player.team = PlayerExt.syncTeam(
					player.pageName:gsub(' ', '_'),
					player.team,
					{
							date = date,
							savePageVar = savePageVar,
						}
				)
				player.faction = (hasFaction or player.faction ~= Faction.defaultFaction) and player.faction or nil
			else
				PlayerExt.populatePageName(player)
			end
			if player.team then
				player.team = TeamTemplate.resolve(player.team, date)
			end
		end
	end
	return opponent
end

return CustomOpponent
