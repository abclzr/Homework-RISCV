`include "defines.v"
module i_cache(
    input wire                  rst,
    input wire                  clk,

    input wire[`CacheIndexBus]  index,
    input wire[`CacheTagBus]    tag,
    input wire                  write_bit,
    input wire[`CacheIndexBus]  write_index,
    input wire[`CacheTagBus]    write_tag,
    input wire[`CacheDataBus]   write_data,
    output reg                  cache_hit,
    output reg[`CacheDataBus]   cache_data
);

integer i;

(* ram_style = "registers" *) reg[`CacheDataBus] CacheData[`BlockNum - 1:0];
(* ram_style = "registers" *) reg[`CacheTagBus] CacheTag[`BlockNum - 1:0];
(* ram_style = "registers" *) reg CacheValid[`BlockNum - 1:0];

    always @ (posedge clk) begin
        if (rst) begin
            for (i = 0; i < `BlockNum; i = i + 1) begin
                CacheValid[i]              <= 1'b0;
            end
        end else if (write_bit) begin
            CacheValid[write_index] <= `True_v;
            CacheTag[write_index] <= write_tag;
            CacheData[write_index] <= write_data;
        end
    end

    always @ ( * ) begin
        if (rst) begin
            cache_hit <= `False_v;
            cache_data <= `ZeroWord;
        end else if (!write_bit) begin
            cache_hit <= CacheValid[index] && (CacheTag[index] == tag);
            cache_data <= CacheData[index];
        end else if (write_index == index && write_tag == tag) begin
            cache_hit <= `True_v;
            cache_data <= write_data;
        end else begin
            cache_hit <= CacheValid[index] && (CacheTag[index] == tag);
            cache_data <= CacheData[index];
        end
    end

endmodule