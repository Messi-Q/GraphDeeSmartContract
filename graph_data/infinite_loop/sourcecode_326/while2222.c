#include "vntlib.h"

KEY uint128 count = 0;

constructor While2(){

}

MUTABLE
uint128 test1(){

    while (count <= 100) {
        count++;
        PrintUint256T("count:", count);
    }

    return count;
}
