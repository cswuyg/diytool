;Win32�����ϰ��ѧϰ��д����ͳ�ƹ��ߡ�
;2010.5.8
		.386
		.model flat, stdcall
		option casemap :none
include	codecount.inc
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; �����
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		.code
include		_BrowseFolder.asm
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;���ܣ��ļ���׺���ж�
;��ڣ�����·�����ļ���
;���ڣ�����1��ʾ����Ҫ�󣬷���0��ʾ������
;˼·��
;�����жϵ�ѭ��
;  ��ѭ����ѭ����ȡszAllFileType��ÿһ����׺�������浽szfilterbuf1������ֻ�ȡ�ĺ�׺�������Ϲ淶�����˳�������������ֵ��Ϊ0
;  ��ȡ�����ļ��ĺ�׺�����浽szfilterbuf2
;  �Ƚ������Ƿ���ͬ�������ͬ���˳���������������Ӧ�ļ����ͱ�־λ��ֵ������ֵ��Ϊ1��
;  �����ͬ��Ϊ��֤ʧ���˳���������ȷ�ԣ�szfilterbuf1�ĵ�һ���ַ���ֵ0��Ȼ�����ѭ����
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_Judge	proc	_lpszFile
	local	@szFileType[MAX_PATH]:byte		;��Ҫ�������ļ�����
	local   @szInputFileType[MAX_PATH]:byte         ;�����ļ�����
	cld
	lea	esi,szAllFileType
	xor	eax,eax
	mov	file_index,eax
	.while	TRUE
		lea	edi,@szFileType
		lodsb
		.while	(al != ';') && al
			stosb
			lodsb
		.endw
		mov	byte ptr [edi],0
		.if @szFileType != '*'
			mov	eax,0;�ļ����Ͳ���ɸѡ����
			.break;
		.endif
		;��Ϊ���ܴ����ļ�������'.'����������Ա���Ӻ���ǰ�Һ�׺����bug������2010.6.28
		invoke	lstrlen, _lpszFile
		mov	edi,_lpszFile
		add	edi,eax
		dec	edi
		;����ӵ����ڶ�����ʼ�㡣��Ϊ������һ���ַ���������'.'
		dec	edi
		mov	al,byte ptr [edi]
		.while	(al != '.') && (al != NULL)
			dec	edi
			mov	al,byte	ptr [edi]
		.endw
		inc	edi
		invoke	lstrcpy,addr @szInputFileType,edi;������׺��
		invoke	lstrcmp,addr @szInputFileType,addr @szFileType+2;ȥ��*.
		.if !eax
			lea	ebx,count_file_array
			mov	eax,file_index
			mov	ecx,2
			shl	eax,cl;����4
			lea	ebx,count_file_array
			lea	edi,[eax+ebx]
			mov	eax,[edi]
			inc	eax
			mov	[edi],eax
			mov	eax,1
			.break;
		.endif
		mov	@szFileType,NULL
		inc	file_index
	.endw
	ret

