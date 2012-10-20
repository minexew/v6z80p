
object_loc_list     dw spr_object0,spr_object1,spr_object2,spr_object3
                    dw spr_object4,spr_object5,spr_object6,spr_object7
                    dw spr_object8,spr_object9,spr_objecta,spr_objectb
                    dw spr_objectc,spr_objectd,spr_objecte,spr_objectf
                    
                    dw spr_object10,spr_object11,spr_object12,spr_object13
                    dw spr_object14,spr_object15,spr_object16,spr_object17
                    dw spr_object18,spr_object19,spr_object1a,spr_object1b
                    dw spr_object1c,spr_object1d,spr_object1e,spr_object1f
                    
                    dw spr_object20,spr_object21,spr_object22,spr_object23
                    dw spr_object24,spr_object25,spr_object26,spr_object27
                    dw spr_object28,spr_object29,spr_object2a,spr_object2b
                    dw spr_object2c,spr_object2d,spr_object2e,spr_object2f
                    
                    dw spr_object30,spr_object31,spr_object32,spr_object33
                    dw spr_object34,spr_object35,spr_object36,spr_object37
                    dw spr_object38,spr_object39,spr_object3a,spr_object3b
                    dw spr_object3c,spr_object3d,spr_object3e,spr_object3f
                    
                    dw spr_object40,spr_object41,spr_object42,spr_object43
                    dw spr_object44,spr_object45,spr_object46,spr_object47
                    dw spr_object48,spr_object49,spr_object4a,spr_object4b
                    dw spr_object4c,spr_object4d,spr_object4e,spr_object4f
                    
                    dw spr_object50,spr_object51,spr_object52,spr_object53
                    dw spr_object54,spr_object55,spr_object56,spr_object57
                    dw spr_object58,spr_object59,spr_object5a,spr_object5b
                    dw spr_object5c,spr_object5d,spr_object5e,spr_object5f
                    
                    dw spr_object60,spr_object61,spr_object62,spr_object63
                    dw spr_object64,spr_object65,spr_object66,spr_object67
                    dw spr_object68,spr_object69,spr_object6a,spr_object6b
                    dw spr_object6c,spr_object6d,spr_object6e,spr_object6f
                    
                    dw spr_object70,spr_object71,spr_object72,spr_object73
                    dw spr_object74,spr_object75,spr_object76,spr_object77
                    dw spr_object78,spr_object79,spr_object7a,spr_object7b
                    dw spr_object7c,spr_object7d,spr_object7e,spr_object7f
                    
                    dw spr_object80,spr_object81,spr_object82,spr_object83
                    dw spr_object84,spr_object85,spr_object86,spr_object87
                    dw spr_object88,spr_object89,spr_object8a,spr_object8b
                    dw spr_object8c,spr_object8d,spr_object8e,spr_object8f
                    
                    dw spr_object90,spr_object91,spr_object92,spr_object93
                    dw spr_object94,spr_object95,spr_object96,spr_object97
                    dw spr_object98,spr_object99,spr_object9a,spr_object9b
                    dw spr_object9c,spr_object9d,spr_object9e,spr_object9f
                    
                    dw spr_objecta0,spr_objecta1,spr_objecta2,spr_objecta3
                    dw spr_objecta4,spr_objecta5,spr_objecta6,spr_objecta7
                    dw spr_objecta8,spr_objecta9,spr_objectaa,spr_objectab
                    dw spr_objectac,spr_objectad,spr_objectae,spr_objectaf
                    
                    dw spr_objectb0,spr_objectb1,spr_objectb2,spr_objectb3
                    dw spr_objectb4,spr_objectb5,spr_objectb6,spr_objectb7
                    dw spr_objectb8,spr_objectb9,spr_objectba,spr_objectbb
                    dw spr_objectbc,spr_objectbd,spr_objectbe,spr_objectbf
                    
                    dw spr_objectc0,spr_objectc1,spr_objectc2,spr_objectc3
                    dw spr_objectc4,spr_objectc5,spr_objectc6,spr_objectc7
                    dw spr_objectc8,spr_objectc9,spr_objectca,spr_objectcb
                    dw spr_objectcc,spr_objectcd,spr_objectce,spr_objectcf

                    dw spr_objectd0,spr_objectd1,spr_objectd2,spr_objectd3
                    dw spr_objectd4,spr_objectd5,spr_objectd6,spr_objectd7
                    dw spr_objectd8,spr_objectd9,spr_objectda,spr_objectdb
                    dw spr_objectdc,spr_objectdd,spr_objectde,spr_objectdf
                    
                    dw spr_objecte0,spr_objecte1,spr_objecte2,spr_objecte3
                    

;===== Null object =========================================================================================

spr_object0         db $01    ;number of sprites required by this object
                    
                    db $00    ;x offset from origin for sprite 0                    -.
                    db $00    ;y offset from origin for sprite 0                     . For each sprite
                    db $00    ;sprite definition (LSB) for sprite 0                  . of object
                    db $10    ;y height for sprite 0 in pixels AND $F0 OR defn MSB  -' 

;===== Ball object ==========================================================================================


spr_object1         db $02    ;number of sprites required by this object
                    
                    db $f0    ;x offset from origin for sprite 0                    -.
                    db $f0    ;y offset from origin for sprite 0                     . For each sprite
                    db $03    ;sprite definition (LSB) for sprite 0                  . of object
                    db $20    ;y height for sprite 0 in pixels AND $F0 OR defn MSB  -' 

                    db $00
                    db $f0
                    db $13
                    db $20
                    
;-----------------------------------------------------------------------------------------------------------

spr_object2         db $02    ;number of sprites required by this object
                    
                    db $f0    ;x offset from origin for sprite 0                    -.
                    db $f0    ;y offset from origin for sprite 0                     . For each sprite
                    db $05    ;sprite definition (LSB) for sprite 0                  . of object
                    db $20    ;y height for sprite 0 in pixels AND $F0 OR defn MSB  -' 

                    db $00
                    db $f0
                    db $15
                    db $20
                    
;-----------------------------------------------------------------------------------------------------------

