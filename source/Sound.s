
#ifdef __arm__

#include "AY38910/AY38910.i"

#define COUNTER (65)

	.global soundInit
	.global soundReset
	.global VblSound2
	.global setMuteSoundGUI
	.global setMuteSoundGame
	.global soundCpuTimer
	.global soundWriteAY0
	.global soundWriteAY1
	.global ay38910_0
	.global ay38910_1

	.extern pauseEmulation


;@----------------------------------------------------------------------------

	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
soundInit:
	.type soundInit STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldr r0,=ay38910_0

	ldmfd sp!,{lr}
//	bx lr

;@----------------------------------------------------------------------------
soundReset:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov r0,#COUNTER
	str r0,timer240Hz
	ldr r0,=ay38910_0
	bl ay38910Reset				;@ Sound
	ldr r0,=ay38910_1
	bl ay38910Reset				;@ Sound
	ldmfd sp!,{lr}
	bx lr

;@----------------------------------------------------------------------------
setMuteSoundGUI:
	.type   setMuteSoundGUI STT_FUNC
;@----------------------------------------------------------------------------
	ldr r1,=pauseEmulation		;@ Output silence when emulation paused.
	ldrb r0,[r1]
	strb r0,muteSoundGUI
	bx lr
;@----------------------------------------------------------------------------
setMuteSoundGame:			;@ For System E ?
;@----------------------------------------------------------------------------
	strb r0,muteSoundGame
	bx lr
;@----------------------------------------------------------------------------
VblSound2:					;@ r0=length, r1=pointer, r2=formats?
;@----------------------------------------------------------------------------
	stmfd sp!,{r0,r1,r4,r5,lr}

	ldr r2,muteSound
	cmp r2,#0
	bne silenceMix

	mov r0,r0,lsl#2
	ldr r1,=mixSpace0
	ldr r2,=ay38910_0
	bl ay38910Mixer

	ldmfd sp,{r0}
	mov r0,r0,lsl#2
	ldr r1,=mixSpace1
	ldr r2,=ay38910_1
	bl ay38910Mixer

	ldmfd sp,{r0,r1}
	ldr r2,=mixSpace0
	ldr r3,=mixSpace1
//	ldr r12,soundFilter
mixLoop01:
	ldrsh r4,[r2],#2
	ldrsh r5,[r2],#2
	add r4,r4,r5
	ldrsh r5,[r2],#2
	add r4,r4,r5
	ldrsh r5,[r2],#2
	add r4,r4,r5

	ldrsh r5,[r3],#2
	add r4,r4,r5
	ldrsh r5,[r3],#2
	add r4,r4,r5
	ldrsh r5,[r3],#2
	add r4,r4,r5
	ldrsh r5,[r3],#2
	add r4,r4,r5

//	sub r12,r12,r12,asr#2
//	add r12,r12,r4,lsl#16-3-2
//	mov r4,r12,lsr#16

	mov r4,r4,lsl#16-3
	mov r4,r4,lsr#16
	orr r4,r4,r4,lsl#16
	subs r0,r0,#1
	strpl r4,[r1],#4
	bhi mixLoop01

//	str r12,soundFilter
	ldmfd sp!,{r0,r1,r4,r5,lr}
	bx lr

silenceMix:
	ldmfd sp!,{r0,r1,r4,r5}
	mov r12,r0
	mov r2,#0
silenceLoop:
	subs r12,r12,#1
	strpl r2,[r1],#4
	bhi silenceLoop

	ldmfd sp!,{lr}
	bx lr

soundFilter:
	.long 0
;@----------------------------------------------------------------------------
soundCpuTimer:				;@ Call this every scanline
;@----------------------------------------------------------------------------
	ldr r0,timer240Hz
	subs r0,r0,#1
	moveq r0,#COUNTER
	str r0,timer240Hz
	movne r0,#0
	b soundCpuSetIRQ

;@----------------------------------------------------------------------------
soundWriteAY0:				;@ 0x2000-0x2001
;@----------------------------------------------------------------------------
//	mov r11,r11					;@ No$GBA breakpoint
	stmfd sp!,{r3,r12,lr}
	tst r12,#1
	ldr r1,=ay38910_0
	adr lr,soundRet
	beq ay38910IndexW
	b ay38910DataW
soundRet:
	ldmfd sp!,{r3,r12,pc}
;@----------------------------------------------------------------------------
soundWriteAY1:				;@ 0x4000-0x4001
;@----------------------------------------------------------------------------
//	mov r11,r11					;@ No$GBA breakpoint
	stmfd sp!,{r3,r12,lr}
	tst r12,#1
	ldr r1,=ay38910_1
	adr lr,soundRet
	beq ay38910IndexW
	b ay38910DataW

;@----------------------------------------------------------------------------
muteSound:
muteSoundGUI:
	.byte 0
muteSoundGame:
	.byte 0
	.space 2
timer240Hz:
	.long 0

	.section .bss
ay38910_0:
	.space aySize
ay38910_1:
	.space aySize
mixSpace0:
	.space 0x8000
mixSpace1:
	.space 0x8000
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
