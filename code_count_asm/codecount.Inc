
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
szStart		db	'��ʼ(&S)',0
szStop		db	'ֹͣ(&S)',0
szFilter	db	"*.*",0
filter		db	"*.c;",0,0,0,0
		db	"*.cpp;",0,0
		db	"*.asm;",0,0
		db	"*.h;",0,0,0,0
		db	"*.inc;",0,0
format1		db	9,"����ʱ��:%d-%d-%d",9,0
format_start	db	"#######################################",0dh,0ah,\
			"ͳ��:",0dh,0ah,\
			"���ҵ� %d ���ļ��У�%d ���ļ����� %luK �ֽ�",0dh,0ah,\
			"������:%d",0dh,0ah,"ͳ��ʱ��:%d-%d-%d",0dh,0ah,0	
format_one	db	"%s���ļ�������%d���ļ�������%d",0dh,0ah,0
format_end	db 	"#######################################",0dh,0ah,0
			
			
format3		db	"�ļ���С:%d�ֽ�",9,0
format4		db	"����+ע��ͳ��:%d��",0dh,0ah,0
szDllRichEdit	db	'RichEd20.dll',0
SzExtPe		db	"TXT Files",0,"*.txt",0,0
szsave		db	"----CodeCount��������ͳ�Ʊ���(by cswuyg)----",0dh,0ah,0
szFont		db	"YaHei Consolas Hybrid",0
;#########################################################################

.data?
hWinMain	dd	?
hInstance	dd 	?
dwFileSizeHigh	dd	?;�ļ���С
dwFileSizeLow	dd	?;�ļ���С
dwFileCount	dd	?;�ļ���Ŀ
dwFolderCount	dd	?;�ļ�����Ŀ
hRichEdit	dd	?;����RichEdit��dll���
hsave		dd	?;���ڱ���ͳ�ƽ�����½��ļ����
dwTickCount1	dd	?;����ͳ�Ƴ�����������ʱ��

szPath		db	MAX_PATH dup (?)
dwOption	db	?
F_SEARCHING	equ	0001h; ������־ֵ
F_STOP		equ	0002h; ֹͣ��־ֵ
szfilterbuf2	db	32 dup(?);�����ļ���׺��ƥ��
szbuf		db	1024 dup(?);������
SzFileName	db	MAX_PATH dup(?)	;·��;֮���Բ���szPath������Ϊ��������֮ͣ��Ҫ������������
szAllFileType   db      1024 dup(?); �ļ���׺����
;#########################################################################
.data
dwsize		dd	0;���������ļ��Ĵ�С�ܺ�
allcount	dd	0;�����ܺ�
count_c		dd	0;C��������
count_cpp	dd	0;cpp��������
count_asm	dd	0;asm��������
count_h		dd	0;h��������
count_inc	dd	0;inc��������
count_other	dd	0;�����Զ����������
file_index	dd	0;filter�������������Ķ�Ӧ���
count_file_array     dd    256 dup(0); ���������256���ļ�����  
count_line_array     dd    256 dup(0);
		