---
-- @Liquipedia
-- page=Module:Widget/MainPage/CenterDot
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class CenterDot: Widget
---@operator call(table): CenterDot
local CenterDot = Class.new(Widget)

function CenterDot:render()
	return HtmlWidgets.Span{
		css = {
			['font-style'] = 'normal',
			padding = '0 5px',
		},
		children = {'&#8226;'},
	}
end

return CenterDot