spr_object3         db $02    ;number of sprites required by this object
                    
                    db $f0    ;x offset from origin for sprite 0                    -.
                    db $f0    ;y offset from origin for sprite 0                     . For each sprite
                    db $07    ;sprite definition (LSB) for sprite 0                  . of object
                    db $20    ;y height for sprite 0 in pixels AND $F0 OR defn MSB  -' 

                    db $00
                    db $f0
                    db $17
                    db $20
                    
;-----------------------------------------------------------------------------------------------------------

spr_object4         db $02    ;number of sprites required by this object
                    
                    db $f0    ;x offset from origin for sprite 0                    -.
                    db $f0    ;y offset from origin for sprite 0                     . For each sprite
                    db $09    ;sprite definition (LSB) for sprite 0                  . of object
                    db $20    ;y height for sprite 0 in pixels AND $F0 OR defn MSB  -' 

                    db $00
                    db $f0
                    db $19
                    db $20
                    
;-----------------------------------------------------------------------------------------------------------

spr_object5         db $02    ;number of sprites required by this object
                    
                    db $f0    ;x offset from origin for sprite 0                    -.
                    db $f0    ;y offset from origin for sprite 0                     . For each sprite
                    db $0b    ;sprite definition (LSB) for sprite 0                  . of object
                    db $20    ;y height for sprite 0 in pixels AND $F0 OR defn MSB  -' 

                    db $00
                    db $f0
                    db $1b
                    db $20
                    
;-----------------------------------------------------------------------------------------------------------

spr_object6         db $02    ;number of sprites required by this object
                    
                    db $f0    ;x offset from origin for sprite 0                    -.
                    db $f0    ;y offset from origin for sprite 0                     . For each sprite
                    db $0d    ;sprite definition (LSB) for sprite 0                  . of object
                    db $20    ;y height for sprite 0 in pixels AND $F0 OR defn MSB  -' 

                    db $00
                    db $f0
                    db $1d
                    db $20

;-----------------------------------------------------------------------------------------------------------

spr_object7         db $02    ;number of sprites required by this object
                    
                    db $f0    ;x offset from origin for sprite 0                    -.
                    db $f0    ;y offset from origin for sprite 0                     . For each sprite
                    db $0f    ;sprite definition (LSB) for sprite 0                  . of object
                    db $20    ;y height for sprite 0 in pixels AND $F0 OR defn MSB  -' 

                    db $00
                    db $f0
                    db $1f
                    db $20

;-----------------------------------------------------------------------------------------------------------

spr_object8         db $02    ;number of sprites required by this object
                    
                    db $f0    ;x offset from origin for sprite 0                    -.
                    db $f0    ;y offset from origin for sprite 0                     . For each sprite
                    db $01    ;sprite definition (LSB) for sprite 0                  . of object
                    db $20    ;y height for sprite 0 in pixels AND $F0 OR defn MSB  -' 

                    db $00
                    db $f0
                    db $11
                    db $20
                    
;-----------------------------------------------------------------------------------------------------------

spr_object9         db $01
                    
                    db $f8
                    db $f8
                    db $21
                    db $10

;-----------------------------------------------------------------------------------------------------------
spr_objecta         db $01
                    
                    db $f8
                    db $f8
                    db $22
                    db $10

;-----------------------------------------------------------------------------------------------------------
spr_objectb         db $01
                    
                    db $f8
                    db $f8
                    db $23
                    db $10

;-----------------------------------------------------------------------------------------------------------
spr_objectc         db $01
                    
                    db $f8
                    db $f8
                    db $24
                    db $10

;-----------------------------------------------------------------------------------------------------------
spr_objectd         db $01
                    
                    db $f8
                    db $f8
                    db $25
                    db $10

;-----------------------------------------------------------------------------------------------------------
spr_objecte         db $01
                    
                    db $f8
                    db $f8
                    db $26
                    db $10

;-----------------------------------------------------------------------------------------------------------

spr_objectf         db $01
                    
                    db $f8
                    db $f8
                    db $27
                    db $10

;-----------------------------------------------------------------------------------------------------------
spr_object10        db $01
                    
                    db $f8
                    db $f8
                    db $28
                    db $10

;-----------------------------------------------------------------------------------------------------------
spr_object11        db $01
                    
                    db $f8
                    db $f8
                    db $29
                    db $10

;-----------------------------------------------------------------------------------------------------------
spr_object12        db $01
                    
                    db $f8
                    db $f8
                    db $2a
                    db $10

;-----------------------------------------------------------------------------------------------------------
spr_object13        db $01
                    
                    db $f8
                    db $f8
                    db $2b
                    db $10

;-----------------------------------------------------------------------------------------------------------
spr_object14        db $01
                    
                    db $f8
                    db $f8
                    db $2c
                    db $10

;-----------------------------------------------------------------------------------------------------------
spr_object15        db $01
                    
                    db $f8
                    db $f8
                    db $2d
                    db $10

;-----------------------------------------------------------------------------------------------------------
spr_object16        db $01
                    
                    db $f8
                    db $f8
                    db $2e
                    db $10

;-----------------------------------------------------------------------------------------------------------
spr_object17        db $02    ;number of sprites required by this object
                    
                    db $f0    ;x offset from origin for sprite 0                    -.
                    db $f0    ;y offset from origin for sprite 0                     . For each sprite
                    db $2f    ;sprite definition (LSB) for sprite 0                  . of object
                    db $20    ;y height for sprite 0 in pixels AND $F0 OR defn MSB  -' 

                    db $00
                    db $f0
                    db $3d
                    db $20
                    
;-----------------------------------------------------------------------------------------------------------

spr_object18        db $02    ;number of sprites required by this object
                    
                    db $f0    ;x offset from origin for sprite 0                    -.
                    db $f0    ;y offset from origin for sprite 0                     . For each sprite
                    db $31    ;sprite definition (LSB) for sprite 0                  . of object
                    db $20    ;y height for sprite 0 in pixels AND $F0 OR defn MSB  -' 

                    db $00
                    db $f0
                    db $3f
                    db $20
                    
;-----------------------------------------------------------------------------------------------------------

spr_object19        db $02    ;number of sprites required by this object
                    
                    db $f0    ;x offset from origin for sprite 0                    -.
                    db $f0    ;y offset from origin for sprite 0                     . For each sprite
                    db $33    ;sprite definition (LSB) for sprite 0                  . of object
                    db $20    ;y height for sprite 0 in pixels AND $F0 OR defn MSB  -' 

                    db $00
                    db $f0
                    db $41
                    db $20
                    
