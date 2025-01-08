
module PID(input signed [11:0] error, input clk, input rst_n, input err_vld, input moving, input [9:0] frwrd, output signed [10:0] lft_spd, output signed [10:0] rght_spd);

	//Overall logic signals
	logic signed [8:0] I_term, I_term_2;
	logic signed [10:0] frwrd_ext, lft_pre_sat, rght_pre_sat;
	logic signed [12:0] D_term, D_term_2;
	logic signed [13:0] PID, PID_2, P_SE, I_SE, D_SE, P_term, P_term_2;

	//More flops and flop signals so we can meet timing
	logic signed [11:0] error2;
	logic err_vld2;
	logic moving2;
	logic [9:0] frwrd2;

	//buffer flops for timing reasons
	always_ff @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			P_term_2 <= 0;
			I_term_2 <= 0;
			D_term_2 <= 0;
			PID <= 0;
			error2 <= 0;
			err_vld2 <= 0;
			moving2 <= 0;
			frwrd2 <= 0;
		end
		else begin
			P_term_2 <= P_term;
			I_term_2 <= I_term;
			D_term_2 <= D_term;
			PID <= PID_2;
			error2 <= error;
			err_vld2 <= err_vld;
			moving2 <= moving;
			frwrd2 <= frwrd;
		end
	end

	assign P_SE = {P_term_2[13], P_term_2[13:1]};

	assign I_SE = {{5{I_term_2[8]}}, I_term_2};

	assign D_SE = {D_term_2[12], D_term_2};

	assign frwrd_ext = {1'b0, frwrd2};

	assign PID_2 = P_SE + I_SE + D_SE;

	assign lft_pre_sat = (moving2) ? (PID[13:3] + frwrd_ext) : 11'h000;

	assign rght_pre_sat = (moving2) ? (frwrd_ext - PID[13:3]) : 11'h000;

	assign lft_spd = (~PID[13] & lft_pre_sat[10]) ? 11'h3FF : lft_pre_sat;

	assign rght_spd = (PID[13] & rght_pre_sat[10]) ? 11'h3FF : rght_pre_sat;

	//P term module
	logic signed [9:0] err_sat;
	parameter signed P_COEFF = 6'h10;

	assign err_sat = (error2[11] == 1 && (error2[10] == 0 || error2[9] == 0)) ? 10'b1000000000 : (error2[11] == 0 && (error2[10] == 1 || error2[9] == 1)) ? 10'b0111111111 : error2[9:0];

	assign P_term = P_COEFF * err_sat;


	//I term module
	logic signed [14:0] I_error, integrator, sum, muxOut, nxt_integrator;
	logic overflow, muxSelect;

	assign I_error = (err_sat[9] == 1) ? {5'b11111, err_sat[9:0]} : {5'b00000, err_sat[9:0]};

	assign sum = I_error + integrator;

	assign overflow = (I_error[14] == integrator[14] && sum[14] == ~I_error[14]) ? 1'b1 : 1'b0;

	and (muxSelect, ~overflow, err_vld2);

	assign muxOut = (muxSelect == 1) ? sum : integrator;

	assign nxt_integrator = (moving2 == 1) ? muxOut : 15'h0000;

	always_ff@(posedge clk, negedge rst_n)
		if(!rst_n)
			integrator <= 15'h0000;
		else
			integrator <= nxt_integrator;

	assign I_term = integrator[14:6];


	//D term module
	logic [9:0] q1, q2, prev_err;

	logic [9:0] D_diff;

	logic [7:0] D_diff_sat;

	localparam signed D_COEFF = 5'h07;

		//always block for the three flip flops
		always_ff@(posedge clk, negedge rst_n) begin
			if (!rst_n) begin
				q1 <= 10'h000;
				q2 <= 10'h000;
				prev_err <= 10'h000;
			end
			else if(err_vld2) begin
				q1 <= err_sat;
				q2 <= q1;
				prev_err <= q2;
			end
		end

	assign D_diff = err_sat - prev_err;

	//saturate D difference
	assign D_diff_sat = (D_diff[9] == 1 && (D_diff[8] == 0 || D_diff[7] == 0)) ? 8'h80 : (D_diff[9] == 0 && (D_diff[8] == 1 || D_diff[7] == 1)) ? 8'h7F : D_diff[7:0];

	//sign multiply by D_COEFF
	assign D_term = $signed(D_diff_sat) * $signed(D_COEFF);

endmodule