
task init();
  begin
    clk = 0;
    RST_n = 0;
    send_cmd = 0;
    cmd = 16'h0000; //initialize cmd for post-sythnesis testing
    @(posedge clk);
    @(negedge clk);
    @(posedge clk);
    @(negedge clk);
    RST_n = 1;
    @(posedge clk);
    @(negedge clk);
  end
endtask

task snd_cmd(input [15:0] cmd_to_send);
  begin
    cmd = cmd_to_send;
    send_cmd = 1;
    @(posedge clk);
    @(negedge clk);
    send_cmd = 0;
  end
endtask

task checkPosAck();
  //look for positive ack
  fork
      begin : ack_timeout
          repeat(150000000) @(posedge clk);
          $display("ERROR: timed out waiting for positive ack");
          $stop();
      end

      begin
          @(posedge resp_rdy);
          disable ack_timeout;
      end
  join

  //Check if response is correct
  if (resp !== 8'hA5) begin
    $display("ERROR: response was expected to be %h but was actually %h", 8'hA5, resp);
    $stop();
  end

endtask

task waitClockCycles();
  repeat (150000) @(posedge clk);
endtask

task checkFanfare();
  //look for assertion of fanfare_go
  fork
      begin : fanfare_timeout
          repeat(15000) @(posedge piezo);
          $display("ERROR: timed out waiting for piezo signal");
          $stop();
      end

      begin
          @(posedge piezo);
          $display("Fanfare played!");
          disable fanfare_timeout;
      end
  join
endtask

//check the position of the gyro on the board after it has stopped
task posCheck(input [14:0] expected_xx, input [14:0] expected_yy);
  
  if(xx < (expected_xx + 15'h0200) && xx > (expected_xx - 15'h0200)) begin
    $display("xx within bounds");
  end
  else begin
    $display("xx out of bounds! xx: %h  xx_upper: %h  xx_lower: %h", xx, (expected_xx + 15'h0200), (expected_xx - 15'h0200));
    $stop();
  end
  
  if(yy < (expected_yy + 15'h0200) && yy > (expected_yy - 15'h0200)) begin
    $display("yy within bounds");
  end
  else begin
    $display("yy out of bounds! yy: %h yy_upper: %h  yy_lower: %h", yy, (expected_yy + 15'h0200), (expected_yy - 15'h0200));
    $stop();
  end  
  
endtask      
    

