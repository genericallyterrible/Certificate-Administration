USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 19, 2021
-- Description:     
-- Return:          
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Validation].[ValidateObjectName]
      @db_name      SYSNAME
    , @schema_name  SYSNAME
    , @object_name  SYSNAME OUTPUT
    , @raiserror    BIT = 1
    , @debug        BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE @orig_name SYSNAME = @object_name

    SELECT @object_name = OBJECT_NAME(OBJECT_ID(QUOTENAME(@db_name)+'.'+QUOTENAME(@schema_name)+'.'+QUOTENAME(@object_name)), DB_ID(@db_name))

    IF @object_name IS NULL
    BEGIN
        IF @raiserror = 1
            RAISERROR('No object: "%s" in schema: "%s" database: "%s"', 16, 1, @orig_name, @schema_name, @db_name)
        IF @debug = 1
            PRINT '-- No object: ' + QUOTENAME(@orig_name, '"') + 'in schema: ' + QUOTENAME(@schema_name, '"') + ' in database: ' + QUOTENAME(@db_name, '"')
                + CHAR(13) + CHAR(10)
    END

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
