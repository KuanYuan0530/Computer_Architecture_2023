quant_bf16_to_int8:
        la a0, after_quant
        lw t0, 0(a1)  # max
        la s1, array_size 
        lw s1, 0(s1)  # array size
        addi a3, x0, 1 
for2:
        addi a3, a3, 1 
        addi t2, s2, 4
        lw t1, 0(t2)  # second element
        blt t1, t0, max_not_change
        mv t0, t1
max_not_change:
        blt a3, s1, for2
        
# calculate scale
        li t1, 0x43000000 # range 128, 2^(n-1)-1, n: quant bit
# bf16 divide
        mv a0, t1
        mv a1, t0

         
        
bf16_divide:
    
# a0: dividend, a1: divisor
        # Prologue
        addi sp, sp, -16
        sw ra, 0(sp)
        sw s0, 4(sp)
        sw s1, 8(sp)
        sw s2, 12(sp)
        
        li s0, 0x80000000  # sign mask
        li s1, 0x7f800000  # exp mask
        li s2, 0x007f0000  # man mask
        
        # sign(t6)
        and t0, a0, s0
        and t1, a1, s0
        or t6, t0, t1        
        # exp(t5)
        and t0, a0, s1
        and t1, a1, s1
        sub t2, t0, t1        
        # man(t4)
        li t5, 0x00800000
        and t3, a0, s2
        and t4, a1, s2
        or t3, t3, t5
        or t4, t4, t5
        
        bge t2, x0, dividend_big_divisor
        mov t5, t1      
        # align mantissa
        srl t3, t3, t2  
        j add_man
        
dividend_big_divisor:
        mov t5, t0
        # align mantissa
        srl t4, t4, t2
        
div_man:
        div t4, t3, t4        
        
        
        
        # Epilogue
        lw ra, 0(sp)
        lw s0, 4(sp)
        lw s1, 8(sp)
        lw s2, 12(sp)
        addi sp, sp, 16