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
	return: �Ƿ������ȡ����д��
	*/
	virtual bool WriteToFile(const std::wstring& content) = 0;
};