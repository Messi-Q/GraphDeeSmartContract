#include "vntlib.h"

KEY uint64 count = 0;

constructor While1(){

}

MUTABLE
uint64 test(uint64 x){
    PrintStr("While", "while")

    while(true) {
        count = x;
    }

    return count;
}
