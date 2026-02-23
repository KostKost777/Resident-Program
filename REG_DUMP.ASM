.model tiny

.code

org 100h

centre_offset             equ 5 * 160 + 80
F12_scancode_press        equ 58h
F12_scancode_unpress      equ 58h + 80h          

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

        mov ax, 3100h
        mov dx, offset EOP
        shr dx, 4
        inc dx

        int 21h

My09IneraptFunc proc

        push ax
        push bx
        push cx
        push es

        mov ax, 0b800h
        mov es, ax

        mov bx, centre_offset
        mov ah, 4eh

        in al, 60h

        cmp al, F12_scancode_press
        je F12_button_press

        cmp al, F12_scancode_unpress
        je F12_button_unpress

        jmp end_F12_button

F12_button_press:

        cmp cs:[F12_press_status], 1
        je end_F12_button

        mov cx, es:[bx]
        mov word ptr cs:[old_sym], cx

        mov es:[bx], ax
        mov byte ptr cs:[F12_press_status], 1

        jmp end_F12_button

F12_button_unpress:
        cmp cs:[F12_press_status], 0
        je end_F12_button

        mov word ptr cx, cs:[old_sym]
        mov  es:[bx], cx

        mov byte ptr cs:[F12_press_status], 0

end_F12_button:
        in al, 61h
        or al, 80h
        out 61h, al
        and al, not 80h
        out 61h, al

        mov al, 20h
        out 20h, al

        pop es
        pop cx
        pop bx
        pop ax

         db 0eah
old09off dw 0
old09seg dw 0

        iret
        endp

old_sym                   dw 0
F12_press_status          dw 0

EOP:
end Start