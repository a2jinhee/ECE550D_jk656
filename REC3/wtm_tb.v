`timescale 1ns/100ps

module wtm_tb();

	// inputs
	reg  [4:0] in1;
	reg  [4:0] in2;

	reg clock;

	// outputs
	wire cout;
	wire [9:0] out;

//	integer num_errors;

	wtm test_wtm(in1, in2, out, cout);

	initial begin
	$display($time, "simulation start"); 

	clock = 1'b0; 
  
	@(negedge clock); 
	in1 = 5'd0; 
	in2 = 5'd20;

	@(negedge clock); 
	in1 = 5'd25; 
	in2 = 5'd16;
 
	@(negedge clock); 
	in1 = 5'd31; 
	in2 = 5'd1;
	
	@(negedge clock); 
	$stop;
	end
	
	always
	#10 clock = ~clock;
	
endmodule
  