		TITLE	CVHASHES - Copyright (c) SLR Systems 1994

		INCLUDE	MACROS
if	fg_cvpack
		INCLUDE	CVTYPES
		INCLUDE	CVSTUFF

		PUBLIC	INIT_CV_SYMBOL_HASHES,STORE_CV_SYMBOL_INFO,FLUSH_CV_SYMBOL_HASHES,OUTPUT_CV_SYMBOL_ALIGN,FIRST_CVH


		.DATA

		EXTERNDEF	CV_TEMP_RECORD:BYTE

		EXTERNDEF	CURNMOD_GINDEX:DWORD,CURNMOD_NUMBER:DWORD,CV_PUB_TXT_OFFSET:DWORD,CV_PUB_SYMBOL_ID:DWORD
		EXTERNDEF	CVG_SEGMENT:DWORD,BYTES_SO_FAR:DWORD,CVG_SYMBOL_OFFSET:DWORD,CVG_SEGMENT_OFFSET:DWORD
		EXTERNDEF	CVG_SYMBOL_HASH:DWORD,FINAL_HIGH_WATER:DWORD,EXETABLE:DWORD,LAST_CVH_SEGMENT:DWORD

		EXTERNDEF	CV_HASHES_GARRAY:STD_PTR_S,CV_HASHES_STUFF:ALLOCS_STRUCT

		EXTERNDEF	CV_DWORD_ALIGN:DWORD
		externdef	CV_HASH_HEADER:CV_HASH_HDR_STRUCT
		externdef	CV_PRIMES:WORD

		externdef	CV_PAGE_BYTES		: DWORD
		externdef	CV_HASH_COUNT		: DWORD
;		externdef	CV_TEMP_JUNK		: DWORD
		externdef	CVG_PUT_PTR		: DWORD
		externdef	CVG_PUT_LIMIT		: DWORD
		externdef	CVG_PUT_BLK		: DWORD
		externdef	CV_SECTION_OFFSET	: DWORD
		externdef	CV_SECTION_HDR_ADDRESS	: DWORD
		externdef	CV_SYMBOL_BASE_ADDR	: DWORD
		externdef	CVG_N_HASHES		: DWORD
		externdef	CVG_BUFFER_LOG		: DWORD
		externdef	CVG_BUFFER_LIMIT	: DWORD
		externdef	FIRST_CVH		: DWORD
		externdef	LAST_CVH		: DWORD


		.CODE	CVPACK_TEXT

		EXTERNDEF	MOVE_TEXT_TO_OMF:PROC,HANDLE_CV_INDEX:PROC,FLUSH_CV_TEMP:PROC,RELEASE_BLOCK:PROC
		EXTERNDEF	ALLOC_LOCKED:PROC,GET_NEW_LOG_BLK:PROC,MOVE_EAX_TO_FINAL_HIGH_WATER:PROC,RELEASE_LOCKED:PROC
		EXTERNDEF	MOVE_EAX_TO_EDX_FINAL:PROC,SORT_HASHES_GARRAY:PROC,GET_NAME_HASH32:PROC,CV_HASHES_POOL_GET:PROC
		EXTERNDEF	RELEASE_GARRAY:PROC,_release_minidata:proc
		externdef	_move_eax_to_edx_final:proc


INIT_CV_SYMBOL_HASHES	PROC
		;
		;INITIALIZE STUFF USED FOR GLOBAL SYMBOL HASH TABLES
		;
		XOR	EAX,EAX

		MOV	CV_HASH_COUNT,EAX
		MOV	CV_PAGE_BYTES,EAX

		MOV	FIRST_CVH,EAX
		MOV	LAST_CVH,EAX

		MOV	CVG_SYMBOL_OFFSET,EAX

		CALL	CV_DWORD_ALIGN		;MAKE SURE OF DWORD ALIGNMENT

		MOV	EAX,BYTES_SO_FAR
		MOV	ECX,FINAL_HIGH_WATER

		MOV	CV_SECTION_OFFSET,EAX
		MOV	CV_SECTION_HDR_ADDRESS,ECX

		ADD	EAX,SIZE CV_HASH_HDR_STRUCT
		ADD	ECX,SIZE CV_HASH_HDR_STRUCT

		MOV	BYTES_SO_FAR,EAX
		MOV	FINAL_HIGH_WATER,ECX

		MOV	CV_SYMBOL_BASE_ADDR,ECX
		CALL	GET_NEW_LOG_BLK

		MOV	CVG_PUT_BLK,EAX
		MOV	CVG_PUT_PTR,EAX

		ADD	EAX,PAGE_SIZE-512

		MOV	CVG_PUT_LIMIT,EAX

		RET

