#include "vntlib.h"

KEY uint64 count = 0;

EVENT EVENT_GETFINALCOUNT(uint64 count);

constructor While5(){}

UNMUTABLE
uint64 getFinalCount() {
    uint64 x = 100;
    uint64 res = U256SafeAdd(x, x);
    count = test(res);

    return count;
}

MUTABLE
uint64 test(uint64 res) {
    PrintStr("do While", "do While")

    do {
        count++;
    } while(count != 0);

    EVENT_GETFINALCOUNT(count);
    return count
}
