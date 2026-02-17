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
        or            eax, eax
        jz            .failed
        mov           [TextName], eax
        invoke        CreateWindowEx,WS_EX_CLIENTEDGE,_edit,0,WS_VISIBLE+WS_CHILD+ES_AUTOHSCROLL,100,50,350,35,[hWnd],0,[wc.hInstance],NULL
        or            eax,eax
        jz            .failed
        mov           [editKey],eax
        invoke        CreateWindowEx,0,_static,_key,WS_VISIBLE+WS_CHILD,20,50,80,25,[hWnd],0,[wc.hInstance],NULL
        or            eax, eax
        jz            .failed
        mov           [TextKey],eax

        invoke        CreateWindowEx,WS_EX_CLIENTEDGE,_edit,0,WS_VISIBLE+WS_CHILD+ES_AUTOVSCROLL+ES_MULTILINE,20,130,700,120,[hWnd],0,[wc.hInstance],NULL
        or            eax,eax
        jz            .failed
        mov           [editOrigText],eax
        invoke        CreateWindowEx,0,_static,_OrigText,WS_VISIBLE+WS_CHILD,20,100,400,25,[hWnd],0,[wc.hInstance],NULL
        or            eax, eax
        jz            .failed
        mov           [TextOrigText], eax
        invoke        CreateWindowEx,WS_EX_CLIENTEDGE,_edit,0,WS_VISIBLE+WS_CHILD+ES_AUTOVSCROLL+ES_MULTILINE+ES_READONLY,20,280,700,120,[hWnd],0,[wc.hInstance],NULL
        or            eax,eax
        jz            .failed
        mov           [editResultText],eax
        invoke        CreateWindowEx,0,_static,_ResultText,WS_VISIBLE+WS_CHILD,20,250,400,30,[hWnd],0,[wc.hInstance],NULL
        or            eax, eax
        jz            .failed
        mov           [TextResultText], eax
        invoke        CreateWindowEx,0,_button,_code,WS_VISIBLE+WS_CHILD+BS_DEFPUSHBUTTON,20,430,220,30,[hWnd],IDC_Code,[wc.hInstance],NULL
        or            eax, eax
        jz            .failed
        mov           [butnCode], eax
        invoke        CreateWindowEx,0,_button,_decode,WS_VISIBLE+WS_CHILD+BS_DEFPUSHBUTTON,260,430,220,30,[hWnd],IDC_Decode,[wc.hInstance],NULL
        or            eax, eax
        jz            .failed
        mov           [butnDecode], eax
        invoke        CreateWindowEx,0,_button,_remove,WS_VISIBLE+WS_CHILD+BS_DEFPUSHBUTTON,500,430,220,30,[hWnd],IDC_Remove,[wc.hInstance],NULL
        or            eax, eax
        jz            .failed
        mov           [butnRemove], eax
        invoke        CreateFont,30,15,0,0,0,FALSE,FALSE,FALSE,DEFAULT_CHARSET,OUT_RASTER_PRECIS,CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,FIXED_PITCH+FF_DONTCARE,NULL
        or            eax,eax
        jz            .failed
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

.failed:
        or             eax,-1
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
        jmp           .EndProc

.VigCipher:
        invoke        SendMessage,[TextName],WM_SETTEXT,0,_nameV
        jmp           .EndProc

.Open:
        invoke        GetOpenFileName, ofnRead
        mov           [FileRead], szFileRead
        invoke        SendMessage,[editOrigText],WM_SETTEXT,0,0
        stdcall       ReadText
        jmp           .EndProc
.Save:
        invoke        GetOpenFileName, ofnWrite
        mov           [FileWrite], szFileWrite
        invoke        GetWindowTextLength,[editResultText]
        mov           ebx, eax
        inc           ebx
        invoke        GetProcessHeap
        invoke        HeapAlloc, eax, HEAP_ZERO_MEMORY, ebx
        mov           edi, eax
        invoke        GetWindowText,[editResultText], edi, ebx
        invoke        CreateFile, [FileWrite], GENERIC_WRITE, FILE_SHARE_WRITE, NULL, CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL, NULL
        push          eax
        invoke        WriteFile, eax , bom, 2,.nBytes, NULL
        pop           eax
        shl           ebx, 1
        invoke        WriteFile, eax, edi,ebx , .nBytes, NULL
        jmp           .EndProc

.Code:
        invoke        SetWindowText, [editResultText], [Mas]
        jmp           .EndProc

.Decode:
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

.nBytes                       dd      ?
endp

proc ReadText
        stdcall       ReadFileProc, [FileRead]
        test          eax, eax
        jz            .EndProc

        invoke        SetWindowText, [editOrigText], [Mas]
.EndProc:
        ret

endp

proc ReadFileProc uses ebx, Name
        invoke        CreateFile,[Name], GENERIC_READ , FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL

        push          eax
        push          eax
        invoke        GetFileSize, eax, NULL
        mov           ebx, eax
        add           ebx, 16
        mov           [.FileSize], eax
        invoke        GetProcessHeap
        invoke        HeapAlloc, eax, HEAP_ZERO_MEMORY, ebx
        mov           [Mas], eax
        pop           eax
        invoke        ReadFile, eax, [Mas], [.FileSize],.nBytes, NULL
        pop           eax
        invoke        CloseHandle, eax

.EndProc:
        mov           eax, [.FileSize]
        mov           ebx, [Mas]
        mov           word[ebx + eax], 0
        ret

.FileSize                     dd      0
.nBytes                       dd      ?

endp

section '.data' data readable writeable

wc                           WNDCLASS 0,WindowProc,0,0,NULL,NULL,NULL,COLOR_BTNFACE+1,NULL,_class
bom                          dw      $FEFF
_class                       du      'CipherLab', 0
_title                       du      'CipherLab', 0
_edit                        du      'EDIT',0
_static                      du      'STATIC',0
_button                      du      'BUTTON',0
_key                         du      'Ключ',0
_nameC                       du      'Столбцовый метод',0
_nameV                       du      'Метод Вижнера',0
_OrigText                    du      'Исходный Текст',0
_ResultText                  du      'Результат',0
_code                        du      'Шифрировать',0
_decode                      du      'Дешифрировать',0
_remove                      du      'Очистить',0
szFileRead                   du      256  dup 0
szFileWrite                  du      256  dup 0
szFilterTxt                  du      'Txt files',0,'*.txt',0,0
ofnRead                      OPENFILENAME sizeof.OPENFILENAME, 0,0, szFilterTxt,0,0,0,szFileRead,260,0,0,0,0,OFN_ALLOWMULTISELECT+OFN_FILEMUSTEXIST+OFN_EXPLORER,0,0,0,0,0,0
ofnWrite                     OPENFILENAME sizeof.OPENFILENAME, 0,0, szFilterTxt,0,0,0,szFileWrite,260,0,0,0,0,OFN_ALLOWMULTISELECT+OFN_FILEMUSTEXIST+OFN_EXPLORER,0,0,0,0,0,0
msg                          MSG
client                       RECT
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
butnFile                     dd      ?
FileRead                     dd      ?
FileWrite                    dd      ?
Mas                          dd      ?

section '.idata' data import readable writeable

library kernel, 'kernel32.dll',\
        shell, 'shell32.dll',\
        user, 'user32.dll',\
        gdi, 'GDI32.DLL',\
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
                menuitem 'Метод Вижнера',IDM_VigCipher,MFR_END
       menuitem '&Файл',0, MFR_POPUP+MFR_END
                menuitem '&Открыть',IDM_Open
                menuitem '&Сохранить',IDM_Save,MFR_END