_Judge endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;���ܣ� �����ҵ����ļ�
;��ڣ�����·�����ļ���
;���ڣ�������ļ�������ɣ��޷������ݡ�
;˼·��
;���ж��ļ��Ƿ��Ƿ���Ҫ����ļ����������ת�ڴ�������������򷵻�
;������ʾ�ļ�·������ȡ�ļ����CreateFile-->��ȡ�ļ�����ʱ��GetFileTime
;	-->��ʾ�ļ�����ʱ��-->��ȡ�ļ���СGetFileSize-->��ʾ�ļ���С
;	-->�����ڴ�ӳ���ļ�����CreateFileMapping-->�ļ�ӳ�䵽�ڴ�MapViewOfFile
;	-->��
;�۶�ȡ�ļ������ݲ��������жϵ������������ӵģ��ж������������ֽ��Ƿ���0dh��0ah��
;	�������������ַ�ǰ�治��0dh��0ah��������ϣ���������1��������������������䡣
;	ÿ�ζ�ȡһ���ַ�����һ����ѭ�����жϡ�
;	���������ļ���β��ʱ�򣬿��ܴ������һ��ĳû��0dh��0ah����������Ա������ݱ�־λ
;	�жϸò��ü�1��ͳ�����֮����ʾ����ͳ��
;�ܹر��ļ�������ڴ�ӳ��UnmapViewOfFile-->�ر��ڴ�ӳ���ļ�CloseHandle
;	-->�ر��ļ�CloseHandle
;�ݸ�����_Judge������ȷ�����ļ����ͣ��ѻ�ȡ���ļ������ӵ���Ӧ�ı����С�
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_ProcessFile	proc	uses ebx edi esi _lpszFile
		LOCAL	@hFile
		LOCAL	@hFileMap
		LOCAL	@lpMemory
		LOCAL	@tempFileSize
		LOCAL	@systemtime :SYSTEMTIME
		LOCAL	@filetime:FILETIME
		LOCAL   @flag:byte
		LOCAL 	@count
		
		invoke _Judge,_lpszFile
		.if	!eax
			jmp	eenndd	
		.endif
		mov	@count,0
		mov	@flag,1
		inc	dwFileCount
		;invoke	SetDlgItemText,hWinMain,IDC_NOWFILE,_lpszFile
		invoke	SendDlgItemMessage,hWinMain,IDC_EDT1,EM_REPLACESEL,0,_lpszFile;��ʾ�ļ�·��
		invoke	CreateFile,_lpszFile,GENERIC_READ,FILE_SHARE_READ,0,\
			OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
		.if	eax !=	INVALID_HANDLE_VALUE
			mov	@hFile,eax
			;��ʾ�ļ�����ʱ��
			invoke	GetFileTime,@hFile,addr @filetime,NULL,NULL
			invoke	FileTimeToSystemTime,addr @filetime,addr @systemtime
			;�ر�Ҫע��SYSTEMTIME�ṹ���б���ʱword����������ע��Ļ����������
			movzx	eax,@systemtime.wYear
			movzx	ebx,@systemtime.wMonth
			movzx	edx,@systemtime.wDay
			;��ʾ�ļ�����ʱ��
			invoke	wsprintf,addr szbuf,addr format1,eax,ebx,edx
			invoke	SendDlgItemMessage,hWinMain,IDC_EDT1,EM_REPLACESEL,0,addr szbuf;��ʾ�ļ�����ʱ��
			;��ȡ�ļ���С
			invoke	GetFileSize,@hFile,NULL
			mov	@tempFileSize,eax
			add	dwFileSizeLow,eax
			adc	dwFileSizeHigh,0
			;��ʾ�ļ���С
			invoke	wsprintf,addr szbuf,addr format3,@tempFileSize
			invoke	SendDlgItemMessage,hWinMain,IDC_EDT1,EM_REPLACESEL,0,addr szbuf
			;ʹ���ڴ�ӳ���ļ�
			invoke	CreateFileMapping,@hFile,NULL,PAGE_READONLY,0,0,NULL
			.if	!eax
				jmp	end1
			.endif
			mov	@hFileMap,eax
			invoke	MapViewOfFile,eax,FILE_MAP_READ,0,0,0
			.if	!eax
				jmp	end2
			.endif
			mov	@lpMemory,eax;���Զ��ļ����ж��ˡ�
			mov	esi,eax
			mov	ecx,@tempFileSize
			cld
			.while	ecx
				lodsb;esi to al
				dec ecx
				.if	al == 0ah ;����ʹ��0d0a���жϣ���Ϊunix�µ��ļ���û��0d��
					.if !@flag; 
						inc	@count
						mov	@flag,1;��־λ�����������������0D��������ǿ��С��޳�����
					.else ;������0a
					.endif
				.else
					.if	al != 0dh; ���������������ʱ��windows����0d0a0d0a���������жϱ�������˿��� 
						mov	@flag,0
					.endif
				.endif	
			.endw
			.if	!@flag
				inc @count;����ļ���ĩβ������0D��0A������������Ҫ��1�������0A��������֮ǰ�Ѿ�ͳ���ˣ����ü�
			.endif
			;��ʾ����ͳ��
			invoke	wsprintf,addr szbuf,addr format4, @count
			invoke	SendDlgItemMessage,hWinMain,IDC_EDT1,EM_REPLACESEL,0,addr szbuf
			;����ڴ�ӳ���ļ�
			invoke	UnmapViewOfFile,@lpMemory
			end2:
			invoke	CloseHandle,@hFileMap
			end1:
			invoke	CloseHandle,@hFile

			lea	ebx,count_line_array
			mov	eax,file_index
			mov	ecx,2
			shl	eax,cl;����4
			lea	ebx,count_line_array
			lea	edi,[eax+ebx]
			mov	eax,[edi]
			add	eax,@count
			mov	[edi],eax
			
			mov	eax,@count
			add	allcount,eax	
		.endif	
