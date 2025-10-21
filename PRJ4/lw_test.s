# set up small constants
addi $1,  $0, 1            # r1 = 1
addi $2,  $0, 2            # r2 = 2
addi $3,  $0, 3            # r3 = 3

# seed memory with known values
sw   $1,  10($0)           # mem[10] = 1
addi $5,  $0, 41
sw   $5,  11($0)           # mem[11] = 41
addi $6,  $0, 200
sw   $6,  12($0)           # mem[12] = 200   used later as a pointer
addi $7,  $0, 123456
sw   $7,  200($0)          # mem[200] = 123456
addi $8,  $0, 5
sw   $8,  13($0)           # mem[13] = 5
addi $9,  $0, 1000
sw   $9,  14($0)           # mem[14] = 1000
addi $10, $0, 24
sw   $10, 15($0)           # mem[15] = 24

# 1 load then immediate ALU use
lw   $11, 10($0)           # r11 = 1
add  $12, $11, $1          # r12 = 1 + 1 = 2

# 2 load then immediate store data use
lw   $13, 11($0)           # r13 = 41
sw   $13, 101($0)          # mem[101] = 41
lw   $14, 101($0)          # r14 = 41  confirms previous store

# 3 load then immediate use as address for another load
lw   $15, 12($0)           # r15 = 200
lw   $16, 0($15)           # r16 = mem[200] = 123456

# 4 load then immediate shift use
lw   $17, 13($0)           # r17 = 5
sll  $18, $17, 1           # r18 = 10

# 5 back to back loads then dependent add
lw   $19, 14($0)           # r19 = 1000
lw   $20, 15($0)           # r20 = 24
add  $21, $19, $20         # r21 = 1024

# 6 load then immediate logical use
lw   $22, 10($0)           # r22 = 1
and  $23, $22, $3          # r23 = 1