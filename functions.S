#include <xc.h>
#define debug 1 //used to enable debug logging for Isqrt function
      
.global is_a_digit
.global output_string
.global Bin_to_AsciiDec
.global AsciiDec_to_Bin
.global Isqrt
    
.text
.set noreorder
// text segment for instructions and CONSTANT READ-ONLY data follows here
// stored in non-volatile flash memory
    
.macro push reg     // define a parameter
   addiu    sp,	sp, -4	  // add a word of space to stack    
   sw	    \reg,   0(sp) // save \reg value to stack(text substitution)
.endm
   
.macro pop  reg
   lw	    \reg, 0(sp)
   sw	    zero, 0(sp)
   addiu    sp, sp, 4
.endm
   
.macro loadv reg, label
   la	\reg, \label
   lw	\reg, 0(\reg)
.endm
       
//************************************************************
//intputs: ascii value a0
//outputs: 0xFFFFFF... if not a digit, else return ASCII numb value (v0)
.ent is_a_digit
is_a_digit:
//stack frame creation
addiu sp, sp, -4 //added 5 words to stack
sw fp, 0(sp)  //store calling fnct fp
sw a0, 0(fp)   //stoer a0 in calling fun fp 
OR	fp, sp, zero	//move fp to bottom of frame

//function code    
li v0, 0x39
bgt a0, v0, not_digit
nop
    
li v0, 0x30
blt a0, v0, not_digit
nop

sub v0, a0, v0
j is_a_digit_end
nop

not_digit:
li v0, 0xFFFFFFFF

is_a_digit_end:

//stack frame destruction
addu sp, fp, zero //move sp back to bottom of frame 
lw fp, 0(sp)   //restore calling fns fp
addiu sp, sp, 4 //de allocate fns stack memory
//go back
jr ra
nop

.end is_a_digit
//************************************************************
//takes the adress of a string as it;s only parameter(a0)
//returns nothing

.ent output_string
output_string:
//************************
//stack frame creation
addiu sp, sp, -20 //added 5 words to stack
sw ra, 16(sp)   //store ra
sw	fp, 12(sp)  //store calling fnct fp
sw	s2, 8(sp)   //store s2 fn is using it
sw s1, 4(sp)    //store s1 since fn is using it
sw s0, 0(sp)    //store s0 since fn is using it
sw a0, 20(sp)   //store a0 in calling fun fp 
OR	fp, sp, zero	//move fp to bottom of frame

get_byte:
 lb s0, 0(a0)
 beq s0, zero, done
 nop
send:
// send TX data
 la s2, U1TXREG
 sw s0, 0(s2)
 la s2, U1STA
wait_tx:
 lw s1, 0(s2)
 andi s1, s1, 0x100
 beq s1, zero, wait_tx
 nop
next:
 addu a0, a0, 1
 j get_byte
 nop
done:
//stack destruction
addu    sp, fp, zero //move sp back to bottom of frame
lw	ra, 16(sp)  //restore ra 
lw fp, 12(sp)   //restore calling fns fp
lw s2, 8(sp) 
lw s1, 4(sp)
lw s0, 0(sp)    //restore used s regs
addiu sp, sp, 20 //de allocate fns stack memory

//go back
jr ra
nop
.end output_string

.ent Bin_to_AsciiDec
Bin_to_AsciiDec:
//first:binary(decimal) to convert (a0)
//second: address of a string buffer (a1)
//outputs: nothing
    
//Stack frame create
addiu sp, sp, -28 //added 4 words to stack
sw ra, 20(sp)   //store ra    
sw	fp, 16(sp)  //store calling fnct fp
sw	s3, 12(sp)
sw	s2,  8(sp)
sw	s1, 4(sp)
sw	s0, 0(sp)
sw a1, 4(fp) 
sw a0, 0(fp)   //stoer a0 in calling fun fp 
OR	fp, sp, zero

//function code
li s1, 0 //counter
li s2, 0 //counter
la s3, BUFFER

start_converdec:
beqz a0, finish_convertdec //checks param reg if = 0
nop
addi s1, 1

li s0, 10
divu a0, s0 //divide quotient by 10
mfhi s0 //grab remander, push on stack
nop
addi s0, 0x30 //adjust binary to ascii char
push s0


j start_converdec
nop
finish_convertdec:
beqz s1, end_converrtstr //use counter to go through stack
nop

addi s1, -1 //decriment counter
pop s0  //pop stack

sb s0, 0(s3) //store popped value in s2(BUFFER) s2 = counter for array index
addi s3, s3, 1

j finish_convertdec
nop

end_converrtstr:
sb zero, 0(s3)

//stack frame distruction
addu    sp, fp, zero
lw ra, 20(sp)
lw fp, 16(sp)
lw s3, 12(sp)
lw s2, 8(sp)
lw s1, 4(sp)
lw s0, 0(sp)
addiu sp, sp, 28

//go back
jr ra
nop
.end Bin_to_AsciiDec

