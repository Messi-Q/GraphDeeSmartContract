#include "vntlib.h"

KEY uint256 count = 0;

EVENT EVENT_GETFINALCOUNT(uint256 count);

constructor While6(){
}

UNMUTABLE
uint32 getFinalCount() {
    uint256 x = 100;
    uint256 res = U256SafeAdd(x, x);

    uint32 result = test(res * random(), res);

    return result;
}

MUTABLE
uint64 test(uint32 a, uint32 b) {
    PrintStr("while", "while")

    while (b < a) {
        count++;
        a -= b;
    }

    return count
}

uint64 random()
{
    uint64 time = GetTimestamp();
    PrintUint64T("get time", time);
    string time_sha3 = SHA3(SHA3(SHA3(FromU64(time))));
    PrintStr("get time sha3", time_sha3);
    uint64 index = time % 63 + 2;
    PrintUint64T("get index", index);
    uint64 gas = GetGas() % 64 + 2;
    PrintUint64T("get gas", gas);
    uint64 random_a = (uint64)time_sha3[index];
    PrintUint64T("get random_a", random_a);
    uint64 random_b = (uint64)time_sha3[index + 1];
    PrintUint64T("get random_b", random_b);
    uint64 random_c = random_a * random_b * gas % 101;
    PrintUint64T("get result", random_c);
    return random_c;
}