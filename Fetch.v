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

    wire [31:0] PC_F, PCF, PCPlus4F;
    wire [31:0] InstrF;

    reg [31:0] InstrF_reg;
    reg [31:0] PCF_reg, PCPlus4F_reg;

   
    mux PC_mux(
        .a(PCPlus4F),       
        .b(PCTargetE),        
        .s(PCSrcE),         
        .c(PC_F)             
    );

    PC PC_PC(
        .clk(clk),
        .rst(rst),
        .StallF(StallF),      // StallF sinyali eklendi
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

   
    wire [31:0] lookup_target;
    wire btb_found;

    btb BTB(
        .clk(clk),
        .reset(rst),
        .pc(PCF),
        .target(branch_target),
        .insert(branch_taken),    // Dallanma alındıysa yeni hedef ekle
        .lookup_target(lookup_target),
        .found(btb_found)
    );

    // Dallanma karşılaştırma mantığı
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

