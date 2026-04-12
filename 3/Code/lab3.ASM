include 'win32a.inc'

format PE GUI 4.0
entry WinMain

ID_EDIT_P    = 101
ID_COMBO_G   = 102
ID_EDIT_X    = 103
ID_EDIT_K    = 104
ID_BTN_FINDG = 105
ID_BTN_FILE  = 106
ID_BTN_ENC   = 107
ID_BTN_DEC   = 108
ID_EDIT_LOG  = 109

CBS_DROPDOWNLIST = 3
CB_ADDSTRING     = 0x0143
CB_RESETCONTENT  = 0x014B
CB_SETCURSEL     = 0x014E
WM_GETTEXT       = 0x000D

section '.data' data readable writeable
        _class      db 'ElGamalClass',0
        _title      db 'ElGamal Cipher (Вариант 2)',0
        _edit       db 'EDIT',0
        _button     db 'BUTTON',0
        _static     db 'STATIC',0
        _combobox   db 'COMBOBOX',0

        txt_p       db 'P:',0
        txt_g       db 'G:',0
        txt_x       db 'X:',0
        txt_k       db '1-е K:',0
        txt_findg   db 'Найти G',0
        txt_file    db 'Выбрать файл...',0
        txt_enc     db 'Зашифровать',0
        txt_dec     db 'Расшифровать',0

        err_p_min   db 'Ошибка: P должно быть > 255 для шифрования байтов!',0
        err_p_max   db 'Ошибка: P должно быть <= 65535 (чтобы шифротекст влез в 2 байта)!',0
        err_prime   db 'Ошибка: P должно быть простым числом!',0
        err_x       db 'Ошибка: X должно быть > 1 и < P-1!',0
        err_k       db 'Ошибка: K должно быть > 1 и < P-1!',0
        err_k_gcd   db 'Ошибка: K должно быть взаимно простым с P-1!',0
        err_title   db 'Ошибка ввода',0

        fmt_root    db '%d',0
        fmt_enc_n   db '%d %d ',0
        fmt_dec_n   db '%d ',0
        szEmpty     db 0
        
        szOutEnc    db 'encrypted.bin',0
        szOutDec    db 'decrypted.bin',0

        wc          WNDCLASS
        msg         MSG
        ofn         OPENFILENAME
        szFileName  db 260 dup(0)
        strLog      rb 8192
        tmpStr      rb 256
        
        hWndMain    dd ?
        hFont       dd ?
        hFileIn     dd ?
        hFileOut    dd ?
        hComboG     dd ?

        p_val       dd ?
        g_val       dd ?
        x_val       dd ?
        k_val       dd ?
        y_val       dd ?
        ioBytes     dd ?
        tmpBuf      rb 4
        rng_seed    dd 12345

section '.code' code readable executable

proc WinMain
        invoke  GetModuleHandle,0
        mov     [wc.hInstance],eax
        invoke  LoadCursor,0,IDC_ARROW
        mov     [wc.hCursor],eax
        mov     [wc.lpfnWndProc], WindowProc
        mov     [wc.hbrBackground], COLOR_BTNFACE+1
        mov     [wc.lpszClassName], _class
        invoke  RegisterClass, wc

        invoke  CreateWindowEx,0,_class,_title,WS_VISIBLE+WS_SYSMENU,200,200,640,480,0,0,[wc.hInstance],0
        mov     [hWndMain], eax

.msgLoop:
        invoke  GetMessage, msg, 0,0,0
        cmp     eax,0
        je      .EndProc
        invoke  TranslateMessage,msg
        invoke  DispatchMessage,msg
        jmp     .msgLoop
.EndProc:
        invoke  ExitProcess, [msg.wParam]
endp

