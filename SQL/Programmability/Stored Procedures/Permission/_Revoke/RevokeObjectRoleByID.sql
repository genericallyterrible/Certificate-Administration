USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 20, 2021
-- Description:     Revokes a TargetRole from the SourceObject.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Permission].[RevokeObjectRoleByID]
      @SourceObjectID   INT
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
          @TargetDatabaseID = [td].[TargetDatabaseID]
        , @tar_db_id        = [td].[database_id]
        , @tar_role_id      = [tr].[role_principal_id]
        , @tar_cert_id      = [toc].[certificate_id]
        , @granted          = [orr].[Granted]
    FROM
        [Permission].[ObjectRoleRequest] AS [orr]
        JOIN [Permission].[TargetRole] AS [tr]
            ON [orr].[TargetRoleID] = [tr].[TargetRoleID]
        JOIN [Permission].[TargetDatabase] AS [td]
            ON [tr].[TargetDatabaseID] = [td].[TargetDatabaseID]
        JOIN [Permission].[SourceObjectCertificate] AS [soc]
            ON [orr].[SourceObjectID] = [soc].[SourceObjectID]
        JOIN [Permission].[TargetObjectCertificate] AS [toc]
            ON [soc].[SourceObjectCertificateID] = [toc].[SourceObjectCertificateID]
    WHERE
        [orr].[SourceObjectID] = @SourceObjectID
        AND [orr].[TargetRoleID] = @TargetRoleID

    IF @tar_db_id IS NULL
        RAISERROR(
            'No object permission request exists with SourceObjectID: "%d" TargetRoleID: "%d"'
            , 16, 1
            , @SourceObjectID, @TargetRoleID
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
        DELETE [orr]
        FROM [Permission].[ObjectRoleRequest] AS [orr]
        WHERE
            [orr].[SourceObjectID] = @SourceObjectID
            AND [orr].[TargetRoleID] = @TargetRoleID
    ELSE IF @granted = 1
        -- Permissions revoked, set Granted = 0
        UPDATE [orr]
        SET [orr].[Granted] = 0
        FROM [Permission].[ObjectRoleRequest] AS [orr]
        WHERE
            [orr].[SourceObjectID] = @SourceObjectID
            AND [orr].[TargetRoleID] = @TargetRoleID

    -- Try to clear any certs that aren't granting permissions
    EXEC [Permission].[TryToDropObjectCertificates] @SourceObjectID, @TargetDatabaseID, @debug

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
