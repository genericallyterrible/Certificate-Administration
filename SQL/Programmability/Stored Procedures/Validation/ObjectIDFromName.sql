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

CREATE OR ALTER PROCEDURE [Validation].[ObjectIDFromName]
      @db_name      SYSNAME
    , @schema_name  SYSNAME
    , @object_name  SYSNAME
    , @object_id    INT OUTPUT
    , @raiserror    BIT = 1
AS
BEGIN
    SELECT @object_id = OBJECT_ID(
        QUOTENAME(@db_name)
        + '.' + QUOTENAME(@schema_name)
        + '.' + QUOTENAME(@object_name)
    )

    IF @raiserror = 1 AND @object_id IS NULL
        RAISERROR('Could not find object %s', 16, 1, @object_name)
END
GO
