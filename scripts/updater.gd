extends Node

const TAGS_URL = "https://api.github.com/repos/Matko802/blockshark/tags?per_page=20"
const DL_PATH = "user://update.apk"

var main
var hud
var current := "2.4.8"
var http: HTTPRequest
var dl: HTTPRequest
var pending_silent := false
var pending_tag := ""
var pending_apk := ""
var downloaded_tag := ""
var primary_action := ""

func setup(mn, hd, ver: String) -> void:
	main = mn
	hud = hd
	current = ver
	http = HTTPRequest.new()
	http.timeout = 12.0
	add_child(http)
	http.request_completed.connect(_done)
	dl = HTTPRequest.new()
	dl.timeout = 90.0
	add_child(dl)
	dl.request_completed.connect(_dl_done)

func has_installer() -> bool:
	return Engine.has_singleton("BlocksharkUpdate")

func installer():
	return Engine.get_singleton("BlocksharkUpdate")

func auto_check() -> void:
	await get_tree().create_timer(2.5).timeout
	if is_instance_valid(http):
		check(true)

func check(silent: bool) -> void:
	pending_silent = silent
	pending_tag = ""
	var err := http.request(TAGS_URL, ["User-Agent: blockshark-3d"])
	if err != OK and not silent:
		hud.show_update_dialog("Update check", "Could not reach the update server.", "", false)
		pending_silent = false

func release_url(tag: String) -> String:
	return "https://api.github.com/repos/Matko802/blockshark/releases/tags/" + tag

func _done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if pending_tag != "":
		_done_release(result, code, body)
		return
	var silent := pending_silent
	pending_silent = false
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		if not silent:
			hud.show_update_dialog("Update check", "Could not reach the update server.", "", false)
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_ARRAY:
		if not silent:
			hud.show_update_dialog("Update check", "Update response was invalid.", "", false)
		return
	var best := ""
	for t in data:
		var tag_name := str(t.get("name", ""))
		if tag_name != "" and newer(tag_name, current) and newer(tag_name, best):
			best = tag_name
	if best == "":
		if not silent:
			hud.show_update_dialog("Up to date", "You are on the latest version (" + current + ").", "", false)
		return
	if best == downloaded_tag and FileAccess.file_exists(DL_PATH):
		primary_action = "install"
		hud.show_update_dialog("Update ready", "Version " + best + " is downloaded.", "Install now", true)
		return
	pending_tag = best
	pending_silent = silent
	http.request(release_url(best), ["User-Agent: blockshark-3d"])

func _done_release(result: int, code: int, body: PackedByteArray) -> void:
	var silent := pending_silent
	var tag := pending_tag
	pending_silent = false
	pending_tag = ""
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		if not silent:
			hud.show_update_dialog("Update available", "Version " + tag + " is tagged but its package is not published yet.", "", false)
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY:
		if not silent:
			hud.show_update_dialog("Update available", "Version " + tag + " is tagged but its package is not published yet.", "", false)
		return
	var notes := str(data.get("body", ""))
	var apk := ""
	var assets: Array = data.get("assets", [])
	for a in assets:
		if str(a.get("name", "")).ends_with(".apk"):
			apk = str(a.get("browser_download_url", ""))
			break
	if apk == "":
		if not silent:
			hud.show_update_dialog("Update available", "Version " + tag + " is tagged but its package is not published yet.", "", false)
		return
	pending_apk = apk
	pending_tag = tag
	primary_action = "download"
	var text := "Version " + tag + " is ready."
	if notes != "":
		text += "\n\n" + notes.left(400)
	if has_installer():
		text += "\n\nDownload installs right inside the game."
	else:
		text += "\n\nDownload opens the release page in your browser."
	hud.show_update_dialog("Update available", text, "Download", true)

func on_primary() -> void:
	if primary_action == "download":
		if has_installer():
			start_download()
		else:
			OS.shell_open(pending_apk)
			primary_action = ""
			hud.hide_update()
	elif primary_action == "install":
		try_install()
	elif primary_action == "settings":
		installer().openInstallSettings()
		primary_action = ""
		hud.hide_update()

func start_download() -> void:
	primary_action = ""
	hud.show_update_dialog("Downloading", "Fetching " + pending_tag + "...", "", false)
	dl.download_file = DL_PATH
	var err := dl.request(pending_apk, ["User-Agent: blockshark-3d"])
	if err != OK:
		primary_action = "download"
		hud.show_update_dialog("Update available", "Download failed to start.", "Download", true)

func _dl_done(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and (code == 200 or code == 0):
		downloaded_tag = pending_tag
		primary_action = "install"
		hud.show_update_dialog("Ready to install", "Version " + pending_tag + " downloaded.", "Install now", true)
	else:
		primary_action = "download"
		hud.show_update_dialog("Update available", "Download failed.", "Download", true)

func try_install() -> void:
	if not has_installer():
		OS.shell_open(pending_apk)
		primary_action = ""
		hud.hide_update()
		return
	if installer().canInstallPackages():
		installer().installApk(OS.get_user_data_dir() + "/update.apk")
		primary_action = ""
		hud.show_update_dialog("Installing", "Confirm the install when Android asks.", "", false)
	else:
		primary_action = "settings"
		hud.show_update_dialog("Permission needed", "Allow install unknown apps for Blockshark 3D, then come back and tap Install.", "Open settings", true)

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
