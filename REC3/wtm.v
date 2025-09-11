// 5x5 Wallace Tree Multiplier
// in1[4:0] * in2[4:0] -> out[9:0], cout is the extra carry out bit
module wtm(
    input  [4:0] in1,
    input  [4:0] in2,
    output [9:0] out,
    output       cout
);

    wire a0 = in1[0], a1 = in1[1], a2 = in1[2], a3 = in1[3], a4 = in1[4];
    wire b0 = in2[0], b1 = in2[1], b2 = in2[2], b3 = in2[3], b4 = in2[4];

    // Partial products
    wire p00 = a0 & b0;

    wire p01 = a0 & b1, p10 = a1 & b0;
    wire p02 = a0 & b2, p11 = a1 & b1, p20 = a2 & b0;
    wire p03 = a0 & b3, p12 = a1 & b2, p21 = a2 & b1, p30 = a3 & b0;
    wire p04 = a0 & b4, p13 = a1 & b3, p22 = a2 & b2, p31 = a3 & b1, p40 = a4 & b0;
    wire p14 = a1 & b4, p23 = a2 & b3, p32 = a3 & b2, p41 = a4 & b1;
    wire p24 = a2 & b4, p33 = a3 & b3, p42 = a4 & b2;
    wire p34 = a3 & b4, p43 = a4 & b3;
    wire p44 = a4 & b4;

    // Stage 1 reductions
    wire s11, c11;              // weight 1
    ha HA_11(.x(p01), .y(p10), .s(s11), .c(c11));

    wire s21, c21;              // weight 2
    fa FA_21(.x(p02), .y(p11), .z(p20), .s(s21), .c(c21));

    // weight 3: four bits -> FA then HA
    wire s31a, c31a, s31, c31b;
    fa FA_31a(.x(p03), .y(p12), .z(p21), .s(s31a), .c(c31a));
    ha HA_31b(.x(s31a), .y(p30), .s(s31), .c(c31b));

    // weight 4: five bits -> FA then FA
    wire s41a, c41a, s41, c41b;
    fa FA_41a(.x(p04), .y(p13), .z(p22), .s(s41a), .c(c41a));
    fa FA_41b(.x(p31), .y(p40), .z(s41a), .s(s41), .c(c41b));

    // weight 5: four bits -> FA then HA
    wire s51a, c51a, s51, c51b;
    fa FA_51a(.x(p14), .y(p23), .z(p32), .s(s51a), .c(c51a));
    ha HA_51b(.x(s51a), .y(p41), .s(s51), .c(c51b));

    // weight 6: three bits -> FA
    wire s61, c61;
    fa FA_61(.x(p24), .y(p33), .z(p42), .s(s61), .c(c61));

    // weight 7: two bits -> HA
    wire s71, c71;
    ha HA_71(.x(p34), .y(p43), .s(s71), .c(c71));

    // weight 8: single bit
    wire s81 = p44;

    // Stage 2 reductions to two rows
    // weight 4 three bits -> FA
    wire s42, c42;
    fa FA_42(.x(s41), .y(c31a), .z(c31b), .s(s42), .c(c42));

    // weight 5 three bits -> FA
    wire s52, c52;
    fa FA_52(.x(s51), .y(c41a), .z(c41b), .s(s52), .c(c52));

    // weight 6 three bits -> FA
    wire s62, c62;
    fa FA_62(.x(s61), .y(c51a), .z(c51b), .s(s62), .c(c62));

    // weight 7 three bits -> FA (s71, c61, c62)
    wire s72, c72;
    fa FA_72(.x(s71), .y(c61), .z(c62), .s(s72), .c(c72));

    // weight 8 three bits -> FA (s81, c71, c72)
    wire s82, c82;
    fa FA_82(.x(s81), .y(c71), .z(c72), .s(s82), .c(c82));

    // Build the final two operand rows for a ripple add
    wire [9:0] X = {
        c82,   // bit 9
        s82,   // bit 8
        s72,   // bit 7
        s62,   // bit 6
        s52,   // bit 5
        s42,   // bit 4
        s31,   // bit 3
        s21,   // bit 2
        s11,   // bit 1
        p00    // bit 0
    };

    wire [9:0] Y = {
        1'b0,      // bit 9
        1'b0,      // bit 8
        1'b0,      // bit 7
        c52,       // bit 6
        c42,       // bit 5
        1'b0,      // bit 4
        c21,       // bit 3
        c11,       // bit 2
        1'b0,      // bit 1
        1'b0       // bit 0
    };

    // Final ripple carry adder
    wire [9:0] sum;
    wire       carry_out;
    rca10 ADD_FINAL(.a(X), .b(Y), .cin(1'b0), .sum(sum), .cout(carry_out));

    assign out  = sum;
    assign cout = carry_out;

endmodule


// 10 bit ripple carry adder used for the final merge
module rca10(
    input  [9:0] a,
    input  [9:0] b,
    input        cin,
    output [9:0] sum,
    output       cout
);
    wire [9:0] c;
    genvar i;
    generate
        for (i = 0; i < 10; i = i + 1) begin : GEN_RCA
            if (i == 0)
                fa FA0(.x(a[i]), .y(b[i]), .z(cin), .s(sum[i]), .c(c[i]));
            else
                fa FAi(.x(a[i]), .y(b[i]), .z(c[i-1]), .s(sum[i]), .c(c[i]));
        end
    endgenerate
    assign cout = c[9];
endmodule

// Full adder
module fa(
    input  x, y, z,
    output s, c
);
    assign s = x ^ y ^ z;
    assign c = (x & y) | (x & z) | (y & z);
endmodule

// Half adder
module ha(
    input  x, y,
    output s, c
);
    assign s = x ^ y;
    assign c = x & y;
endmodule