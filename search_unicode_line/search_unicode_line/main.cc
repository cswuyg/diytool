#include "query/QueryFolder.h"

#include "utility/utility.h"

#include <windows.h>
#include <iostream>

//需要检测有无汉字的文件类型
const wchar_t kAllFileType[] = L"*.cpp;*.c;*.h;*.rc;*.txt";

void test_query()
{
	std::cout << "Input the folder where you want to find the Chinese:";
	std::string strInput;
	std::cin >> strInput;
	QueryFolder obj(kAllFileType);
	obj.CalcUnicodeText(utility::str2wstr(strInput, CP_ACP));
}


int main()
{
	test_query();
	::system("pause");
	return 1;
}