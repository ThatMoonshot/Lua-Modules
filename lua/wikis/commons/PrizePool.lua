---
-- @Liquipedia
-- page=Module:PrizePool
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local String = Lua.import('Module:StringUtils')

local Import = Lua.import('Module:PrizePool/Import')
local BasePrizePool = Lua.import('Module:PrizePool/Base')
local Placement = Lua.import('Module:PrizePool/Placement')

local OpponentLibrary = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local Widgets = Lua.import('Module:Widget/All')
local TableRow = Widgets.TableRow
local TableCell = Widgets.TableCell

---@class PrizePool: BasePrizePool
---@field options table
---@field _lpdbInjector LpdbInjector?
---@field placements PrizePoolPlacement[]
local PrizePool = Class.new(BasePrizePool)

local NON_BREAKING_SPACE = '&nbsp;'

---@param args table
function PrizePool:readPlacements(args)
	local currentPlace = 0
	self.placements = Array.mapIndexes(function(placementIndex)
		if not args[placementIndex] then
			return
		end

		local placementInput = Json.parseIfString(args[placementIndex])
		local placement = Placement(placementInput, self):create(currentPlace)

		currentPlace = placement.placeEnd

		return placement
	end)

	self.placements = Import.run(self)
end

---@param placement PrizePoolPlacement
---@return WidgetTableCell
function PrizePool:placeOrAwardCell(placement)
	local placeCell = TableCell{
		children = {placement:getMedal() or '', NON_BREAKING_SPACE, placement:_displayPlace()},
		css = {['font-weight'] = 'bolder'},
		classes = {'prizepooltable-place'},
	}
	placeCell.rowSpan = #placement.opponents

	return placeCell
end

---@param placement PrizePoolPlacement
---@return boolean
function PrizePool:applyCutAfter(placement)
	if placement.placeStart > self.options.cutafter then
		return true
	end
	return false
end

---@param placement PrizePoolPlacement?
---@param nextPlacement PrizePoolPlacement
---@param rows WidgetTableRow[]
function PrizePool:applyToggleExpand(placement, nextPlacement, rows)
	if placement ~= nil
		and placement.placeStart <= self.options.cutafter
		and placement.placeEnd >= self.options.cutafter
		and placement ~= self.placements[#self.placements]
		and nextPlacement.placeStart ~= placement.placeStart
		and nextPlacement.placeEnd ~= placement.placeEnd then

		table.insert(rows, self:_toggleExpand(placement.placeEnd + 1, self.placements[#self.placements].placeEnd))
	end
end

---@param placeStart number
---@param placeEnd number
---@return WidgetTableRow
function PrizePool:_toggleExpand(placeStart, placeEnd)
	local text = 'place ' .. placeStart .. ' to ' .. placeEnd
	local expandButton = TableCell{
		children = {'<div>' .. text .. '&nbsp;<i class="fa fa-chevron-down"></i></div>'},
		classes = {'general-collapsible-expand-button'},
	}
	local collapseButton = TableCell{
		children = {'<div>' .. text .. '&nbsp;<i class="fa fa-chevron-up"></i></div>'},
		classes = {'general-collapsible-collapse-button'},
	}

	return TableRow{classes = {'ppt-toggle-expand'}, children = {expandButton, collapseButton}}
end

-- get the lpdbObjectName depending on opponenttype
---@param lpdbEntry placement
---@param prizePoolIndex integer|string
---@param lpdbPrefix string?
---@return string
function PrizePool:_lpdbObjectName(lpdbEntry, prizePoolIndex, lpdbPrefix)
	local objectName = 'ranking'
	if String.isNotEmpty(lpdbPrefix) then
		objectName = objectName .. '_' .. lpdbPrefix
	end
	if lpdbEntry.opponenttype == Opponent.team then
		return objectName .. '_' .. mw.ustring.lower(lpdbEntry.participant)
	end
	-- for non team opponents the pagename can be case sensitive
	-- so objectname needs to be case sensitive to avoid edge cases
	return objectName .. prizePoolIndex .. '_' .. lpdbEntry.participant
end

return PrizePool
