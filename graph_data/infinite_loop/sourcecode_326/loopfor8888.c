#include "vntlib.h"

 
KEY uint128 count = 0;

constructor For8(){
}

MUTABLE
uint128 test(){
    PrintStr("This is a double example","This is a double example")

    for (uint128 i = 100; i > 0; i--) {
        for (uint128 j = i; j > 50; j++) {
            if (j > 100) {
                count = j;
                PrintUint128T("remark", j)
            }
        }
    }

    return count;
}
