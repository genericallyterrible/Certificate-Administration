-- ===========================
-- ==== Setup for example ====
-- ===========================

CREATE DATABASE [SourceDB]
GO
CREATE DATABASE [TargetDB1]
GO
CREATE DATABASE [TargetDB2]
GO


USE [SourceDB]
GO

CREATE PROCEDURE [dbo].[TestProc1]
AS
BEGIN
    SELECT 1
END
GO

CREATE PROCEDURE [dbo].[TestProc2]
AS
BEGIN
    SELECT 2
END
GO


USE [TargetDB1]
GO

CREATE ROLE [TestRole1]
GO

CREATE ROLE [TestRole2]
GO

CREATE TABLE [TestTable1] (
    [id] INT NOT NULL IDENTITY (1,1)
)
GO

CREATE TABLE [TestTable2] (
    [id] INT NOT NULL IDENTITY (1,1)
)
GO


USE [TargetDB2]
GO

CREATE ROLE [TestRole1]
GO

CREATE ROLE [TestRole2]
GO

CREATE TABLE [TestTable1] (
    [id] INT NOT NULL IDENTITY (1,1)
)
GO

CREATE TABLE [TestTable2] (
    [id] INT NOT NULL IDENTITY (1,1)
)
GO

-- =======================
-- ==== Begin Example ====
-- =======================

USE [Certificate_Administration]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    BEGIN TRANSACTION

    -- Display old certificates and permission requests
    SELECT * FROM [Permission].[Certificates]
    SELECT * FROM [Permission].[PermissionRequests]

    -- Clear out all old permissions and groups
    EXEC [Permission].[DeleteAllSourceGroups]
    EXEC [Permission].[RevokeAllObjects] 1

    DECLARE
          @src_db       SYSNAME = 'SourceDB'
        , @tar_db1      SYSNAME = 'TargetDB1'
        , @tar_db2      SYSNAME = 'TargetDB2'
        , @Group1       SYSNAME = 'Group1'
        , @dbo          SYSNAME = 'dbo'
        , @TestProc1    SYSNAME = 'TestProc1'
        , @TestProc2    SYSNAME = 'TestProc2'
        , @TestTable1   SYSNAME = 'TestTable1'
        , @TestTable2   SYSNAME = 'TestTable2'
        , @TestRole1    SYSNAME = 'TestRole1'
        , @TestRole2    SYSNAME = 'TestRole2'


    -- Request permissions

    -- ===================
    -- ===== Group 1 =====
    -- ===================

    -- Group TestProc1 and TestProc2
    EXEC [Permission].[AddSourceObjectToSourceGroupFromName] @src_db, @dbo, @TestProc1, @Group1
    EXEC [Permission].[AddSourceObjectToSourceGroupFromName] @src_db, @dbo, @TestProc2, @Group1
    
    -- Request permissions for the group
    EXEC [Permission].[AddGroupPermissionRequestFromName] @src_db, @Group1, @tar_db1, @dbo, @TestTable1, 'SELECT'
    EXEC [Permission].[AddGroupPermissionRequestFromName] @src_db, @Group1, @tar_db1, @dbo, @TestTable1, 'UPDATE'
    
    -- Request roles for the group
    EXEC [Permission].[AddGroupRoleRequestFromName] @src_db, @Group1, @tar_db1, @TestRole1
    EXEC [Permission].[AddGroupRoleRequestFromName] @src_db, @Group1, @tar_db2, @TestRole2

    -- =====================
    -- ===== TestProc1 =====
    -- =====================

    -- Request permissions for TestProc1
    EXEC [Permission].[AddObjectPermissionRequestFromName] @src_db, @dbo, @TestProc1, @tar_db2, @dbo, @TestTable1, 'ALTER'
    
    -- Request roles for TestProc1
    EXEC [Permission].[AddObjectRoleRequestFromName] @src_db, @dbo, @TestProc1, @tar_db1, @TestRole2


    -- =====================
    -- ===== TestProc2 =====
    -- =====================

    -- Request permissions for TestProc2
    EXEC [Permission].[AddObjectPermissionRequestFromName] @src_db, @dbo, @TestProc2, @tar_db2, @dbo, @TestTable2, 'INSERT'
    
    -- Request roles for TestProc2
    EXEC [Permission].[AddObjectRoleRequestFromName] @src_db, @dbo, @TestProc2, @tar_db2, @TestRole1


    -- ==========================
    -- ===== Grant Requests =====
    -- ==========================

    -- View certificates and requests before they're granted
    SELECT * FROM [Permission].[Certificates]
    SELECT * FROM [Permission].[PermissionRequests]

    -- Clear out items with no associated requests
    EXEC [Permission].[CleanOrphanedItems]

    -- Create certs and grant perms
    EXEC [Permission].[CreateAllCertificatesAndUsers]
    EXEC [Permission].[GrantAllSourceGroupRequests] 1
    EXEC [Permission].[GrantAllSourceObjectRequests] 1


    -- Display new certificates and permission requests
    SELECT * FROM [Permission].[Certificates]
    SELECT * FROM [Permission].[PermissionRequests]


    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    ; THROW
END CATCH
GO

-- =====================
-- ==== End Example ====
-- =====================


-- ==========================
-- ==== Clean Up Example ====
-- ==========================

-- Clear out all permissions and groups
EXEC [Permission].[DeleteAllSourceGroups]
EXEC [Permission].[RevokeAllObjects] 1
GO

USE master
GO

ALTER DATABASE [SourceDB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DROP DATABASE [SourceDB]
GO
ALTER DATABASE [TargetDB1] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DROP DATABASE [TargetDB1]
GO
ALTER DATABASE [TargetDB2] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DROP DATABASE [TargetDB2]
GO
