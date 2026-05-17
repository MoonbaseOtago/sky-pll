/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_sky_pll (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  	assign uio_out = uio_in & {7'b0, ena};
  	assign uio_oe  = 0;

	reg [3:0]r_reg_div;
	reg	 r_clk;
	always @(posedge clk) begin	// reference prescaler
		if (!rst_n) begin
			r_reg_div <= ui_in[7:4];
			r_clk <= 0;
		end else 
		if (r_reg_div == 0) begin
			r_reg_div <= ui_in[7:4];
			r_clk <= 1;
		end else begin
			r_reg_div <= r_reg_div-1;
			r_clk <= 0;
		end
	end
	wire refclk = ui_in[7:4]==0?clk:r_clk;

	wire	reset_output_n,		// reset generated when clock is running
		clk_result;		// generated clock

	reg [3:0]r_outdiv;		// divided down clock so we can measure jitter on external pins
	always @(posedge clk_result) begin
		if (!reset_output_n) begin
			r_outdiv <= 0;
		end else begin
			r_outdiv <= r_outdiv+1;
		end
		
	end

	assign uo_out = {2'b0,r_outdiv, reset_output_n, clk_result};

	pll pll(.RESET_N(rst_n),
`ifdef GL_TEST
            	.VPWR(VPWR), .VGND(VGND),
`endif
		.RESET_OUT_N(reset_output_n),
		.REFCLK(refclk),
		.COUNT_3(ui_in[3]),
		.COUNT_2(ui_in[2]),
		.COUNT_1(ui_in[1]),
		.COUNT_0(ui_in[0]),
		.CLK(clk_result));

endmodule
