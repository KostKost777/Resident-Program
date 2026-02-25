.model tiny
.286 
.code

org 100h

centre_offset             equ 5 * 160 + 80
F12_scancode_press        equ 58h
F12_scancode_unpress      equ 58h + 80h 
color                     equ 0ah  
video_seg                 equ 0b800h      

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

                pusha
                push ds
                push cs
                push es
                push ss

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

                ;call PrintOldSymbols

                mov byte ptr cs:[F12_press_status], 0

end_F12_button:
                in al, 61h
                or al, 80h
                out 61h, al
                and al, not 80h
                out 61h, al

                mov al, 20h
                out 20h, al

                pop ss
                pop es
                pop ds
                pop ds
                popa

                db 0eah
old09off        dw 0
old09seg        dw 0

                iret
                endp

old_sym                   dw 0
F12_press_status          dw 0

;-----------------------------------------------------------------------
; Вывод на экран содержимого регистров переданных через стек
; Принимает:  
;             1 - ip - 30
;             2 - ax - 28
;             3 - dx - 26
;             4 - bx - 24
;             5 - sp - 22
;             6 - bp - 20
;             2 - cx - 18
;             7 - si - 16
;             8 - di - 14
;             9 - ds - 12
;             10 - cs - 10
;             11 - es - 6
;             12 - ss - 4
; Возвращает: -
;-----------------------------------------------------------------------
PrintRegs       proc

                push bp
                mov bp, sp
                
                mov ax, video_seg
                mov es, ax

                mov di, centre_offset
                mov ax, ss:[bp + 26]

                call PrintOneReg

                pop bp

                ret
                endp

;-----------------------------------------------------------------------
; Вывод на указанной позиции es:di 4 байта переданные через регистр ax
; Принимает:  ax - 4 байта которые выведуться на экран
;             di - адрес в видеопамяти куда нарисовать эти 4 байта
;             bx - имя регистра
; Портит:
;-----------------------------------------------------------------------
PrintOneReg     proc


                push di
                push ax             ; сохраняем исходное значение регистра ax - 1234

                xor ax, ax
                mov al, 41h
                mov byte ptr es:[di], al
                mov byte ptr es:[di + 1], color
                add di, 2

                xor ax, ax
                mov al, 58h
                mov byte ptr es:[di], al
                mov byte ptr es:[di + 1], color
                add di, 2

                xor ax, ax
                mov al, 0
                mov byte ptr es:[di], al
                mov byte ptr es:[di + 1], color

                add di, 2

                xor ax, ax
                mov al, 3dh
                mov byte ptr es:[di], al
                mov byte ptr es:[di + 1], color
                add di, 2

                xor ax, ax
                mov al, 0
                mov byte ptr es:[di], al
                mov byte ptr es:[di + 1], color

                add di, 2
                
                pop ax
                push ax

                shr ax, 12           ; получаем цифру 0001

                call PrintSym

                pop ax
                push ax             ; сохраняем исходное значение регистра ax - 1234

                shl ax, 4
                shr ax, 12          ; получаем цифру 0002

                add di, 2
                call PrintSym

                pop ax
                push ax             ; сохраняем исходное значение регистра ax - 1234

                shl ax, 8
                shr ax, 12          ; получаем цифру 0003

                add di, 2
                call PrintSym

                pop ax

                shl ax, 12
                shr ax, 12          ; получаем цифру 0004

                add di, 2
                call PrintSym

                pop di

                ret
                endp

;-----------------------------------------------------------------------
; Вывод на указанной позиции es:di в текстовый видеобуфер символа (цифры) младшего полубайта числа
; Принимает:  di - адрес куда выводить символ
;             ax - сам символ (число для вывода)
;-----------------------------------------------------------------------
PrintSym        proc

                cmp ax, 10
                jl parse_digit

                add al, 'A' - 10
                jmp end_parse

parse_digit:    add al, '0'

end_parse:
                mov byte ptr es:[di], al
                mov byte ptr es:[di + 1], color

                ret
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