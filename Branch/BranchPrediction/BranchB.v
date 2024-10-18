module branch_basic(
    input op_branch_taken_i,              
    input op_branch_not_taken_i,            
    input [9:0] branch_offset_i,  
    output predicted_flag_o    
    );
   
   // Static branch prediction 
   assign predicted_flag_o = op_branch_taken_i & branch_offset_i[9] |
                             op_branch_not_taken_i & !branch_offset_i[9];

endmodule