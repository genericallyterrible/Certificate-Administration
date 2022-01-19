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

CREATE OR ALTER PROCEDURE [Validation].[ValidateObjectID]
      @db_id        INT
    , @object_id    INT OUTPUT
    , @raiserror    BIT = 1
    , @debug        BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE @name SYSNAME

    SELECT @name = OBJECT_NAME(@object_id, @db_id)

    IF @name IS NULL
    BEGIN
        IF @raiserror = 1
            RAISERROR('No object with id: "%d" in database: "%d"', 16, 1, @object_id, @db_id)
        IF @debug = 1
            PRINT '-- No object with id: ' + QUOTENAME(@object_id, '"') + ' in database: ' + QUOTENAME(@db_id, '"')
                + CHAR(13) + CHAR(10)
    END

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
