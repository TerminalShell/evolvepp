include("shared.lua")
ENT.Scale = Vector(2.2, 2.2, 2.2)
ENT.Emitter = nil


function ENT:Initialize()
	self:DrawShadow(false)
	self:SetRenderBounds(Vector(-40, -40, -18), Vector(40, 40, 90))

	self.Emitter = ParticleEmitter(self:GetPos())
	self.Emitter:SetNearClip(40, 50)
	self.NextEmit = 0
end

function ENT:OnRemove()
	self.Emitter:Finish()
end

function ENT:Think()
	self.Emitter:SetPos(self:GetPos())
end

function ENT:Draw()
	local owner = self:GetOwner()
	if DISPLAYHATS and LocalPlayer():Team() ~= TEAM_SPECTATORS and owner:Team() ~= TEAM_SPECTATOR then
	if not owner:IsValid() or owner == LocalPlayer() and not NOX_VIEW and owner:Alive() and owner:Team() ~= TEAM_SPECTATOR then return end

	if owner:GetRagdollEntity() then
		owner = owner:GetRagdollEntity()
	elseif not owner:Alive() then return end

	local boneindex = owner:LookupBone("ValveBiped.Bip01_Head1")
	if boneindex then
		local pos, ang = owner:GetBonePosition(boneindex)
		if pos and pos ~= owner:GetPos() then
			local col = owner:GetColor()
			col.a = math.max(1,col.a)
			self:SetColor(col)
			self:SetPos(pos + ang:Forward() * 4)
			ang:RotateAroundAxis(ang:Up(), 90)
			ang:RotateAroundAxis(ang:Right(), 180)
			ang:RotateAroundAxis(ang:Forward(), 90)
			self:SetAngles(ang)
			local mat = Matrix()
			mat:Scale( self.Scale )
			self:EnableMatrix( "RenderMultiply", mat )
			self:DrawModel()

			if 200 < col.a and self.NextEmit < CurTime() and LocalPlayer():IsValid() then
				self.NextEmit = CurTime() + 0.1
				local particle = self.Emitter:Add("effects/fire_cloud1", pos + LocalPlayer():GetAimVector() * -2)
				particle:SetVelocity(owner:GetVelocity())
				particle:SetDieTime(math.Rand(0.8, 1))
				particle:SetStartAlpha(255)
				particle:SetStartSize(math.Rand(6, 14))
				particle:SetEndSize(0)
				particle:SetRoll(math.Rand(0, 360))
				particle:SetRollDelta(math.Rand(-1, 1))
				particle:SetGravity(Vector(0,0,125))
				particle:SetCollide(true)
				particle:SetAirResistance(12)
			end
			return
		end
	end

	local attach = owner:GetAttachment(owner:LookupAttachment("eyes"))
	if not attach then attach = owner:GetAttachment(owner:LookupAttachment("head")) end
	if attach then
		local col = owner:GetColor()
		col.a = math.max(1,col.a)
		self:SetColor(col)
		self:SetAngles(attach.Ang)
		local mat = Matrix()
		mat:Scale( self.Scale )
		self:EnableMatrix( "RenderMultiply", mat )
		local pos = attach.Pos
		self:SetPos(pos)
		self:DrawModel()

		if 200 < a and self.NextEmit < CurTime() and LocalPlayer():IsValid() then
			self.NextEmit = CurTime() + 0.1
			local particle = self.Emitter:Add("effects/fire_cloud1", pos + LocalPlayer():GetAimVector() * -2)
			particle:SetVelocity(owner:GetVelocity())
			particle:SetDieTime(math.Rand(0.8, 1))
			particle:SetStartAlpha(255)
			particle:SetStartSize(math.Rand(6, 14))
			particle:SetEndSize(0)
			particle:SetRoll(math.Rand(0, 360))
			particle:SetRollDelta(math.Rand(-1, 1))
			particle:SetGravity(Vector(0,0,125))
			particle:SetCollide(true)
			particle:SetAirResistance(12)
		end
	end
	end
end
