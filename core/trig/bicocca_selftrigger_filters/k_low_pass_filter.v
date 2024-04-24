`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// University: UNIMIB 
// Engineer: Esteban Cristaldo, MSc
//
// Create Date: July 1, 2022, 5:51:46 PM
// Design Name: filtering_and_selftrigger
// Module Name: k_low_pass_filter.v
// Project Name: selftrigger@bicocca
// Target Devices: DAPHNE V2
//
//////////////////////////////////////////////////////////////////////////////////
module k_low_pass_filter(
	input wire clk,
	input wire reset, 
	input wire enable, 
	input wire signed [15:0] x,
    output wire signed [15:0] y
);
    
    parameter k = 26;
    parameter hist = 20;
    
    reg reset_reg, enable_reg;
    reg signed [15:0] in_reg, out_reg, diff;
    //reg signed [15:0] diff;
	reg signed [47:0] x_1, y_1;

	wire signed [47:0] w1, w2, w3, w4, w5, w6, w7;

	always @(posedge clk) begin 
		if(reset) begin
			reset_reg <= 1'b1;
			enable_reg <= 1'b0;
		end else if (enable) begin
			reset_reg <= 1'b0;
			enable_reg <= 1'b1;
		end else begin 
			reset_reg <= 1'b0;
			enable_reg <= 1'b0;
		end
	end

	always @(posedge clk) begin
		if(reset_reg) begin
			x_1 <= 0;
			y_1 <= 0;
			in_reg <= 0;
			out_reg <= 0;
			//diff <= 0;
		end else if(enable_reg) begin
			x_1 <= w1;
			y_1 <= w6;
			in_reg <= x;
            //diff <= out_reg - w6[47:32];
			//if(hist <= $unsigned(diff)) begin
			out_reg <= w6[47:32];
			//end 
		end
	end

	assign w1 = {in_reg,32'b0};
	assign w2 = x_1;
	assign w3 = w1 + w2;
	assign w4 = w3 >> k;
	assign w5 = y_1;
	assign w6 = w4 + w5 - w7;
	assign w7 = w5 >> (k-1);
	assign y = out_reg;

endmodule