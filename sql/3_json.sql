SELECT * FROM tasks;


SELECT title, team_id, current_state FROM tasks;


SELECT jsonb_agg(tasks) FROM tasks;



SELECT jsonb_agg(jsonb_build_object(
	'id', team_id,
	'title', title,
	'current_state', current_state
)) FROM tasks;


SELECT jsonb_pretty(jsonb_agg(jsonb_build_object(
	'id', team_id,
	'title', title,
	'current_state', current_state
))) FROM tasks;


-- Get the assignees per task

SELECT *
FROM tasks, assigned_to, people
WHERE tasks.task_id = assigned_to.task_id
  AND people.people_id = assigned_to.people_id;



SELECT tasks.task_id, jsonb_agg(people)
FROM tasks, assigned_to, people
WHERE tasks.task_id = assigned_to.task_id
  AND people.people_id = assigned_to.people_id
GROUP BY tasks.task_id;


SELECT tasks.task_id,
		json_agg(
			jsonb_build_object(
				'id', people.people_id,
				'name', name
			)) assignees
 FROM tasks,
	  assigned_to,
	  people
 WHERE tasks.task_id = assigned_to.task_id
   AND people.people_id = assigned_to.people_id
 GROUP BY tasks.task_id;


WITH team_tasks AS (SELECT * FROM TASKS WHERE team_id = 'team_sith'),
	 assignees_by_task AS
		 (SELECT team_tasks.task_id,
				 json_agg(
					 jsonb_build_object(
						 'id', people.people_id,
						 'name', name
					 )) assignees
		  FROM team_tasks,
			   assigned_to,
			   people
		  WHERE team_tasks.task_id = assigned_to.task_id
			AND people.people_id = assigned_to.people_id
		  GROUP BY team_tasks.task_id)
SELECT jsonb_pretty(
		   jsonb_agg(
			   jsonb_build_object(
				   'id', task_id,
				   'title', title,
				   'current_state', current_state,
				   'created_at', created_at,
				   'assignees', assignees_by_task.assignees
			   )
		   )
	   )
FROM team_tasks NATURAL JOIN assignees_by_task;
