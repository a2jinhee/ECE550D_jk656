# build useful constants
nop
addi $1, $0, 65535         # r1 = 0x0000FFFF
sll  $2, $1, 15            # r2 = 0x7FFF8000
addi $3, $2, 32767         # r3 = 0x7FFFFFFF
addi $4, $0, 1             # r4 = 1

# normal arithmetic
add  $6, $1, $4            # 65535 + 1 = 65536
sll  $7, $4, 31            # r7 = 0x80000000  negative
sub  $9, $1, $4            # 65535 - 1 = 65534
and  $10, $1, $2
or   $12, $1, $2

# negative immediate and sign extension check
addi $14, $0, -1           # r14 = 0xFFFFFFFF

# arithmetic right shift on a negative value
sra  $26, $7, 1            # 0x80000000 >> 1 = 0xC0000000

# memory ops with r0 base and nonzero base
addi $20, $0, 2            # r20 = 2
add  $21, $4, $20          # r21 = 3
sub  $22, $20, $4          # r22 = 1
and  $23, $22, $21         # r23 = 1
or   $24, $20, $23         # r24 = 3
sll  $25, $23, 1           # r25 = 2
addi $27, $0, 456          # r27 = 456

sw   $4, 1($0)             # mem[1] = 1
sw   $20, 2($0)            # mem[2] = 2
sw   $1, 0($27)            # mem[456] = 65535
lw   $28, 1($0)            # r28 = 1
lw   $29, 2($0)            # r29 = 2
lw   $19, 0($27)           # r19 = 65535

# verify r0 ignores writes
addi $0, $4, 5             # attempt to write r0
add  $30, $0, $0           # harmless read to force a data path use of r0
# r0 must still be zero, grader will enforce that

# overflow tests with snapshots of r30 to memory
# add overflow: 0x40000000 + 0x40000000 -> overflow, r30 should become 1
addi $16, $0, 1
sll  $16, $16, 30          # r16 = 0x40000000
add  $17, $16, $16         # overflow set r30 = 1
sw   $30, 3($0)            # mem[3] = r30

# addi overflow: 0x7FFFFFFF + 1 -> overflow, r30 should become 2
addi $18, $3, 1            # overflow set r30 = 2
sw   $30, 4($0)            # mem[4] = r30

# sub overflow: (-2147483648) - 1 -> overflow, r30 should become 3
sub  $19, $7, $4           # overflow set r30 = 3
sw   $30, 5($0)            # mem[5] = r30