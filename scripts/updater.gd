extends Node

const API_URL = "https://api.github.com/repos/Matko802/blockshark/releases/latest"

var main
var hud
var current := "2.1.0"
var http: HTTPRequest
var pending_silent := false

func setup(mn, hd, ver: String) -> void:
	main = mn
	hud = hd
	current = ver
	http = HTTPRequest.new()
	http.timeout = 12.0
	add_child(http)
	http.request_completed.connect(_done)

func auto_check() -> void:
	await get_tree().create_timer(2.5).timeout
	if is_instance_valid(http):
		check(true)

func check(silent: bool) -> void:
	pending_silent = silent
	var err := http.request(API_URL, ["User-Agent: blockshark-3d"])
	if err != OK and not silent:
		hud.show_update_dialog("Update check", "Could not reach the update server.", "")
		pending_silent = false

func _done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var silent := pending_silent
	pending_silent = false
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		if not silent:
			hud.show_update_dialog("Update check", "Could not reach the update server.", "")
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY:
		if not silent:
			hud.show_update_dialog("Update check", "Update response was invalid.", "")
		return
	var tag := str(data.get("tag_name", ""))
	var notes := str(data.get("body", ""))
	var apk := ""
	var assets: Array = data.get("assets", [])
	for a in assets:
		if str(a.get("name", "")).ends_with(".apk"):
			apk = str(a.get("browser_download_url", ""))
			break
	if tag == "" or apk == "":
		if not silent:
			hud.show_update_dialog("Update check", "No release package found.", "")
		return
	if newer(tag, current):
		var text := "Version " + tag + " is ready."
		if notes != "":
			text += "\n\n" + notes.left(400)
		text += "\n\nDownload opens the release page in your browser."
		hud.show_update_dialog("Update available", text, apk)
	elif not silent:
		hud.show_update_dialog("Up to date", "You are on the latest version (" + current + ").", "")

func newer(remote: String, local: String) -> bool:
	var r := remote.trim_prefix("v").trim_prefix("V").split(".")
	var l := local.split(".")
	for i in 3:
		var a := 0
		var b := 0
		if i < r.size():
			a = int(r[i])
		if i < l.size():
			b = int(l[i])
		if a != b:
			return a > b
	return false
