USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 25, 2021
-- Description:     Grants all SourceObjects their requested permissions.
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

CREATE OR ALTER PROCEDURE [Permission].[GrantAllSourceObjectRequests]
      @GrantNewRequests BIT
    , @debug            BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE @SourceObjectID INT

    DECLARE [src_object_cur] CURSOR STATIC LOCAL FOR
        SELECT DISTINCT [SourceObjectID]
        FROM [Permission].[SourceObject]
    OPEN [src_object_cur]
    WHILE 1 = 1
    BEGIN
        FETCH NEXT FROM [src_object_cur] INTO @SourceObjectID
        IF @@FETCH_STATUS <> 0 BREAK

        EXEC [Permission].[GrantSourceObjectRequests] @SourceObjectID, @GrantNewRequests, @debug
    END
    CLOSE [src_object_cur]
    DEALLOCATE [src_object_cur]

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
