module TourCmd_tb ();

//inputs
logic clk;
logic rst_n;
logic start_tour;
logic [7:0] move;
logic [15:0] cmd_UART;
logic cmd_rdy_UART;
logic clr_cmd_rdy;
logic send_resp;

//outputs
logic [4:0] mv_indx;
logic [15:0] cmd;
logic cmd_rdy;
logic [7:0] resp;

integer i, j;

logic [7:0] move_array [0:7] = {8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80};

TourCmd iDUT(.clk(clk), .rst_n(rst_n), .start_tour(start_tour), .move(move),
                .mv_indx(mv_indx), .cmd_UART(cmd), .cmd(cmd), .cmd_rdy_UART(cmd_rdy_UART),
                .cmd_rdy(cmd_rdy), .clr_cmd_rdy(clr_cmd_rdy), .send_resp(send_resp), .resp(resp));

initial begin
  clk = 0;
  rst_n = 0;
  start_tour = 0;
  move = 8'h01;
  cmd_UART = '0;
  cmd_rdy_UART = 0;
  clr_cmd_rdy = 0;
  send_resp = 0;

  @(negedge clk);
  rst_n = 1;
  @(posedge clk);
  start_tour = 1;
  @(posedge clk);

  for (j = 0; j < 3; j ++) begin
    for (i = 0; i < 8; i++) begin
      move = move_array[i];
      repeat (2) @(posedge clk);

      clr_cmd_rdy = 1;
      @(posedge clk);
      clr_cmd_rdy = 1;
      repeat (3) @(posedge clk);
      send_resp = 1;
      @(posedge clk);
      send_resp = 0;

      repeat (2) @(posedge clk);

      clr_cmd_rdy = 1;
      @(posedge clk);
      clr_cmd_rdy = 1;
      repeat (3) @(posedge clk);
      send_resp = 1;
      @(posedge clk);
      send_resp = 0;
    end
  end

  $stop();

end

always
  #5 clk = ~clk;


endmodule