//////////////////////////////////////////////////////
// Interfaces with ST 6-axis inertial sensor.  In  //
// this application we only use Z-axis gyro for   //
// heading of robot.  Fusion correction comes    //
// from "gaurdrail" signals lftIR/rghtIR.       //
/////////////////////////////////////////////////
module inert_intf(clk,rst_n,strt_cal,cal_done,heading,rdy,lftIR,
              rghtIR,SS_n,SCLK,MOSI,MISO,INT,moving);

    parameter FAST_SIM = 1;	// used to speed up simulation

    input logic clk, rst_n;
    input logic MISO;					// SPI input from inertial sensor
    input logic INT;					// goes high when measurement ready
    input logic strt_cal;				// initiate claibration of yaw readings
    input logic moving;					// Only integrate yaw when going
    input logic lftIR,rghtIR;			// gaurdrail sensors

    output cal_done;				// pulses high for 1 clock when calibration done
    output signed [11:0] heading;	// heading of robot.  000 = Orig dir 3FF = 90 CCW 7FF = 180 CCW
    output rdy;					// goes high for 1 clock when new outputs ready (from inertial_integrator)
    output SS_n,SCLK,MOSI;		// SPI outputs

    //////////////////////////////////
    // Declare any internal signal //
    ////////////////////////////////
    logic snd, done, C_Y_H, C_Y_L, vld, INT_1, INT_stable;        // vld yaw_rt provided to inertial_integrator
    logic [7:0] resp, reg_low, reg_high;
    logic [15:0] cmd, count, yaw_rt, full_resp;

    //instantiate SPI_mnrch
    SPI_mnrch iSPI(.clk(clk), .rst_n(rst_n), .MISO(MISO), .snd(snd), .cmd(cmd), .done(done), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .resp(full_resp));

    typedef enum reg [2:0] {init1, init2, init3, idle, read_low, read_high} action;

    action state, next_state;

    assign yaw_rt = {reg_high, reg_low};

    assign resp = full_resp[7:0];

    //holding registers
    always_ff@(posedge clk, negedge rst_n)
    if (!rst_n) begin
        reg_low <= 8'h00;
        reg_high <= 8'h00;
    end else if (C_Y_H)
        reg_high <= resp;
    else if (C_Y_L)
        reg_low <= resp;

    //state machine flip flop
    always_ff@(posedge clk, negedge rst_n)
    if (!rst_n)
        state <= init1;
    else
        state <= next_state;


    //state machine next logic and outputs
    always_comb begin
        next_state = state;
        snd = 0;
        C_Y_H = 0;
        C_Y_L = 0;
        vld = 0;
        cmd = 16'h0000;

        case (state)

            //Wait for counter to be full
            init1: begin
                cmd = 16'h0d02;
                if (&count) begin
                    next_state = init2;
                    snd = 1;
                end
            end

            //Wait for done to be asserted and initialize INT signal
            init2: begin
                cmd = 16'h1160;
                if (done) begin
                    next_state = init3;
                    snd = 1;
                end
            end

            //Initialize INT signal
            init3: begin
                cmd = 16'h1440;
                if (done) begin
                    next_state = idle;
                    snd = 1;
                end
            end

            //Wait for initialization to complete and then read low
            idle: begin 
                cmd = 16'hA6xx;
                if (INT_stable) begin
                    next_state = read_low;
                    snd = 1;
                end
            end

            //read the low bits of the pitch
            read_low: begin 
                cmd = 16'hA7xx;
                if (done) begin
                    next_state = read_high;
                    C_Y_L = 1;
                    snd = 1;
                end
            end

            //read the high bits of the pitch
            read_high: if (done) begin
                next_state = idle;
                C_Y_H = 1;
                vld = 1;
            end

            default: next_state = init1;

        endcase
    end

    //flip flops for stabalizing INT
    always_ff@(posedge clk, negedge rst_n)
    if (!rst_n) begin
        INT_1 <= 0;
        INT_stable <= 0;
    end else begin
        INT_1 <= INT;
        INT_stable <= INT_1;
    end

    //16-bit timer for init state
    always_ff@(posedge clk, negedge rst_n)
    if (!rst_n)
        count <= 16'h0000;
    else
        count <= count + 16'b1;

    ////////////////////////////////////////////////////////////////////
    // Instantiate Angle Engine that takes in angular rate readings  //
    // and acceleration info and produces a heading reading         //
    /////////////////////////////////////////////////////////////////
    inertial_integrator #(FAST_SIM) iINT(.clk(clk), .rst_n(rst_n), .strt_cal(strt_cal),.vld(vld),
                           .rdy(rdy),.cal_done(cal_done), .yaw_rt(yaw_rt),.moving(moving),.lftIR(lftIR),
                           .rghtIR(rghtIR),.heading(heading));
endmodule
