extends Node

const DEBUGGER: bool = false

const GODOT_ASSET_LIB_API = "https://godotengine.org/asset-library/api/assets"
const ICON_SIZE = Vector2(64, 64)

func setup() -> void:
	fetch_assets()

func fetch_assets() -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request(GODOT_ASSET_LIB_API)
	http_request.request_completed.connect(_on_http_request_completed)

func _display_assets(assets) -> void:
	for asset in assets:
		var title = asset.get("title", "Unknown Asset")
		var author = asset.get("author", "Unknown Author")
		var category = asset.get("category", "Unknown Category")
		var support = asset.get("support_level", "Unknown Support")
		var godot_version = asset.get("godot_version", "Unknown Version")
		var description = asset.get("description", "No description available.")
		var page_url = asset.get("browse_url", "")
		var download_url = asset.get("download_url", "")
		var icon_url = asset.get("icon_url", "")
		var asset_box = HBoxContainer.new()
		asset_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		asset_box.add_theme_constant_override("separation", 10)
		var texture_rect = TextureRect.new()
		texture_rect.custom_minimum_size = ICON_SIZE
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		asset_box.add_child(texture_rect)
		if icon_url:
			var icon_request = HTTPRequest.new()
			add_child(icon_request)
			icon_request.connect("request_completed", Callable(self, "_on_icon_request_completed").bind(icon_request, texture_rect))
			icon_request.request(icon_url)
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label_title = Label.new()
		label_title.text = "[b]" + title + "[/b]"
		label_title.add_theme_font_override("font", load("res://default_font.tres"))
		label_title.add_theme_font_size_override("font_size", 14)
		label_title.set("theme_override_colors/font_color", Color(1, 1, 1))
		var label_info = Label.new()
		label_info.text = "By: %s | %s | %s | Godot %s" % [author, category, support, godot_version]
		label_info.add_theme_font_size_override("font_size", 10)
		label_info.set("theme_override_colors/font_color", Color(0.8, 0.8, 0.8))
		var label_desc = Label.new()
		label_desc.text = description
		label_desc.clip_text = true
		label_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		label_desc.custom_minimum_size.x = 300
		label_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(label_title)
		vbox.add_child(label_info)
		vbox.add_child(label_desc)
		asset_box.add_child(vbox)
		var button_box = VBoxContainer.new()
		var open_button = Button.new()
		open_button.text = "Open Page"
		open_button.connect("pressed", Callable(self, "_on_open_page_pressed").bind(page_url))
		button_box.add_child(open_button)
		var download_button = Button.new()
		download_button.text = "Download"
		download_button.connect("pressed", Callable(self, "_on_download_pressed").bind(download_url, title))
		button_box.add_child(download_button)
		asset_box.add_child(button_box)


func _on_open_page_pressed(url) -> void:
	if url:
		OS.shell_open(url)


func _on_download_pressed(url, title) -> void:
	if url:
		var download_request = HTTPRequest.new()
		add_child(download_request)
		download_request.connect("request_completed", Callable(self, "_on_download_request_completed").bind(download_request, title))
		download_request.request(url)


func _on_http_request_completed(_result, response_code, _headers, body) -> void:
	if response_code != 200:
		_debugger("Failed to fetch assets! HTTP Code: " + str(response_code), true)
		return
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	if parse_result != OK:
		_debugger("Failed to parse JSON!", true)
		return
	var data = json.data
	if data.has("result"):
		_display_assets(data["result"])


func _on_download_request_completed(_result, response_code, _headers, body, _request, title) -> void:
	if response_code == 200:
		var file_path = "user://%s.zip" % title.replace(" ", "_")
		var file = FileAccess.open(file_path, FileAccess.WRITE)
		if file:
			file.store_buffer(body)
			file.close()
			_debugger("Downloaded: " + str(file_path))
		else:
			_debugger("Failed to save asset!")
	else:
		_debugger("Download failed! HTTP Code: " + str(response_code), true)


func _on_icon_request_completed(_result, response_code, _headers, body, request, texture_rect) -> void:
	if response_code == 200:
		var image = Image.new()
		var err = image.load_png_from_buffer(body)
		if err == OK:
			var texture = ImageTexture.create_from_image(image)
			texture_rect.texture = texture
	request.queue_free()


func _debugger(debug_message: String, error: bool = false) -> void:
	if error:
		DebugManager.log_error(debug_message, str(get_script().get_path()))
	else:
		DebugManager.log_debug(debug_message, str(get_script().get_path()))
	if DEBUGGER == true:
		if OS.is_debug_build():
			print_debug(debug_message)
