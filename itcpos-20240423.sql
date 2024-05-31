--
-- PostgreSQL database dump
--

-- Dumped from database version 15.5 (Homebrew)
-- Dumped by pg_dump version 16.0

-- Started on 2024-04-23 15:10:45 +07

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 361 (class 1255 OID 17439)
-- Name: change_all_column_types(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.change_all_column_types() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    table_record RECORD;
    column_record RECORD;
BEGIN
    FOR table_record IN (SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name like 'tbl%' AND table_type = 'BASE TABLE')
    LOOP
        FOR column_record IN (SELECT column_name FROM information_schema.columns WHERE table_name = table_record.table_name AND data_type like 'character%')
        LOOP
            EXECUTE format('ALTER TABLE %I ALTER COLUMN %I TYPE text', table_record.table_name, column_record.column_name);
        END LOOP;
    END LOOP;
END;
$$;


ALTER FUNCTION public.change_all_column_types() OWNER TO postgres;

--
-- TOC entry 400 (class 1255 OID 27814)
-- Name: fn_currency_dml(integer, text, text, text, integer, text, integer, integer, text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_currency_dml(OUT "Stat" integer, p_id integer DEFAULT NULL::integer, p_computerip text DEFAULT NULL::text, p_currency text DEFAULT NULL::text, p_symbol text DEFAULT NULL::text, p_flag integer DEFAULT 1, p_note text DEFAULT NULL::text, p_locationid integer DEFAULT NULL::integer, p_userlocation integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_action text DEFAULT NULL::text, p_role integer DEFAULT 0) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
	
    IF COALESCE(p_computerip,'') = '' OR COALESCE(p_action, '') = '' THEN
        "Stat" := 400;
		RAISE EXCEPTION 'ComputerIP or Action could not be null';
    END IF;
    
    IF COALESCE(p_action,'') = 'I' THEN
	
		IF COALESCE(p_computerip,'') = '' OR COALESCE(p_currency, '') = '' OR COALESCE(p_symbol, '') = ''  OR COALESCE(p_action, '') = '' THEN
			"Stat" := 400;
			RAISE EXCEPTION 'Currency or Symbol could not be null';
		END IF;
	
        INSERT INTO tblcurrency
        (
			"ComputerIP",
			"Currency",
			"Symbol",
			"Note",
			"Flag",
			"LocationID",
			"Updateby"
        ) 
        VALUES 
        (
			p_computerip,
			p_currency,
			p_symbol,
			p_note,
			p_flag,
			p_locationid,
			p_updateby
        );

        "Stat" := 200;
        RAISE NOTICE 'Insert successful';
        
    ELSIF COALESCE(p_action,'') = 'U' THEN
        IF COALESCE(p_id,0) < 1 THEN
			"Stat" := 400;
            RAISE EXCEPTION 'Update ID could not be null';
        END IF;
    
        UPDATE tblcurrency SET
			"ComputerIP" = COALESCE(p_computerip, "ComputerIP"),
			"Currency" = COALESCE(p_currency, "Currency"),
			"Symbol" = COALESCE(p_symbol, "Symbol"),
			"Note" = COALESCE(p_note, "Note"),
			"Flag" = COALESCE(p_flag, "Flag"),
			"LocationID" = COALESCE(p_locationid, "LocationID"),
			"Updateby" = COALESCE(p_updateby, "Updateby"),
            "Updated_at" = NOW()
        WHERE "ID" = p_id 
				AND (
					p_role = 2 OR
					(p_role != 2 AND "LocationID" = p_userlocation)
				  );
        
        "Stat" := 200;
        RAISE NOTICE 'Update successful';
		
	ELSIF COALESCE(p_action,'') = 'D' THEN
        IF COALESCE(p_id,0) < 1 THEN
            "Stat" := 400;
			RAISE EXCEPTION 'Delete ID could not be null';
        END IF;
		
		UPDATE tblcurrency 
			SET "Flag" = 2,"Updated_at" = NOW(),
			"ComputerIP" = COALESCE(p_computerip, "ComputerIP")
		WHERE "ID" = p_id
			AND (
				p_role = 2 OR
				(p_role != 2 AND "LocationID" = p_userlocation)
			  );
		
		"Stat" := 200;
        RAISE NOTICE 'Delete successful';
		
	ELSIF COALESCE(p_action,'') = 'F' THEN
	
		IF COALESCE(p_id,0) < 1 THEN
			"Stat" := 400;
			RAISE EXCEPTION 'Change status ID could not be null';
		END IF;

		UPDATE tblcurrency 
			SET "Flag" = p_flag,"Updated_at" = NOW(),
				"ComputerIP" = COALESCE(p_computerip, "ComputerIP")
		WHERE "ID" = p_id AND (
					p_role = 2 OR
					(p_role != 2 AND "LocationID" = p_userlocation)
				  );

		"Stat" := 200;
		RAISE NOTICE 'Change status successful';
		
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_currency_dml',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_userlocation,
            p_updateby,
            p_action
        );
        
        "Stat" := 400;
        RAISE EXCEPTION 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_currency_dml(OUT "Stat" integer, p_id integer, p_computerip text, p_currency text, p_symbol text, p_flag integer, p_note text, p_locationid integer, p_userlocation integer, p_updateby text, p_action text, p_role integer) OWNER TO postgres;

--
-- TOC entry 399 (class 1255 OID 27813)
-- Name: fn_currency_dql(integer, integer, integer, text, integer, integer, text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_currency_dql(p_page_number integer DEFAULT 1, p_items_per_page integer DEFAULT 15, p_id integer DEFAULT NULL::integer, p_keyword text DEFAULT NULL::text, p_locationid integer DEFAULT NULL::integer, p_userlocation integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_role integer DEFAULT 0, p_action text DEFAULT 'ALL'::text) RETURNS TABLE("ID" integer, "ComputerIP" text, "Currency" text, "Symbol" text, "LocationID" integer, "Location" text, "Note" text, "Flag" text, "Updateby" text, "Created_at" text, "Updated_at" text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    
    IF COALESCE(UPPER(p_action),'') = 'ALL' THEN
		RETURN QUERY
			SELECT 
				a."ID",a."ComputerIP",a."Currency", a."Symbol",c."ID" AS "LocationID", c."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblcurrency a
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
						AND (
							p_role = 2 OR
							(p_role != 2 AND a."LocationID" = p_userlocation)
						  )
			ORDER BY a."Flag" DESC, a."ID" DESC;
			
    ELSIF COALESCE(UPPER(p_action),'') = 'ONE' THEN
		RETURN QUERY
			SELECT 
				a."ID",a."ComputerIP",a."Currency", a."Symbol",c."ID" AS "LocationID", c."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblcurrency a
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
						AND (
							p_role = 2 OR
							(p_role != 2 AND a."LocationID" = p_userlocation)
						  )
				AND a."ID" = p_id;
				
	ELSIF COALESCE(UPPER(p_action),'') = 'SEARCH' THEN
		p_keyword := '%'|| p_keyword ||'%';
		
		RETURN QUERY
			SELECT 
				a."ID",a."ComputerIP",a."Currency", a."Symbol",c."ID" AS "LocationID", c."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblcurrency a
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
						AND (
							p_role = 2 OR
							(p_role != 2 AND a."LocationID" = p_userlocation)
						  )
				AND (
						(a."ComputerIP" ILIKE p_keyword OR p_keyword IS NULL)
					 OR (a."Currency" ILIKE p_keyword OR p_keyword IS NULL)
					 OR (c."Location" ILIKE p_keyword OR p_keyword IS NULL)
					 OR (a."Symbol" ILIKE p_keyword OR p_keyword IS NULL)
					 OR (a."Updateby" ILIKE p_keyword OR p_keyword IS NULL)
					 OR (a."Flag"::TEXT ILIKE p_keyword OR p_keyword IS NULL)
					 OR (CASE WHEN a."Flag" = 1 THEN 'Active' WHEN a."Flag" = 0 THEN 'Inactive' END  ILIKE p_keyword OR p_keyword IS NULL)
				)
			ORDER BY a."Flag" DESC, a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
	ELSE
		RETURN QUERY
			SELECT 
				a."ID",a."ComputerIP",a."Currency", a."Symbol",c."ID" AS "LocationID", c."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblcurrency a
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
						AND (
							p_role = 2 OR
							(p_role != 2 AND a."LocationID" = p_userlocation)
						  )
			ORDER BY a."Flag" DESC, a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
    END IF;
	
    RAISE NOTICE 'Query successful';
	
	
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_currency_dql',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_userlocation,
            p_updateby,
            p_action
        );
        
        RAISE NOTICE 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_currency_dql(p_page_number integer, p_items_per_page integer, p_id integer, p_keyword text, p_locationid integer, p_userlocation integer, p_updateby text, p_role integer, p_action text) OWNER TO postgres;

--
-- TOC entry 390 (class 1255 OID 27726)
-- Name: fn_department_dml(integer, text, text, integer, integer, integer, text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_department_dml(OUT "Stat" integer, p_id integer DEFAULT NULL::integer, p_department text DEFAULT NULL::text, p_note text DEFAULT NULL::text, p_flag integer DEFAULT 1, p_locationid integer DEFAULT NULL::integer, p_userlocation integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_action text DEFAULT NULL::text, p_role integer DEFAULT 0) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF COALESCE(p_locationid, 0) < 1  OR COALESCE(p_action, '') = '' THEN
        "Stat" := 400;
		RAISE EXCEPTION 'LocationID or Action could not be null';
    END IF;
	
	IF COALESCE(p_action,'') = 'I' THEN
	
		IF COALESCE(p_department,'') = '' THEN
			"Stat" := 400;
			RAISE EXCEPTION 'Department could not be null';
		END IF;
	
		IF COALESCE(p_role, 0) != 2 THEN
			p_locationid := p_userlocation;
		END IF;

		INSERT INTO tbldepartment
		(
			"Department",
			"Note",
			"Flag",
			"LocationID",
			"Updateby"
		) 
		VALUES 
		(
			p_department,
			p_note,
			p_flag,
			p_locationid,
			p_updateby
		);

		"Stat" := 200;
		--RAISE NOTICE 'Insert successful';
	ELSIF COALESCE(p_action,'') = 'U' THEN
		IF COALESCE(p_id,0) < 1 THEN
			"Stat" := 400;
			RAISE EXCEPTION 'Update ID could not be null';
		END IF;

		UPDATE tbldepartment SET
			"Department" = COALESCE(p_department, "Department"),
			"Note" = COALESCE(p_note, "Note"),
			"Flag" = COALESCE(p_flag, "Flag"),
			"LocationID" = COALESCE(p_locationid, "LocationID"),
			"Updateby" = COALESCE(p_updateby, "Updateby"),
			"Updated_at" = NOW()
		WHERE "ID" = p_id 
			AND (
					p_role = 2 OR
					(p_role != 2 AND "LocationID" = p_userlocation)
				  );

		"Stat" := 200;
		RAISE NOTICE 'Update successful';

	ELSIF COALESCE(p_action,'') = 'D' THEN
		IF p_id = 0 OR p_id IS NULL THEN
			"Stat" := 400;
			RAISE EXCEPTION 'Delete ID could not be null';
		END IF;

		UPDATE tbldepartment SET "Flag" = 2,"Updated_at" = NOW() WHERE "ID" = p_id AND (
					p_role = 2 OR
					(p_role != 2 AND "LocationID" = p_userlocation)
				  );

		"Stat" := 200;
		RAISE NOTICE 'Delete successful';

	ELSIF COALESCE(p_action,'') = 'F' THEN
		IF p_id = 0 OR p_id IS NULL THEN
			"Stat" := 400;
			RAISE EXCEPTION 'Change status ID could not be null';
		END IF;

		UPDATE tbldepartment SET "Flag" = p_flag,"Updated_at" = NOW() WHERE "ID" = p_id AND (
					p_role = 2 OR
					(p_role != 2 AND "LocationID" = p_userlocation)
				  );

		"Stat" := 200;
		RAISE NOTICE 'Change status successful';

	END IF;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_department_dml',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_userlocation,
            p_updateby,
            p_action
        );
        
        "Stat" := 400;
        RAISE EXCEPTION 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_department_dml(OUT "Stat" integer, p_id integer, p_department text, p_note text, p_flag integer, p_locationid integer, p_userlocation integer, p_updateby text, p_action text, p_role integer) OWNER TO postgres;

--
-- TOC entry 392 (class 1255 OID 27729)
-- Name: fn_department_dql(integer, integer, integer, text, integer, integer, text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_department_dql(p_page_number integer DEFAULT 1, p_items_per_page integer DEFAULT 15, p_id integer DEFAULT NULL::integer, p_keyword text DEFAULT NULL::text, p_locationid integer DEFAULT NULL::integer, p_userlocation integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_role integer DEFAULT 0, p_action text DEFAULT NULL::text) RETURNS TABLE("ID" integer, "Department" text, "LocationID" integer, "Location" text, "Note" text, "Flag" text, "Updateby" text, "Created_at" text, "Updated_at" text)
    LANGUAGE plpgsql
    AS $$
BEGIN
	---User permission -> get only user location
	--IF p_role != 2 THEN
	--	p_action := 'ONE';
	--END IF;
    
    IF COALESCE(UPPER(p_action),'') = 'ALL' THEN
		RETURN QUERY
			SELECT 
				a."ID",a."Department",b."ID" AS "LocationID", b."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tbldepartment a
				JOIN tbllocation b ON a."LocationID" = b."ID"
			WHERE a."Flag" IN (0,1)
				AND (
							p_role = 2 OR
							(p_role != 2 AND a."LocationID" = p_userlocation)
						  )
			ORDER BY a."Flag", a."ID" DESC;
			
    ELSIF COALESCE(UPPER(p_action),'') = 'ONE' THEN
		RETURN QUERY
			SELECT 
				a."ID",a."Department",b."ID" AS "LocationID", b."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tbldepartment a
				JOIN tbllocation b ON a."LocationID" = b."ID"
			WHERE a."Flag" IN (0,1)
				AND a."ID" = p_id
				AND (
							p_role = 2 OR
							(p_role != 2 AND a."LocationID" = p_userlocation)
						  );
					
	ELSIF COALESCE(UPPER(p_action),'') = 'SEARCH' THEN
		p_keyword := '%'|| p_keyword ||'%';
		
		RETURN QUERY
			
			SELECT 
				a."ID",a."Department",b."ID" AS "LocationID", b."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tbldepartment a
				JOIN tbllocation b ON a."LocationID" = b."ID"
			WHERE a."Flag" IN (0,1)
				AND (
							2 = 2 OR
							(2 != 2 AND a."LocationID" = 38)
						  )
				AND (
						(a."Department" ILIKE p_keyword OR p_keyword IS NULL)
					 OR (a."Updateby" ILIKE p_keyword OR p_keyword IS NULL)
					 OR (b."Location" ILIKE p_keyword OR p_keyword IS NULL)
					 OR (a."Note" ILIKE p_keyword OR p_keyword IS NULL)
					 OR (CASE WHEN a."Flag" = 1 THEN 'Active' WHEN a."Flag" = 0 THEN 'Inactive' END  ILIKE p_keyword OR p_keyword IS NULL)
				)
			ORDER BY a."Flag", a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
	ELSE
		RETURN QUERY
			SELECT 
				a."ID",a."Department",b."ID" AS "LocationID", b."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tbldepartment a
				JOIN tbllocation b ON a."LocationID" = b."ID"
			WHERE a."Flag" IN (0,1)
				AND (
							p_role = 2 OR
							(p_role != 2 AND a."LocationID" = p_userlocation)
						  )
			ORDER BY a."Flag", a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
    END IF;
	
    RAISE NOTICE 'Query successful';
	
	
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_department_dql',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_userlocation,
            p_updateby,
            p_action
        );
        
        RAISE NOTICE 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_department_dql(p_page_number integer, p_items_per_page integer, p_id integer, p_keyword text, p_locationid integer, p_userlocation integer, p_updateby text, p_role integer, p_action text) OWNER TO postgres;

--
-- TOC entry 367 (class 1255 OID 19276)
-- Name: fn_discounttype_dql(integer, integer, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_discounttype_dql(p_id integer DEFAULT NULL::integer, p_locationid integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_action text DEFAULT 'ONE'::text) RETURNS TABLE("ID" integer, "DiscountType" text, "LocationID" integer, "Location" text, "Note" text, "Flag" text, "Updateby" text, "Created_at" text, "Updated_at" text)
    LANGUAGE plpgsql
    AS $$
BEGIN
	
    IF COALESCE(UPPER(p_action),'') = 'ONE' THEN
		IF COALESCE(p_id,0) = 0 THEN
			RAISE NOTICE 'p_id could not be null';
		END IF;
		
		RETURN QUERY
			
			SELECT 
				a."ID",a."DiscountType",c."ID" AS "LocationID", c."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tbldiscounttype a
				LEFT JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
				--AND a."LocationID" = p_locationid
				AND a."ID" = p_id
			ORDER BY a."DiscountType";
			
	ELSE
		RETURN QUERY
			SELECT 
				a."ID",a."DiscountType",c."ID" AS "LocationID", c."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tbldiscounttype a
				LEFT JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
				--AND a."LocationID" = p_locationid
			ORDER BY a."DiscountType";
    END IF;
	
    RAISE NOTICE 'Query successful';
	
	
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_discounttype_dql',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_locationid,
            p_updateby,
            p_action
        );
        
        RAISE NOTICE 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_discounttype_dql(p_id integer, p_locationid integer, p_updateby text, p_action text) OWNER TO postgres;

--
-- TOC entry 375 (class 1255 OID 19302)
-- Name: fn_employee_dml(integer, text, integer, text, text, text, text, text, integer, text, text, text, integer, integer, integer, text, double precision, text, integer, integer, text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_employee_dml(OUT "Stat" integer, p_id integer DEFAULT NULL::integer, p_computerip text DEFAULT NULL::text, p_empid integer DEFAULT NULL::integer, p_title text DEFAULT 3, p_firstname text DEFAULT NULL::text, p_lastname text DEFAULT NULL::text, p_email text DEFAULT NULL::text, p_birthday text DEFAULT NULL::text, p_maritalstatus integer DEFAULT 1, p_bloodgroup text DEFAULT NULL::text, p_mobile text DEFAULT NULL::text, p_emergencymobile text DEFAULT NULL::text, p_departmentid integer DEFAULT NULL::integer, p_shiftid integer DEFAULT NULL::integer, p_positionid integer DEFAULT NULL::integer, p_prifileimg text DEFAULT NULL::text, p_salary double precision DEFAULT NULL::double precision, p_note text DEFAULT NULL::text, p_flag integer DEFAULT 1, p_locationid integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_action text DEFAULT NULL::text, p_role integer DEFAULT 0) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF COALESCE(p_empid,'') = '' OR COALESCE(p_firstname,'') = '' OR COALESCE(p_birthday, '') = '' OR COALESCE(p_departmentid, 0) < 1 OR COALESCE(p_action, '') = '' THEN
        "Stat" := 400;
		RAISE EXCEPTION 'EmpID, FirstName, BirthDay, DepartID or Action could not be null';
    END IF;
    
    IF COALESCE(p_action,'') = 'I' THEN
        INSERT INTO tblemployee
        (
			"ComputerIP",
			"EmpID",
			"Title",
			"FirstName",
			"LastName",
			"Email",
			"BirthDay",
			"MaritalStatus",
			"BloodGroup",
			"Mobile",
			"EmergencyMobile",
			"DepartmentID",
			"ShiftID",
			"PositionID",
			"ProfileImg",
			"Salary",
			"Note",
			"Flag",
			"LocationID",
			"Updateby"
        ) 
        VALUES 
        (
            p_computerip,
			p_empid,
			p_title,
			p_firstname,
			p_lastname,
			p_email,
			p_birthday::date,
			p_maritalstatus,
			p_bloodgroup,
			p_mobile,
			p_emergencymobile,
			p_departmentid,
			p_shiftid,
			p_positionid,
			p_prifileimg,
			p_salary,
			p_note,
			p_flag,
			p_locationid,
			p_updateby
        );

        "Stat" := 200;
        RAISE NOTICE 'Insert successful';
        
    ELSIF COALESCE(p_action,'') = 'U' THEN
        IF p_id = 0 THEN
			"Stat" := 400;
            RAISE EXCEPTION 'Update ID could not be null';
        END IF;
    
        UPDATE tblemployee SET
			"ComputerIP" = COALESCE(p_computerip, "ComputerIP"),
			"EmpID" = COALESCE(p_empid, "EmpID"),
			"Title" = COALESCE(p_title, "Title"),
			"FirstName" = COALESCE(p_firstname, "FirstName"),
			"LastName" = COALESCE(p_lastname, "LastName"),
			"Email" = COALESCE(p_email, "Email"),
			"BirthDay" = COALESCE(p_birthday::date, "BirthDay"),
			"MaritalStatus" = COALESCE(p_maritalstatus, "MaritalStatus"),
			"BloodGroup" = COALESCE(p_bloodgroup, "BloodGroup"),
			"Mobile" = COALESCE(p_mobile, "Mobile"),
			"EmergencyMobile" = COALESCE(p_emergencymobile, "EmergencyMobile"),
			"DepartmentID" = COALESCE(p_departmentid, "DepartmentID"),
			"ShiftID" = COALESCE(p_shiftid, "ShiftID"),
			"PositionID" = COALESCE(p_positionid, "PositionID"),
			"ProfileImg" = COALESCE(p_prifileimg, "ProfileImg"),
			"Salary" = COALESCE(p_salary, "Salary"),
			"Note" = COALESCE(p_note, "Note"),
			"Flag" = COALESCE(p_flag, "Flag"),
			"LocationID" = COALESCE(p_locationid, "LocationID"),
			"Updateby" = COALESCE(p_updateby, "Updateby"),
            "Updated_at" = NOW()
        WHERE "ID" = p_id 
			AND "LocationID" = p_locationid;
        
        "Stat" := 200;
        RAISE NOTICE 'Update successful';
		
	ELSIF COALESCE(p_action,'') = 'D' THEN
        IF p_id = 0 OR p_id IS NULL THEN
            "Stat" := 400;
			RAISE EXCEPTION 'Delete ID could not be null';
        END IF;
		
		UPDATE tblemployee SET "Flag" = 2,"Updated_at" = NOW() WHERE "ID" = p_id;
		
		"Stat" := 200;
        RAISE NOTICE 'Delete successful';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_employee_dml',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_locationid,
            p_updateby,
            p_action
        );
        
        "Stat" := 400;
        RAISE EXCEPTION 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_employee_dml(OUT "Stat" integer, p_id integer, p_computerip text, p_empid integer, p_title text, p_firstname text, p_lastname text, p_email text, p_birthday text, p_maritalstatus integer, p_bloodgroup text, p_mobile text, p_emergencymobile text, p_departmentid integer, p_shiftid integer, p_positionid integer, p_prifileimg text, p_salary double precision, p_note text, p_flag integer, p_locationid integer, p_updateby text, p_action text, p_role integer) OWNER TO postgres;

--
-- TOC entry 362 (class 1255 OID 19280)
-- Name: fn_employee_dql(integer, integer, integer, text, integer, text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_employee_dql(p_page_number integer DEFAULT 1, p_items_per_page integer DEFAULT 15, p_id integer DEFAULT NULL::integer, p_keyword text DEFAULT NULL::text, p_locationid integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_role integer DEFAULT 0, p_action text DEFAULT 'ALL'::text) RETURNS TABLE("ID" integer, "ComputerIP" text, "EmpID" integer, "Title" text, "FirstName" text, "LastName" text, "Email" text, "BirthDay" text, "MaritalStatus" text, "BloodGroup" text, "Mobile" text, "EmergencyMobile" text, "DepartmentID" text, "Department" text, "ShiftID" integer, "Shift" text, "PositionID" integer, "Position" text, "ProfileImg" text, "Salary" double precision, "Note" text, "LocationID" integer, "Location" text, "Flag" text, "Updateby" text, "Created_at" text, "Updated_at" text)
    LANGUAGE plpgsql
    AS $$
BEGIN
	---User permission -> get only user location
	IF p_role != 2 THEN
		p_action := 'ONE';
	END IF;
    
    IF COALESCE(UPPER(p_action),'') = 'ALL' THEN
		RETURN QUERY
			SELECT 
				a."ID",a."ComputerIP",a."EmpID",
				CASE WHEN a."Title" = 1 THEN 'Female' WHEN a."Title" = 2 THEN 'Male' ELSE 'Other' END AS "Title",
				a."FirstName",a."LastName",a."Email",TO_CHAR(a."BirthDay",'DD/MM/YYYY') AS "BirthDay",
				CASE WHEN a."MaritalStatus" = 0 THEN 'Single' WHEN a."MaritalStatus" = 1 THEN 'Married' ELSE 'Other' END AS "MaritalStatus",
				a."BloodGroup",a."Mobile",a."EmergencyMobile",c."ID" AS "DepartmentID",c."Department",
				d."ID" AS "ShiftID",d."Shift" AS "Shift",e."ID" AS "PositionID",e."Position",a."ProfileImg",a."Salary",a."Note",
				b."ID" AS "LocationID",b."Location",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblemployee a
				JOIN tbllocation b ON a."LocationID" = b."ID"
				JOIN tbldepartment c ON a."DepartmentID" = c."ID"
				JOIN tblposition e ON a."PositionID" = e."ID"
				LEFT JOIN tblshift d ON a."ShiftID" = d."ID"
			WHERE a."Flag" IN (0,1)
					--AND a."LocationID" = p_locationid
			ORDER BY a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
			
    ELSIF COALESCE(UPPER(p_action),'') = 'ONE' THEN
		RETURN QUERY
			SELECT 
				a."ID",a."ComputerIP",a."EmpID", a."Title",
				a."FirstName",a."LastName",a."Email",a."BirthDay",
				CASE WHEN a."MaritalStatus" = 0 THEN 'Single' WHEN a."MaritalStatus" = 1 THEN 'Married' ELSE 'Other' END AS "MaritalStatus",
				a."BloodGroup",a."Mobile",a."EmergencyMobile",c."ID" AS "DepartmentID",c."Department",
				d."ID" AS "ShiftID",d."Shift" AS "Shift",e."ID" AS "PositionID",e."Position",a."ProfileImg",a."Salary",a."Note",
				b."ID" AS "LocationID",b."Location",
				a."Flag", a."Updateby", a."Created_at", a."Updated_at"
			FROM tblemployee a
				JOIN tbllocation b ON a."LocationID" = b."ID"
				JOIN tbldepartment c ON a."DepartmentID" = c."ID"
				JOIN tblposition e ON a."PositionID" = e."ID"
				LEFT JOIN tblshift d ON a."ShiftID" = d."ID"
			WHERE a."ID" = p_id AND a."LocationID" = p_locationid
					AND a."Flag" IN (0,1);
					
	ELSE
		RETURN QUERY
			SELECT 
				a."ID",a."ComputerIP",a."EmpID",
				CASE WHEN a."Title" = 1 THEN 'Female' WHEN a."Title" = 2 THEN 'Male' ELSE 'Other' END AS "Title",
				a."FirstName",a."LastName",a."Email",TO_CHAR(a."BirthDay",'DD/MM/YYYY') AS "BirthDay",
				CASE WHEN a."MaritalStatus" = 0 THEN 'Single' WHEN a."MaritalStatus" = 1 THEN 'Married' ELSE 'Other' END AS "MaritalStatus",
				a."BloodGroup",a."Mobile",a."EmergencyMobile",c."ID" AS "DepartmentID",c."Department",
				d."ID" AS "ShiftID",d."Name" AS "Shift",e."ID" AS "PositionID",e."Position",a."ProfileImg",a."Salary",a."Note",
				b."ID" AS "LocationID",b."Location",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblemployee a
				JOIN tbllocation b ON a."LocationID" = b."ID"
				JOIN tbldepartment c ON a."DepartmentID" = c."ID"
				JOIN tblposition e ON a."PositionID" = e."ID"
				LEFT JOIN tblshift d ON a."ShiftID" = d."ID"
			WHERE a."ID" = p_id AND a."LocationID" = p_locationid
					AND a."Flag" IN (0,1)
					AND (
							(a."ComputerIP" LIKE p_keyword OR p_keyword IS NULL)
						 OR (a."EmpID" LIKE p_keyword OR p_keyword IS NULL)
						 OR (a."FirstName" LIKE p_keyword OR p_keyword IS NULL)
						 OR (a."LastName" LIKE p_keyword OR p_keyword IS NULL)
						 OR (a."Email" LIKE p_keyword OR p_keyword IS NULL)
						 OR (c."Department" LIKE p_keyword OR p_keyword IS NULL)
						 OR (d."Name" LIKE p_keyword OR p_keyword IS NULL)
						 OR (b."Location" LIKE p_keyword OR p_keyword IS NULL)
						 OR (a."Flag" LIKE p_keyword OR p_keyword IS NULL)
						 OR (a."Mobile" LIKE p_keyword OR p_keyword IS NULL)
					)
			ORDER BY a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
    END IF;
	
    RAISE NOTICE 'Query successful';
	
	
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_employee_dql',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_locationid,
            p_updateby,
            p_action
        );
        
        RAISE NOTICE 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_employee_dql(p_page_number integer, p_items_per_page integer, p_id integer, p_keyword text, p_locationid integer, p_updateby text, p_role integer, p_action text) OWNER TO postgres;

--
-- TOC entry 376 (class 1255 OID 19304)
-- Name: fn_exchange_dml(integer, double precision, integer, text, integer, integer, text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_exchange_dml(OUT "Stat" integer, p_id integer DEFAULT NULL::integer, p_rate double precision DEFAULT NULL::double precision, p_currencyid integer DEFAULT NULL::integer, p_note text DEFAULT NULL::text, p_flag integer DEFAULT 1, p_locationid integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_action text DEFAULT NULL::text, p_role integer DEFAULT 0) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
	
    IF COALESCE(p_rate,0) < 1 OR COALESCE(p_currencyid, 0) < 1 OR COALESCE(p_action, '') = '' THEN
        "Stat" := 400;
		RAISE EXCEPTION 'Rate, CurrencyID or Action could not be null';
    END IF;
    
    IF COALESCE(p_action,'') = 'I' THEN
        INSERT INTO tbleexchange
        (
			"Rate",
			"CurrencyID",
			"Note",
			"Flag",
			"LocationID",
			"Updateby"
        ) 
        VALUES 
        (
			p_rate,
			p_currencyid,
			p_note,
			p_flag,
			p_locationid,
			p_updateby
        );

        "Stat" := 200;
        RAISE NOTICE 'Insert successful';
        
    ELSIF COALESCE(p_action,'') = 'U' THEN
        IF p_id = 0  OR COALESCE(p_id,'') ='' THEN
			"Stat" := 400;
            RAISE EXCEPTION 'Update ID could not be null';
        END IF;
    
        UPDATE tbleexchange SET
			"Rate" = COALESCE(p_rate, "Rate"),
			"CurrencyID" = COALESCE(p_currencyid, "CurrencyID"),
			"Note" = COALESCE(p_note, "Note"),
			"Flag" = COALESCE(p_flag, "Flag"),
			"LocationID" = COALESCE(p_locationid, "LocationID"),
			"Updateby" = COALESCE(p_updateby, "Updateby"),
            "Updated_at" = NOW()
        WHERE "ID" = p_id 
			AND "LocationID" = p_locationid;
        
        "Stat" := 200;
        RAISE NOTICE 'Update successful';
		
	ELSIF COALESCE(p_action,'') = 'D' THEN
        IF p_id = 0 OR COALESCE(p_id,0) < 1 THEN
            "Stat" := 400;
			RAISE EXCEPTION 'Delete ID could not be null';
        END IF;
		
		UPDATE tbleexchange SET "Flag" = 2,"Updated_at" = NOW() WHERE "ID" = p_id;
		
		"Stat" := 200;
        RAISE NOTICE 'Delete successful';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_exchange_dml',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_locationid,
            p_updateby,
            p_action
        );
        
        "Stat" := 400;
        RAISE EXCEPTION 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_exchange_dml(OUT "Stat" integer, p_id integer, p_rate double precision, p_currencyid integer, p_note text, p_flag integer, p_locationid integer, p_updateby text, p_action text, p_role integer) OWNER TO postgres;

--
-- TOC entry 368 (class 1255 OID 19282)
-- Name: fn_exchange_dql(integer, integer, integer, text, integer, text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_exchange_dql(p_page_number integer DEFAULT 1, p_items_per_page integer DEFAULT 15, p_id integer DEFAULT NULL::integer, p_keyword text DEFAULT NULL::text, p_locationid integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_role integer DEFAULT 0, p_action text DEFAULT 'ALL'::text) RETURNS TABLE("ID" integer, "Rate" double precision, "CurrencyID" text, "Currency" text, "Symbol" text, "LocationID" integer, "Location" text, "Note" text, "Flag" text, "Updateby" text, "Created_at" text, "Updated_at" text)
    LANGUAGE plpgsql
    AS $$
BEGIN
	---User permission -> get only user location
	IF p_role != 2 THEN
		p_action := 'ONE';
	END IF;
    
    IF COALESCE(UPPER(p_action),'') = 'ALL' THEN
		RETURN QUERY
			SELECT 
				a."ID",a."Rate",a."CurrencyID",b."Currency", b."Symbol",c."ID" AS "LocationID", c."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tbleexchange a
				JOIN tblcurrency b ON a."CurrencyID" = b."ID"
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
				AND a."LocationID" = p_locationid
			ORDER BY a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
			
    ELSIF COALESCE(UPPER(p_action),'') = 'ONE' THEN
		RETURN QUERY
			SELECT 
				a."ID",a."Rate",a."CurrencyID",b."Currency", b."Symbol",c."ID" AS "LocationID", c."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tbleexchange a
				JOIN tblcurrency b ON a."CurrencyID" = b."ID"
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
				AND a."LocationID" = p_locationid
				AND a."ID" = p_id;
	ELSE
		RETURN QUERY
			SELECT 
				a."ID",a."Rate",a."CurrencyID",b."Currency", b."Symbol",c."ID" AS "LocationID", c."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tbleexchange a
				JOIN tblcurrency b ON a."CurrencyID" = b."ID"
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
				AND a."LocationID" = p_locationid
				AND (
						(a."Rate" LIKE p_keyword OR p_keyword IS NULL)
					 OR (b."Currency" LIKE p_keyword OR p_keyword IS NULL)
					 OR (c."Location" LIKE p_keyword OR p_keyword IS NULL)
					 OR (b."Symbol" LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."Updateby" LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."Flag" LIKE p_keyword OR p_keyword IS NULL)
				)
			ORDER BY a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
    END IF;
	
    RAISE NOTICE 'Query successful';
	
	
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_exchange_dql',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_locationid,
            p_updateby,
            p_action
        );
        
        RAISE NOTICE 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_exchange_dql(p_page_number integer, p_items_per_page integer, p_id integer, p_keyword text, p_locationid integer, p_updateby text, p_role integer, p_action text) OWNER TO postgres;

--
-- TOC entry 388 (class 1255 OID 27724)
-- Name: fn_location_detail_dml(integer, text, text, text, text, text, integer, integer, integer, text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_location_detail_dml(OUT "Stat" integer, p_id integer DEFAULT NULL::integer, p_bankname text DEFAULT NULL::text, p_accholder text DEFAULT NULL::text, p_acc text DEFAULT NULL::text, p_qr text DEFAULT NULL::text, p_note text DEFAULT NULL::text, p_flag integer DEFAULT 1, p_locationid integer DEFAULT NULL::integer, p_userlocation integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_role integer DEFAULT 0, p_action text DEFAULT 'I'::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF COALESCE(p_action, '') = '' OR COALESCE(p_locationid,0) < 1 OR COALESCE(p_updateby,'') = '' THEN
        "Stat" := 400;
		RAISE EXCEPTION 'Action, Updateby or LocationID could not be null';
    END IF;
	
    IF COALESCE(p_action,'') = 'I' THEN
		IF COALESCE(p_bankname,'') = '' OR COALESCE(p_accholder,'') = '' OR COALESCE(p_acc, '') = '' THEN
			"Stat" := 400;
			RAISE EXCEPTION 'BankName, Location or ACC could not be null';
		END IF;
	
        INSERT INTO tbllocationdetail
        (
			"BankName",
			"ACCHolder",
			"ACC",
			"QR",
			"Note",
			"Flag",
			"LocationID",
			"Updateby"
        ) 
        VALUES 
        (
            p_bankname,
			p_accholder,
			p_acc,
			p_qr,
			p_note,
			p_flag,
			p_locationid,
			p_updateby
        );

        "Stat" := 200;
        RAISE NOTICE 'Insert successful';
        
    ELSIF COALESCE(p_action,'') = 'U' THEN
        IF COALESCE(p_id,0) < 1 THEN
			"Stat" := 400;
            RAISE EXCEPTION 'Update ID could not be null';
        END IF;
    
        UPDATE tbllocationdetail SET
			"BankName" = COALESCE(p_bankname, "BankName"),
			"ACCHolder" = COALESCE(p_accholder, "ACCHolder"),
			"ACC" = COALESCE(p_acc, "ACC"),
			"QR" = COALESCE(p_qr, "QR"),
			"Note" = COALESCE(p_note, "Note"),
			"Flag" = COALESCE(p_flag, "Flag"),
			"LocationID" = COALESCE(p_locationid, "LocationID"),
			"Updateby" = COALESCE(p_updateby, "Updateby"),
            "Updated_at" = NOW()
        WHERE "ID" = p_id
				AND "Flag" IN(0,1);
			--AND "LocationID" = p_locationid;
        
        "Stat" := 200;
        RAISE NOTICE 'Update successful';
		
	ELSIF COALESCE(p_action,'') = 'D' THEN
		IF COALESCE(p_id,0) < 1 THEN
			"Stat" := 400;
            RAISE EXCEPTION 'Update ID could not be null';
        END IF;
		
		UPDATE tbllocationdetail SET "Flag" = 2,"Updated_at" = NOW() WHERE "ID" = p_id;
		
		"Stat" := 200;
        RAISE NOTICE 'Delete successful';
	ELSIF COALESCE(p_action,'') = 'F' THEN
		IF COALESCE(p_id,0) < 1 THEN
		"Stat" := 400;
		RAISE EXCEPTION 'Change status ID could not be null';
		END IF;
		
		UPDATE tbllocationdetail SET 
				"Flag" = COALESCE(p_flag, "Flag"),
				"Updateby" = COALESCE(p_updateby, "Updateby"),
				"Updated_at" = NOW() 
			WHERE "ID" = p_id
					 AND "Flag" IN (0,1);
		
		"Stat" := 200;
        RAISE NOTICE 'Change flag successful';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_location_detail_dml',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_userlocation,
            p_updateby,
            p_action
        );
        
        "Stat" := 400;
        RAISE EXCEPTION 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_location_detail_dml(OUT "Stat" integer, p_id integer, p_bankname text, p_accholder text, p_acc text, p_qr text, p_note text, p_flag integer, p_locationid integer, p_userlocation integer, p_updateby text, p_role integer, p_action text) OWNER TO postgres;

--
-- TOC entry 389 (class 1255 OID 27723)
-- Name: fn_location_detail_dql(integer, integer, integer, text, integer, integer, text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_location_detail_dql(p_page_number integer DEFAULT 1, p_items_per_page integer DEFAULT 15, p_id integer DEFAULT NULL::integer, p_keyword text DEFAULT NULL::text, p_locationid integer DEFAULT NULL::integer, p_userlocation integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_role integer DEFAULT 0, p_action text DEFAULT NULL::text) RETURNS TABLE("ID" integer, "BankName" text, "ACCHolder" text, "ACC" text, "QR" text, "Note" text, "LocationID" integer, "Location" text, "Flag" text, "Updateby" text, "Created_at" text, "Updated_at" text)
    LANGUAGE plpgsql
    AS $$
BEGIN
	---User permission -> get only user location
-- 	IF p_role != 2 THEN
-- 		p_action := 'ONE';
-- 	END IF;
    
    IF COALESCE(UPPER(p_action),'') = 'ALL' THEN
		RETURN QUERY
			SELECT 
				a."ID", a."BankName",a."ACCHolder",a."ACC",a."QR",a."Note",b."ID" AS "LocationID",b."Location",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tbllocationdetail a
				JOIN tbllocation b ON a."LocationID" = b."ID"
			WHERE a."Flag" IN (0,1)
					  AND (
							p_role = 2 OR
							(p_role != 2 AND a."LocationID" = p_userlocation)
						  )
			ORDER BY a."Flag" DESC, a."ID" DESC;
			
    ELSIF COALESCE(UPPER(p_action),'') = 'ONE' THEN
		RETURN QUERY
			SELECT 
				a."ID", a."BankName",a."ACCHolder",a."ACC",a."QR",a."Note",b."ID" AS "LocationID",b."Location",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag"
				, a."Updateby", 
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tbllocationdetail a JOIN tbllocation b ON a."LocationID" = b."ID"
			WHERE a."ID" = p_id 
					  AND (
							p_role = 2 OR
							(p_role != 2 AND a."LocationID" = p_userlocation)
						  )
					AND a."Flag" IN (0,1);
					
	ELSIF COALESCE(UPPER(p_action),'') = 'SEARCH' THEN
		p_keyword := '%'|| p_keyword ||'%';
	
		RETURN QUERY
			SELECT 
				a."ID", a."BankName",a."ACCHolder",a."ACC",a."QR",a."Note",b."ID" AS "LocationID",b."Location",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tbllocationdetail a
				JOIN tbllocation b ON a."LocationID" = b."ID"
			WHERE a."Flag" IN (0,1) 
					  AND (
							p_role = 2 OR
							(p_role != 2 AND a."LocationID" = p_userlocation)
						  )
				  AND (
				  		 (a."BankName" LIKE p_keyword OR p_keyword IS NULL)
					  OR (a."ACCHolder" LIKE p_keyword OR p_keyword IS NULL)
					  OR (a."ACC" LIKE p_keyword OR p_keyword IS NULL)
					  OR (b."Location" LIKE p_keyword OR p_keyword IS NULL)
					  OR (CASE WHEN a."Flag" = 1 THEN 'Active' WHEN a."Flag" = 0 THEN 'Inactive' END  ILIKE p_keyword OR p_keyword IS NULL)
				  )
			ORDER BY a."Flag" DESC, a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
	ELSE
		RETURN QUERY
				SELECT 
					a."ID", a."BankName",a."ACCHolder",a."ACC",a."QR",a."Note",b."ID" AS "LocationID",b."Location",
					CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
					a."Updateby",
					TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
					TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
				FROM tbllocationdetail a
					JOIN tbllocation b ON a."LocationID" = b."ID"
				WHERE a."Flag" IN (0,1)
					  AND (
							p_role = 2 OR
							(p_role != 2 AND a."LocationID" = p_userlocation)
						  )
				ORDER BY a."Flag" DESC, a."ID" DESC
				OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
    END IF;
	
    RAISE NOTICE 'Insert successful';
	
	
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_location_detail_dql',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_userlocation,
            p_updateby,
            p_action
        );
        
        RAISE NOTICE 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_location_detail_dql(p_page_number integer, p_items_per_page integer, p_id integer, p_keyword text, p_locationid integer, p_userlocation integer, p_updateby text, p_role integer, p_action text) OWNER TO postgres;

--
-- TOC entry 386 (class 1255 OID 27722)
-- Name: fn_location_dml(integer, text, text, text, text, text, double precision, double precision, text, text, text, text, integer, text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_location_dml(OUT "Stat" integer, p_id integer DEFAULT NULL::integer, p_computerip text DEFAULT NULL::text, p_location text DEFAULT NULL::text, p_tel1 text DEFAULT NULL::text, p_tel2 text DEFAULT NULL::text, p_mobile text DEFAULT NULL::text, p_lat double precision DEFAULT NULL::double precision, p_long double precision DEFAULT NULL::double precision, p_address text DEFAULT NULL::text, p_logo text DEFAULT NULL::text, p_profile text DEFAULT NULL::text, p_note text DEFAULT NULL::text, p_flag integer DEFAULT 1, p_updateby text DEFAULT NULL::text, p_userlocation integer DEFAULT NULL::integer, p_action text DEFAULT NULL::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    
    IF COALESCE(p_action,'') = 'I' THEN
	
		IF COALESCE(p_computerip,'') = '' OR COALESCE(p_location,'') = '' OR COALESCE(p_action, '') = '' THEN
			"Stat" := 400;
			RAISE EXCEPTION 'ComputerIP, Location, or Action could not be null';
		END IF;
	
        INSERT INTO tbllocation
        (
            "ComputerIP",
            "Location",
            "Tel1",
            "Tel2",
            "Mobile",
            "Lat",
            "Long",
            "Address",
            "Logo",
			"Profile",
            "Note",
            "Flag",
            "Updateby"
        ) 
        VALUES 
        (
            p_computerip,
            p_location,
            p_tel1,
            p_tel2,
            p_mobile,
            p_lat,
            p_long,
            p_address,
            p_logo,
			p_profile,
            p_note,
            p_flag,
            p_updateby
        );

        "Stat" := 200;
        RAISE NOTICE 'Insert successful';
        
    ELSIF COALESCE(p_action,'') = 'U' THEN
        IF COALESCE(p_id,0) < 1 OR COALESCE(p_action,'') = '' THEN
			"Stat" := 400;
            RAISE EXCEPTION 'Update ID could not be null';
        END IF;
    
        UPDATE tbllocation SET
            "ComputerIP" = COALESCE(p_computerip, "ComputerIP"),
            "Location" = COALESCE(p_location, "Location"),
            "Tel1" = COALESCE(p_tel1, "Tel1"),
            "Tel2" = COALESCE(p_tel2, "Tel2"),
            "Mobile" = COALESCE(p_mobile, "Mobile"),
            "Lat" = COALESCE(p_lat, "Lat"),
            "Long" = COALESCE(p_long, "Long"),
            "Address" = COALESCE(p_address, "Address"),
            "Logo" = COALESCE(p_logo, "Logo"),
			"Profile" = COALESCE(p_profile,"Profile"),
            "Note" = COALESCE(p_note, "Note"),
            "Flag" = COALESCE(p_flag, "Flag"),
            "Updateby" = COALESCE(p_updateby, "Updateby"),
            "Updated_at" = NOW()
        WHERE "ID" = p_id
				 AND "Flag" IN (0,1);
        
        "Stat" := 200;
        RAISE NOTICE 'Update successful';
		
	ELSIF COALESCE(p_action,'') = 'D' THEN
        IF COALESCE(p_id,0) < 1 OR COALESCE(p_action,'') = '' THEN
			"Stat" := 400;
            RAISE EXCEPTION 'Delete ID could not be null';
        END IF;
		
		UPDATE tbllocation SET 
				"ComputerIP" = COALESCE(p_computerip, "ComputerIP"),
				"Flag" = 2,
				"Updateby" = COALESCE(p_updateby, "Updateby"),
				"Updated_at" = NOW() 
			WHERE "ID" = p_id 
					AND "Flag" IN (0,1);
		
		"Stat" := 200;
        RAISE NOTICE 'Delete successful';
		
	ELSIF COALESCE(p_action,'') = 'F' THEN
        IF COALESCE(p_id,0) < 1 OR COALESCE(p_action,'') = '' THEN
			"Stat" := 400;
            RAISE EXCEPTION 'Change status ID could not be null';
        END IF;
		
		UPDATE tbllocation SET 
				"ComputerIP" = COALESCE(p_computerip, "ComputerIP"),
				"Flag" = COALESCE(p_flag, "Flag"),
				"Updateby" = COALESCE(p_updateby, "Updateby"),
				"Updated_at" = NOW() 
			WHERE "ID" = p_id
					 AND "Flag" IN (0,1);
		
		"Stat" := 200;
        RAISE NOTICE 'Change flag successful';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'sp_location_dml',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_userlocation,
            p_updateby,
            p_action
        );
        
        "Stat" := 400;
        RAISE EXCEPTION 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_location_dml(OUT "Stat" integer, p_id integer, p_computerip text, p_location text, p_tel1 text, p_tel2 text, p_mobile text, p_lat double precision, p_long double precision, p_address text, p_logo text, p_profile text, p_note text, p_flag integer, p_updateby text, p_userlocation integer, p_action text) OWNER TO postgres;

--
-- TOC entry 387 (class 1255 OID 27721)
-- Name: fn_location_dql(integer, integer, integer, text, text, integer, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_location_dql(p_page_number integer DEFAULT 1, p_items_per_page integer DEFAULT 15, p_id integer DEFAULT NULL::integer, p_keyword text DEFAULT NULL::text, p_updateby text DEFAULT NULL::text, p_role integer DEFAULT 0, p_userlocation integer DEFAULT NULL::integer, p_action text DEFAULT NULL::text) RETURNS TABLE("ID" integer, "ComputerIP" text, "Location" text, "Tel1" text, "Tel2" text, "Mobile" text, "Lat" double precision, "Long" double precision, "Address" text, "Logo" text, "Profile" text, "Note" text, "Flag" text, "Updateby" text, "Created_at" text, "Updated_at" text)
    LANGUAGE plpgsql
    AS $$
BEGIN

	---User permission -> get only user location
	IF p_role != 2 THEN
		p_action := 'ONE';
	END IF;
    
    IF COALESCE(UPPER(p_action),'') = 'ALL' THEN
		RETURN QUERY
			SELECT 
				a."ID", a."ComputerIP",a."Location",a."Tel1", a."Tel2",a."Mobile",a."Lat",a."Long",
				a."Address",a."Logo",a."Profile",a."Note",
				CASE WHEN a."Flag"=1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tbllocation a
			WHERE a."Flag" IN (0,1)
			ORDER BY a."Flag" DESC, a."ID" DESC;
		
    ELSIF COALESCE(UPPER(p_action),'') = 'ONE' THEN
		RETURN QUERY
			SELECT 
				a."ID", a."ComputerIP",a."Location",a."Tel1", a."Tel2",a."Mobile",a."Lat",a."Long",
				a."Address",a."Logo",a."Profile",a."Note",
				CASE WHEN a."Flag"=1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tbllocation a
			WHERE a."ID" = p_id
					AND a."Flag" IN (0,1);
	ELSIF COALESCE(UPPER(p_action),'') = 'SEARCH' THEN
		p_keyword := '%'|| p_keyword ||'%';
		
		RETURN QUERY
			SELECT 
				a."ID", a."ComputerIP",a."Location",a."Tel1", a."Tel2",a."Mobile",a."Lat",a."Long",
				a."Address",a."Logo",a."Profile",a."Note",
				CASE WHEN a."Flag"=1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tbllocation a
			WHERE a."Flag" IN (0,1)
			  AND (
					   (a."ComputerIP" ILIKE p_keyword OR p_keyword IS NULL)
					OR (a."Location" ILIKE p_keyword OR p_keyword IS NULL)
					OR (a."Tel1" ILIKE p_keyword OR p_keyword IS NULL)
					OR (a."Tel2" ILIKE p_keyword OR p_keyword IS NULL)
					OR (a."Mobile" ILIKE p_keyword OR p_keyword IS NULL)
				  	OR (a."Address" ILIKE p_keyword OR p_keyword IS NULL)
				  	OR (CAST(a."Flag" AS TEXT) ILIKE p_keyword OR p_keyword IS NULL)
				  	OR (CASE WHEN a."Flag" = 1 THEN 'Active' WHEN a."Flag" = 0 THEN 'Inactive' END  ILIKE p_keyword OR p_keyword IS NULL)
				  	OR (a."Note" ILIKE p_keyword OR p_keyword IS NULL)
				  )
			ORDER BY a."Flag" DESC, a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
	ELSE 
		RETURN QUERY
				SELECT 
					a."ID", a."ComputerIP",a."Location",a."Tel1", a."Tel2",a."Mobile",a."Lat",a."Long",
					a."Address",a."Logo",a."Profile",a."Note",
					CASE WHEN a."Flag"=1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
					a."Updateby",
					TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
					TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
				FROM tbllocation a
				WHERE a."Flag" IN (0,1)
				ORDER BY a."Flag" DESC, a."ID" DESC
				OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
    END IF;
	
    RAISE NOTICE 'Query successful';
	
	
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'sp_location_dql',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_userlocation,
            p_updateby,
            p_action
        );
        
        RAISE NOTICE 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_location_dql(p_page_number integer, p_items_per_page integer, p_id integer, p_keyword text, p_updateby text, p_role integer, p_userlocation integer, p_action text) OWNER TO postgres;

--
-- TOC entry 385 (class 1255 OID 27720)
-- Name: fn_menu_dql(integer, integer, text, integer, text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_menu_dql(p_userid integer DEFAULT NULL::integer, p_id integer DEFAULT NULL::integer, p_menuid text DEFAULT NULL::text, p_userlocation integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_role integer DEFAULT 0, p_action text DEFAULT 'ALL'::text) RETURNS TABLE("ID" integer, "ParentID" text, "MenuID" text, "MenuName" text, "Action" text, "Priority" integer, "MenuAction" text, "Flag" text, "Updateby" text, "Created_at" text, "Updated_at" text)
    LANGUAGE plpgsql
    AS $$
BEGIN
	
    IF COALESCE(UPPER(p_action),'') = 'ONE' THEN
		RETURN QUERY
			SELECT DISTINCT
					a."ID", a."ParentID",a."MenuID",a."MenuName",
					a."Action",a."Priority",a."MenuAction",
					CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
					a."Updateby",
					TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
					TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM public.tblmenu a 
			WHERE a."Flag" IN(0,1)
					AND (a."ID" = p_id OR a."MenuID" = p_menuid);
			
    ELSIF COALESCE(UPPER(p_action),'') = 'UserID' THEN
		RETURN QUERY
			SELECT 
					a."ID", a."ParentID",a."MenuID",a."MenuName",
					a."Action",a."Priority",a."MenuAction",
					CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
					a."Updateby",
					TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
					TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM public.tblmenu a 
			WHERE a."MenuID" IN (
				SELECT 
						UNNEST(STRING_TO_ARRAY(m."MenuList", ',')) 
				FROM public.tblmenuprivilege m 
				WHERE m."MenuList" IS NOT NULL 
						AND m."UserID" = p_userid
			)
			ORDER BY a."Priority";
					
	ELSE
		RETURN QUERY
			SELECT 
					a."ID", a."ParentID",a."MenuID",a."MenuName",
					a."Action",a."Priority",a."MenuAction",
					CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
					a."Updateby",
					TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
					TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM public.tblmenu a 
			WHERE a."Flag" IN(0,1)
			ORDER BY a."Priority";
    END IF;
	
    RAISE NOTICE 'Query successful';
	
	
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_menu_dql',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_userlocation,
            p_updateby,
            p_action
        );
        
        RAISE NOTICE 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_menu_dql(p_userid integer, p_id integer, p_menuid text, p_userlocation integer, p_updateby text, p_role integer, p_action text) OWNER TO postgres;

--
-- TOC entry 377 (class 1255 OID 19308)
-- Name: fn_payment_method_dml(integer, text, text, integer, integer, text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_payment_method_dml(OUT "Stat" integer, p_id integer DEFAULT NULL::integer, p_method text DEFAULT NULL::text, p_note text DEFAULT NULL::text, p_flag integer DEFAULT 1, p_locationid integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_action text DEFAULT NULL::text, p_role integer DEFAULT 0) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
	
    IF COALESCE(p_method,'') = '' OR COALESCE(p_locationid, 0) < 1 OR COALESCE(p_action, '') = '' THEN
        "Stat" := 400;
		RAISE EXCEPTION 'Payment Method or Action could not be null';
    END IF;
    
    IF COALESCE(p_action,'') = 'I' THEN
        INSERT INTO tblpaymentmethod
        (
			"Method",
			"Note",
			"Flag",
			"LocationID",
			"Updateby"
        ) 
        VALUES 
        (
			p_method,
			p_note,
			p_flag,
			p_locationid,
			p_updateby
        );

        "Stat" := 200;
        RAISE NOTICE 'Insert successful';
        
    ELSIF COALESCE(p_action,'') = 'U' THEN
        IF p_id = 0  OR COALESCE(p_id,0) < 1 THEN
			"Stat" := 400;
            RAISE EXCEPTION 'Update ID could not be null';
        END IF;
    
        UPDATE tblpaymentmethod SET
			"Method" = COALESCE(p_method, "Method"),
			"Note" = COALESCE(p_note, "Note"),
			"Flag" = COALESCE(p_flag, "Flag"),
			"LocationID" = COALESCE(p_locationid, "LocationID"),
			"Updateby" = COALESCE(p_updateby, "Updateby"),
            "Updated_at" = NOW()
        WHERE "ID" = p_id 
			AND "LocationID" = p_locationid;
        
        "Stat" := 200;
        RAISE NOTICE 'Update successful';
		
	ELSIF COALESCE(p_action,'') = 'D' THEN
        IF p_id = 0 OR COALESCE(p_id,'') ='' THEN
            "Stat" := 400;
			RAISE EXCEPTION 'Delete ID could not be null';
        END IF;
		
		UPDATE tblpaymentmethod SET "Flag" = 2,"Updated_at" = NOW() WHERE "ID" = p_id;
		
		"Stat" := 200;
        RAISE NOTICE 'Delete successful';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_payment_method_dml',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_locationid,
            p_updateby,
            p_action
        );
        
        "Stat" := 400;
        RAISE EXCEPTION 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_payment_method_dml(OUT "Stat" integer, p_id integer, p_method text, p_note text, p_flag integer, p_locationid integer, p_updateby text, p_action text, p_role integer) OWNER TO postgres;

--
-- TOC entry 369 (class 1255 OID 19286)
-- Name: fn_payment_method_dql(integer, integer, integer, text, integer, text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_payment_method_dql(p_page_number integer DEFAULT 1, p_items_per_page integer DEFAULT 15, p_id integer DEFAULT NULL::integer, p_keyword text DEFAULT NULL::text, p_locationid integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_role integer DEFAULT 0, p_action text DEFAULT 'ALL'::text) RETURNS TABLE("ID" integer, "Method" text, "LocationID" integer, "Location" text, "Note" text, "Flag" text, "Updateby" text, "Created_at" text, "Updated_at" text)
    LANGUAGE plpgsql
    AS $$
BEGIN
	---User permission -> get only user location
	IF p_role != 2 THEN
		p_action := 'ONE';
	END IF;
    
    IF COALESCE(UPPER(p_action),'') = 'ALL' THEN
		RETURN QUERY
			SELECT 
				a."ID",a."Method",c."ID" AS "LocationID", c."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblpaymentmethod a
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
				AND a."LocationID" = p_locationid
			ORDER BY a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
			
    ELSIF COALESCE(UPPER(p_action),'') = 'ONE' THEN
		RETURN QUERY
			SELECT 
				a."ID",a."Method",c."ID" AS "LocationID", c."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",a."Created_at",a."Updated_at"
			FROM tblpaymentmethod a
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
				AND a."LocationID" = p_locationid
				AND a."ID" = p_id;
	ELSE
		RETURN QUERY
			SELECT 
				a."ID",a."Method",c."ID" AS "LocationID", c."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblpaymentmethod a
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
				AND a."LocationID" = p_locationid
				AND (
						(a."Method" LIKE p_keyword OR p_keyword IS NULL)
					 OR (c."Location" LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."Updateby" LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."Flag" LIKE p_keyword OR p_keyword IS NULL)
				)
			ORDER BY a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
    END IF;
	
    RAISE NOTICE 'Query successful';
	
	
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_payment_method_dql',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_locationid,
            p_updateby,
            p_action
        );
        
        RAISE NOTICE 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_payment_method_dql(p_page_number integer, p_items_per_page integer, p_id integer, p_keyword text, p_locationid integer, p_updateby text, p_role integer, p_action text) OWNER TO postgres;

--
-- TOC entry 370 (class 1255 OID 19287)
-- Name: fn_payterm_dql(integer, integer, text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_payterm_dql(p_id integer DEFAULT NULL::integer, p_locationid integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_role integer DEFAULT 0, p_action text DEFAULT 'ALL'::text) RETURNS TABLE("ID" integer, "Payterms" text, "LocationID" integer, "Location" text, "Note" text, "Flag" text, "Updateby" text, "Created_at" text, "Updated_at" text)
    LANGUAGE plpgsql
    AS $$
BEGIN
	---User permission -> get only user location
	IF p_role != 2 THEN
		p_action := 'ONE';
	END IF;
    
    IF COALESCE(UPPER(p_action),'') = 'ONE' THEN
		RETURN QUERY
			SELECT 
				a."ID",a."PayTerms",c."ID" AS "LocationID", c."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblpayterm a
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
				AND a."LocationID" = p_locationid
				AND a."ID" = p_id;
	ELSE
		RETURN QUERY
			SELECT 
				a."ID",a."PayTerms",c."ID" AS "LocationID", c."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblpayterm a
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
				AND a."LocationID" = p_locationid
			ORDER BY a."ID" DESC;
    END IF;
	
    RAISE NOTICE 'Query successful';
	
	
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_payterm_dql',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_locationid,
            p_updateby,
            p_action
        );
        
        RAISE NOTICE 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_payterm_dql(p_id integer, p_locationid integer, p_updateby text, p_role integer, p_action text) OWNER TO postgres;

--
-- TOC entry 378 (class 1255 OID 19309)
-- Name: fn_position_dml(integer, text, text, integer, integer, text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_position_dml(OUT "Stat" integer, p_id integer DEFAULT NULL::integer, p_position text DEFAULT NULL::text, p_note text DEFAULT NULL::text, p_flag integer DEFAULT 1, p_locationid integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_action text DEFAULT NULL::text, p_role integer DEFAULT 0) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF COALESCE(p_position,'') = '' OR COALESCE(p_locationid, 0) < 1  OR COALESCE(p_action, '') = '' THEN
        "Stat" := 400;
		RAISE EXCEPTION 'Position, LocationID or Action could not be null';
    END IF;
    
    IF COALESCE(p_action,'') = 'I' THEN
        INSERT INTO tblposition
        (
			"Position",
			"Note",
			"Flag",
			"LocationID",
			"Updateby"
        ) 
        VALUES 
        (
            p_position,
			p_note,
			p_flag,
			p_locationid,
			p_updateby
        );

        "Stat" := 200;
        RAISE NOTICE 'Insert successful';
        
    ELSIF COALESCE(p_action,'') = 'U' THEN
        IF p_id = 0 OR COALESCE(p_id,0) < 1 THEN
			"Stat" := 400;
            RAISE EXCEPTION 'Update ID could not be null';
        END IF;
    
        UPDATE tblposition SET
			"Position" = COALESCE(p_position, "Department"),
			"Note" = COALESCE(p_note, "Note"),
			"Flag" = COALESCE(p_flag, "Flag"),
			"LocationID" = COALESCE(p_locationid, "LocationID"),
			"Updateby" = COALESCE(p_updateby, "Updateby"),
            "Updated_at" = NOW()
        WHERE "ID" = p_id 
			AND "LocationID" = p_locationid;
        
        "Stat" := 200;
        RAISE NOTICE 'Update successful';
		
	ELSIF COALESCE(p_action,'') = 'D' THEN
        IF p_id = 0 OR p_id IS NULL THEN
            "Stat" := 400;
			RAISE EXCEPTION 'Delete ID could not be null';
        END IF;
		
		UPDATE tblposition SET "Flag" = 2,"Updated_at" = NOW() WHERE "ID" = p_id;
		
		"Stat" := 200;
        RAISE NOTICE 'Delete successful';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_position_dml',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_locationid,
            p_updateby,
            p_action
        );
        
        "Stat" := 400;
        RAISE EXCEPTION 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_position_dml(OUT "Stat" integer, p_id integer, p_position text, p_note text, p_flag integer, p_locationid integer, p_updateby text, p_action text, p_role integer) OWNER TO postgres;

--
-- TOC entry 371 (class 1255 OID 19288)
-- Name: fn_position_dql(integer, integer, integer, text, integer, text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_position_dql(p_page_number integer DEFAULT 1, p_items_per_page integer DEFAULT 15, p_id integer DEFAULT NULL::integer, p_keyword text DEFAULT NULL::text, p_locationid integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_role integer DEFAULT 0, p_action text DEFAULT 'ALL'::text) RETURNS TABLE("ID" integer, "Position" text, "LocationID" integer, "Location" text, "Note" text, "Flag" text, "Updateby" text, "Created_at" text, "Updated_at" text)
    LANGUAGE plpgsql
    AS $$
BEGIN
	---User permission -> get only user location
	IF p_role != 2 THEN
		p_action := 'ONE';
	END IF;
    
    IF COALESCE(UPPER(p_action),'') = 'ALL' THEN
		RETURN QUERY
			SELECT 
				a."ID",a."Position",b."ID" AS "LocationID", b."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblposition a
				JOIN tbllocation b ON a."LocationID" = b."ID"
			WHERE a."Flag" IN (0,1)
				AND a."LocationID" = p_locationid
			ORDER BY a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
			
    ELSIF COALESCE(UPPER(p_action),'') = 'ONE' THEN
		RETURN QUERY
			SELECT 
				a."ID",a."Position",b."ID" AS "LocationID", b."Location",a."Note",
				a."Flag", a."Updateby", a."Created_at", a."Updated_at"
			FROM tblposition a
				JOIN tbllocation b ON a."LocationID" = b."ID"
			WHERE a."Flag" IN (0,1)
				AND a."LocationID" = p_locationid
				AND a."ID" = p_id;
					
	ELSE
		RETURN QUERY
			SELECT 
				a."ID",a."Position",b."ID" AS "LocationID", b."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblposition a
				JOIN tbllocation b ON a."LocationID" = b."ID"
			WHERE a."Flag" IN (0,1)
				AND a."LocationID" = p_locationid
				AND (
						(a."Position" LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."Updateby" LIKE p_keyword OR p_keyword IS NULL)
					 OR (b."Location" LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."Flag" LIKE p_keyword OR p_keyword IS NULL)
				)
			ORDER BY a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
    END IF;
	
    RAISE NOTICE 'Query successful';
	
	
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_position_dql',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_locationid,
            p_updateby,
            p_action
        );
        
        RAISE NOTICE 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_position_dql(p_page_number integer, p_items_per_page integer, p_id integer, p_keyword text, p_locationid integer, p_updateby text, p_role integer, p_action text) OWNER TO postgres;

--
-- TOC entry 383 (class 1255 OID 27679)
-- Name: fn_setting_dml(integer, integer, integer, integer, integer, integer, integer, text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_setting_dml(OUT "Stat" integer, p_id integer DEFAULT NULL::integer, p_taxtypeid integer DEFAULT NULL::integer, p_taxid integer DEFAULT NULL::integer, p_currencyid integer DEFAULT NULL::integer, p_languageid integer DEFAULT NULL::integer, p_locationid integer DEFAULT NULL::integer, p_flag integer DEFAULT 1, p_updateby text DEFAULT NULL::text, p_role integer DEFAULT 0, p_action text DEFAULT 'I'::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
	
    IF COALESCE(p_action, '') = '' OR COALESCE(p_locationid, 0) < 1 THEN
        "Stat" := 400;
		RAISE EXCEPTION 'LocationID or Action could not be null';
    END IF;
    
	IF COALESCE(p_action = 'I')
	THEN
		INSERT INTO public.tblsetting(
			"DefaultTaxTypeID",
			"DefaultTaxID",
			"DefaultCurrencyID",
			"DefaultLanguageID",
			"LocationID",
			"Flag",
			"Updateby"
		)
		VALUES
		(
			p_taxtypeid,
			p_taxid,
			p_currencyid,
			p_Languageid,
			p_locationid,
			p_flag,
			p_updateby
		);
		
		"Stat" := 200;
		RAISE NOTICE 'Insert successful';
		
	ELSIF (COALESCE(p_action,'') = 'U')
	THEN
		IF (COALESCE(p_id,0) = 0) THEN
			"Stat" := 400;
            RAISE EXCEPTION 'Update ID could not be null';
		END IF;
		
		UPDATE public.tblsetting SET
			"DefaultTaxTypeID" = COALESCE(p_taxtypeid, "DefaultTaxTypeID"),
			"DefaultTaxID" = COALESCE(p_taxid, "DefaultTaxID"),
			"DefaultCurrencyID" = COALESCE(p_currencyid, "DefaultCurrencyID"),
			"DefaultLanguageID" = COALESCE(p_Languageid, "DefaultLanguageID"),
			"LocationID" = COALESCE(p_locationid, "LocationID"),
			"Flag" = COALESCE(p_flag, "Flag"),
			"Updateby" = COALESCE(p_updateby, "Updateby"),
			"Updated_at" = NOW()
		WHERE "ID" = p_id 
				AND "LocationID" = p_locationdid;
				
		"Stat" := 200;
        RAISE NOTICE 'Update successful';
	ELSIF (COALESCE(p_action,'') = 'D')
	THEN
		IF (COALESCE(p_id,0) = 0) THEN
            "Stat" := 400;
			RAISE EXCEPTION 'Delete ID could not be null';
        END IF;
		
		UPDATE public.tblsetting SET "Flag" = 2,"Updated_at" = NOW() WHERE "ID" = p_id;
		
		"Stat" := 200;
        RAISE NOTICE 'Delete successful';
	END IF;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_setting_dml',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_locationid,
            p_updateby,
            'S'
        );
        
        "Stat" := 400;
        RAISE EXCEPTION 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_setting_dml(OUT "Stat" integer, p_id integer, p_taxtypeid integer, p_taxid integer, p_currencyid integer, p_languageid integer, p_locationid integer, p_flag integer, p_updateby text, p_role integer, p_action text) OWNER TO postgres;

--
-- TOC entry 384 (class 1255 OID 27692)
-- Name: fn_setting_dql(integer, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_setting_dql(p_locationid integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_role integer DEFAULT 0) RETURNS TABLE("ID" integer, "DefaultTaxTypeID" integer, "DefaultTaxType" text, "DefaultTaxID" integer, "DefaultTax" text, "TaxPercentage" double precision, "DefaultCurrencyID" integer, "DefaultCurrency" text, "DefaultLanguageID" integer, "DefaultLanguage" text, "Flag" text, "Updateby" text, "Created_at" text, "Updated_at" text)
    LANGUAGE plpgsql
    AS $$
BEGIN
	
    IF COALESCE(p_locationid, 0) < 1 THEN
        RAISE EXCEPTION 'LocationID or Action could not be null';
    END IF;
    
	SELECT
			a."ID",c."ID" AS "DefaultTaxTypeID",c."TaxType" AS "DefaultTaxType", 
			d."ID" AS "DefaultTaxID",d."TaxName" AS "DefaultTax",d."TaxPercentage",
			e."ID" AS "DefaultCurrencyID", e."Currency" AS "DefaultCurrency",
			a."DefaultLanguageID", CASE WHEN a."DefaultLanguageID" = 1 THEN 'Lao' ELSE 'English' END AS "DefaultLanguage",
			CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
			a."Updateby",
			TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
			TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
		FROM public.tblsetting a 
				 JOIN public.tbllocation b ON a."LocationID" = b."ID"
			LEFT JOIN public.tbltaxtype c ON a."DefaultTaxTypeID" = c."ID"
			LEFT JOIN public.tbltax d ON a."DefaultTaxID" = d."ID"
			LEFT JOIN public.tblcurrency e ON a."DefaultCurrencyID" = e."ID"
		WHERE a."ID" = p_locationid 
				AND a."Flag" = 1;

	RAISE NOTICE 'Query successful';
		

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_setting_dql',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_locationid,
            p_updateby,
            0
        );
        
        RAISE EXCEPTION 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_setting_dql(p_locationid integer, p_updateby text, p_role integer) OWNER TO postgres;

--
-- TOC entry 397 (class 1255 OID 27787)
-- Name: fn_shift_dml(integer, text, integer, text, text, integer, text, integer, integer, integer, text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_shift_dml(OUT "Stat" integer, p_id integer DEFAULT NULL::integer, p_shift text DEFAULT NULL::text, p_shifttypeid integer DEFAULT NULL::integer, p_starttime text DEFAULT NULL::text, p_endtime text DEFAULT NULL::text, p_holiday integer DEFAULT 1, p_note text DEFAULT NULL::text, p_flag integer DEFAULT 1, p_locationid integer DEFAULT NULL::integer, p_userlocation integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_action text DEFAULT NULL::text, p_role integer DEFAULT 0) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF COALESCE(p_locationid, 0) < 1  OR COALESCE(p_action, '') = '' OR COALESCE(p_updateby,'') = '' THEN
        "Stat" := 400;
		RAISE EXCEPTION 'LocationID, Action, Updateby could not be null';
    END IF;
    
    IF COALESCE(p_action,'') = 'I' THEN
		 IF COALESCE(p_shift,'') = '' OR COALESCE(p_shifttypeid,0) < 1 THEN
			"Stat" := 400;
			RAISE EXCEPTION 'Shift OR ShiftTypeID could not be null';
		 END IF;
	
        INSERT INTO tblshift
        (
			"Shift",
			"ShiftTypeID",
			"StartTime",
			"EndTime",
			"Holiday",
			"Note",
			"Flag",
			"LocationID",
			"Updateby"
        ) 
        VALUES 
        (
            p_shift,
			p_shifttypeid,
			p_starttime,
			p_endtime,
			p_holiday,
			p_note,
			p_flag,
			p_locationid,
			p_updateby
        );

        "Stat" := 200;
        RAISE NOTICE 'Insert successful';
        
    ELSIF COALESCE(p_action,'') = 'U' THEN
        IF COALESCE(p_id,0) < 1 THEN
			"Stat" := 400;
            RAISE EXCEPTION 'Update ID could not be null';
        END IF;
    
        UPDATE tblshift SET
			"Shift" = COALESCE(p_shift, "Shift"),
			"ShiftTypeID" = COALESCE(p_shifttypeid, "ShiftTypeID"),
			"StartTime" = COALESCE(p_starttime, "StartTime"),
			"EndTime" = COALESCE(p_endtime, "EndTime"),
			"Holiday" = COALESCE(p_holiday, "Holiday"),
			"Note" = COALESCE(p_note, "Note"),
			"Flag" = COALESCE(p_flag, "Flag"),
			"LocationID" = COALESCE(p_locationid, "LocationID"),
			"Updateby" = COALESCE(p_updateby, "Updateby"),
            "Updated_at" = NOW()
        WHERE "ID" = p_id AND "Flag" IN(0,1)
					  AND (
							p_role = 2 OR
							(p_role != 2 AND "LocationID" = p_userlocation)
						  );
        
        "Stat" := 200;
        RAISE NOTICE 'Update successful';
		
	ELSIF COALESCE(p_action,'') = 'D' THEN
        IF COALESCE(p_id,0) < 1 THEN
            "Stat" := 400;
			RAISE EXCEPTION 'Delete ID could not be null';
        END IF;
		
		UPDATE tblshift SET "Flag" = 2,"Updated_at" = NOW() WHERE "ID" = p_id
					  AND (
							p_role = 2 OR
							(p_role != 2 AND "LocationID" = p_userlocation)
						  );
		
		"Stat" := 200;
        RAISE NOTICE 'Delete successful';
		
	ELSIF COALESCE(p_action,'') = 'F' THEN
		IF COALESCE(p_id,0) < 1 THEN
		"Stat" := 400;
		RAISE EXCEPTION 'Change status ID could not be null';
		END IF;
		
		UPDATE tblshift SET 
				"Flag" = COALESCE(p_flag, "Flag"),
				"Updateby" = COALESCE(p_updateby, "Updateby"),
				"Updated_at" = NOW() 
			WHERE "ID" = p_id
					 AND "Flag" IN (0,1)
					  AND (
							p_role = 2 OR
							(p_role != 2 AND "LocationID" = p_userlocation)
						  );
		
		"Stat" := 200;
        RAISE NOTICE 'Change flag successful';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_shift_dml',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_userlocation,
            p_updateby,
            p_action
        );
        
        "Stat" := 400;
        RAISE EXCEPTION 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_shift_dml(OUT "Stat" integer, p_id integer, p_shift text, p_shifttypeid integer, p_starttime text, p_endtime text, p_holiday integer, p_note text, p_flag integer, p_locationid integer, p_userlocation integer, p_updateby text, p_action text, p_role integer) OWNER TO postgres;

--
-- TOC entry 398 (class 1255 OID 27790)
-- Name: fn_shift_dql(integer, integer, integer, text, integer, integer, text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_shift_dql(p_page_number integer DEFAULT 1, p_items_per_page integer DEFAULT 15, p_id integer DEFAULT NULL::integer, p_keyword text DEFAULT NULL::text, p_locationid integer DEFAULT NULL::integer, p_userlocation integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_role integer DEFAULT 0, p_action text DEFAULT 'SEARCH'::text) RETURNS TABLE("ID" integer, "Shift" text, "ShiftTypeID" integer, "ShiftType" text, "LocationID" integer, "Location" text, "StartTime" text, "EndTime" text, "Holiday" text, "Note" text, "Flag" text, "Updateby" text, "Created_at" text, "Updated_at" text)
    LANGUAGE plpgsql
    AS $$
BEGIN
	---User permission -> get only user location
-- 	IF p_role != 2 THEN
-- 		p_action := 'ONE';
-- 	END IF;
    
    IF COALESCE(UPPER(p_action),'') = 'ALL' THEN
		RETURN QUERY
			SELECT 
				a."ID",a."Shift",c."ID" AS "ShiftTypeID",c."ShiftType",b."ID" AS "LocationID", b."Location",
				a."StartTime",
				a."EndTime",
				public."fn_week_days_text"(a."Holiday") AS "Holiday",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblshift a
				JOIN tbllocation b ON a."LocationID" = b."ID"
				JOIN tblshiftType c ON a."ShiftTypeID" = c."ID"
			WHERE a."Flag" IN (0,1)
					  AND (
							p_role = 2 OR
							(p_role != 2 AND a."LocationID" = p_userlocation)
						  )
			ORDER BY a."Flag" DESC, a."ID" DESC;
			
    ELSIF COALESCE(UPPER(p_action),'') = 'ONE' THEN
		RETURN QUERY
			SELECT 
				a."ID",a."Shift",c."ID" AS "ShiftTypeID",c."ShiftType",b."ID" AS "LocationID", b."Location",
				a."StartTime",
				a."EndTime",
				public."fn_week_days_text"(a."Holiday") AS "Holiday",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblshift a
				JOIN tbllocation b ON a."LocationID" = b."ID"
				JOIN tblshiftType c ON a."ShiftTypeID" = c."ID"
			WHERE a."Flag" IN (0,1)
					  AND (
							p_role = 2 OR
							(p_role != 2 AND a."LocationID" = p_userlocation)
						  )
				AND a."ID" = p_id;
				
	ELSIF COALESCE(UPPER(p_action),'') = 'SEARCH' THEN
		p_keyword := '%'|| p_keyword ||'%';
		
		RETURN QUERY
			SELECT 
				a."ID",a."Shift",c."ID" AS "ShiftTypeID",c."ShiftType",b."ID" AS "LocationID", b."Location",
				a."StartTime",
				a."EndTime",
				public."fn_week_days_text"(a."Holiday") AS "Holiday",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblshift a
				JOIN tbllocation b ON a."LocationID" = b."ID"
				JOIN tblshiftType c ON a."ShiftTypeID" = c."ID"
			WHERE a."Flag" IN (0,1)
					  AND (
							p_role = 2 OR
							(p_role != 2 AND a."LocationID" = p_userlocation)
						  )
				AND (
							(a."Shift" ILIKE p_keyword OR p_keyword IS NULL)
						OR (c."ShiftType" ILIKE p_keyword OR p_keyword IS NULL)
						OR (public."fn_week_days_text"(a."Holiday") ILIKE p_keyword OR p_keyword IS NULL)
						OR (public."fn_week_days_int"(a."Holiday"::text)::TEXT ILIKE p_keyword OR p_keyword IS NULL)
						OR (a."Updateby" ILIKE p_keyword OR p_keyword IS NULL)
						OR (b."Location" ILIKE p_keyword OR p_keyword IS NULL)
						OR (a."Flag"::TEXT ILIKE p_keyword OR p_keyword IS NULL)
						OR (CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END ILIKE p_keyword OR p_keyword IS NULL)
					)

			ORDER BY a."Flag" DESC, a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
	ELSE
		RETURN QUERY
			SELECT 
				a."ID",a."Shift",c."ID" AS "ShiftTypeID",c."ShiftType",b."ID" AS "LocationID", b."Location",
				a."StartTime",
				a."EndTime",
				public."fn_week_days_text"(a."Holiday") AS "Holiday",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblshift a
				JOIN tbllocation b ON a."LocationID" = b."ID"
				JOIN tblshiftType c ON a."ShiftTypeID" = c."ID"
			WHERE a."Flag" IN (0,1)
					  AND (
							p_role = 2 OR
							(p_role != 2 AND a."LocationID" = p_userlocation)
						  )
			ORDER BY a."Flag" DESC, a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
    END IF;
	
    RAISE NOTICE 'Query successful';
	
	
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_shift_dql',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_locationid,
            p_updateby,
            p_action
        );
        
        RAISE NOTICE 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_shift_dql(p_page_number integer, p_items_per_page integer, p_id integer, p_keyword text, p_locationid integer, p_userlocation integer, p_updateby text, p_role integer, p_action text) OWNER TO postgres;

--
-- TOC entry 396 (class 1255 OID 27732)
-- Name: fn_shift_type_dml(integer, text, text, integer, integer, integer, text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_shift_type_dml(OUT "Stat" integer, p_id integer DEFAULT NULL::integer, p_shifttype text DEFAULT NULL::text, p_note text DEFAULT NULL::text, p_flag integer DEFAULT 1, p_locationid integer DEFAULT NULL::integer, p_userlocation integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_role integer DEFAULT 0, p_action text DEFAULT 'I'::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF COALESCE(p_action, '') = '' OR COALESCE(p_locationid,0) < 1 OR COALESCE(p_updateby,'') = '' THEN
        "Stat" := 400;
		RAISE EXCEPTION 'Action, Updateby or LocationID could not be null';
    END IF;
	
    IF COALESCE(p_action,'') = 'I' THEN
		IF COALESCE(p_shifttype,'') = '' THEN
			"Stat" := 400;
			RAISE EXCEPTION 'ShiftType could not be null';
		END IF;
	
        INSERT INTO tblshifttype
        (
			"ShiftType",
			"Note",
			"Flag",
			"LocationID",
			"Updateby"
        ) 
        VALUES 
        (
            p_shifttype,
			p_note,
			p_flag,
			p_locationid,
			p_updateby
        );

        "Stat" := 200;
        RAISE NOTICE 'Insert successful';
        
    ELSIF COALESCE(p_action,'') = 'U' THEN
        IF COALESCE(p_id,0) < 1 THEN
			"Stat" := 400;
            RAISE EXCEPTION 'Update ID could not be null';
        END IF;
    
        UPDATE tblshifttype SET
			"ShiftType" = COALESCE(p_shifttype, "ShiftType"),
			"Note" = COALESCE(p_note, "Note"),
			"Flag" = COALESCE(p_flag, "Flag"),
			"LocationID" = COALESCE(p_locationid, "LocationID"),
			"Updateby" = COALESCE(p_updateby, "Updateby"),
            "Updated_at" = NOW()
        WHERE "ID" = p_id
				AND "Flag" IN(0,1)
					  AND (
							p_role = 2 OR
							(p_role != 2 AND "LocationID" = p_userlocation)
						  );
        
        "Stat" := 200;
        RAISE NOTICE 'Update successful';
		
	ELSIF COALESCE(p_action,'') = 'D' THEN
		IF COALESCE(p_id,0) < 1 THEN
			"Stat" := 400;
            RAISE EXCEPTION 'Update ID could not be null';
        END IF;
		
		UPDATE tblshifttype SET "Flag" = 2,"Updated_at" = NOW() WHERE "ID" = p_id
					  AND (
							p_role = 2 OR
							(p_role != 2 AND "LocationID" = p_userlocation)
						  );
		
		"Stat" := 200;
        RAISE NOTICE 'Delete successful';
	ELSIF COALESCE(p_action,'') = 'F' THEN
		IF COALESCE(p_id,0) < 1 THEN
		"Stat" := 400;
		RAISE EXCEPTION 'Change status ID could not be null';
		END IF;
		
		UPDATE tblshifttype SET 
				"Flag" = COALESCE(p_flag, "Flag"),
				"Updateby" = COALESCE(p_updateby, "Updateby"),
				"Updated_at" = NOW() 
			WHERE "ID" = p_id
					 AND "Flag" IN (0,1)
					  AND (
							p_role = 2 OR
							(p_role != 2 AND "LocationID" = p_userlocation)
						  );
		
		"Stat" := 200;
        RAISE NOTICE 'Change flag successful';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_shift_type_dml',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_userlocation,
            p_updateby,
            p_action
        );
        
        "Stat" := 400;
        RAISE EXCEPTION 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_shift_type_dml(OUT "Stat" integer, p_id integer, p_shifttype text, p_note text, p_flag integer, p_locationid integer, p_userlocation integer, p_updateby text, p_role integer, p_action text) OWNER TO postgres;

--
-- TOC entry 391 (class 1255 OID 27731)
-- Name: fn_shift_type_dql(integer, integer, integer, integer, integer, text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_shift_type_dql(p_page_number integer DEFAULT 1, p_items_per_page integer DEFAULT 15, p_id integer DEFAULT NULL::integer, p_locationid integer DEFAULT NULL::integer, p_userlocation integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_role integer DEFAULT 0, p_action text DEFAULT 'ALL'::text) RETURNS TABLE("ID" integer, "ShiftType" text, "LocationID" integer, "Location" text, "Note" text, "Flag" text, "Updateby" text, "Created_at" text, "Updated_at" text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF COALESCE(UPPER(p_action),'') = 'ONE' THEN
		RETURN QUERY
			SELECT 
				a."ID",a."ShiftType",b."ID" AS "LocationID", b."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblshifttype a
				JOIN tbllocation b ON a."LocationID" = b."ID"
			WHERE a."Flag" = 1
					  AND (
							p_role = 2 OR
							(p_role != 2 AND a."LocationID" = p_userlocation)
						  )
				AND a."ID" = p_id;
			
    ELSE
		RETURN QUERY
			SELECT 
				a."ID",a."ShiftType",b."ID" AS "LocationID", b."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblshifttype a
				JOIN tbllocation b ON a."LocationID" = b."ID"
			WHERE a."Flag" = 1
					  AND (
							p_role = 2 OR
							(p_role != 2 AND a."LocationID" = p_userlocation)
						  )
				ORDER BY a."ID" DESC
				OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
    END IF;
	
    RAISE NOTICE 'Query successful';
	
	
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_shift_type_dql',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_userlocation,
            p_updateby,
            p_action
        );
        
        RAISE NOTICE 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_shift_type_dql(p_page_number integer, p_items_per_page integer, p_id integer, p_locationid integer, p_userlocation integer, p_updateby text, p_role integer, p_action text) OWNER TO postgres;

--
-- TOC entry 363 (class 1255 OID 19273)
-- Name: fn_supplier_detail_dml(integer, text, text, text, character, integer, integer, character, character, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_supplier_detail_dml(OUT "Stat" integer, p_id integer DEFAULT NULL::integer, p_contactid text DEFAULT NULL::text, p_docname text DEFAULT NULL::text, p_doctype text DEFAULT NULL::text, p_note character DEFAULT NULL::bpchar, p_flag integer DEFAULT 1, p_locationid integer DEFAULT NULL::integer, p_updateby character DEFAULT NULL::bpchar, p_action character DEFAULT NULL::bpchar, p_role integer DEFAULT 0) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
	
    IF COALESCE(p_contactid,'') = '' OR COALESCE(p_docname, '') = '' OR COALESCE(p_locationid, '') = '' OR COALESCE(p_action, '') = '' THEN
        "Stat" := 400;
		RAISE EXCEPTION 'ContactID,DocName, Location or Action could not be null';
    END IF;
    
    IF COALESCE(p_action,'') = 'I' THEN
        INSERT INTO tblsupplierdetail
        (
			"ContactID",
			"DocName",
			"DocType",
			"Note",
			"Flag",
			"LocationID",
			"Updateby"
        ) 
        VALUES 
        (
			p_contactid,
			p_docname,
			p_doctype,
			p_note,
			p_flag,
			p_locationid,
			p_updateby
        );

        "Stat" := 200;
        RAISE NOTICE 'Insert successful';
        
    ELSIF COALESCE(p_action,'') = 'U' THEN
        IF p_id = 0  OR COALESCE(p_id,'') ='' THEN
			"Stat" := 400;
            RAISE EXCEPTION 'Update ID could not be null';
        END IF;
    
        UPDATE tblsupplierdetail SET
			"ContactID" = COALESCE(p_contactid, "ContactID"),
			"DocName" = COALESCE(p_docname, "DocName"),
			"DocType" = COALESCE(p_doctype, "DocType"),
			"Note" = COALESCE(p_note, "Note"),
			"Flag" = COALESCE(p_flag, "Flag"),
			"LocationID" = COALESCE(p_locationid, "LocationID"),
			"Updateby" = COALESCE(p_updateby, "Updateby"),
            "Updated_at" = NOW()
        WHERE "ID" = p_id 
			AND "LocationID" = p_locationid;
        
        "Stat" := 200;
        RAISE NOTICE 'Update successful';
		
	ELSIF COALESCE(p_action,'') = 'D' THEN
        IF p_id = 0 OR COALESCE(p_id,'') ='' THEN
            "Stat" := 400;
			RAISE EXCEPTION 'Delete ID could not be null';
        END IF;
		
		UPDATE tblsupplierdetail SET "Flag" = 2,"Updated_at" = NOW() WHERE "ID" = p_id;
		
		"Stat" := 200;
        RAISE NOTICE 'Delete successful';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_supplier_detail_dml',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_locationid,
            p_updateby,
            p_action
        );
        
        "Stat" := 400;
        RAISE EXCEPTION 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_supplier_detail_dml(OUT "Stat" integer, p_id integer, p_contactid text, p_docname text, p_doctype text, p_note character, p_flag integer, p_locationid integer, p_updateby character, p_action character, p_role integer) OWNER TO postgres;

--
-- TOC entry 372 (class 1255 OID 19290)
-- Name: fn_supplier_detail_dql(integer, integer, integer, text, integer, text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_supplier_detail_dql(p_page_number integer DEFAULT 1, p_items_per_page integer DEFAULT 15, p_id integer DEFAULT NULL::integer, p_keyword text DEFAULT NULL::text, p_locationid integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_role integer DEFAULT 0, p_action text DEFAULT 'ALL'::text) RETURNS TABLE("ID" integer, "SupplierID" integer, "ContactID" text, "BusinessName" text, "DocName" text, "DocType" text, "Note" text, "Flag" text, "LocationID" integer, "Location" text, "Updateby" text, "Created_at" text, "Updated_at" text)
    LANGUAGE plpgsql
    AS $$
BEGIN
	---User permission -> get only user location
	IF p_role != 2 THEN
		p_action := 'ONE';
	END IF;
    
    IF COALESCE(UPPER(p_action),'') = 'ALL' THEN
		RETURN QUERY
			SELECT 
				a."ID",b."ID" AS "SupplierID",a."ContactID",b."BusinessName",a."DocName",a."DocType",
				c."ID" AS "LocationID", c."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblsupplierdetail a
				JOIN tblsupplier b ON a."ContactID" = b."ContactID"
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
				AND a."LocationID" = p_locationid
			ORDER BY a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
			
			
    ELSIF COALESCE(UPPER(p_action),'') = 'ONE' THEN
		RETURN QUERY
			SELECT 
				a."ID",b."ID" AS "SupplierID",a."ContactID",b."BusinessName",a."DocName",a."DocType",
				c."ID" AS "LocationID", c."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblsupplierdetail a
				JOIN tblsupplier b ON a."ContactID" = b."ContactID"
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
				AND a."LocationID" = p_locationid
				AND a."ID" = p_id;
	ELSE
		RETURN QUERY
			SELECT 
				a."ID",b."ID" AS "SupplierID",a."ContactID",b."BusinessName",a."DocName",a."DocType",
				c."ID" AS "LocationID", c."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblsupplierdetail a
				JOIN tblsupplier b ON a."ContactID" = b."ContactID"
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
				AND a."LocationID" = p_locationid
				AND (
						(a."ContactID" LIKE p_keyword OR p_keyword IS NULL)
					 OR (b."BusinessName" LIKE p_keyword OR p_keyword IS NULL)
					 OR (b."ID" LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."DocName" LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."DocType" LIKE p_keyword OR p_keyword IS NULL)
					 OR (c."Location" LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."Updateby" LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."Flag" LIKE p_keyword OR p_keyword IS NULL)
				)
			ORDER BY a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
    END IF;
	
    RAISE NOTICE 'Query successful';
	
	
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_supplier_detail_dql',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_locationid,
            p_updateby,
            p_action
        );
        
        RAISE NOTICE 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_supplier_detail_dql(p_page_number integer, p_items_per_page integer, p_id integer, p_keyword text, p_locationid integer, p_updateby text, p_role integer, p_action text) OWNER TO postgres;

--
-- TOC entry 379 (class 1255 OID 19314)
-- Name: fn_supplier_dml(integer, text, text, text, integer, text, text, text, text, text, text, text, text, text, double precision, integer, text, text, text, text, text, text, text, text, integer, integer, text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_supplier_dml(OUT "Stat" integer, p_id integer DEFAULT NULL::integer, p_computerip text DEFAULT NULL::text, p_contacttype text DEFAULT NULL::text, p_businessname text DEFAULT NULL::text, p_title integer DEFAULT 4, p_firstname text DEFAULT NULL::text, p_middlename text DEFAULT NULL::text, p_lastname text DEFAULT NULL::text, p_mobile text DEFAULT NULL::text, p_altmobile text DEFAULT NULL::text, p_email text DEFAULT NULL::text, p_hotline text DEFAULT NULL::text, p_birthday text DEFAULT NULL::text, p_taxnumber text DEFAULT NULL::text, p_openbalance double precision DEFAULT NULL::double precision, p_paytermid integer DEFAULT NULL::integer, p_pobox text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_state text DEFAULT NULL::text, p_province text DEFAULT NULL::text, p_country text DEFAULT NULL::text, p_zipcode text DEFAULT NULL::text, p_shippingaddress text DEFAULT NULL::text, p_note text DEFAULT NULL::text, p_flag integer DEFAULT 1, p_locationid integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_action text DEFAULT NULL::text, p_role integer DEFAULT 0) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
	
    IF COALESCE(p_firstname,'') = '' OR COALESCE(p_locationid, 0) < 1 OR COALESCE(p_action, '') = '' THEN
        "Stat" := 400;
		RAISE EXCEPTION 'Name, Location or Action could not be null';
    END IF;
    
    IF COALESCE(p_action,'') = 'I' THEN
        INSERT INTO tblsupplier
        (
			"ContactID",
			"ComputerIP",
			"ContactType",
			"BusinessName",
			"Title",
			"FirstName",
			"MiddleName",
			"LastName",
			"Mobile",
			"AltMobile",
			"EMail",
			"HotLine",
			"BirthDay",
			"TaxNumber",
			"OpenBalance",
			"PayTermID",
			"POBox",
			"City",
			"State",
			"Province",
			"Country",
			"ZIPCode",
			"ShippingAddress",
			"Note",
			"Flag",
			"LocationID",
			"Updateby"
        ) 
        VALUES 
        (
			fun_auto_id('tblsupplier','SP',9),
			p_computerip,
			p_contacttype,
			p_businessname,
			p_title,
			p_firstname,
			p_middlename,
			p_lastname,
			p_mobile,
			p_altmobile,
			p_email,
			p_hotline,
			p_birthday::date,
			p_taxnumber,
			p_openbalance,
			p_paytermid,
			p_pobox,
			p_city,
			p_state,
			p_province,
			p_country,
			p_zipcode,
			p_shippingaddress,
			p_note,
			p_flag,
			p_locationid,
			p_updateby
        );

        "Stat" := 200;
        RAISE NOTICE 'Insert successful';
        
    ELSIF COALESCE(p_action,'') = 'U' THEN
        IF COALESCE(p_id, 0) < 1 THEN
			"Stat" := 400;
            RAISE EXCEPTION 'Update ID could not be null';
        END IF;
    
        UPDATE tblsupplier SET
			"ComputerIP" = COALESCE(p_computerip, "ComputerIP"),
			"ContactType" = COALESCE(p_contacttype, "ContactType"),
			"BusinessName" = COALESCE(p_businessname, "BusinessName"),
			"Title" = COALESCE(p_title, "Title"),
			"FirstName" = COALESCE(p_firstname, "FirstName"),
			"MiddleName" = COALESCE(p_middlename, "MiddleName"),
			"LastName" = COALESCE(p_lastname, "LastName"),
			"Mobile" = COALESCE(p_mobile, "Mobile"),
			"AltMobile" = COALESCE(p_altmobile, "AltMobile"),
			"EMail" = COALESCE(p_email, "EMail"),
			"HotLine" = COALESCE(p_hotline, "HotLine"),
			"BirthDay" = COALESCE(p_birthday::date, "BirthDay"),
			"TaxNumber" = COALESCE(p_taxnumber, "TaxNumber"),
			"OpenBalance" = COALESCE(p_openbalance, "OpenBalance"),
			"PayTermID" = COALESCE(p_pobox, "PayTermID"),
			"POBox" = COALESCE(p_note, "POBox"),
			"City" = COALESCE(p_city, "City"),
			"State" = COALESCE(p_state, "State"),
			"Province" = COALESCE(p_province, "Province"),
			"Country" = COALESCE(p_country, "Country"),
			"ZIPCode" = COALESCE(p_zipcode, "ZIPCode"),
			"ShippingAddress" = COALESCE(p_shippingaddress, "ShippingAddress"),
			"Note" = COALESCE(p_note, "Note"),
			"Flag" = COALESCE(p_flag, "Flag"),
			"LocationID" = COALESCE(p_locationid, "LocationID"),
			"Updateby" = COALESCE(p_updateby, "Updateby"),
            "Updated_at" = NOW()
        WHERE "ID" = p_id 
			AND "LocationID" = p_locationid;
        
        "Stat" := 200;
        RAISE NOTICE 'Update successful';
		
	ELSIF COALESCE(p_action,'') = 'D' THEN
        IF COALESCE(p_id,0) < 1 THEN
            "Stat" := 400;
			RAISE EXCEPTION 'Delete ID could not be null';
        END IF;
		
		UPDATE tblsupplier SET "Flag" = 2,"Updated_at" = NOW() WHERE "ID" = p_id;
		
		"Stat" := 200;
        RAISE NOTICE 'Delete successful';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_supplier_dml',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_locationid,
            p_updateby,
            p_action
        );
        
        "Stat" := 400;
        RAISE EXCEPTION 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_supplier_dml(OUT "Stat" integer, p_id integer, p_computerip text, p_contacttype text, p_businessname text, p_title integer, p_firstname text, p_middlename text, p_lastname text, p_mobile text, p_altmobile text, p_email text, p_hotline text, p_birthday text, p_taxnumber text, p_openbalance double precision, p_paytermid integer, p_pobox text, p_city text, p_state text, p_province text, p_country text, p_zipcode text, p_shippingaddress text, p_note text, p_flag integer, p_locationid integer, p_updateby text, p_action text, p_role integer) OWNER TO postgres;

--
-- TOC entry 373 (class 1255 OID 19291)
-- Name: fn_supplier_dql(integer, integer, integer, text, integer, text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_supplier_dql(p_page_number integer DEFAULT 1, p_items_per_page integer DEFAULT 15, p_id integer DEFAULT NULL::integer, p_keyword text DEFAULT NULL::text, p_locationid integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_role integer DEFAULT 0, p_action text DEFAULT 'ALL'::text) RETURNS TABLE("ID" integer, "ContactID" text, "ComputerIP" text, "ContactType" text, "BusinessName" text, "Title" text, "FirstName" text, "MiddleName" text, "LastName" text, "Mobile" text, "AltMobile" text, "EMail" text, "HotLine" text, "BirthDay" text, "TaxNumber" text, "OpenBalance" double precision, "PayTermID" integer, "PayTerm" text, "POBox" text, "City" text, "State" text, "Province" text, "Country" text, "ZIPCode" text, "ShippingAddress" text, "Note" text, "Flag" text, "LocationID" integer, "Location" text, "Updateby" text, "Created_at" text, "Updated_at" text)
    LANGUAGE plpgsql
    AS $$
BEGIN
	---User permission -> get only user location
	IF p_role != 2 THEN
		p_action := 'ONE';
	END IF;
    
    IF COALESCE(UPPER(p_action),'') = 'ALL' THEN
		RETURN QUERY
			SELECT 
				a."ID",a."ContactID",a."ComputerIP",
				CASE WHEN a."ContactType" = 1 THEN 'Individual' ELSE 'Business' END AS "ContactType",
				a."BusinessName",
				CASE WHEN a."Title" = 1 THEN 'Mr.' WHEN a."Title" = 2 THEN 'Mrs.' WHEN a."Title" = 3 THEN 'Miss' ELSE 'Other' END AS "Title",
				a."FirstName",a."MiddleName",a."LastName",a."Mobile",a."AltMobile",a."EMail",a."HotLine",
				TO_CHAR(a."BirthDay",'DD/MM/YYYY') AS "BirthDay",a."TaxNumber",a."OpenBalance",
				c."ID" AS "PaytermID", c."PayTerms" AS "PayTerm",
				a."POBox",a."City",a."State",a."Province",a."Country",a."ZIPCode",a."ShippingAddress"
				,b."ID" AS "LocationID", b."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblsupplier a
				JOIN tbllocation b ON a."LocationID" = b."ID"
				LEFT JOIN tblpayterm c ON a."PayTermID" = c."ID"
			WHERE a."Flag" IN (0,1)
				AND a."LocationID" = p_locationid
			ORDER BY a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
			
			
    ELSIF COALESCE(UPPER(p_action),'') = 'ONE' THEN
		RETURN QUERY
			SELECT 
				a."ID",a."ContactID",a."ComputerIP",
				CASE WHEN a."ContactType" = 1 THEN 'Individual' ELSE 'Business' END AS "ContactType",
				a."BusinessName",
				CASE WHEN a."Title" = 1 THEN 'Mr.' WHEN a."Title" = 2 THEN 'Mrs.' WHEN a."Title" = 3 THEN 'Miss' ELSE 'Other' END AS "Title",
				a."FirstName",a."MiddleName",a."LastName",a."Mobile",a."AltMobile",a."EMail",a."HotLine",
				TO_CHAR(a."BirthDay",'DD/MM/YYYY') AS "BirthDay",a."TaxNumber",a."OpenBalance",
				c."ID" AS "PaytermID", c."PayTerms" AS "PayTerm",
				a."POBox",a."City",a."State",a."Province",a."Country",a."ZIPCode",a."ShippingAddress"
				,b."ID" AS "LocationID", b."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblsupplier a
				JOIN tbllocation b ON a."LocationID" = b."ID"
				LEFT JOIN tblpayterm c ON a."PayTermID" = c."ID"
			WHERE a."Flag" IN (0,1)
				AND a."LocationID" = p_locationid
				AND a."ID" = p_id;
	ELSE
		RETURN QUERY
			SELECT 
				a."ID",a."ContactID",a."ComputerIP",
				CASE WHEN a."ContactType" = 1 THEN 'Individual' ELSE 'Business' END AS "ContactType",
				a."BusinessName",
				CASE WHEN a."Title" = 1 THEN 'Mr.' WHEN a."Title" = 2 THEN 'Mrs.' WHEN a."Title" = 3 THEN 'Miss' ELSE 'Other' END AS "Title",
				a."FirstName",a."MiddleName",a."LastName",a."Mobile",a."AltMobile",a."EMail",a."HotLine",
				TO_CHAR(a."BirthDay",'DD/MM/YYYY') AS "BirthDay",a."TaxNumber",a."OpenBalance",
				c."ID" AS "PaytermID", c."PayTerms" AS "PayTerm",
				a."POBox",a."City",a."State",a."Province",a."Country",a."ZIPCode",a."ShippingAddress"
				,b."ID" AS "LocationID", b."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tblsupplier a
				JOIN tbllocation b ON a."LocationID" = b."ID"
				LEFT JOIN tblpayterm c ON a."PayTermID" = c."ID"
			WHERE a."Flag" IN (0,1)
				AND a."LocationID" = p_locationid
				AND (
						(a."ContactID" LIKE p_keyword OR p_keyword IS NULL)
					 OR (CASE WHEN a."ContactType" = 1 THEN 'Individual' ELSE 'Business' END LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."BusinessName" LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."FirstName" LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."LastName" LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."EMail" LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."POBox" LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."City" LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."Province" LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."Country" LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."ZIPCode" LIKE p_keyword OR p_keyword IS NULL)
					 OR (c."Location" LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."Updateby" LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."Flag" LIKE p_keyword OR p_keyword IS NULL)
				)
			ORDER BY a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
    END IF;
	
    RAISE NOTICE 'Query successful';
	
	
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_supplier_dql',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_locationid,
            p_updateby,
            p_action
        );
        
        RAISE NOTICE 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_supplier_dql(p_page_number integer, p_items_per_page integer, p_id integer, p_keyword text, p_locationid integer, p_updateby text, p_role integer, p_action text) OWNER TO postgres;

--
-- TOC entry 395 (class 1255 OID 27800)
-- Name: fn_tax_dml(integer, text, double precision, text, integer, integer, integer, text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_tax_dml(OUT "Stat" integer, p_id integer DEFAULT NULL::integer, p_taxname text DEFAULT NULL::text, p_taxpercentage double precision DEFAULT NULL::double precision, p_note text DEFAULT NULL::text, p_flag integer DEFAULT 1, p_locationid integer DEFAULT NULL::integer, p_userlocation integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_action text DEFAULT NULL::text, p_role integer DEFAULT 0) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
	
    IF COALESCE(p_locationid, 0) < 1 OR COALESCE(p_action, '') = '' THEN
        "Stat" := 400;
		RAISE EXCEPTION 'LocationID or Action could not be null';
    END IF;
    
    IF COALESCE(p_action,'') = 'I' THEN
	
		IF COALESCE(p_taxname,'') = '' THEN
			"Stat" := 400;
			RAISE EXCEPTION 'Rate, CurrencyID or Action could not be null';
		END IF;
	
        INSERT INTO tbltax
        (
			"TaxName",
			"TaxPercentage",
			"Note",
			"Flag",
			"LocationID",
			"Updateby"
        ) 
        VALUES 
        (
			p_taxname,
			p_taxpercentage,
			p_note,
			p_flag,
			p_locationid,
			p_updateby
        );

        "Stat" := 200;
        RAISE NOTICE 'Insert successful';
        
    ELSIF COALESCE(p_action,'') = 'U' THEN
        IF COALESCE(p_id, 0) < 1 THEN
			"Stat" := 400;
            RAISE EXCEPTION 'Update ID could not be null';
        END IF;
    
        UPDATE tbltax SET
			"TaxName" = COALESCE(p_taxname, "TaxName"),
			"TaxPercentage" = COALESCE(p_taxpercentage, "TaxPercentage"),
			"Note" = COALESCE(p_note, "Note"),
			"Flag" = COALESCE(p_flag, "Flag"),
			"LocationID" = COALESCE(p_locationid, "LocationID"),
			"Updateby" = COALESCE(p_updateby, "Updateby"),
            "Updated_at" = NOW()
        WHERE "ID" = p_id 
				AND "Flag" IN (0,1)
				  AND (
						p_role = 2 OR
						(p_role != 2 AND "LocationID" = p_userlocation)
					  );
        
        "Stat" := 200;
        RAISE NOTICE 'Update successful';
		
	ELSIF COALESCE(p_action,'') = 'D' THEN
	
		IF COALESCE(p_id, 0) < 1 THEN
			"Stat" := 400;
			RAISE EXCEPTION 'Delete ID could not be null';
        END IF;
		
		UPDATE tbltax SET "Flag" = 2,"Updated_at" = NOW() WHERE "ID" = p_id
					  AND (
							p_role = 2 OR
							(p_role != 2 AND "LocationID" = p_userlocation)
						  );
		
		"Stat" := 200;
        RAISE NOTICE 'Delete successful';
		
    ELSIF COALESCE(p_action,'') = 'F' THEN
		IF COALESCE(p_id,0) < 1 THEN
		"Stat" := 400;
		RAISE EXCEPTION 'Change status ID could not be null';
		END IF;
		
		UPDATE tbltax SET 
				"Flag" = COALESCE(p_flag, "Flag"),
				"Updateby" = COALESCE(p_updateby, "Updateby"),
				"Updated_at" = NOW() 
			WHERE "ID" = p_id
					 AND "Flag" IN (0,1)
					  AND (
							p_role = 2 OR
							(p_role != 2 AND "LocationID" = p_userlocation)
						  );
		
		"Stat" := 200;
        RAISE NOTICE 'Change flag successful';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_tax_dml',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_userlocation,
            p_updateby,
            p_action
        );
        
        "Stat" := 400;
        RAISE EXCEPTION 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_tax_dml(OUT "Stat" integer, p_id integer, p_taxname text, p_taxpercentage double precision, p_note text, p_flag integer, p_locationid integer, p_userlocation integer, p_updateby text, p_action text, p_role integer) OWNER TO postgres;

--
-- TOC entry 394 (class 1255 OID 27798)
-- Name: fn_tax_dql(integer, integer, integer, text, integer, integer, text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_tax_dql(p_page_number integer DEFAULT 1, p_items_per_page integer DEFAULT 15, p_id integer DEFAULT NULL::integer, p_keyword text DEFAULT NULL::text, p_locationid integer DEFAULT NULL::integer, p_userlocation integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_role integer DEFAULT 0, p_action text DEFAULT 'ALL'::text) RETURNS TABLE("ID" integer, "TaxName" text, "TaxPercentage" double precision, "LocationID" integer, "Location" text, "Note" text, "Flag" text, "Updateby" text, "Created_at" text, "Updated_at" text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    
    IF COALESCE(UPPER(p_action),'') = 'ALL' THEN
		RETURN QUERY
			SELECT 
				a."ID",a."TaxName",a."TaxPercentage",c."ID" AS "LocationID", c."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tbltax a
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
					  AND (
							p_role = 2 OR
							(p_role != 2 AND a."LocationID" = p_userlocation)
						  )
			ORDER BY a."Flag" DESC, a."ID" DESC;
			
    ELSIF COALESCE(UPPER(p_action),'') = 'ONE' THEN
		RETURN QUERY
			SELECT 
				a."ID",a."TaxName",a."TaxPercentage",c."ID" AS "LocationID", c."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tbltax a
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
					  AND (
							p_role = 2 OR
							(p_role != 2 AND a."LocationID" = p_userlocation)
						  )
				AND a."ID" = p_id;
				
	ELSIF COALESCE(UPPER(p_action),'') = 'SEARCH' THEN
		p_keyword := '%'|| p_keyword ||'%';
		
		RETURN QUERY
			SELECT 
				a."ID",a."TaxName",a."TaxPercentage",c."ID" AS "LocationID", c."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tbltax a
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
					  AND (
							p_role = 2 OR
							(p_role != 2 AND a."LocationID" = p_userlocation)
						  )
				AND (
						(a."TaxName" ILIKE p_keyword OR p_keyword IS NULL)
					 OR (a."TaxPercentage"::TEXT ILIKE p_keyword OR p_keyword IS NULL)
					 OR (c."Location" ILIKE p_keyword OR p_keyword IS NULL)
					 OR (a."Updateby" ILIKE p_keyword OR p_keyword IS NULL)
					 OR (a."Flag"::TEXT ILIKE p_keyword OR p_keyword IS NULL)
					 OR (CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END ILIKE p_keyword OR p_keyword IS NULL)
				)
			ORDER BY a."Flag" DESC, a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
	ELSE
		RETURN QUERY
			SELECT 
				a."ID",a."TaxName",a."TaxPercentage",c."ID" AS "LocationID", c."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tbltax a
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
					  AND (
							p_role = 2 OR
							(p_role != 2 AND a."LocationID" = p_userlocation)
						  )
			ORDER BY a."Flag" DESC, a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
    END IF;
	
    RAISE NOTICE 'Query successful';
	
	
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_tax_dql',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_userlocation,
            p_updateby,
            p_action
        );
        
        RAISE NOTICE 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_tax_dql(p_page_number integer, p_items_per_page integer, p_id integer, p_keyword text, p_locationid integer, p_userlocation integer, p_updateby text, p_role integer, p_action text) OWNER TO postgres;

--
-- TOC entry 393 (class 1255 OID 27796)
-- Name: fn_taxtype_dql(integer, integer, integer, text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_taxtype_dql(p_id integer DEFAULT NULL::integer, p_locationid integer DEFAULT NULL::integer, p_userlocation integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_role integer DEFAULT 0, p_action text DEFAULT 'ONE'::text) RETURNS TABLE("ID" integer, "TaxType" text, "LocationID" integer, "Location" text, "Note" text, "Flag" text, "Updateby" text, "Created_at" text, "Updated_at" text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    
    IF COALESCE(UPPER(p_action),'') = 'ONE' THEN
		RETURN QUERY
			SELECT 
				a."ID",a."TaxType",c."ID" AS "LocationID", c."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tbltaxtype a
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" =1
					  AND (
							p_role = 2 OR
							(p_role != 2 AND a."LocationID" = p_userlocation)
						  )
				AND a."ID" = p_id
			ORDER BY a."TaxType";
			
	ELSE
		RETURN QUERY
			SELECT 
				a."ID",a."TaxType",c."ID" AS "LocationID", c."Location",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tbltaxtype a
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" =1
					  AND (
							p_role = 2 OR
							(p_role != 2 AND a."LocationID" = p_userlocation)
						  )
			ORDER BY a."TaxType";
    END IF;
	
    RAISE NOTICE 'Query successful';
	
	
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_taxtype_dql',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_userlocation,
            p_updateby,
            p_action
        );
        
        RAISE NOTICE 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_taxtype_dql(p_id integer, p_locationid integer, p_userlocation integer, p_updateby text, p_role integer, p_action text) OWNER TO postgres;

--
-- TOC entry 382 (class 1255 OID 19318)
-- Name: fn_user_activity_dml(integer, text, text, text, text, integer, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_user_activity_dml(OUT "Stat" integer, p_userid integer DEFAULT NULL::integer, p_activity text DEFAULT NULL::text, p_function text DEFAULT NULL::text, p_note text DEFAULT NULL::text, p_date text DEFAULT NULL::text, p_locationid integer DEFAULT NULL::integer, p_role integer DEFAULT 0, p_action text DEFAULT 'ONE'::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
	
	IF COALESCE(p_userid,0) < 1 OR COALESCE(p_action, '') = '' THEN
        "Stat" := 400;
		RAISE EXCEPTION 'UserID, Action could not be null';
    END IF;
	
	INSERT INTO tbluseractivity("Date","Action","UserId","Function","Note")
		VALUES(p_date::timestamp,p_activity,p_userid,p_function,p_note);
	
    RAISE NOTICE 'Query successful';
	
	
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_user_activity_dml',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            COALESCE(p_locationid,0),
            COALESCE(p_updateby,''),
            p_action
        );
        
       "Stat" := 400;
        RAISE EXCEPTION 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_user_activity_dml(OUT "Stat" integer, p_userid integer, p_activity text, p_function text, p_note text, p_date text, p_locationid integer, p_role integer, p_action text) OWNER TO postgres;

--
-- TOC entry 381 (class 1255 OID 19317)
-- Name: fn_user_activity_dql(integer, integer, integer, integer, text, text, integer, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_user_activity_dql(p_page_number integer DEFAULT 1, p_items_per_page integer DEFAULT 15, p_id integer DEFAULT NULL::integer, p_userid integer DEFAULT NULL::integer, p_keyword text DEFAULT NULL::text, p_updateby text DEFAULT NULL::text, p_locationid integer DEFAULT NULL::integer, p_role integer DEFAULT 0, p_action text DEFAULT 'ONE'::text) RETURNS TABLE("ID" integer, "EmpID" integer, "UserName" text, "Role" text, "Status" text, "Function" text, "Updated_at" text)
    LANGUAGE plpgsql
    AS $$
BEGIN
	---User permission -> get only user location
	IF p_role != 2 THEN
		p_action := 'ONE';
	END IF;
    
    IF COALESCE(UPPER(p_action),'') = 'ONE' THEN
		RETURN QUERY
			SELECT 
				a."ID",b."EmpID",b."UserName",
				CASE WHEN b."Role" = 2 THEN 'SuperAdmin' WHEN b."Role" = 1 THEN 'Administrator' ELSE 'User' END AS "Role",
				CASE WHEN b."Status" = 0 THEN 'Normal' ELSE 'Locked' END AS "Status",
				a."Function",a."Action",
				TO_CHAR(a."Date",'DD/MM/YYYY HH24:MI:SS') As "Created_at"
			FROM tbluseractivity a
				JOIN tbluser b ON a."UserID" = b."ID"
			WHERE 1=1
				AND a."UserID" = p_userid
			ORDER BY a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
	ELSE
		RETURN QUERY
			SELECT 
				a."ID",b."EmpID",b."UserName",
				CASE WHEN b."Role" = 2 THEN 'SuperAdmin' WHEN b."Role" = 1 THEN 'Administrator' ELSE 'User' END AS "Role",
				CASE WHEN b."Status" = 0 THEN 'Normal' ELSE 'Locked' END AS "Status",
				a."Function",a."Action",
				TO_CHAR(a."Date",'DD/MM/YYYY HH24:MI:SS') As "Created_at"
			FROM tbluseractivity a
				JOIN tbluser b ON a."UserID" = b."ID"
			WHERE 1=1
				AND (
							(a."UserID" LIKE p_keyword OR p_keyword IS NULL)
						OR (a."UserName" LIKE p_keyword OR p_keyword IS NULL)
						OR (b."EmpID" LIKE p_keyword OR p_keyword IS NULL)
						OR (a."Function" LIKE p_keyword OR p_keyword IS NULL)
						OR (a."Action" LIKE p_keyword OR p_keyword IS NULL)
					)
			ORDER BY a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
    END IF;
	
    RAISE NOTICE 'Query successful';
	
	
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_user_activity_dql',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_locationid,
            p_updateby,
            p_action
        );
        
        RAISE NOTICE 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_user_activity_dql(p_page_number integer, p_items_per_page integer, p_id integer, p_userid integer, p_keyword text, p_updateby text, p_locationid integer, p_role integer, p_action text) OWNER TO postgres;

--
-- TOC entry 380 (class 1255 OID 19316)
-- Name: fn_user_dml(integer, integer, text, text, integer, integer, integer, integer, text, integer, text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_user_dml(OUT "Stat" integer, p_id integer DEFAULT NULL::integer, p_empid integer DEFAULT NULL::integer, p_username text DEFAULT NULL::text, p_password text DEFAULT NULL::text, p_permission integer DEFAULT 0, p_status integer DEFAULT 1, p_retrycount integer DEFAULT 0, p_flag integer DEFAULT 1, p_note text DEFAULT NULL::text, p_locationid integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_action text DEFAULT NULL::text, p_role integer DEFAULT 0) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF COALESCE(p_empid,0) < 1 OR COALESCE(p_locationid, 0) < 1  OR COALESCE(p_action, '') = '' THEN
        "Stat" := 400;
		RAISE EXCEPTION 'EmpID, LocationID or Action could not be null';
    END IF;
	
	IF COALESCE(p_username,'') = '' OR COALESCE(p_password, '') = ''  OR COALESCE(p_role, 0) < 0 THEN
        "Stat" := 400;
		RAISE EXCEPTION 'Username, Pass or Role could not be null';
    END IF;
    
    IF COALESCE(p_action,'') = 'I' THEN
        INSERT INTO tbluser
        (
			"EmpID",
			"UserName",
			"Password",
			"Role",
			"Status",
			"RetryCount",
			"Note",
			"Flag",
			"LocationID",
			"Updateby"
        ) 
        VALUES 
        (
			p_empid,
			p_username,
			p_password,
			p_permission,
			p_status,
			p_retrycount,
			p_note,
			p_flag,
			p_locationid,
			p_updateby
        );

        "Stat" := 200;
        RAISE NOTICE 'Insert successful';
        
    ELSIF COALESCE(p_action,'') = 'U' THEN
        IF COALESCE(p_id,0) < 1 THEN
			"Stat" := 400;
            RAISE EXCEPTION 'Update ID could not be null';
        END IF;
    
        UPDATE tbluser SET
			"EmpID" = COALESCE(p_empid, "EmpID"),
			"UserName" = COALESCE(p_username, "UserName"),
			"Password" = COALESCE(p_password, "Password"),
			"Role" = COALESCE(p_permission, "Role"),
			"Status" = COALESCE(p_status, "Status"),
			"RetryCount" = COALESCE(p_retrycount, "RetryCount"),
			"Note" = COALESCE(p_note, "Note"),
			"Flag" = COALESCE(p_flag, "Flag"),
			"LocationID" = COALESCE(p_locationid, "LocationID"),
			"Updateby" = COALESCE(p_updateby, "Updateby"),
            "Updated_at" = NOW()
        WHERE "ID" = p_id 
			AND "LocationID" = p_locationid;
        
        "Stat" := 200;
        RAISE NOTICE 'Update successful';
		
	ELSIF COALESCE(p_action,'') = 'D' THEN
        IF COALESCE(p_id,0) < 1 THEN
            "Stat" := 400;
			RAISE EXCEPTION 'Delete ID could not be null';
        END IF;
		
		UPDATE tbluser SET "Flag" = 2,"Updated_at" = NOW() WHERE "ID" = p_id;
		
		"Stat" := 200;
        RAISE NOTICE 'Delete successful';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_user_dml',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_locationid,
            p_updateby,
            p_action
        );
        
        "Stat" := 400;
        RAISE EXCEPTION 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_user_dml(OUT "Stat" integer, p_id integer, p_empid integer, p_username text, p_password text, p_permission integer, p_status integer, p_retrycount integer, p_flag integer, p_note text, p_locationid integer, p_updateby text, p_action text, p_role integer) OWNER TO postgres;

--
-- TOC entry 374 (class 1255 OID 19296)
-- Name: fn_user_dql(integer, integer, integer, text, integer, text, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_user_dql(p_page_number integer DEFAULT 1, p_items_per_page integer DEFAULT 15, p_id integer DEFAULT NULL::integer, p_keyword text DEFAULT NULL::text, p_locationid integer DEFAULT NULL::integer, p_updateby text DEFAULT NULL::text, p_role integer DEFAULT 0, p_action text DEFAULT 'ALL'::text) RETURNS TABLE("ID" integer, "UserName" text, "EmpID" integer, "Employee" text, "LocationID" integer, "Location" text, "Role" integer, "Status" integer, "RetryCount" integer, "Note" text, "Flag" text, "Updateby" text, "Created_at" text, "Updated_at" text)
    LANGUAGE plpgsql
    AS $$
BEGIN
	---User permission -> get only user location
	IF p_role != 2 THEN
		p_action := 'ONE';
	END IF;
    
    IF COALESCE(UPPER(p_action),'') = 'ALL' THEN
		RETURN QUERY
			SELECT 
				a."ID",a."UserName",b."EmpID",CONCAT(b."FirstName",' ',b."LastName") AS "Employee",
				c."ID" AS "LocationID", c."Location",
				CASE WHEN a."Role" = 2 THEN 'SuperAdmin' WHEN a."Role" = 1 THEN 'Administrator' ELSE 'User' END AS "Role",
				CASE WHEN a."Status" = 0 THEN 'Normal' ELSE 'Locked' END AS "Status",
				a."RetryCount",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tbluser a
				JOIN tblemployee b ON a."EmpID" = b."EmpID"
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
				AND a."LocationID" = p_locationid
			ORDER BY a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
			
    ELSIF COALESCE(UPPER(p_action),'') = 'ONE' THEN
		RETURN QUERY
			SELECT 
				a."ID",a."UserName",b."EmpID",CONCAT(b."FirstName",' ',b."LastName") AS "Employee",
				c."ID" AS "LocationID", c."Location",a."Role",a."Status",
				a."RetryCount",a."Note", a."Flag",a."Updateby", a."Created_at", a."Updated_at"
			FROM tbluser a
				JOIN tblemployee b ON a."EmpID" = b."EmpID"
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
				AND a."LocationID" = p_locationid
				AND a."ID" = p_id;
	ELSE
		RETURN QUERY
			SELECT 
				a."ID",a."UserName",b."EmpID",CONCAT(b."FirstName",' ',b."LastName") AS "Employee",
				c."ID" AS "LocationID", c."Location",
				CASE WHEN a."Role" = 2 THEN 'SuperAdmin' WHEN a."Role" = 1 THEN 'Administrator' ELSE 'User' END AS "Role",
				CASE WHEN a."Status" = 0 THEN 'Normal' ELSE 'Locked' END AS "Status",
				a."RetryCount",a."Note",
				CASE WHEN a."Flag" = 1 THEN 'Active' ELSE 'Inactive' END AS "Flag",
				a."Updateby",
				TO_CHAR(a."Created_at",'DD/MM/YYYY HH24:MI:SS') As "Created_at",
				TO_CHAR(a."Updated_at",'DD/MM/YYYY HH24:MI:SS') As "Updated_at"
			FROM tbluser a
				JOIN tblemployee b ON a."EmpID" = b."EmpID"
				JOIN tbllocation c ON a."LocationID" = c."ID"
			WHERE a."Flag" IN (0,1)
				AND a."LocationID" = p_locationid
				AND (
						(a."UserName" LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."EmpID" LIKE p_keyword OR p_keyword IS NULL)
					 OR (c."Location" LIKE p_keyword OR p_keyword IS NULL)
					 OR (CONCAT(b."FirstName",' ',b."LastName") LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."Updateby" LIKE p_keyword OR p_keyword IS NULL)
					 OR (a."Flag" LIKE p_keyword OR p_keyword IS NULL)
				)
			ORDER BY a."ID" DESC
			OFFSET ((p_page_number - 1) * p_items_per_page) LIMIT p_items_per_page;
    END IF;
	
    RAISE NOTICE 'Query successful';
	
	
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.tblsystemlog
        (
            "FunctionName",
            "ErrCode",
            "ErrMessage",
            "LocationID",
            "Updateby",
            "Action"
        )
        VALUES
        (
            'fn_user_dql',
            SQLSTATE,
            CASE WHEN LENGTH(SQLERRM) > 150 THEN LEFT(SQLERRM, 150) || '...' ELSE SQLERRM END,
            p_locationid,
            p_updateby,
            p_action
        );
        
        RAISE NOTICE 'Something goes wrong! ==> %', SQLERRM;
END;
$$;


ALTER FUNCTION public.fn_user_dql(p_page_number integer, p_items_per_page integer, p_id integer, p_keyword text, p_locationid integer, p_updateby text, p_role integer, p_action text) OWNER TO postgres;

--
-- TOC entry 365 (class 1255 OID 27793)
-- Name: fn_week_days_int(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_week_days_int(p_ref text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
 
DECLARE
    p_day text;
BEGIN
	
	IF p_ref = 'Monday' THEN
		p_day := 1;
	ELSIF p_ref = 'Tuesday' THEN
		p_day := 2;
	ELSIF p_ref = 'Wednesday' THEN
		p_day := 3;
	ELSIF p_ref = 'Thursday' THEN
		p_day := 4;
	ELSIF p_ref = 'Friday' THEN
		p_day := 5;
	ELSIF p_ref = 'Saturday' THEN
		p_day := 6;
	ELSIF p_ref = 'Sunday' THEN
		p_day := 7;
	ELSE
		p_day := 0;
	END IF;
    
    RETURN p_day;
END; 
$$;


ALTER FUNCTION public.fn_week_days_int(p_ref text) OWNER TO postgres;

--
-- TOC entry 366 (class 1255 OID 27791)
-- Name: fn_week_days_text(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_week_days_text(p_ref integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
 
DECLARE
    p_day text;
BEGIN
	
	IF p_ref = 1 THEN
		p_day := 'Monday';
	ELSIF p_ref = 2 THEN
		p_day := 'Tuesday';
	ELSIF p_ref = 3 THEN
		p_day := 'Wednesday';
	ELSIF p_ref = 4 THEN
		p_day := 'Thursday';
	ELSIF p_ref = 5 THEN
		p_day := 'Friday';
	ELSIF p_ref = 6 THEN
		p_day := 'Saturday';
	ELSIF p_ref = 7 THEN
		p_day := 'Sunday';
	ELSE
		p_day := 'Unknown';
	END IF;
    
    RETURN p_day;
END; 
$$;


ALTER FUNCTION public.fn_week_days_text(p_ref integer) OWNER TO postgres;

--
-- TOC entry 364 (class 1255 OID 19297)
-- Name: fun_auto_id(text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fun_auto_id(p_tbname text, p_prefix text, p_len integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
 
DECLARE
    newID text;
    p_char text;
    p_num bigint;
	p_ref character(8);
BEGIN
    -- Construct the dynamic SQL query
	
    EXECUTE 'SELECT COALESCE(MAX("ID"), 0) + 1 FROM ' || p_tbname INTO p_num;
	
	SELECT TO_CHAR(now(),'YYYYMMSS') INTO p_ref;

    p_char := p_prefix;
    
    IF LENGTH(p_num::text) < p_len THEN
        newID := p_char || p_ref || '/' || '1' || LPAD(p_num::text, p_len - 1, '0');
    ELSE 
        newID := p_char || p_ref || '/' || p_num::text;
    END IF; 
    RETURN newID;
END 
$$;


ALTER FUNCTION public.fun_auto_id(p_tbname text, p_prefix text, p_len integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 214 (class 1259 OID 16390)
-- Name: tblNotification; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."tblNotification" (
    "ID" integer NOT NULL,
    "RefNo" text,
    "RefType" integer NOT NULL,
    "NotifyToList" text,
    "NotifyCCList" text,
    "NotifyBCCList" text,
    "Title" integer DEFAULT 4 NOT NULL,
    "Header" text,
    "Body" text,
    "Footer" text,
    "NotifyStatus" integer DEFAULT 0 NOT NULL,
    "LocationID" integer NOT NULL,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public."tblNotification" OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 16399)
-- Name: tblNotification_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblNotification_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblNotification_ID_seq" OWNER TO postgres;

--
-- TOC entry 4539 (class 0 OID 0)
-- Dependencies: 215
-- Name: tblNotification_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblNotification_ID_seq" OWNED BY public."tblNotification"."ID";


--
-- TOC entry 317 (class 1259 OID 19320)
-- Name: tblapproval; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblapproval (
    "ID" integer NOT NULL,
    "ComputerIP" text,
    "RefNo" text,
    "ApproverID" integer,
    "Note" text,
    "LocationID" integer,
    "Flag" integer,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblapproval OWNER TO postgres;

--
-- TOC entry 316 (class 1259 OID 19319)
-- Name: tblapproval_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblapproval_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblapproval_ID_seq" OWNER TO postgres;

--
-- TOC entry 4540 (class 0 OID 0)
-- Dependencies: 316
-- Name: tblapproval_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblapproval_ID_seq" OWNED BY public.tblapproval."ID";


--
-- TOC entry 216 (class 1259 OID 16407)
-- Name: tblbill; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblbill (
    "ID" integer NOT NULL,
    "ComputerIP" text,
    "BillNo" text,
    "CustomerID" integer DEFAULT 0 NOT NULL,
    "LocationID" integer,
    "CounterNo" integer NOT NULL,
    "BillStatus" integer DEFAULT 1 NOT NULL,
    "PaymentStatus" integer DEFAULT 0 NOT NULL,
    "PrintCount" integer DEFAULT 0 NOT NULL,
    "TotalQty" integer,
    "TotalAmount" double precision,
    "DisCountTypeID" integer,
    "TotalDiscount" double precision DEFAULT 0 NOT NULL,
    "TaxID" integer,
    "TotalTax" double precision DEFAULT 0 NOT NULL,
    "NetTotal" double precision,
    "ReturnAmount" double precision DEFAULT 0 NOT NULL,
    "ShippingStatus" integer DEFAULT 0 NOT NULL,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblbill OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16420)
-- Name: tblbill_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblbill_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblbill_ID_seq" OWNER TO postgres;

--
-- TOC entry 4541 (class 0 OID 0)
-- Dependencies: 217
-- Name: tblbill_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblbill_ID_seq" OWNED BY public.tblbill."ID";


--
-- TOC entry 218 (class 1259 OID 16421)
-- Name: tblbilldetail; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblbilldetail (
    "ID" integer NOT NULL,
    "BillNo" text,
    "ProductID" integer,
    "Barcode" text,
    "UnitID" integer,
    "Price" double precision,
    "Qty" integer DEFAULT 1 NOT NULL,
    "Total" double precision,
    "DiscountID" integer DEFAULT 0 NOT NULL,
    "TotalDiscount" double precision DEFAULT 0 NOT NULL,
    "TaxID" integer DEFAULT 0 NOT NULL,
    "TotalTax" double precision DEFAULT 0 NOT NULL,
    "NetTotal" double precision,
    "Size" text,
    "isWarranty" integer DEFAULT 0 NOT NULL,
    "ItemStatus" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblbilldetail OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16432)
-- Name: tblbilldetail_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblbilldetail_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblbilldetail_ID_seq" OWNER TO postgres;

--
-- TOC entry 4542 (class 0 OID 0)
-- Dependencies: 219
-- Name: tblbilldetail_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblbilldetail_ID_seq" OWNED BY public.tblbilldetail."ID";


--
-- TOC entry 220 (class 1259 OID 16433)
-- Name: tblbillreturn; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblbillreturn (
    "ID" integer NOT NULL,
    "BillNo" text,
    "BillDetailID" integer,
    "ComputerIP" text,
    "Price" double precision,
    "Qty" integer DEFAULT 1 NOT NULL,
    "Total" double precision,
    "ChargeType" integer DEFAULT 1 NOT NULL,
    "TotalCharge" double precision,
    "NetTotal" double precision,
    "PaymentStatus" integer DEFAULT 1 NOT NULL,
    "Note" text,
    "LocationID" integer,
    "CounterNo" integer NOT NULL,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblbillreturn OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16441)
-- Name: tblbillreturn_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblbillreturn_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblbillreturn_ID_seq" OWNER TO postgres;

--
-- TOC entry 4543 (class 0 OID 0)
-- Dependencies: 221
-- Name: tblbillreturn_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblbillreturn_ID_seq" OWNED BY public.tblbillreturn."ID";


--
-- TOC entry 222 (class 1259 OID 16442)
-- Name: tblbrand; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblbrand (
    "ID" integer NOT NULL,
    "BrandName" text,
    "Note" text,
    "LocationID" integer,
    "Flag" integer DEFAULT 1 NOT NULL,
    "Updatebby" text,
    "Created_at" timestamp with time zone NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblbrand OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16447)
-- Name: tblbrand_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblbrand_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblbrand_ID_seq" OWNER TO postgres;

--
-- TOC entry 4544 (class 0 OID 0)
-- Dependencies: 223
-- Name: tblbrand_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblbrand_ID_seq" OWNED BY public.tblbrand."ID";


--
-- TOC entry 224 (class 1259 OID 16455)
-- Name: tblcheckstock; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblcheckstock (
    "ID" integer NOT NULL,
    "ComputerIP" text,
    "ProductID" integer NOT NULL,
    "Barcode" text,
    "PeriodSaleQty" integer DEFAULT 1 NOT NULL,
    "PeriodStockQty" integer DEFAULT 1 NOT NULL,
    "ExpiryDate" date,
    "ActionID" integer,
    "CheckTermID" integer NOT NULL,
    "Note" text,
    "LocationID" integer NOT NULL,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblcheckstock OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16462)
-- Name: tblcheckstock_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblcheckstock_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblcheckstock_ID_seq" OWNER TO postgres;

--
-- TOC entry 4545 (class 0 OID 0)
-- Dependencies: 225
-- Name: tblcheckstock_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblcheckstock_ID_seq" OWNED BY public.tblcheckstock."ID";


--
-- TOC entry 226 (class 1259 OID 16463)
-- Name: tblcheckstockaction; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblcheckstockaction (
    "ID" integer NOT NULL,
    "ActionName" text NOT NULL,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer NOT NULL,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblcheckstockaction OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16469)
-- Name: tblcheckstockaction_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblcheckstockaction_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblcheckstockaction_ID_seq" OWNER TO postgres;

--
-- TOC entry 4546 (class 0 OID 0)
-- Dependencies: 227
-- Name: tblcheckstockaction_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblcheckstockaction_ID_seq" OWNED BY public.tblcheckstockaction."ID";


--
-- TOC entry 228 (class 1259 OID 16470)
-- Name: tblcounter; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblcounter (
    "ID" integer NOT NULL,
    "CounterNo" text DEFAULT '1'::bpchar NOT NULL,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblcounter OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16477)
-- Name: tblcounter_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblcounter_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblcounter_ID_seq" OWNER TO postgres;

--
-- TOC entry 4547 (class 0 OID 0)
-- Dependencies: 229
-- Name: tblcounter_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblcounter_ID_seq" OWNED BY public.tblcounter."ID";


--
-- TOC entry 312 (class 1259 OID 17337)
-- Name: tblcurrency; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblcurrency (
    "ID" integer NOT NULL,
    "ComputerIP" text,
    "Currency" text,
    "Symbol" text,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblcurrency OWNER TO postgres;

--
-- TOC entry 313 (class 1259 OID 17343)
-- Name: tblcurrency_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblcurrency_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblcurrency_ID_seq" OWNER TO postgres;

--
-- TOC entry 4548 (class 0 OID 0)
-- Dependencies: 313
-- Name: tblcurrency_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblcurrency_ID_seq" OWNED BY public.tblcurrency."ID";


--
-- TOC entry 230 (class 1259 OID 16485)
-- Name: tblcustomer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblcustomer (
    "ID" integer NOT NULL,
    "ComputerIP" text,
    "ContactID" text,
    "ContactType" integer DEFAULT 1 NOT NULL,
    "BusinessName" text,
    "Title" integer DEFAULT 4 NOT NULL,
    "FirstName" text,
    "MiddleName" text,
    "LastName" text,
    "Mobile" text,
    "AltMobile" text,
    "EMail" text,
    "HotLine" text,
    "TaxNumber" text,
    "CreditLimit" double precision,
    "AdvanceBalance" double precision,
    "PayTermID" integer,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblcustomer OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 16493)
-- Name: tblcustomer_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblcustomer_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblcustomer_ID_seq" OWNER TO postgres;

--
-- TOC entry 4549 (class 0 OID 0)
-- Dependencies: 231
-- Name: tblcustomer_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblcustomer_ID_seq" OWNED BY public.tblcustomer."ID";


--
-- TOC entry 287 (class 1259 OID 16980)
-- Name: tblcustomerdoc; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblcustomerdoc (
    "ID" integer NOT NULL,
    "ContactID" text,
    "DocName" text,
    "DocType" text,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblcustomerdoc OWNER TO postgres;

--
-- TOC entry 286 (class 1259 OID 16979)
-- Name: tblcustomerdoc_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblcustomerdoc_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblcustomerdoc_ID_seq" OWNER TO postgres;

--
-- TOC entry 4550 (class 0 OID 0)
-- Dependencies: 286
-- Name: tblcustomerdoc_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblcustomerdoc_ID_seq" OWNED BY public.tblcustomerdoc."ID";


--
-- TOC entry 232 (class 1259 OID 16494)
-- Name: tbldailycashflow; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tbldailycashflow (
    "ID" integer NOT NULL,
    "ComputerIP" text,
    "CurrencyID" integer,
    "Amount" double precision,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "CounterNo" integer NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tbldailycashflow OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 16500)
-- Name: tbldailycashflow_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tbldailycashflow_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tbldailycashflow_ID_seq" OWNER TO postgres;

--
-- TOC entry 4551 (class 0 OID 0)
-- Dependencies: 233
-- Name: tbldailycashflow_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tbldailycashflow_ID_seq" OWNED BY public.tbldailycashflow."ID";


--
-- TOC entry 306 (class 1259 OID 17248)
-- Name: tbldepartment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tbldepartment (
    "ID" integer NOT NULL,
    "Department" text NOT NULL,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tbldepartment OWNER TO postgres;

--
-- TOC entry 307 (class 1259 OID 17254)
-- Name: tbldepartment_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tbldepartment_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tbldepartment_ID_seq" OWNER TO postgres;

--
-- TOC entry 4552 (class 0 OID 0)
-- Dependencies: 307
-- Name: tbldepartment_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tbldepartment_ID_seq" OWNED BY public.tbldepartment."ID";


--
-- TOC entry 234 (class 1259 OID 16508)
-- Name: tbldiscounttype; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tbldiscounttype (
    "ID" integer NOT NULL,
    "DiscountType" text NOT NULL,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tbldiscounttype OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 16513)
-- Name: tbldiscounttype_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tbldiscounttype_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tbldiscounttype_ID_seq" OWNER TO postgres;

--
-- TOC entry 4553 (class 0 OID 0)
-- Dependencies: 235
-- Name: tbldiscounttype_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tbldiscounttype_ID_seq" OWNED BY public.tbldiscounttype."ID";


--
-- TOC entry 236 (class 1259 OID 16514)
-- Name: tblearnpointtransaction; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblearnpointtransaction (
    "ID" integer NOT NULL,
    "MemberID" integer,
    "BillNo" text,
    "ComputerIP" text,
    "Formula" text,
    "TotalAmount" double precision DEFAULT 0 NOT NULL,
    "PointEarn" integer DEFAULT 0 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblearnpointtransaction OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 16521)
-- Name: tblearnpointtransaction_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblearnpointtransaction_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblearnpointtransaction_ID_seq" OWNER TO postgres;

--
-- TOC entry 4554 (class 0 OID 0)
-- Dependencies: 237
-- Name: tblearnpointtransaction_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblearnpointtransaction_ID_seq" OWNED BY public.tblearnpointtransaction."ID";


--
-- TOC entry 238 (class 1259 OID 16522)
-- Name: tbleexchange; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tbleexchange (
    "ID" integer NOT NULL,
    "Rate" double precision NOT NULL,
    "CurrencyID" integer NOT NULL,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tbleexchange OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 16527)
-- Name: tbleexchange_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tbleexchange_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tbleexchange_ID_seq" OWNER TO postgres;

--
-- TOC entry 4555 (class 0 OID 0)
-- Dependencies: 239
-- Name: tbleexchange_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tbleexchange_ID_seq" OWNED BY public.tbleexchange."ID";


--
-- TOC entry 240 (class 1259 OID 16528)
-- Name: tblempbankdetail; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblempbankdetail (
    "ID" integer NOT NULL,
    "EmpID" integer,
    "BankName" text NOT NULL,
    "HolderName" text NOT NULL,
    "ACC" text NOT NULL,
    "QR" text NOT NULL,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblempbankdetail OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 16533)
-- Name: tblempbankdetail_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblempbankdetail_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblempbankdetail_ID_seq" OWNER TO postgres;

--
-- TOC entry 4556 (class 0 OID 0)
-- Dependencies: 241
-- Name: tblempbankdetail_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblempbankdetail_ID_seq" OWNED BY public.tblempbankdetail."ID";


--
-- TOC entry 308 (class 1259 OID 17265)
-- Name: tblemployee; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblemployee (
    "ID" integer NOT NULL,
    "ComputerIP" text,
    "EmpID" text,
    "Title" integer DEFAULT 3 NOT NULL,
    "FirstName" text,
    "LastName" text,
    "Email" text,
    "BirthDay" date,
    "MaritalStatus" integer DEFAULT 1 NOT NULL,
    "BloodGroup" text,
    "Mobile" text,
    "EmergencyMobile" text,
    "DepartmentID" integer,
    "ShiftID" integer,
    "PositionID" integer,
    "ProfileImg" text,
    "Salary" double precision,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblemployee OWNER TO postgres;

--
-- TOC entry 309 (class 1259 OID 17273)
-- Name: tblemployee_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblemployee_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblemployee_ID_seq" OWNER TO postgres;

--
-- TOC entry 4557 (class 0 OID 0)
-- Dependencies: 309
-- Name: tblemployee_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblemployee_ID_seq" OWNED BY public.tblemployee."ID";


--
-- TOC entry 299 (class 1259 OID 17108)
-- Name: tblexpense; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblexpense (
    "ID" integer NOT NULL,
    "ComputerIP" text,
    "LocationID" integer,
    "ExpenseTypeID" integer,
    "ExpenseDate" timestamp with time zone,
    "ExpenseFor" text,
    "Amount" double precision,
    "TaxTypeID" integer,
    "TaxID" integer,
    "TotalAmount" double precision,
    "AttachFile" text,
    "PaymentMethod" integer,
    "Status" integer DEFAULT 1 NOT NULL,
    "ApprovalRoute" integer,
    "Note" text,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblexpense OWNER TO postgres;

--
-- TOC entry 298 (class 1259 OID 17107)
-- Name: tblexpense_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblexpense_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblexpense_ID_seq" OWNER TO postgres;

--
-- TOC entry 4558 (class 0 OID 0)
-- Dependencies: 298
-- Name: tblexpense_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblexpense_ID_seq" OWNED BY public.tblexpense."ID";


--
-- TOC entry 289 (class 1259 OID 17035)
-- Name: tblexpensetype; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblexpensetype (
    "ID" integer NOT NULL,
    "LocationID" integer,
    "Type" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "Note" text,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblexpensetype OWNER TO postgres;

--
-- TOC entry 288 (class 1259 OID 17034)
-- Name: tblexpensetype_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblexpensetype_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblexpensetype_ID_seq" OWNER TO postgres;

--
-- TOC entry 4559 (class 0 OID 0)
-- Dependencies: 288
-- Name: tblexpensetype_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblexpensetype_ID_seq" OWNED BY public.tblexpensetype."ID";


--
-- TOC entry 337 (class 1259 OID 19547)
-- Name: tblimportproductlot; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblimportproductlot (
    "ID" integer NOT NULL,
    "LotNumber" integer,
    "PurchaseID" integer,
    "SupplierID" integer,
    "ProductID" integer,
    "Barcode" text,
    "ImportQty" integer,
    "CostPerUnit" double precision,
    "Note" text,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblimportproductlot OWNER TO postgres;

--
-- TOC entry 336 (class 1259 OID 19546)
-- Name: tblimportproductlot_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblimportproductlot_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblimportproductlot_ID_seq" OWNER TO postgres;

--
-- TOC entry 4560 (class 0 OID 0)
-- Dependencies: 336
-- Name: tblimportproductlot_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblimportproductlot_ID_seq" OWNED BY public.tblimportproductlot."ID";


--
-- TOC entry 339 (class 1259 OID 27665)
-- Name: tbllocation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tbllocation (
    "ID" integer NOT NULL,
    "ComputerIP" text,
    "Location" text,
    "Tel1" text,
    "Tel2" text,
    "Mobile" text,
    "Lat" double precision,
    "Long" double precision,
    "Address" text,
    "Logo" text,
    "Profile" text,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tbllocation OWNER TO postgres;

--
-- TOC entry 338 (class 1259 OID 27664)
-- Name: tbllocation_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tbllocation_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tbllocation_ID_seq" OWNER TO postgres;

--
-- TOC entry 4561 (class 0 OID 0)
-- Dependencies: 338
-- Name: tbllocation_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tbllocation_ID_seq" OWNED BY public.tbllocation."ID";


--
-- TOC entry 343 (class 1259 OID 27702)
-- Name: tbllocationdetail; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tbllocationdetail (
    "ID" integer NOT NULL,
    "BankName" text,
    "ACCHolder" text,
    "ACC" text,
    "QR" text,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tbllocationdetail OWNER TO postgres;

--
-- TOC entry 342 (class 1259 OID 27701)
-- Name: tbllocationdetail_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tbllocationdetail_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tbllocationdetail_ID_seq" OWNER TO postgres;

--
-- TOC entry 4562 (class 0 OID 0)
-- Dependencies: 342
-- Name: tbllocationdetail_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tbllocationdetail_ID_seq" OWNED BY public.tbllocationdetail."ID";


--
-- TOC entry 242 (class 1259 OID 16556)
-- Name: tblmember; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblmember (
    "ID" integer NOT NULL,
    "LocationID" integer NOT NULL,
    "MemberID" text,
    "RefNo" text,
    "FirstName" text,
    "LastName" text,
    "Birthday" date,
    "Village" text,
    "District" text,
    "Province" text,
    "Country" text DEFAULT 'Laos'::bpchar NOT NULL,
    "MemberTypeID" integer,
    "Percentage" double precision,
    "PointTypeID" integer,
    "Point" integer DEFAULT 0 NOT NULL,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblmember OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 16564)
-- Name: tblmember_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblmember_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblmember_ID_seq" OWNER TO postgres;

--
-- TOC entry 4563 (class 0 OID 0)
-- Dependencies: 243
-- Name: tblmember_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblmember_ID_seq" OWNED BY public.tblmember."ID";


--
-- TOC entry 244 (class 1259 OID 16565)
-- Name: tblmembertype; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblmembertype (
    "ID" integer NOT NULL,
    "LocationID" integer,
    "Type" text,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "Updateby" text,
    "Created_at" timestamp with time zone NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblmembertype OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 16570)
-- Name: tblmembertype_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblmembertype_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblmembertype_ID_seq" OWNER TO postgres;

--
-- TOC entry 4564 (class 0 OID 0)
-- Dependencies: 245
-- Name: tblmembertype_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblmembertype_ID_seq" OWNED BY public.tblmembertype."ID";


--
-- TOC entry 324 (class 1259 OID 19444)
-- Name: tblmenu; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblmenu (
    "ID" integer NOT NULL,
    "ParentID" text,
    "MenuID" text,
    "MenuName" text,
    "Action" text,
    "Priority" integer NOT NULL,
    "MenuAction" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "Note" text,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblmenu OWNER TO postgres;

--
-- TOC entry 325 (class 1259 OID 19452)
-- Name: tblmenu_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblmenu_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblmenu_ID_seq" OWNER TO postgres;

--
-- TOC entry 4565 (class 0 OID 0)
-- Dependencies: 325
-- Name: tblmenu_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblmenu_ID_seq" OWNED BY public.tblmenu."ID";


--
-- TOC entry 246 (class 1259 OID 16577)
-- Name: tblmenuprivilege; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblmenuprivilege (
    "ID" integer NOT NULL,
    "UserID" integer NOT NULL,
    "MenuList" text NOT NULL,
    "Note" text,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblmenuprivilege OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 16582)
-- Name: tblmenuprivilege_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblmenuprivilege_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblmenuprivilege_ID_seq" OWNER TO postgres;

--
-- TOC entry 4566 (class 0 OID 0)
-- Dependencies: 247
-- Name: tblmenuprivilege_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblmenuprivilege_ID_seq" OWNED BY public.tblmenuprivilege."ID";


--
-- TOC entry 248 (class 1259 OID 16583)
-- Name: tblpacking; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblpacking (
    "ID" integer NOT NULL,
    "PackingSlip" text,
    "ComputerIP" text,
    "RefNo" text,
    "PackingStatus" integer DEFAULT 0 NOT NULL,
    "Note" text,
    "LocationID" integer NOT NULL,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblpacking OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 16589)
-- Name: tblpacking_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblpacking_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblpacking_ID_seq" OWNER TO postgres;

--
-- TOC entry 4567 (class 0 OID 0)
-- Dependencies: 249
-- Name: tblpacking_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblpacking_ID_seq" OWNED BY public.tblpacking."ID";


--
-- TOC entry 302 (class 1259 OID 17151)
-- Name: tblpayment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblpayment (
    "ID" integer NOT NULL,
    "PaymentID" text,
    "ComputerIP" text,
    "PaymentCategory" integer NOT NULL,
    "RefNo" text NOT NULL,
    "CustomerID" integer,
    "Amount" double precision DEFAULT 0 NOT NULL,
    "ReceiveCash" double precision,
    "ReturnCash" double precision,
    "PaymentMethodID" integer DEFAULT 1 NOT NULL,
    "PaymentType" integer DEFAULT 1 NOT NULL,
    "PaymentNote" text,
    "CurrencyID" integer NOT NULL,
    "SendNotify" integer DEFAULT 0 NOT NULL,
    "NotifyCount" integer DEFAULT 0 NOT NULL,
    "File" text,
    "LocationID" integer NOT NULL,
    "CounterNo" integer NOT NULL,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblpayment OWNER TO postgres;

--
-- TOC entry 303 (class 1259 OID 17161)
-- Name: tblpayment_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblpayment_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblpayment_ID_seq" OWNER TO postgres;

--
-- TOC entry 4568 (class 0 OID 0)
-- Dependencies: 303
-- Name: tblpayment_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblpayment_ID_seq" OWNED BY public.tblpayment."ID";


--
-- TOC entry 250 (class 1259 OID 16600)
-- Name: tblpaymentmethod; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblpaymentmethod (
    "ID" integer NOT NULL,
    "Method" text NOT NULL,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblpaymentmethod OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 16605)
-- Name: tblpaymentmethod_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblpaymentmethod_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblpaymentmethod_ID_seq" OWNER TO postgres;

--
-- TOC entry 4569 (class 0 OID 0)
-- Dependencies: 251
-- Name: tblpaymentmethod_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblpaymentmethod_ID_seq" OWNED BY public.tblpaymentmethod."ID";


--
-- TOC entry 252 (class 1259 OID 16606)
-- Name: tblpayterm; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblpayterm (
    "ID" integer NOT NULL,
    "PayTerms" text NOT NULL,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblpayterm OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 16611)
-- Name: tblpayterm_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblpayterm_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblpayterm_ID_seq" OWNER TO postgres;

--
-- TOC entry 4570 (class 0 OID 0)
-- Dependencies: 253
-- Name: tblpayterm_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblpayterm_ID_seq" OWNED BY public.tblpayterm."ID";


--
-- TOC entry 254 (class 1259 OID 16612)
-- Name: tblpointtype; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblpointtype (
    "ID" integer NOT NULL,
    "LocationID" integer,
    "Type" text,
    "BaseAmount" double precision DEFAULT 0 NOT NULL,
    "Rate" integer DEFAULT 0 NOT NULL,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "Updateby" text,
    "Created_at" timestamp with time zone NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblpointtype OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 16619)
-- Name: tblpointtype_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblpointtype_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblpointtype_ID_seq" OWNER TO postgres;

--
-- TOC entry 4571 (class 0 OID 0)
-- Dependencies: 255
-- Name: tblpointtype_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblpointtype_ID_seq" OWNED BY public.tblpointtype."ID";


--
-- TOC entry 256 (class 1259 OID 16620)
-- Name: tblposition; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblposition (
    "ID" integer NOT NULL,
    "Position" text NOT NULL,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblposition OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 16625)
-- Name: tblposition_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblposition_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblposition_ID_seq" OWNER TO postgres;

--
-- TOC entry 4572 (class 0 OID 0)
-- Dependencies: 257
-- Name: tblposition_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblposition_ID_seq" OWNED BY public.tblposition."ID";


--
-- TOC entry 258 (class 1259 OID 16626)
-- Name: tblproductcategory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblproductcategory (
    "ID" integer NOT NULL,
    "ProductCategory" text NOT NULL,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblproductcategory OWNER TO postgres;

--
-- TOC entry 259 (class 1259 OID 16631)
-- Name: tblproductcategory_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblproductcategory_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblproductcategory_ID_seq" OWNER TO postgres;

--
-- TOC entry 4573 (class 0 OID 0)
-- Dependencies: 259
-- Name: tblproductcategory_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblproductcategory_ID_seq" OWNED BY public.tblproductcategory."ID";


--
-- TOC entry 326 (class 1259 OID 19459)
-- Name: tblproductlist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblproductlist (
    "ID" integer NOT NULL,
    "ComputerIP" text,
    "Barcode" text,
    "ProductName" text,
    "Slug" text,
    "ProductTypeID" integer,
    "CategoryID" integer,
    "BrandID" integer,
    "UnitID" integer,
    "WarrantyID" integer,
    "ShelfID" integer,
    "TotalQty" bigint,
    "AlertStock_Qty" integer,
    "Cost" double precision,
    "RetailPrice" double precision,
    "WholeSalePrice" double precision,
    "CurrentStock" double precision,
    "ProductStatus" integer,
    "TaxPercentage" integer,
    "ImageArr" text,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblproductlist OWNER TO postgres;

--
-- TOC entry 327 (class 1259 OID 19467)
-- Name: tblproductlist_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblproductlist_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblproductlist_ID_seq" OWNER TO postgres;

--
-- TOC entry 4574 (class 0 OID 0)
-- Dependencies: 327
-- Name: tblproductlist_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblproductlist_ID_seq" OWNED BY public.tblproductlist."ID";


--
-- TOC entry 260 (class 1259 OID 16641)
-- Name: tblproducttype; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblproducttype (
    "ID" integer NOT NULL,
    "ProductType" text NOT NULL,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblproducttype OWNER TO postgres;

--
-- TOC entry 261 (class 1259 OID 16646)
-- Name: tblproducttype_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblproducttype_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblproducttype_ID_seq" OWNER TO postgres;

--
-- TOC entry 4575 (class 0 OID 0)
-- Dependencies: 261
-- Name: tblproducttype_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblproducttype_ID_seq" OWNED BY public.tblproducttype."ID";


--
-- TOC entry 294 (class 1259 OID 17077)
-- Name: tblpromotion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblpromotion (
    "ID" integer NOT NULL,
    "PromotionName" text,
    "ComputerIP" text,
    "PromotionType" integer,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer NOT NULL,
    "ApprovalRoute" integer,
    "Note" text,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblpromotion OWNER TO postgres;

--
-- TOC entry 295 (class 1259 OID 17083)
-- Name: tblpromotion_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblpromotion_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblpromotion_ID_seq" OWNER TO postgres;

--
-- TOC entry 4576 (class 0 OID 0)
-- Dependencies: 295
-- Name: tblpromotion_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblpromotion_ID_seq" OWNED BY public.tblpromotion."ID";


--
-- TOC entry 262 (class 1259 OID 16654)
-- Name: tblpromotiondetail; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblpromotiondetail (
    "ID" integer NOT NULL,
    "PromotionID" integer,
    "ProductID" integer,
    "Barcode" text,
    "Price" double precision,
    "Qty" integer,
    "Total" double precision,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblpromotiondetail OWNER TO postgres;

--
-- TOC entry 263 (class 1259 OID 16660)
-- Name: tblpromotiondetail_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblpromotiondetail_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblpromotiondetail_ID_seq" OWNER TO postgres;

--
-- TOC entry 4577 (class 0 OID 0)
-- Dependencies: 263
-- Name: tblpromotiondetail_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblpromotiondetail_ID_seq" OWNED BY public.tblpromotiondetail."ID";


--
-- TOC entry 285 (class 1259 OID 16970)
-- Name: tblpromotiontype; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblpromotiontype (
    "ID" integer NOT NULL,
    "Type" text,
    "Note" text,
    "LocationID" integer,
    "Flag" integer DEFAULT 1 NOT NULL,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblpromotiontype OWNER TO postgres;

--
-- TOC entry 284 (class 1259 OID 16969)
-- Name: tblpromotiontype_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblpromotiontype_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblpromotiontype_ID_seq" OWNER TO postgres;

--
-- TOC entry 4578 (class 0 OID 0)
-- Dependencies: 284
-- Name: tblpromotiontype_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblpromotiontype_ID_seq" OWNED BY public.tblpromotiontype."ID";


--
-- TOC entry 290 (class 1259 OID 17044)
-- Name: tblpurchase; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblpurchase (
    "ID" integer NOT NULL,
    "PurchaseID" integer,
    "ComputerIP" text,
    "SupplierID" integer,
    "RefNo" text,
    "Total_b_discount" double precision,
    "DiscountTypeID" integer,
    "Discount_amt" double precision,
    "Total_b_tax" double precision,
    "TaxID" integer,
    "Net_Total" double precision,
    "PurchaseDate" date,
    "PurchaseStatus" integer,
    "PayStatus" integer,
    "Duration" integer,
    "PayTermID" integer,
    "ApprovalRoute" integer,
    "AttactFile" text,
    "Note" text,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblpurchase OWNER TO postgres;

--
-- TOC entry 291 (class 1259 OID 17049)
-- Name: tblpurchase_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblpurchase_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblpurchase_ID_seq" OWNER TO postgres;

--
-- TOC entry 4579 (class 0 OID 0)
-- Dependencies: 291
-- Name: tblpurchase_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblpurchase_ID_seq" OWNED BY public.tblpurchase."ID";


--
-- TOC entry 264 (class 1259 OID 16667)
-- Name: tblpurchasedetail; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblpurchasedetail (
    "ID" integer NOT NULL,
    "PurchaseID" integer,
    "ProductID" integer,
    "Barcode" text,
    "UnitID" integer,
    "PurchaseQty" integer,
    "Cost_b_discount" double precision,
    "DiscountTypeID" integer,
    "Discount_Amt" double precision,
    "Cost_b_Tax" double precision,
    "TaxID" integer,
    "Tax_Amt" double precision,
    "NetCost" double precision,
    "ProfitMarginPercentage" integer,
    "SellingPrice" double precision,
    "Note" text,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblpurchasedetail OWNER TO postgres;

--
-- TOC entry 265 (class 1259 OID 16672)
-- Name: tblpurchasedetail_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblpurchasedetail_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblpurchasedetail_ID_seq" OWNER TO postgres;

--
-- TOC entry 4580 (class 0 OID 0)
-- Dependencies: 265
-- Name: tblpurchasedetail_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblpurchasedetail_ID_seq" OWNED BY public.tblpurchasedetail."ID";


--
-- TOC entry 323 (class 1259 OID 19392)
-- Name: tblrefreshtoken; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblrefreshtoken (
    "ID" integer NOT NULL,
    "UserID" integer NOT NULL,
    "RefreshToken" text NOT NULL,
    "Lastupdate" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblrefreshtoken OWNER TO postgres;

--
-- TOC entry 322 (class 1259 OID 19391)
-- Name: tblrefreshtoken_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblrefreshtoken_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblrefreshtoken_ID_seq" OWNER TO postgres;

--
-- TOC entry 4581 (class 0 OID 0)
-- Dependencies: 322
-- Name: tblrefreshtoken_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblrefreshtoken_ID_seq" OWNED BY public.tblrefreshtoken."ID";


--
-- TOC entry 319 (class 1259 OID 19354)
-- Name: tblroute; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblroute (
    "ID" integer NOT NULL,
    "RouteName" integer,
    "RouteObjective" integer,
    "Note" text,
    "LocationID" integer,
    "Flag" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblroute OWNER TO postgres;

--
-- TOC entry 318 (class 1259 OID 19353)
-- Name: tblroute_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblroute_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblroute_ID_seq" OWNER TO postgres;

--
-- TOC entry 4582 (class 0 OID 0)
-- Dependencies: 318
-- Name: tblroute_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblroute_ID_seq" OWNED BY public.tblroute."ID";


--
-- TOC entry 321 (class 1259 OID 19365)
-- Name: tblroutedetail; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblroutedetail (
    "ID" integer NOT NULL,
    "RouteID" integer,
    "ApproverID" integer,
    "EMail" text,
    "Mobile" text,
    "WhatsApp" text,
    "Line" text,
    "Priority" integer,
    "Note" text,
    "LocationID" integer,
    "Flag" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblroutedetail OWNER TO postgres;

--
-- TOC entry 320 (class 1259 OID 19364)
-- Name: tblroutedetail_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblroutedetail_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblroutedetail_ID_seq" OWNER TO postgres;

--
-- TOC entry 4583 (class 0 OID 0)
-- Dependencies: 320
-- Name: tblroutedetail_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblroutedetail_ID_seq" OWNED BY public.tblroutedetail."ID";


--
-- TOC entry 296 (class 1259 OID 17097)
-- Name: tblsaletarget; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblsaletarget (
    "ID" integer NOT NULL,
    "ComputerIP" text,
    "TargetName" text NOT NULL,
    "EmpID" integer,
    "MinTarget" double precision,
    "MaxTarget" double precision,
    "CommissionType" double precision,
    "MinCommissionPercentage" double precision,
    "MiddleCommissionPercentage" double precision,
    "MaxCommissionPercentage" double precision,
    "EffectDate" date,
    "DueDate" date,
    "ApprovalRoute" integer,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblsaletarget OWNER TO postgres;

--
-- TOC entry 297 (class 1259 OID 17103)
-- Name: tblsaletarget_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblsaletarget_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblsaletarget_ID_seq" OWNER TO postgres;

--
-- TOC entry 4584 (class 0 OID 0)
-- Dependencies: 297
-- Name: tblsaletarget_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblsaletarget_ID_seq" OWNED BY public.tblsaletarget."ID";


--
-- TOC entry 329 (class 1259 OID 19484)
-- Name: tblselftype; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblselftype (
    "ID" integer NOT NULL,
    "ShelfType" text NOT NULL,
    "LocationID" integer,
    "Flag" integer DEFAULT 1 NOT NULL,
    "Note" text,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblselftype OWNER TO postgres;

--
-- TOC entry 328 (class 1259 OID 19483)
-- Name: tblselftype_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblselftype_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblselftype_ID_seq" OWNER TO postgres;

--
-- TOC entry 4585 (class 0 OID 0)
-- Dependencies: 328
-- Name: tblselftype_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblselftype_ID_seq" OWNED BY public.tblselftype."ID";


--
-- TOC entry 341 (class 1259 OID 27681)
-- Name: tblsetting; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblsetting (
    "ID" integer NOT NULL,
    "DefaultTaxTypeID" integer,
    "DefaultTaxID" integer,
    "DefaultCurrencyID" integer,
    "DefaultLanguageID" integer,
    "LocationID" integer,
    "Flag" integer DEFAULT 1 NOT NULL,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblsetting OWNER TO postgres;

--
-- TOC entry 340 (class 1259 OID 27680)
-- Name: tblsetting_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblsetting_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblsetting_ID_seq" OWNER TO postgres;

--
-- TOC entry 4586 (class 0 OID 0)
-- Dependencies: 340
-- Name: tblsetting_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblsetting_ID_seq" OWNED BY public.tblsetting."ID";


--
-- TOC entry 333 (class 1259 OID 19508)
-- Name: tblshelf; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblshelf (
    "ID" integer NOT NULL,
    "ShelfTypeID" integer,
    "ZoneID" integer,
    "ShelfNo" text,
    "TotalQty" bigint DEFAULT 0 NOT NULL,
    "StockQty" integer DEFAULT 0 NOT NULL,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblshelf OWNER TO postgres;

--
-- TOC entry 332 (class 1259 OID 19507)
-- Name: tblshelf_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblshelf_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblshelf_ID_seq" OWNER TO postgres;

--
-- TOC entry 4587 (class 0 OID 0)
-- Dependencies: 332
-- Name: tblshelf_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblshelf_ID_seq" OWNED BY public.tblshelf."ID";


--
-- TOC entry 335 (class 1259 OID 19534)
-- Name: tblshelftransfer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblshelftransfer (
    "ID" integer NOT NULL,
    "FromShelfID" integer NOT NULL,
    "FromZoneID" integer,
    "ToShelfID" integer NOT NULL,
    "ToZoneID" integer,
    "ProductID" integer NOT NULL,
    "LocationID" integer,
    "Status" integer DEFAULT 3 NOT NULL,
    "Note" text,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblshelftransfer OWNER TO postgres;

--
-- TOC entry 334 (class 1259 OID 19533)
-- Name: tblshelftransfer_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblshelftransfer_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblshelftransfer_ID_seq" OWNER TO postgres;

--
-- TOC entry 4588 (class 0 OID 0)
-- Dependencies: 334
-- Name: tblshelftransfer_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblshelftransfer_ID_seq" OWNED BY public.tblshelftransfer."ID";


--
-- TOC entry 347 (class 1259 OID 27772)
-- Name: tblshift; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblshift (
    "ID" integer NOT NULL,
    "Shift" text,
    "ShiftTypeID" integer,
    "StartTime" text,
    "EndTime" text,
    "Holiday" integer DEFAULT 1,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblshift OWNER TO postgres;

--
-- TOC entry 346 (class 1259 OID 27771)
-- Name: tblshift_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblshift_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblshift_ID_seq" OWNER TO postgres;

--
-- TOC entry 4589 (class 0 OID 0)
-- Dependencies: 346
-- Name: tblshift_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblshift_ID_seq" OWNED BY public.tblshift."ID";


--
-- TOC entry 345 (class 1259 OID 27737)
-- Name: tblshifttype; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblshifttype (
    "ID" integer NOT NULL,
    "ShiftType" text NOT NULL,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblshifttype OWNER TO postgres;

--
-- TOC entry 344 (class 1259 OID 27736)
-- Name: tblshifttype_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblshifttype_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblshifttype_ID_seq" OWNER TO postgres;

--
-- TOC entry 4590 (class 0 OID 0)
-- Dependencies: 344
-- Name: tblshifttype_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblshifttype_ID_seq" OWNED BY public.tblshifttype."ID";


--
-- TOC entry 266 (class 1259 OID 16699)
-- Name: tblshipping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblshipping (
    "ID" integer NOT NULL,
    "PackingSlip" text,
    "RefNo" text,
    "ShippingFee" double precision,
    "ShippingAddress" text,
    "Village" text,
    "City" text,
    "District" text,
    "Province" text,
    "Country" text,
    "Mobile" text,
    "AltMobile" text,
    "Title" integer DEFAULT 4 NOT NULL,
    "FirstName" text,
    "LastName" text,
    "ShippingStatus" integer DEFAULT 0 NOT NULL,
    "LocationID" integer NOT NULL,
    "Shippedby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblshipping OWNER TO postgres;

--
-- TOC entry 267 (class 1259 OID 16708)
-- Name: tblshipping_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblshipping_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblshipping_ID_seq" OWNER TO postgres;

--
-- TOC entry 4591 (class 0 OID 0)
-- Dependencies: 267
-- Name: tblshipping_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblshipping_ID_seq" OWNED BY public.tblshipping."ID";


--
-- TOC entry 268 (class 1259 OID 16709)
-- Name: tblstatus; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblstatus (
    "ID" integer NOT NULL,
    "Status" text,
    "StatusTypeID" integer,
    "Note" text,
    "LocationID" integer,
    "Flag" integer DEFAULT 1 NOT NULL,
    "Updateby" text,
    "Created_at" timestamp with time zone NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblstatus OWNER TO postgres;

--
-- TOC entry 269 (class 1259 OID 16714)
-- Name: tblstatus_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblstatus_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblstatus_ID_seq" OWNER TO postgres;

--
-- TOC entry 4592 (class 0 OID 0)
-- Dependencies: 269
-- Name: tblstatus_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblstatus_ID_seq" OWNED BY public.tblstatus."ID";


--
-- TOC entry 270 (class 1259 OID 16715)
-- Name: tblstatustype; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblstatustype (
    "ID" integer NOT NULL,
    "Type" text,
    "Note" text,
    "LocationID" integer,
    "Flag" integer DEFAULT 1 NOT NULL,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblstatustype OWNER TO postgres;

--
-- TOC entry 271 (class 1259 OID 16721)
-- Name: tblstatustype_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblstatustype_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblstatustype_ID_seq" OWNER TO postgres;

--
-- TOC entry 4593 (class 0 OID 0)
-- Dependencies: 271
-- Name: tblstatustype_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblstatustype_ID_seq" OWNED BY public.tblstatustype."ID";


--
-- TOC entry 292 (class 1259 OID 17066)
-- Name: tblstocktransfer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblstocktransfer (
    "ID" integer NOT NULL,
    "TransferID" text NOT NULL,
    "ComputerIP" text,
    "LocationFrom" integer NOT NULL,
    "LocationTo" integer NOT NULL,
    "Transferedby" text,
    "Contact" text,
    "TransferFee" double precision,
    "PaymentStatus" integer DEFAULT 1 NOT NULL,
    "TransferStatus" integer DEFAULT 1 NOT NULL,
    "ApprovalRoute" integer,
    "TransferNote" text,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblstocktransfer OWNER TO postgres;

--
-- TOC entry 293 (class 1259 OID 17073)
-- Name: tblstocktransfer_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblstocktransfer_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblstocktransfer_ID_seq" OWNER TO postgres;

--
-- TOC entry 4594 (class 0 OID 0)
-- Dependencies: 293
-- Name: tblstocktransfer_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblstocktransfer_ID_seq" OWNED BY public.tblstocktransfer."ID";


--
-- TOC entry 272 (class 1259 OID 16730)
-- Name: tblstocktransferdetail; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblstocktransferdetail (
    "ID" integer NOT NULL,
    "TransferID" text NOT NULL,
    "ProductID" integer NOT NULL,
    "Barcode" text,
    "Price" double precision,
    "Qty" integer,
    "Total" double precision,
    "TransferStatus" integer DEFAULT 1 NOT NULL,
    "LocationID" integer NOT NULL,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblstocktransferdetail OWNER TO postgres;

--
-- TOC entry 273 (class 1259 OID 16736)
-- Name: tblstocktransferdetail_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblstocktransferdetail_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblstocktransferdetail_ID_seq" OWNER TO postgres;

--
-- TOC entry 4595 (class 0 OID 0)
-- Dependencies: 273
-- Name: tblstocktransferdetail_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblstocktransferdetail_ID_seq" OWNED BY public.tblstocktransferdetail."ID";


--
-- TOC entry 314 (class 1259 OID 17391)
-- Name: tblsupplier; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblsupplier (
    "ID" integer NOT NULL,
    "ContactID" text,
    "ComputerIP" text,
    "ContactType" integer DEFAULT 1 NOT NULL,
    "BusinessName" text,
    "Title" integer DEFAULT 4 NOT NULL,
    "FirstName" text,
    "MiddleName" text,
    "LastName" text,
    "Mobile" text,
    "AltMobile" text,
    "EMail" text,
    "HotLine" text,
    "BirthDay" date,
    "TaxNumber" text,
    "OpenBalance" double precision,
    "PayTermID" integer,
    "POBox" text,
    "City" text,
    "State" text,
    "Province" text,
    "Country" text,
    "ZIPCode" text,
    "ShippingAddress" text,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblsupplier OWNER TO postgres;

--
-- TOC entry 315 (class 1259 OID 17401)
-- Name: tblsupplier_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblsupplier_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblsupplier_ID_seq" OWNER TO postgres;

--
-- TOC entry 4596 (class 0 OID 0)
-- Dependencies: 315
-- Name: tblsupplier_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblsupplier_ID_seq" OWNED BY public.tblsupplier."ID";


--
-- TOC entry 274 (class 1259 OID 16748)
-- Name: tblsupplierdetail; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblsupplierdetail (
    "ID" integer NOT NULL,
    "ContactID" text,
    "DocName" text,
    "DocType" text,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblsupplierdetail OWNER TO postgres;

--
-- TOC entry 275 (class 1259 OID 16753)
-- Name: tblsupplierdoc_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblsupplierdoc_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblsupplierdoc_ID_seq" OWNER TO postgres;

--
-- TOC entry 4597 (class 0 OID 0)
-- Dependencies: 275
-- Name: tblsupplierdoc_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblsupplierdoc_ID_seq" OWNED BY public.tblsupplierdetail."ID";


--
-- TOC entry 305 (class 1259 OID 17205)
-- Name: tblsystemlog; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblsystemlog (
    "ID" integer NOT NULL,
    "FunctionName" text,
    "ErrCode" text,
    "ErrMessage" text,
    "LocationID" integer,
    "Updateby" text,
    "Action" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblsystemlog OWNER TO postgres;

--
-- TOC entry 304 (class 1259 OID 17204)
-- Name: tblsystemlog_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblsystemlog_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblsystemlog_ID_seq" OWNER TO postgres;

--
-- TOC entry 4598 (class 0 OID 0)
-- Dependencies: 304
-- Name: tblsystemlog_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblsystemlog_ID_seq" OWNED BY public.tblsystemlog."ID";


--
-- TOC entry 349 (class 1259 OID 27802)
-- Name: tbltax; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tbltax (
    "ID" integer NOT NULL,
    "TaxName" text,
    "TaxPercentage" double precision,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tbltax OWNER TO postgres;

--
-- TOC entry 348 (class 1259 OID 27801)
-- Name: tbltax_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tbltax_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tbltax_ID_seq" OWNER TO postgres;

--
-- TOC entry 4599 (class 0 OID 0)
-- Dependencies: 348
-- Name: tbltax_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tbltax_ID_seq" OWNED BY public.tbltax."ID";


--
-- TOC entry 276 (class 1259 OID 16760)
-- Name: tbltaxtype; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tbltaxtype (
    "ID" integer NOT NULL,
    "TaxType" text,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tbltaxtype OWNER TO postgres;

--
-- TOC entry 277 (class 1259 OID 16765)
-- Name: tbltaxtype_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tbltaxtype_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tbltaxtype_ID_seq" OWNER TO postgres;

--
-- TOC entry 4600 (class 0 OID 0)
-- Dependencies: 277
-- Name: tbltaxtype_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tbltaxtype_ID_seq" OWNED BY public.tbltaxtype."ID";


--
-- TOC entry 278 (class 1259 OID 16766)
-- Name: tblunit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblunit (
    "ID" integer NOT NULL,
    "ShortUnit" text,
    "LongUnit" text,
    "isDecimal" integer DEFAULT 0 NOT NULL,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblunit OWNER TO postgres;

--
-- TOC entry 279 (class 1259 OID 16772)
-- Name: tblunit_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblunit_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblunit_ID_seq" OWNER TO postgres;

--
-- TOC entry 4601 (class 0 OID 0)
-- Dependencies: 279
-- Name: tblunit_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblunit_ID_seq" OWNED BY public.tblunit."ID";


--
-- TOC entry 310 (class 1259 OID 17320)
-- Name: tbluser; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tbluser (
    "ID" integer NOT NULL,
    "EmpID" integer NOT NULL,
    "UserName" text,
    "Password" text,
    "Role" integer DEFAULT 0 NOT NULL,
    "Status" integer DEFAULT 1 NOT NULL,
    "RetryCount" integer DEFAULT 0 NOT NULL,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer NOT NULL,
    "Note" text,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tbluser OWNER TO postgres;

--
-- TOC entry 311 (class 1259 OID 17329)
-- Name: tbluser_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tbluser_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tbluser_ID_seq" OWNER TO postgres;

--
-- TOC entry 4602 (class 0 OID 0)
-- Dependencies: 311
-- Name: tbluser_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tbluser_ID_seq" OWNED BY public.tbluser."ID";


--
-- TOC entry 280 (class 1259 OID 16782)
-- Name: tbluseractivity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tbluseractivity (
    "ID" integer NOT NULL,
    "Date" timestamp with time zone DEFAULT now() NOT NULL,
    "Action" text,
    "UserID" integer,
    "Function" text,
    "Note" text
);


ALTER TABLE public.tbluseractivity OWNER TO postgres;

--
-- TOC entry 281 (class 1259 OID 16786)
-- Name: tbluseractivity_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tbluseractivity_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tbluseractivity_ID_seq" OWNER TO postgres;

--
-- TOC entry 4603 (class 0 OID 0)
-- Dependencies: 281
-- Name: tbluseractivity_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tbluseractivity_ID_seq" OWNED BY public.tbluseractivity."ID";


--
-- TOC entry 282 (class 1259 OID 16787)
-- Name: tblvariation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblvariation (
    "ID" integer NOT NULL,
    "Size" text,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblvariation OWNER TO postgres;

--
-- TOC entry 283 (class 1259 OID 16792)
-- Name: tblvariation_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblvariation_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblvariation_ID_seq" OWNER TO postgres;

--
-- TOC entry 4604 (class 0 OID 0)
-- Dependencies: 283
-- Name: tblvariation_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblvariation_ID_seq" OWNED BY public.tblvariation."ID";


--
-- TOC entry 300 (class 1259 OID 17140)
-- Name: tblwarranty; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblwarranty (
    "ID" integer NOT NULL,
    "ProductID" integer,
    "Name" text NOT NULL,
    "Duration" integer NOT NULL,
    "Unit" integer DEFAULT 1 NOT NULL,
    "EffectDate" date,
    "DueDate" date,
    "Note" text,
    "Flag" integer DEFAULT 1 NOT NULL,
    "LocationID" integer,
    "Updateby" text,
    "Created_at" timestamp with time zone NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblwarranty OWNER TO postgres;

--
-- TOC entry 301 (class 1259 OID 17146)
-- Name: tblwarranty_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblwarranty_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblwarranty_ID_seq" OWNER TO postgres;

--
-- TOC entry 4605 (class 0 OID 0)
-- Dependencies: 301
-- Name: tblwarranty_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblwarranty_ID_seq" OWNED BY public.tblwarranty."ID";


--
-- TOC entry 331 (class 1259 OID 19496)
-- Name: tblzone; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tblzone (
    "ID" integer NOT NULL,
    "Zone" text NOT NULL,
    "LocationID" integer,
    "Flag" integer DEFAULT 1 NOT NULL,
    "Note" text,
    "Updateby" text,
    "Created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "Updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tblzone OWNER TO postgres;

--
-- TOC entry 330 (class 1259 OID 19495)
-- Name: tblzone_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."tblzone_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."tblzone_ID_seq" OWNER TO postgres;

--
-- TOC entry 4606 (class 0 OID 0)
-- Dependencies: 330
-- Name: tblzone_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."tblzone_ID_seq" OWNED BY public.tblzone."ID";


--
-- TOC entry 3836 (class 2604 OID 16800)
-- Name: tblNotification ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblNotification" ALTER COLUMN "ID" SET DEFAULT nextval('public."tblNotification_ID_seq"'::regclass);


--
-- TOC entry 4055 (class 2604 OID 19323)
-- Name: tblapproval ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblapproval ALTER COLUMN "ID" SET DEFAULT nextval('public."tblapproval_ID_seq"'::regclass);


--
-- TOC entry 3841 (class 2604 OID 16802)
-- Name: tblbill ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblbill ALTER COLUMN "ID" SET DEFAULT nextval('public."tblbill_ID_seq"'::regclass);


--
-- TOC entry 3852 (class 2604 OID 16803)
-- Name: tblbilldetail ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblbilldetail ALTER COLUMN "ID" SET DEFAULT nextval('public."tblbilldetail_ID_seq"'::regclass);


--
-- TOC entry 3861 (class 2604 OID 16804)
-- Name: tblbillreturn ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblbillreturn ALTER COLUMN "ID" SET DEFAULT nextval('public."tblbillreturn_ID_seq"'::regclass);


--
-- TOC entry 3867 (class 2604 OID 16805)
-- Name: tblbrand ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblbrand ALTER COLUMN "ID" SET DEFAULT nextval('public."tblbrand_ID_seq"'::regclass);


--
-- TOC entry 3870 (class 2604 OID 16807)
-- Name: tblcheckstock ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblcheckstock ALTER COLUMN "ID" SET DEFAULT nextval('public."tblcheckstock_ID_seq"'::regclass);


--
-- TOC entry 3875 (class 2604 OID 16808)
-- Name: tblcheckstockaction ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblcheckstockaction ALTER COLUMN "ID" SET DEFAULT nextval('public."tblcheckstockaction_ID_seq"'::regclass);


--
-- TOC entry 3879 (class 2604 OID 16809)
-- Name: tblcounter ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblcounter ALTER COLUMN "ID" SET DEFAULT nextval('public."tblcounter_ID_seq"'::regclass);


--
-- TOC entry 4045 (class 2604 OID 17344)
-- Name: tblcurrency ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblcurrency ALTER COLUMN "ID" SET DEFAULT nextval('public."tblcurrency_ID_seq"'::regclass);


--
-- TOC entry 3884 (class 2604 OID 16811)
-- Name: tblcustomer ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblcustomer ALTER COLUMN "ID" SET DEFAULT nextval('public."tblcustomer_ID_seq"'::regclass);


--
-- TOC entry 3986 (class 2604 OID 16983)
-- Name: tblcustomerdoc ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblcustomerdoc ALTER COLUMN "ID" SET DEFAULT nextval('public."tblcustomerdoc_ID_seq"'::regclass);


--
-- TOC entry 3890 (class 2604 OID 16812)
-- Name: tbldailycashflow ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbldailycashflow ALTER COLUMN "ID" SET DEFAULT nextval('public."tbldailycashflow_ID_seq"'::regclass);


--
-- TOC entry 4028 (class 2604 OID 17255)
-- Name: tbldepartment ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbldepartment ALTER COLUMN "ID" SET DEFAULT nextval('public."tbldepartment_ID_seq"'::regclass);


--
-- TOC entry 3894 (class 2604 OID 16814)
-- Name: tbldiscounttype ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbldiscounttype ALTER COLUMN "ID" SET DEFAULT nextval('public."tbldiscounttype_ID_seq"'::regclass);


--
-- TOC entry 3897 (class 2604 OID 16815)
-- Name: tblearnpointtransaction ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblearnpointtransaction ALTER COLUMN "ID" SET DEFAULT nextval('public."tblearnpointtransaction_ID_seq"'::regclass);


--
-- TOC entry 3902 (class 2604 OID 16816)
-- Name: tbleexchange ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbleexchange ALTER COLUMN "ID" SET DEFAULT nextval('public."tbleexchange_ID_seq"'::regclass);


--
-- TOC entry 3905 (class 2604 OID 16817)
-- Name: tblempbankdetail ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblempbankdetail ALTER COLUMN "ID" SET DEFAULT nextval('public."tblempbankdetail_ID_seq"'::regclass);


--
-- TOC entry 4032 (class 2604 OID 17274)
-- Name: tblemployee ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblemployee ALTER COLUMN "ID" SET DEFAULT nextval('public."tblemployee_ID_seq"'::regclass);


--
-- TOC entry 4010 (class 2604 OID 17111)
-- Name: tblexpense ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblexpense ALTER COLUMN "ID" SET DEFAULT nextval('public."tblexpense_ID_seq"'::regclass);


--
-- TOC entry 3990 (class 2604 OID 17038)
-- Name: tblexpensetype ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblexpensetype ALTER COLUMN "ID" SET DEFAULT nextval('public."tblexpensetype_ID_seq"'::regclass);


--
-- TOC entry 4092 (class 2604 OID 19550)
-- Name: tblimportproductlot ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblimportproductlot ALTER COLUMN "ID" SET DEFAULT nextval('public."tblimportproductlot_ID_seq"'::regclass);


--
-- TOC entry 4095 (class 2604 OID 27668)
-- Name: tbllocation ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbllocation ALTER COLUMN "ID" SET DEFAULT nextval('public."tbllocation_ID_seq"'::regclass);


--
-- TOC entry 4103 (class 2604 OID 27705)
-- Name: tbllocationdetail ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbllocationdetail ALTER COLUMN "ID" SET DEFAULT nextval('public."tbllocationdetail_ID_seq"'::regclass);


--
-- TOC entry 3908 (class 2604 OID 16821)
-- Name: tblmember ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblmember ALTER COLUMN "ID" SET DEFAULT nextval('public."tblmember_ID_seq"'::regclass);


--
-- TOC entry 3914 (class 2604 OID 16822)
-- Name: tblmembertype ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblmembertype ALTER COLUMN "ID" SET DEFAULT nextval('public."tblmembertype_ID_seq"'::regclass);


--
-- TOC entry 4066 (class 2604 OID 19453)
-- Name: tblmenu ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblmenu ALTER COLUMN "ID" SET DEFAULT nextval('public."tblmenu_ID_seq"'::regclass);


--
-- TOC entry 3917 (class 2604 OID 16824)
-- Name: tblmenuprivilege ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblmenuprivilege ALTER COLUMN "ID" SET DEFAULT nextval('public."tblmenuprivilege_ID_seq"'::regclass);


--
-- TOC entry 3920 (class 2604 OID 16825)
-- Name: tblpacking ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblpacking ALTER COLUMN "ID" SET DEFAULT nextval('public."tblpacking_ID_seq"'::regclass);


--
-- TOC entry 4018 (class 2604 OID 17162)
-- Name: tblpayment ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblpayment ALTER COLUMN "ID" SET DEFAULT nextval('public."tblpayment_ID_seq"'::regclass);


--
-- TOC entry 3924 (class 2604 OID 16827)
-- Name: tblpaymentmethod ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblpaymentmethod ALTER COLUMN "ID" SET DEFAULT nextval('public."tblpaymentmethod_ID_seq"'::regclass);


--
-- TOC entry 3927 (class 2604 OID 16828)
-- Name: tblpayterm ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblpayterm ALTER COLUMN "ID" SET DEFAULT nextval('public."tblpayterm_ID_seq"'::regclass);


--
-- TOC entry 3930 (class 2604 OID 16829)
-- Name: tblpointtype ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblpointtype ALTER COLUMN "ID" SET DEFAULT nextval('public."tblpointtype_ID_seq"'::regclass);


--
-- TOC entry 3935 (class 2604 OID 16830)
-- Name: tblposition ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblposition ALTER COLUMN "ID" SET DEFAULT nextval('public."tblposition_ID_seq"'::regclass);


--
-- TOC entry 3938 (class 2604 OID 16831)
-- Name: tblproductcategory ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblproductcategory ALTER COLUMN "ID" SET DEFAULT nextval('public."tblproductcategory_ID_seq"'::regclass);


--
-- TOC entry 4070 (class 2604 OID 19468)
-- Name: tblproductlist ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblproductlist ALTER COLUMN "ID" SET DEFAULT nextval('public."tblproductlist_ID_seq"'::regclass);


--
-- TOC entry 3941 (class 2604 OID 16833)
-- Name: tblproducttype ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblproducttype ALTER COLUMN "ID" SET DEFAULT nextval('public."tblproducttype_ID_seq"'::regclass);


--
-- TOC entry 4002 (class 2604 OID 17084)
-- Name: tblpromotion ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblpromotion ALTER COLUMN "ID" SET DEFAULT nextval('public."tblpromotion_ID_seq"'::regclass);


--
-- TOC entry 3944 (class 2604 OID 16835)
-- Name: tblpromotiondetail ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblpromotiondetail ALTER COLUMN "ID" SET DEFAULT nextval('public."tblpromotiondetail_ID_seq"'::regclass);


--
-- TOC entry 3982 (class 2604 OID 16973)
-- Name: tblpromotiontype ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblpromotiontype ALTER COLUMN "ID" SET DEFAULT nextval('public."tblpromotiontype_ID_seq"'::regclass);


--
-- TOC entry 3994 (class 2604 OID 17050)
-- Name: tblpurchase ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblpurchase ALTER COLUMN "ID" SET DEFAULT nextval('public."tblpurchase_ID_seq"'::regclass);


--
-- TOC entry 3948 (class 2604 OID 16837)
-- Name: tblpurchasedetail ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblpurchasedetail ALTER COLUMN "ID" SET DEFAULT nextval('public."tblpurchasedetail_ID_seq"'::regclass);


--
-- TOC entry 4064 (class 2604 OID 19395)
-- Name: tblrefreshtoken ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblrefreshtoken ALTER COLUMN "ID" SET DEFAULT nextval('public."tblrefreshtoken_ID_seq"'::regclass);


--
-- TOC entry 4058 (class 2604 OID 19357)
-- Name: tblroute ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblroute ALTER COLUMN "ID" SET DEFAULT nextval('public."tblroute_ID_seq"'::regclass);


--
-- TOC entry 4061 (class 2604 OID 19368)
-- Name: tblroutedetail ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblroutedetail ALTER COLUMN "ID" SET DEFAULT nextval('public."tblroutedetail_ID_seq"'::regclass);


--
-- TOC entry 4006 (class 2604 OID 17104)
-- Name: tblsaletarget ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblsaletarget ALTER COLUMN "ID" SET DEFAULT nextval('public."tblsaletarget_ID_seq"'::regclass);


--
-- TOC entry 4074 (class 2604 OID 19487)
-- Name: tblselftype ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblselftype ALTER COLUMN "ID" SET DEFAULT nextval('public."tblselftype_ID_seq"'::regclass);


--
-- TOC entry 4099 (class 2604 OID 27684)
-- Name: tblsetting ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblsetting ALTER COLUMN "ID" SET DEFAULT nextval('public."tblsetting_ID_seq"'::regclass);


--
-- TOC entry 4082 (class 2604 OID 19511)
-- Name: tblshelf ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblshelf ALTER COLUMN "ID" SET DEFAULT nextval('public."tblshelf_ID_seq"'::regclass);


--
-- TOC entry 4088 (class 2604 OID 19537)
-- Name: tblshelftransfer ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblshelftransfer ALTER COLUMN "ID" SET DEFAULT nextval('public."tblshelftransfer_ID_seq"'::regclass);


--
-- TOC entry 4111 (class 2604 OID 27775)
-- Name: tblshift ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblshift ALTER COLUMN "ID" SET DEFAULT nextval('public."tblshift_ID_seq"'::regclass);


--
-- TOC entry 4107 (class 2604 OID 27740)
-- Name: tblshifttype ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblshifttype ALTER COLUMN "ID" SET DEFAULT nextval('public."tblshifttype_ID_seq"'::regclass);


--
-- TOC entry 3951 (class 2604 OID 16842)
-- Name: tblshipping ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblshipping ALTER COLUMN "ID" SET DEFAULT nextval('public."tblshipping_ID_seq"'::regclass);


--
-- TOC entry 3956 (class 2604 OID 16843)
-- Name: tblstatus ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblstatus ALTER COLUMN "ID" SET DEFAULT nextval('public."tblstatus_ID_seq"'::regclass);


--
-- TOC entry 3959 (class 2604 OID 16844)
-- Name: tblstatustype ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblstatustype ALTER COLUMN "ID" SET DEFAULT nextval('public."tblstatustype_ID_seq"'::regclass);


--
-- TOC entry 3997 (class 2604 OID 17074)
-- Name: tblstocktransfer ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblstocktransfer ALTER COLUMN "ID" SET DEFAULT nextval('public."tblstocktransfer_ID_seq"'::regclass);


--
-- TOC entry 3963 (class 2604 OID 16846)
-- Name: tblstocktransferdetail ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblstocktransferdetail ALTER COLUMN "ID" SET DEFAULT nextval('public."tblstocktransferdetail_ID_seq"'::regclass);


--
-- TOC entry 4049 (class 2604 OID 17402)
-- Name: tblsupplier ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblsupplier ALTER COLUMN "ID" SET DEFAULT nextval('public."tblsupplier_ID_seq"'::regclass);


--
-- TOC entry 3967 (class 2604 OID 16848)
-- Name: tblsupplierdetail ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblsupplierdetail ALTER COLUMN "ID" SET DEFAULT nextval('public."tblsupplierdoc_ID_seq"'::regclass);


--
-- TOC entry 4026 (class 2604 OID 17208)
-- Name: tblsystemlog ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblsystemlog ALTER COLUMN "ID" SET DEFAULT nextval('public."tblsystemlog_ID_seq"'::regclass);


--
-- TOC entry 4116 (class 2604 OID 27805)
-- Name: tbltax ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbltax ALTER COLUMN "ID" SET DEFAULT nextval('public."tbltax_ID_seq"'::regclass);


--
-- TOC entry 3970 (class 2604 OID 16850)
-- Name: tbltaxtype ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbltaxtype ALTER COLUMN "ID" SET DEFAULT nextval('public."tbltaxtype_ID_seq"'::regclass);


--
-- TOC entry 3973 (class 2604 OID 16851)
-- Name: tblunit ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblunit ALTER COLUMN "ID" SET DEFAULT nextval('public."tblunit_ID_seq"'::regclass);


--
-- TOC entry 4038 (class 2604 OID 17330)
-- Name: tbluser ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbluser ALTER COLUMN "ID" SET DEFAULT nextval('public."tbluser_ID_seq"'::regclass);


--
-- TOC entry 3977 (class 2604 OID 16853)
-- Name: tbluseractivity ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbluseractivity ALTER COLUMN "ID" SET DEFAULT nextval('public."tbluseractivity_ID_seq"'::regclass);


--
-- TOC entry 3979 (class 2604 OID 16854)
-- Name: tblvariation ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblvariation ALTER COLUMN "ID" SET DEFAULT nextval('public."tblvariation_ID_seq"'::regclass);


--
-- TOC entry 4014 (class 2604 OID 17147)
-- Name: tblwarranty ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblwarranty ALTER COLUMN "ID" SET DEFAULT nextval('public."tblwarranty_ID_seq"'::regclass);


--
-- TOC entry 4078 (class 2604 OID 19499)
-- Name: tblzone ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblzone ALTER COLUMN "ID" SET DEFAULT nextval('public."tblzone_ID_seq"'::regclass);


--
-- TOC entry 4398 (class 0 OID 16390)
-- Dependencies: 214
-- Data for Name: tblNotification; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4501 (class 0 OID 19320)
-- Dependencies: 317
-- Data for Name: tblapproval; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4400 (class 0 OID 16407)
-- Dependencies: 216
-- Data for Name: tblbill; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4402 (class 0 OID 16421)
-- Dependencies: 218
-- Data for Name: tblbilldetail; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4404 (class 0 OID 16433)
-- Dependencies: 220
-- Data for Name: tblbillreturn; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4406 (class 0 OID 16442)
-- Dependencies: 222
-- Data for Name: tblbrand; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4408 (class 0 OID 16455)
-- Dependencies: 224
-- Data for Name: tblcheckstock; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4410 (class 0 OID 16463)
-- Dependencies: 226
-- Data for Name: tblcheckstockaction; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4412 (class 0 OID 16470)
-- Dependencies: 228
-- Data for Name: tblcounter; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4496 (class 0 OID 17337)
-- Dependencies: 312
-- Data for Name: tblcurrency; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tblcurrency VALUES (2, '12.121.22.11', 'Baht', '฿', 'Thai Baht', 1, 38, 'IT', '2024-02-26 22:50:34.159814+07', '2024-02-26 22:50:34.159814+07');
INSERT INTO public.tblcurrency VALUES (4, '12.121.22.14', 'Dollar', '$', 'US Dollar', 2, 38, 'IT', '2024-02-26 22:52:24.763469+07', '2024-02-26 23:04:34.230424+07');
INSERT INTO public.tblcurrency VALUES (3, '12.121.22.15', 'Dollar', '$', 'US Dollar', 1, 38, 'IT', '2024-02-26 22:51:04.904024+07', '2024-02-26 23:11:44.559455+07');
INSERT INTO public.tblcurrency VALUES (1, '12.121.22.15', 'Kip', '₭', 'Lao Kip', 1, 38, 'IT', '2024-02-26 22:48:55.240155+07', '2024-02-26 23:11:48.553934+07');


--
-- TOC entry 4414 (class 0 OID 16485)
-- Dependencies: 230
-- Data for Name: tblcustomer; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4471 (class 0 OID 16980)
-- Dependencies: 287
-- Data for Name: tblcustomerdoc; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4416 (class 0 OID 16494)
-- Dependencies: 232
-- Data for Name: tbldailycashflow; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4490 (class 0 OID 17248)
-- Dependencies: 306
-- Data for Name: tbldepartment; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tbldepartment VALUES (4, 'Information Technology', 'Write something here', 1, 39, 'IT', '2024-02-22 21:40:27.404862+07', '2024-02-22 22:05:21.814972+07');
INSERT INTO public.tbldepartment VALUES (2, 'Information Technology', '888', 1, 39, 'IT', '2024-02-22 20:48:00.600711+07', '2024-02-22 21:58:23.354901+07');


--
-- TOC entry 4418 (class 0 OID 16508)
-- Dependencies: 234
-- Data for Name: tbldiscounttype; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tbldiscounttype VALUES (1, 'Fixed', 'Amount of discount is fix as number. e.g: 5,000', 1, 1, 'System', '2024-01-01 22:05:35.273886+07', '2024-01-01 22:05:35.273886+07');
INSERT INTO public.tbldiscounttype VALUES (2, 'Percentage', 'Amount of discount is input as % and need to calculate', 1, 1, 'System', '2024-01-01 22:05:35.273886+07', '2024-01-01 22:05:35.273886+07');


--
-- TOC entry 4420 (class 0 OID 16514)
-- Dependencies: 236
-- Data for Name: tblearnpointtransaction; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4422 (class 0 OID 16522)
-- Dependencies: 238
-- Data for Name: tbleexchange; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4424 (class 0 OID 16528)
-- Dependencies: 240
-- Data for Name: tblempbankdetail; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4492 (class 0 OID 17265)
-- Dependencies: 308
-- Data for Name: tblemployee; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tblemployee VALUES (1, '1.1.1.1', 'VIP24-1993', 1, 'Admin', 'Dev', 'admin@itc.la', '1990-12-22', 1, NULL, NULL, NULL, 1, 1, 1, NULL, NULL, NULL, 1, 1, 'System', '2024-02-03 20:47:34.701535+07', '2024-02-03 20:47:34.701535+07');


--
-- TOC entry 4483 (class 0 OID 17108)
-- Dependencies: 299
-- Data for Name: tblexpense; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4473 (class 0 OID 17035)
-- Dependencies: 289
-- Data for Name: tblexpensetype; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4521 (class 0 OID 19547)
-- Dependencies: 337
-- Data for Name: tblimportproductlot; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4523 (class 0 OID 27665)
-- Dependencies: 339
-- Data for Name: tbllocation; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tbllocation VALUES (38, '1.1.1.1', 'Vientaine', '20333333', '2100394930493', '2055995858', 12.0000202, 102.03493049, 'Adreseflkdjlfdsjflds', 'uploads/locations/image/737d36bf-5379-4fc5-99b3-524fa7c596e8.jpg', 'uploads/locations/documents/pdf/9792b281-2f36-4028-ace5-0f9214ad0e63.pdf', 'sdfds', 1, 'IT', '2024-02-14 23:53:37.472821+07', '2024-02-14 23:53:37.472821+07');
INSERT INTO public.tbllocation VALUES (39, '1.1.1.1', 'Vientaine', '20333333', '2100394930493', '2055995858', 12.0000202, 102.03493049, 'Adreseflkdjlfdsjflds', 'uploads/locations/image/8bcee62d-09e9-4760-8f00-002dc5d8ba51.jpg', 'uploads/locations/documents/pdf/0b0f09d4-fb9d-4158-a275-10c2265fb0db.pdf', 'sdfds', 1, 'IT', '2024-02-14 23:53:38.54357+07', '2024-02-14 23:53:38.54357+07');
INSERT INTO public.tbllocation VALUES (40, '3.3.3.3', 'Vientaine', '20333333', '2100394930493', '2055995858', 12.0000202, 102.03493049, 'Adreseflkdjlfdsjflds', 'uploads/locations/image/2ec4363a-89d0-46c5-9864-7ceac4aa8e0a.jpg|uploads/locations/image/f79f88f8-04aa-4644-af74-4d53d735ee06.png|uploads/locations/image/e29ad4e7-e8ca-4a07-ada2-0c594b368bd6.png', 'uploads/locations/documents/pdf/97472062-4815-43de-a649-3d987e04e763.pdf', 'sdfds', 1, 'IT', '2024-02-14 23:57:45.584795+07', '2024-02-21 22:45:53.274602+07');


--
-- TOC entry 4527 (class 0 OID 27702)
-- Dependencies: 343
-- Data for Name: tbllocationdetail; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tbllocationdetail VALUES (4, 'BCELONE', 'Phonesai', '1002-9393-1939-1393', 'uploads/location-details/image/8cfe0e6b-c799-4d9d-bbbd-3d2ca7bf9835.png', 'BCEL Note and Description for understanding', 1, 38, 'IT', '2024-02-22 19:42:54.309767+07', '2024-02-22 20:24:44.69857+07');


--
-- TOC entry 4426 (class 0 OID 16556)
-- Dependencies: 242
-- Data for Name: tblmember; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4428 (class 0 OID 16565)
-- Dependencies: 244
-- Data for Name: tblmembertype; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4508 (class 0 OID 19444)
-- Dependencies: 324
-- Data for Name: tblmenu; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tblmenu VALUES (1, NULL, '1001', 'Home', NULL, 1, NULL, 1, NULL, 'System', '2024-02-04 23:39:21.918278+07', '2024-02-04 23:39:21.918278+07');
INSERT INTO public.tblmenu VALUES (2, NULL, '1002', 'Dashboard', NULL, 1, NULL, 1, NULL, 'System', '2024-02-05 00:14:05.152361+07', '2024-02-05 00:14:05.152361+07');


--
-- TOC entry 4430 (class 0 OID 16577)
-- Dependencies: 246
-- Data for Name: tblmenuprivilege; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tblmenuprivilege VALUES (1, 1, '1001,1002', NULL, 'System', '2024-02-04 23:48:02.396505+07', '2024-02-04 23:48:02.396505+07');


--
-- TOC entry 4432 (class 0 OID 16583)
-- Dependencies: 248
-- Data for Name: tblpacking; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4486 (class 0 OID 17151)
-- Dependencies: 302
-- Data for Name: tblpayment; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4434 (class 0 OID 16600)
-- Dependencies: 250
-- Data for Name: tblpaymentmethod; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tblpaymentmethod VALUES (1, 'Advance', NULL, 1, 1, 'System', '2023-12-28 18:37:52.168962+07', '2023-12-28 18:37:52.168962+07');
INSERT INTO public.tblpaymentmethod VALUES (2, 'Visa Card', NULL, 1, 1, 'System', '2023-12-28 18:37:57.93228+07', '2023-12-28 18:37:57.93228+07');
INSERT INTO public.tblpaymentmethod VALUES (3, 'Master Card', NULL, 1, 1, 'System', '2023-12-28 18:38:04.233372+07', '2023-12-28 18:38:04.233372+07');
INSERT INTO public.tblpaymentmethod VALUES (4, 'Credit Card', NULL, 1, 1, 'System', '2023-12-28 18:38:13.29199+07', '2023-12-28 18:38:13.29199+07');
INSERT INTO public.tblpaymentmethod VALUES (5, 'Debit Card', NULL, 1, 1, 'System', '2023-12-28 18:38:17.467765+07', '2023-12-28 18:38:17.467765+07');
INSERT INTO public.tblpaymentmethod VALUES (6, 'Cheque', NULL, 1, 1, 'System', '2023-12-28 18:38:47.926407+07', '2023-12-28 18:38:47.926407+07');
INSERT INTO public.tblpaymentmethod VALUES (7, 'Bank Transfer', NULL, 1, 1, 'System', '2023-12-28 18:38:53.376638+07', '2023-12-28 18:38:53.376638+07');
INSERT INTO public.tblpaymentmethod VALUES (8, 'Other', NULL, 1, 1, 'System', '2023-12-28 18:38:57.761828+07', '2023-12-28 18:38:57.761828+07');


--
-- TOC entry 4436 (class 0 OID 16606)
-- Dependencies: 252
-- Data for Name: tblpayterm; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tblpayterm VALUES (1, 'Per Day', NULL, 1, 1, 'System', '2023-12-28 18:32:23.227934+07', '2023-12-28 18:32:23.227934+07');
INSERT INTO public.tblpayterm VALUES (2, 'Per Week', NULL, 1, 1, 'System', '2023-12-28 18:32:31.360664+07', '2023-12-28 18:32:31.360664+07');
INSERT INTO public.tblpayterm VALUES (3, 'Per Month', NULL, 1, 1, 'System', '2023-12-28 18:32:36.453782+07', '2023-12-28 18:32:36.453782+07');
INSERT INTO public.tblpayterm VALUES (4, 'Per Year', NULL, 1, 1, 'System', '2023-12-28 18:32:42.331297+07', '2023-12-28 18:32:42.331297+07');


--
-- TOC entry 4438 (class 0 OID 16612)
-- Dependencies: 254
-- Data for Name: tblpointtype; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tblpointtype VALUES (1, NULL, 'Point', 0, 0, 'Member collect into point', 1, 'System', '2024-01-03 21:45:06.607335+07', '2024-01-03 21:45:06.607335+07');
INSERT INTO public.tblpointtype VALUES (2, NULL, 'Balance', 0, 0, 'Member collect into balance', 1, 'System', '2024-01-03 21:45:06.607335+07', '2024-01-03 21:45:06.607335+07');


--
-- TOC entry 4440 (class 0 OID 16620)
-- Dependencies: 256
-- Data for Name: tblposition; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4442 (class 0 OID 16626)
-- Dependencies: 258
-- Data for Name: tblproductcategory; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4510 (class 0 OID 19459)
-- Dependencies: 326
-- Data for Name: tblproductlist; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4444 (class 0 OID 16641)
-- Dependencies: 260
-- Data for Name: tblproducttype; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4478 (class 0 OID 17077)
-- Dependencies: 294
-- Data for Name: tblpromotion; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4446 (class 0 OID 16654)
-- Dependencies: 262
-- Data for Name: tblpromotiondetail; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4469 (class 0 OID 16970)
-- Dependencies: 285
-- Data for Name: tblpromotiontype; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4474 (class 0 OID 17044)
-- Dependencies: 290
-- Data for Name: tblpurchase; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4448 (class 0 OID 16667)
-- Dependencies: 264
-- Data for Name: tblpurchasedetail; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4507 (class 0 OID 19392)
-- Dependencies: 323
-- Data for Name: tblrefreshtoken; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tblrefreshtoken VALUES (41, 1, 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJJRCI6MSwiRW1wSUQiOiJWSVAyNC0xOTkzIiwiVXNlck5hbWUiOiJJVCIsIlJvbGUiOjIsIlVzZXJMb2NhdGlvbiI6MzgsImlhdCI6MTcxMTc5ODYxNiwiZXhwIjoxNzExODg1MDE2fQ.E-n0E2SMBtO3uVrZprTTFgqt-OdGcHPR-jRpyTL9pDWUTXydZdmZXiEI8Fl5nhuOlwuAfXslRO1XcHjYK1nOaaeBgPBdsiGkuP-jLaxXExJk8dCoDJHi1C62tPFs2A20SgZ6phJZUBL2BLL3J2dXCx8rzx-2XRj5_am7H7TtLp82gohtRG9HmGBUTITzxT-ZdQQOMLu3_iSWRprAwMCGkvvoy2DtD1tacGRJmjQu-p4XSsYDKsMfod5dowS4tWE1nGlQPbxJ2GXa-G6ArRzNG0zdBzGWpjA0ob0wn2pq9EhiSjh93bf1DNHyr-CQDqPV2fUHzuH9JDwM9ZpvXSKLuw', '2024-03-30 18:36:56.524653+07');


--
-- TOC entry 4503 (class 0 OID 19354)
-- Dependencies: 319
-- Data for Name: tblroute; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4505 (class 0 OID 19365)
-- Dependencies: 321
-- Data for Name: tblroutedetail; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4480 (class 0 OID 17097)
-- Dependencies: 296
-- Data for Name: tblsaletarget; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4513 (class 0 OID 19484)
-- Dependencies: 329
-- Data for Name: tblselftype; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4525 (class 0 OID 27681)
-- Dependencies: 341
-- Data for Name: tblsetting; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4517 (class 0 OID 19508)
-- Dependencies: 333
-- Data for Name: tblshelf; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4519 (class 0 OID 19534)
-- Dependencies: 335
-- Data for Name: tblshelftransfer; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4531 (class 0 OID 27772)
-- Dependencies: 347
-- Data for Name: tblshift; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tblshift VALUES (1, 'B', 2, '13:59', '19:59', 2, 'Shift B', 1, 38, 'IT', '2024-02-23 23:14:08.657148+07', '2024-02-23 23:33:11.639039+07');
INSERT INTO public.tblshift VALUES (2, 'A', 1, '07:59', '16:59', 1, 'Write something here', 1, 39, 'IT', '2024-02-23 23:32:11.045204+07', '2024-02-23 23:36:38.167776+07');


--
-- TOC entry 4529 (class 0 OID 27737)
-- Dependencies: 345
-- Data for Name: tblshifttype; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tblshifttype VALUES (1, 'ShiftType', 'Write something about This ShiftType', 1, 38, 'IT', '2024-02-23 21:35:32.594569+07', '2024-02-23 21:35:32.594569+07');
INSERT INTO public.tblshifttype VALUES (2, 'Flexible', 'Can change shift', 1, 38, 'System', '2024-02-23 21:38:07.640375+07', '2024-02-23 21:38:07.640375+07');
INSERT INTO public.tblshifttype VALUES (3, 'Fixed', 'Can not change shift', 1, 38, 'System', '2024-02-23 21:38:07.640375+07', '2024-02-23 21:38:07.640375+07');


--
-- TOC entry 4450 (class 0 OID 16699)
-- Dependencies: 266
-- Data for Name: tblshipping; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4452 (class 0 OID 16709)
-- Dependencies: 268
-- Data for Name: tblstatus; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tblstatus VALUES (1, 'Proccessing', 3, NULL, 1, 1, 'System', '2024-01-01 23:05:58.270524+07', '2024-01-01 23:05:58.270524+07');
INSERT INTO public.tblstatus VALUES (2, 'Completed', 3, NULL, 1, 1, 'System', '2024-01-01 23:05:58.270524+07', '2024-01-01 23:05:58.270524+07');
INSERT INTO public.tblstatus VALUES (3, 'In Transit', 3, NULL, 1, 1, 'System', '2024-01-01 23:05:58.270524+07', '2024-01-01 23:05:58.270524+07');
INSERT INTO public.tblstatus VALUES (4, 'Partial Return', 6, NULL, 1, 1, 'System', '2024-01-01 23:05:58.270524+07', '2024-01-01 23:05:58.270524+07');
INSERT INTO public.tblstatus VALUES (5, 'Normal', 6, NULL, 1, 1, 'System', '2024-01-01 23:05:58.270524+07', '2024-01-01 23:05:58.270524+07');
INSERT INTO public.tblstatus VALUES (6, 'Partial Paid', 6, NULL, 1, 1, 'System', '2024-01-01 23:05:58.270524+07', '2024-01-01 23:05:58.270524+07');
INSERT INTO public.tblstatus VALUES (7, 'Paid', 6, NULL, 1, 1, 'System', '2024-01-01 23:05:58.270524+07', '2024-01-01 23:05:58.270524+07');
INSERT INTO public.tblstatus VALUES (8, 'Due', 6, NULL, 1, 1, 'System', '2024-01-01 23:05:58.270524+07', '2024-01-01 23:05:58.270524+07');
INSERT INTO public.tblstatus VALUES (11, 'Expired', NULL, NULL, 1, 1, 'System', '2024-01-01 23:05:58.270524+07', '2024-01-01 23:05:58.270524+07');
INSERT INTO public.tblstatus VALUES (12, 'Valid', NULL, NULL, 1, 1, 'System', '2024-01-01 23:05:58.270524+07', '2024-01-01 23:05:58.270524+07');
INSERT INTO public.tblstatus VALUES (13, 'Return', 6, NULL, 1, 1, 'System', '2024-01-01 23:05:58.270524+07', '2024-01-01 23:05:58.270524+07');
INSERT INTO public.tblstatus VALUES (14, 'Postpone', NULL, NULL, 1, 1, 'System', '2024-01-01 23:05:58.270524+07', '2024-01-01 23:05:58.270524+07');
INSERT INTO public.tblstatus VALUES (15, 'Canceled', NULL, NULL, 1, 1, 'System', '2024-01-01 23:05:58.270524+07', '2024-01-01 23:05:58.270524+07');
INSERT INTO public.tblstatus VALUES (16, 'OutStock', 7, NULL, 1, 1, 'System', '2024-01-01 23:05:58.270524+07', '2024-01-01 23:05:58.270524+07');
INSERT INTO public.tblstatus VALUES (17, 'isStock', 7, NULL, 1, 1, 'System', '2024-01-01 23:05:58.270524+07', '2024-01-01 23:05:58.270524+07');
INSERT INTO public.tblstatus VALUES (18, 'Pending', NULL, NULL, 1, 1, 'System', '2024-01-01 23:05:58.270524+07', '2024-01-01 23:05:58.270524+07');
INSERT INTO public.tblstatus VALUES (9, 'Inactive', 11, NULL, 1, 1, 'System', '2024-01-01 23:05:58.270524+07', '2024-01-01 23:05:58.270524+07');
INSERT INTO public.tblstatus VALUES (10, 'Active', 11, NULL, 1, 1, 'System', '2024-01-01 23:05:58.270524+07', '2024-01-01 23:05:58.270524+07');


--
-- TOC entry 4454 (class 0 OID 16715)
-- Dependencies: 270
-- Data for Name: tblstatustype; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4476 (class 0 OID 17066)
-- Dependencies: 292
-- Data for Name: tblstocktransfer; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4456 (class 0 OID 16730)
-- Dependencies: 272
-- Data for Name: tblstocktransferdetail; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4498 (class 0 OID 17391)
-- Dependencies: 314
-- Data for Name: tblsupplier; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4458 (class 0 OID 16748)
-- Dependencies: 274
-- Data for Name: tblsupplierdetail; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4489 (class 0 OID 17205)
-- Dependencies: 305
-- Data for Name: tblsystemlog; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tblsystemlog VALUES (246, 'fn_tax_dql', '2201X', 'OFFSET must not be negative', 38, 'IT', 'PARTIAL', '2024-02-26 21:40:17.948524+07');
INSERT INTO public.tblsystemlog VALUES (247, 'fn_tax_dql', '42P01', 'missing FROM-clause entry for table "b"', 38, 'IT', 'SEARCH', '2024-02-26 21:40:48.954147+07');
INSERT INTO public.tblsystemlog VALUES (248, 'fn_tax_dql', '42P01', 'missing FROM-clause entry for table "b"', 38, 'IT', 'SEARCH', '2024-02-26 21:41:31.66892+07');
INSERT INTO public.tblsystemlog VALUES (249, 'fn_tax_dql', '42P01', 'missing FROM-clause entry for table "b"', 38, 'IT', 'SEARCH', '2024-02-26 21:41:33.922473+07');
INSERT INTO public.tblsystemlog VALUES (250, 'fn_tax_dql', '42P01', 'missing FROM-clause entry for table "b"', 38, 'IT', 'SEARCH', '2024-02-26 21:41:50.427166+07');
INSERT INTO public.tblsystemlog VALUES (251, 'fn_tax_dql', '42P01', 'missing FROM-clause entry for table "b"', 38, 'IT', 'SEARCH', '2024-02-26 21:43:17.46457+07');
INSERT INTO public.tblsystemlog VALUES (252, 'fn_tax_dql', '42P01', 'missing FROM-clause entry for table "b"', 38, 'IT', 'SEARCH', '2024-02-26 21:44:26.835703+07');
INSERT INTO public.tblsystemlog VALUES (253, 'fn_tax_dql', '42883', 'operator does not exist: double precision ~~* text', 38, 'IT', 'SEARCH', '2024-02-26 21:45:58.100112+07');
INSERT INTO public.tblsystemlog VALUES (260, 'fn_currency_dql', '42883', 'operator does not exist: integer ~~ text', 38, 'IT', 'SEARCH', '2024-02-26 23:16:55.409028+07');
INSERT INTO public.tblsystemlog VALUES (261, 'fn_currency_dql', '42883', 'operator does not exist: integer ~~ text', 38, 'IT', 'SEARCH', '2024-02-26 23:17:04.521843+07');


--
-- TOC entry 4533 (class 0 OID 27802)
-- Dependencies: 349
-- Data for Name: tbltax; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tbltax VALUES (2, 'PKT-IMPORT', 0.2, 'This tax is used for PKT import only', 1, 38, 'IT', '2024-02-26 20:48:12.317846+07', '2024-02-26 20:48:12.317846+07');
INSERT INTO public.tbltax VALUES (1, 'SOS-STAFF', 12, 'Government SOS', 1, 39, 'IT', '2024-02-26 20:46:45.636392+07', '2024-03-30 18:50:25.875835+07');


--
-- TOC entry 4460 (class 0 OID 16760)
-- Dependencies: 276
-- Data for Name: tbltaxtype; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tbltaxtype VALUES (1, 'Inclusive', '', 1, 38, 'System', '2023-12-28 18:23:32.846911+07', '2023-12-28 18:23:32.846911+07');
INSERT INTO public.tbltaxtype VALUES (2, 'Exclusive', '', 1, 38, 'System', '2023-12-28 18:23:40.925786+07', '2023-12-28 18:23:40.925786+07');
INSERT INTO public.tbltaxtype VALUES (3, 'None', '', 1, 38, 'System', '2023-12-28 18:23:45.438869+07', '2023-12-28 18:23:45.438869+07');


--
-- TOC entry 4462 (class 0 OID 16766)
-- Dependencies: 278
-- Data for Name: tblunit; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4494 (class 0 OID 17320)
-- Dependencies: 310
-- Data for Name: tbluser; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tbluser VALUES (1, 1, 'IT', '$2b$10$vY5ud3IUDO2E4TSBEQh/wu7w3BbpjM9c45TH/UO7odPIepKg2COru', 2, 0, 0, 1, 38, NULL, 'System', '2024-02-03 20:41:24.076382+07', '2024-03-30 18:36:56.511311+07');


--
-- TOC entry 4464 (class 0 OID 16782)
-- Dependencies: 280
-- Data for Name: tbluseractivity; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tbluseractivity VALUES (1, '2024-02-03 22:44:21.020621+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (2, '2024-02-04 00:22:39.478458+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (3, '2024-02-04 00:23:31.038431+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (4, '2024-02-04 00:31:21.520969+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (5, '2024-02-04 00:31:54.744179+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (6, '2024-02-04 00:41:04.838109+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (7, '2024-02-04 01:42:54.694546+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (8, '2024-02-04 01:45:08.487272+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (9, '2024-02-04 01:47:36.981064+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (10, '2024-02-04 01:49:57.866688+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (11, '2024-02-04 23:36:39.802086+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (12, '2024-02-09 23:06:19.984277+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (13, '2024-02-10 00:33:17.761604+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (14, '2024-02-10 00:49:32.716012+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (15, '2024-02-10 00:56:31.512165+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (16, '2024-02-10 01:02:49.722718+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (17, '2024-02-10 14:33:56.838877+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (18, '2024-02-10 15:18:43.163875+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (19, '2024-02-11 17:43:11.402891+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (20, '2024-02-14 18:11:55.446428+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (21, '2024-02-14 20:34:37.254856+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (22, '2024-02-21 18:23:17.585759+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (23, '2024-02-21 21:43:51.271903+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (24, '2024-02-21 21:46:20.713405+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (25, '2024-02-21 21:50:21.996661+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (26, '2024-02-21 21:50:48.123831+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (27, '2024-02-21 21:51:13.475599+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (28, '2024-02-21 22:02:44.774254+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (29, '2024-02-22 18:57:45.369212+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (30, '2024-02-22 19:44:20.976262+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (31, '2024-02-22 19:50:21.764901+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (32, '2024-02-23 21:28:23.675139+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (33, '2024-02-26 19:41:42.566305+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (34, '2024-03-25 22:40:06.328647+07', 'Login', 1, 'Login', 'Record by system');
INSERT INTO public.tbluseractivity VALUES (35, '2024-03-30 18:36:56.529279+07', 'Login', 1, 'Login', 'Record by system');


--
-- TOC entry 4466 (class 0 OID 16787)
-- Dependencies: 282
-- Data for Name: tblvariation; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4484 (class 0 OID 17140)
-- Dependencies: 300
-- Data for Name: tblwarranty; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4515 (class 0 OID 19496)
-- Dependencies: 331
-- Data for Name: tblzone; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 4607 (class 0 OID 0)
-- Dependencies: 215
-- Name: tblNotification_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblNotification_ID_seq"', 1, false);


--
-- TOC entry 4608 (class 0 OID 0)
-- Dependencies: 316
-- Name: tblapproval_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblapproval_ID_seq"', 1, false);


--
-- TOC entry 4609 (class 0 OID 0)
-- Dependencies: 217
-- Name: tblbill_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblbill_ID_seq"', 1, false);


--
-- TOC entry 4610 (class 0 OID 0)
-- Dependencies: 219
-- Name: tblbilldetail_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblbilldetail_ID_seq"', 1, false);


--
-- TOC entry 4611 (class 0 OID 0)
-- Dependencies: 221
-- Name: tblbillreturn_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblbillreturn_ID_seq"', 1, false);


--
-- TOC entry 4612 (class 0 OID 0)
-- Dependencies: 223
-- Name: tblbrand_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblbrand_ID_seq"', 1, false);


--
-- TOC entry 4613 (class 0 OID 0)
-- Dependencies: 225
-- Name: tblcheckstock_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblcheckstock_ID_seq"', 1, false);


--
-- TOC entry 4614 (class 0 OID 0)
-- Dependencies: 227
-- Name: tblcheckstockaction_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblcheckstockaction_ID_seq"', 1, false);


--
-- TOC entry 4615 (class 0 OID 0)
-- Dependencies: 229
-- Name: tblcounter_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblcounter_ID_seq"', 1, false);


--
-- TOC entry 4616 (class 0 OID 0)
-- Dependencies: 313
-- Name: tblcurrency_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblcurrency_ID_seq"', 4, true);


--
-- TOC entry 4617 (class 0 OID 0)
-- Dependencies: 231
-- Name: tblcustomer_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblcustomer_ID_seq"', 1, false);


--
-- TOC entry 4618 (class 0 OID 0)
-- Dependencies: 286
-- Name: tblcustomerdoc_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblcustomerdoc_ID_seq"', 1, false);


--
-- TOC entry 4619 (class 0 OID 0)
-- Dependencies: 233
-- Name: tbldailycashflow_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tbldailycashflow_ID_seq"', 1, false);


--
-- TOC entry 4620 (class 0 OID 0)
-- Dependencies: 307
-- Name: tbldepartment_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tbldepartment_ID_seq"', 4, true);


--
-- TOC entry 4621 (class 0 OID 0)
-- Dependencies: 235
-- Name: tbldiscounttype_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tbldiscounttype_ID_seq"', 2, true);


--
-- TOC entry 4622 (class 0 OID 0)
-- Dependencies: 237
-- Name: tblearnpointtransaction_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblearnpointtransaction_ID_seq"', 1, false);


--
-- TOC entry 4623 (class 0 OID 0)
-- Dependencies: 239
-- Name: tbleexchange_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tbleexchange_ID_seq"', 1, false);


--
-- TOC entry 4624 (class 0 OID 0)
-- Dependencies: 241
-- Name: tblempbankdetail_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblempbankdetail_ID_seq"', 1, false);


--
-- TOC entry 4625 (class 0 OID 0)
-- Dependencies: 309
-- Name: tblemployee_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblemployee_ID_seq"', 1, true);


--
-- TOC entry 4626 (class 0 OID 0)
-- Dependencies: 298
-- Name: tblexpense_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblexpense_ID_seq"', 1, false);


--
-- TOC entry 4627 (class 0 OID 0)
-- Dependencies: 288
-- Name: tblexpensetype_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblexpensetype_ID_seq"', 1, false);


--
-- TOC entry 4628 (class 0 OID 0)
-- Dependencies: 336
-- Name: tblimportproductlot_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblimportproductlot_ID_seq"', 1, false);


--
-- TOC entry 4629 (class 0 OID 0)
-- Dependencies: 338
-- Name: tbllocation_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tbllocation_ID_seq"', 40, true);


--
-- TOC entry 4630 (class 0 OID 0)
-- Dependencies: 342
-- Name: tbllocationdetail_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tbllocationdetail_ID_seq"', 4, true);


--
-- TOC entry 4631 (class 0 OID 0)
-- Dependencies: 243
-- Name: tblmember_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblmember_ID_seq"', 1, false);


--
-- TOC entry 4632 (class 0 OID 0)
-- Dependencies: 245
-- Name: tblmembertype_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblmembertype_ID_seq"', 1, false);


--
-- TOC entry 4633 (class 0 OID 0)
-- Dependencies: 325
-- Name: tblmenu_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblmenu_ID_seq"', 2, true);


--
-- TOC entry 4634 (class 0 OID 0)
-- Dependencies: 247
-- Name: tblmenuprivilege_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblmenuprivilege_ID_seq"', 1, true);


--
-- TOC entry 4635 (class 0 OID 0)
-- Dependencies: 249
-- Name: tblpacking_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblpacking_ID_seq"', 1, false);


--
-- TOC entry 4636 (class 0 OID 0)
-- Dependencies: 303
-- Name: tblpayment_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblpayment_ID_seq"', 1, false);


--
-- TOC entry 4637 (class 0 OID 0)
-- Dependencies: 251
-- Name: tblpaymentmethod_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblpaymentmethod_ID_seq"', 8, true);


--
-- TOC entry 4638 (class 0 OID 0)
-- Dependencies: 253
-- Name: tblpayterm_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblpayterm_ID_seq"', 4, true);


--
-- TOC entry 4639 (class 0 OID 0)
-- Dependencies: 255
-- Name: tblpointtype_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblpointtype_ID_seq"', 2, true);


--
-- TOC entry 4640 (class 0 OID 0)
-- Dependencies: 257
-- Name: tblposition_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblposition_ID_seq"', 1, false);


--
-- TOC entry 4641 (class 0 OID 0)
-- Dependencies: 259
-- Name: tblproductcategory_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblproductcategory_ID_seq"', 1, false);


--
-- TOC entry 4642 (class 0 OID 0)
-- Dependencies: 327
-- Name: tblproductlist_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblproductlist_ID_seq"', 1, false);


--
-- TOC entry 4643 (class 0 OID 0)
-- Dependencies: 261
-- Name: tblproducttype_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblproducttype_ID_seq"', 1, false);


--
-- TOC entry 4644 (class 0 OID 0)
-- Dependencies: 295
-- Name: tblpromotion_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblpromotion_ID_seq"', 1, false);


--
-- TOC entry 4645 (class 0 OID 0)
-- Dependencies: 263
-- Name: tblpromotiondetail_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblpromotiondetail_ID_seq"', 1, false);


--
-- TOC entry 4646 (class 0 OID 0)
-- Dependencies: 284
-- Name: tblpromotiontype_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblpromotiontype_ID_seq"', 1, false);


--
-- TOC entry 4647 (class 0 OID 0)
-- Dependencies: 291
-- Name: tblpurchase_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblpurchase_ID_seq"', 1, false);


--
-- TOC entry 4648 (class 0 OID 0)
-- Dependencies: 265
-- Name: tblpurchasedetail_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblpurchasedetail_ID_seq"', 1, false);


--
-- TOC entry 4649 (class 0 OID 0)
-- Dependencies: 322
-- Name: tblrefreshtoken_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblrefreshtoken_ID_seq"', 41, true);


--
-- TOC entry 4650 (class 0 OID 0)
-- Dependencies: 318
-- Name: tblroute_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblroute_ID_seq"', 1, false);


--
-- TOC entry 4651 (class 0 OID 0)
-- Dependencies: 320
-- Name: tblroutedetail_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblroutedetail_ID_seq"', 1, false);


--
-- TOC entry 4652 (class 0 OID 0)
-- Dependencies: 297
-- Name: tblsaletarget_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblsaletarget_ID_seq"', 1, false);


--
-- TOC entry 4653 (class 0 OID 0)
-- Dependencies: 328
-- Name: tblselftype_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblselftype_ID_seq"', 1, false);


--
-- TOC entry 4654 (class 0 OID 0)
-- Dependencies: 340
-- Name: tblsetting_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblsetting_ID_seq"', 1, false);


--
-- TOC entry 4655 (class 0 OID 0)
-- Dependencies: 332
-- Name: tblshelf_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblshelf_ID_seq"', 1, false);


--
-- TOC entry 4656 (class 0 OID 0)
-- Dependencies: 334
-- Name: tblshelftransfer_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblshelftransfer_ID_seq"', 1, false);


--
-- TOC entry 4657 (class 0 OID 0)
-- Dependencies: 346
-- Name: tblshift_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblshift_ID_seq"', 2, true);


--
-- TOC entry 4658 (class 0 OID 0)
-- Dependencies: 344
-- Name: tblshifttype_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblshifttype_ID_seq"', 3, true);


--
-- TOC entry 4659 (class 0 OID 0)
-- Dependencies: 267
-- Name: tblshipping_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblshipping_ID_seq"', 1, false);


--
-- TOC entry 4660 (class 0 OID 0)
-- Dependencies: 269
-- Name: tblstatus_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblstatus_ID_seq"', 18, true);


--
-- TOC entry 4661 (class 0 OID 0)
-- Dependencies: 271
-- Name: tblstatustype_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblstatustype_ID_seq"', 1, false);


--
-- TOC entry 4662 (class 0 OID 0)
-- Dependencies: 293
-- Name: tblstocktransfer_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblstocktransfer_ID_seq"', 1, false);


--
-- TOC entry 4663 (class 0 OID 0)
-- Dependencies: 273
-- Name: tblstocktransferdetail_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblstocktransferdetail_ID_seq"', 1, false);


--
-- TOC entry 4664 (class 0 OID 0)
-- Dependencies: 315
-- Name: tblsupplier_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblsupplier_ID_seq"', 1, false);


--
-- TOC entry 4665 (class 0 OID 0)
-- Dependencies: 275
-- Name: tblsupplierdoc_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblsupplierdoc_ID_seq"', 1, false);


--
-- TOC entry 4666 (class 0 OID 0)
-- Dependencies: 304
-- Name: tblsystemlog_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblsystemlog_ID_seq"', 261, true);


--
-- TOC entry 4667 (class 0 OID 0)
-- Dependencies: 348
-- Name: tbltax_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tbltax_ID_seq"', 2, true);


--
-- TOC entry 4668 (class 0 OID 0)
-- Dependencies: 277
-- Name: tbltaxtype_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tbltaxtype_ID_seq"', 3, true);


--
-- TOC entry 4669 (class 0 OID 0)
-- Dependencies: 279
-- Name: tblunit_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblunit_ID_seq"', 1, false);


--
-- TOC entry 4670 (class 0 OID 0)
-- Dependencies: 311
-- Name: tbluser_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tbluser_ID_seq"', 1, true);


--
-- TOC entry 4671 (class 0 OID 0)
-- Dependencies: 281
-- Name: tbluseractivity_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tbluseractivity_ID_seq"', 35, true);


--
-- TOC entry 4672 (class 0 OID 0)
-- Dependencies: 283
-- Name: tblvariation_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblvariation_ID_seq"', 1, false);


--
-- TOC entry 4673 (class 0 OID 0)
-- Dependencies: 301
-- Name: tblwarranty_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblwarranty_ID_seq"', 1, false);


--
-- TOC entry 4674 (class 0 OID 0)
-- Dependencies: 330
-- Name: tblzone_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."tblzone_ID_seq"', 1, false);


--
-- TOC entry 4121 (class 2606 OID 16857)
-- Name: tblNotification tblNotification_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."tblNotification"
    ADD CONSTRAINT "tblNotification_pkey" PRIMARY KEY ("ID");


--
-- TOC entry 4223 (class 2606 OID 19329)
-- Name: tblapproval tblapproval_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblapproval
    ADD CONSTRAINT tblapproval_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4123 (class 2606 OID 16861)
-- Name: tblbill tblbill_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblbill
    ADD CONSTRAINT tblbill_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4125 (class 2606 OID 16863)
-- Name: tblbilldetail tblbilldetail_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblbilldetail
    ADD CONSTRAINT tblbilldetail_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4127 (class 2606 OID 16865)
-- Name: tblbillreturn tblbillreturn_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblbillreturn
    ADD CONSTRAINT tblbillreturn_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4129 (class 2606 OID 16867)
-- Name: tblbrand tblbrand_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblbrand
    ADD CONSTRAINT tblbrand_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4131 (class 2606 OID 16871)
-- Name: tblcheckstock tblcheckstock_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblcheckstock
    ADD CONSTRAINT tblcheckstock_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4133 (class 2606 OID 16873)
-- Name: tblcheckstockaction tblcheckstockaction_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblcheckstockaction
    ADD CONSTRAINT tblcheckstockaction_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4135 (class 2606 OID 16875)
-- Name: tblcounter tblcounter_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblcounter
    ADD CONSTRAINT tblcounter_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4219 (class 2606 OID 17346)
-- Name: tblcurrency tblcurrency_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblcurrency
    ADD CONSTRAINT tblcurrency_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4137 (class 2606 OID 16879)
-- Name: tblcustomer tblcustomer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblcustomer
    ADD CONSTRAINT tblcustomer_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4193 (class 2606 OID 16988)
-- Name: tblcustomerdoc tblcustomerdoc_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblcustomerdoc
    ADD CONSTRAINT tblcustomerdoc_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4139 (class 2606 OID 16881)
-- Name: tbldailycashflow tbldailycashflow_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbldailycashflow
    ADD CONSTRAINT tbldailycashflow_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4213 (class 2606 OID 17257)
-- Name: tbldepartment tbldepartment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbldepartment
    ADD CONSTRAINT tbldepartment_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4141 (class 2606 OID 16885)
-- Name: tbldiscounttype tbldiscounttype_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbldiscounttype
    ADD CONSTRAINT tbldiscounttype_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4143 (class 2606 OID 16887)
-- Name: tblearnpointtransaction tblearnpointtransaction_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblearnpointtransaction
    ADD CONSTRAINT tblearnpointtransaction_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4145 (class 2606 OID 16889)
-- Name: tbleexchange tbleexchange_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbleexchange
    ADD CONSTRAINT tbleexchange_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4147 (class 2606 OID 16891)
-- Name: tblempbankdetail tblempbankdetail_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblempbankdetail
    ADD CONSTRAINT tblempbankdetail_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4215 (class 2606 OID 17276)
-- Name: tblemployee tblemployee_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblemployee
    ADD CONSTRAINT tblemployee_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4205 (class 2606 OID 17116)
-- Name: tblexpense tblexpense_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblexpense
    ADD CONSTRAINT tblexpense_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4195 (class 2606 OID 17043)
-- Name: tblexpensetype tblexpensetype_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblexpensetype
    ADD CONSTRAINT tblexpensetype_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4243 (class 2606 OID 19556)
-- Name: tblimportproductlot tblimportproductlot_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblimportproductlot
    ADD CONSTRAINT tblimportproductlot_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4245 (class 2606 OID 27675)
-- Name: tbllocation tbllocation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbllocation
    ADD CONSTRAINT tbllocation_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4249 (class 2606 OID 27712)
-- Name: tbllocationdetail tbllocationdetail_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbllocationdetail
    ADD CONSTRAINT tbllocationdetail_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4149 (class 2606 OID 16899)
-- Name: tblmember tblmember_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblmember
    ADD CONSTRAINT tblmember_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4151 (class 2606 OID 16901)
-- Name: tblmembertype tblmembertype_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblmembertype
    ADD CONSTRAINT tblmembertype_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4231 (class 2606 OID 19455)
-- Name: tblmenu tblmenu_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblmenu
    ADD CONSTRAINT tblmenu_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4153 (class 2606 OID 16905)
-- Name: tblmenuprivilege tblmenuprivilege_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblmenuprivilege
    ADD CONSTRAINT tblmenuprivilege_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4155 (class 2606 OID 16907)
-- Name: tblpacking tblpacking_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblpacking
    ADD CONSTRAINT tblpacking_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4209 (class 2606 OID 17164)
-- Name: tblpayment tblpayment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblpayment
    ADD CONSTRAINT tblpayment_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4157 (class 2606 OID 16911)
-- Name: tblpaymentmethod tblpaymentmethod_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblpaymentmethod
    ADD CONSTRAINT tblpaymentmethod_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4159 (class 2606 OID 16913)
-- Name: tblpayterm tblpayterm_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblpayterm
    ADD CONSTRAINT tblpayterm_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4161 (class 2606 OID 16915)
-- Name: tblpointtype tblpointtype_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblpointtype
    ADD CONSTRAINT tblpointtype_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4163 (class 2606 OID 16917)
-- Name: tblposition tblposition_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblposition
    ADD CONSTRAINT tblposition_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4165 (class 2606 OID 16919)
-- Name: tblproductcategory tblproductcategory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblproductcategory
    ADD CONSTRAINT tblproductcategory_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4233 (class 2606 OID 19470)
-- Name: tblproductlist tblproductlist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblproductlist
    ADD CONSTRAINT tblproductlist_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4167 (class 2606 OID 16923)
-- Name: tblproducttype tblproducttype_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblproducttype
    ADD CONSTRAINT tblproducttype_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4201 (class 2606 OID 17086)
-- Name: tblpromotion tblpromotion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblpromotion
    ADD CONSTRAINT tblpromotion_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4169 (class 2606 OID 16927)
-- Name: tblpromotiondetail tblpromotiondetail_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblpromotiondetail
    ADD CONSTRAINT tblpromotiondetail_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4191 (class 2606 OID 16978)
-- Name: tblpromotiontype tblpromotiontype_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblpromotiontype
    ADD CONSTRAINT tblpromotiontype_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4197 (class 2606 OID 17052)
-- Name: tblpurchase tblpurchase_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblpurchase
    ADD CONSTRAINT tblpurchase_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4171 (class 2606 OID 16931)
-- Name: tblpurchasedetail tblpurchasedetail_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblpurchasedetail
    ADD CONSTRAINT tblpurchasedetail_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4229 (class 2606 OID 19400)
-- Name: tblrefreshtoken tblrefreshtoken_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblrefreshtoken
    ADD CONSTRAINT tblrefreshtoken_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4225 (class 2606 OID 19363)
-- Name: tblroute tblroute_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblroute
    ADD CONSTRAINT tblroute_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4227 (class 2606 OID 19374)
-- Name: tblroutedetail tblroutedetail_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblroutedetail
    ADD CONSTRAINT tblroutedetail_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4203 (class 2606 OID 17106)
-- Name: tblsaletarget tblsaletarget_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblsaletarget
    ADD CONSTRAINT tblsaletarget_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4235 (class 2606 OID 19494)
-- Name: tblselftype tblselftype_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblselftype
    ADD CONSTRAINT tblselftype_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4247 (class 2606 OID 27691)
-- Name: tblsetting tblsetting_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblsetting
    ADD CONSTRAINT tblsetting_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4239 (class 2606 OID 19520)
-- Name: tblshelf tblshelf_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblshelf
    ADD CONSTRAINT tblshelf_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4241 (class 2606 OID 19544)
-- Name: tblshelftransfer tblshelftransfer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblshelftransfer
    ADD CONSTRAINT tblshelftransfer_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4253 (class 2606 OID 27783)
-- Name: tblshift tblshift_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblshift
    ADD CONSTRAINT tblshift_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4251 (class 2606 OID 27747)
-- Name: tblshifttype tblshifttype_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblshifttype
    ADD CONSTRAINT tblshifttype_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4173 (class 2606 OID 16941)
-- Name: tblshipping tblshipping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblshipping
    ADD CONSTRAINT tblshipping_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4175 (class 2606 OID 16943)
-- Name: tblstatus tblstatus_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblstatus
    ADD CONSTRAINT tblstatus_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4177 (class 2606 OID 16945)
-- Name: tblstatustype tblstatustype_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblstatustype
    ADD CONSTRAINT tblstatustype_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4199 (class 2606 OID 17076)
-- Name: tblstocktransfer tblstocktransfer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblstocktransfer
    ADD CONSTRAINT tblstocktransfer_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4179 (class 2606 OID 16949)
-- Name: tblstocktransferdetail tblstocktransferdetail_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblstocktransferdetail
    ADD CONSTRAINT tblstocktransferdetail_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4221 (class 2606 OID 17404)
-- Name: tblsupplier tblsupplier_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblsupplier
    ADD CONSTRAINT tblsupplier_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4181 (class 2606 OID 16953)
-- Name: tblsupplierdetail tblsupplierdoc_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblsupplierdetail
    ADD CONSTRAINT tblsupplierdoc_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4211 (class 2606 OID 17211)
-- Name: tblsystemlog tblsystemlog_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblsystemlog
    ADD CONSTRAINT tblsystemlog_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4255 (class 2606 OID 27812)
-- Name: tbltax tbltax_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbltax
    ADD CONSTRAINT tbltax_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4183 (class 2606 OID 16957)
-- Name: tbltaxtype tbltaxtype_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbltaxtype
    ADD CONSTRAINT tbltaxtype_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4185 (class 2606 OID 16959)
-- Name: tblunit tblunit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblunit
    ADD CONSTRAINT tblunit_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4217 (class 2606 OID 17332)
-- Name: tbluser tbluser_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbluser
    ADD CONSTRAINT tbluser_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4187 (class 2606 OID 16963)
-- Name: tbluseractivity tbluseractivity_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tbluseractivity
    ADD CONSTRAINT tbluseractivity_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4189 (class 2606 OID 16965)
-- Name: tblvariation tblvariation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblvariation
    ADD CONSTRAINT tblvariation_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4207 (class 2606 OID 17149)
-- Name: tblwarranty tblwarranty_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblwarranty
    ADD CONSTRAINT tblwarranty_pkey PRIMARY KEY ("ID");


--
-- TOC entry 4237 (class 2606 OID 19506)
-- Name: tblzone tblzone_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tblzone
    ADD CONSTRAINT tblzone_pkey PRIMARY KEY ("ID");


-- Completed on 2024-04-23 15:10:45 +07

--
-- PostgreSQL database dump complete
--

