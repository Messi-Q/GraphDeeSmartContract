#include "vntlib.h"

KEY mapping (address, uint256) balances;
KEY string name;
KEY uint8 decimals;
KEY string symbol;
KEY address owner;

constructor Function6(uint256 _initialAmount, string, uint8 _decimalUnits, string _tokenSymbol){
    address from = GetSender();
    balances.key = from;
    balances.value = _initialAmount;
    name = _tokenName;
    decimals = _decimalUnits;
    symbol = _tokenSymbol;
}

MUTABLE
bool transfer(address _to, uint256 _value) {
     address sender = GetSender();
     balances.key = sender;
     Require(balances.value >= _value, "balances > value");
     balances.value -= _value;

     balances.key = sender;
     balances.value += _value;
     SendFromContract(_to, _value);
     balanceOf(_to);
     balanceOf(sender);

     return true;
}

MUTABLE
void test(address _to, uint256 _value) {
    owner = GetSender();
    if (owner != _to) {
        transfer(_to, _value);
    }

}

MUTABLE
uint64 balanceOf(address _owner) {
    balances.key = _owner;
    PrintInt64T("value", balances.value);
    return balances.value;
}

