#include "vntlib.h"

 
KEY uint64 count;

constructor For6(){}

MUTABLE
uint64 test(){
    PrintStr("For(;;)", "For(;;)")

    for (; ;) {
        count++;
    }

    return count;
}
