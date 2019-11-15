#include "vntlib.h"

KEY uint128 count = 0;

constructor Fallback4() {}

MUTABLE
void test1(uint128 amount){

    for(uint32 i = 1; i< amount; i++) {
        count += i;
    }

}

 
_(){
    PrintStr("fallback", "fallback");
    test1(count);
}