
#include "WriteResult.h"

#include <windows.h>

WriteResultImpl::WriteResultImpl( const std::wstring& file_path )
	: file_path_(file_path)
	, hFile_(INVALID_HANDLE_VALUE)
	, bInitialize_(false)
{
}

bool WriteResultImpl::WriteToFile( const std::wstring& content )
{
	bool bInit = Initialize();
	if (bInit)
	{
		DWORD dwWrited = 0;
		BOOL bSuc = ::WriteFile(hFile_, 
			content.c_str(), 
			content.length()*sizeof(wchar_t), 
			&dwWrited, 
			0);
		return bSuc == TRUE ? true : false;
	}
	return false;
}

bool WriteResultImpl::Initialize()
{
	if (bInitialize_)
	{
		return bInitialize_;
	}
	else
	{
		hFile_ = ::CreateFile(file_path_.c_str(), 
			GENERIC_READ | GENERIC_WRITE, 
			NULL, 
			NULL, 
			CREATE_ALWAYS, 
			FILE_ATTRIBUTE_NORMAL, 
			0);
		if (hFile_ != INVALID_HANDLE_VALUE)
		{
			byte unicode_head[2] = {0xFF, 0xFE};
			DWORD dwWrited = 0;
			::WriteFile(hFile_, &unicode_head[0], 2, &dwWrited, 0);
			SYSTEMTIME sys_time;
			RtlZeroMemory(&sys_time, sizeof(SYSTEMTIME));
			::GetSystemTime(&sys_time);
			wchar_t buf[128];
			::_snwprintf_s(buf, 
				_countof(buf), 
				128-1, 
				L"----UTC:%4dƒÍ%2d‘¬%2d»’£¨%2d:%2d:%2d(by cswuyg)----\r\n",
				sys_time.wYear,
				sys_time.wMonth,
				sys_time.wDay,
				sys_time.wHour,
				sys_time.wMinute,
				sys_time.wSecond);
			std::wstring time_info = buf;
			::WriteFile(hFile_, time_info.c_str(), time_info.length()*sizeof(wchar_t), &dwWrited, 0);
			bInitialize_ = true;
		}
		return bInitialize_;
	}

}

WriteResultImpl::~WriteResultImpl()
{
	Uninitialize();
}

void WriteResultImpl::Uninitialize()
{
	if (hFile_ != INVALID_HANDLE_VALUE)
	{
		::CloseHandle(hFile_);
	}
}