proc WindowProc uses ebx esi edi, hWnd, wMsg, wParam, lParam
        cmp     [wMsg], WM_CREATE
        je      .wmCreate
        cmp     [wMsg], WM_COMMAND
        je      .wmCommand
        cmp     [wMsg], WM_DESTROY
        je      .wmDestroy
        invoke  DefWindowProc, [hWnd], [wMsg], [wParam], [lParam]
        ret

.wmCreate:
        invoke  CreateFont,16,0,0,0,FW_NORMAL,0,0,0,RUSSIAN_CHARSET,0,0,0,0,0
        mov     [hFont], eax

        invoke  CreateWindowEx,0,_static,txt_p,WS_CHILD+WS_VISIBLE,20,20,20,20,[hWnd],0,[wc.hInstance],0
        invoke  CreateWindowEx,WS_EX_CLIENTEDGE,_edit,0,WS_CHILD+WS_VISIBLE+ES_NUMBER,40,18,50,24,[hWnd],ID_EDIT_P,[wc.hInstance],0
        invoke  CreateWindowEx,0,_button,txt_findg,WS_CHILD+WS_VISIBLE,100,18,80,24,[hWnd],ID_BTN_FINDG,[wc.hInstance],0

        invoke  CreateWindowEx,0,_static,txt_g,WS_CHILD+WS_VISIBLE,195,20,20,20,[hWnd],0,[wc.hInstance],0
        invoke  CreateWindowEx,0,_combobox,0,WS_CHILD+WS_VISIBLE+CBS_DROPDOWNLIST+WS_VSCROLL,215,18,60,150,[hWnd],ID_COMBO_G,[wc.hInstance],0
        mov     [hComboG], eax

        invoke  CreateWindowEx,0,_static,txt_x,WS_CHILD+WS_VISIBLE,290,20,20,20,[hWnd],0,[wc.hInstance],0
        invoke  CreateWindowEx,WS_EX_CLIENTEDGE,_edit,0,WS_CHILD+WS_VISIBLE+ES_NUMBER,310,18,50,24,[hWnd],ID_EDIT_X,[wc.hInstance],0

        invoke  CreateWindowEx,0,_static,txt_k,WS_CHILD+WS_VISIBLE,380,20,40,20,[hWnd],0,[wc.hInstance],0
        invoke  CreateWindowEx,WS_EX_CLIENTEDGE,_edit,0,WS_CHILD+WS_VISIBLE+ES_NUMBER,420,18,50,24,[hWnd],ID_EDIT_K,[wc.hInstance],0

        invoke  CreateWindowEx,0,_button,txt_file,WS_CHILD+WS_VISIBLE,490,18,110,24,[hWnd],ID_BTN_FILE,[wc.hInstance],0

        invoke  CreateWindowEx,0,_button,txt_enc,WS_CHILD+WS_VISIBLE,20,60,280,30,[hWnd],ID_BTN_ENC,[wc.hInstance],0
        invoke  CreateWindowEx,0,_button,txt_dec,WS_CHILD+WS_VISIBLE,320,60,280,30,[hWnd],ID_BTN_DEC,[wc.hInstance],0

        invoke  CreateWindowEx,WS_EX_CLIENTEDGE,_edit,0,WS_CHILD+WS_VISIBLE+ES_MULTILINE+ES_AUTOVSCROLL+WS_VSCROLL+ES_READONLY,20,110,580,300,[hWnd],ID_EDIT_LOG,[wc.hInstance],0
        
        invoke  GetTickCount
        mov     [rng_seed], eax
        ret

.wmCommand:
        mov     eax, [wParam]
        and     eax, 0FFFFh
        cmp     eax, ID_BTN_FINDG
        je      .FindRoots
        cmp     eax, ID_BTN_FILE
        je      .OpenFile
        cmp     eax, ID_BTN_ENC
        je      .Encrypt
        cmp     eax, ID_BTN_DEC
        je      .Decrypt
        ret

