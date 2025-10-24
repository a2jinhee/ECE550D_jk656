`timescale 1ns/1ps

module processor_jump_tb;

  reg clock, reset;
  integer cycle;
  reg [11:0] prev_pc;    // <-- define once here (no duplicates)

  // Connect to DUT
  wire [11:0] pc_addr;
  wire [31:0] instr_word;

  // instantiate skeleton (your top-level)
  skeleton dut (
    .clock           (clock),
    .reset           (reset),
    .imem_clock      (),
    .dmem_clock      (),
    .processor_clock (),
    .regfile_clock   ()
  );

  // hierarchical access (adjust if needed)
  assign pc_addr    = dut.my_processor.address_imem;
  assign instr_word = dut.my_processor.q_imem;

  // clock generation (50 MHz)
  initial begin
    clock = 1'b0;
    forever #10 clock = ~clock;
  end

  // reset + run test
  initial begin
    $dumpfile("processor_jump_tb.vcd");
    $dumpvars(0, processor_jump_tb);

    reset   = 1'b1;
    prev_pc = 12'd0;
    repeat (5) @(posedge clock);
    reset = 1'b0;

    $display("\n==== Running Jump Test ====\n");

    for (cycle = 0; cycle < 2000; cycle = cycle + 1) begin
      @(posedge clock);
      $display("[CYCLE %0d] PC=%0d  INSTR=0x%08h", cycle, pc_addr, instr_word);

      // detect any non-sequential PC changes (jump / branch)
      if (cycle > 0 && pc_addr !== prev_pc + 1)
        $display("  --> Jump detected: from %0d to %0d", prev_pc, pc_addr);

      prev_pc = pc_addr;

      // stop if we hit end loop (address 24)
      if (pc_addr == 12'd24) begin
        $display("\n==== Reached end loop at PC=24 ====\n");
        $finish;
      end
    end

    $display("\n==== Timeout: No end loop detected ====\n");
    $finish;
  end

endmodule