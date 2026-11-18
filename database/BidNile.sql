CREATE DATABASE BidNile;
GO
USE BidNile;
GO

CREATE SCHEMA Members
GO

CREATE SCHEMA Warehouses
GO

CREATE SCHEMA Catalogue
GO

CREATE SCHEMA AuctionsAndBidding
GO

CREATE TABLE Members.City
(
	Id TINYINT IDENTITY 
		CONSTRAINT PK_City PRIMARY KEY,

	Name NVARCHAR(60),

	Code CHAR(2),

	CONSTRAINT UQ_City_Name_Code UNIQUE (Name,Code)
);
GO

CREATE TABLE Members.Wallet
(
	Id INT IDENTITY 
		CONSTRAINT PK_Wallet PRIMARY KEY,

	Balance DECIMAL(12,2)
		CONSTRAINT CK_Wallet_Balance CHECK (Balance > 0)
		CONSTRAINT DF_Wallet_Balance DEFAULT 0,

	AmountOnHold DECIMAL(12,2),

	Currency CHAR(3)
		CONSTRAINT DF_Wallet_Currency DEFAULT 'EGP',

	LastUpdatedAt DATETIME2(0)
		CONSTRAINT DF_Wallet_LastUpdatedAt DEFAULT NULL,

	CONSTRAINT CK_Wallet_AmountOnHold  
		CHECK (AmountOnHold > 0 AND AmountOnHold < Balance)
);
GO

CREATE TABLE Members.Member
(
	Id UNIQUEIDENTIFIER
		CONSTRAINT PK_Member PRIMARY KEY,

	FullName NVARCHAR(100),

	Email VARCHAR(254)
		CONSTRAINT UQ_Member_Email UNIQUE,

	PhoneNumber VARCHAR(16),

	NationalId VARCHAR(20)
		NOT NULL
		CONSTRAINT UQ_Member_NationalId UNIQUE,

	BirthDate DateTime2(0)
		NOT NULL
		CONSTRAINT CK_Member_BirthDate CHECK (BirthDate <= DATEADD(YEAR, -18, GETDATE())),

	IsVerified BIT
		CONSTRAINT DF_Member_IsVerified DEFAULT 0,

	RegisteredAt DATETIME2(3) NOT NULL,

	WarehouseId INT NULL,
	
	CityId TINYINT NOT NULL,

	WalletId INT NOT NULL,

	InvitedById UNIQUEIDENTIFIER NULL
);
GO

CREATE TABLE Warehouses.Warehouse
(
	Id INT IDENTITY(1,1) 
		NOT NULL
		CONSTRAINT PK_Warehouse PRIMARY KEY,
	
	Name NVARCHAR(80) 
		NULL
		CONSTRAINT UQ_Warehouse_Name UNIQUE,

	Capacity INT 
		NULL
		CONSTRAINT CK_Warehouse_Capacity CHECK (Capacity > 0),

	Longitude FLOAT NULL
		CONSTRAINT CK_Warehouse_Longitude CHECK (Longitude BETWEEN -180 AND 180),

	Latitude FLOAT NULL
		CONSTRAINT CK_Warehouse_Latitude CHECK (Latitude BETWEEN -90 AND 90),

	CityId TINYINT NULL,

	ManagerId UNIQUEIDENTIFIER NULL,

	ManageStartTime DATE NULL
);
GO

CREATE TABLE Catalogue.Item
(
	Id INT IDENTITY(1,1) 
		NOT NULL
		CONSTRAINT PK_Item PRIMARY KEY,

	Title NVARCHAR(150) NULL,

	Description NVARCHAR(MAX) NULL,

	ConditionScore TINYINT 
		NULL
		CONSTRAINT CK_Item_ConditionScore CHECK (ConditionScore BETWEEN 1 AND 10),

	Specifications NVARCHAR(MAX) 
		NULL
		CONSTRAINT CK_Item_Specifications CHECK (ISJSON(Specifications) = 1),

	ListedDate DATETIME2 NULL,

	CategoryId INT NOT NULL,

	InspectorId UNIQUEIDENTIFIER NULL,

	SellerId UNIQUEIDENTIFIER NULL,

	WarehouseId INT NULL,

	CONSTRAINT CK_Item_Seller_Inspector CHECK (SellerId <> InspectorId)
);
GO

