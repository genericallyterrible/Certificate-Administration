USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 20, 2021
-- Description:     
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Permission].[TryToDropGroupCertificates]
      @SourceGroupID    INT
    , @TargetDatabaseID INT
    , @debug            BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @src_count INT
        , @tar_count INT

    -- Get count of roles/perms associated with SourceGroup in TargetDatabase
    SELECT
        @tar_count = COUNT(*)
    FROM
        [Permission].[TargetDatabase] AS [td]
        JOIN [Permission].[TargetObject] AS [to]
            ON [td].[TargetDatabaseID] = [to].[TargetDatabaseID]
        JOIN [Permission].[TargetRole] AS [tr]
            ON [td].[TargetDatabaseID] = [tr].[TargetDatabaseID]
        LEFT JOIN [Permission].[GroupPermissionRequest] AS [gpr]
            ON [to].[TargetObjectID] = [gpr].[TargetObjectID]
            AND [gpr].[SourceGroupID] = @SourceGroupID
            AND [gpr].[Granted] = 1
        LEFT JOIN [Permission].[GroupRoleRequest] AS [grr]
            ON [tr].[TargetRoleID] = [grr].[TargetRoleID]
            AND [grr].[SourceGroupID] = @SourceGroupID
            AND [grr].[Granted] = 1
    WHERE
        [td].[TargetDatabaseID] = @TargetDatabaseID
        AND (
            [gpr].[SourceGroupID] IS NOT NULL
            OR [grr].[SourceGroupID] IS NOT NULL
        )

    -- Get count of roles/perms associated with SourceGroup
    SELECT
        @src_count = COUNT(*)
    FROM
        [Permission].[SourceGroup] AS [so]
        LEFT JOIN [Permission].[GroupPermissionRequest] AS [gpr]
            ON [so].[SourceGroupID] = [gpr].[SourceGroupID]
            AND [gpr].[Granted] = 1
        LEFT JOIN [Permission].[GroupRoleRequest] AS [grr]
            ON [so].[SourceGroupID] = [grr].[SourceGroupID]
            AND [grr].[Granted] = 1
    WHERE
        [so].[SourceGroupID] = @SourceGroupID
        AND (
            [gpr].[SourceGroupID] IS NOT NULL
            OR [grr].[SourceGroupID] IS NOT NULL
        )

    IF @tar_count = 0
    BEGIN
        DECLARE @SGC_ID INT
        SELECT
            @SGC_ID = [sgc].[SourceGroupCertificateID]
        FROM
            [Permission].[SourceGroupCertificate] AS [sgc]
        WHERE
            [sgc].[SourceGroupID] = @SourceGroupID


        EXEC [Permission].[DropTargetGroupCertificateByID] @SGC_ID, @TargetDatabaseID, @debug

        IF @src_count = 0
            EXEC [Permission].[DropSourceGroupCertificateByID] @SGC_ID, @debug
    END

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
