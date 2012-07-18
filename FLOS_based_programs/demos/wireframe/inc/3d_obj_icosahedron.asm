icosahedron_info

		db 12	;coords
		db 30	;lines

		db 0	;x rot
		db 255	;y rot
		db 1	;z rot
		
		dw 950	;max zoom
		
 
icosahedron_source_coords
 
	dw  00000/100,       00000/100,       20000/100,       15
	dw  17888/100,       00000/100,       08944/100,       15
	dw  05527/100,       17013/100,       08944/100,       15
	dw -14472/100,       10514/100,       08944/100,       15
	dw -14472/100,      -10514/100,       08944/100,       15
	dw  05527/100,      -17013/100,       08944/100,       15
	dw  14472/100,       10514/100,      -08944/100,       15
	dw -05527/100,       17013/100,      -08944/100,       15
	dw -17888/100,       00000/100,      -08944/100,       15
	dw -05527/100,      -17013/100,      -08944/100,       15
	dw  14472/100,      -10514/100,      -08944/100,       15
	dw  00000/100,       00000/100,      -20000/100,       15
	
icosahedtron_join_list

	db 2,0, 0,1, 1,2
	db 3,0, 2,3
	db 4,0, 3,4
	db 5,0, 4,5
	db 5,1
	
	db 1,6, 6,2
	db 7,2, 6,7
	db 7,3
	db 8,3, 7,8
	db 8,4
	db 9,4, 8,9
	db 9,5
	db 10,5, 9,10
	db 1,10, 10,6
	
	db 6,11, 11,7 
	db 11,8 
	db 11,9 
	db 11,10
	
	