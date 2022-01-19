USE [Certificate_Administration]
GO

DROP TABLE IF EXISTS [Permission].[GrantablePermission];
GO

CREATE TABLE [Permission].[GrantablePermission] (
      [GrantablePermissionID]   INT         NOT NULL    IDENTITY (1,1)
    , [Permission]              VARCHAR(50) NOT NULL    UNIQUE
    , CONSTRAINT [PK_GrantablePermission]
        PRIMARY KEY CLUSTERED ([GrantablePermissionID])
)
GO

INSERT INTO [Permission].[GrantablePermission]
VALUES
      ('ALTER')
    , ('CONTROL')
    , ('DELETE')
    , ('EXECUTE')
    , ('INSERT')
    , ('REFERENCES')
    , ('SELECT')
    , ('TAKE OWNERSHIP')
    , ('UPDATE')
    , ('VIEW CHANGE TRACKING')
    , ('VIEW DEFINITION')
    -- Currently includes all table and sp permissions
GO
