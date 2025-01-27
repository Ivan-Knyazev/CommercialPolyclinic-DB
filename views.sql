-- 1
-- Получение полной информации по пациенту
CREATE VIEW Clinic.PatientFullInfo AS
SELECT p.PatientID,
       p.Name,
       p.Surname,
       p.Patronymic,
       p.BirthDate,
       p.Gender,
       p.PassportDetails,
       p.Address,
       p.MedicalInsurancePolicy,
       p.SNILS,
       p.BloodGroup,
       p.CreatedAt    AS PatientCreatedAt,
       c.ContactID,
       c.Phone,
       c.Email,
       c.TelegramNickname,
       c.VKNickname,
       lp.ProgramID,
       lp.ProgramName,
       lp.Description AS LoyaltyProgramDescription,
       lp.StartDate   AS LoyaltyProgramStartDate,
       lp.EndDate     AS LoyaltyProgramEndDate,
       lp.Discount,
       lpp.EnrollmentDate,
       lpp.Status     AS LoyaltyProgramStatus
FROM Clinic.Patient p
         INNER JOIN
     Clinic.Contacts c ON p.ContactID = c.ContactID
         LEFT JOIN
     Clinic.LoyaltyProgramParticipant lpp ON p.PatientID = lpp.PatientID
         LEFT JOIN
     Clinic.LoyaltyProgram lp ON lpp.ProgramID = lp.ProgramID;
GO
-- DROP VIEW Clinic.PatientFullInfo

-- TEST 1
SELECT *
FROM Clinic.PatientFullInfo;
GO


-- 2
-- Получение полной информации о приёмах с указанием стоимости, результата, информации о враче и типе услуги
CREATE VIEW Clinic.ReceptionFullInfo AS
SELECT r.ReceptionID,
       r.DateTime               AS ReceptionDateTime,
       r.Status                 AS ReceptionStatus,
       r.Result                 AS ReceptionResult,
       r.CreatedAt              AS ReceptionCreatedAt,
       mw.MedicalWorkerID,
       mw.Name                  AS MedicalWorkerName,
       mw.JobTitle              AS MedicalWorkerJobTitle,
       mw.QualificationCategory AS MedicalWorkerQualificationCategory,
       mw.AcademicDegree        AS MedicalWorkerAcademicDegree,
       s.SpecialityID,
       s.SpecialityName,
       st.ServiceTypeID,
       st.NameOfService,
       st.Description           AS ServiceTypeDescription,
       st.Price,
       p.PatientID,
       p.Name                   AS PatientName,
       p.Surname                AS PatientSurname,
       pd.PaymentID,
       pd.PaymentDate,
       pd.Amount,
       pd.Category              as PaymentCategory,
       pd.PaymentStatus
FROM Clinic.Reception r
         INNER JOIN
     Clinic.MedicalWorker mw ON r.MedicalWorkerID = mw.MedicalWorkerID
         INNER JOIN
     Clinic.Specialities s ON mw.SpecialityID = s.SpecialityID
         INNER JOIN
     Clinic.ServiceType st ON r.ServiceTypeID = st.ServiceTypeID
         INNER JOIN
     Clinic.Patient p ON r.PatientID = p.PatientID
         LEFT JOIN
     Clinic.PaymentDocuments pd ON r.ReceptionID = pd.ReceptionID;
GO
-- DROP VIEW Clinic.ReceptionFullInfo

-- TEST 2
SELECT *
FROM Clinic.ReceptionFullInfo;
GO


-- 3
-- получение всех записей на приёмы на сегодняшний день
CREATE VIEW Clinic.TodayReceptions AS
SELECT r.ReceptionID,
       r.DateTime AS ReceptionDateTime,
       r.Status   AS ReceptionStatus,
       r.Result   AS ReceptionResult,
       mw.MedicalWorkerID,
       mw.Name    AS MedicalWorkerName,
       s.SpecialityName,
       st.NameOfService,
       p.Name     AS PatientName,
       p.Surname  AS PatientSurname
FROM Clinic.Reception r
         INNER JOIN
     Clinic.MedicalWorker mw ON r.MedicalWorkerID = mw.MedicalWorkerID
         INNER JOIN
     Clinic.Specialities s ON mw.SpecialityID = s.SpecialityID
         INNER JOIN
     Clinic.ServiceType st ON r.ServiceTypeID = st.ServiceTypeID
         INNER JOIN
     Clinic.Patient p ON r.PatientID = p.PatientID
WHERE CAST(r.DateTime AS DATE) = CAST(GETDATE() AS DATE);
GO
-- DROP VIEW Clinic.TodayReceptions;

-- TEST 3
SELECT *
FROM Clinic.TodayReceptions;
GO


-- 4
-- получение среднего рейтинга на основе отзывов по всем врачам (для пользователей и аналитики)
CREATE VIEW Clinic.MedicalWorkerAverageRating AS
SELECT mw.MedicalWorkerID,
       mw.Name                                         AS MedicalWorkerName,
       ISNULL(AVG(CAST(r.Rating AS DECIMAL(3, 2))), 0) AS AverageRating,
       COUNT(r.FeedbackID)                             AS NumberOfReviews
FROM Clinic.MedicalWorker mw
         LEFT JOIN
     Clinic.Feedback r ON mw.MedicalWorkerID = r.MedicalWorkerID
GROUP BY mw.MedicalWorkerID, mw.Name;
GO

-- TEST 4
SELECT *
FROM Clinic.MedicalWorkerAverageRating;
GO
