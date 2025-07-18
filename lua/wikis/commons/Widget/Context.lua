---
-- @Liquipedia
-- page=Module:Widget/Context
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')

---@class WidgetContext: Widget
local WidgetContext = Class.new(Widget)

---@param default any
---@return any
function WidgetContext:getValue(default)
	if type(self.props.value) == 'function' then
		return self.props.value(default)
	end
	return self.props.value
end

---@return (Widget|Html|string|number)[]
function WidgetContext:render()
	return self.props.children
end

return WidgetContext
