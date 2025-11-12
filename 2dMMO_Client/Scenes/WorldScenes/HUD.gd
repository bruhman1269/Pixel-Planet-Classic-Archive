extends CanvasLayer


func comma_sep(number: int) -> String:
	var string = str(number)
	var mod = string.length() % 3
	var res = ""

	for i in range(0, string.length()):
		if i != 0 && i % 3 == mod:
			res += ","
		res += string[i]

	return res


func display_bits(_bits_amount: int) -> void:
	$BitsAndHealth/BitsLabel.text = comma_sep(_bits_amount)
