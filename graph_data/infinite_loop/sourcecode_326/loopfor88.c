#include "vntlib.h"

 
KEY uint64 count;

constructor For8(){}

MUTABLE
uint64 test1(){
    PrintStr("Double For", "Double For")

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
