#pragma once
/*
2012-12-10 始
cswuyg@gmail.com
*/
#include <string>
#include <windows.h>
#define IF_BREAK(x) if (x) break;


namespace utility
{
	/**读写文件相关*/
	namespace WYGFile
	{
		BOOL WriteToDiskA(const std::wstring& strFilePath, std::string& data);
		BOOL ReadFromDiskA(const std::wstring& strFilePath, std::string& data);
	}
	/**字符串处理相关*/
	namespace WYGString
	{
		std::wstring int2wstr(int nData);
		std::string wstr2str(const std::wstring& strInput, int nEncode);
		std::wstring str2wstr(const std::string& strInput, int nEncode);
	}
	/**编码相关*/
	namespace WYGPageCode
	{
		enum ePageCode
		{
			e_ANSI,         //ANSI编码
			e_UNICODE,      //UNICODE
			e_UTF8,         //UTF8
			e_UTF8_NOBOM,   //UTF8 无标志
			e_BigEnd        //大端 无标志 
		};
		bool IsNoBomUTF8Data(const char* content, int length);
		ePageCode GetPageCode(const char* content, int length);
		bool ReadFile(const std::wstring& strFilePath, std::wstring& text);
		void ReadUnicode(char* content, unsigned int length, std::wstring& text);   
		void ReadUTF8(char* content, unsigned int length, std::wstring& text);
		void ReadANSI(char* content, unsigned int length, std::wstring& text);
	}
}