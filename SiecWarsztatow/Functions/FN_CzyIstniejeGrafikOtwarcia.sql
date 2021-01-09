/****** Object:  UserDefinedFunction [dbo].[CzyIstniejeGrafikOtwarcia]    Script Date: 09.01.2021 01:22:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[CzyIstniejeGrafikOtwarcia] (@serwisID int, @start_date DATETIME, @end_date DATETIME)
RETURNS BIT
AS 
BEGIN
    DECLARE @result BIT = 0
	DECLARE @id INT = NULL

SET @id = (SELECT dbo.GrafikOtwarcia.serwis_id
		FROM dbo.GrafikOtwarcia
		WHERE serwis_id = @serwisID AND dbo.GrafikOtwarcia.data_otwarcia >= @start_date AND dbo.GrafikOtwarcia.data_zamkniecia <= @end_date )

	IF(@id is not null)
		BEGIN
			SET @result = 1
		--RAISERROR ('Serwis otwarty jest w innych godzinach nie mozna stworzyc grafiku', 16, 1)
		END

RETURN @result
END;
GO


