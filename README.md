# Mealybug Tearoom Tests

Game Boy emulator test ROMs.


## About

This project contains some test ROMs I wrote to verify the correctness of my Game Boy emulator - [Beaten Dying Moon](https://mattcurrie.com/bdm-demo/).

Currently the tests focus on changes made to the PPU registers during STAT mode 3. This allows you to verify correct timing of the background tile and sprite data fetches as each scanline is rendered.

These tests examine very specific PPU behaviour/timings, so will give different results on a DMG compared to a CGB. Currently there are only expected result screenshots for when running on a DMG.

These tests are written to be easily automated. See the usage section below for details.

## Screenshots

Pictures are always interesting so here are some:

![m3_background_palette_change](/expected/DMG-blob/m3_background_palette_change.png?raw=true "m3_background_palette_change")
![m3_background_palette_change_sprites](/expected/DMG-blob/m3_background_palette_change_sprites.png?raw=true "m3_background_palette_change_sprites")
![m3_lcdc_bit_1_change](/expected/DMG-blob/m3_lcdc_bit_1_change.png?raw=true "m3_lcdc_bit_1_change")
![m3_sprite_palette_change](/expected/DMG-blob/m3_sprite_palette_change.png?raw=true "m3_sprite_palette_change")

![m3_wx_4_change](/expected/DMG-blob/m3_wx_4_change.png?raw=true "m3_wx_4_change")
![m3_wx_4_change_sprites](/expected/DMG-blob/m3_wx_4_change_sprites.png?raw=true "m3_wx_4_change_sprites")
![m3_wx_5_change](/expected/DMG-blob/m3_wx_5_change.png?raw=true "m3_wx_5_change")
![m3_wx_6_change](/expected/DMG-blob/m3_wx_6_change.png?raw=true "m3_wx_6_change")

## Requirements

- RGBDS is required if you want to build the test ROMs yourself
- A Game Boy emulator and/or real Game Boy and flash cart to test on


## Usage

- Clone or download the project and run ```make``` from the root directory. The test ROMs will be placed in the ```build``` directory.  You can also download an [archive of the ROMs](mealybug-tearoom-tests.zip).
- Check the results. You can check in the ```expected``` directory for screenshots from my Game Boy emulator (which I believe to be correct), and the ```photos``` directory contains blurry photos of the ROMs running on real devices. My logic analyzer is in the post so I can try [capturing screenshots from the real device](https://github.com/svendahlstrand/game-boy-lcd-sniffing) :)
- Automated testing can be achieved using the ```compare``` command from imagemagick to get the number of pixels that are different when comparing the expected image to a screenshot from an emulator.  The screenshot from the emulator can be generated when the ```LD B,B``` software breakpoint is encountered. The screenshot from the emulator should use these colour values in greyscale images or in RGB components to ensure the images can be compared correctly: ```$00```, ```$55```, ```$AA```, ```$FF``` 

  An example imagemagick compare command is below. ```result``` will contain the number of pixels that differ between the two images, so ```0``` indicates success.

   ```result=$(compare -metric AE emulator-screenshot.png expected-result.png NULL: 2>&1)```