;-----------------------------------------------------------------------------------------------------------

spr_object1a        db $02    ;number of sprites required by this object
                    
                    db $f0    ;x offset from origin for sprite 0                    -.
                    db $f0    ;y offset from origin for sprite 0                     . For each sprite
                    db $35    ;sprite definition (LSB) for sprite 0                  . of object
                    db $20    ;y height for sprite 0 in pixels AND $F0 OR defn MSB  -' 

                    db $00
                    db $f0
                    db $43
                    db $20
                    
;-----------------------------------------------------------------------------------------------------------

spr_object1b        db $02    ;number of sprites required by this object
                    
                    db $f0    ;x offset from origin for sprite 0                    -.
                    db $f0    ;y offset from origin for sprite 0                     . For each sprite
                    db $37    ;sprite definition (LSB) for sprite 0                  . of object
                    db $20    ;y height for sprite 0 in pixels AND $F0 OR defn MSB  -' 

                    db $00
                    db $f0
                    db $45
                    db $20
                    
;-----------------------------------------------------------------------------------------------------------

spr_object1c        db $02    ;number of sprites required by this object
                    
                    db $f0    ;x offset from origin for sprite 0                    -.
                    db $f0    ;y offset from origin for sprite 0                     . For each sprite
                    db $39    ;sprite definition (LSB) for sprite 0                  . of object
                    db $20    ;y height for sprite 0 in pixels AND $F0 OR defn MSB  -' 

                    db $00
                    db $f0
                    db $47
                    db $20

;-----------------------------------------------------------------------------------------------------------

spr_object1d        db $02    ;number of sprites required by this object
                    
                    db $f0    ;x offset from origin for sprite 0                    -.
                    db $f0    ;y offset from origin for sprite 0                     . For each sprite
                    db $3b    ;sprite definition (LSB) for sprite 0                  . of object
                    db $20    ;y height for sprite 0 in pixels AND $F0 OR defn MSB  -' 

                    db $00
                    db $f0
                    db $49
                    db $20
;-----------------------------------------------------------------------------------------------------------

spr_object1e        db $02    ;number of sprites required by this object
                    
                    db $f0    ;x offset from origin for sprite 0                    -.
                    db $f0    ;y offset from origin for sprite 0                     . For each sprite
                    db $4b    ;sprite definition (LSB) for sprite 0                  . of object
                    db $20    ;y height for sprite 0 in pixels AND $F0 OR defn MSB  -' 

                    db $00
                    db $f0
                    db $59
                    db $20
;-----------------------------------------------------------------------------------------------------------

spr_object1f        db $02    ;number of sprites required by this object
                    
                    db $f0    ;x offset from origin for sprite 0                    -.
                    db $f0    ;y offset from origin for sprite 0                     . For each sprite
                    db $4d    ;sprite definition (LSB) for sprite 0                  . of object
                    db $20    ;y height for sprite 0 in pixels AND $F0 OR defn MSB  -' 

                    db $00
                    db $f0
                    db $5b
                    db $20
;-----------------------------------------------------------------------------------------------------------

spr_object20        db $02    ;number of sprites required by this object
                    
                    db $f0    ;x offset from origin for sprite 0                    -.
                    db $f0    ;y offset from origin for sprite 0                     . For each sprite
                    db $4f    ;sprite definition (LSB) for sprite 0                  . of object
                    db $20    ;y height for sprite 0 in pixels AND $F0 OR defn MSB  -' 

                    db $00
                    db $f0
                    db $5d
                    db $20
;-----------------------------------------------------------------------------------------------------------

spr_object21        db $02    ;number of sprites required by this object
                    
                    db $f0    ;x offset from origin for sprite 0                    -.
                    db $f0    ;y offset from origin for sprite 0                     . For each sprite
                    db $51    ;sprite definition (LSB) for sprite 0                  . of object
                    db $20    ;y height for sprite 0 in pixels AND $F0 OR defn MSB  -' 

                    db $00
                    db $f0
                    db $5f
                    db $20
;-----------------------------------------------------------------------------------------------------------

spr_object22        db $02    ;number of sprites required by this object
                    
                    db $f0    ;x offset from origin for sprite 0                    -.
                    db $f0    ;y offset from origin for sprite 0                     . For each sprite
                    db $53    ;sprite definition (LSB) for sprite 0                  . of object
                    db $20    ;y height for sprite 0 in pixels AND $F0 OR defn MSB  -' 

                    db $00
                    db $f0
                    db $61
                    db $20
;-----------------------------------------------------------------------------------------------------------

spr_object23        db $02    ;number of sprites required by this object
                    
                    db $f0    ;x offset from origin for sprite 0                    -.
                    db $f0    ;y offset from origin for sprite 0                     . For each sprite
                    db $55    ;sprite definition (LSB) for sprite 0                  . of object
                    db $20    ;y height for sprite 0 in pixels AND $F0 OR defn MSB  -' 

                    db $00
                    db $f0
                    db $63
                    db $20
;-----------------------------------------------------------------------------------------------------------

spr_object24        db $02    ;number of sprites required by this object
                    
                    db $f0    ;x offset from origin for sprite 0                    -.
                    db $f0    ;y offset from origin for sprite 0                     . For each sprite
                    db $57    ;sprite definition (LSB) for sprite 0                  . of object
                    db $20    ;y height for sprite 0 in pixels AND $F0 OR defn MSB  -' 

                    db $00
                    db $f0
                    db $65
                    db $20
;-----------------------------------------------------------------------------------------------------------

spr_object25        db $02
          
                    db $f0
                    db $f0
                    db $77
                    db $20
                    
                    db $00
                    db $f0
                    db $81
                    db $20
                    
;-----------------------------------------------------------------------------------------------------------

spr_object26        db $02
          
                    db $f0
                    db $f0
                    db $79
                    db $20
                    
                    db $00
                    db $f0
                    db $83
                    db $20
                    
;-----------------------------------------------------------------------------------------------------------

spr_object27        db $02
          
                    db $f0
                    db $f0
                    db $7b
                    db $20
                    
                    db $00
                    db $f0
                    db $85
                    db $20
                    
