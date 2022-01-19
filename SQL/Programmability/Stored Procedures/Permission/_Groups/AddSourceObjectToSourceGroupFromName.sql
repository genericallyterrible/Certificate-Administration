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

CREATE OR ALTER PROCEDURE [Permission].[AddSourceObjectToSourceGroupFromName]
      @db_name          SYSNAME
    , @schema_name      SYSNAME
    , @object_name      SYSNAME
    , @group_name       SYSNAME
    , @debug            BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @SourceGroupID            INT
        , @SourceObjectID           INT
        , @SourceGroupCertificateID INT
        , @TargetDatabaseID         INT

    -- Get or create group
    EXEC [Permission].[GetOrCreateSourceGroupIDFromName]
        @db_name
        , @group_name
        , @SourceGroupID OUTPUT

    -- Get or create object
    EXEC [Permission].[GetOrCreateSourceObjectIDFromName]
          @db_name
        , @schema_name
        , @object_name
        , @SourceObjectID OUTPUT

    -- If the object is already a member of the group, return
    IF EXISTS (
        SELECT *
        FROM [Permission].[SourceGroupObject]
        WHERE [SourceGroupID] = @SourceGroupID
            AND [SourceObjectID] = @SourceObjectID
    ) RETURN

    -- Add object to group
    INSERT INTO [Permission].[SourceGroupObject] (
          [SourceGroupID]
        , [SourceObjectID]
    ) VALUES (
          @SourceGroupID
        , @SourceObjectID
    )

    -- Check to see if SourceGroup has a certificate associated with it already
    SELECT @SourceGroupCertificateID = [sgc].[SourceGroupCertificateID]
    FROM [Permission].[SourceGroupCertificate] AS [sgc]
    WHERE [sgc].[SourceGroupID] = @SourceGroupID

    -- Certificate already exists, we have to recreate it to add the new object
    IF @SourceGroupCertificateID IS NOT NULL
    BEGIN
        IF @debug = 1 PRINT CONCAT('-- Rebuilding certificates for source group with ID: ', @SourceGroupID)
        -- Drop group's certificates
        EXEC [Permission].[DropAllTargetGroupCertsByID] @SourceGroupCertificateID, @debug
        EXEC [Permission].[DropSourceGroupCertificateByID] @SourceGroupCertificateID, @debug

        -- Rebuild group's certificates
        EXEC [Permission].[CreateSourceGroupCertificate] @SourceGroupID, @SourceGroupCertificateID OUTPUT, @debug

        DECLARE [tar_db_cur] CURSOR STATIC LOCAL FOR
            SELECT DISTINCT [TargetDatabaseID]
            FROM [Permission].[PermissionRequests] AS [pr]
            WHERE [pr].[SourceGroupID] = @SourceGroupID
        OPEN [tar_db_cur]
        WHILE 1 = 1
        BEGIN
            FETCH NEXT FROM [tar_db_cur] INTO @TargetDatabaseID
            IF @@FETCH_STATUS <> 0 BREAK
            -- Create new target certificate in target database
            EXEC [Permission].[CreateTargetGroupCertificateAndUser] @SourceGroupCertificateID, @TargetDatabaseID, @debug
        END
        CLOSE [tar_db_cur]
        DEALLOCATE [tar_db_cur]
        
        -- Grant permissions to target certificates (where granted = 1 already, don't grant new perms)
        EXEC [Permission].[GrantSourceGroupRequests] @SourceGroupID, 0, @debug
    END

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
