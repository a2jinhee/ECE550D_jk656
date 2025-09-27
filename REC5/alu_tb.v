`timescale 1ns/1ps
module alu_tb;

    reg  [31:0] A, B;
    reg  [4:0]  opcode, shamt;
    wire [31:0] result;
    wire ne, lt, ov;

    alu uut (
        .data_operandA(A),
        .data_operandB(B),
        .ctrl_ALUopcode(opcode),
        .ctrl_shiftamt(shamt),
        .data_result(result),
        .isNotEqual(ne),
        .isLessThan(lt),
        .overflow(ov)
    );

    initial begin
        $display("=== ALU Testbench Start ===");

        opcode = 5'b00000; shamt = 0;
        A = 10; B = 5; #10;
        $display("ADD Test1: %d + %d = %d", A, B, result);

        A = -15; B = 7; #10;
        $display("ADD Test2: %d + %d = %d, overflow=%b", A, B, result, ov);

        A = 32'h7FFFFFFF; B = 1; #10;
        $display("ADD Test3: %d + %d = %d, overflow=%b", A, B, result, ov);

        opcode = 5'b00001;
        A = 10; B = 5; #10;
        $display("SUB Test1: %d - %d = %d, ne=%b, lt=%b", A, B, result, ne, lt);

        A = 5; B = 10; #10;
        $display("SUB Test2: %d - %d = %d, ne=%b, lt=%b", A, B, result, ne, lt);

        A = 32'h80000000; B = 1; #10;
        $display("SUB Test3: %d - %d = %d, overflow=%b", A, B, result, ov);

        opcode = 5'b00010;
        A = 32'hF0F0F0F0; B = 32'h0F0F0F0F; #10;
        $display("AND Test1: %h & %h = %h", A, B, result);

        A = 32'hFFFFFFFF; B = 32'h12345678; #10;
        $display("AND Test2: %h & %h = %h", A, B, result);

        A = 0; B = 32'hABCD1234; #10;
        $display("AND Test3: %h & %h = %h", A, B, result);

        $display("=== ALU Testbench End ===");
        $stop;
    end
endmodule