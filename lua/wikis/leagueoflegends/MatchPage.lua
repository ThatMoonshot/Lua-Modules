---
-- @Liquipedia
-- page=Module:MatchPage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local BaseMatchPage = Lua.import('Module:MatchPage/Base')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local PlayerStat = Lua.import('Module:Widget/Match/Page/PlayerStat')
local PlayerDisplay = Lua.import('Module:Widget/Match/Page/PlayerDisplay')
local StatsList = Lua.import('Module:Widget/Match/Page/StatsList')
local VetoItem = Lua.import('Module:Widget/Match/Page/VetoItem')
local VetoRow = Lua.import('Module:Widget/Match/Page/VetoRow')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class LoLMatchPageGame: MatchPageGame
---@field vetoGroups {type: 'ban'|'pick', team: integer, character: string, vetoNumber: integer}[][][]

---@class LoLMatchPage: BaseMatchPage
---@field games LoLMatchPageGame[]
local MatchPage = Class.new(BaseMatchPage)

local KEYSTONES = Table.map({
	-- Precision
	'Press the Attack',
	'Lethal Tempo',
	'Fleet Footwork',
	'Conqueror',

	-- Domination
	'Electrocute',
	'Predator',
	'Dark Harvest',
	'Hail of Blades',

	-- Sorcery
	'Summon Aery',
	'Arcane Comet',
	'Phase Rush',

	-- Resolve
	'Grasp of the Undying',
	'Aftershock',
	'Guardian',

	-- Inspiration
	'Glacial Augment',
	'Unsealed Spellbook',
	'First Strike',
}, function(_, value)
	return value, true
end)

local DEFAULT_ITEM = 'EmptyIcon'
local LOADOUT_ICON_SIZE = '24px'
local ITEMS_TO_SHOW = 6

local KDA_ICON = IconFa{iconName = 'leagueoflegends_kda', hover = 'KDA'}
local GOLD_ICON = IconFa{iconName = 'gold', hover = 'Gold'}
local SPAN_SLASH = HtmlWidgets.Span{classes = {'slash'}, children = '/'}

---@param props {match: MatchGroupUtilMatch}
---@return Widget
function MatchPage.getByMatchId(props)
	local matchPage = MatchPage(props.match)

	-- Update the view model with game and team data
	matchPage:populateGames()

	-- Add more opponent data field
	matchPage:populateOpponents()

	return matchPage:render()
end

function MatchPage:populateGames()
	Array.forEach(self.games, function(game)
		game.finished = game.winner ~= nil and game.winner ~= -1
		game.teams = Array.map(game.opponents, function(opponent, teamIdx)
			local team = {}

			team.scoreDisplay = game.winner == teamIdx and 'W' or game.finished and 'L' or '-'
			team.side = String.nilIfEmpty(game.extradata['team' .. teamIdx ..'side'])

			team.players = Array.map(opponent.players, function(player)
				if Logic.isDeepEmpty(player) then return end
				return Table.mergeInto(player, {
					items = Array.map(Array.range(1, ITEMS_TO_SHOW), function(idx)
						return player.items[idx] or DEFAULT_ITEM
					end),
					runeKeystone = Array.filter(player.runes.primary.runes, function(rune)
						return KEYSTONES[rune]
					end)[1]
				})
			end)

			if game.finished then
				-- Aggregate stats
				team.gold = MatchPage.abbreviateNumber(MatchPage.sumItem(team.players, 'gold'))
				team.kills = MatchPage.sumItem(team.players, 'kills')
				team.deaths = MatchPage.sumItem(team.players, 'deaths')
				team.assists = MatchPage.sumItem(team.players, 'assists')

				-- Set fields
				team.objectives = game.extradata['team' .. teamIdx .. 'objectives'] or {}
			else
				team.objectives = {}
			end

			team.picks = Array.map(team.players, Operator.property('character'))
			team.pickOrder = Array.filter(game.extradata.vetophase or {}, function(veto)
				return veto.type == 'pick' and veto.team == teamIdx
			end)
			team.bans = Array.filter(game.extradata.vetophase or {}, function(veto)
				return veto.type == 'ban' and veto.team == teamIdx
			end)

			return team
		end)

		local _, vetoByTeam = Array.groupBy(game.extradata.vetophase or {}, Operator.property('team'))
		game.vetoGroups = {}

		Array.forEach(vetoByTeam, function(team, teamIndex)
			local groupIndex = 1
			local lastType = 'ban'
			Array.forEach(team, function(veto)
				if lastType ~= veto.type then groupIndex = groupIndex + 1 end
				veto.groupIndex = groupIndex
				lastType = veto.type
			end)
			_, game.vetoGroups[teamIndex] = Array.groupBy(team, Operator.property('groupIndex'))
		end)
	end)
