.model tiny
.286 
.code
org 100h

centre_offset             equ 5 * 160 + 80
one_line_len              equ 160
F12_scancode_press        equ 58h
F12_scancode_unpress      equ 58h + 80h 
color                     equ 0ah  
video_seg                 equ 0b800h      

Start:          mov ax, 3509h
                int 21h
                mov word ptr old09off, bx
                mov word ptr old09seg, es

                mov ax, 3508h
                int 21h
                mov word ptr old08off, bx
                mov word ptr old08seg, es

                mov ax, 0
                mov es, ax

                mov bx, 4 * 09h
                cli 
                mov es:[bx], offset My09IntFunc
                mov ax, cs
                mov es:[bx + 2], ax
                sti 

                mov bx, 4 * 08h
                cli 
                mov es:[bx], offset My08IntFunc
                mov ax, cs
                mov es:[bx + 2], ax
                sti 

                mov ax, 3100h
                mov dx, offset EOP
                shr dx, 4
                inc dx

                ;call My09IntFunc
                int 21h

;-----------------------------------------------------------------------
; Функция прерывания номер 8, которая по тику процессора обновляет значения регистров в видеопамяти
; Входные данные:  -
; Выходные данные: -
;-----------------------------------------------------------------------
My08IntFunc     proc

                pusha
                push ds
                push es
                push ss

                cmp cs:[F12_press_status], 0
                je F12_unpress

                call PrintRegs

F12_unpress:
                pop ss
                pop es
                pop ds
                popa

                db 0eah
old08off        dw 0
old08seg        dw 0

                iret
                endp

;-----------------------------------------------------------------------
; Функция прерывания номер 9, которая при нажатой клавишы F12 выводит на экран значение регистров
; Входные данные:  -
; Выходные данные: -
;-----------------------------------------------------------------------
My09IntFunc     proc

                pusha
                push ds
                push es
                push ss

                ;call PrintRegs

                in al, 60h  

                cmp al, F12_scancode_press
                je F12_button_press

                jmp end_F12_button

F12_button_press:

                cmp cs:[F12_press_status], 1
                je F12_second_press

                call PrintRegs                              ;первое нажатие клавиши f12
                mov byte ptr cs:[F12_press_status], 1

                jmp end_F12_button

F12_second_press:

                ;call PrintOldSymbols                        ;второе нажатие f12
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
                popa

                db 0eah
old09off        dw 0
old09seg        dw 0

                iret
                endp

;-----------------------------------------------------------------------
; Процедура вывода на экран значений регистров в момент нажатия клавиши
; Смещения в стеке:
;             1  - ip    - 30
;             2  - cs    - 28
;             3  - flags - 26
;             4  - ax    - 24
;             5  - cx    - 22
;             6  - dx    - 20
;             7  - bx    - 18
;             8  - sp    - 16
;             9  - bp    - 14
;             10 - si    - 12
;             11 - di    - 10
;             12 - ds    - 8
;             13 - es    - 6
;             14 - ss    - 4
;
; Использует: cx, ax, di, bx
;-----------------------------------------------------------------------
PrintRegs       proc

                push bp
                mov bp, sp
                
                mov ax, video_seg
                mov es, ax

                mov di, centre_offset
                mov cx, 24
                mov bx, offset regs_names

loop_1:
                add bp, cx
                mov ax, ss:[bp]
                sub bp, cx

                call PrintOneReg

                add bx, 2
                add di, one_line_len
                sub cx, 2

                cmp cx, 2
                ja loop_1

                pop bp

                ret
                endp

;-----------------------------------------------------------------------
; Процедура вывода в видеопамять es:di 4 символов названия регистра и значения ax
; Входные данные:  ax - 4 байтное значение для вывода на экран
;                   di - позиция в видеопамяти для вывода на 4 символа
;                   bx - указатель на название
; Выходные данные:
;-----------------------------------------------------------------------
PrintOneReg     proc


                push di
                push cx
                push ax             ; сохраняем выводимое значение регистра ax - 1234

                mov cl, cs:[bx]
                mov byte ptr es:[di], cl
                mov byte ptr es:[di + 1], color
                add di, 2

                mov cl, cs:[bx + 1]
                mov byte ptr es:[di], cl
                mov byte ptr es:[di + 1], color
                add di, 2

                mov byte ptr es:[di], 0
                mov byte ptr es:[di + 1], color

                add di, 2

                mov byte ptr es:[di], 3dh
                mov byte ptr es:[di + 1], color
                add di, 2

                mov byte ptr es:[di], 0
                mov byte ptr es:[di + 1], color

                add di, 2
                
                pop ax
                push ax

                shr ax, 12           ; получаем первую цифру 0001

                call PrintSym

                pop ax
                push ax             ; сохраняем выводимое значение регистра ax - 1234

                shl ax, 4
                shr ax, 12          ; получаем вторую цифру 0002

                add di, 2
                call PrintSym

                pop ax
                push ax             ; сохраняем выводимое значение регистра ax - 1234

                shl ax, 8
                shr ax, 12          ; получаем третью цифру 0003

                add di, 2
                call PrintSym

                pop ax

                shl ax, 12
                shr ax, 12          ; получаем четвертую цифру 0004

                add di, 2
                call PrintSym

                pop cx
                pop di

                ret
                endp

;-----------------------------------------------------------------------
; Процедура вывода в видеопамять es:di с цветом шестнадцатиричной цифры в виде символа
; Входные данные:  di - позиция для вывода символа
;                  ax - номер символа (цифра для вывода)
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

video_buffer              db 160 dup (?)
regs_names                db "AXCXDXBXSPBPSIDIDSCSESSS"
F12_press_status          db 0

EOP:


end Start