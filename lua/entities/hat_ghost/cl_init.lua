include("shared.lua")
ENT.PositionUp = 5
ENT.PositionForward = 0
ENT.PositionRight = 10
ENT.RotateUp = 0
ENT.RotateForward = 0
ENT.RotateRight = 0
ENT.Scale = Vector(.5, .5, .5)
ENT.MoveCenter = 5
ENT.MoveSpeed = 0.0275
ENT.MoveDist = 1.5
ENT.I = 0

function ENT:Think()
	self.PositionUp = math.sin(self.I) * self.MoveDist + self.MoveCenter
	self.I = (self.I + self.MoveSpeed) % ( 2 * math.pi )
end