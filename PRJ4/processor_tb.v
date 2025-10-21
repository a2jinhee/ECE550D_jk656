`timescale 1ns/1ps

module processor_tb;

  localparam real CLK_PERIOD_NS = 20.0;

  reg  clock_50mhz;
  reg  reset_n;
  wire imem_clock;
  wire dmem_clock;
  wire processor_clock;
  wire regfile_clock;

  integer max_cycles     = 300;
  integer reset_cycles   = 5;
  integer heartbeat_step = 100;
  integer cycle;

  // Shadow copy of architectural registers
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

  // Set the hierarchical scope of the regfile instance
`ifndef RF_SCOPE
  `define RF_SCOPE dut.my_regfile
`endif

  // Tap common reference regfile ports
  wire        rf_we       = `RF_SCOPE.ctrl_writeEnable;
  wire [4:0]  rf_waddr    = `RF_SCOPE.ctrl_writeReg;
  wire [31:0] rf_wdata    = `RF_SCOPE.data_writeReg;
  wire [4:0]  rf_raddr_a  = `RF_SCOPE.ctrl_readRegA;
  wire [4:0]  rf_raddr_b  = `RF_SCOPE.ctrl_readRegB;
  wire [31:0] rf_rdata_a  = `RF_SCOPE.data_readRegA;
  wire [31:0] rf_rdata_b  = `RF_SCOPE.data_readRegB;

  initial begin
    // init shadow file
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
      $display("[TB] HEARTBEAT=%0d", heartbeat_step);

    reset_n = 1'b1;
    cycle   = 0;

    repeat (reset_cycles) begin
      @(posedge clock_50mhz);
      cycle = cycle + 1;
    end

    reset_n = 1'b0;

    for (cycle = cycle; cycle < max_cycles; cycle = cycle + 1) begin
      @(posedge clock_50mhz);
      if (heartbeat_step > 0 && (cycle % heartbeat_step) == 0) begin
        $display("[TB] cycle %0d time %0t", cycle, $time);
      end
    end

    $display("[TB] run complete at time %0t", $time);

    // print nonzero registers from the shadow file
    $display("==== Final regfile snapshot (nonzero) ====");
    for (i = 0; i < 32; i = i + 1) begin
      if (rf_shadow[i] !== 32'b0)
        $display("r%0d = 0x%08h (%0d)", i, rf_shadow[i], rf_shadow[i]);
    end
    $finish;
  end

  // Update shadow file on regfile write
  always @(posedge regfile_clock) begin
    if (rf_we) begin
      // ignore writes to r0 per spec
      if (rf_waddr != 5'd0) begin
        rf_shadow[rf_waddr] <= rf_wdata;
        if (rf_waddr == 5'd30)
          $display("[RF] rstatus write 0x%08h at time %0t", rf_wdata, $time);
        else
          $display("[RF] write r%0d <= 0x%08h at time %0t", rf_waddr, rf_wdata, $time);
      end
    end
  end

  // Optional live view of read ports to help debug hazards and bypass
  always @(posedge regfile_clock) begin
    $strobe("[RF] read A r%0d=0x%08h  read B r%0d=0x%08h",
            rf_raddr_a, rf_rdata_a, rf_raddr_b, rf_rdata_b);
  end
  

endmodule