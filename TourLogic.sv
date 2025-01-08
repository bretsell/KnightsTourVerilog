module TourLogic(clk,rst_n,x_start,y_start,go,done,indx,move);

  input clk,rst_n;				// 50MHz clock and active low asynch reset
  input [2:0] x_start, y_start;	// starting position on 5x5 board
  input logic go;						// initiate calculation of solution
  input [4:0] indx;				// used to specify index of move to read out
  output logic done;			// pulses high for 1 clock when solution complete
  output logic [7:0] move;			// the move addressed by indx (1 of 24 moves)

  ////////////////////////////////////////
  // Declare needed internal registers //
  //////////////////////////////////////

  //<< some internal registers to consider: >>
  //<< These match the variables used in knightsTourSM.pl >>
  reg [4:0] board[0:4][0:4];				// keeps track if position visited
  reg [7:0] last_move[0:23];		// last move tried from this spot
  //reg [7:0] poss_moves[0:23];		// stores possible moves from this position as 8-bit one hot
  reg [7:0] move_try;				// one hot encoding of move we will try next
  reg [4:0] move_num;				// keeps track of move we are on
  reg [2:0] xx,yy;					// current x & y position

  //Bits 0 for xx and yy
  //Bits 4, 3, and 0 for movenum

  /*
  << 2-D array of 5-bit vectors that keep track of where on the board the knight
     has visited.  Will be reduced to 1-bit boolean after debug phase >>
  << 1-D array (of size 24) to keep track of last move taken from each move index >>
  << 1-D array (of size 24) to keep track of possible moves from each move index >>
  << move_try ... not sure you need this.  I had this to hold move I would try next >>
  << move number...when you have moved 24 times you are done.  Decrement when backing up >>
  << xx, yy couple of 3-bit vectors that represent the current x/y coordinates of the knight>>
  */

  //<< below I am giving you an implementation of the one of the register structures you have >>
  //<< to infer (board[][]).  You need to implement the rest, and the controlling SM >>
  ///////////////////////////////////////////////////
  // The board memory structure keeps track of where
  // the knight has already visited.  Initially this
  // should be a 5x5 array of 5-bit numbers to store
  // the move number (helpful for debug).  Later it
  // can be reduced to a single bit (visited or not)
  ////////////////////////////////////////////////
  logic zero, init, moveBackup, checkNext, calcDone;
  logic moveGo, move_en;

  typedef enum reg [1:0] {IDLE, MOVE, DONE} action;

  action state, next_state;

  always_ff @(posedge clk) begin
    if (init) begin
      xx <= x_start;
      yy <= y_start;
    end
    else if (moveGo) begin
      xx <= xx + off_x(move_try);
      yy <= yy + off_y(move_try);
    end
    else if (moveBackup) begin
      xx <= xx - off_x(last_move[move_num - 2]);
      yy <= yy -  off_y(last_move[move_num - 2]);
    end
    else begin
      xx <= xx;
      yy <= yy;
    end
  end

  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)begin
      move_try <= 1;
    end
    else if (init) begin
      move_try <= 1;
    end
    else if (moveGo) begin
      move_try <= 1;
    end
    else if (moveBackup) begin
      move_try <= last_move[move_num - 2] << 1;
    end
    else if (checkNext)begin
      move_try <= move_try << 1;
    end
    else begin
      move_try <= move_try;
    end
  end

  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)begin
      board <= '{'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0}};
    end
    else if (init) begin
      board <= '{'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0}};
    end
    else if (moveGo) begin
      board[xx][yy] <= move_num;
    end
    else if (moveBackup) begin
      board[xx][yy] <= 5'h0;
    end
    else if (calcDone) begin
      board[xx][yy] <= move_num + 1;
    end
    else begin
      board <= board;
    end
  end

  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)begin
      move_num <= 1;
    end
    else if (init) begin
      move_num <= 1;
    end
    else if (moveGo) begin
      move_num <= move_num + 1;
    end
    else if (moveBackup) begin
      move_num <= move_num - 1;
    end
    else begin
      move_num <= move_num;
    end
  end

  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)begin
      last_move <= '{default: '0};
    end
    else if (init) begin
      last_move <= '{default: '0};
    end
    else if (moveGo) begin
      last_move[move_num-1] <= move_try;
    end
    else if (calcDone) begin
      last_move[move_num-1] <= move_try;
    end
    else begin
      last_move <= last_move;
    end
  end

  // always_ff @(posedge clk, negedge rst_n) begin
  //   if (~rst_n) begin
  //     //all_moves <= '0;
  //     // xx <= x_start;
  //     // yy <= y_start;
  //     //move_try <= 1;
  //     //board <= '{'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0}};
  //     //move_num <= 1;
  //   end
  //   else if (init) begin //Starting position, move_try is 1, board is all 0s as we only update if we can find a move from the current position
  //     // xx <= x_start;
  //     // yy <= y_start;
  //     //move_try <= 1;
  //     //board <= '{'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0},'{0,0,0,0,0}};
  //     //move_num <= 1;
  //   end else if (moveGo) begin //Move is possible from current xx and yy
  //     // xx <= xx + off_x(move_try);
  //     // yy <= yy + off_y(move_try);
  //     //move_num <= move_num + 1;
  //     last_move[move_num-1] <= move_try;
  //     //move_try <= 1;
  //     //board[xx][yy] <= move_num;
  //   end else if (moveBackup) begin
  //     //move_num <= move_num - 1; //If we backup we have to mark the last move as unvisited
  //     // xx <= xx - off_x(last_move[move_num - 2]);
  //     // yy <= yy -  off_y(last_move[move_num - 2]);
  //     //move_try <= last_move[move_num - 2] << 1;
  //     //board[xx][yy] <= 5'h0;
  //   end else if (checkNext) begin
  //     //move_try <= move_try << 1;
  //   end else if (calcDone) begin //Finished with it, just mark the current square and be done with it
  //     //board[xx][yy] <= move_num + 1;
  //     last_move[move_num-1] <= move_try; //This could be wrong
  //   end
  // end

