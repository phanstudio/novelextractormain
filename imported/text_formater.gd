extends RefCounted
class_name TextFormater

static func split_text(text: String, max_length: int = 300) -> Array:
	var regex := RegEx.new()
	regex.compile("[.!?]\\s+")
	var matches := regex.search_all(text)

	var chunks: Array = []
	var start := 0

	for match in matches:
		var end := match.get_end()
		var sentence := text.substr(start, end - start)
		start = end

		sentence = sentence.strip_edges()
		if chunks.size() > 0 and (chunks[-1].length() + sentence.length()) < max_length:
			chunks[-1] += " " + sentence
		else:
			chunks.append(sentence)

	# Add any remaining text after last punctuation
	if start < text.length():
		var last_part := text.substr(start, text.length() - start).strip_edges()
		if last_part != "":
			if chunks.size() > 0 and (chunks[-1].length() + last_part.length()) < max_length:
				chunks[-1] += " " + last_part
			else:
				chunks.append(last_part)
	return chunks

static func remove_filler(text: String) -> String:
	text = text.replace("--", "")
	text = text.replace("__", "")
	#text = text.replace("__", "")
	return text

static func format_text(text:String, max_length: int = 300) -> Array:
	return split_text(remove_filler(text), max_length)

static func extract_chapter_title(text: String) -> String:
	var lines = text.split("\n")
	for line in lines:
		line = line.strip_edges()
		if line.length() > 0 and not line.begins_with("Chapter"):
			return line.substr(0, min(50, line.length())) + "..."
	return "Novel Reading"
