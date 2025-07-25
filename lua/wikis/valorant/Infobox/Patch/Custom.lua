---
-- @Liquipedia
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Patch = Lua.import('Module:Infobox/Patch')

---@class ValorantPatchInfobox: PatchInfobox
local CustomPatch = Class.new(Patch)

---@param frame Frame
---@return Html
function CustomPatch.run(frame)
	local patch = CustomPatch(frame)

	return patch:createInfobox()
end

---@param args table
---@return {previous: string?, next: string?}
function CustomPatch:getChronologyData(args)
	local data = {}
	if args.previous then
		data.previous = 'Patch ' .. args.previous .. '|' .. args.previous
	end
	if args.next then
		data.next = 'Patch ' .. args.next .. '|' .. args.next
	end
	return data
end

return CustomPatch
