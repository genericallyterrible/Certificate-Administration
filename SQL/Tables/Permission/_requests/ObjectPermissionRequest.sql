USE [Certificate_Administration]
GO

DROP TABLE IF EXISTS [Permission].[ObjectPermissionRequest]
GO

CREATE TABLE [Permission].[ObjectPermissionRequest] (
      [SourceObjectID]          INT NOT NULL
    , [TargetObjectID]          INT NOT NULL
    , [GrantablePermissionID]   INT NOT NULL
    , [Granted]                 BIT NOT NULL    DEFAULT 0
    , CONSTRAINT [PK_ObjectPermissionRequest]
        PRIMARY KEY CLUSTERED (
              [SourceObjectID]
            , [TargetObjectID]
            , [GrantablePermissionID]
        )
    , CONSTRAINT [FK_SourceObject_ObjectPermissionRequest]
        FOREIGN KEY ([SourceObjectID])
        REFERENCES [Permission].[SourceObject] ([SourceObjectID])
        ON DELETE CASCADE
        ON UPDATE CASCADE
    , CONSTRAINT [FK_TargetObject_ObjectPermissionRequest]
        FOREIGN KEY ([TargetObjectID])
        REFERENCES [Permission].[TargetObject] ([TargetObjectID])
        ON DELETE CASCADE
        ON UPDATE CASCADE
    , CONSTRAINT [FK_GrantablePermission_ObjectPermissionRequest]
        FOREIGN KEY ([GrantablePermissionID])
        REFERENCES [Permission].[GrantablePermission] ([GrantablePermissionID])
        ON DELETE CASCADE
        ON UPDATE CASCADE
)
GO
