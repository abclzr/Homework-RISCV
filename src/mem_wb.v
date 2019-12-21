`include "defines.v"
module mem_wb(
    input wire                  clk,
    input wire                  rst,

    input wire[`StallBus]       stall,
    
    input wire[`RegAddrBus]     wd_o,
    input wire                  wreg_o,
    input wire[`RegBus]         wdata_o,
    
    output reg                  we,
    output reg[`RegAddrBus]     waddr,
    output reg[`RegBus]         wdata
);

    always @ (posedge clk) begin
        if (rst) begin
            we                          <= `False_v;
            waddr                       <= `ZeroRegAddr;
            wdata                       <= `ZeroWord;
        end else if (stall[5] && !stall[6]) begin
            we                          <= `False_v;
            waddr                       <= `ZeroRegAddr;
            wdata                       <= `ZeroWord;
        end else if (!stall[5]) begin
            we                          <= wreg_o;
            waddr                       <= wd_o;
            wdata                       <= wdata_o;
        end
    end

endmodule