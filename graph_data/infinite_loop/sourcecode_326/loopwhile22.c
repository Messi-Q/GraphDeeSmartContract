#include "vntlib.h"

KEY uint64 count = 0;

constructor While2(){}

MUTABLE
uint64 test1(uint256 x){
    PrintStr("while", "while")

    while (count <= 100)
        PrintUint256T("count:", count);
    count++;

    return count
}
