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

CREATE OR ALTER PROCEDURE [Validation].[ObjectNameFromID]
      @db_id        INT
    , @object_id    INT
    , @object_name  SYSNAME OUTPUT
    , @raiserror    BIT = 1
AS
BEGIN
    SELECT @object_name = OBJECT_NAME(@object_id, @db_id)

    IF @raiserror = 1 AND @object_name IS NULL
        RAISERROR('Could not find object %d', 16, 1, @object_id)
END
GO
