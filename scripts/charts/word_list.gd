class_name WordList
extends RefCounted

# lowercase, no punctuation or numbers, kept short so typing on beat is fair
const WORDS := [
	"the", "be", "to", "of", "and", "in", "that", "have", "it", "for",
	"not", "on", "with", "he", "as", "you", "do", "at", "this", "but",
	"his", "by", "from", "they", "we", "say", "her", "she", "or", "an",
	"will", "my", "one", "all", "would", "there", "their", "what", "so", "up",
	"out", "if", "about", "who", "get", "which", "go", "me", "when", "make",
	"can", "like", "time", "no", "just", "him", "know", "take", "people", "into",
	"year", "your", "good", "some", "could", "them", "see", "other", "than", "then",
	"now", "look", "only", "come", "its", "over", "think", "also", "back", "after",
	"use", "two", "how", "our", "work", "first", "well", "way", "even", "new",
	"want", "because", "any", "these", "give", "day", "most", "us", "game", "jam",
	"click", "robot", "human", "proof", "verify", "submit", "skip", "close", "ad", "worst",
]

static func random(rng: RandomNumberGenerator) -> String:
	return WORDS[rng.randi() % WORDS.size()]
