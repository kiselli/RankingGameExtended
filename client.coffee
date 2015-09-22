Db = require 'db'
Dom = require 'dom'
Event = require 'event'
Modal = require 'modal'
Icon = require 'icon'
Loglist = require 'loglist'
Obs = require 'obs'
Plugin = require 'plugin'
Page = require 'page'
Server = require 'server'
Ui = require 'ui'
Form = require 'form'
Time = require 'time'
Colors = Plugin.colors()
Photo = require 'photo'
Social = require 'social'
Util = require 'util'
{tr} = require 'i18n'


# shared: results (server-side calculated), scores
# personal: rankings

exports.render = !->
	rounds = Db.shared.ref 'rounds'
	if Plugin.users.count().get() < 3
		Ui.emptyText tr("You need at least 3 members in your happening to play the Ranking Game")
		return
	else if roundId = Page.state.get(0)
		if roundId is 'competition' or Page.state.get(1) is 'competition'
			renderCompetition()
			return

		round = rounds.ref(roundId)

		if Page.state.get(1) is 'personal'
			renderRankPersonal round
		else if round.get('results')
			renderRoundResults round
		else
			renderRound round
		return

	Page.setFooter
		label: tr("Know Thyself Competition")
		action: !-> Page.nav ['competition']

	Obs.observe !->
		maxId = Db.shared.get('rounds', 'maxId')
		winnerId = Db.shared.get('rounds', maxId, 'results')?
		questionIds = Db.shared.get('questionIds')||[]
		if maxId and winnerId and !questionIds.length
			Ui.emptyText tr("Out of questions, wait for new ones!")

		Ui.list !->
			if maxId and winnerId and questionIds.length
				Ui.item !->
					Dom.div !->
						Dom.style width: '40px', height: '40px', marginRight: '10px', Box: 'center middle'
						Icon.render data: 'fastforward', style: { display: 'block' }, size: 34

					Dom.div !->
						Dom.style Flex: 1, color: Plugin.colors().highlight, fontWeight: 'bold'
						Dom.text tr("Pick the next question.."), !->

					Dom.onTap !->
						Modal.show tr("Pick the next question"), !->
							Dom.div !->
								Dom.style margin: '-12px'
								if !Db.shared.get('questionIds')
									Ui.emptyText tr("Another member just picked a question, sorry!")
								else
									questions = Util.questions()
									questionIds.forEach (qId) !->
										log 'qId', qId, questions[qId]
										Ui.item !->
											Dom.text Util.qToQuestion(questions[qId][0])
											Dom.onTap !->
												Server.call 'newRound', qId
												Modal.remove()

						, null
						, ['cancel', tr("Cancel")]

			rounds.observeEach (round) !->
				winnerId = round.get('results', 1)
				ranking = Db.personal.ref('rankings', round.key()) || Obs.create()
				hasRanked = ranking.get(1)
				hasResults = round.get('results')?
				q = round.get('question')

				Ui.item !->
					if winnerId
						# this round has a winner
						Ui.avatar Plugin.userAvatar(winnerId), style: marginRight: '10px'
						resultTime = Db.shared.get('rounds', +round.key()+1, 'time') || 0
							# note how we're looking at the next round's start-time for this
						roundColor = if resultTime and Event.isNew(resultTime) then '#5b0' else 'inherit'
						Dom.div !->
							Dom.style Flex: 1, color: roundColor
							Dom.b Plugin.userName winnerId
							Dom.div q
						Dom.onTap !->
							Page.nav [round.key()]
					else if hasResults
						# this round has no results
						Dom.div !->
							Dom.style width: '40px', height: '40px', marginRight: '10px', Box: 'center middle'
							Icon.render data: 'warn', color: '#aaa', style: { display: 'block' }, size: 34

						Dom.div !->
							Dom.style Flex: 1, color: '#aaa'
							Dom.b !->
								Dom.text Util.qToQuestion(q)
							Dom.div !->
								if 1441206000 < round.get('time') < 1441378800 # period of two days since 2015-09-02 17:00
									Dom.text tr("No results (technical problem)")
								else
									Dom.text tr("No results")
					else
						# this round is current and has been ranked, or needs to be ranked
						Dom.div !->
							Dom.style Box: 'center middle', Flex: true, padding: '8px 8px 8px 8px', margin: '-8px -8px -8px -8px'
							Dom.div !->
								Dom.style width: '40px', height: '40px', marginRight: '10px', Box: 'center middle'
								Icon.render
									data: (if hasRanked then 'clock2' else 'new')
									color: (if hasRanked then '#aaa' else null)
									style: { display: 'block' }
									size: 34

							Dom.div !->
								Dom.style Flex: 1
								Dom.b !->
									Dom.style color: (if !hasRanked then Colors.highlight else 'inherit')
									Dom.text Util.qToQuestion(q)
								Dom.div !->
									if pickedBy = round.get('by')
										Dom.text tr("Picked by %1.", Plugin.userName(pickedBy)) + ' '
									Dom.text (if hasRanked then tr("Results") else tr("Voting closes")) + ' '
									Time.deltaText(Db.shared.get('next'))
									Dom.text '.'

							Dom.onTap !->
								Page.nav [round.key()]

						if Plugin.userId() is Plugin.ownerId() or Plugin.userIsAdmin()
							Dom.div !->
								Dom.style borderLeft: '1px solid #ccc', padding: '10px 14px', marginLeft: '8px'
								Icon.render data: 'ok'
								Dom.onTap !->
									Server.call 'getVoteCnt', (voteCnt) !->
										require('modal').confirm tr("Close round early?"), !->
											Dom.userText tr("The group app owner and/or admin can close the round at any time.\n\n**The current round has had %1 vote|s.**", voteCnt),
										, !->
											Server.call('closeRound')
										, tr("Close round")


					Event.renderBubble [round.key()], style: marginLeft: '4px'

			, (round) -> # skip the maxId key
				if +round.key()
					-round.key()

