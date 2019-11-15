#include "vntlib.h"

KEY uint128 count = 0;

constructor While2(){
}

MUTABLE
uint128 test1(uint128 x){
    while (count <= 100)
        PrintUint128T("count:", count);
    count++;

    return count
}
