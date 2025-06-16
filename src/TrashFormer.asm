

.data

; mask: 4 bytes (r8)
;   [x]xxx -> usable registers
;   x[x]xx -> usable instructions
;   xx[x]x -> source and destination registers
;   xxx[x] -> InstructionNumber

; usable registers mask
reg_rax         equ             00000001b       ; 1
reg_rcx         equ             00000010b       ; 2
reg_rdx         equ             00000100b       ; 4
reg_r8          equ             00001000b       ; 8
reg_r9          equ             00010000b       ; 16
reg_r10         equ             00100000b       ; 32
reg_r11         equ             01000000b       ; 64
reg_any         equ             01111111b       ; 127



; instructions used
mov_cmd       equ         00000001b             ; 8bh
cmp_cmd       equ         00000010b             ; 3Bh
or_cmd        equ         00000100b             ; 0bh
xor_cmd       equ         00001000b             ; 33h
lea_cmd       equ         00010000b             ; 8Dh
any_cmd       equ         11111111b             ; FFh



; src dst registers
reg_rxx_rxx     equ              00000001b       ; 1
reg_rxx_rx      equ              00000010b       ; 2
reg_rx_rxx      equ              00000100b       ; 4
reg_rx_rx       equ              00001000b       ; 8
reg_any_any     equ              11111111b       ; 0xFF



; usable destination registers operation
ins_c0          equ             00001001b ; (rax, r8)
ins_c8          equ             00010010b ; (rcx, r9)
ins_d0          equ             00100100b ; (rdx, r10)
ins_d8          equ             01000000b ; (r11)


UserBuf qword 0h
UserSize dword 0h

usableReg byte 0h
usableIns byte 0h
srcDest byte 0h

instructionsNumber byte 0h

RegistersMask byte 0h



.code

TrashFormer proc public

  push rcx
  push rdx
  push rdi
  push r8
  push r9
  push r10
  push r11
  

  xor rax, rax				; rax = 0

  or rcx, rcx				; check userbuf ptr
  jz __error
  mov UserBuf, rcx
  mov rdi, rcx				; move userbuf ptr to `rdi` for `stosb` instruction
  xor rcx, rcx


  or edx, edx				; check userbuf size
  jz __error
  cmp edx, 16
  jbe __error
  sub edx, 16               ; avoid overflows
  mov UserSize, edx
  xor rdx, rdx


  or r8d, r8d				; check mask flag
  jz __error

  or r8b, r8b				; check number of junk instructions
  jz __error
  mov instructionsNumber, r8b

  shr r8d, 8
  or r8b, r8b				; check usable srcdst flag
  jz __error
  mov srcDest, r8b

  shr r8d, 8
  or r8b, r8b				; check usable instructions flag
  jz __error
  mov usableIns, r8b

  shr r8d, 8
  or r8b, r8b				; check usable registers flag
  jz __error
  mov usableReg, r8b
  shr r8d, 8

  xor rax, rax
  mov al, instructionsNumber
  cmp eax, UserSize
  jae __error


__cycle:

  cmp instructionsNumber, 8
  je __ret_end
  dec instructionsNumber

  sub UserSize, 3
  cmp UserSize, 6
  jbe __ret_end
  add r9, 3

__movement_dispatcher:
  xor rax, rax
  mov al, srcDest

  bt rax, 7
  jc __reg_any


__movement_cycle:
  call randNum4

  mov rcx, rax
 
  mov al, srcDest
  bt rax, rcx
  jnc __movement_cycle

  test usableReg, 111b
  jz __only_rx

  cmp rcx, 0                ;reg_rxx_rxx        01001000 -> 00000001
  jz __rxx_rxx

  cmp rcx, 1                ;reg_rxx_rx         01001001 -> 00000010
  jz __rxx_rx


  test usableReg, 1111000b
  jz __movement_cycle

__only_rx:
  cmp rcx, 2                ;reg_rx_rxx         01001100 -> 00000100
  jz __rx_rxx

  cmp rcx, 3                ;reg_rx_rx          01001101 -> 00001000
  jz __rx_rx

  jmp __movement_cycle


