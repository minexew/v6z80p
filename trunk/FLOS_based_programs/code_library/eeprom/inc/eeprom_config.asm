
; Set A to slot to reconfigure from


eeprom_reconfig
		
		call set_config_slot
		
		ld hl,cmd_reconfigure
		call send_pic_command
ee_infloop	jr ee_infloop

cmd_reconfigure	db 2,$88,$a1
		

;-----------------------------------------------------------------------------------------------------------------


set_config_slot

		sla a
		ld (ee_recon_slot),a
		ld hl,cmd_set_config_slot
		call send_pic_command
		ret
		
cmd_set_config_slot

		db 5
		db $88,$b8,$00,$00
ee_recon_slot	db $00
		

;-----------------------------------------------------------------------------------------------------------------

