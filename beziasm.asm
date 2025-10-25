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
    extrn CheckCollisionPointRec
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
    test al, al
    jnz .exit
    call BeginDrawing
    
    mov rdi, 0xFF181818
    call ClearBackground
    ;-----------------------------------------------------------------

    ; Vars resets -----------------------------------------------------
    
    ; ----------------------------------------------------------------


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
    ; ---------------------------------------------------------------------

    ; Select an Anchor ----------------------------------------------------

    ; If left button is down AND we already have a valid anchor selected, keep it
    mov edi, 0   ; Left Button 
    call IsMouseButtonDown
    test al, al
    jz .do_selection  ; Button not pressed, proceed with selection

    ; check if we have a valid anchor
    movzx eax, byte [current_anchor] 
    cmp eax, 3
    jl .anchor_selection_done 

    ; -------------------------------
    
   .do_selection:

    mov byte [current_anchor], 4

    movq xmm0, [mouse_position]
    movq xmm1, [anchors + 0]
    movq xmm2, [anchors + 8]
    call CheckCollisionPointRec
    test al, al
    jz .check_anchor1
    mov byte [current_anchor],0
    jmp .anchor_selection_done 

    .check_anchor1:
    movq xmm0, [mouse_position]
    movq xmm1, [anchors + 16]
    movq xmm2, [anchors + 24]
    call CheckCollisionPointRec
    test al, al
    jz .check_anchor2
    mov byte [current_anchor], 1    
    jmp .anchor_selection_done 

    .check_anchor2:
    movq xmm0, [mouse_position]
    movq xmm1, [anchors + 32]
    movq xmm2, [anchors + 40]
    call CheckCollisionPointRec
    test al, al
    jz .anchor_selection_done
    mov byte [current_anchor], 2    

    .anchor_selection_done:

    ; Act on Selected Anchor ----------------------------------------------

    ; Move ----
    movzx eax, byte [current_anchor] 
    cmp eax, 4
    jge .dont_move

    mov edi, 0   ; Left Button
    call IsMouseButtonDown
    test al, al
    jz .dont_move

    movzx rax, byte [current_anchor] ; commpute offset
    imul rax, 16
    movq xmm0, [mouse_position]
    movq [anchors + rax], xmm0 

    ; --------

    .dont_move: 

    ; Set Next Anchor -----------------------------------------------------
    movzx eax, byte [anchor_to_add] 
    cmp eax, 3   ; All have been created  
    jge .end_loop

    mov edi, 0   ; Left Button
    call IsMouseButtonPressed          
    test al, al
    jz .end_loop

    ; Compute offset for anchor to set
    movzx rax, byte [anchor_to_add]
    imul rax, 16

    ; Copy x,y
    movq xmm0, [mouse_position]
    movq [anchors + rax], xmm0

    ; Copy w,h
    movss xmm1, [anchor_size]
    movss [anchors + rax + 8], xmm1    
    movss [anchors + rax + 12], xmm1

    inc byte [anchor_to_add]

    ; ----------------------------------------------------------------


.end_loop:
    ; Debug ----------------------------------------------------------
    mov rdi, toadddmsg          
    movzx rsi, byte [anchor_to_add] 
    xor rax, rax                    
    call printf

    mov rdi, currmsg          
    movzx rsi, byte [current_anchor] 
    xor rax, rax                    
    call printf
    ; -----------------------------------------------------------------
    call EndDrawing
    jmp .main_loop

.exit:
    call CloseWindow
    xor     edi, edi         
    call _exit

section '.data' writeable

anchor_size:
    dd 50.0

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
toadddmsg db "Anchor to add %i.", 0xA,0    
currmsg db "Anchor selected %i.", 0xA,0    
debugmsg: db "Anchor stored: x=%d y=%d w=%d h=%d", 0xA, 0
collchkmsg: db "Checking: mouse(%d,%d) vs rect(%d,%d,%d,%d)", 0xA, 0




section '.note.GNU-stack'