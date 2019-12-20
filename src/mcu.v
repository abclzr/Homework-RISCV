`include "defines.v"
module mcu(
    input wire                  rst,
    input wire                  if_require,
    input wire                  mem_require,

    input wire[`InstAddrBus]    if_addr,
    input wire[`InstAddrBus]    mem_addr,
    input wire[`MemDataBus]     mem_data,
    input wire                  mem_write_enable,

    output reg                  write_enable_o,
    output reg[`MemAddrBus]     addr_o,
    output reg[`MemDataBus]     data_o,

    output reg                  if_req_stall,
    output reg                  mem_req_stall
);

    always @ ( * ) begin
        if (rst) begin
            write_enable_o          <= `WriteDisable;
            addr_o                  <= 17'b0;
            data_o                  <= `ZeroByte;
            if_req_stall            <= `False_v;
            mem_req_stall           <= `False_v;
        end else if (mem_require) begin
            write_enable_o          <= mem_write_enable;
            addr_o                  <= mem_addr[16:0];
            data_o                  <= mem_data;
            if_req_stall            <= `False_v;
            mem_req_stall           <= `True_v;
        end else if (if_require) begin
            write_enable_o          <= `WriteDisable;
            addr_o                  <= if_addr[16:0];
            data_o                  <= `ZeroByte;
            if_req_stall            <= `True_v;
            mem_req_stall           <= `False_v;
        end else begin
            write_enable_o          <= `WriteDisable;
            addr_o                  <= 17'b0;
            data_o                  <= `ZeroByte;
            if_req_stall            <= `False_v;
            mem_req_stall           <= `False_v;
        end
    end

endmodule