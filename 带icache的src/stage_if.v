`include "defines.v"
module stage_if(
    input wire                  rst,
    input wire                  clk,
    
    // from ctrl
    input wire[`StallBus]       stall,

    // from ram
    input wire[`MemDataBus]     mem_data_i,

    // from stage_id
    input wire                  branch_enable_i,
    input wire[`InstAddrBus]    branch_addr_i,

    // to mcu
    output reg                  mem_req_o,
    output reg[`InstAddrBus]    mem_addr_o,

    //to if_id
    output reg[`InstAddrBus]    pc_o,
    output reg[`InstBus]        inst_o
);

reg[4:0] state;
reg[`InstAddrBus] pc_reg;
reg[`DataBus] data1;
reg[`DataBus] data2;
reg[`DataBus] data3;
integer i;

(* ram_style = "registers" *) reg[`CacheDataBus] cache_data[`BlockNum - 1:0];
(* ram_style = "registers" *) reg[`CacheTagBus] cache_tag[`BlockNum - 1:0];
(* ram_style = "registers" *) reg cache_valid[`BlockNum - 1:0];

wire[`CacheIndexBus] index;
wire[`CacheTagBus] tag;
wire[`CacheIndexBus] branch_pc_index;
wire[`CacheTagBus] branch_pc_tag;

wire cache_hit;
wire branch_cache_hit;

assign index = pc_reg[`getCacheIndex];
assign tag = pc_reg[`getCacheTag];
assign branch_pc_index = branch_addr_i[`getCacheIndex];
assign branch_pc_tag = branch_addr_i[`getCacheTag];
assign cache_hit = cache_valid[index] && (cache_tag[index] == tag);
assign branch_cache_hit = cache_valid[branch_pc_index] && (cache_tag[branch_pc_index] == branch_pc_tag);

always @ (posedge clk) begin
    if (rst) begin
        mem_req_o                   <= `False_v;
        mem_addr_o                  <= `ZeroWord;
        pc_o                        <= `ZeroWord;
        inst_o                      <= `ZeroWord;
        state                       <= 5'b00000;
        pc_reg                      <= `ZeroWord;
        for (i = 0; i < `BlockNum; i = i + 1) begin
            cache_valid[i]              <= 1'b0;
        end
    end else if (branch_enable_i && !stall[3]) begin
        if (branch_cache_hit) begin
            mem_req_o                   <= `False_v;
            inst_o                      <= cache_data[branch_pc_index];
            pc_o                        <= branch_addr_i;
            pc_reg                      <= branch_addr_i + 4;
            state                       <= 5'b00000;
        end else begin
            mem_req_o                   <= `True_v;
            mem_addr_o                  <= branch_addr_i;
            pc_reg                      <= branch_addr_i;
            state                       <= 5'b00001;
        end
    end else begin
        case (state)
            5'b00000: begin
                if (stall[2]) begin
                    state                       <= 5'b00000;
                end else begin
                    if (cache_hit) begin
                        mem_req_o                   <= `False_v;
                        inst_o                      <= cache_data[index];
                        pc_o                        <= pc_reg;
                        pc_reg                      <= pc_reg + 4;
                        state                       <= 5'b00000;
                    end else begin
                        mem_req_o                   <= `True_v;
                        mem_addr_o                  <= pc_reg;
                        state                       <= 5'b00001;
                    end
                end
            end
            5'b00001: begin
                if (stall[0]) begin
                    mem_addr_o                  <= pc_reg;
                    state                       <= 5'b00001;
                end else begin
                    mem_addr_o                  <= pc_reg + 1;
                    state                       <= 5'b00010;
                end
            end
            5'b00010: begin
                if (stall[0]) begin
                    data1                       <= mem_data_i;
                    mem_addr_o                  <= pc_reg + 1;
                    state                       <= 5'b01010;
                end else begin
                    data1                       <= mem_data_i;
                    mem_addr_o                  <= pc_reg + 2;
                    state                       <= 5'b00011;
                end
            end
            5'b00011: begin
                if (stall[0]) begin
                    data2                       <= mem_data_i;
                    mem_addr_o                  <= pc_reg + 2;
                    state                       <= 5'b01011;
                end else begin
                    data2                       <= mem_data_i;
                    mem_addr_o                  <= pc_reg + 3;
                    state                       <= 5'b00100;
                end
            end
            5'b00100: begin
                if (stall[0]) begin
                    data3                       <= mem_data_i;
                    mem_addr_o                  <= pc_reg + 3;
                    state                       <= 5'b01100;
                end else begin
                    data3                       <= mem_data_i;
                    state                       <= 5'b00101;
                end
            end
            5'b00101: begin
                inst_o                      <= {mem_data_i, data3, data2, data1};
                pc_o                        <= pc_reg;
                pc_reg                      <= pc_reg + 4;
                mem_req_o                   <= `False_v;
                state                       <= 5'b00000;
                cache_valid[index]          <= 1'b1;
                cache_tag[index]            <= tag;
                cache_data[index]           <= {mem_data_i, data3, data2, data1};
            end

            5'b01010: begin
                if (stall[0]) begin
                    mem_addr_o                  <= pc_reg + 1;
                    state                       <= 5'b01010;
                end else begin
                    mem_addr_o                  <= pc_reg + 2;
                    state                       <= 5'b00011;
                end
            end
            5'b01011: begin
                if (stall[0]) begin
                    mem_addr_o                  <= pc_reg + 2;
                    state                       <= 5'b01011;
                end else begin
                    mem_addr_o                  <= pc_reg + 3;
                    state                       <= 5'b00100;
                end
            end
            5'b01100: begin
                if (stall[0]) begin
                    mem_addr_o                  <= pc_reg + 3;
                    state                       <= 5'b10100;
                end else begin
                    mem_addr_o                  <= pc_reg + 3;
                    state                       <= 5'b00101;
                end
            end
            5'b01101: begin
                if (stall[0]) begin
                    state                       <= 5'b10101;
                end else begin
                    mem_addr_o                  <= pc_reg + 3;
                    state                       <= 5'b00101;
                end
            end
        endcase
    end
end

endmodule