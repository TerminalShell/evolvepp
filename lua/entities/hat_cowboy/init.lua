AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = "models/player/items/engineer/engineer_cowboy_hat.mdl"
ENT.Name = "Cowboy Hat"

resource.AddFile( ENT.Model )
resource.AddFile( "materials/"..string.StripExtension(ENT.Model)..".vmt" )
resource.AddFile( "materials/"..string.StripExtension(ENT.Model).."_pick.vmt" )
resource.AddFile( "materials/"..string.StripExtension(ENT.Model).."2.vmt" )