Timer = require 'timer'
Plugin = require 'plugin'
Db = require 'db'
Event = require 'event'
Util = require 'util'
{tr} = require 'i18n'

questions = Util.questions()
userCnt = Plugin.userIds().length
topCnt = Math.min(3, userCnt-1)

exports.getTitle = !-> # prevents title input from showing up when adding the plugin

exports.onInstall = exports.onConfig = (config) !->
	Db.shared.set 'adult', config.adult if config?

	if !Db.shared.get('rounds')
		newRound()
	else if maxId = Db.shared.get('rounds', 'maxId')
		if Db.shared.get('rounds', maxId, 'results')?
			newRound() # newest round should always be open (otherwise questions depleted)

exports.onUpgrade = !->
	if !Db.shared.get('rounds')
		newRound()
	else
		# Restart ranking games that exhausted all questions
		maxId = Db.shared.get('rounds', 'maxId')
		lastRoundTime = Db.shared.get('rounds', maxId, 'time')
		if lastRoundTime > 0 and lastRoundTime < (0|(Date.now()*.001) - 24*60*60)
			#newRound()
			Timer.set(Math.floor(Math.random()*6*3600*1000), 'newRound')
				# restart somewhere the next 6 hours

	### done
	if curId = Db.shared.get('rounds', 'maxId')
		curRoundTime = Db.shared.get('rounds', curId, 'time')
		roundDuration = Util.getRoundDuration(curRoundTime)
		stillDuration = curRoundTime+roundDuration-Plugin.time()
		if stillDuration <= 0
			newRound()
		else
			Timer.cancel()
			Timer.set stillDuration*1000, 'newRound'
			Timer.set (stillDuration-30*60)*1000, 'reminder'
			Db.shared.set 'next', curRoundTime+roundDuration
	###

exports.onJoin = !->
	if userCnt >= 3 and !Db.shared.get('rounds', 'maxId')
		newRound()

exports.client_closeRound = exports.closeRound = closeRound = !->
	maxId = Db.shared.get('rounds', 'maxId') || 0
	if maxId and !Db.shared.get('rounds', maxId, 'results')
		calcResults maxId

		# give users three questions to pick from for the next round
		questionIds = selectNewQuestions()
		if questionIds.length
			Db.shared.set 'questionIds', questionIds

exports.client_selectNewQuestions = selectNewQuestions = (single) ->
	maxId = Db.shared.get('rounds', 'maxId') || 0
	# find questions already used, select new one:
	used = []
	for i in [1..maxId]
		qid = Db.shared.get 'rounds', i, 'qid'
		used.push +qid

	allowAdult = Db.shared.get 'adult'
	available = []
	for q, nr in questions
		if +nr not in used and (allowAdult or q[1] is false) and q[1] isnt null
			available.push +nr

	amount = if single then 1 else 3
	selected = []
	while available.length and amount-->0
		rndPos = Math.floor(Math.random()*available.length)
		selected.push available[rndPos]
		available.splice(rndPos, 1)

	if selected.length is 0
		return -1 # no question found

	if single then selected[0] else	selected

exports.client_newRound = exports.newRound = newRound = (pickedQuestionId) !->
	return if userCnt < 3 or +Db.shared.get('next') is -1
		# -1 is for my plugins and master happenings
	maxId = Db.shared.get('rounds', 'maxId') || 0
	log 'maxId', maxId

	# only start a new round when a question still needs to be selected (so no round currently active)
	if pickedQuestionId?
		qIds = Db.shared.get('questionIds')
		return if !qIds or qIds.indexOf(pickedQuestionId)<0
		Db.shared.remove 'questionIds'

	# current round results should have been determined, but make sure
	if maxId and !Db.shared.get('rounds', maxId, 'results')
		calcResults maxId

	if pickedQuestionId?
		newQuestionId = pickedQuestionId
	else
		newQuestionId = selectNewQuestions(true) # select a single question randomly

	if newQuestionId>=0
		maxId = maxId + 1
		Db.shared.set 'rounds', 'maxId', maxId

		time = 0|(Date.now()*.001)
		Db.shared.set 'rounds', maxId,
			qid: newQuestionId
			by: Plugin.userId()
			question: questions[newQuestionId][0]
			time: time

		roundDuration = Util.getRoundDuration(time)

		Timer.cancel()
		if roundDuration > 3600
			Timer.set roundDuration*1000, 'closeRound'
			Timer.set (roundDuration-120*60)*1000, 'reminder'
			Db.shared.set 'next', time+roundDuration

		if !pickedQuestionId?
			Event.create
				text: "New ranking round: " + Util.qToQuestion(questions[newQuestionId][0])

exports.reminder = !->
	roundId = Db.shared.get('rounds', 'maxId')
	remind = []
	for userId in Plugin.userIds()
		rankings = Db.personal(userId).get 'rankings', roundId
		if !rankings or !rankings[1]
			remind.push userId

	if remind.length
		qId = Db.shared.get 'rounds', roundId, 'qid'
		time = 0|(Date.now()*.001)
		minsLeft = (Db.shared.get('next') - time) / 60
		if minsLeft<60
			leftText = tr("30 minutes")
		else
			leftText = tr("2 hours")

		if pickedBy = Db.shared.get('rounds', roundId, 'by')
			pickedByText = tr("Picked by %1, %2 left to vote!", Plugin.userName(pickedBy), leftText)
		else
			pickedByText = tr("%1 left to vote!", leftText)
		Event.create
			for: remind
			unit: 'remind'
			text: Util.qToQuestion(questions[qId][0]) + ' ' + pickedByText

