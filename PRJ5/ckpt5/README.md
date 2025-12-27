# Checkpoint 5 – Full Processor

**Team Members**
- **Ruxin Xue** (rx66)  
- **Jinhee Kim** (jk656)

---

## Design Description
Our design implements a **single-cycle 32-bit processor** based on the Duke ECE 551 ISA. It integrates the ALU, register file, data memory, instruction memory, and control logic within the `skeleton` wrapper.

We used a **hierarchical modular design** and a **clock divider** to generate four clock domains (`imem_clock`, `dmem_clock`, `processor_clock`, `regfile_clock`) from the 50 MHz input clock.  
The processor supports all R-, I-, and J-type instructions, including `add`, `sub`, `and`, `or`, `lw`, `sw`, `addi`, `bne`, `blt`, `j`, `jal`, `jr`, `setx`, and `bex`.  
Branch and jump logic is handled by ALU-based comparisons and target address computation.  
Overflow and status register handling for `$r30` (`$rstatus`) and return address handling for `$r31` (`$ra`) are fully implemented.  
After reset, all registers are cleared and the program counter starts from 0. The design runs stably under the divided 12.5 MHz processor clock.

---

## Module Summaries

### `skeleton.v`
Top-level wrapper connecting processor, imem, dmem, and regfile; generates and routes four clocks for different modules.

### `processor.v`
Implements the core datapath and control logic for fetch, decode, execute, memory, and write-back within a single cycle.

### `alu.v`
Performs arithmetic and logical operations (`add`, `sub`, `and`, `or`, `sll`, `sra`) and outputs `isNotEqual`, `isLessThan`, and `overflow`.

### `regfile.v`
32×32-bit register file with two read ports and one write port; resets all registers to zero and keeps `$r0` constant zero.

### `imem.v` / `dmem.v`
Quartus megafunctions (`altsyncram`) implementing instruction and data memories, each 4096 × 32 bits.

### `dffe_ref.v`
D-flip-flop with enable and asynchronous clear used for the program counter and state registers.

### `clk_div_4.v`
Clock divider that reduces the 50 MHz clock to 12.5 MHz for processor and regfile operation.

---

## Known Issues / Bugs
One subtle but serious bug came from the mismatch between how the BLT instruction is defined in the ISA and how the processor wired operands into the ALU. The BLT specification requires branching when R[rd] < R[rs], but the processor fed R[rs] into the ALU’s A input and R[rd] into the B input. Since the ALU only provides flags for A < B and A != B, BLT could not be checked directly and the condition needed to be rewritten. The original implementation incorrectly used only ~aluLt, which made BLT fire on both the greater case and the equal case, causing partial scoring on graded tests. The correct condition combines aluNe and ~aluLt to capture exactly R[rd] < R[rs] under the processor’s operand order.