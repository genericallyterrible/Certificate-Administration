USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 6, 2021
-- Description:     
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Validation].[AllNamesFromIDs]
      @db_id        INT
    , @object_id    INT
    , @db_name      SYSNAME OUTPUT
    , @schema_name  SYSNAME OUTPUT
    , @object_name  SYSNAME OUTPUT
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

    -- Get database name
    EXEC [Validation].[DBNameFromID]
          @db_id
        , @db_name OUTPUT
        , @raiserror

    -- Get object name
    EXEC [Validation].[ObjectNameFromID]
          @db_id
        , @object_id
        , @object_name OUTPUT
        , @raiserror

    -- Initialize dynamic sql to query db sys tables
    EXEC [InitDynamicSQL]
          @db_name      OUTPUT
        , @executesql   OUTPUT
        , @sql_start    OUTPUT
        , @sql_end      OUTPUT

    -- Get schema name from object id in database
    SELECT
        @sql =
            @sql_start
            + 'SELECT
                @schema_name = MIN([s].[name])
            FROM
                [sys].[objects] AS [o]
                JOIN [sys].[schemas] AS [s]
                    ON [o].[schema_id] = [s].[schema_id]
            WHERE
                [o].[object_id] = @object_id'
            + @sql_end
        , @params = 
            '@schema_name SYSNAME OUTPUT
            , @object_id INT'
    IF @debug = 1 PRINT '-- Getting schema name'
    IF @debug = 1 PRINT @sql
    EXEC @executesql @sql, @params
        , @schema_name OUTPUT
        , @object_id
    IF @raiserror = 1 AND @schema_name IS NULL
        RAISERROR('Could not find schema of object: %d', 16, 1, @object_id)

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
