`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// University: UNIMIB 
// Engineer: Esteban Cristaldo, MSc
//
// Create Date: July 14, 2022, 11:53:42 AM
// Design Name: filtering_and_selftrigger
// Module Name: hpf_pedestal_recovery_filter_trigger.v
// Project Name: selftrigger@bicocca
// Target Devices: DAPHNE V2
//
//////////////////////////////////////////////////////////////////////////////////
module hpf_pedestal_recovery_filter_trigger(
	input wire clk,
	input wire reset,
	input wire enable,
    input wire signed [13:0] threshold_value,
    input wire [1:0] output_selector,
    output wire signed [15:0] baseline,
	input wire signed [15:0] x,
    output wire trigger_output,
	output wire signed [15:0] y
);
	
	wire signed [15:0] hpf_out;
    wire signed [15:0] movmean_out;
	wire signed [15:0] x_i;
    //wire signed [15:0] w_resta_out [4:0][7:0];
    wire signed [15:0] w_out;
	wire signed [15:0] resta_out, lpf_out;
	wire signed [15:0] suma_out;
    wire tm_output_selector;

    wire trigger_output_wire;

    (* dont_touch = "true" *) reg signed [13:0] threshold_level;

    always @(posedge clk) begin 
        if(reset) begin
           threshold_level <= $signed(256); // Same as DEFAULT_THRESHOLD
        end else if (enable) begin 
           threshold_level <= $signed(threshold_value);
        end
    end
    

    k_low_pass_filter lpf(
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .x(x_i),
        .y(lpf_out)
    );

    IIRFilter_afe_integrator_optimized hpf(
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .x(resta_out),
        .y(hpf_out)
    );

    IIRfilter_movmean25_cfd_trigger mov_mean_cfd(
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .output_selector(tm_output_selector),
        .threshold(threshold_level),
        .x(hpf_out),
        .trigger(trigger_output),
        .y(movmean_out)
    );

    assign resta_out =  (enable==0) ?   x_i : 
                        (enable==1) ?   (x_i - lpf_out) : 
                        16'bx; 
    
    assign suma_out = (enable==0) ?   hpf_out : 
                      (enable==1) ?   (hpf_out + lpf_out) : 
                      16'bx;


    assign w_out = (output_selector == 2'b00) ?   suma_out : 
                   (output_selector == 2'b01) ?   lpf_out + movmean_out : //movmean
                   (output_selector == 2'b10) ?   lpf_out + movmean_out : //movmean cfd
                   (output_selector == 2'b11) ?   x_i :
                   16'bx;
   

    assign x_i = x;
    assign y = w_out;

	
    assign tm_output_selector = (output_selector == 2'b00) ?   1'b0 : //hpf 
                                (output_selector == 2'b01) ?   1'b0 : //movmean
                                (output_selector == 2'b10) ?   1'b1 : //movmean cfd
                                (output_selector == 2'b11) ?   1'b0 : //unfiltered
                                 1'bx;

endmodule