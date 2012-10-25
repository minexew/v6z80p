
	
beetroot equ 5

strings	dw $1234

	dw beetroot,$9876,beetroot
	
	dw strings
	
	dw beetroot+10,strings+10
	
	dw 1,2,3,4,5,6,7,8,9,10
	
last_line	dw $1111 , $2222, $3333,$4444	,$5555	,	$6666	;comment
	
