`timescale 1 ns / 100 ps 
module mod5_tb();
    reg clk, rst, w;
    wire [2:0] count;
    wire [2:0] state;
	 
    mod5 test_counter(clk, rst, w, count, state);
	 
    initial begin
        $display($time, " Simulation start");
        clk = 1'b0;
        rst = 1'b0;
        w = 1'b0;

        #10 rst = 1'b1;
        #10 rst = 1'b0;
	  
        @(negedge clk);
            w = 1'b1;
        @(negedge clk);
            w = 1'b1;
        @(negedge clk);
            w = 1'b1;
        @(negedge clk);
            w = 1'b1;
        @(negedge clk);
            w = 1'b1;
        $stop;
    end

    always #10 clk = ~clk;

endmodule
