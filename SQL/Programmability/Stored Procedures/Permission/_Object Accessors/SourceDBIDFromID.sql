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

CREATE OR ALTER PROCEDURE [Permission].[SourceDBIDFromID]
      @db_id            INT
    , @SourceDatabaseID INT OUTPUT
    , @raiserror        BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE @db_name SYSNAME

    EXEC [Validation].[DBNameFromID] @db_id, @db_name OUTPUT, @raiserror

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
