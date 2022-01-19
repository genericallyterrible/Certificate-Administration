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

CREATE OR ALTER PROCEDURE [Permission].[GetOrCreateTargetDBIDFromID]
      @db_id            INT
    , @TargetDatabaseID INT OUTPUT
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    EXEC [Permission].[TargetDBIDFromID] @db_id, @TargetDatabaseID OUTPUT, 0

    IF @TargetDatabaseID IS NULL
    BEGIN
        EXEC [Validation].[ValidateDBID] @db_id, 1

        INSERT INTO [Permission].[TargetDatabase] ([database_id]) VALUES (@db_id)

        EXEC [Permission].[TargetDBIDFromID] @db_id, @TargetDatabaseID OUTPUT, 1
    END

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
