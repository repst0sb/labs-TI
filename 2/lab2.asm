        include '\encoding\win1251.inc'
        include '\win32w.inc'

        format PE GUI 4.0
        entry WinMain

IDR_MENU        = 10
IDM_Open        = 13
IDM_Save        = 14
IDC_Code        = 15
IDC_Decode      = 16
IDC_Remove      = 17

GWL_WNDPROC     = -4
EM_SETLIMITTEXT = 00C5h

section '.code' code readable writeable executable

proc WinMain
        invoke        GetModuleHandle,0
        mov           [wc.hInstance],eax
        invoke        LoadCursor,0,IDC_ARROW
        mov           [wc.hCursor],eax
        invoke        RegisterClass, wc

        invoke        LoadMenu,[wc.hInstance],IDR_MENU
        invoke        CreateWindowEx,0,_class,_title,WS_VISIBLE+WS_OVERLAPPEDWINDOW + (not WS_THICKFRAME),100,100,1040,850,NULL,eax,[wc.hInstance],NULL

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

proc EditSubclassProc uses ebx esi edi, hWnd, uMsg, wParam, lParam
        mov           eax, [uMsg]
        cmp           eax, WM_CHAR
        jne           .call_old
        mov           eax, [wParam]
        cmp           eax, '0'
        je            .call_old
        cmp           eax, '1'
        je            .call_old
        cmp           eax, 8
        je            .call_old
        xor           eax, eax
        ret
.call_old:
        invoke        CallWindowProc, [oldWndProc], [hWnd], [uMsg], [wParam], [lParam]
        ret
endp

