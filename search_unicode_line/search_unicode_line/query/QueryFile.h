#pragma once

#include "IWriteResult.h"

#include <string>
#include <map>

/**
no thread safe

�����ļ������Һ���
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
	���չ۲��ߣ���������
	*/
	void accept(IWriteResult* visitor);

private:
	void Read();
	/**
	��ȡunicode�ļ�
	*/
	void ReadUnicode(char* content, unsigned int length);   
	/**
	��ȡUTF8�ļ�
	*/
	void ReadUTF8(char* content, unsigned int length);
	/**
	��ȡANSI�ļ�
	*/
	void ReadANSI(char* content, unsigned int length);
	/**
	��ȡ���
	*/
	void calc();
private:
	T_map_uint_string all_line_text_;  //�ļ�������
	T_map_uint_string all_result_;     //�ļ���ѯ���
	std::wstring file_path_;           //����ѯ�ļ�·��
};
