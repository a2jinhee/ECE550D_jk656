// % top module alu
module alu(data_operandA, data_operandB, ctrl_ALUopcode, ctrl_shiftamt, data_result, isNotEqual, isLessThan, overflow);

    input [31:0] data_operandA, data_operandB; // signed
    input [4:0] ctrl_ALUopcode;
    input [4:0] ctrl_shiftamt; // used in SLL and SRA

    output [31:0] data_result;
    output isNotEqual, isLessThan; // needs to be correct after SUB
    output overflow; // needs to be correct after ADD/SUB

    wire b4, b3, b2, b1, b0;
    wire nb4, nb3, nb2, nb1, nb0;
    assign {b4,b3,b2,b1,b0} = ctrl_ALUopcode;
    not n4(nb4, b4); not n3(nb3, b3); not n2(nb2, b2); not n1(nb1, b1); not n0(nb0, b0);

    // % ctrl_ALUopcode related wires
    wire op_add, op_sub, op_and, op_or, op_sll, op_sra;

    wire t_add0, t_add1, t_add2, t_add3; // op_add = ~b4 & ~b3 & ~b2 & ~b1 & ~b0 (00000)
    and a_add0(t_add0, nb4, nb3); and a_add1(t_add1, nb2, nb1); 
    and a_add2(t_add2, t_add0, t_add1); and a_add3(op_add, t_add2, nb0);

    wire t_sub0, t_sub1, t_sub2; // op_sub = ~b4 & ~b3 & ~b2 & ~b1 & b0 (00001)
    and a_sub0(t_sub0, nb4, nb3); and a_sub1(t_sub1, nb2, nb1); 
    and a_sub2(t_sub2, t_sub0, t_sub1); and a_sub3(op_sub, t_sub2, b0);

    wire t_and0, t_and1, t_and2; // op_and = ~b4 & ~b3 & ~b2 & b1 & ~b0 (00010)
    and a_and0(t_and0, nb4, nb3); and a_and1(t_and1, nb2, b1); 
    and a_and2(t_and2, t_and0, t_and1); and a_and3(op_and, t_and2, nb0);

    wire t_or0, t_or1, t_or2; // op_or  = ~b4 & ~b3 & ~b2 & b1 & b0 (00011)
    and a_or0(t_or0, nb4, nb3); and a_or1(t_or1, nb2, b1); 
    and a_or2(t_or2, t_or0, t_or1); and a_or3(op_or, t_or2, b0);

    wire t_sll0, t_sll1, t_sll2; // op_sll = ~b4 & ~b3 & b2 & nb1 & nb0  (00100)
    and a_sll0(t_sll0, nb4, nb3); and a_sll1(t_sll1, t_sll0, b2);
    and a_sll2(t_sll2, nb1, nb0); and a_sll3(op_sll, t_sll1, t_sll2);

    wire t_sra0, t_sra1, t_sra2; // op_sra = ~b4 & ~b3 & b2 & nb1 & b0   (00101)
    and a_sra0(t_sra0, nb4, nb3); and a_sra1(t_sra1, t_sra0, b2);
    and a_sra2(t_sra2, nb1, b0); and a_sra3(op_sra, t_sra1, t_sra2);

    // % ADD and SUB using carry select over eight 4 bit RCA blocks
    wire [31:0] B2; // B xor op_sub to form SUB 2's complement
    genvar xi;
    generate
        for (xi = 0; xi < 32; xi = xi + 1) begin: XOR_B_WITH_SUB
            xor g_xb(B2[xi], data_operandB[xi], op_sub);
        end
    endgenerate

    wire cin0, cin1;
    assign cin0 = 1'b0;
    assign cin1 = 1'b1;

    wire sel0;  // initial carry select for block 0
    assign sel0 = op_sub;

    wire c4, c8, c12, c16, c20, c24, c28, c32;
    wire [31:0] sum;

    // * Block 0~7
    wire [3:0] s0_c0, s0_c1; wire c4_c0, c4_c1;
    rca4 u0_c0(.a(data_operandA[3:0]),  .b(B2[3:0]),  .cin(cin0), .sum(s0_c0), .cout(c4_c0));
    rca4 u0_c1(.a(data_operandA[3:0]),  .b(B2[3:0]),  .cin(cin1), .sum(s0_c1), .cout(c4_c1));
    assign {c4, sum[3:0]} = sel0 ? {c4_c1, s0_c1} : {c4_c0, s0_c0};

    wire [3:0] s1_c0, s1_c1; wire c8_c0, c8_c1;
    rca4 u1_c0(.a(data_operandA[7:4]),  .b(B2[7:4]),  .cin(cin0), .sum(s1_c0), .cout(c8_c0));
    rca4 u1_c1(.a(data_operandA[7:4]),  .b(B2[7:4]),  .cin(cin1), .sum(s1_c1), .cout(c8_c1));
    assign {c8, sum[7:4]} = c4 ? {c8_c1, s1_c1} : {c8_c0, s1_c0};

    wire [3:0] s2_c0, s2_c1; wire c12_c0, c12_c1;
    rca4 u2_c0(.a(data_operandA[11:8]), .b(B2[11:8]), .cin(cin0), .sum(s2_c0), .cout(c12_c0));
    rca4 u2_c1(.a(data_operandA[11:8]), .b(B2[11:8]), .cin(cin1), .sum(s2_c1), .cout(c12_c1));
    assign {c12, sum[11:8]} = c8 ? {c12_c1, s2_c1} : {c12_c0, s2_c0};
    
    wire [3:0] s3_c0, s3_c1; wire c16_c0, c16_c1; 
    rca4 u3_c0(.a(data_operandA[15:12]), .b(B2[15:12]), .cin(cin0), .sum(s3_c0), .cout(c16_c0));
    rca4 u3_c1(.a(data_operandA[15:12]), .b(B2[15:12]), .cin(cin1), .sum(s3_c1), .cout(c16_c1));
    assign {c16, sum[15:12]} = c12 ? {c16_c1, s3_c1} : {c16_c0, s3_c0};

    wire [3:0] s4_c0, s4_c1; wire c20_c0, c20_c1;
    rca4 u4_c0(.a(data_operandA[19:16]), .b(B2[19:16]), .cin(cin0), .sum(s4_c0), .cout(c20_c0));
    rca4 u4_c1(.a(data_operandA[19:16]), .b(B2[19:16]), .cin(cin1), .sum(s4_c1), .cout(c20_c1));
    assign {c20, sum[19:16]} = c16 ? {c20_c1, s4_c1} : {c20_c0, s4_c0};
    
    wire [3:0] s5_c0, s5_c1; wire c24_c0, c24_c1;
    rca4 u5_c0(.a(data_operandA[23:20]), .b(B2[23:20]), .cin(cin0), .sum(s5_c0), .cout(c24_c0));
    rca4 u5_c1(.a(data_operandA[23:20]), .b(B2[23:20]), .cin(cin1), .sum(s5_c1), .cout(c24_c1));
    assign {c24, sum[23:20]} = c20 ? {c24_c1, s5_c1} : {c24_c0, s5_c0};

    wire [3:0] s6_c0, s6_c1; wire c28_c0, c28_c1;
    rca4 u6_c0(.a(data_operandA[27:24]), .b(B2[27:24]), .cin(cin0), .sum(s6_c0), .cout(c28_c0));
    rca4 u6_c1(.a(data_operandA[27:24]), .b(B2[27:24]), .cin(cin1), .sum(s6_c1), .cout(c28_c1));
    assign {c28, sum[27:24]} = c24 ? {c28_c1, s6_c1} : {c28_c0, s6_c0};

    wire [3:0] s7_c0, s7_c1; wire c32_c0, c32_c1; 
    rca4 u7_c0(.a(data_operandA[31:28]), .b(B2[31:28]), .cin(cin0), .sum(s7_c0), .cout(c32_c0));
    rca4 u7_c1(.a(data_operandA[31:28]), .b(B2[31:28]), .cin(cin1), .sum(s7_c1), .cout(c32_c1));
    assign { c32 , sum[31:28]} = c28 ? {c32_c1, s7_c1} : {c32_c0, s7_c0};

    // * Signed overflow for ADD or SUB (with B2)
    wire a31 = data_operandA[31];
    wire b31 = B2[31];
    wire s31 = sum[31];

    wire na31, nb31, ns31;
    not na_(na31, a31); not nb_(nb31, b31); not ns_(ns31, s31);

    wire t1, t2, t3, t4;
    and a1(t1, a31, b31); and a2(t2, t1, ns31); and a3(t3, na31, nb31); and a4(t4, t3, s31);
    or  o1(overflow, t2, t4);

    // % Bitwise AND and OR 
    wire [31:0] and_res, or_res;
    genvar bi;
    generate
        for (bi = 0; bi < 32; bi = bi + 1) begin: BITWISE_AND_OR
            and g_and(and_res[bi], data_operandA[bi], data_operandB[bi]);
            or  g_or (or_res[bi],  data_operandA[bi], data_operandB[bi]);
        end
    endgenerate

    // % Barrel shifters - Five stages 1,2,4,8,16 using 2-1 MUX
    wire [31:0] sll_out, sra_out;
    barrel_sll32 u_sll(.in (data_operandA), .sa (ctrl_shiftamt), .out(sll_out));
    barrel_sra32 u_sra(.in (data_operandA), .sa (ctrl_shiftamt), .out(sra_out));

    // % isNotEqual is OR reduce of sum from A - B
    // % isLessThan is s31 xor overflow from A - B
    wire neq_or;
    reduce_or32 u_red(.in(sum), .out(neq_or));
    assign isNotEqual = neq_or;

    wire lt_xor;
    xor x_lt(lt_xor, s31, overflow);
    assign isLessThan = lt_xor;

    // % Final result based on opcode wires
    wire [31:0] add_res = sum;       // when op_add
    wire [31:0] sub_res = sum;       // when op_sub

    wire [31:0] sel0_res = op_add ? add_res : sub_res;         // op_add or op_sub
    wire [31:0] sel1_res = op_and ? and_res : sel0_res;        // add and sub already in sel0
    wire [31:0] sel2_res = op_or  ? or_res  : sel1_res;
    wire [31:0] sel3_res = op_sll ? sll_out : sel2_res;
    wire [31:0] sel4_res = op_sra ? sra_out : sel3_res;

    assign data_result = sel4_res;

