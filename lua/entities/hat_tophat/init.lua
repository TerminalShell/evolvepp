AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = "models/gmod_tower/tophat.mdl"
ENT.Name = "Tophat"

resource.AddFile( ENT.Model )
resource.AddFile( "materials/"..string.StripExtension(ENT.Model)..".vmt" )