/*-------------------------------------------------------------------------------------------------------------------------
	Default ranks
-------------------------------------------------------------------------------------------------------------------------*/

evolve.ranks.guest = {}
evolve.ranks.guest.Title = "Guest"
evolve.ranks.guest.Icon = "user"
evolve.ranks.guest.NotRemovable = true
evolve.ranks.guest.UserGroup = "guest"
evolve.ranks.guest.Immunity = 0
evolve.ranks.guest.Privileges = {}

evolve.ranks.respected = {}
evolve.ranks.respected.Title = "Member"
evolve.ranks.respected.Icon = "user_add"
evolve.ranks.respected.UserGroup = "guest"
evolve.ranks.respected.Immunity = 25
evolve.ranks.respected.Privileges = {}

evolve.ranks.admin = {}
evolve.ranks.admin.Title = "Admin"
evolve.ranks.admin.Icon = "shield"
evolve.ranks.admin.UserGroup = "admin"
evolve.ranks.admin.Immunity = 50
evolve.ranks.admin.Privileges = {}

evolve.ranks.superadmin = {}
evolve.ranks.superadmin.Title = "Super Admin"
evolve.ranks.superadmin.Icon = "shield_add"
evolve.ranks.superadmin.UserGroup = "superadmin"
evolve.ranks.superadmin.Immunity = 75
evolve.ranks.superadmin.Privileges = {}

evolve.ranks.owner = {}
evolve.ranks.owner.Title = "Owner"
evolve.ranks.owner.Icon = "key"
evolve.ranks.owner.ReadOnly = true
evolve.ranks.owner.UserGroup = "superadmin"
evolve.ranks.owner.Immunity = 99