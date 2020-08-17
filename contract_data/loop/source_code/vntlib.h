// vnt合约标准库
// 所有vnt合约能够调用的方法都会在标准库中定义
// 编写合约代码时需要引用标准库
// vnt-wasm虚拟机中实现了标准库中的方法

//###################################################################

#include <stdbool.h> //支持bool类型
#ifndef _DEFINE_VNTLIB_H
#define _DEFINE_VNTLIB_H
#define VNT_WASM_EXPORT __attribute__((visibility("default"))) //导出方法
#define MUTABLE VNT_WASM_EXPORT //定义需要导出且修改状态变量的方法
#define UNMUTABLE                                                              \
  VNT_WASM_EXPORT //定义需要导出的方法，该方法可以读取状态变量但不会修改状态变量
#define EVENT void //空宏，声明Event函数时用的关键字
#define indexed //空宏，声明Event函数时，定义需要索引的参数时用到的关键字
#define CALL    //空宏，声明跨合约调用函数时用到的关键字
#define KEY volatile                      //宏，声明全局变量
#define constructor VNT_WASM_EXPORT void  //空宏，声明构造函数时使用
#define _ VNT_WASM_EXPORT void Fallback   //宏，fallback函数符号
#define $_ VNT_WASM_EXPORT void $Fallback //宏，payable fallback函数符号
#define N(name) (#name) //宏，将输入直接转化为字符串的形式
#define CAT(n) n##n
#define U256(n) ("u2561537182776" #n)      //声明uint256类型时使用的宏
#define Address(n) ("address1537182776" n) //声明address类型时使用的宏

#define now GetTimestamp() //获取区块生成的时间戳

// Time units
//#define years(n) (60 * 60 * 24 * 365 * n)UL;
#define years(n) n * 31536000UL
//#define weeks(n) (60 * 60 * 24 * 7 * n)UL;
#define weeks(n) n * 604800UL
//#define days(n) (60 * 60 * 24 * n)UL;
#define days(n) n * 86400UL
//#define hours(n) (60 * 60 * n)UL;
#define hours(n) n * 3600UL
//#define minutes(n) (60 * n)UL;
#define minutes(n) n * 60UL
// seconds为基本单位
#define seconds(n) n * 1UL

//以下为合约支持的类型的定义
typedef unsigned long long uint64;
typedef unsigned long uint32;
typedef long long int64;
typedef long int32;
typedef char *string;
// uint256其实是char数组
typedef char *uint256;
typedef char *address;

//二次编译时用到的类型标记
#define TY_INT32 1
#define TY_INT64 2
#define TY_UINT32 3
#define TY_UINT64 4
#define TY_UINT256 5
#define TY_STRING 6
#define TY_ADDRESS 7
#define TY_BOOL 8
#define TY_POINTER 9

//获取交易发起者地址
address GetSender();
//在跨合约调用时，获取交易最初的发起者地址
address GetOrigin();
//获取合约创建、调用时，同时发生的vnt转账值，单位为wei
uint256 GetValue();
//获取某个地址的vnt余额，单位为wei
uint256 GetBalanceFromAddress(address addr);
//获取当前正在执行合约的地址
address GetContractAddress();
//获取区块hash
string GetBlockHash(uint64 blocknumber);
//获取区块高度
uint64 GetBlockNumber();
//获取区块生成的时间戳
uint64 GetTimestamp();
//获取区块生产者的地址
address GetBlockProduser();
// SHA3加密运算,返回以0x开头的十六进制字符串
string SHA3(string data);
// Ecrecover,参数hash,v,r,s都需要转化成十六进制字符串
// example
// Ecrecover("0x8309e99c09154c8f03d373c270965cf6d2be0af1fc1395e518596c4d7945b989",\
"0x1c","0xdd3d526fb1154524d4c61a9e673d4bfc6fcc9fdcce39108a8486437196dd828b","0x5d7b80ae2985f43a817e1043ac02f6d421e9704b9bb31f4c3211aac9493d0d91")
address Ecrecover(string hash, string v, string r, string s);
//获取剩余GAS
uint64 GetGas();
//获取当前交易的GasLimit
uint64 GetGasLimit();
//判断条件，如果失败则返回msg，并且交易失败。该函数通常用来调试，正式环境请使用require
void Assert(bool condition, string msg);
//交易回滚
void Revert(string msg);
//判断条件是否成立，如果失败则交易失败
void Require(bool condition, string msg) {
  if (condition != true) {
    Revert(msg);
  }
}

//合约向addr转账，转账金额为amount，单位为wei,转账失败会revert,消耗2300gas
void SendFromContract(address addr, uint256 amount);
//合约向addr转账，转账金额为amount，单位为wei,转账失败返回false,消耗2300gas
bool TransferFromContract(address addr, uint256 amount);

//将int64的数值转化为字符串
string FromI64(int64 value);
//将uint64的数值转化为字符串
string FromU64(uint64 value);
//将字符串转化为int64
int64 ToI64(string value);
//将字符串转化为uint64
uint64 ToU64(string value);
//连接两个字符串
string Concat(string str1, string str2);
//判断两个字符串是否相等
bool Equal(char *str1, char *str2);

