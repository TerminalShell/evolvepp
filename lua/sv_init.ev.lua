/*-------------------------------------------------------------------------------------------------------------------------
	Serverside initialization
-------------------------------------------------------------------------------------------------------------------------*/

// Show startup message
MsgN( "\n=============================================================" )
MsgN( " "..evolve.title.." version "..evolve.version.." succesfully initialized serverside." )
MsgN( "=============================================================\n" )

if evolve.useDataSync and file.Exists( "datasync_config.ev.lua", "LUA") then include( "datasync_config.ev.lua" ) end

// Load plugins
hook.Add( "Initialize", "EvolveInitialize", function()
	evolve:LoadPlugins()
	evolve:Message( "plugins loaded serverside." )
end )

// Tell the clients Evolve is installed on the server
util.AddNetworkString( "EV_Init" )
util.AddNetworkString( "EV_PluginClient" )
hook.Add( "PlayerInitialSpawn", "EvolveInit", function( ply )
	if ( !ply.EV_SentInit and ply:IsValid() ) then
		net.Start( "EV_Init" )
		net.Send( ply )
		
		ply.EV_SentInit = true
		
		for k, v in ipairs( evolve.pluginClient ) do
			net.Start( "EV_PluginClient" )
			net.WriteString( v )
			net.WriteString( util.Base64Encode( util.Compress( file.Read( v, "DATA" ) ) ) )
			net.Send(ply)
		end
		net.Start( "EV_PluginClient" )
		net.WriteString( "" )
		net.WriteString( "" )
		net.Send(ply)
	end
end )

// Add Evolve to the tag list
timer.Create( "TagCheck", 1, 0, function()
	if not GetConVar( "sv_tags" ) then CreateConVar("sv_tags","") end
	if ( !string.find( GetConVar( "sv_tags" ):GetString(), evolve.title ) ) then
		local comma = ","
		if ( GetConVar( "sv_tags" ):GetString() == "" ) then
			comma = ""
		end
		RunConsoleCommand( "sv_tags", GetConVar( "sv_tags" ):GetString() .. comma .. evolve.title )
	end
end )