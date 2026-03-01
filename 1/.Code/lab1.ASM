        include '\encoding\win1251.inc'
        include '\win32w.inc'

        format PE GUI 4.0
        entry WinMain

IDR_MENU        = 10
IDM_ColCipher   = 11
IDM_VigCipher   = 12
IDM_Open        = 13
IDM_Save        = 14
IDC_Code        = 15
IDC_Decode      = 16
IDC_Remove      = 17

section '.code' code readable writeable executable

proc WinMain
        invoke        GetModuleHandle,0
        mov           [wc.hInstance],eax
        invoke        LoadCursor,0,IDC_ARROW
        mov           [wc.hCursor],eax
        invoke        RegisterClass, wc

        invoke        LoadMenu,[wc.hInstance],IDR_MENU
        invoke        CreateWindowEx,0,_class,_title,WS_VISIBLE+WS_OVERLAPPEDWINDOW + (not WS_THICKFRAME),200,200,740,550,NULL,eax,[wc.hInstance],NULL

.msgLoop:
        invoke        GetMessage, msg, NULL,0,0
        cmp           eax,1
        jb            .EndProc
        jne           .msgLoop
        invoke        TranslateMessage,msg
        invoke        DispatchMessage,msg
        jmp           .msgLoop

.EndProc:
        invoke        ExitProcess, 0
endp

proc WindowProc uses ebx esi edi, hWnd,wMsg,wParam,lParam
        mov           eax,[wMsg]
        cmp           eax, WM_CREATE
        je            .wmCreate
        cmp           eax, WM_SETFOCUS
        je            .wmSetFocus
        cmp           eax, WM_COMMAND
        je            .wmCommand
        cmp           eax,WM_DESTROY
        je            .wmDestroy

.defwndproc:
        invoke        DefWindowProc, [hWnd], [wMsg], [wParam], [lParam]
        jmp           .EndProc

.wmCreate:
        invoke        CreateWindowEx,0,_static,_nameC,WS_VISIBLE+WS_CHILD,250,10,400,30,[hWnd],0,[wc.hInstance],NULL
        mov           [TextName], eax
        invoke        CreateWindowEx,WS_EX_CLIENTEDGE,_edit,0,WS_VISIBLE+WS_CHILD+ES_AUTOHSCROLL,100,50,350,35,[hWnd],0,[wc.hInstance],NULL
        mov           [editKey],eax
        invoke        CreateWindowEx,0,_static,_key,WS_VISIBLE+WS_CHILD,20,50,80,25,[hWnd],0,[wc.hInstance],NULL
        mov           [TextKey],eax

        invoke        CreateWindowEx,WS_EX_CLIENTEDGE,_edit,0,WS_VISIBLE+WS_CHILD+ES_AUTOVSCROLL+ES_MULTILINE,20,130,700,120,[hWnd],0,[wc.hInstance],NULL
        mov           [editOrigText],eax
        invoke        CreateWindowEx,0,_static,_OrigText,WS_VISIBLE+WS_CHILD,20,100,400,25,[hWnd],0,[wc.hInstance],NULL
        mov           [TextOrigText], eax
        invoke        CreateWindowEx,WS_EX_CLIENTEDGE,_edit,0,WS_VISIBLE+WS_CHILD+ES_AUTOVSCROLL+ES_MULTILINE+ES_READONLY,20,280,700,120,[hWnd],0,[wc.hInstance],NULL
        mov           [editResultText],eax
        invoke        CreateWindowEx,0,_static,_ResultText,WS_VISIBLE+WS_CHILD,20,250,400,30,[hWnd],0,[wc.hInstance],NULL
        mov           [TextResultText], eax
        invoke        CreateWindowEx,0,_button,_code,WS_VISIBLE+WS_CHILD+BS_DEFPUSHBUTTON,20,430,220,30,[hWnd],IDC_Code,[wc.hInstance],NULL
        mov           [butnCode], eax
        invoke        CreateWindowEx,0,_button,_decode,WS_VISIBLE+WS_CHILD+BS_DEFPUSHBUTTON,260,430,220,30,[hWnd],IDC_Decode,[wc.hInstance],NULL
        mov           [butnDecode], eax
        invoke        CreateWindowEx,0,_button,_remove,WS_VISIBLE+WS_CHILD+BS_DEFPUSHBUTTON,500,430,220,30,[hWnd],IDC_Remove,[wc.hInstance],NULL
        mov           [butnRemove], eax

        invoke        CreateFont,30,15,0,0,0,FALSE,FALSE,FALSE,RUSSIAN_CHARSET,OUT_RASTER_PRECIS,CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,FIXED_PITCH+FF_DONTCARE,NULL
        mov           [editFont],eax

        invoke        SendMessage,[editKey],WM_SETFONT,[editFont],FALSE
        invoke        SendMessage,[TextKey],WM_SETFONT,[editFont], FALSE
        invoke        SendMessage,[TextName],WM_SETFONT,[editFont],FALSE
        invoke        SendMessage,[editOrigText],WM_SETFONT,[editFont],FALSE
        invoke        SendMessage,[TextOrigText],WM_SETFONT,[editFont],FALSE
        invoke        SendMessage,[editResultText],WM_SETFONT,[editFont],FALSE
        invoke        SendMessage,[TextResultText],WM_SETFONT,[editFont],FALSE
        invoke        SendMessage,[butnCode],WM_SETFONT,[editFont],FALSE
        invoke        SendMessage,[butnDecode],WM_SETFONT,[editFont],FALSE
        invoke        SendMessage,[butnRemove],WM_SETFONT,[editFont],FALSE
        jmp           .EndProc

