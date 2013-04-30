#pragma once

#include <string>

/**
2013.4.30
cswuyg@gmail.com
*/
class HtmlDocGenerator
{

public:
	HtmlDocGenerator(const std::wstring& config_path);
private:
	void AnalyzeConfig(const std::wstring& config_path);
	bool ReleaseHtmlFile();
	//�����Ż����ѿ��ļ��й��˵����ȳ�ȡ���е��ļ���Ȼ��������html
	void ReleaseHtmlByFolder(const std::wstring& folder);
	void ReleaseHtmlHead(const std::wstring& title);
private:
	std::wstring input_path_;
	std::wstring output_path_;
	std::wstring html_content_;
	std::wstring html_anchor_;
	std::wstring html_head_;
};