__reg_any:

    xor rax, rax
    call randNum4
    cmp rax, 0
    jz __rxx_rxx
    cmp rax, 1
    jz __rxx_rx
    cmp rax, 2
    jz __rx_rxx
    cmp rax, 3
    jz __rx_rx
    jmp __instructionDispatcher
    


__rxx_rxx:

    xor rax, rax
    mov al, 48h
    cld                     ; clear direction flag so DF = 0, going forward
    stosb

    jmp __instructionDispatcher
    


__rxx_rx:

    xor rax, rax
    mov al, 49h
    cld                     ; clear direction flag so DF = 0, going forward
    stosb

    jmp __instructionDispatcher
    


__rx_rxx:

    xor rax, rax
    mov al, 4ch
    cld                     ; clear direction flag so DF = 0, going forward
    stosb

    jmp __instructionDispatcher
    


__rx_rx:

    xor rax, rax
    mov al, 4dh
    cld                     ; clear direction flag so DF = 0, going forward
    stosb

    jmp __instructionDispatcher
    


__instructionDispatcher:
    
    mov r8b, al
    xor rax, rax
    mov al, usableIns
    bt rax, 7
    jc __any_cmd

__instructionCycle:
    call randNum4

    mov rcx, rax

    mov al, usableIns
    bt rax, rcx
    jnc __instructionCycle

    cmp rcx, 4
    jz __lea_cmd
    
    cmp rcx, 3
    jz __xor_cmd
    
    cmp rcx, 2
    jz __or_cmd
    
    cmp rcx, 1
    jz __cmp_cmd
    
    cmp rcx, 0
    jz __mov_cmd


    jmp __error



__any_cmd:
    
    xor rax, rax
    call randNum5
    
    cmp rax, 0
    jz __mov_cmd
    
    cmp rax, 1
    jz __cmp_cmd
    
    cmp rax, 2
    jz __or_cmd
    
    cmp rax, 3
    jz __xor_cmd
    
    cmp rax, 4
    jz __lea_cmd

    jmp __error



;   mov_cmd       equ         8bh
__mov_cmd:

    mov ecx, eax
    xor rax, rax
    mov al, 8bh
    cld                     ; clear direction flag so DF = 0, going forward
    stosb

    jmp __dataDispatcher



;   or_cmd        equ         0bh
__or_cmd:

    mov ecx, eax
    xor rax, rax
    mov al, 0bh
    cld                     ; clear direction flag so DF = 0, going forward
    stosb

    jmp __dataDispatcher



;   xor_cmd       equ         33h
__xor_cmd:

    mov ecx, eax
    xor rax, rax
    mov al, 33h
    cld                     ; clear direction flag so DF = 0, going forward
    stosb

    jmp __dataDispatcher



;   lea_cmd       equ         8Dh
__lea_cmd:

    cmp r8b, 48h
    jne __instructionDispatcher

    test usableReg, 111b
    jz __instructionDispatcher

    mov ecx, eax
    xor rax, rax
    mov al, 8dh
    cld                     ; clear direction flag so DF = 0, going forward
    stosb


__lea_rnd:
    
    call randNum3

    mov rcx, rax

    mov al, usableReg
    bt rax, rcx
    jnc __lea_rnd

    cmp rcx, 0
    je __lea_rax
    
    cmp rcx, 1
    je __lea_rcx

    cmp rcx, 2
    je __lea_rdx


__lea_rax:

    xor rax, rax
    xor rcx, rcx

    call randNum3
    test rax, rax
    jz __lea_rax

    stosb
    jmp __cycle


__lea_rcx:

    xor rax, rax
    xor rcx, rcx

    mov cl, 08

    call randNum2
    test rax, rax
    jz _off_lea
    or cl, 2

_off_lea:

    mov al, cl
    stosb
    jmp __cycle


__lea_rdx:

    xor rax, rax
    xor rcx, rcx

    mov cl, 10h

    call randNum2

    or cl, al
    mov al, cl

    stosb
    jmp __cycle



;   cmp_cmd       equ         3Bh
__cmp_cmd:

    xor rax, rax
    mov al, 3bh
    cld                     ; clear direction flag so DF = 0, going forward
    stosb

    jmp __dataDispatcher



__dataDispatcher:
    
