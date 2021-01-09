/****** Object:  UserDefinedFunction [dbo].[CzyPracownikPrzyPisanyDoSerwisu]    Script Date: 09.01.2021 01:23:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[CzyPracownikPrzyPisanyDoSerwisu] (@pracownikId INT)
	RETURNS BIT
	AS 
	BEGIN

	IF NOT EXISTS
	(
		SELECT *
			FROM dbo.Pracownik AS P
			JOIN dbo.Pracownik_Na_Stanowisku_W_Serwisie AS PSS on P.id = PSS.pracownik_id
			JOIN dbo.Stanowisko_w_serwisie AS SS on PSS.stanowiskoWSerwisie_id = SS.id
			JOIN Serwis AS S ON SS.serwis_id = S.id
			WHERE P.serwis_id = SS.serwis_id AND P.id = @pracownikId
	)
	BEGIN
		RETURN 0
	END

	RETURN 1
END
GO


