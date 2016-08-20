/*-------------------------------------------------------------------------------------------------------------------------
	Serverside menu framework
-------------------------------------------------------------------------------------------------------------------------*/

AddCSLuaFile( "cl_menu_playercontrols.ev.lua" )

evolve.menus={}

// Load menus
hook.Add( "Initialize", "EvolveMenuInitialize", function()
	//timer.Simple(1, function()
		local dir = evolve.folderMain .. evolve.folder.menu
		menus = file.Find( dir .. "tab_*.lua" .. evolve.fileExt, "DATA" )
		for k, menu in pairs( menus ) do
			table.insert( evolve.menus, dir .. menu )
			RunString(file.Read( dir .. menu, "DATA" ))
		end
		evolve:Message( "menus loaded serverside." )
	//end )
end )

// Register privileges
table.insert( evolve.privileges, "Menu" )

function evolve:RegisterTab( tab )
	table.Add( evolve.privileges, tab.Privileges or {} )
end

// Send all tabs to the clients
util.AddNetworkString( "EV_Menu" )
hook.Add( "PlayerInitialSpawn", "EvolveMenu", function( ply )
	if ( !ply.EV_SentMenu and ply:IsValid() ) then
		//timer.Simple(1, function()
			for k, v in ipairs( evolve.menus ) do
				net.Start( "EV_Menu" )
				net.WriteString( v )
				net.WriteString( util.Base64Encode( util.Compress( file.Read( v, "DATA" ) ) ) )
				net.Send(ply)
			end
			net.Start( "EV_Menu" )
			net.WriteString( "" )
			net.WriteString( "" )
			net.Send(ply)
			
			ply.EV_SentMenu = true
		//end )
	end
end )