INIT_CV_SYMBOL_HASHES	ENDP


STORE_CV_SYMBOL_INFO	PROC
		;
		;
		;
		MOV	EAX,SIZE CV_HASHES_STRUCT
		CALL	CV_HASHES_POOL_GET

		ASSUME	EAX:PTR CV_HASHES_STRUCT

		MOV	ECX,CVG_SYMBOL_OFFSET
		MOV	EDX,CV_HASH_COUNT

		MOV	[EAX]._SYMBOL_OFFSET,ECX
		INC	EDX

		MOV	ECX,CVG_SYMBOL_HASH
		MOV	CV_HASH_COUNT,EDX

		MOV	[EAX]._SYMBOL_HASH,ECX
		MOV	ECX,CVG_SEGMENT_OFFSET

		MOV	EDX,CVG_SEGMENT
		MOV	[EAX]._SEGMENT_OFFSET,ECX

		MOV	[EAX]._SEGMENT,EDX
		MOV	ECX,LAST_CVH

		TEST	ECX,ECX
		JZ	L8$

		MOV	[ECX].CV_HASHES_STRUCT._NEXT,EAX
L7$:
		MOV	[EAX]._PREV,ECX

		XOR	EDX,EDX
		MOV	LAST_CVH,EAX

		MOV	[EAX]._NEXT,EDX
		MOV	[EAX]._NEXT_HASH,EDX

		RET


L8$:
		MOV	FIRST_CVH,EAX
		JMP	L7$

STORE_CV_SYMBOL_INFO	ENDP


OUTPUT_CV_SYMBOL_ALIGN	PROC
		;
		;EAX IS CV_TEMP_RECORD
		;
		;ALIGN SYMBOL STORED IN CV_TEMP_RECORD
		;
		;RETURN EAX IS OFFSET OF THIS SYMBOL...
		;
		ASSUME	EAX:PTR CV_SYMBOL_STRUCT

		PUSH	EDI
		MOV	EDX,DPTR [EAX]._LENGTH

		AND	EDX,0FFFFH
		XOR	ECX,ECX

		PUSH	ESI
		MOV	ESI,EAX

		MOV	BPTR [EAX+EDX]._ID,CL
		MOV	AL,2

		ASSUME	ESI:PTR CV_SYMBOL_STRUCT,EAX:NOTHING

		SUB	EAX,EDX
		MOV	BPTR [ESI+EDX+1]._ID,CL

		AND	EAX,3			;# OF ZEROS TO ADD AT THE END
		MOV	BPTR [ESI+EDX+2]._ID,CL

		ADD	EDX,EAX
		GETT	AL,DOING_4K_ALIGN	;STATICSYM DOESN'T MATTER

		MOV	[ESI]._LENGTH,DX
		LEA	ECX,2[EDX]
		;
		;DO 4K ALIGNMENT CALCULATION
		;
		OR	AL,AL
		JZ	L3$

		MOV	EAX,CV_PAGE_BYTES
		MOV	EDX,4K

		ADD	EAX,ECX

		SUB	EDX,EAX
		JC	L2$

		JZ	L28$			;MUST LEAVE 0 OR AT LEAST 8 BYTES

		CMP	EDX,8
		JA	L29$
