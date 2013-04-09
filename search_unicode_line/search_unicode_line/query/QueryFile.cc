#include "QueryFile.h"

#include "../utility/utility.h"

#include <Windows.h>
#include <assert.h>

void QueryFile::Read()
{
	HANDLE hFile = ::CreateFile(file_path_.c_str(),
		GENERIC_READ, 
		FILE_SHARE_READ, 
		NULL,
		OPEN_EXISTING,
		FILE_ATTRIBUTE_NORMAL,
		0);
	if (hFile == INVALID_HANDLE_VALUE)
	{
		return;
	}
	DWORD dwHigh = 0;
	DWORD dwLow = ::GetFileSize(hFile, &dwHigh);
	do 
	{
		if (dwLow == 0)
		{
			break;
		}
		HANDLE hMap = ::CreateFileMapping(hFile, NULL, PAGE_READONLY, 0, 0, 0);
		if (hMap == 0)
		{
			break;
		}
		LPVOID lpFile = ::MapViewOfFile(hMap, FILE_MAP_READ, 0, 0, 0);
		if (lpFile == NULL)
		{
			break;
		}
		utility::ePageCode page_code = utility::GetPageCode((char*)lpFile, dwLow);
		if (page_code == utility::e_ANSI)
		{
			ReadANSI((char*)lpFile, dwLow);
		}
		else if (page_code == utility::e_UNICODE)
		{
			ReadUnicode((char*)lpFile, dwLow);
		}
		else if (page_code == utility::e_UTF8)
		{
			ReadUTF8(((char*)lpFile+3), dwLow-3);
		}
		else if (page_code == utility::e_UTF8_NOBOM)
		{
			ReadUTF8((char*)lpFile, dwLow);
		}
		else if (page_code == utility::e_BigEnd)
		{
			//无法处理大端数据
			assert(false);
		}
	} while (false);
	
	::CloseHandle(hFile);
}

void QueryFile::ReadUnicode( char* content, unsigned int length )
{
	WORD* pFile = (WORD*)content;
	int k = 0;
	unsigned int newline = 0;
	unsigned int unicode_length = length / 2;
	for (int i = 1; i != unicode_length-1; ++i)
	{
		if (pFile[i] == 0x000A)
		{
			wchar_t* pbuf = new wchar_t[i - newline + 1];
			::memcpy((char*)pbuf, (char*)&pFile[newline], (i-newline)*sizeof(wchar_t));
			pbuf[i-newline] = L'\0';
			//std::wstring item(pbuf);
			all_line_text_[k++] = pbuf;
			delete [] pbuf;
			//unix下的文件没有0x000d，windows下的文件有0x000d
			if (pFile[i+1] == 0x000D)
			{
				++i;
				newline = i+1;
			}
			newline = i+1;
		}
	}
	if (newline < unicode_length-1)
	{
		wchar_t* pbuf = new wchar_t[unicode_length - newline + 1];
		::memcpy((char*)pbuf, (char*)&pFile[newline], (unicode_length-newline)*sizeof(wchar_t));
		pbuf[unicode_length-newline] = L'\0';
		//std::wstring item(pbuf);
		all_line_text_[k++] = pbuf;
		delete [] pbuf;
	}
}

void QueryFile::ReadUTF8( char* content, unsigned int length )
{
	char* pFile = content;
	int k = 0;
	unsigned int newline = 0;
	unsigned int i = 1;
	for (; i < length-1; ++i)
	{
		if (pFile[i] == 0x0A)
		{
			char* pbuf = new char[i - newline + 1];
			::memcpy((char*)pbuf, (char*)&pFile[newline], (i-newline)*sizeof(char));
			pbuf[i-newline] = L'\0';
			//std::wstring item(pbuf);
			all_line_text_[k++] = utility::str2wstr(pbuf, CP_UTF8);
			delete [] pbuf;
			//unix下的文件没有0x0d，windows下的文件有0x0d
			if (pFile[i+1] == 0x0D)
			{
				++i;
			}
			newline = i+1;
		}
	}
	if (newline < length-1)
	{
		char* pbuf = new char[length - newline + 1];
		::memcpy((char*)pbuf, (char*)&pFile[newline], (length-newline)*sizeof(char));
		pbuf[length-newline] = L'\0';
		//std::wstring item(pbuf);
		all_line_text_[k++] = utility::str2wstr(pbuf, CP_UTF8);
		delete [] pbuf;
	}

}

void QueryFile::ReadANSI( char* content, unsigned int length )
{
	char* pFile = content;
	int k = 1;
	for (int i = 1, newline = 0; i != length-1; ++i)
	{
		if (pFile[i] == 0x0A)
		{
			char* pbuf = new char[i - newline + 1];
			::memcpy((char*)pbuf, (char*)&pFile[newline], (i-newline)*sizeof(char));
			pbuf[i-newline] = L'\0';
			//std::wstring item(pbuf);
			all_line_text_[k++] = utility::str2wstr(pbuf, CP_ACP);
			delete [] pbuf;
			//unix下的文件没有0x0d，windows下的文件有0x0d
			if (pFile[i+1] == 0x0D)
			{
				++i;
				newline = i+1;
			}
			newline = i+1;
		}
	}
}

void QueryFile::calc()
{
	for ( T_map_uint_string::iterator it = all_line_text_.begin(); it != all_line_text_.end(); ++it )
	{
		const wchar_t* content = it->second.c_str();
		std::wstring::size_type size = it->second.size();
		for (std::wstring::size_type i = 0; i < size; ++i)
		{
			//中文的UNICODE编码范围是4e00--9fa5
			if (0x4e00 <= content[i] && content[i] <=  0x9fa5)
			{
				all_result_[it->first] = it->second;
				break;
			}
		}
	}
}

void QueryFile::accept( IWriteResult* visitor )
{
	//没有汉字的文件就不要显示了，不然满屏都是文件
	if (all_result_.size() == 0)
	{
		return;
	}
	std::wstring write_path = file_path_ + L"\r\n";
	visitor->WriteToFile(write_path);
	for (T_map_uint_string::iterator it = all_result_.begin(); it != all_result_.end(); ++it)
	{

		std::wstring write_line = L"\tline ";
		write_line += utility::int2wstr(it->first);
		write_line += L":";
		write_line += it->second;
		write_line += L"\n";
		bool bSuc = visitor->WriteToFile(write_line);
		if (!bSuc)
		{
			break;
		}
	}
}