.FindRoots:
        invoke  GetDlgItemInt, [hWnd], ID_EDIT_P, 0, FALSE
        mov     [p_val], eax

        cmp     eax, 255
        jg      .check_p_max1
        invoke  MessageBox, [hWnd], err_p_min, err_title, MB_ICONERROR
        ret
    .check_p_max1:
        cmp     eax, 65535
        jle     .check_prime_roots
        invoke  MessageBox, [hWnd], err_p_max, err_title, MB_ICONERROR
        ret

    .check_prime_roots:
        stdcall IsPrime, [p_val]
        test    eax, eax
        jnz     .prime_ok
        invoke  MessageBox, [hWnd], err_prime, err_title, MB_ICONERROR
        ret

    .prime_ok:
        invoke  SendMessage, [hComboG], CB_RESETCONTENT, 0, 0
        mov     esi, 2
    .root_loop:
        mov     eax, [p_val]
        dec     eax
        cmp     esi, eax
        jge     .root_done
        
        mov     edi, 1
    .div_loop:
        mov     eax, [p_val]
        sub     eax, 2
        cmp     edi, eax
        jg      .is_root
        
        mov     eax, [p_val]
        dec     eax
        xor     edx, edx
        div     edi
        test    edx, edx
        jnz     .next_div
        
        stdcall QuickPow, esi, edi, [p_val]
        cmp     eax, 1
        je      .not_root
        
    .next_div:
        inc     edi
        jmp     .div_loop

    .is_root:
        invoke  wsprintf, tmpStr, fmt_root, esi
        invoke  SendMessage, [hComboG], CB_ADDSTRING, 0, tmpStr
    .not_root:
        inc     esi
        jmp     .root_loop

    .root_done:
        invoke  SendMessage, [hComboG], CB_SETCURSEL, 0, 0
        invoke  SetDlgItemText, [hWnd], ID_EDIT_LOG, szEmpty
        ret

.OpenFile:
        mov     [ofn.lStructSize], sizeof.OPENFILENAME
        mov     eax, [hWnd]
        mov     [ofn.hwndOwner], eax
        mov     [ofn.lpstrFile], szFileName
        mov     [ofn.nMaxFile], 260
        invoke  GetOpenFileName, ofn
        ret

