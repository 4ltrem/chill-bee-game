<!-- style_critic_check.py, 2026-11-05; overwritten each run -->

### Critic, round 1
VERDICT: FAIL
| # | Rule | Shot | Finding | Fix |
|---|---|---|---|---|
| 1 | V10 | disabled-low-contrast.png | The disabled "Upgrade (not enough money)" button at the bottom has grey text on a dark brown-grey panel. The text is only slightly lighter than the fill, and I estimate its contrast at about 1.3:1, well under 4.5:1. The label is barely readable. | Make the disabled label cream (1.0, 0.96, 0.86) on the panel colour, or lighten the text until it reaches at least 4.5:1. Show the disabled state with a dimmer fill or a lock icon, and keep the text legible. |
| 2 | V7 | disabled-low-contrast.png | The green terrain diamond runs past the left and right screen edges at mid-height. The side corner tiles are cut off, so the diorama does not sit whole in the frame. | Scale the terrain or pull the camera back so the full diamond fits inside the 720 px width with a margin. (minor) |
