-- 1
-- добавление нового пациента с обработкой контактных данных
CREATE PROCEDURE Clinic.AddNewPatient @Phone NVARCHAR(20),
                                      @Email NVARCHAR(100),
                                      @TelegramNickname NVARCHAR(100),
                                      @VKNickname NVARCHAR(100),
                                      @Name NVARCHAR(255),
                                      @Surname NVARCHAR(255),
                                      @Patronymic NVARCHAR(255),
                                      @BirthDate DATE,
                                      @Gender NVARCHAR(10),
                                      @PassportDetails NVARCHAR(255),
                                      @Address NVARCHAR(255),
                                      @MedicalInsurancePolicy NVARCHAR(255),
                                      @SNILS NVARCHAR(50),
                                      @BloodGroup NVARCHAR(50),
                                      @NewPatientID INT OUTPUT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Clinic.Contacts (Phone, Email, TelegramNickname, VKNickname)
        VALUES (@Phone, @Email, @TelegramNickname, @VKNickname);

        DECLARE @ContactID INT = SCOPE_IDENTITY();

        INSERT INTO Clinic.Patient (ContactID, Name, Surname, Patronymic, BirthDate, Gender, PassportDetails, Address,
                                    MedicalInsurancePolicy, SNILS, BloodGroup)
        VALUES (@ContactID, @Name, @Surname, @Patronymic, @BirthDate, @Gender, @PassportDetails,
                @Address, @MedicalInsurancePolicy, @SNILS, @BloodGroup);

        SET @NewPatientID = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT @ErrorMessage;
        THROW;
    END CATCH
END;
GO
-- DROP PROCEDURE Clinic.AddNewPatient;

-- TEST 1
DECLARE @NewPatientID INT;
EXEC Clinic.AddNewPatient
     @Phone = N'+79123456789',
     @Email = N'test@example.com',
     @TelegramNickname = N'test_telegram',
     @VKNickname = N'test_vk',
     @Name = N'Иван',
     @Surname = N'Иванов',
     @Patronymic = N'Иванович',
     @BirthDate = '1990-01-01',
     @Gender = N'Мужской',
     @PassportDetails = N'1234 567890',
     @Address = N'г. Москва, ул. Ленина, д. 1',
     @MedicalInsurancePolicy = N'1234567890123456',
     @SNILS = N'123-456-789 01',
     @BloodGroup = N'O(I)',
     @NewPatientID = @NewPatientID OUTPUT;

PRINT N'ID нового пациента: ' + CAST(@NewPatientID AS VARCHAR(10));

SELECT *
FROM Clinic.Patient p
         INNER JOIN Clinic.Contacts c ON p.ContactID = c.ContactID
WHERE PatientID = @NewPatientID;


-- 2
-- выписка чека по какому-то приёму с учётом скидки
CREATE PROCEDURE Clinic.CreatePaymentDocument @ReceptionID INT, @NewPaymentID INT OUTPUT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @MedicalWorkerID INT,
            @ServiceTypeID INT,
            @PatientID INT
        SELECT @MedicalWorkerID = r.MedicalWorkerID,
               @ServiceTypeID = r.ServiceTypeID,
               @PatientID = r.PatientID
        FROM Clinic.Reception as r
        WHERE ReceptionID = @ReceptionID;

        IF @@ROWCOUNT = 0
            BEGIN
                THROW 50001, N'Прием с указанным ID не найден.', 16;
            END

        DECLARE @ServicePrice DECIMAL(10, 2);
        SELECT @ServicePrice = Price
        FROM Clinic.ServiceType
        WHERE ServiceTypeID = @ServiceTypeID;

        DECLARE @Discount DECIMAL(5, 2)
        SELECT @Discount = lp.Discount
        FROM Clinic.LoyaltyProgramParticipant lpp
                 JOIN Clinic.LoyaltyProgram lp ON lpp.ProgramID = lp.ProgramID
        WHERE lpp.PatientID = @PatientID
          AND lp.StartDate <= GETDATE()
          AND (lp.EndDate IS NULL OR lp.EndDate >= GETDATE())
          AND lpp.Status = N'Активен';

        DECLARE @Amount DECIMAL(10, 2)
        IF @Discount IS NULL
            BEGIN
                PRINT N'Для пациента с ID ' + CAST(@PatientID AS VARCHAR(10)) + N' активная скидка не найдена.';
                SET @Amount = @ServicePrice;
            END
        ELSE
            BEGIN
                PRINT N'Скидка для пациента с ID ' + CAST(@PatientID AS VARCHAR(10)) + N': ' +
                      CAST(@Discount AS VARCHAR(10));
                SET @Amount = @ServicePrice * (100 - @Discount) * 0.01;
            END

        INSERT INTO Clinic.PaymentDocuments (MedicalWorkerID, ServiceTypeID, PatientID, ReceptionID, PaymentDate,
                                             Amount, Category, PaymentStatus)
        VALUES (@MedicalWorkerID, @ServiceTypeID, @PatientID, @ReceptionID, GETDATE(), @Amount, N'Медицинские услуги',
                N'Ожидает оплаты');

        COMMIT TRANSACTION;

        SET @NewPaymentID = SCOPE_IDENTITY();

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT @ErrorMessage;
        THROW;
    END CATCH
