#include "vntlib.h"

KEY uint256 count = 0;

constructor While1(){}

MUTABLE
uint256 test(uint256 x){
    PrintStr("count == x", "count == x");
    count = x;
    while (count < 100) {
        count++;
    }

    return count;
}
