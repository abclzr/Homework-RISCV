`include "defines.v"
module id_exe(
    input wire                  rst,
    input wire                  clk,

    input wire[`StallBus]       stall,

    input wire[`OpcodeBus]      opcode_o,
    input wire[`Func3Bus]       func3_o,
    input wire[`Func7Bus]       func7_o,
    input wire[`RegBus]         data1_o,
    input wire[`RegBus]         data2_o,
    input wire[`RegBus]         ls_offset_o,
    input wire[`RegBus]         wd_o,
    input wire                  wreg_o,

    output reg[`OpcodeBus]      opcode_i,
    output reg[`Func3Bus]       func3_i,
    output reg[`Func7Bus]       func7_i,
    output reg[`RegBus]         data1_i,
    output reg[`RegBus]         data2_i,
    output reg[`RegBus]         ls_offset_i,
    output reg[`RegAddrBus]     wd_i,
    output reg                  wreg_i
);

    always @ (posedge clk) begin
        if (rst) begin
            opcode_i            <= `NON_OP;
            func3_i             <= `NON_FUNC3;
            func7_i             <= `NON_FUNC7;
            data1_i             <= `ZeroWord;
            data2_i             <= `ZeroWord;
            ls_offset_i         <= `ZeroWord;
            wd_i                <= `ZeroRegAddr;
            wreg_i              <= `WriteDisable;
        end else if (stall[3] && !stall[4]) begin
            opcode_i            <= `NON_OP;
            func3_i             <= `NON_FUNC3;
            func7_i             <= `NON_FUNC7;
            data1_i             <= `ZeroWord;
            data2_i             <= `ZeroWord;
            ls_offset_i         <= `ZeroWord;
            wd_i                <= `ZeroRegAddr;
            wreg_i              <= `WriteDisable;
        end else if (!stall[3]) begin
            opcode_i            <= opcode_o;
            func3_i             <= func3_o;
            func7_i             <= func7_o;
            data1_i             <= data1_o;
            data2_i             <= data2_o;
            ls_offset_i         <= ls_offset_o;
            wd_i                <= wd_o;
            wreg_i              <= wreg_o;
        end
    end

endmodule