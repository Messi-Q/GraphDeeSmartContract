#include "vntlib.h"

KEY uint128 count = 0;

EVENT EVENT_GETFINALCOUNT(uint128 count);

constructor While7(){
}

MUTABLE
uint128 test1(uint128 res) {
    while(res == 100) {
        count++;
    }
    EVENT_GETFINALCOUNT(count);
    return count
}

UNMUTABLE
uint128 getFinalCount() {
    uint128 x = 100;
    uint128 res = U256SafeAdd(x, x);
    return test1(res);
}