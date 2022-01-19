USE [Certificate_Administration]
GO

DROP TABLE IF EXISTS [Permission].[GroupPermissionRequest]
GO

CREATE TABLE [Permission].[GroupPermissionRequest] (
      [SourceGroupID]           INT NOT NULL
    , [TargetObjectID]          INT NOT NULL
    , [GrantablePermissionID]   INT NOT NULL
    , [Granted]                 BIT NOT NULL    DEFAULT 0
    , CONSTRAINT [PK_GroupPermissionRequest]
        PRIMARY KEY CLUSTERED (
              [SourceGroupID]
            , [TargetObjectID]
            , [GrantablePermissionID]
        )
    , CONSTRAINT [FK_SourceGroup_GroupPermissionRequest]
        FOREIGN KEY ([SourceGroupID])
        REFERENCES [Permission].[SourceGroup] ([SourceGroupID])
        ON DELETE CASCADE
        ON UPDATE CASCADE
    , CONSTRAINT [FK_TargetObject_GroupPermissionRequest]
        FOREIGN KEY ([TargetObjectID])
        REFERENCES [Permission].[TargetObject] ([TargetObjectID])
        ON DELETE CASCADE
        ON UPDATE CASCADE
    , CONSTRAINT [FK_GrantablePermission_GroupPermissionRequest]
        FOREIGN KEY ([GrantablePermissionID])
        REFERENCES [Permission].[GrantablePermission] ([GrantablePermissionID])
        ON DELETE CASCADE
        ON UPDATE CASCADE
)
GO
