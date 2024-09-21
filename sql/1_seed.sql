CREATE TABLE teams
(
	team_id    TEXT PRIMARY KEY,
	name       TEXT CHECK ( length(name) <= 250),
	created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE people
(
	people_id TEXT PRIMARY KEY,
	name      TEXT CHECK ( length(name) <= 250)
);

CREATE TABLE tasks
(
	task_id       INTEGER PRIMARY KEY,
	team_id       TEXT REFERENCES teams (team_id),
	title         TEXT      NOT NULL  CHECK ( length(title) <= 1000),
	current_state TEXT      NOT NULL,
	created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE assigned_to
(
	people_id TEXT REFERENCES people (people_id) ON DELETE CASCADE,
	task_id   INTEGER REFERENCES tasks (task_id) ON DELETE CASCADE,
	PRIMARY KEY (people_id, task_id)
);

CREATE TABLE member_of
(
	people_id TEXT REFERENCES people (people_id) ON DELETE CASCADE,
	team_id   TEXT REFERENCES teams (team_id) ON DELETE CASCADE,
	PRIMARY KEY (people_id, team_id)
);

INSERT INTO teams (team_id, name)
VALUES ('team_jedi', 'Jedi Knights'),
	   ('team_sith', 'Sith Lords');

INSERT INTO people (people_id, name)
VALUES ('luke', 'Luke Skywalker'),
	   ('joda', 'Master Joda'),
	   ('vader', 'Darth Vader'),
	   ('palpatine', 'Emperor Palpatine');

INSERT INTO member_of (people_id, team_id)
VALUES ('luke', 'team_jedi'),
	   ('joda', 'team_jedi'),
	   ('vader', 'team_sith'),
	   ('palpatine', 'team_sith');

INSERT INTO tasks (task_id, team_id, current_state, title)
VALUES (1, 'team_sith', 'DONE', 'Build death star'),
	   (2, 'team_jedi', 'IN_PROGRESS', 'Find Master Joda'),
	   (3, 'team_sith', 'IN_PROGRESS', 'Terrorize the Galactic');

INSERT INTO assigned_to(people_id, task_id)
VALUES ('vader', 1), -- Vader has built the death star
	   ('joda', 2),  -- Luke is finding Joda
	   ('vader', 3), -- Vader is terrorizing the galactic
	   ('palpatine', 3); -- Palpatine is terrorizing the galactic
