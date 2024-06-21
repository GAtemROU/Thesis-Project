SELECT fileName, listNumber, assignmentId, hitId, workerId, origin, timestamp, partId, questionId, answer::TEXT, (data->>'itemid') as itemid, (data->>'itemType') as itemType, (data->>'msg') as msg, (data->>'img1') as img1, (data->>'img2') as img2, (data->>'img3') as img3, id FROM (
	(SELECT * FROM Results WHERE experimentType='RefGameShapesGazeFeedbackExperiment') as tmp1
	LEFT OUTER JOIN Questions USING (QuestionId)
	LEFT OUTER JOIN Groups USING (PartId)
) as tmp
WHERE LingoExpModelId = 1661
ORDER BY partId, questionId, workerId