L2$:
		;
		;INSERT S_ALIGN SYMBOL FOR PAGE ALIGNMENT
		;
		MOV	EDI,CVG_PUT_PTR
		PUSH	ECX

		MOV	ECX,4K-2
		MOV	EAX,CV_PAGE_BYTES

		SUB	ECX,EAX			;# OF BYTES TO FILL
		MOV	EDX,S_ALIGN*64K

		OR	EDX,ECX
		SUB	ECX,2

		MOV	[EDI],EDX
		ADD	EDI,4

		SHR	ECX,2
		XOR	EAX,EAX

		;BUG: seg faults here with long symbol,
		; ECX apparently went negative.
		; Happens when record length is > 0x1000
		; Bugzilla 2436
		REP	STOSD

		MOV	EAX,CVG_PUT_LIMIT
		MOV	CVG_PUT_PTR,EDI

		CMP	EDI,EAX
		JB	L27$

		CALL	FLUSH_CVG_TEMP
L27$:
		POP	ECX

		MOV	EDX,ECX
L28$:
		MOV	EAX,EDX
L29$:
		MOV	CV_PAGE_BYTES,EAX	;# OF BYTES IN PAGE AFTER THIS SYMBOL GOES OUT...
L3$:
		;
		;STORE IN BUFFER
		;
		MOV	EAX,FINAL_HIGH_WATER
		MOV	EDX,CV_SYMBOL_BASE_ADDR

		SUB	EAX,EDX
		MOV	EDI,CVG_PUT_PTR

		ADD	EAX,EDI
		MOV	EDX,CVG_PUT_BLK

		SHR	ECX,2
		SUB	EAX,EDX

		REP	MOVSD

		MOV	ECX,CVG_PUT_LIMIT
		MOV	CVG_PUT_PTR,EDI

		CMP	EDI,ECX
		POP	ESI

		POP	EDI
		JAE	FLUSH_CVG_TEMP

		RET

OUTPUT_CV_SYMBOL_ALIGN	ENDP


FLUSH_CVG_TEMP	PROC	NEAR
		;
		;MUST SAVE EAX
		;
		PUSH	EAX
		MOV	EAX,CVG_PUT_BLK

		MOV	ECX,CVG_PUT_PTR
		MOV	CVG_PUT_PTR,EAX

		SUB	ECX,EAX
		JZ	L9$

		CALL	MOVE_EAX_TO_FINAL_HIGH_WATER

L9$:
		POP	EAX

		RET

FLUSH_CVG_TEMP	ENDP


FLUSH_CV_SYMBOL_HASHES	PROC
		;
		;CLEAN UP THE MESS YOU STARTED...
		;
		PUSH	EAX
		CALL	FLUSH_CVG_TEMP

		MOV	EAX,FINAL_HIGH_WATER
		MOV	EDX,CV_SYMBOL_BASE_ADDR

		SUB	EAX,EDX
		MOV	EDX,BYTES_SO_FAR

		MOV	CV_HASH_HEADER._CVHH_CBSYMBOL,EAX
		ADD	EDX,EAX

		MOV	BYTES_SO_FAR,EDX
		CALL	DO_SYMBOL_HASH

		CALL	DO_ADDRESS_HASH

		;
		;WRITE OUT CV_HASH_HEADER
		;
		MOV	EAX,OFF CV_HASH_HEADER
		MOV	EDX,CV_SECTION_HDR_ADDRESS

		MOV	ECX,SIZE CV_HASH_HDR_STRUCT

		push	EDX
		push	ECX
		push	EAX
		call	_move_eax_to_edx_final
		add	ESP,12

		MOV	EAX,CVG_PUT_BLK
		CALL	RELEASE_BLOCK

		MOV	EAX,OFF CV_HASHES_GARRAY
		CALL	RELEASE_GARRAY

		MOV	EAX,OFF CV_HASHES_STUFF

		push	EAX
		call	_release_minidata
		add	ESP,4

		POP	ECX			;CV_INDEX
		MOV	EAX,CV_SECTION_OFFSET

		JMP	HANDLE_CV_INDEX		;BACKWARDS

FLUSH_CV_SYMBOL_HASHES	ENDP


DO_SYMBOL_HASH	PROC	NEAR
		;
		;
		;
		MOV	EAX,CV_HASH_COUNT

		TEST	EAX,EAX
		JNZ	L0$

		MOV	CV_HASH_HEADER._CVHH_CBSYMHASH,EAX

		RET

