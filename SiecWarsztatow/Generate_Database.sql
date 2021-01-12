/****** Object:  UserDefinedFunction [dbo].[CzyDanaCzescPasujeDoNaprawianegoSamochodu]    Script Date: 12.01.2021 09:51:42 ******/
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
/****** Object:  UserDefinedFunction [dbo].[CzyGrafikZawieraSieWGodzinachOtwarciaSerwisu]    Script Date: 12.01.2021 09:51:42 ******/
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
/****** Object:  UserDefinedFunction [dbo].[CzyIstniejeGrafikOtwarcia]    Script Date: 12.01.2021 09:51:42 ******/
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
/****** Object:  UserDefinedFunction [dbo].[CzyIstniejeJuzTakiPracownikDlaStanowiskaWSerwisie]    Script Date: 12.01.2021 09:51:42 ******/
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
/****** Object:  UserDefinedFunction [dbo].[CzyIstniejeStanowiskoDlaUslugi]    Script Date: 12.01.2021 09:51:42 ******/
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
/****** Object:  UserDefinedFunction [dbo].[CzyPracownikPrzypisanyDoStanowiskaWSerwisie]    Script Date: 12.01.2021 09:51:42 ******/
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
/****** Object:  UserDefinedFunction [dbo].[CzyUslugaMozeBycWykonywana]    Script Date: 12.01.2021 09:51:42 ******/
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
/****** Object:  UserDefinedFunction [dbo].[CzyWszystkieNaprawyZamknieteDlaZlecenia]    Script Date: 12.01.2021 09:51:42 ******/
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
/****** Object:  UserDefinedFunction [dbo].[fn_diagramobjects]    Script Date: 12.01.2021 09:51:42 ******/
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
/****** Object:  UserDefinedFunction [dbo].[GetStatus]    Script Date: 12.01.2021 09:51:42 ******/
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
/****** Object:  UserDefinedFunction [dbo].[ZamienIdBleduNaTekst]    Script Date: 12.01.2021 09:51:42 ******/
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
/****** Object:  Table [dbo].[Czesc]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Czesc](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[nazwa] [nvarchar](250) NULL,
	[opis] [nvarchar](250) NOT NULL,
	[nrKatalogowy] [nvarchar](250) NOT NULL,
	[cena] [decimal](18, 0) NOT NULL,
 CONSTRAINT [PK_Czesc] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CzescDoNaprawy]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CzescDoNaprawy](
	[id] [int] NOT NULL,
	[czesc_id] [int] NOT NULL,
	[naprawa_id] [int] NOT NULL,
 CONSTRAINT [PK_CzescDoNaprawy] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CzesciSamochodu]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CzesciSamochodu](
	[id] [int] NOT NULL,
	[czesc_id] [int] NULL,
	[model_id] [int] NULL,
	[typNadwozia_id] [int] NULL,
 CONSTRAINT [PK_CzesciSamochodu] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CzesciWZamowieniu]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CzesciWZamowieniu](
	[id] [int] NOT NULL,
	[czesc_id] [int] NOT NULL,
	[zamowienie_id] [int] NOT NULL,
 CONSTRAINT [PK_CzesciWZamowieniu] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DzienTygodnia]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DzienTygodnia](
	[id] [int] NOT NULL,
	[nazwa] [nvarchar](250) NULL,
 CONSTRAINT [PK_DzienTygodnia] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[GrafikOtwarcia]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GrafikOtwarcia](
	[serwis_id] [bigint] NOT NULL,
	[dzienTygodnia_id] [int] NOT NULL,
	[data_otwarcia] [datetime2](7) NOT NULL,
	[data_zamkniecia] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_GrafikOtwarcia] PRIMARY KEY CLUSTERED 
(
	[serwis_id] ASC,
	[dzienTygodnia_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[GrafikPracy]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GrafikPracy](
	[pracownik_id] [bigint] NOT NULL,
	[dzienTygodnia_id] [int] NOT NULL,
	[data_rozpoczecia] [datetime2](7) NOT NULL,
	[data_zakonczenia] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_GrafikPracy] PRIMARY KEY CLUSTERED 
(
	[pracownik_id] ASC,
	[dzienTygodnia_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Klient]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Klient](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[imie] [nvarchar](250) NOT NULL,
	[nazwisko] [nvarchar](250) NOT NULL,
	[PESEL] [nvarchar](250) NOT NULL,
	[tel_komorkowy] [int] NOT NULL,
	[email] [nvarchar](250) NOT NULL,
 CONSTRAINT [PK_Klient] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Marka]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Marka](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[nazwa] [nvarchar](250) NOT NULL,
 CONSTRAINT [PK_Marka] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Model]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Model](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[marka_id] [int] NULL,
	[nazwa] [nvarchar](250) NOT NULL,
 CONSTRAINT [PK_Model] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Naprawa]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Naprawa](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pracownikNaStanowiskuWSerwisie_id] [int] NOT NULL,
	[usluga_id] [int] NOT NULL,
	[status_id] [bigint] NOT NULL,
	[zlecenie_id] [bigint] NOT NULL,
	[opis] [nvarchar](250) NOT NULL,
	[data_realizacji] [datetime] NOT NULL,
 CONSTRAINT [PK_Naprawa] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Pracownik]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Pracownik](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[serwis_id] [bigint] NOT NULL,
	[imie] [nvarchar](250) NOT NULL,
	[nazwisko] [nvarchar](2500) NOT NULL,
	[PESEL] [bigint] NOT NULL,
 CONSTRAINT [PK_Pracownik] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Pracownik_Na_Stanowisku_W_Serwisie]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Pracownik_Na_Stanowisku_W_Serwisie](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[stanowiskoWSerwisie_id] [bigint] NOT NULL,
	[pracownik_id] [bigint] NOT NULL,
 CONSTRAINT [PK_PracownikNaStanowiskuWSerwisie] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Rachunek]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Rachunek](
	[id] [bigint] NOT NULL,
	[kwota] [numeric](18, 0) NOT NULL,
	[opis] [nvarchar](250) NULL,
	[zlecenie_id] [bigint] NOT NULL,
	[numer] [nvarchar](250) NOT NULL,
 CONSTRAINT [PK_Rachunek] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Samochod]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Samochod](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[model_id] [int] NOT NULL,
	[typNadwozia_id] [int] NOT NULL,
	[klient_id] [int] NOT NULL,
	[numer_rejestracyjny] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_Samochod] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Serwis]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Serwis](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[nazwa] [nvarchar](250) NOT NULL,
	[miasto] [nvarchar](250) NOT NULL,
	[ulica] [nchar](50) NOT NULL,
	[numer_budynku] [int] NOT NULL,
	[numer_telefonu] [int] NOT NULL,
 CONSTRAINT [PK_Serwis] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Stanowisko]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Stanowisko](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[nazwa] [nvarchar](250) NOT NULL,
	[opis] [nvarchar](250) NOT NULL,
 CONSTRAINT [PK_Stanowisko] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Stanowisko_w_serwisie]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Stanowisko_w_serwisie](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[stanowisko_id] [int] NOT NULL,
	[serwis_id] [bigint] NOT NULL,
 CONSTRAINT [PK_Stanowisko_w_serwisie] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Status]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Status](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[nazwa] [nvarchar](250) NULL,
 CONSTRAINT [PK_Status] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[sysdiagrams]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[sysdiagrams](
	[name] [sysname] NOT NULL,
	[principal_id] [int] NOT NULL,
	[diagram_id] [int] IDENTITY(1,1) NOT NULL,
	[version] [int] NULL,
	[definition] [varbinary](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[diagram_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UK_principal_name] UNIQUE NONCLUSTERED 
(
	[principal_id] ASC,
	[name] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Typ_nadwozia]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Typ_nadwozia](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[nazwa] [nvarchar](250) NOT NULL,
 CONSTRAINT [PK_Typ_nadwozia] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Usluga]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Usluga](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[nazwa] [nvarchar](250) NOT NULL,
	[cena] [decimal](18, 0) NULL,
	[stanowisko_id] [bigint] NOT NULL,
 CONSTRAINT [PK_Usluga] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Zamowienie]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Zamowienie](
	[id] [int] NOT NULL,
	[pracownik_id] [bigint] NOT NULL,
	[opis] [nvarchar](250) NULL,
 CONSTRAINT [PK_Zamowienie] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Zlecenie]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Zlecenie](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[data_rozpoczecia] [datetime2](7) NOT NULL,
	[samochod_id] [int] NOT NULL,
	[status_id] [bigint] NOT NULL,
 CONSTRAINT [PK_Zlecenie] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CzescDoNaprawy]  WITH CHECK ADD  CONSTRAINT [FK_CzescDoNaprawy_Czesc] FOREIGN KEY([czesc_id])
REFERENCES [dbo].[Czesc] ([id])
GO
ALTER TABLE [dbo].[CzescDoNaprawy] CHECK CONSTRAINT [FK_CzescDoNaprawy_Czesc]
GO
ALTER TABLE [dbo].[CzescDoNaprawy]  WITH CHECK ADD  CONSTRAINT [FK_CzescDoNaprawy_Naprawa] FOREIGN KEY([naprawa_id])
REFERENCES [dbo].[Naprawa] ([id])
GO
ALTER TABLE [dbo].[CzescDoNaprawy] CHECK CONSTRAINT [FK_CzescDoNaprawy_Naprawa]
GO
ALTER TABLE [dbo].[CzesciSamochodu]  WITH CHECK ADD  CONSTRAINT [FK_CzesciSamochodu_Czesc] FOREIGN KEY([czesc_id])
REFERENCES [dbo].[Czesc] ([id])
GO
ALTER TABLE [dbo].[CzesciSamochodu] CHECK CONSTRAINT [FK_CzesciSamochodu_Czesc]
GO
ALTER TABLE [dbo].[CzesciSamochodu]  WITH CHECK ADD  CONSTRAINT [FK_CzesciSamochodu_Model] FOREIGN KEY([model_id])
REFERENCES [dbo].[Model] ([id])
GO
ALTER TABLE [dbo].[CzesciSamochodu] CHECK CONSTRAINT [FK_CzesciSamochodu_Model]
GO
ALTER TABLE [dbo].[CzesciSamochodu]  WITH CHECK ADD  CONSTRAINT [FK_CzesciSamochodu_Typ_nadwozia] FOREIGN KEY([typNadwozia_id])
REFERENCES [dbo].[Typ_nadwozia] ([id])
GO
ALTER TABLE [dbo].[CzesciSamochodu] CHECK CONSTRAINT [FK_CzesciSamochodu_Typ_nadwozia]
GO
ALTER TABLE [dbo].[CzesciWZamowieniu]  WITH CHECK ADD  CONSTRAINT [FK_CzesciWZamowieniu_Czesc] FOREIGN KEY([czesc_id])
REFERENCES [dbo].[Czesc] ([id])
GO
ALTER TABLE [dbo].[CzesciWZamowieniu] CHECK CONSTRAINT [FK_CzesciWZamowieniu_Czesc]
GO
ALTER TABLE [dbo].[CzesciWZamowieniu]  WITH CHECK ADD  CONSTRAINT [FK_CzesciWZamowieniu_Zamowienie] FOREIGN KEY([zamowienie_id])
REFERENCES [dbo].[Zamowienie] ([id])
GO
ALTER TABLE [dbo].[CzesciWZamowieniu] CHECK CONSTRAINT [FK_CzesciWZamowieniu_Zamowienie]
GO
ALTER TABLE [dbo].[GrafikOtwarcia]  WITH CHECK ADD  CONSTRAINT [FK_GrafikOtwarcia_DzienTygodnia] FOREIGN KEY([dzienTygodnia_id])
REFERENCES [dbo].[DzienTygodnia] ([id])
GO
ALTER TABLE [dbo].[GrafikOtwarcia] CHECK CONSTRAINT [FK_GrafikOtwarcia_DzienTygodnia]
GO
ALTER TABLE [dbo].[GrafikOtwarcia]  WITH CHECK ADD  CONSTRAINT [FK_GrafikOtwarcia_Serwis] FOREIGN KEY([serwis_id])
REFERENCES [dbo].[Serwis] ([id])
GO
ALTER TABLE [dbo].[GrafikOtwarcia] CHECK CONSTRAINT [FK_GrafikOtwarcia_Serwis]
GO
ALTER TABLE [dbo].[Model]  WITH CHECK ADD  CONSTRAINT [FK_Model_Marka] FOREIGN KEY([marka_id])
REFERENCES [dbo].[Marka] ([id])
GO
ALTER TABLE [dbo].[Model] CHECK CONSTRAINT [FK_Model_Marka]
GO
ALTER TABLE [dbo].[Pracownik]  WITH CHECK ADD  CONSTRAINT [FK_Pracownik_Serwis] FOREIGN KEY([serwis_id])
REFERENCES [dbo].[Serwis] ([id])
GO
ALTER TABLE [dbo].[Pracownik] CHECK CONSTRAINT [FK_Pracownik_Serwis]
GO
ALTER TABLE [dbo].[Rachunek]  WITH CHECK ADD  CONSTRAINT [FK_Rachunek_Zlecenie] FOREIGN KEY([zlecenie_id])
REFERENCES [dbo].[Zlecenie] ([id])
GO
ALTER TABLE [dbo].[Rachunek] CHECK CONSTRAINT [FK_Rachunek_Zlecenie]
GO
ALTER TABLE [dbo].[Samochod]  WITH CHECK ADD  CONSTRAINT [FK_Samochod_Klient] FOREIGN KEY([klient_id])
REFERENCES [dbo].[Klient] ([id])
GO
ALTER TABLE [dbo].[Samochod] CHECK CONSTRAINT [FK_Samochod_Klient]
GO
ALTER TABLE [dbo].[Samochod]  WITH CHECK ADD  CONSTRAINT [FK_Samochod_Model] FOREIGN KEY([model_id])
REFERENCES [dbo].[Model] ([id])
GO
ALTER TABLE [dbo].[Samochod] CHECK CONSTRAINT [FK_Samochod_Model]
GO
ALTER TABLE [dbo].[Samochod]  WITH CHECK ADD  CONSTRAINT [FK_Samochod_Typ_nadwozia] FOREIGN KEY([typNadwozia_id])
REFERENCES [dbo].[Typ_nadwozia] ([id])
GO
ALTER TABLE [dbo].[Samochod] CHECK CONSTRAINT [FK_Samochod_Typ_nadwozia]
GO
ALTER TABLE [dbo].[Stanowisko_w_serwisie]  WITH CHECK ADD  CONSTRAINT [FK_Stanowisko_w_serwisie_Serwis] FOREIGN KEY([serwis_id])
REFERENCES [dbo].[Stanowisko] ([id])
GO
ALTER TABLE [dbo].[Stanowisko_w_serwisie] CHECK CONSTRAINT [FK_Stanowisko_w_serwisie_Serwis]
GO
ALTER TABLE [dbo].[Stanowisko_w_serwisie]  WITH CHECK ADD  CONSTRAINT [FK_Stanowisko_w_serwisie_Stanowisko] FOREIGN KEY([serwis_id])
REFERENCES [dbo].[Serwis] ([id])
GO
ALTER TABLE [dbo].[Stanowisko_w_serwisie] CHECK CONSTRAINT [FK_Stanowisko_w_serwisie_Stanowisko]
GO
ALTER TABLE [dbo].[Usluga]  WITH CHECK ADD  CONSTRAINT [FK_Usluga_Stanowisko] FOREIGN KEY([stanowisko_id])
REFERENCES [dbo].[Stanowisko] ([id])
GO
ALTER TABLE [dbo].[Usluga] CHECK CONSTRAINT [FK_Usluga_Stanowisko]
GO
ALTER TABLE [dbo].[Zamowienie]  WITH CHECK ADD  CONSTRAINT [FK_Zamowienie_Pracownik] FOREIGN KEY([pracownik_id])
REFERENCES [dbo].[Pracownik] ([id])
GO
ALTER TABLE [dbo].[Zamowienie] CHECK CONSTRAINT [FK_Zamowienie_Pracownik]
GO
ALTER TABLE [dbo].[Zlecenie]  WITH CHECK ADD  CONSTRAINT [FK_Zlecenie_Samochod] FOREIGN KEY([samochod_id])
REFERENCES [dbo].[Samochod] ([id])
GO
ALTER TABLE [dbo].[Zlecenie] CHECK CONSTRAINT [FK_Zlecenie_Samochod]
GO
ALTER TABLE [dbo].[Zlecenie]  WITH CHECK ADD  CONSTRAINT [FK_Zlecenie_Status] FOREIGN KEY([status_id])
REFERENCES [dbo].[Status] ([id])
GO
ALTER TABLE [dbo].[Zlecenie] CHECK CONSTRAINT [FK_Zlecenie_Status]
GO
/****** Object:  StoredProcedure [dbo].[AddCar]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================				
-- Author:	<Dawid,Sobstyl>			
-- Create date: <2020-12-11>				
-- Description:	<Procedure to adding new car>			
-- =============================================				
CREATE PROCEDURE [dbo].[AddCar] 				
	@PlateNO	Varchar(25),		
	@NazwaModelu 	Varchar(20),		
	@NazwaTypuNadwozia	Varchar(20),		
	@NazwaMarki 	Varchar(50),		
	@Imie  	Varchar(20),		
	@Nazwisko 	Varchar(20),		
	@PESEL 	varchar(50),		
	@NumerTelefonu	INT,
	@email nvarchar(50)	
AS				
BEGIN				
	SET NOCOUNT ON;			
	DECLARE @IDCar BIGINT			
	DECLARE @IDModel int = NULL			
	DECLARE @IDTypNadwozia BIGINT = NULL			
	DECLARE @IDMarka int = NULL			
	DECLARE @IDKlient BIGINT = NULL			
    
	SET @IDMarka = (SELECT id 			
			FROM dbo.[Marka] 	
			WHERE nazwa = @NazwaMarki)	
	IF(@IDMarka is null)			
		BEGIN		
			EXECUTE @IDMarka = dbo.AddMarka @NazwaMarki	
		END	
					
	SET @IDModel = (SELECT id 			
			FROM dbo.[Model] 	
			WHERE nazwa = @NazwaModelu)	
	IF(@IDModel is null)			
		BEGIN		
			EXECUTE @IDModel = dbo.AddModel @IDMarka, @NazwaModelu	
		END		
				
	SET @IDTypNadwozia = (SELECT id 			
				FROM dbo.[Typ_nadwozia] 
				WHERE nazwa = @NazwaTypuNadwozia)
	IF(@IDTypNadwozia is null)			
		BEGIN		
			EXECUTE @IDTypNadwozia = dbo.AddTypNadwozia @NazwaTypuNadwozia	
		END			
				
	SET @IDKlient = (SELECT id 			
			FROM dbo.[Klient] 	
			WHERE [PESEL] = @PESEL)	
	IF(@IDKlient is null)			
		BEGIN		
			EXECUTE @IDKlient = dbo.AddKlient @Imie, @Nazwisko, @PESEL, @NumerTelefonu, @email
		END		
	INSERT INTO dbo.[Samochod] (			
		[model_id],
		  [typNadwozia_id],
		  [klient_id],
		  [numer_rejestracyjny]

	) VALUES (			
		@IDModel,		
		@IDTypNadwozia,			
		@IDKlient,
		@PlateNO		
	);			
	SELECT @IDCar = SCOPE_IDENTITY();			
	RETURN @IDCar			
END				
GO
/****** Object:  StoredProcedure [dbo].[AddEmployee]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================					
-- Author:		DSOB			
-- Create date: 2020-12-11					
-- Description:	Add User entry				
-- =============================================					
CREATE PROCEDURE [dbo].[AddEmployee]					
	@Imie  	Varchar(20),
	@Nazwisko 	Varchar(20),
	@Pesel	bigInt,
	@NazwaSerwisu Varchar(50),
	@Miasto	Varchar(30),
	@Ulica	Varchar(50),
	@Numer	INT,
	@NumerTelefonu	INT				
AS					
BEGIN					
	SET NOCOUNT ON;		
	DECLARE @IDSerwis Varchar(50)			
	DECLARE @IDEmployee BIGINT 			
		
	SELECT @IDSerwis= id				
	FROM dbo.Serwis 
	WHERE nazwa = @NazwaSerwisu
	IF(@IDSerwis is null)
		BEGIN
			Execute @IDSerwis = dbo.AddSerwis @NazwaSerwisu, @Miasto, @Ulica, @Numer, @NumerTelefonu
		END	
					
	SELECT @IDEmployee = id				
	FROM dbo.[Pracownik] 
	WHERE [PESEL] = @Pesel
	IF(@IDEmployee is null)				
		BEGIN		
			INSERT INTO [dbo].[Pracownik] (serwis_id, [Imie], [Nazwisko], PESEL) VALUES (@IDSerwis, @Imie, @Nazwisko, @Pesel);						
		END		
									
	RETURN @IDEmployee				
END					
GO
/****** Object:  StoredProcedure [dbo].[AddGrafikPracy]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================		
-- Author:		DSOB
-- Create date: 2020-12-11		
-- Description:	Add User entry	
-- =============================================		
CREATE PROCEDURE [dbo].[AddGrafikPracy]		
	@PESEL 	bigint,
	@start_date	datetime,
	@end_date	datetime,
	@workTime int,
	@dayOfWeek varchar(30)
AS		
BEGIN		
	SET NOCOUNT ON;	
	DECLARE @hourOpen bit
	DECLARE @workerID bigint
	DECLARE @serwisID bigint
	DECLARE @dayOfWeekId bigint
	DECLARE @grafikOtwarcia bigint
	
	SET @workerID = (SELECT id
					  FROM dbo.Pracownik
					  WHERE PESEL = @PESEL)
					  
	IF(@workerID is null)
		BEGIN			
			RAISERROR ('Nie ma takiego pracownika. ', 16, 1)	
		END	
		
	SET @dayOfWeekId = (SELECT id
			  FROM dbo.DzienTygodnia
			  WHERE DzienTygodnia.nazwa = @dayOfWeek)
					  
	IF(@dayOfWeekId is null)				
		BEGIN			
			RAISERROR ('Bledna data', 16, 1)	
		END	
	
	SET @serwisID = (SELECT S.id
			  FROM dbo.Serwis as S
				JOIN Stanowisko_w_serwisie SS ON S.id = SS.serwis_id
				JOIN Pracownik_Na_Stanowisku_W_Serwisie PSS ON  SS.id = PSS.stanowiskoWSerwisie_id
			  WHERE PSS.pracownik_id = @workerID)
					  
	IF(@serwisID is null)				
		BEGIN			
			RAISERROR ('Nie ma serwisu w ktorym pracuje dany pracownik', 16, 1)	
		END	
					  
	SET @hourOpen = dbo.[CzyIstniejeGrafikOtwarcia](@serwisID, @start_date, @end_date)
	
	IF(@hourOpen is null)				
		BEGIN			
			RAISERROR ('Serwis otwarty jest w innych godzinach nie mozna stworzyc grafiku', 16, 1)	
		END	
	
	DECLARE @grafikPracyId BIGINT	
	INSERT INTO [dbo].[GrafikPracy] ([pracownik_id], [dzienTygodnia_id], [data_rozpoczecia],[data_zakonczenia]) VALUES (@workerID, @dayOfWeekId, @start_date, @end_date);	
	SELECT @grafikPracyId = SCOPE_IDENTITY();	
	RETURN @grafikPracyId	
END		
GO
/****** Object:  StoredProcedure [dbo].[AddKlient]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================		
-- Author:		DSOB
-- Create date: 2020-12-11		
-- Description:	Add User entry	
-- =============================================		
CREATE PROCEDURE [dbo].[AddKlient]		
	@Imie  	Varchar(20),
	@Nazwisko 	Varchar(20),
	@PESEL 	varchar(40),
	@NumerTelefonu	INT,
	@email varchar(20)
		
AS		
BEGIN		
	SET NOCOUNT ON;	
	DECLARE @IDKlient BIGINT	
	INSERT INTO [dbo].[Klient] ([imie], [nazwisko], [PESEL],[tel_komorkowy], [email]) VALUES (@Imie, @Nazwisko, @PESEL, @NumerTelefonu, @email);	
	SELECT @IDKlient = SCOPE_IDENTITY();	
	RETURN @IDKlient	
END		
GO
/****** Object:  StoredProcedure [dbo].[AddMarka]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================		
-- Author:		DSOB
-- Create date: 2020-12-11		
-- Description:	Add User entry	
-- =============================================		
CREATE PROCEDURE [dbo].[AddMarka]		
	@NazwaMarki varchar (50)	
AS		
BEGIN		
	SET NOCOUNT ON;	
	DECLARE @IDMarka BIGINT	
	INSERT INTO dbo.[Marka] ([nazwa]) VALUES (@NazwaMarki);	
	SELECT @IDMarka = SCOPE_IDENTITY();	
	RETURN @IDMarka	
END		
GO
/****** Object:  StoredProcedure [dbo].[AddModel]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================		
-- Author:		DSOB
-- Create date: 2020-12-11		
-- Description:	Add User entry	
-- =============================================		
CREATE PROCEDURE [dbo].[AddModel]
	@IDMarka int,		
	@NazwaModelu varchar (50)	
AS		
BEGIN		
	SET NOCOUNT ON;	
	DECLARE @IDModel BIGINT	
	INSERT INTO dbo.[Model] (marka_id, nazwa) VALUES (@IDMarka, @NazwaModelu);	
	SELECT @IDModel = SCOPE_IDENTITY();	
	RETURN @IDModel	
END		
GO
/****** Object:  StoredProcedure [dbo].[AddOrder]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================					
-- Author:		DSOB			
-- Create date: 2020-12-11					
-- Description:	Add User entry				
-- =============================================					
CREATE PROCEDURE [dbo].[AddOrder]	
	@dateStart datetime2,				
	@PlateNO	Varchar(20),			
	@NazwaStatusu	Varchar(20)		
					
AS					
BEGIN					
	SET NOCOUNT ON;				
	DECLARE @IDcar BIGINT			
	DECLARE @IDOrder BIGINT 		
	DECLARE @IDStatus BIGINT				
					
	SET @IDcar = (SELECT  id				
					FROM dbo.[Samochod] 
					WHERE numer_rejestracyjny = @PlateNO)
	IF(@IDcar is null)				
		BEGIN			
			RAISERROR('Brak takiego samochodu', 16, 1)		
		END		
	SET @IDStatus = (SELECT  id				
					FROM dbo.[Status] 
					WHERE nazwa = @NazwaStatusu)
	IF(@IDStatus is null)				
		BEGIN			
			EXECUTE @IDStatus = dbo.AddStatus @NazwaStatusu
		END	

	INSERT INTO [dbo].Zlecenie (data_rozpoczecia, [samochod_id], status_id) VALUES ( @dateStart,@IDcar,@IDStatus);				
	SELECT @IDOrder = SCOPE_IDENTITY();				
	RETURN @IDOrder				
END					
GO
/****** Object:  StoredProcedure [dbo].[AddPart]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================					
-- Author:		DSOB			
-- Create date: 2020-12-11					
-- Description:	Add User entry				
-- =============================================					
CREATE PROCEDURE [dbo].[AddPart]					
	@Name	Varchar(20),
	@opis	varchar(100),
	@nrKatalog varchar(100),
	@Cost	Varchar(30)				
AS					
BEGIN					
	SET NOCOUNT ON;						
	DECLARE @IDPart BIGINT 			
					
	SET @IDPart = (SELECT  id		
					FROM dbo.[Czesc] 
					WHERE nrKatalogowy = @nrKatalog)
	IF(@IDPart is null)				
		BEGIN		
			INSERT INTO [dbo].[Czesc] (nazwa, opis, nrKatalogowy, [Cena]) VALUES (@Name, @opis, @nrKatalog, @Cost);						
		END		
							
	SELECT @IDPart = SCOPE_IDENTITY();				
	RETURN @IDPart				
END					
GO
/****** Object:  StoredProcedure [dbo].[AddPracownikStanowiskoWSerwisie]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================		
-- Author:		DSOB
-- Create date: 2020-12-11		
-- Description:	Add User entry	
-- =============================================		
CREATE PROCEDURE [dbo].[AddPracownikStanowiskoWSerwisie]		
	@IDStanowiskoWSerwisie bigint,
	@IDPracownik bigint
AS		
BEGIN		
	SET NOCOUNT ON;	
	DECLARE @ID BIGINT	

	INSERT INTO dbo.[Pracownik_Na_Stanowisku_W_Serwisie] (stanowiskoWSerwisie_id, pracownik_id) VALUES (@IDStanowiskoWSerwisie, @IDPracownik);	
	
	SELECT @ID = SCOPE_IDENTITY();	
	RETURN @ID	
END		
GO
/****** Object:  StoredProcedure [dbo].[AddRepair]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================				
-- Author:	<Dawid,Sobstyl>			
-- Create date: <2021-01-08>				
-- Description:	<Procedure to adding new car>			
-- =============================================				
CREATE PROCEDURE [dbo].[AddRepair] 				
	@IDOrder	BIGINT,
	@Status	Varchar(10),
	@NazwaUsługi Varchar(255),
	@PESEL	bigint,
	@NazwaSerwisu Varchar(30),
	@opis varchar(250),
	@endDate datetime


AS				
BEGIN				
	SET NOCOUNT ON;			
	DECLARE @IDRepair BIGINT			
	DECLARE @IDStatus BIGINT = NULL			
	DECLARE @IDUsluga BIGINT = NULL			
	DECLARE @IDPracownik BIGINT = NULL			
	DECLARE @IDPracownikStanowiskoWSerwisie BIGINT = NULL

    				
	SELECT @IDStatus = id 			
	FROM dbo.[Status] 	
	WHERE [nazwa] = @Status	
	IF(@IDStatus is null)			
		BEGIN		
			EXECUTE @IDStatus = dbo.AddStatus @Status	
		END		
				
	SELECT @IDUsluga = id	 			
	FROM dbo.[Usluga] 
	WHERE [nazwa] = @NazwaUsługi
	IF(@IDUsluga is null)			
		BEGIN		
			return -1
		END	
			
	SELECT @IDPracownik = PSS.id 			
	FROM dbo.[Pracownik] AS P JOIN dbo.Pracownik_Na_Stanowisku_W_Serwisie AS PSS ON P.id = PSS.pracownik_id  	
	WHERE P.[PESEL] = @PESEL
	IF(@IDPracownik is null)			
		BEGIN		
			return -1
		END		

	SELECT @IDPracownikStanowiskoWSerwisie = id 			
	FROM dbo.Pracownik_Na_Stanowisku_W_Serwisie  	
	WHERE pracownik_id = @IDPracownik

	IF(@IDPracownikStanowiskoWSerwisie is null)			
		BEGIN		
			return -1
		END
				 
	INSERT INTO dbo.[Naprawa] (			
		pracownikNaStanowiskuWSerwisie_id,		
		usluga_id,		
		status_id,	
		zlecenie_id,
		opis,
		data_realizacji	
				
	) VALUES (					
		 @IDPracownikStanowiskoWSerwisie, 			
		 @IDUsluga,   			
		 @IDStatus,  
		 @IDOrder,
		 @opis,
		 @endDate
		  	
	);			
	SELECT @IDRepair = SCOPE_IDENTITY();			
	RETURN @IDRepair			
END				
GO
/****** Object:  StoredProcedure [dbo].[AddSerwis]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================					
-- Author:		DSOB			
-- Create date: 2020-12-11					
-- Description:	Add User entry				
-- =============================================					
CREATE PROCEDURE [dbo].[AddSerwis]					
	@Nazwa	nVarchar(20),
	@MiastoName	NVarchar(50),
	@Ulica	Varchar(50),
	@Numer	INT,
	@NumerTelefonu	INT
	
					
AS					
BEGIN					
	SET NOCOUNT ON;						
	DECLARE @IDSerwis BIGINT 			
					
	SET @IDSerwis = (SELECT  id				
					FROM dbo.[Serwis] 
					WHERE nazwa = @Nazwa AND
						miasto=@MiastoName AND
						ulica = @Ulica	AND
						numer_budynku = @Numer	AND
						numer_telefonu = @NumerTelefonu)
	IF(@IDSerwis is null)				
		BEGIN		
			INSERT INTO [dbo].Serwis(nazwa, miasto, ulica, numer_budynku, numer_telefonu) 
									 VALUES (@Nazwa, @MiastoName, @Ulica, @Numer, @NumerTelefonu);						
		END							
	SELECT @IDSerwis = SCOPE_IDENTITY();				
	RETURN @IDSerwis				
END					
GO
/****** Object:  StoredProcedure [dbo].[AddStanowisko]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================		
-- Author:		DSOB
-- Create date: 2020-12-11		
-- Description:	Add User entry	
-- =============================================		
CREATE PROCEDURE [dbo].[AddStanowisko]
	@Nazwa varchar (250)	,		
	@opis varchar (250)	
AS		
BEGIN		
	SET NOCOUNT ON;	
	DECLARE @ID BIGINT	
	INSERT INTO dbo.[Stanowisko] (nazwa, opis) VALUES (@Nazwa, @opis);	
	SELECT @ID = SCOPE_IDENTITY();	
	RETURN @ID
END		
GO
/****** Object:  StoredProcedure [dbo].[AddStanowiskoWSerwisie]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================		
-- Author:		DSOB
-- Create date: 2020-12-11		
-- Description:	Add User entry	
-- =============================================		
CREATE PROCEDURE [dbo].[AddStanowiskoWSerwisie]		
	@IDStanowisko bigint,
	@IDSerwis bigint	
AS		
BEGIN		
	SET NOCOUNT ON;	
	DECLARE @ID BIGINT	

	INSERT INTO dbo.[Stanowisko_w_serwisie] (stanowisko_id, serwis_id) VALUES (@IDStanowisko, @IDSerwis);	

	SELECT @ID = SCOPE_IDENTITY();	
	RETURN @ID	
END		
GO
/****** Object:  StoredProcedure [dbo].[AddStatus]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================		
-- Author:		DSOB
-- Create date: 2020-12-11		
-- Description:	Add User entry	
-- =============================================		
CREATE PROCEDURE [dbo].[AddStatus]		
	@NazwaStatusu varchar (50)	
AS		
BEGIN		
	SET NOCOUNT ON;	
	DECLARE @IDSatus BIGINT	
	INSERT INTO dbo.[Status] ([nazwa]) VALUES (@NazwaStatusu);	

	SELECT @IDSatus = SCOPE_IDENTITY();	
	RETURN @IDSatus	
END		
GO
/****** Object:  StoredProcedure [dbo].[AddTypNadwozia]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================		
-- Author:		DSOB
-- Create date: 2020-12-11		
-- Description:	Add User entry	
-- =============================================		
CREATE PROCEDURE [dbo].[AddTypNadwozia]		
	@NazwaTypuNadwozia varchar (50)	
AS		
BEGIN		
	SET NOCOUNT ON;	
	DECLARE @IDTypNadwozia BIGINT	
	INSERT INTO dbo.[Typ_nadwozia] ([nazwa]) VALUES (@NazwaTypuNadwozia);	
	SELECT @IDTypNadwozia = SCOPE_IDENTITY();	
	RETURN @IDTypNadwozia	
END		
GO
/****** Object:  StoredProcedure [dbo].[AddUsluga]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================		
-- Author:		DSOB
-- Create date: 2020-12-11		
-- Description:	Add User entry	
-- =============================================		
CREATE PROCEDURE [dbo].[AddUsluga]		
	@Nazwa	Varchar(50),
	@Cena 	decimal,
	@IDStanowiska 	varchar(40)
		
AS		
BEGIN		
	SET NOCOUNT ON;	
	DECLARE @ID BIGINT	
	INSERT INTO dbo.Usluga (nazwa,cena,stanowisko_id) VALUES (@Nazwa, @Cena, @IDStanowiska);	
	SELECT @ID = SCOPE_IDENTITY();	
	RETURN @ID	
END		
GO
/****** Object:  StoredProcedure [dbo].[checkUsluga]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[checkUsluga]					
	@Name	Varchar(10),	
	@Stanowisko varchar(20),		
	@Cost	Int		
					
AS					
BEGIN					
	SET NOCOUNT ON;						
	DECLARE @IDStanowisko BIGINT 
	Declare @IDUsluga BIGINT	
				
	SET @IDUsluga = (SELECT  usluga.id				
					FROM dbo.[Usluga] 
					join dbo.Stanowisko on Stanowisko.id = Usluga.stanowisko_id
					WHERE usluga.nazwa = @Name AND Stanowisko.nazwa = @Stanowisko)	
	
	IF(@IDUsluga is null)				
		BEGIN			
			RAISERROR ('Nie takiej uslugi.', 16, 1)	
		END			
	SELECT @IDUsluga = SCOPE_IDENTITY();				
	RETURN @IDUsluga				
END
GO
/****** Object:  StoredProcedure [dbo].[sp_alterdiagram]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE PROCEDURE [dbo].[sp_alterdiagram]
	(
		@diagramname 	sysname,
		@owner_id	int	= null,
		@version 	int,
		@definition 	varbinary(max)
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
	
		declare @theId 			int
		declare @retval 		int
		declare @IsDbo 			int
		
		declare @UIDFound 		int
		declare @DiagId			int
		declare @ShouldChangeUID	int
	
		if(@diagramname is null)
		begin
			RAISERROR ('Invalid ARG', 16, 1)
			return -1
		end
	
		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID();	 
		select @IsDbo = IS_MEMBER(N'db_owner'); 
		if(@owner_id is null)
			select @owner_id = @theId;
		revert;
	
		select @ShouldChangeUID = 0
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname 
		
		if(@DiagId IS NULL or (@IsDbo = 0 and @theId <> @UIDFound))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1);
			return -3
		end
	
		if(@IsDbo <> 0)
		begin
			if(@UIDFound is null or USER_NAME(@UIDFound) is null) -- invalid principal_id
			begin
				select @ShouldChangeUID = 1 ;
			end
		end

		-- update dds data			
		update dbo.sysdiagrams set definition = @definition where diagram_id = @DiagId ;

		-- change owner
		if(@ShouldChangeUID = 1)
			update dbo.sysdiagrams set principal_id = @theId where diagram_id = @DiagId ;

		-- update dds version
		if(@version is not null)
			update dbo.sysdiagrams set version = @version where diagram_id = @DiagId ;

		return 0
	END
	
GO
/****** Object:  StoredProcedure [dbo].[sp_creatediagram]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE PROCEDURE [dbo].[sp_creatediagram]
	(
		@diagramname 	sysname,
		@owner_id		int	= null, 	
		@version 		int,
		@definition 	varbinary(max)
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
	
		declare @theId int
		declare @retval int
		declare @IsDbo	int
		declare @userName sysname
		if(@version is null or @diagramname is null)
		begin
			RAISERROR (N'E_INVALIDARG', 16, 1);
			return -1
		end
	
		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID(); 
		select @IsDbo = IS_MEMBER(N'db_owner');
		revert; 
		
		if @owner_id is null
		begin
			select @owner_id = @theId;
		end
		else
		begin
			if @theId <> @owner_id
			begin
				if @IsDbo = 0
				begin
					RAISERROR (N'E_INVALIDARG', 16, 1);
					return -1
				end
				select @theId = @owner_id
			end
		end
		-- next 2 line only for test, will be removed after define name unique
		if EXISTS(select diagram_id from dbo.sysdiagrams where principal_id = @theId and name = @diagramname)
		begin
			RAISERROR ('The name is already used.', 16, 1);
			return -2
		end
	
		insert into dbo.sysdiagrams(name, principal_id , version, definition)
				VALUES(@diagramname, @theId, @version, @definition) ;
		
		select @retval = @@IDENTITY 
		return @retval
	END
	
GO
/****** Object:  StoredProcedure [dbo].[sp_dropdiagram]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE PROCEDURE [dbo].[sp_dropdiagram]
	(
		@diagramname 	sysname,
		@owner_id	int	= null
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
		declare @theId 			int
		declare @IsDbo 			int
		
		declare @UIDFound 		int
		declare @DiagId			int
	
		if(@diagramname is null)
		begin
			RAISERROR ('Invalid value', 16, 1);
			return -1
		end
	
		EXECUTE AS CALLER;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner'); 
		if(@owner_id is null)
			select @owner_id = @theId;
		REVERT; 
		
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname 
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1)
			return -3
		end
	
		delete from dbo.sysdiagrams where diagram_id = @DiagId;
	
		return 0;
	END
	
GO
/****** Object:  StoredProcedure [dbo].[sp_helpdiagramdefinition]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE PROCEDURE [dbo].[sp_helpdiagramdefinition]
	(
		@diagramname 	sysname,
		@owner_id	int	= null 		
	)
	WITH EXECUTE AS N'dbo'
	AS
	BEGIN
		set nocount on

		declare @theId 		int
		declare @IsDbo 		int
		declare @DiagId		int
		declare @UIDFound	int
	
		if(@diagramname is null)
		begin
			RAISERROR (N'E_INVALIDARG', 16, 1);
			return -1
		end
	
		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner');
		if(@owner_id is null)
			select @owner_id = @theId;
		revert; 
	
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname;
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId ))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1);
			return -3
		end

		select version, definition FROM dbo.sysdiagrams where diagram_id = @DiagId ; 
		return 0
	END
	
GO
/****** Object:  StoredProcedure [dbo].[sp_helpdiagrams]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE PROCEDURE [dbo].[sp_helpdiagrams]
	(
		@diagramname sysname = NULL,
		@owner_id int = NULL
	)
	WITH EXECUTE AS N'dbo'
	AS
	BEGIN
		DECLARE @user sysname
		DECLARE @dboLogin bit
		EXECUTE AS CALLER;
			SET @user = USER_NAME();
			SET @dboLogin = CONVERT(bit,IS_MEMBER('db_owner'));
		REVERT;
		SELECT
			[Database] = DB_NAME(),
			[Name] = name,
			[ID] = diagram_id,
			[Owner] = USER_NAME(principal_id),
			[OwnerID] = principal_id
		FROM
			sysdiagrams
		WHERE
			(@dboLogin = 1 OR USER_NAME(principal_id) = @user) AND
			(@diagramname IS NULL OR name = @diagramname) AND
			(@owner_id IS NULL OR principal_id = @owner_id)
		ORDER BY
			4, 5, 1
	END
	
GO
/****** Object:  StoredProcedure [dbo].[sp_renamediagram]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE PROCEDURE [dbo].[sp_renamediagram]
	(
		@diagramname 		sysname,
		@owner_id		int	= null,
		@new_diagramname	sysname
	
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
		declare @theId 			int
		declare @IsDbo 			int
		
		declare @UIDFound 		int
		declare @DiagId			int
		declare @DiagIdTarg		int
		declare @u_name			sysname
		if((@diagramname is null) or (@new_diagramname is null))
		begin
			RAISERROR ('Invalid value', 16, 1);
			return -1
		end
	
		EXECUTE AS CALLER;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner'); 
		if(@owner_id is null)
			select @owner_id = @theId;
		REVERT;
	
		select @u_name = USER_NAME(@owner_id)
	
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname 
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1)
			return -3
		end
	
		-- if((@u_name is not null) and (@new_diagramname = @diagramname))	-- nothing will change
		--	return 0;
	
		if(@u_name is null)
			select @DiagIdTarg = diagram_id from dbo.sysdiagrams where principal_id = @theId and name = @new_diagramname
		else
			select @DiagIdTarg = diagram_id from dbo.sysdiagrams where principal_id = @owner_id and name = @new_diagramname
	
		if((@DiagIdTarg is not null) and  @DiagId <> @DiagIdTarg)
		begin
			RAISERROR ('The name is already used.', 16, 1);
			return -2
		end		
	
		if(@u_name is null)
			update dbo.sysdiagrams set [name] = @new_diagramname, principal_id = @theId where diagram_id = @DiagId
		else
			update dbo.sysdiagrams set [name] = @new_diagramname where diagram_id = @DiagId
		return 0
	END
	
GO
/****** Object:  StoredProcedure [dbo].[sp_upgraddiagrams]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE PROCEDURE [dbo].[sp_upgraddiagrams]
	AS
	BEGIN
		IF OBJECT_ID(N'dbo.sysdiagrams') IS NOT NULL
			return 0;
	
		CREATE TABLE dbo.sysdiagrams
		(
			name sysname NOT NULL,
			principal_id int NOT NULL,	-- we may change it to varbinary(85)
			diagram_id int PRIMARY KEY IDENTITY,
			version int,
	
			definition varbinary(max)
			CONSTRAINT UK_principal_name UNIQUE
			(
				principal_id,
				name
			)
		);


		/* Add this if we need to have some form of extended properties for diagrams */
		/*
		IF OBJECT_ID(N'dbo.sysdiagram_properties') IS NULL
		BEGIN
			CREATE TABLE dbo.sysdiagram_properties
			(
				diagram_id int,
				name sysname,
				value varbinary(max) NOT NULL
			)
		END
		*/

		IF OBJECT_ID(N'dbo.dtproperties') IS NOT NULL
		begin
			insert into dbo.sysdiagrams
			(
				[name],
				[principal_id],
				[version],
				[definition]
			)
			select	 
				convert(sysname, dgnm.[uvalue]),
				DATABASE_PRINCIPAL_ID(N'dbo'),			-- will change to the sid of sa
				0,							-- zero for old format, dgdef.[version],
				dgdef.[lvalue]
			from dbo.[dtproperties] dgnm
				inner join dbo.[dtproperties] dggd on dggd.[property] = 'DtgSchemaGUID' and dggd.[objectid] = dgnm.[objectid]	
				inner join dbo.[dtproperties] dgdef on dgdef.[property] = 'DtgSchemaDATA' and dgdef.[objectid] = dgnm.[objectid]
				
			where dgnm.[property] = 'DtgSchemaNAME' and dggd.[uvalue] like N'_EA3E6268-D998-11CE-9454-00AA00A3F36E_' 
			return 2;
		end
		return 1;
	END
	
