#pragma once

#include "IWriteResult.h"

#include <windows.h>

class WriteResultImpl : public IWriteResult
{
public:
	WriteResultImpl(const std::wstring& file_path);
	~WriteResultImpl();

	virtual bool WriteToFile(const std::wstring& content);
private:
	bool Initialize();
	void Uninitialize();
private:
	std::wstring file_path_;          //写入结果的文件
	HANDLE hFile_;                    //文件句柄
	bool bInitialize_;                //是否已经初始化
};
