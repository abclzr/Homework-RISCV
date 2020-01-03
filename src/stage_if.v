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
    output reg[`InstBus]        inst_o,


    // i_cache
    output reg[`CacheIndexBus]  index,
    output reg[`CacheTagBus]    tag,
    output reg                  write_bit,
    output reg[`CacheIndexBus]  write_index,
    output reg[`CacheTagBus]    write_tag,
    output reg[`CacheDataBus]   write_data,

    input wire                  cache_hit,
    input wire[`CacheDataBus]   cache_data
);

reg[4:0] state;
reg[`InstAddrBus] pc_reg;
reg[`DataBus] data1;
reg[`DataBus] data2;
reg[`DataBus] data3;
reg[`InstAddrBus] count_hit;
reg[`InstAddrBus] count_total;

    always @ ( * ) begin
        if (rst) begin
            index <= `ZeroCacheIndex;
            tag <= `ZeroCacheTag;
        end else if (branch_enable_i) begin
            index <= branch_addr_i[`getCacheIndex];
            tag <= branch_addr_i[`getCacheTag];
        end else begin
            index <= pc_reg[`getCacheIndex];
            tag <= pc_reg[`getCacheTag];
        end
    end


always @ (posedge clk) begin
    if (rst) begin
        mem_req_o                   <= `False_v;
        mem_addr_o                  <= `ZeroWord;
        pc_o                        <= `ZeroWord;
        inst_o                      <= `ZeroWord;
        state                       <= 5'b00000;
        pc_reg                      <= `ZeroWord;
        write_bit                   <= `False_v;
        count_hit                   <= `ZeroWord;
        count_total                 <= `ZeroWord;
     end else if (branch_enable_i) begin
        write_bit                   <= `False_v;
        if (cache_hit) begin
            mem_req_o                   <= `False_v;
            inst_o                      <= cache_data;
            pc_o                        <= branch_addr_i;
            pc_reg                      <= branch_addr_i + 4;
            state                       <= 5'b00000;
            count_hit                   <= count_hit + 1;
            count_total                 <= count_total + 1;
        end else begin
            mem_req_o                   <= `True_v;
            mem_addr_o                  <= branch_addr_i;
            pc_reg                      <= branch_addr_i;
            state                       <= 5'b00001;
            count_total                 <= count_total + 1;
        end
    end else begin
        case (state)
            5'b00000: begin
                write_bit                   <= `False_v;
                if (stall[2]) begin
                    state                       <= 5'b00000;
                end else begin
                    if (cache_hit) begin
                        mem_req_o                   <= `False_v;
                        inst_o                      <= cache_data;
                        pc_o                        <= pc_reg;
                        pc_reg                      <= pc_reg + 4;
                        state                       <= 5'b00000;
                        count_hit                   <= count_hit + 1;
                        count_total                 <= count_total + 1;
                    end else begin
                        mem_req_o                   <= `True_v;
                        mem_addr_o                  <= pc_reg;
                        state                       <= 5'b00001;
                        count_total                 <= count_total + 1;
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
                write_bit                   <= `True_v;
                write_index                 <= index;
                write_tag                   <= tag;
                write_data                  <= {mem_data_i, data3, data2, data1};
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
