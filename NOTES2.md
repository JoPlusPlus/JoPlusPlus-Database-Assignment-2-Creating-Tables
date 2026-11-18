# BidNile Database — Notes

## 1. Schemas and their tables

The design is split into four schemas, each grouping tables that belong to the same business area:

- **Members**: `Members.Member`, `Members.Wallet`. Everything about a person and their money account.
- **Locations**: `Locations.City`, `Locations.Warehouse`. Where members live and where items are stored.
- **Catalogue**: `Catalogue.Category`, `Catalogue.Item`, `Catalogue.Photo`. What is being sold and how it is classified.
- **Auctions**: `Auctions.Auction`, `Auctions.Bid`, `Auctions.Followers`. Selling events, bidding and following. `Followers` moves to a `Marketing` schema in Task 3.12.

Tables are grouped this way so that each schema matches one business area, which makes permissions and later changes easier to manage.

## 2. Relationship types in BidNile

- **1:1**
  - `Member` ↔ `Wallet`: each member has exactly one wallet and each wallet belongs to one member. `Member.WalletID` holds the FK and is `UNIQUE`.
  - `Warehouse` ↔ `Member` (manager): one manager per warehouse and one warehouse per manager. `Warehouse.ManagerID` is an FK to `Member` and is `UNIQUE`.

- **1:N**
  - `City` → `Member` (a city has many members, each member lives in one city).
  - `City` → `Warehouse`.
  - `Warehouse` → `Member` (employees, via `Member.WarehouseID`, which is nullable because not every member is an employee).
  - `Warehouse` → `Item` (`Item.WarehouseID`, nullable until the item arrives).
  - `Member` → `Item` as seller (`SellerID`) and as inspector (`InspectorID`). Two separate FKs to the same table. A CHECK ensures they are never the same member.
  - `Category` → `Item` (`CategoryID`).
  - `Item` → `Auction` (`Auction.ItemID`). An item can have several auctions over time.
  - `Auction` → `Bid` and `Member` → `Bid`. Each bid belongs to one auction and one member.
  - `Item` → `Photo` (through the weak entity below).

- **M:N**
  - `Member` ↔ `Auction` (following). Resolved with the `Followers` table, whose composite PK is (`MemberID`, `AuctionID`). This also guarantees nobody follows the same auction twice.

- **Recursive**
  - `Member` invites `Member`: `Member.InvitedByID` references `Member.ID`. One inviter per member, many invitees per inviter.
  - `Category` is a tree: `Category.ParentCategoryID` references `Category.Code`. Top-level categories have a NULL parent.

- **Circular**
  - `Member.WarehouseID` → `Warehouse` and `Warehouse.ManagerID` → `Member`. A member works in a warehouse, and that warehouse is managed by a member. The two tables reference each other.

- **Weak entity**
  - `Photo` depends on `Item`. It has no meaning without its item, so its PK is the composite (`Number`, `ItemID`), and `ItemID` is an FK with `ON DELETE CASCADE`.

## 3. Data type choices

- **GUID for members, BIGINT for bids.** Members are created on the phone before reaching the server, so IDs must be globally unique without asking the database for a number. A `UNIQUEIDENTIFIER` with a default of `NEWID()` gives that. Bids are expected to pass 2.1 billion, which is beyond the range of `INT`, so `BIGINT` is needed.

- **FLOAT for GPS, DECIMAL for money.** GPS coordinates are approximate measurements with many decimal places, so a floating-point type is appropriate and the small rounding error does not matter. Money must be exact. Floating-point rounding errors would make balances and bids unreliable, so `DECIMAL(p,s)` is used for `Balance`, `AmountOnHold` and bid amounts.

- **DATETIMEOFFSET for auctions.** Auctions run in Cairo (+02:00), Riyadh (+03:00) and Dubai (+04:00). `DATETIME2` would lose the offset, so the same clock time would be ambiguous. `DATETIMEOFFSET` stores the offset with the value, so start and end times are unambiguous.

## 4. Why the circular relationship cannot be created inside CREATE TABLE

`Member` references `Warehouse` (through `WarehouseID`), and `Warehouse` references `Member` (through `ManagerID`). SQL Server creates tables in order, and a FK must point to a table that already exists. Whichever table is created first would reference a table that does not exist yet, so the script fails.

The solution is to create all tables first, with the FK columns in place but without FK constraints. The constraints are then added afterwards with `ALTER TABLE ... ADD CONSTRAINT` (Task 3.1), when both tables exist.

## 5. Order of filling the tables

The order follows the foreign key dependencies: a row can only reference rows that already exist.

1. `City` (no dependencies)
2. `Category`, parents before children, because of `ParentCategoryID`
3. `Wallet` (no dependencies)
4. `Member`, with `WarehouseID` left NULL, because `Warehouse` does not exist yet. `InvitedByID` is filled in the Excel file with the inviter's row first.
5. `Warehouse`, with `ManagerID` pointing to a member from step 4
6. `Member` again through Edit Top 200 Rows, to set `WarehouseID` for the employees
7. `Item` (needs `Category`, `Member` and `Warehouse`)
8. `Photo` (needs `Item`)
9. `Auction` (needs `Item`)
10. `Bid` and `Followers` (need `Member` and `Auction`)

The circular relationship is the reason for step 4 and step 6. The member and warehouse rows reference each other, so one of the two FK columns has to be left NULL first and updated afterwards.

## 6. Errors in Task 3.6 and 3.11 and how I fixed them

**Task 3.6 — MaxItems to the smallest fitting type.**
Capacity must hold up to 30,000 items. `TINYINT` holds only 0–255, and `SMALLINT` holds up to 32,767, so `SMALLINT` is the smallest type that fits. The `ALTER COLUMN` failed because the existing check constraint (`> 0`) depends on the column. The fix was to drop the check constraint, change the column type to `SMALLINT`, and then re-add the constraint with the same `> 0` rule under the same name.

**Task 3.11 — Replace IsVerified with VerifiedAt.**
`VerifiedAt` was added as a nullable `DATETIME2(3)`. Dropping `IsVerified` failed because its `DEFAULT` constraint (`DF_Member_IsVerified`) is attached to the column, and SQL Server cannot drop a column that has a constraint on it. The fix was to drop `DF_Member_IsVerified` first, then drop `IsVerified`.

