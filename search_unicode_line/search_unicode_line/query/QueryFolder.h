#pragma once

#include "WriteResult.h"

#include <set>
#include <vector>

/**
no thread safe
�����ļ���
*/
class QueryFolder
{
public:
	QueryFolder(const std::wstring& filter)
		: write_file_(L"result.txt")
	{
		CreateFileFilter(filter);
	}

	void CalcUnicodeText(const std::wstring& folder_path);

private:
	/**������׺������*/
	void CreateFileFilter(const std::wstring& filter);
	/**��ȡ���еĿ��ж��ļ�*/
	void GetAllJudgeFile(const std::wstring& folder_path);
	/**�����ļ�*/
	void FilterFile(const std::wstring& file_path);
	/**������*/
	void GetResult();

	std::set< std::wstring >    all_filter_;           //��Ҫ������ļ�����
	std::vector< std::wstring > all_query_file_;       //��Ҫ������ļ�
	WriteResultImpl write_file_;                       //д����
};