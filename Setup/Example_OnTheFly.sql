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

CREATE PROCEDURE [dbo].[TestProc3]
AS
BEGIN
    SELECT 3
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


-- =====================
-- ==== First batch ====
-- =====================

-- Group TestProc1 and TestProc2
EXEC [Permission].[AddSourceObjectToSourceGroupFromName] 'SourceDB', 'dbo', 'TestProc1', 'Group1'
EXEC [Permission].[AddSourceObjectToSourceGroupFromName] 'SourceDB', 'dbo', 'TestProc2', 'Group1'

-- Request permissions for the group
EXEC [Permission].[AddGroupPermissionRequestFromName] 'SourceDB', 'Group1', 'TargetDB1', 'dbo', 'TestTable1', 'SELECT'
EXEC [Permission].[AddGroupPermissionRequestFromName] 'SourceDB', 'Group1', 'TargetDB1', 'dbo', 'TestTable1', 'UPDATE'

-- Request roles for the group
EXEC [Permission].[AddGroupRoleRequestFromName] 'SourceDB', 'Group1', 'TargetDB1', 'TestRole1'
EXEC [Permission].[AddGroupRoleRequestFromName] 'SourceDB', 'Group1', 'TargetDB2', 'TestRole2'

-- Create certs and grant perms
EXEC [Permission].[CreateAllCertificatesAndUsers]
EXEC [Permission].[GrantAllSourceGroupRequests] 1
EXEC [Permission].[GrantAllSourceObjectRequests] 1

-- Display certificates and permission requests
SELECT * FROM [Permission].[Certificates]
SELECT * FROM [Permission].[PermissionRequests]
GO

-- ======================
-- ==== Second batch ====
-- ======================

-- Add TestProc3 to Group1
-- Objects added to a group that has already been granted requests will be immediately granted the same permissions as the group.
EXEC [Permission].[AddSourceObjectToSourceGroupFromName] 'SourceDB', 'dbo', 'TestProc3', 'Group1'

-- Display certificates and permission requests
SELECT * FROM [Permission].[Certificates]
SELECT * FROM [Permission].[PermissionRequests]
GO


-- =====================
-- ==== Third batch ====
-- =====================

-- Request permissions for TestProc1
EXEC [Permission].[AddObjectPermissionRequestFromName] 'SourceDB', 'dbo', 'TestProc1', 'TargetDB1', 'dbo', 'TestTable1', 'ALTER'

-- Request roles for TestProc1
EXEC [Permission].[AddObjectRoleRequestFromName] 'SourceDB', 'dbo', 'TestProc1', 'TargetDB2', 'TestRole2'

-- Create certs and grant perms
EXEC [Permission].[CreateAllCertificatesAndUsers]
EXEC [Permission].[GrantAllSourceGroupRequests] 1
EXEC [Permission].[GrantAllSourceObjectRequests] 1

-- Display certificates and permission requests
SELECT * FROM [Permission].[Certificates]
SELECT * FROM [Permission].[PermissionRequests]
GO


-- ======================
-- ==== Fourth batch ====
-- ======================

-- Delete a source group
DECLARE @group_id INT

EXEC [Permission].[SourceGroupIDFromName] 'SourceDB', 'Group1', @group_id OUTPUT
EXEC [Permission].[DeleteSourceGroupByID] @group_id

-- Display certificates and permission requests
SELECT * FROM [Permission].[Certificates]
SELECT * FROM [Permission].[PermissionRequests]
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