eenndd:
		ret
_ProcessFile	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;���ܣ������ļ�
;��ڣ��ļ���·��
;���ڣ���
;ͨ��FindFirstFile��FindNextFile�����ļ������ļ�����ݹ鴦�������ļ���_ProcessFile����
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_FindFile	proc	_lpszPath
		local	@stFindFile:WIN32_FIND_DATA
		local	@hFindFile
		local	@szPath[MAX_PATH]:byte		;������š�·��\��
		local	@szSearch[MAX_PATH]:byte	;������š�·��\*.*��
		local	@szFindFile[MAX_PATH]:byte	;������š�·��\�ҵ����ļ���

		pushad
		invoke	lstrcpy,addr @szPath,_lpszPath
;********************************************************************
; ��·���������\*.*
;********************************************************************
		@@:
		invoke	lstrlen,addr @szPath
		lea	esi,@szPath
		add	esi,eax
		xor	eax,eax
		mov	al,'\'
		.if	byte ptr [esi-1] != al
			mov	word ptr [esi],ax
		.endif
		invoke	lstrcpy,addr @szSearch,addr @szPath
		invoke	lstrcat,addr @szSearch,addr szFilter
;********************************************************************
; Ѱ���ļ�
;********************************************************************
		invoke	FindFirstFile,addr @szSearch,addr @stFindFile
		.if	eax !=	INVALID_HANDLE_VALUE
			mov	@hFindFile,eax
			.repeat
				invoke	lstrcpy,addr @szFindFile,addr @szPath
				invoke	lstrcat,addr @szFindFile,addr @stFindFile.cFileName
				.if	@stFindFile.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY
					.if	@stFindFile.cFileName != '.'
						inc	dwFolderCount
						invoke	_FindFile,addr @szFindFile;�ݹ�������Ŀ¼
					.endif
				.else
					;invoke	MessageBox,NULL,addr @szFindFile,0,1;���ڵ���
					invoke	_ProcessFile,addr @szFindFile
				.endif
				invoke	FindNextFile,@hFindFile,addr @stFindFile
			.until	(eax ==	FALSE) || (dwOption & F_STOP)
			invoke	FindClose,@hFindFile
		.endif
		popad
		ret

_FindFile	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;���ܣ������̣߳�����ͳ��
;��ڣ���
;���ڣ���
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_ProcThread	proc	uses ebx ecx edx esi edi,lParam
		local	@szBuffer[1024]:byte
		local	@systemtime:SYSTEMTIME
		LOCAL	@szFileType[64]:byte
		LOCAL	@FileTypeIndex
		
		invoke	GetTickCount
		mov	dwTickCount1,eax
