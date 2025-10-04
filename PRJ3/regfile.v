module regfile (
    clock,
    ctrl_writeEnable,
    ctrl_reset, ctrl_writeReg,
    ctrl_readRegA, ctrl_readRegB, data_writeReg,
    data_readRegA, data_readRegB
);

   input clock, ctrl_writeEnable, ctrl_reset;
   input [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
   input [31:0] data_writeReg;

   output [31:0] data_readRegA, data_readRegB;

   /* YOUR CODE HERE */
   // storage array outputs from each register
    wire [31:0] q [31:0];

    // force r0 to constant zero and never write it
    // q[0] is tied to 0 so it always reads as 0
    assign q[0] = 32'b0;

    // one hot write enables for regs 0..31
    // wr_sel[i] is high when ctrl_writeReg == i
    wire [31:0] wr_sel;

    // read selects for A and B
    wire [31:0] rdA_sel;
    wire [31:0] rdB_sel;

    // decode and register build
    genvar i, b;
    generate
        for (i = 0; i < 32; i = i + 1) begin: GEN_REGS
            // index constant for this block
            localparam [4:0] IDX = i[4:0];

            // equality using only bitwise ops
            // eq_w = 1 when ctrl_writeReg == IDX
            wire eq_w;
            assign eq_w = &(~(ctrl_writeReg ^ IDX));  // AND of XNOR bits

            // eq_a = 1 when ctrl_readRegA == IDX
            wire eq_a;
            assign eq_a = &(~(ctrl_readRegA ^ IDX));

            // eq_b = 1 when ctrl_readRegB == IDX
            wire eq_b;
            assign eq_b = &(~(ctrl_readRegB ^ IDX));

            // write select one hot
            // r0 never writes
            assign wr_sel[i] = (i == 0) ? 1'b0 : (ctrl_writeEnable & eq_w);

            // read selects
            assign rdA_sel[i] = eq_a;
            assign rdB_sel[i] = eq_b;

            if (i != 0) begin: GEN_DFFES
                // 32 bit register made of 32 DFFE cells
                for (b = 0; b < 32; b = b + 1) begin: GEN_BITS
                    // Instantiation of your DFFE primitive
                    // Adjust port names here if your dffe.v uses different ones
                    dffe u_dffe (
                        .q   (q[i][b]),
                        .d   (data_writeReg[b]),
                        .clk (clock),
                        .en  (wr_sel[i]),
                        .clr (ctrl_reset)
                    );
                end
            end
        end
    endgenerate

    // Read port A bus using tri state drivers
    // Only the selected register drives the bus, others drive Z
    // r0 already tied to zero so it is safe
    // Note: multiple continuous assigns to the same net form a wired bus
    // The project note allows this ternary tri state style
    genvar ia;
    generate
        for (ia = 0; ia < 32; ia = ia + 1) begin: GEN_READ_A
            assign data_readRegA = rdA_sel[ia] ? q[ia] : 32'bz;
        end
    endgenerate

    // Read port B bus
    genvar ib;
    generate
        for (ib = 0; ib < 32; ib = ib + 1) begin: GEN_READ_B
            assign data_readRegB = rdB_sel[ib] ? q[ib] : 32'bz;
        end
    endgenerate

endmodule
