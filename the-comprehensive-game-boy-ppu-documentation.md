# The Comprehensive Game Boy PPU Documentation

These are my notes/findings based on the results of my test ROMs and subsequent implementation in my Game Boy emulator: [Beaten Dying Moon](https://mattcurrie.com/bdm-demo/)

Familiarity with Kevin Horton's [Nitty Gritty Gameboy Cycle Timing](http://blog.kevtris.org/blogfiles/Nitty%20Gritty%20Gameboy%20VRAM%20Timing.txt) is assumed.  

Any corrections or improvements are welcomed, especially for any already "known" information.

## Registers

### LCDC `$FF40`

#### TILE_SEL (bit 4)

The `TILE_SEL` bit of the `LCDC` register controls which area of VRAM is accessed when reading tile bitplane data.

| TILE_SEL | VRAM Range               |
| -------- | ------------------------ |
|        0 | $8800 - $97FF            |
|        1 | $8000 - $8FFF (OBJ area) |

The value of this bit can be written to at any time.

`TILE_SEL` is read during the `0` and `1` stages of background tile data fetching. Changing its value during background tile data fetch allows for mixing tile bitplane data from two different tile patterns.

On the CGB, there is strange behaviour if the value of this bit changes on particular T-cycles of the background tile data fetch. The following behaviour has been observed:

- On all CGB revisions, setting `TILE_SEL` on the same T-cycle as a bitplane data read will cause it to use either:
  - bitplane 1 data from the most recently drawn sprite as bitplane data, if any, or
  - bitplane 1 data from the most recently drawn tile as when `TILE_SEL` was last reset, if any, or
  - bitplane 0 or 1 data from the read in progress during pixel 159/160 (?) on the previous row when the tile fetcher is interrupted. The timing of which bitplane is selected differs between CGB revisions.
- On all CGB revisions, excluding CPU CGB D, resetting `TILE_SEL` on the same T-cycle as a bitplane data read will cause the **tile index** to be instead used as the data for that bitplane.
- On CPU CGB D, resetting `TILE_SEL` on the same T-cycle as the bitplane 1 data read will cause the PPU to instead read the bitplane data from the address for bitplane 0.

#### WIN_EN (bit 5)

If WIN_EN is set then the window will be displayed when the WX and WY conditions are satisifed.

Obscure behavior:

- WIN_EN can be disabled during mode 3.  The disabling will take effect at the end of the current window tile being drawn. When the current window tile has finished being drawn, the PPU will start drawing background tiles again.
- When the background resumes drawing it is on a tile boundary. The low 3 bits of SCX have no effect. 
- Setting WIN_EN again during mode 3 on the same scanline will have no effect unless WX has been updated to set the window to activate on a pixel that hasn't been drawn yet.
- If WX has been updated correctly and WIN_EN is set again then the PPU stops drawing the background, and will activate the window again, but it will start drawing the **next row** of the window, on the same scanline.

### SCY `$FF42`

The `SCY` register controls the Y scroll of the background tile map.  

The `SCY` register can be written to at any time. Writes will take effect immediately on the DMG. On CGB and AGB devices, writes appear to take effect 2 T-cycles later.

On the DMG and CGB revisions up to and including the "CPU GBC C" revision, the `SCY` register is read during the background tile fetch `B`, `0` and `1` stages. Changing the value during background tile data fetch allows for mixing tile bitplane data from different rows of the tile.

On the AGB and CGB revisions "CPU GBC D" and greater, the `SCY` register is only read during the `B` stage, so no tile bitplane data mixing can occur.


