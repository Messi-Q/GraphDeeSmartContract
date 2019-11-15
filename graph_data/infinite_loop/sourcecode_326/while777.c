#include "vntlib.h"

KEY uint256 count = 0;

EVENT EVENT_GETFINALCOUNT(uint256 count);

constructor While7(){}

UNMUTABLE
uint256 getFinalCount() {
    uint256 x = 100;
    uint256 res = U256SafeAdd(x, x);
    return test1(res);
}

MUTABLE
uint256 test1(uint256 res) {
    EVENT_GETFINALCOUNT(count);

    while(res == 100) {
        count++;
    }

    return count;
}
