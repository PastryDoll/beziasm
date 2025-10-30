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
    extrn DrawRectangleLinesEx
    extrn IsKeyPressed
    extrn GetScreenWidth
    extrn GetScreenHeight
    extrn DrawLineEx  ; (Vector2 startPos, Vector2 endPos, float thick, Color color)
    extrn DrawCircleV ; (Vector2 center, float radius, Color color)
    extrn GetTime     ; double GetTime(void)
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

    ; Compute Mouse position on the center of anchor
    movq xmm1, xmm0                  
    mov eax, dword [anchor_size]     
    sub eax, 0x00800000              ; Subtract 1 from exponent (÷2)
    movd xmm2, eax                   
    shufps xmm2, xmm2, 0             
    subps xmm1, xmm2                 
    movq [mouse_position_on_center], xmm1
    ; ----------------------------------------------------------------

    ; Draw Anchors ---------------------------------------------------
    .draw_anchors:
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

    ; Draw Lines & Circles -------------------------------------------
    .draw_lines:

            movzx eax, byte [anchor_to_add]
            cmp eax, 2
            jge .draw_first
            jmp .draw_first_done

        .draw_first:
            movq xmm0, [anchors]
            movq xmm1, [anchors + 16]
            ; Compute centering offset (half anchor size)
            mov eax, dword [anchor_size]     
            sub eax, 0x00800000              
            movd xmm7, eax                   
            shufps xmm7, xmm7, 0
            
            ; Center the points
            addps xmm0, xmm7                
            addps xmm1, xmm7 
            call draw_line_with_circle
            movq [circle1], xmm0


        .draw_first_done:
            movzx eax, byte [anchor_to_add]
            cmp eax, 3
            jl .dont_draw_lines              

        .draw_second:
            movq xmm1, [anchors + 32]
            movq xmm0, [anchors + 16]
            ; Compute centering offset (half anchor size)
            mov eax, dword [anchor_size]     
            sub eax, 0x00800000              
            movd xmm7, eax                   
            shufps xmm7, xmm7, 0
            
            ; Center the points
            addps xmm0, xmm7                
            addps xmm1, xmm7 
            call draw_line_with_circle
            movq [circle2], xmm0

            movq xmm0, [circle1]
            movq xmm1, [circle2]
            call draw_line_with_circle




    .dont_draw_lines:
    ;-----------------------------------------------------------------

    ; Select an Anchor ----------------------------------------------- Sets [current_anchor] (default value is 3)
    .select_anchor:

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
            mov byte [current_anchor], 3 ; no selection = 3
            mov byte [is_dragging], 0 ; reset is dragging 

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

            ; Draw Contour of selected Anchor
            movzx eax, byte [current_anchor]
            cmp eax, 3                     
            jge .skip_outline             

            ; Compute offset for selected anchor
            movzx rax, byte [current_anchor]
            imul rax, 16
            mov [current_anchor_byte_offset], rax

            mov rax, [current_anchor_byte_offset]
            movq xmm0, [anchors + rax]      
            movq xmm1, [anchors + rax + 8]  
            
            mov eax, 0x40400000 ; Thickness             
            movd xmm2, eax 
            
            mov rdi, 0xFFFFFF00  ; Color
            
            call DrawRectangleLinesEx

            .skip_outline:
    ; ----------------------------------------------------------------

    ; Move ----------------------------------------------------------- Move [current_anchor]
    .move_selected_anchor:
        movzx eax, byte [current_anchor] ; TODO - Do we need this ? 
        cmp eax, 3
        jge .finish_move

        mov edi, 0   ; Left Button
        call IsMouseButtonDown
        test al, al
        jz .finish_move

        ; Check if this is the first frame of dragging
        cmp byte [is_dragging], 0
        jne .continue_drag

        ; First frame - save initial positions
        mov byte [is_dragging], 1

        ; Save initial mouse position
        movq xmm0, [mouse_position]
        movq [drag_start_mouse], xmm0

        ; Save initial anchor position
        mov rax, [current_anchor_byte_offset]
        movq xmm0, [anchors + rax]
        movq [drag_start_anchor], xmm0

        .continue_drag:

        ; Calculate delta = current_mouse - drag_start_mouse
        movq xmm0, [mouse_position]
        movq xmm1, [drag_start_mouse]
        subps xmm0, xmm1                    ; xmm0 = delta

        ; New position = drag_start_anchor + delta
        movq xmm1, [drag_start_anchor]
        addps xmm0, xmm1                    ; xmm0 = new position

        ; Clamp to screen boundaries ----------------------------
        call GetScreenWidth
        cvtsi2ss xmm2, eax                  
        call GetScreenHeight
        cvtsi2ss xmm3, eax                 

        ; Subtract anchor size to get max position
        movss xmm4, [anchor_size]
        subss xmm2, xmm4                    ; xmm2 = max_x
        subss xmm3, xmm4                    ; xmm3 = max_y

        movaps xmm5, xmm0
        shufps xmm5, xmm5, 0x00             ; xmm5 = [x, x, x, x]
        movaps xmm6, xmm0
        shufps xmm6, xmm6, 0x55             ; xmm6 = [y, y, y, y]

        ; Clamp x: min(max(0, x), max_x)
        pxor xmm7, xmm7                     ; xmm7 = 0
        maxss xmm5, xmm7                    ; x = max(0, x)
        minss xmm5, xmm2                    ; x = min(x, max_x)
        
        ; Clamp y
        maxss xmm6, xmm7                    
        minss xmm6, xmm3                   

        movss xmm0, xmm5                    ; xmm0[0] = clamped_x
        insertps xmm0, xmm6, 0x10           ; xmm0[1] = clamped_y

        ; --------------------------------------------------------

        ; Store new position
        mov rax, [current_anchor_byte_offset]
        movq [anchors + rax], xmm0 

        ; --------
    .finish_move:

    
    ; Add Next Anchor ------------------------------------------------ Increments [anchor_to_add] (0,1,2)
    movzx eax, byte [current_anchor]
    cmp eax, 3
    jne .finish_add
    
    .add_next_anchor:
        movzx eax, byte [anchor_to_add] 
        cmp eax, 3   ; All have been created  
        jge .finish_add

        mov edi, 0   ; Left Button
        call IsMouseButtonPressed          
        test al, al
        jz .finish_add

        ; Compute offset for anchor to add
        movzx rax, byte [anchor_to_add]
        imul rax, 16

        ; Copy x,y
        movq xmm0, [mouse_position_on_center]
        movq [anchors + rax], xmm0

        ; Copy w,h
        movss xmm1, [anchor_size]
        movss [anchors + rax + 8], xmm1    
        movss [anchors + rax + 12], xmm1

        inc byte [anchor_to_add]
    .finish_add:
    ; ----------------------------------------------------------------

    ; Delete --------------------------------------------------------- Decrements [anchor_to_add] & deletes [current_anchor]
    .delete_selected_anchor:
        movzx eax, byte [current_anchor] ; TODO - Do we need this ? Maybe factor out
        cmp eax, 3
        jge .finish_delete

        mov rdi, 259
        call IsKeyPressed
        test al, al
        jz .finish_delete

        ; Determine which anchor to delete and shift accordingly
        movzx eax, byte [current_anchor]
        
        ; Since only 3 anchor why generalize ?!
        cmp eax, 0
        je .delete_anchor_0
        cmp eax, 1
        je .delete_anchor_1
        cmp eax, 2
        je .delete_anchor_2
        jmp .finish_delete

        .delete_anchor_0:
            movdqa xmm0, [anchors + 16]
            movdqa [anchors + 0], xmm0
            
            movdqa xmm0, [anchors + 32]
            movdqa [anchors + 16], xmm0
            
            pxor xmm0, xmm0
            movdqa [anchors + 32], xmm0
            
            jmp .finish_delete_shift

        .delete_anchor_1:
            movdqa xmm0, [anchors + 32]
            movdqa [anchors + 16], xmm0
            
            pxor xmm0, xmm0
            movdqa [anchors + 32], xmm0
            
            jmp .finish_delete_shift

        .delete_anchor_2:
            pxor xmm0, xmm0
            movdqa [anchors + 32], xmm0
            
            jmp .finish_delete_shift

        .finish_delete_shift:
            movzx eax, byte [anchor_to_add]
            cmp eax, 0
            je .finish_delete
            dec byte [anchor_to_add]
            mov byte [current_anchor], 3
    .finish_delete:
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


