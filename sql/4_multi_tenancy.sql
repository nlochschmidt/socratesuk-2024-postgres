-- Multi tenancy database

CREATE OR REPLACE FUNCTION set_tenant_id()
	RETURNS TRIGGER AS $$
DECLARE
	tenant_id text;
BEGIN
	IF current_user = 'tenant' THEN
		tenant_id := current_setting('app.current_tenant');
		IF tenant_id = '' THEN
			RAISE EXCEPTION 'MultiTenancy Parameter ''app.current_tenant'' is empty, but required for % into ''%.%''',
				TG_OP, TG_TABLE_SCHEMA, TG_TABLE_NAME;
		END IF;
		NEW."tenant_id" := tenant_id;
	END IF;
	RETURN NEW;
END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION enable_multitenancy(table_name regclass) RETURNS VOID
AS
$$
BEGIN
	-- Enable row-level security for the tenants table
	EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', table_name);
	EXECUTE format('GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE %I TO tenant', table_name);

	--Create the row-level security policy for tenant isolation
	EXECUTE format(
		'CREATE POLICY tenant_isolation_policy
			ON %I
			USING (tenant_id = current_setting(''app.current_tenant''))', table_name);

	EXECUTE format (
		'CREATE TRIGGER trigger_set_tenant_id_on_insert_or_update BEFORE INSERT OR UPDATE ON %I FOR EACH ROW EXECUTE PROCEDURE set_tenant_id()',
					table_name);
END
$$ LANGUAGE plpgsql;





CREATE TABLE tenants
(
	tenant_id TEXT PRIMARY KEY,
	name      TEXT NOT NULL
);

CREATE ROLE tenant;






GRANT SELECT, UPDATE ON tenants TO tenant;
SELECT enable_multitenancy('tenants');


ALTER TABLE tasks
	ADD COLUMN tenant_id TEXT REFERENCES tenants (tenant_id);
SELECT enable_multitenancy('tasks');

ALTER TABLE people
	ADD COLUMN tenant_id TEXT REFERENCES tenants (tenant_id);
SELECT enable_multitenancy('people');

ALTER TABLE teams
	ADD COLUMN tenant_id TEXT REFERENCES tenants (tenant_id);
SELECT enable_multitenancy('teams');

ALTER TABLE assigned_to
	ADD COLUMN tenant_id TEXT REFERENCES tenants (tenant_id);
SELECT enable_multitenancy('assigned_to');

ALTER TABLE member_of
    ADD COLUMN tenant_id TEXT REFERENCES tenants (tenant_id);
SELECT enable_multitenancy('member_of');


INSERT INTO tenants (tenant_id, name)
VALUES ('jedi_order', 'Order of the Jedi'),
	   ('empire', 'Galactic Empire');

SELECT it(
		   (SELECT jsonb_agg(jsonb_build_object('title', title)) FROM tasks),
		   ('[{"title": "Build death star"}, {"title": "Find Master Joda"}, {"title": "Terrorize the Galactic"}]'::jsonb),
		   'returns all tasks'
	   );

SET ROLE tenant;
SET app.current_tenant TO 'team_jedi';
SELECT it(
		   (SELECT jsonb_agg(jsonb_build_object('title', title)) FROM tasks),
		   ('[{"name": "Find Master Joda"}]'::jsonb),
		   'returns only the Jedi tasks'
	   );

RESET ROLE;









CREATE FUNCTION assignTeamRecursively(team_param TEXT, tenant_param TEXT) RETURNS RECORD
AS $$
WITH updated_team AS (
	UPDATE teams
		SET tenant_id = tenant_param
		WHERE team_id = team_param
		RETURNING teams.team_id, tenant_id
), updated_member_of AS (
	UPDATE member_of
		SET tenant_id = updated_team.tenant_id
		FROM updated_team
		WHERE member_of.team_id = updated_team.team_id
		RETURNING  member_of.people_id, updated_team.tenant_id
), updated_people AS (
	UPDATE people
		SET tenant_id = updated_member_of.tenant_id
		FROM updated_member_of
		WHERE people.people_id = updated_member_of.people_id
		RETURNING people.people_id, updated_member_of.tenant_id
), updated_tasks AS (UPDATE tasks
	SET tenant_id = updated_team.tenant_id
	FROM updated_team
	WHERE tasks.team_id = updated_team.team_id
	RETURNING tasks.task_id, updated_team.tenant_id
), updated_assigned_to AS (
	UPDATE assigned_to
		SET tenant_id = updated_tasks.tenant_id
		FROM updated_tasks
		WHERE assigned_to.task_id = updated_tasks.task_id)
SELECT
	(SELECT COUNT(*) FROM updated_team) team_count,
	(SELECT COUNT(*) FROM updated_people) people_count,
	(SELECT COUNT(*) FROM updated_tasks) task_count;
$$ language sql;





SELECT assignTeamRecursively('team_jedi', 'jedi_order');
SELECT assignTeamRecursively('team_sith', 'empire');








SET ROLE tenant;
SET app.current_tenant TO 'jedi_order';
SELECT it(
   (SELECT jsonb_agg(jsonb_build_object('title', title)) FROM tasks),
   ('[{"title": "Find Master Joda"}]'::jsonb),
   'returns only the Jedi tasks'
);




SET ROLE tenant;
SET app.current_tenant TO 'jedi_order';

INSERT INTO tasks (task_id, team_id, title, current_state)
VALUES (4, 'team_sith', 'Sabotage the Empire', 'TODO');

-- Important: delete task 4
RESET ROLE;
CREATE OR REPLACE FUNCTION check_team_exists()
	RETURNS TRIGGER AS $$
BEGIN
	IF NOT EXISTS (SELECT 1 FROM teams WHERE team_id = NEW.team_id) THEN
		RAISE EXCEPTION 'Team with id % does not exist', NEW.team_id;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER team_exists_trigger
	BEFORE INSERT OR UPDATE ON tasks
	FOR EACH ROW
EXECUTE FUNCTION check_team_exists();



SET ROLE tenant;
SET app.current_tenant TO 'jedi_order';
INSERT INTO tasks (task_id, team_id, title, current_state)
VALUES (4, 'team_sith', 'Sabotage the Empire', 'TODO');


INSERT INTO tasks (task_id, team_id, title, current_state, tenant_id)
VALUES (4, 'team_sith', 'Sabotage the Empire', 'TODO', 'empire');


INSERT INTO tasks (task_id, team_id, title, current_state, tenant_id)
VALUES (4, 'team_jedi', 'Sabotage the Empire', 'TODO', 'empire');

SET ROLE tenant;
SET app.current_tenant TO 'jedi_order';
SELECT it(
		   (SELECT jsonb_agg(jsonb_build_object('title', title)) FROM tasks),
		   ('[{"title": "Find Master Joda"}, {"title": "Sabotage the Empire"}]'::jsonb),
		   'returns only the Jedi tasks'
	   );

SET app.current_tenant TO 'empire';
SELECT it(
   (SELECT jsonb_agg(jsonb_build_object('title', title)) FROM tasks),
   ('[{"title": "Build death star"}, {"title": "Terrorize the Galactic"}]'::jsonb),
   'returns only the Empire tasks'
);
RESET ROLE;



