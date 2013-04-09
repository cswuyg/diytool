#pragma once

#include "IWriteResult.h"

#include <string>
#include <map>

/**
no thread safe

检阅文件，查找汉字
*/
class QueryFile
{
public:
	typedef std::map< unsigned int, std::wstring > T_map_uint_string;
	QueryFile(const std::wstring& file_path)
		: file_path_(file_path)
	{
		Read();
		calc();
	}
	
	/**
	接收观察者，访问数据
	*/
	void accept(IWriteResult* visitor);

private:
	void Read();
	/**
	读取unicode文件
	*/
	void ReadUnicode(char* content, unsigned int length);   
	/**
	读取UTF8文件
	*/
	void ReadUTF8(char* content, unsigned int length);
	/**
	读取ANSI文件
	*/
	void ReadANSI(char* content, unsigned int length);
	/**
	获取结果
	*/
	void calc();
private:
	T_map_uint_string all_line_text_;  //文件所有行
	T_map_uint_string all_result_;     //文件查询结果
	std::wstring file_path_;           //被查询文件路径
};
