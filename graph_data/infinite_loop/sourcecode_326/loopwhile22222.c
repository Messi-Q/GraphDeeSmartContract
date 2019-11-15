#include "vntlib.h"

KEY uint16 count = 0;

constructor While2(){
}

MUTABLE
uint16 test1(uint16 x){
    while (count <= 100)
        PrintUint16T("count:", count);
    count++;

    return count
}