.wmSetFocus:
        invoke        SetFocus,[editKey]
        xor           eax,eax
        jmp           .EndProc

.wmCommand:
        mov           eax,[wParam]
        and           eax,0FFFFh
        cmp           eax,IDM_ColCipher
        je            .ColCipher
        cmp           eax,IDM_VigCipher
        je            .VigCipher
        cmp           eax,IDM_Open
        je            .Open
        cmp           eax,IDM_Save
        je            .Save
        cmp           eax, IDC_Code
        je            .Code
        cmp           eax, IDC_Decode
        je            .Decode
        cmp           eax, IDC_Remove
        je            .Remove
        jmp           .defwndproc

.ColCipher :
        invoke        SendMessage,[TextName],WM_SETTEXT,0,_nameC
        mov           byte[CipherMode], 0
        jmp           .EndProc

.VigCipher:
        invoke        SendMessage,[TextName],WM_SETTEXT,0,_nameV
        mov           byte[CipherMode], 1
        jmp           .EndProc

.Open:
        invoke        GetOpenFileName, ofnRead
        test          eax, eax
        jz            .EndProc
        invoke        SendMessage,[editOrigText],WM_SETTEXT,0,0
        stdcall       ReadFileProc
        jmp           .EndProc

.Save:
        invoke        GetOpenFileName, ofnWrite
        test          eax, eax
        jz            .EndProc
        invoke        GetWindowTextLength,[editResultText]
        mov           ebx, eax
        inc           ebx
        mov           [.sLen], ebx
        shl           ebx, 1
        invoke        GetProcessHeap
        invoke        HeapAlloc, eax, HEAP_ZERO_MEMORY, ebx
        mov           edi, eax
        invoke        GetWindowText,[editResultText], edi, [.sLen]
        invoke        CreateFile, szFileWrite, GENERIC_WRITE, FILE_SHARE_WRITE, NULL, CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL, NULL
        push          eax
        invoke        WriteFile, eax , bom, 2, .nBytes, NULL
        pop           eax
        mov           ebx, [.sLen]
        dec           ebx
        shl           ebx, 1
        push          eax
        invoke        WriteFile, eax, edi, ebx, .nBytes, NULL
        pop           eax
        invoke        CloseHandle, eax
        jmp           .EndProc

.Code:
        mov           dword[Mas], 0
        cmp           byte[CipherMode], 0
        jnz           .VigEnc
        stdcall       EncryptC
        jmp           .ShowRes
.VigEnc:
        stdcall       EncryptV
.ShowRes:
        cmp           dword[Mas], 0
        je            .EndProc
        invoke        SetWindowText, [editResultText], [Mas]
        jmp           .EndProc

.Decode:
        mov           dword[Mas], 0
        cmp           byte[CipherMode], 0
        jnz           .VigDec
        stdcall       DecryptC
        jmp           .ShowDec
.VigDec:
        stdcall       DecryptV
.ShowDec:
        cmp           dword[Mas], 0
        je            .EndProc
        invoke        SetWindowText, [editResultText], [Mas]
        jmp           .EndProc

.Remove:
        invoke        SendMessage,[editKey],WM_SETTEXT,0,0
        invoke        SendMessage,[editOrigText],WM_SETTEXT,0,0
        invoke        SendMessage,[editResultText],WM_SETTEXT,0,0
        jmp           .EndProc

.wmDestroy:
        invoke        DeleteObject,[editFont]
        invoke        PostQuitMessage,0
        xor           eax, eax

.EndProc:
        ret

.sLen   dd ?
.nBytes dd ?
endp

proc ReadFileProc uses ebx esi
        invoke        CreateFile, szFileRead, GENERIC_READ , FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
        cmp           eax, -1
        je            .EndProc
        push          eax
        push          eax
        invoke        GetFileSize, eax, NULL
        mov           ebx, eax
        add           ebx, 16
        mov           [.FileSize], eax
        invoke        GetProcessHeap
        invoke        HeapAlloc, eax, HEAP_ZERO_MEMORY, ebx
        mov           esi, eax
        pop           eax
        invoke        ReadFile, eax, esi, [.FileSize], .nBytes, NULL
        pop           eax
        invoke        CloseHandle, eax
        cmp           word[esi], 0FEFFh
        jne           .setText
        add           esi, 2
