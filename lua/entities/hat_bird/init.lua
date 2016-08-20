AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = "models/player/items/medic/archimedes.mdl"
ENT.Name = "Bird"

resource.AddFile( ENT.Model )
resource.AddFile( "materials/"..string.StripExtension(ENT.Model)..".vmt" )