;-----------------------------------------------------------------------------------------------------------

spr_object28        db $02
          
                    db $f0
                    db $f0
                    db $7d
                    db $20
                    
                    db $00
                    db $f0
                    db $87
                    db $20
                    
;-----------------------------------------------------------------------------------------------------------

spr_object29        db $02
          
                    db $f0
                    db $f0
                    db $7f
                    db $20
                    
                    db $00
                    db $f0
                    db $89
                    db $20
;-----------------------------------------------------------------------------------------------------------

spr_object2a        db $01
          
                    db $f8
                    db $f8
                    db $21
                    db $10
                    
spr_object2b        db $01
          
                    db $f8
                    db $f8
                    db $8b
                    db $10    
                    
spr_object2c        db $01
          
                    db $f8
                    db $f8
                    db $8c
                    db $10
                    
spr_object2d        db $01
          
                    db $f8
                    db $f8
                    db $8d
                    db $10    

spr_object2e        db $01
          
                    db $f8
                    db $f8
                    db $8e
                    db $10

;-----------------------------------------------------------------------------------------------------------

spr_object2f        db $01
          
                    db $f8
                    db $fd
                    db $6b
                    db $10
                    
spr_object30        db $02
          
                    db $f6
                    db $fd
                    db $6c
                    db $10

                    db $06
                    db $fd
                    db $6d
                    db $10

spr_object31        db $02
          
                    db $f6
                    db $fd
                    db $6e
                    db $10

                    db $06
                    db $fd
                    db $6f
                    db $10

spr_object32        db $02
          
                    db $f5
                    db $fd
                    db $70
                    db $10

                    db $05
                    db $fd
                    db $71
                    db $10
                    
;-----------------------------------------------------------------------------------------------------------

spr_object33        db $02
                    
                    db $f8
                    db $f8
                    db $72
                    db $10
                    
                    db $00
                    db $00
                    db $74
                    db $10
                    
spr_object34        db $02
                    
                    db $f8
                    db $f8
                    db $73
                    db $10
                    
                    db $00
                    db $00
                    db $74
                    db $10
                    
spr_object35        db $02
                    
                    db $f8
                    db $f8
                    db $72
                    db $10
                    
                    db $00
                    db $00
                    db $75
                    db $10    
                    
spr_object36        db $02
                    
                    db $f8
                    db $f8
                    db $73
                    db $10
                    
                    db $00
                    db $00
                    db $75
                    db $10


spr_object37        db $02
                    
                    db $f8
                    db $f8
                    db $72
                    db $10
                    
                    db $00
                    db $00
                    db $76
                    db $10
                              
spr_object38        db $02
                    
                    db $f8
                    db $f8
                    db $73
                    db $10
                    
                    db $00
                    db $00
                    db $76
                    db $10              
                    
;-- Enemies --------------------------------------------------------------------------------------------------------
                    

spr_object39        db 4                          ;bird
                    db -24,-14,$c0,$10
                    db -8,-14,$c8,$20
                    db 8,-14,$d0,$10
                    db -8,-25,$da,$30
                    
spr_object3a        db 5
                    db -25,-12,$c1,$10
                    db -9,-12,$ca,$20
                    db 7,-12,$d1,$10
                    db 23,-12,$d8,$10
                    db -8,-25,$da,$30
                    
spr_object3b        db 5
                    db -29,-9,$c2,$10
                    db -13,-9,$cc,$10
                    db 3,-9,$d2,$10
                    db 19,-9,$d9,$10
                    db -8,-25,$da,$30
                    
spr_object3c        db 4
                    db -24,-9,$c3,$20
                    db -8,-9,$cd,$10
                    db 8,-9,$d3,$20
                    db -8,-25,$da,$30

spr_object3d        db 4
                    db -24,-9,$c5,$20
                    db -8,-9,$ce,$10
                    db 8,-9,$d5,$20
                    db -8,-25,$da,$30

spr_object3e        db 4
                    db -20,-9,$c7,$10
                    db -4,-9,$cf,$10
                    db 12,-9,$d7,$10
                    db -8,-25,$da,$30

;-------------------------------------------------------------------------------------------------------------------

spr_object3f        db 3                          ;fan right
                    db -16,-16,$0b,$24
                    db 0,-16,$0f,$24
                    db 12,-17,$dd,$20
                    
spr_object40        db 3
                    db -16,-16,$0b,$24
                    db 0,-16,$0f,$24
                    db 12,-15,$df,$20
                    
spr_object41        db 3
                    db -16,-16,$0b,$24
                    db 0,-16,$0f,$24
                    db 12,-14,$e1,$20
                    
spr_object42        db 3
                    db -16,-16,$0b,$24
                    db 0,-16,$0f,$24
                    db 12,-17,$e3,$30

;-------------------------------------------------------------------------------------------------------------------

spr_object43        db 3                          ;fan left
                    db -22,-17,$e6,$20
                    db -16,-16,$0d,$24
                    db 0,-16,$11,$24
                    
spr_object44        db 3
                    db -22,-15,$e8,$20
                    db -16,-16,$0d,$24
                    db 0,-16,$11,$24
                    
spr_object45        db 3
                    db -22,-14,$ea,$20
                    db -16,-16,$0d,$24
                    db 0,-16,$11,$24
                    
spr_object46        db 3
                    db -22,-17,$ec,$20
                    db -16,-16,$0d,$24
                    db 0,-16,$11,$24

;-------------------------------------------------------------------------------------------------------------------

spr_object47        db 3                          ;teleport
                    db -8,-7,$ef,$20
                    db 8,-7,$f1,$20
                    db 0,0,$f3,$10

spr_object48        db 3
                    db -8,-7,$ef,$20
                    db 8,-7,$f1,$20
                    db 0,0,$f4,$10
                    
spr_object49        db 3
                    db -8,-7,$ef,$20
                    db 8,-7,$f1,$20
                    db 0,0,$f5,$10
                    
spr_object4a        db 3
                    db -8,-7,$ef,$20
                    db 8,-7,$f1,$20
                    db 0,0,$f6,$10
                    
spr_object4b        db 3
                    db -8,-7,$ef,$20
                    db 8,-7,$f1,$20
                    db 0,0,$f7,$10
                                        
