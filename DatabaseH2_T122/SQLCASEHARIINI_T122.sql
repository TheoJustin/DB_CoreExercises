-- No 1
DROP PROCEDURE sp_PrintMonthlyReport;
GO
CREATE PROCEDURE sp_PrintMonthlyReport(
	@Year INT,
	@Month INT
)
AS
BEGIN
	DECLARE @FormattedMonth VARCHAR(3) = RIGHT('00' + CAST(@Month AS VARCHAR(2)), 2);
	DECLARE @FormattedYear VARCHAR(3) = RIGHT('0000' + CAST(@Year AS VARCHAR(4)), 2);
	DECLARE @Revenue DECIMAL(10,2)
	DECLARE @CustomerCount INT
	SELECT  @Revenue = SUM(amount), @CustomerCount = COUNT(DISTINCT customer_id)
	FROM payment
	WHERE MONTH(payment_date) = @FormattedMonth AND RIGHT(CAST(YEAR(payment_date) AS VARCHAR(4)), 2) = @FormattedYear
	IF @CustomerCount != 0
	BEGIN
		PRINT '==================================='
		PRINT 'Monthly Report -  Period: '+ @FormattedYear + @FormattedMonth
		PRINT 'Revenue: $' + CAST(@Revenue AS VARCHAR(100))
		PRINT 'Customer Count: '+CAST(@CustomerCount AS VARCHAR(100)) + ' person(s)'
		PRINT '==================================='
	END
	ELSE
	BEGIN
		PRINT 'No transaction occured in that month'
	END
END
EXEC sp_PrintMonthlyReport '2005','2'
EXEC sp_PrintMonthlyReport '2006','2'
GO
-- No 2
DROP PROCEDURE sp_Top5CountryWithMostCustomer;
GO
CREATE PROCEDURE sp_Top5CountryWithMostCustomer
AS
BEGIN
	SELECT TOP(5)country.country AS [country], COUNT([address].phone) AS [customer_count]
	FROM country
	JOIN city ON country.country_id = city.country_id
	JOIN [address] ON [address].city_id = city.city_id
	GROUP BY country.country
	ORDER BY COUNT([address].phone) DESC
END;
GO
EXEC sp_Top5CountryWithMostCustomer

-- No 3
GO

DROP FUNCTION HashStaffPassword;
GO
CREATE FUNCTION HashStaffPassword (@inputString NVARCHAR(MAX))
RETURNS NVARCHAR(64) AS
BEGIN
    DECLARE @hashedPassword VARBINARY(32)
    SET @hashedPassword = HASHBYTES('SHA2_256', @inputString)
    
    RETURN (SELECT CONVERT(NVARCHAR(64), @hashedPassword, 2))
END


GO
SELECT dbo.HashStaffPassword('Veryveryveryconfidentialpassword22-2')

-- No 4
GO
CREATE PROCEDURE sp_RemovedUnusuedLanguage
AS
BEGIN
	DELETE FROM language
	WHERE NOT EXISTS(
		SELECT *
		FROM film
		WHERE film.language_id = language.language_id
	)
END

SELECT * FROM language
EXEC sp_RemovedUnusuedLanguage
SELECT * FROM language

-- No 5
GO
DROP FUNCTION ChangeMinutesToDurationFormat;
GO
CREATE FUNCTION ChangeMinutesToDurationFormat (@minutes INT)
RETURNS VARCHAR(8) AS
BEGIN
    DECLARE @tempTime DATETIME
    SET @tempTime = DATEADD(MINUTE, @minutes, 0)
    RETURN CONVERT(VARCHAR(8), @tempTime, 108)
