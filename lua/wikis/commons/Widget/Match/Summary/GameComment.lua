---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/GameComment
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MatchSummaryBreak = Lua.import('Module:Widget/Match/Summary/Break')

---@class MatchSummaryGameComment: Widget
---@operator call(table): MatchSummaryGameComment
local MatchSummaryGameComment = Class.new(Widget)

---@return Widget?
function MatchSummaryGameComment:render()
	if Logic.isEmpty(self.props.children) then
		return nil
	end
	return HtmlWidgets.Fragment{children = {
		MatchSummaryBreak{},
		HtmlWidgets.Div{
			css = {margin = 'auto', ['max-width'] = '100%'},
			classes = self.props.classes,
			children = self.props.children
		},
	}}
end

return MatchSummaryGameComment