L0$:
		PUSHM	EDI,ESI

		PUSH	EBX
		MOV	EAX,FINAL_HIGH_WATER

		PUSH	EAX
		;
		;CALCULATE # OF HASH BUCKETS
		;
		MOV	EBX,17+16
		MOV	EAX,CV_HASH_COUNT
L1$:
		DEC	EBX

		ADD	EAX,EAX
		JNC	L1$

		CMP	EBX,10
		JA	L12$

		MOV	EBX,10
L12$:
		MOV	EAX,CV_HASH_COUNT
		SUB	EBX,7

		XOR	EDX,EDX
		MOV	ESI,OFF CV_PRIMES

		ASSUME	ESI:PTR WORD

		DIV	EBX
		;
		;HIGH LIMIT IS PAGE_SIZE/8
		;
		CMP	EAX,PAGE_SIZE_8_HASH
		JB	L14$

		MOV	EAX,PAGE_SIZE_8_HASH
L14$:
		;
		;NOW CONVERT TO NEXT HIGHEST PRIME #
		;
		XOR	ECX,ECX
L16$:
		MOV	CX,[ESI]
		ADD	ESI,2

		CMP	ECX,EAX
		JB	L16$

		MOV	CX,[ESI-2]
		MOV	EDI,CVG_PUT_BLK

		MOV	CVG_N_HASHES,ECX
		MOV	ESI,LAST_CVH
		;
		;SCAN CV_HASHES, LINK-LIST STUFF PLEASE
		;
		XOR	EAX,EAX
		ADD	ECX,ECX

		REP	STOSD

		MOV	EDI,CVG_PUT_BLK
		MOV	ECX,ESI

L2$:
		CONVERT	ESI,ESI,CV_HASHES_GARRAY
		ASSUME	ESI:PTR CV_HASHES_STRUCT

		MOV	EAX,[ESI]._SYMBOL_HASH
		XOR	EDX,EDX

		DIV	CVG_N_HASHES

		MOV	EAX,[EDI+EDX*8]		;LINK-LIST TO THIS 'BUCKET'
		MOV	[EDI+EDX*8],ECX

		MOV	EBX,[EDI+EDX*8+4]
		MOV	[ESI]._NEXT_HASH,EAX

		INC	EBX			;COUNT GUYS IN THIS 'BUCKET'
		MOV	ESI,[ESI]._PREV

		MOV	[EDI+EDX*8+4],EBX
		MOV	ECX,ESI

		TEST	ESI,ESI
		JNZ	L2$
L29$:
		;
		;NOW START WRITING HASH TABLE OUT
		;
		CALL	GET_NEW_LOG_BLK

		MOV	ESI,EAX
		MOV	EBX,CVG_N_HASHES
		ASSUME	ESI:NOTHING

		MOV	CVG_BUFFER_LOG,EAX
		MOV	[EAX],EBX

		ADD	EAX,PAGE_SIZE
		XOR	EDX,EDX
		;
		;WRITE OFFSET OF EACH CHAIN
		;
		MOV	CVG_BUFFER_LIMIT,EAX
		XOR	ECX,ECX
L3$:
		MOV	EAX,[EDI+ECX*8+4]	;BUCKET COUNT
		MOV	[ESI+ECX*4+4],EDX

		INC	ECX
		DEC	EBX

		LEA	EDX,[EDX+EAX*8]
		JNZ	L3$

		INC	ECX
		MOV	EAX,ESI

		SHL	ECX,2
		CALL	MOVE_EAX_TO_FINAL_HIGH_WATER
		;
		;NOW WRITE BUCKET COUNTS
		;
		MOV	ESI,CVG_PUT_BLK
		MOV	EDI,CVG_BUFFER_LOG

		ADD	ESI,4			;LOOK AT COUNT
		MOV	ECX,CVG_N_HASHES
L4$:
		MOV	EAX,[ESI]
		ADD	ESI,8

		MOV	[EDI],EAX
		ADD	EDI,4

		DEC	ECX
		JNZ	L4$

		MOV	ECX,EDI
		MOV	EAX,CVG_BUFFER_LOG

		SUB	ECX,EAX
		CALL	MOVE_EAX_TO_FINAL_HIGH_WATER
		;
		;NOW WRITE CHAINS
		;
		MOV	EBX,CVG_PUT_BLK
		MOV	EDI,CVG_BUFFER_LOG

		MOV	EDX,CVG_N_HASHES
