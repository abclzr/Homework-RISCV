`define RstEnable               1'b1
`define RstDisable              1'b0
`define WriteEnable             1'b1
`define WriteDisable            1'b0

// bus
`define InstAddrBus             31:0
`define InstBus                 31:0
`define RegAddrBus              4:0
`define RegBus                  31:0
`define DataAddrBus             16:0
`define DataBus                 7:0
`define OpcodeBus               6:0
`define Func3Bus                2:0
`define Func7Bus                6:0
`define StallBus                6:0

// opcode
`define NON_OP                  7'b0000000
`define LUI_OP                  7'b0110111
`define AUIPC_OP                7'b0010111
`define JAL_OP                  7'b1101111
`define JALR_OP                 7'b1100111
`define B_OP                    7'b1100011
`define L_OP                    7'b0000011
`define S_OP                    7'b0100011
`define I_OP                    7'b0010011
`define R_OP                    7'b0110011

// func3
`define NON_FUNC3               3'b000
`define JALR_FUNC3              3'b000
`define BEQ_FUNC3               3'b000
`define BNE_FUNC3               3'b001
`define BLT_FUNC3               3'b100
`define BGE_FUNC3               3'b101
`define BLTU_FUNC3              3'b110
`define BGEU_FUNC3              3'b111
`define LB_FUNC3                3'b000
`define LH_FUNC3                3'b001
`define LW_FUNC3                3'b010
`define LBU_FUNC3               3'b100
`define LHU_FUNC3               3'b101
`define SB_FUNC3                3'b000
`define SH_FUNC3                3'b001
`define SW_FUNC3                3'b010
`define ADDI_FUNC3              3'b000
`define SLTI_FUNC3              3'b010
`define SLTIU_FUNC3             3'b011
`define XORI_FUNC3              3'b100
`define ORI_FUNC3               3'b110
`define ANDI_FUNC3              3'b111
`define SLLI_FUNC3              3'b001
`define SRLI_FUNC3              3'b101
`define SRAI_FUNC3              3'b101
`define ADD_FUNC3               3'b000
`define SUB_FUNC3               3'b000
`define SLL_FUNC3               3'b001
`define SLT_FUNC3               3'b010
`define SLTU_FUNC3              3'b011
`define XOR_FUNC3               3'b100
`define SRL_FUNC3               3'b101
`define SRA_FUNC3               3'b101
`define OR_FUNC3                3'b110
`define AND_FUNC3               3'b111

// func7
`define NON_FUNC7               7'b0000000
`define SLLI_FUNC7              7'b0000000
`define SRLI_FUNC7              7'b0000000
`define SRAI_FUNC7              7'b0100000
`define ADD_FUNC7               7'b0000000
`define SUB_FUNC7               7'b0100000
`define SLL_FUNC7               7'b0000000
`define SLT_FUNC7               7'b0000000
`define SLTU_FUNC7              7'b0000000
`define XOR_FUNC7               7'b0000000
`define SRL_FUNC7               7'b0000000
`define SRA_FUNC7               7'b0100000
`define OR_FUNC7                7'b0000000
`define AND_FUNC7               7'b0000000