USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 20, 2021
-- Description:     Revokes a GrantablePermission from the SourceObject
--                  on the TargetObject.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Permission].[RevokeObjectPermissionByID]
      @SourceObjectID           INT
    , @TargetObjectID           INT
    , @GrantablePermissionID    INT
    , @DropRequest              BIT
    , @debug                    BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @TargetDatabaseID INT
        , @tar_db_id        INT
        , @tar_obj_id       INT
        , @tar_cert_id      INT
        , @permission       VARCHAR(50)
        , @granted          BIT

    SELECT
          @TargetDatabaseID = [pr].[TargetDatabaseID]
        , @tar_db_id        = [pr].[tar_db_id]
        , @tar_obj_id       = [pr].[tar_obj_id]
        , @tar_cert_id      = [pr].[tar_cert_id]
        , @permission       = [pr].[Permission]
        , @granted          = [pr].[Granted]
    FROM
        [Permission].[PermissionRequests] AS [pr]
    WHERE
        [pr].[SourceObjectID] = @SourceObjectID
        AND [pr].[TargetObjectID] = @TargetObjectID
        AND [pr].[GrantablePermissionID] = @GrantablePermissionID

    IF @tar_db_id IS NULL
        RAISERROR(
            'No object permission request exists with SourceObjectID: "%d" TargetObjectID: "%d" GrantablePermissionID: "%d"'
            , 16, 1
            , @SourceObjectID, @TargetObjectID, @GrantablePermissionID
        )

    -- Only hit other databases if the permission has been granted
    IF @granted = 1
    BEGIN

        DECLARE
              @tar_db_name          SYSNAME
            , @tar_schema_name      SYSNAME
            , @tar_obj_name         SYSNAME
            , @tar_cert_username    SYSNAME

        -- Get db, schema, and object names
        EXEC [Validation].[AllNamesFromIDs]
              @tar_db_id
            , @tar_obj_id
            , @tar_db_name      OUTPUT
            , @tar_schema_name  OUTPUT
            , @tar_obj_name     OUTPUT
            , 1
            , @debug

        -- Get certificate username
        EXEC [Validation].[CertUsernameFromCertID]
              @tar_db_id
            , @tar_cert_id
            , @tar_cert_username OUTPUT
            , 1
            , @debug

        -- Revoke permission
        EXEC [Definition].[RevokePermOnObjFromUserByName]
              @tar_db_name
            , @tar_schema_name
            , @tar_obj_name
            , @tar_cert_username
            , @permission
            , @debug
    END

    IF @DropRequest = 1
        -- Permissions revoked, drop request
        DELETE [opr]
        FROM [Permission].[ObjectPermissionRequest] AS [opr]
        WHERE
            [opr].[SourceObjectID] = @SourceObjectID
            AND [opr].[TargetObjectID] = @TargetObjectID
            AND [opr].[GrantablePermissionID] = @GrantablePermissionID
    ELSE IF @granted = 1
        -- Permissions revoked, set Granted = 0
        UPDATE [opr]
        SET [opr].[Granted] = 0
        FROM [Permission].[ObjectPermissionRequest] AS [opr]
        WHERE
            [opr].[SourceObjectID] = @SourceObjectID
            AND [opr].[TargetObjectID] = @TargetObjectID
            AND [opr].[GrantablePermissionID] = @GrantablePermissionID

    -- Try to clear any certs that aren't granting permissions
    EXEC [Permission].[TryToDropObjectCertificates] @SourceObjectID, @TargetDatabaseID, @debug

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
