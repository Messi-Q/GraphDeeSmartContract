#include "vntlib.h"

KEY uint64 count = 0;

EVENT EVENT_GETFINALCOUNT(uint256 count);

constructor While4(){}

UNMUTABLE
uint64 getFinalCount() {
    uint256 x = 100;
    uint256 res = U256SafeAdd(x, x);
    EVENT_GETFINALCOUNT(count);
    return test(res);
}

MUTABLE
uint64 test(uint256 res) {
    PrintStr("while", "while")

    while(count < res) {
        count++;
        if(count > 100) {
            count = 0;
        }
    }

    return count
}
