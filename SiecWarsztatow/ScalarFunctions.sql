/****** Object:  UserDefinedFunction [dbo].[CzyDanaCzescPasujeDoNaprawianegoSamochodu]    Script Date: 12.01.2021 10:05:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[CzyDanaCzescPasujeDoNaprawianegoSamochodu] (@CzescId INT, @idNaprawa int)
	RETURNS BIT
	AS 
	BEGIN

	IF NOT EXISTS
	(
		SELECT *
				FROM dbo.Czesc AS C
				JOIN dbo.CzescDoNaprawy AS CN on C.id = CN.czesc_id
				JOIN dbo.Naprawa AS N on CN.naprawa_id = N.id
				JOIN Zlecenie AS Z ON N.zlecenie_id = Z.id
				JOIN Samochod AS S ON Z.samochod_id = S.id
				JOIN Model AS M ON S.model_id = M.id
				JOIN Typ_nadwozia AS TN ON S.typNadwozia_id = TN.id
				WHERE M.id = (SELECT CzesciSamochodu.model_id
								FROM Czesc JOIN CzesciSamochodu ON Czesc.id = CzesciSamochodu.czesc_id
								WHERE CzesciSamochodu.id = @CzescId
							)
				AND TN.id = (	SELECT CzesciSamochodu.typNadwozia_id
								FROM Czesc JOIN CzesciSamochodu ON Czesc.id = CzesciSamochodu.czesc_id
								WHERE CzesciSamochodu.id = @CzescId
							) 
				AND CN.czesc_id = @CzescId AND CN.naprawa_id = @idNaprawa
	)
	BEGIN
		RETURN 0
	END

	RETURN 1
END
GO
/****** Object:  UserDefinedFunction [dbo].[CzyGrafikZawieraSieWGodzinachOtwarciaSerwisu]    Script Date: 12.01.2021 10:05:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- -3 FAILURE Dzien rozpoczecia pracy jest inny niz dzien zakonczenia
-- -2 FAILURE Data rozpoczecia jest niezgodna z wprowadzanym dniem tygodnia
-- -1 FAILURE Data zakonczenia jest niezgodna z wprowadzanym dniem tygodnia
--  0 FAILURE Grafik pracy dla danego pracownika nie zawiera sie w godzinach otwarcia serwisu
--  1 SUCCESS Grafik zawiera sie w Godzinach Otwarcia Serwisu
CREATE FUNCTION [dbo].[CzyGrafikZawieraSieWGodzinachOtwarciaSerwisu] (@pracownikId INT, @dataRozpoczeciaPracy DATETIME, @dataZakonczeniaPracy DATETIME, @dzienTygodniaId INT)
	RETURNS INT 

	AS 
	BEGIN

	DECLARE @dzienTygodniaRozpoczeciaPracySlownie VARCHAR(MAX)
	DECLARE @dzienTygodniaZakonczeniaPracySlownie VARCHAR(MAX)
	DECLARE @wprowadzonyDzienTygodniaslownie VARCHAR(MAX)

	SET @wprowadzonyDzienTygodniaslownie = (SELECT DzienTygodnia.nazwa 
											FROM DzienTygodnia 
											WHERE DzienTygodnia.id = @dzienTygodniaId)

	SET @dzienTygodniaRozpoczeciaPracySlownie = DATENAME(WEEKDAY, @dataRozpoczeciaPracy)
	SET @dzienTygodniaZakonczeniaPracySlownie = DATENAME(WEEKDAY, @dataZakonczeniaPracy)

	
	IF @wprowadzonyDzienTygodniaslownie != @dzienTygodniaRozpoczeciaPracySlownie
		RETURN -1
	ELSE IF
		@wprowadzonyDzienTygodniaslownie != @dzienTygodniaZakonczeniaPracySlownie
		RETURN -2
	ELSE IF
		@dzienTygodniaRozpoczeciaPracySlownie != @dzienTygodniaZakonczeniaPracySlownie
		RETURN -3

	DECLARE @SerwisId INT

	SELECT @SerwisId = Serwis.id
		FROM Pracownik
		join Serwis on Pracownik.serwis_id = Serwis.id
		JOIN Pracownik_Na_Stanowisku_W_Serwisie as PNSWS on PNSWS.pracownik_id = Pracownik.id
		JOIN Stanowisko_w_serwisie on Stanowisko_w_serwisie.id = PNSWS.stanowiskoWSerwisie_id
		WHERE Pracownik.id = @pracownikId

		--komentarz do porównywania dat:  
		--istnieja bardziej optymalne metody porownywania daty i godziny
		IF (
			NOT EXISTS
				(
				 SELECT *
				 FROM Serwis 
				 JOIN GrafikOtwarcia on GrafikOtwarcia.serwis_id = Serwis.id
				 JOIN Pracownik on Pracownik.serwis_id = Serwis.id
				 join Pracownik_Na_Stanowisku_W_Serwisie on Pracownik_Na_Stanowisku_W_Serwisie.pracownik_id = Pracownik.id
				 WHERE Serwis.id = @serwisId 
				 AND DATEPART(year, @dataRozpoczeciaPracy) >= DATEPART(year,data_otwarcia)
				 AND DATEPART(month, @dataRozpoczeciaPracy) >= DATEPART(month, data_otwarcia)
				 AND DATEPART(day, @dataRozpoczeciaPracy) >=  DATEPART(DAY, data_otwarcia)
				 AND DATEPART(hh, @dataRozpoczeciaPracy) >= DATEPART(hh, data_otwarcia)
				 AND DATEPART(mi, @dataRozpoczeciaPracy) >= DATEPART(mi, data_otwarcia)
				 AND DATEPART(year, @dataZakonczeniaPracy) <= DATEPART(year, data_zamkniecia)
				 AND DATEPART(month, @dataZakonczeniaPracy) <= DATEPART(month, data_zamkniecia)
				 AND DATEPART(day, @dataZakonczeniaPracy) <=  DATEPART(DAY, data_zamkniecia)
				 AND DATEPART(hh, @dataZakonczeniaPracy) <= DATEPART(hh, data_zamkniecia)
				 AND DATEPART(mi, @dataZakonczeniaPracy) <= DATEPART(mi, data_zamkniecia))
			)
		BEGIN
			RETURN 0
			--RAISERROR ('Grafik pracy dla danego pracownika nie zawiera sie w godzinach otwarcia...', 16, 1)
		END
	RETURN 1
END
GO
/****** Object:  UserDefinedFunction [dbo].[CzyIstniejeGrafikOtwarcia]    Script Date: 12.01.2021 10:05:35 ******/
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
/****** Object:  UserDefinedFunction [dbo].[CzyIstniejeJuzTakiPracownikDlaStanowiskaWSerwisie]    Script Date: 12.01.2021 10:05:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[CzyIstniejeJuzTakiPracownikDlaStanowiskaWSerwisie] (@pracownikId INT, @IDStanowiskoWSerwisie INT)
	RETURNS BIT
	AS 
	BEGIN

		IF  
				EXISTS
				(
							SELECT *
							FROM dbo.Pracownik_Na_Stanowisku_W_Serwisie as PNSWS
							WHERE PNSWS.pracownik_id = @pracownikId AND PNSWS.stanowiskoWSerwisie_id = @IDStanowiskoWSerwisie
				)
		BEGIN
			RETURN 1
			--RAISERROR ('Takie przypisanie juz istnieje.', 16, 1)
		END
	RETURN 0
END
GO
/****** Object:  UserDefinedFunction [dbo].[CzyIstniejeStanowiskoDlaUslugi]    Script Date: 12.01.2021 10:05:35 ******/
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
/****** Object:  UserDefinedFunction [dbo].[CzyPracownikPrzypisanyDoStanowiskaWSerwisie]    Script Date: 12.01.2021 10:05:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[CzyPracownikPrzypisanyDoStanowiskaWSerwisie] (@pracownikId INT, @StanowiskoWSerwisieId INT)
	RETURNS BIT
	AS 
	BEGIN

	IF NOT EXISTS
	(
		SELECT *
			FROM dbo.Pracownik as P
			JOIN dbo.Stanowisko_w_serwisie as SWS on SWS.serwis_id = P.serwis_id
			WHERE P.id = @pracownikId and SWS.id = @StanowiskoWSerwisieId
	)
	BEGIN
		RETURN 0
	END

	RETURN 1
END
GO
/****** Object:  UserDefinedFunction [dbo].[CzyUslugaMozeBycWykonywana]    Script Date: 12.01.2021 10:05:35 ******/
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
/****** Object:  UserDefinedFunction [dbo].[CzyWszystkieNaprawyZamknieteDlaZlecenia]    Script Date: 12.01.2021 10:05:35 ******/
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
/****** Object:  UserDefinedFunction [dbo].[fn_diagramobjects]    Script Date: 12.01.2021 10:05:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE FUNCTION [dbo].[fn_diagramobjects]() 
	RETURNS int
	WITH EXECUTE AS N'dbo'
	AS
	BEGIN
		declare @id_upgraddiagrams		int
		declare @id_sysdiagrams			int
		declare @id_helpdiagrams		int
		declare @id_helpdiagramdefinition	int
		declare @id_creatediagram	int
		declare @id_renamediagram	int
		declare @id_alterdiagram 	int 
		declare @id_dropdiagram		int
		declare @InstalledObjects	int

		select @InstalledObjects = 0

		select 	@id_upgraddiagrams = object_id(N'dbo.sp_upgraddiagrams'),
			@id_sysdiagrams = object_id(N'dbo.sysdiagrams'),
			@id_helpdiagrams = object_id(N'dbo.sp_helpdiagrams'),
			@id_helpdiagramdefinition = object_id(N'dbo.sp_helpdiagramdefinition'),
			@id_creatediagram = object_id(N'dbo.sp_creatediagram'),
			@id_renamediagram = object_id(N'dbo.sp_renamediagram'),
			@id_alterdiagram = object_id(N'dbo.sp_alterdiagram'), 
			@id_dropdiagram = object_id(N'dbo.sp_dropdiagram')

		if @id_upgraddiagrams is not null
			select @InstalledObjects = @InstalledObjects + 1
		if @id_sysdiagrams is not null
			select @InstalledObjects = @InstalledObjects + 2
		if @id_helpdiagrams is not null
			select @InstalledObjects = @InstalledObjects + 4
		if @id_helpdiagramdefinition is not null
			select @InstalledObjects = @InstalledObjects + 8
		if @id_creatediagram is not null
			select @InstalledObjects = @InstalledObjects + 16
		if @id_renamediagram is not null
			select @InstalledObjects = @InstalledObjects + 32
		if @id_alterdiagram  is not null
			select @InstalledObjects = @InstalledObjects + 64
		if @id_dropdiagram is not null
			select @InstalledObjects = @InstalledObjects + 128
		
		return @InstalledObjects 
	END
	
GO
/****** Object:  UserDefinedFunction [dbo].[GetStatus]    Script Date: 12.01.2021 10:05:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetStatus](@nazwaStatus varchar(max))  
RETURNS INT   
	AS   
	BEGIN  
		DECLARE @ret INT = -1;
		SET @ret = (SELECT TOP 1 id FROM [dbo.].[Status]
		WHERE nazwa = @nazwaStatus)
		RETURN @ret
	END
GO
/****** Object:  UserDefinedFunction [dbo].[ZamienIdBleduNaTekst]    Script Date: 12.01.2021 10:05:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- -3 FAILURE Dzien rozpoczecia pracy jest inny niz dzien zakonczenia
-- -2 FAILURE Data rozpoczecia jest niezgodna z wprowadzanym dniem tygodnia
-- -1 FAILURE Data zakonczenia jest niezgodna z wprowadzanym dniem tygodnia
--  0 FAILURE Grafik pracy dla danego pracownika nie zawiera sie w godzinach otwarcia serwisu
--  1 SUCCESS Grafik zawiera sie w Godzinach Otwarcia Serwisu
CREATE FUNCTION [dbo].[ZamienIdBleduNaTekst] (@numerBledu INT)
	RETURNS VARCHAR(MAX) 
	AS 
	BEGIN

		DECLARE @result VARCHAR(MAX) 



		SET @Result = 
		CASE
			WHEN @numerBledu = -3 THEN 'FAILURE: Dzien rozpoczecia pracy jest inny niz dzien zakonczenia'
			WHEN @numerBledu = -2 THEN 'FAILURE: Data rozpoczecia jest niezgodna z wprowadzanym dniem tygodnia'
			WHEN @numerBledu = -1 THEN 'FAILURE: Data zakonczenia jest niezgodna z wprowadzanym dniem tygodnia'
			WHEN @numerBledu = 0 THEN  'FAILURE: Grafik pracy dla danego pracownika nie zawiera sie w godzinach otwarcia serwisu'
			WHEN @numerBledu = 1 THEN  'SUCCESS: Grafik zawiera sie w Godzinach Otwarcia Serwisu'
			ELSE
				'FAILURE Napotkano nieoczekiwany kod bledu'
		END

		RETURN @Result +  'Kod: <<' + CONVERT(VARCHAR(MAX), @numerBledu) + '>>'

	END
GO
