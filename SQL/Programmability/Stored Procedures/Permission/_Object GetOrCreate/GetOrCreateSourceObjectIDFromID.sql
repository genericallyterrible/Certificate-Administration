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

CREATE OR ALTER PROCEDURE [Permission].[GetOrCreateSourceObjectIDFromID]
      @db_id            INT
    , @object_id        INT
    , @SourceObjectID   INT OUTPUT
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE @SourceDatabaseID INT

    EXEC [Permission].[GetOrCreateSourceDBIDFromID] @db_id, @SourceDatabaseID OUTPUT

    EXEC [Permission].[SourceObjectIDFromID] @db_id, @object_id, @SourceObjectID OUTPUT, 0

    IF @SourceObjectID IS NULL
    BEGIN
        EXEC [Validation].[ValidateObjectID] @db_id, @object_id, 1

        INSERT INTO [Permission].[SourceObject] (
            [SourceDatabaseID]
            , [object_id]
        ) VALUES (
              @SourceDatabaseID
            , @object_id
        )

        EXEC [Permission].[SourceObjectIDFromID] @db_id, @object_id, @SourceObjectID OUTPUT, 1
    END

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