end

---@param game LoLMatchPageGame
---@return Widget
function MatchPage:renderGame(game)
	return HtmlWidgets.Fragment{
		children = WidgetUtil.collect(
			self:_renderGameOverview(game),
			self:_renderDraft(game),
			self:_renderTeamStats(game),
			self:_renderPlayersPerformance(game)
		)
	}
end

---@private
---@param game LoLMatchPageGame
---@return Widget[]
function MatchPage:_buildGameResultSummary(game)
	return {
		Div{
			classes = {'match-bm-lol-game-summary-faction'},
			children = game.teams[1].side and IconImage{
				imageLight = 'Lol faction ' .. game.teams[1].side .. '.png',
				link = '',
				caption = game.teams[1].side .. ' side'
			} or nil
		},
		Div{
			classes = {'match-bm-lol-game-summary-score-holder'},
			children = game.finished and {
				Div{
					classes = {'match-bm-lol-game-summary-score'},
					children = {
						game.teams[1].scoreDisplay,
						'&ndash;',
						game.teams[2].scoreDisplay
					}
				},
				Div{
					classes = {'match-bm-lol-game-summary-length'},
					children = game.length
				}
			} or nil
		},
		Div{
			classes = {'match-bm-lol-game-summary-faction'},
			children = game.teams[2].side and IconImage{
				imageLight = 'Lol faction ' .. game.teams[2].side .. '.png',
				link = '',
				caption = game.teams[2].side .. ' side'
			} or nil
		}
	}
end

---@private
---@param game LoLMatchPageGame
---@return Widget?
function MatchPage:_renderGameOverview(game)
	if self:isBestOfOne() then return end
	return Div{
		classes = {'match-bm-lol-game-overview'},
		children = {
			Div{
				classes = {'match-bm-lol-game-summary'},
				children = {
					Div{
						classes = {'match-bm-lol-game-summary-team'},
						children = self.opponents[1].iconDisplay
					},
					Div{
						classes = {'match-bm-lol-game-summary-center'},
						children = self:_buildGameResultSummary(game)
					},
					Div{
						classes = {'match-bm-lol-game-summary-team'},
						children = self.opponents[2].iconDisplay
					},
				}
			}
		}
	}
end

---@private
---@param game LoLMatchPageGame
---@return Widget[]
function MatchPage:_renderDraft(game)
	return {
		HtmlWidgets.H3{children = 'Draft'},
		Div{
			classes = {'match-bm-lol-game-veto', 'collapsed', 'general-collapsible'},
			children = {
				Div{
					classes = {'match-bm-lol-game-veto-overview'},
					children = Array.map({1, 2}, function (teamIndex)
						return self:_renderGameTeamVetoOverview(game, teamIndex)
					end)
				},
				Div{
					classes = {'match-bm-lol-game-veto-order-toggle', 'ppt-toggle-expand'},
					children = {
						Div{
							classes = {'general-collapsible-expand-button'},
							children = Div{children = {
								'Show Order &nbsp;',
								IconFa{iconName = 'expand'}
							}}
						},
						Div{
							classes = {'general-collapsible-collapse-button'},
							children = Div{children = {
								'Hide Order &nbsp;',
								IconFa{iconName = 'collapse'}
							}}
						}
					}
				},
				Div{
					classes = {'match-bm-lol-game-veto-order-list', 'ppt-hide-on-collapse'},
					children = {
						self:_renderGameTeamVetoOrder(game, 1),
						self:_renderGameTeamVetoOrder(game, 2),
					}
				}
			}
		}
	}
end

---@private
---@param game LoLMatchPageGame
---@param teamIndex integer
---@return Widget
function MatchPage:_renderGameTeamVetoOverview(game, teamIndex)
	return Div{
		classes = {'match-bm-lol-game-veto-overview-team'},
		children = {
			Div{
				classes = {'match-bm-game-veto-overview-team-header'},
				children = self.opponents[teamIndex].iconDisplay
			},
			Div{
				classes = {'match-bm-lol-game-veto-overview-team-veto'},
				children = {
					VetoRow{
						vetoType = 'pick',
						side = game.teams[teamIndex].side,
						vetoItems = Array.map(game.teams[teamIndex].picks, function (pick)
							return VetoItem{
								characterIcon = self:getCharacterIcon(pick),
							}
						end)
					},
					VetoRow{
						vetoType = 'ban',
						vetoItems = Array.map(game.teams[teamIndex].bans, function (ban)
							return VetoItem{
								characterIcon = self:getCharacterIcon(ban.character),
							}
						end)
					}
				}
			}
		}
	}
