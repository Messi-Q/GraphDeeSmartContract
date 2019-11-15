#include "vntlib.h"

KEY uint256 count = 0;

EVENT EVENT_GETFINALCOUNT(uint256 count);

constructor While5(){
}

MUTABLE
uint32 test1(uint256 res) {

    do {
        count++;
    } while(count != 0);

    EVENT_GETFINALCOUNT(count);
    return count
}

UNMUTABLE
uint32 getFinalCount() {
    uint256 x = 100;
    uint256 res = U256SafeAdd(x, x);
    count = test1(res);

    return count;
}