proc WindowProc uses ebx esi edi ebp, hWnd,wMsg,wParam,lParam
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
        invoke        CreateWindowEx,0,_static,_name,WS_VISIBLE+WS_CHILD,340,10,360,300,[hWnd],0,[wc.hInstance],NULL
        mov           [TextName], eax
        invoke        CreateWindowEx,WS_EX_CLIENTEDGE,_edit,0,WS_VISIBLE+WS_CHILD+ES_AUTOHSCROLL,20,85,980,35,[hWnd],0,[wc.hInstance],NULL
        mov           [editSid],eax
        invoke        CreateWindowEx,0,_static,_sid,WS_VISIBLE+WS_CHILD,20,50,950,30,[hWnd],0,[wc.hInstance],NULL
        mov           [TextSid],eax

        invoke        CreateWindowEx,WS_EX_CLIENTEDGE,_edit,0,WS_VISIBLE+WS_CHILD+ES_AUTOVSCROLL+ES_MULTILINE,20,165,980,150,[hWnd],0,[wc.hInstance],NULL
        mov           [editOrigText],eax
        invoke        CreateWindowEx,0,_static,_OrigText,WS_VISIBLE+WS_CHILD,20,135,400,25,[hWnd],0,[wc.hInstance],NULL
        mov           [TextOrigText], eax

        ; Снимаем ограничение длины
        invoke        SendMessage, [editOrigText], EM_SETLIMITTEXT, 0, 0

        invoke        SetWindowLong, [editSid], GWL_WNDPROC, EditSubclassProc
        mov           [oldWndProc], eax
        invoke        SetWindowLong, [editOrigText], GWL_WNDPROC, EditSubclassProc

        invoke        CreateWindowEx,WS_EX_CLIENTEDGE,_edit,0,WS_VISIBLE+WS_CHILD+ES_AUTOVSCROLL+ES_MULTILINE+ES_READONLY,20,365,980,150,[hWnd],0,[wc.hInstance],NULL
        mov           [editKey],eax
        invoke        CreateWindowEx,0,_static,_Key,WS_VISIBLE+WS_CHILD,20,330,400,30,[hWnd],0,[wc.hInstance],NULL
        mov           [TextKey], eax
        invoke        SendMessage, [editKey], EM_SETLIMITTEXT, 0, 0

        invoke        CreateWindowEx,WS_EX_CLIENTEDGE,_edit,0,WS_VISIBLE+WS_CHILD+ES_AUTOVSCROLL+ES_MULTILINE+ES_READONLY,20,565,980,150,[hWnd],0,[wc.hInstance],NULL
        mov           [editResultText],eax
        invoke        CreateWindowEx,0,_static,_ResultText,WS_VISIBLE+WS_CHILD,20,530,400,30,[hWnd],0,[wc.hInstance],NULL
        mov           [TextResultText], eax
        invoke        SendMessage, [editResultText], EM_SETLIMITTEXT, 0, 0

        invoke        CreateWindowEx,0,_button,_code,WS_VISIBLE+WS_CHILD+BS_DEFPUSHBUTTON,20,740,310,40,[hWnd],IDC_Code,[wc.hInstance],NULL
        mov           [butnCode], eax
        invoke        CreateWindowEx,0,_button,_decode,WS_VISIBLE+WS_CHILD+BS_DEFPUSHBUTTON,355,740,310,40,[hWnd],IDC_Decode,[wc.hInstance],NULL
        mov           [butnDecode], eax
        invoke        CreateWindowEx,0,_button,_remove,WS_VISIBLE+WS_CHILD+BS_DEFPUSHBUTTON,690,740,310,40,[hWnd],IDC_Remove,[wc.hInstance],NULL
        mov           [butnRemove], eax

        invoke        CreateFont,30,15,0,0,0,FALSE,FALSE,FALSE,RUSSIAN_CHARSET,OUT_RASTER_PRECIS,CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,FIXED_PITCH+FF_DONTCARE,NULL
        mov           [editFont],eax

        invoke        SendMessage,[editSid],WM_SETFONT,[editFont],FALSE
        invoke        SendMessage,[editSid],EM_SETLIMITTEXT,36, FALSE
        invoke        SendMessage,[TextSid],WM_SETFONT,[editFont], FALSE
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
        cmp           eax,IDM_Open
        je            .Open
        cmp           eax,IDM_Save
        je            .Save
        cmp           eax, IDC_Code
        je            .Code
        cmp           eax, IDC_Decode
        je            .Code
        cmp           eax, IDC_Remove
        je            .Remove

        jmp           .defwndproc

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
        
        invoke        GetWindowTextLength, [editResultText]
        test          eax, eax
        jz            .EndProc
        mov           [sLen], eax
        
        inc           eax
        mov           [bufChars], eax
        shl           eax, 1
        invoke        GetProcessHeap
        mov           [hHeap], eax
        invoke        HeapAlloc, [hHeap], HEAP_ZERO_MEMORY, eax
        mov           [pCharBuffer], eax

        invoke        GetWindowText, [editResultText], [pCharBuffer], [bufChars]
        
        mov           eax, [sLen]
        shr           eax, 3
        test          eax, eax
        jz            .FreeSaveMem
        mov           [nBytes], eax
        
        invoke        HeapAlloc, [hHeap], HEAP_ZERO_MEMORY, [nBytes]
        mov           [pBinBuffer], eax
        
        mov           esi, [pCharBuffer]
        mov           edi, [pBinBuffer]
        mov           ecx, [nBytes]
    .packLoop:
        push          ecx
        xor           al, al
        mov           ecx, 8
    .packBits:
        shl           al, 1
        mov           dx, [esi]
        cmp           dx, '1'
        jne           @F
        or            al, 1
    @@:
        add           esi, 2
        loop          .packBits
        mov           [edi], al
        inc           edi
        pop           ecx
        loop          .packLoop
        
        invoke        CreateFile, szFileWrite, GENERIC_WRITE, FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
        mov           ebx, eax
        invoke        WriteFile, ebx, [pBinBuffer], [nBytes], nBytesWritten, NULL
        invoke        CloseHandle, ebx
        
        invoke        HeapFree, [hHeap], 0, [pBinBuffer]
    .FreeSaveMem:
        invoke        HeapFree, [hHeap], 0, [pCharBuffer]
        jmp           .EndProc

