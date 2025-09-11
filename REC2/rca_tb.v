`timescale 1ns/1ps
module rca_tb();

  reg [3:0] a, b;
  reg cin;
  wire [3:0] sum;
  wire cout;

  rca UUT (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));

  initial begin
    $monitor("t=%0d: a=%b b=%b cin=%b | sum=%b cout=%b",
             $time, a, b, cin, sum, cout);

    a=4'b1101; b=4'b1000; cin=1; #10;
    a=4'b1010; b=4'b1001; cin=0; #10;
    $stop;
  end

endmodule