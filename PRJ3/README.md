### Name: Jinhee Kim
### netID: jk656

### Design overview
I implemented a 32-register register file that supports:
- 32 registers (r0-r31), each 32 bits wide
- Two simultaneous read ports (A and B) 
- One write port with write enable control
- Synchronous write operations on positive clock edge
- Asynchronous reset capability
- Register r0 is hardwired to always read as 0 and cannot be written
The design uses D flip-flops with enable (DFFE) as the basic storage elements and implements address decoding for register selection using tri-state drivers for the read ports.

### Key design choices
1. **Register r0 Implementation**: Register 0 is implemented as a constant 0 output rather than actual storage, ensuring it always reads 0 regardless of write attempts.
2. **Address Decoding**: Used bitwise XNOR followed by AND reduction (`&(~(address ^ index))`) to generate equality signals for register selection. This creates a clean one-hot encoding for register enables.
3. **Tri-state Read Ports**: Implemented read ports using tri-state drivers where only the selected register drives the output bus while others are in high-impedance state. This allows multiple registers to share the same output bus.
4. **Write Enable Logic**: Combined global write enable with register-specific selection to prevent unwanted writes. Register 0 write is explicitly disabled.
### Modules

**regfile.v**: Main register file module
- Inputs: clock, ctrl_writeEnable, ctrl_reset, ctrl_writeReg[4:0], ctrl_readRegA[4:0], ctrl_readRegB[4:0], data_writeReg[31:0]
- Outputs: data_readRegA[31:0], data_readRegB[31:0]
- 32 registers implemented using DFFE cells with address decoding and tri-state read logic

**dffe_ref.v**: D flip-flop with enable reference module
- Inputs: d, clk, en, clr
- Output: q
- Basic storage element with synchronous write (when enabled) and asynchronous clear

### Testing and Bugs summary

- Off-by-One Error in Generate Loop: 
Wrote the generate loop as:
```verilog
for (i = 1; i <= 32; i = i + 1) begin: GEN_REGS
```
instead of:
```verilog
for (i = 0; i < 32; i = i + 1) begin: GEN_REGS
```
Causing several problems:
- Try to create register 32 (which doesn't exist in a 32-register file)
- Synthesis/simulation failures