.setText:
        invoke        SetWindowText, [editOrigText], esi
.EndProc:
        ret
.FileSize dd 0
.nBytes   dd ?
endp

proc BuildOrder uses ecx esi edi, pKey, len, pOrder
        xor     ecx, ecx
.ol:
        cmp     ecx, [len]
        jge     .od
        xor     ebx, ebx
        xor     esi, esi
.il:
        cmp     esi, [len]
        jge     .st
        mov     edi, [pKey]
        movzx   eax, word[edi + esi*2]
        movzx   edx, word[edi + ecx*2]
        cmp     eax, edx
        jg      .nx
        je      .tie
        inc     ebx
        jmp     .nx
.tie:
        cmp     esi, ecx
        jge     .nx
        inc     ebx
.nx:
        inc     esi
        jmp     .il
.st:
        inc     ebx
        mov     edi, [pOrder]
        mov     [edi + ecx*4], ebx
        inc     ecx
        jmp     .ol
.od:
        ret
endp

proc EncryptC uses ebx esi edi
        ; Получаем исходный текст
        invoke  GetWindowTextLength, [editOrigText]
        test    eax, eax
        jz      .done
        mov     [tLen], eax
        inc     eax
        shl     eax, 1
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [tBuf], eax
        mov     eax, [tLen]
        inc     eax
        invoke  GetWindowText, [editOrigText], [tBuf], eax

        ; Фильтрация: оставляем только буквы и пробелы
        mov     eax, [tLen]
        inc     eax
        shl     eax, 1
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [fBuf], eax     ; Буфер только для букв (для шифрования)

        mov     eax, [tLen]
        inc     eax
        shl     eax, 1
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     edi, eax        ; Буфер для букв и пробелов (для сборки)
        
        xor     ecx, ecx        ; Индекс по исходному tBuf
        xor     ebx, ebx        ; Индекс по fBuf (только буквы)
        xor     edx, edx        ; Индекс по edi (буквы + пробелы)
.doFilt:
        cmp     ecx, [tLen]
        jge     .fdone
        mov     esi, [tBuf]
        movzx   eax, word[esi + ecx*2]

        cmp     eax, ' '
        je      .isSpace

        cmp     eax, 'a'
        jb      .chkUp
        cmp     eax, 'z'
        ja      .skipCh
        sub     eax, 20h
        jmp     .isLet

.chkUp:
        cmp     eax, 'A'
        jb      .skipCh
        cmp     eax, 'Z'
        ja      .skipCh

.isLet:
        mov     esi, [fBuf]
        mov     word[esi + ebx*2], ax
        inc     ebx
        mov     word[edi + edx*2], ax
        inc     edx
        jmp     .nextCh

.isSpace:
        mov     word[edi + edx*2], ax
        inc     edx
        jmp     .nextCh

.skipCh:
.nextCh:
        inc     ecx
        jmp     .doFilt

.fdone:
        mov     [fLen], ebx     ; Кол-во букв
        mov     [tLen], edx     ; Кол-во букв + пробелов
        mov     [tBuf], edi     ; Перезаписываем tBuf на очищенный текст

        ; Если нет ключа - возвращаем очищенный текст (буквы + пробелы)
        invoke  GetWindowTextLength, [editKey]
        test    eax, eax
        jz      .noKeyC
        
        ; Если есть ключ, но нет букв (одни пробелы) - возвращаем пробелы
        test    ebx, ebx
        jz      .noKeyC

        mov     [kLen], eax
        inc     eax
        shl     eax, 1
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [kBuf], eax
        mov     eax, [kLen]
        inc     eax
        invoke  GetWindowText, [editKey], [kBuf], eax

        ; Перевод ключа в верхний регистр
        xor     ecx, ecx
.kUpLoop:
        cmp     ecx, [kLen]
        jge     .kUpDone
        mov     esi, [kBuf]
        movzx   eax, word[esi + ecx*2]
        cmp     eax, 'a'
        jb      .kUpSkip
        cmp     eax, 'z'
        ja      .kUpSkip
        sub     eax, 20h
        mov     word[esi + ecx*2], ax
.kUpSkip:
        inc     ecx
        jmp     .kUpLoop
.kUpDone:

        ; Ранги
        mov     eax, [kLen]
        shl     eax, 2
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [oBuf], eax
        stdcall BuildOrder, [kBuf], [kLen], [oBuf]

        mov     eax, [kLen]
        inc     eax
        shl     eax, 2
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [r2pBuf], eax
        xor     ecx, ecx
.r2p:
        cmp     ecx, [kLen]
        jge     .r2pdone
        mov     esi, [oBuf]
        mov     eax, [esi + ecx*4]
        mov     esi, [r2pBuf]
        mov     [esi + eax*4], ecx
        inc     ecx
        jmp     .r2p
