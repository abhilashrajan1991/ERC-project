Overview of The contract:

Uses OpenZeppelin’s ERC1155, Ownable, and ReentrancyGuard.
Represents rooms or units (apartments, shops) as token IDs.
Each room/unit has fractional ownership via “shares” (ERC-1155 tokens).
Allows tenants to lease shares for a given number of months, paying rent in ETH.
Tracks lease periods using block numbers.

Key Functionalities

For Room Creation:
constructor() creates 8 rooms (5 apartments, 3 shops).
Each room has a name, totalShares (100), and pricePerShare (e.g., 0.01 ETH/month/share).
_mint() mints all shares to the contract owner initially.

Leasing: 
leaseShares() lets tenants lease a number of shares for a period.
Payment = pricePerShare * shares * months.
Tenant receives the ERC-1155 tokens (fractional ownership for that lease duration).
Lease duration tracked in blocks, roughly converting months to blocks via (months * 200000 / 12) — assuming ~200k blocks/month (~12s block time).
Rent is transferred to the owner.
Refunds any overpayment.
Emits an event for transparency.

Lease Info:
checkLeaseStatus() lets anyone check if a lease is active (based on block number).
getRoom() and getTenants() provide metadata and tenant lists.

i want to create a similar kind of smart contract for this purpose: to issue a tradeable and verifiable certificate to a working member of trading and managements association
