## 2024-10-24, Xavier

GOAL: Set up devenv.

Cloned repo to mod directory.

PROBLEM: Mod doesn't load when launching debug. `modfiles` subdirectory needs to
be at the root level. Renamed repo directory to something else and made a
windows shortcut. Didn't work. Copy+pasted directory to verify it should work.

Found how to create "proper" symlinks on windows:

    New-Item -Path factoryplanner -ItemType SymbolicLink -Value .\factoryplannerrepo\modfiles

Works.

PROBLEM: Scenarios don't show up.

Symlinked `scenarios` directory into `modfiles`. Probably would be cleaner to
symlink into user directory. Reference:
https://wiki.factorio.com/Tutorial:Mod_structure

PROBLEM: misc crashes loading testing scenario. Liberal commenting out and
updating to 2.0 (e.g. `global` to `storage`) got the scenario booting, though
not doing anything.