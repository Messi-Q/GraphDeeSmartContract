pragma solidity ^0.4.14;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
         
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

         
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

     
    function toSlice(string self) internal pure returns (slice) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

     
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (self & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (self & 0xffffffffffffffff == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (self & 0xffffffff == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (self & 0xffff == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (self & 0xff == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

     
    function toSliceB32(bytes32 self) internal pure returns (slice ret) {
         
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

     
    function copy(slice self) internal pure returns (slice) {
        return slice(self._len, self._ptr);
    }

     
    function toString(slice self) internal pure returns (string) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

     
    function len(slice self) internal pure returns (uint l) {
         
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

     
    function empty(slice self) internal pure returns (bool) {
        return self._len == 0;
    }

     
    function compare(slice self, slice other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                 
                uint256 mask = uint256(-1);  
                if(shortest < 32) {
                    mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                uint256 diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

     
    function equals(slice self, slice other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

     
    function nextRune(slice self, slice rune) internal pure returns (slice) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
         
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

         
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

     
    function nextRune(slice self) internal pure returns (slice ret) {
        nextRune(self, ret);
    }

     
    function ord(slice self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

         
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

         
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                 
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

     
    function keccak(slice self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

     
    function startsWith(slice self, slice needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

     
    function beyond(slice self, slice needle) internal pure returns (slice) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(sha3(selfptr, length), sha3(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

     
    function endsWith(slice self, slice needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

     
    function until(slice self, slice needle) internal pure returns (slice) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    event log_bytemask(bytes32 mask);

     
     
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                 
                bytes32 hash;
                assembly { hash := sha3(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := sha3(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

     
     
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                 
                bytes32 hash;
                assembly { hash := sha3(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := sha3(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

     
    function find(slice self, slice needle) internal pure returns (slice) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

     
    function rfind(slice self, slice needle) internal pure returns (slice) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

     
    function split(slice self, slice needle, slice token) internal pure returns (slice) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
             
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

     
    function split(slice self, slice needle) internal pure returns (slice token) {
        split(self, needle, token);
    }

     
    function rsplit(slice self, slice needle, slice token) internal pure returns (slice) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
             
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

     
    function rsplit(slice self, slice needle) internal pure returns (slice token) {
        rsplit(self, needle, token);
    }

     
    function count(slice self, slice needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

     
    function contains(slice self, slice needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

     
    function concat(slice self, slice other) internal pure returns (string) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

     
    function join(slice self, slice[] parts) internal pure returns (string) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}

 
contract MyWill {

    using strings for *;

    address club;

     
    address owner;

     
    string listWitnesses;

     
    string listHeirs;
    string listHeirsPercentages;

     
    mapping (string => bool) mapHeirsVoteOwnerHasDied;

     
    enum Status {CREATED, ALIVE, DEAD}
    Status status;

     
    event Deposit(address from, uint value);
    event SingleTransact(address owner, uint value, address to, bytes data);

     
     
     

    function MyWill (address _owner, string _listHeirs, string _listHeirsPercentages, string _listWitnesses, address _club) {
        club = _club;
        owner = _owner;
        status = Status.CREATED;
        listHeirs = _listHeirs;
        listHeirsPercentages = _listHeirsPercentages;
        listWitnesses = _listWitnesses;

         
        var s = _listHeirsPercentages.toSlice().copy();
        var delim = ";".toSlice();
        var parts = new uint256[](s.count(delim) + 1);

        uint256 countPercentage;
        for(uint i = 0; i < parts.length; i++) {
            countPercentage = countPercentage + stringToUint(s.split(delim).toString());
        }

        require(countPercentage == 100000);
    }

     
     
     

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAlive() {
        require(status == Status.ALIVE || status == Status.CREATED);
        _;
    }

    modifier onlyDead() {
        require(status == Status.DEAD);
        _;
    }

    modifier onlyHeir() {

        var s = listHeirs.toSlice().copy();
        var delim = ";".toSlice();
        string[] memory listOfHeirs = new string[](s.count(delim) + 1);
        bool itsHeir = false;

        string memory senderStringAddress = addressToString(msg.sender);

        for(uint i = 0; i < listOfHeirs.length; i++) {

            if(keccak256(senderStringAddress) == keccak256(s.split(delim).toString())){
                itsHeir = true;
                break;
            }
        }

        require(itsHeir);

        _;
    }

    modifier onlyWitness() {

        var s = listWitnesses.toSlice().copy();
        var delim = ";".toSlice();
        string[] memory arrayOfWitnesses = new string[](s.count(delim) + 1);
        bool itsWitness = false;

        string memory senderStringAddress = addressToString(msg.sender);

        for(uint i = 0; i < arrayOfWitnesses.length; i++) {

            if(keccak256(senderStringAddress) == keccak256(s.split(delim).toString())){
                itsWitness = true;
                break;
            }
        }

        require(itsWitness);

        _;
    }

     
     
     

     
    function () payable onlyAlive {
        if (status == Status.CREATED) {
             

             
            var witnessesList = listWitnesses.toSlice().copy();
            var witnessesLength = witnessesList.count(";".toSlice()) + 1;
            var needed = 1000000000000000 * witnessesLength + 5000000000000000;  
            require(msg.value > needed);

             
            for (uint i = 0; i < witnessesLength; i++) {
                var witnessAddress = parseAddr(witnessesList.split(";".toSlice()).toString());
                witnessAddress.transfer(1000000000000000);
            }

             
            club.transfer(5000000000000000);

             
            status = Status.ALIVE;

             
            Deposit(msg.sender, msg.value - needed);
        } else {
            Deposit(msg.sender, msg.value);
        }
    }

     
    function ownerDied() onlyWitness onlyAlive {

        require (this.balance > 0);

         
        mapHeirsVoteOwnerHasDied[addressToString(msg.sender)] = true;

        var users = listWitnesses.toSlice().copy();
        uint256 listLength = users.count(";".toSlice()) + 1;
        uint8 count = 0;

        for(uint i = 0; i < listLength; i++) {

            if(mapHeirsVoteOwnerHasDied[users.split(";".toSlice()).toString()] == true){
                count = count + 1;
            }
        }

        if(count == listLength){

             

            users = listHeirs.toSlice().copy();
            var  percentages = listHeirsPercentages.toSlice().copy();
            listLength = users.count(";".toSlice()) + 1;

            for(i = 0; i < listLength - 1; i++) {
                parseAddr(users.split(";".toSlice()).toString()).transfer(((this.balance * stringToUint(percentages.split(";".toSlice()).toString())) / 100000));
            }

             
            parseAddr(users.split(";".toSlice()).toString()).transfer(this.balance);

            status = Status.DEAD;
        }
    }

    function execute(address _to, uint _value, bytes _data) external onlyOwner {
        SingleTransact(msg.sender, _value, _to, _data);
        _to.call.value(_value)(_data);
    }

    function isOwner() returns (bool){
        return msg.sender == owner;
    }

    function getStatus() returns (Status){
        return status;
    }

    function getHeirs() returns (string, string) {
        return (listHeirs, listHeirsPercentages);
    }

    function getWitnesses() returns (string) {
        return listWitnesses;
    }

    function getWitnessesCount() returns (uint) {
        return listWitnesses.toSlice().copy().count(";".toSlice()) + 1;
    }

    function getBalance() constant returns (uint) {
        return  address(this).balance;
    }

    function hasVoted() returns (bool){
        return mapHeirsVoteOwnerHasDied[addressToString(msg.sender)];
    }

     
     
     

    function stringToUint(string s) constant private returns (uint result) {
        bytes memory b = bytes(s);
        uint i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    function addressToString(address x) private returns (string) {
        bytes memory s = new bytes(42);
        s[0] = "0";
        s[1] = "x";
        for (uint i = 0; i < 20; i++) {
            byte b = byte(uint8(uint(x) / (2**(8*(19 - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2+2*i] = char(hi);
            s[2+2*i+1] = char(lo);
        }
        return string(s);
    }

    function char(byte b) private returns (byte c) {
        if (b < 10) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }


    function parseAddr(string _a) internal returns (address){
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i=2; i<2+2*20; i+=2){
            iaddr *= 256;
            b1 = uint160(tmp[i]);
            b2 = uint160(tmp[i+1]);
            if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;
            else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;
            if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;
            else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;
            iaddr += (b1*16+b2);
        }
        return address(iaddr);
    }


}