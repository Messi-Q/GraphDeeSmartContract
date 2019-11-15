#include "vntlib.h"

KEY uint256 count = 0;

constructor While2(){}

MUTABLE
uint256 test1(){
    PrintStr("test()", "test()");

    while (count <= 100) {
        count++;
        PrintUint256T("count:", count);
    }

    return count;
}
