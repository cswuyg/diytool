
include windows.inc
include kernel32.inc
include user32.inc
include shell32.inc
include	ole32.inc
include Comctl32.inc
include	comdlg32.inc

includelib Comctl32.lib
includelib kernel32.lib
includelib user32.lib
includelib shell32.lib
includelib ole32.lib
includelib comdlg32.lib

;#########################################################################
RGB	macro		red,green,blue
				xor	eax,eax
				mov	ah,blue
				shl	eax,8
				mov	ah,green
				mov	al,red
endm
;#########################################################################
DlgProc			PROTO	:HWND,:UINT,:WPARAM,:LPARAM
;#########################################################################
IDD_DIALOG1		equ	101
IDC_STC1		equ	1001
IDC_PATH		equ	1002
IDC_BROWSE		equ	1003
IDC_START		equ	1004
IDC_FILETYPE		equ	1012
IDC_MVI1		equ	1017
IDC_CHK1		equ	1005
IDC_CHK2		equ	1006
IDC_CHK3		equ	1007
IDC_CHK4		equ	1008
IDC_CHK5		equ	1009
IDC_STC2		equ	1010
IDC_EDT1		equ	1013
IDC_SAVE		equ	1011
ICO_MAIN		equ	1000
IDC_TIME		EQU	1014
;#########################################################################
.const
SzLibname	db	"dll.dll",0
szStart		db	'开始(&S)',0
szStop		db	'停止(&S)',0
szFilter	db	"*.*",0
filter		db	"*.c;",0,0,0,0
		db	"*.cpp;",0,0
		db	"*.asm;",0,0
		db	"*.h;",0,0,0,0
		db	"*.inc;",0,0
format1		db	9,"创建时间:%d-%d-%d",9,0
format_start	db	"#######################################",0dh,0ah,\
			"统计:",0dh,0ah,\
			"共找到 %d 个文件夹，%d 个文件，共 %luK 字节",0dh,0ah,\
			"总行数:%d",0dh,0ah,"统计时间:%d-%d-%d",0dh,0ah,0	
format_one	db	"%s，文件个数：%d，文件行数：%d",0dh,0ah,0
format_end	db 	"#######################################",0dh,0ah,0
			
			
format3		db	"文件大小:%d字节",9,0
format4		db	"代码+注释统计:%d行",0dh,0ah,0
szDllRichEdit	db	'RichEd20.dll',0
SzExtPe		db	"TXT Files",0,"*.txt",0,0
szsave		db	"----CodeCount代码行数统计保存(by cswuyg)----",0dh,0ah,0
szFont		db	"YaHei Consolas Hybrid",0
;#########################################################################

.data?
hWinMain	dd	?
hInstance	dd 	?
dwFileSizeHigh	dd	?;文件大小
dwFileSizeLow	dd	?;文件大小
dwFileCount	dd	?;文件数目
dwFolderCount	dd	?;文件夹数目
hRichEdit	dd	?;用于RichEdit的dll句柄
hsave		dd	?;用于保存统计结果是新建文件句柄
dwTickCount1	dd	?;用于统计程序搜索所需时间

szPath		db	MAX_PATH dup (?)
dwOption	db	?
F_SEARCHING	equ	0001h; 搜索标志值
F_STOP		equ	0002h; 停止标志值
szfilterbuf2	db	32 dup(?);用于文件后缀名匹配
szbuf		db	1024 dup(?);缓冲区
SzFileName	db	MAX_PATH dup(?)	;路径;之所以不用szPath，是因为当搜索暂停之后，要保存会存在问题
szAllFileType   db      1024 dup(?); 文件后缀名集
;#########################################################################
.data
dwsize		dd	0;保存所有文件的大小总和
allcount	dd	0;行数总和
count_c		dd	0;C代码行数
count_cpp	dd	0;cpp代码行数
count_asm	dd	0;asm代码行数
count_h		dd	0;h代码行数
count_inc	dd	0;inc代码行数
count_other	dd	0;其它自定义代码行数
file_index	dd	0;filter数组跟计数数组的对应序号
count_file_array     dd    256 dup(0); 最多允许有256种文件类型  
count_line_array     dd    256 dup(0);
		
