extends RefCounted
class_name GameModLoader

const MAX_MODS := 32
const MAX_FILE_BYTES := 262144
const VALID_EFFECTS := ["swift","spring","wave","rapid","sturdy"]

var skins: Array[Dictionary] = []
var maps: Array[Dictionary] = []
var upgrades: Array[Dictionary] = []
var loaded_mod_names: Array[String] = []
var warnings: Array[String] = []

func load_all() -> void:
    skins.clear()
    maps.clear()
    upgrades.clear()
    loaded_mod_names.clear()
    warnings.clear()
    var root := "user://mods"
    var user_directory := DirAccess.open("user://")
    if user_directory != null:
        user_directory.make_dir_recursive("mods")
    var folders := DirAccess.get_directories_at(root)
    folders.sort()
    var loaded_count := 0
    for folder in folders:
        if loaded_count >= MAX_MODS:
            warnings.append("Достигнут лимит модов: %d" % MAX_MODS)
            break
        var manifest_path := root.path_join(folder).path_join("mod.json")
        if not FileAccess.file_exists(manifest_path):
            continue
        if FileAccess.get_file_as_bytes(manifest_path).size() > MAX_FILE_BYTES:
            warnings.append(folder + ": файл слишком большой")
            continue
        var file := FileAccess.open(manifest_path, FileAccess.READ)
        if file == null:
            warnings.append(folder + ": не удалось открыть файл")
            continue
        var parsed: Variant = JSON.parse_string(file.get_as_text())
        file.close()
        if typeof(parsed) != TYPE_DICTIONARY:
            warnings.append(folder + ": ошибка JSON")
            continue
        var manifest: Dictionary = parsed
        var mod_name := str(manifest.get("name",folder)).strip_edges()
        if mod_name.is_empty():
            mod_name = folder
        loaded_mod_names.append(mod_name.left(40))
        _append_skins(manifest.get("skins",[]),folder)
        _append_maps(manifest.get("maps",[]),folder)
        _append_upgrades(manifest.get("upgrades",[]),folder)
        loaded_count += 1

func _append_skins(source: Variant, folder: String) -> void:
    if typeof(source) != TYPE_ARRAY:
        return
    for item in source:
        if typeof(item) != TYPE_DICTIONARY:
            continue
        var name := str(item.get("name","")).strip_edges()
        var color := str(item.get("color",""))
        if name.is_empty() or name.length() > 32:
            warnings.append(folder + ": пропущен скин с неверным именем")
            continue
        if not (color.begins_with("#") and (color.length() == 7 or color.length() == 9)):
            warnings.append(folder + ": пропущен скин с неверным цветом")
            continue
        skins.append({"id":str(item.get("id",name)).left(40),"name":name,"color":color})

func _append_maps(source: Variant, folder: String) -> void:
    if typeof(source) != TYPE_ARRAY:
        return
    for item in source:
        if typeof(item) != TYPE_DICTIONARY:
            continue
        var name := str(item.get("name","")).strip_edges()
        var raw_platforms: Variant = item.get("platforms",[])
        if name.is_empty() or name.length() > 40 or typeof(raw_platforms) != TYPE_ARRAY:
            warnings.append(folder + ": пропущена арена с неверными данными")
            continue
        var safe_platforms: Array[Dictionary] = []
        for raw_platform in raw_platforms:
            if typeof(raw_platform) != TYPE_DICTIONARY:
                continue
            var x := float(raw_platform.get("x",640))
            var y := float(raw_platform.get("y",500))
            var w := float(raw_platform.get("w",180))
            var h := float(raw_platform.get("h",22))
            if x < 60.0 or x > 1220.0 or y < 100.0 or y > 680.0:
                continue
            if w < 60.0 or w > 700.0 or h < 10.0 or h > 60.0:
                continue
            safe_platforms.append({"x":x,"y":y,"w":w,"h":h})
            if safe_platforms.size() >= 20:
                break
        if safe_platforms.size() < 2:
            warnings.append(folder + ": в арене должно быть хотя бы 2 платформы")
            continue
        maps.append({"name":name,"platforms":safe_platforms})

func _append_upgrades(source: Variant, folder: String) -> void:
    if typeof(source) != TYPE_ARRAY:
        return
    for item in source:
        if typeof(item) != TYPE_DICTIONARY:
            continue
        var effect := str(item.get("effect",item.get("id","")))
        if not VALID_EFFECTS.has(effect):
            warnings.append(folder + ": неизвестный эффект карточки " + effect)
            continue
        var clean := item.duplicate(true)
        clean["effect"] = effect
        upgrades.append(clean)
