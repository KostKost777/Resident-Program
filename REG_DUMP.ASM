.model tiny

.code

org 100h

centre_offset             equ 5 * 160 + 80
F12_scancode_press        equ 58h
F12_scancode_unpress      equ 58h + 80h 
color                     equ 4eh         

Start:          mov ax, 3509h
                int 21h
                mov word ptr old09off, bx
                mov word ptr old09seg, es

                mov ax, 0
                mov es, ax

                mov bx, 4 * 09h
                cli 
                mov es:[bx], offset My09IntFunc
                mov ax, cs
                mov es:[bx + 2], ax
                sti 

                mov ax, 3100h
                mov dx, offset EOP
                shr dx, 4
                inc dx

                int 21h

My09IntFunc     proc

                push ax
                push di
                push cx
                push es

                mov ax, 0b800h
                mov es, ax

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

                call PrintRegs

                mov byte ptr cs:[F12_press_status], 1

                jmp end_F12_button

F12_button_unpress:

                cmp cs:[F12_press_status], 0
                je end_F12_button

                call PrintOldSymbols

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
                pop di
                pop ax

                db 0eah
old09off        dw 0
old09seg        dw 0

                iret
                endp

old_sym                   dw 0
F12_press_status          dw 0

;-----------------------------------------------------------------------
;Выводит на экран значение всех регистров
;Принимает:  di - адрес откуда в столбик начнуть печататься регстры, 
;Портит:     di
;-----------------------------------------------------------------------
PrintRegs       proc

                push di

                mov di, centre_offset
                push di
                call PrintRegAx

                pop di

                ret
                endp

;--------------------------Pascal---------------------------------------
;Выведет по указанному адресу es:di в видео память четыре числа характерные 4 байтам регистра AX
;Принимает:  1 - адрес откуда начать выводить регистр AX, 
;-----------------------------------------------------------------------

PrintRegAx      proc

                push bp
                mov bp, sp

                push di
                mov di, [bp + 4]

                push ax             ;сохраняем исходное значение регистра ax - 1234

                shr ax, 12           ;Получаем вид 0001

                push di
                push ax
                call PrintSym

                pop ax
                push ax             ;сохраняем исходное значение регистра ax - 1234

                shl ax, 4
                shr ax, 12          ;Получаем вид 0002

                add di, 2
                push di
                push ax
                call PrintSym

                pop ax
                push ax             ;сохраняем исходное значение регистра ax - 1234

                shl ax, 8
                shr ax, 12          ;Получаем вид 0003

                add di, 2
                push di
                push ax
                call PrintSym

                pop ax

                shl ax, 12
                shr ax, 12          ;Получаем вид 0004

                add di, 2
                push di
                push ax
                call PrintSym

                pop di
                pop bp

                ret 2
                endp

;-------------------------------Pascal------------------------------------
;Выведет по указанному адресу es:di в видео память четыре числа характерные 4 байтам регистра AX
;Принимает:  1 - адрес куда выводить элемент
;            2 - сам символ для вывода
;-----------------------------------------------------------------------
PrintSym        proc

                push bp
                mov bp, sp

                push di
                push ax

                mov ax, [bp + 4]
                mov di, [bp + 6]

                cmp ax, 10
                jl parse_digit

                add al, 'A' - 10
                jmp end_parse

parse_digit:    add al, '0'
end_parse:
                mov byte ptr es:[di], al
                mov byte ptr es:[di + 1], color

                pop ax
                pop di
                pop bp

                ret 4
                endp


PrintOldSymbols proc

                push di

                mov di, centre_offset

                mov byte ptr es:[di], 20h
                mov byte ptr es:[di + 1], 0h
                mov byte ptr es:[di + 2], 20h
                mov byte ptr es:[di + 3], 0h
                mov byte ptr es:[di + 4], 20h
                mov byte ptr es:[di + 5], 0h
                mov byte ptr es:[di + 6], 20h
                mov byte ptr es:[di + 7], 0h

                pop di

                ret
                endp

EOP:
end Start