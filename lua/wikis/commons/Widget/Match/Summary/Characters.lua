---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Characters
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Character = Lua.import('Module:Widget/Match/Summary/Character')

local BASE_SIZE = 24 -- From brkts-champion-icon in Brackets.less
local HOVER_MODIFIER = 2.5 -- From brkts-champion-icon in Brackets.less

---@class MatchSummaryCharacters: Widget
---@operator call(table): MatchSummaryCharacters
local MatchSummaryCharacters = Class.new(Widget)
MatchSummaryCharacters.defaultProps = {
	flipped = false,
	hideOnMobile = false,
	size = BASE_SIZE * HOVER_MODIFIER,
}

---@return Widget[]?
function MatchSummaryCharacters:render()
	if not self.props.characters then
		return nil
	end
	local flipped = self.props.flipped

	return Div{
		classes = Array.extend(
			'brkts-popup-body-element-thumbs',
			'brkts-champion-icon',
			flipped and 'brkts-popup-body-element-thumbs-right' or nil,
			self.props.hideOnMobile and 'mobile-hide' or nil
		),
		children = Array.map(self.props.characters, function(character)
			return Character{
				character = character,
				date = self.props.date,
				bg = self.props.bg,
				showName = #self.props.characters == 1,
				flipped = flipped,
				size = self.props.size .. 'px',
			}
		end)
	}
end

return MatchSummaryCharacters