spr_object4c        db 3
                    db -8,-7,$ef,$20
                    db 8,-7,$f1,$20
                    db 0,0,$f8,$10
                    
;-------------------------------------------------------------------------------------------------------------------
          
spr_object4d        db 4                          ;right bumper
                    db 2,-3,$24,$14
                    db 14,-16,$20,$24
                    db -16,-16,$18,$24
                    db 0,-16,$1c,$24
                                        
spr_object4e        db 4
                    db 16,-3,$24,$14
                    db 28,-16,$20,$24
                    db -16,-16,$18,$24
                    db 0,-16,$1c,$24
                                        
spr_object4f        db 4
                    db 14,-3,$24,$14
                    db 26,-16,$20,$24
                    db -16,-16,$18,$24
                    db 0,-16,$1c,$24                        
                                        
spr_object50        db 4
                    db 12,-3,$24,$14
                    db 24,-16,$20,$24
                    db -16,-16,$18,$24
                    db 0,-16,$1c,$24
                                        
spr_object51        db 4
                    db 10,-3,$24,$14
                    db 22,-16,$20,$24
                    db -16,-16,$18,$24
                    db 0,-16,$1c,$24    
          
spr_object52        db 4
                    db 8,-3,$24,$14
                    db 20,-16,$20,$24
                    db -16,-16,$18,$24
                    db 0,-16,$1c,$24
                                        
spr_object53        db 4
                    db 6,-3,$24,$14
                    db 18,-16,$20,$24
                    db -16,-16,$18,$24
                    db 0,-16,$1c,$24    

spr_object54        db 4
                    db 4,-3,$24,$14
                    db 16,-16,$20,$24
                    db -16,-16,$18,$24
                    db 0,-16,$1c,$24
                                        
;-------------------------------------------------------------------------------------------------------------------

spr_object55        db 4                          ;bumper left
                    db -26,-16,$1a,$24
                    db -16,-3,$24,$14
                    db -16,-16,$1e,$24
                    db 0,-16,$22,$24

spr_object56        db 4
                    db -40,-16,$1a,$24
                    db -30,-3,$24,$14
                    db -16,-16,$1e,$24
                    db 0,-16,$22,$24
                    
spr_object57        db 4
                    db -38,-16,$1a,$24
                    db -28,-3,$24,$14
                    db -16,-16,$1e,$24
                    db 0,-16,$22,$24

spr_object58        db 4
                    db -36,-16,$1a,$24
                    db -26,-3,$24,$14
                    db -16,-16,$1e,$24
                    db 0,-16,$22,$24

spr_object59        db 4
                    db -34,-16,$1a,$24
                    db -24,-3,$24,$14
                    db -16,-16,$1e,$24
                    db 0,-16,$22,$24

spr_object5a        db 4
                    db -32,-16,$1a,$24
                    db -22,-3,$24,$14
                    db -16,-16,$1e,$24
                    db 0,-16,$22,$24
                    
spr_object5b        db 4
                    db -30,-16,$1a,$24
                    db -20,-3,$24,$14
                    db -16,-16,$1e,$24
                    db 0,-16,$22,$24

spr_object5c        db 4
                    db -28,-16,$1a,$24
                    db -18,-3,$24,$14
                    db -16,-16,$1e,$24
                    db 0,-16,$22,$24    
                    
;-------------------------------------------------------------------------------------------------------------------

spr_object5d        db 1                          ;spikey drill
                    db -7,-8,$f9,$10
                    
spr_object5e        db 1
                    db -8,-8,$fa,$10
                    
spr_object5f        db 1
                    db -8,-8,$fb,$10
                    
spr_object60        db 1
                    db -8,-8,$fc,$10    
                    
spr_object61        db 1
                    db -8,-8,$fd,$10
                    
spr_object62        db 1
                    db -8,-8,$fe,$10
                    
spr_object63        db 1
                    db -8,-8,$ff,$10
                    
spr_object64        db 1
                    db -8,-8,$00,$14    
                                        
spr_object65        db 1
                    db -8,-8,$01,$14
                    
spr_object66        db 1
                    db -8,-8,$02,$14
                    
spr_object67        db 1
                    db -8,-8,$03,$14
                    
spr_object68        db 1
                    db -8,-8,$04,$14
                    
                    
;-------------------------------------------------------------------------------------------------------------------

spr_object69        db 2                          ;big mine
                    db -16,-16,$13,$24
                    db 0,-16,$15,$24

;-------------------------------------------------------------------------------------------------------------------

spr_object6a        db 1                          ;small mine NW
                    db -8,-8,$17,$14
                    
spr_object6b        db 1                          ;small mine NE
                    db -8,-8,$17,$14
                    
spr_object6c        db 1                          ;small mine SW
                    db -8,-8,$17,$14
                    
spr_object6d        db 1                          ;small mine SE
                    db -8,-8,$17,$14
                    
;-------------------------------------------------------------------------------------------------------------------

spr_object6e        db 4                          ;laser turrets
                    db 0,-16,$61,$24
                    db 16,-2,$63,$14
                    db 80,-16,$65,$24
                    db 64,-2,$64,$14
                                                            
spr_object6f        db 4                          ;laser blast frame 1
                    db -32,-10,$69,$14
                    db -16,-10,$6c,$14
                    db 0,-10,$6f,$14
                    db 16,-10,$72,$14
          
spr_object70        db 4                          ;laser blast frame 2
                    db -32,-10,$6a,$14
                    db -16,-10,$6d,$14
                    db 0,-10,$70,$14
                    db 16,-10,$73,$14

spr_object71        db 4                          ;laser blast frame 3
                    db -32,-10,$6b,$14
                    db -16,-10,$6e,$14
                    db 0,-10,$71,$14
                    db 16,-10,$74,$14

;-------------------------------------------------------------------------------------------------------------------

spr_object72        db 2                          ;bone
                    db -16,-16,$7a,$24
                    db 0,-16,$8a,$24
                    
spr_object73        db 2
                    db -16,-16,$7c,$24
                    db 0,-16,$8c,$24
          
spr_object74        db 2
                    db -16,-16,$7e,$24
                    db 0,-16,$8e,$24
                    
spr_object75        db 2
                    db -16,-16,$80,$24
                    db 0,-16,$90,$24

