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

CREATE OR ALTER PROCEDURE [Permission].[TargetObjectIDFromID]
      @db_id            INT
    , @object_id        INT
    , @TargetObjectID   INT OUTPUT
    , @raiserror        BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE @TargetDatabaseID INT

    EXEC [Permission].[TargetDBIDFromID] @db_id, @TargetDatabaseID OUTPUT, @raiserror

    SELECT
        @TargetObjectID = MIN([TargetObjectID])
    FROM
        [Permission].[TargetObject] AS [so]
    WHERE
        [so].[TargetDatabaseID] = @TargetDatabaseID
        AND [so].[object_id] = @object_id

    IF @raiserror = 1 AND @TargetDatabaseID IS NULL
        RAISERROR('Object with ID "%d" in database "%d" has not been added as a target object.', 16, 1, @object_id, @db_id)

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
