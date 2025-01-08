module cmd_proc(clk, rst_n, cmd, cmd_rdy, clr_cmd_rdy, send_resp, tour_go, heading,
    heading_rdy, strt_cal, cal_done, moving, lftIR, cntrIR, rghtIR,
    fanfare_go, frwrd, error);

    //Clk, rst_n
    input clk, rst_n;

    //UART_Wrapper
    input logic [15:0] cmd;
    input cmd_rdy;
    output logic clr_cmd_rdy, send_resp;

    //To TourLogic/TourCmd
    output logic tour_go;

    //To/from iner_intf
    input logic [11:0] heading;
    input heading_rdy;
    output logic strt_cal;
    input cal_done;
    output logic moving;

    //From IR sensors
    input lftIR, cntrIR, rghtIR;

    //To Spongebob
    output logic fanfare_go;

    //To PID
    output logic [9:0] frwrd;
    output logic signed [11:0] error;

    ///Fast Sim Param
    parameter FAST_SIM = 1;

    logic [3:0] line_cntr;
    logic [2:0] numSquares;
    logic [3:0] numShifted;
    logic cntrIR_flop, cntrIR_rise, move_done;

    //Map commands to logic signals
    logic move_cmd; assign move_cmd = (cmd[15:12] === 4'b0100) && cmd_rdy;
    logic cal_cmd; assign cal_cmd = (cmd[15:12] === 4'b0010) && cmd_rdy;
    logic fan_cmd; assign fan_cmd = (cmd[15:12] === 4'b0101) && cmd_rdy;
    logic tour_cmd; assign tour_cmd = (cmd[15:12] === 4'b0110) && cmd_rdy;

    //logic for holding fanfare
    logic fanfare;

    /////////////STATE MACHINE LOGIC/////////////
    typedef enum logic [2:0] {IDLE, INIT, TOUR, MOVEWAIT, RAMPUP, RAMPDOWN, MOVEDELAY} state_t;
    state_t state;
    state_t nextState;

    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n) state <= IDLE;
        else state <= nextState;

    logic clr_frwrd, dec_frwrd, inc_frwrd;

    //always comb for state machine
    always_comb begin
        //initialize output values to zero
        clr_frwrd = 0;
        dec_frwrd = 0;
        inc_frwrd = 0;
        fanfare_go = 0;
        tour_go = 0;
        strt_cal = 0;
        send_resp = 0;
        moving = 0;
        nextState = state;
        clr_cmd_rdy = 0;

        case (state)
          IDLE: begin
            //Wait for a command
            if (cal_cmd) begin nextState = INIT; strt_cal = 1; clr_cmd_rdy = 1; end
            else if (move_cmd) begin nextState = MOVEDELAY; clr_frwrd = 1; clr_cmd_rdy = 1; end
            else if (fan_cmd) begin nextState = MOVEDELAY; clr_frwrd = 1; clr_cmd_rdy = 1; end
            else if (tour_cmd) begin nextState = TOUR; clr_cmd_rdy = 1; end

          end

          //Wait for calibration and then begin moving
          INIT: if (cal_done) begin
              nextState = IDLE;
              send_resp = 1;
            end

          //Use tour logic to move gyro
          TOUR: begin
            tour_go = 1;
            nextState = IDLE;
          end

          //Delay so error can be calculated before ramping up
          MOVEDELAY: begin
            nextState = MOVEWAIT;
          end

          //Wait for error to be small enough to start ramping up
          MOVEWAIT: begin
            if (error < $signed(12'h02C) && error > $signed(12'hFD4)) begin                
              nextState = RAMPUP;
            end
            moving = 1;
          end

          //Wait for move_done to be asserted and then slow down
          RAMPUP: if (move_done) begin
                nextState = RAMPDOWN;
                moving = 1;
            end else begin
              //Ramp up frwrd (increment) till saturated at max_spd and count squares
              inc_frwrd = 1;
              moving = 1;
            end

          //Rampdown until completely stopped
          RAMPDOWN: if (~(|frwrd)) begin //Wait until movement is stopped
              nextState = IDLE;
              if (fanfare) fanfare_go = 1; //Play fanfare if the fanfare command was given
              send_resp = 1;
              moving = 1;
            end else begin
              dec_frwrd = 1;
              moving = 1;
            end

        endcase
    end

    /////////// Fanfare Flip-Flop ///////////
    always_ff@(posedge clk, negedge rst_n)
      if (!rst_n)
        fanfare <= 1'b0;
      else if (cmd_rdy)
        fanfare <= fan_cmd; //assign fanfare to 0 or 1 depending on if the new command is of type fanfare
      else 
        fanfare <= fanfare;


    ///////////FRWRD REGISTER//////////////
    logic en, zero, max_spd;
    logic signed [7:0] add_term;

    assign zero = (frwrd === 10'h000) && dec_frwrd;

    assign max_spd = (&frwrd[9:8]) && inc_frwrd;

    assign en = (heading_rdy) ? ((zero | max_spd) ? 1'b0 : 1'b1) : 1'b0;      //enable signal for if frwrd should be changed                                   

    //term added to frwrd based on if gyro should speed up or slow down
    assign add_term = (inc_frwrd) ? ((FAST_SIM) ? 8'h20 : 8'h03) : ((dec_frwrd) ? ((FAST_SIM) ? $signed(-8'h40) : $signed(-8'h06)) : 8'h00);

    always_ff @(posedge clk, negedge rst_n)
      if (!rst_n)
        frwrd <= 10'h000;
      else if (clr_frwrd)
        frwrd <= 10'h000;
      else if (en)
        frwrd <= frwrd + add_term;
      else
        frwrd <= frwrd;

    /////////////PID INTERFACE////////////

    logic [11:0] err_nudge;
    logic [11:0] desired_heading, cmd_append;

    assign cmd_append = |cmd[11:4] ? {cmd[11:4], 4'hF} : {cmd[11:4], 4'h0};

    //Desired heading flip-flop
    always_ff @(posedge clk, negedge rst_n) begin
      if(!rst_n)
        desired_heading <= '0;
      else if(move_cmd | fan_cmd)
        desired_heading <= cmd_append;
      else
        desired_heading <= desired_heading;
    end

    //Calculate nudges if sensor reads
    always_comb begin
      if(!FAST_SIM) begin
        if(lftIR)
          err_nudge = 12'h05F;
        else if(rghtIR)
          err_nudge = 12'hFA1;
        else
          err_nudge = 12'h000;
      end
      else begin
        if(lftIR)
          err_nudge = 12'h1FF;
        else if(rghtIR)
          err_nudge = 12'hE00;
        else
          err_nudge = 12'h000;
      end
    end

    assign error = $signed(heading) - $signed(desired_heading) + $signed(err_nudge);                                    


    ///////////COUNTING SQUARES/////////////

    always_ff @(posedge clk, negedge rst_n) begin
      if (!rst_n) 
        cntrIR_flop <= 1'b0;
      else 
        cntrIR_flop <= cntrIR;
    end

    assign cntrIR_rise = (~cntrIR_flop && cntrIR);
    
    always_ff @(posedge clk, negedge rst_n) begin
      if (!rst_n) 
        line_cntr <= 0;
      else if (move_cmd | fan_cmd)
       line_cntr <= 0;
      else if (cntrIR_rise) 
        line_cntr <= line_cntr + 1;
    end

    always_ff @(posedge clk, negedge rst_n) begin
      if (!rst_n) 
        numSquares <= '0;
      else if (move_cmd | fan_cmd)  
        numSquares <= cmd[2:0];
    end

    assign numShifted = {numSquares, 1'b0};

    assign move_done = (numShifted === line_cntr);


endmodule
