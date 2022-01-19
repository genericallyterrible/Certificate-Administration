USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   January 10, 2022
-- Description:     Removes orphaned items from the database structure.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Permission].[CleanOrphanedItems]
    @debug BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    -- ================
    -- ==== SOURCE ====
    -- ================

    -- Source Groups
    DELETE [sg]
    FROM
        [Permission].[SourceGroup] AS [sg]
        LEFT JOIN [Permission].[OrphanedSourceGroups] AS [osg]
            ON [sg].[SourceGroupID] = [osg].[SourceGroupID]
    WHERE
        [osg].[SourceGroupID] IS NOT NULL

    -- Source Objects
    DELETE [so]
    FROM
        [Permission].[SourceObject] AS [so]
        LEFT JOIN [Permission].[OrphanedSourceObjects] AS [oso]
            ON [so].[SourceObjectID] = [oso].[SourceObjectID]
    WHERE
        [oso].[SourceObjectID] IS NOT NULL

    -- Source Databases
    DELETE [sd]
    FROM
        [Permission].[SourceDatabase] AS [sd]
        LEFT JOIN [Permission].[OrphanedSourceDatabases] AS [osd]
            ON [sd].[SourceDatabaseID] = [osd].[SourceDatabaseID]
    WHERE
        [osd].[SourceDatabaseID] IS NOT NULL


    -- ================
    -- ==== TARGET ====
    -- ================

    -- Target Roles
    DELETE [tr]
    FROM
        [Permission].[TargetRole] AS [tr]
        LEFT JOIN [Permission].[OrphanedTargetRoles] AS [otr]
            ON [tr].[TargetRoleID] = [otr].[TargetRoleID]
    WHERE
        [otr].[TargetRoleID] IS NOT NULL

    -- Target Objects
    DELETE [to]
    FROM
        [Permission].[TargetObject] AS [to]
        LEFT JOIN [Permission].[OrphanedTargetObjects] AS [oto]
            ON [to].[TargetObjectID] = [oto].[TargetObjectID]
    WHERE
        [oto].[TargetObjectID] IS NOT NULL

    -- Target Databases
    DELETE [td]
    FROM
        [Permission].[TargetObject] AS [td]
        LEFT JOIN [Permission].[OrphanedTargetDatabases] AS [otd]
            ON [td].[TargetDatabaseID] = [otd].[TargetDatabaseID]
    WHERE
        [otd].[TargetDatabaseID] IS NOT NULL

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
