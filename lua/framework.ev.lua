/*-------------------------------------------------------------------------------------------------------------------------
	Framework providing the main Evolve++ functions
-------------------------------------------------------------------------------------------------------------------------*/

/*-------------------------------------------------------------------------------------------------------------------------
	Constants
-------------------------------------------------------------------------------------------------------------------------*/

evolve.title = "Evolve++" -- Title
evolve.prefix = evolve.prefix or "ev"
evolve.prefixSilent = evolve.prefixSilent or "evs"
evolve.chatPrefix = evolve.chatPrefix or { "!", "/" }
evolve.chatPrefixSilent = evolve.chatPrefixSilent or { "@" }
evolve.prefixLog = "[EV++]" -- Log/console output prefix
evolve.timeOffset = evolve.timeOffset or 0
evolve.version = "19.7.3" -- Version

-- Initialize main tables
evolve.bans = {}
evolve.globalvars = {}
evolve.ranks = {}
evolve.plugins = {}
evolve.privileges = {}
evolve.users = {}

evolve.constants = {} -- Initialize basic constants table
evolve.constants.notallowed = "You are not allowed to do that." -- Not allowed message
evolve.constants.noplayers = "No matching players with an equal or lower immunity found." -- Not allowed on players with greater immunity message
evolve.constants.noplayers2 = "No matching players with a lower immunity found." -- Not allowed on players with greater than or equal immunity message
evolve.constants.noplayersnoimmunity = "No matching players found." -- No players found message

evolve.colors = {} -- Initialize color table
evolve.colors.blue = Color( 98, 176, 255, 255 ) -- Default blue color
evolve.colors.red = Color( 255, 62, 62, 255 ) -- Default red color
evolve.colors.yellow = Color( 255, 255, 62, 255 ) -- Default yellow color
evolve.colors.black = Color( 0, 0, 0, 255 ) -- Default black color
evolve.colors.white = color_white -- Default white color

evolve.category = {} -- Initialize plugin menu category table
evolve.category.administration = 1 -- Administrative type plugins
evolve.category.actions = 2 -- Player action type plugins
evolve.category.punishment = 3 -- Punishment type plugins
evolve.category.teleportation = 4 -- Teleportation type plugins

evolve.admins = 1 -- Admins only (used in notify)

-- Define file locations
evolve.folderMain = 'evolvepp/'

evolve.folder = {}
evolve.folder.data = 'data/'
evolve.folder.logs = 'logs/'
evolve.folder.lua = 'lua/'
evolve.folder.plugins = evolve.folder.lua .. 'plugins/'
evolve.folder.menu = evolve.folder.lua .. 'menu/'

evolve.file = {}
evolve.file.bans = 'bans'
evolve.file.globalvars = 'globalvars'
evolve.file.ranks = 'ranks'
evolve.file.users = 'users'

evolve.fileExt = '.ev.txt'
evolve.filePackExt = '.pck'

evolve.pluginClient = {} -- Plugin file list to send to the client

/*-------------------------------------------------------------------------------------------------------------------------
	Load meta tables
-------------------------------------------------------------------------------------------------------------------------*/

EV_func_Player = FindMetaTable("Player")
EV_func_Entity = FindMetaTable("Entity")

/*-------------------------------------------------------------------------------------------------------------------------
	Messages and notifications
-------------------------------------------------------------------------------------------------------------------------*/

function evolve:Message( msg )
	MsgN( self.prefixLog .. " " .. msg )
end

