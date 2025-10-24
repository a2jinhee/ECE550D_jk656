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

  // Override these with +define+RF_SCOPE=your.path if names differ
`ifndef RF_SCOPE
  `define RF_SCOPE dut.my_regfile
`endif

`ifndef CPU_SCOPE
  `define CPU_SCOPE dut.my_processor
`endif

  // Regfile taps
  wire        rf_we       = `RF_SCOPE.ctrl_writeEnable;
  wire [4:0]  rf_waddr    = `RF_SCOPE.ctrl_writeReg;
  wire [31:0] rf_wdata    = `RF_SCOPE.data_writeReg;
  wire [4:0]  rf_raddr_a  = `RF_SCOPE.ctrl_readRegA;
  wire [4:0]  rf_raddr_b  = `RF_SCOPE.ctrl_readRegB;
  wire [31:0] rf_rdata_a  = `RF_SCOPE.data_readRegA;
  wire [31:0] rf_rdata_b  = `RF_SCOPE.data_readRegB;

  // Instruction fetch taps
  wire [11:0] pc_addr     = `CPU_SCOPE.address_imem;  // lower 12 bits of PC
  wire [31:0] instr_word  = `CPU_SCOPE.q_imem;

  // Simple done detection
  localparam [11:0] END_PC = 12'd24;

  initial begin
    for (i = 0; i < 32; i = i + 1) rf_shadow[i] = 32'b0;

    clock_50mhz = 1'b0;
    forever #(CLK_PERIOD_NS/2.0) clock_50mhz = ~clock_50mhz;
  end

  initial begin
    $dumpfile("processor_tb.vcd");
    $dumpvars(0, processor_tb);

    if ($value$plusargs("MAX_CYCLES=%d", max_cycles))
      $display("[TB] MAX_CYCLES=%0d", max_cycles);
    if ($value$plusargs("RESET_CYCLES=%d", reset_cycles))
      $display("[TB] RESET_CYCLES=%0d", reset_cycles);
    if ($value$plusargs("HEARTBEAT=%d", heartbeat_step))
      $display("[TB] HEARTBEAT=%d", heartbeat_step);

    reset_n = 1'b1;
    cycle   = 0;

    repeat (reset_cycles) begin
      @(posedge clock_50mhz);
      cycle = cycle + 1;
    end

    reset_n = 1'b0;

    for (cycle = cycle; cycle < max_cycles; cycle = cycle + 1) begin
      @(posedge clock_50mhz);

      // Optional heartbeat
      if (heartbeat_step > 0 && (cycle % heartbeat_step) == 0) begin
        $display("[TB] cycle %0d time %0t", cycle, $time);
      end

      // Stop condition when PC reaches the end loop
      if (pc_addr == END_PC) begin
        $display("[TB] reached END_PC=%0d at time %0t", END_PC, $time);
        disable all_done;
      end
    end

  all_done:
    $display("[TB] run complete at time %0t", $time);
    $display("==== Final regfile snapshot nonzero ====");
    for (i = 0; i < 32; i = i + 1) begin
      if (rf_shadow[i] !== 32'b0)
        $display("r%0d = 0x%08h %0d", i, rf_shadow[i], rf_shadow[i]);
    end
    $finish;
  end

  // Log instruction fetch with PC each processor clock
  always @(posedge processor_clock) begin
    $strobe("[IF] PC=%0d INSTR=0x%08h time=%0t", pc_addr, instr_word, $time);
  end

  // Update shadow file on regfile writes
  always @(posedge regfile_clock) begin
    if (rf_we && rf_waddr != 5'd0) begin
      rf_shadow[rf_waddr] <= rf_wdata;
      if (rf_waddr == 5'd30)
        $display("[RF] rstatus <= 0x%08h time %0t", rf_wdata, $time);
      else if (rf_waddr == 5'd31)
        $display("[RF] ra <= 0x%08h time %0t", rf_wdata, $time);
      else
        $display("[RF] r%0d <= 0x%08h time %0t", rf_waddr, rf_wdata, $time);
    end
  end

  // Live view of read ports
  always @(posedge regfile_clock) begin
    $strobe("[RF] A r%0d=0x%08h  B r%0d=0x%08h",
            rf_raddr_a, rf_rdata_a, rf_raddr_b, rf_rdata_b);
  end

endmodule