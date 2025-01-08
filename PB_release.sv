module PB_release(input clk, input PB, input rst_n, output released);

	logic PB_ff1, PB_ff2, PB_ff3;

	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			PB_ff1 <= 0;
			PB_ff2 <= 0;
			PB_ff3 <= 0;
		end else begin
			PB_ff1 <= PB;
			PB_ff2 <= PB_ff1;
			PB_ff3 <= PB_ff2;
		end
	end

	assign released = PB_ff2 && ~PB_ff3;

endmodule
