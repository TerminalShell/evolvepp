/*-------------------------------------------------------------------------------------------------------------------------
	Serverside autorun file
-------------------------------------------------------------------------------------------------------------------------*/

// Set up evolve table
if evolve then return end
evolve = evolve or {}

// Load serverside files
include( "config.ev.lua" )
include( "framework.ev.lua" )
if ( evolve.version ) then
	require( "SHA1" )
	include( "sv_init.ev.lua" )
	include( "sv_menu.ev.lua" )

	// Distribute clientside and shared files
	AddCSLuaFile( "autorun/client/cl_autorun.lua" )
	AddCSLuaFile( "config.ev.lua" )
	AddCSLuaFile( "framework.ev.lua" )
	AddCSLuaFile( "cl_init.ev.lua" )
	AddCSLuaFile( "cl_menu.ev.lua" )
else
	MsgN("Evolve++ failed to load serverside, aborting additional modules.")
end