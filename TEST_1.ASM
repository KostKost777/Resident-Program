.model tiny

.code

org 100h

centre_offset       equ 5 * 160 + 80

Start: 
        
        mov ax, 3509h
        int 21h
        mov word ptr old09off, bx
        mov word ptr old09seg, es

        mov ax, 0
        mov es, ax

        mov bx, 4 * 09h
        cli 
        mov es:[bx], offset My09IneraptFunc
        mov ax, cs
        mov es:[bx + 2], ax
        sti 

        pushf
        push cs
        call My09IneraptFunc

        mov ax, 3100h
        mov dx, offset EOP
        shr dx, 4
        inc dx

        int 21h

My09IneraptFunc proc

        push ax
        push bx
        push es

        mov ax, 0b800h
        mov es, ax

        mov bx, centre_offset
        mov ah, 4eh

        in al, 60h
        mov es:[bx], ax

        in al, 61h
        or al, 80h
        out 61h, al
        and al, not 80h
        out 61h, al

        mov al, 20h
        out 20h, al

        pop es
        pop bx
        pop ax

         db 0eah
old09off dw 0
old09seg dw 0

        iret
        endp

EOP:
end Start