USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 25, 2021
-- Description:     Revokes all permissions/roles for the SourceGroup.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Permission].[RevokeGroupByID]
      @SourceGroupID    INT
    , @DropRequests     BIT
    , @debug            BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE @SourceGroupCertificateID INT

    SELECT @SourceGroupCertificateID = [sgc].[SourceGroupCertificateID]
    FROM [Permission].[SourceGroupCertificate] AS [sgc]
        WHERE [sgc].[SourceGroupID] = @SourceGroupID

    IF @SourceGroupCertificateID IS NOT NULL
    BEGIN
        -- Drop all group specific certificates
        EXEC [Permission].[DropAllTargetGroupCertsByID] @SourceGroupCertificateID, @debug
        EXEC [Permission].[DropSourceGroupCertificateByID] @SourceGroupCertificateID, @debug
    END

    -- Delete object requests or set granted = 0
    IF @DropRequests = 1
    BEGIN
        DELETE [gpr]
        FROM [Permission].[GroupPermissionRequest] AS [gpr]
        WHERE [gpr].[SourceGroupID] = @SourceGroupID

        DELETE [grr]
        FROM [Permission].[GroupRoleRequest] AS [grr]
        WHERE [grr].[SourceGroupID] = @SourceGroupID
    END
    ELSE
    BEGIN
        UPDATE [Permission].[GroupPermissionRequest]
        SET [Granted] = 0
        WHERE [SourceGroupID] = @SourceGroupID

        UPDATE [Permission].[GroupRoleRequest]
        SET [Granted] = 0
        WHERE [SourceGroupID] = @SourceGroupID
    END

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
