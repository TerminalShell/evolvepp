AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = "models/gmod_tower/fedorahat.mdl"
ENT.Name = "Fedora"

resource.AddFile( ENT.Model )
resource.AddFile( "materials/"..string.StripExtension(ENT.Model)..".vmt" )
resource.AddFile( "materials/"..string.StripExtension(ENT.Model).."2.vmt" )