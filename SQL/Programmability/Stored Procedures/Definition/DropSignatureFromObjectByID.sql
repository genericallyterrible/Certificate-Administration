USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 20, 2021
-- Description:     Drops a signature made by a certificate from the
--                  provided object using ID's.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Definition].[DropSigFromObjByID]
      @db_id        INT
    , @object_id    INT
    , @cert_id      INT
    , @debug        BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @db_name      SYSNAME
        , @schema_name  SYSNAME
        , @object_name  SYSNAME
        , @cert_name    SYSNAME

    EXEC [Validation].[AllNamesFromIDs]
          @db_id
        , @object_id
        , @db_name      OUTPUT
        , @schema_name  OUTPUT
        , @object_name  OUTPUT
        , 1
        , @debug

    EXEC [Validation].[CertificateNameFromID] @db_id, @cert_id, @cert_name OUTPUT, 1, @debug

    EXEC [Definition].[DropSigFromObjByName] @db_name, @schema_name, @object_name, @cert_name, @debug

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
