#include "vntlib.h"

KEY uint128 count = 0;

constructor While1(){

}

MUTABLE
uint128 test1(uint256 x){

    count = x;

    while (count < 100) {
        count++;
    }

    return count;
}
