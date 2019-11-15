#include "vntlib.h"

KEY uint16 count = 0;

EVENT EVENT_GETFINALCOUNT(uint16 count);

constructor While4(){
}

MUTABLE
uint16 test1(uint16 res) {

    while(count < res) {
        count += 2;
    }

    return count
}

UNMUTABLE
uint16 getFinalCount() {
    uint16 x = 1000;
    uint16 res = U256SafeAdd(x, x);
    EVENT_GETFINALCOUNT(count);
    return test1(res);
}