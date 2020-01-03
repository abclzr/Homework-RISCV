`include "defines.v"
module stage_mem(
    input wire                  rst,
    input wire                  clk,

    //debug
    input wire[`InstAddrBus]    pc_i,
    input wire[`InstBus]        inst_i,
    output reg[`InstAddrBus]    pc_o,
    output reg[`InstBus]        inst_o,

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

    output reg                  mem_req_o,
    output reg                  mem_write_enable_o,
    output reg[`InstAddrBus]    mem_addr_o,
    output reg[`DataBus]        mem_data_o,

    
    output reg[`InstAddrBus]    read_addr,
    output reg                  write_bit,
    output reg[`Func3Bus]       write_type,
    output reg[`InstAddrBus]    write_addr,
    output reg[`CacheOneDataBus]write_data,
    input wire                  cache_hit,
    input wire[`CacheDataBus]   cache_data
);

reg mem_check_busy;
reg[2:0] state;
reg[`DataBus] data1;
reg[`DataBus] data2;
reg[`DataBus] data3;
reg[`RegBus] all_data;

    always @ ( * ) begin
        if (rst) begin
            wd_o                    <= `ZeroRegAddr;
            wreg_o                  <= `False_v;
            wdata_o                 <= `ZeroWord;
            mem_req_o               <= `False_v;
            pc_o                    <= `ZeroWord;
            inst_o                  <= `ZeroWord;
        end else begin
            wd_o                    <= wd_i;
            wreg_o                  <= wreg_i;
            pc_o                    <= pc_i;
            inst_o                  <= inst_i;
            if (opcode_i == `L_OP) begin
                wdata_o                 <= all_data;
            end else begin
                wdata_o                 <= wdata_i;
            end
            if (mem_check_busy) begin
                mem_req_o               <= ((opcode_i == `L_OP) || (opcode_i == `S_OP));
            end else begin
                mem_req_o               <= `False_v;
            end
        end
    end

    always @ (posedge clk) begin
        if (rst) begin
            mem_check_busy          <= `False_v;
            state                   <= 3'b000;
            mem_write_enable_o      <= `False_v;
            mem_addr_o              <= `ZeroWord;
            mem_data_o              <= `ZeroByte;
            read_addr               <= `ZeroWord;
            write_bit               <= `False_v;
            write_type              <= 3'b000;
            write_addr              <= `ZeroWord;
            write_data              <= `ZeroByte;
        end else if (mem_req_o) begin
            case (state)
                3'b000: begin
                    mem_check_busy          <= `True_v;
                    mem_addr_o              <= mem_addr_i;
                    if (opcode_i == `L_OP) begin
                        read_addr               <= mem_addr_i;
                        write_bit               <= `False_v;
                        mem_write_enable_o      <= `False_v;
                        state                   <= 3'b001;
                    end else if (opcode_i == `S_OP) begin
                        write_bit               <= `True_v;
                        write_type              <= func3_i;
                        write_addr              <= mem_addr_i;
                        write_data              <= wdata_i[7:0];
                        mem_write_enable_o      <= `True_v;
                        mem_data_o              <= wdata_i[7:0];
                        state                   <= 3'b001;
                    end
                end
                3'b001: begin
                    if (opcode_i == `L_OP) begin
                        if (cache_hit) begin
                            state                   <= 3'b000;
                            mem_check_busy          <= `False_v;
                            mem_addr_o              <= `ZeroWord;
                            case (func3_i)
                                `LB_FUNC3 : begin
                                    all_data                <= {{24{cache_data[7]}}, cache_data[7:0]};
                                end
                                `LBU_FUNC3 : begin
                                    all_data                <= {24'b0, cache_data[7:0]};
                                end
                                `LH_FUNC3 : begin
                                    all_data                <= {{16{cache_data[15]}}, cache_data[15:0]};
                                end
                                `LHU_FUNC3 : begin
                                    all_data                <= {16'b0, cache_data[15:0]};
                                end
                                `LW_FUNC3 : begin
                                    all_data                <= cache_data;
                                end
                            endcase
                        end else begin
                            case (func3_i)
                                `LB_FUNC3, `LBU_FUNC3: begin
                                    state                   <= 3'b010;
                                end
                                `LH_FUNC3, `LHU_FUNC3, `LW_FUNC3: begin
                                    mem_addr_o              <= mem_addr_i + 1;
                                    state                   <= 3'b010;
                                end
                            endcase
                        end
                    end else if (opcode_i == `S_OP) begin
                        case (func3_i)
                            `SB_FUNC3: begin
                                write_bit               <= `False_v;
                                mem_write_enable_o      <= `False_v;
                                mem_check_busy          <= `False_v;
                                mem_addr_o              <= `ZeroWord;
                                state                   <= 3'b000;
                            end
                            `SH_FUNC3, `SW_FUNC3: begin
                                write_addr              <= mem_addr_i + 1;
                                write_data              <= wdata_i[15:8];
                                mem_addr_o              <= mem_addr_i + 1;
                                mem_data_o              <= wdata_i[15:8];
                                state                   <= 3'b010;
                            end
                        endcase
                    end
                end
                3'b010: begin
                    if (opcode_i == `L_OP) begin
                        case (func3_i)
                            `LB_FUNC3: begin
                                all_data                <= {{24{mem_data_i[7]}}, mem_data_i};
                                mem_check_busy          <= `False_v;
                                mem_addr_o              <= `ZeroWord;
                                state                   <= 3'b000;
                            end
                            `LBU_FUNC3: begin
                                all_data                <= {24'b0, mem_data_i};
                                mem_check_busy          <= `False_v;
                                mem_addr_o              <= `ZeroWord;
                                state                   <= 3'b000;
                            end
                            `LH_FUNC3, `LHU_FUNC3: begin
                                data1                   <= mem_data_i;
                                state                   <= 3'b011;
                            end
                            `LW_FUNC3: begin
                                data1                   <= mem_data_i;
                                mem_addr_o              <= mem_addr_i + 2;
                                state                   <= 3'b011;
                            end
                        endcase
                    end else if (opcode_i == `S_OP) begin
                        case (func3_i)
                            `SH_FUNC3: begin
                                write_bit               <= `False_v;
                                mem_write_enable_o      <= `False_v;
                                mem_check_busy          <= `False_v;
                                mem_addr_o              <= `ZeroWord;
                                state                   <= 3'b000;
                            end
                            `SW_FUNC3: begin
                                write_addr              <= mem_addr_i + 2;
                                write_data              <= wdata_i[23:16];
                                mem_addr_o              <= mem_addr_i + 2;
                                mem_data_o              <= wdata_i[23:16];
                                state                   <= 3'b011;
                            end
                        endcase
                    end
                end
                3'b011: begin
                    if (opcode_i == `L_OP) begin
                        case (func3_i)
                            `LH_FUNC3: begin
                                all_data                <= {{16{mem_data_i[7]}}, mem_data_i, data1};
                                mem_check_busy          <= `False_v;
                                mem_data_o              <= `ZeroWord;
                                state                   <= 3'b000;
                            end
                            `LHU_FUNC3: begin
                                all_data                <= {16'b0, mem_data_i, data1};
                                mem_check_busy          <= `False_v;
                                mem_data_o              <= `ZeroWord;
                                state                   <= 3'b000;
                            end
                            `LW_FUNC3: begin
                                data2                   <= mem_data_i;
                                mem_addr_o              <= mem_addr_i + 3;
                                state                   <= 3'b100;
                            end
                        endcase
                    end else if (opcode_i == `S_OP) begin
                        case (func3_i)
                            `SW_FUNC3: begin
                                write_addr              <= mem_addr_i + 3;
                                write_data              <= wdata_i[31:24];
                                mem_addr_o              <= mem_addr_i + 3;
                                mem_data_o              <= wdata_i[31:24];
                                state                   <= 3'b100;
                            end
                        endcase
                    end
                end
                3'b100: begin
                    if (opcode_i == `L_OP) begin
                        case (func3_i)
                            `LW_FUNC3: begin
                                data3                   <= mem_data_i;
                                state                   <= 3'b101;
                            end
                        endcase
                    end else if (opcode_i == `S_OP) begin
                        case (func3_i)
                            `SW_FUNC3: begin
                                write_bit               <= `False_v;
                                mem_write_enable_o      <= `False_v;
                                mem_check_busy          <= `False_v;
                                mem_addr_o              <= `ZeroWord;
                                state                   <= 3'b000;
                            end
                        endcase
                    end
                end
                3'b101: begin
                    if (opcode_i == `L_OP) begin
                        all_data                <= {mem_data_i, data3, data2, data1};
                        mem_check_busy          <= `False_v;
                        mem_addr_o              <= `ZeroWord;
                        state                   <= 3'b000;
                    end
                end
            endcase
        end else begin
            mem_check_busy          <= `True_v;
            write_bit               <= `False_v;
        end
    end

endmodule