renderCompetition = !->
	Page.setTitle tr("Know Thyself Competition")

	if !Db.shared.get('competition')
		Ui.emptyText tr("No rankings have taken place yet")
	else
		Ui.list !->
			Db.shared.observeEach 'competition', (score) !->
				Ui.item !->
					userId = +score.key()
					if userId is Plugin.userId()
						Dom.style fontWeight: 'bold'
					Ui.avatar Plugin.userAvatar(userId), onTap: !-> Plugin.userInfo(userId)
					Dom.div !->
						Dom.style marginLeft: '10px', Flex: 1
						Dom.text Plugin.userName(userId)
					Dom.div !->
						Dom.style fontSize: '150%'
						Dom.text score.get()
			, (score) ->
				-score.get()
		Dom.div !->
			Dom.style padding: '6px', textAlign: 'center', color: '#888', fontSize: '85%'
			Dom.userText tr("Points can be earned by correctly predicting\nyour own ranking each round")


renderQuestion = (question) !->
	Dom.div !->
		Dom.style fontSize: '150%', fontWeight: 'bold', textShadow: '0 1px 0 #fff', textAlign: 'center', padding: '4px 10px 10px 10px'
		Dom.text Util.qToQuestion(question)

renderRankPersonal = (round) !->
	userCnt = Plugin.users.count().get()
	roundId = round.key()
	Page.setTitle tr("Know Thyself")
	Page.setSubTitle tr("Your rank")
	renderQuestion round.get('question')

	if round.get('results')?
		Ui.emptyText tr("Voting just closed, sorry!")
		return

	self = Db.personal.get('rankings', roundId, 'self') || 0
	selfRank = Obs.create(self)
	Dom.section !->
		Dom.style textAlign: 'center'
		Dom.h3 !->
			Dom.style fontSize: '130%'
			Dom.text tr("Predict your own rank")

		Dom.div !->
			Dom.style margin: '0px 5px 10px 5px', fontSize: '85%', color: '#888'
			Dom.userText tr("Do you know what people think of you?\nA better prediction results in more points!")

		Form.setPageSubmit (values) !->
			# not using values
			if !selfRank.get()
				Modal.show tr("Please select where you expect to be ranked")
				return

			Server.sync 'rankSelf', roundId, selfRank.get()
			Page.back(2)
		, true

		# uses ranking, roundId and userCnt from scope
		renderOwnRank = (nr) !->
			Dom.div !->
				Dom.style
					minWidth: '60px'
					height: '60px'
					margin: '5px'
					lineHeight: '60px'
					border: '1px solid gray'
					borderRadius: '60px'
					fontSize: '150%'
					display: 'inline-block'
					color: (if selfRank.get() is nr then '#fff' else 'inherit')
					backgroundColor: (if selfRank.get() is nr then '#bbb' else '#eee')
				Dom.span !->
					Dom.style padding: '0 12px'
					if nr >= 4 and userCnt>=5
						Dom.style display: 'inline-block', minWidth: '180px'
						Dom.text Util.selfRankToText(nr)
					else
						Dom.text nr
						Dom.span !->
							Dom.style fontSize: '80%'
							Dom.text (if nr is 1 then 'st' else if nr is 2 then 'nd' else if nr is 3 then 'rd' else 'th')
				Dom.onTap !->
					selfRank.set(nr)

		for nr in [1..3]
			renderOwnRank nr

		if userCnt>=4
			for nr in [4..Math.min(5, userCnt)]
				Dom.div !->
					renderOwnRank nr


