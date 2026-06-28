__asm__(
".global caml_clock_nanosleep\n"
".type caml_clock_nanosleep, @function\n"
"caml_clock_nanosleep:\n"
"    sar     $1, %rdi\n"
"    imul    $1000000, %rdi, %rax\n"
"    push    %r11\n"
"    cqo\n"
"    mov     $1000000000, %rcx\n"
"    idiv    %rcx\n"
"    push    %rdx      
"    push    %rax      
"    mov     $230, %rax
"    mov     $1, %rdi  
"    xor     %rsi, %rsi
"    mov     %rsp, %rdx
"    xor     %r10, %r10
"    syscall\n"
"    add     $16, %rsp\n"
"    pop     %r11\n"
"    mov     $1, %rax\n"
"    ret\n"
);