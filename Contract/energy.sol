pragma solidity >=0.4.16 <0.7.0;


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract InterfaceInvoice {
    function subTotal() external view returns (uint256);
    function actualConsumption() external view returns (uint256);
    function expiration() external view returns (uint256);
    function feeRate() external view returns (uint256);
    function paid() external view returns (bool);
    
    function daysLate() public view returns (uint256);
}

contract Invoice is InterfaceInvoice {
    using SafeMath for uint256; 
    
    uint256 public subTotal;
    uint256 public actualConsumption;
    uint256 public expiration;
    uint256 public feeRate;
    address public user;
    address payable public energyCompany = address(0xD0b548B8d5559c8D077165725f6Ae6F85bddab11);
    bool public paid;
    uint256 public totalizado;
    
    event paidInvoice(address indexed user, uint256 value);  
    
    constructor (address _user, uint256 _total, uint256 _actualConsumption, uint256 _expiration, uint256 _feeRate) public {
        user = _user;
        subTotal = _total;
        actualConsumption = _actualConsumption;
        expiration = _expiration;
        feeRate = _feeRate;
        paid = false;
    } 
    
    function daysLate() public view returns (uint256) {
        uint256 dayLate = 0;
        if(now > expiration){
            dayLate = now.sub(expiration).div(60).div(60).div(24);
        }
        return dayLate;
    }
    
    function lateFee() public view returns (uint256){
        uint256 fee = 0;
        if(now > expiration){
            uint256 dayLate = daysLate();
            fee = dayLate.mul(feeRate);
        }
        return fee;
    }
    
    function() payable external {
        require(msg.value > 0, 'value dont can be zero!');
        uint256 fee = lateFee();
        subTotal = subTotal.add(fee);
        
        energyCompany.transfer(msg.value);
        paid = true;
    }
}

contract EnergyRegister {
    
    mapping(address => address[]) public users;
    
    function createInvoce (address _user, uint256 _total, uint256 _actualConsumption, uint256 _expiration, uint256 _feeRate) external returns(bool) {
        address newInvoice = address(new Invoice(_user, _total, _actualConsumption, _expiration, _feeRate));
        address[] storage invoices = users[_user]; 
        invoices.push(newInvoice);
        users[_user] = invoices;
    }
    
    function getInvoice(address _invoice) external view returns ( uint256, uint256, uint256, uint256, uint256, bool){
        InterfaceInvoice invoice = InterfaceInvoice(_invoice);
        uint256 total = invoice.subTotal();
        uint256 actualConsumption = invoice.actualConsumption();
        uint256 expiration = invoice.expiration();
        uint256 feeRate = invoice.feeRate();
        uint256 daysLate = invoice.daysLate();
        bool paid = invoice.paid();
        
        return (total,actualConsumption ,expiration, daysLate,feeRate, paid );
    }
    
}