CREATE TABLE Catalogue.Category
(
	Code INT
		NOT NULL
		CONSTRAINT PK_Category PRIMARY KEY,

	EnglishName NVARCHAR(50)
		NOT NULL
		CONSTRAINT UQ_Category_EnglishName UNIQUE,

	ArabicName NVARCHAR(50) NULL,

	Commision DECIMAL(4,2)
		NULL
		CONSTRAINT CK_Category_Commision CHECK (Commision BETWEEN 0 AND 30),

	ParentCategoryId INT NULL,

	CONSTRAINT CK_Category_Parent CHECK (ParentCategoryId <> Code)
);
GO

CREATE TABLE Catalogue.Photo
(
	ItemId INT NOT NULL,

	Number TINYINT
		NOT NULL
		CONSTRAINT CK_Photo_Number CHECK (Number BETWEEN 1 AND 20),

	PhotoUrl VARCHAR(500) NULL,

	IsMain BIT
		NULL
		CONSTRAINT DF_Photo_IsMain DEFAULT 0,

	CONSTRAINT PK_Photo PRIMARY KEY (ItemId, Number)
);
GO

CREATE TABLE AuctionsAndBidding.Auction
(
	Id INT IDENTITY(1,1)
		NOT NULL
		CONSTRAINT PK_Auction PRIMARY KEY,

	StartPrice DECIMAL(12,2)
		NULL
		CONSTRAINT CK_Auction_StartPrice CHECK (StartPrice > 0),

	ReservePrice DECIMAL(12,2) NULL,

	BidIncrement DECIMAL(12,2)
		NULL
		CONSTRAINT DF_Auction_BidIncrement DEFAULT 50.00,

	StartDate DATETIMEOFFSET NULL,

	EndDate DATETIMEOFFSET NULL,

	Status VARCHAR(10)
		NULL
		CONSTRAINT DF_Auction_Status DEFAULT 'Draft'
		CONSTRAINT CK_Auction_Status CHECK (Status IN ('Draft','Live','Ended','Cancelled')),

	ItemId INT NOT NULL,

	CONSTRAINT CK_Auction_ReservePrice CHECK (ReservePrice >= StartPrice),

	CONSTRAINT CK_Auction_Dates CHECK (EndDate > StartDate)
);
GO

CREATE TABLE AuctionsAndBidding.Bid
(
	Id BIGINT IDENTITY(1,1)
		NOT NULL
		CONSTRAINT PK_Bid PRIMARY KEY,

	MemberId UNIQUEIDENTIFIER NOT NULL,

	AuctionId INT NOT NULL,

	Amount DECIMAL(12,2)
		NULL
		CONSTRAINT CK_Bid_Amount CHECK (Amount > 0),

	PlacedAt DATETIME2(3) NULL,

	DeviceIpAdress VARCHAR(45) NULL,

	CONSTRAINT UQ_Bid_Auction_Amount UNIQUE (AuctionId, Amount)
);
GO

CREATE TABLE AuctionsAndBidding.Followers
(
	MemberId UNIQUEIDENTIFIER NOT NULL,

	AuctionId INT NOT NULL,

	FollowedAt DATETIME2 NULL,

	CONSTRAINT PK_Follow PRIMARY KEY (MemberId, AuctionId)
);
GO


----------------------------------------------------------------------
-- Task 3.1

ALTER TABLE Members.Member
	ADD CONSTRAINT FK_Member_Warehouse
	FOREIGN KEY(WarehouseId) REFERENCES Warehouses.Warehouse(Id);

