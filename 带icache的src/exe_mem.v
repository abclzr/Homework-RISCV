`include "defines.v"
module exe_mem(
    input wire                  clk,
    input wire                  rst,

    //debug
    input wire[`InstAddrBus]    pc_i,
    input wire[`InstBus]        inst_i,
    output reg[`InstAddrBus]    pc_o,
    output reg[`InstBus]        inst_o,

    input wire[`StallBus]       stall,

    input wire[`OpcodeBus]      opcode_o,
    input wire[`Func3Bus]       func3_o,
    input wire[`RegBus]         mem_addr_o,
    input wire[`RegAddrBus]     wd_o,
    input wire                  wreg_o,
    input wire[`RegBus]         wdata_o,

    output reg[`OpcodeBus]      opcode_i,
    output reg[`Func3Bus]       func3_i,
    output reg[`RegBus]         mem_addr_i,
    output reg[`RegAddrBus]     wd_i,
    output reg                  wreg_i,
    output reg[`RegBus]         wdata_i
);

    always @ (posedge clk) begin
        if (rst) begin
            opcode_i                    <= `NON_OP;
            func3_i                     <= `NON_FUNC3;
            mem_addr_i                  <= `ZeroWord;
            wd_i                        <= `ZeroRegAddr;
            wreg_i                      <= `False_v;
            wdata_i                     <= `ZeroWord;
            pc_o                <= `ZeroWord;
            inst_o              <= `ZeroWord;
        end else if (stall[4] && !stall[5]) begin            
            opcode_i                    <= `NON_OP;
            func3_i                     <= `NON_FUNC3;
            mem_addr_i                  <= `ZeroWord;
            wd_i                        <= `ZeroRegAddr;
            wreg_i                      <= `False_v;
            wdata_i                     <= `ZeroWord;
            pc_o                <= `ZeroWord;
            inst_o              <= `ZeroWord;
        end else if (!stall[4]) begin
            opcode_i                    <= opcode_o;
            func3_i                     <= func3_o;
            mem_addr_i                  <= mem_addr_o;
            wd_i                        <= wd_o;
            wreg_i                      <= wreg_o;
            wdata_i                     <= wdata_o;
            pc_o                <= pc_i;
            inst_o              <= inst_i;
        end
    end

endmodule