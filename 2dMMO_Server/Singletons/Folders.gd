extends Node

const FOLDER_PATHS: Dictionary = {
	Folders = ["user://worlds", "user://users", "user://quests"],
}

func CreateFolders() -> void:
	for PathName in FOLDER_PATHS.Folders:
		if not DirAccess.dir_exists_absolute(PathName):
			DirAccess.make_dir_absolute(PathName)
	
	#if not FileAccess.file_exists(Global.DATABASE_PATH):
	#	DirAccess.copy_absolute("res://Data/db.db", Global.DATABASE_PATH)
