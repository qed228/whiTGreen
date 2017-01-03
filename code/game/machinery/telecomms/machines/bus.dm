/*
	The  bus  mainframe  idles  and  waits  for  hubs  to  relay  them  signals.  They  act
	as  junctions  for  the  network.

	They  transfer  uncompressed  subspace  packets  to  processor  units,  and  then  take
	the  processed  packet  to  a  server  for  logging.

	Link  to  a  subspace  hub  if  it  can't  send  to  a  server.
*/

/obj/machinery/telecomms/bus
	name  =  "bus  mainframe"
	icon_state  =  "bus"
	desc  =  "A  mighty  piece  of  hardware  used  to  send  massive  amounts  of  data  quickly."
	density  =  1
	anchored  =  1
	use_power  =  1
	idle_power_usage  =  50
	machinetype  =  2
	//heatgen  =  20
	circuitboard  =  "/obj/item/weapon/circuitboard/telecomms/bus"
	netspeed  =  40
	var/change_frequency  =  0

/obj/machinery/telecomms/bus/receive_information(datum/signal/signal,  obj/machinery/telecomms/machine_from)

	if(is_freq_listening(signal))
		if(change_frequency)
			signal.frequency  =  change_frequency

		if(!istype(machine_from,  /obj/machinery/telecomms/processor)  &&  machine_from  !=  src)  //  Signal  must  be  ready  (stupid  assuming  machine),  let's  send  it
			//  send  to  one  linked  processor  unit
			var/send_to_processor  =  relay_information(signal,  "/obj/machinery/telecomms/processor")

			if(send_to_processor)
				return
			//  failed  to  send  to  a  processor,  relay  information  anyway
			signal.data["slow"]  +=  rand(1,  5)  //  slow  the  signal  down  only  slightly
			src.receive_information(signal,  src)

		//  Try  sending  it!
		var/list/try_send  =  list("/obj/machinery/telecomms/server",  "/obj/machinery/telecomms/hub",  "/obj/machinery/telecomms/broadcaster",  "/obj/machinery/telecomms/bus")
		var/i  =  0
		for(var/send  in  try_send)
			if(i)
				signal.data["slow"]  +=  rand(0,  1)  //  slow  the  signal  down  only  slightly
			i++
			var/can_send  =  relay_information(signal,  send)
			if(can_send)
				break

/obj/machinery/telecomms/bus/New()
	..()
	component_parts  =  list()
	component_parts  +=  new  /obj/item/weapon/circuitboard/telecomms/bus(null)
	component_parts  +=  new  /obj/item/weapon/stock_parts/subspace/filter(null)
	component_parts  +=  new  /obj/item/weapon/stock_parts/manipulator(null)
	component_parts  +=  new  /obj/item/weapon/stock_parts/manipulator(null)
	component_parts  +=  new  /obj/item/stack/cable_coil(null,  1)
	RefreshParts()






//Preset  Buses

/obj/machinery/telecomms/bus/preset_one
	id  =  "Bus  1"
	network  =  "tcommsat"
	freq_listening  =  list(SCI_FREQ,  MED_FREQ)
	autolinkers  =  list("processor1",  "science",  "medical")

/obj/machinery/telecomms/bus/preset_two
	id  =  "Bus  2"
	network  =  "tcommsat"
	freq_listening  =  list(SUPP_FREQ,SERV_FREQ)
	autolinkers  =  list("processor2",  "supply",  "service")

/obj/machinery/telecomms/bus/preset_three
	id  =  "Bus  3"
	network  =  "tcommsat"
	freq_listening  =  list(SEC_FREQ,  COMM_FREQ)
	autolinkers  =  list("processor3",  "security",  "command")

/obj/machinery/telecomms/bus/preset_four
	id  =  "Bus  4"
	network  =  "tcommsat"
	freq_listening  =  list(ENG_FREQ)
	autolinkers  =  list("processor4",  "engineering",  "common")

/obj/machinery/telecomms/bus/preset_four/New()
	for(var/i  =  1441,  i  <  1489,  i  +=  2)
		freq_listening  |=  i
	..()