END
GO
SELECT dbo.ChangeMinutesToDurationFormat(153)
GO
-- No 6
GO
DROP FUNCTION ToPascalCase;
GO
CREATE FUNCTION ToPascalCase (@inputString VARCHAR(MAX))
RETURNS VARCHAR(MAX)
AS
BEGIN
    DECLARE @resultString VARCHAR(MAX)
    SET @inputString = LOWER(@inputString)
    SET @resultString = UPPER(SUBSTRING(@inputString, 1, 1))
    DECLARE @idx INT = 2
    WHILE @idx <= LEN(@inputString)
    BEGIN
        IF SUBSTRING(@inputString, @idx - 1, 1) = ' '
        BEGIN
            SET @resultString += UPPER(SUBSTRING(@inputString, @idx, 1))
        END
        ELSE
        BEGIN
            SET @resultString += SUBSTRING(@inputString, @idx, 1)
        END
        SET @idx += 1
    END
    RETURN @resultString
END

GO
SELECT dbo.ToPascalCase('kevin josafat anderson christian yonain')
SELECT dbo.ToPascalCase('MARCHEL HERMANLIANSYAH')

-- No 7
GO
CREATE FUNCTION PreferredMovieRatingPercentage ()
RETURNS @tableResult TABLE(
	rating VARCHAR (30),
	[percentage] VARCHAR (6)
) 
AS
BEGIN
	DECLARE @totalCount DECIMAL(6)
	SELECT @totalCount = COUNT(*) FROM film
	INSERT INTO @tableResult
	SELECT rating, CAST(CAST(COUNT(*)*100/@totalCount AS DECIMAL(5,2))AS VARCHAR(6))+'%' AS [percentage] FROM film
	GROUP BY rating
	RETURN
END

GO
SELECT * FROM dbo.PreferredMovieRatingPercentage()
GO

-- No 8
GO
DROP TRIGGER IsInactiveTrigger;
GO
CREATE TRIGGER IsInactiveTrigger
ON rental
INSTEAD OF INSERT
AS
BEGIN
	IF NOT EXISTS(
		SELECT 1
		FROM customer c
		JOIN inserted i ON c.customer_id = i.customer_id
		WHERE c.active = 1
	)
	BEGIN
		THROW 50000, 'The transaction ended in the trigger. The batch has been aborted.', 1
		ROLLBACK TRANSACTION
	END
	IF EXISTS(
	SELECT 1
		FROM customer c
		JOIN inserted i ON c.customer_id = i.customer_id
		WHERE c.active = 1
	)
	BEGIN
		INSERT INTO rental
		SELECT rental_id, rental_date, inventory_id, customer_id, return_date, staff_id, last_update
		FROM inserted
	END
END

GO
INSERT INTO rental VALUES (16050, GETDATE(), 1420, 16, NULL, 1, GETDATE())

GO
-- No 9
CREATE TRIGGER CantUpdateAdmin
ON staff
FOR INSERT, UPDATE, DELETE
AS
BEGIN
  print 'This data is fixed, you can''t perform any changes to this table!'
  ROLLBACK TRANSACTION;
END
UPDATE staff SET first_name = 'Udin' WHERE staff_id = 1

-- No 10
GO

CREATE TRIGGER PaymentTrigger
ON payment
AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @RentalID INT
	DECLARE @CustomerID INT
	DECLARE @Amount INT
	DECLARE @Price INT
	DECLARE @ReturnDate DATETIME

	SELECT @RentalID = rental_id, @CustomerID = customer_id, @Amount = amount
	FROM inserted

	IF EXISTS(
		SELECT 1
		FROM rental
		WHERE rental_id = @RentalID AND return_date IS NOT NULL
	)
	BEGIN
		PRINT 'Payment failed. The rental has been returned previously.'
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT @Price = CEILING(rental_rate * DATEDIFF(DAY, rental_date, return_date))
	FROM rental r
	JOIN inventory i ON i.inventory_id = r.inventory_id
	JOIN film f ON f.film_id = i.inventory_id
	WHERE rental_id = @RentalID

	if @Amount < @Price
	BEGIN
		PRINT 'Payment failed. The payment amount is less than the amount to pay.'
		ROLLBACK TRANSACTION
		RETURN
	END

	UPDATE rental
	SET return_date = GETDATE()
	WHERE rental_id = @RentalID

	PRINT 'Payment Successful. Rental return date has been updated to the current date and time.'
