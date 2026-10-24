class_name CaptchaImages
extends RefCounted

# c1: dogs (with or without bread) are the targets, bagels are decoys with no notes

const TARGETS: Array[Texture2D] = [
	preload("res://assets/captcha/dog/dog1.png"),
	preload("res://assets/captcha/dog/dog2.png"),
	preload("res://assets/captcha/dog/dog3.png"),
	preload("res://assets/captcha/dog/dog4.png"),
	preload("res://assets/captcha/dog/dog5.png"),
	preload("res://assets/captcha/dog/dog6.png"),
	preload("res://assets/captcha/dog/dog7.png"),
	preload("res://assets/captcha/dog/dog8.png"),
	preload("res://assets/captcha/dog/dog9.png"),
	preload("res://assets/captcha/dogb/dogb1.png"),
	preload("res://assets/captcha/dogb/dogb2.png"),
	preload("res://assets/captcha/dogb/dogb3.png"),
	preload("res://assets/captcha/dogb/dogb4.png"),
]
const DECOYS: Array[Texture2D] = [
	preload("res://assets/captcha/bagel/bagel1.png"),
	preload("res://assets/captcha/bagel/bagel2.png"),
	preload("res://assets/captcha/bagel/bagel3.png"),
	preload("res://assets/captcha/bagel/bagel4.png"),
]
