module Fetch(
    input clk, rst, PCSrcE, StallF,
    input [31:0] PCTargetE,
    input branch_taken,
    input [31:0] branch_target,
    input [31:0] rs1_i,
    input [31:0] rs2_i,
    output [31:0] InstrD, PCD, PCplus4D,
    output branch_lt,
    output branch_ltu,
    output branch_eq
);

    wire [31:0] PC_F, PCF, PCPlus4F, InstrF;
    reg [31:0] InstrF_reg, PCF_reg, PCPlus4F_reg;
    wire predicted_flag_o, branch_mispredict_o;
    
    // New signals for branch prediction
    wire branch_pred_flag;
    wire [31:0] lookup_target;
    wire btb_found;

    // Mux logic to select the next PC based on branch prediction and PCSrcE
    mux PC_mux(
        .a(PCPlus4F),
        .b(PCTargetE),
        .s(PCSrcE || branch_pred_flag),   // Modified to include branch prediction result
        .c(PC_F)
    );

    PC PC_PC(
        .clk(clk),
        .rst(rst),
        .StallF(StallF),      // StallF signal added
        .PC_Next(PC_F),
        .PC(PCF)
    );

    Instruction_Memory IMEM(
        .rst(rst),
        .address(PCF),
        .instruction_out(InstrF)
    );

    PC_Adder PC_Adder(
        .a(PCF),
        .b(32'h00000004),
        .c(PCPlus4F)
    );

    // Branch prediction unit instance
    Branch_prediction #(
        .BRANCH_MODE(2)  // Select the mode (0: Simple, 1: Gshare, 2: Saturation Counter)
    ) branch_predictor (
        .clk(clk),
        .rst(rst),
        .op_branch_taken_i(branch_taken),
        .op_branch_not_taken_i(!branch_taken),
        .branch_offset_i(PCF[9:0]),
        .pc_i(PCF),
        .predicted_flag_o(branch_pred_flag),
        .op_conditional_i(1'b1),  // Assuming always conditional for this setup
        .previous_predicted_flag_i(1'b0),  // Simplified; adjust for real use
        .flag_i(branch_taken),  // Current branch flag
        .pi_decode_i(1'b0),  // Assuming no decode stage pipeline stall for now
        .fetch_branch_flag_i(branch_taken),
        .fetch_branch_branch_not_flag_i(!branch_taken),
        .branch_mispredict_o(branch_mispredict_o)
    );

    // Dallanma karşılaştırma mantığı (Branch comparison logic)
    wire lt_w = ($signed(rs1_i) < $signed(rs2_i));
    wire ltu_w = (rs1_i < rs2_i);
    wire eq_w = (rs1_i === rs2_i);

    assign branch_lt = lt_w;
    assign branch_ltu = ltu_w;
    assign branch_eq = eq_w;

    always @(posedge clk or posedge rst) begin
        if (rst == 1'b1) begin
            InstrF_reg <= 32'h00000000;
            PCF_reg <= 32'h00000000;
            PCPlus4F_reg <= 32'h00000000;
        end else if (!StallF) begin  
            InstrF_reg <= InstrF;
            PCF_reg <= (btb_found) ? lookup_target : PCF;
            PCPlus4F_reg <= PCPlus4F;
        end
    end

    assign InstrD = (rst == 1'b1) ? 32'h00000000 : InstrF_reg;
    assign PCD = (rst == 1'b1) ? 32'h00000000 : PCF_reg;
    assign PCplus4D = (rst == 1'b1) ? 32'h00000000 : PCPlus4F_reg;

endmodule


