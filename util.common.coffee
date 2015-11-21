Plugin = require 'plugin'
Db = require 'db'
{tr} = require 'i18n'

exports.qToQuestion = (q) ->
	return q
	# if typeof q is 'string'
	# 	tr("Who") + ' ' + q.charAt(0).toLowerCase() + q.slice(1) + '?'

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
		#duration += Math.round(Math.random()*6*3600) # delay randomly

	duration

exports.questions = ->
	if !Db.shared.get
		return []
	rv = []
	Db.shared.iterate 'questions', (q) !->
		q = q.get()
		log q
		rv.push([q.question, q.inappropriate])
	# questions =  Db.shared.get('questions')
	# # if questions
	# # 	return questions.map (question) -> [question.question, question.inappropriate]
	# # else
	# if questions
	# 	question.iterate
	return rv


exports.initalquestions = -> [
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
	["is most addicted to his/her phone", false]
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
	["is clumsiest", false]
	["could seduce anyone", true]
	["has taken nude pictures of him or herself", true]
	["is most likely to have kinky fetishes", true]
	["would pay for sex", true]
	["would be in for a threesome", true]
	["is most bi-curious", true]
	["has the dirtiest mind", true]
	["is most confident", false]
	["gives the most money to charity", false]
	["would be the first to dye his/her hair", false]
	["has probably cheated on exams", false]
	["would be the first to buy a Ferrari", false]
	["looks older than he/she really is", false]
	["can eat without gaining weight", false]
	["is most likely to become a monk/nun", false]
	["would be in for interracial sex", null]
	["could be a time traveller", null]
	["is funniest when drunk", false]
	["is the bravest", false]
	["takes most selfies", false]
	["is always getting into trouble", false]
	["eats junk food most often", false]
	["is most persuasive", false]
	["could be a great actor/actress", false]
	["would have sex on the first date", true]
	["would never harm anyone", false]
	["has the most infectious smile", false]
	["has the most life experience", false]
	["gives the best advice", false]
	["should rule the world", false]
	["has the most beautiful name" ,false]
	["is or would be the best parent", false]
	["laughs most", false]
	["was sent back from the future", false]
	["would have made a great hippy", false]
	["is probably hungover right now", true]
	["has the worst sense of direction", false]
	["secretly reads horoscopes", false]
	["is most addicted to social media", false]
	["is the best public speaker", false]
	["has the biggest vocabulary", false]
	["thinks rules are to be broken", false]
	["should see his/her family more often", false]
	["is/was the teacher’s favourite", false]
	["is most easily stressed", false]
	["is the biggest party animal", false]
	["knows most about celebrity gossip", false]
	["is the master of obscure facts", false]
	["is most dependent upon technology", false]
	["can handle every situation", false]
	["is the best handy(wo)man", false]
	["has most musical talent", false]
	["endlessly postpones tasks", false]
	["enjoys sci-fi most", false]
	["should write a book", false]
	["has the strangest habits", false]
	["has the most tech gadgets", false]
	["is the biggest chickflick-fan", false]
	["knows most plants by name", false]
	["would be the best companion on a deserted island", false]
	["owns most jewelry", false]
	["looks in the mirror most often", false]
	["would be first to sell his/her soul to the devil", false]
	["is most stubborn", false]
	["usually stays until late", false]
	["has the most shoes", false]
	["is the biggest nitpicker", false]
	["is the biggest show-off", false]
	["is the biggest animal lover", false]
	["refuses to deviate from the plan", false]
	["has the most beautiful eyes", false]
	["would be first to get a(nother) tattoo", false]
	["believed in santa clause the longest", false]
	["knows most about cars", false]
	["wears the tightest jeans", false]
	["is the best swimmer", false]
	["likes to annoy people", false]
	["is the most picky eater", false]
	["wears expensive brands", false]
	["uses movie quotes most often", false]
	["would lead the resistance in a war", false]
	["is most in touch with his/her inner child", false]
	["finds it most difficult to say 'no'", false]
	["looks most like a Bond villain", false]
	["sleeps naked", true]
	["has the best reflexes", false]
	["is the most well-connected", false]
	["can be trusted with superpowers", null]
	["is telepathic", false]
	["imagines people naked", true]
	["is loudest", false]
	["believes in life after death", false]
	["is nosiest", false]
	["should buy a new phone", false]
	["gets bored with things quickly", false]
	["is most sophisticated", false]
	["is most conservative", false]
	["is grumpy in the morning", false]
	["would be the best police officer", false]
	["would be happiest as a truck driver", false]
	["wouldn't mind working night shifts", false]
	["might have been an emperor in a previous life", false]
	["doesn't mind doing dirty work", false]
	["would be happiest as a farmer", false]
	["dislikes office jobs most", false]
	["was the most annoying know-it-all as a child", false]
	["is most comfortable wearing high heels", false]
	["would be the best computer programmer", false]
	["is most afraid of heights", false]
	["is most afraid of spiders", false]
	["has the most patience", false]
	["likes Mondays best", false]
	["is most nostalgic", false]
	["has a calming influence on people", false]
	["eats just about anything", false]
	["can be trusted with a big secret", false]
	["has climbed the most trees", false]
	["talks about boobs most often", true]
	["is the biggest Disney fan", false]
	["was/is most popular in school", false]
	["will always want a bigger house", false]
	["is best at solving a rubix cube", false]
	["is the best babysitter", false]
	["is the best text writer", false]
	["is the best at playing pool", false]
	["will be in the history books", false]
	["keeps a baseball bat under the bed", false]
	["swears the most", false]
	["needs the least sleep", false]
	["wanted to be a astronaut when he/she was little", false]
	["has the most secret admirers", false]
	["loves Christmas the most", false]
	["is the biggest daredevil", false]
	["is the best photographer", false]
	["would be the first to buy a hot tub", false]
	["would be the first to buy an electric bicycle", false]
	["is the best snowboarder/skier", false]
	["knows how to dance the Macarena", false]
	["knows how to milk a cow", false]
	["knows how to sail a boat", false]
	["knows how to wield a sword", false]
	["would be first to start a restaurant", false]
	["would be first to start a bed & breakfast", false]
	["would be first to move abroad", false]
	["wears sunglasses indoors to look cool", false]
	["hates rollercoasters the most", false]
	["wishes cell phones were never invented", false]
	["wishes the internet was never invented", false]
	["cares most about Valentine's Day", false]

	# WARNING: always add new questions to the end of this array
]
