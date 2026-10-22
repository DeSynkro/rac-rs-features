# Xbox button artwork

The button prompts in the game can show the buttons the way an Xbox pad does
instead of the retail's own PlayStation glyphs. These are the pictures they use.

| the retail's glyph | code | the picture | the Xbox's name |
|---|---|---|---|
| Cross | `0x10` | `a.png` | A |
| Circle | `0x11` | `b.png` | B |
| Triangle | `0x12` | `y.png` | Y |
| Square | `0x13` | `x.png` | X |
| L1 | `0x14` | `lb.png` | LB |
| R1 | `0x15` | `rb.png` | RB |
| L2 | `0x16` | `lt.png` | LT |
| R2 | `0x17` | `rt.png` | RT |
| right stick | `0x18` | `rs.png` | R3 |
| left stick | `0x19` | `ls.png` | L3 |

The pictures are 480 by 480 pixels with an alpha channel. The game scales them
down to the size of the prompt's button cell, so they can be replaced with
anything of the same kind.

The rest of the set (the D-pad, the stick directions and the Menu, View, Back
and Start buttons) has no cell in the retail's font, so it is not in this
folder.

## Licence

Xbox Buttons (c) 2020 by ArksDigital, from https://arks.itch.io/xbox-buttons,
licensed under the Creative Commons Attribution 4.0 International licence
(CC BY 4.0), https://creativecommons.org/licenses/by/4.0/.

The changes made here: the pictures were renamed, and the ones this fork does
not use were left out.
