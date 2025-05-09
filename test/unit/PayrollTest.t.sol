// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {PayRoll} from "../../src/Payroll.sol";
import {Vm} from "forge-std/Vm.sol";
import {DeployPayRoll} from "../../script/DeployPayroll.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract PayrollTest is Test {
        PayRoll payRoll;
        uint256 minimumAmount = 1 ether;
        uint256 interval;
        address vrfCoordinator; 
        uint64 subscriptionId; 
        address link;
    
        address STAFF = makeAddr("staff");
        address OWNER = makeAddr("owner");
        uint256 public FUND = 10 ether;
        uint256 public SALARY = 0.1 ether;

    function setUp() external {
        DeployPayRoll deployPayRoll = new DeployPayRoll();
        HelperConfig helperConfig;
        (payRoll, helperConfig) = deployPayRoll.run();
        (minimumAmount, 
         interval,
         vrfCoordinator, 
        // bytes32 gasLane,
         subscriptionId, 
        // uint32 callbackGasLimit,
         link
        ) = helperConfig.activeNetworkConfig();
        vm.deal(OWNER, FUND);
    }

    function testOwnerIsMsgSender() external view {
        assertEq(payRoll.getOwner(), msg.sender);
    }
    function testOnlyOwnerCanAddEmployee() external {
        vm.prank(OWNER);
        vm.expectRevert();
        payRoll.addEmployee("John Doe", STAFF, SALARY);
    }
    function testAddEmployee() external {
        vm.startPrank(payRoll.getOwner());
        payRoll.addEmployee("John Doe", STAFF, SALARY);
        vm.stopPrank();
        assertEq(payRoll.getNameToEmployeeData("John Doe").employeeName, "John Doe");
        assertEq(payRoll.getNameToEmployeeData("John Doe").employeeAddress, STAFF);
        assertEq(payRoll.getNameToEmployeeData("John Doe").employeeSalary, SALARY);
    }
    function testAddEmployeeAlreadyExists() external {
        vm.startPrank(payRoll.getOwner());
        payRoll.addEmployee("John Doe", STAFF, SALARY);
        vm.expectRevert(PayRoll.Payroll__EmployeeAlreadyExists.selector);
        payRoll.addEmployee("John Doe", STAFF, SALARY);
        vm.stopPrank();
    }
    function testAddEmployeeAddsToArray() external {
        vm.startPrank(payRoll.getOwner());
        payRoll.addEmployee("John Doe", STAFF, SALARY);
        vm.stopPrank();
        assertEq(payRoll.getEmployees(0).employeeName, "John Doe");
        assertEq(payRoll.getEmployees(0).employeeAddress, STAFF);
        assertEq(payRoll.getEmployees(0).employeeSalary, SALARY);
    }
    function testRemoveEmployee() external {
        vm.startPrank(payRoll.getOwner());
        payRoll.addEmployee("John Doe", STAFF, SALARY);
        payRoll.removeEmployee("John Doe");
        vm.stopPrank();
        assertEq(payRoll.getEmployeeCount(), 0);
    }
    function testOnlyOwnerCanRemoveEmployee() external {
        vm.prank(OWNER);
        vm.expectRevert();
        payRoll.removeEmployee("Alex");
    }
    function testCannotRemoveEmployeeThatDoesNotExist() external {
        vm.startPrank(payRoll.getOwner());
        payRoll.addEmployee("John Doe", STAFF, SALARY);
        vm.expectRevert(PayRoll.PayRoll__EmployeeDoesNotExist.selector);
        payRoll.removeEmployee("Alex");
        vm.stopPrank();
    }
    function testFundPayRoll() external {
        vm.prank(payRoll.getOwner());
        payRoll.FundPayroll{value : minimumAmount}();
        assertEq(address(payRoll).balance, minimumAmount);
    }
    function testCannotFundPayRollWithLessThanMinimum() external {
        vm.prank(payRoll.getOwner());
        vm.expectRevert(PayRoll.PayRoll__NotEnoughEthToFundPayRoll.selector);
        payRoll.FundPayroll{value : 0.01 ether}();
    }
    function testOnlyOwnerCanFundPayRoll() external {
        vm.prank(OWNER);
        vm.expectRevert();
        payRoll.FundPayroll{value : minimumAmount}();
    }
    function testWithdrawFromPayroll() external {
        vm.prank(payRoll.getOwner());
        payRoll.FundPayroll{value : minimumAmount}();
        vm.prank(payRoll.getOwner());
        payRoll.withdrawFromPayroll();
        assertEq(address(payRoll).balance, 0);
    }
    function testOnlyOwnerCanWithdrawFromPayroll() external {
        vm.prank(OWNER);
        vm.expectRevert();
        payRoll.withdrawFromPayroll();
    }
                ////////////////////////
                // Check Upkeep       //
                ////////////////////////

    function testUpkeepNeededFailsIfThereIsNoBalance() external {
        vm.prank(STAFF);
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded,) = payRoll.checkUpkeep("");

        assert(!upkeepNeeded);
    }
    function testUpkeepNeededFailsIfThereAreNoEmployees() external {
        vm.prank(payRoll.getOwner());
        payRoll.FundPayroll{value : minimumAmount}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded,) = payRoll.checkUpkeep("");

        assert(!upkeepNeeded);
    }
    function testUpkeepNeededFailsIfTimeHasNotPassed() external {
        vm.prank(payRoll.getOwner());
        payRoll.FundPayroll{value : minimumAmount}();
        vm.startPrank(payRoll.getOwner());
        payRoll.addEmployee("John Doe", STAFF, SALARY);
        vm.stopPrank();
        (bool upkeepNeeded,) = payRoll.checkUpkeep("");

        assert(!upkeepNeeded);
    }
    

                ////////////////////////
                // Perform Upkeep     //
                ////////////////////////
    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() external {
        vm.startPrank(payRoll.getOwner());
        payRoll.FundPayroll{value : minimumAmount}();
        payRoll.addEmployee("John Doe", STAFF, SALARY);
        vm.stopPrank();
        
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        
        payRoll.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepFails() external {
        uint256 currentBalance;
        uint256 numOfEmployees;
        vm.expectRevert(
            abi.encodeWithSelector(
            PayRoll.UpKeepNotNeeded.selector,
            currentBalance,
            numOfEmployees
            )
        );
        payRoll.performUpkeep("");
    }
}