.Encrypt:
        invoke  GetDlgItemInt, [hWnd], ID_EDIT_P, 0, FALSE
        mov     [p_val], eax
        
        cmp     eax, 255
        jg      .check_p_max2
        invoke  MessageBox, [hWnd], err_p_min, err_title, MB_ICONERROR
        ret
    .check_p_max2:
        cmp     eax, 65535
        jle     .check_prime_enc
        invoke  MessageBox, [hWnd], err_p_max, err_title, MB_ICONERROR
        ret

    .check_prime_enc:
        stdcall IsPrime, [p_val]
        test    eax, eax
        jnz     .read_params
        invoke  MessageBox, [hWnd], err_prime, err_title, MB_ICONERROR
        ret

    .read_params:
        invoke  SendMessage, [hComboG], WM_GETTEXT, 255, tmpStr
        mov     esi, tmpStr
        xor     eax, eax
        xor     ecx, ecx
    .atoi_loop:
        movzx   edx, byte [esi+ecx]
        test    edx, edx
        jz      .atoi_done
        sub     edx, '0'
        imul    eax, 10
        add     eax, edx
        inc     ecx
        jmp     .atoi_loop
    .atoi_done:
        mov     [g_val], eax

        invoke  GetDlgItemInt, [hWnd], ID_EDIT_X, 0, FALSE
        mov     [x_val], eax
        invoke  GetDlgItemInt, [hWnd], ID_EDIT_K, 0, FALSE
        mov     [k_val], eax

    .check_x:
        mov     eax, [x_val]
        cmp     eax, 1
        jle     .errX
        mov     ebx, [p_val]
        dec     ebx
        cmp     eax, ebx
        jge     .errX
        jmp     .check_k
    .errX:
        invoke  MessageBox, [hWnd], err_x, err_title, MB_ICONERROR
        ret

    .check_k:
        mov     eax, [k_val]
        cmp     eax, 1
        jle     .errK
        mov     ebx, [p_val]
        dec     ebx
        cmp     eax, ebx
        jge     .errK

        mov     eax, [p_val]
        dec     eax
        stdcall Gcd, [k_val], eax
        cmp     eax, 1
        je      .start_enc
        invoke  MessageBox, [hWnd], err_k_gcd, err_title, MB_ICONERROR
        ret
    .errK:
        invoke  MessageBox, [hWnd], err_k, err_title, MB_ICONERROR
        ret

    .start_enc:
        stdcall QuickPow, [g_val], [x_val], [p_val]
        mov     [y_val], eax

        invoke  CreateFile, szFileName, GENERIC_READ, 1, 0, OPEN_EXISTING, 0, 0
        mov     [hFileIn], eax
        invoke  CreateFile, szOutEnc, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, 0, 0
        mov     [hFileOut], eax

        mov     byte [strLog], 0

    .encLoop:
        invoke  ReadFile, [hFileIn], tmpBuf, 1, ioBytes, 0
        cmp     [ioBytes], 0
        je      .encDone

        stdcall QuickPow, [g_val], [k_val], [p_val]
        mov     ebx, eax

        stdcall QuickPow, [y_val], [k_val], [p_val]
        movzx   ecx, byte [tmpBuf]
        mul     ecx
        mov     edi, [p_val]
        div     edi
        mov     edi, edx

        invoke  lstrlen, strLog
        cmp     eax, 4000
        jg      .encSkipLog
        invoke  wsprintf, tmpStr, fmt_enc_n, ebx, edi
        invoke  lstrcat, strLog, tmpStr
    .encSkipLog:

        mov     eax, ebx
        xchg    ah, al
        mov     word [tmpBuf], ax
        mov     eax, edi
        xchg    ah, al
        mov     word [tmpBuf+2], ax
        invoke  WriteFile, [hFileOut], tmpBuf, 4, ioBytes, 0

    .genK:
        mov     eax, [rng_seed]
        imul    eax, 1103515245
        add     eax, 12345
        mov     [rng_seed], eax
        
        xor     edx, edx
        mov     ecx, [p_val]
        dec     ecx
        div     ecx
        add     edx, 2
        mov     [k_val], edx
        
        mov     eax, [p_val]
        dec     eax
        stdcall Gcd, [k_val], eax
        cmp     eax, 1
        jne     .genK
        jmp     .encLoop

    .encDone:
        invoke  CloseHandle, [hFileIn]
        invoke  CloseHandle, [hFileOut]
        invoke  SetDlgItemText, [hWnd], ID_EDIT_LOG, strLog
        ret

.Decrypt:
        invoke  GetDlgItemInt, [hWnd], ID_EDIT_P, 0, FALSE
        mov     [p_val], eax
        invoke  GetDlgItemInt, [hWnd], ID_EDIT_X, 0, FALSE
        mov     [x_val], eax

        invoke  CreateFile, szFileName, GENERIC_READ, 1, 0, OPEN_EXISTING, 0, 0
        mov     [hFileIn], eax
        invoke  CreateFile, szOutDec, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, 0, 0
        mov     [hFileOut], eax

        mov     byte [strLog], 0

    .decLoop:
        invoke  ReadFile, [hFileIn], tmpBuf, 4, ioBytes, 0
        cmp     [ioBytes], 4
        jne     .decDone

        movzx   eax, word [tmpBuf]
        xchg    ah, al
        mov     ebx, eax

        movzx   eax, word [tmpBuf+2]
        xchg    ah, al
        mov     edi, eax

        mov     eax, [p_val]
        dec     eax
        sub     eax, [x_val]
        stdcall QuickPow, ebx, eax, [p_val]
        
        mul     edi
        mov     ecx, [p_val]
        div     ecx
        mov     ebx, edx
        
        invoke  lstrlen, strLog
        cmp     eax, 4000
        jg      .decSkipLog
        invoke  wsprintf, tmpStr, fmt_dec_n, ebx
        invoke  lstrcat, strLog, tmpStr
    .decSkipLog:
    
        mov     eax, ebx
        mov     byte [tmpBuf], al
        invoke  WriteFile, [hFileOut], tmpBuf, 1, ioBytes, 0
        jmp     .decLoop

    .decDone:
        invoke  CloseHandle, [hFileIn]
        invoke  CloseHandle, [hFileOut]
        invoke  SetDlgItemText, [hWnd], ID_EDIT_LOG, strLog
        ret

