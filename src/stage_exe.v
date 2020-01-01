`include "defines.v"
module stage_exe(
    input wire                  rst,
    input wire                  rdy,


    input wire[`OpcodeBus]      opcode_i,
    input wire[`Func3Bus]       func3_i,
    input wire[`Func7Bus]       func7_i,
    input wire[`RegBus]         data1_i,
    input wire[`RegBus]         data2_i,
    input wire[`RegBus]         ls_offset_i,
    input wire[`RegAddrBus]     wd_i,
    input wire                  wreg_i,

    output reg[`OpcodeBus]      opcode_o,
    output reg[`Func3Bus]       func3_o,
    output reg[`RegBus]         mem_addr_o,
    output reg[`RegAddrBus]     wd_o,
    output reg                  wreg_o,
    output reg[`RegBus]         wdata_o
);

wire                        data1_lt_data2;
wire                        data1_lt_data2_u;
wire[`RegBus]               sra_result;

assign data1_lt_data2 = ((data1_i[31] & !data2_i[31])
                        || ((data1_i[31] == data2_i[31])
                        && (data1_i < data2_i)));
assign data1_lt_data2_u = data1_i < data2_i;
assign sra_result = ({32{data1_i[31]}} << (6'd32 - {1'b0, data2_i[4:0]})) | data1_i >> data2_i[4:0];

    always @ ( * ) begin
        if (rst) begin
            opcode_o            <= `NON_OP;
            func3_o             <= `NON_FUNC3;
            mem_addr_o          <= `ZeroWord;
            wd_o                <= `ZeroRegAddr;
            wreg_o              <= `WriteDisable;
            wdata_o             <= `ZeroWord;
        end else begin
            opcode_o            <= opcode_i;
            func3_o             <= func3_i;
            wd_o                <= wd_i;
            wreg_o              <= wreg_i;
            case (opcode_i)
                `NON_OP: begin
                    mem_addr_o      <= `ZeroWord;
                    wdata_o         <= `ZeroWord;
                end
                `LUI_OP: begin
                    mem_addr_o      <= `ZeroWord;
                    wdata_o         <= data1_i;
                end
                `AUIPC_OP: begin
                    mem_addr_o      <= `ZeroWord;
                    wdata_o         <= data1_i;
                end
                `JAL_OP: begin
                    mem_addr_o      <= `ZeroWord;
                    wdata_o         <= data1_i;
                end
                `JALR_OP: begin
                    mem_addr_o      <= `ZeroWord;
                    wdata_o         <= data2_i;
                end
                `B_OP: begin
                    mem_addr_o      <= `ZeroWord;
                    wdata_o         <= `ZeroWord;
                    case (func3_i)
                        `BEQ_FUNC3: begin
                        end
                        `BNE_FUNC3: begin
                        end
                        `BLT_FUNC3: begin
                        end
                        `BGE_FUNC3: begin
                        end
                        `BLTU_FUNC3: begin
                        end
                        `BGEU_FUNC3: begin
                        end                        
                    endcase
                end
                `L_OP: begin
                    mem_addr_o      <= data1_i + ls_offset_i;
                    wdata_o         <= `ZeroWord;
                    case (func3_i)
                        `LB_FUNC3: begin
                        end
                        `LH_FUNC3: begin
                        end
                        `LW_FUNC3: begin
                        end
                        `LBU_FUNC3: begin
                        end
                        `LBU_FUNC3: begin
                        end
                    endcase
                end
                `S_OP: begin
                    mem_addr_o      <= data1_i + ls_offset_i;
                    wdata_o         <= data2_i;
                    case (func3_i)
                        `SB_FUNC3: begin
                        end
                        `SH_FUNC3: begin
                        end
                        `SW_FUNC3: begin
                        end
                    endcase
                end
                `I_OP: begin
                    mem_addr_o      <= `ZeroWord;
                    case (func3_i)
                        `ADDI_FUNC3: begin
                            wdata_o     <= data1_i + data2_i;
                        end
                        `SLTI_FUNC3: begin
                            wdata_o     <= data1_lt_data2;
                        end
                        `SLTIU_FUNC3: begin
                            wdata_o     <= data1_lt_data2_u;
                        end
                        `XORI_FUNC3: begin
                            wdata_o     <= data1_i ^ data2_i;
                        end
                        `ORI_FUNC3: begin
                            wdata_o     <= data1_i | data2_i;
                        end
                        `ANDI_FUNC3: begin
                            wdata_o     <= data1_i & data2_i;
                        end
                        `SLLI_FUNC3: begin
                            wdata_o     <= data1_i << data2_i[4:0];
                        end
                        `SRLI_FUNC3: begin
                            if (func7_i == `NON_FUNC7) begin //srli
                                wdata_o     <= data1_i >> data2_i[4:0];
                            end else begin //srai
                                wdata_o     <= sra_result;
                            end
                        end
                    endcase
                end
                `R_OP: begin
                    mem_addr_o      <= `ZeroWord;
                    case (func3_i)
                        `ADD_FUNC3: begin
                            if (func7_i == `NON_FUNC7) begin //add
                                wdata_o     <= data1_i + data2_i;
                            end else begin //sub
                                wdata_o     <= data1_i + (~data2_i) + 1;
                            end
                        end
                        `SLL_FUNC3: begin
                            wdata_o     <= data1_i << data2_i[4:0];
                        end
                        `SLT_FUNC3: begin
                            wdata_o     <= data1_lt_data2;
                        end
                        `SLTU_FUNC3: begin
                            wdata_o     <= data1_lt_data2_u;
                        end
                        `XOR_FUNC3: begin
                            wdata_o     <= data1_i ^ data2_i;
                        end
                        `SRL_FUNC3: begin
                            if (func7_i == `NON_FUNC7) begin //srl
                                wdata_o     <= data1_i >> data2_i[4:0];
                            end else begin //sra
                                wdata_o     <= sra_result;
                            end
                        end
                        `OR_FUNC3: begin
                            wdata_o     <= data1_i | data2_i;
                        end
                        `AND_FUNC3: begin
                            wdata_o     <= data1_i & data2_i;
                        end
                    endcase
                end
            endcase
        end
    end

endmodule