/**
 * READ THIS DESCRIPTION!
 *
 * The processor takes in several inputs from a skeleton file.
 *
 * Inputs
 * clock: this is the clock for your processor at 50 MHz
 * reset: we should be able to assert a reset to start your pc from 0 (sync or
 * async is fine)
 *
 * Imem: input data from imem
 * Dmem: input data from dmem
 * Regfile: input data from regfile
 *
 * Outputs
 * Imem: output control signals to interface with imem
 * Dmem: output control signals and data to interface with dmem
 * Regfile: output control signals and data to interface with regfile
 *
 * Notes
 *
 * Ultimately, your processor will be tested by subsituting a master skeleton, imem, dmem, so the
 * testbench can see which controls signal you active when. Therefore, there needs to be a way to
 * "inject" imem, dmem, and regfile interfaces from some external controller module. The skeleton
 * file acts as a small wrapper around your processor for this purpose.
 *
 * You will need to figure out how to instantiate two memory elements, called
 * "syncram," in Quartus: one for imem and one for dmem. Each should take in a
 * 12-bit address and allow for storing a 32-bit value at each address. Each
 * should have a single clock.
 *
 * Each memory element should have a corresponding .mif file that initializes
 * the memory element to certain value on start up. These should be named
 * imem.mif and dmem.mif respectively.
 *
 * Importantly, these .mif files should be placed at the top level, i.e. there
 * should be an imem.mif and a dmem.mif at the same level as process.v. You
 * should figure out how to point your generated imem.v and dmem.v files at
 * these MIF files.
 *
 * imem
 * Inputs:  12-bit address, 1-bit clock enable, and a clock
 * Outputs: 32-bit instruction
 *
 * dmem
 * Inputs:  12-bit address, 1-bit clock, 32-bit data, 1-bit write enable
 * Outputs: 32-bit data at the given address
 *
 */
