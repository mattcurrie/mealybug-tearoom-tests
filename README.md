# Mealybug Tearoom Tests

Game Boy emulator test ROMs.


## About

This project contains some test ROMs I wrote to verify the correctness of my Game Boy emulator - [Beaten Dying Moon](https://mattcurrie.com/bdm-demo/).

Currently the tests focus on changes made to the PPU registers during STAT mode 3. This allows you to verify correct timing of the background tile and sprite data fetches as each scanline is rendered.

These tests examine very specific PPU behaviour/timings, so produce different results on a DMG compared to a CGB. There are expected result screenshots for when running on a DMG, and CPU CGB C and CPU CGB D (for most tests).

These tests are written to be easily automated. See the usage section below for details.

## Screenshots

Pictures are always interesting so here are some screenshots showing the expected results on DMG:

![m2_win_en_toggle](/expected/DMG-blob/m2_win_en_toggle.png?raw=true "m2_win_en_toggle")
![m3_lcdc_bg_map_change](/expected/DMG-blob/m3_lcdc_bg_map_change.png?raw=true "m3_lcdc_bg_map_change")
![m3_lcdc_tile_sel_change](/expected/DMG-blob/m3_lcdc_tile_sel_change.png?raw=true "m3_lcdc_tile_sel_change")
![m3_lcdc_win_map_change](/expected/DMG-blob/m3_lcdc_win_map_change.png?raw=true "m3_lcdc_win_map_change")
![m3_lcdc_win_en_change_multiple](/expected/DMG-blob/m3_lcdc_win_en_change_multiple.png?raw=true "m3_lcdc_win_en_change_multiple")
![m3_lcdc_win_en_change_multiple_wx](/expected/DMG-blob/m3_lcdc_win_en_change_multiple_wx.png?raw=true "m3_lcdc_win_en_change_multiple_wx")
![m3_window_timing](/expected/DMG-blob/m3_window_timing.png?raw=true "m3_window_timing")
![m3_window_timing_wx_0](/expected/DMG-blob/m3_window_timing_wx_0.png?raw=true "m3_window_timing_wx_0")
![m3_lcdc_tile_sel_win_change](/expected/DMG-blob/m3_lcdc_tile_sel_win_change.png?raw=true "m3_lcdc_tile_sel_win_change")
![m3_lcdc_obj_en_change](/expected/DMG-blob/m3_lcdc_obj_en_change.png?raw=true "m3_lcdc_obj_en_change")
![m3_lcdc_obj_en_change_variant](/expected/DMG-blob/m3_lcdc_obj_en_change_variant.png?raw=true "m3_lcdc_obj_en_change_variant")
![m3_lcdc_bg_en_change](/expected/DMG-blob/m3_lcdc_bg_en_change.png?raw=true "m3_lcdc_bg_en_change")
![m3_lcdc_obj_size_change](/expected/DMG-blob/m3_lcdc_obj_size_change.png?raw=true "m3_lcdc_obj_size_change")
![m3_lcdc_obj_size_change_scx](/expected/DMG-blob/m3_lcdc_obj_size_change_scx.png?raw=true "m3_lcdc_obj_size_change_scx")
![m3_bgp_change](/expected/DMG-blob/m3_bgp_change.png?raw=true "m3_bgp_change")
![m3_bgp_change_sprites](/expected/DMG-blob/m3_bgp_change_sprites.png?raw=true "m3_bgp_change_sprites")
![m3_obp0_change](/expected/DMG-blob/m3_obp0_change.png?raw=true "m3_obp0_change")
![m3_scx_low_3_bits](/expected/DMG-blob/m3_scx_low_3_bits.png?raw=true "m3_scx_low_3_bits")
![m3_scx_high_5_bits](/expected/DMG-blob/m3_scx_high_5_bits.png?raw=true "m3_scx_high_5_bits")
![m3_scy_change](/expected/DMG-blob/m3_scy_change.png?raw=true "m3_scy_change")
![m3_wx_4_change](/expected/DMG-blob/m3_wx_4_change.png?raw=true "m3_wx_4_change")
![m3_wx_4_change_sprites](/expected/DMG-blob/m3_wx_4_change_sprites.png?raw=true "m3_wx_4_change_sprites")
![m3_wx_5_change](/expected/DMG-blob/m3_wx_5_change.png?raw=true "m3_wx_5_change")
![m3_wx_6_change](/expected/DMG-blob/m3_wx_6_change.png?raw=true "m3_wx_6_change")
![m3_lcdc_bg_en_change2](/expected/CPU%20CGB%20C/m3_lcdc_bg_en_change2.png?raw=true "m3_lcdc_bg_en_change2")
![m3_lcdc_bg_map_change2](/expected/CPU%20CGB%20C/m3_lcdc_bg_map_change2.png?raw=true "m3_lcdc_bg_map_change2")
![m3_lcdc_tile_sel_change2](/expected/CPU%20CGB%20C/m3_lcdc_tile_sel_change2.png?raw=true "m3_lcdc_tile_sel_change2")
![m3_lcdc_tile_sel_win_change2](/expected/CPU%20CGB%20C/m3_lcdc_tile_sel_win_change2.png?raw=true "m3_lcdc_tile_sel_win_change2")
![m3_lcdc_win_map_change2](/expected/CPU%20CGB%20C/m3_lcdc_win_map_change2.png?raw=true "m3_lcdc_win_map_change2")
![m3_scx_high_5_bits_change2](/expected/CPU%20CGB%20C/m3_scx_high_5_bits_change2.png?raw=true "m3_scx_high_5_bits_change2")
![m3_scy_change2](/expected/CPU%20CGB%20C/m3_scy_change2.png?raw=true "m3_scy_change2")

## Requirements

- RGBDS is required if you want to build the test ROMs yourself
- A Game Boy emulator and/or real Game Boy and flash cart to test on


## Usage

- Clone or download the project and run ```make``` from the root directory. The test ROMs will be placed in the ```build``` directory.  You can also download an [archive of the ROMs](mealybug-tearoom-tests.zip).
- Check the results. You can check in the ```expected``` directory for screenshots from my Game Boy emulator (which I believe to be correct), and the ```photos``` directory contains blurry photos of the ROMs running on real devices. 
- Automated testing can be achieved using the ```compare``` command from imagemagick to get the number of pixels that are different when comparing the expected image to a screenshot from an emulator.  
- The screenshot from the emulator should be generated when the ```LD B,B``` software breakpoint is encountered. 
- A DMG emulator should use these 8-bit values in greyscale images or in RGB components to ensure the images can be compared correctly: ```$00```, ```$55```, ```$AA```, ```$FF``` 
- A CGB emulator should use this formula to convert 5-bit CGB palette components to 8-bit: ```(r << 3) | (r >> 2)```

  An example imagemagick compare command is below. ```result``` will contain the number of pixels that differ between the two images, so ```0``` indicates success.

   ```result=$(compare -metric AE emulator-screenshot.png expected-result.png NULL: 2>&1)```
