/****** Object:  Trigger [dbo].[TR_CzescDoNaprawy]    Script Date: 09.01.2021 01:27:33 ******/
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


	DECLARE @CzescId INT
	SET @CzescId = (select i.czesc_id from inserted i)

	SET @CzyDanaCzescPasujeSamochodu = dbo.CzyDanaCzescPasujeDoNaprawianegoSamochodu(@CzescId)

	IF @CzyDanaCzescPasujeSamochodu = 1
		BEGIN
			INSERT INTO dbo.CzescDoNaprawy(czesc_id, naprawa_id)
			select i.czesc_id, i.naprawa_id from inserted i
		END
	ELSE
		BEGIN
			RAISERROR ('Czesc nie pasuje do naprawianego samochodu.', 16, 1)
		END


	

	


	---- Czy dana czesc jest aby na pewno dla danego samochodu?
	--		IF NOT EXISTS(
	--			SELECT Zlecenie.samochod_id, i.czesc_id
	--			FROM
	--				inserted i
	--				join Naprawa on Naprawa.id = i.naprawa_id
	--				join Zlecenie on Zlecenie.id = Naprawa.zlecenie_id
	--				join CzesciSamochodu on CzesciSamochodu.czesc_id = i.czesc_id
	--				)
	--BEGIN
	--	RAISERROR ('Czesc wybrana do danej naprawy, nie jest przeznaczona dla naprawianego samochodu.', 16, 1)
	--	ROLLBACK TRANSACTION
	--END
	--ELSE
	--	BEGIN
	--	INSERT INTO CzescDoNaprawy (id, czesc_id, naprawa_id)
	--	select inserted.id, inserted.naprawa_id, inserted.naprawa_id 
	--	from inserted
	--END

END
GO

ALTER TABLE [dbo].[CzescDoNaprawy] ENABLE TRIGGER [TR_CzescDoNaprawy]
GO