;********************************************************************
; ���ñ�־λ�����һ����������ť��·�����������ļ���������������������checkbox
;********************************************************************
		and	dwOption,not F_STOP
		or	dwOption,F_SEARCHING
		invoke	GetDlgItem,hWinMain,IDC_PATH
		invoke	EnableWindow,eax,FALSE
		invoke	GetDlgItem,hWinMain,IDC_FILETYPE
		invoke	EnableWindow,eax,FALSE
		invoke	GetDlgItem,hWinMain,IDC_BROWSE
		invoke	EnableWindow,eax,FALSE
		mov	ecx,IDC_CHK1
		.while	ecx <= IDC_CHK5
			push ecx
			invoke	GetDlgItem,hWinMain,ecx
			invoke	EnableWindow,eax,FALSE
			pop ecx
			inc	ecx
		.endw			
		invoke	SetDlgItemText,hWinMain,IDC_START,addr szStop
		invoke	GetDlgItemText,hWinMain,IDC_FILETYPE,addr szAllFileType,1024
		xor	eax,eax
		mov	dwFileSizeHigh,eax
		mov	dwFileSizeLow,eax
		mov	dwFileCount,eax
		mov	dwFolderCount,eax
		mov	allcount,eax
		invoke	RtlZeroMemory,addr count_file_array,sizeof count_file_array
		invoke	RtlZeroMemory,addr count_line_array,sizeof count_line_array		
		invoke	_FindFile,addr szPath
;********************************************************************
; �˳�ʱ��ʾ�ҵ��ļ����ܴ�С
;********************************************************************
		mov	edx,dwFileSizeHigh
		mov	eax,dwFileSizeLow
		mov	ecx,1024
		div	ecx
		mov	dwsize,eax
		;��ȡϵͳʱ��
		invoke	GetLocalTime,addr @systemtime;����GetSystemTime
		movzx	eax,@systemtime.wYear
		movzx	ebx,@systemtime.wMonth
		movzx	edx,@systemtime.wDay
		;��ʾͳ�����	
		invoke	wsprintf,addr @szBuffer,addr format_start,dwFolderCount,dwFileCount,dwsize,\
				allcount,eax,ebx,edx
		invoke	SendDlgItemMessage,hWinMain,IDC_EDT1,EM_REPLACESEL,0,addr @szBuffer
		cld
		lea	esi,szAllFileType
		xor	eax,eax
		mov	@FileTypeIndex,eax
		.while	TRUE
			lea	edi,@szFileType
			lodsb
			.while	(al != ';') && al
				stosb
				lodsb
			.endw
			mov	byte ptr [edi],0	
			.if @szFileType != '*'
				.break;;ѭ������
			.endif
			lea	ebx,count_file_array
			mov	eax,@FileTypeIndex
			mov	ecx,2
			shl	eax,cl;����4
			lea	edi,count_file_array
			lea	edi,[eax+edi]
			lea	edx,count_line_array
			lea	edx,[eax+edx]
			mov	eax,[edi]
			mov	ebx,[edx]	
			invoke	wsprintf,addr @szBuffer,addr format_one,addr @szFileType,eax,ebx
			invoke	SendDlgItemMessage,hWinMain,IDC_EDT1,EM_REPLACESEL,0,addr @szBuffer
			mov	@szFileType,NULL
			inc	@FileTypeIndex
		.endw	
		
		invoke	wsprintf,addr @szBuffer,addr format_end
		invoke	SendDlgItemMessage,hWinMain,IDC_EDT1,EM_REPLACESEL,0,addr @szBuffer
		
;********************************************************************
; ���ñ�־λ�������á��������ť��·�����������ļ���������������������checkbox
;********************************************************************
		invoke	GetDlgItem,hWinMain,IDC_BROWSE
		invoke	EnableWindow,eax,TRUE
		invoke	GetDlgItem,hWinMain,IDC_PATH
		invoke	EnableWindow,eax,TRUE
		invoke	GetDlgItem,hWinMain,IDC_FILETYPE
		invoke	EnableWindow,eax,TRUE
		mov	ecx,IDC_CHK1
		.while	ecx <= IDC_CHK5
			push ecx
			invoke	GetDlgItem,hWinMain,ecx
			invoke	EnableWindow,eax,TRUE
			pop ecx
			inc	ecx
		.endw			
		
		invoke	SetDlgItemText,hWinMain,IDC_START,addr szStart
		invoke	SetDlgItemText,hWinMain,IDC_PATH,addr szPath
		and	dwOption,not F_SEARCHING
		
		invoke	GetTickCount
		sub	eax,dwTickCount1
		invoke	SetDlgItemInt,hWinMain,IDC_TIME,eax,0	
		ret