; mov_cmd       equ         00000001b             ; 8bh
; cmp_cmd       equ         00000010b             ; 3Bh
; or_cmd        equ         00000100b             ; 0bh
; xor_cmd       equ         00001000b             ; 33h
; lea_cmd       equ         00010000b             ; 8Dh

; EXCEPTIONAL CASES:
    ;   lea

    call randNum7

    mov rcx, rax

    mov al, usableReg
    bt rax, rcx
    
    jnc __dataDispatcher
    
    cmp rcx, 0
    jz __rax_dst

    cmp rcx, 1
    jz __rcx_dst
    
    cmp rcx, 2
    jz __rdx_dst
    
    cmp rcx, 3
    jz __r8_dst
    
    cmp rcx, 4
    jz __r9_dst
    
    cmp rcx, 5
    jz __r10_dst
    
    cmp rcx, 6
    jz __r11_dst


; put the last byte on the three-byte instruction (except on `lea`) and go to __cycle again

__rax_dst:
    
    xor rax, rax
    xor rcx, rcx

    call randNum3
    mov rcx, rax
    mov al, 0c0h
    or al, cl

    stosb
    jmp __cycle


__rcx_dst:

    xor rax, rax
    xor rcx, rcx

    call randNum3
    mov rcx, rax
    mov al, 0c8h
    or al, cl

    stosb
    jmp __cycle


__rdx_dst:

    xor rax, rax
    xor rcx, rcx

    call randNum3
    mov rcx, rax
    mov al, 0d0h
    or al, cl

    stosb
    jmp __cycle


__r8_dst:

    xor rax, rax
    xor rcx, rcx

    call randNum4
    mov rcx, rax
    mov al, 0c0h
    or al, cl

    stosb
    jmp __cycle


__r9_dst:

    xor rax, rax
    xor rcx, rcx

    call randNum4
    mov rcx, rax
    mov al, 0c0h
    or al, cl

    stosb
    jmp __cycle


__r10_dst:

    xor rax, rax
    xor rcx, rcx

    call randNum3
    mov rcx, rax
    mov al, 0c0h
    or al, cl

    stosb
    jmp __cycle


__r11_dst:

    xor rax, rax
    xor rcx, rcx

    mov al, 0dbh

    stosb
    jmp __cycle


__ret_end:
    xor rax, rax
    mov al, 0c3h
    stosb
    jmp __success



__Success:

    xor rax, rax
    jmp __exit



__error:
    mov rcx, r9
    mov al, 00h
    rep stosb
	mov rax, 1234

__exit:
	
  pop r11
  pop r10
  pop r9
  pop r8
  pop rdi
  pop rdx
  pop rcx

  ret

TrashFormer endp


; randNumX: Get a random number between 0 and (X-1). The result is on rax

randNum219 proc
    call randFunc
    xor rdx, rdx
    mov rcx, 219
    div rcx
    mov rax, rdx
    ret
randNum219 endp


randNum64 proc
    call randFunc
    xor rdx, rdx
    mov rcx, 64
    div rcx
    mov rax, rdx
    ret
randNum64 endp


randNum8 proc
    call randFunc
    xor rdx, rdx
    mov rcx, 8
    div rcx
    mov rax, rdx
    ret
randNum8 endp


randNum7 proc
    call randFunc
    xor rdx, rdx
    mov rcx, 7
    div rcx
    mov rax, rdx
    ret
randNum7 endp


randNum6 proc
    call randFunc
    xor rdx, rdx
    mov rcx, 6
    div rcx
    mov rax, rdx
    ret
randNum6 endp


randNum5 proc
    call randFunc
    xor rdx, rdx
    mov rcx, 5
    div rcx
    mov rax, rdx
    ret
randNum5 endp


randNum4 proc
    call randFunc
    xor rdx, rdx
    mov rcx, 4
    div rcx
    mov rax, rdx
    ret
randNum4 endp


randNum3 proc
    call randFunc
    xor rdx, rdx
    mov rcx, 3
    div rcx
    mov rax, rdx
    ret
randNum3 endp


randNum2 proc
    call randFunc
    xor rdx, rdx
    mov rcx, 2
    div rcx
    mov rax, rdx
    ret
randNum2 endp


randFunc proc
    rdtsc               ; edx:eax counter
    xor rax, rcx
    ret
randFunc endp

end
