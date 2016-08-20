AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = "models/naitosears/woxears.mdl"
ENT.Name = "Wolf Ears"

resource.AddFile( ENT.Model )
resource.AddFile( "materials/"..string.StripExtension(ENT.Model)..".vmt" )