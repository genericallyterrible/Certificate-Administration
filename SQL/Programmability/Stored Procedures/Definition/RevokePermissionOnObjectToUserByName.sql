USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 12, 2021
-- Description:     
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Definition].[RevokePermOnObjFromUserByName]
      @db_name      SYSNAME
    , @schema_name  SYSNAME
    , @object_name  SYSNAME
    , @username     SYSNAME
    , @permission   VARCHAR(50) -- Injection hole, do not expose to clients
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

    EXEC [Validation].[ValidateSchemaObject]
          @db_name
        , @schema_name OUTPUT
        , @object_name OUTPUT
        , 1
        , @debug

    SELECT
        @sql =
            @sql_start
            + 'REVOKE ' + @permission + '
            ON ' + QUOTENAME(@schema_name) + '.' + QUOTENAME(@object_name) + '
            TO ' + QUOTENAME(@username, '"')
            + @sql_end
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
