USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 19, 2021
-- Description:     Drops a certificate user from a provided DB.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Definition].[DropCertUserByName]
      @db_name      SYSNAME
    , @cert_name    SYSNAME
    , @raiserror    BIT = 1
    , @debug        BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE @username SYSNAME

    EXEC [Validation].[ValidateDBName] @db_name OUTPUT, 1

    EXEC [Validation].[ValidateCertName] @db_name, @cert_name OUTPUT, 1, @debug

    EXEC [Validation].[ValidateCertUsername] @db_name, @cert_name, @username OUTPUT, @raiserror, @debug

    IF @username IS NOT NULL
        EXEC [Definition].[DropUserByName] @db_name, @username, @raiserror, @debug

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO
