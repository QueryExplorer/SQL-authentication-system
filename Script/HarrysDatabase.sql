USE Master
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'HarrysDatabase')
BEGIN
ALTER DATABASE HarrysDatabase SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE HarrysDatabase
END


CREATE DATABASE HarrysDatabase
GO

USE HarrysDatabase
GO

-- User table
CREATE TABLE Users (
User_id 		INT IDENTITY (1,1) PRIMARY KEY NOT NULL,
Full_name		VARCHAR(50) NOT NULL, 
Email			VARCHAR(256) UNIQUE NOT NULL,
Is_admin		BIT NOT NULL,
Is_customer		BIT NOT NULL,
Hashed_password	VARBINARY(128) NOT NULL,
Salt			NVARCHAR(50) NOT NULL,
City			NVARCHAR(50) NULL,
Country		    NVARCHAR(60) NULL,
Address		    NVARCHAR(100) NULL,
Phone_number	NVARCHAR(13) NOT NULL,
Verified		BIT NOT NULL,
Disabled 		BIT NOT NULL,
Valid_from		DATETIME NOT NULL,
Valid_to		DATETIME NOT NULL

)

-- Token table
CREATE TABLE Tokens (
Token_id		INT IDENTITY (1,1) PRIMARY KEY NOT NULL,
User_id		    INT NOT NULL,
Token_value		NVARCHAR(36) NOT NULL,
Token_type		VARCHAR(200) NULL,
Created_at		DATETIME NOT NULL,
Expires_at		DATETIME NOT NULL,
Used			BIT NOT NULL,		
FOREIGN KEY (User_id) REFERENCES Users(User_id)
)

-- LoginAttempt table
CREATE TABLE LoginAttempt (
Attempt_id		INT IDENTITY (1,1) PRIMARY KEY NOT NULL,
User_id		    INT NOT NULL,
Ip_address		NVARCHAR(14) NULL,
Email_address	NVARCHAR(256) NOT NULL,
Attempt_time	DATETIME NOT NULL,
Success		    BIT NOT NULL,
FOREIGN KEY (User_id) REFERENCES Users(User_id)
)

-- Insert sample user data
INSERT INTO Users
(Full_name, Email, Is_admin, Is_customer, Hashed_password, Salt, City, Country, Address, Phone_number, Verified, Disabled, Valid_from, Valid_to)

VALUES
('Alice Andersson', 'AliceAndersson@harrys.com', 1, 0, CONVERT(VARBINARY(128), 'f7a8723796d0493a379a9405c3521015f6f635c9'), '522b276a356bdf39013dfabea2cd43e1', 'Stockholm', 'Sweden', 'Tomtevägen 24', '0701234567', 1, 0, GETDATE(), DATEADD(YEAR, 1, GETDATE())),
('Bobby Claesson', 'Bobbybob@harrys.com', 0, 1, CONVERT(VARBINARY(128),'57c723644d98106beaee9042283bf0d2a8e7a6ff'), '4501c3b0336cf2d19ed69a8d0ec436ee3f88b31b', 'Stockholm', 'Sweden', 'Torget 3', '0702345678', 1, 0, GETDATE(), DATEADD(YEAR, 1, GETDATE())),
('Jimmy Svensson', 'Jimmy123@harrys.com', 0,1, CONVERT(VARBINARY(128), 'ed4f5bad5c091296dcb43340be25d93a030d368a'),'a02e841dc190f81e9f785e7f6e143cfb958409d8', 'Stockholm', 'Sweden', 'Torget 5','0703456789', 1, 0, GETDATE(), DATEADD(YEAR, 1, GETDATE())),
('Charlie Karlsson', 'KarlssonC@harrys.com', 0, 1, CONVERT(VARBINARY(128),'73a0c9366dc4c950c456a847ffe25213e37f3298'), 'd8cd10b920dcbdb5163ca0185e402357', 'Göteborg', 'Sweden', 'Apollogatan 22', '0704567890', 1, 0, GETDATE(), DATEADD(YEAR, 1, GETDATE())),
('Eva Larsson', 'Eva@harrys.com', 0, 1, CONVERT(VARBINARY(128), 'cb3881c8dc9663ac6325d8b27fba39e4826ccbe6'), '3da1befff5b5c75e2e99948ffb230642c19', 'Göteborg', 'Sweden', 'Apollogatan 21', '0705678901', 1, 0, GETDATE(), DATEADD(YEAR, 1, GETDATE()))


-- Insert sample login attempts
INSERT INTO LoginAttempt (User_id, Ip_address, Email_address, Attempt_time, Success)

