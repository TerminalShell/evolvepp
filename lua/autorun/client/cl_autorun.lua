/*-------------------------------------------------------------------------------------------------------------------------
	Clientside autorun file
-------------------------------------------------------------------------------------------------------------------------*/

// Set up evolve table
if evolve then return end
evolve = evolve or {}

// Load clientside files
include( "config.ev.lua" )
include( "framework.ev.lua" )
if ( evolve.version ) then
	include( "cl_menu.ev.lua" )
	include( "cl_init.ev.lua" )
else
	MsgN("Evolve++ framework failed to load clientside, aborting additional modules.")
end