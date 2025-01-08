module rst_synch(input clk, input RST_n, output logic rst_n);

  logic Q1;

  //reset_synch logic
  always_ff@(negedge clk, negedge RST_n)
	if (!RST_n) begin
      Q1 <= 1'b0;
      rst_n <= 1'b0;
    end else begin
      Q1 <= 1'b1;
      rst_n <= Q1;
  end

endmodule