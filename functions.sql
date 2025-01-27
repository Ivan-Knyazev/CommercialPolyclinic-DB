-- 1
-- получение очереди по записям к какому-то конкретному врачу на сегодняшний день
-- через вызов представления "получение записей на приёмы на сегодняшний день"
CREATE FUNCTION Clinic.GetTodayQueueForDoctor(@MedicalWorkerID INT)
    RETURNS @QueueTable TABLE
                        (
                            PatientName       NVARCHAR(255),
                            PatientSurname    NVARCHAR(255),
                            NameOfService     NVARCHAR(255),
                            ReceptionDateTime DATETIME,
                            MedicalWorkerID   INT,
                            ReceptionStatus   NVARCHAR(50)
                        )
AS
BEGIN
    INSERT INTO @QueueTable
    SELECT tr.PatientName,
           tr.PatientSurname,
           tr.NameOfService,
           tr.ReceptionDateTime,
           tr.MedicalWorkerID,
           tr.ReceptionStatus
    FROM Clinic.TodayReceptions tr
    WHERE tr.MedicalWorkerID = @MedicalWorkerID
    ORDER BY tr.ReceptionDateTime;

    RETURN;
END;
GO
-- DROP FUNCTION Clinic.GetTodayQueueForDoctor;

-- TEST 1
SELECT *
FROM Clinic.GetTodayQueueForDoctor(1);
GO
SELECT *
FROM Clinic.GetTodayQueueForDoctor(2);
GO


-- 2
-- получение истории посещения врачей по определённому клиенту
CREATE FUNCTION Clinic.GetPatientVisitHistory (@PatientID INT)
RETURNS TABLE
AS
RETURN
(
    SELECT
        r.ReceptionID,
        r.DateTime AS ReceptionDateTime,
        r.Status AS ReceptionStatus,
        r.Result AS ReceptionResult,
        r.MedicalWorkerID,
        mw.Name AS MedicalWorkerName,
        st.NameOfService,
        st.Price,
        r.Result
    FROM
        Clinic.Reception r
    INNER JOIN
        Clinic.Patient p ON r.PatientID = p.PatientID
    INNER JOIN
        Clinic.MedicalWorker mw ON r.MedicalWorkerID = mw.MedicalWorkerID
    INNER JOIN
        Clinic.ServiceType st ON r.ServiceTypeID = st.ServiceTypeID
    WHERE
        p.PatientID = @PatientID AND r.Status = N'Завершен'
);
GO
-- DROP FUNCTION Clinic.GetPatientVisitHistory;

-- TEST 2
SELECT *
FROM Clinic.GetPatientVisitHistory(2)
ORDER BY ReceptionDateTime;
GO


-- 3
-- получение предстоящих записей к врачам по определённому клиенту
CREATE FUNCTION Clinic.GetUpcomingReceptionsForPatientByPatientID (@PatientID INT)
RETURNS TABLE
AS
RETURN
(
    SELECT
        r.ReceptionID,
        r.DateTime AS ReceptionDateTime,
        r.Status AS ReceptionStatus,
        mw.Name AS MedicalWorkerName,
        st.NameOfService,
        st.Price,
        r.Result
    FROM
        Clinic.Reception r
    INNER JOIN
        Clinic.Patient p ON r.PatientID = p.PatientID
    INNER JOIN
        Clinic.MedicalWorker mw ON r.MedicalWorkerID = mw.MedicalWorkerID
    INNER JOIN
        Clinic.ServiceType st ON r.ServiceTypeID = st.ServiceTypeID
    WHERE
        p.PatientID = @PatientID
        AND r.DateTime >= GETDATE()
);
GO

-- TEST 3
SELECT *
FROM Clinic.GetUpcomingReceptionsForPatientByPatientID(1);


-- 4
-- получение списка чеков по какому-то врачу
CREATE FUNCTION Clinic.GetReceptionsByMedicalWorker (@MedicalWorkerID INT)
RETURNS TABLE
AS
RETURN
(
    SELECT
        r.ReceptionID,
        r.DateTime AS ReceptionDateTime,
        r.Status AS ReceptionStatus,
        p.Name AS PatientName,
        p.Surname AS PatientSurname,
        st.NameOfService,
        st.Price,
        r.Result
    FROM
        Clinic.Reception r
    INNER JOIN
        Clinic.MedicalWorker mw ON r.MedicalWorkerID = mw.MedicalWorkerID
    INNER JOIN
        Clinic.Patient p ON r.PatientID = p.PatientID
    INNER JOIN
        Clinic.ServiceType st ON r.ServiceTypeID = st.ServiceTypeID
    INNER JOIN
        Clinic.PaymentDocuments pd ON r.ReceptionID = pd.ReceptionID
    WHERE
        mw.MedicalWorkerID = @MedicalWorkerID AND r.Status = N'Завершен' AND pd.PaymentStatus = N'Оплачено'
);
GO
-- DROP FUNCTION Clinic.GetReceptionsByMedicalWorker;

-- TEST 4
SELECT *
FROM Clinic.GetReceptionsByMedicalWorker(1);


-- 5
-- получение средней стоимости чека по всем типам услуг
CREATE FUNCTION Clinic.GetAverageReceptionAmount ()
RETURNS DECIMAL(12, 2)
AS
BEGIN
    DECLARE @AveragePrice DECIMAL(12, 2);

    SELECT @AveragePrice = AVG(Amount)
    FROM Clinic.PaymentDocuments pd
    WHERE pd.PaymentStatus = N'Оплачено';

    RETURN @AveragePrice;
END;
GO

-- TEST 5
SELECT Clinic.GetAverageReceptionAmount() AS AverageReceptionAmount;
