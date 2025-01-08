module TourLogic_tb();

  reg clk,rst_n;
  reg go;

  logic [4:0] indx;
  logic [7:0] move;

  wire done;

  //////////////////////
  // Instantiate DUT //
  ////////////////////
  TourLogic iDUT(.clk(clk),.rst_n(rst_n),.x_start(3'h2),.y_start(3'h2),
                 .go(go),.done(done),.indx(indx),.move(move));

  initial begin
    clk = 0;
	rst_n = 0;
	go = 0;
	indx = 0;
	@(posedge clk);
	@(negedge clk);
	rst_n = 1;
	@(posedge clk);
	go = 1;
	@(posedge clk);
	go = 0;

	fork
	  begin: timeout
	    repeat(8000000) @(negedge clk);
		$display("ERR: timed out waiting for done");
		$stop();
	  end
	  begin
	    @(posedge done);
		disable timeout;
      end
	join

	for (indx = 4'b0; indx < 24; indx++) begin
		@(posedge clk);
		@(negedge clk);
		$display("Move: %h", move);
	end

    $display("YAHOO! Solution found!");
	$stop();

  end

  always
    #5 clk = ~clk;

  ////////////////////////////////////////////////////
  // Look inside DUT for position to update.  When //
  // it does print out state of board.  This is   //
  // very helpful in debug. Perhaps your internal//
  // signal is called different than update_position //
  ////////////////////////////////////////////////
//   always @(negedge iDUT.moveGo) begin: disp
//     integer x,y;
// 	for (y=4; y>=0; y--) begin
// 	    $display("%2d  %2d  %2d  %2d  %2d\n",iDUT.board[0][y],iDUT.board[1][y],
// 		         iDUT.board[2][y],iDUT.board[3][y],iDUT.board[4][y]);
// 	end
// 	$display("--------------------\n");
//   end

endmodule