if ( SERVER ) then
	evolve.SilentNotify = false

	function evolve:Notify( ... )
		local ply
		local arg = { ... }
		if ( type( arg[1] ) == "Player" or type( arg[1] ) == "userdata" or arg[1] == NULL ) then ply = arg[1] end
		if ( arg[1] == self.admins ) then
			for _, pl in pairs( player.GetAll() ) do
				if ( pl:IsAdmin() ) then
					table.remove( arg, 1 )
					self:Notify( pl, unpack( arg ) )
				end
			end
			return
		end
		if ( ply != NULL and !self.SilentNotify ) then
			umsg.Start( "EV_Notification", ply )
				umsg.Short( #arg )
				for _, v in ipairs( arg ) do
					if ( type( v ) == "string" ) then
						umsg.String( v )
					elseif ( type ( v ) == "table" ) then
						umsg.Short( v.r )
						umsg.Short( v.g )
						umsg.Short( v.b )
						umsg.Short( v.a )
					end
				end
			umsg.End()
		end

		local str = ""
		for _, v in ipairs( arg ) do
			if ( type( v ) == "string" ) then str = str .. v end
		end

		if ( ply ) then
			evolve:Message( ply:Nick() .. " -> " .. str )
			evolve:Log( evolve:PlayerLogStr( ply ) .. " -> " .. str )
		else
			evolve:Message( str )
			evolve:Log( str )
		end
	end
else
	function evolve:Notify( ... )
		local arg = { ... }

		args = {}
		for _, v in ipairs( arg ) do
			if ( type( v ) == "string" or type( v ) == "table" ) then table.insert( args, v ) end
		end

		chat.AddText( unpack( args ) )
	end

	usermessage.Hook( "EV_Notification", function( um )
		local argc = um:ReadShort()
		local args = {}
		for i = 1, argc / 2, 1 do
			table.insert( args, Color( um:ReadShort(), um:ReadShort(), um:ReadShort(), um:ReadShort() ) )
			table.insert( args, um:ReadString() )
		end

		chat.AddText( unpack( args ) )
	end )
end

/*-------------------------------------------------------------------------------------------------------------------------
	File/folder handling
-------------------------------------------------------------------------------------------------------------------------*/

if SERVER then -- Create our folder structure
	if ( !file.IsDir( evolve.folderMain, "DATA" ) ) then
		file.CreateDir( evolve.folderMain )
	end
	for k, v in pairs( evolve.folder ) do
		if ( !file.IsDir( evolve.folderMain..v, "DATA" ) ) then
			file.CreateDir( evolve.folderMain..v )
		end
	end
end

-- Save files to the data folder, adding ".pck" to the end of the name will compress it ([string] name of file, [vararg] data to save)
function evolve:SaveFile( name, data )
	if CLIENT then return end
	local filename = self.folderMain..name..self.fileExt
	local filedata = data
	if ( type(filedata) == "table" ) then filedata = util.TableToJSON( data ) end
	if ( string.EndsWith( name, self.filePackExt ) ) then
		file.Write( filename, util.Compress( filedata ) )
	else
		file.Write( filename, filedata )
	end
	return file.Exists( filename, "DATA" )
end

-- Alias for SaveFile, points at data files specifically
function evolve:SaveData( name, data )
	if CLIENT then return end
	return self:SaveFile( self.folder.data .. name, data )
end

-- Load files from the data folder, adding ".pck" to the end of the name will decompress it ([string] name of file) Returns [table] if JSON or [string]
function evolve:LoadFile( name )
	if CLIENT then return end
	local filename = self.folderMain..name..self.fileExt
	local pack = false or string.EndsWith( name, self.filePackExt )
	if ( !file.Exists( filename, "DATA" ) ) then return {} end
	local data = file.Read( filename, "DATA" )
	if ( pack ) then data = util.Decompress( data ) end
	local json = util.JSONToTable( data )
	if ( type(json) == "table" ) then
		return json or {}
	else
		return data or ""
	end
end

-- Alias for LoadFile, points at data files specifically
function evolve:LoadData( name )
	if CLIENT then return end
	return self:LoadFile( self.folder.data .. name )
end

-- Append to files in the data folder ([string] name of file, [string] data to save)
function evolve:AppendFile( name, data )
	if CLIENT then return end
	local filename = self.folderMain..name..self.fileExt
	local filedata = tostring(data)
	file.Append( filename, filedata )
	return file.Exists( filename, "DATA" )
end

-- Alias for AppendFile, points at data files specifically
function evolve:AppendData( name, data )
	if CLIENT then return end
	return self:AppendFile( self.folder.data .. name, data )
end

/*-------------------------------------------------------------------------------------------------------------------------
	Time functions
-------------------------------------------------------------------------------------------------------------------------*/

-- Give us the offset time. Returns [int]
function evolve:Time()
	return os.time() + ( self.timeOffset*60*60 or 0 )
end

-- Sync time on client.
usermessage.Hook( "EV_TimeSync", function( um )
	evolve.timeOffset = math.floor((um:ReadLong() - os.time())/60/60)
end )

-- Give us a date ([string] date format{, [int] time value}) Returns [int]
function evolve:Date( format, time )
	if ( !time ) then
		time = self:Time()
	end
	return os.date( format, time )
end

function evolve:FileDate( time )
	if ( !time ) then
		time = self:Time()
	end
	return self:Date( "%Y-%m-%d", time )
end

function evolve:IsFileDate( date )
	if ( string.match( date, "([0-9][0-9][0-9][0-9])-([0-9][0-9])-([0-9][0-9])" ) != nil ) then
		return true
	else
		return false
	end
end

function evolve:FormatTime( t )
	if ( t < 0 ) then
		return "Forever"
	elseif ( t < 60 ) then
		if ( t == 1 ) then return "one second" else return math.ceil(t) .. " seconds" end
	elseif ( t < 3600 ) then
		if ( math.ceil( t / 60 ) == 1 ) then return "one minute" else return math.ceil( t / 60 ) .. " minutes" end
	elseif ( t < 24 * 3600 ) then
		if ( math.ceil( t / 3600 ) == 1 ) then return "one hour" else return math.ceil( t / 3600 ) .. " hours" end
	elseif ( t < 24 * 3600 * 7 ) then
		if ( math.ceil( t / ( 24 * 3600 ) ) == 1 ) then return "one day" else return math.ceil( t / ( 24 * 3600 ) ) .. " days" end
	elseif ( t < 24 * 3600 * 30 ) then
		if ( math.ceil( t / ( 24 * 3600 * 7 ) ) == 1 ) then return "one week" else return math.ceil( t / ( 24 * 3600 * 7 ) ) .. " weeks" end
	else
		if ( math.ceil( t / ( 24 * 3600 * 30 ) ) == 1 ) then return "one month" else return math.ceil( t / ( 24 * 3600 * 30 ) )  .. " months" end
	end
end

/*-------------------------------------------------------------------------------------------------------------------------
	Utility functions
-------------------------------------------------------------------------------------------------------------------------*/

-- Converts a boolean value to an int ([boolean] value to convert) Returns [int]
function evolve:BoolToInt( bool )
	if ( bool ) then return 1 else return 0 end
end

-- Finds the index of a value in a table ([table] table to search, [vararg] value to find, [function] iteration function) Returns [int or string]
function evolve:KeyByValue( tbl, value, iterator )
	iterator = iterator or ipairs
	for k, v in iterator( tbl ) do
		if ( value == v ) then return k end
	end
end

function evolve:CompareVersion( cur, new )
	if ( !new and !cur ) then return 0 elseif ( !new ) then return -1 elseif ( !cur ) then return 1 end
	cur = string.Explode('.',cur)
	new = string.Explode('.',new)

	local ncur = table.Count(cur)
	local nnew = table.Count(new)

	if ( ncur != nnew ) then
		for i=1,ncur do
			if ( tonumber(cur[ncur+1-i]) == 0 ) then table.remove( cur, ncur+1-i ) else break end
		end
		ncur = table.Count(cur)
		for i=1,nnew do
			if ( tonumber(new[nnew+1-i]) == 0 ) then table.remove( new, nnew+1-i ) else break end
		end
		nnew = table.Count(new)
	end

	for i=1,math.max(ncur,nnew) do
		if ( !cur[i] ) then
			return 1
		elseif ( !new[i] ) then
			return -1
		elseif ( tonumber(cur[i]) < tonumber(new[i]) ) then
			return -1
		elseif ( tonumber(cur[i]) > tonumber(new[i]) ) then
			return 1
		end
	end
	return 0
end

-- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
-- licensed under the terms of the LGPL2
util.Base64Decode = function( data ) -- Y U NO MAKE "util.Base64Decode" GARRY? >:(
	local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	if !data then return end
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

/*-------------------------------------------------------------------------------------------------------------------------
	Plugin handling
-------------------------------------------------------------------------------------------------------------------------*/

-- This variable lets us carry over plugin data from LoadPlugins to RegisterPlugin as they are being loaded
local pluginFile

function evolve:LoadPlugins()
	if( self.plugins ) then table.Empty(self.plugins) end
	self.plugins = {}
	local plugins
	local prefix
	local dirs = { self.folderMain .. self.folder.plugins }
	local fileCheck

	fileCheck = file.Find( dirs[1] .. GAMEMODE_NAME .. "/*", "DATA" )
	if ( #fileCheck ) then
		table.insert( dirs, dirs[1] .. GAMEMODE_NAME .. "/" )
	end
	fileCheck = file.Find( dirs[1] .. "sandbox_derived/*", "DATA" )
	if ( #fileCheck and GAMEMODE_NAME != "sandbox_derived" and GAMEMODE.IsSandboxDerived ) then
		table.insert( dirs, dirs[1] .. "sandbox_derived/" )
	end

	for _, dir in pairs( dirs ) do
		plugins = file.Find( dir .. "*.lua" .. self.fileExt, "DATA" )
		for k, plugin in pairs( plugins ) do
			prefix = string.Left( plugin, string.find( plugin, "_" ) - 1 )
			pluginFile = dir .. plugin
			//if ( CLIENT and ( prefix == "sh" or prefix == "cl" ) ) then
				//RunString(file.Read( dir .. plugin, "DATA" ))
			//else
        RunString(file.Read( dir .. plugin, "DATA" ))
			//end
		end
	end
	hook.Call("EV_PluginsLoaded")
end

function evolve:RegisterPlugin( plugin )
	if ( !plugin or type(plugin) != "table" ) then return end
	if ( plugin.File ) then pluginFile = plugin.File
	elseif ( !pluginFile ) then return end

	local prefix = string.Explode( "/", pluginFile )
	prefix = prefix[#prefix]
	prefix = string.Left( prefix, string.find( prefix, "_" ) - 1 )
	if ( plugin.Disabled ) then
		if ( !self.pluginsDisabled ) then
			self.pluginsDisabled = {}
		end
		self.pluginsDisabled[plugin.Title] = { Title = plugin.Title, File = pluginFile }
		return
	end
	if ( plugin.Gamemodes and table.Count(plugin.Gamemodes) > 0 ) then
		if ( type(plugin.Gamemodes) != "table" ) then
			plugin.Gamemodes = {plugin.Gamemodes}
		end
		local gmfind = false
		for k, v in pairs( plugin.Gamemodes ) do
			if ( v == GAMEMODE_NAME or ( v == "sandbox_derived" and GAMEMODE.IsSandboxDerived ) ) then
				gmfind = true
			end
		end
		if ( !gmfind and prefix != "cl" ) then
			if ( !self.pluginsDisabled ) then
				self.pluginsDisabled = {}
			end
			self.pluginsDisabled[plugin.Title] = { Title = plugin.Title, File = pluginFile, Gamemodes = plugin.Gamemodes }
			return
		end
	end
	if SERVER then -- If on server, only send plugin to client if enabled
		if ( prefix == "sh" or prefix == "cl" ) then
			table.insert( self.pluginClient, pluginFile )
			if ( prefix == "cl" ) then
				self.plugins[plugin.Title] = { Title = plugin.Title, File = pluginFile }
				return
			end
		end
	end

	if ( plugin.Privileges and !istable(plugin.Privileges) ) then
		plugin.Privileges = {plugin.Privileges}
	end
	if ( plugin.Commands and !istable(plugin.Commands) ) then
		plugin.Commands = {plugin.Commands}
	end

	self.plugins[plugin.Title] = plugin
	plugin.File = pluginFile
	if ( isfunction( plugin.Initialize ) ) then
		plugin.EV_PluginsLoaded = plugin.Initialize
		plugin.Initialize = nil
	end

	if ( plugin.Privileges and SERVER ) then table.Add( self.privileges, plugin.Privileges ) table.sort( self.privileges ) end
end

if CLIENT then
	net.Receive("EV_PluginClient", function( len, ply )
		local loc = net.ReadString()
		if ( loc == "" ) then
			evolve:Message( "plugins loaded clientside." )
			hook.Call("EV_PluginsLoaded")
			net.ReadString()
		else
			pluginFile = loc
			RunString( util.Decompress( util.Base64Decode( net.ReadString() ) ) )
		end
	end )
end

function evolve:GetPlugin( title )
	if self.plugins[title] then
		return self.plugins[title]
	else
		for k, plugin in pairs( self.plugins ) do
			if ( string.lower( k ) == string.lower( title ) ) then
				return plugin
			end
		end
	end
end

function evolve:IsPlugin( title )
	if self.plugins[title] then
		return true
	else
		for k, plugin in pairs( self.plugins ) do
			if ( string.lower( k ) == string.lower( title ) ) then
				return true
			end
		end
	end
	return false
end

function evolve:GetPluginByProperty( property, value, exact )
	for k, v in pairs( self.plugins ) do
		if(istable(v[property])) then
			for i, j in pairs( v[property] ) do
				if ( j == value ) then
					return v
				elseif ( !exact and string.find( string.lower( j or "" ), string.lower( value ) ) ) then
					return v
				end
			end
		else
			if ( v[property] == value ) then
				return v
			elseif ( !exact and string.find( string.lower( v[property] or "" ), string.lower( value ) ) ) then
				return v
			end
		end
	end
end

if ( !evolve.HookCall ) then evolve.HookCall = hook.Call end
hook.Call = function( name, gm, ... )
	local arg = { ... }

	for _, plugin in pairs( evolve.plugins ) do
		if ( plugin[ name ] ) then
			local retValues = { pcall( plugin[name], plugin, ... ) }

			if ( retValues[1] and retValues[2] != nil ) then
				table.remove( retValues, 1 )
				return unpack( retValues )
			elseif ( !retValues[1] ) then
				evolve:Notify( 1, evolve.colors.red, "Hook '" .. name .. "' in plugin '" .. plugin.Title .. "' failed with error:" )
				evolve:Notify( 1, evolve.colors.red, retValues[2] )
			end
		end
	end

	if ( CLIENT ) then
		for _, tab in ipairs( evolve.MENU.Tabs ) do
			if ( tab[ name ] ) then
				local retValues = { pcall( tab[name], tab, ... ) }

				if ( retValues[1] and retValues[2] != nil ) then
					table.remove( retValues, 1 )
					return unpack( retValues )
				elseif ( !retValues[1] ) then
					evolve:Notify( 1, evolve.colors.red, "Hook '" .. name .. "' in tab '" .. tab.Title .. "' failed with error:" )
					evolve:Notify( 1, evolve.colors.red, retValues[2] )
				end
			end
		end
	end

	return evolve.HookCall( name, gm, ... )
end

if ( SERVER ) then
	util.AddNetworkString( "EV_PluginFile" )

	function evolve:ReloadPlugin( ply, com, args)
			if ( !ply:IsValid() and args[1] ) then
			local found
			local name = args[1] or ""

			for k, plugin in pairs( evolve.plugins ) do
				if ( string.lower( plugin.Title ) == string.lower( name ) ) then
					found = k
					break
				end
			end

			if ( found ) then
				evolve:Message( "Reloading plugin " .. evolve.plugins[found].Title .. "..." )

				local plugin = evolve.plugins[found].File
				local title = evolve.plugins[found].Title
				local prefix = string.Explode( "/", plugin )
				prefix = prefix[#prefix]
				prefix = string.Left( prefix, string.find(prefix, "_" ) - 1 )

				if ( prefix != "cl" ) then
					table.Empty( evolve.plugins[found] )
					evolve.plugins[found]=nil
					pluginFile = plugin
					RunString( file.Read( plugin, "DATA" ) )
					if ( type( PLUGIN.EV_PluginsLoaded ) == "function" ) then
						PLUGIN.EV_PluginsLoaded()
					end
					if ( type( PLUGIN.PlayerInitialSpawn ) == "function" ) then
						for k,v in pairs(player.GetAll()) do
							PLUGIN.PlayerInitialSpawn( v )
						end
					end
				end

				if ( prefix == "sh" or prefix == "cl" ) then
					net.Start( "EV_PluginFile" )
					net.WriteTable( { Title = title, Contents = file.Read( plugin, "DATA" ) } )
					net.Broadcast()
				end
			else
				evolve:Message( "Plugin '" .. tostring( name ) .. "' not found!" )
			end
		end
	end

	concommand.Add( "EV_PluginFile", function( ply, com, args )
		evolve:ReloadPlugin( ply, com, args )
	end )
else
	net.Receive("EV_PluginFile", function( len, ply )
		local data = net.ReadTable()

		for k, plugin in pairs( evolve.plugins ) do
			if ( string.lower( plugin.Title ) == string.lower( data.Title ) ) then
				found = k
				table.Empty( evolve.plugins[found] ) evolve.plugins[found]=nil
			end
		end

		RunString( data.Contents )
		if ( type( PLUGIN.EV_PluginsLoaded ) == "function" ) then
			PLUGIN.EV_PluginsLoaded()
		end
	end )
end

/*-------------------------------------------------------------------------------------------------------------------------
	Player finding/listing
-------------------------------------------------------------------------------------------------------------------------*/

function evolve:IsNameMatch( ply, str )
	if ( str == "*" ) then
		return true
	elseif ( str == "@" and ply:IsAdmin() ) then
		return true
	elseif ( str == "!@" and !ply:IsAdmin() ) then
		return true
	elseif ( string.sub(str,1,1) == "#" and string.lower( string.Replace( team.GetName( ply:Team() ), " ", "" ) ) == string.sub( str, 2 ) ) then
		return true
	elseif ( string.sub(str,1,2) == "!#" and string.lower( string.Replace( team.GetName( ply:Team() ), " ", "" ) ) != string.sub( str, 3 ) ) then
		return true
	elseif ( self.IsSteamID( str ) ) then
		return ply:SteamID() == str
	elseif ( string.Left( str, 1 ) == "\"" and string.Right( str, 1 ) == "\"" ) then
		return ( ply:Nick() == string.sub( str, 2, #str - 1 ) )
	else
		return ( string.lower( ply:Nick() ) == string.lower( str ) or string.find( string.lower( ply:Nick() ), string.lower( str ), nil, true ) )
	end
end

function evolve:FindPlayer( name, def, nonum, noimmunity )
	local matches = {}

	if ( !name or #name == 0 ) then
		matches[1] = def
	else
		if ( !istable( name ) ) then name = { name } end
		local name2 = table.Copy( name )
		if ( nonum ) then
			if ( #name2 > 1 and tonumber( name2[ #name2 ] ) ) then table.remove( name2, #name2 ) end
		end

		for _, ply in pairs( player.GetAll() ) do
			for _, pm in pairs( name2 ) do
				if ( self:IsNameMatch( ply, pm ) and !table.HasValue( matches, ply ) and ( noimmunity or !def or def:EV_BetterThanOrEqual( ply ) ) ) then table.insert( matches, ply ) end
			end
		end
	end

	return matches
end

function evolve:CreatePlayerList( tbl, notall )
	local lst = ""
	local lword = "and"
	if ( notall ) then lword = "or" end

	if ( #tbl == 1 ) then
		lst = tbl[1]:Nick()
	elseif ( #tbl == #player.GetAll() ) then
		lst = "everyone"
	else
		for i = 1, #tbl do
			if ( i == #tbl ) then lst = lst .. " " .. lword .. " " .. tbl[i]:Nick() elseif ( i == 1 ) then lst = tbl[i]:Nick() else lst = lst .. ", " .. tbl[i]:Nick() end
		end
	end

	return lst
end

/*-------------------------------------------------------------------------------------------------------------------------
	Ranks
-------------------------------------------------------------------------------------------------------------------------*/

EV_func_Player._IsAdmin=EV_func_Player.IsAdmin
function EV_func_Player:IsAdmin()
	return self:IsUserGroup("admin") or self:_IsAdmin() or self:IsSuperAdmin()
end
EV_func_Player.EV_IsAdmin=EV_func_Player.IsAdmin

EV_func_Player._IsSuperAdmin=EV_func_Player.IsSuperAdmin
function EV_func_Player:EV_IsSuperAdmin()
	return self:IsUserGroup("superadmin") or self:_IsSuperAdmin() or self:EV_IsOwner()
end
EV_func_Player.EV_IsSuperAdmin=EV_func_Player.IsSuperAdmin

function EV_func_Player:IsOwner()
	if ( SERVER ) then
		return self:EV_GetRank() == "owner" or self:IsListenServerHost()
	else
		return self:EV_GetRank() == "owner"
	end
end
EV_func_Player.EV_IsOwner=EV_func_Player.IsOwner

function EV_func_Player:IsRank( rank )
	return self:EV_GetRank() == rank
end
EV_func_Player.EV_IsRank=EV_func_Player.IsRank

/*-------------------------------------------------------------------------------------------------------------------------
	Console
-------------------------------------------------------------------------------------------------------------------------*/

function EV_func_Entity:Nick() if ( !self:IsValid() ) then return "Console" end end
function EV_func_Entity:EV_IsAdmin() if ( !self:IsValid() ) then return true end end
function EV_func_Entity:EV_IsSuperAdmin() if ( !self:IsValid() ) then return true end end
function EV_func_Entity:EV_IsOwner() if ( !self:IsValid() ) then return true end end
function EV_func_Entity:EV_GetRank() if ( !self:IsValid() ) then return "owner" end end
function EV_func_Entity:SteamID() if ( !self:IsValid() ) then return 0 end end

/*-------------------------------------------------------------------------------------------------------------------------
	User information
-------------------------------------------------------------------------------------------------------------------------*/

function evolve:SaveUsers()
	if CLIENT then return end
	self:SaveData(self.file.users,self.users)
end

function evolve:LoadUsers()
	if CLIENT then return end
	self.users = self:LoadData(self.file.users)
end
if SERVER then evolve:LoadUsers() end

function EV_func_Player:GetProperty( id, defaultvalue )
	if ( evolve.users[ self:SteamID() ] ) then
		return evolve.users[ self:SteamID() ][ id ] or defaultvalue
	else
		return defaultvalue
	end
end

function EV_func_Player:SetProperty( id, value )
	if ( !evolve.users[ self:SteamID() ] ) then evolve.users[ self:SteamID() ] = {} end

	evolve.users[ self:SteamID() ][ id ] = value
end

function EV_func_Player:GetIP()
	if ( !self:IsValid() or CLIENT ) then
		return "127.0.0.1"
	else
		return string.Explode(':',self:IPAddress())[1]
	end
end

function evolve:IsSteamID( steamid )
	return string.match( steamid or "", "STEAM_[0-5]:[0-9]:[0-9]+" )
end

function evolve:SteamIDByProperty( property, value, exact )
	for k, v in pairs( self.users ) do
		if ( v[ property ] == value ) then
			return k
		elseif ( !exact and string.find( string.lower( v[ property ] or "" ), string.lower( value ) ) ) then
			return k
		end
	end
end

function evolve:GetBySteamID( steamid )
	for k, v in pairs( player.GetAll() ) do
		if ( v:SteamID() == steamid ) then
			return v
		end
	end
	return
end

function evolve:GetProperty( steamid, id, defaultvalue )
	steamid = tostring( steamid )

	if ( self.users[ steamid ] ) then
		return self.users[ steamid ][ id ] or defaultvalue
	else
		return defaultvalue
	end
end

function evolve:SetProperty( steamid, id, value )
	steamid = tostring( steamid )
	if ( !self.users[ steamid ] ) then self.users[ steamid ] = {} end

	self.users[ steamid ][ id ] = value
end

/*-------------------------------------------------------------------------------------------------------------------------
	Check if a users file cleanup would be convenient
-------------------------------------------------------------------------------------------------------------------------*/
function evolve:CommitProperties()
	local count = table.Count( self.users )
	local maxrows = evolve.usersFileMax or 1000

	if ( count > maxrows ) then
		local original = count
		local info = {}
		for steamid, entry in pairs( self.users ) do
			table.insert( info, { STEAMID = steamid, Seen = tonumber(entry.Seen), Rank = entry.Rank } )
		end
		table.SortByMember( info, "Seen", function(a, b) return a > b end )

		for _, entry in pairs( info ) do
			if ( ( !entry.Banned ) and ( !entry.Rank or entry.Rank == "guest" ) ) then
				self.users[ entry.STEAMID ] = nil
				count = count - 1
				if ( count < maxrows ) then break end
			end
		end

		self:Message( "Cleaned up " .. original - count .. " players." )
	end

	self:SaveUsers()
end

/*-------------------------------------------------------------------------------------------------------------------------
	Entity ownership
-------------------------------------------------------------------------------------------------------------------------*/

hook.Add( "PlayerSpawnedProp", "EV_SpawnHook", function( ply, model, ent ) ent.EV_Owner = ply:SteamID() evolve:Log( evolve:PlayerLogStr( ply ) .. " spawned prop '" .. model .. "'." ) end )
hook.Add( "PlayerSpawnedSENT", "EV_SpawnHook", function( ply, ent ) ent.EV_Owner = ply:SteamID() evolve:Log( evolve:PlayerLogStr( ply ) .. " spawned scripted entity '" .. ent:GetClass() .. "'." ) end )
hook.Add( "PlayerSpawnedNPC", "EV_SpawnHook", function( ply, ent ) ent.EV_Owner = ply:SteamID() evolve:Log( evolve:PlayerLogStr( ply ) .. " spawned npc '" .. ent:GetClass() .. "'." ) end )
hook.Add( "PlayerSpawnedVehicle", "EV_SpawnHook", function( ply, ent ) ent.EV_Owner = ply:SteamID() evolve:Log( evolve:PlayerLogStr( ply ) .. " spawned vehicle '" .. ent:GetClass() .. "'." ) end )
hook.Add( "PlayerSpawnedEffect", "EV_SpawnHook", function( ply, model, ent ) ent.EV_Owner = ply:SteamID() evolve:Log( evolve:PlayerLogStr( ply ) .. " spawned effect '" .. model .. "'." ) end )
hook.Add( "PlayerSpawnedRagdoll", "EV_SpawnHook", function( ply, model, ent ) ent.EV_Owner = ply:SteamID() evolve:Log( evolve:PlayerLogStr( ply ) .. " spawned ragdoll '" .. model .. "'." ) end )

evolve.AddCount = EV_func_Player.AddCount
function EV_func_Player:AddCount( type, ent )
	ent.EV_Owner = self:SteamID()
	return evolve.AddCount( self, type, ent )
end

evolve.CleanupAdd = cleanup.Add
function cleanup.Add( ply, type, ent )
	if ( ent ) then ent.EV_Owner = ply:SteamID() end
	return evolve.CleanupAdd( ply, type, ent )
end

function EV_func_Entity:EV_GetOwner()
	return self.EV_Owner
end

/*-------------------------------------------------------------------------------------------------------------------------
	Ranks and Privileges
-------------------------------------------------------------------------------------------------------------------------*/

function EV_func_Player:EV_HasPrivilege( priv )
	if ( evolve.ranks[ self:EV_GetRank() ] ) then
		return self:EV_GetRank() == "owner" or table.HasValue( evolve.ranks[ self:EV_GetRank() ].Privileges, priv )
	else
		return false
	end
end

function EV_func_Entity:EV_BetterThan( ply )
	return true
end

function EV_func_Entity:EV_BetterThanOrEqual( ply )
	return true
end

function EV_func_Player:EV_BetterThan( ply )
	return tonumber( evolve.ranks[ self:EV_GetRank() ].Immunity ) > tonumber( evolve.ranks[ ply:EV_GetRank() ].Immunity ) or self == ply
end

function EV_func_Player:EV_BetterThanOrEqual( ply )
	return tonumber( evolve.ranks[ self:EV_GetRank() ].Immunity ) >= tonumber( evolve.ranks[ ply:EV_GetRank() ].Immunity )
end

function EV_func_Entity:EV_HasPrivilege( priv )
	if ( self == NULL ) then return true end
end

function EV_func_Entity:EV_BetterThan( ply )
	if ( self == NULL ) then return true end
end

function EV_func_Player:EV_SetRank( rank )
	self:SetProperty( "Rank", rank )
	evolve:CommitProperties()

	self:SetNWString( "EV_UserGroup", rank )

	evolve:RankGroup( self, rank )

	if ( self:EV_HasPrivilege( "Ban menu" ) ) then
		evolve:SyncBans( self )
	end
end

function EV_func_Player:GetRank()
	if ( !self:IsValid() ) then return false end
	if ( SERVER and self:IsListenServerHost() ) then return "owner" end

	local rank

	if ( SERVER ) then
		rank = self:GetProperty( "Rank", "guest" )
	else
		rank = self:GetNWString( "EV_UserGroup", "guest" )
	end

	if ( evolve.ranks[ rank ] ) then
		return rank
	else
		return "guest"
	end
end
EV_func_Player.EV_GetRank=EV_func_Player.GetRank

EV_func_Player._IsUserGroup=EV_func_Player.IsUserGroup
function EV_func_Player:IsUserGroup( group )
	if ( !self:IsValid() ) then return false end
	return self:GetNWString( "UserGroup" ) == group or evolve.ranks[ self:EV_GetRank() ].UserGroup == group
end

function evolve:RankGroup( ply, rank )
	ply:SetUserGroup( self.ranks[ rank ].UserGroup )
end

function evolve:Rank( ply )
	if ( !ply:IsValid() ) then return end

	self:TransferPrivileges( ply )
	self:TransferRanks( ply )

	if ( ply:IsListenServerHost() ) then ply:SetNWString( "EV_UserGroup", "owner" ) ply:SetNWString( "UserGroup", "superadmin" ) return end

	local usergroup = ply:GetNWString( "UserGroup", "guest" )
	if ( usergroup == "user" ) then usergroup = "guest" end
	ply:SetNWString( "EV_UserGroup", usergroup )

	local rank = ply:GetProperty( "Rank" )
	if ( rank and self.ranks[ rank ] ) then
		ply:SetNWString( "EV_UserGroup", rank )
		usergroup = rank
	end

	if ( ply:EV_HasPrivilege( "Ban menu" ) ) then
		self:SyncBans( ply )
	end

	self:RankGroup( ply, usergroup )
end

hook.Add("PostCleanupMap", "EV_PostCleanupHook", function()
	if SERVER then
		for k,v in pairs(player.GetAll()) do
			v.EV_Ranked=false
		end
	else
		LocalPlayer().EV_Ranked=false
	end
end)

hook.Add( "PlayerSpawn", "EV_RankHook", function( ply )
	if ( !ply.EV_Ranked ) then
		ply:SetNWString( "EV_UserGroup", ply:GetProperty( "Rank", "guest" ) )

		timer.Simple( 1, function()
			evolve:Rank( ply )
		end )
		ply.EV_Ranked = true

		ply:SetNWInt( "EV_Seen", evolve:Time() )
		ply:SetNWInt( "EV_Time", ply:GetProperty( "Time" ) or 0 )
		SendUserMessage( "EV_TimeSync", ply, evolve:Time() )
	end
end )

/*-------------------------------------------------------------------------------------------------------------------------
	Rank management
-------------------------------------------------------------------------------------------------------------------------*/

function evolve:SaveRanks()
	if CLIENT then return end
	self:SaveData(self.file.ranks,self.ranks)
end

function evolve:LoadRanks()
	if CLIENT then return end
	self.ranks = self:LoadData(self.file.ranks)
	if ( table.Count(self.ranks) == 0 ) then
		include( "defaultranks.ev.lua" ) -- NEEDS REWRITING
		self:SaveRanks()
	end
end
if SERVER then evolve:LoadRanks() end

function evolve:SyncRanks()
	for _, pl in pairs( player.GetAll() ) do self:TransferRanks( pl ) end
end

function evolve:TransferPrivileges( ply )
	if ( !ply:IsValid() ) then return end

	for id, privilege in pairs( self.privileges ) do
		umsg.Start( "EV_Privilege", ply )
			umsg.Short( id )
			umsg.String( privilege )
		umsg.End()
	end
end

function evolve:TransferRank( ply, rank )
	if ( !ply:IsValid() ) then return end

	local data = self.ranks[ rank ]
	local color = data.Color

	umsg.Start( "EV_Rank", ply )
		umsg.String( rank )
		umsg.String( data.Title )
		umsg.String( data.Icon )
		umsg.String( data.UserGroup )
		umsg.Short( data.Immunity )

		if ( color ) then
			umsg.Bool( true )
			umsg.Short( color.r )
			umsg.Short( color.g )
			umsg.Short( color.b )
		else
			umsg.Bool( false )
		end
	umsg.End()

	local privs = #( data.Privileges or {} )
	local count

	for i = 1, privs, 100 do
		count = math.min( privs, i + 99 ) - i

		umsg.Start( "EV_RankPrivileges", ply )
			umsg.String( rank )
			umsg.Short( count + 1 )

			for ii = i, i + count do
				umsg.Short( self:KeyByValue( self.privileges, data.Privileges[ii], ipairs ) )
			end
		umsg.End()
	end
end

function evolve:TransferRanks( ply )
	for id, data in pairs( self.ranks ) do
		self:TransferRank( ply, id )
	end
end

usermessage.Hook( "EV_Rank", function( um )
	local id = string.lower( um:ReadString() )
	local title = um:ReadString()
	local created = evolve.ranks[id] == nil

	evolve.ranks[id] = {
		Title = title,
		Icon = um:ReadString(),
		UserGroup = um:ReadString(),
		Immunity = um:ReadShort(),
		Privileges = {},
	}

	if ( um:ReadBool() ) then
		evolve.ranks[id].Color = Color( um:ReadShort(), um:ReadShort(), um:ReadShort() )
	end

	evolve.ranks[id].IconTexture = Material( "icon16/" .. evolve.ranks[id].Icon ..".png" )

	if ( created ) then
		hook.Call( "EV_RankCreated", nil, id )
	else
		hook.Call( "EV_RankUpdated", nil, id )
	end
end )

usermessage.Hook( "EV_Privilege", function( um )
	local id = um:ReadShort()
	local name = um:ReadString()

	evolve.privileges[ id ] = name
end )

usermessage.Hook( "EV_RankPrivileges", function( um )
	local rank = um:ReadString()
	local privilegeCount = um:ReadShort()

	for i = 1, privilegeCount do
		table.insert( evolve.ranks[ rank ].Privileges, evolve.privileges[ um:ReadShort() ] )
	end
end )

usermessage.Hook( "EV_RemoveRank", function( um )
	local rank = um:ReadString()
	hook.Call( "EV_RankRemoved", nil, rank )
	evolve.ranks[ rank ] = nil
end )

usermessage.Hook( "EV_RenameRank", function( um )
	local rank = um:ReadString():lower()
	evolve.ranks[ rank ].Title = um:ReadString()

	hook.Call( "EV_RankRenamed", nil, rank, evolve.ranks[ rank ].Title )
end )

usermessage.Hook( "EV_RankPrivilege", function( um )
	local rank = um:ReadString()
	local priv = evolve.privileges[ um:ReadShort() ]
	local enabled = um:ReadBool()

	if ( enabled ) then
		table.insert( evolve.ranks[ rank ].Privileges, priv )
	else
		table.remove( evolve.ranks[ rank ].Privileges, evolve:KeyByValue( evolve.ranks[ rank ].Privileges, priv ) )
	end

	hook.Call( "EV_RankPrivilegeChange", nil, rank, priv, enabled )
end )

usermessage.Hook( "EV_RankPrivilegeAll", function( um )
	local rank = um:ReadString()
	local enabled = um:ReadBool()
	local filter = um:ReadString()

	if ( enabled ) then
		for _, priv in pairs( evolve.privileges ) do
			if ( ( ( #filter == 0 and !string.match( priv, "[@:#]" ) ) or string.Left( priv, 1 ) == filter ) and !table.HasValue( evolve.ranks[rank].Privileges, priv ) ) then
				hook.Call( "EV_RankPrivilegeChange", nil, rank, priv, true )
				table.insert( evolve.ranks[ rank ].Privileges, priv )
			end
		end
	else
		local i = 1

		while ( i <= #evolve.ranks[rank].Privileges ) do
			if ( ( #filter == 0 and !string.match( evolve.ranks[rank].Privileges[i], "[@:#]" ) ) or string.Left( evolve.ranks[rank].Privileges[i], 1 ) == filter ) then
				hook.Call( "EV_RankPrivilegeChange", nil, rank, evolve.ranks[rank].Privileges[i], false )
				table.remove( evolve.ranks[rank].Privileges, i )
			else
				i = i + 1
			end
		end
	end
end )

/*-------------------------------------------------------------------------------------------------------------------------
	Rank modification
-------------------------------------------------------------------------------------------------------------------------*/

if ( SERVER ) then
	concommand.Add( "ev_Renamerank", function( ply, com, args )
		if ( ply:EV_HasPrivilege( "Rank modification" ) ) then
			if ( #args > 1 and evolve.ranks[ args[1] ] ) then
				evolve:Notify( evolve.colors.red, ply:Nick(), evolve.colors.white, " has renamed ", evolve.colors.blue, evolve.ranks[ args[1] ].Title, evolve.colors.white, " to ", evolve.colors.blue, table.concat( args, " ", 2 ), evolve.colors.white, "." )

				evolve.ranks[ args[1] ].Title = table.concat( args, " ", 2 )
				evolve:SaveRanks()

				umsg.Start( "EV_RenameRank" )
					umsg.String( args[1] )
					umsg.String( evolve.ranks[ args[1] ].Title )
				umsg.End()
			end
		end
	end )

	concommand.Add( "ev_setrank", function( ply, com, args )
		if ( ply:EV_HasPrivilege( "Rank modification" ) ) then
			if ( #args == 3 and args[1] != "owner" and evolve.ranks[ args[1] ] and table.HasValue( evolve.privileges, args[2] ) and tonumber( args[3] ) ) then
				local rank = args[1]
				local privilege = args[2]

				if ( tonumber( args[3] ) == 1 ) then
					if ( !table.HasValue( evolve.ranks[ rank ].Privileges, privilege ) ) then
						table.insert( evolve.ranks[ rank ].Privileges, privilege )
					end
				else
					if ( table.HasValue( evolve.ranks[ rank ].Privileges, privilege ) ) then
						table.remove( evolve.ranks[ rank ].Privileges, evolve:KeyByValue( evolve.ranks[ rank ].Privileges, privilege ) )
					end
				end

				evolve:SaveRanks()

				umsg.Start( "EV_RankPrivilege" )
					umsg.String( rank )
					umsg.Short( evolve:KeyByValue( evolve.privileges, privilege ) )
					umsg.Bool( tonumber( args[3] ) == 1 )
				umsg.End()
			elseif ( #args >= 2 and evolve.ranks[ args[1] ] and tonumber( args[2] ) and ( !args[3] or #args[3] == 1 ) ) then
				local rank = args[1]

				if ( tonumber( args[2] ) == 1 ) then
					for _, priv in pairs( evolve.privileges ) do
						if ( ( ( !args[3] and !string.match( priv, "[@:#]" ) ) or string.Left( priv, 1 ) == args[3] ) and !table.HasValue( evolve.ranks[ rank ].Privileges, priv ) ) then
							table.insert( evolve.ranks[ rank ].Privileges, priv )
						end
					end
				else
					local i = 1

					while ( i <= #evolve.ranks[rank].Privileges ) do
						if ( ( !args[3] and !string.match( evolve.ranks[rank].Privileges[i], "[@:#]" ) ) or string.Left( evolve.ranks[rank].Privileges[i], 1 ) == args[3] ) then
							table.remove( evolve.ranks[rank].Privileges, i )
						else
							i = i + 1
						end
					end
				end

				evolve:SaveRanks()

				umsg.Start( "EV_RankPrivilegeAll" )
					umsg.String( rank )
					umsg.Bool( tonumber( args[2] ) == 1 )
					umsg.String( args[3] or "" )
				umsg.End()
			end
		end
	end )

	concommand.Add( "ev_setrankp", function( ply, com, args )
		if ( ply:EV_HasPrivilege( "Rank modification" ) ) then
			if ( #args == 6 and tonumber( args[2] ) and evolve.ranks[ args[1] ] and ( args[3] == "guest" or args[3] == "admin" or args[3] == "superadmin" ) and tonumber( args[4] ) and tonumber( args[5] ) and tonumber( args[6] ) ) then
				if ( args[1] != "owner" ) then
					evolve.ranks[ args[1] ].Immunity = tonumber( args[2] )
					evolve.ranks[ args[1] ].UserGroup = args[3]
				end

				evolve.ranks[ args[1] ].Color = Color( args[4], args[5], args[6] )
				evolve:SaveRanks()

				for _, pl in pairs( player.GetAll() ) do
						evolve:TransferRank( pl, args[1] )

						if ( args[1] != "owner" and pl:EV_GetRank() == args[1] ) then
							pl:SetNWString( "UserGroup", args[3] )
						end
					end
			end
		end
	end )

	concommand.Add( "ev_Removerank", function( ply, com, args )
		if ( ply:EV_HasPrivilege( "Rank modification" ) ) then
			if ( args[1] != "guest" and args[1] != "owner" and evolve.ranks[ args[1] ] ) then
				evolve:Notify( evolve.colors.red, ply:Nick(), evolve.colors.white, " has removed the rank ", evolve.colors.blue, evolve.ranks[ args[1] ].Title, evolve.colors.white, "." )

				evolve.ranks[ args[1] ] = nil
				evolve:SaveRanks()

				for _, pl in pairs( player.GetAll() ) do
					if ( pl:EV_GetRank() == args[1] ) then
						pl:EV_SetRank( "guest" )
					end
				end

				umsg.Start( "EV_RemoveRank" )
					umsg.String( args[1] )
				umsg.End()
			end
		end
	end )

	concommand.Add( "ev_createrank", function( ply, com, args )
		if ( ply:EV_HasPrivilege( "Rank modification" ) ) then
			if ( ( #args == 2 or #args == 3 ) and !string.find( args[1], " " ) and string.lower( args[1] ) == args[1] and !evolve.ranks[ args[1] ] ) then
				if ( #args == 2 ) then
					evolve.ranks[ args[1] ] = {
						Title = args[2],
						Icon = "user",
						UserGroup = "guest",
						Immunity = 0,
						Privileges = {},
					}
				elseif ( #args == 3 and evolve.ranks[ args[3] ] ) then
					local parent = evolve.ranks[ args[3] ]

					evolve.ranks[ args[1] ] = {
						Title = args[2],
						Icon = parent.Icon,
						UserGroup = parent.UserGroup,
						Immunity = tonumber( parent.Immunity ),
						Privileges = table.Copy( parent.Privileges ),
					}
				end

				evolve:SaveRanks()
				evolve:SyncRanks()

				evolve:Notify( evolve.colors.red, ply:Nick(), evolve.colors.white, " has created the rank ", evolve.colors.blue, args[2], evolve.colors.white, "." )
			end
		end
	end )
end

/*-------------------------------------------------------------------------------------------------------------------------
	Banning
-------------------------------------------------------------------------------------------------------------------------*/

function evolve:SaveBans()
	if CLIENT then return end
	self:SaveData(self.file.bans,self.bans)
end

function evolve:LoadBans()
	if CLIENT then return end
	self.bans = self:LoadData(self.file.bans)
end
if SERVER then evolve:LoadBans() end

if SERVER then
	function evolve:SyncBans( ply )
		if ( self.bans and table.Count(self.bans) > 0 ) then
			for k,v in pairs(self.bans) do
				local time = tonumber(v.banend) - self:Time()
				if ( tonumber(v.banend) == 0 ) then time = 0 end
				SendUserMessage( "EV_BanEntry", ply, k, v.nick, v.reason, self:GetProperty( v.admin, "Nick" ), time )
			end
		end

	end

	function evolve:Ban( steamid, length, reason, adminsid )
		if ( length == 0 ) then length = -self:Time() end

		local a = "Console"
		if ( adminsid != 0 ) then a = self:GetBySteamID( adminsid ):Nick(); end
		SendUserMessage( "EV_BanEntry", nil, steamid, self:GetProperty( steamid, "Nick" ), reason, a, length )

		if ( self.bans ) then
			if ( self.bans[steamid] ) then
				table.Empty(self.bans[steamid])
				self.bans[steamid] = nil
			end
			self.bans[steamid] = {}
			self.bans[steamid].nick = self:GetProperty( steamid, "Nick" )
			self.bans[steamid].ip = self:GetProperty( steamid, "IP" )
			self.bans[steamid].reason = reason
			self.bans[steamid].length = tostring(math.max( 0, length ))
			self.bans[steamid].banend = tostring(self:Time()+length)
			self.bans[steamid].admin = adminsid

			self:SaveBans()
		end


		local pl
		if ( steamid != 0 ) then pl = self:GetBySteamID( steamid ) end

		if ( pl ) then
			game.ConsoleCommand( "banid " .. length / 60 .. " " .. pl:SteamID() .. "\n" )

			if ( length < 0 ) then
				pl:Kick( "Permabanned! (" .. reason .. ")" )
			else
				pl:Kick( "Banned for " .. length / 60 .. " minutes! (" .. reason .. ")" )
			end
		else
			if steamid!=nil and self:GetProperty( steamid, "IP" )!=nil and self:GetProperty( steamid, "IP" )!="N/A" then
				game.ConsoleCommand( "addip " .. length / 60 .. " \"" .. string.match( self:GetProperty( steamid, "IP" ), "(%d+%.%d+%.%d+%.%d+)" ) .. "\"\n" )
			end
			game.ConsoleCommand( "banid " .. length / 60 .. " " .. steamid .. "\n" )
		end
	end

	function evolve:UnBan( steamid, adminsid )
		SendUserMessage( "EV_RemoveBanEntry", nil, steamid )
		if ( self.bans ) then
			if ( self.bans[steamid] ) then
				table.Empty(self.bans[steamid])
				self.bans[steamid] = nil
			end
			self:SaveBans()
		end

		if steamid!=nil and self:GetProperty( steamid, "IP" )!=nil and self:GetProperty( steamid, "IP" )!="N/A" then
			game.ConsoleCommand( "removeip \"" .. ( self:GetProperty( steamid, "IP" ) or "" ) .. "\"\n" )
		end
		game.ConsoleCommand( "removeid " .. steamid .. "\n" )
	end

	function evolve:IsBanned( steamid )
		local banEnd
		if ( self.bans ) then
			if ( self.bans[steamid] ) then
				if ( self.bans[steamid].banend ) then
					banEnd = tonumber(self.bans[steamid].banend)
				else
					return true
				end
			end
		end

		if ( banEnd and banEnd > 0 and self:Time() > banEnd ) then
			self:UnBan( steamid )
			return false
		end
		if ((banEnd and ( banEnd > self:Time())) or banEnd == 0 ) then
			return true
		end
	end
else
	usermessage.Hook( "EV_BanEntry", function( um )
		if ( !evolve.bans ) then evolve.bans = {} end

		local SteamID = um:ReadString()
		evolve.bans[SteamID] =  {
			Nick = um:ReadString(),
			Reason = um:ReadString(),
			Admin = um:ReadString()
		}

		local time = um:ReadLong()
		if ( time > 0 ) then
			evolve.bans[SteamID].End = time + evolve:Time()
		else
			evolve.bans[SteamID].End = 0
		end

		hook.Call( "EV_BanAdded", nil, SteamID )
	end )

	usermessage.Hook( "EV_RemoveBanEntry", function( um )
		if ( !evolve.bans ) then return end

		local SteamID = um:ReadString()
		hook.Call( "EV_BanRemoved", nil, SteamID )
		evolve.bans[SteamID] = nil
	end )
end

/*-------------------------------------------------------------------------------------------------------------------------
	GlobalVar system
-------------------------------------------------------------------------------------------------------------------------*/

function evolve:SaveGlobalVars()
	if CLIENT then return end
	self:SaveData(self.file.globalvars,self.globalvars)
end

function evolve:LoadGlobalVars()
	if CLIENT then return end
	self.globalvars = self:LoadData(self.file.globalvars)
end
evolve:LoadGlobalVars()

function evolve:SetGlobalVar( name, value )
	self.globalvars[name] = value
	self:SaveGlobalVars()
end

function evolve:GetGlobalVar( name, default )
	return self.globalvars[name] or default
end

/*-------------------------------------------------------------------------------------------------------------------------
	Log system
-------------------------------------------------------------------------------------------------------------------------*/

function evolve:Log( str )
	if CLIENT then return end
	self:AppendFile( self.folder.logs .. self:FileDate() .. "_log", "[" .. self:Date("%Y-%m-%d %H:%M:%S %Z") .. "] " .. str .. "\n" )
end

function evolve:PlayerLogStr( ply )
	if ( ply and IsEntity(ply) and ply:IsValid() ) then
		if ( ply:IsPlayer() ) then
			return "[" .. ply:SteamID() .. "|" .. ply:GetIP() .. "] " .. ply:Nick()
		else
			return ply:GetClass()
		end
	else
		return "Console"
	end
end

/*-------------------------------------------------------------------------------------------------------------------------
	Hooks
-------------------------------------------------------------------------------------------------------------------------*/

hook.Add( "InitPostEntity", "EV_LogInit", function()
	evolve:Log( "== Started in map '" .. game.GetMap() .. "' and gamemode '" .. GAMEMODE.Name .. "' ==" )
end )

hook.Add( "PlayerDisconnected", "EV_LogDisconnect", function( ply )
	evolve:Log( evolve:PlayerLogStr( ply ) .. " disconnected from the server." )
end )

hook.Add( "PlayerInitialSpawn", "EV_LogSpawn", function( ply )
	evolve:SyncBans(ply)
	evolve:Log( evolve:PlayerLogStr( ply ) .. " spawned for the first time this session." )
end )

hook.Add( "PlayerConnect", "EV_LogConnect", function( name, address )
	evolve:Log( name .. " connected to the server." )
end )

hook.Add( "PlayerDeath", "EV_LogDeath", function( ply, inf, killer )
	if ( ply != killer ) then
		evolve:Log( evolve:PlayerLogStr( ply ) .. " was killed by " .. evolve:PlayerLogStr( killer ) .. "." )
	end
end )

hook.Add( "PlayerSay", "EV_PlayerChat", function( ply, txt )
	evolve:Log( evolve:PlayerLogStr( ply ) .. ": " ..  txt )
end )
