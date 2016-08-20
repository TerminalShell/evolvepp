# ($>) Terminal Shell - Evolve++

# Description
Evolve++ is an easy to use extensible server administration mod for Garry's Mod. Based on Evolve from Overv, ported which was ported by Northdegree to Garry's Mod 13. It's primary feature is it's plugin system, which are easy to create and dynamically loadable

## Installation
Place the `/evolvepp/` directory in your `/garrysmod/addons/` folder, and check `/evolvepp/lua/config.ev.lua` for anything you might want to change.

Be sure to download the plugins and add them to your `/garrysmod/data/evolvepp/lua/plugins/` folder as well. While the Evolve++ framework will technically function without them, the following are highly recommended, as without them you wont be able to run commands or set ranks:

- `sh_consolecommands.lua.ev.txt`
- `sh_chatcommands.lua.ev.txt`
- `sh_ranks.lua.ev.txt`

I also recommend the following for help with running commands:

- `cl_autocomplete.lua.ev.txt`
- `sh_commandlist.lua.ev.txt`

Beyond that, you can [download the plugins and menus](https://github.com/TerminalShell/evolvepp_plugins) you like, or even create your own. You can find the ones made by us here:

[https://github.com/TerminalShell/evolvepp_plugins](https://github.com/TerminalShell/evolvepp_plugins)

## Help Questions

### How to become owner

If you're running a listen server, you're always owner. If you're running a dedicated server, join your server and type the following in the dedicated server console:

- `ev rank <YOUR_NAME> owner`

### How to make people admin, or set their rank

There are a few ways, assuming you have the permissions to do so:

- Type in chat: `!rank playername <RANK>`
- Type in console: `ev rank <PLAYER_NAME> <RANK>`
- Type in the dedicated server console: `ev rank <PLAYER_NAME> <RANK>`
- Use the in-game menu: `Select player -> Administration -> Rank -> Admin/Super Admin`

The following ranks are available by default:

- guest
- member
- admin
- superadmin
- owner

People can only be set to or removed from the rank of owner from the server console. Owner has all permissions by default, and all other ranks have no permissions by default.

### How to open the in-game menu

Open your console and type `bind <KEY> +ev_menu`

Pushing and holding the key in-game will now expand the menu, and releasing it will close it.