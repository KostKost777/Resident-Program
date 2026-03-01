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
equal_sign                equ 3dh
whitespace                equ 0h
flags_offset              equ 5 * 160 + 80 + 22
buffer_width              equ 34
buffer_length             equ 26

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
                call PrintFlags

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

                call SaveOldSym 
                call PrintRegs                              ;первое нажатие клавиши f12
                call PrintFlags
                

                mov byte ptr cs:[F12_press_status], 1

                jmp end_F12_button

F12_second_press:

                call PrintOldSyms                           ;второе нажатие f12
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
; Процедура вывода значений регистров в момент нажатия клавиши
; Смещения в стеке:
;             1  - flags - 30
;             2  - cs    - 28
;             3  - ip    - 26
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
; Портятся: cx, ax, di, bx
;-----------------------------------------------------------------------
PrintRegs       proc

                push bp
                mov bp, sp
                
                mov ax, video_seg
                mov es, ax

                mov di, centre_offset               ; начальное значение di
                mov cx, 28                          ; смещение наибольшего регистра в стеке
                mov bx, offset regs_names

loop_1:
                add bp, cx
                mov ax, ss:[bp]      
                sub bp, cx

                cmp cx, 16          ; смещение регистра sp
                jne not_reg_sp
                add ax, 6           ; так как в cтек пушится еще и flags, ip, cs

not_reg_sp:
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
; Процедура вывода в видеопамять es:di имя флага и его значение
; Входные данные:  по сдвигу 30 должно лежать 16-ричное число с информацие о флагах
; Выходные данные: -
; Портит: bx, di
;-----------------------------------------------------------------------
PrintFlags      proc

                push bp
                mov bp, sp

                mov di, flags_offset

                mov ax, ss:[bp + 30]

                push ax
                push 1
                call GetFlagStatus

                mov dx, "CF"
                call PrintOneFlag

                add di, one_line_len

                push ax
                push 4
                call GetFlagStatus

                mov dx, "PF"
                call PrintOneFlag

                add di, one_line_len

                push ax
                push 16
                call GetFlagStatus

                mov dx, "AF"
                call PrintOneFlag

                add di, one_line_len

                push ax
                push 64
                call GetFlagStatus

                mov dx, "ZF"
                call PrintOneFlag

                add di, one_line_len

                push ax
                push 128
                call GetFlagStatus

                mov dx, "SF"
                call PrintOneFlag

                add di, one_line_len

                push ax
                push 256
                call GetFlagStatus

                mov dx, "TF"
                call PrintOneFlag

                add di, one_line_len

                push ax
                push 512
                call GetFlagStatus

                mov dx, "IF"
                call PrintOneFlag

                add di, one_line_len

                push ax
                push 1024
                call GetFlagStatus

                mov dx, "DF"
                call PrintOneFlag

                add di, one_line_len

                push ax
                push 2048
                call GetFlagStatus

                mov dx, "OF"
                call PrintOneFlag

                add di, one_line_len

                pop bp
                ret
                endp

;-----------------------------------------------------------------------
; Выводит имя флага и его значение через знак равенства
; Входные данные:  dx - имя флага
;                  bx - значение флага
;                  di - адрес в видео памяти
;
; Выходные данные: -
; Портит: 
;-----------------------------------------------------------------------
PrintOneFlag    proc

                push cx
                push di

                mov ch, color

                mov cl, dh
                call PrintSym

                mov cl, dl
                call PrintSym

                mov cl, whitespace
                call PrintSym

                mov cl, equal_sign
                call PrintSym

                mov cl, whitespace
                call PrintSym

                mov cl, bl
                call PrintSym

                pop di
                pop cx

                ret

                endp

;-----------------------------------------------------------------------
; Проверка совпадение переданного значением с переданной маской
; Входные данные:  1 - значение
;                  2 - маска
; Выходные данные: bx - совпало/не совпало (1/0)
; Портит: ax, bx
;-----------------------------------------------------------------------
GetFlagStatus   proc

                push bp
                mov bp, sp

                mov ax, ss:[bp + 6]
                
                test ax, ss:[bp + 4]
                jnz equal_bit

                mov bl, '0'

                pop bp
                ret 4

equal_bit:
                mov bl, '1'

                pop bp
                ret 4

                endp
                
