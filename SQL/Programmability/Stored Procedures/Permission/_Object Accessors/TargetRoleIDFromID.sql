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

CREATE OR ALTER PROCEDURE [Permission].[TargetRoleIDFromID]
      @db_id            INT
    , @role_id          INT
    , @TargetRoleID     INT OUTPUT
    , @raiserror        BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE @DatabaseID INT

    EXEC [Permission].[TargetDBIDFromID] @db_id, @DatabaseID OUTPUT, @raiserror

    SELECT
        @TargetRoleID = MIN([TargetRoleID])
    FROM
        [Permission].[TargetRole] AS [tr]
    WHERE
        [tr].[TargetDatabaseID] = @DatabaseID
        AND [tr].[role_principal_id] = @role_id

    IF @raiserror = 1 AND @TargetRoleID IS NULL
        RAISERROR('Role with principal ID "%d" has not been added as a target role for database "%d".', 16, 1, @role_id, @db_id)

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
