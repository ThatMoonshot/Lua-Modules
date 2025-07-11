---
-- @Liquipedia
-- page=Module:Infobox/Team
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Date = Lua.import('Module:Date/Ext')
local Game = Lua.import('Module:Game')
local Image = Lua.import('Module:Image')
local Info = Lua.import('Module:Info')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local MatchTicker = Lua.import('Module:MatchTicker/Custom')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local BasicInfobox = Lua.import('Module:Infobox/Basic')
local Earnings = Lua.import('Module:Earnings')
local Flags = Lua.import('Module:Flags')
local Links = Lua.import('Module:Links')
local Locale = Lua.import('Module:Locale')
local ReferenceCleaner = Lua.import('Module:ReferenceCleaner')
local Region = Lua.import('Module:Region')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Builder = Widgets.Builder

---@class InfoboxTeam : BasicInfobox
local Team = Class.new(BasicInfobox)

local LINK_VARIANT = 'team'

local Language = mw.getContentLanguage()

local CREATED_STRING = '<span class="icon-16px">${icon}</span> ${date}'

---@enum statuses
local Status = {
	ACTIVE = 'active',
	DISBANDED = 'disbanded',
}

---@param frame Frame
---@return Html
function Team.run(frame)
	local team = Team(frame)
	return team:createInfobox()
end

---@return string
function Team:createInfobox()
	local args = self.args

	--- Transform data
	-- Links
	local links = Links.transform(args)

	-- Earnings
	self.totalEarnings, self.yearlyEarnings = self:calculateEarnings(args)

	-- Team Information
	local team = args.teamtemplate or self.pagename
	self.teamTemplate = mw.ext.TeamTemplate.raw(team) or {}

	args.imagedark = args.imagedark or args.imagedarkmode or args.image or self.teamTemplate.imagedark
	args.image = args.image or self.teamTemplate.image
	args.teamcardimagedark = self.teamTemplate.imagedark or args.teamcardimagedark or args.teamcardimage
	args.teamcardimage = self.teamTemplate.image or args.teamcardimage

	self.region = self:createRegion(args.region)

	local created
	args.created, created = self:processCreateDates()

	--- Display
	local widgets = {
		Header{
			name = args.name,
			image = not Game.isDefaultTeamLogo{logo = args.image} and args.image or nil,
			imageDefault = args.default,
			imageDark = not Game.isDefaultTeamLogo{logo = args.imagedark} and args.imagedark or nil,
			imageDefaultDark = args.defaultdark or args.defaultdarkmode,
			size = args.imagesize,
		},
		Center{children = {args.caption}},
		Title{children = 'Team Information'},
		Customizable{id = 'topcustomcontent', children = {}},
		Cell{
			name = 'Location',
			content = {
				self:_createLocation(args.location),
				self:_createLocation(args.location2)
			}
		},
		Customizable{
			id = 'region',
			children = {
				Cell{name = 'Region', content = {self.region.display}},
			}
		},
		Customizable{
			id = 'staff',
			children = {
				Cell{name = 'Coaches', content = {args.coaches}},
				Cell{name = 'Coach', content = {args.coach}},
				Cell{name = 'Director', content = {args.director}},
				Cell{name = 'Manager', content = {args.manager}},
				Cell{name = 'Team Captain', content = {args.captain}},
			}
		},
		Customizable{
			id = 'earnings',
			children = {
				Cell{
					name = not Logic.readBool(args.doNotIncludePlayerEarnings) and Abbreviation.make{
						text = 'Approx. Total Winnings',
						title = 'Includes individual player winnings&#10;while representing this team',
					} or 'Approx. Total Winnings',
					content = {self.totalEarnings > 0 and '$' .. Language:formatNum(self.totalEarnings) or nil}
				}
			}
		},
		Customizable{id = 'custom', children = {}},
		Builder{
			builder = function()
				if not Table.isEmpty(links) then
					return {
						Title{children = 'Links'},
						Widgets.Links{links = links, variant = LINK_VARIANT}
					}
				end
			end
		},
		Customizable{
			id = 'achievements',
			children = {
				Builder{
					builder = function()
						if String.isNotEmpty(args.achievements) then
							return {
								Title{children = 'Achievements'},
								Center{children = {args.achievements}}
							}
						end
					end
				}
			}
		},
		Customizable{
			id = 'history',
			children = {
				Builder{
					builder = function()
						if Table.isNotEmpty(created) or args.disbanded then
							return {
								Title{children = 'History'},
								Cell{name = 'Created', content = created},
								Cell{name = 'Disbanded', content = {args.disbanded}}
							}
						end
					end
				}
			}
		},
		Builder{
			builder = function()
				if args.trades then
					return {
						Center{children = {args.trades}}
					}
				end
			end
		},
		Customizable{id = 'customcontent', children = {}},
		Center{children = {args.footnotes}},
	}
	self:bottom(self:_createUpcomingMatches())
	self:bottom(self:createBottomContent())

	-- Categories
	if self:shouldStore(args) then
		self:categories('Teams')
		self:categories(unpack(self:getWikiCategories(args)))
	end

	-- Store LPDB data
	if self:shouldStore(args) then
		self:_setLpdbData(args, links)
	end

	-- Store Wiki-variables
	self:_definePageVariables(args)

	return self:build(widgets)
end

