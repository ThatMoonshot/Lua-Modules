---
-- @Liquipedia
-- wiki=arenafps
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CONTENT = {
	usefulArticles = {
		heading = 'Useful Articles',
		body = '{{Liquipedia:Useful Articles}}',
		padding = true,
		boxid = 1503,
	},
	wantToHelp = {
		heading = 'Want To Help?',
		body = '{{Liquipedia:Want_to_help}}',
		padding = true,
		boxid = 1504,
	},
	transfers = {
		heading = 'Transfers',
		body = '{{Transfer List|limit=15}}\n<div style{{=}}"display:block; text-align:center; padding:0.5em;">\n' ..
			'<div style{{=}}"display:inline; float:left; font-style:italic;">\'\'[[#Top|Back to top]]\'\'</div>\n' ..
			'<div style{{=}}"display:inline; float:right;" class="plainlinks smalledit">' ..
			'&#91;[{{FULLURL:Player Transfers/{{Current term}}|action=edit}} edit]&#93;</div>\n' ..
			'<div style{{=}}"white-space:nowrap; display:inline; margin:0 10px font-size:15px; font-style:italic;">' ..
			'[[Portal:Transfers|See more transfers]]<span style="font-style:normal; padding:0 5px;">&#8226;</span>' ..
			'[[Transfer query]]<span style{{=}}"font-style:normal; padding:0 5px;">&#8226;</span>' ..
			'[[lpcommons:Special:RunQuery/Transfer|Input Form]]' ..
			'<span style="font-style:normal; padding:0 5px;">&#8226;</span>' ..
			'[[Portal:Rumours|Rumours]]</center></div>\n</div>',
		boxid = 1509,
	},
	thisDay = {
		heading = 'This day in Arena FPS <small id="this-day-date" style = "margin-left: 5px">' ..
			'({{#time:F}} {{Ordinal|{{#time:j}}}})</small>',
		body = '{{Liquipedia:This day}}',
		padding = true,
		boxid = 1510,
	},
	specialEvents = {
		noPanel = true,
		body = '{{Liquipedia:Special Event}}',
	},
	filterButtons = {
		noPanel = true,
		body = '<div style{{=}}"width:100%;margin-bottom:8px;">' ..
			'{{#invoke:Lua|invoke|module=FilterButtons|fn=getFromConfig}}</div>',
	},
	matches = {
		heading = 'Matches',
		body = '{{#invoke:Lua|invoke|module=Widget/Factory|fn=fromTemplate|widget=Match/Ticker/Container}}' ..
			'<div style{{=}}"white-space:nowrap; display: block; margin:0 10px; ' ..
			'font-size:15px; font-style:italic; text-align:center;">[[Liquipedia:Matches|See more matches]]</div>',
		padding = true,
		boxid = 1507,
	},
	tournaments = {
		heading = 'Tournaments',
		body = '{{#invoke:Lua|invoke|module=Widget/Factory|fn=fromTemplate|widget=Tournaments/Ticker' ..
			'|upcomingDays=40|completedDays=40}}',
		padding = true,
		boxid = 1508,
	},
}

return {
	banner = {
		lightmode = 'Arenafps-lightmode.svg',
		darkmode = 'Arenafps-darkmode.svg',
	},
	metadesc = 'The Arena FPS esports wiki covering everything from players, teams and transfers, ' ..
		'to tournaments and results, maps, and weapons.',
	title = 'Arena FPS',
	navigation = {
		{
			file = 'Team Liquid at DH Winter 2017.jpg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'Rapha_at_Barcelona_KeenCon_2023.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'PGL Quake Champions Open 2018 Trophy.jpg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'CYpheR and Asdtroboy at DH Winter 2017.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = 'DreamHack Summer 2010.jpg',
			title = 'Statistics',
			link = 'Portal:Statistics',
		},
		{
			file = 'QL_Blood_Run.jpg',
			title = 'Maps',
			link = 'Portal:Maps',
			count = {
				method = 'CATEGORY',
				category = 'Maps',
			},
		},
		{
			file = 'Cover Quake Champions.jpg',
			title = 'Games',
			link = 'Portal:Games',
			count = {
				method = 'CATEGORY',
				category = 'Games',
			},
		},
	},
	layouts = {
		main = {
			{ -- Left
				size = 6,
				children = {
					{
						mobileOrder = 1,
						content = CONTENT.specialEvents,
					},
					{
						mobileOrder = 3,
						content = CONTENT.transfers,
					},
					{
						mobileOrder = 6,
						content = CONTENT.wantToHelp,
					},
				}
			},
			{ -- Right
				size = 6,
				children = {
					{
						mobileOrder = 2,
						children = {
							{
								children = {
									{
										noPanel = true,
										content = CONTENT.filterButtons,
									},
								},
							},
							{
								size = 6,
								children = {
									{
										noPanel = true,
										content = CONTENT.matches,
									},
								},
							},
							{
								size = 6,
								children = {
									{
										noPanel = true,
										content = CONTENT.tournaments,
									},
								},
							},
						},
					},
					{
						mobileOrder = 5,
						content = CONTENT.thisDay,
					},
					{
						mobileOrder = 4,
						content = CONTENT.usefulArticles,
					},
				},
			},
		},
	},
}