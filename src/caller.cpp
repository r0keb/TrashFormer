#include <windows.h>
#include <stdio.h>


#define reg_rax         1				// 00000001b
#define reg_rcx         2				// 00000010b
#define reg_rdx         4				// 00000100b

#define reg_r8          8				// 00001000b
#define reg_r9          16				// 00010000b
#define reg_r10         32				// 00100000b
#define reg_r11         64				// 01000000b

#define reg_any         127				// 10000000b

// instructions used
#define mov_cmd				1
#define cmp_cmd				2
#define or_cmd				4
#define xor_cmd				8
#define lea_cmd				16
#define any_cmd				0xFF

// src dst registers
#define reg_rxx_rxx     1
#define reg_rxx_rx      2
#define reg_rx_rxx      4
#define reg_rx_rx       8
#define reg_any_any		0xff

extern "C" unsigned int TrashFormer(void* pFreeBuf, unsigned long sFreeBuf, unsigned long mask);

int main() {

	BYTE pTrashBuffer[1000] = { 0 };

	printf("\npTrashBuffer: %p\n", pTrashBuffer);

	// call to the engine
	// unsigned int result = TrashFormer(pTrashBuffer, 300, (((reg_any) << 24) | ((any_cmd) << 16) | ((reg_any_any) << 8) | (0xFF)));
	// unsigned int result = TrashFormer(pTrashBuffer, 300, (/*usable registers*/ ((reg_r8) << 24) | /*instruction used*/((mov_cmd) << 16) | /*Instruction movement*/ ((reg_rx_rx) << 8) | /*Number of instructions*/ (0x10)));
	unsigned int result = TrashFormer(pTrashBuffer, 300, (/*usable registers*/ ((reg_rax) << 24) | /*instruction used*/(((any_cmd) << 16) | /*Instruction movement*/ (reg_rxx_rxx | reg_rx_rxx) << 8) | /*Number of instructions*/ (0xff)));

	printf("\nresult: %u\n", result);

	// return 0;

	printf("\n\n");

	// print buffer on hex byte format
	for (unsigned int i = 0; i < 300; i++) {
		if (i % 8 == 0) {
			printf("\n\t");
		}
		if (i + 2 > 300) {
			printf("0x%0.2X\n\n", (BYTE*)pTrashBuffer[i]);
		}
		else {
			printf("0x%0.2X, ", (BYTE*)pTrashBuffer[i]);

		}
	}

	// make the buffer executable
	DWORD OldProtection = 0;
	VirtualProtect(pTrashBuffer, 1000, PAGE_EXECUTE_READWRITE, &OldProtection);

	// execute the content on the buffer
	(*(void(*)())(void*)pTrashBuffer) ();

	return 0;
}