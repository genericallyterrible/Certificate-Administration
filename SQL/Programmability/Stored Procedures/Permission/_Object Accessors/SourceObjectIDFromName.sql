USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 18, 2021
-- Description:     
-- Return:          
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Permission].[SourceObjectIDFromName]
      @db_name          SYSNAME
    , @schema_name      SYSNAME
    , @object_name      SYSNAME
    , @SourceObjectID   INT OUTPUT
    , @raiserror        BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @SourceDatabaseID INT
        , @object_id        INT

    EXEC [Permission].[SourceDBIDFromName] @db_name, @SourceDatabaseID OUTPUT, @raiserror

    EXEC [Validation].[ObjectIDFromName] @db_name, @schema_name, @object_name, @object_id OUTPUT, @raiserror

    SELECT
        @SourceObjectID = MIN([SourceObjectID])
    FROM
        [Permission].[SourceObject] AS [so]
    WHERE
        [so].[SourceDatabaseID] = @SourceDatabaseID
        AND [so].[object_id] = @object_id

    IF @raiserror = 1 AND @SourceDatabaseID IS NULL
        RAISERROR('Object with name "%s" in database "%s" has not been added as a source object.', 16, 1, @object_name, @db_name)

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
