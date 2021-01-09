/****** Object:  Trigger [dbo].[TR_Naprawa_ForUpdate]    Script Date: 09.01.2021 01:29:22 ******/
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

	-- Ostatnie zamkniecie statusu uslugi powoduje zamkniecie zlecenia powiazaneog z naprawa

	DECLARE @ZlecenieId BIGINT

	select @ZlecenieId = i.zlecenie_id from inserted i


	DECLARE @result BIT

	 SET @result = dbo.[CzyWszystkieNaprawyZamknieteDlaZlecenia](@ZlecenieId)

	 IF @result = 1
	 BEGIN
		-- krok 1: wystawic rachunek (insert do Rachunek)
		-- (musi zaweirac: wszystkie ceny czesci i ceny uslug


		SELECT SUM(Czesc.cena + Usluga.cena) 
		from Naprawa 
		join Zlecenie on Zlecenie.id = Naprawa.zlecenie_id 
		join Usluga on Usluga.id = Naprawa.usluga_id
		join CzescDoNaprawy on CzescDoNaprawy.naprawa_id = Naprawa.id
		join Czesc on CzescDoNaprawy.czesc_id = Czesc.id

		--wystawiamy rachunek
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


