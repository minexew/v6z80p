cube_info

	db 8	;coords
	db 12	;lines

	db 0	;x rot
	db 255	;y rot
	db 1	;z rot
	
	dw 950	;max zoom


cube_source_coords	dw 30*4,30*4,30*4,$a2	;x y z colour
		dw 30*4,-30*4,30*4,$a2
		dw -30*4,-30*4,30*4,$a2
		dw -30*4,30*4,30*4,$a2
		
		dw 30*4,30*4,-30*4,$a2
		dw 30*4,-30*4,-30*4,$a2
		dw -30*4,-30*4,-30*4,$a2
		dw -30*4,30*4,-30*4,$a2	;coord vals approx 4x actual pixel positions


cube_join_list	db 0,1, 1,2, 2,3, 3,0
		db 4,5, 5,6, 6,7, 7,4
		db 0,4, 1,5, 2,6, 3,7
		
	