ALTER TABLE Members.Member
	ADD CONSTRAINT FK_Member_City
	FOREIGN KEY(CityId) REFERENCES Members.City(Id);

ALTER TABLE Members.Member
	ADD CONSTRAINT FK_Member_WalletId
	FOREIGN KEY(WalletId) REFERENCES Members.Wallet(Id);

ALTER TABLE Members.Member
	ADD CONSTRAINT FK_Member_InvitedById
	FOREIGN KEY(InvitedById) REFERENCES Members.Member(Id);

ALTER TABLE Warehouses.Warehouse
	ADD CONSTRAINT FK_Warehouse_CityId
	FOREIGN KEY(CityId) REFERENCES Members.City(Id);

ALTER TABLE Warehouses.Warehouse
	ADD CONSTRAINT FK_Warehouse_ManagerId
	FOREIGN KEY(ManagerId) REFERENCES Members.Member(Id);

ALTER TABLE Catalogue.Category
	ADD CONSTRAINT FK_Category_ParentCategoryId
	FOREIGN KEY(ParentCategoryId) REFERENCES Catalogue.Category(Code);

ALTER TABLE Catalogue.Item
	ADD CONSTRAINT FK_Item_Category
	FOREIGN KEY (CategoryId) REFERENCES Catalogue.Category(Code);

ALTER TABLE Catalogue.Item
	ADD CONSTRAINT FK_Item_Inspector
	FOREIGN KEY (InspectorId) REFERENCES Members.Member(Id);

ALTER TABLE Catalogue.Item
	ADD CONSTRAINT FK_Item_Seller
	FOREIGN KEY (SellerId) REFERENCES Members.Member(Id);

ALTER TABLE Catalogue.Item
	ADD CONSTRAINT FK_Item_Warehouse
	FOREIGN KEY (WarehouseId) REFERENCES Warehouses.Warehouse(Id);

ALTER TABLE Catalogue.Photo
	ADD CONSTRAINT FK_Photo_Item
	FOREIGN KEY (ItemId) REFERENCES Catalogue.Item(Id)
	ON DELETE CASCADE;

ALTER TABLE AuctionsAndBidding.Auction
	ADD CONSTRAINT FK_Auction_Item
	FOREIGN KEY(ItemId) REFERENCES Catalogue.Item(Id);

ALTER TABLE AuctionsAndBidding.Bid
	ADD CONSTRAINT FK_Bids_Member
	FOREIGN KEY(MemberId) REFERENCES Members.Member(Id);

ALTER TABLE AuctionsAndBidding.Bid
	ADD CONSTRAINT FK_Bids_Auction
	FOREIGN KEY(AuctionId) REFERENCES AuctionsAndBidding.Auction(Id);

ALTER TABLE AuctionsAndBidding.Followers
	ADD CONSTRAINT FK_Followers_Member
	FOREIGN KEY(MemberId) REFERENCES Members.Member(Id);

ALTER TABLE AuctionsAndBidding.Followers
	ADD CONSTRAINT FK_Followers_Auction
	FOREIGN KEY(AuctionId) REFERENCES AuctionsAndBidding.Auction(Id);
GO

-----------------------------------------------------------------------------
-- Task 3.2

ALTER TABLE Members.Member
	ADD AppLanguage CHAR(2)
		NOT NULL
		CONSTRAINT DF_Member_AppLanguage DEFAULT 'ar';
GO

ALTER TABLE Members.Member
	ADD CONSTRAINT CK_Member_AppLanguage CHECK (AppLanguage IN ('ar','en'))
GO

-----------------------------------------------------------------------------
-- Task 3.3

ALTER TABLE Catalogue.Item
	ADD Featured VARCHAR(3)
		NOT NULL
		CONSTRAINT DF_Items_Featured DEFAULT 'NO';
GO

-----------------------------------------------------------------------------
-- Task 3.4

