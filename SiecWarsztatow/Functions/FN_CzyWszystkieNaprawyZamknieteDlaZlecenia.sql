/****** Object:  UserDefinedFunction [dbo].[CzyWszystkieNaprawyZamknieteDlaZlecenia]    Script Date: 09.01.2021 01:24:01 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[CzyWszystkieNaprawyZamknieteDlaZlecenia] (@zlecenieId INT)
	RETURNS BIT
	AS 
	BEGIN

	DECLARE @wszystkieNaprawy BIT
	DECLARE @wszystkieNaprawyWZleceniu INT = NULL;     
	DECLARE @zamknieteNaprawyWZleceniu INT = NULL;     

	SET @wszystkieNaprawyWZleceniu = (SELECT COUNT(*) FROM Naprawa
							WHERE Naprawa.zlecenie_id = @zlecenieId)

	SET @zamknieteNaprawyWZleceniu = (SELECT COUNT(*)
							FROM Naprawa
							WHERE Naprawa.zlecenie_id = @zlecenieId AND 
								  Naprawa.status_id = 1 -- zamkniety status
							)

	IF @wszystkieNaprawy = @wszystkieNaprawyWZleceniu AND @zamknieteNaprawyWZleceniu != NULL
	BEGIN
		RETURN 1
	END
	RETURN 0
END
GO


