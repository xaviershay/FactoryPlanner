## 2024-10-25, Xavier

PROBLEM: Need test suite to actually do something. Start uncommenting and
actually figure out what's going on.

Need to make `Factory` constant available in `tests.lua`.

    local Factory = require("__factoryplanner__.backend.data.Factory")

require works, but has picket up the `init` and `unpack` functions. `get`
doesn't exist anymore, but looking at usage plausible that `unpack` is the
replacement function ... but has a different API.

Hrmm maybe not, looking at type of `import_factory`.

`process_export_string` is returning `nil`, breakpointing to step through it.

We're getting a migration failure.

So: the test fixture data is in an old format. 1.1.42. This is before 1.1.60 which is first migratable version.
So: we need new fixture data. Can we export from mod? Or simply construct by looking at data constructors?

The fixture data is created in `parts.lua`, which hard codes version strings.

Confirmed can export a string from mod proper, so let's use that and try to reverse engineer.

Ok it loads now, but solving fails because factory is not in a district. (Line:get_surface_compatibility)

Let's try regening with a district? Feel like it might still fail coz we're in a testenv and no surfaces?
Actually maybe just looking for compat between district and machines/recipes.

So factory export from ingame mod is specific just to factory and doesn't include district. So we need another way to rehydrate that data.
For now will comment out in `Line` and see if we can make progress.

Found one more line trying to find pollution type, commented that out also.

Altered test body to locate an item in the factory as a proof-of-concept.

Messy, but this _is_ technically testing something now.

The default District initialiser contains a default location, so adding one of
those to the test subfactory lets us remove hacks.

Added print to control.lua so that results are printed to console as well as file.
Pretty sure the code to dump errors to results.txt is broken, but don't care at this point.

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