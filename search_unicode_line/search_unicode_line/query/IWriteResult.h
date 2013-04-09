#pragma once

#include <string>

/**
visitor pattern
visitor interface
*/
class IWriteResult
{
public:
	/**
	return: 是否继续获取数据写入
	*/
	virtual bool WriteToFile(const std::wstring& content) = 0;
};