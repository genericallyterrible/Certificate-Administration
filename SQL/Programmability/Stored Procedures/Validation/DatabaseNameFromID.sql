USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 5, 2021
-- Description:     
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Validation].[DBNameFromID]
      @db_id        INT
    , @db_name      SYSNAME OUTPUT
    , @raiserror    BIT = 1
AS
BEGIN
    SELECT @db_name = DB_NAME(@db_id)

    IF @raiserror = 1 AND @db_name IS NULL
        RAISERROR('Could not find database %d', 16, 1, @db_id)
END
GO
