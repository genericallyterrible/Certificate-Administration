USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 20, 2021
-- Description:     Drops a certificate from a provided DB.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Validation].[CertThumbprintFromName]
      @db_name      SYSNAME
    , @cert_name    SYSNAME
    , @thumbprint   VARBINARY(32) OUTPUT
    , @raiserror    BIT = 1
    , @debug        BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @db_id INT
        , @cert_id INT

    EXEC [Validation].[DBIDFromName] @db_name, @db_id OUTPUT, 1
    EXEC [Validation].[CertificateIDFromName] @db_name, @cert_name, @cert_id OUTPUT, 1, @debug

    EXEC [Validation].[CertThumbprintFromID] @db_id, @cert_id, @thumbprint OUTPUT, @raiserror, @debug

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
