/****** Object:  Trigger [dbo].[TR_GrafikPracy_InsteadOf]    Script Date: 09.01.2021 01:28:37 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ================================================
-- Template generated from Template Explorer using:
-- Create Trigger (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
CREATE TRIGGER [dbo].[TR_GrafikPracy_InsteadOf] 
ON [dbo].[GrafikPracy]
INSTEAD OF INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @SerwisId INT
	DECLARE @DataRozpoczecia DATETIME
	DECLARE @DataZakonczenia DATETIME

	 SELECT @SerwisId = Stanowisko_w_serwisie.id, 
			@DataRozpoczecia = i.data_rozpoczecia, 
			@DataZakonczenia = i.data_zakonczenia
	FROM inserted i
	JOIN Pracownik_Na_Stanowisku_W_Serwisie as PNSWS on PNSWS.pracownik_id = i.pracownik_id
	JOIN Stanowisko_w_serwisie on Stanowisko_w_serwisie.id = PNSWS.stanowiskoWSerwisie_id

	-- Czy grafik dla danego pracownika zawiera sie w godzinach otwarcia serwisu??	
	DECLARE @CzyGrafikZawieraSieWGodzinachOtwarciaSerwisu BIT = 0
	SET @CzyGrafikZawieraSieWGodzinachOtwarciaSerwisu = [dbo].[CzyGrafikZawieraSieWGodzinachOtwarciaSerwisu](@SerwisId, @DataRozpoczecia, @DataZakonczenia)

	IF @CzyGrafikZawieraSieWGodzinachOtwarciaSerwisu = 1
	BEGIN
		DECLARE @PESEL Varchar(Max)

		SELECT Pracownik.PESEL 
		FROM inserted i
		JOIN Pracownik ON Pracownik.id = i.pracownik_id
		
		EXECUTE [dbo].[AddGrafikPracy]  @PESEL, @DataRozpoczecia, @DataZakonczenia, '8'
	END
	ELSE
		BEGIN
			RAISERROR ('Grafik pracy dla danego pracownika nie zawiera siew godzinach otwarcia...', 16, 1)
			ROLLBACK TRANSACTION
		END

END
GO

ALTER TABLE [dbo].[GrafikPracy] ENABLE TRIGGER [TR_GrafikPracy_InsteadOf]
GO


