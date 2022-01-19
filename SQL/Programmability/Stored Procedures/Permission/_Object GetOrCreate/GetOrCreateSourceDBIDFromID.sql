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

CREATE OR ALTER PROCEDURE [Permission].[GetOrCreateSourceDBIDFromID]
      @db_id            INT
    , @SourceDatabaseID INT OUTPUT
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    EXEC [Permission].[SourceDBIDFromID] @db_id, @SourceDatabaseID OUTPUT, 0

    IF @SourceDatabaseID IS NULL
    BEGIN
        INSERT INTO [Permission].[SourceDatabase] ([database_id]) VALUES (@db_id)

        EXEC [Permission].[SourceDBIDFromID] @db_id, @SourceDatabaseID OUTPUT, 1
    END

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