; ===================================================================
; Function: draw_line_with_circle
; Draws a line between two anchors and animates a circle along it
; Input:
;   xmm0 - start point [x1, y1]
;   xmm1 - end point [x2, y2]
; ===================================================================
draw_line_with_circle:
    push rbp                        ; Align stack
    mov rbp, rsp
    sub rsp, 32                     ; Allocate space (stays 16-aligned)

    movdqa [rsp], xmm0              ; Save args on stack
    movdqa [rsp + 16], xmm1      

    movss xmm2, [line_thickness] 
    mov edi, [line_color]         
    call DrawLineEx

    ; Get time and compute oscillating 't' value (0 -> 1 -> 0 -> 1 ...)
    call GetTime                     
    cvtsd2ss xmm0, xmm0             ; Convert double to float

    ; Take modulo 2.0 ( a mod b = a - b × floor(a/b) )
    movss xmm4, xmm0                ; Save original t
    mov eax, dword 2.0
    movd xmm1, eax
    divss xmm0, xmm1                ; xmm0 = t / 2.0
    cvttss2si eax, xmm0             ; eax = floor(t / 2.0)
    cvtsi2ss xmm1, eax
    mov eax, dword 2.0
    movd xmm2, eax
    mulss xmm1, xmm2                ; xmm1 = floor * 2.0
    movss xmm0, xmm4                ; Restore original t
    subss xmm0, xmm1                ; xmm0 = t - t* floor(t / 2.0) =  t % 2.0 

    ; Convert 0-2 range to 0-1-0 
    mov eax, dword 1.0
    movd xmm1, eax
    movss xmm2, xmm0
    subss xmm2, xmm1                ; xmm2 = (t % 2) - 1 (range -1 to 1)
    movaps xmm3, xmm2
    mulss xmm3, xmm3                ; Square to make positive
    sqrtss xmm3, xmm3               ; Take sqrt to get abs -1,1 to 1,0,1
    mov eax, dword 1.0
    movd xmm2, eax
    subss xmm2, xmm3                ; xmm2 = 1 - abs((t % 2) - 1) (0,1,0)

    movss [norm_time_loop], xmm2         ; Store computed time

    movdqa xmm0, [rsp]
    movdqa xmm1, [rsp + 16]

    ; Compute point in line parametrized by t
    movss xmm2, [norm_time_loop]
    shufps xmm2, xmm2, 0            ; Broadcast 

    movaps xmm3, xmm1               ; xmm3 = [x2, y2]
    subps xmm3, xmm0                ; xmm3 = [x2-x1, y2-y1]
    mulps xmm3, xmm2                ; xmm3 = [(x2-x1)*t, (y2-y1)*t]
    addps xmm3, xmm0                ; xmm3 = [(x2-x1)*t + x1, (y2-y1)*t + y1]

    movq xmm0, xmm3
    movss xmm1, [circle_radius] 
    mov edi, dword [circle_color]
    sub rsp, 16
    movdqa [rsp], xmm3
    call DrawCircleV
    movdqa xmm3, [rsp]
    add rsp, 16

    movq xmm0, xmm3 ; return pos on xmm0
    
    leave                           ; Restore rbp and rsp
    ret