_ProcThread	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Richedit���������ص�����
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_ProcStream	proc uses ebx edi esi _dwCookie,_lpBuffer,_dwBytes,_lpBytes

		invoke	WriteFile,hsave,_lpBuffer,_dwBytes,_lpBytes,0
		xor	eax,eax
		ret
_ProcStream	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; �������弰������ɫ
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_SetFont	proc	
		local	@stCf:CHARFORMAT2

		invoke	RtlZeroMemory,addr @stCf,sizeof @stCf
		mov	@stCf.cbSize,sizeof @stCf
		
		mov	@stCf.dwMask,  CFM_BACKCOLOR or CFM_BOLD or CFM_SIZE 
		mov	@stCf.dwEffects,CFE_BOLD
		mov	@stCf.yHeight,200
		RGB	204,232,207
		mov	@stCf.crBackColor,eax
		invoke	SendDlgItemMessage,hWinMain,IDC_EDT1,EM_SETTEXTMODE,TM_PLAINTEXT,0;���ù���ģʽ
		invoke	SendDlgItemMessage,hWinMain,IDC_EDT1,EM_SETCHARFORMAT,SCF_ALL,addr @stCf
		ret
_SetFont	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_ProcDlgMain	proc	uses ebx edi esi hWnd,wMsg,wParam,lParam
		local	@dwTemp
		local   @szBuffer[MAX_PATH]:byte
		local	@stOf:OPENFILENAME
		local	@stES:EDITSTREAM
		
		mov	eax,wMsg
		.if	eax ==	WM_CLOSE
			.if	! (dwOption & F_SEARCHING)
				invoke	EndDialog,hWnd,NULL
			.endif
;********************************************************************
		.elseif	eax ==	WM_INITDIALOG
			push	hWnd
			pop	hWinMain
			invoke	LoadIcon,hInstance,ICO_MAIN
			invoke	SendMessage,hWnd,WM_SETICON,ICON_BIG,eax
			invoke	SendDlgItemMessage,hWnd,IDC_PATH,EM_SETLIMITTEXT,MAX_PATH,0;�޶������ַ���Ŀ
			invoke	GetDlgItem,hWnd,IDC_START
			invoke	EnableWindow,eax,FALSE
			invoke _SetFont
;********************************************************************
		.elseif	eax ==	WM_COMMAND
			mov	eax,wParam
			.if	ax ==	IDC_BROWSE
				invoke	_BrowseFolder,hWnd,addr szPath
				.if	eax
					invoke	SetDlgItemText,hWnd,IDC_PATH,addr szPath
				.endif
			.elseif	(ax >= IDC_CHK1) && (ax <= IDC_CHK5)
				invoke	SetDlgItemText,hWnd,IDC_FILETYPE,NULL;���ԭ�������ݣ����Ű�ѡ�е�item��ʾ��edit��
				mov	ecx,IDC_CHK1
				.while	ecx <= IDC_CHK5
					push	ecx
					invoke	SendDlgItemMessage,hWnd,ecx,BM_GETCHECK,0,0
					;invoke	SetDlgItemInt,hWnd,IDC_EDT1,eax,0
					.if	eax == BST_CHECKED 
						pop	eax
						push	eax
						sub	eax,IDC_CHK1
						;�±�Ϊeax*8
						mov	ecx,3
						shl	eax,cl
						lea	ebx,filter
						lea	eax,[eax+ebx]
						;invoke	lstrcpy,addr szbuf,eax
						invoke	wsprintf,addr szbuf,eax
						invoke	SendDlgItemMessage,hWnd,IDC_FILETYPE,EM_REPLACESEL,0,addr szbuf
					.endif
					pop	ecx
					inc	ecx
				.endw	
			.elseif	ax == IDC_PATH || ax == IDC_FILETYPE
				invoke	GetDlgItemText,hWnd,IDC_PATH,addr @szBuffer,MAX_PATH
				push eax
				invoke	GetDlgItemText,hWnd,IDC_FILETYPE,addr @szBuffer,MAX_PATH
				pop ebx
				xor ecx,ecx
				.if eax !=0 && ebx != 0
					mov ecx,TRUE
				.endif
				invoke	GetDlgItem,hWnd,IDC_START
				invoke	EnableWindow,eax,ecx
			.elseif ax == IDC_FILETYPE
				
				mov	ebx,eax
				invoke	GetDlgItem,hWnd,IDC_START
				invoke	EnableWindow,eax,ebx			
