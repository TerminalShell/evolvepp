DISPLAYHATS = true
SPEC_TEAM = TEAM_SPECTATOR or -1
include("shared.lua")

ENT.LowerBound = Vector(-40, -40, -18)
ENT.UpperBound = Vector(40, 40, 84)
ENT.Scale = Vector(1.0, 1.0, 1.0)
ENT.PositionForward = 0
ENT.PositionRight = 0
ENT.PositionUp = 0
ENT.RotateForward = 0
ENT.RotateRight = 0
ENT.RotateUp = 0
//ENT.Color = Color(255,255,255,255)

function ENT:Initialize()
	self:DrawShadow(false)
	self:SetRenderBounds(self.LowerBound, self.UpperBound)
end

function ENT:Draw()
	local owner = self:GetOwner()
	if !IsEntity(owner) then return end
	local radius = 25 -- How close to hide hats
	if DISPLAYHATS and LocalPlayer():IsPlayer() and LocalPlayer():Team() ~= SPEC_TEAM and owner:Team() ~= SPEC_TEAM then
		if not owner:IsValid() or owner == LocalPlayer() and owner:Alive() and owner:Team() ~= SPEC_TEAM then return end
		
		if ( self:GetModel() == 'models/error.mdl' ) then return end
		
		if owner:GetRagdollEntity() then
			owner = owner:GetRagdollEntity()
		elseif not owner:Alive() then return end

		local boneindex = owner:LookupBone("ValveBiped.Bip01_Head1")
		if boneindex then
			local pos, ang = owner:GetBonePosition(boneindex)
			if pos and pos ~= owner:GetPos() then
				//self:SetColor(self.Color)
				self:SetPos(pos + (ang:Forward()*self.PositionUp)+(ang:Right()*self.PositionForward)+(ang:Up()*self.PositionRight))
				ang:RotateAroundAxis(ang:Forward(), (self.RotateUp-90)%360-180)
				ang:RotateAroundAxis(ang:Right(), (self.RotateForward+90)%360-180)
				ang:RotateAroundAxis(ang:Up(), (self.RotateRight)%360-180)
				self:SetAngles(ang)
				local mat = Matrix()
				mat:Scale( self.Scale )
				self:EnableMatrix( "RenderMultiply", mat )
				if owner:IsPlayer() and LocalPlayer():Team() == owner:Team() then
					local eyepos = EyePos()
					local dist = owner:NearestPoint(EyePos()):Distance(EyePos())
					if dist < radius then
						return
					end
				end
				self:DrawModel()
				return
			end
		end

		local attach = owner:GetAttachment(owner:LookupAttachment("eyes"))
		if not attach then attach = owner:GetAttachment(owner:LookupAttachment("head")) end
		if attach then
			//self:SetColor(self.Color)
			self:SetPos(attach.Pos)
			self:SetAngles(attach.Ang)
			local mat = Matrix()
			mat:Scale( self.Scale )
			self:EnableMatrix( "RenderMultiply", mat )
			if LocalPlayer():Team() == owner:Team() then
				local eyepos = EyePos()
				local dist = owner:NearestPoint(eyepos):Distance(eyepos)
				if dist < radius then
					return
				end
			end
			self:DrawModel()
		end
	end
end
