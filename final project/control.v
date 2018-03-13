
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