.Code:
        invoke        GetWindowTextLength, [editSid]
        cmp           eax, 36
        jne           .BadInput
        
        invoke        GetWindowTextLength, [editOrigText]
        test          eax, eax
        jz            .EndProc
        mov           [len], eax

        inc           eax
        mov           [bufChars], eax
        shl           eax, 1
        mov           [memSize], eax

        invoke        GetProcessHeap
        mov           [hHeap], eax

        invoke        HeapAlloc,[hHeap], HEAP_ZERO_MEMORY, [memSize]
        mov           [pText], eax
        invoke        HeapAlloc,[hHeap], HEAP_ZERO_MEMORY, [memSize]
        mov           [pResult], eax
        invoke        HeapAlloc,[hHeap], HEAP_ZERO_MEMORY, [memSize]
        mov           [pKey], eax

        invoke        GetWindowText, [editSid], bufferSid, 37
        invoke        GetWindowText, [editOrigText], [pText], [bufChars]

        mov           ecx, 36
        mov           esi, bufferSid
    .CheckSid:
        mov           ax, [esi]
        cmp           ax, '0'
        jb            .BadData
        cmp           ax, '1'
        ja            .BadData
        add           esi, 2
        loop          .CheckSid

        mov           esi, [pText]
    .CheckTextLoop:
        mov           ax, [esi]
        test          ax, ax
        jz            .ValidText
        cmp           ax, '0'
        je            .TextNext
        cmp           ax, '1'
        je            .TextNext
        jmp           .BadData
    .TextNext:
        add           esi, 2
        jmp           .CheckTextLoop

    .ValidText:
        mov           esi, [pText]
        mov           edi, [pResult]
        mov           edx, [pKey]

.NextBit:
        mov           ax, [esi]
        test          ax, ax
        jz            .Final

        ; --- АЛГОРИТМ LFSR: СДВИГ ВЛЕВО ---
        ; 1. Берем самый левый бит (нулевой индекс) как бит ключа
        mov           bx, [bufferSid]         
        ; 2. Берем бит для полинома (индекс 25 для сохранения математики 36-го порядка)
        mov           cx, [bufferSid+25*2]    
        mov           [edx], bx               ; Записываем бит в поле Ключ

        ; 3. Считаем обратную связь (XOR)
        push          ax bx
        sub           bx, '0'
        sub           cx, '0'
        xor           bx, cx
        add           bx, '0'
        mov           bp, bx                  ; bp = новый бит
        pop           bx ax

        ; 4. Сдвигаем регистр ВЛЕВО
        push          esi edi
        cld                                   ; Копируем слева направо (прямое направление)
        lea           edi, [bufferSid]        ; КУДА: начиная с 0-го индекса
        lea           esi, [bufferSid+2]      ; ОТКУДА: начиная с 1-го индекса
        mov           ecx, 35
        rep movsw                             ; Сдвигаем 35 элементов
        pop           edi esi
        
        ; 5. Записываем новый бит справа (в самый конец массива)
        mov           [bufferSid+35*2], bp

        ; 6. Шифруем символ: Исходный текст XOR Ключ
        sub           ax, '0'
        sub           bx, '0'
        xor           ax, bx
        add           ax, '0'
        mov           [edi], ax
        
        add           esi, 2
        add           edi, 2
        add           edx, 2
        jmp           .NextBit

.BadData:
        invoke        HeapFree, [hHeap], 0, [pText]
        invoke        HeapFree, [hHeap], 0, [pResult]
        invoke        HeapFree, [hHeap], 0, [pKey]
.BadInput:
        invoke        MessageBox, [hWnd], _errorMsg, _errorCap, MB_OK+MB_ICONERROR
        jmp           .EndProc

.Final:
        invoke        SetWindowText, [editResultText], [pResult]
        invoke        SetWindowText, [editKey], [pKey]

        invoke        HeapFree, [hHeap], 0, [pText]
        invoke        HeapFree, [hHeap], 0, [pResult]
        invoke        HeapFree, [hHeap], 0, [pKey]
        jmp           .EndProc

.Remove:
        invoke        SendMessage,[editKey],WM_SETTEXT,0,0
        invoke        SendMessage,[editOrigText],WM_SETTEXT,0,0
        invoke        SendMessage,[editSid],WM_SETTEXT,0,0
        invoke        SendMessage,[editResultText],WM_SETTEXT,0,0
        jmp           .EndProc

.wmDestroy:
        invoke        DeleteObject,[editFont]
        invoke        PostQuitMessage,0
        xor           eax, eax

.EndProc:
        ret
endp

proc ReadFileProc uses ebx esi edi
        invoke        CreateFile, szFileRead, GENERIC_READ , FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
        cmp           eax, -1
        je            .EndProc
        mov           ebx, eax
        
        invoke        GetFileSize, ebx, NULL
        mov           [FileSize], eax
        
        invoke        GetProcessHeap
        mov           [hHeap], eax
        invoke        HeapAlloc, [hHeap], HEAP_ZERO_MEMORY, [FileSize]
        mov           [pBinBuffer], eax
        
        mov           eax, [FileSize]
        shl           eax, 4
        add           eax, 2
        invoke        HeapAlloc, [hHeap], HEAP_ZERO_MEMORY, eax
        mov           [pCharBuffer], eax
        
        invoke        ReadFile, ebx, [pBinBuffer], [FileSize], nBytesRead, NULL
        invoke        CloseHandle, ebx
        
        mov           esi, [pBinBuffer]
        mov           edi, [pCharBuffer]
        mov           ecx, [FileSize]
        test          ecx, ecx
        jz            .Free

