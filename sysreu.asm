         *= $3000

; ----- Betriebssystem ---------------

komma    = $aefd ; sucht komma
valint   = $b1b5 ; int in lo/hi
getbyt   = $b79e ; holt byte
error    = $a43a ; gibt error aus
chrout   = $ffd2 ; druckt auf Scr
klamzu   = $aef7 ; prüft )
valpar   = $ad9e ; prueft paramtyp
valstr   = $b6a3 ; holt str anfangsadr
curpos   = $e510 ; setzt cursorpos

; -------- reuregister ---------------

reucmd   = $df01
c64stal  = $df02 ; c64 start lo
c64stah  = $df03 ; c64 start hi
reustal  = $df04 ; reu start lo
reustah  = $df05 ; reu start hi
reubank  = $df06 ; reubank #
reulengl = $df07 ; reu trans lenght lo
reulengh = $df08 ; reu trans lenght hi
reuadrct = $df0a ; reu adressctrlreg

; ---------- dummy -------------------

temp     = $033c
reupres  = $fb
reusize  = $fc

; ----------- Todo -------------------

         ; fehlernr $19=illegal quant.

         ; todo: basicloader erstellen
         ; sys <adr> -> Check reu&size
         ; 
         ; sys <adr+150> c64,reu,
         ;               laenge,bank,
         ;               action
         ; action 0 = c64 -> reu
         ;        1 = reu -> c64
         ;        2 = swap c64/reu
         ;        3 = verify
         ; $fb    1 -> reu detect
         ;        0 -> no reu
         ; $fc    = reusize in banks
         ;         (max 8MB)

; ------------ detect REU ------------

         ldx #2
loop1    txa
         sta $df00,x
         inx
         cpx #6
         bne loop1

         ldx #2
loop2    txa
         cmp $df00,x
         bne noreu
         inx
         cpx #6
         bne loop2

         lda #1
         sta reupres  ; wenn reu erkannt
         cmp #1
         beq det      ; dann groesse ermitteln

noreu    lda #0       ; ansonsten
         sta reupres  ; 
         
         rts          ; rücksprunk zu Basic

; ------- detect reu size -----------

det      lda #0
         sta $df04 ; reustlo
         sta $df05 ; reusthi
         sta $df08 ; lenghthi
         sta $df0a ; adrctrlreg
         lda #1
         sta $df07 ; lenghtlo

         lda #<temp 
         sta $df02 ; c64stlo
         lda #>temp
         sta $df03 ; c64sthi

         ldx #0
loop3    stx $df06 ; reubank
         stx temp
         stx temp+1
         lda #178
         sta $df01 ; reucmd
         lda temp
         sta temp+1,x
         inx
         bne loop3

         ldy #177
         ldx #0
         stx old
loop4    stx $df06
         sty $df01
         lda temp
         cmp old
         bcc next
         sta old
         inx
         bne loop4
next     stx size
         ldy #176
         ldx #255
loop5    stx $df06
         lda temp+1,x
         sta temp
         sty $df01
         dex
         cpx #255
         bne loop5
         lda size
         sta reusize

         rts

; --------- Parse sysline -----------

         jsr komma
         jsr valint
         lda $64     ; c64 adresse hi
         sta c64stah 
         ldx $65     ; c64 adresse lo
         stx c64stal

         jsr komma
         jsr valint
         lda $64     ; reu adresse hi
         sta reustah 
         ldx $65     ; reu adresse lo
         stx reustal

         jsr komma
         jsr valint
         lda $64     ; laenge hi
         sta reulengh
         ldx $65     ; laenge lo
         stx reulengl

         jsr komma
         jsr getbyt
         txa         ; wegen substrac
         sec         ; x->a transfer
         clc         ; carry ein und
         sbc $fc     ; loeschen. anz.
         bcs fehler  ; wenn<dann fehl
         stx $df06   ; bank anlegen

         jsr komma
         jsr getbyt
         txa         ; aktion
         sec         ; x->a transfer
         clc         ; carry ein und
         adc #144    ; loeschen. anz.
         sta reucmd

         rts

fehler   ldx #$0e    ; illegal quant.
         jsr error

         rts

; ------------------------------------

old      !word 0
size     !word 0


