USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 25, 2021
-- Description:     
-- Return:          
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Permission].[DeleteSourceGroupByID]
      @SourceGroupID    INT
    , @debug            BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    EXEC [Permission].[RevokeGroupByID] @SourceGroupID, 1, @debug

    DELETE [sg]
    FROM [Permission].[SourceGroup] AS [sg]
    WHERE [sg].[SourceGroupID] = @SourceGroupID

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
