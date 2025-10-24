

addi $1,  $0, 1         # 0
addi $2,  $0, 2         # 1
addi $5,  $0, 0         # 2
# ----- 1. Test j -----
j  5                    # 3
addi $6, $0, 111        # 4, SKIP
addi $5, $5, 1          # 5, r5 = 1  (j worked)
# ----- 2. Test jal / jr -----
jal 9                   # 6, link PC+1
addi $7, $0, 777        # 7, EXECUTE
j   11                  # 8, skip over the subroutine body
addi $18, $0, 42        # 9, EXECUTE, subroutine body
jr   $31                # 10, return to link
addi $5, $5, 1          # 11, r5 = 2  (jal/jr worked)
# ----- 3. Test bne (taken and not taken) -----
bne  $1, $1, 1          # 12, not taken
addi $8, $0, 222        # 13, EXECUTE
bne  $1, $2, 1          # 14, taken, skips next addi
addi $9, $0, 999        # 15, SKIP
addi $5, $5, 1          # 16, r5 = 3  (bne worked)
# ----- 4. Test blt -----
blt  $1, $2, 1          # 17, taken, skips next addi
addi $10, $0, 888       # 18, SKIP
addi $5,  $5, 1         # 19, r5 = 4  (blt worked)
blt  $2, $1, 1          # 20, not taken
addi $11, $0, 777       # 21, EXECUTE
addi $5,  $5, 1         # 22, r5 = 5  (blt not taken works)
# ----- 5. Test setx / bex -----
setx  30                # 23, set rstatus=30
bex   26                # 24, branch to 27 if rstatus=nonzero
addi  $12, $0, 444      # 25, SKIP
addi  $5,  $5, 1        # 26, r5 = 6  (bex worked)
setx  0                 # 27, clear rstatus = 0
bex   30                # 28, not taken, skip to end
addi  $13, $0, 555      # 29, SKIP
addi  $5,  $5, 1        # 30, r5 = 7  (bex not taken works)
# ----- 6. Final jump to end -----
j 33                    # 31, absolute jump to end
addi $14, $0, 666       # 32, SKIP
addi $0,  $0, 0         # 33, NOP

# ==========================================================
# Expected register summary after simulation:
# r1=1  r2=2  r5=7  r7=777  r8=222  r11=777  r18=42
# rstatus=0  all others 0
# ==========================================================