EXEC sp_rename 'AuctionsAndBidding.Bid.DeviceIpAdress', 'DeviceIp', 'COLUMN';
GO

ALTER TABLE Warehouses.Warehouse
	DROP CONSTRAINT CK_Warehouse_Capacity;
GO

EXEC sp_rename 'Warehouses.Warehouse.Capacity', 'MaxItems', 'COLUMN';
GO

ALTER TABLE Warehouses.Warehouse
	ADD CONSTRAINT CK_Warehouse_MaxItems CHECK (MaxItems > 0);
GO

-----------------------------------------------------------------------------
-- Task 3.5

ALTER TABLE Members.Member
	ALTER COLUMN FullName NVARCHAR(150) NOT NULL;
GO

-----------------------------------------------------------------------------
-- Task 3.6

ALTER TABLE Warehouses.Warehouse
	DROP CONSTRAINT CK_Warehouse_MaxItems;
GO

ALTER TABLE Warehouses.Warehouse
	ALTER COLUMN MaxItems SMALLINT NULL;
GO

ALTER TABLE Warehouses.Warehouse
	ADD CONSTRAINT CK_Warehouse_MaxItems CHECK (MaxItems > 0);
GO

-----------------------------------------------------------------------------
-- Task 3.7

ALTER TABLE Catalogue.Category
	DROP CONSTRAINT CK_Category_Commision;

ALTER TABLE Catalogue.Category
	ADD CONSTRAINT CK_Category_Commision CHECK (Commision <= 25);
GO

-----------------------------------------------------------------------------
-- Task 3.8

ALTER TABLE AuctionsAndBidding.Auction
	DROP CONSTRAINT DF_Auction_Status;

ALTER TABLE AuctionsAndBidding.Auction
	DROP CONSTRAINT CK_Auction_Status;
GO

ALTER TABLE AuctionsAndBidding.Auction
	ALTER COLUMN Status VARCHAR(15) NULL;
GO

ALTER TABLE AuctionsAndBidding.Auction
	ADD CONSTRAINT DF_Auction_Status DEFAULT 'PendingReview'
	FOR Status;

ALTER TABLE AuctionsAndBidding.Auction
	ADD CONSTRAINT CK_Auction_Status
	CHECK (Status = 'PendingReview' OR Status = 'Draft' OR Status = 'Live' OR Status = 'Ended' OR Status = 'Cancelled');
GO

-----------------------------------------------------------------------------
-- Task 3.9

ALTER TABLE AuctionsAndBidding.Auction
	ADD BuyNowPrice DECIMAL(12,2) NULL;
GO

ALTER TABLE AuctionsAndBidding.Auction
	WITH CHECK
	ADD CONSTRAINT CK_Auction_BuyNowPrice
	CHECK (BuyNowPrice IS NULL OR BuyNowPrice > StartPrice);
GO

/*
	WITH CHECK to enforce the check on old and new rows
	WITHOUT CHECK will pass the already inserted rows and we dont want that
*/

-----------------------------------------------------------------------------
-- Task 3.10

CREATE UNIQUE INDEX UX_Member_PhoneNumber
	ON Members.Member (PhoneNumber)
	WHERE PhoneNumber IS NOT NULL;
GO

-----------------------------------------------------------------------------
-- Task 3.11

ALTER TABLE Members.Member
	ADD VerifiedAt DATETIME2(0) NULL;
GO

UPDATE Members.Member
SET VerifiedAt = SYSDATETIME()
WHERE IsVerified = 1;
GO

ALTER TABLE Members.Member
	DROP CONSTRAINT DF_Member_IsVerified;

ALTER TABLE Members.Member
	DROP COLUMN IsVerified;
GO

-----------------------------------------------------------------------------
-- Task 3.12

CREATE SCHEMA Marketing;
GO

ALTER SCHEMA Marketing
	TRANSFER AuctionsAndBidding.Followers;
GO

         -----------------------------------------------------------------------------


