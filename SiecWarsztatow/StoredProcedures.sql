/****** Object:  StoredProcedure [dbo].[AddCar]    Script Date: 12.01.2021 10:00:22 ******/
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
/****** Object:  StoredProcedure [dbo].[AddEmployee]    Script Date: 12.01.2021 10:00:22 ******/
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
/****** Object:  StoredProcedure [dbo].[AddGrafikPracy]    Script Date: 12.01.2021 10:00:22 ******/
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
/****** Object:  StoredProcedure [dbo].[AddKlient]    Script Date: 12.01.2021 10:00:22 ******/
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
/****** Object:  StoredProcedure [dbo].[AddMarka]    Script Date: 12.01.2021 10:00:22 ******/
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
/****** Object:  StoredProcedure [dbo].[AddModel]    Script Date: 12.01.2021 10:00:22 ******/
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
/****** Object:  StoredProcedure [dbo].[AddOrder]    Script Date: 12.01.2021 10:00:22 ******/
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
/****** Object:  StoredProcedure [dbo].[AddPart]    Script Date: 12.01.2021 10:00:22 ******/
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
/****** Object:  StoredProcedure [dbo].[AddPracownikStanowiskoWSerwisie]    Script Date: 12.01.2021 10:00:22 ******/
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
/****** Object:  StoredProcedure [dbo].[AddRepair]    Script Date: 12.01.2021 10:00:22 ******/
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
/****** Object:  StoredProcedure [dbo].[AddSerwis]    Script Date: 12.01.2021 10:00:22 ******/
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
/****** Object:  StoredProcedure [dbo].[AddStanowisko]    Script Date: 12.01.2021 10:00:22 ******/
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
/****** Object:  StoredProcedure [dbo].[AddStanowiskoWSerwisie]    Script Date: 12.01.2021 10:00:22 ******/
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
/****** Object:  StoredProcedure [dbo].[AddStatus]    Script Date: 12.01.2021 10:00:22 ******/
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
/****** Object:  StoredProcedure [dbo].[AddTypNadwozia]    Script Date: 12.01.2021 10:00:22 ******/
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
/****** Object:  StoredProcedure [dbo].[AddUsluga]    Script Date: 12.01.2021 10:00:22 ******/
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
/****** Object:  StoredProcedure [dbo].[checkUsluga]    Script Date: 12.01.2021 10:00:22 ******/
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
/****** Object:  StoredProcedure [dbo].[sp_alterdiagram]    Script Date: 12.01.2021 10:00:22 ******/
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
/****** Object:  StoredProcedure [dbo].[sp_creatediagram]    Script Date: 12.01.2021 10:00:22 ******/
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
/****** Object:  StoredProcedure [dbo].[sp_dropdiagram]    Script Date: 12.01.2021 10:00:22 ******/
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
/****** Object:  StoredProcedure [dbo].[sp_helpdiagramdefinition]    Script Date: 12.01.2021 10:00:22 ******/
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
/****** Object:  StoredProcedure [dbo].[sp_helpdiagrams]    Script Date: 12.01.2021 10:00:22 ******/
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
/****** Object:  StoredProcedure [dbo].[sp_renamediagram]    Script Date: 12.01.2021 10:00:22 ******/
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
/****** Object:  StoredProcedure [dbo].[sp_upgraddiagrams]    Script Date: 12.01.2021 10:00:22 ******/
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
