#include "vntlib.h"

KEY uint16 count = 0;

EVENT EVENT_GETFINALCOUNT(uint16 count);

constructor While5(){
}

MUTABLE
uint16 test1(uint16 res) {

    do {
        count++;
    } while(count != 0);

    EVENT_GETFINALCOUNT(count);
    return count
}

UNMUTABLE
uint16 getFinalCount() {
    uint16 x = 100;
    uint16 res = U256SafeAdd(x, x);
    count = test1(res);

    return count;
}