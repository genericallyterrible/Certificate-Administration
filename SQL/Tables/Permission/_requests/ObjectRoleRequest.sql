USE [Certificate_Administration]
GO

DROP TABLE IF EXISTS [Permission].[ObjectRoleRequest]
GO

CREATE TABLE [Permission].[ObjectRoleRequest] (
      [SourceObjectID]  INT NOT NULL
    , [TargetRoleID]    INT NOT NULL
    , [Granted]         BIT NOT NULL    DEFAULT 0
    , CONSTRAINT [PK_ObjectRoleRequest]
        PRIMARY KEY CLUSTERED (
              [SourceObjectID]
            , [TargetRoleID]
        )
    , CONSTRAINT [FK_SourceObject_ObjectRoleRequest]
        FOREIGN KEY ([SourceObjectID])
        REFERENCES [Permission].[SourceObject] ([SourceObjectID])
        ON DELETE CASCADE
        ON UPDATE CASCADE
    , CONSTRAINT [FK_TargetRole_ObjectRoleRequest]
        FOREIGN KEY ([TargetRoleID])
        REFERENCES [Permission].[TargetRole] ([TargetRoleID])
        ON DELETE CASCADE
        ON UPDATE CASCADE
)
GO
