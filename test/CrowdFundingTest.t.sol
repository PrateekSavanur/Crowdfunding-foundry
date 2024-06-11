// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Crowdfunding} from "../src/Crowdfunding.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";

contract CrowdfundingTest is Test {
    Crowdfunding crowdfunding;
    TokenFactory tokenFactory;
    address public owner;
    address public contributor;
    uint256 public initialBalance = 100 ether;

    function setUp() public {
        tokenFactory = new TokenFactory();
        crowdfunding = new Crowdfunding(address(tokenFactory));
        owner = address(this);
        contributor = address(0x123);
        vm.deal(contributor, initialBalance); // allocate initial balance to contributor
    }

    function testCreateProject() public {
        string memory tokenName = "Test Token";
        string memory tokenTicker = "TT";
        uint256 goalAmount = 10 ether;
        uint256 durationDays = 30;
        uint256 tokenPerEth = 1000;

        vm.prank(owner);
        crowdfunding.createProject(owner, goalAmount, durationDays, tokenName, tokenTicker, tokenPerEth);

        (
            ,
            ,
            uint256 fundingGoal,
            bool closed,
            uint256 deadline,
            uint256 tokensPerEth,
            address projectOwner,
            bool icoCompleted
        ) = crowdfunding.getProjectDetails(1);

        assertEq(fundingGoal, goalAmount);
        assertEq(deadline, block.timestamp + (durationDays * 1 days));
        assertEq(tokensPerEth, tokenPerEth);
        assertEq(projectOwner, owner);
        assertEq(closed, false);
        assertEq(icoCompleted, false);
    }

    function testContributeFunds() public {
        setUpProject();

        uint256 projectId = 1;
        uint256 contributionAmount = 5 ether;

        vm.prank(contributor);
        crowdfunding.contributeFunds{value: contributionAmount}(projectId);

        (, uint256 funded,,,,,,) = crowdfunding.getProjectDetails(projectId);

        assertEq(funded, contributionAmount);
        assertEq(crowdfunding.contributions(projectId, contributor), contributionAmount);
    }

    function testStartICO() public {
        setUpProject();

        uint256 projectId = 1;

        vm.prank(owner);
        crowdfunding.startICO(projectId);

        assertTrue(crowdfunding.projectICOStarted(projectId));
    }

    function testDistributeTokens() public {
        setUpProject();
        contributeToProject();

        uint256 projectId = 1;

        vm.prank(owner);
        crowdfunding.startICO(projectId);

        vm.prank(owner);
        crowdfunding.distributeTokens(projectId);

        IERC20 token = IERC20(crowdfunding.getTokenAddressOfProject(projectId));
        uint256 expectedTokens = (10 ether * 1000) / 1 ether;

        assertEq(token.balanceOf(contributor), expectedTokens);
        assertTrue(crowdfunding.participatedInICO(projectId, contributor));
        (,,,,,,, bool icoCompleted) = crowdfunding.getProjectDetails(projectId);
        assertTrue(icoCompleted);
    }

    // Helper Functions
    function setUpProject() internal {
        string memory tokenName = "Test Token";
        string memory tokenTicker = "TT";
        uint256 goalAmount = 10 ether;
        uint256 durationDays = 30;
        uint256 tokenPerEth = 1000;

        vm.prank(owner);
        crowdfunding.createProject(owner, goalAmount, durationDays, tokenName, tokenTicker, tokenPerEth);
    }

    function contributeToProject() internal {
        uint256 projectId = 1;
        uint256 contributionAmount = 10 ether;

        vm.prank(contributor);
        crowdfunding.contributeFunds{value: contributionAmount}(projectId);
    }
}
