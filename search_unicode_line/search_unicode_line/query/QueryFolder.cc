#include "QueryFolder.h"
#include "QueryFile.h"

#include <windows.h>
#include <algorithm>
#include <shlwapi.h>
#pragma comment(lib, "shlwapi.lib")

void QueryFolder::CreateFileFilter( const std::wstring& filter )
{
	if (filter.empty())
	{
		return;
	}
	std::wstring wstrFilter = filter;
	transform(wstrFilter.begin(), wstrFilter.end(), wstrFilter.begin(), toupper);
	while (true)
	{
		std::wstring::size_type pos = wstrFilter.find_first_of(L';');
		if (pos != std::wstring::npos)
		{
			std::wstring wstrFile = wstrFilter.substr(0, pos);
			wstrFilter = wstrFilter.substr(pos+1, wstrFilter.size()-(pos+1));
			all_filter_.insert(wstrFile);
		}
		else 
		{
			all_filter_.insert(wstrFilter);
			break;
		}
	}
}

void QueryFolder::FilterFile( const std::wstring& file_path )
{
	if (file_path.empty())
	{
		return;
	}

	std::wstring::size_type npos = file_path.find_last_of(L'.');
	if (npos != std::wstring::npos)
	{
		std::wstring wstrExt = L"*";
		wstrExt += file_path.substr(npos, file_path.size() - npos);
		transform(wstrExt.begin(), wstrExt.end(), wstrExt.begin(), toupper);
		std::set< std::wstring>::iterator iter = all_filter_.find(wstrExt);
		if (iter != all_filter_.end())
		{
			all_query_file_.push_back(file_path);
		}
	}
}

void QueryFolder::CalcUnicodeText( const std::wstring& folder_path )
{
	BOOL bExist = ::PathFileExists(folder_path.c_str());
	if (bExist)
	{
		GetAllJudgeFile(folder_path);
		GetResult();
	}
}

void QueryFolder::GetAllJudgeFile( const std::wstring& folder_path )
{
	if (!::PathFileExists(folder_path.c_str()))
	{
		return;
	}
	WIN32_FIND_DATA stFindFile;
	RtlZeroMemory(&stFindFile, sizeof(WIN32_FIND_DATA));
	std::wstring wstrSearchPath = folder_path;
	wstrSearchPath += L"\\*.*";
	HANDLE hFinder = ::FindFirstFile(wstrSearchPath.c_str(), &stFindFile);
	if (hFinder != INVALID_HANDLE_VALUE)
	{
		do 
		{
			if (stFindFile.cFileName[0] != L'.')
			{
				std::wstring wstrFilePath = folder_path;
				wstrFilePath += L"\\";
				wstrFilePath += stFindFile.cFileName;
				if (stFindFile.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
				{
					GetAllJudgeFile(wstrFilePath.c_str());
				}
				else
				{
					FilterFile(wstrFilePath.c_str());
				}
			}

		} while (::FindNextFile(hFinder, &stFindFile) != 0);
	}
}

void QueryFolder::GetResult()
{
	for (std::vector< std::wstring >::iterator it = all_query_file_.begin(); it != all_query_file_.end(); ++it)
	{
		QueryFile obj(*it);
		obj.accept(&write_file_);
	}
}
