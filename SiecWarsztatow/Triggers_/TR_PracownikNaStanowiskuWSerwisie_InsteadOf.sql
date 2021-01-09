/****** Object:  Trigger [dbo].[TR_PracownikNaStanowiskuWSerwisie_InsteadOf]    Script Date: 09.01.2021 01:31:44 ******/
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
CREATE TRIGGER [dbo].[TR_PracownikNaStanowiskuWSerwisie_InsteadOf] 
ON [dbo].[Pracownik_Na_Stanowisku_W_Serwisie]
INSTEAD OF INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @CzyPracownikPrzypisanyDoSerwisu BIT

	DECLARE @PracownikId Int
	SET @PracownikId = (select i.pracownik_id from inserted i)

	SET @CzyPracownikPrzypisanyDoSerwisu = [dbo].[CzyPracownikPrzyPisanyDoSerwisu](@PracownikId)
	IF @CzyPracownikPrzypisanyDoSerwisu = 1
	BEGIN
		INSERT INTO dbo.[Pracownik_Na_Stanowisku_W_Serwisie](id, pracownik_id, stanowiskoWSerwisie_id)
		select i.id, i.pracownik_id, i.stanowiskoWSerwisie_id from inserted i
	END
	ELSE
	BEGIN
		RAISERROR ('Pracownik nie jest przypisany do serwisu.', 16, 1)
	END

END
GO

ALTER TABLE [dbo].[Pracownik_Na_Stanowisku_W_Serwisie] ENABLE TRIGGER [TR_PracownikNaStanowiskuWSerwisie_InsteadOf]
GO