END


INSERT INTO payment VALUES (16050, 599, 2, 11496, 3800.00, GETDATE(), GETDATE())
INSERT INTO payment VALUES (16051, 599, 2, 1, 3810.00, GETDATE(), GETDATE())


-- No 11
GO
DECLARE ChangeTitleFormat CURSOR
FOR SELECT title, film_id FROM film

DECLARE @currTitle VARCHAR(255), @currID INT
OPEN ChangeTitleFormat
FETCH NEXT FROM ChangeTitleFormat INTO
@currTitle, @currID

WHILE @@FETCH_STATUS = 0
BEGIN	
	DECLARE @newTitle VARCHAR(255) = dbo.ToPascalCase(@currTitle)
	UPDATE film
	SET title = @newTitle
	WHERE CURRENT OF ChangeTitleFormat

	PRINT 'Film id ' + CAST(@currID AS VARCHAR) + ' = ' + @newTitle

	FETCH NEXT FROM ChangeTitleFormat INTO
	@currTitle, @currID
END

CLOSE ChangeTitleFormat
DEALLOCATE ChangeTitleFormat
GO

GO
-- no 18
DROP FUNCTION GetInactiveCustomer;
GO
CREATE FUNCTION dbo.GetInactiveCustomer()
RETURNS @InactiveCustomers TABLE (
    customer_code VARCHAR(50),
    customer_full_name VARCHAR(100)
)
AS
BEGIN
    INSERT INTO @InactiveCustomers (customer_code, customer_full_name)
    SELECT 
        CONCAT(
            LEFT(first_name, 1), 
            LEFT(last_name, 1),
            LEFT(customer_id, 1), 
			RIGHT(customer_id, 1)
        ) AS customer_code,
        CONCAT(first_name, ' ', last_name) AS customer_full_name
    FROM customer
    WHERE active = 0 
    RETURN
END
GO
SELECT * FROM dbo.GetInactiveCustomer()
GO
-- No 19
CREATE PROCEDURE GenerateShortStockedFilm
AS
BEGIN
	SELECT
		s.store_id,
		CONCAT(f.title, '[',f.rating, ']') AS [film],
		COUNT(i.film_id) AS [film_count]
	FROM store s
	JOIN inventory i ON i.store_id = s.store_id
	JOIN film f ON f.film_id = i.film_id
	GROUP BY s.store_id, f.title, f.rating
	HAVING COUNT(i.film_id) <(SELECT AVG(stock_count)
		FROM(SELECT COUNT(film_id) AS stock_count 
			FROM inventory
			GROUP BY store_id, film_id) AS stock_avg)
END

EXEC GenerateShortStockedFilm
GO

GO
-- No 27
CREATE TRIGGER InsertCategoryTrigger
ON category FOR INSERT
AS
BEGIN
	DECLARE @count INT
	DECLARE @newCategory VARCHAR(MAX)
	SELECT @newCategory = [name] FROM inserted
	SELECT @count = COUNT(*) FROM category
	WHERE category.name = @newCategory
	GROUP BY category.name

	IF @count > 1
	BEGIN
		PRINT 'Can''t insert the new category, because it''s duplicate!'
		ROLLBACK TRANSACTION
	END
END

GO
-- No 28
CREATE TRIGGER ActorUpdateTrigger
ON actor
AFTER UPDATE
AS
BEGIN
    IF UPDATE(first_name) OR UPDATE(last_name)
    BEGIN
        DECLARE @old_name VARCHAR(255)
        DECLARE @new_name VARCHAR(255)
        SELECT @old_name = CONCAT(first_name, ' ', last_name)
        FROM deleted
        SELECT @new_name = CONCAT(first_name, ' ', last_name)
        FROM inserted
        PRINT @old_name + 'change their stage name from ' + @old_name + 'to ' + @new_name
    END
END

UPDATE actor SET first_name = 'Jaysie' WHERE actor_id = 150
UPDATE actor SET last_name = 'Christian' WHERE actor_id = 127
GO

