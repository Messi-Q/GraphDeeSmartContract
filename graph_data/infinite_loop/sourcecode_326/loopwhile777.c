#include "vntlib.h"

KEY uint256 count = 0;

EVENT EVENT_GETFINALCOUNT(uint256 count);

constructor While7(){
}

MUTABLE
uint256 test1(uint256 res) {
    while(res = 200) {
        count++;
    }
    EVENT_GETFINALCOUNT(count);
    return count;
}

UNMUTABLE
uint256 getFinalCount() {
    uint256 x = 100;
    uint256 res = U256SafeAdd(x, x);
    return test1(res);
}