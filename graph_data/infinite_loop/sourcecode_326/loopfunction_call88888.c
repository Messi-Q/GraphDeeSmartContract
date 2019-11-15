#include "vntlib.h"

constructor Function8(){}

MUTABLE
uint16 test1(uint16 a){
    uint16 v = a;
    uint16 c = test2(a, v)
    return c;
}

MUTABLE
uint16 test2(uint16 b, uint16 c){
    uint32 i = 0;
    uint256 e = U256SafeAdd(b, c);
    do {
        i++;
        e += i;
    } while(e > 0);

    return i;
}


