AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = "models/gmod_tower/afro.mdl"
ENT.Name = "Afro"

resource.AddFile( ENT.Model )
resource.AddFile( "materials/"..string.StripExtension(ENT.Model)..".vmt" )
resource.AddFile( "materials/"..string.StripExtension(ENT.Model).."_pick.vmt" )
resource.AddFile( "materials/"..string.StripExtension(ENT.Model).."2.vmt" )