endmodule

// % ripple carry adder 4 bit
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

// % 1 bit full adder
module fa(
    input  a, b, cin,
    output s, cout
);
    wire axb, ab, ac, bc;
    xor x1(axb, a, b); xor x2(s,   axb, cin);
    and a1(ab, a, b); and a2(ac, a, cin); and a3(bc, b, cin);
    or  o1(cout, ab, ac, bc);
endmodule

// % OR reduce 32 bits using only gate primitives
module reduce_or32(
    input  [31:0] in,
    output        out
);
    wire [15:0] l1;
    wire [7:0]  l2;
    wire [3:0]  l3;
    wire [1:0]  l4;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin: L1
            or g(in_or, in[2*i], in[2*i+1]);
            assign l1[i] = in_or;
        end
        for (i = 0; i < 8; i = i + 1) begin: L2
            or g(l2_or, l1[2*i], l1[2*i+1]);
            assign l2[i] = l2_or;
        end
        for (i = 0; i < 4; i = i + 1) begin: L3
            or g(l3_or, l2[2*i], l2[2*i+1]);
            assign l3[i] = l3_or;
        end
        for (i = 0; i < 2; i = i + 1) begin: L4
            or g(l4_or, l3[2*i], l3[2*i+1]);
            assign l4[i] = l4_or;
        end
    endgenerate

    or g_out(out, l4[0], l4[1]);
