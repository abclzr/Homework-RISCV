`include "defines.v"
module mem_wb(
    input wire                  clk,
    input wire                  rst,

    //debug
    input wire[`InstAddrBus]    pc_i,
    input wire[`InstBus]        inst_i,

    input wire[`StallBus]       stall,
    
    input wire[`RegAddrBus]     wd_o,
    input wire                  wreg_o,
    input wire[`RegBus]         wdata_o,
    
    output reg                  we,
    output reg[`RegAddrBus]     waddr,
    output reg[`RegBus]         wdata
);

reg[`InstAddrBus]    pc_o;
reg[`InstBus]        inst_o;
reg[`InstAddrBus]    counter;

    always @ (posedge clk) begin
        if (rst) begin
            we                          <= `False_v;
            waddr                       <= `ZeroRegAddr;
            wdata                       <= `ZeroWord;
            pc_o                <= `ZeroWord;
            inst_o              <= `ZeroWord;
            counter             <= `ZeroWord;
        end else if (stall[5] && !stall[6]) begin
            we                          <= `False_v;
            waddr                       <= `ZeroRegAddr;
            wdata                       <= `ZeroWord;
            pc_o                <= `ZeroWord;
            inst_o              <= `ZeroWord;
        end else if (!stall[5]) begin
            we                          <= wreg_o;
            waddr                       <= wd_o;
            wdata                       <= wdata_o;
            pc_o                <= pc_i;
            inst_o              <= inst_i;
            if (inst_i[6:0] != `S_OP && inst_i[6:0] != `B_OP && inst_i != `ZeroWord)
                counter <= counter + 1;
        end
    end

endmodule