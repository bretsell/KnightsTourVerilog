module sponge_tb();


    logic clk, rst_n, go, piezo, piezo_n;

    sponge dut (.clk(clk), .rst_n(rst_n), .go(go), .piezo(piezo), .piezo_n(piezo_n));


    // Clock generation
    always #5 clk = ~clk;

    initial begin
        clk =0;
        rst_n = 0;
        go = 0;

        // Reset DUT
		@(posedge clk);
        @(negedge clk);
		rst_n = 1'b1;

        go = 1;
        @(posedge clk);
		go = 0;

        repeat(2500000) @(posedge clk);

		$stop();
    end
endmodule