endmodule


// % Logical left shift barrel shifter 32 bit
module barrel_sll32(
    input  [31:0] in,
    input  [4:0]  sa,
    output [31:0] out
);
    wire [31:0] s1, s2, s3, s4, s5;

    // shift by 1 when sa[0] is 1
    genvar i1;
    generate
        for (i1 = 0; i1 < 32; i1 = i1 + 1) begin: SLL1
            if (i1 == 0) begin
                assign s1[i1] = sa[0] ? 1'b0 : in[i1];
            end else begin
                assign s1[i1] = sa[0] ? in[i1-1] : in[i1];
            end
        end
    endgenerate

    // shift by 2 when sa[1] is 1
    genvar i2;
    generate
        for (i2 = 0; i2 < 32; i2 = i2 + 1) begin: SLL2
            if (i2 < 2) begin
                assign s2[i2] = sa[1] ? 1'b0 : s1[i2];
            end else begin
                assign s2[i2] = sa[1] ? s1[i2-2] : s1[i2];
            end
        end
    endgenerate

    // shift by 4
    genvar i3;
    generate
        for (i3 = 0; i3 < 32; i3 = i3 + 1) begin: SLL4
            if (i3 < 4) begin
                assign s3[i3] = sa[2] ? 1'b0 : s2[i3];
            end else begin
                assign s3[i3] = sa[2] ? s2[i3-4] : s2[i3];
            end
        end
    endgenerate

    // shift by 8
    genvar i4;
    generate
        for (i4 = 0; i4 < 32; i4 = i4 + 1) begin: SLL8
            if (i4 < 8) begin
                assign s4[i4] = sa[3] ? 1'b0 : s3[i4];
            end else begin
                assign s4[i4] = sa[3] ? s3[i4-8] : s3[i4];
            end
        end
    endgenerate

    // shift by 16
    genvar i5;
    generate
        for (i5 = 0; i5 < 32; i5 = i5 + 1) begin: SLL16
            if (i5 < 16) begin
                assign s5[i5] = sa[4] ? 1'b0 : s4[i5];
            end else begin
                assign s5[i5] = sa[4] ? s4[i5-16] : s4[i5];
            end
        end
    endgenerate

    assign out = s5;
