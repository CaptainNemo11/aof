`define DIAL_NUMBER 100
`define DIAL_WIDTH 32
module day1 #(
	parameter int PASSWORD_WIDTH = 32
) (
	input logic clk,
	input logic rst,
	input logic i_dir,
	input logic part,
	input logic [`DIAL_WIDTH-1:0] i_dist,
	output logic[PASSWORD_WIDTH - 1 : 0] o_zero
);

logic signed [`DIAL_WIDTH-1:0] abs, n_abs;
logic [PASSWORD_WIDTH-1:0]hit_zero;


function automatic signed [`DIAL_WIDTH-1:0] floor_div_dial(input signed [`DIAL_WIDTH-1:0] x);
	if (x > 0)
	floor_div_dial = x / `DIAL_NUMBER;
	else
	floor_div_dial = -((-x + (`DIAL_NUMBER - 1))/`DIAL_NUMBER);
endfunction


always_comb begin 
	n_abs = abs;
	hit_zero = '0;

	if(i_dir == 1'b0) begin
		n_abs = abs - i_dist;
	end else begin
		n_abs = abs + i_dist;
	end

	if (part == 1'b0) begin
		hit_zero = (n_abs % `DIAL_NUMBER) == 0;
	end else begin
		if (n_abs > abs) begin
		   hit_zero = floor_div_dial(n_abs) - floor_div_dial(abs);
		end else if (n_abs < abs) begin
		   hit_zero = floor_div_dial(abs - 1) - floor_div_dial(n_abs - 1);
		end else begin
		   hit_zero = 0;
		end
	end
	
end
always_ff @(posedge clk or posedge rst) begin
	if (rst) begin
		o_zero <= 0;
		abs <= `DIAL_WIDTH'd50;
	end else begin
		abs <= n_abs;
		o_zero <= o_zero + hit_zero;
	end
end
endmodule