VALUES 
(1, '192.168.7.85', 'AliceAndersson@harrys.com', GETDATE(), 1),
(2, '10.23.67.190', 'Bobbybob@harrys.com', GETDATE(), 1),
(3, '172.31.45.22', 'Jimmy123@harrys.com', GETDATE(), 1),
(4, '203.0.113.158', 'KarlssonC@harrys.com', GETDATE(), 1),
(5, '198.51.100.44', 'Eva@harrys.com', GETDATE(), 1),
(4, '203.0.113.158', 'KarlssonC@harrys.com', GETDATE(), 1),
(4, '203.0.113.158', 'KarlssonC@harrys.com', GETDATE(), 1)



-- View: Last successful and failed login per user
GO
CREATE VIEW UsersInformationView AS
WITH LatestLogins AS (
    SELECT 
        User_id,
        MAX(CASE WHEN Success = 1 THEN Attempt_time END) AS LatestSuccessfulLogin,
        MAX(CASE WHEN Success = 0 THEN Attempt_time END) AS LatestUnsuccessfulLogin
    FROM LoginAttempt
    GROUP BY User_id
)

SELECT 
    Email,
    Full_name,
    ll.LatestSuccessfulLogin,
    ll.LatestUnsuccessfulLogin
FROM Users u
LEFT JOIN LatestLogins ll ON u.User_id = ll.User_id
GO


SELECT * FROM UsersInformationView


-- View: Summary of login attempts by IP address

GO
CREATE VIEW LoginAttempstSummaryView AS 
	
	SELECT Attempt_id,
		   User_id,
		   Ip_address,
		   Email_address,
		   Attempt_time,
		   Success,   
		   COUNT(*) OVER (PARTITION BY Ip_address ORDER BY Attempt_time) AS TotalAttempts,
		   SUM(CASE WHEN Success = 1 THEN 1 ELSE 0 END) OVER (PARTITION BY Ip_address ORDER BY Attempt_time) AS SuccessfullAttempts,
		   SUM(CASE WHEN Success = 0 THEN 1 ELSE 0 END) OVER (PARTITION BY Ip_address ORDER BY Attempt_time) AS UnsuccessfullAttempts,
		   AVG(CASE WHEN Success = 1 THEN 1.0 ELSE 0 END) OVER (PARTITION BY Ip_address ORDER BY Attempt_time) AS AvgSuccessfullAttempts
	FROM LoginAttempt
GO

SELECT *
FROM LoginAttempstSummaryView
ORDER BY Attempt_id


-- Insert sample login attempts
INSERT INTO LoginAttempt (User_id, Ip_address, Email_address, Attempt_time, Success)
VALUES 
(1, '192.168.7.85', 'AliceAndersson@harrys.com', GETDATE(), 0),
(2, '10.23.67.190', 'Bobbybob@harrys.com', GETDATE(), 1),
(3, '172.31.45.22', 'Jimmy123@harrys.com', GETDATE(), 0),
(4, '203.0.113.158', 'KarlssonC@harrys.com', GETDATE(), 1),
(5, '198.51.100.44', 'Eva@harrys.com', GETDATE(), 1),
(2, '10.23.67.190', 'Bobbybob@harrys.com', GETDATE(), 0),
(2, '10.23.67.190', 'Bobbybob@harrys.com', GETDATE(), 0),
(2, '10.23.67.190', 'Bobbybob@harrys.com', GETDATE(), 0)


-- Stored procedure: TryLogin (with lockout handling)

GO
CREATE PROCEDURE TryLogin @Email VARCHAR(256), @Password VARBINARY(128), @IpAddress NVARCHAR(14)
AS
	BEGIN
		
		SET NOCOUNT ON

		IF OBJECT_ID('tempdb..##LoginLog') IS NOT NULL
		DROP TABLE ##LoginLog

	CREATE TABLE ##LoginLog (
		Log_id INT IDENTITY (1,1) PRIMARY KEY,
		User_id INT,
		Email VARCHAR(256),
		Ip_address NVARCHAR(14),
		Attempt_time DATETIME,
		Success BIT,
		Description VARCHAR(200)
)

	DECLARE @UserID INT
	DECLARE @StoredPassword VARBINARY(128)
	DECLARE @CurrentTime DATETIME = GETDATE()
	DECLARE @FailedCount INT

	SELECT @UserID = User_id, @StoredPassword = Hashed_password
	FROM Users
	WHERE @Email = Email


	IF @Password <> @StoredPassword
		BEGIN
			
			-- Insert sample login attempts