.r2pdone:

        ; Шифрование
        mov     eax, [fLen]
        inc     eax
        shl     eax, 1
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [rBuf], eax
        mov     dword[outIdx], 0

        mov     dword[colRank], 1
.cLoop:
        mov     eax, [colRank]
        cmp     eax, [kLen]
        jg      .cDone
        mov     esi, [r2pBuf]
        mov     ecx, [esi + eax*4]

        mov     dword[rowRank], 1
        mov     dword[startPos], 0
.rLoop:
        mov     eax, [startPos]
        cmp     eax, [fLen]
        jge     .nxCol
        mov     eax, [rowRank]
        mov     esi, [r2pBuf]
        mov     edx, [esi + eax*4]
        cmp     ecx, edx
        jg      .skpRow
        mov     eax, [startPos]
        add     eax, ecx
        cmp     eax, [fLen]
        jge     .skpRow
        push    ecx edx esi
        mov     esi, [fBuf]
        movzx   ebx, word[esi + eax*2]
        mov     esi, [rBuf]
        mov     eax, [outIdx]
        mov     word[esi + eax*2], bx
        inc     dword[outIdx]
        pop     esi edx ecx
.skpRow:
        add     [startPos], edx
        inc     dword[startPos]
        inc     dword[rowRank]
        mov     eax, [rowRank]
        cmp     eax, [kLen]
        jle     .rLoop
        mov     dword[rowRank], 1
        jmp     .rLoop
.nxCol:
        inc     dword[colRank]
        jmp     .cLoop
.cDone:

        ; Сборка с пробелами
        mov     eax, [tLen]
        inc     eax
        shl     eax, 1
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     edi, eax        
        
        xor     ecx, ecx
        xor     ebx, ebx
.rebuild:
        cmp     ecx, [tLen]
        jge     .rebuildDone
        mov     esi, [tBuf]
        movzx   eax, word[esi + ecx*2]
        
        cmp     eax, ' '
        je      .putSpace

        push    esi
        mov     esi, [rBuf]
        movzx   eax, word[esi + ebx*2]
        inc     ebx
        pop     esi

.putSpace:
        mov     word[edi + ecx*2], ax
        inc     ecx
        jmp     .rebuild

.rebuildDone:
        mov     word[edi + ecx*2], 0
        mov     [Mas], edi
        jmp     .done

.noKeyC:
        ; Возвращаем очищенный текст
        mov     esi, [tBuf]
        mov     ecx, [tLen]
        mov     word[esi + ecx*2], 0
        mov     [Mas], esi

.done:
        ret
endp

proc DecryptC uses ebx esi edi
        invoke  GetWindowTextLength, [editOrigText]
        test    eax, eax
        jz      .done
        mov     [tLen], eax
        inc     eax
        shl     eax, 1
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [tBuf], eax
        mov     eax, [tLen]
        inc     eax
        invoke  GetWindowText, [editOrigText], [tBuf], eax

        mov     eax, [tLen]
        inc     eax
        shl     eax, 1
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [fBuf], eax

        mov     eax, [tLen]
        inc     eax
        shl     eax, 1
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     edi, eax
        
        xor     ecx, ecx
        xor     ebx, ebx
        xor     edx, edx
.doFilt:
        cmp     ecx, [tLen]
        jge     .fdone
        mov     esi, [tBuf]
        movzx   eax, word[esi + ecx*2]

        cmp     eax, ' '
        je      .isSpace

        cmp     eax, 'a'
        jb      .chkUp
        cmp     eax, 'z'
        ja      .skipCh
        sub     eax, 20h
        jmp     .isLet

.chkUp:
        cmp     eax, 'A'
        jb      .skipCh
        cmp     eax, 'Z'
        ja      .skipCh

.isLet:
        mov     esi, [fBuf]
        mov     word[esi + ebx*2], ax
        inc     ebx
        mov     word[edi + edx*2], ax
        inc     edx
        jmp     .nextCh

.isSpace:
        mov     word[edi + edx*2], ax
        inc     edx
        jmp     .nextCh

.skipCh:
.nextCh:
        inc     ecx
        jmp     .doFilt

.fdone:
        mov     [fLen], ebx
        mov     [tLen], edx
        mov     [tBuf], edi

        invoke  GetWindowTextLength, [editKey]
        test    eax, eax
        jz      .noKeyC

        test    ebx, ebx
        jz      .noKeyC

        mov     [kLen], eax
        inc     eax
        shl     eax, 1
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [kBuf], eax
        mov     eax, [kLen]
        inc     eax
        invoke  GetWindowText, [editKey], [kBuf], eax

        xor     ecx, ecx
