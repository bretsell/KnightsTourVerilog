module PWM11(clk, rst_n, duty, PWM_sig, PWM_sig_n);
    input clk; //50MHz system clk
    input rst_n; //Asynch active low
    input [10:0] duty; // Specifies duty cycle (unsigned 11-bit)
    output logic PWM_sig, PWM_sig_n; //PWM signal out (glitch free)

    logic [10:0] cnt; // Counter

    // Counter flop
    always_ff @(posedge clk, negedge rst_n)
        if (~rst_n)
            cnt <= 0;
        else
            cnt <= cnt + 11'b1;

    // Value-holding flop
    always_ff @(posedge clk, negedge rst_n)
        if (~rst_n)
            PWM_sig <= 11'b0;
        else
            PWM_sig <= (cnt < duty);

    assign PWM_sig_n = ~PWM_sig;

endmodule