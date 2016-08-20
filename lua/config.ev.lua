/*-------------------------------------------------------------------------------------------------------------------------
	Evolve++ Configuration Variables
-------------------------------------------------------------------------------------------------------------------------*/

-- Standard console command prefix (eg. "ev rank <user> guest")
evolve.prefix = "ev"

-- Silent console command prefix (eg. "evs rank <user> guest")
evolve.prefixSilent = "evs"

-- Standard chat command prefix (eg. "!rank <user> guest")
evolve.chatPrefix = { "!", "/" }

-- Silent chat command prefix (eg. "@rank <user> guest")
evolve.chatPrefixSilent = { "@" }

-- Timezone offset (offsets from server time, only change if you notice the time is wrong for things like logs)
evolve.timeOffset = 0

-- Maximum number of players to store in the users table at a given time (smaller uses less memory and filesize, but means less players are tracked)
evolve.usersFileMax = 1000