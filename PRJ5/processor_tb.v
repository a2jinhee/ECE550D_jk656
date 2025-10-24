`timescale 1ns/1ps

module processor_tb;

  localparam real CLK_PERIOD_NS = 20.0;

  reg  clock_50mhz;
  reg  reset_n;
  wire imem_clock;
  wire dmem_clock;
  wire processor_clock;
  wire regfile_clock;

  integer max_cycles     = 2000;
  integer reset_cycles   = 8;
  integer heartbeat_step = 100;
  integer cycle;

  // simple scoreboard of architectural regs as seen on regfile writes
  reg [31:0] rf_shadow [0:31];
  integer i;

  skeleton dut (
    .clock           (clock_50mhz),
    .reset           (reset_n),
    .imem_clock      (imem_clock),
    .dmem_clock      (dmem_clock),
    .processor_clock (processor_clock),
    .regfile_clock   (regfile_clock)
  );

`ifndef RF_SCOPE
  `define RF_SCOPE dut.my_regfile
`endif

`ifndef CPU_SCOPE
  `define CPU_SCOPE dut.my_processor
`endif

  // taps to regfile
  wire        rf_we       = `RF_SCOPE.ctrl_writeEnable;
  wire [4:0]  rf_waddr    = `RF_SCOPE.ctrl_writeReg;
  wire [31:0] rf_wdata    = `RF_SCOPE.data_writeReg;
  wire [4:0]  rf_raddr_a  = `RF_SCOPE.ctrl_readRegA;
  wire [4:0]  rf_raddr_b  = `RF_SCOPE.ctrl_readRegB;
  wire [31:0] rf_rdata_a  = `RF_SCOPE.data_readRegA; // used for jr target and bex status
  wire [31:0] rf_rdata_b  = `RF_SCOPE.data_readRegB;

  // taps to processor fetch
  wire [11:0] pc_addr    = `CPU_SCOPE.address_imem;  // low 12 bits of PC
  wire [31:0] instr_word = `CPU_SCOPE.q_imem;

  // decode helpers on the fly
  wire [4:0]  opcode = instr_word[31:27];
  wire [26:0] Tfield = instr_word[26:0];
  wire [31:0] T32    = {5'b00000, Tfield};
  wire [16:0] Nfield = instr_word[16:0];
  wire [31:0] Nsext  = {{15{Nfield[16]}}, Nfield};

  // end condition for the demo program
  localparam [11:0] END_PC = 12'd24;

  // previous cycle latches for checking next PC
  reg [11:0] pc_prev;
  reg [31:0] instr_prev;
  reg        have_prev;

  // bookkeeping to check jal and setx writes against expected values
  reg        expect_jal_write;
  reg [31:0] expect_jal_value;
  reg        expect_setx_write;
  reg [31:0] expect_setx_value;

  // a small pretty printer for opcodes
  function [79*8:1] op_name;
    input [4:0] op;
    begin
      case (op)
        5'b00001: op_name = "j";
        5'b00010: op_name = "bne";
        5'b00011: op_name = "jal";
        5'b00100: op_name = "jr";
        5'b00110: op_name = "blt";
        5'b10101: op_name = "setx";
        5'b10110: op_name = "bex";
        default:  op_name = "other";
      endcase
    end
  endfunction

  // clock gen
  initial begin
    for (i = 0; i < 32; i = i + 1) rf_shadow[i] = 32'b0;
    clock_50mhz = 1'b0;
    forever #(CLK_PERIOD_NS/2.0) clock_50mhz = ~clock_50mhz;
  end

  // waveform dump
  initial begin
    $dumpfile("processor_tb.vcd");
    $dumpvars(0, processor_tb);
  end

  // reset and run
  initial begin : RUN
    // allow plusargs to tweak lengths
    if ($value$plusargs("MAX_CYCLES=%d", max_cycles))
      $display("[TB] MAX_CYCLES=%0d", max_cycles);
    if ($value$plusargs("RESET_CYCLES=%d", reset_cycles))
      $display("[TB] RESET_CYCLES=%0d", reset_cycles);
    if ($value$plusargs("HEARTBEAT=%d", heartbeat_step))
      $display("[TB] HEARTBEAT=%0d", heartbeat_step);

    reset_n = 1'b1;
    cycle   = 0;
    have_prev = 1'b0;
    expect_jal_write  = 1'b0;
    expect_setx_write = 1'b0;

    repeat (reset_cycles) begin
      @(posedge clock_50mhz);
      cycle = cycle + 1;
    end
    reset_n = 1'b0;

    for (cycle = cycle; cycle < max_cycles; cycle = cycle + 1) begin
      @(posedge processor_clock);

      // log fetch
      $strobe("[IF] PC=%0d INSTR=0x%08h OP=%s T=%0d N=%0d t=%0t",
              pc_addr, instr_word, op_name(opcode), T32[11:0], $signed(Nsext), $time);

      // check previous instruction effect on PC
      if (have_prev) begin
        check_pc_transition(pc_prev, instr_prev, pc_addr);
      end

      // remember current for next cycle check
      pc_prev    <= pc_addr;
      instr_prev <= instr_word;
      have_prev  <= 1'b1;

      if (heartbeat_step > 0 && (cycle % heartbeat_step) == 0) begin
        $display("[TB] cycle %0d time %0t", cycle, $time);
      end

      if (pc_addr == END_PC) begin
        $display("[TB] reached END_PC=%0d time %0t", END_PC, $time);
        disable RUN;
      end
    end

    $display("[TB] timeout at time %0t", $time);
    $finish;
  end

  // check regfile writes and keep a mirror
  always @(posedge regfile_clock) begin
    if (rf_we && rf_waddr != 5'd0) begin
      rf_shadow[rf_waddr] <= rf_wdata;
      $display("[RF] r%0d <= 0x%08h time %0t", rf_waddr, rf_wdata, $time);

      // verify jal link when expected
      if (expect_jal_write && rf_waddr == 5'd31) begin
        if (rf_wdata !== expect_jal_value) begin
          $display("[FAIL] jal wrote r31=0x%08h expected 0x%08h", rf_wdata, expect_jal_value);
          $fatal;
        end else begin
          $display("[PASS] jal link r31=0x%08h", rf_wdata);
        end
        expect_jal_write <= 1'b0;
      end

      // verify setx when expected
      if (expect_setx_write && rf_waddr == 5'd30) begin
        if (rf_wdata !== expect_setx_value) begin
          $display("[FAIL] setx wrote r30=0x%08h expected 0x%08h", rf_wdata, expect_setx_value);
          $fatal;
        end else begin
          $display("[PASS] setx r30=0x%08h", rf_wdata);
        end
        expect_setx_write <= 1'b0;
      end
    end
  end

  // function to check PC transition for control flow
  task check_pc_transition;
    input [11:0] pc_prev_local;   // low 12 bits
    input [31:0] instr_prev_local;
    input [11:0] pc_now_local;    // low 12 bits
    reg   [4:0]  op;
    reg   [26:0] Tloc;
    reg   [31:0] Tloc32;
    reg   [16:0] Nloc;
    reg   [31:0] Nsext_loc;
    reg   [11:0] expect_pc_low;
    begin
      op        = instr_prev_local[31:27];
      Tloc      = instr_prev_local[26:0];
      Tloc32    = {5'b00000, Tloc};
      Nloc      = instr_prev_local[16:0];
      Nsext_loc = {{15{Nloc[16]}}, Nloc};

      expect_pc_low = pc_prev_local + 12'd1; // default fall through

      case (op)
        5'b00001: begin // j
          expect_pc_low = Tloc32[11:0];
          if (pc_now_local !== expect_pc_low) begin
            $display("[FAIL] j expected PC=%0d got %0d", expect_pc_low, pc_now_local);
            $fatal;
          end else $display("[PASS] j to %0d", pc_now_local);
        end

        5'b00011: begin // jal
          expect_pc_low = Tloc32[11:0];
          expect_jal_write <= 1'b1;
          expect_jal_value <= {20'b0, pc_prev_local} + 32'd1; // full 32 bit add of PC plus 1
          if (pc_now_local !== expect_pc_low) begin
            $display("[FAIL] jal expected PC=%0d got %0d", expect_pc_low, pc_now_local);
            $fatal;
          end else $display("[PASS] jal to %0d and will check r31", pc_now_local);
        end

        5'b00100: begin // jr  PC becomes value on A port in that cycle
          expect_pc_low = rf_rdata_a[11:0];
          if (pc_now_local !== expect_pc_low) begin
            $display("[FAIL] jr expected PC=%0d got %0d (A=0x%08h)", expect_pc_low, pc_now_local, rf_rdata_a);
            $fatal;
          end else $display("[PASS] jr to %0d", pc_now_local);
        end

        5'b00010: begin // bne  compare rd vs rs inside CPU, we cannot see flags here, so validate by outcome against both possibilities
          // expected taken target
          if (pc_now_local == (pc_prev_local + 12'd1 + Nsext_loc[11:0])) begin
            $display("[PASS] bne taken to %0d", pc_now_local);
          end else if (pc_now_local == (pc_prev_local + 12'd1)) begin
            $display("[PASS] bne not taken to %0d", pc_now_local);
          end else begin
            $display("[FAIL] bne unexpected PC=%0d from prev %0d N=%0d", pc_now_local, pc_prev_local, $signed(Nsext_loc));
            $fatal;
          end
        end

        5'b00110: begin // blt
          if (pc_now_local == (pc_prev_local + 12'd1 + Nsext_loc[11:0])) begin
            $display("[PASS] blt taken to %0d", pc_now_local);
          end else if (pc_now_local == (pc_prev_local + 12'd1)) begin
            $display("[PASS] blt not taken to %0d", pc_now_local);
          end else begin
            $display("[FAIL] blt unexpected PC=%0d from prev %0d N=%0d", pc_now_local, pc_prev_local, $signed(Nsext_loc));
            $fatal;
          end
        end

        5'b10101: begin // setx  only verifies the write here, PC falls through
          expect_setx_write <= 1'b1;
          expect_setx_value <= Tloc32;
          if (pc_now_local !== (pc_prev_local + 12'd1)) begin
            $display("[FAIL] setx should fall through to %0d got %0d", pc_prev_local + 12'd1, pc_now_local);
            $fatal;
          end else $display("[PASS] setx fall through and will check r30");
        end

        5'b10110: begin // bex  jump when rstatus != 0, we read it on A port this cycle
          if (rf_raddr_a !== 5'd30) begin
            $display("[WARN] bex A port did not select r30 as expected");
          end
          if (rf_rdata_a != 32'b0) begin
            expect_pc_low = Tloc32[11:0];
            if (pc_now_local !== expect_pc_low) begin
              $display("[FAIL] bex expected PC=%0d got %0d", expect_pc_low, pc_now_local);
              $fatal;
            end else $display("[PASS] bex taken to %0d", pc_now_local);
          end else begin
            expect_pc_low = pc_prev_local + 12'd1;
            if (pc_now_local !== expect_pc_low) begin
              $display("[FAIL] bex fall through expected PC=%0d got %0d", expect_pc_low, pc_now_local);
              $fatal;
            end else $display("[PASS] bex not taken to %0d", pc_now_local);
          end
        end

        default: begin
          // non control flow
          if (pc_now_local !== (pc_prev_local + 12'd1)) begin
            $display("[FAIL] seq PC expected %0d got %0d", pc_prev_local + 12'd1, pc_now_local);
            $fatal;
          end
        end
      endcase
    end
  endtask

endmodule