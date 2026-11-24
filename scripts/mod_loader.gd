extends RefCounted
class_name GameModLoader

var skins: Array[Dictionary] = []
var maps: Array[Dictionary] = []
var upgrades: Array[Dictionary] = []
var loaded_mod_names: Array[String] = []

func load_all() -> void:
    skins.clear()
    maps.clear()
    upgrades.clear()
    loaded_mod_names.clear()
    var root := "user://mods"
    DirAccess.make_dir_recursive(root)
    var folders := DirAccess.get_directories_at(root)
    for folder in folders:
        var manifest_path := root.path_join(folder).path_join("mod.json")
        if not FileAccess.file_exists(manifest_path):
            continue
        var file := FileAccess.open(manifest_path, FileAccess.READ)
        if file == null:
            continue
        var parsed: Variant = JSON.parse_string(file.get_as_text())
        file.close()
        if typeof(parsed) != TYPE_DICTIONARY:
            continue
        var manifest: Dictionary = parsed
        loaded_mod_names.append(str(manifest.get("name", folder)))
        _append_dicts(manifest.get("skins", []), skins)
        _append_dicts(manifest.get("maps", []), maps)
        _append_dicts(manifest.get("upgrades", []), upgrades)

func _append_dicts(source: Variant, destination: Array[Dictionary]) -> void:
    if typeof(source) != TYPE_ARRAY:
        return
    for item in source:
        if typeof(item) == TYPE_DICTIONARY:
            destination.append(item.duplicate(true))
