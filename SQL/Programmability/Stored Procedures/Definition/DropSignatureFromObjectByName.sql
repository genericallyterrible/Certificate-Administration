USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 4, 2021
-- Description:     Drops a signature made by a certificate from the
--                  provided object.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Definition].[DropSigFromObjByName]
      @db_name      SYSNAME
    , @schema_name  SYSNAME
    , @object_name  SYSNAME
    , @cert_name    SYSNAME
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

    -- Validate schema and object names
    EXEC [Validation].[ValidateSchemaObject]
          @db_name
        , @schema_name  OUTPUT
        , @object_name  OUTPUT
        , 1
        , @debug

    -- Validate certificate name
    EXEC [Validation].[ValidateCertName] @db_name, @cert_name OUTPUT, 1, @debug

    SELECT
        @sql =
            @sql_start
            + 'DROP SIGNATURE FROM ' + QUOTENAME(@schema_name) +'.' + QUOTENAME(@object_name) + '
            BY CERTIFICATE ' + QUOTENAME(@cert_name, '"')
            + @sql_end
    IF @debug = 1
    BEGIN
        PRINT '-- Dropping signature of certificate: "' + @cert_name + '"'
        PRINT '-- from object: "' + @schema_name +'.' + @object_name + '"'
        PRINT @sql
    END
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
