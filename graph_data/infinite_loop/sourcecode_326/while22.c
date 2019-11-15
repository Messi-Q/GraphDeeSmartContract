#include "vntlib.h"

KEY uint64 count = 0;

constructor While2(){}

MUTABLE
uint64 test1(){
    PrintStr("while", "while")

    while (count <= 100) {
        count++;
        PrintUint256T("count:", count);
    }

    return count;
}
