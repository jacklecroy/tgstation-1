///Component for customizable food
/datum/component/customizable
	can_transfer = TRUE
	var/list/obj/item/ingredients
	var/replacement
	var/fill_type
	var/max_ingredients
	var/mutable_appearance/top_overlay


/datum/component/customizable/Initialize(atom/replacement, fill_type, max_ingredients = INFINITY)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE

	src.replacement = replacement
	src.fill_type = fill_type
	src.max_ingredients = max_ingredients


/datum/component/customizable/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_PARENT_ATTACKBY, .proc/customizable_attack)
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, .proc/on_examine)


/datum/component/customizable/UnregisterFromParent()
	. = ..()
	UnregisterSignal(parent, list(COMSIG_PARENT_ATTACKBY, COMSIG_PARENT_EXAMINE))


/datum/component/customizable/PostTransfer()
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE


/datum/component/customizable/proc/on_examine(atom/A, mob/user, list/examine_list)
	SIGNAL_HANDLER

	var/atom/P = parent
	examine_list += "It contains [LAZYLEN(ingredients) ? "[ingredients]" : "no ingredient, "]making a [custom_adjective()]-sized [initial(P.name)]."


/datum/component/customizable/proc/customizable_attack(datum/source, obj/item/I, mob/M, silent = FALSE, force = FALSE)
	SIGNAL_HANDLER

	// only accept items with reagents
	if (!IS_EDIBLE(I))
		to_chat(M, "<span class='warning'>[I] doesn't belong on [parent]!</span>")
		return

	if (LAZYLEN(ingredients) >= max_ingredients)
		to_chat(M, "<span class='warning'>[parent] is too full for any more ingredients!</span>")
		return

	var/atom/P = parent
	if(!M.transferItemToLoc(I, P))
		return
	if (replacement)
		var/atom/R = new replacement(P.loc)
		I.forceMove(R)
		replacement = null
		RemoveComponent()
		R.TakeComponent(src)
		qdel(P)
	handle_fill(I)
	handle_reagents(I)
	handle_ingredients(I)


/datum/component/customizable/proc/handle_fill(obj/item/I)
	var/atom/P = parent
	var/mutable_appearance/filling = mutable_appearance(P.icon, "[initial(P.icon_state)]_filling")
	// get average color
	var/icon/ico = new(I.icon, I.icon_state)
	ico.Scale(1, 1)
	var/fillcol = copytext(ico.GetPixel(1, 1), 1, 8) // remove opacity
	filling.color = fillcol

	switch(fill_type)
		if(CUSTOM_INGREDIENTS_SCATTER)
			filling.pixel_x = rand(-1,1)
			filling.pixel_y = rand(-1,1)
		if(CUSTOM_INGREDIENTS_STACK)
			filling.pixel_x = rand(-1,1)
			filling.pixel_y = 2 * LAZYLEN(ingredients) - 1
		if(CUSTOM_INGREDIENTS_STACKPLUSTOP)
			filling.pixel_x = rand(-1,1)
			filling.pixel_y = 2 *  LAZYLEN(ingredients) - 1
			if (top_overlay) // delete old top if exists
				P.cut_overlay(top_overlay)
			top_overlay = mutable_appearance(P.icon, "[P.icon_state]_top")
			top_overlay.pixel_y = 2 * LAZYLEN(ingredients) + 3
			P.add_overlay(filling)
			P.add_overlay(top_overlay)
			return
		if(CUSTOM_INGREDIENTS_FILL)
			P.cut_overlays()
		if(CUSTOM_INGREDIENTS_LINE)
			filling.pixel_x = filling.pixel_y = rand(-8,3)
	P.add_overlay(filling)


/datum/component/customizable/proc/handle_reagents(obj/item/I)
	var/atom/P = parent
	I.reagents.trans_to(P, I.reagents.total_volume)
	return


/datum/component/customizable/proc/handle_ingredients(obj/item/I)
	LAZYADD(ingredients, I)
	// deal with food trash?
	SEND_SIGNAL(I, COMSIG_FOOD_CONSUMED, null, null)
	var/atom/P = parent
	P.name = "[custom_adjective()] [custom_type()] [initial(P.name)]"


/datum/component/customizable/proc/custom_adjective()
	switch(LAZYLEN(ingredients))
		if (0 to 2)
			return "small"
		if (3 to 5)
			return "standard"
		if (6 to 8)
			return "big"
		if (8 to 11)
			return "ridiculous"
		if (12 to INFINITY)
			return "monstrous"

/datum/component/customizable/proc/custom_type()
	var/custom_type = "empty"
	if (LAZYLEN(ingredients))
		var/obj/item/I = ingredients[1]
		if (istype(I, /obj/item/food/meat))
			var/obj/item/food/meat/M = I
			if (M.subjectname)
				custom_type = M.subjectname
			else if (M.subjectjob)
				custom_type = M.subjectjob
		if (custom_type == "empty" && I.name)
			custom_type = I.name
	return custom_type
