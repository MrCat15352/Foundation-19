/*/decl/security_state
	// When defining any of these values type paths should be used, not instances. Instances will be acquired in /New()

	// The security level in which the destruction of the site is likely. Not selectable by personnel; set internally or by admins
	var/decl/security_level/destruction_security_level = /decl/security_level/code_delta

	// While at or above this security level, the use of nuclear fission devices and other extreme measures are allowed.
	var/decl/security_level/severe_security_level = /decl/security_level/code_black

	// While at or above this security level, transfer votes are disabled, MTF may be requested, and other similar high alert implications.
	var/decl/security_level/high_security_level = /decl/security_level/code_red

	var/decl/security_level/current_security_level // The current security level. Defaults to the first entry in all_security_levels if unset.
	var/decl/security_level/stored_security_level  // The security level that we are escalating from - please set and use this when reverting.

	// List of all available security levels
	// [CELADON-EDIT] - CELADON_COMPONENTS
	// var/list/all_security_levels = list(/decl/security_level/code_green, /decl/security_level/code_yellow, /decl/security_level/code_red, /decl/security_level/code_black, /decl/security_level/code_pitchblack, /decl/security_level/code_delta) // CELADON-EDIT - ORIGINAL
	var/list/all_security_levels = list(/decl/security_level/code_green, /decl/security_level/code_yellow, /decl/security_level/code_blue, /decl/security_level/code_orange, /decl/security_level/code_red, /decl/security_level/code_black, /decl/security_level/code_pitchblack, /decl/security_level/code_delta)
	// [/CELADON-EDIT]

	// List of all normally selectable security levels
	// [CELADON-EDIT] - CELADON_COMPONENTS
	// var/list/standard_security_levels = list(/decl/security_level/code_green, /decl/security_level/code_yellow, /decl/security_level/code_red, /decl/security_level/code_black, /decl/security_level/code_pitchblack) // CELADON-EDIT - ORIGINAL
	var/list/standard_security_levels = list(/decl/security_level/code_green, /decl/security_level/code_yellow, /decl/security_level/code_blue, /decl/security_level/code_orange, /decl/security_level/code_red, /decl/security_level/code_black, /decl/security_level/code_pitchblack)
	// [/CELADON-EDIT]

/decl/security_state/New()
	// Setup threshold security levels
	destruction_security_level = decls_repository.get_decl(destruction_security_level)
	severe_security_level = decls_repository.get_decl(severe_security_level)
	high_security_level = decls_repository.get_decl(high_security_level)

	// Setup starting security level
	current_security_level = decls_repository.get_decl(all_security_levels[1])

	// Setup the full list of available security levels now that we no longer need to use "x in all_security_levels"
	var/list/all_security_level_instances = list()
	for(var/security_level_type in all_security_levels)
		all_security_level_instances += decls_repository.get_decl(security_level_type)
	all_security_levels = all_security_level_instances

	// Setup the full list of standard security levels
	var/list/standard_security_level_instances = list()
	for(var/security_level_type in standard_security_levels)
		standard_security_level_instances += decls_repository.get_decl(security_level_type)
	standard_security_levels = standard_security_level_instances

/decl/security_state/Initialize()
	// Finally switch up to the default starting security level.
	current_security_level.switching_up_to()
	. = ..()

/decl/security_state/proc/can_change_security_level()
	return current_security_level in standard_security_levels

/decl/security_state/proc/can_switch_to(given_security_level)
	if(!can_change_security_level())
		return FALSE
	return given_security_level in standard_security_levels

/decl/security_state/proc/current_security_level_is_lower_than(given_security_level)
	var/current_index = list_find(all_security_levels, current_security_level)
	var/given_index   = list_find(all_security_levels, given_security_level)

	return given_index && current_index < given_index

/decl/security_state/proc/current_security_level_is_same_or_higher_than(given_security_level)
	var/current_index = list_find(all_security_levels, current_security_level)
	var/given_index   = list_find(all_security_levels, given_security_level)

	return given_index && current_index >= given_index

/decl/security_state/proc/current_security_level_is_higher_than(given_security_level)
	var/current_index = list_find(all_security_levels, current_security_level)
	var/given_index   = list_find(all_security_levels, given_security_level)

	return given_index && current_index > given_index

/decl/security_state/proc/set_security_level(decl/security_level/new_security_level, force_change = FALSE)
	if(new_security_level == current_security_level)
		return FALSE
	if(!(new_security_level in all_security_levels))
		return FALSE
	if(!force_change && !can_switch_to(new_security_level))
		return FALSE

	var/decl/security_level/previous_security_level = current_security_level
	current_security_level = new_security_level

	var/previous_index = list_find(all_security_levels, previous_security_level)
	var/new_index      = list_find(all_security_levels, new_security_level)

	if(new_index > previous_index)
		previous_security_level.switching_up_from()
		new_security_level.switching_up_to()
	else
		previous_security_level.switching_down_from()
		new_security_level.switching_down_to()

	log_and_message_staff("has changed the security level from [previous_security_level.name] to [new_security_level.name].")
	return TRUE

// This proc decreases the current security level, if possible
/decl/security_state/proc/decrease_security_level(force_change = FALSE)
	var/current_index = list_find(all_security_levels, current_security_level)
	if(current_index == 1)
		return FALSE
	return set_security_level(all_security_levels[current_index - 1], force_change)

/decl/security_state/proc/notify_station()
	SEND_SIGNAL(src, COMSIG_SECURITY_LEVEL_CHANGED)

	post_status("alert")

/decl/security_level
	// [CELADON-EDIT] - CELADON_COMPONENTS
	// var/icon = 'icons/misc/security_state.dmi' // CELADON-EDIT - ORIGINAL
	var/icon = 'mod_celadon/_components/icons/security_state.dmi'
	// [/CELADON-EDIT]
	var/name
	var/alarm_level = "off"

	var/static/datum/announcement/priority/security/security_announcement_up = new(do_log = 0, do_newscast = 1, new_sound = sound('sounds/misc/notice1.ogg'))
	var/static/datum/announcement/priority/security/security_announcement_down = new(do_log = 0, do_newscast = 1, new_sound = sound('sounds/misc/notice1.ogg'))

	// These values are primarily for station alarms and status displays, and which light colors and overlays to use
	var/light_max_bright = 0.5
	var/light_inner_range = 0.1
	var/light_outer_range = 1
	var/light_color_alarm
	var/light_color_status_display

	var/overlay_alarm
	var/overlay_status_display
	var/alert_border

	// Describes the alert itself, shown when choosing alarms
	var/description

// [CELADON-ADD] - CELADON_COMPONENTS
/decl/security_level/proc/do_emergency()
	for(var/obj/machinery/light/M in get_area_all_atoms(/area/site53))
		if (M.current_mode <> "emergency_lighting")
			M.set_emergency_lighting(TRUE)
			playsound(M, 'sounds/machines/apc_nopower.ogg', 20, 0)
		else
			M.flicker(10)

/decl/security_level/proc/undo_emergency()
	for(var/obj/machinery/light/M in get_area_all_atoms(/area/site53))
		if (M.current_mode == "emergency_lighting")
			M.set_emergency_lighting(FALSE)
			playsound(M, 'sounds/machines/lightson.ogg', 40, 0)
// [/CELADON-ADD]

// Called when we're switching from a lower security level to this one.
/decl/security_level/proc/switching_up_to()
	notify_station()

// Called when we're switching from a higher security level to this one.
/decl/security_level/proc/switching_down_to()
	notify_station()

// Called when we're switching from this security level to a higher one.
/decl/security_level/proc/switching_up_from()
	return

// Called when we're switching from this security level to a lower one.
/decl/security_level/proc/switching_down_from()
	return

/decl/security_level/proc/notify_station()
	var/decl/security_state/security_state = decls_repository.get_decl(GLOB.using_map.security_state)
	security_state.notify_station()
// SECURITY LEVELS

/decl/security_level/code_green
	name = "code green"

	light_max_bright = 0.25
	light_inner_range = 0.1
	light_outer_range = 1
	light_color_alarm = COLOR_GREEN
	light_color_status_display = COLOR_GREEN

	overlay_alarm = "alarm_green"
	overlay_status_display = "status_display_green"
	alert_border = "alert_border_green"

	// [CELADON-EDIT] - CELADON_COMPONENTS
	// description = "There is no active threat to the Site." // CELADON-EDIT - ORIGINAL
	description = "Активная угроза объекту отсутствует."
	// [/CELADON-EDIT]

	var/static/datum/announcement/priority/security/security_announcement_green = new(do_log = 0, do_newscast = 1, new_sound = sound('sounds/AI/announcer/codegreen.ogg', volume = 150))

/decl/security_level/code_green/switching_down_to()
	// [CELADON-EDIT] - CELADON_COMPONENTS
	// security_announcement_green.Announce("The situation has been resolved. All personnel are to return to their regular duties.", "Attention! Alert level lowered to code green.") // CELADON-EDIT - ORIGINAL
	security_announcement_green.Announce("Кризис преодолен. Весь персонал должен вернуться к своим стандартным процедурам.", "Внимание! Код тревоги понижен до зеленого кода.")
	// [/CELADON-EDIT]
	// [CELADON-ADD] - CELADON_COMPONENTS
	undo_emergency()
	// [/CELADON-ADD]
	notify_station()

/decl/security_level/code_yellow
	// [CELADON-EDIT] - CELADON_COMPONENTS
	// name = "code yellow" // CELADON-EDIT - ORIGINAL
	name = "Yellow alert (Euclid Research)"
	// [/CELADON-EDIT]

	light_max_bright = 0.5
	light_inner_range = 1
	light_outer_range = 2
	light_color_alarm = COLOR_YELLOW
	light_color_status_display = COLOR_YELLOW

	overlay_alarm = "alarm_yellow"
	overlay_status_display = "status_display_yellow"
	alert_border = "alert_border_yellow"

	// [CELADON-EDIT] - CELADON_COMPONENTS
	// description = "A potential threat has been reported but not yet confirmed." // CELADON-EDIT - ORIGINAL
	description = "Испытание SCP класса Евклид."
	// [/CELADON-EDIT]

	// [CELADON-EDIT] - CELADON_COMPONENTS
	// var/static/datum/announcement/priority/security/security_announcement_yellow = new(do_log = 0, do_newscast = 1, new_sound = sound('sounds/misc/notice1.ogg')) // CELADON-EDIT - ORIGINAL
	var/static/datum/announcement/priority/security/security_announcement_yellow = new(do_log = 0, do_newscast = 1, new_sound = sound('sounds/misc/notice3.ogg'))
	// [/CELADON-EDIT]

/decl/security_level/code_yellow/switching_up_to()
	// [CELADON-EDIT] - CELADON_COMPONENTS
	// security_announcement_yellow.Announce("There is an unconfirmed potential threat to the facility. Guards are to cautiously investigate the facility and secure sensitive areas. All personnel are recommended to report unusual behaviour.", "Attention! Code Yellow alert procedures now in effect!") // CELADON-EDIT - ORIGINAL
	security_announcement_yellow.Announce("Начинаются испытания SCP класса Евклид. Службе безопасности зоны проведения испытания быть в повышенной готовности.", "Внимание! Объявляется желтый код тревоги!")
	// [/CELADON-EDIT]
	notify_station()

/decl/security_level/code_yellow/switching_down_to()
	// [CELADON-EDIT] - CELADON_COMPONENTS
	// security_announcement_yellow.Announce("All Euclid and Keter SCPs have been recontained. All areas should be swept for Safe SCPs, and the general integrity of the site should be restored.", "Attention! Code Yellow alert procedures now in effect!") // CELADON-EDIT - ORIGINAL
	security_announcement_yellow.Announce("Кризис преодолен. Планируются испытания SCP класса Евклид. Службе безопасности зоны проведения испытания быть в повышенной готовности.", "Внимание! Код тревоги понижен до желтого!")
	// [/CELADON-EDIT]
	// [CELADON-ADD] - CELADON_COMPONENTS
	undo_emergency()
	// [/CELADON-ADD]
	notify_station()

/decl/security_level/code_red
	// [CELADON-EDIT] - CELADON_COMPONENTS
	// name = "code red" // CELADON-EDIT - ORIGINAL
	name = "Red alert (Keter Containment Breach)"
	// [/CELADON-EDIT]

	light_max_bright = 0.75
	light_inner_range = 1
	light_outer_range = 3
	light_color_alarm = COLOR_RED
	light_color_status_display = COLOR_RED

	overlay_alarm = "alarm_red"
	overlay_status_display = "status_display_red"
	alert_border = "alert_border_red"

	// [CELADON-EDIT] - CELADON_COMPONENTS
	// description = "An SCP is currently uncontained." // CELADON-EDIT - ORIGINAL
	description = "Нарушение условий содержания SCP класса Кетер."
	// [/CELADON-EDIT]

	var/static/datum/announcement/priority/security/security_announcement_red = new(do_log = 0, do_newscast = 1, new_sound = sound('sounds/AI/announcer/codered.ogg'))

/decl/security_level/code_red/switching_up_to()
	// [CELADON-EDIT] - CELADON_COMPONENTS
	// security_announcement_red.Announce("An SCP has broken containment and its current whereabouts are unknown. Security should secure all exit points immediately before recontaining breached anomalies.", "Attention! Code red alert procedures now in effect!") // CELADON-EDIT - ORIGINAL
	security_announcement_red.Announce("Нарушение условий содержания SCP класса Кетер! Службе безопасности зоны с нарушением условий содержания - немедленное реагирование и восстановление условий содержания! Гражданскому персоналу в зоне с нарушением условий содержания - немедленная эвакуация! Разрешается открытие бункеров. Вся служба безопасности должена быть в боевой готовности!", "Внимание! Объявляется красный код тревоги!")
	// [/CELADON-EDIT]
	notify_station()

/decl/security_level/code_red/switching_down_to()
	// [CELADON-EDIT] - CELADON_COMPONENTS
	// security_announcement_red.Announce("All major threats to the Site have been neutralized or contained, but one or more SCPs remain uncontained. Security should focus their efforts on recontaining the escaped SCP. Full site lockdown disengaged.", "Attention! Code red alert procedures now in effect!") // CELADON-EDIT - ORIGINAL
	security_announcement_red.Announce("Кризис смягчен. Блокировка зоны снята. Нарушение условий содержания SCP класса Кетер! Службе безопасности зоны с нарушением условий содержания - немедленное реагирование и восстановление условий содержания! Вся служба безопасности должена быть в боевой готовности!", "Внимание! Код тревоги понижен до красного!")
	// [/CELADON-EDIT]
	// [CELADON-ADD] - CELADON_COMPONENTS
	undo_emergency()
	// [/CELADON-ADD]
	notify_station()

/decl/security_level/code_black
	// [CELADON-EDIT] - CELADON_COMPONENTS
	// name = "code black" // CELADON-EDIT - ORIGINAL
	name = "Black alert (Multiple Containment Breach)"
	// [/CELADON-EDIT]

	light_max_bright = 0.75
	light_inner_range = 0.1
	light_outer_range = 3
	light_color_alarm = COLOR_RED
	light_color_status_display = COLOR_NAVY_BLUE

	overlay_alarm = "alarm_black"
	overlay_status_display = "status_display_black"
	alert_border = "alert_border_black"

	// [CELADON-EDIT] - CELADON_COMPONENTS
	// description = "Several Keter and Euclid SCPs are uncontained." // CELADON-EDIT - ORIGINAL
	description = "Множественные нарушения условий содержания SCP."
	// [/CELADON-EDIT]

	var/static/datum/announcement/priority/security/security_announcement_black = new(do_log = 0, do_newscast = 1, new_sound = sound('sounds/AI/announcer/codeblack.ogg'))

/decl/security_level/code_black/switching_up_to()
	// [CELADON-EDIT] - CELADON_COMPONENTS
	// security_announcement_black.Announce("The site is experiencing multiple Keter and Euclid level containment breaches. Full site lockdown initiated.", "Attention! Code Black alert procedures now in effect!") // CELADON-EDIT - ORIGINAL
	security_announcement_black.Announce("Множественное нарушение условий содержаний! Вся служба безопасности обязана восстановить условия содеражния! Включена блокировка Зоны!", "Внимание! Объявляется черный код тревоги!")
	// [/CELADON-EDIT]
	// [CELADON-ADD] - CELADON_COMPONENTS
	do_emergency()
	// [/CELADON-ADD]
	notify_station()

/decl/security_level/code_black/switching_down_to()
	// [CELADON-EDIT] - CELADON_COMPONENTS
	// security_announcement_black.Announce("The Site has been secured from subversive elements. Security is to sweep the facility and recontain all dangerous SCPs immediately.", "Attention! Code Black alert procedures now in effect!") // CELADON-EDIT - ORIGINAL
	security_announcement_black.Announce("Кризис смягчен! Вся служба безопасности обязана восстановить условия содеражния! Блокировка зоны активна!", "Внимание! Объявляется черный код тревоги!")
	// [/CELADON-EDIT]
	// [CELADON-ADD] - CELADON_COMPONENTS
	do_emergency()
	// [/CELADON-ADD]
	notify_station()

/decl/security_level/code_pitchblack
	// [CELADON-EDIT] - CELADON_COMPONENTS
	// name = "code pitchblack" // CELADON-EDIT - ORIGINAL
	name = "Pitchblack alert (Invasion Group of Interest)"
	// [/CELADON-EDIT]

	light_max_bright = 0.75
	light_inner_range = 0.1
	light_outer_range = 3
	light_color_alarm = COLOR_RED
	light_color_status_display = COLOR_NAVY_BLUE

	overlay_alarm = "alarm_pitchblack"
	overlay_status_display = "status_display_pitchblack"
	alert_border = "alert_border_pitchblack"

	// [CELADON-EDIT] - CELADON_COMPONENTS
	// description = "A hostile Group of Interest is invading or infiltrating the site." // CELADON-EDIT - ORIGINAL
	description = "Проникновение вражеских связанных организаций."
	// [/CELADON-EDIT]

	// [CELADON-EDIT] - CELADON_COMPONENTS
	// var/static/datum/announcement/priority/security/security_announcement_pitchblack = new(do_log = 0, do_newscast = 1, new_sound = sound('sounds/AI/announcer/codeblack.ogg')) // CELADON-EDIT - ORIGINAL
	var/static/datum/announcement/priority/security/security_announcement_pitchblack = new(do_log = 0, do_newscast = 1, new_sound = sound('sounds/misc/redalert1.ogg'))
	// [/CELADON-EDIT]

/decl/security_level/code_pitchblack/switching_up_to()
	// [CELADON-EDIT] - CELADON_COMPONENTS
	// security_announcement_pitchblack.Announce("There have been confirmed reports of a hostile Group of Interest on-site. Security is allowed to terminate all suspected hostiles." ,"Attention! Code pitchblack alert procedures now in effect!") // CELADON-EDIT - ORIGINAL
	security_announcement_pitchblack.Announce("Подвтерждено вторжение вражеских агентов Связаннных Организаций. Вся служба безопасности должена быть в боевой готовности! Устранить враждебные элементы! " ,"Внимание! Объявлен код Мрак!")
	// [/CELADON-EDIT]
	// [CELADON-ADD] - CELADON_COMPONENTS
	do_emergency()
	// [/CELADON-ADD]
	notify_station()

/decl/security_level/code_pitchblack/switching_down_to()
	// [CELADON-EDIT] - CELADON_COMPONENTS
	// security_announcement_pitchblack.Announce("The destructive threat has been neutralized, however there is still a hostile Group of Interest within the facility.", "Attention! Code pitchblack alert procedures now in effect!") // CELADON-EDIT - ORIGINAL
	security_announcement_pitchblack.Announce("Уничтожение предотвращено! Вся служба безопасности должена быть в боевой готовности! Устранить вражеских агентов Связаннных Организаций!", "Внимание! Объявлен код Мрак!")
	// [/CELADON-EDIT]
	// [CELADON-ADD] - CELADON_COMPONENTS
	do_emergency()
	// [/CELADON-ADD]
	notify_station()


/decl/security_level/code_delta
	// [CELADON-EDIT] - CELADON_COMPONENTS
	// name = "code delta" // CELADON-EDIT - ORIGINAL
	name = "Delta alert (Risk imminent destruction)"
	// [/CELADON-EDIT]
	alarm_level = "on"

	light_max_bright = 0.75
	light_inner_range = 0.1
	light_outer_range = 3
	light_color_alarm = COLOR_RED
	light_color_status_display = COLOR_NAVY_BLUE

	overlay_alarm = "alarm_delta"
	overlay_status_display = "status_display_delta"
	alert_border = "alert_border_delta"

	// [CELADON-EDIT] - CELADON_COMPONENTS
	// description = "The site is at risk of imminent destruction." // CELADON-EDIT - ORIGINAL
	description = "Опасность неминуемого уничтожения Зоны."
	// [/CELADON-EDIT]

	var/static/datum/announcement/priority/security/security_announcement_delta = new(do_log = 0, do_newscast = 1, new_sound = sound('sounds/effects/siren.ogg'))

/decl/security_level/code_delta/switching_up_to()
	// [CELADON-EDIT] - CELADON_COMPONENTS
	// security_announcement_delta.Announce("The destruction of the site is imminent. All personnel are to obey instructions given by administrative staff. Any violation of these orders is punishable by immediate termination. This is not a drill.", "Attention! Code Delta evacuation procedures now in effect!") // CELADON-EDIT - ORIGINAL
	security_announcement_delta.Announce("Риск уничтожения объекта критический. Все сотрудники должны подчиняться указаниям административного персонала. Нарушение приказов карается незамедлительным устранением. Это не учебная тревога!", "Внимание! Объявлен код Дельта")
	// [/CELADON-EDIT]
	// [CELADON-ADD] - CELADON_COMPONENTS
	do_emergency()
	// [/CELADON-ADD]
	notify_station()
*/
