`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module Branch_detector(
    input wire clk,
    input wire reset,
    
    input wire [31:0] pc,            
    input wire [31:0] branch_target,  
    input wire branch_taken,          
    input wire branch_prediction,   
    input wire [31:0] btb_target,     
    input wire btb_found,             
    input wire [2:0] branch_op,      
    input wire [31:0] rs1,          
    input wire [31:0] rs2,       
    
    output reg branch_mispredict,     
    output reg [31:0] next_pc        
);

    always @(posedge clk) begin
        if (reset) begin
            branch_mispredict <= 0;
            next_pc <= 32'h0;
        end else begin
            case(branch_op)
                3'b000: // BEQ (Branch if Equal)
                    if (branch_taken) begin
                        if (branch_prediction && btb_found && (btb_target == branch_target) && (rs1 == rs2)) begin
                            // Tahmin doğru ve rs1 ile rs2 eşitse, BTB hedefini kullan
                            branch_mispredict <= 0;
                            next_pc <= btb_target;
                        end else begin
                            // Yanlış tahmin veya rs1 ve rs2 eşit değilse
                            branch_mispredict <= 1;
                            next_pc <= branch_target;
                        end
                    end else begin
                        // Dallanma yok, pc + 4 ilerle
                        branch_mispredict <= 0;
                        next_pc <= pc + 4;
                    end
                
                3'b001: // BNE (Branch if Not Equal)
                    if (branch_taken) begin
                        if (branch_prediction && btb_found && (btb_target != branch_target) && (rs1 != rs2)) begin
                            // Tahmin doğru ve rs1 ile rs2 eşit değilse, BTB hedefini kullan
                            branch_mispredict <= 0;
                            next_pc <= btb_target;
                        end else begin
                            // Yanlış tahmin veya rs1 ve rs2 eşit
                            branch_mispredict <= 1;
                            next_pc <= branch_target;
                        end
                    end else begin
                        // Dallanma yok, pc + 4 ilerle
                        branch_mispredict <= 0;
                        next_pc <= pc + 4;
                    end

                // Diğer dallanma komutları için ek case blokları
                
                default: begin
                    // Eğer branch_op bilinen bir değer değilse, normal sıralı ilerleme
                    branch_mispredict <= 0;
                    next_pc <= pc + 4;
                end
            endcase
        end
    end

endmodule