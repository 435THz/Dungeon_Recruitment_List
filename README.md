# Dungeon Recruitment List
By: MistressNebula

This [PMDO](https://github.com/audinowho/PMDODump/releases) mod adds
an option to the Others menu that allows players to view the current
floor or an entire dungeon's spawn list.
It also shows which Pokémon have already been recruited.

**Warning**: longer dungeon lists can take a bit to load.

This mod is currently not compatible with
[Halcyon](https://github.com/Palikadude/Halcyon/releases) and any
other mod that edits the ```services/debug_tools_init.lua``` file.
A Halcyon version of this mod *IS* in the works, however, so stay
tuned for future updates

### How the mod operates
This mod adds a Recruits option to the game's Others menu.
This new sub-menu contains 4 more options:

1. **Dungeons/List**: The top option changes depending on your
location. It will be "List" when  inside a dungeon, and "Dungeons"
outside.
    - **Dungeons**: When choosing this option, the game will load a
list of all Dungeons you have even just partially explored. Choose
one, and the game will show you all Pokémon that can be recruited
in the portion of the dungeon you have explored and where to find
them. Just be mindful: this can be a slow process, and the bigger
dungeons can take some seconds to load.
    - **List**: Choose this option and the game will show you the
list of all pokémon that are or can appear on your current floor.
Pokémon that can spawn but you have never met yet will be listed
as a "???". You will also see any recruitable Pokémon that is on
the floor but is not listed to spawn, as long as you've met their
species before. These will be marked with a different color and will
always be placed at the bottom of the list.
2. **Info**: Shows what is essentially a recap of this README, but
in-game and in a more compact format.
3. **Colors**: Lists the various colors used in the mod to 
differentiate which pokémon have already been recruited and which ones
do or do not respawn upon defeat.
4. **Options**: Displays a toggle option to activate the mod's
*Spoiler Mode*. If *Spoiler Mode* is on, then you will be unable to
see the current floor's spawn list if it's your first visit.
This option can only be accessed outside of dungeons.