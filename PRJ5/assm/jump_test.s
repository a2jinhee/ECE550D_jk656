# ==========================================================
# Minimal jump / branch test for ECE550 single-cycle CPU
# Each section increments r5 (score) if jump/branch worked.
# ==========================================================

    addi $1,  $0, 1        # r1 = 1
    addi $2,  $0, 2        # r2 = 2
    addi $5,  $0, 0        # r5 = score counter

# ----- 1. Test j -----
    j  6                   # absolute jump to instruction index 6
    addi $6, $0, 111       # skipped if j works

# target (PC = 6)
    addi $5, $5, 1          # r5 = 1  (j worked)

# ----- 2. Test jal / jr -----
    jal 10                  # jump to instruction index 10
    addi $7, $0, 777        # runs after jr returns

# subroutine at index 10
    addi $18, $0, 42        # mark subroutine executed
    jr   $31                # return to PC+1 (jal return)

# return destination (PC+1 = 8)
    addi $5, $5, 1          # r5 = 2  (jal/jr worked)

# ----- 3. Test bne (taken and not taken) -----
    bne  $1, $1, 1          # not taken → executes next addi
    addi $8, $0, 222        # executes
    bne  $1, $2, 1          # taken → skips next addi
    addi $9, $0, 999        # skipped
    addi $5, $5, 1          # r5 = 3  (bne worked)

# ----- 4. Test blt -----
    blt  $1, $2, 1          # taken → skips next addi
    addi $10, $0, 888       # skipped
    addi $5,  $5, 1         # r5 = 4  (blt worked)
    blt  $2, $1, 1          # not taken → executes next addi
    addi $11, $0, 777       # executes
    addi $5,  $5, 1         # r5 = 5  (blt not taken works)

# ----- 5. Test setx / bex -----
    setx  30                # set rstatus = 30 (nonzero)
    bex   27                # jump to instruction index 27 (target)
    addi  $12, $0, 444      # skipped if bex works

# target (index 27)
    addi  $5,  $5, 1        # r5 = 6  (bex worked)
    setx  0                 # clear rstatus = 0
    bex   31                # not taken, skip to end
    addi  $13, $0, 555      # executes
    addi  $5,  $5, 1        # r5 = 7  (bex not taken works)

# ----- 6. Final jump to end -----
    j 33                    # absolute jump to end
    addi $14, $0, 666       # skipped
# end (PC = 33)
    addi $0,  $0, 0         # nop

# ==========================================================
# Expected register summary after simulation:
# r1=1  r2=2  r5=7  r18=42  r8=222  r11=777  r13=555
# rstatus=0  all others 0
# ==========================================================