end

---@private
---@param game LoLMatchPageGame
---@param teamIndex integer
---@return Widget
function MatchPage:_renderGameTeamVetoOrder(game, teamIndex)
	local teamVetoGroups = game.vetoGroups[teamIndex]
	return Div{
		classes = {'match-bm-lol-game-veto-order-team'},
		children = {
			Div{
				classes = {'match-bm-lol-game-veto-order-team-header'},
				children = self.opponents[teamIndex].iconDisplay
			},
			Div{
				classes = {'match-bm-lol-game-veto-order-team-choices'},
				children = Array.map(teamVetoGroups or {}, function (vetoGroup)
					return VetoRow{
						vetoType = vetoGroup[1].type,
						side = game.teams[teamIndex].side,
						vetoItems = Array.map(vetoGroup, function (veto)
							return VetoItem{
								characterIcon = self:getCharacterIcon(veto.character),
								vetoNumber = veto.vetoNumber
							}
						end)
					}
				end)
			}
		}
	}
end

---@private
---@param game LoLMatchPageGame
---@return Widget[]
function MatchPage:_renderTeamStats(game)
	return {
		HtmlWidgets.H3{children = 'Team Stats'},
		Div{
			classes = {'match-bm-team-stats'},
			children = {
				Div{
					classes = {'match-bm-lol-team-stats-header'},
					children = {
						Div{
							classes = {'match-bm-lol-team-stats-header-team'},
							children = self.opponents[1].iconDisplay
						},
						Div{
							classes = {'match-bm-team-stats-list-cell'},
							children = self:isBestOfOne() and self:_buildGameResultSummary(game) or nil
						},
						Div{
							classes = {'match-bm-lol-team-stats-header-team'},
							children = self.opponents[2].iconDisplay
						}
					}
				},
				StatsList{
					finished = game.finished,
					data = {
						{
							icon = KDA_ICON,
							name = 'KDA',
							team1Value = Array.interleave({
								game.teams[1].kills,
								game.teams[1].deaths,
								game.teams[1].assists
							}, SPAN_SLASH),
							team2Value = Array.interleave({
								game.teams[2].kills,
								game.teams[2].deaths,
								game.teams[2].assists
							}, SPAN_SLASH)
						},
						{
							icon = GOLD_ICON,
							name = 'Gold',
							team1Value = game.teams[1].gold,
							team2Value = game.teams[2].gold
						},
						{
							icon = IconImage{imageLight = 'Lol stat icon tower.png', link = ''},
							name = 'Towers',
							team1Value = game.teams[1].objectives.towers,
							team2Value = game.teams[2].objectives.towers
						},
						{
							icon = IconImage{imageLight = 'Lol stat icon inhibitor.png', link = ''},
							name = 'Inhibitors',
							team1Value = game.teams[1].objectives.inhibitors,
							team2Value = game.teams[2].objectives.inhibitors
						},
						{
							icon = IconImage{imageLight = 'Lol stat icon grub.png', link = ''},
							name = 'Void Grubs',
							team1Value = game.teams[1].objectives.grubs,
							team2Value = game.teams[2].objectives.grubs
						},
						{
							icon = IconImage{imageLight = 'Lol stat icon herald.png', link = ''},
							name = 'Rift Heralds',
							team1Value = game.teams[1].objectives.heralds,
							team2Value = game.teams[2].objectives.heralds
						},
						{
							icon = IconImage{imageLight = 'Lol stat icon atakhan.png', link = ''},
							name = 'Atakhan',
							team1Value = game.teams[1].objectives.atakhans,
							team2Value = game.teams[2].objectives.atakhans
						},
						{
							icon = IconImage{imageLight = 'Lol stat icon dragon.png', link = ''},
							name = 'Dragons',
							team1Value = game.teams[1].objectives.dragons,
							team2Value = game.teams[2].objectives.dragons
						},
						{
							icon = IconImage{imageLight = 'Lol stat icon baron.png', link = ''},
							name = 'Barons',
							team1Value = game.teams[1].objectives.barons,
							team2Value = game.teams[2].objectives.barons
						},
					}
				}
			}
		}
	}
end

---@private
---@param game LoLMatchPageGame
---@return Widget[]
function MatchPage:_renderPlayersPerformance(game)
	return {
		HtmlWidgets.H3{children = 'Player Performance'},
		Div{
			classes = {'match-bm-players-wrapper'},
			children = {
				self:_renderTeamPerformance(game, 1),
				self:_renderTeamPerformance(game, 2)
			}
		}
	}
end

