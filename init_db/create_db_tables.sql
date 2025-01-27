-- Проверка существования базы данных и удаление, если она уже есть
IF DB_ID('CommercialPolyclinic') IS NOT NULL
    BEGIN
        ALTER DATABASE CommercialPolyclinic SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
        DROP DATABASE CommercialPolyclinic;
    END;

-- Создание БД
CREATE DATABASE CommercialPolyclinic;
GO

-- Переключение на новую БД
USE CommercialPolyclinic;
GO

-- Создание схемы Clinic
CREATE SCHEMA Clinic;
GO

-- Создание таблицы Contacts
CREATE TABLE Clinic.Contacts
(
    ContactID        INT IDENTITY (1,1) PRIMARY KEY,
    Phone            NVARCHAR(20) UNIQUE NOT NULL,
    Email            NVARCHAR(100) UNIQUE,
    TelegramNickname NVARCHAR(100) UNIQUE,
    VKNickname       NVARCHAR(100) UNIQUE
);

-- Создание таблицы Patient
CREATE TABLE Clinic.Patient
(
    PatientID              INT IDENTITY (1,1) PRIMARY KEY,
    ContactID              INT           NOT NULL,
    Name                   NVARCHAR(255) NOT NULL,
    Surname                NVARCHAR(255) NOT NULL,
    Patronymic             NVARCHAR(255),
    BirthDate              DATE,
    Gender                 NVARCHAR(10),
    PassportDetails        NVARCHAR(255),
    Address                NVARCHAR(255),
    MedicalInsurancePolicy NVARCHAR(255),
    SNILS                  NVARCHAR(50),
    BloodGroup             NVARCHAR(50),
    CreatedAt              DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (ContactID) REFERENCES Clinic.Contacts (ContactID)
);

-- Создание таблицы LoyaltyProgram
CREATE TABLE Clinic.LoyaltyProgram
(
    ProgramID   INT IDENTITY (1,1) PRIMARY KEY,
    ProgramName NVARCHAR(255) NOT NULL,
    Description NVARCHAR(MAX),
    StartDate   DATE,
    EndDate     DATE,
    Discount    DECIMAL(5, 2)
);

-- Создание таблицы LoyaltyProgramParticipant
CREATE TABLE Clinic.LoyaltyProgramParticipant
(
    ParticipantID  INT IDENTITY (1,1) PRIMARY KEY,
    ProgramID      INT NOT NULL,
    PatientID      INT NOT NULL,
    EnrollmentDate DATE,
    Status         NVARCHAR(50),
    FOREIGN KEY (ProgramID) REFERENCES Clinic.LoyaltyProgram (ProgramID),
    FOREIGN KEY (PatientID) REFERENCES Clinic.Patient (PatientID)
);

-- Создание таблицы ServiceType
CREATE TABLE Clinic.ServiceType
(
    ServiceTypeID INT IDENTITY (1,1) PRIMARY KEY,
    NameOfService NVARCHAR(255) NOT NULL,
    Description   NVARCHAR(MAX),
    Price         DECIMAL(10, 2),
    Category      NVARCHAR(255)
);

-- Создание таблицы Specialities
CREATE TABLE Clinic.Specialities
(
    SpecialityID   INT IDENTITY (1,1) PRIMARY KEY,
    SpecialityName NVARCHAR(255) NOT NULL,
    Description    NVARCHAR(MAX)
);

-- Создание таблицы MedicalWorker
CREATE TABLE Clinic.MedicalWorker
(
    MedicalWorkerID       INT IDENTITY (1,1) PRIMARY KEY,
    SpecialityID          INT           NOT NULL,
    Name                  NVARCHAR(255) NOT NULL,
    JobTitle              NVARCHAR(255),
    QualificationCategory NVARCHAR(255),
    AcademicDegree        NVARCHAR(255),
    FOREIGN KEY (SpecialityID) REFERENCES Clinic.Specialities (SpecialityID)
);

-- Создание таблицы Reception
CREATE TABLE Clinic.Reception
(
    ReceptionID     INT IDENTITY (1,1) PRIMARY KEY,
    MedicalWorkerID INT NOT NULL,
    ServiceTypeID   INT NOT NULL,
    PatientID       INT NOT NULL,
    DateTime        DATETIME,
    Status          NVARCHAR(50),
    Result          NVARCHAR(MAX),
    CreatedAt       DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (MedicalWorkerID) REFERENCES Clinic.MedicalWorker (MedicalWorkerID),
    FOREIGN KEY (ServiceTypeID) REFERENCES Clinic.ServiceType (ServiceTypeID),
    FOREIGN KEY (PatientID) REFERENCES Clinic.Patient (PatientID)
);

-- Создание таблицы PaymentDocuments
CREATE TABLE Clinic.PaymentDocuments
(
    PaymentID       INT IDENTITY (1,1) PRIMARY KEY,
    MedicalWorkerID INT NOT NULL,
    ServiceTypeID   INT NOT NULL,
    PatientID       INT NOT NULL,
    ReceptionID     INT NOT NULL,
    PaymentDate     DATETIME,
    Amount          DECIMAL(10, 2),
    Category        NVARCHAR(255),
    PaymentStatus   NVARCHAR(50),
    FOREIGN KEY (MedicalWorkerID) REFERENCES Clinic.MedicalWorker (MedicalWorkerID),
    FOREIGN KEY (ServiceTypeID) REFERENCES Clinic.ServiceType (ServiceTypeID),
    FOREIGN KEY (PatientID) REFERENCES Clinic.Patient (PatientID),
    FOREIGN KEY (ReceptionID) REFERENCES Clinic.Reception (ReceptionID)
);

-- Создание таблицы Feedback
CREATE TABLE Clinic.Feedback
(
    FeedbackID      INT IDENTITY (1,1) PRIMARY KEY,
    PatientID       INT NOT NULL,
    MedicalWorkerID INT NOT NULL,
    Rating          INT,
    Comment         NVARCHAR(MAX),
    FeedbackDate    DATETIME,
    FOREIGN KEY (PatientID) REFERENCES Clinic.Patient (PatientID),
    FOREIGN KEY (MedicalWorkerID) REFERENCES Clinic.MedicalWorker (MedicalWorkerID)
);


-- Проверка наличия новой БД
USE master;
GO
SELECT name, database_id, create_date
FROM sys.databases
WHERE name = 'CommercialPolyclinic';
GO
