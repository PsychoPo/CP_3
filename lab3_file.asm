model small
.data
    databuf db 50 dup(?)
    len dw $ - databuf
    input_file db 'TEST.TXT', 0
    buf db 50 dup(?)
    filesize dw 50
    path2 db 'RESULT.TXT',0
    handle dw ?
    handle2 dw ?
    sign db ?

    open_error db 'OPEN_ERROR$', 0Dh, 0Ah, '$'
    read_error db 'READ_ERROR$', 0Dh, 0Ah, '$'
    create_error db 'CREATE_ERROR$', 0Dh, 0Ah, '$'
    write_error db 'WRITE_ERROR$', 0Dh, 0Ah, '$'
    close_error db 'CLOSE_ERROR$', 0Dh, 0Ah, '$'
.code
.386
start:
    mov ax, @data
    mov ds, ax

    call open_file

    call read_file

    call create_file

    xor ax, ax
    
    finit
    call read_float
    inc si
    mov al, databuf[si]
    mov dl, al
    inc si
    inc si
    inc si
    call read_float
    push 10

    cmp dl, '-'
    je subtraction
    fadd
    jmp outp
    subtraction:
        fsub
    outp:
        call OutFloat
    
    xor ax, ax
    int 16h
    .exit
    
    ten equ word ptr [bp-2]
    temp equ word ptr [bp-4]

    open_file proc
        mov al, 0
        mov ah, 3dh
        mov dx, offset input_file
        int 21h
        jc err_open
        mov handle, ax
        ret
        err_open:
            xor dx, dx
            mov dx, offset open_error
            mov ah, 09h
            int 21h
            ret
    open_file endp

    read_file proc
        mov ah, 3fh
        mov bx, handle
        mov cx, filesize
        mov dx, offset databuf
        int 21h
        jc err_read
        ret
        err_read:
            xor dx, dx
            mov dx, offset read_error
            mov ah, 09h
            int 21h
            ret
    read_file endp

    create_file proc
        mov cx,0
        mov al,1
        mov ah,3ch
        mov dx,offset path2
        int 21h
        mov handle2,ax
        jc err_create
        ret
        err_create:
            xor dx, dx
            mov dx, offset create_error
            mov ah, 09h
            int 21h
            ret
    create_file endp

    write_file proc
        mov ah, 40h
        mov bx, handle2
        mov cx, filesize
        mov dx, offset buf
        int 21h
        jc err_write
        ret
        err_write:
            xor dx, dx
            mov dx, offset write_error
            mov ah, 09h
            int 21h
            ret
    write_file endp

    close_input_file proc
        mov bx, handle
        mov ah, 3eh
        int 21h
        jc err_close_input
        ret
        err_close_input:
            xor dx, dx
            mov dx, offset close_error
            mov ah, 09h
            int 21h
            ret
    close_input_file endp

    close_output_file proc
        mov bx, handle2
        mov ah, 3eh
        int 21h
        jc err_close_output
        ret
        err_close_output:
            xor dx, dx
            mov dx, offset close_error
            mov ah, 09h
            int 21h
            ret
    close_output_file endp
    
    read_float proc
        enter 4, 0
        mov ten, 10
        fldz
        xor bx, bx ; символ
        mov al, databuf[si]
        inc si
        cmp al, '-'
        jne @read_float2
        xor bx, 1
        @read_float1:
            mov al, databuf[si]
            inc si
        @read_float2:
            cmp al, '.'
            je @read_float3
            cmp al, '9'
            ja @read_float6
            sub al, '0'
            jb @read_float6
            cbw
            mov temp, ax
            fimul ten
            fiadd temp
            jmp @read_float1
        @read_float3:
            fld1
        @read_float4:
            ;mov ah, 01h
            ;int 21h
            mov al, databuf[si]
            inc si

            cmp al, '9'
            ja @read_float5
            sub al, '0'
            jb @read_float5
            cbw
            mov temp, ax
            fidiv ten
            fld st(0)
            fimul temp
            faddp st(2), st
            jmp short @read_float4
        @read_float5:
            fstp st(0)
        @read_float6:
            ;mov al, 10
            ;int 29h
            ;mov al, 0Dh
            ;int 29h
            or bx, bx
            jz @q
            fchs
        @q:
            leave
            ret
    read_float endp
    
    length_frac equ [bp+4]
    
    OutFloat proc near
        xor si, si
        enter 4, 0
        mov ten, 10
        ftst
        fstsw ax
        sahf
        jnc @positiv
        mov al, '-'
        mov buf[si], al
        inc si
        int 29h
        fchs
    @positiv:
        fld1
        fld st(1)
        fprem
        fsub st(2), st
        fxch st(2)
        xor cx, cx
    @1:
        fidiv ten
        fxch st(1)
        fld st(1)
        fprem
        fsub st(2), st
        fimul ten
        fistp temp
        push temp
        inc cx
        fxch st(1)
        ftst
        fstsw ax
        sahf
        jnz @1
    @2:
        pop ax
        add al, '0'
        mov buf[si], al
        inc si 
        int 29h
        loop @2
        fstp st
        fxch st(1)
        ftst
        fstsw ax
        sahf
        jz @quit
        mov al, '.'
        mov buf[si], al
        inc si  
        int 29h
        mov cx, length_frac
    @3:
        fimul ten
        fxch st(1)
        fld st(1)
        fprem
        fsub st(2), st
        fxch st(2)
        fistp temp
        mov ax, temp
        or al, 30h
        mov buf[si], al
        inc si  
        int 29h
        fxch st(1)
        ftst
        fstsw ax
        sahf
        loopne @3
    @quit:
        call write_file

        call close_output_file
        call close_input_file

        fstp
        fstp st
        leave
        ret 2
    OutFloat endp
 
end start