/****** Object:  UserDefinedFunction [dbo].[CzyGrafikZawieraSieWGodzinachOtwarciaSerwisu]    Script Date: 09.01.2021 01:22:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[CzyGrafikZawieraSieWGodzinachOtwarciaSerwisu] (@serwisId INT, @dataRozpoczeciaPracy DATETIME, @dataZakonczeniaPracy DATETIME)
	RETURNS BIT
	AS 
	BEGIN
		IF (
			NOT EXISTS
				(
				 SELECT *
				 FROM Serwis 
				 JOIN GrafikOtwarcia on GrafikOtwarcia.serwis_id = SErwis.id
				 WHERE Serwis.id = @serwisId AND
					   @dataRozpoczeciaPracy >= GrafikOtwarcia.data_otwarcia AND 
					   @dataZakonczeniaPracy <= GrafikOtwarcia.data_zamkniecia
				)
			)
		BEGIN
			RETURN 0
			--RAISERROR ('Grafik pracy dla danego pracownika nie zawiera siew godzinach otwarcia...', 16, 1)
		END
	RETURN 1
END
GO


