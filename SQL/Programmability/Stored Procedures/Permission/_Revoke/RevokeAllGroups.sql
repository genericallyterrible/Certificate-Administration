USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 25, 2021
-- Description:     Revokes all permissions/roles for all SourceGroups.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Permission].[RevokeAllGroups]
      @DropRequests     BIT
    , @debug            BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE @SourceGroupID INT

    DECLARE [src_group_cur] CURSOR STATIC LOCAL FOR
        SELECT DISTINCT [SourceGroupID]
        FROM [Permission].[SourceGroup]
        WHERE [SourceGroupID] IS NOT NULL
    OPEN [src_group_cur]
    WHILE 1 = 1
    BEGIN
        FETCH NEXT FROM [src_group_cur] INTO @SourceGroupID
        IF @@FETCH_STATUS <> 0 BREAK

        EXEC [Permission].[RevokeGroupByID] @SourceGroupID, @DropRequests, @debug
    END
    CLOSE [src_group_cur]
    DEALLOCATE [src_group_cur]

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
