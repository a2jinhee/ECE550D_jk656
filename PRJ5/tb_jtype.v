`timescale 1ns/1ps

module tb_jtype();
    reg clock;
    reg reset;
    
    wire imem_clock, dmem_clock, processor_clock, regfile_clock;
    
    skeleton uut (
        .clock(clock),
        .reset(reset),
        .imem_clock(imem_clock),
        .dmem_clock(dmem_clock),
        .processor_clock(processor_clock),
        .regfile_clock(regfile_clock)
    );
    
    // 50MHz clock
    initial begin
        clock = 0;
        forever #10 clock = ~clock;
    end
    
    // Reset
    initial begin
        reset = 1;
        #35;
        reset = 0;
    end
    
    // Test
    initial begin
        $display("========== J-Type Instructions Test ==========");
        
        // Run for enough time
        #10000;
        
        $display("\n========== Checking Results ==========\n");
        
        // Force read registers
        @(posedge clock);
        
        // Initial values
        force uut.my_processor.ctrl_readRegA = 5'd1;
        @(posedge clock); #1;
        $display("r1  = %d - Expected: 100", uut.my_processor.data_readRegA);
        
        force uut.my_processor.ctrl_readRegA = 5'd2;
        @(posedge clock); #1;
        $display("r2  = %d - Expected: 200", uut.my_processor.data_readRegA);
        
        // Test 1: j instruction
        force uut.my_processor.ctrl_readRegA = 5'd3;
        @(posedge clock); #1;
        $display("\n--- Test 1: j instruction ---");
        $display("r3  = %d - Expected: 50 (addresses 4-9 should be skipped)", 
                 uut.my_processor.data_readRegA);
        
        // Test 2: jal/jr
        force uut.my_processor.ctrl_readRegA = 5'd4;
        @(posedge clock); #1;
        $display("\n--- Test 2: jal and jr ---");
        $display("r4  = %d - Expected: 11 (executed after jr return)", 
                 uut.my_processor.data_readRegA);
        
        force uut.my_processor.ctrl_readRegA = 5'd5;
        @(posedge clock); #1;
        $display("r5  = %d - Expected: 77 (from function)", 
                 uut.my_processor.data_readRegA);
        
        force uut.my_processor.ctrl_readRegA = 5'd6;
        @(posedge clock); #1;
        $display("r6  = %d - Expected: 300 (100+200 from function)", 
                 uut.my_processor.data_readRegA);
        
        force uut.my_processor.ctrl_readRegA = 5'd31;
        @(posedge clock); #1;
        $display("r31 = %d - Expected: 12 (return address from jal)", 
                 uut.my_processor.data_readRegA);
        
        // Test 3: bne
        force uut.my_processor.ctrl_readRegA = 5'd7;
        @(posedge clock); #1;
        $display("\n--- Test 3: bne instruction ---");
        $display("r7  = %d - Expected: 10", uut.my_processor.data_readRegA);
        
        force uut.my_processor.ctrl_readRegA = 5'd8;
        @(posedge clock); #1;
        $display("r8  = %d - Expected: 20", uut.my_processor.data_readRegA);
        
        force uut.my_processor.ctrl_readRegA = 5'd9;
        @(posedge clock); #1;
        $display("r9  = %d - Expected: 33 (bne branch taken)", 
                 uut.my_processor.data_readRegA);
        
        force uut.my_processor.ctrl_readRegA = 5'd10;
        @(posedge clock); #1;
        $display("r10 = %d - Expected: 44 (bne not taken)", 
                 uut.my_processor.data_readRegA);
        
        // Test 4: blt
        force uut.my_processor.ctrl_readRegA = 5'd11;
        @(posedge clock); #1;
        $display("\n--- Test 4: blt instruction ---");
        $display("r11 = %d - Expected: 5", uut.my_processor.data_readRegA);
        
        force uut.my_processor.ctrl_readRegA = 5'd12;
        @(posedge clock); #1;
        $display("r12 = %d - Expected: 15", uut.my_processor.data_readRegA);
        
        force uut.my_processor.ctrl_readRegA = 5'd13;
        @(posedge clock); #1;
        $display("r13 = %d - Expected: 55 (blt branch taken)", 
                 uut.my_processor.data_readRegA);
        
        force uut.my_processor.ctrl_readRegA = 5'd14;
        @(posedge clock); #1;
        $display("r14 = %d - Expected: 66 (blt not taken)", 
                 uut.my_processor.data_readRegA);
        
        // Test 5: setx and bex
        force uut.my_processor.ctrl_readRegA = 5'd15;
        @(posedge clock); #1;
        $display("\n--- Test 5: setx and bex ---");
        $display("r15 = %d - Expected: 88 (bex branch taken)", 
                 uut.my_processor.data_readRegA);
        
        force uut.my_processor.ctrl_readRegA = 5'd16;
        @(posedge clock); #1;
        $display("r16 = %d - Expected: 99 (bex not taken)", 
                 uut.my_processor.data_readRegA);
        
        // Test 6: Exception + bex
        force uut.my_processor.ctrl_readRegA = 5'd17;
        @(posedge clock); #1;
        $display("\n--- Test 6: Exception and bex ---");
        $display("r17 = %d - Expected: 32767", uut.my_processor.data_readRegA);
        
        force uut.my_processor.ctrl_readRegA = 5'd19;
        @(posedge clock); #1;
        $display("r19 = %d - Expected: 111 (bex after overflow)", 
                 uut.my_processor.data_readRegA);
        
        force uut.my_processor.ctrl_readRegA = 5'd30;
        @(posedge clock); #1;
        $display("r30 = %d - Expected: 2 (overflow exception code)", 
                 uut.my_processor.data_readRegA);
        
        // Final
        force uut.my_processor.ctrl_readRegA = 5'd20;
        @(posedge clock); #1;
        $display("\n--- Final ---");
        $display("r20 = %d - Expected: 255 (program completed)", 
                 uut.my_processor.data_readRegA);
        
        release uut.my_processor.ctrl_readRegA;
        
        $display("\n========== Test Complete ==========");
        #100;
        $finish;
    end

endmodule