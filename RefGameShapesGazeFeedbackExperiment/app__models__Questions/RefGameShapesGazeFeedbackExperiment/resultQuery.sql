SELECT fileName, listNumber, assignmentId, hitId, workerId, origin, timestamp, partId, questionId, answer::TEXT, (data->>'trialid') as trialid, (data->>'type') as type, (data->>'sentmsg') as sentmsg, (data->>'trgt') as trgt, (data->>'comp') as comp, (data->>'dist') as dist, (data->>'msg1') as msg1, (data->>'msg2') as msg2, (data->>'msg3') as msg3, (data->>'msg4') as msg4, id FROM (
	(SELECT * FROM Results WHERE experimentType='RefGameShapesGazeFeedbackExperiment') as tmp1
	LEFT OUTER JOIN Questions USING (QuestionId)
	LEFT OUTER JOIN Groups USING (PartId)
) as tmp
WHERE LingoExpModelId = 141
ORDER BY partId, questionId, workerId