# Per-game OpenComposite override template

Copy this directory to `<appid>-<slug>/` (for example `617830-superhot-vr`) and
adjust the files to your game.

## Files

- `opencomposite.ini` (optional) - render/haptics tunables. Same syntax as the
  global file; valid options are limited (see `../../global/opencomposite.ini`).
- `bindings_<profile>.json` (optional, one per controller profile) - SteamVR
  Input binding file copied from the game install dir then edited. For Quest
  headsets the relevant profile is `oculus_touch`.
- `actions.json` (rarely needed) - action manifest override. Only if you need
  to add or rename actions, which is unusual.

## Audit checklist for a new game

1. Locate the install dir, for example
   `/games/SteamLibrary/steamapps/common/<game>/`.
2. List the SteamVR Input files shipped by the game:
   `ls *.json | grep -E "action|binding"`.
3. Open `actions.json` to discover the action ids the game uses
   (`/actions/default/in/*`).
4. Open `bindings_oculus_touch.json` to see how those actions are mapped to
   the Touch controller paths.
5. Identify the offending mapping (which action triggers when you do not want
   it, which one does not trigger at all).
6. Copy the binding file into this directory, edit the offending entries,
   keep everything else as-is.
7. Document the diff in `NOTES.md` so a future reader knows why we override.

## Activation

In Steam: right-click the game, `Properties -> Launch Options`, type:

```
oc-launch %command%
```

Then launch the game. Check `~/.local/state/oc-launch/<appid>-*.log` for the
deployment trace.
