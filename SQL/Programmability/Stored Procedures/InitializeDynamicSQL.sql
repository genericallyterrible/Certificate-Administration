USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 4, 2021
-- Description:     Validates db and initializes dynamic sql variables.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [dbo].[InitDynamicSQL]
      @db_name      SYSNAME         OUTPUT
    , @executesql   NVARCHAR(350)   OUTPUT
    , @sql_start    NVARCHAR(200)   OUTPUT
    , @sql_end      NVARCHAR(200)   OUTPUT
    
AS
BEGIN
    -- Validate db
    EXEC [Validation].[ValidateDBName]
        @db_name OUTPUT
        , 1

    DECLARE @nl CHAR(2) = CHAR(13) + CHAR(10)

    SELECT
          @executesql = @db_name + '.sys.sp_executesql'
        , @sql_start =
                '-- In database ' + @db_name
                + @nl + 'EXECUTE AS USER = ''dbo'''
                + @nl
        , @sql_end = @nl + 'REVERT' + @nl
END
GO
