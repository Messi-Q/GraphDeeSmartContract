#include "vntlib.h"

KEY uint256 count = 0;

EVENT EVENT_GETFINALCOUNT(uint256 count);

constructor While4(){
}

MUTABLE
uint32 test1(uint256 res) {

    while(count < res) {
        count++;
        if(count > 100) {
            count = 0;
        }
    }

    return count
}

UNMUTABLE
uint32 getFinalCount() {
    uint256 x = 100;
    uint256 res = U256SafeAdd(x, x);
    EVENT_GETFINALCOUNT(count);
    return test1(res);
}