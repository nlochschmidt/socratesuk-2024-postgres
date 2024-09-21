CREATE TYPE test_result AS
(
	result TEXT,
	name   TEXT,
	hint   TEXT
);

CREATE OR REPLACE FUNCTION report_outcome(passed BOOLEAN, name TEXT, hint TEXT)
	RETURNS test_result
AS
$$
DECLARE
	test_result test_result;
BEGIN
	test_result.name := name;
	IF passed THEN
		test_result.result := '✅';
	ELSE
		test_result.result := '❌';
		test_result.hint := hint;
	END IF;
	RETURN test_result;
END
$$ language plpgsql;

-- Test Helpers
CREATE OR REPLACE FUNCTION it(actual JSONB, expect JSONB, test_name TEXT)
	RETURNS test_result
AS
$$
SELECT report_outcome(actual = expect, test_name,
					  'expected ' || expect::text || ' but was ' || actual::text);
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION it(actual NUMERIC, expect NUMERIC, test_name TEXT)
	RETURNS test_result
AS
$$
SELECT report_outcome(actual = expect, test_name,
					  'expected ' || expect::text || ' but was ' || actual::text);
$$ LANGUAGE sql;

--EXAMPLES
SELECT it(
       (SELECT 1), (SELECT 2), '1 is not equal to 2'
	   )
UNION ALL
SELECT it(
		   (SELECT 1), (SELECT 1), '1 is equal to 1'
	   )
UNION ALL
SELECT it(
		   (SELECT '{"name": "Hello"}'::jsonb),
		   (SELECT '{"name": "World"}'::jsonb),
		   'example test'
	   )
UNION ALL
SELECT it(
		   (SELECT '{"name": "Socrates"}'::jsonb),
		   (SELECT '{"name": "Socrates"}'::jsonb),
		   'example test 2');