INSERT INTO LoginAttempt (User_id, Ip_address, Email_address, Attempt_time, Success)
			VALUES(@UserID, @IpAddress, @Email, @CurrentTime, 0)

		SELECT @FailedCount = Count(*)
		FROM LoginAttempt
		WHERE User_id = @UserID
		AND Success = 0
		AND Attempt_time BETWEEN DATEADD(MINUTE, -15, @CurrentTime) AND @CurrentTime

	IF @FailedCount = 3
		BEGIN 

			UPDATE Users
			SET Disabled = 1
			WHERE User_id = @UserID

			INSERT INTO ##LoginLog (User_id, Email, Ip_address, Attempt_time, Success, Description)
			VALUES (@UserID, @Email, @IpAddress, @CurrentTime, 0, 'Account locked due to 3 failed attempts in 15 minutes')
			SELECT * FROM ##LoginLog
			RETURN -1
		END

	ELSE IF @FailedCount > 1 AND @FailedCount < 3
	BEGIN

			INSERT INTO ##LoginLog (User_id, Email, Ip_address, Attempt_time, Success, Description)
			VALUES (@UserID, @Email, @IpAddress, @CurrentTime, 0, 'Wrong password')
			SELECT * FROM ##LoginLog
			RETURN -2
		END
	END

	ELSE
	BEGIN 
			-- Insert sample login attempts
INSERT INTO LoginAttempt (User_id, Ip_address, Email_address, Attempt_time, Success)
			VALUES(@UserID, @IpAddress, @Email, @CurrentTime, 1)
			
			INSERT INTO ##LoginLog (User_id, Email, Ip_address, Attempt_time, Success, Description)
			VALUES (@UserID, @Email, @IpAddress, @CurrentTime, 1, 'Login Successful')
			SELECT * FROM ##LoginLog
			RETURN 0
		END
	END



EXEC TryLogin'AliceAndersson@harrys.com', 0x66376138373233373936643034393361333739613934303563333532313031356636663633356339,'192.168.7.85'

-- Stored procedure: ForgotPassword (generates and stores reset token)
GO
CREATE PROCEDURE ForgotPassword @Email NVARCHAR(256)
AS
	BEGIN
		
		SET NOCOUNT ON

	DECLARE @UserID INT
	DECLARE @Token NVARCHAR(36)
	DECLARE @ExpiresAt DATETIME

	SELECT @UserID = User_id
	FROM Users
	WHERE Email = @Email

	IF @UserID IS NULL
		BEGIN
			PRINT ('User not found')
			RETURN -1
		END

	SET @Token = CONVERT(NVARCHAR(36), NEWID())
	SET @ExpiresAt = DATEADD(HOUR, 24, GETDATE())

	INSERT INTO Tokens (User_id, Token_value, Token_type, Created_at, Expires_at, Used)
	VALUES(@UserID, @Token, 'Password Reset', GETDATE(), @ExpiresAt, 0)

	PRINT('Password reset token sent to email')
	RETURN 0

END


EXEC ForgotPassword 'AliceAndersson@harrys.com'


SELECT * FROM Tokens


-- Stored procedure: SetForgottenPassword (verifies token and sets new password)
GO
CREATE PROCEDURE SetForgottenPassword @Email NVARCHAR(256), @NewPassword VARBINARY(128), @Token NVARCHAR(200)
AS
	BEGIN
		
		SET NOCOUNT ON

	DECLARE @UserID INT
	DECLARE @TokenValid BIT

	SELECT @UserID = User_id
	FROM Users
	WHERE Email = @Email

	IF @UserID IS NULL
		BEGIN
			PRINT ('User not found')
			RETURN -1
		END

	SELECT @TokenValid = CASE WHEN Expires_at > GETDATE() AND Used = 0 THEN 1 ELSE 0 END
	FROM Tokens
	WHERE User_id = @UserID
	AND Token_type = 'Password Reset'
	AND Token_value = @Token

	IF @TokenValid = 0
		BEGIN
			PRINT('Expired Token')
			RETURN -2
		END

	DECLARE @NewSalt VARBINARY(16) = CRYPT_GEN_RANDOM(16)
	DECLARE @NewHashedPassword VARBINARY(128) = HASHBYTES('SHA2_256', CONVERT(VARBINARY(128), @NewPassword) + @NewSalt)

	UPDATE Users
	SET Hashed_password = @NewHashedPassword, 
	Salt = CONVERT(NVARCHAR(50), @NewSalt, 2)
	WHERE User_id = @UserID

	UPDATE Tokens
	SET Used = 1
	WHERE Token_value = @Token
	AND User_id = @UserID

	PRINT('Password updated successfully')
	RETURN 0

END

EXEC SetForgottenPassword 'AliceAndersson@harrys.com', 0x66376138373233373936643034393361333739613934303563333532313031356636663633356339, '8D8189FD-F97B-44F9-A599-A4228B774083'


-- Indexing --

-- Indexing for Users table
CREATE NONCLUSTERED INDEX Users_Index 
ON Users (Email) 

-- Indexing for Tokens table
CREATE NONCLUSTERED INDEX Tokens_Index
ON Tokens (user_id, Token_value)

-- Indexing for LoginAttempt table
CREATE NONCLUSTERED INDEX LoginAttempt_Index
ON LoginAttempt (user_id, email_address, Attempt_time)
