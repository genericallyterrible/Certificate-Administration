USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 8, 2021
-- Description:     
-- Return:          
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Validation].[ValidateRoleName]
      @db_name      SYSNAME
    , @role_name    SYSNAME OUTPUT
    , @raiserror    BIT = 1
    , @debug        BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @executesql   NVARCHAR(350)
        , @sql_start    NVARCHAR(200)
        , @sql_end      NVARCHAR(200)
        , @sql          NVARCHAR(MAX)
        , @params       NVARCHAR(MAX)
        , @origname     SYSNAME = @role_name

    -- Validate db and initialize dynamic variables
    EXEC [InitDynamicSQL]
          @db_name      OUTPUT
        , @executesql   OUTPUT
        , @sql_start    OUTPUT
        , @sql_end      OUTPUT

    SELECT
        -- Use MIN to get NULL if role name does not exist
        @sql =
            @sql_start
            + 'SELECT
                @role_name = MIN([dp].[name])
            FROM
                [sys].[database_principals] AS [dp]
            WHERE
                [dp].[type] = ''R''
                AND [dp].[name] = @role_name'
            + @sql_end
        , @params = 
            '@role_name SYSNAME OUTPUT'
    IF @debug = 1 PRINT '-- Validating role :"' + @role_name + '"'
    IF @debug = 1 PRINT @sql
    EXEC @executesql @sql, @params
            , @role_name OUTPUT

    IF @role_name IS NULL
    BEGIN
        IF @raiserror = 1
            RAISERROR('No role: "%s"', 16, 1, @origname)
        IF @debug = 1
            PRINT '-- No role: ' + QUOTENAME(@origname, '"')
                + CHAR(13) + CHAR(10)
    END

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

    -- In cases there is an error while we are impersonating dbo, we need
    -- to revert back, which must be done in the user database.
    IF EXISTS (
        SELECT * FROM [sys].[login_token] WHERE [usage] = 'DENY ONLY'
    )
    BEGIN
        IF @debug = 1 PRINT '-- Error while impersonating dbo, reverting'
        EXEC @executesql N'REVERT'
    END
    ; THROW
END CATCH
GO
