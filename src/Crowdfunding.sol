// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TokenFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Crowdfunding {
    struct Project {
        address tokenContractAddress;
        uint256 funded;
        uint256 fundingGoal;
        bool closed;
        uint256 deadline;
        uint256 tokensPerEth;
        address owner;
        address[] contributors;
        bool icoCompleted;
    }

    TokenFactory public tokenFactory;
    address public admin;
    uint256 public projectIdCounter;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => mapping(address => uint256)) public contributions;
    mapping(uint256 => bool) public projectICOStarted;
    mapping(uint256 => mapping(address => bool)) public participatedInICO;

    modifier OnlyOwner(uint256 _projectId) {
        Project storage project = projects[_projectId];
        require(msg.sender == project.owner, "Only project owner can access this fxn");
        _;
    }

    event ProjectCreated(uint256 indexed projectId, address indexed owner, uint256 goalAmount, uint256 deadline);
    event FundsContributed(uint256 indexed projectId, address indexed contributor, uint256 amount);
    event ProjectClosed(uint256 indexed projectId, uint256 totalAmountRaised);
    event TokensDistributed(address receiver, uint256 amount);

    constructor(address _tokenFactory) {
        tokenFactory = TokenFactory(_tokenFactory);
        admin = msg.sender;
        projectIdCounter = 1;
    }

    function createProject(
        address _owner,
        uint256 _goalAmount,
        uint256 _durationDays,
        string memory _tokenName,
        string memory _tokenTicker,
        uint256 _tokenPerEth
    ) external {
        require(_goalAmount > 0, "Goal amount must be greater than 0");
        require(_durationDays > 0, "Duration must be greater than 0");

        uint256 tokensToMint = (_goalAmount * 1e16) / (uint256(1e16) / _tokenPerEth);

        address newTokenAddress = tokenFactory.createToken(_tokenName, _tokenTicker, tokensToMint, address(this));

        Project storage project = projects[projectIdCounter];
        project.tokenContractAddress = newTokenAddress;
        project.fundingGoal = _goalAmount;
        project.deadline = block.timestamp + (_durationDays * 1 days);
        project.owner = _owner;
        project.tokensPerEth = _tokenPerEth;

        emit ProjectCreated(projectIdCounter, _owner, _goalAmount, project.deadline);

        projectIdCounter++;
    }

    function contributeFunds(uint256 _projectId) external payable {
        if (projects[_projectId].deadline < block.timestamp) {
            closeProject(_projectId);
        }
        require(!projects[_projectId].closed, "Project is closed");
        require(projects[_projectId].tokenContractAddress != address(0), "Invalid project");
        require(msg.value > 0, "Contribution amount must be greater than 0");

        if (contributions[_projectId][msg.sender] == 0) {
            projects[_projectId].contributors.push(msg.sender);
        }

        contributions[_projectId][msg.sender] += msg.value;
        projects[_projectId].funded += msg.value;

        emit FundsContributed(_projectId, msg.sender, msg.value);

        if (projects[_projectId].funded >= projects[_projectId].fundingGoal) {
            closeProject(_projectId);
        }
    }

    function closeProject(uint256 _projectId) internal {
        projects[_projectId].closed = true;
        emit ProjectClosed(_projectId, projects[_projectId].funded);
    }

    function withdrawFunds(uint256 _projectId) external OnlyOwner(_projectId) {
        Project storage project = projects[_projectId];
        require(project.closed, "Project is not closed yet");
        uint256 amount = project.funded;
        project.funded = 0;
        payable(project.owner).transfer(amount);
    }

    function startICO(uint256 _projectId) external OnlyOwner(_projectId) {
        projectICOStarted[_projectId] = true;
    }

    function distributeTokens(uint256 _projectId) external OnlyOwner(_projectId) {
        require(projectICOStarted[_projectId], "ICO not started for this project");

        IERC20 tokenContract = IERC20(projects[_projectId].tokenContractAddress);
        uint256 tokensPerEth = projects[_projectId].tokensPerEth;

        address[] memory contributors = projects[_projectId].contributors;
        for (uint256 i = 0; i < contributors.length; i++) {
            address contributor = contributors[i];
            uint256 contributedAmount = contributions[_projectId][contributor];
            if (contributedAmount > 0 && !participatedInICO[_projectId][contributor]) {
                uint256 tokenToDistribute = (contributedAmount * tokensPerEth) / 1 ether;
                require(tokenToDistribute > 0, "No tokens to distribute");

                tokenContract.transfer(contributor, tokenToDistribute);
                participatedInICO[_projectId][contributor] = true;

                emit TokensDistributed(contributor, tokenToDistribute);
            }
        }
        projects[_projectId].icoCompleted = true;
    }

    function withdrawLeftTokens(uint256 _projectId) external OnlyOwner(_projectId) {
        address projectOwner = projects[_projectId].owner;

        IERC20 tokenContract = IERC20(projects[_projectId].tokenContractAddress);
        tokenContract.transfer(projectOwner, tokenContract.balanceOf(address(this)));
    }

    function getTokenAddressOfProject(uint256 _projectId) public view returns (address) {
        return projects[_projectId].tokenContractAddress;
    }

    function getTokenRecievedFromICO(uint256 _projectId) external view returns (uint256) {
        IERC20 tokenContract = IERC20(projects[_projectId].tokenContractAddress);
        return tokenContract.balanceOf(msg.sender);
    }

    function getTokenPerEth(uint256 _projectId) external view returns (uint256) {
        return projects[_projectId].tokensPerEth;
    }

    function getProjectOwner(uint256 _projectId) external view returns (address) {
        return projects[_projectId].owner;
    }

    function getProjectDetails(uint256 _projectId)
        external
        view
        returns (
            address tokenContractAddress,
            uint256 funded,
            uint256 fundingGoal,
            bool closed,
            uint256 deadline,
            uint256 tokensPerEth,
            address owner,
            bool icoCompleted
        )
    {
        Project memory project = projects[_projectId];
        return (
            project.tokenContractAddress,
            project.funded,
            project.fundingGoal,
            project.closed,
            project.deadline,
            project.tokensPerEth,
            project.owner,
            project.icoCompleted
        );
    }
}