.wmDestroy:
        invoke  DeleteObject, [hFont]
        invoke  PostQuitMessage, 0
        ret
endp

proc IsPrime, n:DWORD
        mov     eax, [n]
        cmp     eax, 2
        jl      .no
        je      .yes
        test    eax, 1
        jz      .no
        mov     ecx, 3
    .loop:
        mov     eax, ecx
        mul     ecx
        cmp     eax, [n]
        ja      .yes
        mov     eax, [n]
        xor     edx, edx
        div     ecx
        test    edx, edx
        jz      .no
        add     ecx, 2
        jmp     .loop
    .yes:
        mov     eax, 1
        ret
    .no:
        xor     eax, eax
        ret
endp

proc QuickPow, base:DWORD, exp:DWORD, mod_val:DWORD
        push    ebx esi edi
        mov     eax, 1
        mov     ebx, [base]
        mov     ecx, [exp]
        mov     edi, [mod_val]
    .pow_loop:
        test    ecx, ecx
        jz      .pow_end
        test    ecx, 1
        jz      .skip_mul
        mul     ebx
        div     edi
        mov     eax, edx
    .skip_mul:
        shr     ecx, 1
        test    ecx, ecx
        jz      .pow_end
        push    eax
        mov     eax, ebx
        mul     ebx
        div     edi
        mov     ebx, edx
        pop     eax
        jmp     .pow_loop
    .pow_end:
        pop     edi esi ebx
        ret
endp

proc Gcd, val_a:DWORD, val_b:DWORD
        push    ebx
        mov     eax, [val_a]
        mov     ebx, [val_b]
    .gcd_loop:
        test    ebx, ebx
        jz      .gcd_end
        xor     edx, edx
        div     ebx
        mov     eax, ebx
        mov     ebx, edx
        jmp     .gcd_loop
    .gcd_end:
        pop     ebx
        ret
endp

section '.idata' import data readable writeable
        library kernel32,'KERNEL32.DLL', user32,'USER32.DLL', gdi32,'GDI32.DLL', comdlg32,'COMDLG32.DLL'
        import kernel32, GetModuleHandle,'GetModuleHandleA', ExitProcess,'ExitProcess', CreateFile,'CreateFileA', ReadFile,'ReadFile', WriteFile,'WriteFile', CloseHandle,'CloseHandle', lstrlen,'lstrlenA', lstrcpy,'lstrcpyA', lstrcat,'lstrcatA', GetTickCount,'GetTickCount'
        import user32, RegisterClass,'RegisterClassA', CreateWindowEx,'CreateWindowExA', DefWindowProc,'DefWindowProcA', GetMessage,'GetMessageA', TranslateMessage,'TranslateMessage', DispatchMessage,'DispatchMessageA', MessageBox,'MessageBoxA', GetDlgItemInt,'GetDlgItemInt', SetDlgItemText,'SetDlgItemTextA', wsprintf,'wsprintfA', SendMessage,'SendMessageA', LoadCursor,'LoadCursorA', PostQuitMessage,'PostQuitMessage'
        import gdi32, CreateFont,'CreateFontA', DeleteObject,'DeleteObject'
        import comdlg32, GetOpenFileName,'GetOpenFileNameA'