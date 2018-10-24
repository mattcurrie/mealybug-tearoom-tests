# The Comprehensive Game Boy PPU Documentation

These are my notes/findings based on the results of my test ROMs and subsequent implementation in my Game Boy emulator: [Beaten Dying Moon](https://mattcurrie.com/bdm-demo/)

Familiarity with Kevin Horton's [Nitty Gritty Gameboy Cycle Timing](http://blog.kevtris.org/blogfiles/Nitty%20Gritty%20Gameboy%20VRAM%20Timing.txt) is assumed.  

Any corrections or improvements are welcomed, especially for any already "known" information.

## Registers

### SCY `$FF42`

The `SCY` register controls the Y scroll of the background tile map.  

The `SCY` register can be written to at any time. Writes will take effect immediately on the DMG. On CGB and AGB devices, writes appear to take effect 2 T-cycles later.

On the DMG and CGB revisions up to and including the "CPU GBC C" revision, the `SCY` register is read during the background tile fetch `B`, `0` and `1` stages.

On the AGB and CGB revisions "CPU GBC D" and greater, the `SCY` register is only read during the `B` stage.


