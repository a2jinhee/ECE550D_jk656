### Name: Jinhee Kim
### netID: jk656

### Design overview
I implemented a 32 bit ALU that supports ADD SUB AND OR SLL SRA. The adder is carry select built from pairs of 4 bit ripple adders with cin equals zero and cin equals one per block and a carry controlled mux between blocks. SUB is formed by XORing B with op_sub and seeding the first select with op_sub. Overflow is detected from MSB signs for the selected add or subtract path. Bitwise operations use gate primitives with generate. SLL and SRA are five stage barrel shifters with shift amounts 1 2 4 8 16 built from ternary muxing. isNotEqual and isLessThan are derived from the subtract path as required by the spec in the code comments.

### Key design choices
- Opcode decode uses only `not` and `and` to produce one hot control wires
- SUB path uses B XOR op_sub to form 2's complement and selects cin and block outputs using op_sub and carries
- Overflow is computed from a31 b31 s31 with gate primitives
- Shifters are staged networks of ternary assigns where each condition is a single wire

### Modules
- `alu`:  top level that decodes opcodes, selects between arithmetic logical and shift results, and computes flags
- `rca4`:  a 4 bit ripple carry adder used as a building block inside the carry select structure
- `fa`:  a 1 bit full adder made from xor and and and or gates
- `reduce_or32`:  a tree of two input OR gates that reduces a 32 bit vector to one bit
- `barrel_sll32`: a 32 bit logical left shifter implemented as five staged mux layers for 1 2 4 8 16
- `barrel_sra32`:  a 32 bit arithmetic right shifter with sign extension using five staged mux layers

### Testing and Bugs summary
- SLL stage 1 bit zero wiring
  - Left shift by one loses the LSB source or injects the wrong value.
  - Used in[1] instead of zero for s1[0].
  - Fix: `assign s1[0] = sa[0] ? 1'b0 : in[0];`
- Stage-to-stage source mixup
  - Larger shifts (4, 8, 16) output wrong values.
  - Pulled from the original in instead of the previous stage bus.
  - Fix: each stage should source from the immediately prior stage.
- SRA MSB sign extension
  - Right shift by one does not preserve the sign bit.
  - Used in[30] instead of sgn for s1[31].
  - Fix: assign s1[31] = sa[0] ? sgn : in[31];