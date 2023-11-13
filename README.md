# Dungeon Recruitment List
By: MistressNebula

This [PMDO](https://github.com/audinowho/PMDODump/releases) mod allows
the player to access the full Recruitment List of explored dungeons,
accessible from the Others menu while in a Ground Map.
This list shows all Recruitable Pokémon up to the highest reached
floor of a dungeon, complete with the exact floor number you can find
those Pokémon at.
It even contains some explanation screens and an icon mode.

Using ths mod in dev mode will display unrecruitable Pokémon, as well.

**Warning**: longer dungeon lists can take some seconds to load.

This mod is currently not compatible with
[Halcyon](https://github.com/Palikadude/Halcyon/releases) and any
other mod that edits the ```services/debug_tools_init.lua``` file.
A Halcyon version of this mod *IS* in the works, however, so stay
tuned for future updates.

### How the mod operates
This mod swaps the Recruitment Search option in the game's Others
with a Recruit one.
This new sub-menu is also accessible outside of dungeons and contains
4 more options:

1. **Dungeons/List**: The top option changes depending on your
location. It will be "List" when inside a dungeon, and "Dungeons"
outside.
    - **Dungeons**: When choosing this option, the game will load a
list of all Dungeons you have even just partially explored. Choose
one, and the game will show you all Pokémon that can be recruited
in the portion of the dungeon you have explored and where to find
them. Just be mindful: this can be a slow process, and the bigger
dungeons can take some seconds to load.
    - **List**: Choose this option and the game will show you the
game's regular Recruitment Search screen.
2. **Info**: Shows what is essentially a recap of this README, but
in-game and in a more compact format.
3. **Colors**: Lists the various colors used in the mod to 
differentiate which pokémon have already been recruited and which ones
do or do not respawn upon defeat.
4. **Options**: Displays a toggle option for the mod's
*Spoiler Mode* and *Icon Mode*. If *Spoiler Mode* is on, then you
will be unable to see the current floor's spawn list if it's your
first visit, and if *Icon Mode* is on, the list will also use special
icon markers to distinguish between caught, non-caught and special 
spawning pokémon.
This option can only be accessed outside of dungeons.