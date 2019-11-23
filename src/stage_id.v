`include "defines.v"
module stage_id(
    // from if_id
    input wire                  rst,
    input wire                  rdy,

    input wire[`InstAddrBus]    pc_i,
    input wire[`InstBus]        inst_i,

    // from reg file
    input wire[`RegBus]         data1_i,
    input wire[`RegBus]         data2_i,

    // from exe
    input wire                  exe_wreg_i,
    input wire[`RegAddrBus]     exe_wd_i,
    input wire[`RegBus]         exe_wdata_i,
    input wire[`OpcodeBus]      exe_op_i,

    // from mem
    input wire                  mem_wreg_i,
    input wire[`RegAddrBus]     mem_wd_i,
    input wire[`RegBus]         mem_wdata_i,

    input wire[`StallBus]       stall,

    // to reg file
    output reg                  reg1_read_o,
    output reg                  reg2_read_o,
    output reg[`RegAddrBus]     reg1_addr_o,
    output reg[`RegAddrBus]     reg2_addr_o,

    // to id_ex
    output reg[`OpcodeBus]      opcode_o,
    output reg[`Func3Bus]       func3_o,
    output reg[`Func7Bus]       func7_o,
    output reg[`RegBus]         data1_o,
    output reg[`RegBus]         data2_o,
    output reg[`RegBus]         ls_offset_o,
    output reg[`RegBus]         wd_o,
    output reg                  wreg_o,

    // todo : branch prediction
    output reg                  branch_enable_o,
    output reg                  branch_addr_o,
);

    wire[`OpcodeBus]            opcode = inst_i[6:0];
    wire[`Func3Bus]             func3 = inst_i[14:12];
    wire[`Func7Bus]             func7 = inst_i[31:25];

    reg[`RegBus]                imm;

    always @ ( * ) begin
        if (rst) begin
            opcode_o            <= `NON_OP;
            func3_o             <= `NON_FUNC3;
            func7_o             <= `NON_FUNC7;
        end else begin
        end
    end

endmodule : stage_id