//*****************************************************************************
//AsciiDec_to_Bin:
//  converts null terminated ascii numb into binary value
//first parameter: pointer (address) of string to convert to binary (a0)
//Returns: converted binary value (v0)
.ent AsciiDec_to_Bin
AsciiDec_to_Bin:
  //create stack
    addiu sp, sp, -16
    sw ra, 12(sp)
    sw fp, 8(sp)
    sw s0, 4(sp)
    sw a0, 0(fp)
    ori fp, sp, 0 // fp = sp doing weird or masking
 
//code
  push	zero		//push zero
  or	s0, a0, zero	//move pointer to s0 to maintain value across function calls
  
read_top:
  lb	    a0, 0(s0)	//load current ascii char 
  beqz	    a0, horner_loop_start //if nullchar, start converting to decimal
  nop
  
  jal	    is_a_digit	//see if ascii char is digit
  nop
  
  li	    t0, -1  // -1 = xFFFFFFFFF
  beq	    t0, v0, error   //if NaN, set error and gtfo
  addiu	    s0, s0, 1	//increment pointer
  
  //it is a digit, so push to stack
  push	    v0
  j	    read_top	//iterate
  nop
  
error:
    li	    t0, 1
    la	    t1, errno	    //load address of errno into t1
    sb	    t0, 0(t1)
    j	    conv_done	
    nop
    
horner_loop_start:
    li	    v0, 0   //load acc init value =0
    li	    t0, 1   //weight intit to 1
    li	    t9,	10  //multiplier for weight
    
horner_loop:
    pop	    t1	//pop curr value
    
    beqz    t1, conv_done   //if null, conversion done
    nop
    
    mul	    t1, t1, t0	//t1 = dec value * weight
    addu    v0, v0, t1	//acc = acc + dec value *weight(t1)
    
    
    mul t0, t0, t9  //weight = weight * 10
    
    j horner_loop   //continue 
    nop
    
conv_done:

  //stack destruction
  addu sp, fp, zero
  lw	ra, 12(sp)
  lw	fp, 8(sp)
  lw	s0, 4(sp)
  //lw	a0, 16(sp)
  addiu sp, sp, 16
  
  jr  ra
  nop    
 .end AsciiDec_to_Bin

//*****************************************************************************
//Isqrt
//first parameter: unsigned int (a0)
//Returns: unsigned (v0)
.ent Isqrt
Isqrt:
//create stack
    addiu sp, sp, -16
    sw ra, 12(sp)
    sw fp, 8(sp)
    sw s0, 4(sp)//might need to add var for debug
    sw a0, 0(fp)
    ori fp, sp, 0 // fp = sp doing weird or masking
     
    //init
    li s0, 0
    
    //edge case check
    beqz a0, zero_case
    nop
    
    li t1, 1
    beq a0, t1, one_case
    nop
    
    ori  v0, zero, 0        
    ori  t1, a0 , 0         
    li	s0, 1	//counter
  addi  t0, zero, 1
  sll   t0, t0, 30      

isqrt_bit:
  slt   t2, t1, t0     
  beqz   t2, isqrt_loop
nop

  srl	t0, t0, 2       
  j     isqrt_bit
nop
  
isqrt_loop:   
// debugging stuff here
.if debug
    la a0, TEXT_1//"debug iteration: "
    jal output_string
    nop
    
    ori a0, s0, 0
    la a1, BUFFER
    jal Bin_to_AsciiDec
    nop
    
    la a0, BUFFER
    jal output_string
    nop
    
    la a0, TEXT_2//" guess: "
    jal output_string
    nop
        
    ori a0, t1, 0
    la a1, BUFFER
    jal Bin_to_AsciiDec
    nop
    
    la a0, BUFFER
    jal output_string
    nop
    
    la a0, CRLF//newline
    jal output_string
    nop
.endif

  beqz   t0, isqrt_return
  nop
  add   t3, v0, t0     
  slt   t2, t1, t3
  beqz   t2, isqrt_else
  nop
  srl   v0, v0, 1       
  j     isqrt_loop_end
  nop
isqrt_else:
  sub   t1, t1, t3     
  srl   v0, v0, 1       
  add   v0, v0, t0     

isqrt_loop_end:
  addi s0, 1  
  srl   t0, t0, 2       
  j     isqrt_loop
  nop

zero_case:
    li v0, 0    
    j isqrt_return_no
    nop
    
one_case:    
    li v0, 1    
j isqrt_return_no
    nop
    
isqrt_return:    
// debugging stuff here
.if debug
    la a0, TEXT_1//"debug iteration: "
    jal output_string
    nop
    
    addi s0, 1
    ori a0, s0, 0
    la a1, BUFFER
    jal Bin_to_AsciiDec
    nop
    
    la a0, BUFFER
    jal output_string
    nop
    
    la a0, TEXT_2//" guess: "
    jal output_string
    nop
    
    ori a0, v0, 0
    la a1, BUFFER
    jal Bin_to_AsciiDec
    nop
    
    la a0, BUFFER
    jal output_string
    nop
    
    la a0, CRLF//newline
    jal output_string
    nop
.endif

isqrt_return_no:
  //stack destruction
  addu sp, fp, zero
  lw	ra, 12(sp)
  lw	fp, 8(sp)
  lw	s0, 4(sp)
  addiu sp, sp, 16
  jr  ra
  nop
.end Isqrt   