# Minimal jump and branch test

start:
    addi $1,  $0, 1        # r1 = 1
    addi $2,  $0, 2        # r2 = 2
    addi $5,  $0, 0        # r5 = score counter

    # j T  absolute jump
    j L_j_ok
    addi $6,  $0, 111      # should be skipped if j works

L_j_ok:
    addi $5,  $5, 1        # score += 1  j worked

    # jal T  then jr $ra to return
    jal L_sub               # $r31 = PC + 1, jump to L_sub
    addi $7,  $0, 777       # runs only after jr $31 returns

    # bne not taken
    bne  $1,  $1, 2         # not taken, next two lines run
    addi $16, $0, 123       # executes
    j    L_after_bne1       # skip the next line
    addi $9,  $0, 999       # should be skipped

L_after_bne1:
    # bne taken
    bne  $1,  $2, 1         # taken, skip next addi
    addi $10, $0, 555       # skipped if branch works
    addi $5,  $5, 1         # score += 1

    # blt taken
    blt  $1,  $2, 1         # taken, skip next addi
    addi $11, $0, 444       # skipped if blt works
    addi $5,  $5, 1         # score += 1

    # blt not taken
    blt  $2,  $1, 1         # not taken, do not skip next addi
    addi $12, $0, 333       # executes
    addi $5,  $5, 1         # score += 1

    # setx T and bex T
    setx L_bex              # rstatus = address of L_bex  nonzero
    bex  L_bex              # taken because rstatus != 0
    addi $13, $0, 222       # should be skipped
L_bex:
    addi $5,  $5, 1         # score += 1

    setx 0                  # rstatus = 0
    bex  L_should_not       # not taken because rstatus == 0
    addi $14, $0, 111       # executes
L_should_not:

    # final absolute jump to end
    j    L_end
    addi $15, $0, 999       # should be skipped

L_end:
    addi $0,  $0, 0         # nop

# Subroutine for jal and jr
L_sub:
    addi $18, $0, 42        # mark that subroutine ran
    jr   $31                # return to PC saved by jal