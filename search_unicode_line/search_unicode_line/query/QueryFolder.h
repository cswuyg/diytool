#pragma once

#include "WriteResult.h"

#include <set>
#include <vector>

/**
no thread safe
检阅文件夹
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
	/**创建后缀名过滤*/
	void CreateFileFilter(const std::wstring& filter);
	/**获取所有的可判断文件*/
	void GetAllJudgeFile(const std::wstring& folder_path);
	/**过滤文件*/
	void FilterFile(const std::wstring& file_path);
	/**计算结果*/
	void GetResult();

	std::set< std::wstring >    all_filter_;           //需要处理的文件类型
	std::vector< std::wstring > all_query_file_;       //需要处理的文件
	WriteResultImpl write_file_;                       //写入结果
};