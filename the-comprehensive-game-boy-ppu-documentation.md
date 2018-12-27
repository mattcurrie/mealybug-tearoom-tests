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

- Using bitplane 1 data from most recently drawn sprite as bitplane data
- Using the tile index as bitplane data (excluding CPU-CGB-D)
- Using bitplane 0 data instead of bitplane 1 data (only CPU-CGB-D)


### SCY `$FF42`

The `SCY` register controls the Y scroll of the background tile map.  

The `SCY` register can be written to at any time. Writes will take effect immediately on the DMG. On CGB and AGB devices, writes appear to take effect 2 T-cycles later.

On the DMG and CGB revisions up to and including the "CPU GBC C" revision, the `SCY` register is read during the background tile fetch `B`, `0` and `1` stages. Changing the value during background tile data fetch allows for mixing tile bitplane data from different rows of the tile.

On the AGB and CGB revisions "CPU GBC D" and greater, the `SCY` register is only read during the `B` stage, so no tile bitplane data mixing can occur.


