#ifdef __arm__

#include "Shared/nds_asm.h"
#include "Shared/EmuSettings.h"
#include "SonSonVideo/SonSonVideo.i"

	.global gFlicker
	.global gTwitch
	.global gScaling
	.global gGfxMask
	.global yStart
	.global EMUPALBUFF
	.global sonVideo_0

	.global gfxInit
	.global gfxReset
	.global paletteInit
	.global paletteTxAll
	.global refreshGfx
	.global endFrame
	.global vblIrqHandler
	.global updateLCDRefresh
	.global hz55Refresh


	.syntax unified
	.arm

#ifdef GBA
	.section .ewram, "ax", %progbits	;@ For the GBA
#else
	.section .text						;@ For anything else
#endif
	.align 2
;@----------------------------------------------------------------------------
gfxInit:					;@ Called from machineInit
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldr r0,=OAM_BUFFER1			;@ No stray sprites please
	mov r1,#0x200+SCREEN_HEIGHT
	mov r2,#0x100
	bl memset_
	adr r0,scaleParms
	bl setupSpriteScaling

	bl sonVideoInit
	mov r0,#55
	bl setTargetFPS
//	bl updateLCDRefresh;

	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
scaleParms:					;@  NH     FH     NV     FV
	.long OAM_BUFFER1,0x0000,0x0100,0xff01,0x0140,0xfeb6
