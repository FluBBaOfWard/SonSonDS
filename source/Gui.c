#include <nds.h>

#include "Gui.h"
#include "Shared/EmuMenu.h"
#include "Shared/EmuSettings.h"
#include "Shared/FileHelper.h"
#include "Main.h"
#include "FileHandling.h"
#include "Cart.h"
#include "Gfx.h"
#include "io.h"
#include "ARM6809/Version.h"
#include "AY38910/Version.h"
#include "SonSonVideo/Version.h"

#define EMUVERSION "V0.1.1 2021-11-28"

const fptr fnMain[] = {nullUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI};

const fptr fnList0[] = {uiDummy};
const fptr fnList1[] = {ui8, loadState, saveState, saveSettings, resetGame};
const fptr fnList2[] = {ui4, ui5, ui6, ui7};
const fptr fnList3[] = {uiDummy};
const fptr fnList4[] = {autoBSet, autoASet, controllerSet, swapABSet};
const fptr fnList5[] = {scalingSet, flickSet, gammaSet, bgrLayerSet, sprLayerSet};
const fptr fnList6[] = {speedSet, autoStateSet, autoSettingsSet, autoNVRAMSet, autoPauseGameSet, powerSaveSet, screenSwapSet, debugTextSet, sleepSet};
const fptr fnList7[] = {coinageSet, coinAffectSet, demoSet, livesSet, difficultSet, bonusSet, secondPlayerSet, flipSet, serviceSet, freezeSet};
const fptr fnList8[] = {quickSelectGame, quickSelectGame, quickSelectGame};
const fptr fnList9[] = {uiDummy};
const fptr *const fnListX[] = {fnList0, fnList1, fnList2, fnList3, fnList4, fnList5, fnList6, fnList7, fnList8, fnList9};
const u8 menuXItems[] = {ARRSIZE(fnList0), ARRSIZE(fnList1), ARRSIZE(fnList2), ARRSIZE(fnList3), ARRSIZE(fnList4), ARRSIZE(fnList5), ARRSIZE(fnList6), ARRSIZE(fnList7), ARRSIZE(fnList8), ARRSIZE(fnList9)};
const fptr drawUIX[] = {uiNullNormal, uiFile, uiOptions, uiAbout, uiController, uiDisplay, uiSettings, uiDipswitches, uiLoadGame, uiDummy};
const u8 menuXBack[] = {0,0,0,0,2,2,2,2,1,8};

u8 g_gammaValue = 0;

char *const autoTxt[] = {"Off","On","With R"};
char *const speedTxt[] = {"Normal","200%","Max","50%"};
char *const sleepTxt[] = {"5min","10min","30min","Off"};
char *const brighTxt[] = {"I","II","III","IIII","IIIII"};
char *const ctrlTxt[] = {"1P","2P"};
char *const dispTxt[] = {"Unscaled","Scaled"};
char *const flickTxt[] = {"No Flicker","Flicker"};

char *const coinTxt[] = {
	"1 Coin - 1 Credit","1 Coin - 2 Credits","1 Coin - 3 Credits","1 Coin - 4 Credits",
	"1 Coin - 5 Credits","1 Coin - 6 Credits","1 Coin - 7 Credits","2 Coins - 1 Credit",
	"2 Coins - 3 Credits","2 Coins - 5 Credits","3 Coins - 1 Credit","3 Coins - 2 Credits",
	"3 Coins - 4 Credits","4 Coins - 1 Credit","4 Coins - 3 Credits","Free Play",
};
char *const credit2Txt[] = {"1 Credit","2 Credits"};
char *const coinAffectTxt[] = {"Coin A","Coin B"};
char *const diffTxt[] = {"Easy","Normal","Difficult","Very Difficult"};
char *const livesTxt[] = {"3","4","5","7"};
char *const bonusTxt[] = {"20K","30K","20K 80K 100K+","30K 90K 120K+"};


void setupGUI() {
	emuSettings = AUTOPAUSE_EMULATION;
	keysSetRepeat(25, 4);	// Delay, repeat.
	openMenu();
}

/// This is called when going from emu to ui.
void enterGUI() {
}

/// This is called going from ui to emu.
void exitGUI() {
}

void quickSelectGame(void) {
	while (loadGame(selected)) {
		setSelectedMenu(9);
		if (!browseForFileType(FILEEXTENSIONS)) {
			backOutOfMenu();
			return;
		}
	}
	closeMenu();
}

void uiNullNormal() {
	uiNullDefault();
}

void uiFile() {
	setupMenu();
	drawMenuItem("Load Game");
	drawMenuItem("Load State");
	drawMenuItem("Save State");
	drawMenuItem("Save Settings");
	drawMenuItem("Reset Game");
	if (enableExit) {
		drawMenuItem("Quit Emulator");
	}
}

void uiOptions() {
	setupMenu();
	drawMenuItem("Controller");
	drawMenuItem("Display");
	drawMenuItem("Settings");
	drawMenuItem("DipSwitches");
}

void uiAbout() {
	cls(1);
	drawTabs();
	drawSubText("Select: Insert coin",4,0);
	drawSubText("Start:  Start",5,0);
	drawSubText("DPad:   Move character",6,0);
	drawSubText("B:      Shot",7,0);

	drawSubText("SonSonDS     " EMUVERSION, 21, 0);
	drawSubText("ARM6809      " ARM6809VERSION, 22, 0);
	drawSubText("ARMAY38910   " ARMAY38910VERSION, 23, 0);
}

