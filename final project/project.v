// Part 2 skeleton

module project
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,					//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   							//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
	
	wire ld_x,ld_y,update_temp,update_grid,update_single;
	wire [6:0] xy_position;
    //Instantiate datapath
	datapath d0(
	.resetN(SW[10]),
	.clk(CLOCK_50),
	.ld_x(ld_x),
	.ld_y(ld_y),
	.drw(writeEn),
	.update_temp(),
	.update_grid(),
	.update_single(),
	.x(x),
	.y(y),
	.colour(colour)
	);
	
	//Instantiate control
    control c0(
	.resetN(SW[10]),
	.Enable(SW[9]),
	.go(KEY[0]),
	.clk(CLOCK_50),
	.ld_x(ld_x),
	.ld_y(ld_y),
	.drw(writeEn),
	.update_grid(update_grid),
	.update_temp(update_temp),
	.update_single(update_single),
	.xy_position(xy_position)
	);
 
endmodule




module alt_counter #(parameter size=4)(Enable,q,d,Clear_b,ParLoad,clock);
input Enable,Clear_b,clock,ParLoad;
input [size:0] d;
output reg [size:0] q; // declare q
always @(posedge clock) // triggered every time clock rises
begin
	if (Clear_b == 1'b0) // when Clear b is 0
		q <= 0; // q is set to 0
	else if (ParLoad == 1'b1) // Check if parallel load
		q <= d; // load d
	else if ((q) == d) // when q is the max value
		q <= 16'b0; // q reset to 0
	else if (Enable == 1'b1) // increment q only when Enable is 1
		q <= q + 1'b1; // increment q
end
endmodule