L5$:
		MOV	ESI,[EBX]		;FIRST ITEM IN CHAIN
		ADD	EBX,8
L51$:
		TEST	ESI,ESI
		JZ	L58$

		CONVERT	ESI,ESI,CV_HASHES_GARRAY
		ASSUME	ESI:PTR CV_HASHES_STRUCT

		MOV	EAX,[ESI]._SYMBOL_OFFSET
		MOV	ECX,[ESI]._SYMBOL_HASH

		MOV	[EDI],EAX
		MOV	[EDI+4],ECX

		ADD	EDI,8
		MOV	EAX,CVG_BUFFER_LIMIT

		CMP	EDI,EAX
		JAE	L57$
L56$:
		MOV	ESI,[ESI]._NEXT_HASH
		JMP	L51$

L58$:
		DEC	EDX
		JNZ	L5$

		MOV	ECX,EDI
		MOV	EAX,CVG_BUFFER_LOG

		SUB	ECX,EAX
		JZ	L59$

		CALL	MOVE_EAX_TO_FINAL_HIGH_WATER
L59$:
		;
		;STORE BYTE-COUNT FOR SYMBOL HASH STUFF
		;
		POP	ECX
		MOV	EAX,FINAL_HIGH_WATER

		SUB	EAX,ECX
		MOV	ECX,BYTES_SO_FAR

		MOV	CV_HASH_HEADER._CVHH_CBSYMHASH,EAX
		ADD	ECX,EAX

		MOV	EAX,CVG_BUFFER_LOG
		MOV	BYTES_SO_FAR,ECX

		POPM	EBX,ESI

		POP	EDI
		JMP	RELEASE_BLOCK

L57$:
		MOV	ECX,EDI
		MOV	EAX,CVG_BUFFER_LOG

		PUSH	EDX
		SUB	ECX,EAX

		MOV	EDI,CVG_BUFFER_LOG
		CALL	MOVE_EAX_TO_FINAL_HIGH_WATER

		POP	EDX
		JMP	L56$

DO_SYMBOL_HASH	ENDP


DAH_VARS	STRUC

CV_SEG_TBL_BP		DD	128/(PAGE_SIZE/1024) DUP(?)
CVG_CSEG_BP		DD	?
CV_SEGTBL_PTR_BP	DD	?
CV_SEGTBL_PTR_LIMIT_BP	DD	?
CV_EXETABLE_PTR_BP	DD	?
CV_PUT_LIMIT_BP		DD	?
CV_NEXT_SEG_TBL_BP	DD	?

DAH_VARS	ENDS


FIX	MACRO	X

X	EQU	([EBP-SIZE DAH_VARS].(X&_BP))

	ENDM


FIX	CV_SEG_TBL
FIX	CVG_CSEG
FIX	CV_SEGTBL_PTR
FIX	CV_SEGTBL_PTR_LIMIT
FIX	CV_EXETABLE_PTR
FIX	CV_PUT_LIMIT
FIX	CV_NEXT_SEG_TBL


DO_ADDRESS_HASH	PROC	NEAR
		;
		;NOW BUILD AND OUTPUT ADDRESS HASH
		;
		MOV	EAX,CV_HASH_COUNT

		OR	EAX,EAX
		JNZ	L0$
L00$:
		MOV	CV_HASH_HEADER._CVHH_CBADDRHASH,EAX

		RET

L0$:
		CALL	SORT_HASHES_GARRAY		;SORT IN ADDRESS ORDER

;		MOV	EAX,LAST_CVH_SEGMENT		;ALL CONSTANTS?

