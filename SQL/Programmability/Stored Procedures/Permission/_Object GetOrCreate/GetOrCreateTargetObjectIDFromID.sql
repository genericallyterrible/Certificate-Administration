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

CREATE OR ALTER PROCEDURE [Permission].[GetOrCreateTargetObjectIDFromID]
      @db_id            INT
    , @object_id        INT
    , @TargetObjectID   INT OUTPUT
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE @TargetDatabaseID INT

    EXEC [Permission].[GetOrCreateTargetDBIDFromID] @db_id, @TargetDatabaseID OUTPUT

    EXEC [Permission].[TargetObjectIDFromID] @db_id, @object_id, @TargetObjectID OUTPUT, 0

    IF @TargetObjectID IS NULL
    BEGIN
        EXEC [Validation].[ValidateObjectID] @db_id, @object_id, 1

        INSERT INTO [Permission].[TargetObject] (
            [TargetDatabaseID]
            , [object_id]
        ) VALUES (
              @TargetDatabaseID
            , @object_id
        )

        EXEC [Permission].[TargetObjectIDFromID] @db_id, @object_id, @TargetObjectID OUTPUT, 1
    END

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
