module processor(
    // Control signals
    clock,
    reset,

    // Imem
    address_imem,
    q_imem,

    // Dmem
    address_dmem,
    data,
    wren,
    q_dmem,

    // Regfile
    ctrl_writeEnable,
    ctrl_writeReg,
    ctrl_readRegA,
    ctrl_readRegB,
    data_writeReg,
    data_readRegA,
    data_readRegB
);
    // Control signals
    input clock, reset;

    // Imem
    output [11:0] address_imem;
    input  [31:0] q_imem;

    // Dmem
    output [11:0] address_dmem;
    output [31:0] data;
    output        wren;
    input  [31:0] q_dmem;

    // Regfile
    output        ctrl_writeEnable;
    output [4:0]  ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
    output [31:0] data_writeReg;
    input  [31:0] data_readRegA, data_readRegB;

    /* YOUR CODE STARTS HERE */
    // % Program counter and instruction fetch
    wire [31:0] pc_q, pc_plus_one, pc_d;
    wire [31:0] const_one = 32'd1;

    alu alu_pc(.data_operandA(pc_q), .data_operandB(const_one), .ctrl_ALUopcode(5'b00000),
               .ctrl_shiftamt(5'b00000), .data_result(pc_plus_one), .isNotEqual(), .isLessThan(), .overflow());

    // default next PC is sequential
//    assign pc_d = pc_plus_one;

    genvar i;
    generate
        for(i = 0; i < 32; i = i + 1) begin: pc_bits
            dffe_ref pc_reg(.q(pc_q[i]), .d(pc_d[i]), .clk(clock), .en(1'b1), .clr(reset));
        end
    endgenerate

    assign address_imem = pc_q[11:0];

    // % Instruction decode
    wire [31:0] instr = q_imem;
    wire [4:0]  opcode = instr[31:27];
    wire [4:0]  rd = instr[26:22];
    wire [4:0]  rs = instr[21:17];
    wire [4:0]  rt = instr[16:12];
    wire [4:0]  shamt = instr[11:7];
    wire [4:0]  func = instr[6:2];
    wire [16:0] imm17 = instr[16:0];

    // sign extend I immediate
    wire [31:0] imm32 = {{15{imm17[16]}}, imm17};

    // JI target T extends with zero in upper bits per spec
    wire [26:0] T = instr[26:0];
    wire [31:0] t32 = {5'b00000, T};

    // % Opcode decodes
    wire [4:0] op_eq_R     = ~(opcode ^ 5'b00000);
    wire [4:0] op_eq_ADDI  = ~(opcode ^ 5'b00101);
    wire [4:0] op_eq_SW    = ~(opcode ^ 5'b00111);
    wire [4:0] op_eq_LW    = ~(opcode ^ 5'b01000);

    // new opcodes per ISA
    wire [4:0] op_eq_J     = ~(opcode ^ 5'b00001); // j T
    wire [4:0] op_eq_BNE   = ~(opcode ^ 5'b00010); // bne
    wire [4:5] __dummy_avoid_verilog_warning = 2'b00; // keeps tool happy with no unused local warnings
    wire [4:0] op_eq_JAL   = ~(opcode ^ 5'b00011); // jal
    wire [4:0] op_eq_JR    = ~(opcode ^ 5'b00100); // jr
    wire [4:0] op_eq_BLT   = ~(opcode ^ 5'b00110); // blt
    wire [4:0] op_eq_SETX  = ~(opcode ^ 5'b10101); // setx
    wire [4:0] op_eq_BEX   = ~(opcode ^ 5'b10110); // bex

    wire isR    = &op_eq_R;
    wire isADDI = &op_eq_ADDI;
    wire isSW   = &op_eq_SW;
    wire isLW   = &op_eq_LW;

    wire isJ    = &op_eq_J;
    wire isBNE  = &op_eq_BNE;
    wire isJAL  = &op_eq_JAL;
    wire isJR   = &op_eq_JR;
    wire isBLT  = &op_eq_BLT;
    wire isSETX = &op_eq_SETX;
    wire isBEX  = &op_eq_BEX;

    // % Func decodes for R
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

    // % Register file read port selects
    // A reads rs for most, but for bex we need $r30 to check nonzero
    wire use_rstatus_on_A = isBEX;
    wire [4:0] sel_readA  = use_rstatus_on_A ? 5'd30 : rs;
    assign ctrl_readRegA  = sel_readA;

    // B reads:
    //   sw uses rd as your original code
    //   branch compares use rd
    //   jr uses rd to fetch the jump target value
    wire isCmp = isBNE | isBLT;
    wire use_rd_on_B = isSW | isJR | isCmp;
    wire [4:0] sel_readB = use_rd_on_B ? rd : rt;
    assign ctrl_readRegB = sel_readB;

    // % Execute
    wire [31:0] aluA = data_readRegA;
    // B operand
    wire use_B_from_reg_for_cmp_or_jr = isCmp | isJR;
    wire [31:0] aluB =
        isR                     ? data_readRegB :
        isCmp                  ? data_readRegB :   // <<< ensure branches use rt
        (isADDI | isSW | isLW)  ? imm32 :
        32'b0;

    wire [4:0] aluOp =
        r_add ? 5'b00000 :
        r_sub ? 5'b00001 :
        r_and ? 5'b00010 :
        r_or  ? 5'b00011 :
        r_sll ? 5'b00100 :
        r_sra ? 5'b00101 :
        isCmp ? 5'b00001 :   // <<< SUB for BNE and BLT	
        5'b00000;

    wire [31:0] aluOut;
    wire aluNe, aluLt, aluOv;

    alu exec_alu(.data_operandA(aluA), .data_operandB(aluB), .ctrl_ALUopcode(aluOp),
                 .ctrl_shiftamt(shamt), .data_result(aluOut), .isNotEqual(aluNe),
                 .isLessThan(aluLt), .overflow(aluOv));

    // dmem interface
    assign address_dmem = aluOut[11:0];
    assign data = data_readRegB;
    assign wren = isSW;

    // % Branch target PC + 1 + N computed by an ALU add
    wire [31:0] pc_branch_target;
    alu alu_pc_br(.data_operandA(pc_plus_one), .data_operandB(imm32), .ctrl_ALUopcode(5'b00000),
                  .ctrl_shiftamt(5'b00000), .data_result(pc_branch_target), .isNotEqual(), .isLessThan(), .overflow());

    // % Branch and jump decisions
    wire bne_taken = isBNE & aluNe;
    wire blt_taken = isBLT & aluNe & ~aluLt;
//	 wire blt_taken = isBLT & ~aluNe;
    wire takeBranch = bne_taken | blt_taken;

    // bex uses rstatus, nonzero check on data_readRegA since we redirected A to $r30
    wire nz_rstatus = |data_readRegA;
    wire bex_taken = isBEX & nz_rstatus;

    // jump target is either JI target or JR register value
    wire [31:0] jr_target = data_readRegB;
    wire use_jr_target = isJR;
    wire [31:0] pc_jump_target = use_jr_target ? jr_target : t32;

    wire takeJump = isJ | isJAL | bex_taken | isJR;

    // final PC mux
    wire [31:0] pc_next_sel_branch = takeBranch ? pc_branch_target : pc_plus_one;
    wire [31:0] pc_next_sel_jump   = takeJump  ? pc_jump_target   : pc_next_sel_branch;

    // override default next PC
    // use explicit wires so the ternary conditions are wires, per style rules
    wire do_pc_jump_or_branch = takeBranch | takeJump;
    wire [31:0] pc_d_final = do_pc_jump_or_branch ? pc_next_sel_jump : pc_plus_one;

    // drive into the PC register bank
    // replace the earlier simple assign to pc_d by this final one
    // to avoid duplicate drivers, we gate through an intermediate wire
    wire [31:0] pc_d_bus = pc_d_final;
    // connect to each bit d input
    // reuse the same generate block d input by renaming the signal
    // note: we already instantiated dffe with .d(pc_d[i]), so we tie pc_d to pc_d_bus
    // keep compatibility
    // tie pc_d to bus
    assign pc_d = pc_d_bus;

    // % Write back
    wire ovAdd  = r_add & aluOv;
    wire ovAddi = isADDI & aluOv;
    wire ovSub  = r_sub & aluOv;
    wire [31:0] rstatVal = ovAdd ? 32'd1 : ovAddi ? 32'd2 : ovSub ? 32'd3 : 32'd0;
    wire willWriteRS = ovAdd | ovAddi | ovSub;

    // new writeback sources
    wire doJal  = isJAL;
    wire doSetx = isSETX;

    wire [31:0] wbVal_core = isLW ? q_dmem : (isR | isADDI) ? aluOut : 32'b0;
    wire [4:0]  wbReg_core = (isR | isADDI | isLW) ? rd : 5'd0;

    // priority: exceptions to r30, then setx to r30, then jal to r31, then core
    wire [31:0] wbVal_after_ex =
        willWriteRS ? rstatVal :
        doSetx      ? t32      :
        doJal       ? pc_plus_one :
        wbVal_core;

    wire [4:0] wbReg_after_ex =
        willWriteRS ? 5'd30 :
        doSetx      ? 5'd30 :
        doJal       ? 5'd31 :
        wbReg_core;

    wire we_core = (isR | isADDI | isLW);
    wire we_with_new = willWriteRS | doSetx | doJal | we_core;

    // block writes to $r0
    wire nz_wreg = |wbReg_after_ex;
    assign ctrl_writeEnable = we_with_new & nz_wreg;

    assign ctrl_writeReg  = wbReg_after_ex;
    assign data_writeReg  = wbVal_after_ex;

endmodule