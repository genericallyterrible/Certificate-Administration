USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 20, 2021
-- Description:     Revokes a TargetRole from the SourceGroup.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Permission].[RevokeGroupRoleByID]
      @SourceGroupID    INT
    , @TargetRoleID     INT
    , @DropRequest      BIT
    , @debug            BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @TargetDatabaseID INT
        , @tar_db_id        INT
        , @tar_role_id      INT
        , @tar_cert_id      INT
        , @granted          BIT

    SELECT
          @TargetDatabaseID = [pr].[TargetDatabaseID]
        , @tar_db_id        = [pr].[tar_db_id]
        , @tar_role_id      = [pr].[tar_role_id]
        , @tar_cert_id      = [pr].[tar_cert_id]
        , @granted          = [pr].[Granted]
    FROM
        [Permission].[PermissionRequests] AS [pr]
    WHERE
        [pr].[SourceGroupID] = @SourceGroupID
        AND [pr].[TargetRoleID] = @TargetRoleID

    IF @tar_db_id IS NULL
        RAISERROR(
            'No group permission request exists with SourceGroupID: "%d" TargetRoleID: "%d"'
            , 16, 1
            , @SourceGroupID, @TargetRoleID
        )

    -- Only hit other databases if the permission has been granted
    IF @granted = 1
    BEGIN

        DECLARE
              @tar_db_name          SYSNAME
            , @tar_role_name        SYSNAME
            , @tar_cert_username    SYSNAME

        -- Get db name
        EXEC [Validation].[DBNameFromID] @tar_db_id, @tar_db_name, 1

        -- Get certificate username
        EXEC [Validation].[CertUsernameFromCertID]
              @tar_db_id
            , @tar_cert_id
            , @tar_cert_username OUTPUT
            , 1
            , @debug

        -- Revoke role
        EXEC [Definition].[DropMemberFromRoleByName]
              @tar_db_name
            , @tar_role_name
            , @tar_cert_username
            , @debug
    END

    IF @DropRequest = 1
        -- Permissions revoked, drop request
        DELETE [grr]
        FROM [Permission].[GroupRoleRequest] AS [grr]
        WHERE
            [grr].[SourceGroupID] = @SourceGroupID
            AND [grr].[TargetRoleID] = @TargetRoleID
    ELSE IF @granted = 1
        -- Permission revoked, set Granted = 0
        UPDATE [grr]
        SET [grr].[granted] = 0
        FROM [Permission].[GroupRoleRequest] AS [grr]
        WHERE
            [grr].[SourceGroupID] = @SourceGroupID
            AND [grr].[TargetRoleID] = @TargetRoleID

    -- Try to clear any certs that aren't granting permissions
    EXEC [Permission].[TryToDropGroupCertificates] @SourceGroupID, @TargetDatabaseID, @debug

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
