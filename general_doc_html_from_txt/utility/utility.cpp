#include "utility.h"
#include <new.h>
#include <Shlwapi.h>
#include <assert.h>

#pragma comment(lib, "shlwapi.lib")

namespace utility
{
	namespace WYGFile
	{
		BOOL WriteToDiskA( const std::wstring& strFilePath, std::string& data )
		{
			BOOL bRet = FALSE;
			HANDLE hFile = INVALID_HANDLE_VALUE;
			do 
			{
				std::wstring strFilePathTmp = strFilePath + L".tmp";
				hFile = ::CreateFile(strFilePathTmp.c_str(), GENERIC_WRITE | GENERIC_READ, FILE_SHARE_READ, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
				IF_BREAK(hFile == INVALID_HANDLE_VALUE);
				DWORD dwWrite = 0;
				DWORD dwLength = (DWORD)data.length();
				::WriteFile(hFile, data.c_str(), dwLength, &dwWrite, NULL);
				IF_BREAK(dwWrite != dwLength);
				::CloseHandle(hFile);
				hFile = INVALID_HANDLE_VALUE;
				bRet = ::MoveFileEx(strFilePathTmp.c_str(), strFilePath.c_str(), MOVEFILE_COPY_ALLOWED|MOVEFILE_REPLACE_EXISTING|MOVEFILE_WRITE_THROUGH);
			} while (FALSE);

			if (hFile != INVALID_HANDLE_VALUE)
			{
				::CloseHandle(hFile);
			}
			return bRet;
		}

		BOOL ReadFromDiskA( const std::wstring& strFilePath, std::string& data )
		{
			BOOL bRet = FALSE;
			HANDLE hFile = INVALID_HANDLE_VALUE;
			do 
			{
				hFile = ::CreateFile(strFilePath.c_str(), GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
				IF_BREAK(hFile == INVALID_HANDLE_VALUE);

				DWORD nCount = ::GetFileSize(hFile, NULL);
				if (nCount == INVALID_FILE_SIZE)
				{
					//DWORD dwErr = GetLastError();
					break;
				}
				DWORD nReturnCount = 0;
				char* buf = new char[nCount+1];
				::memset(buf, 0, nCount + 1);
				::ReadFile(hFile, buf, nCount, &nReturnCount, NULL);
				if (nReturnCount != nCount)
				{
					delete [] buf;
					break;
				}
				data = buf;
				delete [] buf;

				::CloseHandle(hFile);
				hFile = INVALID_HANDLE_VALUE;
				bRet = TRUE;
			} while (FALSE);

			if (hFile != INVALID_HANDLE_VALUE)
			{
				::CloseHandle(hFile);
			}
			return bRet;
		}
	} //WYGFile
	namespace WYGString
	{
		std::wstring int2wstr( int nData )
		{
			wchar_t wchBuf[32] = L"";
			::swprintf_s(wchBuf, L"%d", nData);
			return wchBuf;
		}

		std::string wstr2str( const std::wstring& strInput, int nEncode )
		{
			if (strInput.empty())
			{
				return "";
			}
			int nLength = ::WideCharToMultiByte(nEncode, 0, strInput.c_str(), -1, 0, 0, 0, 0);
			char* buf = new char[nLength + 1];
			::memset(buf, 0, nLength + 1);
			::WideCharToMultiByte(nEncode, 0, strInput.c_str(), -1, buf, nLength, 0, 0);
			std::string strResult = buf;
			delete[] buf;
			return strResult;
		}

		std::wstring str2wstr( const std::string& strInput, int nEncode )
		{
			if( strInput.empty() )
			{
				return L"";
			}
			int nLength = ::MultiByteToWideChar( nEncode, 0, strInput.c_str(), -1, 0, 0 );
			wchar_t* buf = new wchar_t[nLength + 1];
			::memset(buf, 0, ( nLength + 1 ) * 2);
			::MultiByteToWideChar(nEncode, 0, strInput.c_str(), -1, buf, nLength);
			std::wstring strResult = buf;
			delete[] buf;
			return strResult;
		}
	}

	namespace WYGPageCode
	{
		ePageCode GetPageCode( const char* content, int length )
		{
			ePageCode ret = e_ANSI;
			if (length >= 2)
			{
				byte b0 = *content;
				byte b1 = *(content+1);
				byte b2 = (length >= 3 ? *(content+2) : 0);
				if (b0 == 0xFF && b1 == 0xFE)
				{
					ret = e_UNICODE;
				}
				else if (b0 == 0xFE && b1 == 0xFF)
				{
					ret = e_BigEnd;
				}
				else if (b0 == 0xEF && b1 == 0xBB && b2 == 0xBF)
				{
					ret = e_UTF8;
				}
				else if (IsNoBomUTF8Data(content, length))
				{
					ret = e_UTF8_NOBOM;
				}
			}
			return ret;
		}

		bool IsNoBomUTF8Data( const char* content, int length )
		{
			int i = 0;
			int size = length;

			while(i < size)
			{
				int step = 0;
				if((content[i] & 0x80) == 0x00)
				{
					step = 1;
				}
				else if((content[i] & 0xe0) == 0xc0)
				{
					if(i + 1 >= size) return false;
					if((content[i + 1] & 0xc0) != 0x80)
					{
						return false;
					}
					step = 2;
				}
				else if((content[i] & 0xf0) == 0xe0)
				{
					if(i + 2 >= size)
					{
						return false;
					}
					if((content[i + 1] & 0xc0) != 0x80) 
					{
						return false;
					}
					if((content[i + 2] & 0xc0) != 0x80)
					{
						return false;
					}
					step = 3;
				}
				else
				{
					return false;
				}

				i += step;
			}

			if(i == size) 
			{
				return true;
			}
			return false;
		}

		bool ReadFile( const std::wstring& strFilePath, std::wstring& text )
		{
			if (!::PathFileExists(strFilePath.c_str()) || ::PathIsDirectory(strFilePath.c_str()))
			{
				return false;
			}
			HANDLE hFile = ::CreateFile(strFilePath.c_str(),
				GENERIC_READ, 
				FILE_SHARE_READ, 
				NULL,
				OPEN_EXISTING,
				FILE_ATTRIBUTE_NORMAL,
				0);
			if (hFile == INVALID_HANDLE_VALUE)
			{
				return false;
			}
			DWORD dwHigh = 0;
			DWORD dwLow = ::GetFileSize(hFile, &dwHigh);
			if (dwLow == 0)
			{
				::CloseHandle(hFile);
				return false;
			}

			HANDLE hMap = ::CreateFileMapping(hFile, NULL, PAGE_READONLY, 0, 0, 0);
			::CloseHandle(hFile);
			if (hMap == 0)
			{
				return false;
			}
			LPVOID lpFile = ::MapViewOfFile(hMap, FILE_MAP_READ, 0, 0, 0);
			::CloseHandle(hMap);
			if (lpFile == NULL)
			{
				::CloseHandle(hMap);
				return false;
			}
			ePageCode page_code = GetPageCode((char*)lpFile, dwLow);
			if (page_code == e_ANSI)
			{
				ReadANSI((char*)lpFile, dwLow, text);
			}
			else if (page_code == e_UNICODE)
			{
				ReadUnicode((char*)lpFile+2, dwLow-2, text);
			}
			else if (page_code == e_UTF8)
			{
				ReadUTF8(((char*)lpFile+3), dwLow-3, text);
			}
			else if (page_code == e_UTF8_NOBOM)
			{
				ReadUTF8((char*)lpFile, dwLow, text);
			}
			else if (page_code == e_BigEnd)
			{
				//无法处理大端数据
				assert(false);
			}
			::UnmapViewOfFile(lpFile);
			return true;
		}

		void ReadUnicode( char* content, unsigned int length, std::wstring& text )
		{
			text = std::wstring(content, content+length);
		}

		void ReadUTF8( char* content, unsigned int length, std::wstring& text )
		{
			std::string input = std::string(content, content + length);
			text = WYGString::str2wstr(input, CP_UTF8);	
		}

		void ReadANSI( char* content, unsigned int length, std::wstring& text )
		{
			std::string input = std::string(content, content + length);
			text = WYGString::str2wstr(input, CP_ACP);	
		}

	}
}