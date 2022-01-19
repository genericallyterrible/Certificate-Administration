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

CREATE OR ALTER PROCEDURE [Permission].[SourceGroupIDFromName]
      @db_name          SYSNAME
    , @GroupName        SYSNAME
    , @SourceGroupID    INT     OUTPUT
    , @raiserror        BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE @SourceDatabaseID INT

    EXEC [Permission].[SourceDBIDFromName] @db_name, @SourceDatabaseID OUTPUT, @raiserror

    SELECT
        @SourceGroupID = MIN([sg].[SourceGroupID])
    FROM
        [Permission].[SourceGroup] AS [sg]
    WHERE
        [sg].[Name] = @GroupName
        AND [sg].[SourceDatabaseID] = @SourceDatabaseID

    IF @raiserror = 1 AND @SourceGroupID IS NULL
        RAISERROR('No group named "%s" found for database "%s"', 16, 1, @GroupName, @db_name)

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