spr_object76        db 2
                    db -16,-16,$82,$24
                    db 0,-16,$92,$24

spr_object77        db 2
                    db -16,-16,$84,$24
                    db 0,-16,$94,$24

spr_object78        db 2
                    db -16,-16,$86,$24
                    db 0,-16,$96,$24

spr_object79        db 2
                    db -16,-16,$88,$24
                    db 0,-16,$98,$24

;-------------------------------------------------------------------------------------------------------------------
                    
spr_object7a        db 2                          ;tank right 1
                    db -16,-16,$4d,$24
                    db 0,-16,$4f,$24

spr_object7b        db 2                          ;tank right 2
                    db -16,-16,$4b,$24
                    db 0,-16,$51,$24

spr_object7c        db 2                          ;tank right 3
                    db -16,-16,$49,$24
                    db 0,-16,$53,$24

spr_object7d        db 1                          ;unused.
                    db 0,0,0,0                                        
                                        
;-------------------------------------------------------------------------------------------------------------------

spr_object7e        db 3                          ;old dart right
                    db -24,-8,$05,$14
                    db -8,-8,$07,$14
                    db 8,-8,$09,$14

spr_object7f        db 3                          ;old dart left
                    db -24,-8,$06,$14
                    db -8,-8,$08,$14
                    db 8,-8,$0a,$14
                    
;-------------------------------------------------------------------------------------------------------------------
                    
spr_object80        db 3                          ;cannon right
                    db -24,-16,$3c,$24
                    db -8,-16,$40,$24
                    db 8,-16,$44,$24

spr_object81        db 3                          ;cannon left
                    db -24,-16,$3e,$24
                    db -8,-16,$42,$24
                    db 8,-16,$46,$24    
                    
;-------------------------------------------------------------------------------------------------------------------

spr_object82        db 1                          ;cannon ball
                    db -8,-8,$48,$14                        
                    
;-------------------------------------------------------------------------------------------------------------------

spr_object83        db 2                          ;rocket fr 1
                    db -8,-16,$25,$14
                    db -8,-3,$2b,$34
                                        
                    
spr_object84        db 2                          ;rocket fr 2
                    db -8,-32,$26,$24
                    db -8,-3,$2b,$34                        


spr_object85        db 2                          ;rocket fr 3
                    db -8,-32,$28,$24
                    db -8,-3,$2b,$34
                    
;----------------------------------------------------------------------------------------------------------------------

spr_object86        db 1                          ;not used
                    db 0,0,0,0
                              
;-----------------------------------------------------------------------------------------------------------------------

spr_object87        db 2
                    db -16,-16,$9a,$24
                    db 0,-16,$9c,$24
                    
;-----------------------------------------------------------------------------------------------------------------------

spr_object88        db 1                          ;hot rock
                    db -8,-8,$75,$14

spr_object89        db 1
                    db -8,-8,$76,$14

spr_object8a        db 1
                    db -8,-8,$77,$14

spr_object8b        db 1
                    db -8,-8,$78,$14

spr_object8c        db 1
                    db -8,-8,$79,$14

;-----------------------------------------------------------------------------------------------------------------------

spr_object8d        db 1
                    db 0,0,$00,$10

spr_object8e        db 2                          ;turret from water (old)
                    db -16,-16,$9e,$24
                    db 0,-16,$aa,$24
                    
spr_object8f        db 2
                    db -16,-16,$a0,$24
                    db 0,-16,$ac,$24
                    
spr_object90        db 2
                    db -16,-16,$a2,$24
                    db 0,-16,$ae,$24
                    
spr_object91        db 2
                    db -16,-16,$a4,$24
                    db 0,-16,$b0,$24
                    
spr_object92        db 2
                    db -16,-16,$a6,$24
                    db 0,-16,$b2,$24
                    
spr_object93        db 2
                    db -16,-16,$a8,$24
                    db 0,-16,$b4,$24
                    
;-------------------------------------------------------------------------------------------------

spr_object94        db 1                          ;glowing orb
                    db -8,-8,$b6,$14
                    
spr_object95        db 1
                    db -8,-8,$b7,$14
                    
spr_object96        db 1
                    db -8,-8,$b8,$14
                    
spr_object97        db 1
                    db -8,-8,$b9,$14
                    
;-------------------------------------------------------------------------------------------------
                    
spr_object98        db $02              ;jump bonus + 1
                    
                    db $f6
                    db $f6
                    db $67
                    db $10
                    
                    db $00
                    db $00
                    db $74
                    db $10
                    
spr_object99        db $02              ;jump bonus + 2
                    
                    db $f6
                    db $f6
                    db $67
                    db $10
                    
                    db $00
                    db $00
                    db $75
                    db $10
                    
spr_object9a        db $02              ;jump bonus + 3
                    
                    db $f6
                    db $f6
                    db $67
                    db $10
                    
                    db $00
                    db $00
                    db $76
                    db $10
                    
spr_object9b        db $01              ;shield bonus 
                    
                    db $f8
                    db $f8
                    db $68
                    db $10              
                              
;-------------------------------------------------------------------------------------------------

spr_object9c        db $01              ;bright mystery tile
                    db $f8
                    db $f8
                    db $b1
                    db $10

;-------------------------------------------------------------------------------------------------

spr_object9d        db $06              ;"START!"
                    db $d8
                    db $f8
                    db $a3
                    db $10
                    
                    db $e8
                    db $f8
                    db $a4
                    db $10
                    
                    db $f8
                    db $f8
                    db $99
                    db $10
                    
                    db $08
                    db $f8
                    db $a2
                    db $10
                    
                    db $18
                    db $f8
                    db $a4
                    db $10

                    db $28
                    db $f8
                    db $a6
                    db $10
                    
;-------------------------------------------------------------------------------------------------

spr_object9e        db $0a              ;"BONUS ROUND"
                    
                    db $d8
                    db $ec
                    db $9a
                    db $10
                    
                    db $e8
                    db $ec
                    db $a7
                    db $10
                    
                    db $f8
                    db $ec
                    db $a0
                    db $10
                    
                    db $08
                    db $ec
                    db $a5
                    db $10
                    
                    db $18
                    db $ec
                    db $a3
                    db $10

                    db $d8
                    db $00
                    db $a2
                    db $10
                    
                    db $e8
                    db $00
                    db $a7
                    db $10
                    
                    db $f8
                    db $00
                    db $a5
                    db $10
                    
                    db $08
                    db $00
                    db $a0
                    db $10
                    
                    db $18
                    db $00
                    db $9b
                    db $10

