`include "defines.v"
module stage_if(
    input wire                  rst,
    input wire                  rdy,
    
    // from ctrl
    input wire[`StallBus]       stall,

    // from ram
    input wire[`MemDataBus]     mem_data_i,

    // from stage_id
    input wire                  branch_enable_i,
    input wire[`InstAddrBus]    branch_addr_i,

    // to mcu
    output reg                  mem_req_o,
    output reg                  mem_write_enable_o,
    output reg[`InstAddrBus]    mem_addr_o,

    //to if_id
    output reg[`InstAddrBus]    pc_o,
    output reg[`InstBus]        inst_o,
);

reg[4:0] state;
reg[`InstAddrBus] pc_reg;
reg[`DataBus] data1;
reg[`DataBus] data2;
reg[`DataBus] data3;

always @ (posedge clk) begin
    if (rst) begin
        mem_req_o                   <= `False_v;
        mem_write_enable_o          <= `False_v;
        mem_addr_o                  <= `ZeroWord;
        pc_o                        <= `ZeroWord;
        inst_o                      <= `ZeroWord;
        state                       <= 5'b00000;
        pc_reg                      <= `ZeroWord;
    end else if (branch_enable_i) begin
        mem_req_o                   <= `True_v;
        mem_addr_o                  <= branch_addr_i;
        pc_reg                      <= branch_addr_i;
        state                       <= 5'b00000;
    end else begin
        case (state)
            5'b00000: begin
                if (stall[0]) begin
                    state                       <= 5'b10000;
                end else begin
                    mem_addr_o                  <= pc_reg + 1;
                    state                       <= 5'b00001;
                end
            end
            5'b00001: begin
                if (stall[0]) begin
                    state                       <= 5'b10001;
                end else begin
                    data1                       <= mem_data_i;
                    mem_addr_o                  <= pc_reg + 2;
                    state                       <= 5'b00010;
                end
            end
            5'b00010: begin
                if (stall[0]) begin
                    state                       <= 5'b10010;
                end else begin
                    data2                       <= mem_data_i;
                    mem_addr_o                  <= pc_reg + 3;
                    state                       <= 5'b00011;
                end
            end
            5'b00011: begin
                if (stall[0]) begin
                    state                       <= 5'b10011;
                end else begin
                    data3                       <= mem_data_i;
                    state                       <= 5'b00100;
                end
            end
            5'b00100: begin
                if (stall[0]) begin
                    state                       <= 5'b10100;
                end else begin
                    inst_o                      <= {mem_data_i, data3, data2, data1};
                    pc_o                        <= pc_reg;
                    pc_reg                      <= pc_reg + 4;
                    mem_req_o                   <= `False_v;
                    state                       <= 5'b00000;
                end
            end
            
            5'b10000: begin
                if (stall[0]) begin
                end else begin

                end
            end
            5'b10001: begin
                if (stall[0]) begin
                end else begin
                end
            end
            5'b10010: begin
                if (stall[0]) begin
                end else begin
                end
            end
            5'b10011: begin
                if (stall[0]) begin
                end else begin
                end
            end
            5'b10100: begin
                if (stall[0]) begin
                end else begin
                end
            end

            5'b01000: begin
                if (stall[0]) begin
                end else begin
                end
            end
            5'b01001: begin
                if (stall[0]) begin
                end else begin
                end
            end
            5'b01010: begin
                if (stall[0]) begin
                end else begin
                end
            end
            5'b01011: begin
                if (stall[0]) begin
                end else begin
                end
            end
            5'b01100: begin
                if (stall[0]) begin
                end else begin
                end
            end
        endcase
    end
end

endmodule