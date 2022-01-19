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

CREATE OR ALTER PROCEDURE [Validation].[AllIDsFromNames]
      @db_name      SYSNAME
    , @schema_name  SYSNAME
    , @object_name  SYSNAME
    , @db_id        INT OUTPUT
    , @object_id    INT OUTPUT
    , @raiserror    BIT = 1
    , @debug        BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

        -- Validate db name
        EXEC [Validation].[ValidateDBName] @db_name OUTPUT, 1

        -- Validate schema and object names
        EXEC [Validation].[ValidateSchemaObject]
              @db_name
            , @schema_name  OUTPUT
            , @object_name  OUTPUT
            , @raiserror
            , @debug

        -- Get db_id
        EXEC [Validation].[DBIDFromName]
              @db_name
            , @db_id OUTPUT
            , @raiserror

        -- Get object_id
        EXEC [Validation].[ObjectIDFromName]
              @db_name
            , @schema_name
            , @object_name
            , @object_id OUTPUT
            , @raiserror
    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
