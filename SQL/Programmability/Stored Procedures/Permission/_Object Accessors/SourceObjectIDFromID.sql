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

CREATE OR ALTER PROCEDURE [Permission].[SourceObjectIDFromID]
      @db_id            INT
    , @object_id        INT
    , @SourceObjectID   INT OUTPUT
    , @raiserror        BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE @SourceDatabaseID INT

    EXEC [Permission].[SourceDBIDFromID] @db_id, @SourceDatabaseID OUTPUT, @raiserror

    SELECT
        @SourceObjectID = MIN([SourceObjectID])
    FROM
        [Permission].[SourceObject] AS [so]
    WHERE
        [so].[SourceDatabaseID] = @SourceDatabaseID
        AND [so].[object_id] = @object_id

    IF @raiserror = 1 AND @SourceDatabaseID IS NULL
        RAISERROR('Object with ID "%d" in database "%d" has not been added as a source object.', 16, 1, @object_id, @db_id)

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
