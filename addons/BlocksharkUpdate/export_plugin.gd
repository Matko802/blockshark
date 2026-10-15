@tool
extends EditorPlugin

var export_plugin: AndroidExportPlugin

func _enter_tree() -> void:
	export_plugin = AndroidExportPlugin.new()
	add_export_plugin(export_plugin)

func _exit_tree() -> void:
	remove_export_plugin(export_plugin)
	export_plugin = null

class AndroidExportPlugin extends EditorExportPlugin:
	var _plugin_name = "BlocksharkUpdate"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		return PackedStringArray(["BlocksharkUpdate/bin/BlocksharkUpdate.aar"])

	func _get_name() -> String:
		return _plugin_name

	func _get_android_manifest_element_contents(platform: EditorExportPlatform, debug: bool) -> String:
		return "<uses-permission android:name=\"android.permission.REQUEST_INSTALL_PACKAGES\" />"
