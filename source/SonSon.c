#include <nds.h>

#include "SonSon.h"
#include "Cart.h"
#include "cpu.h"
#include "Gfx.h"
#include "Sound.h"
#include "ARM6809/ARM6809.h"
#include "SonSonVideo/SonSonVideo.h"

int packState(void *statePtr) {
	int size = 0;
	memcpy(statePtr+size, soundCpuRam, sizeof(soundCpuRam));
	size += sizeof(soundCpuRam);
	size += ay38910SaveState(statePtr+size, &ay38910_1);
	size += ay38910SaveState(statePtr+size, &ay38910_0);
	size += sonSaveState(statePtr+size, &sonVideo_0);
	size += m6809SaveState(statePtr+size, &m6809CPU1);
	size += m6809SaveState(statePtr+size, &m6809CPU0);
	return size;
}

void unpackState(const void *statePtr) {
	int size = 0;
	memcpy(soundCpuRam, statePtr+size, sizeof(soundCpuRam));
	size += sizeof(soundCpuRam);
	size += ay38910LoadState(&ay38910_1, statePtr+size);
	size += ay38910LoadState(&ay38910_0, statePtr+size);
	size += sonLoadState(&sonVideo_0, statePtr+size);
	size += m6809LoadState(&m6809CPU1, statePtr+size);
	m6809LoadState(&m6809CPU0, statePtr+size);
}

int getStateSize() {
	int size = 0;
	size += sizeof(soundCpuRam);
	size += ay38910GetStateSize();
	size += ay38910GetStateSize();
	size += sonGetStateSize();
	size += m6809GetStateSize();
	size += m6809GetStateSize();
	return size;
}

static const ArcadeRom sonsonRoms[17] = {
	// ROM_REGION( 0x10000, "maincpu", 0 ) // 64k for code + 3*16k for the banked ROMs images
	{"ss.01e",     0x4000, 0xcd40cc54},
	{"ss.02e",     0x4000, 0xc3476527},
	{"ss.03e",     0x4000, 0x1fd0e729},
	// ROM_REGION( 0x10000, "audiocpu", 0 )
	{"ss_6.c11",   0x2000, 0x1135c48a},
	// ROM_REGION( 0x04000, "gfx1", 0 )
	{"ss_7.b6",    0x2000, 0x990890b1},
	{"ss_8.b5",    0x2000, 0x9388ff82},
	// ROM_REGION( 0x0c000, "gfx2", 0 )
	{"ss_9.m5",    0x2000, 0x8cb1cacf},
	{"ss_10.m6",   0x2000, 0xf802815e},
	{"ss_11.m3",   0x2000, 0x4dbad88a},
	{"ss_12.m4",   0x2000, 0xaa05e687},
	{"ss_13.m1",   0x2000, 0x66119bfa},
	{"ss_14.m2",   0x2000, 0xe14ef54e},
	// ROM_REGION( 0x0340, "proms", 0 )
	{"ssb4.b2",    0x0020, 0xc8eaf234},
	{"ssb5.b1",    0x0020, 0x0e434add},
	{"ssb2.c4",    0x0100, 0xc53321c6},
	{"ssb3.h7",    0x0100, 0x7d2c324a},
	{"ssb1.k11",   0x0100, 0xa04b0cfe},
};

static const ArcadeRom sonsonjRoms[20] = {
	// ROM_REGION( 0x10000, "maincpu", 0 ) // 64k for code + 3*16k for the banked ROMs images
	{"ss_0.l9",    0x2000, 0x705c168f},
	{"ss_1.j9",    0x2000, 0x0f03b57d},
	{"ss_2.l8",    0x2000, 0xa243a15d},
	{"ss_3.j8",    0x2000, 0xcb64681a},
	{"ss_4.l7",    0x2000, 0x4c3e9441},
	{"ss_5.j7",    0x2000, 0x847f660c},
	// ROM_REGION( 0x10000, "audiocpu", 0 )
	{"ss_6.c11",   0x2000, 0x1135c48a},
	// ROM_REGION( 0x04000, "gfx1", 0 )
	{"ss_7.b6",    0x2000, 0x990890b1},
	{"ss_8.b5",    0x2000, 0x9388ff82},
	// ROM_REGION( 0x0c000, "gfx2", 0 )
	{"ss_9.m5",    0x2000, 0x8cb1cacf},
	{"ss_10.m6",   0x2000, 0xf802815e},
	{"ss_11.m3",   0x2000, 0x4dbad88a},
	{"ss_12.m4",   0x2000, 0xaa05e687},
	{"ss_13.m1",   0x2000, 0x66119bfa},
	{"ss_14.m2",   0x2000, 0xe14ef54e},
	// ROM_REGION( 0x0340, "proms", 0 )
	{"ssb4.b2",    0x0020, 0xc8eaf234},
	{"ssb5.b1",    0x0020, 0x0e434add},
	{"ssb2.c4",    0x0100, 0xc53321c6},
	{"ssb3.h7",    0x0100, 0x7d2c324a},
	{"ssb1.k11",   0x0100, 0xa04b0cfe},
};

const ArcadeGame sonsonGames[GAME_COUNT] = {
	AC_GAME("sonson",   "Son Son", sonsonRoms)
	AC_GAME("sonsonj",  "Son Son (Japan)", sonsonjRoms)
};
