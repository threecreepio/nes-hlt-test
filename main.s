.segment "INES"
.byte "NES",26;
.byte 1    ; prg
.byte 0    ; chr
.byte $01  ; vertical mirroring

.segment "PRG"
TestState             = $10
TestPhase             = $11
PPUCTRL               = $2000
PPUMASK               = $2001
PPUSTATUS             = $2002
PPUSCROLL             = $2005
PPUADDR               = $2006
PPUDATA               = $2007
SNDCHN                = $4015
JOYPAD_PORT           = $4016
.org $8000

; simple macro to write fixed data to the ppu
.macro WriteDataToPPU PPU, Start, Len
    ; update the ppu location
    lda #>PPU
    sta PPUADDR
    lda #<PPU
    sta PPUADDR
    ; and write 'Len' bytes to ppu, starting at the memory location in 'Start'
    ldx #0
:   lda Start,x
    sta PPUDATA
    inx
    cpx #Len
    bne :-
.endmacro

V_IRQ:
    bit SNDCHN
    rti

V_REBOOT:
    sei
    ldx #$FF
    txs
    ldx #0
	stx PPUCTRL
	stx PPUMASK
    ldy #0
    lda #0
:   sta $000,y
    sta $100,y
    sta $200,y
    sta $300,y
    sta $400,y
    sta $500,y
    sta $600,y
    sta $700,y
    iny
    bne :-
:   bit PPUSTATUS
    bpl :-
:   bit PPUSTATUS
    bpl :-
    lda #0
    sta PPUCTRL
    sta PPUMASK
    jsr PPUPaletteSetup
    jsr CopyCHR
    jsr ClearScreen
    WriteDataToPPU $2020, OkMsgStart, OkMsgEnd-OkMsgStart
    lda #%10001000
    sta PPUCTRL
    lda #%00000000
    sta PPUMASK
    lda #$0
    sta PPUSCROLL
    sta PPUSCROLL
:    jmp :-

V_NMI:
    lda #%00001010
    sta PPUMASK
    lda TestState
    bne @Done
    ldy TestPhase
    cpy #0
    bne @CheckNMI
    inc TestPhase
    .byte HLT_INSTRUCTION
    WriteDataToPPU $2020, FailMsg1Start, FailMsg1End-FailMsg1Start
    lda #1
    sta TestState
    jmp @Done
@CheckNMI:
    cpy #1
    bne @Done
    inc TestPhase
    WriteDataToPPU $2020, FailMsg2Start, FailMsg2End-FailMsg2Start
    lda #2
    sta TestState
    jmp @Done
@Done:
    lda #0
    sta PPUSCROLL
    sta PPUSCROLL
    rti

ClearScreen:
    lda #$20
    sta PPUADDR
    lda #$00
    sta PPUADDR
    lda #$0
    ldx #$0
    ldy #$0
:   sta PPUDATA
    iny
    bne :-
    inx
    cpx #$4
    bne :-
    rts

PPUPaletteSetup:
    bit PPUSTATUS
    ldx #0
    lda #$3F
    sta PPUADDR
    lda #$00
    sta PPUADDR
:   lda PaletteDataStart,x
    sta PPUDATA
    inx
    cpx #(PaletteDataEnd-PaletteDataStart)
    bne :-
    rts

CopyCHR:
    ; reposition to ascii start pos
    bit PPUSTATUS
    lda #0
    sta PPUADDR
    sta PPUADDR
    ; load ascii memory addresses
    lda #<AsciiDataStart
    sta $0
    ldx #>AsciiDataStart
    ldy #0
@Continue:
    stx $1
:   lda ($0),y
    sta PPUDATA
    iny
    bne :-
    inx
    cpx #>AsciiDataEnd
    bne @Continue
    rts

OkMsgStart:
    .byte .sprintf("%02X", HLT_INSTRUCTION)
    .byte " TEST OK"
OkMsgEnd:

FailMsg1Start:
    .byte .sprintf("%02X", HLT_INSTRUCTION)
    .byte " FAIL 1 - STOP ON HLT FAILED"
FailMsg1End:

FailMsg2Start:
    .byte .sprintf("%02X", HLT_INSTRUCTION)
    .byte " FAIL 2 - NMI RAN AFTER HLT "
FailMsg2End:

; palette data
PaletteDataStart:
.byte $0D,$30,$30,$30
.byte $0D,$3D,$00,$00
PaletteDataEnd:

; chr data
AsciiDataStart:
.incbin "charset.chr"
AsciiDataEnd:

.res $BFFA-*, $00
.word V_NMI
.word V_REBOOT
.word V_IRQ
