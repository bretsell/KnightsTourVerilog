
module UART_tx(input clk, input rst_n, input trmt, input [7:0] tx_data, output TX, output logic tx_done);

	logic init, shift, transmitting, set_done;
	logic [11:0] baud_cnt;
	logic [3:0] bit_cnt;
	logic [8:0] tx_shift_reg;

	//state machine declaration
	typedef enum reg {idle, processing} action;

	action state;
	action next_state;

	assign shift = (baud_cnt == 12'hA2C);

	assign TX = tx_shift_reg[0];

	//tx shift flip flop
	always_ff@(posedge clk, negedge rst_n)
		if (!rst_n)
			tx_shift_reg <= 9'h1FF;
		else begin
			casex ({init, shift})
				2'b1x: tx_shift_reg <= {tx_data, 1'b0};
				2'b01: tx_shift_reg <= {1'b1, tx_shift_reg[8:1]};
				2'b00: tx_shift_reg <= tx_shift_reg;
			endcase
		end

	//baud counter flip flop
	always_ff@(posedge clk, negedge rst_n)
		if (!rst_n)
			baud_cnt <= 12'h000;
		else begin
			casex ({(init | shift), transmitting})
				2'b1x: baud_cnt <= 12'h000;
				2'b01: baud_cnt <= baud_cnt + 12'b1;
				2'b00: baud_cnt <= baud_cnt;
			endcase
		end

	//bit counter flip flop
	always_ff@(posedge clk, negedge rst_n)
		if (!rst_n)
			bit_cnt <= 4'h0;
		else begin
			casex ({init, shift})
				2'b1x: bit_cnt <= 4'h0;
				2'b01: bit_cnt <= bit_cnt + 4'b1;
				2'b00: bit_cnt <= bit_cnt;
			endcase
		end

	//SR flip flop for tx_done
	always_ff@(posedge clk, negedge rst_n)
		if (!rst_n)
			tx_done <= 1'b0;
		else if (init)
			tx_done <= 1'b0;
		else if (set_done)
			tx_done <= 1'b1;

	//Flip flop for state machine
	always_ff@(posedge clk, negedge rst_n)
		if (!rst_n)
			state <= idle;
		else
			state <= next_state;

	//State machine logic
	always_comb begin
		next_state = idle;
		init = 0;
		transmitting = 0;
		set_done = 0;

		case (state)

			//idle state declaration
			idle: if (trmt) begin
				next_state = processing;
				init = 1;
				transmitting = 1;
			end else begin
				next_state = idle;
				init = 0;
				transmitting = 0;
			end

			//processing state declaration
			processing: if (bit_cnt == 4'hA) begin
				next_state = idle;
				init = 0;
				transmitting = 0;
				set_done = 1;
			end else begin
				next_state = processing;
				init = 0;
				transmitting = 1;
				set_done = 0;
			end
		endcase
	end

endmodule
