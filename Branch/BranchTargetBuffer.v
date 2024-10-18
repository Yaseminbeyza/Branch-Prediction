`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module btb (

    input wire clk,
    input wire reset,
    input wire [31:0] pc,      
    input wire [31:0] target,  
    input wire insert,           
    output reg [31:0] lookup_target, 
    output reg found           
);
    parameter BTB_SIZE = 8;    

  
    reg [31:0] btb_pc [0:BTB_SIZE-1];    
    reg [31:0] btb_target [0:BTB_SIZE-1];

    integer i;

   
    initial begin
        for (i = 0; i < BTB_SIZE; i = i + 1) begin
            btb_pc[i] = 32'hFFFFFFFF; 
            btb_target[i] = 32'h0;    
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < BTB_SIZE; i = i + 1) begin
                btb_pc[i] <= 32'hFFFFFFFF; // Reset all entries
                btb_target[i] <= 32'h0;     // Reset targets
            end
        end else if (insert) begin
            // Insert the new entry if an empty slot is found
            found = 0;
            for (i = 0; i < BTB_SIZE; i = i + 1) begin
                if (btb_pc[i] == 32'hFFFFFFFF) begin 
                    btb_pc[i] <= pc;
                    btb_target[i] <= target;
                    found = 1; 
                   
                end
            end
            if (!found) begin
               
                btb_pc[0] <= pc;
                btb_target[0] <= target;
            end
        end
end

    // Lookup logic
    always @(*) begin
        found = 0;
        lookup_target = 32'h0; // Default output
        for (i = 0; i < BTB_SIZE; i = i + 1) begin
            if (btb_pc[i] == pc) begin
                lookup_target = btb_target[i]; // Found target for the given PC
                found = 1; // Set found flag
              
            end
        end
        if (!found) begin
            lookup_target = 32'h0; // PC not found
        end
    end
endmodule