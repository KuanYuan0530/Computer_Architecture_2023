.data
array: .word 0x3f99999a, 0x3f9a0000, 0x4013d70a, 0x40140000, 0x405d70a4, 0x405d0000, 0x40b428f6
# test data1: 1.200000, 1.203125, 2.310000, 2.312500, 3.460000, 3.4531255, 5.630000

array2: .word 0x3dcccccd, 0x3e4ccccd, 0x3f99999a, 0x40400000, 0x40066666, 0xc0866666, 0x40600000
# test data2: 0.1, 0.2, 1.2, 3, 2.1, -4.2, 3.5

array3: .word 0x40490fdb, 0x3dfcd6e9, 0x3f9e0652, 0x35a5167a, 0x322bcc77, 0x3f800000, 0x339652e8
# test data3: 3.14159265, 0.12345678 , 1.23456789 , 0.00000123, 0.00000001, 0.99999999 , 0.00000007

array_size: .word 7
array_bf16: .word 0, 0, 0, 0, 0, 0, 0

exp_mask: .word 0x7F800000
man_mask: .word 0x007FFFFF
sign_exp_mask: .word 0xFF800000
bf16_mask: .word 0xFFFF0000

next_line: .string "\n"
max_string: .string "maximum number is "
bf16_string: .string "\nbfloat16 number is \n"

.text
main:
# data 1
        la a0, bf16_string
        addi a7, x0, 4
        ecall
        la s0, array  # array address
        la s2, array_bf16  # array_bf16 address
        la s1, array_size 
        lw s1, 0(s1)  # array size
        
        la s3, exp_mask
        lw s3, 0(s3)
        la s4, man_mask
        lw s4, 0(s4)
        la s5, sign_exp_mask
        lw s5, 0(s5)
        la s6, bf16_mask
        lw s6, 0(s6)
        
for1:
        lw a0, 0(s0)  # first element
        jal ra, fp32_to_bf16
        sw a0, 0(s2)
        addi a7, x0, 34
        ecall
        la a0, next_line
        addi a7, x0, 4
        ecall
        addi s1, s1, -1
        addi s0, s0, 4
        addi s2, s2, 4
        bne s1, x0, for1
        
        # invoke find maximum
        la a0, max_string
        addi a7, x0, 4
        ecall
        addi a1, s2, -28  # input array_bf16
        jal ra, bf16_findmax
        addi a7, x0, 34
        ecall

# data 2
        la a0, bf16_string
        addi a7, x0, 4
        ecall
        la s0, array2  # array address
        la s2, array_bf16  # array_bf16 address
        la s1, array_size 
        lw s1, 0(s1)  # array size
        
        la s3, exp_mask
        lw s3, 0(s3)
        la s4, man_mask
        lw s4, 0(s4)
        la s5, sign_exp_mask
        lw s5, 0(s5)
        la s6, bf16_mask
        lw s6, 0(s6)
        
data2for1:
        lw a0, 0(s0)  # first element
        jal ra, fp32_to_bf16
        sw a0, 0(s2)
        addi a7, x0, 34
        ecall
        la a0, next_line
        addi a7, x0, 4
        ecall
        addi s1, s1, -1
        addi s0, s0, 4
        addi s2, s2, 4
        bne s1, x0, data2for1
        
        # invoke find maximum
        la a0, max_string
        addi a7, x0, 4
        ecall
        addi a1, s2, -28  # input array_bf16
        jal ra, bf16_findmax
        addi a7, x0, 34
        ecall
        
# data 3
        la a0, bf16_string
        addi a7, x0, 4
        ecall
        la s0, array3  # array address
        la s2, array_bf16  # array_bf16 address
        la s1, array_size 
        lw s1, 0(s1)  # array size
        
        la s3, exp_mask
        lw s3, 0(s3)
        la s4, man_mask
        lw s4, 0(s4)
        la s5, sign_exp_mask
        lw s5, 0(s5)
        la s6, bf16_mask
        lw s6, 0(s6)
        
data3for1:
        lw a0, 0(s0)  # first element
        jal ra, fp32_to_bf16
        sw a0, 0(s2)
        addi a7, x0, 34
        ecall
        la a0, next_line
        addi a7, x0, 4
        ecall
        addi s1, s1, -1
        addi s0, s0, 4
        addi s2, s2, 4
        bne s1, x0, data3for1
        
        # invoke find maximum
        la a0, max_string
        addi a7, x0, 4
        ecall
        addi a1, s2, -28  # input array_bf16
        jal ra, bf16_findmax
        addi a7, x0, 34
        ecall
        
        # Exit program
        li a7, 10
        ecall 
        

