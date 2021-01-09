/****** Object:  UserDefinedFunction [dbo].[GetStatus]    Script Date: 09.01.2021 01:24:28 ******/
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