exports.client_getVoteCnt = (cb) !->
	voteCnt = 0
	maxId = Db.shared.get('rounds', 'maxId')

	for userId in Plugin.userIds()
		rankings = Db.personal(userId).get 'rankings', maxId
		if rankings and rankings[1] and rankings[2]
			voteCnt++

	cb.reply voteCnt


calcResults = (roundId = false) !->
	roundId = roundId || Db.shared.get('rounds', 'maxId')
	log 'calculating result for round', roundId

	# calculate results here using personal data (we only take into account current users)
	scores = {}
	voteCnt = 0
	for userId in Plugin.userIds()
		# make sure everyone is represented
		if !scores[userId]?
			scores[userId] = 0

		rankings = Db.personal(userId).get 'rankings', roundId
		if rankings and rankings[1] and rankings[2]
			scores[rankings[1]] = (scores[rankings[1]]||0) + 3 # this max-score is used below as well!
			scores[rankings[2]] = (scores[rankings[2]]||0) + 2
			if rankings[3]
				scores[rankings[3]] = (scores[rankings[3]]||0) + 1
			voteCnt++

	Db.shared.set 'rounds', roundId, 'votes', voteCnt

	if !voteCnt
		log 'no scores', roundId
		Db.shared.set 'rounds', roundId, 'results', false
		return false

	results = []
	for userId, score of scores when voteCnt>0
		results.push([userId, score, score + (Math.random() * 0.5 - 0.25)])
			# some jitter is added to randomize same-score order

	results.sort (a, b) -> b[2] - a[2]
	resultsObj = { 1: 0, 2: 0, 3: 0 }
	percsObj = { 1: 0, 2: 0, 3: 0 }

	log 'sorted results', JSON.stringify(results)

	# top 3 (also works for top 2)
	for value, pos in results
		userId = +value[0]
		score = value[1]
		resultsObj[pos+1] = userId # one-based

		vCnt = voteCnt
		if (rankings = Db.personal(userId).get('rankings', roundId)) and rankings[1] and rankings[2]
			vCnt-- # this user voted as well, but couldn't have voted for him/herself

		percsObj[pos+1] = Math.round(score / (vCnt * 3) * 100)
			# this uses the max-score of 3 (see above as well) to calculate
			# the percentage of max possible points received
		break if pos is 2 # pos 0, 1, 2

	Db.shared.set 'rounds', roundId, 'percs', percsObj

	# now divide remaining 4...x over bucket 4 and 5
	resultsObj[4] = []
	resultsObj[5] = []

	if results.length is 4
		resultsObj[4].push(+results[3][0])
	else if results.length > 4
		resultCnt = results.length
		middle = 3+(resultCnt-4)/2
		best = {diff: resultCnt, pos: if results[3][1] then results.length else 3}
		for pos in [4...resultCnt] when results[pos-1][1] > results[pos][1]
			# the score is lower than the prev result
			if best.diff > (diff = Math.abs(pos-middle))
				# it's closer to the middle then the former best result
				best = {diff, pos}

		#resultsObj[4] = results.slice 3, best.pos-3
		#resultsObj[5] = results.slice best.pos

		#log 'best pos', best.pos
		for i in [3...best.pos] when 3<best.pos
			resultsObj[4].push(+results[i][0])
		for i in [best.pos...results.length] when best.pos<results.length
			resultsObj[5].push(+results[i][0])

	log 'resultsObj', JSON.stringify(resultsObj)
	Db.shared.set 'rounds', roundId, 'results', resultsObj

	# calculate personal score
	for userId in Plugin.userIds()
		self = Db.personal(userId).get 'rankings', roundId, 'self'
		curScore = Db.shared.get 'competition', userId

		if !curScore?
			# new user, initialize on 2 points per round score
			curScore = (roundId-1) * 2

		score = 2
		if self
			# participating user
			rank = 0
			for i in [1..5]
				if i>3
					rank = i if +userId in resultsObj[i]
				else
					rank = i if +userId is resultsObj[i]

			if rank
				diff = Math.min(3, Math.abs(rank - self))
				scoring = Util.scoring()
				score = scoring[diff]

		Db.shared.set 'competition', userId, curScore + score

	if results.length
		qid = Db.shared.get('rounds', roundId, 'qid')
		Event.create
			unit: 'round'
			text: Plugin.userName(resultsObj[1]) + ' ' + questions[qid][0] + '!'

exports.client_rankSelf = (roundId, self) !->
	self = +self
	return if Db.shared.get('rounds', roundId, 'results') or self not in [1..5]
		# round no longer active

	Db.personal().set 'rankings', roundId, 'self', self

exports.client_rankTop = (roundId, values) !->
	return if Db.shared.get('rounds', roundId, 'results') or !values[1] or !values[2] or (topCnt isnt 2 and !values[3])
		# round no longer active

	if values is 'remove'
		Db.personal().remove 'rankings', roundId
	else
		resObj =
			1: +values[1]
			2: +values[2]
			3: +values[3]
		Db.personal().merge 'rankings', roundId, resObj
