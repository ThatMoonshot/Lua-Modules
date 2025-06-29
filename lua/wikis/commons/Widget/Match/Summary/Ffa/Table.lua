---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class MatchSummaryFfaTable: Widget
---@operator call(table): MatchSummaryFfaTable
local MatchSummaryFfaTable = Class.new(Widget)

---@return Widget
function MatchSummaryFfaTable:render()
	return HtmlWidgets.Div{
		classes = {'panel-table'},
		attributes = {
			['data-js-battle-royale'] = 'table',
		},
		children = self.props.children,
	}
end

return MatchSummaryFfaTable
