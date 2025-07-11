---
-- @Liquipedia
-- page=Module:Widget/FilterButtons/Button
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class FilterButtonParameters
---@field buttonClasses string[]?
---@field css table<string,string>?
---@field active boolean?
---@field value string?
---@field display string|Widget|Html|nil

---@class FilterButton: Widget
---@operator call(table): FilterButton
---@field props FilterButtonParameters
local FilterButton = Class.new(Widget)

---@return Widget
function FilterButton:render()
	return HtmlWidgets.Span{
		classes = Array.extend({
			'filter-button',
			Logic.readBool(self.props.active) and 'filter-button--active' or nil
		}, self.props.buttonClasses),
		attributes = { ['data-filter-on'] = self.props.value },
		css = self.props.css,
		children = { self.props.display }
	}
end

return FilterButton
