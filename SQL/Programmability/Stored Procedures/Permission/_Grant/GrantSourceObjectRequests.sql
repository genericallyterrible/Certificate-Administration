USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 22, 2021
-- Description:     Grants a SourceObject the requested permissions.
--                  If @GrantNewRequests is 0, only permissions which
--                  have previously been granted (Granted = 1) will be
--                  granted. If @GrantNewRequests is 1, all permissions
--                  will be granted.
--                  Setting @GrantNewRequests = 0 is useful when the
--                  underlying certificate has changed and must be given
--                  the same permissions as the previous certificate.
--                  All certificate users must exist, this procedure only
--                  grants permissions to the existing certificate user.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Permission].[GrantSourceObjectRequests]
      @SourceObjectID   INT
    , @GrantNewRequests BIT
    , @debug            BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @perm_cur         CURSOR
        , @tar_db_id        INT
        , @tar_cert_id      INT
        , @tar_role_id      INT
        , @tar_object_id    INT
        , @tar_perm         VARCHAR(50)
        , @src_type         VARCHAR(50)
        , @req_type         VARCHAR(50)
        , @tar_db_name      SYSNAME
        , @tar_schema_name  SYSNAME
        , @tar_object_name  SYSNAME
        , @tar_role_name    SYSNAME
        , @tar_username     SYSNAME

    IF @GrantNewRequests = 0
        SET @perm_cur = CURSOR LOCAL STATIC FOR
            SELECT DISTINCT
                  [pr].[SourceType]
                , [pr].[RequestType]
                , [pr].[tar_db_id]
                , [pr].[tar_cert_id]
                , [pr].[tar_role_id]
                , [pr].[tar_obj_id]
                , [pr].[Permission]
            FROM [Permission].[PermissionRequests] AS [pr]
            WHERE [pr].[SourceObjectID] = @SourceObjectID
                AND [pr].[Granted] = 1
    ELSE
        SET @perm_cur = CURSOR LOCAL STATIC FOR
            SELECT DISTINCT
                  [pr].[SourceType]
                , [pr].[RequestType]
                , [pr].[tar_db_id]
                , [pr].[tar_cert_id]
                , [pr].[tar_role_id]
                , [pr].[tar_obj_id]
                , [pr].[Permission]
            FROM [Permission].[PermissionRequests] AS [pr]
            WHERE [pr].[SourceObjectID] = @SourceObjectID

    OPEN @perm_cur
    WHILE 1 = 1
    BEGIN
        FETCH NEXT FROM @perm_cur INTO
              @src_type
            , @req_type
            , @tar_db_id
            , @tar_cert_id
            , @tar_role_id
            , @tar_object_id
            , @tar_perm
        IF @@FETCH_STATUS <> 0 BREAK

        EXEC [Validation].[CertUsernameFromCertID]
              @tar_db_id
            , @tar_cert_id
            , @tar_username OUTPUT
            , 1
            , @debug

        IF @req_type = 'PERMISSION'
        BEGIN
            EXEC [Validation].[AllNamesFromIDs]
                  @tar_db_id
                , @tar_object_id
                , @tar_db_name      OUTPUT
                , @tar_schema_name  OUTPUT
                , @tar_object_name  OUTPUT
                , 1
                , @debug

            EXEC [Definition].[GrantPermOnObjToUserByName] 
                  @tar_db_name
                , @tar_schema_name
                , @tar_object_name
                , @tar_username
                , @tar_perm
                , @debug
        END
        ELSE IF @req_type = 'ROLE'
        BEGIN
            EXEC [Validation].[DBNameFromID]
                  @tar_db_id
                , @tar_db_name OUTPUT
                , 1

            EXEC [Validation].[RoleNameFromID]
                  @tar_db_id
                , @tar_role_id
                , @tar_role_name OUTPUT
                , 1
                , @debug

            EXEC [Definition].[AddMemberToRoleByName]
                  @tar_db_name
                , @tar_role_name
                , @tar_username
                , @debug
        END
    END
    CLOSE @perm_cur
    DEALLOCATE @perm_cur

    -- Set Granted = 1 if we are granting new permissions
    IF @GrantNewRequests = 1
    BEGIN
        UPDATE [Permission].[ObjectPermissionRequest]
        SET [Granted] = 1
        WHERE [SourceObjectID] = @SourceObjectID

        UPDATE [Permission].[ObjectRoleRequest]
        SET [Granted] = 1
        WHERE [SourceObjectID] = @SourceObjectID
    END

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
