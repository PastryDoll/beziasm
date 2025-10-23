; Integer/Pointer arguments (in order):
;   rdi - 1st argument
;   rsi - 2nd argument  
;   rdx - 3rd argument
;   rcx - 4th argument
;   r8  - 5th argument
;   r9  - 6th argument

format ELF64

section '.text' executable
    public _start
    extrn printf
    extrn InitWindow
    extrn WindowShouldClose
    extrn CloseWindow
    extrn BeginDrawing
    extrn EndDrawing
    extrn ClearBackground
    extrn DrawRectangle
    extrn SetTargetFPS
    extrn GetMousePosition
    extrn DrawRectangleV
    extrn IsMouseButtonPressed
    extrn IsMouseButtonDown
    extrn _exit

_start:

    ; Set Window -----------------------------------------------------
    mov rdi, 800
    mov rsi, 600
    mov rdx, title
    call InitWindow
    mov rdi, 360          
    call SetTargetFPS 


.main_loop:

    ; Window clean up ------------------------------------------------
    call WindowShouldClose
    test rax, rax
    jnz .exit
    call BeginDrawing
    
    mov rdi, 0xFF181818
    call ClearBackground
    ;-----------------------------------------------------------------


    ; Get mouse inputs/position --------------------------------------
    call GetMousePosition
    movq [mouse_position], xmm0   
    mov edi, 0  
    ; ----------------------------------------------------------------

    ; Draw Anchors ---------------------------------------------------
    movq xmm0, [anchors + 0]
    movq xmm1, [anchors + 8]
    mov rdi, 0xFF0000FF
    call DrawRectangleV
    movq xmm0, [anchors + 16]
    movq xmm1, [anchors + 24]
    mov rdi, 0xFF0000FF
    call DrawRectangleV
    movq xmm0, [anchors + 32]
    movq xmm1, [anchors + 40]
    mov rdi, 0xFF0000FF
    call DrawRectangleV
    ; ----------------------------------------------------------------

    ; Set Anchor -----------------------------------------------------
    mov eax, [anchor_to_add] 
    cmp eax, 4   ; All have been created  
    jge .end_loop

    call IsMouseButtonPressed          
    test rax, rax
    jz .end_loop
    movq xmm0, [mouse_position]
    movq [anchors + 8*anchor_to_add], xmm0
    mov [anchors + 8*anchor_to_add + 8], 10
    mov [anchors + 8*anchor_to_add + 12], 10

    ; ----------------------------------------------------------------


.end_loop:
    call EndDrawing
    jmp .main_loop

.exit:
    call CloseWindow
    xor     edi, edi         
    call _exit

section '.data' writeable

mouse_position:
    dd 0.0
    dd 0.0

anchors:
    ; Anchor 0
    dd 0.0      ; x
    dd 0.0      ; y
    dd 0.0      ; w
    dd 0.0      ; h
    ; Anchor 1
    dd 0.0      ; x
    dd 0.0      ; y
    dd 0.0      ; w
    dd 0.0      ; h
    ; Anchor 2
    dd 0.0      ; x
    dd 0.0      ; y
    dd 0.0      ; w
    dd 0.0      ; h

current_anchor: db 0
anchor_to_add: db 0

title: db "Beziasm", 0
mouseXmsg db "Current Mouse X %d.", 0xA,0    


section '.note.GNU-stack'