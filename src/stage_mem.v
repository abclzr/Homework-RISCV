`include "defines.v"
module stage_mem(
    input wire                  rst,

    input wire[`OpcodeBus]      opcode_i,
    input wire[`Func3Bus]       func3_i,
    input wire[`RegBus]         mem_addr_i,
    input wire[`RegAddrBus]     wd_i,
    input wire                  wreg_i,
    input wire[`RegBus]         wdata_i,
    
    output reg[`RegAddrBus]     wd_o,
    output reg                  wreg_o,
    output reg[`RegBus]         wdata_o,

    input wire[`MemDataBus]     mem_data_i,
    input wire[]
);

endmodule