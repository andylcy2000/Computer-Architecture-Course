.globl __start

.rodata
    msg0: .string "This is HW1-1: T(n) = 3T(n/4) + 10n + 3, T(1)=T(2)=T(3) = 3\n"
    msg1: .string "Enter a number: "
    msg2: .string "The result is: "

.text


__start:
  # Prints msg0
    addi a0, x0, 4
    la a1, msg0
    ecall

  # Prints msg1
    addi a0, x0, 4
    la a1, msg1
    ecall

  # Reads an int
    addi a0, x0, 5
    ecall

########################################################################################### 
  # Write your main function here. 
  # Input n is in a0. You should store the result T(n) into t0
  # HW1-1 T(n) = 3T(n/4) + 10n + 3, T(1)=T(2)=T(3) = 3, round down the result of division
  # ex. addi t0, a0, 1
addi x18, x0, 4 #for comparison in T
addi x7, x0, 3 #for multiplication in T
addi x21, x0, 10 #for multiplication in T

#similar to a main function
function_call:
    jal x1, t_function #call the recursive function
    addi t0, x10, 0
    jal x0, result #when the recursive function is finished, jump to print result
    
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

###########################################################################################
result:
  # Prints msg2
    addi a0, x0, 4
    la a1, msg2
    ecall

  # Prints the result in t0
    addi a0, x0, 1
    add a1, x0, t0
    ecall
    
  # Ends the program with status code 0
    addi a0, x0, 10
    ecall