#define EGG_INCUBATION_TIME 4 MINUTES

/mob/living/simple_animal/hostile/headcrab
	name = "headslug"
	desc = "Absolutely not de-beaked or harmless. Keep away from corpses."
	icon_state = "headcrab"
	icon_living = "headcrab"
	icon_dead = "headcrab_dead"
	gender = NEUTER
	health = 50
	maxHealth = 50
	melee_damage_lower = 5
	melee_damage_upper = 5
	attack_verb_continuous = "chomps"
	attack_verb_simple = "chomp"
	attack_sound = 'sound/weapons/bite.ogg'
	attack_vis_effect = ATTACK_EFFECT_BITE
	faction = list("creature")
	robust_searching = 1
	stat_attack = DEAD
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	speak_emote = list("squeaks")
	var/datum/mind/origin
	var/egg_lain = 0

/mob/living/simple_animal/hostile/headcrab/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS, INNATE_TRAIT)

/mob/living/simple_animal/hostile/headcrab/proc/Infect(mob/living/carbon/victim)
	var/obj/item/organ/internal/body_egg/changeling_egg/egg = new(victim)
	egg.Insert(victim)
	if(origin)
		egg.origin = origin
	else if(mind) // Let's make this a feature
		egg.origin = mind
	for(var/obj/item/organ/I in src)
		I.forceMove(egg)
	visible_message(span_warning("[src] plants something in [victim]'s flesh!"), \
					span_danger("We inject our egg into [victim]'s body!"))
	egg_lain = 1

/mob/living/simple_animal/hostile/headcrab/AttackingTarget()
	. = ..()
	if(. && !egg_lain && iscarbon(target) && !ismonkey(target))
		// Changeling egg can survive in aliens!
		var/mob/living/carbon/C = target
		if(C.stat == DEAD)
			if(HAS_TRAIT(C, TRAIT_XENO_HOST))
				to_chat(src, span_userdanger("A foreign presence repels us from this body. Perhaps we should try to infest another?"))
				return
			Infect(target)
			to_chat(src, span_userdanger("With our egg laid, our death approaches rapidly..."))
			addtimer(CALLBACK(src, .proc/death), 100)

/obj/item/organ/internal/body_egg/changeling_egg
	name = "changeling egg"
	desc = "Twitching and disgusting."
	var/datum/mind/origin
	var/time = 0

/obj/item/organ/internal/body_egg/changeling_egg/egg_process(delta_time, times_fired)
	// Changeling eggs grow in dead people
	time += delta_time * 10
	if(time >= EGG_INCUBATION_TIME)
		Pop()
		Remove(owner)
		qdel(src)

/obj/item/organ/internal/body_egg/changeling_egg/proc/Pop()
	// SKYRAT EDIT START	( TODO: Move some of this upstream. )
	var/mob/living/carbon/human/species/monkey/spawned_monkey = new(owner)
	// Need to clear the skyrat customisation stuff before transforming into a monkey, otherwise an abomination is created.
	var/datum/dna/current_dna = spawned_monkey.dna
	for(var/key in current_dna.mutant_bodyparts)
		LAZYSET(current_dna.mutant_bodyparts, key, "None")
	for(var/key in current_dna.body_markings)
		LAZYSET(current_dna.body_markings, key, null)
	if(current_dna.features["body_size"])
		LAZYSET(current_dna.features, "body_size", 1)
	if(current_dna.features["legs"])
		LAZYREMOVE(current_dna.features, "legs")
	spawned_monkey.set_species(/datum/species/monkey)
	for(var/scar in spawned_monkey.all_scars)
		var/datum/scar/iter_scar = scar
		if(iter_scar.fake)
			qdel(iter_scar)
	spawned_monkey.regenerate_icons()
	// SKYRAT EDIT END

	for(var/obj/item/organ/I in src)
		I.Insert(spawned_monkey, 1)

	if(origin && (origin.current ? (origin.current.stat == DEAD) : origin.get_ghost()))
		origin.transfer_to(spawned_monkey)
		spawned_monkey.key = origin.key
		var/datum/antagonist/changeling/changeling_datum = origin.has_antag_datum(/datum/antagonist/changeling)
		if(!changeling_datum)
			changeling_datum = origin.add_antag_datum(/datum/antagonist/changeling/headslug)
		if(changeling_datum.can_absorb_dna(owner))
			changeling_datum.add_new_profile(owner)

		// SKYRAT EDIT START	( TODO: Move upstream. )
		var/datum/action/changeling/humanform/hf = new()
		changeling_datum.purchased_powers += hf
		hf.Grant(origin.current)
		changeling_datum.regain_powers()
		// SKYRAT EDIT END

	owner.gib()

#undef EGG_INCUBATION_TIME
