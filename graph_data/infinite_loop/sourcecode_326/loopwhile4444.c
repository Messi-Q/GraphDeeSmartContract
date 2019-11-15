#include "vntlib.h"

KEY uint256 count = 0;

EVENT EVENT_GETFINALCOUNT(uint256 count);

constructor While4(){
}

MUTABLE
uint128 test1(uint256 res) {
    while(count < res) {
        count++;
        if(count > 100) {
            count = 0;
        }
    }

    EVENT_GETFINALCOUNT(count);

    return count;
}

UNMUTABLE
uint128 getFinalCount() {
    uint128 x = 100;
    uint128 res = U256SafeAdd(x, x);

    return test1(res);
}