.LoopBytes:
        push          ecx
        mov           al, [esi]
        mov           ecx, 8

.LoopBits:
        rol           al, 1
        mov           word [edi], '0'
        jnc           .NextBit
        mov           word [edi], '1'
.NextBit:
        add           edi, 2
        loop          .LoopBits
        inc           esi
        pop           ecx
        loop          .LoopBytes
        
        invoke        SetWindowText, [editOrigText], [pCharBuffer]

.Free:
        invoke        HeapFree, [hHeap], 0, [pBinBuffer]
        invoke        HeapFree, [hHeap], 0, [pCharBuffer]
.EndProc:
        ret
endp

section '.data' data readable writeable

wc                           WNDCLASS 0,WindowProc,0,0,NULL,NULL,NULL,COLOR_BTNFACE+1,NULL,_class
_class                       du      'Cipher', 0
_title                       du      'Cipher — Шифратор', 0
_edit                        du      'EDIT',0
_static                      du      'STATIC',0
_button                      du      'BUTTON',0
_sid                         du      'Начальное состояние регистра',0
_name                        du      'Потоковый шифратор',0
_Key                         du      'Ключ',0
_OrigText                    du      'Исходный Текст',0
_ResultText                  du      'Результат',0
_code                        du      'Зашифровать',0
_decode                      du      'Дешифровать',0
_remove                      du      'Очистить',0
szFileRead                   du      256  dup 0
szFileWrite                  du      256  dup 0
szFilterAll                  du      'All files',0,'*.*',0,0
_errorCap                    du      'Ошибка ввода',0
_errorMsg                    du      'Можно вводить только 1 или 0! (Убедитесь, что нет пробелов, а Сид ровно 36 символов)',0

ofnRead OPENFILENAME sizeof.OPENFILENAME, 0,0, szFilterAll,0,0,0,szFileRead,260,0,0,0,0,OFN_ALLOWMULTISELECT+OFN_FILEMUSTEXIST+OFN_EXPLORER,0,0,0,0,0,0
ofnWrite OPENFILENAME sizeof.OPENFILENAME, 0,0, szFilterAll,0,0,0,szFileWrite,260,0,0,0,0,OFN_ALLOWMULTISELECT+OFN_EXPLORER,0,0,0,0,0,0

msg                          MSG
bufferSid                    du      40 dup 0
editKey                      dd      ?
editSid                      dd      ?
editOrigText                 dd      ?
editResultText               dd      ?
editFont                     dd      ?
TextKey                      dd      ?
TextSid                      dd      ?
TextName                     dd      ?
TextOrigText                 dd      ?
TextResultText               dd      ?
butnCode                     dd      ?
butnDecode                   dd      ?
butnRemove                   dd      ?

sLen                         dd ?
bufChars                     dd ?
nBytes                       dd ?
nBytesWritten                dd ?
nBytesRead                   dd ?
len                          dd ?
memSize                      dd ?
hHeap                        dd ?
pText                        dd ?
pResult                      dd ?
pKey                         dd ?
FileSize                     dd ?
pBinBuffer                   dd ?
pCharBuffer                  dd ?
oldWndProc                   dd ?

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
            CallWindowProc, 'CallWindowProcW',\
            SetWindowLong, 'SetWindowLongW',\
            LoadCursor,'LoadCursorW',\
            LoadMenu,'LoadMenuW',\
            GetMessage,'GetMessageW',\
            DispatchMessage,'DispatchMessageW',\
            SendMessage,'SendMessageW',\
            SetFocus,'SetFocus',\
            GetFocus, 'GetFocus',\
            TranslateMessage,'TranslateMessage',\
            MessageBox, 'MessageBoxW',\
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
       menuitem '&Файл',0, MFR_POPUP+MFR_END
                menuitem '&Открыть',IDM_Open
                menuitem '&Сохранить',IDM_Save,MFR_END