void uiController() {
	setupSubMenu("Controller Settings");
	drawSubItem("B Autofire: ", autoTxt[autoB]);
	drawSubItem("A Autofire: ", autoTxt[autoA]);
	drawSubItem("Controller: ", ctrlTxt[(joyCfg>>29)&1]);
	drawSubItem("Swap A-B:   ", autoTxt[(joyCfg>>10)&1]);
}

void uiDisplay() {
	setupSubMenu("Display Settings");
	drawSubItem("Display: ", dispTxt[g_scaling]);
	drawSubItem("Scaling: ", flickTxt[g_flicker]);
	drawSubItem("Gamma: ", brighTxt[g_gammaValue]);
	drawSubItem("Disable Background: ", autoTxt[g_gfxMask&1]);
	drawSubItem("Disable Sprites: ", autoTxt[(g_gfxMask>>4)&1]);
}

void uiSettings() {
	setupSubMenu("Settings");
	drawSubItem("Speed: ", speedTxt[(emuSettings>>6)&3]);
	drawSubItem("Autoload State: ", autoTxt[(emuSettings>>2)&1]);
	drawSubItem("Autosave Settings: ", autoTxt[(emuSettings>>9)&1]);
	drawSubItem("Autosave NVRAM: ", autoTxt[(emuSettings>>10)&1]);
	drawSubItem("Autopause Game: ", autoTxt[emuSettings&1]);
	drawSubItem("Powersave 2nd Screen: ",autoTxt[(emuSettings>>1)&1]);
	drawSubItem("Emulator on Bottom: ", autoTxt[(emuSettings>>8)&1]);
	drawSubItem("Debug Output: ", autoTxt[gDebugSet&1]);
	drawSubItem("Autosleep: ", sleepTxt[(emuSettings>>4)&3]);
}

void uiDipswitches() {
	setupSubMenu("Dipswitch Settings");
	drawSubItem("Coinage: ", coinTxt[g_dipSwitch1 & 0xf]);
	drawSubItem("Coinage Affects: ", coinAffectTxt[(g_dipSwitch1>>4) & 0x1]);
	drawSubItem("Demo Sound: ", autoTxt[(g_dipSwitch1>>5) & 1]);
	drawSubItem("Lives: ", livesTxt[g_dipSwitch2 & 3]);
	drawSubItem("Difficulty: ", diffTxt[(g_dipSwitch2>>5) & 3]);
	drawSubItem("Bonus: ", bonusTxt[(g_dipSwitch2>>3) & 3]);
	drawSubItem("2 Players: ", credit2Txt[(g_dipSwitch2>>2) & 1]);
	drawSubItem("Flip Screen: ", autoTxt[(g_dipSwitch1>>7) & 1]);
	drawSubItem("Service: ", autoTxt[(g_dipSwitch1>>6) & 1]);
	drawSubItem("Freeze: ", autoTxt[(g_dipSwitch2>>7) & 1]);
}

void uiLoadGame() {
	setupSubMenu("Load game");
	drawMenuItem("Son Son");
	drawMenuItem("Son Son (Japan)");
}

void nullUINormal(int key) {
	if (key & KEY_TOUCH) {
		openMenu();
	}
}

void nullUIDebug(int key) {
	if (key & KEY_TOUCH) {
		openMenu();
	}
}

void resetGame() {
	loadCart(romNum,0);
}


//---------------------------------------------------------------------------------
/// Switch between Player 1 & Player 2 controls
void controllerSet() {				// See io.s: refreshEMUjoypads
	joyCfg ^= 0x20000000;
}

/// Swap A & B buttons
void swapABSet() {
	joyCfg ^= 0x400;
}

/// Turn on/off scaling
void scalingSet(){
	g_scaling ^= 0x01;
	refreshGfx();
}

/// Change gamma (brightness)
void gammaSet() {
	g_gammaValue++;
	if (g_gammaValue > 4) g_gammaValue=0;
	paletteInit(g_gammaValue);
	paletteTxAll();					// Make new palette visible
	setupMenuPalette();
}

/// Turn on/off rendering of background
void bgrLayerSet() {
	g_gfxMask ^= 0x03;
}
/// Turn on/off rendering of sprites
void sprLayerSet() {
	g_gfxMask ^= 0x10;
}


/// Number of coins for credits
void coinageSet() {
	int i = (g_dipSwitch1+1) & 0xf;
	g_dipSwitch1 = (g_dipSwitch1 & ~0xf) | i;
}
/// Which coin slot is affected
void coinAffectSet() {
	g_dipSwitch1 ^= 0x10;
}
/// Demo sound on/off
void demoSet() {
	g_dipSwitch1 ^= 0x20;
}
/// Number of lifes to start with
void livesSet() {
	int i = (g_dipSwitch2+0x01) & 0x03;
	g_dipSwitch2 = (g_dipSwitch2 & ~0x03) | i;
}
/// Game difficulty
void difficultSet() {
	int i = (g_dipSwitch2+0x20) & 0x60;
	g_dipSwitch2 = (g_dipSwitch2 & ~0x60) | i;
}
/// At which score you get bonus lifes
void bonusSet() {
	int i = (g_dipSwitch2+0x08) & 0x18;
	g_dipSwitch2 = (g_dipSwitch2 & ~0x18) | i;
}
/// Does second player need own credit?
void secondPlayerSet() {
	g_dipSwitch2 ^= 0x04;
}
/// Test/Service mode
void serviceSet() {
	g_dipSwitch1 ^= 0x40;
}
/// Flip screen
void flipSet() {
	g_dipSwitch1 ^= 0x80;
}
/// Pause game
void freezeSet() {
	g_dipSwitch2 ^= 0x80;
}
