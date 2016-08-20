AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.NoRemoveOnDeath = true
ENT.Model = ""
ENT.Name = "Unnamed"

function ENT:Initialize()
	self:DrawShadow(false)
	self:SetModel(self.Model)
end
function ENT:Think()
end
