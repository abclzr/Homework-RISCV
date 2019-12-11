`include "defines.v"
module stage_id(
    // from if_id
    input wire                  rst,

    input wire[`InstAddrBus]    pc_i,
    input wire[`InstBus]        inst_i,

    // from reg file
    input wire[`RegBus]         data1_i,
    input wire[`RegBus]         data2_i,

    // from exe
    input wire                  exe_wreg_i,
    input wire[`RegAddrBus]     exe_wd_i,
    input wire[`RegBus]         exe_wdata_i,
    input wire[`OpcodeBus]      exe_op_i,

    // from mem
    input wire                  mem_wreg_i,
    input wire[`RegAddrBus]     mem_wd_i,
    input wire[`RegBus]         mem_wdata_i,

    // to reg file
    output reg                  reg1_read_o,
    output reg                  reg2_read_o,
    output reg[`RegAddrBus]     reg1_addr_o,
    output reg[`RegAddrBus]     reg2_addr_o,

    // to id_ex
    output reg[`OpcodeBus]      opcode_o,
    output reg[`Func3Bus]       func3_o,
    output reg[`Func7Bus]       func7_o,
    output reg[`RegBus]         data1_o,
    output reg[`RegBus]         data2_o,
    output reg[`RegBus]         ls_offset_o,
    output reg[`RegBus]         wd_o,
    output reg                  wreg_o,

    // todo : branch prediction
    output reg                  branch_enable_o,
    output reg                  branch_addr_o,
);

    reg [`RegBus]                   imm;
    wire [`OpcodeBus]               opcode = inst_i[6:0];
    wire [`Func3Bus]                func3 = inst_i[14:12];
    wire [`Func7Bus]                func7 = inst_i[31:25];
    wire [`InstAddrBus]             pc_i_plus_4;

    assign pc_i_plus_4          = pc_i + 32'h4;
    assign data1_lt_data2 = ((data1_o[31] & !data2_o[31]) //need to check
                            || ((data1_o[31] == data2_o[31]) && data1_o < data2_o));

    always @ ( * ) begin
        if (rst || inst_i == 32'b0) begin
            opcode_o            <= `NON_OP;
            func3_o             <= `NON_FUNC3;
            func7_o             <= `NON_FUNC7;
            ls_offset_o         <= `ZeroWord;
            wd_o                <= `ZeroRegAddr;
            wreg_o              <= `WriteDisable;
            reg1_read_o         <= `ReadDisable;
            reg1_addr_o         <= `ZeroRegAddr;
            reg2_read_o         <= `ReadDisable;
            reg2_addr_o         <= `ZeroRegAddr;
            branch_enable_o     <= `BranchDisable;
            branch_addr_o       <= `ZeroWord;
        end else begin
            opcode_o            <= opcode;
            func3_o             <= func3;
            func7_o             <= func7;
            wd_o                <= inst_i[11:7];
            reg1_addr_o         <= inst_i[19:15];
            reg2_addr_o         <= inst_i[24:20];
            case (opcode)
                `NON_OP: begin
                    ls_offset_o         <= `ZeroWord;
                    wreg_o              <= `WriteDisable;
                    reg1_read_o         <= `ReadDisable;
                    reg2_read_o         <= `ReadDisable;
                    branch_enable_o     <= `BranchDisable;
                    branch_addr_o       <= `ZeroWord;
                end
                `LUI_OP: begin
                    ls_offset_o         <= `ZeroWord;
                    wreg_o              <= `WriteEnable;
                    imm                 <= {inst_i[31:12], 12'b0};
                    reg1_read_o         <= `ReadDisable;
                    reg2_read_o         <= `ReadDisable;
                    branch_enable_o     <= `BranchDisable;
                    branch_addr_o       <= `ZeroWord;
                end
                `AUIPC_OP: begin
                    ls_offset_o         <= `ZeroWord;
                    wreg_o              <= `WriteEnable;
                    imm                 <= {inst_i[31:12], 12'b0} + pc_i;
                    reg1_read_o         <= `ReadDisable;
                    reg2_read_o         <= `ReadDisable;
                    branch_enable_o     <= `BranchDisable;
                    branch_addr_o       <= `ZeroWord;
                end
                `JAL_OP: begin
                    ls_offset_o         <= `ZeroWord;
                    wreg_o              <= `WriteEnable;
                    imm                 <= pc_i_plus_4;
                    reg1_read_o         <= `ReadDisable;
                    reg2_read_o         <= `ReadDisable;
                    branch_enable_o     <= `BranchEnable;
                    branch_addr_o       <= {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0} + pc_i;
                end
                `JALR_OP: begin
                    ls_offset_o         <= `ZeroWord;
                    wreg_o              <= `WriteEnable;
                    imm                 <= pc_i_plus_4;
                    reg1_read_o         <= `ReadEnable;
                    reg2_read_o         <= `ReadDisable;
                    branch_enable_o     <= `BranchEnable;
                    branch_addr_o       <= {{20{inst_i[31]}}, inst_i[31:20]} + data1_o;
                end
                `B_OP: begin
                    ls_offset_o         <= `ZeroWord;
                    wreg_o              <= `WriteDisable;
                    reg1_read_o         <= `ReadDisable;
                    reg2_read_o         <= `ReadDisable;
                    branch_enable_o     <= `BranchEnable;
                    case (func3)
                        `BEQ_FUNC3: begin
                            if (data1_o == data2_o) begin
                                branch_addr_o   <= {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0} + pc_i;
                            end else begin
                                branch_addr_o   <= pc_i_plus_4;
                            end
                        end
                        `BNE_FUNC3: begin
                            if (data1_o != data2_o) begin
                                branch_addr_o   <= {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0} + pc_i;
                            end else begin
                                branch_addr_o   <= pc_i_plus_4;
                            end
                        end
                        `BLT_FUNC3: begin
                            if (data1_lt_data2) begin
                                branch_addr_o   <= {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0} + pc_i;
                            end else begin
                                branch_addr_o   <= pc_i_plus_4;
                            end
                        end
                        `BGE_FUNC3: begin
                            if (!data1_lt_data2) begin
                                branch_addr_o   <= {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0} + pc_i;
                            end else begin
                                branch_addr_o   <= pc_i_plus_4;
                            end
                        end
                        `BLTU_FUNC3: begin
                            if (data1_o < data2_o) begin
                                branch_addr_o   <= {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0} + pc_i;
                            end else begin
                                branch_addr_o   <= pc_i_plus_4;
                            end
                        end
                        `BGEU_FUNC3: begin
                            if (data1_o >= data2_o) begin
                                branch_addr_o   <= {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0} + pc_i;
                            end else begin
                                branch_addr_o   <= pc_i_plus_4;
                            end
                        end                        
                    endcase
                end
                `L_OP: begin
                    ls_offset_o         <= {{20{inst_i[31]}}, inst_i[31:20]};
                    wreg_o              <= `WriteEnable;
                    reg1_read_o         <= `ReadEnable;
                    reg2_read_o         <= `ReadDisable;
                    branch_enable_o     <= `BranchDisable;
                    branch_addr_o       <= `ZeroWord;
                end
                `S_OP: begin
                    ls_offset_o         <= {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
                    wreg_o              <= `WriteDisable;
                    reg1_read_o         <= `ReadEnable;
                    reg2_read_o         <= `ReadEnable;
                    branch_enable_o     <= `BranchDisable;
                    branch_addr_o       <= `ZeroWord;
                end
                `I_OP: begin
                    ls_offset_o     <= `ZeroWord;
                    wreg_o          <= `WriteEnable;
                    reg1_read_o     <= `ReadEnable;
                    reg2_read_o     <= `ReadDisable;
                    branch_enable_o <= `BranchDisable;
                    branch_addr_o   <= `ZeroWord;
                    case (func3)
                        `ADDI_FUNC3: begin
                            imm             <= {{20{inst_i[31]}}, inst_i[31:20]};
                        end
                        `SLTI_FUNC3: begin
                            imm             <= {{20{inst_i[31]}}, inst_i[31:20]};
                        end
                        `SLTIU_FUNC3: begin
                            imm             <= {{20{inst_i[31]}}, inst_i[31:20]};
                        end
                        `XORI_FUNC3: begin
                            imm             <= {{20{inst_i[31]}}, inst_i[31:20]};
                        end
                        `ORI_FUNC3: begin
                            imm             <= {{20{inst_i[31]}}, inst_i[31:20]};
                        end
                        `ANDI_FUNC3: begin
                            imm             <= {{20{inst_i[31]}}, inst_i[31:20]};
                        end
                        `SLLI_FUNC3: begin
                            imm             <= {27'b0, inst_i[24:20]};
                        end
                        `SRLI_FUNC3: begin
                            imm             <= {27'b0, inst_i[24:20]};
                        end
                    endcase
                end
                `R_OP: begin
                    ls_offset_o     <= `ZeroWord;
                    wreg_o          <= `WriteEnable;
                    reg1_read_o     <= `ReadEnable;
                    reg2_read_o     <= `ReadEnable;
                    branch_enable_o <= `BranchDisable;
                    branch_addr_o   <= `ZeroWord;
                end
            endcase
        end
    end

    always @ ( * ) begin
        if (rst == `RstEnable || inst_i == 32'b0) begin
            data1_o <= `ZeroWord;
        end else if (reg1_read_o == 'ReadDisable) begin
            data1_o <= imm;
        end else if (exe_wreg_i == 'WriteEnable && exe_wd_i == reg1_addr_o) begin
            data1_o <= exe_wdata_i;
        end else if (mem_wreg_i == 'WriteEnable && mem_wd_i == reg1_addr_o) begin
            data1_o <= mem_wdata_i;
        end else begin
            data1_o <= data1_i;
        end
    end

    always @ ( * ) begin
        if (rst == `RstEnable || inst_i == 32'b0) begin
            data2_o <= `ZeroWord;
        end else if (reg2_read_o == 'ReadDisable) begin
            data2_o <= imm;
        end else if (exe_wreg_i == 'WriteEnable && exe_wd_i == reg2_addr_o) begin
            data2_o <= exe_wdata_i;
        end else if (mem_wreg_i == 'WriteEnable && mem_wd_i == reg2_addr_o) begin
            data2_o <= mem_wdata_i;
        end else begin
            data2_o <= data2_i;
        end
    end

endmodule