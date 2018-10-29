// opcodes.h

// Opcode Class Masks

#define 0xE0	OPCLASS_MASK	// 1110 0000
#define 0x00	OPCLASS_SPECIAL	// 0000 0000
#define 0x20	OPCLASS_OR		// 0010 0000
#define 0x40	OPCLASS_AND		// 0100 0000
#define 0x60	OPCLASS_CMP		// 0110 0000
#define 0x80	OPCLASS_SUB		// 1000 0000
#define 0xA0	OPCLASS_ADD		// 1010 0000
#define	0xC0	OPCLASS_MOVREG	// 1100 0000
#define 0xE0	OPCLASS_MOVMEM	// 1110 0000

// Opcode Destination Masks

#define 0x18	OPDEST_MASK		// 0001 1000
#define 0x00	OPDEST_AX		// 0000 0000
#define 0x08	OPDEST_BX		// 0000 1000
#define 0x10	OPDEST_CX		// 0001 0000
#define 0x18	OPDEST_DX		// 0001 1000

// Opcode Source Masks

#define 0x07	OPSRC_MASK		// 0000 0111
#define 0x00	OPSRC_AX		// 0000 0000
#define 0x01	OPSRC_BX		// 0000 0001
#define 0x02	OPSRC_CX		// 0000 0010
#define 0x03	OPSRC_DX		// 0000 0011
#define 0x04	OPSRC_INDIRECT	// 0000 0100
#define 0x05	OPSRC_INDEXED	// 0000 0101
#define 0x06	OPSRC_DIRECT	// 0000 0110
#define 0x07	OPSRC_CONST		// 0000 0111


int bitcmp( char c1, char c2, char mask);