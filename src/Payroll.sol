// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title An Automated Payroll contract
 * @author Emperor Edetan
 * @notice This contract is fot creating a payroll system for employees that can be funded by the owner
 * and paid automatically at a specified interval.
 * @dev Implements chainlink automation for automatic payment of employees.
 * The contract is designed to be used with the Chainlink VRF and Automation services.
 * */ 

import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract PayRoll{
    
    error Payroll__EmployeeAlreadyExists();
    error PayRoll__NotOwner();
    error PayRoll__NotEnoughEthToFundPayRoll();
    error callFailed();
    error PayRoll__EmployeeDoesNotExist();
    error UpKeepNotNeeded(
        uint256 currentBalance,
        uint256 numOfEmployees
    );

    uint256 private s_lastPaidStamp;
    address private immutable i_owner;
    uint256 private immutable i_minimumAmount;
    uint256 private immutable i_interval;
       
    struct EmployeeData{
        string employeeName;
        address payable employeeAddress;
        uint256 employeeSalary;
        uint256 lastDatePaid;
    }
    mapping (string => EmployeeData) private  s_nameToEmployeeData;
    EmployeeData[] private s_employees;

    event addedEmployee (EmployeeData indexed employeeData);
    event removedEmployee(EmployeeData indexed employeeData);
    event PaidEmployee(
    address indexed employee,
    uint256 salary,
    uint256 timestamp
    );

    constructor (
        uint256 minimumAmount,
        uint256 interval
    ){
        s_lastPaidStamp = block.timestamp;
        i_owner = msg.sender;
        i_minimumAmount = minimumAmount;
        i_interval = interval;
    }
 

    function addEmployee(string memory name, address wallet, uint256 salary) public onlyOwner{
        uint256 employeesLength = s_employees.length;
        for (uint256 i = 0; i < employeesLength; ++i){
            if(s_employees[i].employeeAddress == wallet){
                revert Payroll__EmployeeAlreadyExists();
            }
        }
        s_employees.push(EmployeeData(name,payable(wallet),salary,s_lastPaidStamp));
        s_nameToEmployeeData[name] = EmployeeData(name,payable(wallet),salary,s_lastPaidStamp);

        emit addedEmployee (s_nameToEmployeeData[name]);
    }

    function removeEmployee(string memory name) public onlyOwner{
        uint256 employeesLength = s_employees.length;
            for (uint256 i = 0; i < employeesLength; ++i) {
            
                if (keccak256(bytes(s_employees[i].employeeName)) == keccak256(bytes(name))) {
                // Remove from mapping
                emit removedEmployee (s_nameToEmployeeData[name]);
                delete s_nameToEmployeeData[name];

                // Swap and pop to remove from array
                s_employees[i] = s_employees[employeesLength - 1];
                s_employees.pop();
                break; // Exit after removing
                }
                // Check if the employee exists
                if(keccak256(bytes(name)) != keccak256(bytes(s_employees[i].employeeName))){
                    revert PayRoll__EmployeeDoesNotExist();
                }
            
            }
     }
     function FundPayroll() public payable onlyOwner{
        if(msg.value < i_minimumAmount){
            revert PayRoll__NotEnoughEthToFundPayRoll();
        }
     }
     function withdrawFromPayroll() public onlyOwner{
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        if(!callSuccess){
            revert callFailed();
        }
     }
     modifier onlyOwner{
        if (msg.sender != i_owner){
            revert PayRoll__NotOwner();
        }
        _;
     }

     function checkUpkeep(
        bytes memory /*checkData*/) 
        public view returns(bool upkeepNeeded, bytes memory /*performData*/
    ){
            bool hasTimePaased = block.timestamp >= (s_lastPaidStamp + i_interval);
            bool hasBalance = address(this).balance >= i_minimumAmount;
            bool hasEmployees = s_employees.length > 0;
            upkeepNeeded = (hasTimePaased && hasBalance && hasEmployees);
            return (upkeepNeeded, "0x0");
        }

        function performUpkeep(bytes calldata /* performData */) external{
            (bool upKeepNeeded,) = checkUpkeep("");
            if(!upKeepNeeded){
                revert UpKeepNotNeeded(
                    address(this).balance,
                    s_employees.length
                );
            }
            s_lastPaidStamp = block.timestamp;

            uint256 employeesLength = s_employees.length;
            for (uint256 i = 0; i < employeesLength; ++i){
                uint256 salaryPay = s_employees[i].employeeSalary;
                address staffWallet = s_employees[i].employeeAddress;

                (bool callSuccess,) = payable(staffWallet).call{value: salaryPay}("");
                  if(!callSuccess){
                    revert callFailed();
                 }

                emit PaidEmployee(staffWallet, salaryPay, block.timestamp);
            }
        }

        function getLastTimeStamp() external view returns(uint256){
            return s_lastPaidStamp;
        }
        function getEmployees(uint256 index) external view returns(EmployeeData memory){
            return s_employees[index];
        } 
        function getNameToEmployeeData(string memory name) external view returns(EmployeeData memory){
            return s_nameToEmployeeData[name];
        }
        function getMinimumAmountToFundContract() external view returns(uint256){
            return i_minimumAmount;
        }
        
        function getOwner() external view returns(address){
            return i_owner;
        }
        function getEmployeeCount() external view returns (uint256) {
             return s_employees.length;
        }


    }