#include "vntlib.h"

KEY uint128 count = 0;

EVENT EVENT_GETFINALCOUNT(uint256 count);

constructor While4(){
}

MUTABLE
uint128 test1(uint256 res) {
    EVENT_GETFINALCOUNT(count);

    while(count < res) {
        count += 2;
    }

    return count
}

UNMUTABLE
uint128 getFinalCount() {
    uint128 x = 1000;
    uint128 res = U256SafeAdd(x, x);
    return test1(res);
}