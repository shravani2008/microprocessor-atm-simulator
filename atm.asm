;**************************************************************
; Secure ATM Transaction Simulator - Corrected Version
; Platform: 8086 Assembly (TASM 5.1)
; Author: Shrau
; Features: PIN Authentication, Balance Check, Withdraw, Deposit
; Initial balance: 20000 (safe 16-bit)
;**************************************************************

.model small
.stack 100h
.data
    pin db 1,2,3,4               ; Correct 4-digit PIN
    enteredPin db 4 dup(?)       ; Buffer for entered PIN
    balance dw 1000             ; Initial balance
    
    msgWelcome db "**** WELCOME TO ATM ****",0dh,0ah,'$'
    msgEnterPin db "Enter 4-digit PIN: $"
    msgWrongPin db "Incorrect PIN! Try again.",0dh,0ah,'$'
    msgMenu db 0dh,0ah,"ATM MENU",0dh,0ah,"1. Check Balance",0dh,0ah,"2. Withdraw",0dh,0ah,"3. Deposit",0dh,0ah,"4. Exit",0dh,0ah,"Enter choice: $"
    msgBalance db 0dh,0ah,"Your Balance is: $"
    msgWithdraw db 0dh,0ah,"Enter amount to withdraw: $"
    msgDeposit db 0dh,0ah,"Enter amount to deposit: $"
    msgThankYou db 0dh,0ah,"Thank You! Visit Again.",0dh,0ah,'$'
    msgInsufficient db 0dh,0ah,"Insufficient Balance!",0dh,0ah,'$'

.code
main proc
    mov ax,@data
    mov ds,ax

; Display Welcome Message
    lea dx,msgWelcome
    mov ah,09h
    int 21h

; PIN Authentication Loop
pin_loop:
    lea dx,msgEnterPin
    mov ah,09h
    int 21h

    mov si,0
read_pin:
    mov ah,01h
    int 21h
    sub al,30h
    mov [enteredPin+si],al
    inc si
    cmp si,4
    jne read_pin

    mov si,0
compare_pin:
    mov al,[enteredPin+si]
    mov bl,[pin+si]
    cmp al,bl
    jne wrong_pin
    inc si
    cmp si,4
    jne compare_pin

    call atm_menu
    jmp exit_prog

wrong_pin:
    lea dx,msgWrongPin
    mov ah,09h
    int 21h
    jmp pin_loop

;*********************** ATM MENU ***************************
atm_menu proc
menu_start:
    lea dx,msgMenu
    mov ah,09h
    int 21h

    mov ah,01h
    int 21h
    sub al,30h
    cmp al,1
    je check_balance
    cmp al,2
    je withdraw
    cmp al,3
    je deposit
    cmp al,4
    je exit_prog
    jmp menu_start

; Check Balance
check_balance:
    lea dx,msgBalance
    mov ah,09h
    int 21h
    mov ax,balance
    call print_number
    jmp menu_start

; Withdraw Cash
withdraw:
    lea dx,msgWithdraw
    mov ah,09h
    int 21h
    call input_number
    cmp ax,balance
    ja insufficient
    sub balance,ax
    jmp menu_start

insufficient:
    lea dx,msgInsufficient
    mov ah,09h
    int 21h
    jmp menu_start

; Deposit Cash
deposit:
    lea dx,msgDeposit
    mov ah,09h
    int 21h
    call input_number
    ; Check for overflow
    mov bx,balance
    add bx,ax
    cmp bx,65535
    ja overflow
    add balance,ax
    jmp menu_start

overflow:
    lea dx,msgInsufficient
    mov ah,09h
    int 21h
    jmp menu_start

; Exit Program
exit_prog:
    lea dx,msgThankYou
    mov ah,09h
    int 21h
    mov ah,4Ch
    int 21h

atm_menu endp

;*********************** INPUT NUMBER ************************
; Reads multi-digit number safely (max 65535)
input_number proc
    xor ax,ax       ; AX accumulator
read_loop:
    mov ah,01h
    int 21h
    cmp al,13       ; Enter key?
    je done_input
    sub al,30h      ; ASCII -> digit
    cmp al,9
    ja read_loop    ; ignore non-digit keys
    ; AX = AX*10 + digit safely
    mov bx,ax       ; save current number
    mov cx,10
    mul cx          ; AX = AX*10
    mov bh,0        ; convert digit to 16-bit
    mov bl,al
    add ax,bx       ; add digit
    jmp read_loop
done_input:
    ret
input_number endp

;*********************** PRINT NUMBER ************************
print_number proc
    mov bx,10
    xor cx,cx
divide_loop:
    xor dx,dx
    div bx
    push dx
    inc cx
    cmp ax,0
    jne divide_loop
print_loop:
    pop dx
    add dl,30h
    mov ah,02h
    int 21h
    loop print_loop
    ret
print_number endp

main endp
end main
