
module UART_wrapper(input clk, input rst_n, input clr_cmd_rdy, input trmt, input RX, output TX, input [7:0] resp, output logic cmd_rdy, output [15:0] cmd, output tx_done);

	logic rx_rdy, clr_rx_rdy, mux_select, set_cmd_rdy;
	logic [7:0] rx_data, tx_data, Q;

	//instantiate UART
	UART iUART(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .rx_rdy(rx_rdy), .clr_rx_rdy(clr_rx_rdy), .trmt(trmt), .tx_done(tx_done), .rx_data(rx_data), .tx_data(resp));

	typedef enum reg {idle, shift} action;

	action state;
	action next_state;

	assign cmd = {Q, rx_data};

	//flip flop for byte storage
	always_ff@(posedge clk, negedge rst_n)
		if (~rst_n) Q <= '0;
		else if (mux_select)
			Q <= rx_data;

	//SR flop for cmd_rdy
	always_ff@(posedge clk, negedge rst_n)
		if (!rst_n)
			cmd_rdy <= 1'b0;
		else if (set_cmd_rdy)
			cmd_rdy <= 1'b1;
		else if (clr_cmd_rdy || mux_select)
			cmd_rdy <= 1'b0;

	//flip flop for state machine
	always_ff@(posedge clk, negedge rst_n)
		if (!rst_n)
			state = idle;
		else
			state = next_state;

	//combinational logic for state machine
	always_comb begin
		next_state = state;
		mux_select = 0;
		set_cmd_rdy = 0;
		clr_rx_rdy = 0;

		case (state)

			//idle state declaration
			idle: if (rx_rdy) begin
				next_state = shift;
				mux_select = 1;
				clr_rx_rdy = 1;
			end

			//shift state declaration
			shift: if (rx_rdy) begin
				next_state = idle;
				clr_rx_rdy = 1;
				set_cmd_rdy = 1;
			end

		endcase

	end

endmodule


