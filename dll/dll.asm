;���ӣ�link /subsystem:windows /dll /def:dll.def dll.obj dll.res
;������ͼƬ����ʾ�ŵ�dll����Խ�ʡ��������ʱ�Ŀռ�
			.386
			.model	flat,stdcall
			option	casemap:none
include		windows.inc
include		kernel32.inc
include		user32.inc
include		gdi32.inc
includelib	kernel32.lib
includelib	user32.lib
includelib	gdi32.lib
			.data
SzBitmapName	db		"MySplashBMP",0;���ַ�������ʾͼƬ
SzClassName		db		"splash",0
hBitMap			dd		0
TimerID			dd		0
			.data?
hInstance	dd		?
			.code
DllEntry	proc	hInst,reason,reserved1
		.if	reason == DLL_PROCESS_ATTACH
			push	hInst
			pop	hInstance
			call	ShowBitMap
		.endif
		mov		eax,TRUE
		ret
DllEntry	endp
ShowBitMap	proc
		local	@wc:WNDCLASSEX
		local	@msg:MSG
		local	@hwnd:HWND
		
		invoke	RtlZeroMemory,addr @wc,sizeof	WNDCLASSEX
		mov	@wc.cbSize,sizeof	WNDCLASSEX
		mov	@wc.style,CS_HREDRAW or CS_VREDRAW
		mov	@wc.lpfnWndProc,offset WndProc
		push	hInstance
		pop	@wc.hInstance
		mov	@wc.hbrBackground,COLOR_WINDOW+1
		mov	@wc.lpszClassName,offset SzClassName
		invoke	LoadIcon,NULL,IDI_APPLICATION
		mov	@wc.hIcon,eax
		mov	@wc.hIconSm,eax
		invoke	LoadCursor,NULL,IDC_ARROW
		mov	@wc.hCursor,eax
		invoke	RegisterClassEx,addr @wc
		invoke	CreateWindowEx,NULL,addr SzClassName,NULL,\
					WS_POPUP,CW_USEDEFAULT,CW_USEDEFAULT,400,266,NULL,NULL,\
					hInstance,NULL
		mov		@hwnd,eax
		invoke	ShowWindow,@hwnd,SW_SHOWNORMAL
		.while	TRUE
			invoke	GetMessage,addr @msg,NULL,0,0
			.break .if(!eax)
			invoke	TranslateMessage,addr @msg
			invoke	DispatchMessage,addr @msg
		.endw
		mov	eax,@msg.wParam
		ret
ShowBitMap	endp
WndProc	proc	hWnd,uMsg,wParam,lParam
		local	@ps:PAINTSTRUCT
		local	@hdc:HDC
		local	@hMemoryDC:HDC
		local	@hOldBmp:DWORD
		local	@bitmap:BITMAP
		local	@DlgHeight:DWORD
		local	@DlgWidth:DWORD
		local	@DlgRect:RECT
		local	@DesktopRect:RECT
		
		.if	uMsg == WM_DESTROY
			.if	hBitMap != 0
				invoke	DeleteObject,hBitMap
			.endif
			invoke	PostQuitMessage,NULL
		.elseif	uMsg == WM_CREATE
			invoke	GetWindowRect,hWnd,addr @DlgRect
			invoke	GetDesktopWindow
			mov		ecx,eax
			invoke	GetWindowRect,ecx,addr @DesktopRect;��ȡ����Ĵ�С
			push		0
			;�±�һ�ѵĲ�������Ϊ��ʹ�����ܹ�����Ļ�м���ʾ
			mov		eax,@DlgRect.bottom
			sub		eax,@DlgRect.top
			mov		@DlgHeight,eax
			push		eax
			mov		eax,@DlgRect.right
			sub		eax,@DlgRect.left
			mov		@DlgWidth,eax
			push		eax
			mov		eax,@DesktopRect.bottom
			sub		eax,@DlgHeight
			shr		eax,1
			push		eax
			mov		eax,@DesktopRect.right
			sub		eax,@DlgWidth
			shr		eax,1
			push		eax
			push		hWnd
			call		MoveWindow
			invoke	LoadBitmap,hInstance,addr SzBitmapName
			mov		hBitMap,eax
			invoke	SetTimer,hWnd,1,2000,NULL;�趨ʱ�� ��ʱ�� ��ÿ2���򴰿ڷ���WM_TIMER��Ϣ
			mov		TimerID,eax
		.elseif	uMsg == WM_TIMER
			invoke	SendMessage,hWnd,WM_LBUTTONDOWN,NULL,NULL
			invoke	KillTimer,hWnd,TimerID
		.elseif	uMsg == WM_PAINT
			invoke	BeginPaint,hWnd,addr @ps
			mov		@hdc,eax
			invoke	CreateCompatibleDC,@hdc
			mov		@hMemoryDC,eax
			invoke	SelectObject,@hMemoryDC,hBitMap
			mov		@hOldBmp,eax
			invoke	GetObject,hBitMap,sizeof BITMAP,addr @bitmap
			;���� StretchBlt ���ܹ��Զ�����ԴDC�������ݵĴ�С����ӦĿ��DC����������С
			invoke	StretchBlt,@hdc,0,0,400,266,\
						@hMemoryDC,0,0,@bitmap.bmWidth,@bitmap.bmHeight,SRCCOPY
			invoke	SelectObject,@hMemoryDC,@hOldBmp;�������ԭ���Ķ���ѡ��ȥ�����������Ĭ�ϵģ�Ȼ����ɾ��
			invoke	DeleteDC,@hMemoryDC
			invoke	DeleteObject,hBitMap
			invoke	EndPaint,hWnd,addr @ps
		.elseif	uMsg == WM_LBUTTONDOWN
			invoke	DestroyWindow,hWnd
		.else	
			invoke	DefWindowProc,hWnd,uMsg,wParam,lParam
			ret
		.endif
		xor	eax,eax
		ret
WndProc	endp
end	DllEntry
						