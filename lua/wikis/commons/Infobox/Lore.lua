
---
-- @Liquipedia
-- page=Module:Infobox/Lore
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Namespace = Lua.import('Module:Namespace')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = Lua.import('Module:Widget/All')
local Header = Widgets.Header
local Center = Widgets.Center
local Customizable = Widgets.Customizable

---@class LoreInfobox: BasicInfobox
local Cosmetic = Class.new(BasicInfobox)

---@return string
function Cosmetic:createInfobox()
	local args = self.args
	self:customParseArguments(args)

	local widgets = {
		Customizable{
			id = 'header',
			children = {
				Header{
					name = args.name,
					subHeader = args.subHeader,
					image = args.image,
					imageDefault = args.default,
					imageDark = args.imagedark or args.imagedarkmode,
					imageDefaultDark = args.defaultdark or args.defaultdarkmode,
					size = args.imagesize,
				},
			}
		},
		Customizable{
			id = 'caption',
			children = {
				Center{children = {args.caption}},
			}
		},
		Customizable{id = 'custom', children = {}},
		Center{children = {args.footnotes}},
	}

	self:categories('Lore')
	self:categories(unpack(self:getWikiCategories(args)))

	if Namespace.isMain() then
		self:setLpdbData(args)
	end

	return self:build(widgets)
end

---@param args table
---@return string[]
function Cosmetic:getWikiCategories(args)
	return {}
end

---@param args table
function Cosmetic:setLpdbData(args)
end

---@param args table
function Cosmetic:customParseArguments(args)
end

return Cosmetic
