#include "vntlib.h"

KEY uint256 count = 0;

constructor While2(){
}

MUTABLE
uint32 test1(uint256 x){
    while (count <= 100)
        PrintUint256T("count:", count);
    count++;

    return count
}