renderRound = (round) !->
	roundId = round.key()
	log 'renderRound', roundId
	userCnt = Plugin.users.count().get()
	topCnt = Math.min(3, userCnt-1)

	Page.setTitle tr("Rank members")
	Page.setSubTitle tr("Top-%1", topCnt)

	renderQuestion round.get('question')
	if round.get('results')?
		Ui.emptyText tr("Voting just closed, sorry!")
		return

	Dom.section !->
		Dom.style textAlign: 'center'
		Dom.h3 !->
			Dom.style fontSize: '130%', marginTop: 0
			Dom.text tr("Rank your top-%1", topCnt)

		step = Obs.create(1)
		ranking = Obs.create()
		current = Db.personal.get('rankings', roundId)
		ranking.set current if current

		hiddenForm = Form.hidden 'submitTrigger'

		Form.setPageSubmit (values) !->
			# test if all are set
			if !ranking.get(1) and !ranking.get(2) and !ranking.get(3) and current?[1]
				Modal.confirm tr("This will remove your vote for this round."), !->
					Server.sync 'rankTop', roundId, 'remove'
					Page.back()
				return

			if !ranking.get(1) or !ranking.get(2) or (topCnt isnt 2 and !ranking.get(3))
				Modal.show tr("Please rank your top-%1", topCnt)
				return

			# we're not using form-supplied values
			values =
				1: ranking.get(1)
				2: ranking.get(2)
				3: ranking.get(3)
			Server.sync 'rankTop', roundId, values, !->
				Db.personal.merge 'rankings', roundId, values
			Page.nav [roundId, 'personal']

		size = if userCnt > 9 then 58 else 86
		Plugin.users.observeEach (user) !->
			Dom.div !->
				Dom.style
					Box: 'center middle'
					display: 'inline-block'
					position: 'relative'
					padding: '6px 4px'
					margin: '1px'
					borderRadius: '2px'
					width: size+'px'

				Ui.avatar Plugin.userAvatar(user.key()),
					size: size
					style:
						display: 'inline-block'
						margin: '0 0 1px 0'

				ranks = [ranking.get(1), ranking.get(2), ranking.get(3)]
				if (ranked = ranks.indexOf(+user.key())) >= 0
					Dom.div !->
						Dom.style
							position: 'absolute'
							left: '4px'
							top: '6px'
							width: (size+2)+'px'
							height: (size+2)+'px'
							borderRadius: (size+2)+'px'
							lineHeight: (size+2)+'px'
							backgroundColor: 'rgba(0, 0, 0, 0.5)'
							fontWeight: 'bold'
							fontSize: '250%'
							color: '#fff'
						Dom.text ranked+1

				Dom.div !->
					Dom.style
						overflow: 'hidden'
						textOverflow: 'ellipsis'
						whiteSpace: 'nowrap'
						fontSize: '90%'
					Dom.text Plugin.userName(user.key())

				Dom.onTap !->
					ranks = [ranking.get(1), ranking.get(2), ranking.get(3)]
					if (ranked = ranks.indexOf(+user.key())) >= 0
						# unselect
						for i in [ranked+1..3]
							ranking.set i, null
						hiddenForm.value null unless ranking.get(1)?
					else
						# select
						maxRanked = 0
						for i in [1..topCnt]
							maxRanked = i if ranking.get(i)
						ranking.set (if maxRanked is topCnt then topCnt else maxRanked+1), +user.key()
						hiddenForm.value true
		, (user) ->
			Plugin.userName(user.key()) if +user.key() isnt Plugin.userId()

