module MtrDrv(clk, rst_n, lft_spd,  rght_spd, lftPWM1, lftPWM2, rghtPWM1, rghtPWM2);
    input clk; //50MHz system clk
    input rst_n; //Asynch active low
    input signed [10:0] lft_spd; //Signed left motor speed
    input signed [10:0] rght_spd; //Signed right motor speed
    output lftPWM1, lftPWM2; //To power MOSFETs that drive lft motor
    output rghtPWM1, rghtPWM2; //To power MOSFETs that drive right motor
    logic clk; //Clock used for PWM
    logic rst_n; //Reset signal

    //Right first
    logic [10:0] correctedRightDuty;
    assign correctedRightDuty = rght_spd + 11'h400;
    PWM11 rightControl(.clk(clk), .rst_n(rst_n), .duty(correctedRightDuty), .PWM_sig(rghtPWM1), .PWM_sig_n(rghtPWM2));

    //Left last
    logic [10:0] correctedLeftDuty;
    assign correctedLeftDuty = lft_spd + 11'h400;
    PWM11 leftControl(.clk(clk), .rst_n(rst_n), .duty(correctedLeftDuty), .PWM_sig(lftPWM1), .PWM_sig_n(lftPWM2));

endmodule