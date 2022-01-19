USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 19, 2021
-- Description:     Checks to see if DB exists.
-- Return:          DB name exactly as it appears in
--                  sys.databases or NULL.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Validation].[ValidateDBID]
      @db_id        INT OUTPUT
    , @raiserror    BIT = 1
AS
BEGIN
    DECLARE @orig INT = @db_id
    SELECT @db_id = DB_ID(DB_NAME(@db_id))
    -- Verify that the database exists.
    IF @raiserror = 1 AND @db_id IS NULL
        RAISERROR('Database "%d" does not exist.', 16, 1, @orig)
END
GO
