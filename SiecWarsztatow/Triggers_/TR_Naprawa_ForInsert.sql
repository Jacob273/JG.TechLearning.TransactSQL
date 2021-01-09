/****** Object:  Trigger [dbo].[TR_Naprawa]    Script Date: 09.01.2021 01:29:37 ******/
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
		DECLARE @IDOrder	BIGINT
		DECLARE @Status	Varchar(10)
		DECLARE @NazwaUsługi	Varchar(15)
		DECLARE @Imie  	Varchar(20)
		DECLARE @Nazwisko 	Varchar(20)
		DECLARE @Miasto	Varchar(30)
		DECLARE @Ulica	Varchar(50)
		DECLARE @Numer	INT
		DECLARE @NumerTelefonu	INT
		DECLARE @opis varchar(50)
		DECLARE @endDate datetime

		select @IDOrder=i.zlecenie_id, @Status=Status.nazwa, @NazwaUslugi = Usluga.nazwa, @Imie = Pracownik.imie,
			   @Nazwisko = Pracownik.nazwisko, @Miasto = Serwis.miasto, @Ulica = Serwis.ulica,
			   @Numer = Serwis.numer_budynku, @NumerTelefonu = Serwis.numer_telefonu, @opis = i.opis, 
			   @endDate = i.data_realizacji
			from inserted i
			join dbo.[Usluga] on Usluga.id = i.usluga_id
			join dbo.[Pracownik_Na_Stanowisku_W_Serwisie] as PNWS on PNWS.id = i.pracownikNaStanowiskuWSerwisie_id
			join dbo.[Pracownik] on PNWS.pracownik_id = Pracownik.id
			join dbo.[Status] on dbo.[Status].id = i.status_id
			join dbo.[Serwis] on Serwis.id = Pracownik.serwis_id
		EXECUTE [dbo].[AddRepair]  @IDOrder
								  ,@Status
								  ,@NazwaUsługi
								  ,@Imie
								  ,@Nazwisko
								  ,@PESEL
								  ,@Miasto
								  ,@Ulica
								  ,@Numer
								  ,@NumerTelefonu
								  ,@opis
								  ,@endDate
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


