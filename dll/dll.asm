;链接：link /subsystem:windows /dll /def:dll.def dll.obj dll.res
;把启动图片的显示放到dll里可以节省程序运行时的空间
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
SzBitmapName	db		"MySplashBMP",0;用字符串来表示图片
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
			invoke	GetWindowRect,ecx,addr @DesktopRect;获取桌面的大小
			push		0
			;下边一堆的操作都是为了使窗口能够在屏幕中间显示
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
			invoke	SetTimer,hWnd,1,2000,NULL;设定时器 定时器 将每2秒向窗口发送WM_TIMER消息
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
			;函数 StretchBlt 则能够自动调整源DC复制内容的大小已适应目的DC的输出区域大小
			invoke	StretchBlt,@hdc,0,0,400,266,\
						@hMemoryDC,0,0,@bitmap.bmWidth,@bitmap.bmHeight,SRCCOPY
			invoke	SelectObject,@hMemoryDC,@hOldBmp;必须把它原来的对象选回去，这个对象是默认的，然后再删除
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
						