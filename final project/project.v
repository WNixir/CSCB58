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

module datapath
	(
	input resetN,
	input clk,
	input ld_x,ld_y,drw,update_temp,update_grid,update_single,
	input [6:0]xy_position,
	input [8:0]dataIn,
	output [7:0]x,
	output [6:0]y,
	output [2:0]colour
	);
	//change this if pixels dont 1 to 1 correspond with cells
	localparam  GridSize = 6'd63,
				ColumnSize = 5'd8,
				RowSize = 5'd8,
				Crowded = 5'd4,
				Birth = 5'd3,
				Lonely = 5'd1;
	reg [GridSize:0] current_cells;
	reg [GridSize:0] temp_cells;
	
	always@(posedge clk)
	begin
		if(drw)
		begin
			x=xy_position[6:4];
			y=xy_position[3:0];
			//if its black colour it dead
			if(current_cells[xy_position])
				colour=3'b100;
			else
				colour=3'b000;
		end
		if(update_single)
		begin
			current_cells[{x,y}] = ^current_cells[{x,y}]; //toggle the currently selected cell
		end
		if (update_grid)
		begin
			current_cells[xy_position] = temp_cells[xy_position]; //update the cell from the temp_grid
		end
		if(update_temp) //update the current cell's temp flipflop
		begin
			int neighbourvalue = (current_cells[xy_position-1%GridSize]+
				current_cells[xy_position+1%GridSize]+
				current_cells[xy_position+RowSize%GridSize]+
				current_cells[xy_position-RowSize%GridSize]);//sum the status of all the neighbours
			if(current_cells[xy_position])
			begin
				temp_cells[xy_position] = ^((
				Crowded<= neighbourvalue)|(
				Lonely>=neighbourvalue
				));//kill it if its overcrowded or lonely
			end
			else
			begin
				temp_cells[i]= neighbourvalue >= Birth; // if there are enough neighbours create a new cell
			end
		end
	end
	
	//store the x/y values of the current cell
	reg [3:0]x;
	reg [3:0]y;
	always@(posedge clk) begin
        if(!resetn) begin
           x <= 4'b0;
		   y <= 4'b0;
        end
        else begin
            if(ld_x)
                x <= dataIn[3:0];
            if(ld_y)
                y <= dataIn[3:0];
        end
    end
	
endmodule

module control
	(
		input resetN,
		input Enable,
		input go,
		input clk,
		output reg ld_x,ld_y,drw,update_temp,update_grid,update_single
		output [6:0]xy_position
	);
	reg current_state,next_state;
	localparam	S_Load_X = 5'd0,
				S_Load_X_Wait = 5'd1,
				S_Load_Y = 5'd2,
				S_Load_Y_Wait = 5'd3,
				S_Cell_Toggle = 5'd4,
				S_Draw = 5'd5, //draw one pass on the whole screen
				S_Update_Temp = 5'd6, //update the temporary grid that is underneath the actual board
				S_Update_Cells = 5'd7, //update the board from the the temporary grid
				S_Draw_Wait = 5'd8; 
	
	always@(*)
	begin: state_table
		case (current_state)
			S_Load_X: next_state = go ? S_Load_X_Wait : S_Load_X;
			S_Load_X_Wait: next_state = go ? S_Load_X_Wait : S_Load_Y;
			S_Load_Y: next_state = go ? S_Load_Y_Wait : S_Load_Y;
			S_Load_Y_Wait: next_state = go ? S_Load_Y_Wait : S_Cell_Toggle;
			S_Cell_Toggle: next_state = S_Draw;
			S_Draw: begin
				if(Enable & Completed)
					next_state = S_Update_Temp; //If the board is in run mode don't go to the wait step
				else
					next_state = (go & Completed) ? S_Draw_Wait : S_Draw; //if the board is in load mode go to the wait step
			end
			S_Draw_Wait: next_state = go ? S_Draw_Wait : S_Load_X; //go to the next load on button release
			S_Update_Temp: next_state = Completed ? S_Update_Cells : S_Update_Temp; //if the circuit has updated all cells then proceed
			S_Update_Cells: next_state = Completed ? S_Draw : S_Update_Cells; // if the circuit has updated all cells then proceed
			default: next_state = S_Load_X;
		endcase
	end
	
	wire Completed;
	reg run_counter;
	alt_counter update_timer #(6) 
	(
	.Enable(run_counter),
	.clock(clk),
	.q(xy_position),
	.d(7'b1000000),//fill this in with the correct value
	.Clear_b(Completed), //clear the value whenever completed is run
	.ParLoad(1'b0)
	);
	
	assign Completed <= (xy_position == 7'b1000000); //wire for if the counter has capped out
	
	always@(*)
	begin: enable_signals
		//default all signals to 0
		ld_x=1'b0; //load x
		ld_y=1'b0; //load y
		drw=1'b0; //should draw
		update_temp=1'b0; //should updated the temp grid
		update_grid=1'b0; //should update the current grid
		run_counter=1'b0; //should be using the counter to delay state transitions
		update_single=1'b0;
		case(current_state)
			S_Load_X: begin
			ld_x=1'b1;
			end
			S_Load_Y: begin
			ld_y=1'b1;
			end
			S_Draw: begin
			drw=1'b1;
			run_counter=1'b1;
			end
			S_Draw_Wait: begin
			drw=1'b1;
			run_counter=1'b1;
			end
			S_Update_Temp: begin
			update_temp=1'b1;
			run_counter=1'b1;
			end
			S_Update_Cells: begin
			update_grid=1'b1;
			run_counter=1'b1;
			end
			S_Cell_Toggle: begin
			update_single=1'b1;
			end
		endcase
	end
	
	//update state registers
	always@(posedge clk)
	begin: state_FF
		if(!resetN)
			current_state<=S_Load_X;
		else
			current_state<=next_state;
	end
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