.kUpLoop:
        cmp     ecx, [kLen]
        jge     .kUpDone
        mov     esi, [kBuf]
        movzx   eax, word[esi + ecx*2]
        cmp     eax, 'a'
        jb      .kUpSkip
        cmp     eax, 'z'
        ja      .kUpSkip
        sub     eax, 20h
        mov     word[esi + ecx*2], ax
.kUpSkip:
        inc     ecx
        jmp     .kUpLoop
.kUpDone:

        mov     eax, [kLen]
        shl     eax, 2
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [oBuf], eax
        stdcall BuildOrder, [kBuf], [kLen], [oBuf]

        mov     eax, [kLen]
        inc     eax
        shl     eax, 2
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [r2pBuf], eax
        xor     ecx, ecx
.r2p:
        cmp     ecx, [kLen]
        jge     .r2pdone
        mov     esi, [oBuf]
        mov     eax, [esi + ecx*4]
        mov     esi, [r2pBuf]
        mov     [esi + eax*4], ecx
        inc     ecx
        jmp     .r2p
.r2pdone:

        mov     eax, [fLen]
        inc     eax
        shl     eax, 1
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [rBuf], eax
        mov     dword[outIdx], 0

        mov     dword[colRank], 1
.cLoop:
        mov     eax, [colRank]
        cmp     eax, [kLen]
        jg      .cDone
        mov     esi, [r2pBuf]
        mov     ecx, [esi + eax*4]

        mov     dword[rowRank], 1
        mov     dword[startPos], 0
.rLoop:
        mov     eax, [startPos]
        cmp     eax, [fLen]
        jge     .nxCol
        mov     eax, [rowRank]
        mov     esi, [r2pBuf]
        mov     edx, [esi + eax*4]
        cmp     ecx, edx
        jg      .skpRow
        
        mov     eax, [startPos]
        add     eax, ecx
        cmp     eax, [fLen]
        jge     .skpRow
        
        push    ecx edx esi eax
        mov     esi, [fBuf]
        mov     eax, [outIdx]
        movzx   ebx, word[esi + eax*2]
        inc     dword[outIdx]
        pop     eax
        mov     esi, [rBuf]
        mov     word[esi + eax*2], bx
        pop     esi edx ecx

.skpRow:
        add     [startPos], edx
        inc     dword[startPos]
        inc     dword[rowRank]
        mov     eax, [rowRank]
        cmp     eax, [kLen]
        jle     .rLoop
        mov     dword[rowRank], 1
        jmp     .rLoop
.nxCol:
        inc     dword[colRank]
        jmp     .cLoop
.cDone:

        mov     eax, [tLen]
        inc     eax
        shl     eax, 1
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     edi, eax
        
        xor     ecx, ecx
        xor     ebx, ebx
.rebuild:
        cmp     ecx, [tLen]
        jge     .rebuildDone
        mov     esi, [tBuf]
        movzx   eax, word[esi + ecx*2]
        
        cmp     eax, ' '
        je      .putSpace

        push    esi
        mov     esi, [rBuf]
        movzx   eax, word[esi + ebx*2]
        inc     ebx
        pop     esi

.putSpace:
        mov     word[edi + ecx*2], ax
        inc     ecx
        jmp     .rebuild

.rebuildDone:
        mov     word[edi + ecx*2], 0
        mov     [Mas], edi
        jmp     .done

.noKeyC:
        mov     esi, [tBuf]
        mov     ecx, [tLen]
        mov     word[esi + ecx*2], 0
        mov     [Mas], esi

.done:
        ret
endp

proc EncryptV uses ebx esi edi
        invoke  GetWindowTextLength, [editOrigText]
        test    eax, eax
        jz      .done
        mov     [tLen], eax
        inc     eax
        shl     eax, 1
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [tBuf], eax
        mov     eax, [tLen]
        inc     eax
        invoke  GetWindowText, [editOrigText], [tBuf], eax

        invoke  GetWindowTextLength, [editKey]
        test    eax, eax
        jz      .noKeyV

        mov     [kLen], eax
        inc     eax
        shl     eax, 1
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [kBuf], eax
        mov     eax, [kLen]
        inc     eax
        invoke  GetWindowText, [editKey], [kBuf], eax

        mov     eax, [kLen]
        inc     eax
        shl     eax, 2
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [vKeyIdxBuf], eax

        xor     edi, edi
        xor     ecx, ecx
.kScan:
        cmp     ecx, [kLen]
        jge     .kDone
        mov     esi, [kBuf]
        movzx   eax, word[esi + ecx*2]

        cmp     eax, 0451h
        jne     .knl
        mov     eax, 0401h
        jmp     .kup
.knl:
        cmp     eax, 0430h
        jb      .kup
        cmp     eax, 044Fh
        ja      .kup
        sub     eax, 20h
.kup:
        cmp     eax, 0401h
        je      .kIsYo
        cmp     eax, 0410h
        jb      .kNxt
        cmp     eax, 042Fh
        ja      .kNxt
        sub     eax, 0410h
        cmp     eax, 5
        jbe     .kStr
        inc     eax
        jmp     .kStr
