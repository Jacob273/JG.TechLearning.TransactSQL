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