GO
/****** Object:  Trigger [dbo].[TR_CzescDoNaprawy]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TR_CzescDoNaprawy] 
ON [dbo].[CzescDoNaprawy]
INSTEAD OF INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @CzyDanaCzescPasujeSamochodu BIT

	DECLARE @NaprawaId INT
	DECLARE @CzescId INT


	SELECT @CzescId = i.czesc_id, @NaprawaId = i.naprawa_id FROM inserted i

	SET @CzyDanaCzescPasujeSamochodu = dbo.CzyDanaCzescPasujeDoNaprawianegoSamochodu(@CzescId, @NaprawaId)

	IF @CzyDanaCzescPasujeSamochodu = 1
		BEGIN
			INSERT INTO dbo.CzescDoNaprawy(czesc_id, naprawa_id)
			select i.czesc_id, i.naprawa_id from inserted i
		END
	ELSE
		BEGIN
			RAISERROR ('Czesc nie pasuje do naprawianego samochodu.', 16, 1)
		END
END
GO
ALTER TABLE [dbo].[CzescDoNaprawy] ENABLE TRIGGER [TR_CzescDoNaprawy]
GO
/****** Object:  Trigger [dbo].[TR_GrafikPracy_InsteadOf]    Script Date: 12.01.2021 09:51:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[TR_GrafikPracy_InsteadOf] 
ON [dbo].[GrafikPracy]
INSTEAD OF INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @PracownikId INT
	DECLARE @DataRozpoczecia DATETIME
	DECLARE @DataZakonczenia DATETIME
	DECLARE @DzienTygodniaId INT

	SELECT @PracownikId = i.pracownik_id, 
			@DataRozpoczecia = i.data_rozpoczecia,
			@DataZakonczenia = i.data_zakonczenia,
			@DzienTygodniaId = i.dzienTygodnia_id
	FROM inserted i


	-- Czy grafik dla danego pracownika zawiera sie w godzinach otwarcia serwisu??
	-- Funkcja zwraca wartosci z zakresu od -3 do 1
	DECLARE @CzyGrafikZawieraSieWGodzinachOtwarciaSerwisuResult INT = -10
	SET @CzyGrafikZawieraSieWGodzinachOtwarciaSerwisuResult = [dbo].[CzyGrafikZawieraSieWGodzinachOtwarciaSerwisu](@PracownikId, 
																												   @DataRozpoczecia, 
																												   @DataZakonczenia, 
																												   @DzienTygodniaId)
	-- Nowo dodany grafik jest poprawny
	IF @CzyGrafikZawieraSieWGodzinachOtwarciaSerwisuResult = 1
	BEGIN
		INSERT INTO dbo.GrafikPracy
		SELECT * FROM INSERTED i
	END
	ELSE
		BEGIN
			DECLARE @KomunikatBledu VARCHAR(MAX)
			SEt @KomunikatBledu = dbo.ZamienIdBleduNaTekst(@CzyGrafikZawieraSieWGodzinachOtwarciaSerwisuResult)

			RAISERROR (@KomunikatBledu, 16, 1)
			ROLLBACK TRANSACTION
		END

END
GO
ALTER TABLE [dbo].[GrafikPracy] ENABLE TRIGGER [TR_GrafikPracy_InsteadOf]
GO
/****** Object:  Trigger [dbo].[TR_Naprawa]    Script Date: 12.01.2021 09:51:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TR_Naprawa] 
ON [dbo].[Naprawa]
INSTEAD OF INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @CzyUslugaMozeBycWykonana BIT = 0
	DECLARE @PESEL VARCHAR(max) = ''
	DECLARE @NazwaUslugi VARCHAR(max) = ''

	select @PESEL = Pracownik.PESEL, @NazwaUslugi = Usluga.nazwa
	from inserted i
	join Usluga on Usluga.id = i.usluga_id
	join Pracownik_Na_Stanowisku_W_Serwisie as PNWS on PNWS.id = i.pracownikNaStanowiskuWSerwisie_id
	join Pracownik on PNWS.pracownik_id = Pracownik.id
	

	SET @CzyUslugaMozeBycWykonana = dbo.[CzyUslugaMozeBycWykonywana](@PESEL, @NazwaUslugi)

	IF @CzyUslugaMozeBycWykonana = 1
	BEGIN
		INSERT INTO dbo.Naprawa (Naprawa.pracownikNaStanowiskuWSerwisie_id, Naprawa.usluga_id, Naprawa.status_id, Naprawa.zlecenie_id, Naprawa.opis, Naprawa.data_realizacji)
		SELECT i.pracownikNaStanowiskuWSerwisie_id, i.usluga_id,i.status_id,i.zlecenie_id,i.opis, i.data_realizacji
		FROM inserted i
	END
	ELSE
	BEGIN
		RAISERROR ('Ta usluga nie moze byc wykonana przez pracownika na tym stanowisku.', 16, 1)
		ROLLBACK TRANSACTION
	END
END
GO
ALTER TABLE [dbo].[Naprawa] ENABLE TRIGGER [TR_Naprawa]
GO
/****** Object:  Trigger [dbo].[TR_Naprawa_ForUpdate]    Script Date: 12.01.2021 09:51:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TR_Naprawa_ForUpdate] 
ON [dbo].[Naprawa]
FOR UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @InsertedNaprawaId INT
	DECLARE @InsertedNewStatus INT

	--Czy zaszla w ogole zmiana statusu?
	SELECT @InsertedNaprawaId = i.id, 
		   @InsertedNewStatus = i.status_id 
	FROM inserted i

	IF EXISTS (
			SELECT * FROM Naprawa
			WHERE 
			Naprawa.Id = @InsertedNaprawaId 
			AND Naprawa.status_id != @InsertedNewStatus
			)
	BEGIN
		RETURN
	END
	
	-- Ostatnie zamkniecie statusu uslugi powoduje zamkniecie zlecenia POWIAZNAEGO z naprawa

	DECLARE @ZlecenieId BIGINT

	select @ZlecenieId = i.zlecenie_id from inserted i


	DECLARE @result BIT

	 SET @result = dbo.[CzyWszystkieNaprawyZamknieteDlaZlecenia](@ZlecenieId)

	 IF @result = 1
	 BEGIN
		SELECT SUM(Czesc.cena + Usluga.cena) 
		from Naprawa 
		join Zlecenie on Zlecenie.id = Naprawa.zlecenie_id 
		join Usluga on Usluga.id = Naprawa.usluga_id
		join CzescDoNaprawy on CzescDoNaprawy.naprawa_id = Naprawa.id
		join Czesc on CzescDoNaprawy.czesc_id = Czesc.id

		--WYSTAWIAMY RACHUNEK
		INSERT INTO dbo.[Rachunek] (kwota, opis, zlecenie_id, numer)
		VALUES
		(
			(SELECT SUM(Czesc.cena + Usluga.cena) as sum
			from Naprawa 
			join Zlecenie on Zlecenie.id = Naprawa.zlecenie_id 
			join Usluga on Usluga.id = Naprawa.usluga_id
			join CzescDoNaprawy on CzescDoNaprawy.naprawa_id = Naprawa.id
			join Czesc on CzescDoNaprawy.czesc_id = Czesc.id), 
			'Rachunek', 
			@ZlecenieId, 
			0
		)

		--zamykamy zlecenie
		UPDATE Zlecenie
		SET Zlecenie.status_id = 1 
		WHERE Zlecenie.id = (select i.zlecenie_id from inserted i)

	END
END
GO
ALTER TABLE [dbo].[Naprawa] ENABLE TRIGGER [TR_Naprawa_ForUpdate]
GO
/****** Object:  Trigger [dbo].[TR_PracownikNaStanowiskuWSerwisie_InsteadOf]    Script Date: 12.01.2021 09:51:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TR_PracownikNaStanowiskuWSerwisie_InsteadOf] 
ON [dbo].[Pracownik_Na_Stanowisku_W_Serwisie]
INSTEAD OF INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;


	DECLARE @PracownikId Int
	DECLARE @StanowiskoWSerwisie Int

	SELECT @PracownikId = i.pracownik_id, @StanowiskoWSerwisie = i.stanowiskoWSerwisie_id FROM inserted i

	DECLARE @CzyIstniejeJuzTakiePrzypisanie BIT
	SET @CzyIstniejeJuzTakiePrzypisanie = dbo.[CzyIstniejeJuzTakiPracownikDlaStanowiskaWSerwisie](@PracownikId, @StanowiskoWSerwisie)

	IF @CzyIstniejeJuzTakiePrzypisanie = 1
		BEGIN
				RAISERROR ('Takie przypisanie juz istnieje.', 16, 1)
		END

	DECLARE @CzyPracownikPrzypisanyDoSerwisu BIT

	SET @CzyPracownikPrzypisanyDoSerwisu = [dbo].[CzyPracownikPrzypisanyDoStanowiskaWSerwisie](@PracownikId, @StanowiskoWSerwisie)
	IF @CzyPracownikPrzypisanyDoSerwisu = 1
	BEGIN
		INSERT INTO dbo.[Pracownik_Na_Stanowisku_W_Serwisie]
		select i.stanowiskoWSerwisie_id, i.pracownik_id from inserted i
	END
	ELSE
	BEGIN
		RAISERROR ('Pracownik nie jest przypisany do serwisu.', 16, 1)
	END

END
GO
ALTER TABLE [dbo].[Pracownik_Na_Stanowisku_W_Serwisie] ENABLE TRIGGER [TR_PracownikNaStanowiskuWSerwisie_InsteadOf]
GO
EXEC sys.sp_addextendedproperty @name=N'microsoft_database_tools_support', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'sysdiagrams'
GO