section '.data' writeable align 16

anchor_size:
    dd 50.0

current_anchor_byte_offset:
    dq 0

line_thickness:
    dd 3.0

circle_radius:
    dd 8.0

circle_color:
    dd 0xFFFFFF00

line_color:
    dd 0xFF00FF00

norm_time_loop:
    dd 0.0

mouse_position:
    dd 0.0
    dd 0.0

mouse_position_on_center:
    dd 0.0
    dd 0.0

drag_start_mouse:
    dd 0.0
    dd 0.0

drag_start_anchor:
    dd 0.0
    dd 0.0

is_dragging: db 0

align 16  
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

circle1:
    dd 0.0
    dd 0.0

circle2:
    dd 0.0 
    dd 0.0 

current_anchor: db 0
anchor_to_add: db 0

title: db "Beziasm", 0
mouseXmsg db "Current Mouse X %d.", 0xA,0    
toadddmsg db "Anchor to add %i.", 0xA,0    
currmsg db "Anchor selected %i.", 0xA,0    
debugmsg: db "Anchor stored: x=%d y=%d w=%d h=%d", 0xA, 0
collchkmsg: db "Checking: mouse(%d,%d) vs rect(%d,%d,%d,%d)", 0xA, 0
mouse_pos_msg: db "Mouse: x=%d y=%d", 0xA, 0
mouse_offset_msg: db "Mouse Offseted: x=%d y=%d", 0xA, 0
a_debug_msg: db "a value: %f", 0xA, 0
circle1_msg: db "Circle1: x=%d y=%d", 0xA, 0
circle2_msg: db "Circle2: x=%d y=%d", 0xA, 0

debug_circle_msg: db "DEBUG: Storing circle x=%d y=%d", 0xA, 0
section '.note.GNU-stack'