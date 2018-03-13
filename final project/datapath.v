module datapath
	(
	input resetN,
	input clk,
	input ld_x,ld_y,drw,update_temp,update_grid,update_single,
	input [6:0]xy_position,
	input [8:0]dataIn,
	output reg [7:0]x,
	output reg [6:0]y,
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
