#include "vntlib.h"

KEY uint16 count = 0;

constructor While1(){}

MUTABLE
uint16 test1(uint16 x){

    count = x;

    while (count < 100) {
        count++;
    }

    return count;
}
