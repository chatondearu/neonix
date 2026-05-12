# SUPERHOT VR (appid 617830) - OpenComposite override

## Why this override exists

In the stock `bindings_oculus_touch.json` shipped by the game, both `grab`
and `mindwave` are mapped to the **grip button**, differentiated only by
`mode = trigger` (pull) versus `mode = button` (click). On Touch controllers
(Quest 1/2/3) the grip is an analog squeeze, so the runtime cannot reliably
disambiguate "click" from "pull", which means:

- `grab` triggers when you only wanted `mindwave`, and vice versa.
- `mindwave` is hard to fire on demand because any squeeze also counts as grab.

## What we changed

- `mindwave` removed from `/user/hand/left/input/grip` and
  `/user/hand/right/input/grip` (button mode entries).
- `mindwave` re-mapped to the two free face buttons that the game never used:
  - left hand: `/user/hand/left/input/y` (click)
  - right hand: `/user/hand/right/input/b` (click)
- The `menu` binding on `X` (long press) was moved to `A` (long press) on the
  right hand to mirror the layout on Quest Touch (X exists only on the left
  Touch; the stock file accidentally referenced X on both hands).

Everything else is byte-identical to the stock file.

## Diff summary vs stock

```text
- click grip -> mindwave (both hands)
+ click Y    -> mindwave (left)
+ click B    -> mindwave (right)

- long X     -> menu (right hand)
+ long A     -> menu (right hand)
```

## How to re-apply or revert

- Apply: ensure `oc-launch %command%` is set in Steam launch options.
- Revert to stock: `oc-launch restore 617830`.
