module SPI_mnrch (
  input clk, rst_n, MISO, snd,
  input [15:0] cmd,
  output logic done, SS_n,
  output SCLK, MOSI,
  output [15:0] resp
);

logic init, shift, full, done16, ld_SCLK, set_done;

logic [15:0] shift_reg, shift_reg2;

logic [4:0] bit_cntr, SCLK_div;

////// State Machine //////
typedef enum logic [1:0] {idle = 2'b00, shifting = 2'b01, finish = 2'b10} state_t;
state_t state, nxt_state;

always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    state <= idle;
  else
    state <= nxt_state;
end

always_comb begin
  nxt_state = state;
  ld_SCLK = 0;
  init = 0;
  set_done = 0;
  case(state)
    idle : begin
      ld_SCLK = 1;
      if(snd) begin
        init = 1;
        nxt_state = shifting;
      end
    end
    shifting : begin
      if(done16) begin
        nxt_state = finish;
      end
    end
    finish : begin
      if(full) begin
        ld_SCLK = 1;
        set_done = 1;
        nxt_state = idle;
      end
    end
    default : begin
      nxt_state = state;
    end
  endcase
end

//done flip flop
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    done <= 1'b0;
  else if (init)
    done <= 1'b0;
  else if (set_done)
    done <= 1'b1;
  else
    done <= done;
end


//SS_n flip flop
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    SS_n <= 1'b1;
  else if (init)
    SS_n <= 1'b0;
  else if (set_done)
    SS_n <= 1'b1;
  else
    SS_n <= SS_n;
end

////// Bit Counter //////
always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n)
    bit_cntr <= 0;
  else if(init)
    bit_cntr <= '0;
  else if(shift)
    bit_cntr <= bit_cntr + 5'b1;
  else
    bit_cntr <= bit_cntr;
end

assign done16 = (bit_cntr == 5'b10000);

////// SCLK //////
always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n)
    SCLK_div <= 5'b10111;
  else if(ld_SCLK)
    SCLK_div <= 5'b10111;
  else
    SCLK_div <= SCLK_div + 5'b1;
end

assign SCLK = SCLK_div[4];

assign shift = SCLK_div === 5'b10001;

assign full = &SCLK_div;

////// Shift Register //////

always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    shift_reg <= '0;
  else if(init)
    shift_reg <= cmd;
  else if(shift)
    shift_reg <= {shift_reg[14:0], MISO};
  else
    shift_reg <= shift_reg;
end

assign MOSI = shift_reg[15];

assign resp = shift_reg;



endmodule
