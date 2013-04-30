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
	//后续优化：把空文件夹过滤掉，先抽取所有的文件，然后再生成html
	void ReleaseHtmlByFolder(const std::wstring& folder);
	void ReleaseHtmlHead(const std::wstring& title);
private:
	std::wstring input_path_;
	std::wstring output_path_;
	std::wstring html_content_;
	std::wstring html_anchor_;
	std::wstring html_head_;
};
