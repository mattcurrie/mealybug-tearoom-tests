; Copyright (C) 2019 Matt Currie <me@mattcurrie.com>
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in
; all copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

INCLUDE "inc/hardware.inc"
INCLUDE "inc/utils.s"

SECTION "wram", WRAM0

counter::
    ds 1


SECTION "vblank_interrupt", ROM0[$40]

    jp _vblank_handler


SECTION "lcdc_stat_interrupt", ROM0[$48]

    jp _lcdc_stat_int_handler


SECTION "boot", ROM0[$100]

    nop         
    jp main      


SECTION "main", ROM0[$150]

main::
    di
    ld sp, $fffe

    xor a
    ld [counter], a

    call reset_registers
    call reset_oam
    call reset_tile_maps
    call copy_font
    call set_default_dmg_palettes
    call set_default_cgb_palettes

    ld hl, aligned_sprite_data 
    ld c, aligned_sprite_data.end - aligned_sprite_data
    call oam_copy

    init_lcdc_stat_int_test

    ld a, STATF_MODE10  ; mode 2 - OAM scan
    ldh [rSTAT], a

    ld a, IEF_VBLANK | IEF_LCDC
    ldh [rIE], a
    xor a
    ldh [rIF], a

    ei
    jp nop_slide
 

_vblank_handler::
    ; let it run for 10 frames
    ld a, [counter]
    inc a
    ld [counter], a

    cp 10
    jr nz, .skip

    ; source code breakpoint - good time to take a screenshot to compare
    ld b,b

.skip:
    add sp, 2
    ei
    jp nop_slide


_lcdc_stat_int_handler::
    line_0_fix

    ; don't do anything after line 64
    cp 64
    jr nc, .skip

    lcdc_stat_int

.skip:
    add sp, 2
    ei
    jp nop_slide

   
init_bg_maps_alphabetical_9800::
    ld a, 1
    ld [rVBK], a

    ; background is filled with palette 1 on 8 rows
    ld de, 8
    ld hl, $9800
    ld b, 1
.attr_outer:
    ld c, 24
    ld a, b
.attr_inner:
    ld [hl+], a
    dec c
    jr nz, .attr_inner

    add hl, de
    bit 0, h       ; bit 0 will be set when value of h register is $9900
    jr z, .attr_outer

    xor a
    ld [rVBK], a

    ; background is filled with 'ABC...' on 8 rows
    ld de, 8
    ld hl, $9800
    ld b, "A"
.tile_outer:
    ld c, 24
    ld a, b
.tile_inner:   
    ld [hl+], a
    inc a
    dec c
    jr nz, .tile_inner

    add hl, de
    bit 0, h       ; bit 0 will be set when value of h register is $9900
    jr z, .tile_outer
  
    ret


init_bg_maps_alphabetical_9c00::
    ld a, 1
    ld [rVBK], a

    ; background is filled with palette 2 on 8 rows
    ld de, 8
    ld hl, $9c00
    ld b, 2
.attr_outer:
    ld c, 24
    ld a, b
.attr_inner:   
    ld [hl+], a
    dec c
    jr nz, .attr_inner

    add hl, de
    bit 0, h       ; bit 0 will be set when value of h register is $9d00
    jr z, .attr_outer

    xor a
    ld [rVBK], a

    ; background is filled with 'ZYX...' on 8 rows
    ld de, 8
    ld hl, $9c00
    ld b, "Z"
.tile_outer:
    ld c, 24
    ld a, b
.tile_inner:   
    ld [hl+], a
    dec a
    dec c
    jr nz, .tile_inner

    add hl, de
    bit 0, h       ; bit 0 will be set when value of h register is $9d00
    jr z, .tile_outer

    ret


set_default_dmg_palettes::
    ld a, $e4
    ldh [rBGP], a
    ldh [rOBP0], a
    ldh [rOBP1], a
    ret


set_default_cgb_palettes::
    ld hl, cgb_background_palette
    ld b, cgb_background_palette.end - cgb_background_palette
    ld a, $80
    ldh [rBCPS], a
    call copy_bg_color_palette_data

    ld hl, cgb_object_palette
    ld b, cgb_object_palette.end - cgb_object_palette
    ld a, $80
    ldh [rOCPS], a
    call copy_obj_color_palette_data

    ret


nop_slide:
    REPT 2400
    nop
    ENDR
    ; just in case we slide off the end
    jp nop_slide


aligned_sprite_data::
    DB $10,  1, " ", 0
    DB $10, 10, "0", 0  ; 6 + 4 + 6 + 3 = 19
    DB $18,  1, " ", 0
    DB $18, 11, "1", 0  ; 6 + 4 + 6 + 2 = 18 
    DB $20,  1, " ", 0
    DB $20, 12, "2", 0  ; 6 + 4 + 6 + 1 = 17
    DB $28,  1, " ", 0
    DB $28, 13, "3", 0  ; 6 + 4 + 6 + 0 = 16
    DB $30,  5, " ", 0
    DB $30, 10, "4", 0  ; 6 + 0 + 6 + 3 = 15
    DB $38,  5, " ", 0
    DB $38, 11, "5", 0  ; 6 + 0 + 6 + 2 = 14
    DB $40,  5, " ", 0
    DB $40, 12, "6", 0  ; 6 + 0 + 6 + 1 = 13
    DB $48,  5, " ", 0
    DB $48, 13, "7", 0  ; 6 + 0 + 6 + 0 = 12
.end:


cgb_background_palette::
    cgb_color 31, 31, 31
    cgb_color 21, 21, 21
    cgb_color 11, 11, 11
    cgb_color 0, 0, 0    

    ; bg palette 1 - gbr
    cgb_color 31, 31, 31
    cgb_color 0, 31, 0
    cgb_color 31, 0, 0
    cgb_color 0, 0, 31

    ; bg palette 2 - cga
    cgb_color 31, 31, 0
    cgb_color 31, 0, 31
    cgb_color 0, 31, 31
    cgb_color 0, 0, 0
.end:


cgb_object_palette::
    ; obj palette 0 - shades of red
    cgb_color 0, 0, 0           ; transparent
    cgb_color 31, 31, 0
    cgb_color 21, 21, 0
    cgb_color 11, 11, 0

    REPT 4 * 7
    ; remaining entries black
    cgb_color 0, 0, 0
    ENDR
.end:
