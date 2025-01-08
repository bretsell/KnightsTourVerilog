module sponge (clk, rst_n, go, piezo, piezo_n);

input clk, rst_n, go;
output piezo, piezo_n;

parameter FAST_SIM = 1;

localparam SIZE = 23;

localparam D7 = 15'd21285, E7 = 15'd18960, F7 = 15'd17882, A6 = 15'd28409;

logic [4:0] incrementer;

generate
  if(FAST_SIM == 0)
     assign incrementer = 5'd1;
  else
     assign incrementer = 5'd16;
endgenerate

logic [SIZE:0] timer_dur;
logic [15:0] timer_freq;

logic dur_rst, freq, freq_rst;

typedef enum logic [3:0] {IDLE, ONE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT} state_t;
state_t state, nextState;

always @(posedge clk, negedge rst_n)
  if (!rst_n) 
    state <= IDLE;
  else 
    state <= nextState;

always_comb begin
  dur_rst = 0;
  freq_rst = 0;
  nextState = state;

  case(state)
      IDLE: begin
          if(go) begin
            nextState = ONE;
            dur_rst = 1;

          end
      end
      ONE: begin
          if (timer_freq == D7) begin
              freq_rst = 1;
          end
          if(timer_dur[SIZE]) begin
                nextState = TWO;
                dur_rst = 1;
          end
      end
      TWO: begin
          if (timer_freq == E7) begin
            freq_rst = 1;
          end
          if(timer_dur[SIZE]) begin
                nextState = THREE;
                dur_rst = 1;
          end
      end
      THREE: begin
          if (timer_freq == F7) begin
            freq_rst = 1;
          end
          if(timer_dur[SIZE]) begin
                nextState = FOUR;
                dur_rst = 1;
          end
      end
      FOUR: begin
          if (timer_freq == E7) begin
            freq_rst = 1;
          end
          if(timer_dur[SIZE] & timer_dur[SIZE-1]) begin
                nextState = FIVE;
                dur_rst = 1;
          end
      end
      FIVE: begin
          if (timer_freq == F7) begin
            freq_rst = 1;
          end
          if(timer_dur[SIZE-1]) begin
                nextState = SIX;
                dur_rst = 1;
          end
      end
      SIX: begin
          if (timer_freq == D7) begin
            freq_rst = 1;
          end
          if(timer_dur[SIZE] & timer_dur[SIZE-1]) begin
                nextState = SEVEN;
                dur_rst = 1;
          end
      end
      SEVEN: begin
          if (timer_freq == A6) begin
            freq_rst = 1;
          end
          if(timer_dur[SIZE-1]) begin
                nextState = EIGHT;
                dur_rst = 1;
          end
      end
      EIGHT: begin
          if (timer_freq == D7) begin
            freq_rst = 1;
          end
          if(timer_dur[SIZE]) begin
                nextState = IDLE;
                dur_rst = 1;
          end
      end
      default: nextState = IDLE;
  endcase
end

////////DURATION TIMER////////
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    timer_dur <= '0;
  else if(dur_rst)
    timer_dur <= '0;
  else
    timer_dur <= timer_dur + incrementer;
end

////////FREQUENCY TIMER////////
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    timer_freq <= '0;
  else if (freq_rst)
    timer_freq <= '0;
  else
    timer_freq <= timer_freq + 1;
end

////////FREQUENCY CLOCK////////
always_ff @(posedge clk, negedge rst_n) begin
  if(!rst_n)
    freq <= 1'b0;
  else if(freq_rst)
    freq <= ~freq;
  // else freq <= freq;
end

assign piezo = freq;
assign piezo_n = ~freq;

endmodule