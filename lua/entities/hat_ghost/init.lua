AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = "models/props_halloween/smlprop_ghost.mdl"
ENT.Name = "Ghost"

resource.AddFile( ENT.Model )
resource.AddFile( "materials/"..string.StripExtension(ENT.Model)..".vmt" )