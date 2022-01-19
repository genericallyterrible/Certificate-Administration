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

CREATE OR ALTER PROCEDURE [Permission].[TargetObjectIDFromName]
      @db_name          SYSNAME
    , @schema_name      SYSNAME
    , @object_name      SYSNAME
    , @TargetObjectID   INT OUTPUT
    , @raiserror        BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @TargetDatabaseID INT
        , @object_id        INT

    EXEC [Permission].[TargetDBIDFromName] @db_name, @TargetDatabaseID OUTPUT, @raiserror

    EXEC [Validation].[ObjectIDFromName] @db_name, @schema_name, @object_name, @object_id OUTPUT, @raiserror

    SELECT
        @TargetObjectID = MIN([TargetObjectID])
    FROM
        [Permission].[TargetObject] AS [so]
    WHERE
        [so].[TargetDatabaseID] = @TargetDatabaseID
        AND [so].[object_id] = @object_id

    IF @raiserror = 1 AND @TargetDatabaseID IS NULL
        RAISERROR('Object with name "%s" in database "%s" has not been added as a target object.', 16, 1, @object_name, @db_name)

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
