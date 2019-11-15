#include "vntlib.h"

KEY uint256 count = 0;

EVENT EVENT_GETFINALCOUNT(uint256 count);

constructor While4(){
}

MUTABLE
uint256 test1(uint256 res) {
    PrintStr("test1()", "test1()")
    while(count < res) {
        count++;
        if(count > 100) {
            count = 0;
        }
    }
    return count
}

UNMUTABLE
uint256 getFinalCount() {
    uint256 x = 100;
    uint256 res = U256SafeAdd(x, x);
    EVENT_GETFINALCOUNT(count);
    return test1(res);
}