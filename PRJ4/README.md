### Name: Jinhee Kim
### netID: jk656

### Design overview
This design implements a single-cycle 32-bit processor that supports all required R-type and I-type instructions for Checkpoint 4: add, sub, and, or, sll, sra, addi, lw, and sw.
The processor integrates previously designed modules—ALU, register file, and program counter (PC)—with memory and control logic. On each rising clock edge, one instruction is fetched from instruction memory (imem), decoded, executed by the ALU, and written back to the register file or data memory (dmem).

### Key design choices
- Structural decoding: Opcode and function fields are decoded using bitwise comparison and reduction operators (~, ^, &), avoiding banned behavioral operators like == or !=.
- Synchronous PC and register file: The PC is built from 32 DFFEs updated every cycle, allowing the next instruction address to increment automatically.
- Minimal control path: No multiplexers or case statements are used; instruction type signals (isR, isADDI, isLW, isSW) directly select ALU operands and write-back data through ternary assigns.
- Exception handling: Overflow conditions set $rstatus ($r30) according to ISA rules (1 = ADD overflow, 2 = ADDI overflow, 3 = SUB overflow).
- Modular clocking: All modules share the same 50 MHz clock for clarity and functional correctness before later pipelining.

### Modules
- processor.v: Core datapath and control logic. Handles instruction fetch, decode, execute, memory access, and write-back.
- alu.v: Performs arithmetic, logic, and shift operations; generates overflow, less-than, and not-equal flags.
- regfile.v: Contains 32 registers; supports two asynchronous read ports and one synchronous write port with reset to 0.
- dffe.v: Simple D-flip-flop with enable and asynchronous clear for PC registers.
- imem.v / dmem.v: Quartus-generated synchronous memory blocks initialized by .mif files.
- skeleton.v: Top-level wrapper that connects the processor to imem, dmem, and regfile modules with pass-through clocks.

### Testing and Bugs summary
Testing used basic_test.s, assembled to .mif and .hex files, verifying arithmetic, logic, shift, and memory instructions.
Simulation confirms correct PC increment, instruction fetch, and register updates (e.g., $r3 = 8, $r4 = 2, $r12/$r13 load 345 and 567).
Minor early bugs included illegal use of behavioral comparisons and incorrect sign-extension of immediates, both fixed.
Hardware synthesis on Quartus completes with no errors, and runtime output matches expected register values.