;-----------------------------------------------------------------------
; Процедура вывода в видеопамять es:di имя регистра и его 4 байтное значение
; Входные данные:   ax - 4 байтное значение для вывода на экран
;                   di - позиция в видеопамяти для вывода
;                   bx - указатель на имя регистра
; Выходные данные: -
;-----------------------------------------------------------------------
PrintOneReg     proc

                push di
                push cx

                push ax             ; сохраняем выводимое значение регистра ax - 1234

                call PrintRegName

                pop ax
                push ax

                shr ax, 12           ; получаем первую цифру 0001

                call PrintHexDigit

                pop ax
                push ax             ; сохраняем выводимое значение регистра ax - 1234

                shl ax, 4
                shr ax, 12          ; получаем вторую цифру 0002

                add di, 2
                call PrintHexDigit

                pop ax
                push ax             ; сохраняем выводимое значение регистра ax - 1234

                shl ax, 8
                shr ax, 12          ; получаем третью цифру 0003

                add di, 2
                call PrintHexDigit

                pop ax

                shl ax, 12
                shr ax, 12          ; получаем четвертую цифру 0004

                add di, 2
                call PrintHexDigit

                pop cx
                pop di

                ret
                endp

;-----------------------------------------------------------------------
; Процедура вывода в видеопамять es:di Название регистра и знак равенства "XX = "
; Входные данные:  di - адрес для вывода символа в видеопамять
;                  bx - указатель на название регистра
; Портит: cx
;-----------------------------------------------------------------------
PrintRegName    proc

                mov ch, color

                mov cl, cs:[bx]
                call PrintSym

                mov cl, cs:[bx + 1]
                call PrintSym

                mov cl, whitespace
                call PrintSym

                mov cl, equal_sign 
                call PrintSym

                mov cl, whitespace
                call PrintSym

                ret
                endp

;-----------------------------------------------------------------------
; Процедура вывода в видеопамять es:di символа лежащего в cl
; Входные данные:  di - позиция для вывода символа
;                  cl - символ
;                  ch - цвет символа
;
;Портит: di
;-----------------------------------------------------------------------
PrintSym        proc

                mov byte ptr es:[di], cl
                inc di
                mov byte ptr es:[di], ch
                inc di

                ret
                endp

;-----------------------------------------------------------------------
; Процедура вывода в видеопамять es:di с цветом шестнадцатиричной цифры в виде символа
; Входные данные:  di - позиция для вывода символа
;                  ax - номер символа (цифра для вывода)
;-----------------------------------------------------------------------
PrintHexDigit   proc

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

;-----------------------------------------------------------------------
; Процедура сохраняет байты из видеопамяти в буффер, чтобы потом можно было его восстановить 
; Входные данные: -
; Выходные данные: -
; Портит: di, cx, si, ax, bx
;-----------------------------------------------------------------------
SaveOldSym      proc

                mov ax, video_seg
                mov es, ax
                mov di, centre_offset
                xor cx, cx
                mov si, offset video_buffer
                mov bx, buffer_width
                

save_sym_loop:
                cmp cx, buffer_length * buffer_width
                ja end_save_loop

                mov byte ptr al, es:[di]
                mov byte ptr cs:[si], al

                inc si
                inc di
                inc cx

                cmp bx, cx
                jne save_sym_loop

                sub di, buffer_width
                add di, one_line_len

                add bx, buffer_width

                jmp save_sym_loop

end_save_loop:

                ret
                endp

;-----------------------------------------------------------------------
; Процедура выводит на экран сохранившиеся биты по адресу в код сегменте
; Входные данные: -
; Выходные данные: -
; Портит: di, cx, si, ax, bx, es
;-----------------------------------------------------------------------
PrintOldSyms    proc

                mov ax, video_seg
                mov es, ax
                mov di, centre_offset
                xor cx, cx
                mov si, offset video_buffer
                mov bx, buffer_width

print_old_sym_loop:
                cmp cx, buffer_length * buffer_width
                ja end_print_old_loop

                mov byte ptr al, cs:[si]
                mov byte ptr es:[di], al

                inc si
                inc di
                inc cx

                cmp bx, cx
                jne print_old_sym_loop

                sub di, buffer_width
                add di, one_line_len

                add bx, buffer_width

                jmp print_old_sym_loop

end_print_old_loop:

                ret
                endp

regs_names                db "CSIPAXCXDXBXSPBPSIDIDSESSS"
video_buffer              db (buffer_width * buffer_length) dup (?)
F12_press_status          db 0

EOP:


end Start