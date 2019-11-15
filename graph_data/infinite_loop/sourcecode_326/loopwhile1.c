#include "vntlib.h"

KEY uint256 count = 0;

constructor While1(){

}

MUTABLE
uint32 test1(uint256 x){
     
    while(1 == 1) {
        count = x;
    }

     
    while(true) {
        count = x;
    }

    return count;
}
