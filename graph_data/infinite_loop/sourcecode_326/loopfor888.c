#include "vntlib.h"

 
KEY uint256 count = 0;

constructor For8(){
}

MUTABLE
uint256 test(){
    PrintStr("This is a double example","This is a double example")

    for (uint256 i = 100; i > 0; i--) {
        for (uint256 j = i; j > 50; j++) {
            if (j > 100) {
                count = j;
                PrintUint256T("remark", j)
            }
        }
    }

    return count;
}
