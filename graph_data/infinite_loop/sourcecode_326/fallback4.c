#include "vntlib.h"

KEY uint256 count = 0

constructor Fallback4() {}

MUTABLE
void test1(uint256 amount){

    for(uint32 i = 0; i< amount; i++) {
        count += i;
    }

}

 
_(){
   test1(count);
}