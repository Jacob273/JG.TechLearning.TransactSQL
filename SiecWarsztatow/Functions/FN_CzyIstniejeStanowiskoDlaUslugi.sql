/****** Object:  UserDefinedFunction [dbo].[CzyIstniejeStanowiskoDlaUslugi]    Script Date: 09.01.2021 01:23:08 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

	CREATE FUNCTION [dbo].[CzyIstniejeStanowiskoDlaUslugi] (@uslugaId int)
	RETURNS BIT
	AS 
	BEGIN
		DECLARE @result BIT = 0

		IF (
			NOT EXISTS(
					SELECT stanowisko_id 
					from dbo.Usluga
					JOIN Stanowisko on Stanowisko.id = Usluga.stanowisko_id
					)
			)
		BEGIN
			RETURN 0
			--RAISERROR ('Brak stanowiska do wykonywania takiej uslugi.', 16, 1)
		END
	RETURN 1
END
GO


