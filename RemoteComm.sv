
module RemoteComm(input clk, input rst_n, input [15:0] cmd, input send_cmd, input RX, output rx_rdy, output TX, output logic cmd_sent, output [7:0] rx_data);

	logic sel, trmt, tx_done, set_cmd_sent, clr_rx_rdy;
	logic [7:0] tx_data, cmd_low;

	//Instantiate UART module
	UART iUART(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .rx_rdy(rx_rdy), .clr_rx_rdy(clr_rx_rdy), .trmt(trmt), .tx_done(tx_done), .rx_data(rx_data), .tx_data(tx_data));

	assign tx_data = (sel) ? cmd[15:8] : cmd_low;

	typedef enum reg [1:0] {idle, send_high, send_low} action;

	action state, next_state;

	//flip flop for low bits of command
	always_ff@(posedge clk, negedge rst_n)
		if (~rst_n) cmd_low <= 0;
		else if (send_cmd)
			cmd_low <= cmd[7:0];
		else
			cmd_low <= cmd_low;


	//SR register for cmd_sent
	always_ff@(posedge clk, negedge rst_n)
		if (!rst_n)
			cmd_sent <= 1'b0;
		else if (send_cmd)
			cmd_sent <= 1'b0;
		else if (set_cmd_sent)
			cmd_sent <= 1'b1;

	//flip flop for state machine
	always_ff@(posedge clk, negedge rst_n)
		if (!rst_n)
			state <= idle;
		else
			state <= next_state;


	//combinational logic for state machine transitions and output
	always_comb begin
		next_state = state;
		sel = 0;
		trmt = 0;
		set_cmd_sent = 0;
		clr_rx_rdy = 0;

		case (state)

			//idle state declaration
			idle: if (send_cmd) begin
				next_state = send_high;
				sel = 1;
				trmt = 1;
				clr_rx_rdy = 1;
			end

			//send_high state declaration
			send_high: if (tx_done) begin
				next_state = send_low;
				trmt = 1;
			end else begin
				sel = 1;
				trmt = 1;
				clr_rx_rdy = 1;
			end

			//send_low state declaration
			send_low: if (tx_done) begin
				next_state = idle;
				set_cmd_sent = 1;
			end else begin
				trmt = 1;
			end

			default: next_state = idle;

		endcase
	end
endmodule


