USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 19, 2021
-- Description:     
-- Return:          
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Permission].[AddGroupPermissionRequestFromName]
      @src_db_name      SYSNAME
    , @src_group_name   SYSNAME
    , @tar_db_name      SYSNAME
    , @tar_schema_name  SYSNAME
    , @tar_object_name  SYSNAME
    , @permission       VARCHAR(50)
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @SourceGroupID    INT
        , @TargetObjectID   INT
        , @PermissionID     INT

    EXEC [Permission].[PermissionIDFromName] @permission, @PermissionID OUTPUT

    -- Don't add groups on the fly
    EXEC [Permission].[SourceGroupIDFromName] @src_db_name, @src_group_name, @SourceGroupID OUTPUT, 1

    EXEC [Permission].[GetOrCreateTargetObjectIDFromName] @tar_db_name, @tar_schema_name, @tar_object_name, @TargetObjectID OUTPUT

    -- Insert if not exists (avoid erroring on attempted duplicate primary key)
    IF NOT EXISTS (
        SELECT *
        FROM [Permission].[GroupPermissionRequest] AS [gpr]
        WHERE [gpr].[SourceGroupID] = @SourceGroupID
            AND [gpr].[TargetObjectID] = @TargetObjectID
            AND [gpr].[GrantablePermissionID] = @PermissionID
    )
    BEGIN
        INSERT INTO [Permission].[GroupPermissionRequest] (
              [SourceGroupID]
            , [TargetObjectID]
            , [GrantablePermissionID]
        ) VALUES (
              @SourceGroupID
            , @TargetObjectID
            , @PermissionID
        )
    END

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