fp32_to_bf16:
# ! don't need point variable concept
        addi sp,sp,-8 
        sw a0,0(sp)  # y
        addi t0,sp,0  # p
        lw t2,0(t0)  # *p
        and t6, t2, s3  # exp
        and t4, t2, s4  # man
        # if zero        
        bne t6, x0, else
        # exp is zero
        bne t4, x0, else
return_x:
        addi sp,sp,8
        jr ra       
        
else:
        # if infinity or NaN
        beq t4, x0, return_x
        
        # round
        sw a0, 4(sp)  # r
        addi t1, sp, 4  # pr
        lw t3, 0(t1)  # *pr
        and t3, t3, s5
        sw t3, 0(t1)        
        
        lw t3, 4(sp)  # r
        # floating point divide
# ~~        addi t5, x0, 0x100~~
# ~~        div t3, t3, t5~~
        li t5, 0x04000000
        sub t3, t3, t5 # r
        
        # floating point addition
        # t3: r, t4: a0's man, t6:a0's exp
# ~~        add t5, a0, t3  # y~~
        and t5, t3, s3  # r's exp
        srli t6, t6, 23 # exp alignment
        srli t5, t5, 23  
        sub t2, t6, t5  # exp diff
        and t3, t3, s4  # r's man
        # man alignment
        li s11, 0x00800000  # make up 1 to No.24bit
        or t3, t3, s11
        or t4, t4, s11
        # t6>=0, a0>=r; t6<0, a0<r, smaller man shift right, reserve bigger exp
        bge t2, x0, x_big_r
        srl t4, t4, t2  # a0's man shift right t2 bit
        mv t6, t5  # reserve t5(r's exp)
        j add_man              
x_big_r:
        srl t3, t3, t2  # r's man shift right t2 bit
add_man:
        add t3, t3, t4  # mantissa addition
        # check carry
        and t4, t3, s11  # check No.24bit, 0:carry, 1: nocarry
        bne t4, a0, no_carry
        addi t6, t6, 1  # exp+1
        srli t3 ,t3, 1  # man alignment
no_carry: 
        slli t6, t6, 23  # exp shift
        and t6, t6, s3  # mask exp
        and t3, t3, s4  # mask man
        or t6, t3, t6  # combine exp & man
        li s11, 0x80000000  # sign mask
        and t3, a0, s11  # sign
        or t5, t3, t6

# ! integrate divide and addition can be man shift 8 bit 
        sw t5, 0(sp)  # y
        lw t2, 0(t0)  # *p
        and t2, t2, s6
        sw t2, 0(t0)
        
        lw t5, 0(sp)
        add a0, x0, t5
        addi sp,sp,8
        jr ra

bf16_findmax:
# a1: bf16_array, return a0: max
        # Prologue
        addi sp, sp, -12
        sw ra, 0(sp)
        sw s1, 4(sp)
        sw s2, 8(sp)
         
        li s1, 0x7f800000  # exp mask
        li s2, 0x007f0000  # man mask
        
        mv t2, a1  # input array(t2)
        lw a0, 0(t2)  # max(a0)
        la t4, array_size 
        lw t4, 0(t4)  # array size(t4)
        addi t3, x0, 1  # count(t3)
for2:
        addi t3, t3, 1 
        addi t2, t2, 4
        lw t1, 0(t2)  # second element(t1)
#        blt t1, a0, max_not_change
# ! max's sign,exp,man can save 
        # bf16_compare
        # a0: max, t1: next
              
        # compare exp
        and t5, a0, s1
        and t6, t1, s1

        blt t5, t6, max_change  # t5(max.exp)<t6(next.exp) branch
        blt t6, t5, max_not_change
        
        # compare man
        and t5, a0, s2
        and t6, t1, s2
        
        blt t5, t6, max_change
        blt t6, t5, max_not_change

max_change:        
        mv a0, t1
max_not_change:
        blt t3, t4, for2
        
        # Absolute
        li t0, 0x7fffffff
        and a0, a0, t0

        # Epilogue
        lw ra, 0(sp)
        lw s1, 4(sp)
        lw s2, 8(sp)
        addi sp, sp, 12      
        jr ra