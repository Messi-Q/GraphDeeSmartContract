#include "vntlib.h"

KEY uint256 count = 0;

EVENT EVENT_GETFINALCOUNT(uint256 count);

constructor While5(){}

MUTABLE
uint256 test1(uint256 res) {
    EVENT_GETFINALCOUNT(count);

    while(count < res) {
        count++;
    }

    return count；
}

UNMUTABLE
uint256 getFinalCount() {
    uint256 x = 100;
    uint256 res = U256SafeAdd(x, x);
    count = test1(res);

    return count;
}