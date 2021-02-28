#include "vntlib.h"

 
KEY uint64 count;
EVENT EVENT_TEST(uint64 a);

constructor For3(){}

MUTABLE
uint64 test(){
    EVENT_TEST(count);

    for(uint32 i = 10; i < 100; i++) {
        count++;
        PrintUint256T("count:", count);
    }

    return count;
}
