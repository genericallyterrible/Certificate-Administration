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

CREATE OR ALTER PROCEDURE [Permission].[GetOrCreateSourceGroupIDFromName]
      @db_name          SYSNAME
    , @GroupName        SYSNAME
    , @SourceGroupID    INT     OUTPUT
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE @SourceDatabaseID INT
    EXEC [Permission].[GetOrCreateSourceDBIDFromName] @db_name, @SourceDatabaseID OUTPUT -- Ensure DB exists

    EXEC [Permission].[SourceGroupIDFromName] @db_name, @GroupName, @SourceGroupID OUTPUT, 0

    IF @SourceGroupID IS NULL
    BEGIN
        INSERT INTO [Permission].[SourceGroup] (
              [SourceDatabaseID]
            , [Name]
        ) VALUES (
              @SourceDatabaseID
            , @GroupName
        )

        EXEC [Permission].[SourceGroupIDFromName] @db_name, @GroupName, @SourceGroupID OUTPUT, 1
    END

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
