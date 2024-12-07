.data
    n: .word 10
    
.text
.globl __start

FUNCTION:
    # Todo: Define your own function in HW1
    # You should store the output into x10
    addi x18, x0, 4 #for comparison in T
    addi x7, x0, 3 #for multiplication in T
    addi x21, x0, 10 #for multiplication in T
    addi sp, sp, -8
    sw x1, 0(sp)
    jal x1, t_function #call the recursive function
    #addi t0, x10, 0
    lw x1, 0(sp)
    addi sp, sp, 8
    jalr x0, 0(x1)#when the recursive function is finished, jump to print result
    
t_function:
    addi sp, sp, -16
    sw x1, 8(sp)
    sw x10, 0(sp)
    bge x10, x18, L1
    addi x10, x0, 3
    addi sp, sp, 16
    jalr x0, 0(x1)
    
L1:
    srai x10, x10, 2 #divide input by 4 
    jal x1, t_function
    addi x6, x10, 0 #move the result of the leaf function to x6
    lw x10, 0(sp)
    lw x1, 8(sp)
    mul x22, x10, x21 #multiply the original input by 10
    addi sp, sp, 16
    mul x6, x6, x7
    addi x10, x6, 0
    add x10, x10, x22
    addi x10, x10, 3 
    jalr x0, 0(x1)
    

# Do NOT modify this part!!!
__start:
    la   t0, n
    lw   x10, 0(t0)
    jal  x1,FUNCTION
    la   t0, n
    sw   x10, 4(t0)
    addi a0,x0,10
    ecall