endmodule

// % Arithmetic right shift barrel shifter 32 bit
// Sign extends from in[31]
module barrel_sra32(
    input  [31:0] in,
    input  [4:0]  sa,
    output [31:0] out
);
    wire sgn = in[31];
    wire [31:0] s1, s2, s3, s4, s5;

    // shift by 1 when sa[0] is 1
    genvar j1;
    generate
        for (j1 = 0; j1 < 32; j1 = j1 + 1) begin: SRA1
            if (j1 == 31) begin
                assign s1[31] = sa[0] ? sgn : in[31];
            end else begin
                assign s1[j1] = sa[0] ? in[j1+1] : in[j1];
            end
        end
    endgenerate

    // shift by 2
    genvar j2;
    generate
        for (j2 = 0; j2 < 32; j2 = j2 + 1) begin: SRA2
            if (j2 >= 30) begin
                assign s2[j2] = sa[1] ? sgn : s1[j2];
            end else begin
                assign s2[j2] = sa[1] ? s1[j2+2] : s1[j2];
            end
        end
    endgenerate

    // shift by 4
    genvar j3;
    generate
        for (j3 = 0; j3 < 32; j3 = j3 + 1) begin: SRA4
            if (j3 >= 28) begin
                assign s3[j3] = sa[2] ? sgn : s2[j3];
            end else begin
                assign s3[j3] = sa[2] ? s2[j3+4] : s2[j3];
            end
        end
    endgenerate

    // shift by 8
    genvar j4;
    generate
        for (j4 = 0; j4 < 32; j4 = j4 + 1) begin: SRA8
            if (j4 >= 24) begin
                assign s4[j4] = sa[3] ? sgn : s3[j4];
            end else begin
                assign s4[j4] = sa[3] ? s3[j4+8] : s3[j4];
            end
        end
    endgenerate

    // shift by 16
    genvar j5;
    generate
        for (j5 = 0; j5 < 32; j5 = j5 + 1) begin: SRA16
            if (j5 >= 16) begin
                assign s5[j5] = sa[4] ? sgn : s4[j5];
            end else begin
                assign s5[j5] = sa[4] ? s4[j5+16] : s4[j5];
            end
        end
    endgenerate

    assign out = s5;
endmodule