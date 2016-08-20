/*-------------------------------------------------------------------------------------------------------------------------
	Clientside initialization
-------------------------------------------------------------------------------------------------------------------------*/

// Show startup message
MsgN( "\n=============================================================" )
MsgN( " "..evolve.title.." version "..evolve.version.." succesfully initialized clientside." )
MsgN( "=============================================================\n" )

net.Receive("EV_Init", function( len, ply )
	// Register that we are installed
	evolve.installed = true
	
	// Load plugins
	evolve:LoadPlugins()
end )