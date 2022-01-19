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

CREATE OR ALTER PROCEDURE [Permission].[SourceDBIDFromName]
      @db_name          SYSNAME
    , @SourceDatabaseID INT OUTPUT
    , @raiserror        BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE @db_id INT

    EXEC [Validation].[DBIDFromName] @db_name, @db_id OUTPUT, @raiserror

    SELECT
        @SourceDatabaseID = MIN([SourceDatabaseID])
    FROM
        [Permission].[SourceDatabase] AS [sd]
    WHERE
        [sd].[database_id] = @db_id

    IF @raiserror = 1 AND @SourceDatabaseID IS NULL
        RAISERROR('Database with ID "%d" has not been added as a source database.', 16, 1, @db_id)

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
