;-----------------------------------------------------------------------------------
; French Keymap v1.00
;
; Partial. Main keys OK. Some specialized character codes are included (in chars
; 128-255, will require full or patched font)
;
;-----------------------------------------------------------------------------------

; Unqualified (no shift or ALT) ------------------------------------------------------
	
;		ASCII	KEYCODE
;		---------------

		db $00	;00
		db $00	;01	
		db $00	;02
		db $00	;03
		db $00	;04
		db $00	;05
		db $00	;06
		db $00	;07
		db $00	;08
		db $00	;09
		db $00	;0a
		db $00	;0b
		db $00	;0c
		db $00	;0d
		db $23	;0e
		db $00	;0f
		
		db $00	;10
		db $00	;11
		db $00	;12
		db $00	;13
		db $00	;14
		db "a"	;15
		db "&"	;16
		db $00	;17
		db $00	;18
		db $00	;19
		db "w"	;1a
		db $73	;1b
		db "q"	;1c
		db "z"	;1d
		db 130	;1e
		db $00	;1f
		
		db $00	;20
		db $63 	;21
		db $78 	;22
		db $64 	;23
		db $65 	;24
		db $27 	;25
		db $22 	;26
		db $00	;27
		db $00 	;28
		db $20 	;29
		db $76 	;2a
		db $66 	;2b
		db $74 	;2c
		db $72 	;2d
		db "("  ;2e
		db $00	;2f
		
		db $00 	;30
		db $6e 	;31
		db $62 	;32
		db $68 	;33
		db $67 	;34
		db $79 	;35
		db "-" 	;36
		db $00	;37
		db $00 	;38
		db $00 	;39
		db "," 	;3a
		db $6a 	;3b
		db $75 	;3c
		db 138 	;3d
		db "_" 	;3e
		db $00	;3f
		
		db $00 	;40
		db ";" 	;41
		db $6b 	;42
		db $69 	;43
		db $6f 	;44
		db 133 	;45
		db 135 	;46
		db $00	;47
		db $00 	;48
		db ":" 	;49
		db "!" 	;4a
		db $6c 	;4b
		db "m" 	;4c
		db $70 	;4d
		db ")"	;4e
		db $00	;4f
		
		db $00 	;50
		db $00 	;51
		db 151 	;52
		db $00 	;53
		db "^" 	;54
		db "=" 	;55
		db $00 	;56
		db $00	;57
		db $00 	;58
		db $00 	;59
		db $00 	;5a
		db "$" 	;5b
		db $00 	;5c
		db "*" 	;5d
		db $00 	;5e
		db $00	;5f

		db $00 	;60
		db "<"	;61			
						
		
; With SHIFT key held ------------------------------------------------------------------------
	
;		ASCII	KEYCODE
;		---------------
		
		db $00 	;00
		db $00 	;01
		db $00 	;02
		db $00 	;03
		db $00 	;04
		db $00 	;05
		db $00 	;06
		db $00	;07		
		db $00 	;08
		db $00 	;09
		db $00 	;0a
		db $00 	;0b
		db $00 	;0c
		db $00 	;0d
		db $7e 	;0e
		db $00	;0f	
		
		db $00 	;10
		db $00 	;11
		db $00 	;12
		db $00 	;13
		db $00 	;14
		db "A" 	;15
		db "1" 	;16
		db $00	;17
		db $00 	;18
		db $00 	;19
		db "W" 	;1a
		db $53 	;1b
		db "Q" 	;1c
		db "Z" 	;1d
		db "2" 	;1e
		db $00	;1f
		
		db $00 	;20
		db $43 	;21
		db $58 	;22
		db $44 	;23
		db $45 	;24
		db "4" 	;25
		db "3" 	;26	
		db $00	;27
		db $00 	;28
		db $20 	;29
		db $56 	;2a
		db $46 	;2b
		db $54 	;2c
		db $52 	;2d
		db "5"	;2e
		db $00	;2f
		
		db $00 	;30
		db $4e 	;31
		db $42 	;32
		db $48 	;33
		db $47 	;34
		db $59 	;35
		db "6" 	;36
		db $00	;37
		db $00 	;38
		db $00 	;39
		db "?" 	;3a
		db $4a 	;3b
		db $55 	;3c
		db "7" 	;3d
		db "8" 	;3e
		db $00	;3f
		
		db $00 	;40
		db "." 	;41
		db $4b 	;42
		db $49 	;43
		db $4f 	;44
		db "0" 	;45
		db "9" 	;46
		db $00	;47
		db $00 	;48
		db $2f 	;49
		db 0 	;4a	- Unknown ASCII char?
		db $4c 	;4b
		db "M" 	;4c
		db $50 	;4d
		db 167 	;4e
		db $00	;4f
		
		db $00 	;50
		db $00 	;51
		db "%" 	;52
		db $00 	;53
		db 0 	;54	- Uknown ASCII char?
		db "+" 	;55
		db $00 	;56
		db $00	;57
		db $00 	;58
		db $00 	;59
		db $00 	;5a
		db 156 	;5b	- Pound sign
		db $00 	;5c
		db 230 	;5d	- "Micro" sign?
		db $00 	;5e
		db $00	;5f
		
		db $00 	;60
		db ">"	;61				


; With ALT key held ------------------------------------------------------------------------
	
;		ASCII	KEYCODE
;		---------------

		db $00	;00
		db $00	;01
		db $00	;02
		db $00	;03
		db $00	;04
		db $00	;05
		db $00	;06
		db $00	;07
		db $00	;08
		db $00	;09
		db $00	;0a
		db $00	;0b
		db $00	;0c
		db $00	;0d
		db $00	;0e
		db $00	;0f
		
		db $00	;10
		db $00	;11
		db $00	;12
		db $00	;13
		db $00	;14
		db $00	;15
		db $00	;16
		db $00	;17
		db $00	;18
		db $00	;19
		db $00	;1a
		db $00	;1b
		db $00	;1c
		db $00	;1d
		db "~"	;1e
		db $00	;1f	
		
		db $00	;20
		db $00	;21
		db $00	;22
		db $00	;23
		db 145	;24		;- not sure about this, "ae" or Euro symbol?
		db "{"	;25
		db "#"	;26
		db $00	;27
		db $00	;28
		db $00	;29
		db $00	;2a
		db $00	;2b
		db $00	;2c
		db $00	;2d
		db "["	;2e
		db $00	;2f
		
		db $00	;30
		db $00	;31
		db $00	;32
		db $00	;33
		db $00	;34
		db $00	;35
		db "|"	;36
		db $00	;37
		db $00	;38
		db $00	;39
		db $00	;3a
		db $00	;3b
		db $00	;3c
		db $60	;3d
		db $5c	;3e
		db $00	;3f
		
		db $00	;40
		db $00	;41
		db $00	;42
		db $00	;43
		db $00	;44
		db "@"	;45
		db "^"	;46
		db $00	;47
		db $00	;48
		db $00	;49
		db $00	;4a
		db $00	;4b
		db $00	;4c
		db $00	;4d
		db "]"	;4e
		db $00	;4f
		
		db $00	;50
		db $00	;51
		db $00	;52
		db $00	;53
		db $00	;54
		db "}"	;55
		db $00	;56
		db $00	;57
		db $00	;58
		db $00	;59
		db $00	;5a
		db $00	;5b		; unknown ASCII char
		db $00	;5c
		db $00	;5d
		db $00	;5e
		db $00	;5f
		
		db $00	;60
		db $00	;61

		
;-----------------------------------------------------------------------------------
