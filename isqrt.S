#include <xc.h>
        
.global main
.global BUFFER   
.global errno
.global TEXT_1
.global TEXT_2
.global CRLF
   
.data
BUFFER: .space 11   //buffer for number conversion
errno:	.byte 0	    //errorno default 0
    
.text
.set noreorder

.ent main
main:
//build main stack frame create
    addiu   sp, sp, -16
    sw	    ra, 12(sp)
    sw	    fp, 8(sp)
    ori	    fp, sp, 0

   //////////////////////////////////////////////////////////////
// configure UART TX
    la t9, U1MODESET
    li t0,0x8000
    sw t0, 0(t9)
    la t9, U1STASET
    li t0, 0x1400
    sw t0, 0(t9)

// M A I N    P R O G R A M //

//convert input to a decimal
    la		a0, input
    jal		AsciiDec_to_Bin
    nop
    
    la	    t0, errno
    lb	    t0, 0(t0)	//get value of errno
    bnez    t0, err_output  //if error caught, print err message
    nop
    
//calculate isqrt of decimal value
    or	    a0, v0, zero    //move return of ascii_to_bin to input for isqrt
    jal	    Isqrt
    nop
    
output_time:
    la a0, TEXT_3//"The isqrt of "
    jal output_string
    nop
    
    la a0, input
    jal output_string
    nop
    
    la a0, TEXT_4//" is "
    jal output_string
    nop
    
    //INSERT GUESS from v0
    ori a0, v0, 0
    la a1, BUFFER
    jal Bin_to_AsciiDec
    nop
    
    la a0, BUFFER
    jal output_string
    nop
    
    la a0, TEXT_5//". Check: "
    jal output_string
    nop
    
    //INSERT GUESS from v0
    ori a0, v0, 0
    la a1, BUFFER
    jal Bin_to_AsciiDec
    nop
    
    la a0, BUFFER
    jal output_string
    nop
    
    la a0, TEXT_6//"^2 = "
    jal output_string
    nop
    
    //do guess^2, output
    multu v0, v0  // guess*guess
    mflo t0
    ori a0, t0, 0
    la a1, BUFFER
    jal Bin_to_AsciiDec
    nop
    
    la a0, BUFFER
    jal output_string
    nop
    
    la a0, TEXT_7//", "
    jal output_string
    nop
       
    //guess+1 
    addi v0, 1 //guess +1
    ori a0, v0, 0
    la a1, BUFFER
    jal Bin_to_AsciiDec
    nop
    
    la a0, BUFFER
    jal output_string
    nop
    la a0, TEXT_6//"^2 = "
    jal output_string
    nop
    
    //guess+1 ^2
    multu v0, v0  // guess*guess
    mflo t0
    ori a0, t0, 0
    la a1, BUFFER
    jal Bin_to_AsciiDec
    nop
    
    la a0, BUFFER
    jal output_string
    nop
    
    la a0, TEXT_8//"."
    jal output_string
    nop
    
    la a0, CRLF//newline
    jal output_string
    nop

     j main_done
     nop
    
err_output:
    la a0, ERR_TEXT //load err message
    jal output_string	//output
    nop
    
main_done:
    
//stack frame destruction
    ori	    sp, fp, 0
    lw	    ra, 12(sp)
    lw	    fp, 8(sp)
    addiu   sp, sp, 16
    
//endless loop
    endless:
    j endless
    nop

//go back (never gets run in microprossessor)
    jr ra
    nop
    .end main

// constants go here
input:	.asciiz "253"
TEXT_1: .asciiz "debug iteration: "
TEXT_2: .asciiz " guess: "
TEXT_3: .asciiz "The isqrt of "
TEXT_4: .asciiz " is "
TEXT_5: .asciiz ". Check: "
TEXT_6: .asciiz "^2 = "
TEXT_7: .asciiz ", "
TEXT_8: .asciiz "."
CRLF: .asciiz "\r\n"
ERR_TEXT:  .asciiz "input string not a number!\r\n"