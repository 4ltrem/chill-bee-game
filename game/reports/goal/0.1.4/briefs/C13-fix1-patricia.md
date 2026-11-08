Goal agent run `0.1.4`, fix round 1 for goal C13 of `game/specs/0.1.4-ui-placement.md`, branch `milestone/0.1.4`. These checks failed after the last step. Fix what is in your folder only; if the failure is in another folder or in the spec, say so instead. Do not commit.

Your folder: scripts/

tests:
FAIL    unit      137 passed, 1 failed  (exit 1, 202 noise lines dropped)  game/reports/_runs/20261107-235910/unit.log
    FAIL  t_camera_pan_seconds  after a live change to 2.5 the pan took 2.444 s +- 0.053 s  (6113 ms)

Spec text:
13. **Centrifuge text sits on the centrifuge** (designer's play-test of 0.1.4, 2026-11-08: "the centrifuge helper text should stay on top of the centrifgue not screen position locked"). `CentrifugeLabel` ("Honey: x / y" and the crank hint) is fixed at screen (24, 245) in `FarmUI` today. It follows the centrifuge's lid anchor through the same anchor-follow component as Harvest, Spin and Sell (item 2), sitting above the centrifuge in every view, clamped inside the screen and clear of Spin and Back.

Reply in at most 150 words.