---
-- @Liquipedia
-- page=Module:MatchGroup/Legacy/Default
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')

local MAX_NUMBER_OF_OPPONENTS = 2
local MAX_NUMBER_OF_PICKS = 5
local MAX_NUMBER_OF_BANS = 7

---@class Dota2MatchGroupLegacyDefault: MatchGroupLegacy
local MatchGroupLegacyDefault = Class.new(MatchGroupLegacy)

---@return table
function MatchGroupLegacyDefault:getMap()
	local map = {
		['$notEmpty$'] = 'map$1$winner',
		map = 'map$1$',
		team1side = 'map$1$team1side',
		team2side = 'map$1$team2side',
		length = 'map$1$length',
		winner = 'map$1$winner',
	}

	Array.forEach(Array.range(1, MAX_NUMBER_OF_OPPONENTS), function (oppIndex)
		local teamKey = 't' .. oppIndex
		Array.forEach(Array.range(1, MAX_NUMBER_OF_BANS), function (pIndex)
			if pIndex <= MAX_NUMBER_OF_PICKS then
				map[teamKey .. 'h' .. pIndex] = 'map$1$' .. teamKey .. 'h' .. pIndex
			end
			map[teamKey .. 'b' .. pIndex] = 'map$1$' .. teamKey .. 'b' .. pIndex
		end)
	end)

	return map
end

---@param frame Frame
---@return string
function MatchGroupLegacyDefault.run(frame)
	return MatchGroupLegacyDefault(frame):build()
end

return MatchGroupLegacyDefault
