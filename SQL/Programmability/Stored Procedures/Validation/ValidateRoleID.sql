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

CREATE OR ALTER PROCEDURE [Validation].[ValidateRoleID]
      @db_id        INT
    , @role_id      INT OUTPUT
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
        , @db_name      SYSNAME
        , @orig_id      INT = @role_id

    EXEC [Validation].[DBNameFromID] @db_id, @db_name OUTPUT, @raiserror

    -- Validate db and initialize dynamic variables
    EXEC [InitDynamicSQL]
          @db_name      OUTPUT
        , @executesql   OUTPUT
        , @sql_start    OUTPUT
        , @sql_end      OUTPUT

    SELECT
        -- Use MIN to get NULL if role id does not exist
        @sql =
            @sql_start
            + 'SELECT
                @role_id = MIN([dp].[principal_id])
            FROM
                [sys].[database_principals] AS [dp]
            WHERE
                [dp].[type] = ''R''
                AND [dp].[principal_id] = @role_id'
            + @sql_end
        , @params = 
            '@role_id SYSNAME OUTPUT'
    IF @debug = 1 PRINT CONCAT('-- Validating role with id:"', @role_id, '"')
    IF @debug = 1 PRINT @sql
    EXEC @executesql @sql, @params
            , @role_id OUTPUT

    IF @role_id IS NULL
    BEGIN
        IF @raiserror = 1
            RAISERROR('No role with id: "%d"', 16, 1, @orig_id)
        IF @debug = 1
            PRINT '-- No role with id: ' + QUOTENAME(@orig_id, '"')
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