;********************************************************************
; ���¿�ʼ��ť�������Ѱ����������ֹͣ��־
; ���û�п�ʼѰ������һ��Ѱ���ļ����߳�
;********************************************************************
			.elseif	ax ==	IDC_START
				.if	dwOption & F_SEARCHING
					or	dwOption,F_STOP
				.else
					invoke	GetDlgItemText,hWnd,IDC_PATH,addr szPath,MAX_PATH
					.if eax != 0
						invoke	CreateThread,NULL,0,offset _ProcThread,NULL,\
							NULL,addr @dwTemp
						invoke	CloseHandle,eax
					.endif
				.endif
			.elseif	ax == IDC_SAVE
				invoke	RtlZeroMemory,addr @stOf,sizeof	@stOf
				mov	@stOf.lStructSize,sizeof @stOf
				push	hWinMain
				pop	@stOf.hwndOwner
				mov	@stOf.lpstrFile,offset	SzFileName
				mov	@stOf.lpstrFilter,offset SzExtPe
				mov	@stOf.nMaxFile,MAX_PATH
				mov	@stOf.Flags,OFN_PATHMUSTEXIST or OFN_FILEMUSTEXIST
				invoke	GetSaveFileName,addr @stOf
				.if	!eax
					jmp	@f
				.endif
;********************************************************************
;�������ļ�����
;********************************************************************	
				invoke	CreateFile,addr SzFileName,GENERIC_WRITE,NULL,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_ARCHIVE,NULL
				mov	hsave,eax
				mov	ebx,sizeof szsave
				invoke	WriteFile,hsave,addr szsave,ebx,addr @dwTemp,NULL		
				;ͨ��RichEdit���ļ�������
				mov	@stES.dwCookie,FALSE
				mov	@stES.pfnCallback,offset _ProcStream
				invoke	SendDlgItemMessage,hWinMain,IDC_EDT1,EM_STREAMOUT,SF_TEXT,addr @stES
				;invoke	SendDlgItemMessage,hWinMain,IDC_EDT1,EM_SETMODIFY,FALSE,0
				invoke	CloseHandle,hsave
		@@:	
			.endif
;********************************************************************
		.else
			mov	eax,FALSE
			ret
		.endif
		mov	eax,TRUE
		ret

_ProcDlgMain	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
start:
		invoke	LoadLibrary,addr SzLibname;  show the initialize picture(just a joke, it don't have to initialize..)
		.if	eax != NULL
			invoke	FreeLibrary,eax
		.endif
		invoke	GetModuleHandle,NULL
		mov	hInstance,eax
		invoke	LoadLibrary,offset szDllRichEdit
		mov	hRichEdit,eax
		invoke	DialogBoxParam,hInstance,IDD_DIALOG1,NULL,offset _ProcDlgMain,NULL
		invoke	FreeLibrary,hRichEdit
		invoke	ExitProcess,NULL
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		end	start