;-------------------------------------------------------------------------------------------------

spr_object9f        db $01
                    db 0
                    db 0
                    db $00
                    db $10


;-------------------------------------------------------------------------------------------------

spr_objecta0        db $09              ;"JUMP BONUS"
                    
                    db $e0
                    db $ee
                    db $9d
                    db $10
                    
                    db $f0
                    db $ee
                    db $a5
                    db $10
                    
                    db $00
                    db $ee
                    db $9f
                    db $10
                    
                    db $10
                    db $ee
                    db $a1
                    db $10
                    
                    db $d8
                    db $00
                    db $9a
                    db $10
                    
                    db $e8
                    db $00
                    db $a7
                    db $10
                    
                    db $f8
                    db $00
                    db $a0
                    db $10
                    
                    db $08
                    db $00
                    db $a5
                    db $10
                    
                    db $18
                    db $00
                    db $a3
                    db $10

;-------------------------------------------------------------------------------------------------

spr_objecta1        db $04              ;"00000" - defs are dynamically updated by code
                    
                    db $e8
                    db $f8
                    db $a7
                    db $10
                    
                    db $f8
                    db $f8
                    db $a7
                    db $10
                    
                    db $08
                    db $f8
                    db $a7
                    db $10
                    
                    db $18
                    db $f8
                    db $a7
                    db $10
                    
;-------------------------------------------------------------------------------------------------

spr_objecta2        db $04              ;"GOAL" text
          
                    db $e0
                    db $f8
                    db $9c
                    db $10
                    
                    db $f0
                    db $f8
                    db $a7
                    db $10    
                    
                    db $00
                    db $f8
                    db $99
                    db $10
                              
                    db $10
                    db $f8
                    db $9e
                    db $10

;-------------------------------------------------------------------------------------------------

spr_objecta3        db $01
          
                    db $00,$00,$00,$10
                    
;-------------------------------------------------------------------------------------------------

spr_objecta4        db $04              ; "game" text

                    db $e0
                    db $f8
                    db $9c
                    db $10
                    
                    db $f0
                    db $f8
                    db $99
                    db $10    
                    
                    db $00
                    db $f8
                    db $9f
                    db $10
                              
                    db $10
                    db $f8
                    db $b3
                    db $10    

                    
spr_objecta5        db $04              ; "over" text

                    db $e0
                    db $f8
                    db $a7
                    db $10
                    
                    db $f0
                    db $f8
                    db $b4
                    db $10    
                    
                    db $00
                    db $f8
                    db $b3
                    db $10
                              
                    db $10
                    db $f8
                    db $a2
                    db $10    
                    
;-------------------------------------------------------------------------------------------------
                    
spr_objecta6        db 2                          ;tank left 1
                    db -16,-16,$55,$24
                    db 0,-16,$5b,$24

spr_objecta7        db 2                          ;tank left 2
                    db -16,-16,$57,$24
                    db 0,-16,$5d,$24

spr_objecta8        db 2                          ;tank left 3
                    db -16,-16,$59,$24
                    db 0,-16,$5f,$24

;-------------------------------------------------------------------------------------------------

spr_objecta9        db 3                          ;patroller frame 1
                    db -16,-15,$2e,$24
                    db 0,-15,$30,$24                                  
                    db -8,-7,$32,$14
                                        
spr_objectaa        db 3                          ;patroller frame 2
                    db -16,-15,$2e,$24
                    db 0,-15,$30,$24                                  
                    db -8,-7,$33,$14

spr_objectab        db 3                          ;patroller frame 3
                    db -16,-15,$2e,$24
                    db 0,-15,$30,$24                                  
                    db -8,-7,$34,$14

spr_objectac        db 3                          ;patroller frame 4
                    db -16,-15,$2e,$24
                    db 0,-15,$30,$24                                  
                    db -8,-7,$35,$14

spr_objectad        db 3                          ;patroller frame 5
                    db -16,-15,$2e,$24
                    db 0,-15,$30,$24                                  
                    db -8,-7,$34,$14

spr_objectae        db 3                          ;patroller frame 6
                    db -16,-15,$2e,$24
                    db 0,-15,$30,$24                                  
                    db -8,-7,$33,$14

;-------------------------------------------------------------------------------------------------

spr_objectaf        db 2                          ;slime frame 1
                    db -16,-8,$ba,$14
                    db 0,-8,$c0,$14                                   
          
spr_objectb0        db 2                          ;slime frame 2
                    db -16,-8,$bb,$14
                    db 0,-8,$c1,$14                                   
                    
spr_objectb1        db 2                          ;slime frame 3
                    db -16,-8,$bc,$14
                    db 0,-8,$c2,$14                                   
                    
spr_objectb2        db 2                          ;slime frame 4
                    db -16,-8,$bd,$14
                    db 0,-8,$c3,$14                                   
                    
spr_objectb3        db 2                          ;slime frame 5
                    db -16,-8,$be,$14
                    db 0,-8,$c4,$14                                   
                    
spr_objectb4        db 2                          ;slime frame 6
                    db -16,-8,$bf,$14
                    db 0,-8,$c5,$14                                   
                    
;-------------------------------------------------------------------------------------------------

spr_objectb5        db 2                          ;tile break 1
                    db -16,-16,$36,$24
                    db 0,-16,$38,$24

spr_objectb6        db 2                          ;tile break 2
                    db -16,-16,$c6,$24
                    db 0,-16,$ca,$24

spr_objectb7        db 2                          ;tile break 3
                    db -16,-16,$c8,$24
                    db 0,-16,$cc,$24
                    
;-------------------------------------------------------------------------------------------------

spr_objectb8        db 3                          ; new dart right frame 1
                    db -16,0,$05,$14
                    db 0,0,$3a,$14
                    db 16,0,$67,$14

spr_objectb9        db 3                          ; new dart right frame 2
                    db -16,0,$06,$14
                    db 0,0,$3b,$14
                    db 16,0,$67,$14