;@----------------------------------------------------------------------------
gfxReset:					;@ Called with CPU reset, r0 = selectedGame
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}

	ldr r0,=gfxState
	mov r1,#5					;@ 5*4
	bl memclr_					;@ Clear GFX regs

	mov r1,#REG_BASE
	ldr r0,=0x08F8				;@ Start-end
	strh r0,[r1,#REG_WIN0H]
	mov r0,#0x00C0				;@ Start-end
	strh r0,[r1,#REG_WIN0V]
	mov r0,#0x0000
	strh r0,[r1,#REG_WINOUT]

	ldr r0,=mainCpuSetIRQ		;@ Frame irq
	mov r1,#0
	ldr sonptr,=sonVideo_0
	bl sonVideoReset
	ldr r0,=EMU_RAM
	str r0,[sonptr,#gfxRAM]

	ldr r0,=BG_GFX+0x8000		;@ r0 = GBA/NDS BG tileset
	str r0,[sonptr,#chrGfxDest]

	ldr r0,=vromBase0
	ldr r0,[r0]
	str r0,[sonptr,#chrRomBase]
	ldr r0,=vromBase1
	ldr r0,[r0]
	str r0,[sonptr,#spriteRomBase]

	ldr r0,=gGammaValue
	ldrb r0,[r0]
	bl paletteInit				;@ Do palette mapping
	bl paletteTxAll

	ldmfd sp!,{r4,pc}

;@----------------------------------------------------------------------------
paletteInit:		;@ r0-r3 modified.
	.type paletteInit STT_FUNC
;@ Called by ui.c:  void map_palette(char gammaVal);
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r9,lr}
	mov r1,r0					;@ Gamma value = 0 -> 4
	ldr r8,=promBase			;@ Proms
	ldr r8,[r8]
	mov r7,#0xF0
	ldr r6,=MAPPED_RGB
	mov r4,#32					;@ Son Son bgr, r1=R, r2=G, r3=B
noMap:							;@ Map 0000rrrrggggbbbb  ->  0bbbbbgggggrrrrr
	ldrb r9,[r8,#32]
	and r0,r7,r9,lsl#4			;@ Red ready
	bl gPrefix
	mov r5,r0

	ldrb r9,[r8],#1
	and r0,r7,r9				;@ Green ready
	bl gPrefix
	orr r5,r5,r0,lsl#5

	and r0,r7,r9,lsl#4			;@ Blue ready
	bl gPrefix
	orr r5,r5,r0,lsl#10

	strh r5,[r6],#2
	subs r4,r4,#1
	bne noMap

	ldmfd sp!,{r4-r9,lr}
	bx lr

;@----------------------------------------------------------------------------
gPrefix:
	orr r0,r0,r0,lsr#4
;@----------------------------------------------------------------------------
gammaConvert:	;@ Takes value in r0(0-0xFF), gamma in r1(0-4),returns new value in r0=0x1F
;@----------------------------------------------------------------------------
	rsb r2,r0,#0x100
	mul r3,r2,r2
	rsbs r2,r3,#0x10000
	rsb r3,r1,#4
	orr r0,r0,r0,lsl#8
	mul r2,r1,r2
	mla r0,r3,r0,r2
	mov r0,r0,lsr#13

	bx lr
;@----------------------------------------------------------------------------
paletteTxAll:				;@ Called from ui.c
	.type paletteTxAll STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r5}

	ldr r2,=promBase			;@ Proms
	ldr r2,[r2]
	add r2,r2,#64
	ldr r3,=MAPPED_RGB
	ldr r4,=EMUPALBUFF
	add r5,r4,#0x200
	mov r1,#0x100
nomap2:
	ldrb r0,[r2],#1
	and r0,r0,#0x0F
	mov r0,r0,lsl#1
	ldrh r0,[r3,r0]
	strh r0,[r4],#2
	sub r1,r1,#1
	tst r1,#0x03
	addeq r4,r4,#24				;@ Next row
	tst r1,#0x3F
	subeq r4,r4,#0x1F8			;@ Next column
	tst r1,#0xFF
	bne nomap2

	add r3,r3,#32
	mov r1,#256
nomap3:
	ldrb r0,[r2],#1
	and r0,r0,#0x0F
	and r0,r0,#0x1F
	mov r0,r0,lsl#1
	ldrh r0,[r3,r0]
	strh r0,[r5],#2
	subs r1,r1,#1
	bne nomap3

	ldmfd sp!,{r4-r5}
	bx lr

;@----------------------------------------------------------------------------
updateLCDRefresh:
	.type updateLCDRefresh STT_FUNC
;@----------------------------------------------------------------------------
	ldr r0,=emuSettings
	ldr r0,[r0]
	tst r0,#1<<19
	moveq r0,#0
	movne r0,#-24
	str r0,lcdSkip
	moveq r0,#60-1
	movne r0,#55-1
	ldr r1,=fpsNominal
	strb r0,[r1]
	bx lr
;@----------------------------------------------------------------------------
vblIrqHandler:
	.type vblIrqHandler STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	bl calculateFPS

	ldrb r0,gScaling
	cmp r0,#UNSCALED
	moveq r5,#0
	ldrne r5,=0x80000000 + ((GAME_HEIGHT-SCREEN_HEIGHT)*0x10000) / (SCREEN_HEIGHT-1)	;@ NDS 0x2B10 (was 0x2AAB)
	ldrbeq r4,yStart
	movne r4,#0
	add r4,r4,#0x08
	mov r2,r4,lsl#16
//	orr r2,r2,#(256-SCREEN_WIDTH)/2

	ldr r0,gFlicker
	eors r0,r0,r0,lsl#31
	str r0,gFlicker
	addpl r5,r5,r5,lsl#16

	ldr r0,=scrollBuff
	mov r1,r0

	ldr r6,=scrollTemp
	add r4,r6,r4,lsl#2
	mov r12,#SCREEN_HEIGHT
scrolLoop2:
	ldr r6,[r4],#4
	add r6,r6,r2
	mov r3,r6
	stmia r0!,{r3,r6}
	adds r5,r5,r5,lsl#16
	addcs r2,r2,#0x10000
	addcs r4,r4,#4
	subs r12,r12,#1
	bne scrolLoop2


	mov r5,#REG_BASE
	strh r5,[r5,#REG_DMA0CNT_H]	;@ DMA0 stop

	add r0,r5,#REG_DMA0SAD
//	mov r1,r1					;@ DMA0 src, scrolling:
	ldmia r1!,{r3-r4}			;@ Read
	add r2,r5,#REG_BG0HOFS		;@ DMA0 always goes here
	stmia r2,{r3-r4}			;@ Set 1st value manually, HBL is AFTER 1st line
	ldr r3,=0x96600002			;@ noIRQ hblank 32bit repeat incsrc inc_reloaddst, 2 word
	stmia r0,{r1-r3}			;@ DMA0 go

	add r0,r5,#REG_DMA3SAD

	ldr r1,dmaOamBuffer			;@ DMA3 src, OAM transfer:
	mov r2,#OAM					;@ DMA3 dst
	mov r3,#0x84000000			;@ noIRQ 32bit incsrc incdst
	orr r3,r3,#24*2				;@ 24 sprites * 2 longwords
	stmia r0,{r1-r3}			;@ DMA3 go

	ldr r1,=EMUPALBUFF			;@ DMA3 src, Palette transfer:
	mov r2,#BG_PALETTE			;@ DMA3 dst
	mov r3,#0x84000000			;@ noIRQ 32bit incsrc incdst
	orr r3,r3,#0x100			;@ 256 words (1024 bytes)
	stmia r0,{r1-r3}			;@ DMA3 go

	mov r0,#0x0011
	ldrb r1,gGfxMask
	bic r0,r0,r1
	strh r0,[r5,#REG_WININ]

	ldr r0,=emuSettings
	ldr r0,[r0]
	ands r0,r0,#1<<19
	beq exit55Hz
	ldr r0,=pauseEmulation
	ldrb r0,[r0]
	cmp r0,#0
	bne exit55Hz
	ldr r0,lcdSkip
	cmp r0,#0
	strbmi r0,doLowRefresh
exit55Hz:

	blx scanKeys
	ldmfd sp!,{r4-r6,pc}

;@----------------------------------------------------------------------------
hz55Refresh:
;@----------------------------------------------------------------------------
	ldrsb r0,doLowRefresh
	cmp r0,#0
	bxpl lr
	adds r1,r0,#26
	movpl r1,#0
	strb r1,doLowRefresh
	movmi r0,#-26

	mov r2,#REG_BASE
	ldrh r1,[r2,#REG_VCOUNT]
	add r1,r1,r0
	cmp r1,#202
	movmi r1,#202
	strh r1,[r2,#REG_VCOUNT]
	bx lr

;@----------------------------------------------------------------------------
refreshGfx:					;@ Called from C when changing scaling.
	.type refreshGfx STT_FUNC
;@----------------------------------------------------------------------------
	ldr sonptr,=sonVideo_0
;@----------------------------------------------------------------------------
endFrame:					;@ Called just before screen end (~line 224)	(r0-r2 safe to use)
;@----------------------------------------------------------------------------
	stmfd sp!,{r3,lr}

	ldr r0,=scrollTemp
	bl copyScrollValues

	ldr r0,=BG_GFX
	bl convertChrTileMap
	ldr r0,tmpOamBuffer
	bl convertSpritesSonSon
;@--------------------------
	ldr r0,dmaOamBuffer
	ldr r1,tmpOamBuffer
	str r0,tmpOamBuffer
	str r1,dmaOamBuffer

	mov r0,#1
	str r0,oamBufferReady

	ldr r0,=windowTop			;@ Load wTop, store in wTop+4.......load wTop+8, store in wTop+12
	ldmia r0,{r1-r3}			;@ Load with increment after
	stmib r0,{r1-r3}			;@ Store with increment before

	ldmfd sp!,{r3,lr}
	bx lr

;@----------------------------------------------------------------------------
gFlicker:		.byte 1
				.space 2
gTwitch:		.byte 0

gScaling:		.byte SCALED
gGfxMask:		.byte 0
yStart:			.byte 0
doLowRefresh:	.byte 0
;@----------------------------------------------------------------------------

tmpOamBuffer:		.long OAM_BUFFER1
dmaOamBuffer:		.long OAM_BUFFER2

oamBufferReady:		.long 0
;@----------------------------------------------------------------------------

gfxState:
adjustBlend:
	.long 1
windowTop:
	.long 0,0,0,0				;@ L/R scrolling in unscaled mode

lcdSkip:
	.long 0

	.byte 0
	.byte 0
	.byte 0,0

#ifdef GBA
	.section .sbss				;@ This is EWRAM on GBA with devkitARM
#else
	.section .bss
#endif
	.align 2
scrollTemp:
	.space 0x400*2
OAM_BUFFER1:
	.space 0x400
OAM_BUFFER2:
	.space 0x400
DMA0BUFF:
	.space 0x200
scrollBuff:
	.space 0x300*4				;@ Scrollbuffer. SCREEN_HEIGHT * 3 * 4
MAPPED_RGB:
	.space 0x2000				;@ 32 * 2
EMUPALBUFF:
	.space 0x200*2
sonVideo_0:
	.space sonVideoSize

;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
