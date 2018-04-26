# Mealybug Tearoom Tests

Game Boy emulator tests.


## About

This project contains some test ROMs I wrote to verify the correctness of my Game Boy emulator - [Beaten Dying Moon](https://mattcurrie.com/bdm-demo/).

Currently the tests focus on changes made to the PPU registers during STAT mode 3. This allows you to verify correct timing of the background tile and sprite data fetches as each scanline is rendered.


## Requirements

- RGBDS is required if you want to build the test ROMs yourself
- A Game Boy emulator and/or real Game Boy and flash cart to test on


## Usage

- Clone or download the project and run ```make``` from the root directory. The test ROMs will be placed in the ```build``` directory.  You can also download an [archive of the ROMs](mealybug-tearoom-tests.zip).
- Check the results. You can check in the ```expected``` directory for screenshots from my Game Boy emulator (which I believe to be correct), and the ```photos``` directory contains blurry photos of the ROMs running on real devices. My logic analyzer is in the post so I can try [capturing screenshots from the real device](https://github.com/svendahlstrand/game-boy-lcd-sniffing) :)