spr_objectba        db 3                          ; new dart right frame 3
                    db -16,0,$07,$14
                    db 0,0,$3a,$14
                    db 16,0,$67,$14

spr_objectbb        db 3                          ; new dart right frame 4
                    db -16,0,$08,$14
                    db 0,0,$3b,$14
                    db 16,0,$67,$14

spr_objectbc        db 3                          ; new dart right frame 5
                    db -16,0,$09,$14
                    db 0,0,$3a,$14
                    db 16,0,$67,$14

spr_objectbd        db 3                          ; new dart right frame 6
                    db -16,0,$0a,$14
                    db 0,0,$3b,$14
                    db 16,0,$67,$14

;-------------------------------------------------------------------------------------------------

spr_objectbe        db 1                          ;sea lauched missile frame 1
                    db -8,-7,$ce,$14
                    
spr_objectbf        db 1
                    db -8,-7,$cf,$14
                    
spr_objectc0        db 2
                    db -15,-8,$d0,$14
                    db 1,-8,$d5,$14
                    
spr_objectc1        db 2
                    db -15,-8,$d1,$14
                    db 1,-8,$d6,$14
                    
spr_objectc2        db 4
                    db -16,-12,$d3,$14
                    db -16,-9,$d2,$14
                    db 0,-12,$d8,$14
                    db 0,-9,$d7,$14
                    
spr_objectc3        db 4
                    db -16,-12,$d4,$14
                    db -16,-9,$d2,$14
                    db 0,-12,$d9,$14
                    db 0,-9,$d7,$14
                    
spr_objectc4        db 3
                    db -9,-24,$dc,$14
                    db -9,-10,$da,$24
                    db 7,-10,$de,$14
                    
spr_objectc5        db 3                          ;sea launched missile fram 8
                    db -9,-24,$dd,$14
                    db -9,-10,$da,$24
                    db 7,-10,$de,$14    
                    
;-------------------------------------------------------------------------------------------------

spr_objectc6        db 3                          ;snappy hex tile frame 1
                    db 0,6,$e2,$14
                    db 0,15,$e3,$14
                    db 0,0,$df,$34
                                        
spr_objectc7        db 3
                    db 0,5,$e2,$14
                    db 0,16,$e3,$14
                    db 0,0,$df,$34

spr_objectc8        db 3
                    db 0,4,$e2,$14
                    db 0,17,$e3,$14
                    db 0,0,$df,$34
                    
spr_objectc9        db 3
                    db 0,3,$e2,$14
                    db 0,18,$e3,$14
                    db 0,0,$df,$34
                    
spr_objectca        db 3
                    db 0,2,$e2,$14
                    db 0,19,$e3,$14
                    db 0,0,$df,$34
                              
spr_objectcb        db 3                          ;biting hex tile frame 6
                    db 0,1,$e2,$14
                    db 0,20,$e3,$14
                    db 0,0,$df,$34      
                    
;-------------------------------------------------------------------------------------------------

spr_objectcc        db 2                          ;bobbing mine frame 1
                    db -16,-16,$13,$24
                    db 0,-16,$15,$24
                    
spr_objectcd        db 2                          ;bobbing mine frame 2
                    db -16,-16,$9e,$24
                    db 0,-16,$aa,$24
                    
spr_objectce        db 2                          ;bobbing mine frame 3
                    db -16,-16,$a0,$24
                    db 0,-16,$ac,$24
                    
;-------------------------------------------------------------------------------------------------

spr_objectcf        db 2                          ;whirring vent fan frame 1
                    db -16,-16,$a2,$24
                    db 0,-16,$ae,$24
                    
spr_objectd0        db 2                          ;whirring vent fan frame 2
                    db -16,-16,$a4,$24
                    db 0,-16,$b0,$24
                    
spr_objectd1        db 2                          ;whirring vent fan frame 3
                    db -16,-16,$a6,$24
                    db 0,-16,$b2,$24
                    
;-------------------------------------------------------------------------------------------------
                    
spr_objectd2        db 2                          ;turret
                    db -16,-16,$a8,$24
                    db 0,-16,$b4,$24
                    
spr_objectd3        db 1                          ;spare
                    db 0,0,0,0

;-------------------------------------------------------------------------------------------------

spr_objectd4        db 3                          ; new dart left frame 1
                    db -16,1,$ed,$14
                    db 0,0,$eb,$14
                    db 16,0,$e5,$14

spr_objectd5        db 3                          ; new dart l frame 2
                    db -16,1,$ed,$14
                    db 0,0,$ec,$14
                    db 16,0,$e6,$14

spr_objectd6        db 3                          ; new dart l frame 3
                    db -16,1,$ed,$14
                    db 0,0,$eb,$14
                    db 16,0,$e7,$14

spr_objectd7        db 3                          ; new dart l frame 4
                    db -16,1,$ed,$14
                    db 0,0,$ec,$14
                    db 16,0,$e8,$14

spr_objectd8        db 3                          ; new dart l frame 5
                    db -16,1,$ed,$14
                    db 0,0,$eb,$14
                    db 16,0,$e9,$14

spr_objectd9        db 3                          ; new dart l frame 6
                    db -16,1,$ed,$14
                    db 0,0,$ec,$14
                    db 16,0,$ea,$14
                    
;-------------------------------------------------------------------------------------------------

spr_objectda        db 1
                    db -8,-8,$b8,$14              ;small blast fr1


spr_objectdb        db 1
                    db -8,-8,$b8,$14              ;small blast fr1


spr_objectdc        db 1                          ;fr2
                    db -8,-8,$68,$14


spr_objectdd        db 1                          ;fr3
                    db -8,-8,$e4,$14
                    

;----------------------------------------------------------------------------------------------------

spr_objectde        db 1
                    db -8,-8,$ee,$24
                    
spr_objectdf        db 1
                    db -8,-8,$f0,$24
                    
spr_objecte0        db 1
                    db -8,-8,$f2,$24
                    
spr_objecte1        db 1
                    db -8,-8,$f4,$24
                    
spr_objecte2        db 1
                    db -8,-8,$f6,$24
                    
spr_objecte3        db 1
                    db -8,-8,$f8,$24
                    
;----------------------------------------------------------------------------------------------------
                                                                                                                        