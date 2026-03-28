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

proc WindowProc uses ebx esi edi ebp, hWnd,wMsg,wParam,lParam
        mov           eax,[wMsg]
        cmp           eax, WM_CREATE
        je            .wmCreate
        cmp           eax, WM_SETFOCUS
        je            .wmSetFocus
        cmp           eax, WM_CHAR
        je            .wmChar
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

        invoke        CreateWindowEx,WS_EX_CLIENTEDGE,_edit,0,WS_VISIBLE+WS_CHILD+ES_AUTOVSCROLL+ES_MULTILINE+ES_READONLY,20,365,980,150,[hWnd],0,[wc.hInstance],NULL
        mov           [editKey],eax
        invoke        CreateWindowEx,0,_static,_Key,WS_VISIBLE+WS_CHILD,20,330,400,30,[hWnd],0,[wc.hInstance],NULL
        mov           [TextKey], eax

        invoke        CreateWindowEx,WS_EX_CLIENTEDGE,_edit,0,WS_VISIBLE+WS_CHILD+ES_AUTOVSCROLL+ES_MULTILINE+ES_READONLY,20,565,980,150,[hWnd],0,[wc.hInstance],NULL
        mov           [editResultText],eax
        invoke        CreateWindowEx,0,_static,_ResultText,WS_VISIBLE+WS_CHILD,20,530,400,30,[hWnd],0,[wc.hInstance],NULL
        mov           [TextResultText], eax

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

.wmChar:
        invoke        GetFocus
        mov           ebx, eax
        cmp           ebx, [editSid]
        je            @F
        cmp           ebx, [editOrigText]
        jne           .defwndproc

@@:
        mov           eax, [wParam]
        cmp           eax, '0'
        je            .Allow
        cmp           eax, '1'
        je            .Allow
        cmp           eax, 8
        je            .Allow


        invoke        MessageBox, [hWnd], _errorMsg, _errorCap, MB_OK+MB_ICONERROR
        xor           eax, eax
        jmp           .EndProc

.Allow:
        jmp           .defwndproc


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
        invoke        GetWindowTextLength, [editOrigText]
        test          eax, eax
        jz            .EndProc

        mov           [.len], eax
        inc           eax
        shl           eax, 1
        mov           [.memSize], eax

        invoke        GetProcessHeap
        mov           [.hHeap], eax

        invoke        HeapAlloc,[.hHeap], HEAP_ZERO_MEMORY, [.memSize]
        mov           [.pText], eax
        invoke        HeapAlloc,[.hHeap], HEAP_ZERO_MEMORY, [.memSize]
        mov           [.pResult], eax
        invoke        HeapAlloc,[.hHeap], HEAP_ZERO_MEMORY, [.memSize]
        mov           [.pKey], eax

        invoke        GetWindowText, [editSid], bufferSid, 37
        invoke        GetWindowText, [editOrigText], [.pText], [.len+1]
        mov           esi, [.pText]
        mov           edi, [.pResult]
        mov           edx, [.pKey]

.NextBit:
        mov           ax, [esi]
        test          ax, ax
        jz            .Final

        mov           bx, [bufferSid+35*2]
        mov           cx, [bufferSid+10*2]
        mov           [edx], bx

        push          ax bx
        sub           bx, '0'
        sub           cx, '0'
        xor           bx, cx
        add           bx, '0'
        mov           bp, bx
        pop           bx ax

        push          esi edi
        std
        lea           esi, [bufferSid+34*2]
        lea           edi, [bufferSid+35*2]
        mov           ecx, 35
        rep movsw
        cld
        pop           edi esi
        mov           [bufferSid], bp

        sub           ax, '0'
        sub           bx, '0'
        xor           ax, bx
        add           ax, '0'
        mov           [edi], ax
        add           esi, 2
        add           edi, 2
        add           edx, 2
        jmp           .NextBit

.Final:
        invoke        SetWindowText, [editResultText], [.pResult]
        invoke        SetWindowText, [editKey], [.pKey]

        invoke        HeapFree, [.hHeap], 0, [.pText]
        invoke        HeapFree, [.hHeap], 0, [.pResult]
        invoke        HeapFree, [.hHeap], 0, [.pKey]
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

.sLen     dd ?
.nBytes   dd ?
.len      dd ?
.memSize  dd ?
.hHeap    dd ?
.pText    dd ?
.pResult  dd ?
.pKey     dd ?
endp

proc ReadFileProc uses ebx esi
        invoke        CreateFile, szFileRead, GENERIC_READ , FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
        cmp           eax, -1
        je            .EndProc
        mov           ebx, eax
        invoke        GetProcessHeap
        mov           [.hHeap], eax
        invoke        HeapAlloc, [.hHeap], HEAP_ZERO_MEMORY, 512
        mov           [.pBinBuffer], eax
        invoke        HeapAlloc, [.hHeap], HEAP_ZERO_MEMORY, 8194
        mov           [.pCharBuffer], eax
        lea           eax, [.nBytes]
        invoke        ReadFile, ebx, [.pBinBuffer], 512, eax, NULL
        invoke        CloseHandle, ebx
        mov           esi, [.pBinBuffer]
        mov           edi, [.pCharBuffer]
        mov           ecx, [.nBytes]
        test          ecx, ecx
        jz            .Free

.LoopBytes:
        push          ecx
        mov           al, [esi]
        mov           ecx, 8

.LoopBits:
        rol           al, 1
        jc            .SetOne
        mov           word [edi], '0'
        jmp           .NextBit

.SetOne:
        mov           word[edi], '1'

.NextBit:
        add           edi, 2
        loop          .LoopBits
        inc           esi
        pop           ecx
        loop          .LoopBytes
        invoke        SetWindowText, [editOrigText], [.pCharBuffer]

.Free:
        invoke        HeapFree, [.hHeap], 0, [.pBinBuffer]
        invoke        HeapFree, [.hHeap], 0, [.pCharBuffer]
.EndProc:
        ret
.FileSize dd 0
.nBytes   dd ?
.hHeap    dd ?
.pBinBuffer dd ?
.pCharBuffer dd ?
endp

section '.data' data readable writeable

wc                           WNDCLASS 0,WindowProc,0,0,NULL,NULL,NULL,COLOR_BTNFACE+1,NULL,_class
bom                          dw      0FEFFh
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
_errorMsg                    du      'Можно вводить только 1 или 0!',0

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
