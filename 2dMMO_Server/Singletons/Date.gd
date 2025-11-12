extends Node


func GetDay() -> int:
	return floor(Time.get_unix_time_from_system() / 86400)
