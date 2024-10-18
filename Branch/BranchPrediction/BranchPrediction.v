`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
`include "gshare.v"
`include "saturation_counter.v"
`include "branch_basic.v"
module Branch_prediction
  #(
    parameter BRANCH_MODE = 0, // 0: SIMPLE, 1: GSHARE, 2: SAT_COUNTER
    parameter OPTION_OPERAND_WIDTH = 32
    )
   (
   input clk,
   input rst,
   
   input op_branch_taken_i,              
   input op_branch_not_taken_i,              
   input [9:0] branch_offset_i,  
   input [OPTION_OPERAND_WIDTH - 1:0] pc_i,
   output predicted_flag_o,     

   
   input op_conditional_i,      
   input previous_predicted_flag_i, 
   input flag_i,                

   input pi_decode_i,      //decode stage stall atıldı
   input fetch_branch_flag_i,         
   input fetch_branch_branch_not_flag_i,      

   
   output 	branch_mispredict_o 
   );

   assign branch_mispredict_o = op_conditional_i & (flag_i != previous_predicted_flag_i);

generate
  if (BRANCH_MODE == 2) begin : branch_predictor_saturation_counter
      saturation_counter #(
      .OPTION_OPERAND_WIDTH(OPTION_OPERAND_WIDTH)
      ) branch_predictor_saturation_counter (
        .predicted_flag_o                 (predicted_flag_o),
         .clk                              (clk),
         .rst                              (rst),
         .flag_i                           (flag_i),
         .fetch_branch_flag_i              (fetch_branch_flag_i),
         .fetch_branch_branch_not_flag_i   (fetch_branch_branch_not_flag_i),
         .op_branch_taken_i                (op_branch_taken_i),
         .op_branch_not_taken_i            (op_branch_not_taken_i),
         .op_conditional_i                 (op_conditional_i),
         .pi_decode_i                      (pi_decode_i),
         .branch_mispredict_o              (branch_mispredict_o)
      );
      
      end else if (BRANCH_MODE == 1) begin : branch_predictor_gshare
      ghare #(
         .OPTION_OPERAND_WIDTH(OPTION_OPERAND_WIDTH)
      ) branch_predictor_gshare (
         .predicted_flag_o                 (predicted_flag_o),
         .clk                              (clk),
         .rst                              (rst),
         .flag_i                           (flag_i),
         .fetch_branch_flag_i              (fetch_branch_flag_i),
         .fetch_branch_branch_not_flag_i   (fetch_branch_branch_not_flag_i),
         .op_branch_taken_i                (op_branch_taken_i),
         .brn_pc_i                         (brn_pc_i),
         .op_branch_not_taken_i            (op_branch_not_taken_i),
         .op_conditional_i                 (op_conditional_i),
         .pi_decode_i                      (pi_decode_i),
         .branch_mispredict_o              (branch_mispredict_o)
      );
      
      end else if (BRANCH_MODE == 0) begin : branch_basic
      branch_basic branch_basic (
         .predicted_flag_o                 (predicted_flag_o),
         .op_branch_taken_i                (op_branch_taken_i),
         .op_branch_not_taken_i            (op_branch_not_taken_i),
         .branch_offset_i                  (branch_offset_i)
      );
   end
endgenerate

endmodule