module processor(
    // Control signals
    clock,                          // I: The master clock
    reset,                          // I: A reset signal

    // Imem
    address_imem,                   // O: The address of the data to get from imem
    q_imem,                         // I: The data from imem

    // Dmem
    address_dmem,                   // O: The address of the data to get or put from/to dmem
    data,                           // O: The data to write to dmem
    wren,                           // O: Write enable for dmem
    q_dmem,                         // I: The data from dmem

    // Regfile
    ctrl_writeEnable,               // O: Write enable for regfile
    ctrl_writeReg,                  // O: Register to write to in regfile
    ctrl_readRegA,                  // O: Register to read from port A of regfile
    ctrl_readRegB,                  // O: Register to read from port B of regfile
    data_writeReg,                  // O: Data to write to for regfile
    data_readRegA,                  // I: Data from port A of regfile
    data_readRegB                   // I: Data from port B of regfile
);
    // Control signals
    input clock, reset;

    // Imem
    output [11:0] address_imem;
    input [31:0] q_imem;

    // Dmem
    output [11:0] address_dmem;
    output [31:0] data;
    output wren;
    input [31:0] q_dmem;

    // Regfile
    output ctrl_writeEnable;
    output [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
    output [31:0] data_writeReg;
    input [31:0] data_readRegA, data_readRegB;

    /* YOUR CODE STARTS HERE */
    // % Program counter and fetch
    wire [31:0] pc_q, pc_plus_one, pc_d;
    wire [31:0] const_one = 32'd1;

    alu alu_pc(
        .data_operandA(pc_q),
        .data_operandB(const_one),
        .ctrl_ALUopcode(5'b00000),
        .ctrl_shiftamt(5'b00000),
        .data_result(pc_plus_one),
        .isNotEqual(), .isLessThan(), .overflow()
    );

    genvar i;
    generate
        for(i = 0; i < 32; i = i + 1) begin: pc_bits
            dffe_ref pc_reg(.q(pc_q[i]), .d(pc_d[i]), .clk(clock), .en(1'b1), .clr(reset));
        end
    endgenerate

    assign address_imem = pc_q[11:0];

    // % Instruction fields
    wire [31:0] instr = q_imem;
    wire [4:0] opcode = instr[31:27];
    wire [4:0] rd = instr[26:22];
    wire [4:0] rs = instr[21:17];
    wire [4:0] rt = instr[16:12];
    wire [4:0] shamt = instr[11:7];
    wire [4:0] func = instr[6:2];
    wire [16:0] imm17 = instr[16:0];
    wire [31:0] imm32 = {{15{imm17[16]}}, imm17};
    wire [26:0] tgt27 = instr[26:0];
    wire [31:0] tgt32 = {5'b00000, tgt27};

    // % Opcode decodes
    wire [4:0] op_eq_R     = ~(opcode ^ 5'b00000);
    wire [4:0] op_eq_J     = ~(opcode ^ 5'b00001); // j
    wire [4:0] op_eq_BNE   = ~(opcode ^ 5'b00010); // bne
    wire [4:0] op_eq_JAL   = ~(opcode ^ 5'b00011); // jal
    wire [4:0] op_eq_JR    = ~(opcode ^ 5'b00100); // jr
    wire [4:0] op_eq_ADDI  = ~(opcode ^ 5'b00101);
    wire [4:0] op_eq_BLT   = ~(opcode ^ 5'b00110); // blt
    wire [4:0] op_eq_SW    = ~(opcode ^ 5'b00111);
    wire [4:0] op_eq_LW    = ~(opcode ^ 5'b01000);
    wire [4:0] op_eq_SETX  = ~(opcode ^ 5'b10101); // setx
    wire [4:0] op_eq_BEX   = ~(opcode ^ 5'b10110); // bex

    wire isR    = &op_eq_R;
    wire isJ    = &op_eq_J;
    wire isBNE  = &op_eq_BNE;
    wire isJAL  = &op_eq_JAL;
    wire isJR   = &op_eq_JR;
    wire isADDI = &op_eq_ADDI;
    wire isBLT  = &op_eq_BLT;
    wire isSW   = &op_eq_SW;
    wire isLW   = &op_eq_LW;
    wire isSETX = &op_eq_SETX;
    wire isBEX  = &op_eq_BEX;

    // % Func decodes for R type
    wire [4:0] fn_eq_ADD = ~(func ^ 5'b00000);
    wire [4:0] fn_eq_SUB = ~(func ^ 5'b00001);
    wire [4:0] fn_eq_AND = ~(func ^ 5'b00010);
    wire [4:0] fn_eq_OR  = ~(func ^ 5'b00011);
    wire [4:0] fn_eq_SLL = ~(func ^ 5'b00100);
    wire [4:0] fn_eq_SRA = ~(func ^ 5'b00101);

    wire fADD = &fn_eq_ADD;
    wire fSUB = &fn_eq_SUB;
    wire fAND = &fn_eq_AND;
    wire fOR  = &fn_eq_OR;
    wire fSLL = &fn_eq_SLL;
    wire fSRA = &fn_eq_SRA;
    wire r_add = isR & fADD;
    wire r_sub = isR & fSUB;
    wire r_and = isR & fAND;
    wire r_or  = isR & fOR;
    wire r_sll = isR & fSLL;
    wire r_sra = isR & fSRA;

    // % Regfile port selection
    // A port: rs normally, rd for jr, r30 for bex
    wire [4:0] readA_jr = isJR ? rd : rs;
    assign ctrl_readRegA = isBEX ? 5'd30 : readA_jr;

    // B port: rd for sw bne blt, else rt
    wire useB_rd_sw   = isSW;
    wire useB_rd_brz  = isBNE | isBLT;
    wire useB_rd_any  = useB_rd_sw | useB_rd_brz;
    assign ctrl_readRegB = useB_rd_any ? rd : rt;

    // % Execute
    wire [31:0] aluA = data_readRegA;

    // B operand select
    wire useImm     = isADDI | isSW | isLW;
    wire useBranchB = isBNE | isBLT;

    wire [31:0] aluB =
        isR        ? data_readRegB :
        useImm     ? imm32 :
        useBranchB ? data_readRegB :
                     32'b0;

    // ALU op select, force SUB on branches
    wire [4:0] aluOp = r_add ? 5'b00000 :
                       r_sub ? 5'b00001 :
                       r_and ? 5'b00010 :
                       r_or  ? 5'b00011 :
                       r_sll ? 5'b00100 :
                       r_sra ? 5'b00101 :
                               5'b00000;

    wire useBranchOp = isBNE | isBLT;
    wire [4:0] aluOp_final = useBranchOp ? 5'b00001 : aluOp;

    wire [31:0] aluOut;
    wire aluNe, aluLt, aluOv;

    alu exec_alu(
        .data_operandA(aluA),
        .data_operandB(aluB),
        .ctrl_ALUopcode(aluOp_final),
        .ctrl_shiftamt(shamt),
        .data_result(aluOut),
        .isNotEqual(aluNe),
        .isLessThan(aluLt),
        .overflow(aluOv)
    );

    // Dmem interface
    assign address_dmem = aluOut[11:0];
    assign data = data_readRegB;
    assign wren = isSW;

    // % Branch target PC + 1 + imm
    wire [31:0] pc_plus_one_plus_imm;
    alu alu_pc_br(
        .data_operandA(pc_plus_one),
        .data_operandB(imm32),
        .ctrl_ALUopcode(5'b00000),
        .ctrl_shiftamt(5'b00000),
        .data_result(pc_plus_one_plus_imm),
        .isNotEqual(), .isLessThan(), .overflow()
    );

    // % Branch and jump decisions
    wire take_bne = isBNE & aluNe;
    wire take_blt = isBLT & aluLt;

    // bex when rstatus != 0  A port is r30 when isBEX
    wire a_is_zero = ~(|data_readRegA);
    wire take_bex  = isBEX & ~a_is_zero;

    // jr target from A port when isJR
    wire [31:0] jr_target = data_readRegA;

    // select helpers
    wire use_tgt32 = isJ | isJAL | take_bex;
    wire use_jr    = isJR;
    wire use_br    = take_bne | take_blt;

    // % Next PC
    assign pc_d =
        take_bex        ? tgt32 :
        use_jr          ? jr_target :
        use_tgt32       ? tgt32 :
        use_br          ? pc_plus_one_plus_imm :
                          pc_plus_one;

    // % Write back
    wire ovAdd  = r_add & aluOv;
    wire ovAddi = isADDI & aluOv;
    wire ovSub  = r_sub & aluOv;
    wire [31:0] rstatVal = ovAdd ? 32'd1 : ovAddi ? 32'd2 : ovSub ? 32'd3 : 32'd0;
    wire willWriteRS = ovAdd | ovAddi | ovSub;

    wire [31:0] wbVal = isLW ? q_dmem : (isR | isADDI) ? aluOut : 32'b0;
    wire [4:0] wbReg = (isR | isADDI | isLW) ? rd : 5'd0;

    // jal writes r31 with pc_plus_one
    wire willWriteJAL = isJAL;
    wire [31:0] jalVal = pc_plus_one;
    wire [4:0] jalReg = 5'd31;

    // setx writes r30 with tgt32
    wire willWriteSETX = isSETX;
    wire [31:0] setxVal = tgt32;
    wire [4:0] setxReg = 5'd30;

    // combine writes, overflow to r30 has precedence
    wire willWriteCore = (isR | isADDI | isLW);
    wire anyWriteNoOVF = willWriteCore | willWriteJAL | willWriteSETX;

    wire [31:0] wdat_pre_ovf = willWriteSETX ? setxVal
                               : willWriteJAL ? jalVal
                               : wbVal;

    wire [4:0]  wreg_pre_ovf = willWriteSETX ? setxReg
                               : willWriteJAL ? jalReg
                               : wbReg;

    wire [31:0] wdatFinal = willWriteRS ? rstatVal : wdat_pre_ovf;
    wire [4:0]  wregFinal = willWriteRS ? 5'd30    : wreg_pre_ovf;
    wire        weFinal   = willWriteRS | anyWriteNoOVF;

    // * Write enable control
    wire nz_wreg = |wregFinal;
    assign ctrl_writeEnable = weFinal & nz_wreg;

    assign ctrl_writeReg = wregFinal;
    assign data_writeReg = wdatFinal;

endmodule