renderRoundResults = (round) !->
	Page.setTitle tr("Ranking results")
	Event.showStar tr("this round")

	Dom.style padding: 0 # style the main element
	Dom.div !->
		Dom.style backgroundColor: '#f8f8f8', borderBottom: '2px solid #ccc', padding: '8px 0 0 0'

		renderQuestion round.get('question')

		Dom.div !->
			Dom.style padding: '5px 5px 0 5px'

			userCnt = Plugin.users.count().get()
			results = round.get('results')
			if !results
				Dom.div tr("Not enough votes")
			else
				myRank = 0
				for nr in [1..(if userCnt is 4 then 4 else 3)] then do (nr) !->
					userId = results[nr]
					if (nr is 4 and Plugin.userId() in userId) or userId is Plugin.userId()
						myRank = nr
					Ui.item !->
						Ui.avatar Plugin.userAvatar(userId), onTap: !-> Plugin.userInfo(userId)
						Dom.div !->
							Dom.style Flex: 1, marginLeft: '10px'
							Dom.b Plugin.userName(userId)
							Dom.div !->
								if nr is 4
									Dom.userText tr("%1 place", Util.selfRankToText(nr))
								else
									Dom.userText tr("%1 place with %2%%", Util.selfRankToText(nr), round.get('percs', nr))

				for nr in [4..5] when userCnt>4
					continue if !results[nr]
					userIds = results[nr]
					userNames = []
					for userId in userIds
						userNames.push Plugin.userName(userId)
						myRank = nr if userId is Plugin.userId()

					if userNames.length
						Ui.item !->
							Dom.img !->
								Dom.prop src: Plugin.resourceUri("rank-#{if nr is 4 then 'middle' else 'bottom'}.png")
								Dom.style
									width: '24px'
									height: '24px'
									margin: '8px'
							Dom.div !->
								Dom.style Flex: 1, marginLeft: '14px'
								Dom.b userNames.join(', ')
								Dom.div Util.selfRankToText(nr)

				myRanking = Db.personal.get 'rankings', round.key()
				Ui.item !->
					Dom.style Box: 'vertical middle', textAlign: 'center', color: '#aaa', fontSize: '85%', borderBottom: 'none', padding: '12px 8px'
					Dom.div !->
						Dom.style color: Colors.highlight, textTransform: 'uppercase', fontWeight: 'bold'
						Dom.text tr("Know Thyself Competition")

					if myRanking and myRanking[1]
						log 'myRank, myRanking', myRank, myRanking['self']
						scoring = Util.scoring()
						score = scoring[Math.abs(myRank-myRanking['self'])]
						Dom.userText tr("You won %1 point|s by predicting to be ranked '%2'", score, Util.selfRankToText(myRanking['self']))

					Dom.onTap !-> Page.nav [round.key(), 'competition']

				if myRanking and myRanking[1]
					Dom.div !->
						Dom.style
							padding: '4px'
							margin: '0 -5px'
							color: '#999'
							backgroundColor: '#ddd'
							textAlign: 'center'
							fontSize: '85%'
							textShadow: '0 1px 0 #fff'
						Dom.text tr("%1 |person|people voted", round.get('votes'))

	Social.renderComments round.key()


exports.renderSettings = !->
	###
	Ui.button tr("new round"), !->
		Server.call 'newRound'
	Ui.button tr("close round"), !->
		Server.call 'closeRound'
	###
	Dom.div !->
		Dom.style margin: '16px -8px'

		Form.sep()
		Form.check
			text: tr("Allow 18+ topics")
			name: 'adult'
			value: if Db.shared then Db.shared.func('adult')
		Form.sep()
