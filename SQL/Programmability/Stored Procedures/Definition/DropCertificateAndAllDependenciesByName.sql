USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================
-- Author:          John Merkel
-- Creation date:   October 20, 2021
-- Description:     Drops a certificate and all of its dependencies
--                  from a provided DB.
-- Requires:        SA
-- ======================================================================

CREATE OR ALTER PROCEDURE [Definition].[DropCertAndDependenciesByName]
      @db_name          SYSNAME
    , @cert_name        SYSNAME
    , @user_required    BIT
    , @cert_required    BIT
    , @debug            BIT = 1
AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    DECLARE
          @executesql   NVARCHAR(350)
        , @sql_start    NVARCHAR(200)
        , @sql_end      NVARCHAR(200)
        , @sql          NVARCHAR(MAX)
        , @params       NVARCHAR(MAX)
        , @db_id        INT
        , @cert_id      INT
        , @thumbprint   VARBINARY(32)
        , @object_id    INT

    DECLARE @SignedEntities TABLE (
          [entity_id] INT NOT NULL
    )

    -- Get database id
    EXEC [Validation].[DBIDFromName] @db_name, @db_id OUTPUT, 1

    -- Get certificate id
    EXEC [Validation].[CertificateIDFromName]
          @db_name
        , @cert_name
        , @cert_id OUTPUT
        , @cert_required
        , @debug

    -- If the act of dropping the cert is not required and the cert could not be found, return
    IF @cert_required = 0 AND @cert_id IS NULL
        RETURN

    -- Get thumbprint for certificate
    EXEC [Validation].[CertThumbprintFromID]
          @db_id
        , @cert_id
        , @thumbprint OUTPUT
        , 1
        , @debug

    EXEC [dbo].[InitDynamicSQL]
          @db_name
        , @executesql   OUTPUT
        , @sql_start    OUTPUT
        , @sql_end      OUTPUT

    -- Create cursor for all objects signed by certificate
    SELECT
        @sql =
            @sql_start
            + 'SELECT [sigs].[entity_id]
                FROM [sys].[fn_check_object_signatures] (''certificate'', @thumbprint) AS [sigs]
                WHERE [sigs].[is_signed] = 1'
            + @sql_end
        , @params = 
            '@thumbprint VARBINARY(32)'
    IF @debug = 1 PRINT '-- Getting list of objects signed by certificate: "' + @cert_name + '"'
    IF @debug = 1 PRINT @sql
    INSERT INTO @SignedEntities
        EXEC @executesql @sql, @params, @thumbprint

    IF EXISTS (SELECT * FROM @SignedEntities)
    BEGIN
        DECLARE [objects_cur] CURSOR STATIC LOCAL FOR
            SELECT DISTINCT [entity_id] FROM @SignedEntities
        OPEN [objects_cur]
        -- Drop certificate's signature from signed objects
        WHILE 1 = 1
        BEGIN
            FETCH NEXT FROM [objects_cur] INTO @object_id
            IF @@FETCH_STATUS <> 0 BREAK

            EXEC [Definition].[DropSigFromObjByID] @db_id, @object_id, @cert_id, @debug
        END
        CLOSE [objects_cur]
        DEALLOCATE [objects_cur]
    END

    -- Drop certificate user
    EXEC [Definition].[DropCertUserByName] @db_name, @cert_name, @user_required, @debug

    -- Drop certificate
    EXEC [Definition].[DropCertificateByName] @db_name, @cert_name, @debug


    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    -- In cases there is an error while we are impersonating dbo, we need
    -- to revert back, which must be done in the user database.
    IF EXISTS (
        SELECT * FROM [sys].[login_token] WHERE [usage] = 'DENY ONLY'
    )
    BEGIN
        IF @debug = 1 PRINT '-- Error while impersonating dbo, reverting'
        EXEC @executesql N'REVERT'
    END
    ; THROW
END CATCH
GO