;		TEST	EAX,EAX
;		JZ	L00$

		PUSHM	EBP,EDI,ESI,EBX

		MOV	EBP,ESP
		ASSUME	EBP:PTR DAH_VARS
		SUB	ESP,SIZE DAH_VARS

		MOV	EAX,FINAL_HIGH_WATER

		LEA	EBX,CV_SEG_TBL
		MOV	ECX,LAST_CVH_SEGMENT
		;
		;NOW BUILD COUNT TABLE
		;
		PUSH	EAX
		CALL	GET_NEW_LOG_BLK

		MOV	CVG_CSEG,ECX			;== # OF SEGMENTS I ALLOW FOR
		MOV	EDI,EAX

		MOV	[EBX],EAX
		ADD	EAX,PAGE_SIZE

		ADD	EBX,4
		MOV	CV_SEGTBL_PTR_LIMIT,EAX

		MOV	CV_SEGTBL_PTR,EBX
		MOV	EBX,OFF EXETABLE

		XOR	ECX,ECX			;ALSO START WITH SYMBOL # 1
		MOV	EDX,1			;CURRENTLY LOOKING FOR SEG 1

		MOV	[EDI],ECX		;COUNT IS ZERO FOR SEGMENT #1
		MOV	ECX,CV_HASH_COUNT
L1$:
		MOV	ESI,[EBX]
		ADD	EBX,4

		MOV	CV_EXETABLE_PTR,EBX

		LEA	EBX,[ESI+PAGE_SIZE]
L11$:
		MOV	EAX,[ESI]._SEGMENT
		ADD	ESI,SIZEOF CVH_STRUCT
L13$:
		CMP	EDX,EAX
		JNZ	L15$

		INC	DPTR [EDI]		;COUNT SYMBOLS IN THAT SEGMENT
L17$:
		DEC	ECX
		JZ	L19$

		CMP	ESI,EBX
		JB	L11$

		MOV	EBX,CV_EXETABLE_PTR
		JMP	L1$

L15$:
		TEST	EAX,EAX			;CONSTANT?
		JZ	L17$

		INC	EDX
		ADD	EDI,4

		CMP	EDI,CV_SEGTBL_PTR_LIMIT
		JZ	L16$
L153$:
		MOV	DPTR [EDI],0
		JMP	L13$

L16$:
		PUSHM	EBX,EAX

		MOV	EBX,CV_SEGTBL_PTR
		CALL	GET_NEW_LOG_BLK

		MOV	[EBX],EAX
		ADD	EBX,4

		MOV	EDI,EAX
		ADD	EAX,PAGE_SIZE

		MOV	CV_SEGTBL_PTR,EBX
		MOV	CV_SEGTBL_PTR_LIMIT,EAX

		POPM	EAX,EBX

		JMP	L153$

L19$:
		;
		;NOW, OUTPUT STUFF
		;
		MOV	ESI,CVG_PUT_PTR
		ASSUME	ESI:NOTHING
		LEA	EAX,CV_SEG_TBL

		MOV	ECX,CVG_CSEG

		MOV	[ESI],ECX
		LEA	EBX,[ESI+PAGE_SIZE]

		MOV	EDI,[EAX]
		ADD	EAX,4

		ADD	ESI,4
		MOV	CV_NEXT_SEG_TBL,EAX

		LEA	EDX,[EDI+PAGE_SIZE]
		XOR	EAX,EAX

		TEST	ECX,ECX
		JZ	L29$
L20$:
		MOV	CV_SEGTBL_PTR_LIMIT,EDX

L21$:
		MOV	EDX,[EDI]		;# OF ENTRIES
		MOV	[ESI],EAX

		SHL	EDX,3			;*8 BYTES PER ENTRY
		ADD	ESI,4

		ADD	EAX,EDX
		ADD	EDI,4

		DEC	ECX
		JZ	L29$

		CMP	ESI,EBX
		JZ	L27$
L271$:
		CMP	EDI,CV_SEGTBL_PTR_LIMIT
		JNZ	L21$

		MOV	EDX,CV_NEXT_SEG_TBL

		MOV	EDI,[EDX]
		ADD	EDX,4

		MOV	CV_NEXT_SEG_TBL,EDX

		LEA	EDX,[EDI+PAGE_SIZE]
		JMP	L20$

