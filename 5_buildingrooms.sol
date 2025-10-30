// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//parent contracts
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BuildingOwnershipERC1155 is ERC1155, Ownable, ReentrancyGuard {
//initial or primary market shares
    struct Room {
        string name;
        uint256 totalShares;
        uint256 pricePerShare; // rent per share per month
        bool forLease;
    }

struct LeaseInfo {
        uint256 startBlock;     
        uint256 endBlock;       
        uint256 months;         
    }

//total number of rooms
    uint256 public constant TOTAL_ROOMS = 8;
    
//mapping room id, tenant info
    mapping(uint256 => Room) public rooms;
    mapping(uint256 => address[]) public tenantsList;
    mapping(uint256 => mapping(address => LeaseInfo)) public leaseInfo;
    
//event action logs Create Room, Initial purchase, Resale Listing, Secondary Purchase, Clear the Lisitng
    event RoomCreated(uint256 indexed roomId, string name, uint256 totalShares, uint256 pricePerShare);
    event RoomLeased(uint256 indexed roomId, address indexed tenant, uint256 shares, uint256 months, uint256 totalRent);
    event LeaseExpired(uint256 indexed roomId, address indexed tenant);

//initial contract deployer is the owner
    constructor()
        ERC1155("https://amber-worried-crayfish-924.mypinata.cloud/ipfs/bafybeihkmg5nwbeqxznflfxlb4l2fgwp6zbgqvgpz2xqyy6ddu6duoligy/{id}.json")
        Ownable(msg.sender)
    {
        // Create rooms with initial total shares, price per share
        _createRoom(1, "Apartment 1", 100, 0.01 ether);
        _createRoom(2, "Apartment 2", 100, 0.01 ether); 
        _createRoom(3, "Apartment 3", 100, 0.01 ether);
        _createRoom(4, "Apartment 4", 100, 0.01 ether);
        _createRoom(5, "Apartment 5", 100, 0.01 ether);
        _createRoom(6, "Shop 1", 100, 0.05 ether);
        _createRoom(7, "Shop 1", 100, 0.05 ether);
        _createRoom(8, "Shop 1", 100, 0.05 ether);
    }

//only visible to owner
//mint full initial shares ownership of rooms to contract owner 
    function _createRoom(uint256 id, string memory name, uint256 totalShares, uint256 pricePerShare) internal onlyOwner {
        rooms[id] = Room(name, totalShares, pricePerShare, true);
        _mint(owner(), id, totalShares, "");
        emit RoomCreated(id, name, totalShares, pricePerShare);
    }

 // Owner can modify lease availability and price
    function setForLease(uint256 roomId, bool _forLease, uint256 _pricePerShare) external onlyOwner {
        rooms[roomId].forLease = _forLease;
        rooms[roomId].pricePerShare = _pricePerShare;
    }

    // Tenant leases shares for a period (in months)
    function leaseShares(uint256 roomId, uint256 shares, uint256 months) external payable nonReentrant {
        Room storage r = rooms[roomId];
        require(r.forLease, "Room not available for lease");
        require(balanceOf(owner(), roomId) >= shares, "Not enough shares left");
        require(months > 0, "Invalid months");

// Calculate total rent = price per share × number of shares × months
        uint256 totalRent = r.pricePerShare * shares * months;
        require(msg.value >= totalRent, "Insufficient payment");

        // Transfer fractional shares to tenant
        safeTransferFrom(owner(), msg.sender, roomId, shares, "");

        // Record lease info
        leaseInfo[roomId][msg.sender] = LeaseInfo(block.number, block.number + (months * 200000 / 12), months);
        tenantsList[roomId].push(msg.sender);

        // Transfer rent to owner
        payable(owner()).transfer(totalRent);

        // Refund excess ETH (if overpaid)
        if (msg.value > totalRent) {
            payable(msg.sender).transfer(msg.value - totalRent);
        }

        emit RoomLeased(roomId, msg.sender, shares, months, totalRent);
    }

 // Check if a lease has expired
    function checkLeaseStatus(uint256 roomId, address tenant) external view returns (bool active, uint256 endBlock) {
        LeaseInfo storage lease = leaseInfo[roomId][tenant];
        if (block.number <= lease.endBlock && lease.endBlock != 0) {
            return (true, lease.endBlock);
        } else {
            return (false, lease.endBlock);
        }
    }

// View room info
    function getRoom(uint256 roomId) external view returns (string memory, uint256, uint256, bool) {
        Room storage r = rooms[roomId];
        return (r.name, r.pricePerShare, r.totalShares, r.forLease);
    }

    // Get all tenants info of a specific room
    function getTenants(uint256 roomId) external view returns (uint256, address[] memory) {
        return (tenantsList[roomId].length, tenantsList[roomId]);
    }

    receive() external payable {
        revert("Use leaseShares() to lease rooms");
    }
}