module day10 #(
 parameter int MAX_LIGHTS = 8,
 parameter int MAX_BUTTONS = 8
)(
	input logic clk,
	input logic rst,

	input logic [$clog2(MAX_LIGHTS+1)-1:0] i_n_lights,
	input logic [$clog2(MAX_BUTTONS+1)-1:0] i_n_buttons,
	
	input logic [MAX_BUTTONS:0] i_matrix [MAX_LIGHTS],

	output logic [31:0] o_num,
	output logic done,
	output logic [MAX_BUTTONS:0] o_rows [MAX_LIGHTS]
);

logic [$clog2(MAX_BUTTONS):0] col, idx_mask;
logic [$clog2(MAX_LIGHTS)-1:0] pivot, scan_row, elim_row, pivot_row;
logic pivot_found;

logic [MAX_BUTTONS:0] rows [MAX_LIGHTS];

logic [$clog2(MAX_BUTTONS)-1:0] pivot_cols [MAX_BUTTONS];
logic [$clog2(MAX_BUTTONS):0] n_pivot_cols;

enum logic[2:0]{IDLE, PIVOT_INIT, FIND_PIVOT, SWAP, ELIM_INIT, ELIM_ROW, NEXT_COL, DONE} state, n_state;
always_ff @(posedge clk or posedge rst) begin
	if (rst) begin
		state <= IDLE;
	end
	else begin
		state <= n_state;
	end
end


always_comb begin
	case(state)
		IDLE:
			n_state = PIVOT_INIT;
		PIVOT_INIT:
			n_state = FIND_PIVOT;
		FIND_PIVOT:
			n_state = pivot_found ? SWAP : NEXT_COL;
		SWAP:
			n_state = ELIM_INIT;
		ELIM_INIT:
			n_state = ELIM_ROW;
		ELIM_ROW:
			n_state = (elim_row == i_n_lights) ? NEXT_COL:ELIM_ROW;
		NEXT_COL: 
			n_state = (col == i_n_buttons) ? DONE: PIVOT_INIT;
		DONE:
			n_state = DONE;
	endcase
end

assign idx_mask =  1'b1 << (i_n_buttons - col);

assign done = (state == DONE);

always_ff @(posedge clk or posedge rst) begin
	if (rst) begin
		col <= 0;
		pivot_row <=0;
	end else begin
		case(state)
		IDLE:begin
			col <= 0;
			pivot_row <= 0;
		end
		NEXT_COL: begin
			col <= col + 1;
			if (pivot_found) begin
				pivot_row <= pivot_row + 1;
			end
		end
		endcase
	end
end

always_ff @(posedge clk) begin:find_pivot
	if(state == PIVOT_INIT) begin
		pivot_found <= 0;
		scan_row <= pivot_row;
	end else if (state == FIND_PIVOT && scan_row < i_n_lights) begin
		if ((rows[scan_row] & idx_mask) && !pivot_found) begin
			pivot_found <= 1'b1;
			pivot <= scan_row;
		end else begin
			scan_row <= scan_row + 1;
		end
			
	end
end

always_ff @(posedge clk) begin:elim
	if (state == ELIM_INIT) begin
		elim_row <= 0;
	end else if(state == ELIM_ROW) begin
		elim_row <= elim_row + 1;
	end
end

always_ff @(posedge clk) begin
	if(state == IDLE) begin
		for(int i = 0; i < MAX_LIGHTS; i++) begin
			rows[i] <= i_matrix[i];
		end
	end else if (state == SWAP && pivot_row != pivot) begin
		//temp_row <= rows[pivot_row];
    	rows[pivot_row] <= rows[pivot];
    	rows[pivot] <= rows[pivot_row];
    	//rows[pivot] <= temp_row;
	end else if (state == ELIM_ROW) begin
		if (elim_row != pivot_row && (rows[elim_row] & idx_mask)) begin
			rows[elim_row] <= rows[elim_row] ^ rows[pivot_row];
		end
	end
end

always_ff @(posedge clk)begin:check_elim
	if (state == DONE) begin
		for(int i = 0; i < MAX_LIGHTS; i++) begin
			o_rows[i] <= rows[i];
		end
	end
end





endmodule