#include "generator.h"

#include "../utility/utility.h"
#include "../jsoncpp/include/json/json.h"

#include <assert.h>
#include <Shlwapi.h>


#pragma comment(lib, "shlwapi.lib")

HtmlDocGenerator::HtmlDocGenerator( const std::wstring& config_path )
{
	AnalyzeConfig(config_path);
	ReleaseHtmlFile();
}

void HtmlDocGenerator::AnalyzeConfig( const std::wstring& config_path )
{
	using namespace utility::WYGString;
	using namespace utility::WYGPageCode;
	std::wstring data;
	ReadFile(config_path, data);
	std::string ansi_data = wstr2str(data, CP_ACP);
	Json::Reader jsonReader;
	Json::Value root;
	jsonReader.parse(ansi_data, root);

	std::string in_path = root["input"].asString();
	std::string out_path = root["output"].asString();
	input_path_ = str2wstr(in_path, CP_ACP);
	output_path_ = str2wstr(out_path, CP_ACP);
}


bool HtmlDocGenerator::ReleaseHtmlFile()
{
	if (!::PathIsDirectory(input_path_.c_str()))
	{ //默认输入必须是目录
		return false;
	}

	std::wstring folder_name = ::PathFindFileName(input_path_.c_str());
	ReleaseHtmlHead(folder_name);
	ReleaseHtmlByFolder(input_path_);

	std::wstring html_content = L"<html>";
	html_content += html_head_;
	html_content += L"<body>";
	html_content += html_anchor_;
	html_content += html_content_;
	html_content += L"</body>";
	html_content += L"</html>";

	utility::WYGFile::WriteToDiskA(output_path_, utility::WYGString::wstr2str(html_content, CP_UTF8));
	return true;
}



void HtmlDocGenerator::ReleaseHtmlByFolder( const std::wstring& folder )
{
	if (!::PathFileExists(folder.c_str()))
	{
		return;
	}
	//加标题，加锚
	std::wstring folder_name = ::PathFindFileName(folder.c_str());
	html_content_ += L"<h3><a name=\'";
	html_content_ += folder_name + L"\'>";
	html_content_ += folder_name;
	html_content_ += L"</a>";
	html_content_ += L"</h3>";
	html_content_ += L"<ol>";

	//todo，把锚也做成<ol>树状结构
	html_anchor_ += L"<p><a href=\'#";
	html_anchor_ += folder_name + L"\'>";
	html_anchor_ += folder_name;
	html_anchor_ += L"</a></p>";

	WIN32_FIND_DATA stFindFile;
	RtlZeroMemory(&stFindFile, sizeof(WIN32_FIND_DATA));
	std::wstring search_path = folder;
	search_path += L"\\*.*";
	HANDLE hFinder = ::FindFirstFile(search_path.c_str(), &stFindFile);
	if (hFinder != INVALID_HANDLE_VALUE)
	{
		do 
		{
			if (stFindFile.cFileName[0] != L'.')
			{
				std::wstring file_path = folder;
				file_path += L"\\";
				file_path += stFindFile.cFileName;
				if (stFindFile.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
				{//folder
					html_content_ += L"<li>";
					ReleaseHtmlByFolder(file_path.c_str());
					html_content_ += L"</li>";
				}
				else
				{//file
					std::wstring extension_name = ::PathFindExtension(stFindFile.cFileName);
					if (extension_name != L".txt")
					{
						continue;
					}
					html_content_ += L"<li>";

					html_content_ += L"<h4>";
					html_content_ += ::PathFindFileName(stFindFile.cFileName);
					html_content_ += L"</h4>";
					
					html_content_ += L"<blockquote><pre>";
					std::wstring file_content;
					utility::WYGPageCode::ReadFile(file_path, file_content);
					html_content_ += file_content;
					html_content_ += L"</pre></blockquote>";

					html_content_ += L"</li>";
				}
			}

		} while (::FindNextFile(hFinder, &stFindFile) != 0);
	}

	html_content_ += L"</ol>";
}

void HtmlDocGenerator::ReleaseHtmlHead( const std::wstring& title )
{
	html_head_ = L"<head><meta http-equiv='content-type' content='text/html;charset=utf-8' /><title>";
	html_head_ += title + L"</title>";
}
