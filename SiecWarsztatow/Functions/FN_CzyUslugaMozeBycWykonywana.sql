/****** Object:  UserDefinedFunction [dbo].[CzyUslugaMozeBycWykonywana]    Script Date: 09.01.2021 01:23:46 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[CzyUslugaMozeBycWykonywana] (@_PESEL VARCHAR (MAX), @_NAZWAUSLUGI varchar(MAX) )
	RETURNS BIT
	AS 
	BEGIN

		IF (
			NOT EXISTS(
					SELECT *
					FROM dbo.Pracownik AS P
						JOIN Pracownik_Na_Stanowisku_W_Serwisie AS PSS ON P.id = PSS.pracownik_id
						JOIN Stanowisko_w_serwisie AS SS ON PSS.stanowiskoWSerwisie_id = SS.id
						JOIN Stanowisko AS S ON SS.stanowisko_id = S.id
					WHERE P.PESEL = @_PESEL and s.id = (SELECT stanowisko_id	
														FROM dbo.Usluga
														WHERE nazwa = @_NAZWAUSLUGI)
					)
			)
		BEGIN
			RETURN 0
			--RAISERROR ('Pracownik nie ma uprawnien.', 16, 1)
		END
	RETURN 1
END
GO


