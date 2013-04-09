;Win32汇编练习，学习编写代码统计工具。
;2010.5.8
		.386
		.model flat, stdcall
		option casemap :none
include	codecount.inc
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; 代码段
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		.code
include		_BrowseFolder.asm
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;功能：文件后缀名判断
;入口：包含路径的文件名
;出口：返回1表示符合要求，返回0表示不符合
;思路：
;进入判断的循环
;  内循环，循环获取szAllFileType中每一个后缀名，保存到szfilterbuf1如果发现获取的后缀名不符合规范，则退出本函数，返回值置为0
;  获取输入文件的后缀名保存到szfilterbuf2
;  比较它们是否相同，如果相同则退出本函数，设置相应文件类型标志位的值，返回值置为1；
;  如果不同，为保证失败退出函数的正确性，szfilterbuf1的第一个字符赋值0，然后继续循环。
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_Judge	proc	_lpszFile
	local	@szFileType[MAX_PATH]:byte		;需要处理的文件类型
	local   @szInputFileType[MAX_PATH]:byte         ;输入文件类型
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
			mov	eax,0;文件类型不在筛选项中
			.break;
		.endif
		;因为可能存在文件名中有'.'的情况，所以必须从后往前找后缀名，bug修正：2010.6.28
		invoke	lstrlen, _lpszFile
		mov	edi,_lpszFile
		add	edi,eax
		dec	edi
		;必须从倒数第二个开始算。因为倒数第一个字符不可以是'.'
		dec	edi
		mov	al,byte ptr [edi]
		.while	(al != '.') && (al != NULL)
			dec	edi
			mov	al,byte	ptr [edi]
		.endw
		inc	edi
		invoke	lstrcpy,addr @szInputFileType,edi;拷贝后缀名
		invoke	lstrcmp,addr @szInputFileType,addr @szFileType+2;去掉*.
		.if !eax
			lea	ebx,count_file_array
			mov	eax,file_index
			mov	ecx,2
			shl	eax,cl;乘以4
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
;功能： 处理找到的文件
;入口：包含路径的文件名
;出口：输入的文件处理完成，无返回内容。
;思路：
;①判断文件是否是符合要求的文件，如果是则转②处理，如果不是则返回
;②先显示文件路径。获取文件句柄CreateFile-->获取文件创建时间GetFileTime
;	-->显示文件创建时间-->获取文件大小GetFileSize-->显示文件大小
;	-->创建内存映射文件对象CreateFileMapping-->文件映射到内存MapViewOfFile
;	-->③
;③读取文件的内容并处理。判断的依据是这样子的：判断连续的两个字节是否是0dh、0ah，
;	并且在这两个字符前面不是0dh、0ah。如果符合，则行数加1，如果不符合则行数不变。
;	每次读取一个字符，在一个大循环里判断。
;	当处理到文件结尾的时候，可能存在最后一行某没有0dh、0ah的情况，所以必须依据标志位
;	判断该不该加1。统计完成之后显示行数统计
;④关闭文件。解除内存映射UnmapViewOfFile-->关闭内存映射文件CloseHandle
;	-->关闭文件CloseHandle
;⑤根据在_Judge函数中确定的文件类型，把获取的文件行数加到相应的变量中。
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
		invoke	SendDlgItemMessage,hWinMain,IDC_EDT1,EM_REPLACESEL,0,_lpszFile;显示文件路径
		invoke	CreateFile,_lpszFile,GENERIC_READ,FILE_SHARE_READ,0,\
			OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
		.if	eax !=	INVALID_HANDLE_VALUE
			mov	@hFile,eax
			;显示文件创建时间
			invoke	GetFileTime,@hFile,addr @filetime,NULL,NULL
			invoke	FileTimeToSystemTime,addr @filetime,addr @systemtime
			;特别要注意SYSTEMTIME结构体中变量时word！！！，不注意的话，会出错。
			movzx	eax,@systemtime.wYear
			movzx	ebx,@systemtime.wMonth
			movzx	edx,@systemtime.wDay
			;显示文件创建时间
			invoke	wsprintf,addr szbuf,addr format1,eax,ebx,edx
			invoke	SendDlgItemMessage,hWinMain,IDC_EDT1,EM_REPLACESEL,0,addr szbuf;显示文件创建时间
			;获取文件大小
			invoke	GetFileSize,@hFile,NULL
			mov	@tempFileSize,eax
			add	dwFileSizeLow,eax
			adc	dwFileSizeHigh,0
			;显示文件大小
			invoke	wsprintf,addr szbuf,addr format3,@tempFileSize
			invoke	SendDlgItemMessage,hWinMain,IDC_EDT1,EM_REPLACESEL,0,addr szbuf
			;使用内存映射文件
			invoke	CreateFileMapping,@hFile,NULL,PAGE_READONLY,0,0,NULL
			.if	!eax
				jmp	end1
			.endif
			mov	@hFileMap,eax
			invoke	MapViewOfFile,eax,FILE_MAP_READ,0,0,0
			.if	!eax
				jmp	end2
			.endif
			mov	@lpMemory,eax;可以对文件进行读了。
			mov	esi,eax
			mov	ecx,@tempFileSize
			cld
			.while	ecx
				lodsb;esi to al
				dec ecx
				.if	al == 0ah ;不能使用0d0a做判断，因为unix下的文件是没有0d的
					.if !@flag; 
						inc	@count
						mov	@flag,1;标志位，如果接下来还遇到0D，则表明是空行；如果接下来遇到00，则说明是unicode的文本。剔除空行
					.else ;连续的0a
					.endif
				.else
					.if	al != 0dh && al != 0; 当有连续多个空行时，windows下是0d0a0d0a，必须做判断避免计算了空行,unicode格式的文件空行是0d000a00（小端）或者000d000a(大端)，需要做处理  
						mov	@flag,0
					.endif
				.endif	
			.endw
			.if	!@flag
				inc @count;如果文件的末尾不是以0D、0A结束，则行数要加1，如果以0A结束，则之前已经统计了，不用加
			.endif
			;显示行数统计
			invoke	wsprintf,addr szbuf,addr format4, @count
			invoke	SendDlgItemMessage,hWinMain,IDC_EDT1,EM_REPLACESEL,0,addr szbuf
			;解除内存映射文件
			invoke	UnmapViewOfFile,@lpMemory
			end2:
			invoke	CloseHandle,@hFileMap
			end1:
			invoke	CloseHandle,@hFile

			lea	ebx,count_line_array
			mov	eax,file_index
			mov	ecx,2
			shl	eax,cl;乘以4
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
;功能：查找文件
;入口：文件夹路径
;出口：无
;通过FindFirstFile和FindNextFile查找文件，是文件夹则递归处理。是文件则_ProcessFile处理
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_FindFile	proc	_lpszPath
		local	@stFindFile:WIN32_FIND_DATA
		local	@hFindFile
		local	@szPath[MAX_PATH]:byte		;用来存放“路径\”
		local	@szSearch[MAX_PATH]:byte	;用来存放“路径\*.*”
		local	@szFindFile[MAX_PATH]:byte	;用来存放“路径\找到的文件”

		pushad
		invoke	lstrcpy,addr @szPath,_lpszPath
