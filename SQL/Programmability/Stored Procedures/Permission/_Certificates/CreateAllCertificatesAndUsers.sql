USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 25, 2021
-- Description:     Creates source and target certificates and
--                  certificate users for all objects and groups
--                  that do not currently have either.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Permission].[CreateAllCertificatesAndUsers]
    @debug BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @SourceObjectID               INT
        , @SourceObjectCertificateID    INT
        , @SourceGroupID                INT
        , @SourceGroupCertificateID     INT
        , @TargetDatabaseID             INT
        , @TargetDatabaseCursor         CURSOR


    -- ===================
    -- ===== OBJECTS =====
    -- ===================

    IF @debug = 1 PRINT '-- Creating certificates for all objects'

    -- Iterate over all source objects with requests
    DECLARE [src_obj_cur] CURSOR LOCAL STATIC FOR
        SELECT DISTINCT
              [pr].[SourceObjectID]
            , [pr].[SourceCertificateID]
        FROM [Permission].[PermissionRequests] AS [pr]
        WHERE [pr].[SourceObjectID] IS NOT NULL
    OPEN [src_obj_cur]
    WHILE 1 = 1
    BEGIN
        FETCH NEXT FROM [src_obj_cur] INTO @SourceObjectID, @SourceObjectCertificateID
        IF @@FETCH_STATUS <> 0 BREAK

        -- Create source certificate if it does not exist
        IF @SourceObjectCertificateID IS NULL
            EXEC [Permission].[CreateSourceObjectCertificate]
                  @SourceObjectID
                , @SourceObjectCertificateID OUTPUT
                , @debug

        -- Iterate over all target databases for the source that don't have a certificate yet
        SET @TargetDatabaseCursor = CURSOR LOCAL STATIC FOR
            SELECT DISTINCT [TargetDatabaseID]
            FROM [Permission].[PermissionRequests] AS [pr]
            WHERE [pr].[SourceObjectID] = @SourceObjectID
                AND [pr].[TargetDatabaseID] IS NOT NULL
                AND [pr].[TargetCertificateID] IS NULL
        OPEN @TargetDatabaseCursor
        WHILE 1 = 1
        BEGIN
            FETCH NEXT FROM @TargetDatabaseCursor INTO @TargetDatabaseID
            IF @@FETCH_STATUS <> 0 BREAK

            -- Export source certificate to all target databases
            EXEC [Permission].[CreateTargetObjectCertificateAndUser]
                  @SourceObjectCertificateID
                , @TargetDatabaseID
                , @debug
        END
        CLOSE @TargetDatabaseCursor
    END
    CLOSE [src_obj_cur]
    DEALLOCATE [src_obj_cur]


    -- ==================
    -- ===== GROUPS =====
    -- ==================

    IF @debug = 1 PRINT '-- Creating certificates for all groups'

    -- Iterate over all source groups with requests
    DECLARE [src_group_cur] CURSOR LOCAL STATIC FOR
        SELECT DISTINCT
              [pr].[SourceGroupID]
            , [pr].[SourceCertificateID]
        FROM [Permission].[PermissionRequests] AS [pr]
        WHERE [pr].[SourceGroupID] IS NOT NULL
    OPEN [src_group_cur]
    WHILE 1 = 1
    BEGIN
        FETCH NEXT FROM [src_group_cur] INTO @SourceGroupID, @SourceGroupCertificateID
        IF @@FETCH_STATUS <> 0 BREAK

        -- Create source certificate if it does not exist
        
        IF @SourceGroupCertificateID IS NULL
            EXEC [Permission].[CreateSourceGroupCertificate]
                  @SourceGroupID
                , @SourceGroupCertificateID OUTPUT
                , @debug

        -- Iterate over all target databases for the source that don't have a certificate yet
        SET @TargetDatabaseCursor = CURSOR LOCAL STATIC FOR
            SELECT DISTINCT [TargetDatabaseID]
            FROM [Permission].[PermissionRequests] AS [pr]
            WHERE [pr].[SourceGroupID] = @SourceGroupID
                AND [pr].[TargetDatabaseID] IS NOT NULL
                AND [pr].[TargetCertificateID] IS NULL
        OPEN @TargetDatabaseCursor
        WHILE 1 = 1
        BEGIN
            FETCH NEXT FROM @TargetDatabaseCursor INTO @TargetDatabaseID
            IF @@FETCH_STATUS <> 0 BREAK

            -- Export source certificate to all target databases
            EXEC [Permission].[CreateTargetGroupCertificateAndUser]
                  @SourceGroupCertificateID
                , @TargetDatabaseID
                , @debug
        END
        CLOSE @TargetDatabaseCursor
    END
    CLOSE [src_group_cur]
    DEALLOCATE [src_group_cur]

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

    PRINT '-- Error creating all certificates and users'

    ; THROW
END CATCH
GO
