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

CREATE OR ALTER PROCEDURE [Permission].[AddGroupRoleRequestFromName]
      @src_db_name      SYSNAME
    , @src_group_name   SYSNAME
    , @tar_db_name      SYSNAME
    , @role_name        SYSNAME
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @SourceGroupID    INT
        , @TargetRoleID     INT
        , @PermissionID     INT

    -- Don't add groups on the fly
    EXEC [Permission].[SourceGroupIDFromName] @src_db_name, @src_group_name, @SourceGroupID OUTPUT, 1

    EXEC [Permission].[GetOrCreateTargetRoleIDFromName] @tar_db_name, @role_name, @TargetRoleID OUTPUT

    -- Insert if not exists (avoid erroring on attempted duplicate primary key)
    IF NOT EXISTS (
        SELECT *
        FROM [Permission].[GroupRoleRequest] AS [grr]
        WHERE [grr].[SourceGroupID] = @SourceGroupID
            AND [grr].[TargetRoleID] = @TargetRoleID
    )
    BEGIN
        INSERT INTO [Permission].[GroupRoleRequest] (
              [SourceGroupID]
            , [TargetRoleID]
        ) VALUES (
              @SourceGroupID
            , @TargetRoleID
        )
    END

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