//以下为调试函数，用于在合约函数中打印一些变量，其中remark为提示文件，后面的变量为打印对象
//打印一个地址变量
void PrintAddress(string remark, address a);
//打印一个字符串变量
void PrintStr(string remark, string s);
//打印一个uint64数字
void PrintUint64T(string remark, uint64 num);
//打印一个uint32数字
void PrintUint32T(string remark, uint32 num);
//打印一个int64数字
void PrintInt64T(string remark, int64 num);
//打印一个int32数字
void PrintInt32T(string remark, int32 num);
void PrintUint256T(string remark, uint256 num);

//将地址字符串转化成地址
address AddressFrom(string addrStr);
//将地址转化成字符串
string AddressToString(address addr);
//将字符串转成uint256类型
uint256 U256From(string u256Str);
//将uint256类型转成字符串
string U256ToString(uint256 u256);

//这是一个mapping类型的宏，用于定义一个mapping变量，
//其中key_type为key类型，val_type为value类型
#define mapping(key_type, val_type)                                            \
  struct {                                                                     \
    key_type key;                                                              \
    val_type value;                                                            \
    uint64 mapping1537182776;                                                  \
  }

//这是一个array类型的宏，用于定义一个array变量，
//其中val_type为数组元素类型
#define array(val_type)                                                        \
  struct {                                                                     \
    uint64 index;                                                              \
    val_type value;                                                            \
    uint64 length;                                                             \
    uint64 array1537182776;                                                    \
  }

//以下几个指令为全局变量相关指令，不用在合约中显式
//的使用这些指令，而是在二次编译的时候会自动生成

//用于注册全局变量
void AddKeyInfo(uint64 value_address, int32 value_type, uint64 key_address,
                int32 key_type, bool is_array_index);
//写全局变量
void WriteWithPointer(uint64 offset, uint64 baseaddr);
//读全局变量
void ReadWithPointer(uint64 offset, uint64 baseaddr);
//用于对全局变量进行初始化
void InitializeVariables();

// ####math function
// uint64位的Pow运算
uint64 Pow(uint64 x, uint64 y);

//以下为uint256类型的数学运算函数
// UINT256
// uint64转成uint256
uint256 U256FromU64(uint64 x);
// int64转成uint256
uint256 U256FromI64(int64 x);
//加法
uint256 U256_Add(uint256 x, uint256 y);
//减法
uint256 U256_Sub(uint256 x, uint256 y);
//乘法
uint256 U256_Mul(uint256 x, uint256 y);
//除法
uint256 U256_Div(uint256 x, uint256 y);
//取余
uint256 U256_Mod(uint256 x, uint256 y);
//Pow
uint256 U256_Pow(uint256 x, uint256 y);
//Left shift
uint256 U256_Shl(uint256 value, uint256 shift);
//Right shift
uint256 U256_Shr(uint256 value, uint256 shift);
//And
uint256 U256_And(uint256 x, uint256 y);
//Or
uint256 U256_Or(uint256 x, uint256 y);
//Xor
uint256 U256_Xor(uint256 x, uint256 y);

//比较运算
// Cmp compares x and y and returns:
//
//   -1 if x <  y
//    0 if x == y
//   +1 if x >  y
//
int32 U256_Cmp(uint256 x, uint256 y);

//增加gas值，此指令不必显式调用，而是会被二次编译加入到wasm代码中
//####gas function
void AddGas(uint64 gas);

/*
CallParams:跨合约调用的第一个参数
_address:被调用的地址
_amount:发往被调用地址的代币,单位为wei
_gas:为跨合约调用支付的gas
*/
typedef struct {
  address _address;
  uint256 _amount;
  uint64 _gas;
} CallParams;

//隐式调用WriteWithPointer、ReadWithPointer、AddGas三个指令
//使其能被编译到wasm代码中
__attribute__((visibility("default"))) void declaredFunction() {
  WriteWithPointer(0, 0);
  ReadWithPointer(0, 0);
  AddGas(0);
}

//########SafeMath For Uint256###########
uint256 U256SafeMul(uint256 x, uint256 y) {
  uint256 z = U256_Mul(x, y);
  Require(U256_Cmp(x, U256(0)) == 0 || U256_Cmp(U256_Div(z, x), y) == 0,
          "u256SafeMul overflow");
  return z;
}
uint256 U256SafeDiv(uint256 x, uint256 y) {
  Require(U256_Cmp(y, U256(0)) == 1, "U256SafeDiv y == 0");
  uint256 z = U256_Div(x, y);
  //这种情况不会出现
  Require(U256_Cmp(x, U256_Add(U256_Mul(y, z), U256_Mod(x, y))) == 0,
          "U256SafeDiv overflow");
  return z;
}
uint256 U256SafeSub(uint256 x, uint256 y) {
  Require(U256_Cmp(x, y) != -1, "U256SafeSub x < y");
  return U256_Sub(x, y);
}
uint256 U256SafeAdd(uint256 x, uint256 y) {
  uint256 z = U256_Add(x, y);
  Require(U256_Cmp(z, x) != -1 && U256_Cmp(z, y) != -1, "U256SafeAdd overflow");
  return z;
}
//###########################
#endif
//###################################################################
// 以上为标准库
