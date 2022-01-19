USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 1, 2021
-- Description:     Checks to see if DB exists.
-- Return:          DB name exactly as it appears in
--                  sys.databases or NULL.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Validation].[ValidateDBName]
      @db_name      SYSNAME OUTPUT
    , @raiserror    BIT = 1
AS
BEGIN
    DECLARE @orig SYSNAME = @db_name
    SELECT @db_name = DB_NAME(DB_ID(@db_name))
    -- Verify that the database exists.
    IF @raiserror = 1 AND @db_name IS NULL
        RAISERROR('Database "%s" does not exist.', 16, 1, @orig)
END
GO
