#include "vntlib.h"

KEY uint16 count = 0;

constructor While2(){

}

MUTABLE
uint16 test1(){

    while (count <= 100) {
        count++;
        PrintUint16T("count:", count);
    }

    return count;
}