.kIsYo:
        mov     eax, 6
.kStr:
        mov     esi, [vKeyIdxBuf]
        mov     [esi + edi*4], eax
        inc     edi
.kNxt:
        inc     ecx
        jmp     .kScan
.kDone:
        mov     [vKeyLetters], edi
        test    edi, edi
        jz      .noKeyV                   

        mov     eax, [tLen]
        inc     eax
        shl     eax, 1
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [rBuf], eax

        mov     eax, [tLen]
        inc     eax
        shl     eax, 2
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [vPlainIdxBuf], eax

        mov     dword[vLetterCount], 0
        xor     ecx, ecx
.encLoop:
        cmp     ecx, [tLen]
        jge     .encDone

        mov     esi, [tBuf]
        movzx   eax, word[esi + ecx*2]

        cmp     eax, 0451h
        jne     .tnl
        mov     eax, 0401h
        jmp     .tup
.tnl:
        cmp     eax, 0430h
        jb      .tup
        cmp     eax, 044Fh
        ja      .tup
        sub     eax, 20h
.tup:
        cmp     eax, 0401h
        je      .tIsYo
        cmp     eax, 0410h
        jb      .copyCh
        cmp     eax, 042Fh
        ja      .copyCh

        mov     ebx, eax
        sub     ebx, 0410h
        cmp     ebx, 5
        jbe     .midxOK
        inc     ebx
        jmp     .midxOK
.tIsYo:
        mov     ebx, 6
.midxOK:
        
        mov     eax, [vLetterCount]
        cmp     eax, [vKeyLetters]
        jb      .uKey
        push    edi
        mov     edi, eax
        sub     edi, [vKeyLetters]
        mov     esi, [vPlainIdxBuf]
        mov     edi, [esi + edi*4]
        mov     eax, edi
        pop     edi
        push    eax
        pop     eax
        jmp     .gotK
.uKey:
        mov     esi, [vKeyIdxBuf]
        mov     eax, [esi + eax*4]
.gotK:

        push    ebx
        add     eax, ebx
        mov     ebx, 33
        xor     edx, edx
        div     ebx
        mov     eax, edx        
        pop     ebx

        push    eax
        mov     eax, [vLetterCount]
        mov     esi, [vPlainIdxBuf]
        mov     [esi + eax*4], ebx
        inc     dword[vLetterCount]
        pop     eax

        cmp     eax, 6
        jne     .notYoO
        mov     eax, 0401h
        jmp     .putCh
.notYoO:
        cmp     eax, 5
        jbe     .outLow
        dec     eax
.outLow:
        add     eax, 0410h
.putCh:
        mov     esi, [rBuf]
        mov     word[esi + ecx*2], ax
        inc     ecx
        jmp     .encLoop

.copyCh:
        mov     esi, [tBuf]
        movzx   eax, word[esi + ecx*2]
        mov     esi, [rBuf]
        mov     word[esi + ecx*2], ax
        inc     ecx
        jmp     .encLoop

.encDone:
        mov     esi, [rBuf]
        mov     ecx, [tLen]
        mov     word[esi + ecx*2], 0
        mov     [Mas], esi
        jmp     .done

.noKeyV:
        mov     eax, [tLen]
        inc     eax
        shl     eax, 1
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [rBuf], eax
        
        xor     ecx, ecx
.nkLoop:
        cmp     ecx, [tLen]
        jge     .nkDone
        mov     esi, [tBuf]
        movzx   eax, word[esi + ecx*2]
        
        cmp     eax, 0451h
        jne     .nknl
        mov     eax, 0401h
        jmp     .nkSave
.nknl:
        cmp     eax, 0430h
        jb      .nkSave
        cmp     eax, 044Fh
        ja      .nkSave
        sub     eax, 20h
.nkSave:
        mov     esi, [rBuf]
        mov     word[esi + ecx*2], ax
        inc     ecx
        jmp     .nkLoop
.nkDone:
        mov     esi, [rBuf]
        mov     ecx, [tLen]
        mov     word[esi + ecx*2], 0
        mov     [Mas], esi

.done:
        ret
endp

proc DecryptV uses ebx esi edi
        invoke  GetWindowTextLength, [editOrigText]
        test    eax, eax
        jz      .done
        mov     [tLen], eax
        inc     eax
        shl     eax, 1
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [tBuf], eax
        mov     eax, [tLen]
        inc     eax
        invoke  GetWindowText, [editOrigText], [tBuf], eax

        invoke  GetWindowTextLength, [editKey]
        test    eax, eax
        jz      .noKeyV

        mov     [kLen], eax
        inc     eax
        shl     eax, 1
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [kBuf], eax
        mov     eax, [kLen]
        inc     eax
        invoke  GetWindowText, [editKey], [kBuf], eax

        mov     eax, [kLen]
        inc     eax
        shl     eax, 2
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [vKeyIdxBuf], eax

        xor     edi, edi
        xor     ecx, ecx
