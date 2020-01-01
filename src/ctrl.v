`include "defines.v"
module ctrl (
    input wire                  rst,
    input wire                  rdy,

    input wire                  if_stall_req_i,
    input wire                  id_stall_req1_i,
    input wire                  id_stall_req2_i,
    input wire                  mem_stall_req_i,

    output reg[`StallBus]       stall
);

    always @ ( * ) begin
        if (rst) begin
            stall                       <= 7'b0000000;
        end else if (!rdy) begin
            stall                       <= 7'b1111100;
        end else if (mem_stall_req_i) begin
            stall                       <= 7'b0111101;
        end else if (id_stall_req1_i || id_stall_req2_i) begin
            stall                       <= 7'b0001100;
        end else if (if_stall_req_i) begin
            stall                       <= 7'b0000100;            
        end else begin
            stall                       <= 7'b0000000;            
        end
    end

endmodule