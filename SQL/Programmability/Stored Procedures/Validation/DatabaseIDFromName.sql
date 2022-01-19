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

CREATE OR ALTER PROCEDURE [Validation].[DBIDFromName]
      @db_name      SYSNAME
    , @db_id        INT OUTPUT
    , @raiserror    BIT = 1
AS
BEGIN
    SELECT @db_id = DB_ID(@db_name)

    IF @raiserror = 1 AND @db_id IS NULL
        RAISERROR('Could not find database %s', 16, 1, @db_name)
END
GO
