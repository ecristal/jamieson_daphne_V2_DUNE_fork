`timescale 1ns/100ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Esteban Cristaldo
//
// Create Date: 07/05/2022 02:54:52 PM
// Design Name: filtering_and_selftrigger
// Module Name: IIRfilter_movmean25_cfd_trigger
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
//////////////////////////////////////////////////////////////////////////////////


module IIRfilter_movmean25_cfd_trigger #(parameter shift_delay = 15, threshold_divide = 4)(
    clk,
	reset,
	n_1_reset,
    enable,
    output_selector,
    threshold,
    x,
    trigger,
    y);

    input clk;
	input reset;
	input n_1_reset;
    input enable;
    input signed[15:0] x;
    input output_selector;
    input signed[31:0] threshold;
    output trigger;
    output signed[15:0] y;

    //parameter shift_delay = 15;
    //parameter threshold_divide = 4;
	//parameter threshold = -45;

	reg signed [17:0] n1, n2, n3, d1, d2;
	reg signed [24:0] x_1, x_2, y_1, y_2;
  	reg signed[15:0] x_i, en_mux, resta, counter_threshold_mod, y_overshoot, threshold_ride;
  	reg signed [2*16 - 1 : 0] y_delay_reg;
  	reg signed [shift_delay*16 -1 : 0] y_shifted;
  	reg trigger_threshold, trigger_crossover, trigger_reg, threshold_signal;
  	reg [11:0] counter_crossover, counter_threshold;
	reg reset_reg, enable_reg;
	reg signed [31:0] threshold_reg;

	wire signed[24:0] w1, w4, w7, w12, w13, w15, mult1;
	wire signed [17:0] w2, w20, w8, w14, w16, mult2;
	wire signed[47:0] w3, w5, w9, w6, w10, w11, w17, w18, w19, s_fraction_mult;
	wire signed [15:0] y_shifted_w, s_fraction, resta_wire;

	always @(posedge clk) begin
	   reset_reg <= reset;
	   enable_reg <= enable;
	end

	always @(posedge clk) begin
		if(reset_reg) begin

      // ********** FBK *********** //
		// n1 <= {3'b000,15'b001100011001011};
		// n2 <= {3'b111,15'b101000001110111}; // n2 0101111100010001
	    // n3 <= {3'b000,15'b001100000101101}; // n3 001100000101101
		// d1 <= {3'b001,15'b111000110001001};
		// d2 <= {3'b111,15'b000110110111101}; // 111001001000010
		// ********** FBK ************ //

		// ********** HPK ************ //
		n1 <= {3'b000,15'b001111101000111};
		n2 <= {3'b111,15'b100010110111100}; // 0111010010000111
	    n3 <= {3'b000,15'b001111011000101};
		d1 <= {3'b001,15'b110100000010000};
		d2 <= {3'b111,15'b001011000000111 + 1'b1}; // 1101001111110000
		// ********** HPK ************ //

	    x_i <= 16'b0;
        x_1 <= 25'b0;
        x_2 <= 25'b0;
	    y_1 <= 25'b0;
	    y_2 <= 25'b0;
	    
		end else if (n_1_reset) begin
		  x_i <= 16'b0;
			x_1 <= 25'b0;
      x_2 <= 25'b0;
			y_1 <= 25'b0;
			y_2 <= 25'b0;
		end else if (enable_reg) begin
		  x_i <= x;
			x_1 <= w1;
			x_2 <= w4;
			y_1 <= w12;
			y_2 <= w13;
			threshold_reg <= threshold;
		end
	end

    always @(posedge clk) begin
        if (reset_reg) begin
            en_mux <= 16'b0;
            y_delay_reg <= 2*16'b0;
            y_shifted <= shift_delay*16'b0;
            trigger_reg <= 1'b0;
            y_overshoot <= 16'b0;
		end else if(enable_reg) begin
			en_mux <= w11[39:24] + $signed(4);
            y_overshoot <= -$signed(en_mux >>> threshold_divide);
            //en_mux <= w11[40:25]; // + $signed(4);
            resta <= s_fraction - y_shifted[(shift_delay*16-1) : (shift_delay*16-1) - 15 ];
            y_delay_reg <= {y_delay_reg [15 : 0], resta_wire};
			y_shifted <= {y_shifted[(shift_delay*16-1) - 16 : 0], en_mux};
			trigger_reg <= (trigger_threshold && trigger_crossover);
		end else begin
			en_mux <= x;
		end
	end

	// modulo trigger normal 

	always @(posedge clk) begin
	    if (reset_reg || counter_crossover[11] || counter_threshold[11]) begin
			trigger_threshold <= 1'b0;
		end else if(enable_reg) begin
			if (($signed(en_mux) < -($signed(threshold_reg))) || trigger_threshold) begin
			     trigger_threshold <= 1'b1;
			end
			/*if(counter_crossover[11]) begin
			      trigger_threshold <= 1'b0;
			end*/
		end
	end

	always @(posedge clk) begin
	    if (reset_reg || counter_crossover[11]) begin
	        counter_crossover <= 12'b0;
		end else if(enable_reg && trigger_crossover) begin
			counter_crossover <= counter_crossover + 1'b1;
		end
	end

	always @(posedge clk) begin
	    if (reset_reg || ~trigger_threshold) begin
	        counter_threshold <= 12'b0;
		end else if(enable_reg && trigger_threshold) begin
			counter_threshold <= counter_threshold + 1'b1;
		end
	end

	always @(posedge clk) begin
	    if (reset_reg || counter_crossover[11]) begin
	        trigger_crossover <= 1'b0;
		end else if(enable_reg && trigger_threshold && (counter_threshold >= 4)) begin
			if (($signed(y_delay_reg[15:0]) >= $signed(16'd0)) && ($signed(y_delay_reg[31:16]) < $signed(16'd0))) begin
			     trigger_crossover <= 1'b1;
			end
		end
	end

	/// A partir de aqui es experimental 

	//always @(posedge clk) begin
	//	if(reset_reg || (counter_threshold_mod >= 4000)) begin    
    //        threshold_ride <= 16'b0;
    //        threshold_signal <= 1'b0;
    //    end else if((y_overshoot > threshold_reg) && ~threshold_signal && trigger_reg) begin
    //        threshold_ride <= y_overshoot;
    //        threshold_signal <= 1'b1;
    //    end 
    //end

    //always @(posedge clk) begin
    //	if (reset_reg || ~threshold_signal) begin
    //		threshold_reg <= threshold;
    //    end else if(threshold_signal) begin
    //        threshold_reg <= -$signed(y_shifted[(5*16-1) : (5*16-1) - 15 ]) + threshold_ride;
    //   end 
    //end

    //always @(posedge clk) begin
   	//    if(reset_reg) begin
    //        counter_threshold_mod <= 16'b0;
    //     end else if(threshold_signal && (counter_threshold_mod < 4000)) begin
    //        counter_threshold_mod <= counter_threshold_mod + 1'b1;
    //    end else if(threshold_signal && (counter_threshold_mod >= 4000)) begin
    //        counter_threshold_mod <= 16'b0;
    //    end
    // end

    /// End experimental 

  assign w1 = {x_i,9'b0};
  //assign w1 = {1'b0,x_i[13:0],10'b0};
  assign w2 = n1;
  assign w3 = (w1*w2);
  assign w4 = x_1;
  assign w20 = n2;
  assign w5 = (w4*w20);
  assign w7 = x_2;
  assign w8 = n3;
  assign w9 = (w7*w8);
  assign w6 = w3 + w5;
  assign w10 = w6 + w9;
  assign w11 = w19 + w10;
  assign w12 = w11[39:15];
  //assign w12 = w11[40:15];
  assign w13 = y_1;
  assign w14 = d1;
  assign w15 = y_2;
  assign w16 = d2;
  assign w17 = (w15*w16);
  assign w18 = (w13*w14);
  assign w19 = w18 + w17;
  assign mult1 = {en_mux,9'b0};
  assign mult2 = 18'b010011001100110011; // 
  assign s_fraction_mult = mult1*mult2;
  assign s_fraction = s_fraction_mult[41:26];
  assign y = (output_selector == 1'b0) ?   en_mux : 
             (output_selector == 1'b1) ?   y_delay_reg[15:0] :
             16'bx;
  assign resta_wire = resta;
  assign y_shifted_w = y_shifted[(shift_delay*16-1) : (shift_delay*16-1) - 15 ];
  assign trigger = trigger_reg;
endmodule