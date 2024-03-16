# ForzaDatasport-Ruby
Experimental first attempt at creating some Ruby tools for Forza Motorsport (2023) Data out.

# Concept
This is still a very early stage of this project.

The end goal is to create some Ruby tools with which to make use of the Data Out feature of Forza Motorsport 2023
for the XBOX/PC

The current web-browser telemetry viewer is very barebones (basically only rev meter and car information) but it is receiving the full data packet at 60/sec, so the overall performance is visible currently.

It is trivial to spin the server up on any machine on your local network, assign the FM Dataout to that machine's IP - and then use any machine (same/other) to naviagte to server IP + view realtime telemetry
and other info.

I will be adding tuning/analysis tools one at a time including:
- Suspension travel limits / averages / warnings
- Speed averages
- Tire wear / heat comparative analysis (lap-lap)
- Oversteer / understeer warnings
- Gearing analysis
- Differential optimization assistance
- Visualizers
	- custom brakepoint indicators (with wizard to help choose them)
	- relative entry exit speed comparison (per turn / per lap)
	- logged session replays

I will also be doing some research into what data formats are popular/desired - and try to build some low-latency parsers - in case ruby is not your thing + you just want the data in some other formats/structures


Perhaps ultimately, I'll see about making a ForzaMotorsportData gem - or some other broadly useful items.

# Current Status

Currently, the project will allow you to:
1) Collect UDP data stream from Forza Motorsport Data Out
2) Connect over local network to server with browser and view

	(tested with Xbox on local network - not same-machine PC, but should work with some light IP configuration)
	- Rev Meter w/ Gear + Shift Indicator
	- Car Information:
		- Year, Make, Model
		- Class
		- Performance Index
		- Drivetrain
		- Engine Format
3) Use aux IP finder methods to get IP listing from local machine
4) Convert JSON-format TXT docs to hash in external Ruby File

# Technical Notes

This project uses:
1) Sinatra for server
2) Faye/Websocket for websocket/UDP
3) JSON formatted data for web-viewer
4) Canvas for browser rendering (I'm thinking of using Svelte or p5.js instead)