L27$:
		PUSHM	ECX,EAX

		MOV	EAX,CVG_PUT_BLK
		MOV	ECX,PAGE_SIZE

		MOV	ESI,EAX
		CALL	MOVE_EAX_TO_FINAL_HIGH_WATER

		POPM	EAX,ECX

		JMP	L271$

L29$:
		MOV	ECX,ESI
		MOV	EAX,CVG_PUT_BLK

		SUB	ECX,EAX
		JZ	L3$

		CALL	MOVE_EAX_TO_FINAL_HIGH_WATER
L3$:
		;
		;NOW OUTPUT OFFSET COUNTS
		;
		LEA	EBX,CV_SEG_TBL			;TABLE POINTING TO COUNTS
		MOV	EDX,CVG_CSEG			;# OF COUNTS
L30$:
		MOV	EAX,[EBX]			;BLOCK
		MOV	ECX,EDX

		CMP	EDX,PAGE_SIZE/4
		JB	L31$

		MOV	ECX,PAGE_SIZE/4
L31$:
		SUB	EDX,ECX
		ADD	EBX,4

		SHL	ECX,2
		PUSH	EDX

		JZ	L33$

		CALL	MOVE_EAX_TO_FINAL_HIGH_WATER
L33$:
		MOV	EAX,[EBX-4]
		CALL	RELEASE_BLOCK

		POP	EDX

		TEST	EDX,EDX
		JNZ	L30$
		;
		;NOW, OUTPUT ACTUAL SYMBOL_OFFSETS AND SEGMENT_OFFSETS
		;
		MOV	EDI,CVG_PUT_BLK
		MOV	EBX,OFF EXETABLE

		INC	EDX			;CURRENTLY LOOKING FOR SEG 1
		MOV	ECX,CV_HASH_COUNT

		MOV	ESI,[EBX]
		ADD	EBX,4

		MOV	CV_EXETABLE_PTR,EBX
		LEA	EAX,[EDI+PAGE_SIZE]

		LEA	EBX,[ESI+PAGE_SIZE]
		MOV	CV_PUT_LIMIT,EAX
L41$:
		ASSUME	ESI:PTR CVH_STRUCT

		MOV	EAX,[ESI]._SEGMENT
		MOV	EDX,[ESI]._SEGMENT_OFFSET
		
		OR	EAX,EAX
		JZ	L47$

		MOV	EAX,[ESI]._SYMBOL_OFFSET
		MOV	[EDI+4],EDX

		MOV	[EDI],EAX
		ADD	EDI,8

		CMP	EDI,CV_PUT_LIMIT
		JNZ	L47$

		PUSH	ECX
		MOV	ECX,PAGE_SIZE

		LEA	EAX,[EDI-PAGE_SIZE]

		MOV	EDI,EAX
		CALL	MOVE_EAX_TO_FINAL_HIGH_WATER

		POP	ECX
L47$:
		DEC	ECX
		JZ	L49$

		ADD	ESI,SIZE CVH_STRUCT

		CMP	ESI,EBX
		JNZ	L41$

		MOV	EBX,CV_EXETABLE_PTR
		XOR	ESI,ESI

		MOV	EAX,[EBX-4]
		CALL	RELEASE_BLOCK

		MOV	[EBX-4],ESI
		MOV	ESI,[EBX]

		ADD	EBX,4

		MOV	CV_EXETABLE_PTR,EBX
		LEA	EBX,[ESI+PAGE_SIZE]

		JMP	L41$

L49$:
		MOV	EAX,CVG_PUT_BLK
		MOV	ECX,EDI

		SUB	ECX,EAX
		JZ	L5$

		CALL	MOVE_EAX_TO_FINAL_HIGH_WATER
L5$:
		;
		;STORE BYTE-COUNT FOR ADDRESS HASH STUFF
		;
		POP	ECX
		MOV	EAX,FINAL_HIGH_WATER

		SUB	EAX,ECX
		MOV	ESP,EBP

		ADD	BYTES_SO_FAR,EAX
		MOV	CV_HASH_HEADER._CVHH_CBADDRHASH,EAX

		POPM	EBX,ESI,EDI,EBP

		RET

DO_ADDRESS_HASH	ENDP



endif

		END

