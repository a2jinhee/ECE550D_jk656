`timescale 1ns/1ps

module processor_jump_tb;

  reg clock, reset;
  integer cycle;

  wire [11:0] pc;
  wire [31:0] instr;

  // Instantiate top-level skeleton
  skeleton dut (
    .clock           (clock),
    .reset           (reset),
    .imem_clock      (),
    .dmem_clock      (),
    .processor_clock (),
    .regfile_clock   ()
  );

  // --- Define the hierarchical paths (adjust if needed)
  wire [11:0] pc_addr    = dut.my_processor.address_imem;
  wire [31:0] instr_word = dut.my_processor.q_imem;

  assign pc    = pc_addr;
  assign instr = instr_word;

  // --- Clock generation
  initial begin
    clock = 0;
    forever #10 clock = ~clock; // 50 MHz
  end

  // --- Reset and run
  initial begin
    $dumpfile("processor_jump_tb.vcd");
    $dumpvars(0, processor_jump_tb);

    reset = 1;
    repeat (5) @(posedge clock);
    reset = 0;

    $display("\n==== Running jump test ====\n");

    for (cycle = 0; cycle < 2000; cycle = cycle + 1) begin
      @(posedge clock);
      $display("[CYCLE %0d] PC=%0d  INSTR=0x%08h", cycle, pc, instr);

      // Detect jumps (simple heuristic)
      if (cycle > 0 && pc !== prev_pc + 1)
        $display("  --> Jump detected: from %0d to %0d", prev_pc, pc);

      prev_pc = pc;
    end

    $display("\n==== Test finished ====\n");
    $finish;
  end

  reg [11:0] prev_pc;

endmodule