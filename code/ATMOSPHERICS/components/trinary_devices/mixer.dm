/obj/machinery/atmospherics/trinary/mixer
	icon_state  =  "mixer_off"
	density  =  0

	name  =  "gas  mixer"

	can_unwrench  =  1

	var/on  =  0

	var/target_pressure  =  ONE_ATMOSPHERE
	var/node1_concentration  =  0.5
	var/node2_concentration  =  0.5

	//node  3  is  the  outlet,  nodes  1  &  2  are  intakes

/obj/machinery/atmospherics/trinary/mixer/flipped
	icon_state  =  "mixer_off_f"
	flipped  =  1


/obj/machinery/atmospherics/trinary/mixer/update_icon_nopipes()
	if(!(stat  &  NOPOWER)  &&  on  &&  node1  &&  node2  &&  node3)
		icon_state  =  "mixer_on[flipped?"_f":""]"
		return

	icon_state  =  "mixer_off[flipped?"_f":""]"

/obj/machinery/atmospherics/trinary/mixer/power_change()
	var/old_stat  =  stat
	..()
	if(stat  &  NOPOWER)
		on  =  0
	if(old_stat  !=  stat)
		update_icon()

/obj/machinery/atmospherics/trinary/mixer/New()
	..()
	air3.volume  =  300

/obj/machinery/atmospherics/trinary/mixer/process_atmos()
	..()
	if(!on)
		return  0

	var/output_starting_pressure  =  air3.return_pressure()

	if(output_starting_pressure  >=  target_pressure)
		//No  need  to  mix  if  target  is  already  full!
		return  1

	//Calculate  necessary  moles  to  transfer  using  PV=nRT

	var/pressure_delta  =  target_pressure  -  output_starting_pressure
	var/transfer_moles1  =  0
	var/transfer_moles2  =  0

	if(air1.temperature  >  0)
		transfer_moles1  =  (node1_concentration*pressure_delta)*air3.volume/(air1.temperature  *  R_IDEAL_GAS_EQUATION)

	if(air2.temperature  >  0)
		transfer_moles2  =  (node2_concentration*pressure_delta)*air3.volume/(air2.temperature  *  R_IDEAL_GAS_EQUATION)

	var/air1_moles  =  air1.total_moles()
	var/air2_moles  =  air2.total_moles()

	if((air1_moles  <  transfer_moles1)  ||  (air2_moles  <  transfer_moles2))
		var/ratio  =  0
		if  ((  transfer_moles1  >  0  )  &&  (transfer_moles2  >0  ))
			ratio  =  min(air1_moles/transfer_moles1,  air2_moles/transfer_moles2)
		if  ((  transfer_moles2  ==  0  )  &&  (  transfer_moles1  >  0  ))
			ratio  =  air1_moles/transfer_moles1
		if  ((  transfer_moles1  ==  0  )  &&  (  transfer_moles2  >  0  ))
			ratio  =  air2_moles/transfer_moles2

		transfer_moles1  *=  ratio
		transfer_moles2  *=  ratio

	//Actually  transfer  the  gas

	if(transfer_moles1  >  0)
		var/datum/gas_mixture/removed1  =  air1.remove(transfer_moles1)
		air3.merge(removed1)

	if(transfer_moles2  >  0)
		var/datum/gas_mixture/removed2  =  air2.remove(transfer_moles2)
		air3.merge(removed2)

	if(transfer_moles1)
		parent1.update  =  1

	if(transfer_moles2)
		parent2.update  =  1

	parent3.update  =  1

	return  1

/obj/machinery/atmospherics/trinary/mixer/attack_hand(user  as  mob)
	if(..())
		return

	if(!src.allowed(user))
		user  <<  "<span  class='danger'>Access  denied.</span>"
		return

	ui_interact(user)

/obj/machinery/atmospherics/trinary/mixer/ui_interact(mob/user,  ui_key  =  "main")
	if(stat  &  (BROKEN|NOPOWER))
		return

	var/data  =  list()

	data["on"]  =  on
	data["pressure_set"]  =  round(target_pressure*100)  //Nano  UI  can't  handle  rounded  non-integers,  apparently.
	data["max_pressure"]  =  MAX_OUTPUT_PRESSURE
	data["node1_concentration"]  =  round(node1_concentration*100)
	data["node2_concentration"]  =  round(node2_concentration*100)

	var/datum/nanoui/ui  =  SSnano.get_open_ui(user,  src,  ui_key)
	if  (!ui)
		ui  =  new  /datum/nanoui(user,  src,  ui_key,  "atmos_mixer.tmpl",  name,  400,  320)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)
	else
		ui.push_data(data)

/obj/machinery/atmospherics/trinary/mixer/Topic(href,href_list)
	if(..())  return
	if(href_list["power"])
		on  =  !on
		investigate_log("was  turned  [on  ?  "on"  :  "off"]  by  [key_name(usr)]",  "atmos")
	if(href_list["set_press"])
		switch(href_list["set_press"])
			if  ("max")
				target_pressure  =  MAX_OUTPUT_PRESSURE
			if  ("set")
				target_pressure  =  max(0,  min(MAX_OUTPUT_PRESSURE,  safe_input("Pressure  control",  "Enter  new  output  pressure  (0-[MAX_OUTPUT_PRESSURE]  kPa)",  target_pressure)))
		investigate_log("was  set  to  [target_pressure]  kPa  by  [key_name(usr)]",  "atmos")
	if(href_list["node1_c"])
		var/value  =  text2num(href_list["node1_c"])
		src.node1_concentration  =  max(0,  min(1,  src.node1_concentration  +  value))
		src.node2_concentration  =  max(0,  min(1,  src.node2_concentration  -  value))
		investigate_log("was  set  to  [node1_concentration]  %  on  node  1  by  [key_name(usr)]",  "atmos")
	if(href_list["node2_c"])
		var/value  =  text2num(href_list["node2_c"])
		src.node2_concentration  =  max(0,  min(1,  src.node2_concentration  +  value))
		src.node1_concentration  =  max(0,  min(1,  src.node1_concentration  -  value))
		investigate_log("was  set  to  [node2_concentration]  %  on  node  2  by  [key_name(usr)]",  "atmos")
	src.update_icon()
	src.updateUsrDialog()
	return

/obj/machinery/atmospherics/trinary/mixer/AltClick(var/mob/user)
	if(in_range(src,user)  &&  ishuman(user))
		on  =  !on
		update_icon_nopipes()