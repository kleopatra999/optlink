/*
IMPNAME_STRUCT	STRUC			;DESCRIBES MODULES AND SYMBOLS IMPORTED BY NAME

_IMP_NEXT_HASH_GINDEX	DD	?	;NEXT SAME HASH
_IMP_OFFSET		DD	?	;OFFSET IN IMPNAME TABLE (0 IF UNDEF)
if	fg_pe
_IMP_LENGTH		DD	?	;
endif
_IMP_TEXT		DD	?	;

IMPNAME_STRUCT	ENDS

_IMP_HINT		EQU	<_IMP_OFFSET>	;PE USAGE


IMPMOD_HASH_SIZE	EQU	61

IMPMOD_STRUCT	STRUC

_IMPM_NEXT_HASH_GINDEX	DD	?	;NEXT MODULE SAME HASH
_IMPM_NEXT_GINDEX	DD	?	;MODULE ORDER
_IMPM_NAME_SYM_GINDEX	DD	?	;SYMBOLS IMPORTING FROM THIS MODULE BY NAME
_IMPM_ORD_SYM_GINDEX	DD	?	;SYMBOLS IMPORTING FROM THIS MODULE BY ORDINAL
_IMPM_N_IMPORTS		DD	?	;NUMBER OF REFERENCED IMPORTS
_IMPM_JREF_START	DD	?	;FIRST JREF FOR THIS MODULE
_IMPM_THUNK_OFFSET_START DD	?	;FIRST IMPORT THUNK OFFSET FOR THIS MODULE
_IMPM_NUMBER		DD	?	;IMPORT MODULE # (FOR NE OUTPUT)
_IMPM_LENGTH		DD	?	;MODULE NAME LENGTH		;**
_IMPM_TEXT		DD	?	;MODULE NAME			;**

IMPMOD_STRUCT	ENDS

_IMPM_OFFSET		EQU	_IMPM_N_IMPORTS		;FOR SEGM ADDRESS IN NAMETABLE


PENT_STRUCT	STRUC			;POSSIBLE MOVABLE ENTRY POINTS

_PENT_NEXT_HASH_GINDEX	DD	?	;NEXT PENT_ITEM THIS HASH VALUE
_PENT_NEXT_GINDEX	DD	?	;
_PENT_SEGM_GINDEX	DD	?	;SEGMENT OR SYMBOL OR GROUP
_PENT_OFFSET		DD	?	;OFFSET FROM ABOVE
_PENT_REF_COUNT		DD	?	;# OF TIMES REFERENCED (HIGH_BITS 00=SEGMENT, 01=SYMBOL, 10=GROUP)

PENT_STRUCT	ENDS

_PENT_OS2_NUMBER	EQU	_PENT_SEGM_GINDEX

PENT_REF_COUNT		RECORD	P_PENT_FLAGS:2,P_REF_COUNT:30


ENTRY_STRUCT	STRUC

_ENTRY_NEXT_HASH_GINDEX	DD	?	;NEXT PENT_ITEM THIS HASH VALUE
_ENTRY_OFFSET		DD	?	;OFFSET FROM SEGMENT
_ENTRY_SEGMENT		DD	?	;SEGMENT NUMBER
_ENTRY_ORD		DD	?	;ORDINAL NUMBER FOR ENTRY POINT

ENTRY_STRUCT	ENDS


ENT_STRUCT	STRUC		;DESCRIBES ALL EXPORTED SYMBOLS

_ENT_NEXT_HASH_GINDEX		DD	?	;NEXT INDEX, HASH ORDER
_ENT_NEXT_ENT_GINDEX		DD	?	;ENTRY ORDER...
_ENT_START_BLOCK		DD	?
_ENT_INTERNAL_NAME_GINDEX	DD	?	;PUBLIC SYMBOL THIS REFERS TO
_ENT_ORD			DD	?	;NON-ZERO IF SPECIFIED
_ENT_FLAGS			DB	?	;ENT_RESIDENTNAME, ENT_NODATA
_ENT_FLAGS_EXT			DB	?	;ENT_EXT_DATA
_ENT_PWORDS			DB	?	;0-31
_ENT_START_ENTRY		DB	?
_ENT_TEXT			DD	?

ENT_STRUCT	ENDS


ENTRY_RECORD	RECORD	ENT_USE_EXTNAM:1,ENT_BYNAME:1,ENT_UNDEFINED:1,ENT_PRIVATE:1,ENT_NONAME:1,ENT_ORD_SPECIFIED:1,ENT_RESIDENTNAME:1,ENT_NODATA:1

ENTRY_RECORD_EXT RECORD	ENT_EXT_DATA:1,ENT_EXT_DEFREF:1,ENT_EXT_BYORD:1,ENT_EXT_MORESETTINGS:5

if	V5
_ENT_LIBRARY_PAGE	EQU	_ENT_NEXT_HASH_GINDEX
_ENT_DELTA_BLOCK	EQU	_ENT_ORD
_ENT_DELTA_ENTRY	EQU	_ENT_PWORDS
_ENT_UNDECO_GINDEX	EQU	_ENT_START_BLOCK
endif
*/

typedef struct SEGTBL_STRUCT
{
    int _SEGTBL_FADDR;
    int _SEGTBL_PSIZE;	// ALSO A LINK FOR ENTRIES...
    int _SEGTBL_FLAGS;
    int _SEGTBL_LSIZE;
} SEGTBL_STRUCT;

/*
SEGTBL_BITS	EQU	4

CONV_EAX_SEGTBL_ECX	MACRO

		MOV	ECX,EAX

		SHL	ECX,SEGTBL_BITS

		ADD	ECX,OFF SEGMENT_TABLE
		ASSUME	ECX:PTR SEGTBL_STRUCT

		ENDM

*/
