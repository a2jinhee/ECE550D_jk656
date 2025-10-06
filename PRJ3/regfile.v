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

    // one hot
    assign q[0] = 32'b0;
    wire [31:0] wr_sel, rdA_sel, rdB_sel;
    // x0 never writes, decode reads for index zero
    assign wr_sel[0]  = 1'b0;
    assign rdA_sel[0] = &(~(ctrl_readRegA ^ 5'd0));
    assign rdB_sel[0] = &(~(ctrl_readRegB ^ 5'd0));

    // decode and register build
    genvar i, b;
    generate
        for (i = 1; i < 32; i = i + 1) begin: GEN_REGS
            localparam [4:0] IDX = i[4:0];

            wire eq_w; // eq_w = 1 when ctrl_writeReg == IDX
            assign eq_w = &(~(ctrl_writeReg ^ IDX));  // AND of XNOR bits
            wire eq_a; // eq_a = 1 when ctrl_readRegA == IDX
            assign eq_a = &(~(ctrl_readRegA ^ IDX));
            wire eq_b; // eq_b = 1 when ctrl_readRegB == IDX
            assign eq_b = &(~(ctrl_readRegB ^ IDX));

            // write select one hot (r0 never writes) // read selects
            assign wr_sel[i] = (i == 0) ? 1'b0 : (ctrl_writeEnable & eq_w);
            assign rdA_sel[i] = eq_a;
            assign rdB_sel[i] = eq_b;

            if (i != 0) begin: GEN_DFFES
                // 32 bit reg made of 32 DFFE cells
                for (b = 0; b < 32; b = b + 1) begin: GEN_BITS
                    // my DFFE 
                    dffe_ref u_dffe (.q (q[i][b]), .d (data_writeReg[b]), .clk (clock), .en (wr_sel[i]), .clr (ctrl_reset));
                end
            end
        end
    endgenerate

    // read port A using tri state drivers
    // only selected reg drives the bus
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