END;
GO
-- DROP PROCEDURE Clinic.CreatePaymentDocument;

-- TEST 2
INSERT INTO Clinic.Reception (MedicalWorkerID, ServiceTypeID, PatientID, DateTime, Status, Result)
VALUES (1, 1, 1, GETDATE(), N'Завершен', N'Все хорошо');
-- PatientID = 11 без скидки

DECLARE @ReceptionID INT = SCOPE_IDENTITY();
DECLARE @NewPaymentID INT;
EXEC Clinic.CreatePaymentDocument @ReceptionID, @NewPaymentID = @NewPaymentID OUTPUT;

PRINT N'ID созданного платежа: ' + CAST(@NewPaymentID AS VARCHAR(10));
SELECT * FROM Clinic.PaymentDocuments WHERE PaymentID = @NewPaymentID;


-- 3
-- обновление статуса приёма в конце дня (установка статуса "отменён" для тех, кто не пришёл)
CREATE PROCEDURE Clinic.CancelUnattendedReceptions @CancelledReceptions INT OUTPUT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE Clinic.Reception
        SET Status = N'Отменён'
        WHERE DateTime < GETDATE() AND Status <> N'Завершен' AND Status <> N'Отменён';

        SET @CancelledReceptions = @@ROWCOUNT;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT @ErrorMessage;
        THROW;
    END CATCH
END;
GO
-- DROP PROCEDURE Clinic.CancelUnattendedReceptions;

-- TEST 3
INSERT INTO Clinic.Reception (MedicalWorkerID, ServiceTypeID, PatientID, DateTime, Status, Result)
VALUES (1, 1, 1, DATEADD(hour, -1, GETDATE()), N'Ожидается', N''),
       (1, 2, 2, DATEADD(minute, -30, GETDATE()), N'Ожидается', N'')

DECLARE @CancelledReceptions INT;
EXEC Clinic.CancelUnattendedReceptions @CancelledReceptions = @CancelledReceptions OUTPUT;

PRINT N'Количество отмененных приемов: ' + CAST(@CancelledReceptions AS VARCHAR(10));
SELECT * FROM Clinic.Reception WHERE Status = N'Отменён';


-- 4
-- обновление статуса участия в программе лояльности на "неактивен", если вышел срок действия программы
CREATE PROCEDURE Clinic.DeactivateExpiredLoyaltyProgramParticipants @DeactivatedParticipants INT OUTPUT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE lpp
        SET lpp.Status = N'Неактивен'
        FROM Clinic.LoyaltyProgramParticipant lpp
        JOIN Clinic.LoyaltyProgram lp ON lpp.ProgramID = lp.ProgramID
        WHERE (lp.EndDate IS NOT NULL) AND (lp.EndDate < GETDATE())
          AND (lpp.Status = N'Активен');

        SET @DeactivatedParticipants = @@ROWCOUNT;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        PRINT @ErrorMessage;
        THROW;
    END CATCH
END;
GO
-- DROP PROCEDURE Clinic.DeactivateExpiredLoyaltyProgramParticipants;

-- TEST 4
INSERT INTO Clinic.LoyaltyProgram (ProgramName, StartDate, EndDate, Discount)
VALUES (N'Летняя акция', '2023-06-01', '2023-08-31', 0.10)

DECLARE @ProgramID int = SCOPE_IDENTITY();

INSERT INTO Clinic.LoyaltyProgramParticipant (PatientID, ProgramID, EnrollmentDate, Status)
VALUES (1, @ProgramID, '2023-06-15', N'Активен')

DECLARE @DeactivatedParticipants INT;
EXEC Clinic.DeactivateExpiredLoyaltyProgramParticipants @DeactivatedParticipants OUTPUT;

PRINT N'Количество деактивированных участников: ' + CAST(@DeactivatedParticipants AS VARCHAR(10));
SELECT * FROM Clinic.LoyaltyProgramParticipant WHERE Status = N'Неактивен';
