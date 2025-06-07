extends Node2D

@onready var button: Button = $Button

var tts_model: BaseTTSModel
var is_playing = false
var pos: int = 0
var chapter_list: Array = []
var tts_index: int = 0
var chapters: Array[String] = [
	"""
	Chapter 1 - 1 – I Am Busujima’s Step Brother
	Beep beep beep!
	Lifting my head, I stopped the alarm that tried to destroy my eardrums and opened my eyes. And as soon as I did so, I got confused.
	"Hmm..."
	I hummed as I stared up at the ceiling, my arms folded behind my head as I lay down on my bed. The ceiling was a little grey, the white paint starting to peel and flake away, and the light fitting looked like it had seen better days too.
	My bed was a standard single, small and firm. The pillow was lumpy and the blankets were scratchy, but I had grown accustomed to that over the years and hardly even noticed it anymore.
	It should be that way, but... This one was different. What I saw was a perfectly fine place with good condition. Pristine wall and soft mattress.
	Beside me, a naked girl slept soundly, her long hair a mess of tangles and knots. She was sprawled out, her arms wrapped around the pillow. She was beautiful and had large assets, but that didn't really matter to me.
	Right now, I was confused.
	"She's Busujima Saeko, right?" I muttered to myself. I was referring to the girl sleeping beside me. She was the president of the school kendo club and a bit of a celebrity in school, being very beautiful and talented. "But she's so different to how she's depicted in the anime."
	Not in a bad way. Rather, in a good way.
	Her beauty couldn't be properly drawn and her bust was slightly bigger than what I remembered.
	Again, that wasn't important right now. I didn't know why I was here. I didn't mean here sleeping next to Saeko, but here in this place. After all, wasn't this inside a story? The story was about zombies, fights, and boobs.
	'No, no, I need to concentrate and figure out what happened to me.'
	I racked my brain for answers, but I couldn't think of anything. I remembered my life up until the last point.
	My last memories consisted of me attending a gun museum and there was an explosion. Then, I somehow woke up here in the world of HOTD. Hell, the name of the story should have been BOTO, Battle of the Oppai!
	Anyway, I had a massive problem incoming. Namely zombie apocalypse and figuring out why I was here. But at that moment, the answer of my question came suddenly in a form of a mechanical voice.
	[Ding! Unreliable Choice System has been installed!]
	[Make a choice and get a reward!]
	'...Huh?'
	""",
	"""
	I was stupefied for a moment before I regained my bearing. This wasn't the first time I had heard the name, after all. A system.
	It didn't end there. Multiple notifications rang in my head as memories and strange knowledge were forcefully implanted in my brain.
	[Name: Busujima Daiki
	Strength: 8 | Agility: 7 | Stamina: 10 | Dexterity: 8
	Skills: Busujima Swordsmanship (Beginner), Marksmanship (Intermediate)
	Shop Points: 0 P]
	[Shop will be unlocked after the zombie outbreak begins!]
	Instantly, I understood everything thanks to the influx of memories and knowledge. I was an adopted son of the Busujima family, Saeko's step brother.
	My name was Daiki, a highschool student and an apprentice of the Busujima Sword Style. And my Marksmanship skill was probably from my previous life, as I was a gun avid and often hit the range with my buddies.
	With this sudden knowledge, I knew what was going on. I was reincarnated in this world. As the system had said, I was here to make choices and survive the zombie apocalypse.
	However, I wasn't too worried. I was a fan of the anime and I knew how the story progressed. At least until the author died and had no one to continue the story. That's right. This anime, or rather manga, ended in a cliffhanger. Not even a proper ending.
	At that moment, Saeko stirred awake. She moaned slightly as she sat up, rubbing the sleep from her eyes. She looked at me, and I looked at her, my mind blanking as I stared at her naked body.
	Based on my new memories, we always slept together like this so I should've gotten used to it, but this surprised me because I was caught off guard.
	Seeing my reaction, she smiled mischievously and said, "Good morning, Daiki. What are you looking at?"
	 fɾeeweɓnѳveɭ.com
	""", 
	"""
	Just when I was about to answer, the system window popped up.
	[Make your choice!]
	1. Say "good morning" back. (Reward: 5 Shop Points)
	2. Joke around and say "your boobs". (Reward: 10 Shop Points + 1 Agility)
	3. Be honest and kiss her. (Reward: 20 Shop Points + 1 All Stats)
	I blinked in surprise, then sighed as I realized what this system was.
	'Right, it's the typical "choice" system."
	Of course it would be like this. After all, there was no such thing as a free lunch. Everything had its price, and if the system was going to give me a choice, there had to be a consequence for it.
	For example, what would happen if I chose to say "her boobs"? There was a chance she might hit me. Would I be able to survive her blow? No, of course not.
	If I had no prior memories of our relationship, I would definitely avoid it. However...
	"Good morning, Saeko. I was mesmerized by your appearance."
	I said and kissed her cheek. It was a bit weird to me, but based on my memories, this was actually normal for us.
	We were very close siblings.
	Saeko didn't seem to mind it. She even looked happy, smiling brightly and giggling, "You're so honest. I'm glad, though. I like that about you."
	[Ding! You have received 20 Shop Points + 1 All Stats]
	Well, that was easy.
	***
	Support and read advanced Chapters in patreon.com/DungeonLove
	Use arrow keys (or A / D) to PREV/NEXT chapter
	""",
]

var _plugin_name = "GodotAndroidPluginTemplate"
var media_notification_plugin
var play_pressed: bool = false
var current_title: String = ""
var current_chapter: String = ""

func _ready() -> void:
	chapter_list = [1, 2, 3, 4, 5]
	#if OS.has_feature("Android"):
	#tts_model = AndriodTTSModel.new()
	#else:
	#tts_model = DefualtTTSModel.new()
	#tts_model.chapter_list = chapter_list
	#tts_model.chapters = chapters
	#add_child(tts_model)
	#tts_load()
	var count = 0
	for i in chapters:
		save_chapter_text(count, i, "love")
		count += 1
#
# if this breakes 
func save_chapter_text(chapter: int, content: String, filename: String) -> void:
	var folder_path = "user://novels/%s" % filename
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(folder_path):
		dir.make_dir_recursive(folder_path)

	var file_path = "%s/chapter_%d.txt" % [folder_path, chapter]
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
	setup_media_notification()

func _on_Button_pressed():
	is_playing = !is_playing
	button.text = str(is_playing)
	media_notification_plugin.playChapterQueue()

func setup_media_notification():
	if Engine.has_singleton(_plugin_name):
		media_notification_plugin = Engine.get_singleton(_plugin_name)
		media_notification_plugin.setChapterQueue(["chapter_0.txt", "chapter_1.txt", "chapter_2.txt"], "user://novels/love/", 0)
	else:
		button.text = ("MediaStyle notification plugin not available")
