# jump_test.s

nop                         # 00

# setup
addi $1, $0, 5              # 01  r1 = 5
addi $2, $0, 3              # 02  r2 = 3
add  $3, $1, $2             # 03  r3 = 8

# j to an absolute address
j    6                      # 04  go to 06
addi $31, $0, 0             # 05  skipped

addi $4, $0, 1              # 06  r4 = 1

# jal to absolute target and check link
jal  10                     # 07  r31 gets 8 then jump to 10
addi $31, $31, 1            # 08  skipped
nop                         # 09  filler

add  $5, $31, $0            # 10  r5 = r31 = 8

# bne taken
bne  $1, $2, 2              # 11  5 != 3 so to 14
addi $6, $0, 111            # 12  skipped when branch taken
addi $6, $0, 222            # 13  r6 = 222

# blt taken
blt  $2, $1, 2              # 14  3 < 5 so to 17
addi $7, $0, 333            # 15  skipped when branch taken
addi $7, $0, 444            # 16  r7 = 444

# jr using register target
addi $8, $0, 20             # 17  r8 = 20
jr   $8                     # 18  to 20
addi $9, $0, 555            # 19  skipped by jr

addi $9, $0, 666            # 20  r9 = 666

# setx then bex taken
setx 24                     # 21  r30 = 24
bex  24                     # 22  r30 != 0 so to 24
addi $10, $0, 777           # 23  skipped by bex

# end loop
j    24                     # 24  stay here
nop                         # 25