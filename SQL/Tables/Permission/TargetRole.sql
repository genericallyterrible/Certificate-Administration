USE [Certificate_Administration]
GO

DROP TABLE IF EXISTS [Permission].[TargetRole]
GO

CREATE TABLE [Permission].[TargetRole] (
      [TargetRoleID]        INT NOT NULL    IDENTITY (1,1)
    , [TargetDatabaseID]    INT NOT NULL
    , [role_principal_id]   INT NOT NULL
    , CONSTRAINT [PK_TargetRole]
        PRIMARY KEY CLUSTERED (TargetRoleID)
    , CONSTRAINT [UQ_TargetRole_DatabaseObject]
        UNIQUE ([TargetDatabaseID], [role_principal_id])
    , CONSTRAINT [FK_TargetDatabase_TargetRole]
        FOREIGN KEY ([TargetDatabaseID])
        REFERENCES [Permission].[TargetDatabase] ([TargetDatabaseID])
        ON DELETE CASCADE
        ON UPDATE CASCADE
)
GO
