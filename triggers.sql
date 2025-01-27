-- 1
-- запуск процедуры на выписку чека по изменению статуса приёма на "Завершен" с учётом скидки
CREATE TRIGGER trgAfterUpdateReception
    ON Clinic.Reception
    AFTER UPDATE
    AS
BEGIN
    IF EXISTS (SELECT 1
               FROM inserted
                        JOIN deleted ON inserted.ReceptionID = deleted.ReceptionID
               WHERE inserted.Status = N'Завершен'
                 AND deleted.Status <> N'Завершен')
        BEGIN
            IF EXISTS (SELECT 1
                       FROM deleted
                       WHERE deleted.Status = N'Отменён')
                BEGIN
                    THROW 50002, 'You cannot change the status of a cancelled order', 16;
                END
            DECLARE ReceptionCursor CURSOR FOR
                SELECT inserted.ReceptionID
                FROM inserted
                         JOIN deleted ON inserted.ReceptionID = deleted.ReceptionID
                WHERE inserted.Status = N'Завершен'
                  AND deleted.Status <> N'Завершен'
                  AND deleted.Status <> N'Отменён';

            OPEN ReceptionCursor;

            DECLARE @ReceptionID INT;

            FETCH NEXT FROM ReceptionCursor
                INTO @ReceptionID;

            WHILE @@FETCH_STATUS = 0
                BEGIN
                    DECLARE @NewPaymentID INT;
                    BEGIN TRY
                        IF NOT EXISTS (SELECT 1
                                       FROM Clinic.PaymentDocuments pd
                                       WHERE pd.ReceptionID = @ReceptionID)
                            BEGIN
                                EXEC Clinic.CreatePaymentDocument @ReceptionID = @ReceptionID,
                                     @NewPaymentID = @NewPaymentID OUTPUT;
                            END
                    END TRY
                    BEGIN CATCH
                        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
                        PRINT @ErrorMessage;
                        THROW;
                    END CATCH

                    FETCH NEXT FROM ReceptionCursor
                        INTO @ReceptionID;
                END
            CLOSE ReceptionCursor;
            DEALLOCATE ReceptionCursor;
        END
END;
GO
-- DROP TRIGGER Clinic.trgAfterUpdateReception;

-- TEST 1
UPDATE Clinic.Reception
SET Status = N'Завершен'
WHERE ReceptionID IN (3, 4);


-- 2
-- при написании отзыва - проверка на то, что пациент действительно был у данного врача
CREATE TRIGGER trgAfterInsertUpdateFeedback
    ON Clinic.Feedback
    AFTER INSERT, UPDATE
    AS
BEGIN
    DECLARE FeedbackCursor CURSOR FOR
        SELECT inserted.PatientID, inserted.MedicalWorkerID
        FROM inserted;

    OPEN FeedbackCursor;

    DECLARE @PatientID INT;
    DECLARE @MedicalWorkerID INT;

    FETCH NEXT FROM FeedbackCursor
        INTO @PatientID, @MedicalWorkerID;

    WHILE @@FETCH_STATUS = 0
        BEGIN
            IF NOT (@MedicalWorkerID IN (SELECT MedicalWorkerID
                                         FROM Clinic.GetPatientVisitHistory(@PatientID)))
                BEGIN
                    THROW 50003, 'The patient cannot write a feedback for the doctor who has not been', 16;
                END

            FETCH NEXT FROM FeedbackCursor
                INTO @PatientID, @MedicalWorkerID;
        END
    CLOSE FeedbackCursor;
    DEALLOCATE FeedbackCursor;
END;
GO
-- DROP TRIGGER Clinic.trgAfterInsertUpdateFeedback;

-- TEST 2
INSERT INTO Clinic.Feedback(PatientID, MedicalWorkerID, Rating, Comment, FeedbackDate)
VALUES (1, 1, 4.7, 'Is a good doctor!)', GETDATE()),
       (2, 2, 3.2, 'Is not a very good day...', GETDATE());


-- 3
-- при создании записи - проверка на запись на одно и то же время к одному и тому же врачу + проверка даты, что запись не в прошлое
CREATE TRIGGER trgAfterInsertReception
    ON Clinic.Reception
    AFTER INSERT
    AS
BEGIN
    DECLARE ReceptionCursor CURSOR FOR
        SELECT inserted.PatientID, inserted.MedicalWorkerID, inserted.DateTime
        FROM inserted;

    OPEN ReceptionCursor;

    DECLARE @PatientID INT;
    DECLARE @MedicalWorkerID INT;
    DECLARE @DateTime DATETIME;

    FETCH NEXT FROM ReceptionCursor
        INTO @PatientID, @MedicalWorkerID, @DateTime;

    WHILE @@FETCH_STATUS = 0
        BEGIN
            IF @DateTime < GETDATE()
                BEGIN
                    THROW 50004, 'You cannot create a reception for the past tense', 16;
                END

            IF EXISTS (SELECT 1
                       FROM Clinic.Reception r
                       WHERE r.MedicalWorkerID = @MedicalWorkerID
                         AND r.DateTime = @DateTime
                         AND @PatientID <> r.PatientID)
                BEGIN
                    THROW 50005, 'You can''t make an appointment with the same doctor at the same time', 16;
                END

            FETCH NEXT FROM ReceptionCursor
                INTO @PatientID, @MedicalWorkerID, @DateTime;
        END
    CLOSE ReceptionCursor;
    DEALLOCATE ReceptionCursor;
END;
GO
-- DROP TRIGGER Clinic.trgAfterInsertReception;

-- TEST 3
-- 1)
INSERT INTO Clinic.Reception(MedicalWorkerID, ServiceTypeID, PatientID, DateTime, Status)
VALUES (4, 1, 8, DATEADD(DAY, 1, GETDATE()), N'Ожидается'),
       (4, 2, 9, DATEADD(DAY, 1, GETDATE()), N'Ожидается');
-- 2)
INSERT INTO Clinic.Reception(MedicalWorkerID, ServiceTypeID, PatientID, DateTime, Status)
VALUES (4, 1, 7, '2024-12-25 10:00:00', N'Ожидается');
INSERT INTO Clinic.Reception(MedicalWorkerID, ServiceTypeID, PatientID, DateTime, Status)
VALUES (4, 1, 8, '2024-12-25 10:00:00', N'Ожидается');
-- 3)
INSERT INTO Clinic.Reception(MedicalWorkerID, ServiceTypeID, PatientID, DateTime, Status)
VALUES (4, 1, 7, '2023-12-25 10:00:00', N'Ожидается');
