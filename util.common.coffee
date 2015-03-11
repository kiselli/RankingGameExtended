Plugin = require 'plugin'
{tr} = require 'i18n'

exports.qToQuestion = (q) ->
	if typeof q is 'string'
		tr("Who") + ' ' + q.charAt(0).toLowerCase() + q.slice(1) + '?'

exports.selfRankToText = (nr) ->
	if nr is 1
		tr("1st")
	else if nr is 2
		tr("2nd")
	else if nr is 3
		tr("3rd")
	else if nr is 4 and Plugin.users.count().get() is 4
		tr("4th")
	else if nr is 4
		tr("Middle rank")
	else if nr is 5
		tr("Bottom rank")
	else
		'?'

exports.scoring = -> [10, 4, 1, 0]

# determines duration of the round started at 'currentTime'
exports.getRoundDuration = (currentTime) ->
	return false if !currentTime

	duration = 6*3600 # six hours
	while 22 <= (hrs = (new Date((currentTime+duration)*1000)).getHours()) or hrs <= 9
		duration += 6*3600

	duration

exports.questions = -> [
	# WARNING: indices are used, so don't remove items from this array (and add new questions at the end)
	# Use null as second array entry if you want to stop a question from being selected (or true if 18+)
	["drinks the most alcohol", true]
	["sleeps the most", false]
	["has had the most bed partners", true]
	["was spoiled as a child", false]
	["makes the most money", false]
	["is the smartest", false]
	["is the fastest in the 100m sprint", false]
	["is easiest to provoke", false]
	["eats the most", false]
	["lives unhealthiest", false]
	["is the funniest", false]
	["is the most charismatic", false]
	["is the most bossy", false]
	["lives the most interesting life", false]
	["does unexpected things", false]
	["is a dreamer", false]
	["should take a bath more often", null]
	["has seen the most movies", false]
	["knows most about sports", false]
	["is an introvert", false]
	["lost his/her virginity the earliest", true]
	["watches most porn", true]
	["is the most optimistic", false]
	["is easiest to embarrass", false]
	["has the best body", true]
	["is the most nerdy", false]
	["dresses best", false]
	["most often helps other people", false]
	["does things without thinking", false]
	["is happiest", false]
	["has the wildest lifestyle", false]
	["talks most", false]
	["listens best", false]
	["has the most energy", false]
	["gossips the most", false]
	["tells the best stories", false]
	["is the best dancer", false]
	["cleans most often", false]
	["would be the first to undergo plastic surgery", false]
	["will live the longest", false]
	["shouts at his/her computer", false]
	["is the most ambitious", false]
	["is the most superstitious", false]
	["is the most eco friendly", false]
	["never talks about feelings", false]
	["weeps most during movies", false]
	["would be the first to go skinny dipping", false]
	["is the most romantic", false]
	["works the hardest", false]
	["is the most creative", false]
	["has read the most books", false]
	["wears the oldest underwear", false]
	["broke the most hearts", false]
	["looks worst after a bad night", false]
	["is the perfect son/daughter-in-law", false]
	["dislikes talking on the phone", false]
	["has the most outspoken opinion", false]
	["would win in a fight", false]
	["has the most bad-hair-days", false]
	["is the best singer", false]
	["is most elitist", false]
	["is least politically correct", false]
	["knows most about sex", true]
	["is the biggest flirt", false]
	["would you trust with your life", null]
	["gets most attention from the opposite sex", false]
	["gets up the earliest", false]
	["could be a pornstar", true]
	["is probably an alien", false]
	["is probably a secret agent", false]
	["might have the most 18+ toys", true]
	["has tried the most drugs", true]
	["is the alpha male/female", false]
	["is a future nobel prize winner", false]
	["has broken the most promises", false]
	["is always late", false]
	["is craziest", false]
	["craves the most attention", false]
	["is the most philosophical", false]
	["will become most famous", false]
	["is the best liar", false]
	["would survive the zombie apocalypse", false]
	["has the most pleasant voice", false]
	["is a hipster", false]
	["is most addicted to his phone", false]
	["is the worst driver", false]
	["is most forgetful", false]
	["is the best cook", false]
	["has the worst taste in music", false]
	["spends too much money", false]
	["has travelled the most", false]
	["would make the best salesman", false]
	["types fastest on a phone", false]
	["watches too much TV", false]
	["watches the worst TV shows", false]
	["is clumsiest?", false]
	["could seduce anyone", true]
	["has taken nude pictures of him or herself", true]
	["is most likely to have kinky fetishes", true]
	["would pay for sex", true]
	["would be in for a threesome", true]
	["is most bi-curious", true]
	["has the dirtiest mind", true]
	# WARNING: always add new questions to the end of this array
]
