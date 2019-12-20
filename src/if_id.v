`include "defines.v"
module if_id(
    input wire                  rst,
    input wire                  clk,

    input wire[`StallBus]       stall,
    
    input wire[`InstAddrBus]    pc_o,
    input wire[`InstBus]        inst_o,

    output reg[`InstAddrBus]    pc_i,
    output reg[`InstBus]        inst_i
);

    always @ (posedge clk) begin
        if (rst) begin
            pc_i                        <= `ZeroWord;
            inst_i                      <= `ZeroWord;
        end else if (!stall[2]) begin
            pc_i                        <= pc_o;
            inst_i                      <= inst_o;
        end else if (stall[2] && !stall[3]) begin
            pc_i                        <= `ZeroWord;
            inst_i                      <= `ZeroWord;
        end
    end

endmodule