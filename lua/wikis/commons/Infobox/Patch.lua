---
-- @Liquipedia
-- page=Module:Infobox/Patch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Chronology = Widgets.Chronology
local Builder = Widgets.Builder
local Customizable = Widgets.Customizable
local Highlights = Widgets.Highlights

---@class PatchInfobox: BasicInfobox
local Patch = Class.new(BasicInfobox)

---@param frame Frame
---@return Html
function Patch.run(frame)
	local patch = Patch(frame)
	return patch:createInfobox()
end

---@return string
function Patch:createInfobox()
	local args = self.args

	local widgets = {
		Header{
			name = args.name,
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{children = {args.caption}},
		Title{children = (self:getInformationType(args)) .. ' Information'},
		Customizable{id = 'version', children = {
				Cell{name = 'Version', content = {args.version}},
			}
		},
		Customizable{id = 'release', children = {
				Cell{name = 'Release Date', content = {args.release}},
			}
		},
		Customizable{id = 'custom', children = {}},
		Builder{
			builder = function()
				local highlights = self:getAllArgsForBase(args, 'highlight')
				if not Table.isEmpty(highlights) then
					return {
						Title{children = 'Highlights'},
						Highlights{children = highlights}
					}
				end
			end
		},
		Chronology{args = self:getChronologyData(args), showTitle = true},
		Customizable{id = 'customcontent', children = {}},
		Center{children = {args.footnotes}},
	}

	if Namespace.isMain() and not Logic.readBool(Variables.varDefault('disable_LPDB_storage')) then
		self:categories(self:getInformationType(args))
		self:categories(unpack(self:getWikiCategories(args)))
		self:setLpdbData(args)
	end

	return self:build(widgets)
end

--- Allows for overriding this functionality
---Adjust Lpdb data
---@param lpdbData table
---@param args table
---@return table
function Patch:addToLpdb(lpdbData, args)
	return lpdbData
end

--- Allows for overriding this functionality
---@param args table
function Patch:setLpdbData(args)
	local informationType = self:getInformationType(args):lower()
	local lpdbData = {
		name = self.name,
		type = informationType,
		image = args.image,
		imagedark = args.imagedark,
		date = args.release,
		information = args.version,
		extradata = {
			highlights = self:getAllArgsForBase(args, 'highlight')
		},
	}

	lpdbData = self:addToLpdb(lpdbData, args)
	mw.ext.LiquipediaDB.lpdb_datapoint(informationType .. '_' .. self.name, Json.stringifySubTables(lpdbData))
end

--- Allows for overriding this functionality
---@param args table
---@return string
function Patch:getInformationType(args)
	return args.informationType or 'Patch'
end

--- Allows for overriding this functionality
---@protected
---@param args table
---@return string[]
function Patch:getWikiCategories(args)
	return {}
end

--- Allows for overriding this functionality
---@param args table
---@return {previous: string?, next: string?}
function Patch:getChronologyData(args)
	return { previous = args.previous, next = args.next }
end

return Patch
