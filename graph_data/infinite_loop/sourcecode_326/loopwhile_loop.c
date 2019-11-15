#include "vntlib.h"

KEY uint256 count = 0;

constructor While_loop(){}

MUTABLE
uint256 test(uint256 x){
    uint256 a = x;

    while(a > 0) {
        if (a == 100) {
            return x;
        }

        if (a == 1) {
           break;
        }
        a -= 1;
    }

    return a;
}
