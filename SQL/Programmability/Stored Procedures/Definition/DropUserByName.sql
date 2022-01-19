USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 19, 2021
-- Description:     Drops a user from a provided DB.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Definition].[DropUserByName]
      @db_name      SYSNAME
    , @username     SYSNAME
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

    -- Validate db and initialize dynamic variables
    EXEC [InitDynamicSQL]
          @db_name      OUTPUT
        , @executesql   OUTPUT
        , @sql_start    OUTPUT
        , @sql_end      OUTPUT

    -- Validate user and get name back
    EXEC [Validation].[ValidateUsername] @db_name, @username OUTPUT, @raiserror, @debug

    -- Username doesn't exist and we don't want to raise errors, return
    IF @raiserror = 0 AND @username IS NULL
        RETURN

    -- Drop user
    SELECT
        @sql = 
            @sql_start
            + 'DROP USER ' + QUOTENAME(@username, '"')
            + @sql_end
    IF @debug = 1 PRINT '-- Dropping user: "' + @username + '"'
    IF @debug = 1 PRINT @sql
    EXEC @executesql @sql

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
