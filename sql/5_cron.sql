SELECT cron.schedule('* * * * *', -- run every minute
$$
	DELETE FROM tasks WHERE team_id = 'team_sith';
$$);