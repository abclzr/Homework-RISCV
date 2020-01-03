`include "defines.v"
module d_cache(
    input wire                  rst,
    input wire                  clk,

    input wire[`InstAddrBus]    read_addr,
    input wire                  write_bit,
    input wire[`Func3Bus]       write_type,
    input wire[`InstAddrBus]    write_addr,
    input wire[`CacheOneDataBus]write_data,
    output reg                  cache_hit,
    output reg[`CacheDataBus]   cache_data
);

integer i;

(* ram_style = "registers" *) reg[`CacheOneDataBus] CacheData0[`BlockNum - 1:0];
(* ram_style = "registers" *) reg[`CacheOneDataBus] CacheData1[`BlockNum - 1:0];
(* ram_style = "registers" *) reg[`CacheOneDataBus] CacheData2[`BlockNum - 1:0];
(* ram_style = "registers" *) reg[`CacheOneDataBus] CacheData3[`BlockNum - 1:0];
(* ram_style = "registers" *) reg[`CacheTagBus] CacheTag[`BlockNum - 1:0];
(* ram_style = "registers" *) reg CacheValid[`BlockNum - 1:0];

wire[`CacheOffsetBus] write_offset;
wire[`CacheIndexBus] write_index;
wire[`CacheTagBus] write_tag;
wire write_hit;
wire[`CacheDataBus] write_cache_data;

assign write_offset = write_addr[`getCacheOffset];
assign write_index = write_addr[`getCacheIndex];
assign write_tag = write_addr[`getCacheTag];
assign write_hit = (write_type == 3'b010
                    || (CacheValid[write_index] && CacheTag[write_index] == write_tag)
                    && (write_addr[`getCacheUpper] == `ZeroUpper));

    always @ (posedge clk) begin
        if (rst) begin
            for (i = 0; i < `BlockNum; i = i + 1) begin
                CacheValid[i]              <= 1'b0;
            end
        end else if (write_bit && write_hit) begin
            CacheValid[write_index] <= `True_v;
            CacheTag[write_index] <= write_tag;
            case (write_offset)
                2'b00: begin
                    CacheData0[write_index] <= write_data;
                end
                2'b01: begin
                    CacheData1[write_index] <= write_data;
                end
                2'b10: begin
                    CacheData2[write_index] <= write_data;
                end
                2'b11: begin
                    CacheData3[write_index] <= write_data;
                end
            endcase
        end
    end

wire[`CacheOffsetBus] read_offset;
wire[`CacheIndexBus] read_index;
wire[`CacheTagBus] read_tag;
wire read_hit;

assign read_offset = read_addr[`getCacheOffset];
assign read_index = read_addr[`getCacheIndex];
assign read_tag = read_addr[`getCacheTag];
assign read_hit = (CacheValid[read_index]
                && CacheTag[read_index] == read_tag
                && read_offset == 2'b00
                && read_addr[`getCacheUpper] == `ZeroUpper);

    always @ ( * ) begin
        if (rst) begin
            cache_hit <= `False_v;
            cache_data <= `ZeroWord;
        end else if (!write_bit) begin
            cache_hit <= read_hit;
            cache_data <= {CacheData3[read_index], CacheData2[read_index], CacheData1[read_index], CacheData0[read_index]};
        end
    end

endmodule