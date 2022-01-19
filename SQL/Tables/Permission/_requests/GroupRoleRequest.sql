USE [Certificate_Administration]
GO

DROP TABLE IF EXISTS [Permission].[GroupRoleRequest]
GO

CREATE TABLE [Permission].[GroupRoleRequest] (
      [SourceGroupID]   INT NOT NULL
    , [TargetRoleID]    INT NOT NULL
    , [Granted]         BIT NOT NULL    DEFAULT 0
    , CONSTRAINT [PK_GroupRoleRequest]
        PRIMARY KEY CLUSTERED (
              [SourceGroupID]
            , [TargetRoleID]
        )
    , CONSTRAINT [FK_SourceGroup_GroupRoleRequest]
        FOREIGN KEY ([SourceGroupID])
        REFERENCES [Permission].[SourceGroup] ([SourceGroupID])
        ON DELETE CASCADE
        ON UPDATE CASCADE
    , CONSTRAINT [FK_TargetRole_GroupRoleRequest]
        FOREIGN KEY ([TargetRoleID])
        REFERENCES [Permission].[TargetRole] ([TargetRoleID])
        ON DELETE CASCADE
        ON UPDATE CASCADE
)
GO