---@private
---@param game LoLMatchPageGame
---@param teamIndex integer
---@return Widget
function MatchPage:_renderTeamPerformance(game, teamIndex)
	return Div{
		classes = {'match-bm-players-team'},
		children = WidgetUtil.collect(
			Div{
				classes = {'match-bm-players-team-header'},
				children = self.opponents[teamIndex].iconDisplay
			},
			Array.map(game.teams[teamIndex].players, function (player)
				return self:_renderPlayerPerformance(game, teamIndex, player)
			end)
		)
	}
end

---@private
---@param game LoLMatchPageGame
---@param teamIndex integer
---@param player table
---@return Widget
function MatchPage:_renderPlayerPerformance(game, teamIndex, player)
	return Div{
		classes = {'match-bm-players-player match-bm-players-player--col-1'},
		children = {
			Div{
				classes = {'match-bm-lol-players-player-details'},
				children = {
					PlayerDisplay{
						characterIcon = self:getCharacterIcon(player.character),
						characterName = player.character,
						side = game.teams[teamIndex].side,
						roleIcon = IconImage{
							imageLight = 'Lol role ' .. player.role .. ' icon darkmode.svg',
							caption = mw.getContentLanguage():ucfirst(player.role),
							link = ''
						},
						playerLink = player.player,
						playerName = player.displayName or player.player
					},
					MatchPage._buildPlayerLoadout(player)
				}
			},
			Div{
				classes = {'match-bm-players-player-stats match-bm-players-player-stats--col-4'},
				children = {
					PlayerStat{
						title = {KDA_ICON, 'KDA'},
						data = Array.interleave({
							player.kills, player.deaths, player.assists
						}, SPAN_SLASH)
					},
					PlayerStat{
						title = {
							IconImage{
								imageLight = 'Lol stat icon cs.png',
								caption = 'CS',
								link = ''
							},
							'CS'
						},
						data = player.creepscore
					},
					PlayerStat{
						title = {GOLD_ICON, 'Gold'},
						data = MatchPage.abbreviateNumber(player.gold)
					},
					PlayerStat{
						title = {
							IconFa{iconName = 'damage', additionalClasses = {'fa-flip-both'}},
							'Damage'
						},
						data = player.damagedone
					}
				}
			}
		}
	}
end

---@private
---@param props {prefix: string, name: string, caption: string?}
---@return Widget
function MatchPage._generateLoadoutImage(props)
	return IconImage{
		imageLight = props.prefix .. ' ' .. props.name .. '.png',
		caption = props.caption or props.name,
		link = '',
		size = LOADOUT_ICON_SIZE,
	}
end

---@private
---@param runeName string
---@return Widget
MatchPage._generateRuneImage = FnUtil.memoize(function (runeName)
	return MatchPage._generateLoadoutImage{prefix = 'Rune', name = runeName}
end)

---@private
---@param spellName string
---@return Widget
MatchPage._generateSpellImage = FnUtil.memoize(function (spellName)
	return MatchPage._generateLoadoutImage{prefix = 'Summoner spell', name = spellName}
end)

---@private
---@param itemName string
---@return Widget
MatchPage._generateItemImage = FnUtil.memoize(function (itemName)
	local isDefaultItem = itemName == DEFAULT_ITEM
	return MatchPage._generateLoadoutImage{
		prefix = 'Lol item',
		name = itemName,
		caption = isDefaultItem and 'Empty' or itemName,
	}
end)

---@private
---@param player table
---@return Widget
function MatchPage._buildPlayerLoadout(player)
	return Div{
		classes = {'match-bm-lol-players-player-loadout'},
		children = {
			Div{
				classes = {'match-bm-lol-players-player-loadout-rs-wrap'},
				children = {
					Div{
						classes = {'match-bm-lol-players-player-loadout-rs'},
						children = Array.map(
							{player.runeKeystone, player.runes.secondary.tree},
							MatchPage._generateRuneImage
						)
					},
					Div{
						classes = {'match-bm-lol-players-player-loadout-rs'},
						children = Array.map(player.spells, MatchPage._generateSpellImage)
					}
				}
			},
			Div{
				classes = {'match-bm-lol-players-player-loadout-items'},
				children = {
					Div{
						classes = {'match-bm-lol-players-player-loadout-item'},
						children = Array.map(Array.sub(player.items, 1, 3), MatchPage._generateItemImage)
					},
					Div{
						classes = {'match-bm-lol-players-player-loadout-item'},
						children = Array.map(Array.sub(player.items, 4, 6), MatchPage._generateItemImage)
					}
				}
			}
		}
	}
end

function MatchPage.getPoweredBy()
	return 'SAP logo.svg'
end

return MatchPage