assign move = last_move[indx];

  always @(posedge clk, negedge rst_n)
    if (!rst_n) state <= IDLE;
    else state <= next_state;

  always_comb begin
    init = 0;
    zero = 0;
    moveGo = 0;
    moveBackup = 0;
    checkNext = 0;
    done = 0;
    calcDone = 0;
    next_state = state;

    case(state)
      IDLE: begin
        if (go) begin
          next_state = MOVE;
          init = 1;
        end
      end

      MOVE: begin
        //get list of possible moves
        if (move_num === 25) begin
          calcDone = 1;
          next_state = DONE;
        end else if (move_try === 0) begin //No possible moves in current position
          moveBackup = 1;
        end else if (|(calc_poss(xx, yy) & move_try)) begin //We can take the current move
          moveGo = 1;
        end else begin //We can't take the current move, check the next one
          checkNext = 1;
        end
      end

      DONE: begin
        done = 1;
        next_state = IDLE;
      end

      default: next_state = IDLE;
    endcase
  end


  // Returns a packed byte of
	// all the possible moves (at least in bound) moves given
	// coordinates of Knight.
  // E.X. if moves 0 and 3 are possible 8'b00001001 is returned
  function [7:0] calc_poss(input logic [2:0] xpos, input logic [2:0] ypos);
    logic [7:0] move;
    move = 8'b00000000;
    if (xpos < 4 && ypos < 3 && board[xpos+1][ypos+2] === 0)
      move |= 8'b00000001;
    if (xpos >= 1 && ypos < 3 && board[xpos-1][ypos+2] === 0)
      move |= 8'b00000010;
    if (xpos >= 2 && ypos < 4 && board[xpos-2][ypos+1] === 0)
      move |= 8'b00000100;
    if (xpos >= 2 && ypos >= 1 && board[xpos-2][ypos-1] === 0)
      move |= 8'b00001000;
    if (xpos >= 1 && ypos >= 2 && board[xpos-1][ypos-2] === 0)
      move |= 8'b00010000;
    if (xpos < 4 && ypos >= 2 && board[xpos+1][ypos-2] === 0)
      move |= 8'b00100000;
    if (xpos < 3 && ypos >= 1 && board[xpos+2][ypos-1] === 0)
      move |= 8'b01000000;
    if (xpos < 3 && ypos < 4 && board[xpos+2][ypos+1] === 0)
      move |= 8'b10000000;
    return move;
  endfunction

  // Returns a the x-offset
	// the Knight will move given the encoding of the move you
	// are going to try.  Can also be useful when backing up
	// by passing in last move you did try, and subtracting
	// the resulting offset from xx
  function signed [2:0] off_x(input [7:0] try);
    ///////////////////////////////////////////////////
	/////////////////////////////////////////////////////
    logic signed [2:0] val;

    if (try & 8'h01) val = 1;
    else if (try & 8'h02) val = -1;
    else if (try & 8'h04) val = -2;
    else if (try & 8'h08) val = -2;
    else if (try & 8'h10) val = -1;
    else if (try & 8'h20) val = 1;
    else if (try & 8'h40) val = 2;
    else if (try & 8'h80) val = 2;
    else val = 0;

    return val;

  endfunction

  // Returns a the y-offset
	// the Knight will move given the encoding of the move you
	// are going to try.  Can also be useful when backing up
	// by passing in last move you did try, and subtracting
	// the resulting offset from yy
  function signed [2:0] off_y(input [7:0] try);
  logic signed [2:0] val;

    //Returns the first case found, starting at index 0
    if (try & 8'h01) val = 2;
    else if (try & 8'h02) val = 2;
    else if (try & 8'h04) val = 1;
    else if (try & 8'h08) val = -1;
    else if (try & 8'h10) val = -2;
    else if (try & 8'h20) val = -2;
    else if (try & 8'h40) val = -1;
    else if (try & 8'h80) val = 1;
    else val = 0;
    return val;
  endfunction

endmodule