.kScan:
        cmp     ecx, [kLen]
        jge     .kDone
        mov     esi, [kBuf]
        movzx   eax, word[esi + ecx*2]
        cmp     eax, 0451h
        jne     .knl
        mov     eax, 0401h
        jmp     .kup
.knl:
        cmp     eax, 0430h
        jb      .kup
        cmp     eax, 044Fh
        ja      .kup
        sub     eax, 20h
.kup:
        cmp     eax, 0401h
        je      .kIsYo
        cmp     eax, 0410h
        jb      .kNxt
        cmp     eax, 042Fh
        ja      .kNxt
        sub     eax, 0410h
        cmp     eax, 5
        jbe     .kStr
        inc     eax
        jmp     .kStr
.kIsYo:
        mov     eax, 6
.kStr:
        mov     esi, [vKeyIdxBuf]
        mov     [esi + edi*4], eax
        inc     edi
.kNxt:
        inc     ecx
        jmp     .kScan
.kDone:
        mov     [vKeyLetters], edi
        test    edi, edi
        jz      .noKeyV

        mov     eax, [tLen]
        inc     eax
        shl     eax, 1
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [rBuf], eax

        mov     eax, [tLen]
        inc     eax
        shl     eax, 2
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [vPlainIdxBuf], eax

        mov     dword[vLetterCount], 0
        xor     ecx, ecx
.decLoop:
        cmp     ecx, [tLen]
        jge     .decDone

        mov     esi, [tBuf]
        movzx   eax, word[esi + ecx*2]

        cmp     eax, 0451h
        jne     .tnl
        mov     eax, 0401h
        jmp     .tup
.tnl:
        cmp     eax, 0430h
        jb      .tup
        cmp     eax, 044Fh
        ja      .tup
        sub     eax, 20h
.tup:
        cmp     eax, 0401h
        je      .tIsYo
        cmp     eax, 0410h
        jb      .copyCh
        cmp     eax, 042Fh
        ja      .copyCh

        mov     ebx, eax
        sub     ebx, 0410h
        cmp     ebx, 5
        jbe     .cidxOK
        inc     ebx
        jmp     .cidxOK
.tIsYo:
        mov     ebx, 6
.cidxOK:

        mov     eax, [vLetterCount]
        cmp     eax, [vKeyLetters]
        jb      .uKey
        push    edi
        mov     edi, eax
        sub     edi, [vKeyLetters]
        mov     esi, [vPlainIdxBuf]
        mov     edi, [esi + edi*4]
        mov     eax, edi
        pop     edi
        jmp     .gotK
.uKey:
        mov     esi, [vKeyIdxBuf]
        mov     eax, [esi + eax*4]
.gotK:

        push    eax
        mov     eax, ebx
        pop     ebx
        sub     eax, ebx
        add     eax, 33
        mov     ebx, 33
        xor     edx, edx
        div     ebx
        mov     eax, edx        

        push    eax
        mov     eax, [vLetterCount]
        mov     esi, [vPlainIdxBuf]
        mov     ebx, edx
        mov     [esi + eax*4], ebx
        inc     dword[vLetterCount]
        pop     eax

        cmp     eax, 6
        jne     .notYoO
        mov     eax, 0401h
        jmp     .putCh
.notYoO:
        cmp     eax, 5
        jbe     .outLow
        dec     eax
.outLow:
        add     eax, 0410h
.putCh:
        mov     esi, [rBuf]
        mov     word[esi + ecx*2], ax
        inc     ecx
        jmp     .decLoop

.copyCh:
        mov     esi, [tBuf]
        movzx   eax, word[esi + ecx*2]
        mov     esi, [rBuf]
        mov     word[esi + ecx*2], ax
        inc     ecx
        jmp     .decLoop

.decDone:
        mov     esi, [rBuf]
        mov     ecx, [tLen]
        mov     word[esi + ecx*2], 0
        mov     [Mas], esi
        jmp     .done

.noKeyV:
        mov     eax, [tLen]
        inc     eax
        shl     eax, 1
        invoke  GetProcessHeap
        invoke  HeapAlloc, eax, HEAP_ZERO_MEMORY, eax
        mov     [rBuf], eax
        
        xor     ecx, ecx
.nkLoop:
        cmp     ecx, [tLen]
        jge     .nkDone
        mov     esi, [tBuf]
        movzx   eax, word[esi + ecx*2]
        cmp     eax, 0451h
        jne     .nknl
        mov     eax, 0401h
        jmp     .nkSave
.nknl:
        cmp     eax, 0430h
        jb      .nkSave
        cmp     eax, 044Fh
        ja      .nkSave
        sub     eax, 20h
