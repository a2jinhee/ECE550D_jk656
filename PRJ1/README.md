### Name: Jinhee Kim
### netID: jk656

### Design description

1. I implemented ADD and SUB for signed two’s complement inputs using one shared adder. 
2. The opcode bit ctrl_ALUopcode[0] selects the mode. 
3. For SUB I form the effective B by XORing each bit of data_operandB with op_sub, and I inject carry in equal to one. For ADD I pass B unchanged and inject carry in equal to zero. 
4. I built a 32 bit carry select adder from eight 4 bit ripple blocks. 
5. Each 4 bit block is computed twice, once with cin zero and once with cin one, then a selector chooses the proper sum and carry for the next block. 
6. Overflow is detected from sign bits using the standard two’s complement rule. I computed overflow as `(A31 and B2_31 and not S31) or (not A31 and not B2_31 and S31)` where B2_31 is the MSB of the effective B after XORing for SUB, and S31 is the MSB of the 32 bit sum.

### Bugs and fixes
1.	Bitwise NOT usage
- Bug: Initially tried assign op_add = ~ctrl_ALUopcode[0];, but ~ was in the forbidden operator list.
- Fix: Replaced it with a gate primitive instance: `not not_op_code(op_add, ctrl_ALUopcode[0]);`

2.	Two’s complement of B
- Bug: Only XORed B with op_sub, which is wrong, since in 2's complement you also need to add 1.
- Fix: This was clarified during debugging, and solved it by setting the first adder carry-in (cin = 1) when subtracting
