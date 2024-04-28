/decl/security_level/code_blue
	name = "Blue alert (Keter Research)"

	light_max_bright = 0.5
	light_inner_range = 1
	light_outer_range = 2
	light_color_alarm = COLOR_BLUE
	light_color_status_display = COLOR_BLUE

	overlay_alarm = "alarm_blue"
	overlay_status_display = "status_display_blue"
	alert_border = "alert_border_blue"

	description = "Испытание SCP класса Кетер."

	var/static/datum/announcement/priority/security/security_announcement_blue = new(do_log = 0, do_newscast = 1, new_sound = sound('sounds/misc/notice3.ogg'))

/decl/security_level/code_blue/switching_up_to()
	security_announcement_blue.Announce("Начинаются испытания SCP класса Кетер. Вся служба безопасности должена быть в полной готовности.", "Внимание! Объявляется синий код тревоги!")
	notify_station()

/decl/security_level/code_blue/switching_down_to()
	security_announcement_blue.Announce("Кризис преодолен. Планируются испытания SCP класса Кетер. Вся служба безопасности должена быть в полной готовности.", "Внимание! Код тревоги понижен до синего!")
	undo_emergency()
	notify_station()

/decl/security_level/code_orange
	name = "Orange alert (Euclid Containment Breach)"

	light_max_bright = 0.75
	light_inner_range = 1
	light_outer_range = 3
	light_color_alarm = COLOR_ORANGE
	light_color_status_display = COLOR_ORANGE

	overlay_alarm = "alarm_orange"
	overlay_status_display = "status_display_orange"
	alert_border = "alert_border_orange"

	description = "Нарушение условий содержания SCP класса Евклид."

	var/static/datum/announcement/priority/security/security_announcement_orange = new(do_log = 0, do_newscast = 1, new_sound = sound('sounds/AI/announcer/codered.ogg'))

/decl/security_level/code_orange/switching_up_to()
	security_announcement_orange.Announce("Нарушение условий содержания SCP класса Евклид! Службе безопасности зоны с нарушением условий содержания - немедленное реагирование и восстановление условий содержания! Гражданскому персоналу в зоне с нарушением условий содержания - немедленная эвакуация! Вся служба безопасности должена быть в боевой готовности!", "Внимание! Объявляется оранжевый код тревоги!")
	notify_station()

/decl/security_level/code_orange/switching_down_to()
	security_announcement_orange.Announce("Кризис смягчен. Нарушение условий содержания SCP класса Евклид! Службе безопасности зоны с нарушением условий содержания - немедленное реагирование и восстановление условий содержания! Вся служба безопасности должена быть в боевой готовности! ", "Внимание! Код тревоги понижен до оранжевого!")
	undo_emergency()
	notify_station()
