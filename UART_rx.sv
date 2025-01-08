
module UART_rx(input clk, input rst_n, input RX, input clr_rdy, output [7:0] rx_data, output logic rdy);

	logic start, shift, receiving, set_rdy;
	logic [11:0] baud_cnt;
	logic [8:0] rx_shift_reg;
	logic [3:0] bit_cnt;
	logic RX_oneflop, RX_metastable;

	//state machine declaration
	typedef enum reg {idle, receiving_data} action;

	action state;
	action next_state;

	assign shift = (baud_cnt == 12'h000);

	assign rx_data = rx_shift_reg[7:0];

	//rx shift register flip flop
	always_ff@(posedge clk, negedge rst_n) begin
		if (~rst_n) rx_shift_reg <= 0;
		else if (shift)
			rx_shift_reg <= {RX_metastable, rx_shift_reg[8:1]};
		else
			rx_shift_reg <= rx_shift_reg;
	end


	//baud counter flip flop
	always_ff@(posedge clk, negedge rst_n)
		if (~rst_n) baud_cnt <= 0;
		else casex ({(start | shift), receiving})
			2'b1x: baud_cnt <= (start) ? 12'd1302 : 12'd2604;
			2'b01: baud_cnt <= baud_cnt - 12'b1;
			2'b00: baud_cnt <= baud_cnt;
		endcase

	//bit counter flip flop
	always_ff@(posedge clk, negedge rst_n)
		if (~rst_n) bit_cnt <= 0;
		else casex ({start, shift})
			2'b1x: bit_cnt <= 4'h0;
			2'b01: bit_cnt <= bit_cnt + 4'b1;
			2'b00: bit_cnt <= bit_cnt;
		endcase

	//SR flip flop for rdy
	always_ff@(posedge clk, negedge rst_n)
		if (!rst_n)
			rdy <= 1'b0;
		else if (start || clr_rdy)
			rdy <= 1'b0;
		else if (set_rdy)
			rdy <= 1'b1;

	//Flip flop for state machine
	always_ff@(posedge clk, negedge rst_n)
		if (!rst_n)
			state <= idle;
		else
			state <= next_state;

	//flip flop #1 for meta stable RX
	always_ff@(posedge clk, negedge rst_n)
		if (!rst_n)
			RX_oneflop <= 1'b1;
		else
			RX_oneflop <= RX;

	//flip flop #2 for meta stable RX
	always_ff@(posedge clk, negedge rst_n)
		if (!rst_n)
			RX_metastable <= 1'b1;
		else
			RX_metastable <= RX_oneflop;

	//next state logic and output of state machine
	always_comb begin
		next_state = idle;
		start = 0;
		receiving = 0;
		set_rdy = 0;

		case (state)

			//idle state declaration
			idle: if (!RX_metastable) begin
				next_state = receiving_data;
				start = 1;
				receiving = 0;
			end else begin
				next_state = idle;
				start = 0;
				receiving = 0;
			end

			//receiving data state declaration
			receiving_data: if (bit_cnt == 4'hA) begin
				next_state = idle;
				start = 0;
				receiving = 0;
				set_rdy = 1;
			end else begin
				next_state = receiving_data;
				start = 0;
				receiving = 1;
				set_rdy = 0;
			end

		endcase
	end
endmodule
