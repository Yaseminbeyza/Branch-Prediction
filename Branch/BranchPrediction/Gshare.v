module gshare
 #(
    parameter GSHARE_BITS_NUM = 8,
    parameter OPTION_OPERAND_WIDTH = 32
    )
   (
    input clk,
    input rst,
    output predicted_flag_o, 

    input fetch_op_branch_flag_i,       
    input fetch_op_branch_not_flag_i,
    input op_branch_taken_i,
    input op_branch_not_taken_i,
    input pi_decode_i,
    input flag_i,
    
    input op_conditional_i,
    input branch_mispredict_i,

    input [OPTION_OPERAND_WIDTH-1:0] pc_i
    );

   localparam [1:0]
      STRONGLY_NOT_TAKEN = 2'b00,
      WEAKLY_NOT_TAKEN   = 2'b01,
      WEAKLY_TAKEN       = 2'b10,
      STRONGLY_TAKEN     = 2'b11;
   
   localparam FSM_NUM = 2 ** GSHARE_BITS_NUM;

   integer i = 0;

   // State table (PHT) and branch history table (BHT)
   reg [1:0] pht [0:FSM_NUM - 1]; 
   reg [GSHARE_BITS_NUM-1:0] brn_hist_table [0:FSM_NUM - 1]; 
   reg [GSHARE_BITS_NUM - 1:0] previous_index = 0;

   // Calculate the state index based on PHT and BHT
   wire [GSHARE_BITS_NUM - 1:0] state_index = 
       brn_hist_table[pc_i[GSHARE_BITS_NUM + 1:2]] ^ pc_i[GSHARE_BITS_NUM + 1:2];

   // Prediction logic
   assign predicted_flag_o = (pht[state_index][1] && op_branch_taken_i) ||
                              (!pht[state_index][1] && op_branch_not_taken_i);

   wire branch_taken = (fetch_op_branch_flag_i && flag_i) || (fetch_op_branch_not_flag_i && !flag_i);

   always @(posedge clk) begin
      if (rst) begin
         
         for (i = 0; i < FSM_NUM; i = i + 1) begin
            pht[i] <= WEAKLY_TAKEN; 
            brn_hist_table[i] <= 0; 
         end
         previous_index <= 0;
      end else begin
         if (op_branch_taken_i || op_branch_not_taken_i) begin
            
            previous_index <= state_index;
         end

         if (op_conditional_i  && pi_decode_i) begin
           
            brn_hist_table[pc_i[GSHARE_BITS_NUM + 1:2]] <= 
                {brn_hist_table[pc_i[GSHARE_BITS_NUM + 1:2]][GSHARE_BITS_NUM - 1:1], branch_taken};

           
            if (!branch_taken) begin
               case (pht[previous_index])
                  STRONGLY_TAKEN: pht[previous_index] <= WEAKLY_TAKEN;
                  WEAKLY_TAKEN:   pht[previous_index] <= WEAKLY_NOT_TAKEN;
                  WEAKLY_NOT_TAKEN: pht[previous_index] <= STRONGLY_NOT_TAKEN;
                  STRONGLY_NOT_TAKEN: pht[previous_index] <= STRONGLY_NOT_TAKEN;
               endcase
            end else begin
               case (pht[previous_index])
                  STRONGLY_NOT_TAKEN: pht[previous_index] <= WEAKLY_NOT_TAKEN;
                  WEAKLY_NOT_TAKEN:   pht[previous_index] <= WEAKLY_TAKEN;
                  WEAKLY_TAKEN:       pht[previous_index] <= STRONGLY_TAKEN;
                  STRONGLY_TAKEN:     pht[previous_index] <= STRONGLY_TAKEN;
               endcase
            end
         end
      end
   end
endmodule

module saturation_counter(

    input clk,
    input rst,
    output predicted_flag_o,     //result of predictor

    input fetch_op_branch_false_i,      
    input fetch_op_branch_not_false_i,     
    input op_branch_taken_i,               
    input op_branch_not_taken_i,              
    input pi_decode_i,         
    input flag_i,              

    input op_conditional_i,     
    input branch_mispredict_i    
    );

   localparam [1:0]
      STRONGLY_NOT_TAKEN = 2'b00,
      WEAKLY_NOT_TAKEN   = 2'b01,
      WEAKLY_TAKEN       = 2'b10,
      STRONGLY_TAKEN     = 2'b11;

   reg [1:0] state = WEAKLY_TAKEN;

   assign predicted_flag_o = (state[1] && op_branch_taken_i) || (!state[1] && op_branch_not_taken_i); //Dallanma alınacak mı alınmayacak mı?
   
   wire branch_taken = (fetch_op_branch_false_i && flag_i) || (fetch_op_branch_not_false_i && !flag_i);
 
   always @(posedge clk) begin
      if (rst) begin
         state <= WEAKLY_TAKEN;
      end else begin
         if (op_conditional_i && pi_decode_i) begin
            if (!branch_taken) begin
               case (state)
                  STRONGLY_TAKEN:
                     state <= WEAKLY_TAKEN;
                  WEAKLY_TAKEN:
                     state <= WEAKLY_NOT_TAKEN;
                  WEAKLY_NOT_TAKEN:
                     state <= STRONGLY_NOT_TAKEN;
                  STRONGLY_NOT_TAKEN:
                     state <= STRONGLY_NOT_TAKEN;
               endcase
            end else begin
               case (state)
                  STRONGLY_NOT_TAKEN:
                     state <= WEAKLY_NOT_TAKEN;
                  WEAKLY_NOT_TAKEN:
                     state <= WEAKLY_TAKEN;
                  WEAKLY_TAKEN:
                     state <= STRONGLY_TAKEN;
                  STRONGLY_TAKEN:
                     state <= STRONGLY_TAKEN;
               endcase
            end
         end
      end
   end
endmodule
