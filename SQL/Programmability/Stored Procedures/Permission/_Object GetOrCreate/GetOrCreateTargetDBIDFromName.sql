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

CREATE OR ALTER PROCEDURE [Permission].[GetOrCreateTargetDBIDFromName]
      @db_name          SYSNAME
    , @TargetDatabaseID INT OUTPUT
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE @db_id INT

    EXEC [Validation].[DBIDFromName] @db_name, @db_id OUTPUT, 1

    EXEC [Permission].[GetOrCreateTargetDBIDFromID] @db_id, @TargetDatabaseID

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
