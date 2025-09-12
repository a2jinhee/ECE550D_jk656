module alu(data_operandA, data_operandB, ctrl_ALUopcode, ctrl_shiftamt, data_result, isNotEqual, isLessThan, overflow);

    input [31:0] data_operandA, data_operandB; // signed
    input [4:0] ctrl_ALUopcode;
    input [4:0] ctrl_shiftamt; // not used

    output [31:0] data_result;
    output isNotEqual, isLessThan; // not used
    output overflow; // True iff overflow in ADD or SUB

    // Assign ALU opcodes
    wire op_add, op_sub;
    not not_op_code(op_add, ctrl_ALUopcode[0]); // gate primitive
    assign op_sub = ctrl_ALUopcode[0];

    // 2’s complement of B if SUB 
    // XOR each bit with op_sub
    // 32 bit carry select adder: A + B2 + cin
    // cin is 0 for ADD, op_sub for SUB (2's complement)
    wire [31:0] B2;
    genvar xi;
    generate
        for (xi = 0; xi < 32; xi = xi + 1) begin: XOR_B_WITH_SUB
            xor xorb(B2[xi], data_operandB[xi], op_sub);
        end
    endgenerate
    wire cin0, cin1;
    assign cin0 = 1'b0;
    assign cin1 = 1'b1;
    
    wire sel0; // sel for block0 carry in (cin0 or cin1)
    assign sel0 = op_sub;
    wire c4, c8, c12, c16, c20, c24, c28, c32; // Carry wires for rca4 blocks
    wire [31:0] sum;

    // ! Precompute rca4 with 1) cin=0 and 2) cin=1, then mux sel0, c4, c8, ... 
    
    // Block 0: bits [3:0]
    wire [3:0] s0_c0, s0_c1; wire c4_c0, c4_c1;
    rca4 u0_c0(.a(data_operandA[3:0]),  .b(B2[3:0]),  .cin(cin0), .sum(s0_c0), .cout(c4_c0));
    rca4 u0_c1(.a(data_operandA[3:0]),  .b(B2[3:0]),  .cin(cin1), .sum(s0_c1), .cout(c4_c1));
    assign {c4, sum[3:0]} = sel0 ? {c4_c1, s0_c1} : {c4_c0, s0_c0};

    // Block 1: bits [7:4]
    wire [3:0] s1_c0, s1_c1; wire c8_c0, c8_c1;
    rca4 u1_c0(.a(data_operandA[7:4]),  .b(B2[7:4]),  .cin(cin0), .sum(s1_c0), .cout(c8_c0));
    rca4 u1_c1(.a(data_operandA[7:4]),  .b(B2[7:4]),  .cin(cin1), .sum(s1_c1), .cout(c8_c1));
    assign {c8, sum[7:4]} = c4 ? {c8_c1, s1_c1} : {c8_c0, s1_c0};

    // Block 2: bits [11:8]
    wire [3:0] s2_c0, s2_c1; wire c12_c0, c12_c1;
    rca4 u2_c0(.a(data_operandA[11:8]), .b(B2[11:8]), .cin(cin0), .sum(s2_c0), .cout(c12_c0));
    rca4 u2_c1(.a(data_operandA[11:8]), .b(B2[11:8]), .cin(cin1), .sum(s2_c1), .cout(c12_c1));
    assign {c12, sum[11:8]} = c8 ? {c12_c1, s2_c1} : {c12_c0, s2_c0};

    // Block 3: bits [15:12]
    wire [3:0] s3_c0, s3_c1; wire c16_c0, c16_c1;
    rca4 u3_c0(.a(data_operandA[15:12]), .b(B2[15:12]), .cin(cin0), .sum(s3_c0), .cout(c16_c0));
    rca4 u3_c1(.a(data_operandA[15:12]), .b(B2[15:12]), .cin(cin1), .sum(s3_c1), .cout(c16_c1));
    assign {c16, sum[15:12]} = c12 ? {c16_c1, s3_c1} : {c16_c0, s3_c0};

    // Block 4: bits [19:16]
    wire [3:0] s4_c0, s4_c1; wire c20_c0, c20_c1;
    rca4 u4_c0(.a(data_operandA[19:16]), .b(B2[19:16]), .cin(cin0), .sum(s4_c0), .cout(c20_c0));
    rca4 u4_c1(.a(data_operandA[19:16]), .b(B2[19:16]), .cin(cin1), .sum(s4_c1), .cout(c20_c1));
    assign {c20, sum[19:16]} = c16 ? {c20_c1, s4_c1} : {c20_c0, s4_c0};

    // Block 5: bits [23:20]
    wire [3:0] s5_c0, s5_c1; wire c24_c0, c24_c1;
    rca4 u5_c0(.a(data_operandA[23:20]), .b(B2[23:20]), .cin(cin0), .sum(s5_c0), .cout(c24_c0));
    rca4 u5_c1(.a(data_operandA[23:20]), .b(B2[23:20]), .cin(cin1), .sum(s5_c1), .cout(c24_c1));
    assign {c24, sum[23:20]} = c20 ? {c24_c1, s5_c1} : {c24_c0, s5_c0};

    // Block 6: bits [27:24]
    wire [3:0] s6_c0, s6_c1; wire c28_c0, c28_c1;
    rca4 u6_c0(.a(data_operandA[27:24]), .b(B2[27:24]), .cin(cin0), .sum(s6_c0), .cout(c28_c0));
    rca4 u6_c1(.a(data_operandA[27:24]), .b(B2[27:24]), .cin(cin1), .sum(s6_c1), .cout(c28_c1));
    assign {c28, sum[27:24]} = c24 ? {c28_c1, s6_c1} : {c28_c0, s6_c0};

    // Block 7: bits [31:28]
    wire [3:0] s7_c0, s7_c1; wire c32_c0, c32_c1;
    rca4 u7_c0(.a(data_operandA[31:28]), .b(B2[31:28]), .cin(cin0), .sum(s7_c0), .cout(c32_c0));
    rca4 u7_c1(.a(data_operandA[31:28]), .b(B2[31:28]), .cin(cin1), .sum(s7_c1), .cout(c32_c1));
    assign {c32, sum[31:28]} = c28 ? {c32_c1, s7_c1} : {c32_c0, s7_c0};

    // Sum
    assign data_result = sum;

    // Overflow for signed add or subtract:
    // overflow = (A31 & B2_31 & ~S31) | (~A31 & ~B2_31 & S31)
    wire a31, b31_t, s31;
    assign a31  = data_operandA[31];
    assign b31_t = B2[31];
    assign s31  = sum[31];

    wire na31, nb31_t, ns31;
    not na_(na31, a31);
    not nb_(nb31_t, b31_t);
    not ns_(ns31, s31);

    wire t1, t2, t3, t4;
    and a1(t1, a31, b31_t);
    and a2(t2, t1,  ns31);
    and a3(t3, na31, nb31_t);
    and a4(t4, t3,  s31);
    or  o1(overflow, t2, t4);

    // Not used
    assign isNotEqual = 1'b0;
    assign isLessThan = 1'b0;

endmodule

// 4 bit rca4
module rca4(
    input  [3:0] a,
    input  [3:0] b,
    input        cin,
    output [3:0] sum,
    output       cout
);
    wire c1, c2, c3;

    fa fa0(.a(a[0]), .b(b[0]), .cin(cin), .s(sum[0]), .cout(c1));
    fa fa1(.a(a[1]), .b(b[1]), .cin(c1),  .s(sum[1]), .cout(c2));
    fa fa2(.a(a[2]), .b(b[2]), .cin(c2),  .s(sum[2]), .cout(c3));
    fa fa3(.a(a[3]), .b(b[3]), .cin(c3),  .s(sum[3]), .cout(cout));
endmodule

// 1 bit FA using gates
// s = a XOR b XOR cin
// cout = ab + a cin + b cin
module fa(
    input  a, b, cin,
    output s, cout
);
    wire axb, ab, ac, bc;

    xor x1(axb, a, b);
    xor x2(s,   axb, cin);

    and a1(ab, a, b);
    and a2(ac, a, cin);
    and a3(bc, b, cin);
    or  o1(cout, ab, ac, bc);
endmodule