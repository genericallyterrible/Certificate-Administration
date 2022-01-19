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

CREATE OR ALTER PROCEDURE [Permission].[TryToDropObjectCertificates]
      @SourceObjectID   INT
    , @TargetDatabaseID INT
    , @debug            BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @src_count INT
        , @tar_count INT

    -- Get count of roles/perms associated with SourceObject in TargetDatabase
    SELECT
        @tar_count = COUNT(*)
    FROM
        [Permission].[TargetDatabase] AS [td]
        JOIN [Permission].[TargetObject] AS [to]
            ON [td].[TargetDatabaseID] = [to].[TargetDatabaseID]
        JOIN [Permission].[TargetRole] AS [tr]
            ON [td].[TargetDatabaseID] = [tr].[TargetDatabaseID]
        LEFT JOIN [Permission].[ObjectPermissionRequest] AS [opr]
            ON [to].[TargetObjectID] = [opr].[TargetObjectID]
            AND [opr].[SourceObjectID] = @SourceObjectID
            AND [opr].[Granted] = 1
        LEFT JOIN [Permission].[ObjectRoleRequest] AS [orr]
            ON [tr].[TargetRoleID] = [orr].[TargetRoleID]
            AND [orr].[SourceObjectID] = @SourceObjectID
            AND [orr].[Granted] = 1
    WHERE
        [td].[TargetDatabaseID] = @TargetDatabaseID
        AND (
            [opr].[SourceObjectID] IS NOT NULL
            OR [orr].[SourceObjectID] IS NOT NULL
        )

    -- Get count of roles/perms associated with SourceObject
    SELECT
        @src_count = COUNT(*)
    FROM
        [Permission].[SourceObject] AS [so]
        LEFT JOIN [Permission].[ObjectPermissionRequest] AS [opr]
            ON [so].[SourceObjectID] = [opr].[SourceObjectID]
            AND [opr].[Granted] = 1
        LEFT JOIN [Permission].[ObjectRoleRequest] AS [orr]
            ON [so].[SourceObjectID] = [orr].[SourceObjectID]
            AND [orr].[Granted] = 1
    WHERE
        [so].[SourceObjectID] = @SourceObjectID
        AND (
            [opr].[SourceObjectID] IS NOT NULL
            OR [orr].[SourceObjectID] IS NOT NULL
        )

    IF @tar_count = 0
    BEGIN
        DECLARE @SOC_ID INT
        SELECT
            @SOC_ID = [soc].[SourceObjectCertificateID]
        FROM
            [Permission].[SourceObjectCertificate] AS [soc]
        WHERE
            [soc].[SourceObjectID] = @SourceObjectID


        EXEC [Permission].[DropTargetObjectCertificateByID] @SOC_ID, @TargetDatabaseID, @debug

        IF @src_count = 0
            EXEC [Permission].[DropSourceObjectCertificateByID] @SOC_ID, @debug
    END

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
