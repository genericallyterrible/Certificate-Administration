USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 20, 2021
-- Description:     
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Permission].[DropAllTargetGroupCertsByID]
      @SourceGroupCertificateID INT
    , @debug                    BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE @TargetDatabaseID INT

    DECLARE [TD_ID_cursor] CURSOR STATIC LOCAL FOR
        SELECT DISTINCT [tgc].[TargetDatabaseID]
        FROM [Permission].[TargetGroupCertificate] AS [tgc]
        WHERE [tgc].[SourceGroupCertificateID] = @SourceGroupCertificateID
    OPEN [TD_ID_cursor]

    WHILE 1 = 1
    BEGIN
        FETCH NEXT FROM [TD_ID_cursor] INTO @TargetDatabaseID
        IF @@FETCH_STATUS <> 0 BREAK

        EXEC [Permission].[DropTargetGroupCertificateByID]
              @SourceGroupCertificateID
            , @TargetDatabaseID
            , @debug
    END

    CLOSE [TD_ID_cursor]
    DEALLOCATE [TD_ID_cursor]

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
