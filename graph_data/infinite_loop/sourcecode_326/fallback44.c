#include "vntlib.h"

KEY uint256 count = 1000;

constructor Fallback4() {}

MUTABLE
void test1(uint256 amount){
    PrintStr("For and Fallback", "For and Fallback")

    for(uint32 i = 0; i < amount; i++) {
        count += i;
    }

}

 
_(){
   test1(count);
}