.nkSave:
        mov     esi, [rBuf]
        mov     word[esi + ecx*2], ax
        inc     ecx
        jmp     .nkLoop
.nkDone:
        mov     esi, [rBuf]
        mov     ecx, [tLen]
        mov     word[esi + ecx*2], 0
        mov     [Mas], esi

.done:
        ret
endp

section '.data' data readable writeable

wc                           WNDCLASS 0,WindowProc,0,0,NULL,NULL,NULL,COLOR_BTNFACE+1,NULL,_class
bom                          dw      0FEFFh
_class                       du      'CipherLab', 0
_title                       du      'CipherLab — Шифратор', 0
_edit                        du      'EDIT',0
_static                      du      'STATIC',0
_button                      du      'BUTTON',0
_key                         du      'Ключ',0
_nameC                       du      'Столбцовый метод (англ)',0
_nameV                       du      'Метод Виженера (рус)',0
_OrigText                    du      'Исходный Текст',0
_ResultText                  du      'Результат',0
_code                        du      'Зашифровать',0
_decode                      du      'Дешифровать',0
_remove                      du      'Очистить',0
szFileRead                   du      256  dup 0
szFileWrite                  du      256  dup 0
szFilterTxt                  du      'Txt files',0,'*.txt',0,0

ofnRead OPENFILENAME sizeof.OPENFILENAME, 0,0, szFilterTxt,0,0,0,szFileRead,260,0,0,0,0,OFN_ALLOWMULTISELECT+OFN_FILEMUSTEXIST+OFN_EXPLORER,0,0,0,0,0,0
ofnWrite OPENFILENAME sizeof.OPENFILENAME, 0,0, szFilterTxt,0,0,0,szFileWrite,260,0,0,0,0,OFN_ALLOWMULTISELECT+OFN_EXPLORER,0,0,0,0,0,0

msg                          MSG
editKey                      dd      ?
editOrigText                 dd      ?
editResultText               dd      ?
editFont                     dd      ?
TextKey                      dd      ?
TextName                     dd      ?
TextOrigText                 dd      ?
TextResultText               dd      ?
butnCode                     dd      ?
butnDecode                   dd      ?
butnRemove                   dd      ?
Mas                          dd      0
CipherMode                   db      0

kLen     dd 0
kBuf     dd 0
tLen     dd 0
tBuf     dd 0
fLen     dd 0
fBuf     dd 0
oBuf     dd 0
r2pBuf   dd 0
rBuf     dd 0

outIdx   dd 0
colRank  dd 0
rowRank  dd 0
startPos dd 0

vKeyIdxBuf    dd 0
vKeyLetters   dd 0
vPlainIdxBuf  dd 0
vLetterCount  dd 0

section '.idata' data import readable writeable

library kernel, 'kernel32.dll',\
        user, 'user32.dll',\
        gdi, 'gdi32.dll',\
        comdlg, 'comdlg32.dll'

import kernel,\
            GetModuleHandle,'GetModuleHandleW',\
            GetProcessHeap, 'GetProcessHeap',\
            HeapAlloc,  'HeapAlloc',\
            HeapFree, 'HeapFree',\
            ReadFile, 'ReadFile',\
            CreateFile, 'CreateFileW',\
            GetFileSize, 'GetFileSize',\
            CloseHandle, 'CloseHandle',\
            WriteFile, 'WriteFile',\
            ExitProcess, 'ExitProcess'

import user,\
            RegisterClass,'RegisterClassW',\
            CreateWindowEx,'CreateWindowExW',\
            DefWindowProc,'DefWindowProcW',\
            LoadCursor,'LoadCursorW',\
            LoadMenu,'LoadMenuW',\
            GetMessage,'GetMessageW',\
            DispatchMessage,'DispatchMessageW',\
            SendMessage,'SendMessageW',\
            SetFocus,'SetFocus',\
            TranslateMessage,'TranslateMessage',\
            GetWindowTextLength , 'GetWindowTextLengthW',\
            GetWindowText, 'GetWindowTextW',\
            SetWindowText, 'SetWindowTextW', \
            PostQuitMessage,'PostQuitMessage'

import gdi,\
            CreateFont,'CreateFontW',\
            DeleteObject,'DeleteObject'

import comdlg,\
            GetOpenFileName, 'GetOpenFileNameW'

section '.rsrc' resource data readable
directory RT_MENU,menus

resource menus,\
           IDR_MENU,LANG_ENGLISH+SUBLANG_DEFAULT,main_menu

menu main_menu
       menuitem '&Метод шифрования',0,MFR_POPUP
                menuitem '&Столбцовый метод',IDM_ColCipher
                menuitem 'Метод &Виженера',IDM_VigCipher,MFR_END
       menuitem '&Файл',0, MFR_POPUP+MFR_END
                menuitem '&Открыть',IDM_Open
                menuitem '&Сохранить',IDM_Save,MFR_END
