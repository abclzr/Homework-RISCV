// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "defines.v"
module cpu(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	  input  wire					        rdy_in,			// ready signal, pause cpu when low

    input  wire [ 7:0]          mem_din,		// data input bus
    output wire [ 7:0]          mem_dout,		// data output bus
    output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
    output wire                 mem_wr,			// write/read signal (1 for write)

	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read takes 2 cycles(wait till next cycle), write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

wire                if_branch_enable_i;
wire[`InstAddrBus]  if_branch_addr_i;

wire[`InstAddrBus]  if_pc_o;
wire[`InstBus]      if_inst_o;


wire[`InstAddrBus]  id_pc_i;
wire[`InstBus]      id_inst_i;
wire[`InstAddrBus]  id_pc_o;
wire[`InstBus]      id_inst_o;

wire[`RegBus]       id_data1_i;
wire[`RegBus]       id_data2_i;


wire[`OpcodeBus]    id_opcode_o;
wire[`Func3Bus]     id_func3_o;
wire[`Func7Bus]     id_func7_o;
wire[`RegBus]       id_data1_o;
wire[`RegBus]       id_data2_o;
wire[`RegBus]       id_ls_offset_o;
wire[`RegBus]       id_wd_o;
wire                id_wreg_o;


wire[`InstAddrBus]  exe_pc_i;
wire[`InstBus]      exe_inst_i;
wire[`InstAddrBus]  exe_pc_o;
wire[`InstBus]      exe_inst_o;

wire[`OpcodeBus]    exe_opcode_i;
wire[`Func3Bus]     exe_func3_i;
wire[`Func7Bus]     exe_func7_i;
wire[`RegBus]       exe_data1_i;
wire[`RegBus]       exe_data2_i;
wire[`RegBus]       exe_ls_offset_i;
wire[`RegAddrBus]   exe_wd_i;
wire                exe_wreg_i;


wire[`OpcodeBus]    exe_opcode_o;
wire[`Func3Bus]     exe_func3_o;
wire[`RegBus]       exe_mem_addr_o;
wire[`RegAddrBus]   exe_wd_o;
wire                exe_wreg_o;
wire[`RegBus]       exe_wdata_o;


wire[`InstAddrBus]  mem_pc_i;
wire[`InstBus]      mem_inst_i;
wire[`InstAddrBus]  mem_pc_o;
wire[`InstBus]      mem_inst_o;

wire[`OpcodeBus]    mem_opcode_i;
wire[`Func3Bus]     mem_func3_i;
wire[`RegBus]       mem_mem_addr_i;
wire[`RegAddrBus]   mem_wd_i;
wire                mem_wreg_i;
wire[`RegBus]       mem_wdata_i;


wire                mcu_if_require;
wire                mcu_mem_require;
wire[`InstAddrBus]  mcu_if_addr;
wire[`InstAddrBus]  mcu_mem_addr;
wire[`MemDataBus]   mcu_mem_data;
wire                mcu_mem_write_enable;


wire                ctrl_if_stall_req_i;
wire                ctrl_id_stall_req1_i;
wire                ctrl_id_stall_req2_i;
wire                ctrl_mem_stall_req_i;
wire[`StallBus]     ctrl_stall;
wire                ctrl_if_branch_o;

wire[`RegAddrBus]   mem_wd_o;
wire                mem_wreg_o;
wire[`RegBus]       mem_wdata_o;

wire                id_reg1_read_o;
wire                id_reg2_read_o;
wire[`RegAddrBus]   id_reg1_addr_o;
wire[`RegAddrBus]   id_reg2_addr_o;

wire                regfile_we;
wire[`RegAddrBus]   regfile_waddr;
wire[`RegBus]       regfile_wdata;

wire[`CacheIndexBus]cache_index;
wire[`CacheTagBus]  cache_tag;
wire                cache_write_bit;
wire[`CacheIndexBus]cache_write_index;
wire[`CacheTagBus]  cache_write_tag;
wire[`CacheDataBus] cache_write_data;

wire                cache_cache_hit;
wire[`CacheDataBus] cache_cache_data;

wire[`InstAddrBus]    d_cache_read_addr;
wire                  d_cache_write_bit;
wire[`Func3Bus]       d_cache_write_type;
wire[`InstAddrBus]    d_cache_write_addr;
wire[`CacheOneDataBus]d_cache_write_data;
wire                  d_cache_cache_hit;
wire[`CacheDataBus]   d_cache_cache_data;

stage_if stage_if_a(
  .rst(rst_in),
  .clk(clk_in),
  .stall(ctrl_stall),
  .mem_data_i(mem_din),
  .branch_enable_i(ctrl_if_branch_o),
  .branch_addr_i(if_branch_addr_i),
  .mem_req_o(mcu_if_require),
  .mem_addr_o(mcu_if_addr),
  .pc_o(if_pc_o),
  .inst_o(if_inst_o),

  
  .index(cache_index),
  .tag(cache_tag),
  .write_bit(cache_write_bit),
  .write_index(cache_write_index),
  .write_tag(cache_write_tag),
  .write_data(cache_write_data),

  .cache_hit(cache_cache_hit),
  .cache_data(cache_cache_data)
);

i_cache i_cache_a(
  .rst(rst_in),
  .clk(clk_in),

  .index(cache_index),
  .tag(cache_tag),
  .write_bit(cache_write_bit),
  .write_index(cache_write_index),
  .write_tag(cache_write_tag),
  .write_data(cache_write_data),

  .cache_hit(cache_cache_hit),
  .cache_data(cache_cache_data)
);

if_id if_id_a(
  .rst(rst_in),
  .clk(clk_in),
  .stall(ctrl_stall),
  .pc_o(if_pc_o),
  .inst_o(if_inst_o),
  .pc_i(id_pc_i),
  .inst_i(id_inst_i)
);

stage_id stage_id_a(
  .rst(rst_in),
  .rdy(rdy_in),
  .pc_i(id_pc_i),
  .inst_i(id_inst_i),

  .pc_o(id_pc_o),
  .inst_o(id_inst_o),

  .data1_i(id_data1_i),
  .data2_i(id_data2_i),

  .exe_wreg_i(exe_wreg_o),
  .exe_wd_i(exe_wd_o),
  .exe_wdata_i(exe_wdata_o),
  .exe_op_i(exe_opcode_o),

  .mem_wreg_i(mem_wreg_o),
  .mem_wd_i(mem_wd_o),
  .mem_wdata_i(mem_wdata_o),

  .reg1_read_o(id_reg1_read_o),
  .reg2_read_o(id_reg2_read_o),
  .reg1_addr_o(id_reg1_addr_o),
  .reg2_addr_o(id_reg2_addr_o),

  .opcode_o(id_opcode_o),
  .func3_o(id_func3_o),
  .func7_o(id_func7_o),
  .data1_o(id_data1_o),
  .data2_o(id_data2_o),
  .ls_offset_o(id_ls_offset_o),
  .wd_o(id_wd_o),
  .wreg_o(id_wreg_o),

  .branch_enable_o(if_branch_enable_i),
  .branch_addr_o(if_branch_addr_i),

  .id_stall_req1_o(ctrl_id_stall_req1_i),
  .id_stall_req2_o(ctrl_id_stall_req2_i)
);


id_exe id_exe_a(
  .rst(rst_in),
  .clk(clk_in),

  .pc_i(id_pc_o),
  .inst_i(id_inst_o),
  .pc_o(exe_pc_i),
  .inst_o(exe_inst_i),

  .stall(ctrl_stall),

  .opcode_o(id_opcode_o),
  .func3_o(id_func3_o),
  .func7_o(id_func7_o),
  .data1_o(id_data1_o),
  .data2_o(id_data2_o),
  .ls_offset_o(id_ls_offset_o),
  .wd_o(id_wd_o),
  .wreg_o(id_wreg_o),

  .opcode_i(exe_opcode_i),
  .func3_i(exe_func3_i),
  .func7_i(exe_func7_i),
  .data1_i(exe_data1_i),
  .data2_i(exe_data2_i),
  .ls_offset_i(exe_ls_offset_i),
  .wd_i(exe_wd_i),
  .wreg_i(exe_wreg_i)
);


stage_exe stage_exe_a(
  .rst(rst_in),
  .rdy(rdy_in),

  .pc_i(exe_pc_i),
  .inst_i(exe_inst_i),
  .pc_o(exe_pc_o),
  .inst_o(exe_inst_o),

  .opcode_i(exe_opcode_i),
  .func3_i(exe_func3_i),
  .func7_i(exe_func7_i),
  .data1_i(exe_data1_i),
  .data2_i(exe_data2_i),
  .ls_offset_i(exe_ls_offset_i),
  .wd_i(exe_wd_i),
  .wreg_i(exe_wreg_i),

  .opcode_o(exe_opcode_o),
  .func3_o(exe_func3_o),
  .mem_addr_o(exe_mem_addr_o),
  .wd_o(exe_wd_o),
  .wreg_o(exe_wreg_o),
  .wdata_o(exe_wdata_o)
);


exe_mem exe_mem_a(
  .clk(clk_in),
  .rst(rst_in),

  .pc_i(exe_pc_o),
  .inst_i(exe_inst_o),
  .pc_o(mem_pc_i),
  .inst_o(mem_inst_i),

  .stall(ctrl_stall),

  .opcode_o(exe_opcode_o),
  .func3_o(exe_func3_o),
  .mem_addr_o(exe_mem_addr_o),
  .wd_o(exe_wd_o),
  .wreg_o(exe_wreg_o),
  .wdata_o(exe_wdata_o),

  .opcode_i(mem_opcode_i),
  .func3_i(mem_func3_i),
  .mem_addr_i(mem_mem_addr_i),
  .wd_i(mem_wd_i),
  .wreg_i(mem_wreg_i),
  .wdata_i(mem_wdata_i)
);


stage_mem stage_mem_a(
  .rst(rst_in),
  .clk(clk_in),

  .pc_i(mem_pc_i),
  .inst_i(mem_inst_i),
  .pc_o(mem_pc_o),
  .inst_o(mem_inst_o),

  .opcode_i(mem_opcode_i),
  .func3_i(mem_func3_i),
  .mem_addr_i(mem_mem_addr_i),
  .wd_i(mem_wd_i),
  .wreg_i(mem_wreg_i),
  .wdata_i(mem_wdata_i),
    
  .wd_o(mem_wd_o),
  .wreg_o(mem_wreg_o),
  .wdata_o(mem_wdata_o),

  .mem_data_i(mem_din),

  .mem_req_o(mcu_mem_require),
  .mem_write_enable_o(mcu_mem_write_enable),
  .mem_addr_o(mcu_mem_addr),
  .mem_data_o(mcu_mem_data),

  .read_addr(d_cache_read_addr),
  .write_bit(d_cache_write_bit),
  .write_type(d_cache_write_type),
  .write_addr(d_cache_write_addr),
  .write_data(d_cache_write_data),
  .cache_hit(d_cache_cache_hit),
  .cache_data(d_cache_cache_data)
);


d_cache d_cache_a(
    .rst(rst_in),
    .clk(clk_in),

    .read_addr(d_cache_read_addr),
    .write_bit(d_cache_write_bit),
    .write_type(d_cache_write_type),
    .write_addr(d_cache_write_addr),
    .write_data(d_cache_write_data),
    .cache_hit(d_cache_cache_hit),
    .cache_data(d_cache_cache_data)
);

mcu mcu_a(
  .rst(rst_in),
  .if_require(mcu_if_require),
  .mem_require(mcu_mem_require),

  .if_addr(mcu_if_addr),
  .mem_addr(mcu_mem_addr),
  .mem_data(mcu_mem_data),
  .mem_write_enable(mcu_mem_write_enable),

  .write_enable_o(mem_wr),
  .addr_o(mem_a),
  .data_o(mem_dout),

  .if_req_stall(ctrl_if_stall_req_i),
  .mem_req_stall(ctrl_mem_stall_req_i)
);

ctrl ctrl_a(
  .rst(rst_in),
  .rdy(rdy_in),

  .if_stall_req_i(ctrl_if_stall_req_i),
  .id_branch_enable_i(if_branch_enable_i),
  .id_stall_req1_i(ctrl_id_stall_req1_i),
  .id_stall_req2_i(ctrl_id_stall_req2_i),
  .mem_stall_req_i(ctrl_mem_stall_req_i),

  .stall(ctrl_stall),
  .if_branch_enable_o(ctrl_if_branch_o)
);

mem_wb mem_wb_a(
  .clk(clk_in),
  .rst(rst_in),

  .pc_i(mem_pc_o),
  .inst_i(mem_inst_o),

  .stall(ctrl_stall),
    
  .wd_o(mem_wd_o),
  .wreg_o(mem_wreg_o),
  .wdata_o(mem_wdata_o),
    
  .we(regfile_we),
  .waddr(regfile_waddr),
  .wdata(regfile_wdata)
);

regfile regfile_a(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),
  .we(regfile_we),
  .waddr(regfile_waddr),
  .wdata(regfile_wdata),
  .re1(id_reg1_read_o),
  .raddr1(id_reg1_addr_o),
  .rdata1(id_data1_i),
  .re2(id_reg2_read_o),
  .raddr2(id_reg2_addr_o),
  .rdata2(id_data2_i)
);


endmodule