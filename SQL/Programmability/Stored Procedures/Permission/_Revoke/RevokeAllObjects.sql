USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 25, 2021
-- Description:     Revokes all permissions/roles for all SourceObjects.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Permission].[RevokeAllObjects]
      @DropRequests     BIT
    , @debug            BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE @SourceObjectID INT

    DECLARE [src_object_cur] CURSOR STATIC LOCAL FOR
        SELECT DISTINCT [SourceObjectID]
        FROM [Permission].[SourceObject]
        WHERE [SourceObjectID] IS NOT NULL
    OPEN [src_object_cur]
    WHILE 1 = 1
    BEGIN
        FETCH NEXT FROM [src_object_cur] INTO @SourceObjectID
        IF @@FETCH_STATUS <> 0 BREAK

        EXEC [Permission].[RevokeObjectByID] @SourceObjectID, @DropRequests, @debug
    END
    CLOSE [src_object_cur]
    DEALLOCATE [src_object_cur]

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
