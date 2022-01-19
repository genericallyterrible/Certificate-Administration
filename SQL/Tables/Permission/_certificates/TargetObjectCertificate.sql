USE [Certificate_Administration]
GO

DROP TABLE IF EXISTS [Permission].[TargetObjectCertificate]
GO

CREATE TABLE [Permission].[TargetObjectCertificate] (
      [SourceObjectCertificateID]   INT NOT NULL
    , [TargetDatabaseID]            INT NOT NULL
    , [certificate_id]              INT NOT NULL
    , CONSTRAINT [PK_TargetObjectCertificate]
        PRIMARY KEY CLUSTERED ([SourceObjectCertificateID], [TargetDatabaseID])
    , CONSTRAINT [UQ_TargetObjectCertificate_DatabaseCertificate]
        UNIQUE ([TargetDatabaseID], [certificate_id])
    , CONSTRAINT [FK_SourceObjectCertificate_TargetObjectCertificate]
        FOREIGN KEY ([SourceObjectCertificateID])
        REFERENCES [Permission].[SourceObjectCertificate] ([SourceObjectCertificateID])
        ON DELETE CASCADE
        ON UPDATE CASCADE
    , CONSTRAINT [FK_TargetDatabase_TargetObjectCertificate]
        FOREIGN KEY ([TargetDatabaseID])
        REFERENCES [Permission].[TargetDatabase] ([TargetDatabaseID])
        ON DELETE CASCADE
        ON UPDATE CASCADE
)
GO
