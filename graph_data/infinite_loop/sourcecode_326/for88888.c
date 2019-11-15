#include "vntlib.h"

 
KEY uint16 count = 0;

constructor For8(){
}

MUTABLE
uint16 test1(){
    for (uint256 i = 100; i > 0; i--) {
        for (uint256 j = i; j < 50; j++) {
            if (j > 100) {
                count = j
                PrintUint256T("remark", j)
            }
        }
    }

    return count;
}