;********************************************************************
; 在路径后面加上\*.*
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
; 寻找文件
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
						invoke	_FindFile,addr @szFindFile;递归搜索子目录
					.endif
				.else
					;invoke	MessageBox,NULL,addr @szFindFile,0,1;用于调试
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
;功能：工作线程，用于统计
;入口：无
;出口：无
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_ProcThread	proc	uses ebx ecx edx esi edi,lParam
		local	@szBuffer[1024]:byte
		local	@systemtime:SYSTEMTIME
		LOCAL	@szFileType[64]:byte
		LOCAL	@FileTypeIndex
		
		invoke	GetTickCount
		mov	dwTickCount1,eax
;********************************************************************
; 设置标志位，并灰化“浏览”按钮、路径输入栏、文件类型输入栏、常用类型checkbox
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
; 退出时显示找到文件的总大小
;********************************************************************
		mov	edx,dwFileSizeHigh
		mov	eax,dwFileSizeLow
		mov	ecx,1024
		div	ecx
		mov	dwsize,eax
		;获取系统时间
		invoke	GetLocalTime,addr @systemtime;不用GetSystemTime
		movzx	eax,@systemtime.wYear
		movzx	ebx,@systemtime.wMonth
		movzx	edx,@systemtime.wDay
		;显示统计情况	
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
				.break;;循环结束
			.endif
			lea	ebx,count_file_array
			mov	eax,@FileTypeIndex
			mov	ecx,2
			shl	eax,cl;乘以4
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
; 设置标志位，并启用“浏览”按钮、路径输入栏、文件类型输入栏、常用类型checkbox
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
; Richedit的流操作回调函数
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_ProcStream	proc uses ebx edi esi _dwCookie,_lpBuffer,_dwBytes,_lpBytes

		invoke	WriteFile,hsave,_lpBuffer,_dwBytes,_lpBytes,0
		xor	eax,eax
		ret
_ProcStream	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; 设置字体及字体颜色
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
		invoke	SendDlgItemMessage,hWinMain,IDC_EDT1,EM_SETTEXTMODE,TM_PLAINTEXT,0;设置工作模式
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
			invoke	SendDlgItemMessage,hWnd,IDC_PATH,EM_SETLIMITTEXT,MAX_PATH,0;限定输入字符数目
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
				invoke	SetDlgItemText,hWnd,IDC_FILETYPE,NULL;清除原来的内容，接着把选中的item显示在edit上
				mov	ecx,IDC_CHK1
				.while	ecx <= IDC_CHK5
					push	ecx
					invoke	SendDlgItemMessage,hWnd,ecx,BM_GETCHECK,0,0
					;invoke	SetDlgItemInt,hWnd,IDC_EDT1,eax,0
					.if	eax == BST_CHECKED 
						pop	eax
						push	eax
						sub	eax,IDC_CHK1
						;下边为eax*8
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
; 按下开始按钮，如果在寻找中则设置停止标志
; 如果没有开始寻找则建立一个寻找文件的线程
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
;创建新文件保存
;********************************************************************	
				invoke	CreateFile,addr SzFileName,GENERIC_WRITE,NULL,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_ARCHIVE,NULL
				mov	hsave,eax
				mov	ebx,sizeof szsave
				invoke	WriteFile,hsave,addr szsave,ebx,addr @dwTemp,NULL		
				;通过RichEdit的文件流保存
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
