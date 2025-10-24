# Address map
#  00 RESET:
#  01 init:
#  02
#  03
#  04 after_j:
#  05
#  06 after_jal:
#  07
#  08 try_bne:
#  09 after_bne:
#  10 try_blt:
#  11 after_blt:
#  12 prep_jr:
#  13 try_jr:
#  14 after_jr:
#  15 try_bex:
#  16 done:
#  17 end_loop:

        nop                         # 00 warmup fetch

# Basic setup
init:   addi $1, $0, 5              # 01 r1 = 5
        addi $2, $0, 3              # 02 r2 = 3
        add  $3, $1, $2             # 03 r3 = 8

# Test absolute jump
        j    4                      # 04 T = 4 -> jump to after_j
        addi $31, $0, 0             # 05 should be skipped by the j

after_j:
        addi $4, $0, 1              # 06 r4 = 1 to prove we landed

# Test jal to an absolute target and check r31 = pc + 1
        jal  9                      # 07 link to r31 then jump to after_jal
        addi $31, $31, 1            # 08 will be skipped by jal

after_jal:
        # pc here is 9, so r31 should hold 8
        add  $5, $31, $0            # 09 r5 = r31 = 8

# Test bne taken then not taken
try_bne:
        bne  $1, $2, 1              # 10 5 != 3 so branch to 12
        addi $6, $0, 111            # 11 skipped when branch taken
after_bne:
        addi $6, $0, 222            # 12 r6 = 222

# Test blt taken then not taken
try_blt:
        blt  $2, $1, 1              # 13 3 < 5 so branch to 15
        addi $7, $0, 333            # 14 skipped when branch taken
after_blt:
        addi $7, $0, 444            # 15 r7 = 444

# Test jr using a register target
prep_jr:
        addi $8, $0, 14             # 16 r8 = 14 absolute target for jr
try_jr:
        jr   $8                     # 17 jump to address 14
        addi $9, $0, 555            # 18 skipped by jr
after_jr:
        addi $9, $0, 666            # 14 r9 = 666  note that this is the address jr targeted

# Test setx and bex
        setx 16                     # 15 r30 = 16
try_bex:
        bex  16                     # 16 r30 != 0 so jump to 16
        addi $10, $0, 777           # 17 not executed when bex taken

done:
        # simple memory smoke test to ensure lw sw still fine in this program
        addi $11, $0, 345           # 18 r11 = 345
        addi $12, $0, 567           # 19 r12 = 567
        sw   $11, 1($0)             # 20 MEM[1] = 345
        sw   $12, 2($0)             # 21 MEM[2] = 567
        lw   $13, 1($0)             # 22 r13 = 345
        lw   $14, 2($0)             # 23 r14 = 567

end_loop:
        j    17                     # 24 self loop so the testbench knows we are done
        nop                         # 25 padding