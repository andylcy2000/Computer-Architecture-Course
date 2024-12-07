.globl __start

.rodata
    msg0: .string "This is HW1-2: \n"
    msg1: .string "Enter offset: "
    msg2: .string "Plaintext:  "
    msg3: .string "Ciphertext: "
.text

################################################################################
  # print_char function
  # Usage: 
  #     1. Store the beginning address in x20
  #     2. Use "j print_char"
  #     The function will print the string stored from x20 
  #     When finish, the whole program with return value 0

print_char:
    addi a0, x0, 4
    la a1, msg3
    ecall
  
    add a1,x0,x20
    ecall

  # Ends the program with status code 0
    addi a0,x0,10
    ecall
    
################################################################################

__start:
  # Prints msg
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
    add a6, a0, x0
    
  # Prints msg2
    addi a0, x0, 4
    la a1, msg2
    ecall
    
    addi a0,x0,8
    li a1, 0x10150
    addi a2,x0,2047
    ecall
  # Load address of the input string into a0
    add a0,x0,a1


################################################################################ 
  # Write your main function here. 
  # a0 stores the begining Plaintext
  # x16 stores the offset
  # Do store beginning address 66048 (=0x10200) into x20 
  # ex. j print_char
bge a6, x0, PASS #check if the amount of shift is smaller than 0
addi a6, a6, 26 #if the amount of shift is smaller than 0, add 26 to it, which keeps the shifted character within the range a~z
                #after it pre-handling, there's no need to check if the shifted character is smaller than a

PASS: 
addi x28, x0, 10 #\n
addi x5, x0, 32 #space
addi x31, x0, 48 #number 1
addi x21, x0, 123 #upperbound
addi x26, x0, 97 #lowerbound
li x20, 66048

#for shifting characters aka the loop function
mv_char:
    lbu x29, 0(a0)
    beq x29, x28, END #jump to end and print char
    beq x29, x5, SPACE   
    add x19, x29, a6
    bge x19, x21, upper_handle #if the shifted character is greater than z, then handle it
    add x30, x0, x19
    j save_char

#for preparing to go to print_char
END:
    li x20, 66048
    j print_char

#save a character into a memory address
save_char:
    sb x30, 0(x20)
    addi a0, a0, 1
    addi x20, x20, 1
    j mv_char

#for handling shifted characters greater than z
upper_handle:
    sub x25, x21, x29
    sub x25, a6, x25
    addi x25, x25, 97
    add x30, x25, x0
    j save_char

#if the loaded byte is a space, load a number into it
SPACE:
    addi x30, x31, 0
    addi x31, x31, 1
    j save_char


################################################################################

