/** @file debug_macros.h
 *  @brief internal macros used by debug_stub routines
 *
 */

/* Copyright (C) 2007-2010 the NxOS developers
 *
 * Module Developed by: TC Wan <tcwan@cs.usm.my>
 *
 * See AUTHORS for a full list of the developers.
 *
 * See COPYING for redistribution license
 *
 */

#ifndef __DEBUG_MACROS_H__
#define __DEBUG_MACROS_H__



/** @addtogroup debug_macros */
/*@{*/

/* _dbg_jumpTableHandler
 *      Call Jump Table Routine based on Index
 *	On entry:
 *	  jumptableaddr is the address (constant) of the Jump Table
 *	  jumpreg is the register used to perform the indirect jump
 *	  indexreg contains jump table index value
 */
	.macro  _dbg_jumpTableHandler   jumptableaddr, jumpreg, indexreg

	ldr	 \jumpreg, =\jumptableaddr
	ldr	 \jumpreg, [\jumpreg, \indexreg, lsl #2]
	mov	 lr, pc
	bx	  \jumpreg	/* Call Command Handler Routine */
	.endm


/* _dbg_thumbDecodeEntry
 *      Load Thumb Instruction Decoder Entry
 *      On entry:
 *        instrreg is the register to load the instruction into
 *        instrmask is the register to load the instruction mask into
 *        codehandler is the register to load the code handling routine into
 *        indexreg contains decode table index value
 *      NOTE: instrreg, instrmask, codehandler must be in increasing register number order
 */
        .macro  _dbg_thumbDecodeEntry   instrreg, instrmask, codehandler, indexreg

        ldr      \instrmask, =debug_thumbDecodeTable                    /* Temporary register */
        add      \instrmask, \instrmask, \indexreg, lsl #3
        ldm      \instrmask, {\instrreg, \codehandler}                  /* LSHW: IID, MSHW: IBM */
        mov      \instrmask, \instrreg, lsr #16
        and      \instrreg, \instrreg, #HLFWRD0
        .endm

/* _dbg_armDecodeEntry
 *      Load ARM Instruction Decoder Entry
 *      On entry:
 *        instrreg is the register to load the instruction into
 *        instrmask is the register to load the instruction mask into
 *        codehandler is the register to load the code handling routine into
 *        indexreg contains decode table index value
 *      NOTE: instrreg, instrmask, codehandler must be in increasing register number order
 */
        .macro  _dbg_armDecodeEntry   instrreg, instrmask, codehandler, indexreg

        ldr      \instrmask, =debug_thumbDecodeTable                    /* Temporary register */
        add      \instrmask, \instrmask, \indexreg, lsl #3
        add      \instrmask, \instrmask, \indexreg, lsl #2              /* 12  byte entries */
        ldm      \instrmask, {\instrreg, \instrmask, \codehandler}
        .endm

/* _asciiz
 *	Terminate string given string buffer pointer in \strptr
 *	scratchreg is used as a scratch register (destroyed)
 *
 */
	.macro	_asciiz	strptr, scratchreg
	mov	\scratchreg, #0				/* ASCIIZ character */
	strb	\scratchreg, [\strptr]			/* Terminate ASCII string */
 	.endm


/* _dbg_stpcpy
 *	_dbg_stpcpy macro
 *	On entry:
 *	  deststrptr: Destination string
 *	  sourcestrptr: Source string
 *	  scratchreg: scratch register for copying
 *	On exit:
 *	  deststrptr: Pointer to ASCIIZ character in destination string
 *	  sourcestrptr: Pointer to next character slot in source string (after ASCIIZ)
 *	  scratchreg: destroyed
 */
	.macro  _dbg_stpcpy	 deststrptr, sourcestrptr, scratchreg
1:	ldrb	\scratchreg, [\sourcestrptr], #1
	strb	\scratchreg, [\deststrptr], #1
	teq	 \scratchreg, #0
	bne	 1b
	sub	 \deststrptr, \deststrptr, #1	/* Adjust Destination string pointer to point at ASCIIZ character */
	.endm

/* _dbg_memcpy
 *      _dbg_stpcpy macro
 *      On entry:
 *        deststrptr: Destination string
 *        sourcestrptr: Source string
 *        sizereg: Number of bytes to copy
 *        scratchreg: scratch register for copying
 *      On exit:
 *        deststrptr: Pointer to next character slot in destination string
 *        sourcestrptr: Pointer to next character slot in source string
 *        sizereg, scratchreg: destroyed
 */
        .macro  _dbg_memcpy      deststrptr, sourcestrptr, sizereg, scratchreg
1:      ldrb    \scratchreg, [\sourcestrptr], #1
        strb    \scratchreg, [\deststrptr], #1
        subs    \sizereg, \sizereg, #1
        bne      1b
        .endm

/* _dbg_outputMsgValidResponse
 *	Return Message with valid response ('+$')
 *	On exit:
 *	  R0: Pointer to Output Buffer next character slot location
 *        R1: destroyed
 *	  R2: destroyed
 */
	.macro  _dbg_outputMsgValidResponse
	ldr	 r0, =debug_OutMsgBuf
	ldr	 r1, =debug_ValidResponsePrefix
	_dbg_stpcpy	 r0, r1, r2
	.endm


/* _dbg_outputMsgStatusOk
 *	Return Message with Ok ('+$OK') status
 *	On exit:
 *        R0: Pointer to Output Buffer ASCIIZ location
 *	  R1: destroyed
 *	  R2: destroyed
 */
	.macro  _dbg_outputMsgStatusOk
	ldr	 r0, =debug_OutMsgBuf
	ldr	 r1, =debug_OkResponse			/* ASCIIZ terminated */
	_dbg_stpcpy	r0, r1, r2
	.endm

/* _dbg_outputMsgStatusErr
 *	Return Message with Error ('-$ENN') status
 *	On entry:
 *	  R0: error code
 *	On exit:
 *        R0: Pointer to Output Buffer ASCIIZ location
 *	  R1: destroyed
 *	  R2: destroyed
 *	  R3: destroyed
 */
	.macro  _dbg_outputMsgStatusErr
	mov	r1, r0
	ldr	r0, =debug_OutMsgBuf
	ldr	r2, =debug_ErrorResponsePrefix
	_dbg_stpcpy	 r0, r2, r3
	bl	byte2ascii	  /* R0 points to buffer position after byte value */
	_asciiz	r0, r1
	.endm

/* _dbg_outputMsgStatusErrCode
 *	Return Message with Error ('-$ENN') status
 *	On exit:
 *        R0: Pointer to Output Buffer ASCIIZ location
 *	  R1: destroyed
 *	  R2: destroyed
 */
	.macro  _dbg_outputMsgStatusErrCode errcode
	ldr	r0, =debug_OutMsgBuf
	ldr	r1, =debug_ErrorResponsePrefix
	_dbg_stpcpy	 r0, r1, r2
	mov	r1, #\errcode
	bl	byte2ascii	  /* R0 points to buffer position after byte value */
	_asciiz	r0, r1
	.endm

/* _dbg_outputMsgStatusSig
 *	Return Message with Signal ('+$SNN') status
 *	On exit:
 *        R0: Pointer to Output Buffer ASCIIZ location
 *	  R1: destroyed
 *	  R2: destroyed
 */
	.macro  _dbg_outputMsgStatusSig statuscode
	ldr	r0, =debug_OutMsgBuf
	ldr	r1, =debug_SignalResponsePrefix
	_dbg_stpcpy	 r0, r1, r2
	mov	r1, #\statuscode
	bl	byte2ascii	  /* R0 points to buffer position after byte value */
	_asciiz	r0, r1
	.endm

/* _getdbgregisterfromindex
 *      Retrieve register contents from debugger stack given index
 *
 *      On entry:
 *        indexreg contains debugger stack index value (0-max index)
 *      On exit:
 *        indexreg: Breakpoint index (preserved)
 *        contentsreg: Register Contents for given index
 */
        .macro  _getdbgregisterfromindex  indexreg, contentsreg
        ldr      \contentsreg, =__debugger_stack_bottom__
        ldr      \contentsreg, [\contentsreg, \indexreg, lsl #2]
        .endm

/* _setdbgregisterfromindex
 *      Store register contents to debugger stack given index
 *
 *      On entry:
 *        indexreg contains debugger stack index value (0-max index)
 *        contentsreg: Register Contents for given index
 *        addressreg: Scratch register for address pointer
 *      On exit:
 *        indexreg: Breakpoint index (preserved)
 *        contentsreg: Register Contents for given index
 */
        .macro  _setdbgregisterfromindex  indexreg, contentsreg, addressreg
        ldr      \addressreg, =__debugger_stack_bottom__
        str      \contentsreg, [\addressreg, \indexreg, lsl #2]
        .endm


/* _index2bkptindex_addr
 *	Convert Breakpoint index to breakpoing entry address
 *
 *	On entry:
 *	  indexreg contains breakpoint index value
 *	On exit:
 *	  indexreg: Breakpoint index (preserved)
 *	  addrreg: Breakpoint Entry Address
 */
	.macro _index2bkptindex_addr indexreg, addrreg
	ldr	 \addrreg, =__breakpoints_start__
	add	 \addrreg, \addrreg, \indexreg, lsl #3	   /* Calculate Breakpoint Entry Address */
	.endm

/* _dbg_getstate
 *	Get Debugger State
 *	On exit:
 *	  reg: Debugger State enum
 */
	.macro _dbg_getstate	reg
	ldr	 \reg, =debug_state
	ldr	 \reg, [\reg]
	.endm

/* _dbg_setstate
 *	Set Debugger State to given value
 *	On exit:
 *	  r0, r1: destroyed
 */
	.macro _dbg_setstate	state
	ldr	 r0, =\state
	ldr	 r1, =debug_state
	str	 r0, [r1]
	.endm

/* _dbg_getcurrbkpt_index
 *	Get current breakpoint index
 *	On exit:
 *	  reg: Breakpoint index
 */
	.macro _dbg_getcurrbkpt_index   reg
	ldr	 \reg, =debug_curr_breakpoint
	ldr	 \reg, [\reg]
	.endm

/* _dbg_setcurrbkpt_index
 *	Set current breakpoint index
 *	On exit:
 *	  r1: destroyed
 */
	.macro _dbg_setcurrbkpt_index  reg
	ldr	 r1, =debug_curr_breakpoint
	str	 \reg, [r1]
	.endm

/* _dbg_getabortedinstr_addr
 *	Get aborted instruction address
 *	On exit:
 *	  reg: aborted instruction address
 */
        .macro _dbg_getabortedinstr_addr  reg
	ldr	 \reg, =__debugger_stack_bottom__
	ldr	 \reg, [\reg]
	.endm

/* _dbg_setabortedinstr_addr
 *	Set aborted instruction address
 *	On exit:
 *	  r1: destroyed
 */
        .macro _dbg_setabortedinstr_addr  reg
        ldr   r1, =__debugger_stack_bottom__
        str   \reg, [r1]
        .endm


 /*@}*/

#endif /* __DEBUG_MACROS_H__ */