---@return string|number|nil # storage date
---@return string[] # display elements
function Team:processCreateDates()
	local earliestGameTimestamp = Team._parseDate(ReferenceCleaner.clean{input = self.args.created}) or Date.maxTimestamp

	local created = Array.map(self:getAllArgsForBase(self.args, 'created'), function (creation)
		local splitInput = Array.map(mw.text.split(creation, ':'), String.trim)
		if #splitInput ~= 2 then
			-- Legacy Input
			return creation
		end

		local icon
		local game, date = unpack(splitInput)
		local cleanDate = ReferenceCleaner.clean{input = date}

		if game:lower() == 'org' then
			icon = Image.display(self:_getTeamIcon(cleanDate))
		else
			local timestamp = Team._parseDate(cleanDate)
			if timestamp and timestamp < earliestGameTimestamp then
				earliestGameTimestamp = timestamp
			end

			icon = Game.icon{game = game, useDefault = false}
		end

		return String.interpolate(CREATED_STRING, {icon = icon or '', date = date})
	end)

	local storageDate = earliestGameTimestamp ~= Date.maxTimestamp and Date.toYmdInUtc(earliestGameTimestamp) or nil
	return storageDate, created
end

---@param date? string
---@return string?
---@return string?
function Team:_getTeamIcon(date)
	if not self.teamTemplate then
		return
	end

	local icon = self.teamTemplate.historicaltemplate
		and mw.ext.TeamTemplate.raw(self.teamTemplate.historicaltemplate, date).image
		or self.teamTemplate.image

	local iconDark = self.teamTemplate.historicaltemplate
		and mw.ext.TeamTemplate.raw(self.teamTemplate.historicaltemplate, date).imagedark
		or self.teamTemplate.imagedark

	return icon, iconDark
end

---@param date? string
---@return boolean
function Team._isValidDate(date)
	return date and date:match('%d%d%d%d-[%d%?]?[%d%?]?-[%d%?]?[%d%?]?')
end

---@param date string
---@return integer?
function Team._parseDate(date)
	if not Team._isValidDate(date) then
		return
	end

	return Date.readTimestampOrNil(date)
end

---@param region string?
---@return {display: string?, region: string?}
function Team:createRegion(region)
	if Logic.isEmpty(region) then return {} end

	return Region.run{region = region, linkToCategory = true} or {}
end

---@param location string?
---@return string?
function Team:_createLocation(location)
	if String.isEmpty(location)then
		return
	end

	local locationDisplay = self:getStandardLocationValue(location)
	local demonym
	if String.isNotEmpty(locationDisplay) then
		demonym = Flags.getLocalisation(locationDisplay)
		locationDisplay = '[[:Category:' .. locationDisplay
			.. '|' .. locationDisplay .. ']]'
	end

	if String.isNotEmpty(demonym) and self:shouldStore(self.args) then
		self:categories(demonym .. ' Teams')
	end

	return Flags.Icon{flag = location, shouldLink = true} ..
			'&nbsp;' ..
			(locationDisplay or '')
end

---@return Html?
function Team:_createUpcomingMatches()
	if self:shouldStore(self.args) and Info.config.match2.status > 0 then
		local frame = {short = true} ---@type Frame
		return MatchTicker.team(frame)
	end
end

---@param location string?
---@return string?
function Team:getStandardLocationValue(location)
	if String.isEmpty(location) then
		return
	end

	local locationToStore = Flags.CountryName{flag = location}

	if String.isEmpty(locationToStore) then
		table.insert(
			self.warnings,
			'"' .. location .. '" is not supported as a value for locations'
		)
		return
	end

	return locationToStore
end

---@param args table
---@param links table
function Team:_setLpdbData(args, links)
	local name = args.romanized_name or self.name

	local lpdbData = {
		name = name,
		location = self:getStandardLocationValue(args.location),
		location2 = self:getStandardLocationValue(args.location2),
		region = self.region.region,
		locations = Locale.formatLocations(args),
		logo = args.image,
		logodark = args.imagedark,
		textlesslogo = args.teamcardimage,
		textlesslogodark = args.teamcardimagedark,
		earnings = self.totalEarnings,
		earningsbyyear = self.yearlyEarnings or {},
		createdate = args.created,
		disbanddate = ReferenceCleaner.clean{input = args.disbanded},
		template = self.teamTemplate.historicaltemplate or self.teamTemplate.templatename,
		status = args.disbanded and Status.DISBANDED or Status.ACTIVE,
		links = mw.ext.LiquipediaDB.lpdb_create_json(
			Links.makeFullLinksForTableItems(links or {}, 'team')
		),
		extradata = {}
	}

	lpdbData = self:addToLpdb(lpdbData, args)

	mw.ext.LiquipediaDB.lpdb_team('team_' .. self.name, Json.stringifySubTables(lpdbData))
end

--- Allows for overriding this functionality
---@param args table
function Team:_definePageVariables(args)
	Variables.varDefine('region', self.region.region)

	self:defineCustomPageVariables(args)
end

--- Allows for overriding this functionality
---@param args table
function Team:defineCustomPageVariables(args)
end

---@param lpdbData table
---@param args table
---@return table
function Team:addToLpdb(lpdbData, args)
	return lpdbData
end

---@param args table
---@return boolean
function Team:shouldStore(args)
	return Namespace.isMain() and
		not Logic.readBool(Variables.varDefault('disable_LPDB_storage'))
end

---@param args table
---@return number
---@return table<integer, number?>?
function Team:calculateEarnings(args)
	return Earnings.calculateForTeam{
		team = self.pagename or self.name,
		perYear = true,
		queryHistorical = args.queryEarningsHistorical,
		doNotIncludePlayerEarnings = args.doNotIncludePlayerEarnings,
	}
end

return Team
