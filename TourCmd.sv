module TourCmd(clk,rst_n,start_tour,move,mv_indx,
               cmd_UART,cmd,cmd_rdy_UART,cmd_rdy,
			   clr_cmd_rdy,send_resp,resp);

  input clk,rst_n;			// 50MHz clock and asynch active low reset
  input start_tour;			// from done signal from TourLogic
  input [7:0] move;			// encoded 1-hot move to perform
  output reg [4:0] mv_indx;	// "address" to access next move
  input [15:0] cmd_UART;	// cmd from UART_wrapper
  input cmd_rdy_UART;		// cmd_rdy from UART_wrapper
  output [15:0] cmd;		// multiplexed cmd to cmd_proc
  output cmd_rdy;			// cmd_rdy signal to cmd_proc
  input clr_cmd_rdy;		// from cmd_proc (goes to UART_wrapper too)
  input send_resp;			// lets us know cmd_proc is done with the move command
  output logic [7:0] resp;		// either 0xA5 (done) or 0x5A (in progress)


   logic mux_select;
   logic HorV; // 0 is Horizontal, 1 is vertical
   logic cmd_rdy_SM;
   logic mv_indx_rst;
   logic mv_indx_inc;

   logic [15:0] cmd_made;
   logic [3:0] opcode;
   logic [7:0] heading;
   logic [3:0] moves;

   typedef enum logic [2:0] {IDLE = 3'b000, SENDHORIZONTAL = 3'b001, HORIZONTAL = 3'b010, SENDVERTICAL = 3'b011, VERTICAL = 3'b100} state_t;
   state_t state, nxt_state;

   always @(posedge clk, negedge rst_n)
	   if (!rst_n) state <= IDLE;
      else state <= nxt_state;



   always_comb begin
      nxt_state = state;
      HorV = 0;
      mux_select = 0;
      cmd_rdy_SM = 0;
      mv_indx_rst = 0;
      mv_indx_inc = 0;

      case(state)
         IDLE: begin
            if (start_tour) begin
               mux_select = 1;
               mv_indx_rst = 1;
               nxt_state = SENDHORIZONTAL;
            end
         end
         SENDHORIZONTAL: begin
            mux_select = 1;
            cmd_rdy_SM = 1;
            if (clr_cmd_rdy) begin
               nxt_state = HORIZONTAL;
            end
         end
         HORIZONTAL: begin
            mux_select = 1;
            if (send_resp) begin
               nxt_state = SENDVERTICAL;
            end
         end
         SENDVERTICAL: begin
            mux_select = 1;
            HorV = 1;
            cmd_rdy_SM = 1;
            if (clr_cmd_rdy) begin
               nxt_state = VERTICAL;

            end
         end
         VERTICAL: begin
            mux_select = 1;
            if (send_resp) begin
               if (mv_indx === 5'd24)
                  nxt_state = IDLE;
               else
                  nxt_state = SENDHORIZONTAL;
                  mv_indx_inc = 1;
            end
         end
         default: begin

         end
      endcase

   end

   /////////////////////////////
   /////////// MUX /////////////
   /////////////////////////////

   assign cmd = mux_select ? cmd_made : cmd_UART;
   assign cmd_rdy = mux_select ? cmd_rdy_SM : cmd_rdy_UART;

   //////////////////////////////////////
   //////////move_index control//////////
   //////////////////////////////////////

   always_ff @(posedge clk, negedge rst_n) begin
      if(!rst_n)
         mv_indx <= '0;
      else if(mv_indx_rst)
         mv_indx <= '0;
      else if(mv_indx_inc)
         mv_indx <= mv_indx + 5'b1;
      else
         mv_indx <= mv_indx;
   end

   //////////////////////////
   ////////// RESP //////////
   //////////////////////////

   always_comb begin
      if(!mux_select || (mv_indx === 5'd24))
         resp = 8'hA5;
      else
         resp = 8'h5A;
   end

   //////////////////////////////////////
   //////////move decomposition//////////
   //////////////////////////////////////

   assign cmd_made = {opcode, heading, moves};

   always_comb begin
      opcode = 4'h4;
      heading = 8'h00;
      moves = 4'h0;
      case(move)
         8'h01:begin
            if(HorV)begin
               //Vertical cmd to move north 2 squares
               opcode = 4'h5;
               heading = 8'h00;
               moves = 4'h2;
            end
            else begin
               // Horizontal cmd to move  east 1 square
               opcode = 4'h4;
               heading = 8'hBF;
               moves = 4'h1;
            end
         end
         8'h02:begin
            if(HorV) begin
               //Vertical cmd to move north 2 squares
               opcode = 4'h5;
               heading = 8'h00;
               moves = 4'h2;
            end
            else begin
               // Horizontal cmd to move west 1 square
               opcode = 4'h4;
               heading = 8'h3F;
               moves = 4'h1;
            end
         end
         8'h04:begin
            if(HorV)begin
               //Vertical cmd to move north 1 square
               opcode = 4'h5;
               heading = 8'h00;
               moves = 4'h1;
            end
            else begin
               // Horizontal cmd to move west 2 squares
               opcode = 4'h4;
               heading = 8'h3F;
               moves = 4'h2;
            end
         end
         8'h08:begin
            if(HorV)begin
               //Vertical cmd to move south 1 square
               opcode = 4'h5;
               heading = 8'h7F;
               moves = 4'h1;
            end
            else begin
               // Horizontal cmd to move west 2 squares
               opcode = 4'h4;
               heading = 8'h3F;
               moves = 4'h2;
            end
         end
         8'h10:begin
            if(HorV)begin
               //Vertical cmd to move south 2 squares
               opcode = 4'h5;
               heading = 8'h7F;
               moves = 4'h2;
            end
            else begin
               // Horizontal cmd to move west 1 square
               opcode = 4'h4;
               heading = 8'h3F;
               moves = 4'h1;
            end
         end
         8'h20:begin
            if(HorV)begin
               //Vertical cmd to move south 2 squares
               opcode = 4'h5;
               heading = 8'h7F;
               moves = 4'h2;
            end
            else begin
               // Horizontal cmd to move east 1 square
               opcode = 4'h4;
               heading = 8'hBF;
               moves = 4'h1;
            end
         end
         8'h40:begin
            if(HorV)begin
               //Vertical cmd to move south 1 square
               opcode = 4'h5;
               heading = 8'h7F;
               moves = 4'h1;
            end
            else begin
               // Horizontal cmd to move  east 2 squares
               opcode = 4'h4;
               heading = 8'hBF;
               moves = 4'h2;
            end
         end
         8'h80:begin
            if(HorV)begin
               //Vertical cmd to move north 1 square
               opcode = 4'h5;
               heading = 8'h00;
               moves = 4'h1;
            end
            else begin
               // Horizontal cmd to move  east 2 squares
               opcode = 4'h4;
               heading = 8'hBF;
               moves = 4'h2;
            end
         end
         default:begin //should not get here but it will move nowhere if it does
            opcode = 4'h4;
            heading = 8'h00;
            moves = 4'h0;
         end
      endcase
   end




endmodule