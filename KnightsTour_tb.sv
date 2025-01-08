module KnightsTour_tb();

  localparam FAST_SIM = 1;


  /////////////////////////////
  // Stimulus of type reg //
  /////////////////////////
  reg clk, RST_n;
  reg [15:0] cmd;
  reg send_cmd;

  ///////////////////////////////////
  // Declare any internal signals //
  /////////////////////////////////
  wire SS_n,SCLK,MOSI,MISO,INT;
  wire lftPWM1,lftPWM2,rghtPWM1,rghtPWM2;
  wire TX_RX, RX_TX;
  logic cmd_sent;
  logic resp_rdy;
  logic [7:0] resp;
  wire IR_en;
  wire lftIR_n,rghtIR_n,cntrIR_n;
  reg [14:0] xx,yy;

  //////////////////////
  // Instantiate DUT ///
  //////////////////////
  KnightsTour iDUT(.clk(clk), .RST_n(RST_n), .SS_n(SS_n), .SCLK(SCLK),
                   .MOSI(MOSI), .MISO(MISO), .INT(INT), .lftPWM1(lftPWM1),
				   .lftPWM2(lftPWM2), .rghtPWM1(rghtPWM1), .rghtPWM2(rghtPWM2),
				   .RX(TX_RX), .TX(RX_TX), .piezo(piezo), .piezo_n(piezo_n),
				   .IR_en(IR_en), .lftIR_n(lftIR_n), .rghtIR_n(rghtIR_n),
				   .cntrIR_n(cntrIR_n));

  /////////////////////////////////////////////////////
  // Instantiate RemoteComm to send commands to DUT //
  ///////////////////////////////////////////////////
  RemoteComm iRMT(.clk(clk), .rst_n(RST_n), .RX(RX_TX), .TX(TX_RX), .cmd(cmd),
             .send_cmd(send_cmd), .cmd_sent(cmd_sent), .rx_rdy(resp_rdy), .rx_data(resp));

  KnightPhysics iPHYS(.clk(clk), .RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),
                      .MOSI(MOSI),.INT(INT),.lftPWM1(lftPWM1),.lftPWM2(lftPWM2),
					  .rghtPWM1(rghtPWM1),.rghtPWM2(rghtPWM2),.IR_en(IR_en),
					  .lftIR_n(lftIR_n),.rghtIR_n(rghtIR_n),.cntrIR_n(cntrIR_n), .xx(xx), .yy(yy));

  initial begin

    //initlize DUT
    init();

    //Test calibrate cmd
    snd_cmd(16'h2000); //Calibrate command

    //wait for ack
    checkPosAck();

    //test move east 1 square cmd
    snd_cmd(16'h4BF1); //move east 1 square

    //wait for ack
    checkPosAck();

    //check position is as (3, 2)
    posCheck(15'h3800, 15'h2800);

    //wait 150,000 clock cycles
    waitClockCycles();

    //test move north 2 squares cmd
    snd_cmd(16'h4002); //move north 2 squares

    //wait for ack
    checkPosAck();

    //check position is as (3, 4)
    posCheck(15'h3800, 15'h4800);

    $display("YAHOO!! Test Passed!");
    $stop();

  end

  always
    #5 clk = ~clk;

  `include "tb_tasks.sv" //include tasks from other File

endmodule