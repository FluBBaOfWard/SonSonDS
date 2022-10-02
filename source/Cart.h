#ifndef CART_HEADER
#define CART_HEADER

#ifdef __cplusplus
extern "C" {
#endif

extern u32 romNum;
extern u32 emuFlags;
extern u8 cartFlags;

extern u8 soundCpuRam[0x800];
extern u8 NV_RAM[0x400];
extern u8 EMU_RAM[0x2060];
extern u8 ROM_Space[0x1E340];

void machineInit(void);
void loadCart(int, int);
void ejectCart(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // CART_HEADER
