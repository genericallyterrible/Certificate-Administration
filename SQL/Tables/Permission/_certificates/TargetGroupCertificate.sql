USE [Certificate_Administration]
GO

DROP TABLE IF EXISTS [Permission].[TargetGroupCertificate]
GO

CREATE TABLE [Permission].[TargetGroupCertificate] (
      [SourceGroupCertificateID]    INT NOT NULL
    , [TargetDatabaseID]            INT NOT NULL
    , [certificate_id]              INT NOT NULL
    , CONSTRAINT [PK_TargetGroupCertificate]
        PRIMARY KEY CLUSTERED ([SourceGroupCertificateID], [TargetDatabaseID])
    , CONSTRAINT [UQ_TargetGroupCertificate_DatabaseCertificate]
        UNIQUE ([TargetDatabaseID], [certificate_id])
    , CONSTRAINT [FK_SourceGroupCertificate_TargetGroupCertificate]
        FOREIGN KEY ([SourceGroupCertificateID])
        REFERENCES [Permission].[SourceGroupCertificate] ([SourceGroupCertificateID])
        ON DELETE CASCADE
        ON UPDATE CASCADE
    , CONSTRAINT [FK_TargetDatabase_TargetGroupCertificate]
        FOREIGN KEY ([TargetDatabaseID])
        REFERENCES [Permission].[TargetDatabase] ([TargetDatabaseID])
        ON DELETE CASCADE
        ON UPDATE CASCADE
)
GO
