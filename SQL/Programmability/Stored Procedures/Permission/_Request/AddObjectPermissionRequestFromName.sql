USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 18, 2021
-- Description:     
-- Return:          
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Permission].[AddObjectPermissionRequestFromName]
      @src_db_name      SYSNAME
    , @src_schema_name  SYSNAME
    , @src_object_name  SYSNAME
    , @tar_db_name      SYSNAME
    , @tar_schema_name  SYSNAME
    , @tar_object_name  SYSNAME
    , @permission       VARCHAR(50)
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @SourceObjectID   INT
        , @TargetObjectID   INT
        , @PermissionID     INT

    EXEC [Permission].[PermissionIDFromName] @permission, @PermissionID OUTPUT

    EXEC [Permission].[GetOrCreateSourceObjectIDFromName] @src_db_name, @src_schema_name, @src_object_name, @SourceObjectID OUTPUT

    EXEC [Permission].[GetOrCreateTargetObjectIDFromName] @tar_db_name, @tar_schema_name, @tar_object_name, @TargetObjectID OUTPUT

    -- Insert if not exists (avoid erroring on attempted duplicate primary key)
    IF NOT EXISTS (
        SELECT *
        FROM [Permission].[ObjectPermissionRequest] AS [opr]
        WHERE [opr].[SourceObjectID] = @SourceObjectID
            AND [opr].[TargetObjectID] = @TargetObjectID
            AND [opr].[GrantablePermissionID] = @PermissionID
    )
    BEGIN
        INSERT INTO [Permission].[ObjectPermissionRequest] (
              [SourceObjectID]
            , [TargetObjectID]
            , [GrantablePermissionID]
        ) VALUES (
              @SourceObjectID
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
