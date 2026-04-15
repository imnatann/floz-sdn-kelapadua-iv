--
-- PostgreSQL database dump
--

\restrict gITsSpfmi0HtksOltAf4cW81frM8pU5fKrXyVmgt5WIgjFlN5fngzldHguA1c2O

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: academic_years; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.academic_years (
    id bigint NOT NULL,
    name character varying(50) NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.academic_years OWNER TO postgres;

--
-- Name: academic_years_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.academic_years_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.academic_years_id_seq OWNER TO postgres;

--
-- Name: academic_years_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.academic_years_id_seq OWNED BY public.academic_years.id;


--
-- Name: announcements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.announcements (
    id bigint NOT NULL,
    title character varying(255) NOT NULL,
    content text NOT NULL,
    type character varying(20) DEFAULT 'info'::character varying NOT NULL,
    is_published boolean DEFAULT true NOT NULL,
    user_id bigint,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    target_audience character varying(255) DEFAULT 'all'::character varying NOT NULL,
    is_pinned boolean DEFAULT false NOT NULL,
    cover_image_url character varying(255),
    excerpt text,
    CONSTRAINT announcements_target_audience_check CHECK (((target_audience)::text = ANY ((ARRAY['all'::character varying, 'teachers'::character varying, 'students'::character varying])::text[])))
);


ALTER TABLE public.announcements OWNER TO postgres;

--
-- Name: announcements_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.announcements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.announcements_id_seq OWNER TO postgres;

--
-- Name: announcements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.announcements_id_seq OWNED BY public.announcements.id;


--
-- Name: assignment_attachments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.assignment_attachments (
    id bigint NOT NULL,
    assignment_id bigint NOT NULL,
    file_path character varying(255) NOT NULL,
    file_name character varying(255) NOT NULL,
    file_type character varying(255) NOT NULL,
    file_size bigint NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.assignment_attachments OWNER TO postgres;

--
-- Name: assignment_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.assignment_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.assignment_attachments_id_seq OWNER TO postgres;

--
-- Name: assignment_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.assignment_attachments_id_seq OWNED BY public.assignment_attachments.id;


--
-- Name: assignment_submissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.assignment_submissions (
    id bigint NOT NULL,
    assignment_id bigint NOT NULL,
    student_id bigint NOT NULL,
    submitted_at timestamp(0) without time zone NOT NULL,
    status character varying(255) DEFAULT 'submitted'::character varying NOT NULL,
    grade numeric(5,2),
    feedback text,
    link character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.assignment_submissions OWNER TO postgres;

--
-- Name: assignment_submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.assignment_submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.assignment_submissions_id_seq OWNER TO postgres;

--
-- Name: assignment_submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.assignment_submissions_id_seq OWNED BY public.assignment_submissions.id;


--
-- Name: assignments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.assignments (
    id bigint NOT NULL,
    subject_id bigint NOT NULL,
    teacher_id bigint NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    due_date timestamp(0) without time zone NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.assignments OWNER TO postgres;

--
-- Name: assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.assignments_id_seq OWNER TO postgres;

--
-- Name: assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.assignments_id_seq OWNED BY public.assignments.id;


--
-- Name: attendance; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attendance (
    id bigint NOT NULL,
    student_id bigint NOT NULL,
    date date NOT NULL,
    status character varying(20) NOT NULL,
    notes text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    class_id bigint,
    subject_id bigint,
    semester_id bigint,
    recorded_by bigint,
    meeting_number integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.attendance OWNER TO postgres;

--
-- Name: attendance_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.attendance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.attendance_id_seq OWNER TO postgres;

--
-- Name: attendance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.attendance_id_seq OWNED BY public.attendance.id;


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_logs (
    id bigint NOT NULL,
    user_id bigint,
    event character varying(255) NOT NULL,
    auditable_type character varying(255),
    auditable_id character varying(255) NOT NULL,
    old_values json,
    new_values json,
    url character varying(255),
    ip_address character varying(255),
    user_agent character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    method character varying(255)
);


ALTER TABLE public.audit_logs OWNER TO postgres;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_logs_id_seq OWNER TO postgres;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: cache; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cache (
    key character varying(255) NOT NULL,
    value text NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE public.cache OWNER TO postgres;

--
-- Name: cache_locks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cache_locks (
    key character varying(255) NOT NULL,
    owner character varying(255) NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE public.cache_locks OWNER TO postgres;

--
-- Name: classes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.classes (
    id bigint NOT NULL,
    name character varying(50) NOT NULL,
    grade_level integer NOT NULL,
    academic_year_id bigint NOT NULL,
    homeroom_teacher_id bigint,
    max_students integer DEFAULT 40 NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.classes OWNER TO postgres;

--
-- Name: classes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.classes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.classes_id_seq OWNER TO postgres;

--
-- Name: classes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.classes_id_seq OWNED BY public.classes.id;


--
-- Name: counseling_notes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.counseling_notes (
    id bigint NOT NULL,
    student_id bigint NOT NULL,
    counselor_id bigint,
    date date NOT NULL,
    category character varying(255) NOT NULL,
    severity character varying(255) DEFAULT 'low'::character varying NOT NULL,
    title text NOT NULL,
    description text NOT NULL,
    follow_up_action text,
    status character varying(255) DEFAULT 'open'::character varying NOT NULL,
    is_confidential boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.counseling_notes OWNER TO postgres;

--
-- Name: counseling_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.counseling_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.counseling_notes_id_seq OWNER TO postgres;

--
-- Name: counseling_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.counseling_notes_id_seq OWNED BY public.counseling_notes.id;


--
-- Name: exam_scores; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exam_scores (
    id bigint NOT NULL,
    exam_id bigint NOT NULL,
    student_id bigint NOT NULL,
    score numeric(5,2),
    notes text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.exam_scores OWNER TO postgres;

--
-- Name: exam_scores_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.exam_scores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.exam_scores_id_seq OWNER TO postgres;

--
-- Name: exam_scores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.exam_scores_id_seq OWNED BY public.exam_scores.id;


--
-- Name: exams; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exams (
    id bigint NOT NULL,
    class_id bigint NOT NULL,
    subject_id bigint NOT NULL,
    semester_id bigint NOT NULL,
    teacher_id bigint,
    title character varying(255) NOT NULL,
    exam_type character varying(255) NOT NULL,
    exam_date date NOT NULL,
    max_score numeric(5,2) DEFAULT '100'::numeric NOT NULL,
    status character varying(255) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.exams OWNER TO postgres;

--
-- Name: exams_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.exams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.exams_id_seq OWNER TO postgres;

--
-- Name: exams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.exams_id_seq OWNED BY public.exams.id;


--
-- Name: failed_jobs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.failed_jobs (
    id bigint NOT NULL,
    uuid character varying(255) NOT NULL,
    connection text NOT NULL,
    queue text NOT NULL,
    payload text NOT NULL,
    exception text NOT NULL,
    failed_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.failed_jobs OWNER TO postgres;

--
-- Name: failed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.failed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.failed_jobs_id_seq OWNER TO postgres;

--
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.failed_jobs_id_seq OWNED BY public.failed_jobs.id;


--
-- Name: grades; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.grades (
    id bigint NOT NULL,
    student_id bigint NOT NULL,
    subject_id bigint NOT NULL,
    class_id bigint NOT NULL,
    semester_id bigint NOT NULL,
    teacher_id bigint,
    daily_test_avg numeric(5,2),
    mid_test numeric(5,2),
    final_test numeric(5,2),
    knowledge_score numeric(5,2),
    skill_score numeric(5,2),
    final_score numeric(5,2),
    predicate character varying(2),
    description text,
    attendance_score numeric(5,2),
    attitude_score character varying(2),
    notes text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.grades OWNER TO postgres;

--
-- Name: grades_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.grades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.grades_id_seq OWNER TO postgres;

--
-- Name: grades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.grades_id_seq OWNED BY public.grades.id;


--
-- Name: job_batches; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_batches (
    id character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    total_jobs integer NOT NULL,
    pending_jobs integer NOT NULL,
    failed_jobs integer NOT NULL,
    failed_job_ids text NOT NULL,
    options text,
    cancelled_at integer,
    created_at integer NOT NULL,
    finished_at integer
);


ALTER TABLE public.job_batches OWNER TO postgres;

--
-- Name: jobs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.jobs (
    id bigint NOT NULL,
    queue character varying(255) NOT NULL,
    payload text NOT NULL,
    attempts smallint NOT NULL,
    reserved_at integer,
    available_at integer NOT NULL,
    created_at integer NOT NULL
);


ALTER TABLE public.jobs OWNER TO postgres;

--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.jobs_id_seq OWNER TO postgres;

--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.jobs_id_seq OWNED BY public.jobs.id;


--
-- Name: meeting_materials; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.meeting_materials (
    id bigint NOT NULL,
    meeting_id bigint NOT NULL,
    title character varying(255) NOT NULL,
    type character varying(255) DEFAULT 'file'::character varying NOT NULL,
    content text,
    file_path character varying(255),
    file_name character varying(255),
    file_size bigint,
    url character varying(255),
    sort_order smallint DEFAULT '0'::smallint NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.meeting_materials OWNER TO postgres;

--
-- Name: meeting_materials_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.meeting_materials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.meeting_materials_id_seq OWNER TO postgres;

--
-- Name: meeting_materials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.meeting_materials_id_seq OWNED BY public.meeting_materials.id;


--
-- Name: meetings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.meetings (
    id bigint NOT NULL,
    teaching_assignment_id bigint NOT NULL,
    meeting_number smallint NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    is_locked boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.meetings OWNER TO postgres;

--
-- Name: meetings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.meetings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.meetings_id_seq OWNER TO postgres;

--
-- Name: meetings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.meetings_id_seq OWNED BY public.meetings.id;


--
-- Name: migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


ALTER TABLE public.migrations OWNER TO postgres;

--
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.migrations_id_seq OWNER TO postgres;

--
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id uuid NOT NULL,
    type character varying(255) NOT NULL,
    notifiable_type character varying(255) NOT NULL,
    notifiable_id bigint NOT NULL,
    data text NOT NULL,
    read_at timestamp(0) without time zone,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- Name: offline_assignment_answers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.offline_assignment_answers (
    id bigint NOT NULL,
    submission_id bigint NOT NULL,
    question_id bigint NOT NULL,
    answer text,
    is_correct boolean,
    points_earned numeric(5,2) DEFAULT '0'::numeric NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.offline_assignment_answers OWNER TO postgres;

--
-- Name: offline_assignment_answers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.offline_assignment_answers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.offline_assignment_answers_id_seq OWNER TO postgres;

--
-- Name: offline_assignment_answers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.offline_assignment_answers_id_seq OWNED BY public.offline_assignment_answers.id;


--
-- Name: offline_assignment_classes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.offline_assignment_classes (
    id bigint NOT NULL,
    offline_assignment_id bigint NOT NULL,
    class_id bigint NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.offline_assignment_classes OWNER TO postgres;

--
-- Name: offline_assignment_classes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.offline_assignment_classes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.offline_assignment_classes_id_seq OWNER TO postgres;

--
-- Name: offline_assignment_classes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.offline_assignment_classes_id_seq OWNED BY public.offline_assignment_classes.id;


--
-- Name: offline_assignment_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.offline_assignment_files (
    id bigint NOT NULL,
    offline_assignment_id bigint NOT NULL,
    file_path character varying(255) NOT NULL,
    file_name character varying(255) NOT NULL,
    file_type character varying(255) NOT NULL,
    file_size bigint NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.offline_assignment_files OWNER TO postgres;

--
-- Name: offline_assignment_files_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.offline_assignment_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.offline_assignment_files_id_seq OWNER TO postgres;

--
-- Name: offline_assignment_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.offline_assignment_files_id_seq OWNED BY public.offline_assignment_files.id;


--
-- Name: offline_assignment_questions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.offline_assignment_questions (
    id bigint NOT NULL,
    offline_assignment_id bigint NOT NULL,
    question_text text NOT NULL,
    question_type character varying(255) DEFAULT 'multiple_choice'::character varying NOT NULL,
    options jsonb,
    correct_answer text,
    points numeric(5,2) DEFAULT '0'::numeric NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.offline_assignment_questions OWNER TO postgres;

--
-- Name: offline_assignment_questions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.offline_assignment_questions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.offline_assignment_questions_id_seq OWNER TO postgres;

--
-- Name: offline_assignment_questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.offline_assignment_questions_id_seq OWNED BY public.offline_assignment_questions.id;


--
-- Name: offline_assignment_submissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.offline_assignment_submissions (
    id bigint NOT NULL,
    offline_assignment_id bigint NOT NULL,
    student_id bigint NOT NULL,
    submitted_at timestamp(0) without time zone,
    grade numeric(5,2),
    correction_note text,
    correction_file character varying(255),
    answer_text text,
    answer_link character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.offline_assignment_submissions OWNER TO postgres;

--
-- Name: offline_assignment_submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.offline_assignment_submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.offline_assignment_submissions_id_seq OWNER TO postgres;

--
-- Name: offline_assignment_submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.offline_assignment_submissions_id_seq OWNED BY public.offline_assignment_submissions.id;


--
-- Name: offline_assignments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.offline_assignments (
    id bigint NOT NULL,
    teacher_id bigint NOT NULL,
    subject_id bigint NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    due_date timestamp(0) without time zone NOT NULL,
    status character varying(255) DEFAULT 'active'::character varying NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    type character varying(255) DEFAULT 'manual'::character varying NOT NULL,
    meeting_id bigint
);


ALTER TABLE public.offline_assignments OWNER TO postgres;

--
-- Name: offline_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.offline_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.offline_assignments_id_seq OWNER TO postgres;

--
-- Name: offline_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.offline_assignments_id_seq OWNED BY public.offline_assignments.id;


--
-- Name: offline_submission_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.offline_submission_files (
    id bigint NOT NULL,
    submission_id bigint NOT NULL,
    file_path character varying(255) NOT NULL,
    file_name character varying(255) NOT NULL,
    file_type character varying(255) NOT NULL,
    file_size bigint NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.offline_submission_files OWNER TO postgres;

--
-- Name: offline_submission_files_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.offline_submission_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.offline_submission_files_id_seq OWNER TO postgres;

--
-- Name: offline_submission_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.offline_submission_files_id_seq OWNED BY public.offline_submission_files.id;


--
-- Name: password_reset_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.password_reset_tokens (
    email character varying(255) NOT NULL,
    token character varying(255) NOT NULL,
    created_at timestamp(0) without time zone
);


ALTER TABLE public.password_reset_tokens OWNER TO postgres;

--
-- Name: personal_access_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.personal_access_tokens (
    id bigint NOT NULL,
    tokenable_type character varying(255) NOT NULL,
    tokenable_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    token character varying(64) NOT NULL,
    abilities text,
    last_used_at timestamp(0) without time zone,
    expires_at timestamp(0) without time zone,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.personal_access_tokens OWNER TO postgres;

--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.personal_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.personal_access_tokens_id_seq OWNER TO postgres;

--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.personal_access_tokens_id_seq OWNED BY public.personal_access_tokens.id;


--
-- Name: report_cards; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.report_cards (
    id bigint NOT NULL,
    student_id bigint NOT NULL,
    class_id bigint NOT NULL,
    semester_id bigint NOT NULL,
    rank integer,
    total_score numeric(7,2),
    average_score numeric(5,2),
    attendance_present integer DEFAULT 0 NOT NULL,
    attendance_sick integer DEFAULT 0 NOT NULL,
    attendance_permit integer DEFAULT 0 NOT NULL,
    attendance_absent integer DEFAULT 0 NOT NULL,
    achievements text,
    notes text,
    behavior_notes text,
    homeroom_comment text,
    principal_comment text,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    published_at timestamp(0) without time zone,
    pdf_url character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    report_type character varying(255) DEFAULT 'final'::character varying NOT NULL,
    extracurricular json
);


ALTER TABLE public.report_cards OWNER TO postgres;

--
-- Name: report_cards_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.report_cards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.report_cards_id_seq OWNER TO postgres;

--
-- Name: report_cards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.report_cards_id_seq OWNED BY public.report_cards.id;


--
-- Name: schedules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schedules (
    id uuid NOT NULL,
    teaching_assignment_id bigint NOT NULL,
    day_of_week integer NOT NULL,
    start_time time(0) without time zone NOT NULL,
    end_time time(0) without time zone NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.schedules OWNER TO postgres;

--
-- Name: COLUMN schedules.day_of_week; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.schedules.day_of_week IS '1: Monday, 7: Sunday';


--
-- Name: semesters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.semesters (
    id bigint NOT NULL,
    academic_year_id bigint NOT NULL,
    semester_number integer NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.semesters OWNER TO postgres;

--
-- Name: semesters_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.semesters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.semesters_id_seq OWNER TO postgres;

--
-- Name: semesters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.semesters_id_seq OWNED BY public.semesters.id;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sessions (
    id character varying(255) NOT NULL,
    user_id bigint,
    ip_address character varying(45),
    user_agent text,
    payload text NOT NULL,
    last_activity integer NOT NULL
);


ALTER TABLE public.sessions OWNER TO postgres;

--
-- Name: student_health_records; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_health_records (
    id bigint NOT NULL,
    student_id bigint NOT NULL,
    blood_type character varying(5),
    height integer,
    weight integer,
    medical_history text,
    allergies text,
    special_needs text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.student_health_records OWNER TO postgres;

--
-- Name: student_health_records_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.student_health_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.student_health_records_id_seq OWNER TO postgres;

--
-- Name: student_health_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.student_health_records_id_seq OWNED BY public.student_health_records.id;


--
-- Name: student_mutations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_mutations (
    id bigint NOT NULL,
    student_id bigint NOT NULL,
    type character varying(255) NOT NULL,
    from_class_id bigint,
    to_class_id bigint,
    date date NOT NULL,
    reason character varying(255),
    reference_number character varying(255),
    notes text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.student_mutations OWNER TO postgres;

--
-- Name: student_mutations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.student_mutations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.student_mutations_id_seq OWNER TO postgres;

--
-- Name: student_mutations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.student_mutations_id_seq OWNED BY public.student_mutations.id;


--
-- Name: students; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.students (
    id bigint NOT NULL,
    nis character varying(20) NOT NULL,
    nisn character varying(20),
    name character varying(255) NOT NULL,
    gender character varying(10),
    birth_place character varying(100),
    birth_date date,
    religion character varying(20),
    address text,
    parent_name character varying(255),
    parent_phone character varying(20),
    email character varying(255),
    class_id bigint,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    photo_url character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    family_card_number character varying(255),
    nik character varying(255)
);


ALTER TABLE public.students OWNER TO postgres;

--
-- Name: students_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.students_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.students_id_seq OWNER TO postgres;

--
-- Name: students_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.students_id_seq OWNED BY public.students.id;


--
-- Name: subjects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subjects (
    id bigint NOT NULL,
    code character varying(20) NOT NULL,
    name character varying(255) NOT NULL,
    education_level character varying(10) NOT NULL,
    grade_level integer,
    kkm numeric(5,2) DEFAULT '70'::numeric NOT NULL,
    category character varying(50),
    description text,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.subjects OWNER TO postgres;

--
-- Name: subjects_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.subjects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.subjects_id_seq OWNER TO postgres;

--
-- Name: subjects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.subjects_id_seq OWNED BY public.subjects.id;


--
-- Name: submission_attachments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.submission_attachments (
    id bigint NOT NULL,
    submission_id bigint NOT NULL,
    file_path character varying(255) NOT NULL,
    file_name character varying(255) NOT NULL,
    file_type character varying(255) NOT NULL,
    file_size bigint NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.submission_attachments OWNER TO postgres;

--
-- Name: submission_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.submission_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.submission_attachments_id_seq OWNER TO postgres;

--
-- Name: submission_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.submission_attachments_id_seq OWNED BY public.submission_attachments.id;


--
-- Name: task_scores; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task_scores (
    id bigint NOT NULL,
    task_id bigint NOT NULL,
    student_id bigint NOT NULL,
    score numeric(5,2),
    notes text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.task_scores OWNER TO postgres;

--
-- Name: task_scores_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.task_scores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.task_scores_id_seq OWNER TO postgres;

--
-- Name: task_scores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.task_scores_id_seq OWNED BY public.task_scores.id;


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tasks (
    id bigint NOT NULL,
    class_id bigint NOT NULL,
    subject_id bigint NOT NULL,
    semester_id bigint NOT NULL,
    teacher_id bigint,
    title character varying(255) NOT NULL,
    description text,
    task_date date NOT NULL,
    due_date date,
    max_score numeric(5,2) DEFAULT '100'::numeric NOT NULL,
    status character varying(255) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.tasks OWNER TO postgres;

--
-- Name: tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tasks_id_seq OWNER TO postgres;

--
-- Name: tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tasks_id_seq OWNED BY public.tasks.id;


--
-- Name: teachers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teachers (
    id bigint NOT NULL,
    nip character varying(20),
    nuptk character varying(20),
    name character varying(255) NOT NULL,
    gender character varying(10),
    birth_place character varying(100),
    birth_date date,
    email character varying(255) NOT NULL,
    phone character varying(20),
    address text,
    is_homeroom boolean DEFAULT false NOT NULL,
    photo_url character varying(255),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    user_id bigint,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.teachers OWNER TO postgres;

--
-- Name: teachers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.teachers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.teachers_id_seq OWNER TO postgres;

--
-- Name: teachers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.teachers_id_seq OWNED BY public.teachers.id;


--
-- Name: teaching_assignments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teaching_assignments (
    id bigint NOT NULL,
    teacher_id bigint NOT NULL,
    subject_id bigint NOT NULL,
    class_id bigint NOT NULL,
    academic_year_id bigint NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.teaching_assignments OWNER TO postgres;

--
-- Name: teaching_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.teaching_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.teaching_assignments_id_seq OWNER TO postgres;

--
-- Name: teaching_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.teaching_assignments_id_seq OWNED BY public.teaching_assignments.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    email_verified_at timestamp(0) without time zone,
    password character varying(255) NOT NULL,
    role character varying(20) DEFAULT 'teacher'::character varying NOT NULL,
    avatar_url character varying(255),
    is_active boolean DEFAULT true NOT NULL,
    remember_token character varying(100),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: academic_years id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_years ALTER COLUMN id SET DEFAULT nextval('public.academic_years_id_seq'::regclass);


--
-- Name: announcements id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.announcements ALTER COLUMN id SET DEFAULT nextval('public.announcements_id_seq'::regclass);


--
-- Name: assignment_attachments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignment_attachments ALTER COLUMN id SET DEFAULT nextval('public.assignment_attachments_id_seq'::regclass);


--
-- Name: assignment_submissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignment_submissions ALTER COLUMN id SET DEFAULT nextval('public.assignment_submissions_id_seq'::regclass);


--
-- Name: assignments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignments ALTER COLUMN id SET DEFAULT nextval('public.assignments_id_seq'::regclass);


--
-- Name: attendance id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance ALTER COLUMN id SET DEFAULT nextval('public.attendance_id_seq'::regclass);


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: classes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.classes ALTER COLUMN id SET DEFAULT nextval('public.classes_id_seq'::regclass);


--
-- Name: counseling_notes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.counseling_notes ALTER COLUMN id SET DEFAULT nextval('public.counseling_notes_id_seq'::regclass);


--
-- Name: exam_scores id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_scores ALTER COLUMN id SET DEFAULT nextval('public.exam_scores_id_seq'::regclass);


--
-- Name: exams id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exams ALTER COLUMN id SET DEFAULT nextval('public.exams_id_seq'::regclass);


--
-- Name: failed_jobs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.failed_jobs ALTER COLUMN id SET DEFAULT nextval('public.failed_jobs_id_seq'::regclass);


--
-- Name: grades id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grades ALTER COLUMN id SET DEFAULT nextval('public.grades_id_seq'::regclass);


--
-- Name: jobs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobs ALTER COLUMN id SET DEFAULT nextval('public.jobs_id_seq'::regclass);


--
-- Name: meeting_materials id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meeting_materials ALTER COLUMN id SET DEFAULT nextval('public.meeting_materials_id_seq'::regclass);


--
-- Name: meetings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meetings ALTER COLUMN id SET DEFAULT nextval('public.meetings_id_seq'::regclass);


--
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- Name: offline_assignment_answers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignment_answers ALTER COLUMN id SET DEFAULT nextval('public.offline_assignment_answers_id_seq'::regclass);


--
-- Name: offline_assignment_classes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignment_classes ALTER COLUMN id SET DEFAULT nextval('public.offline_assignment_classes_id_seq'::regclass);


--
-- Name: offline_assignment_files id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignment_files ALTER COLUMN id SET DEFAULT nextval('public.offline_assignment_files_id_seq'::regclass);


--
-- Name: offline_assignment_questions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignment_questions ALTER COLUMN id SET DEFAULT nextval('public.offline_assignment_questions_id_seq'::regclass);


--
-- Name: offline_assignment_submissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignment_submissions ALTER COLUMN id SET DEFAULT nextval('public.offline_assignment_submissions_id_seq'::regclass);


--
-- Name: offline_assignments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignments ALTER COLUMN id SET DEFAULT nextval('public.offline_assignments_id_seq'::regclass);


--
-- Name: offline_submission_files id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_submission_files ALTER COLUMN id SET DEFAULT nextval('public.offline_submission_files_id_seq'::regclass);


--
-- Name: personal_access_tokens id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal_access_tokens ALTER COLUMN id SET DEFAULT nextval('public.personal_access_tokens_id_seq'::regclass);


--
-- Name: report_cards id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_cards ALTER COLUMN id SET DEFAULT nextval('public.report_cards_id_seq'::regclass);


--
-- Name: semesters id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.semesters ALTER COLUMN id SET DEFAULT nextval('public.semesters_id_seq'::regclass);


--
-- Name: student_health_records id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_health_records ALTER COLUMN id SET DEFAULT nextval('public.student_health_records_id_seq'::regclass);


--
-- Name: student_mutations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_mutations ALTER COLUMN id SET DEFAULT nextval('public.student_mutations_id_seq'::regclass);


--
-- Name: students id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students ALTER COLUMN id SET DEFAULT nextval('public.students_id_seq'::regclass);


--
-- Name: subjects id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subjects ALTER COLUMN id SET DEFAULT nextval('public.subjects_id_seq'::regclass);


--
-- Name: submission_attachments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.submission_attachments ALTER COLUMN id SET DEFAULT nextval('public.submission_attachments_id_seq'::regclass);


--
-- Name: task_scores id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_scores ALTER COLUMN id SET DEFAULT nextval('public.task_scores_id_seq'::regclass);


--
-- Name: tasks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks ALTER COLUMN id SET DEFAULT nextval('public.tasks_id_seq'::regclass);


--
-- Name: teachers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teachers ALTER COLUMN id SET DEFAULT nextval('public.teachers_id_seq'::regclass);


--
-- Name: teaching_assignments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teaching_assignments ALTER COLUMN id SET DEFAULT nextval('public.teaching_assignments_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: academic_years; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.academic_years (id, name, start_date, end_date, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: announcements; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.announcements (id, title, content, type, is_published, user_id, created_at, updated_at, target_audience, is_pinned, cover_image_url, excerpt) FROM stdin;
\.


--
-- Data for Name: assignment_attachments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.assignment_attachments (id, assignment_id, file_path, file_name, file_type, file_size, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: assignment_submissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.assignment_submissions (id, assignment_id, student_id, submitted_at, status, grade, feedback, link, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: assignments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.assignments (id, subject_id, teacher_id, title, description, due_date, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: attendance; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attendance (id, student_id, date, status, notes, created_at, updated_at, class_id, subject_id, semester_id, recorded_by, meeting_number) FROM stdin;
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_logs (id, user_id, event, auditable_type, auditable_id, old_values, new_values, url, ip_address, user_agent, created_at, updated_at, method) FROM stdin;
\.


--
-- Data for Name: cache; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cache (key, value, expiration) FROM stdin;
floz-sdn-kelapadua-iv-cache-students_d751713988987e9331980363e24189ce	Tzo0MjoiSWxsdW1pbmF0ZVxQYWdpbmF0aW9uXExlbmd0aEF3YXJlUGFnaW5hdG9yIjoxMjp7czo4OiIAKgBpdGVtcyI7TzozOToiSWxsdW1pbmF0ZVxEYXRhYmFzZVxFbG9xdWVudFxDb2xsZWN0aW9uIjoyOntzOjg6IgAqAGl0ZW1zIjthOjA6e31zOjI4OiIAKgBlc2NhcGVXaGVuQ2FzdGluZ1RvU3RyaW5nIjtiOjA7fXM6MTA6IgAqAHBlclBhZ2UiO2k6MjA7czoxNDoiACoAY3VycmVudFBhZ2UiO2k6MTtzOjc6IgAqAHBhdGgiO3M6MzA6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9zdHVkZW50cyI7czo4OiIAKgBxdWVyeSI7YTowOnt9czoxMToiACoAZnJhZ21lbnQiO047czoxMToiACoAcGFnZU5hbWUiO3M6NDoicGFnZSI7czoyODoiACoAZXNjYXBlV2hlbkNhc3RpbmdUb1N0cmluZyI7YjowO3M6MTA6Im9uRWFjaFNpZGUiO2k6MztzOjEwOiIAKgBvcHRpb25zIjthOjI6e3M6NDoicGF0aCI7czozMDoiaHR0cDovLzEyNy4wLjAuMTo4MDAwL3N0dWRlbnRzIjtzOjg6InBhZ2VOYW1lIjtzOjQ6InBhZ2UiO31zOjg6IgAqAHRvdGFsIjtpOjA7czoxMToiACoAbGFzdFBhZ2UiO2k6MTt9	1773285344
floz-sdn-kelapadua-iv-cache-active_classes_list	TzozOToiSWxsdW1pbmF0ZVxEYXRhYmFzZVxFbG9xdWVudFxDb2xsZWN0aW9uIjoyOntzOjg6IgAqAGl0ZW1zIjthOjA6e31zOjI4OiIAKgBlc2NhcGVXaGVuQ2FzdGluZ1RvU3RyaW5nIjtiOjA7fQ==	1773288884
\.


--
-- Data for Name: cache_locks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cache_locks (key, owner, expiration) FROM stdin;
\.


--
-- Data for Name: classes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.classes (id, name, grade_level, academic_year_id, homeroom_teacher_id, max_students, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: counseling_notes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.counseling_notes (id, student_id, counselor_id, date, category, severity, title, description, follow_up_action, status, is_confidential, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: exam_scores; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.exam_scores (id, exam_id, student_id, score, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: exams; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.exams (id, class_id, subject_id, semester_id, teacher_id, title, exam_type, exam_date, max_score, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: failed_jobs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.failed_jobs (id, uuid, connection, queue, payload, exception, failed_at) FROM stdin;
\.


--
-- Data for Name: grades; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.grades (id, student_id, subject_id, class_id, semester_id, teacher_id, daily_test_avg, mid_test, final_test, knowledge_score, skill_score, final_score, predicate, description, attendance_score, attitude_score, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: job_batches; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.job_batches (id, name, total_jobs, pending_jobs, failed_jobs, failed_job_ids, options, cancelled_at, created_at, finished_at) FROM stdin;
\.


--
-- Data for Name: jobs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.jobs (id, queue, payload, attempts, reserved_at, available_at, created_at) FROM stdin;
\.


--
-- Data for Name: meeting_materials; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.meeting_materials (id, meeting_id, title, type, content, file_path, file_name, file_size, url, sort_order, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: meetings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.meetings (id, teaching_assignment_id, meeting_number, title, description, is_locked, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.migrations (id, migration, batch) FROM stdin;
1	0001_01_01_000000_create_users_table	1
2	0001_01_01_000001_create_cache_table	1
3	0001_01_01_000002_create_jobs_table	1
4	2024_01_01_000001_create_personal_access_tokens_table	1
5	2024_01_01_000001_create_users_table	1
6	2024_01_02_000001_create_academic_years_table	1
7	2024_01_03_000001_create_teachers_table	1
8	2024_01_04_000001_create_classes_table	1
9	2024_01_05_000001_create_students_table	1
10	2024_01_06_000001_create_subjects_table	1
11	2024_01_07_000001_create_grades_table	1
12	2024_01_08_000001_create_report_cards_table	1
13	2024_01_09_000001_create_attendance_table	1
14	2024_02_15_000001_create_announcements_table	1
15	2024_02_16_000001_create_teaching_assignments_table	1
16	2026_02_15_174332_add_indexes_to_students_table	1
17	2026_02_15_202057_add_details_to_announcements_table	1
18	2026_02_16_035646_create_notifications_table	1
19	2026_02_16_085037_create_schedules_table	1
20	2026_02_16_100000_enhance_students_module	1
21	2026_02_17_000000_create_audit_logs_table	1
22	2026_02_17_000001_add_method_to_audit_logs_table	1
23	2026_02_18_000000_create_assignments_table	1
24	2026_02_18_000001_create_offline_assignments_table	1
25	2026_02_18_100000_add_type_and_quiz_tables_to_offline_assignments	1
26	2026_02_18_200000_create_meetings_table	1
27	2026_02_18_200001_add_meeting_id_to_offline_assignments	1
28	2026_02_20_075753_change_auditable_id_type_in_audit_logs_table	1
29	2026_02_27_103656_add_meeting_fields_to_attendance_table	1
30	2026_02_27_104504_create_tasks_table	1
31	2026_02_27_104505_create_task_scores_table	1
32	2026_02_27_135014_create_exams_table	1
33	2026_02_27_135015_create_exam_scores_table	1
34	2026_02_27_143640_add_new_fields_to_report_cards_table	1
35	2026_02_28_021123_update_attendance_unique_constraint	1
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications (id, type, notifiable_type, notifiable_id, data, read_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: offline_assignment_answers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.offline_assignment_answers (id, submission_id, question_id, answer, is_correct, points_earned, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: offline_assignment_classes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.offline_assignment_classes (id, offline_assignment_id, class_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: offline_assignment_files; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.offline_assignment_files (id, offline_assignment_id, file_path, file_name, file_type, file_size, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: offline_assignment_questions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.offline_assignment_questions (id, offline_assignment_id, question_text, question_type, options, correct_answer, points, sort_order, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: offline_assignment_submissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.offline_assignment_submissions (id, offline_assignment_id, student_id, submitted_at, grade, correction_note, correction_file, answer_text, answer_link, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: offline_assignments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.offline_assignments (id, teacher_id, subject_id, title, description, due_date, status, created_by, created_at, updated_at, type, meeting_id) FROM stdin;
\.


--
-- Data for Name: offline_submission_files; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.offline_submission_files (id, submission_id, file_path, file_name, file_type, file_size, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: password_reset_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.password_reset_tokens (email, token, created_at) FROM stdin;
\.


--
-- Data for Name: personal_access_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.personal_access_tokens (id, tokenable_type, tokenable_id, name, token, abilities, last_used_at, expires_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: report_cards; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.report_cards (id, student_id, class_id, semester_id, rank, total_score, average_score, attendance_present, attendance_sick, attendance_permit, attendance_absent, achievements, notes, behavior_notes, homeroom_comment, principal_comment, status, published_at, pdf_url, created_at, updated_at, report_type, extracurricular) FROM stdin;
\.


--
-- Data for Name: schedules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schedules (id, teaching_assignment_id, day_of_week, start_time, end_time, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: semesters; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.semesters (id, academic_year_id, semester_number, start_date, end_date, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sessions (id, user_id, ip_address, user_agent, payload, last_activity) FROM stdin;
uuqAi4Lkyw0ZyZ4jVewq2EXQbWf07hremo9vlmBG	2	127.0.0.1	curl/7.53.1	YTozOntzOjY6Il90b2tlbiI7czo0MDoiYXU3VUR3VkFvRnh3bXZzbzVkZkZjS2JtaHlnT0s5ZkVZdjN0d0txZSI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304163
dX3X0RZ0q0ADCO1Aww0ioyOeFoAF5nLAzA3LAf2o	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiOGE5QWtLcEZrbm44V1hLdW9IcUdYdHp1Q2JST1hWWkF5NFRyQTBhZCI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304261
we17FNjMh1Vm7Gt53TANOANpYACKS49YXUJ9XShN	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiZE5hTzVIa21oY3BHdlM0d0t0QWREVEp2cnhuNm9jcnZNbHBBVTB3SiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304261
eowSaHGMOCAdzFs7QG0EHYdaSRwItd9S7LpfUvYh	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiSVBmSElSVFRJM0xQY0pQUjdmRks1MEhBOWY4aHpMZ3NxeTZnMEZnbCI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304263
B4TAlW2wcUVewMb7BhogSSOAYsiC830DaeWvUVf6	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiZHJNQkdvbXd4eUdvVldMVmYwVkVWdWpyNlB2cDVzSDJyQXZjQXpMUiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304263
GfdjENTDE7JSFK7GkccARL3cS8V54IgH72cKjRoE	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiSjFkQk9oRE9adUtaUWxlZ2ZaTmM2ZmwwYkkyVjk3OVNBOG9YVzFCMCI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304265
8oXbFblV651AZUyJyEH1knG1f9kSf2XlRJbY7jKu	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiNnoyb2NXTEhETDFKcGJLN25zWVdJTW9yVmd3YTdIenNGYkZ2YjU3RiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304265
UNkY9Jh9BbyxI6AYrkVBg7nQFawf1wkSCMb9B7oG	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiT0J5S3BxYXdHbE9xQkJOTXVQU29qQ2o5UldXQkY1cEpFeGNKcGFYRCI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304267
XPgbBtb7Y5qGcVRasbfwEBHbQ2T9GNxfj9zLGhFz	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiTXB5dk9WWU9sczNMc3h6RE1jQUdvUVZuVlNSS1A3bXBYMmdPSlJEViI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304267
NWQRMvctzWF5kcA9Q94kV9mHLM0Pg2mUSGbG2vQ2	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoic1ZmTGJwSG5KTW5pY0pLVzhtTWw3eWdpd0ViZXJRUklEOExzSW5jTSI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304269
rzCZdXNyGMwjAxTOoI8y9gsVNEpOvEebOzkgN4An	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiZlFrOWJpSDVpT25HeE9GcmxDS084ZmpEcjMwcGFLeUFXOVFPSVpldSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304269
XNG2fnPatuvkYP0khSWMOWsR6Peg1Rm6PQJUQFSV	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiUk9IT0Q5QUNwWFozaG9UWW53dEVUalV1cEtqRTUxSjBWUjJXRDRORSI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304271
qKqM6OzHsotXCklg3w0cSbkXR6YCmRj6MlXQK88M	2	127.0.0.1	python-requests/2.32.3	YTo0OntzOjY6Il90b2tlbiI7czo0MDoibzc4SzVReVBab2gxQVRLWU1lRVUzNmVKdFQyMlBYaGlHNXdtQ3BzQSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6Mjt9	1772304273
9o1Hntoo0Nxy2qEYUYr4ge3f86vS44wJzrCvpDlg	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiRlFJTGtFb1JzRlZPOHQ4VEoyQld3RDlreUdXSWZXVllwMGxXcnFVQyI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304273
Dv5sN6SjS9arlb30gsdjXruzXRHURu7KK0QXXcOF	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiY1NuZlB4RndDcFpmTmx4SkJqTXd2czIzNWlyaVBTaXNXQWJLZzV6UCI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304277
ZMgyfWyByojITrlB1oc4t5igmUPRsO7SHs5lrhLL	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiQjBSUkF4R0c4OEtGRU5OVU45S0dXYklIMjF5REl5VFpLcWswWDFVeiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304277
Qlwo1GgaEhHa9dTgj7O6xFeiXer49Jjbany6CZP2	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoidnY5aHJCRGNtdFhSN25kdW1VMFVQUFJnOW9qdWxtYUtIbVN6Qk9OQiI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304279
2kodm0H8vzB4nUU4EqjhUPGLTKGZiWU7StZJww5D	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoibEZIQkNmRzJCUHY1TUZkRVkxZ2Vza2planp3UUR2cXlFd3ViVEx0OSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304279
4On7J8Rgvy5ZNWhP9MkxPbw04epfU99qzhr4GNng	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiMjM4bTdJNU9CdDJCNDY3SXRWaGtIbE5SejR0aGY1TG1lc2NGYWRGNCI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304286
QPXAUbzyTZQlDEMeY0mE7637tReYgBVXZeXPjVuw	\N	127.0.0.1	python-requests/2.32.3	YToyOntzOjY6Il90b2tlbiI7czo0MDoieG9KUU9qZ2kzQVBaWElIT1Z2dmtIVmR3SkhBTjBOZEpMbTVLVnhzMSI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304692
3XtuSRnoxTpc5R0xXTDbVJHDXG0cmb39HwLYDejx	\N	127.0.0.1	python-requests/2.32.3	YToyOntzOjY6Il90b2tlbiI7czo0MDoiQVBuQllJc2Y2OTdrR2V0T2NoMnZ4dVdKTGhRS3M2bzllaGNsOVduZSI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304705
Bq7qBt4l70OVATvDrNmsUiClYI7PALhYZYgUUxLe	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiUjBzNUVFRjNJbG54aXFGZ3V3WVB1NnNCQms5UnN0SmZ6bE1hcjFGVCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304286
9Yi5U6WoYIbwKxBKgVu3LVxuhJ0rdhGOgcbmYC1s	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoidGtXWG9LTTJmQVgwU2txRERmcVpTeno2aTdWUUZTWHFWRUJiYnZDOCI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304294
PYLHWcQrjyfE82KrssmZSDsJqoUKUilK5lRjm54y	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiRmJScVJqUmxZejFPS1hZYmZ5cmFTNkpHM211RXMzU2I5dGVtb0paaiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304294
PuW36PG1rhHyolYT5FNITjmz3lscdLGSx1lF7Xyb	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoidThidGx2TnVIZHZRYmRGbFFVQUNUSW1FUENpZ1B3SElUTlBDNDRLbyI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304297
46Ul3izFdH0A0JpkeOmCMBf7oMEZuue0TUvQedu1	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiMzdRa096a1JXaEhyNUJmWDZKbXZCNmJvTE1ONEQ3cnVjcE5BY3JFNyI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304297
y4elI88QAzxdWb23G3xVcA4QKUx8SgbmjQF9MJAf	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiSjJlV1RaREJzYm0wc3BmMWZsbGZWQzQ2WEl5UGozWUdoUkNpZ2IwdyI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304299
McgPJBOcQvWK0K5xM9RosnaXCi7VyDSBDG3jNGl6	\N	127.0.0.1	python-requests/2.32.3	YTo0OntzOjY6Il90b2tlbiI7czo0MDoiT0F3Z1VqWW5IZ2FCNUYyWnlqNWpobExwRWtHRmZJbXF2aktvWmFSQyI7czozOiJ1cmwiO2E6MTp7czo4OiJpbnRlbmRlZCI7czozMToiaHR0cDovL2xvY2FsaG9zdDo4MDAwL2Rhc2hib2FyZCI7fXM6OToiX3ByZXZpb3VzIjthOjI6e3M6MzoidXJsIjtzOjMxOiJodHRwOi8vbG9jYWxob3N0OjgwMDAvZGFzaGJvYXJkIjtzOjU6InJvdXRlIjtzOjk6ImRhc2hib2FyZCI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=	1772304299
ULXzf0VlvIr6rHcxXuEMxYolDROkT5amumOdUqI9	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoidFF1WGVnVVVqUGUyWE5Eb2g4NEpMczJoYnBjRml2Qk9JZUdvWUhGZCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6Mjc6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9sb2dpbiI7czo1OiJyb3V0ZSI7czo1OiJsb2dpbiI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=	1772304300
4elOyf1NIIndg2Y4be7bNWhvEgDw4fMV2mKa8ZFc	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiUFJIaGt4NWJveUgxUUwxTjlESE9GR2YxazFoNkR2a0tYMUJIQlpvTSI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304302
eHq7TtoHfQ2orUuXED6kSgd1Vk42tvuAJlL03y6r	\N	127.0.0.1	python-requests/2.32.3	YTo0OntzOjY6Il90b2tlbiI7czo0MDoiZVVjQ1VUSzFpUW9nMFBqakVxR0t4dFRRRXRVS3dzWkUzZ2IxU1hLaSI7czozOiJ1cmwiO2E6MTp7czo4OiJpbnRlbmRlZCI7czozMToiaHR0cDovL2xvY2FsaG9zdDo4MDAwL2Rhc2hib2FyZCI7fXM6OToiX3ByZXZpb3VzIjthOjI6e3M6MzoidXJsIjtzOjMxOiJodHRwOi8vbG9jYWxob3N0OjgwMDAvZGFzaGJvYXJkIjtzOjU6InJvdXRlIjtzOjk6ImRhc2hib2FyZCI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=	1772304302
jLrwXazPhrP8dbJEaQ7XcKeLVsx9l8WDYx5KrX6Z	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiQ2FoTng3enZEdmhvdjN3cldRSEZ4ZE5XV2NBcHJNSUZYdDFldWF1MiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6Mjc6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9sb2dpbiI7czo1OiJyb3V0ZSI7czo1OiJsb2dpbiI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=	1772304302
KCT1xFAq4Nv7arGZJYvzppH2XyOjXMa1iJ9sRjp2	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoib3FLclhwNVN3bWNGZnBNcHBObnRIQktnTnQ1WGdna3JBZW1mbko0ayI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304304
2kXXTA3wjxhRQZyHqWZ72i9HJ0rmWnm1BVIAukdr	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiRVZ3U1pldFJEcmpwVUVwZUl6UGlRb1pQTE95Zm1oY0pVTFF2ZnRpZCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304304
YKs1Zki8rb6l5RCLZ2ajVEsHmXDBws7jxV3lIHAZ	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiblhaZ1hYamVjeElucXB6eFZOZ2ZIM2RyOEQ3TUIyUWRqaEttbFFBayI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304307
TAxKdc8vsczt0351K8TFbzO0i1o3nFiCvDILEO2z	\N	127.0.0.1	python-requests/2.32.3	YTo0OntzOjY6Il90b2tlbiI7czo0MDoiUG5Yc0dmdHpoVXQxSWd2WTl3SXViVWRtajJMT3lrSjNUVW84RmdMQSI7czozOiJ1cmwiO2E6MTp7czo4OiJpbnRlbmRlZCI7czozMToiaHR0cDovL2xvY2FsaG9zdDo4MDAwL2Rhc2hib2FyZCI7fXM6OToiX3ByZXZpb3VzIjthOjI6e3M6MzoidXJsIjtzOjMxOiJodHRwOi8vbG9jYWxob3N0OjgwMDAvZGFzaGJvYXJkIjtzOjU6InJvdXRlIjtzOjk6ImRhc2hib2FyZCI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=	1772304307
5n1faeUwKK2VUjV8ZiC13LLqvjXpa90DhlSkKE15	2	127.0.0.1	python-requests/2.32.3	YTo0OntzOjY6Il90b2tlbiI7czo0MDoiTFQzS0JNallncWNDYmJudU5YdzBXUWowNFJ1YjV5RlBnZWg3T3NaeiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6Mjc6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9sb2dpbiI7czo1OiJyb3V0ZSI7czo1OiJsb2dpbiI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fXM6NTA6ImxvZ2luX3dlYl81OWJhMzZhZGRjMmIyZjk0MDE1ODBmMDE0YzdmNThlYTRlMzA5ODlkIjtpOjI7fQ==	1772304309
PAQe9ExXSc6Jo3QcKAPV0zF5oLEUeViPTafy3AXN	\N	127.0.0.1	python-requests/2.32.3	YTo0OntzOjY6Il90b2tlbiI7czo0MDoiQktvVXFDaGVKRDZocTJIbWhnSFBMV0dOSGFxaU90RkdWWFd2MzJrViI7czozOiJ1cmwiO2E6MTp7czo4OiJpbnRlbmRlZCI7czozMToiaHR0cDovL2xvY2FsaG9zdDo4MDAwL2Rhc2hib2FyZCI7fXM6OToiX3ByZXZpb3VzIjthOjI6e3M6MzoidXJsIjtzOjI3OiJodHRwOi8vbG9jYWxob3N0OjgwMDAvbG9naW4iO3M6NToicm91dGUiO3M6NToibG9naW4iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304309
WHAOgDGPHyID4P8lrDRrorwAQddxWV9e7jjhqnq1	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiUEVpSVIxaEdmRXpzbm82V1FsenZkNGlzWGVxSWluS0cyS1pGZHdSUSI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304319
78qBNKLFmwGLoEi1A35IBR9FqYDhAIL1PWlPi9F2	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiQjVlWjR4MEVZVnFrUmlHMTc1UnQ2TE5BRm1Oa0xEQ0kyMHF1MW5xbSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304319
DME4I4E3XdwLcmAgDDpJr0FQd7FBHlTJkIrrWYTe	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoidjFxeHFLaElyMzB5MDlWVTNOdHlNaWRZck5Hb0NHZ2llRUNpVGRRaSI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304321
cGth674MqnkY0vynzveVvdDyK1qazMx3wpbnzOeD	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoidlJYcld0S2FBOEd2YTJEOGFHdGhZbWQ1TUR6eW5zZVpxZWF2MVQ2VSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304321
nZ2sOkfAnRpJPaeIMqX1oT0oFban3AynGCl1osKl	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiNklwVHQ3a2ZCZ05kaHBtNmRIVlpHNXJhb3lKTmE5c2FHZW1lVmh6YyI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304323
7yGZJ1u1APrWnJo2LChjzdy5oHPEeDp4sHNslnal	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiUlZRSXBjMlJFaTNCVFZkNDhkWjNKWUtHbFFweWNVY3M2cklNUXRCVCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304323
P6RlWG3NZNo4sJTdSyXGuv1mVuRhDCsE6r9kVUiZ	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiaW1DUXFOMVJFOHc2WFBQV3EwRVJ0NlhNRk05blE1QmE2Y2tJVkdTZiI7czo2OiJlcnJvcnMiO086MzE6IklsbHVtaW5hdGVcU3VwcG9ydFxWaWV3RXJyb3JCYWciOjE6e3M6NzoiACoAYmFncyI7YToxOntzOjc6ImRlZmF1bHQiO086Mjk6IklsbHVtaW5hdGVcU3VwcG9ydFxNZXNzYWdlQmFnIjoyOntzOjExOiIAKgBtZXNzYWdlcyI7YToxOntzOjU6ImVtYWlsIjthOjE6e2k6MDtzOjI2OiJFbWFpbCBhdGF1IHBhc3N3b3JkIHNhbGFoLiI7fX1zOjk6IgAqAGZvcm1hdCI7czo4OiI6bWVzc2FnZSI7fX19czo2OiJfZmxhc2giO2E6Mjp7czozOiJuZXciO2E6MDp7fXM6Mzoib2xkIjthOjE6e2k6MDtzOjY6ImVycm9ycyI7fX19	1772304324
ZsYTaHuwbicCxpLZRKRbVEY4lvw7cGghX3FN6iQ6	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoib2xqOXJuWEJkTHZNU1NDb1pTNmlZekt2MVhKNHA0TUtBbDJzbThzMSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MjE6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMCI7czo1OiJyb3V0ZSI7czo0OiJob21lIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304325
djJgF0BIIQjF7eW6WZjjw8JKCVaBYXbKtTVYL2Df	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiaDJuNnl2SWxpamxwNGN5UnJQYmx6UGVFSkxDUTVJTGdzRGdxc24zUyI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304327
0aQuD9QgjYCRrI2GfDnDNYEUApJ3BdstbFvtGGJV	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiWVVzeUVIMGFrbU5xaEZlYWNDbXBPSnZ2UFFtaElNaG52RnBjZm1KdyI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304327
7qumgwOTPcuc7imQ1HkbpXsY06JsEBi3hqNWM2Eh	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiekF4VDU0NDBTT1NsemhZUnRvSFpza2tsUXR6ZVlaQ3RaQ2JvdjkzWSI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304338
Ap9YvAgTzSjxSXdDNuC4CU3x3Hm5NZbysMN1T6Lh	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiMTMyUEM3TjZ3Q3BoeUY3OG5OTVh1NkVrRHRqbWdndFlFUkZ1TjdZRSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304338
isZgaMiTqyJf3vlVDGNJ4tUsoClobBJGDAkAYoeu	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoialNjMGhSaEduUDJmS25CcnNENHMwRHFPbVBwbE92YVZMc3gzb2ZvMiI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304342
V41ShzcTDMi0jMgJCAASoEGaWBReBaA23Ilz0qZE	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiU2E5TUo4aW5CNjlsVTI2TGdEaFNCSmFCNmkzZ0V2bjBDRWdVaU9iOCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304342
waplQnBjFK8IsMMByveisuYesZUFHHOosmBDIPJ9	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoib1NObzRhdXd6Sk44NnFGTENUQ1JZZXc5cmdRMFp5ckdDQUdaeVJYOSI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304347
JHQVHrGTvv8IiT1b91HaseXfFJDEuRiOGQAsQzXq	\N	127.0.0.1	python-requests/2.32.3	YTo0OntzOjY6Il90b2tlbiI7czo0MDoiT3FvbU5mc21zdzZ0dThmeTRaR1FMQTBUcjV5MTZ1ZmFtdWdrSHF1QSI7czozOiJ1cmwiO2E6MTp7czo4OiJpbnRlbmRlZCI7czozMToiaHR0cDovL2xvY2FsaG9zdDo4MDAwL2Rhc2hib2FyZCI7fXM6OToiX3ByZXZpb3VzIjthOjI6e3M6MzoidXJsIjtzOjMxOiJodHRwOi8vbG9jYWxob3N0OjgwMDAvZGFzaGJvYXJkIjtzOjU6InJvdXRlIjtzOjk6ImRhc2hib2FyZCI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=	1772304347
meu893p0fEfd5x1KpD3FTQf0fmTlXgxyWRWPtF1X	2	127.0.0.1	python-requests/2.32.3	YTo0OntzOjY6Il90b2tlbiI7czo0MDoiTWxmc2FGNnZXMmhxU3hrVWVqTUVuTkhyM282MlY3RklYSDduWUs5bCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6Mjc6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9sb2dpbiI7czo1OiJyb3V0ZSI7czo1OiJsb2dpbiI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fXM6NTA6ImxvZ2luX3dlYl81OWJhMzZhZGRjMmIyZjk0MDE1ODBmMDE0YzdmNThlYTRlMzA5ODlkIjtpOjI7fQ==	1772304350
VegqmjkjgBCMraNoBS7HxxPk7BvTZsgVTKz22tQJ	\N	127.0.0.1	python-requests/2.32.3	YTo0OntzOjY6Il90b2tlbiI7czo0MDoiTW5sS3NGNmNMcDREUVUyWUVVNTJpV2ZMRE40eGx5SkxMemdVS21uSSI7czozOiJ1cmwiO2E6MTp7czo4OiJpbnRlbmRlZCI7czozMToiaHR0cDovL2xvY2FsaG9zdDo4MDAwL2Rhc2hib2FyZCI7fXM6OToiX3ByZXZpb3VzIjthOjI6e3M6MzoidXJsIjtzOjI3OiJodHRwOi8vbG9jYWxob3N0OjgwMDAvbG9naW4iO3M6NToicm91dGUiO3M6NToibG9naW4iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304350
WG9PXzNAXFDkuhhMgl4ltbDYEApXkTadyIEJa6iz	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiNzhwNFIwS3VpbHZsTmRtdWVEdWFScDJIU1loMHJ0bGlmc2xuNWdXSCI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304364
sBhRskakcmdaqUZu5mf9ek77OpO48FR9lg5GnWed	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiUlM5bzhQQVhhWWZKemI3ODNxQmw3TnBYVXZGMU0wOEw5MUNuTXd1biI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304364
fADoIIKupBOPgZNnY7V3dFieC1VJtnIHAxu7p89z	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiWHpLaExZMnlXU2NlRkdiNFJOcHRqV0NxdmRaV3VHbWdYeUM4c1NycSI7czo2OiJlcnJvcnMiO086MzE6IklsbHVtaW5hdGVcU3VwcG9ydFxWaWV3RXJyb3JCYWciOjE6e3M6NzoiACoAYmFncyI7YToxOntzOjc6ImRlZmF1bHQiO086Mjk6IklsbHVtaW5hdGVcU3VwcG9ydFxNZXNzYWdlQmFnIjoyOntzOjExOiIAKgBtZXNzYWdlcyI7YToxOntzOjU6ImVtYWlsIjthOjE6e2k6MDtzOjI2OiJFbWFpbCBhdGF1IHBhc3N3b3JkIHNhbGFoLiI7fX1zOjk6IgAqAGZvcm1hdCI7czo4OiI6bWVzc2FnZSI7fX19czo2OiJfZmxhc2giO2E6Mjp7czozOiJuZXciO2E6MDp7fXM6Mzoib2xkIjthOjE6e2k6MDtzOjY6ImVycm9ycyI7fX19	1772304374
thaEk9rFcMbIfDKT2eSbnanLTaHW0sVjdnMq7DkJ	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiNkJBV1pqajVVOGJ1clBlMGZJUGx0QXJ0WlI0NkdQRmptOUQwRE4yUSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MjE6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMCI7czo1OiJyb3V0ZSI7czo0OiJob21lIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304374
BInD8RYtHqJx7Z4OEp2X7MIUD6VTQQgrYhHOX6CW	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiUkxvbGViZTJjbFBiYng5c2o3QTVhbk9hVWxYb3RNeFBJREFZQWhSTyI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304376
qQHD8osAqdpNMLEdSWWczVMf8GJZ3PHqGxRTI2Qx	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoielkxNkZqelo3ZzgyTEQ1WUdHQUx2bkZHNHpnS3g2VkNjaUY2ZTdhMCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly9sb2NhbGhvc3Q6ODAwMC9kYXNoYm9hcmQiO3M6NToicm91dGUiO3M6OToiZGFzaGJvYXJkIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304376
Li9bFjjeFevJwzwsjPfykPPAj6EJLSYiffluDfqg	2	127.0.0.1	curl/7.53.1	YTozOntzOjY6Il90b2tlbiI7czo0MDoidG9taXIyUTlKRlFWTWpScll1T016V1JtVGZtZlBVcWJrZDdrMjBibCI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304404
Nl05B4yLCPS8VqUn32hDXphbfO2OjlaSll3M78Eb	2	127.0.0.1	curl/7.53.1	YTozOntzOjY6Il90b2tlbiI7czo0MDoiQWtBZ0pVYm5jdnlieUhraU1jbFgxV2lHWno0cFFHMGZUU1FPb0ZRSyI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304426
OqQPWIuHn1Y5Mo35n5tKaEzdxlpzV1KkFbivkNJX	2	127.0.0.1	python-requests/2.32.5	YTozOntzOjY6Il90b2tlbiI7czo0MDoiUDQ4R1djVjdMNjR5bEF6aDVhT1cyMVlOUnNpUUhSN0ZqYTBBVHU3dyI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304459
022EMSwnRnVcuFH2UXyt1W2jM1wBtWufJyY7W1HU	\N	127.0.0.1	python-requests/2.32.5	YTozOntzOjY6Il90b2tlbiI7czo0MDoiQUNma21XUmk5dENvbGZBRHNXd3JNd2xzd1p1amh2QUJ6QkhmWkpXMyI7czo2OiJlcnJvcnMiO086MzE6IklsbHVtaW5hdGVcU3VwcG9ydFxWaWV3RXJyb3JCYWciOjE6e3M6NzoiACoAYmFncyI7YToxOntzOjc6ImRlZmF1bHQiO086Mjk6IklsbHVtaW5hdGVcU3VwcG9ydFxNZXNzYWdlQmFnIjoyOntzOjExOiIAKgBtZXNzYWdlcyI7YToxOntzOjU6ImVtYWlsIjthOjE6e2k6MDtzOjI2OiJFbWFpbCBhdGF1IHBhc3N3b3JkIHNhbGFoLiI7fX1zOjk6IgAqAGZvcm1hdCI7czo4OiI6bWVzc2FnZSI7fX19czo2OiJfZmxhc2giO2E6Mjp7czozOiJuZXciO2E6MDp7fXM6Mzoib2xkIjthOjE6e2k6MDtzOjY6ImVycm9ycyI7fX19	1772304459
ETMjAaCcDeO5uVqNaSbSCHhZzc9n3mDUj2wYfDZG	2	127.0.0.1	python-requests/2.32.5	YTozOntzOjY6Il90b2tlbiI7czo0MDoieEZ3ZVQwRkgxMWJQS0p2aVVmdVBwVkRFa3I3dDRsSlpsSjVmeWdUNSI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304579
HLzrMxE2vsi3RS5w4oOICef0t7I5fFbydQuFQQrk	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiUTREZkhNc2dMTjZxSWhScENoR3A5a1F3MVhkU2JESlVkSnNCYTdVWSI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304682
ZeL4F00aS0Wj9RbbXw1wh6S2GERuHRcTTxr5ucSb	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiaUJDWDhJbkNXSUtIdkNlem51Z28xQnZqWjdLaFpBaW9pVlEyMUZ2NCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6Mzg6Imh0dHA6Ly8xMjcuMC4wLjEubmlwLmlvOjgwMDAvZGFzaGJvYXJkIjtzOjU6InJvdXRlIjtzOjk6ImRhc2hib2FyZCI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=	1772304682
a6twM6a01OhOpoRtpVucAnUky6skNiwtzRmAMuzf	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoidHZaS2FaTEkyRk1Ka1QySkZMbURCSFdtN1ZMR3BPWlprbU85Z3Y3aiI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304684
5o2RXobHN4xdclYZwB3J2ENVkEFQdBAO2pFKR14e	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiRlppR1VLUXRBSU9ob0hicXBuTXJKQ1NoV1drZEpoTXE5Q0xGalcyeSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6Mzg6Imh0dHA6Ly8xMjcuMC4wLjEubmlwLmlvOjgwMDAvZGFzaGJvYXJkIjtzOjU6InJvdXRlIjtzOjk6ImRhc2hib2FyZCI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=	1772304684
3CbqIcVMKB3L6U4QhhYf1hlAfxFGWbp0zNBc5nKg	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiYkhGVVpTNXAzZnByam9pU1pFYkZuVjQyOVloYk1IUHA0c2dYeFF3MCI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304686
rRbp8A49p2oGtwQWLQ46Lz3bu4l52XBbyvubYTwQ	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiUENsTUNCbVlycTJEYzc3ZXNFdFhwWVZhUDRlN05Od2thMkZWenVadyI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6Mzg6Imh0dHA6Ly8xMjcuMC4wLjEubmlwLmlvOjgwMDAvZGFzaGJvYXJkIjtzOjU6InJvdXRlIjtzOjk6ImRhc2hib2FyZCI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=	1772304686
JUqnzfCWHFZIKgcujfZhTooUwreSxyCxAKoJHtoY	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiak9ONmpQU0RZZXRpYWg3YlVGQVRidHNheFp6bnM4NWpiZ2JqS3hBcSI7czo2OiJlcnJvcnMiO086MzE6IklsbHVtaW5hdGVcU3VwcG9ydFxWaWV3RXJyb3JCYWciOjE6e3M6NzoiACoAYmFncyI7YToxOntzOjc6ImRlZmF1bHQiO086Mjk6IklsbHVtaW5hdGVcU3VwcG9ydFxNZXNzYWdlQmFnIjoyOntzOjExOiIAKgBtZXNzYWdlcyI7YToxOntzOjU6ImVtYWlsIjthOjE6e2k6MDtzOjI2OiJFbWFpbCBhdGF1IHBhc3N3b3JkIHNhbGFoLiI7fX1zOjk6IgAqAGZvcm1hdCI7czo4OiI6bWVzc2FnZSI7fX19czo2OiJfZmxhc2giO2E6Mjp7czozOiJuZXciO2E6MDp7fXM6Mzoib2xkIjthOjE6e2k6MDtzOjY6ImVycm9ycyI7fX19	1772304688
CQcc9tFJ93hDPPIYHHx5RmIXfVuU79LM1LXCiFDe	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiM1h6TnV5dWhXOEM4SWZiM0ZtV2RSV1R6aklVOHRvM1lUeWNPSzJ5QiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6Mjg6Imh0dHA6Ly8xMjcuMC4wLjEubmlwLmlvOjgwMDAiO3M6NToicm91dGUiO3M6NDoiaG9tZSI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=	1772304688
11Yj5cknVYz8sgrBe2aosK05pQC4RizrGgRUxtNw	2	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiMFBCUk1hUzNZckx4c2t2Rzh3OFVNTTc1a1p4cVBZRDNoczJseDdQNCI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MjtzOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304690
E8G0kOTb6hoy9SyVrfrNGT5nNRE6no1twvc0fA1y	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiNEU5ZFdSZzNRMlptbVRIM1pkQTlEZVZXUEJuMlFyZW8wakdQS3dhMyI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6Mzg6Imh0dHA6Ly8xMjcuMC4wLjEubmlwLmlvOjgwMDAvZGFzaGJvYXJkIjtzOjU6InJvdXRlIjtzOjk6ImRhc2hib2FyZCI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=	1772304691
zNP7fHh0July0ZC2hLBqo8JkV95ImszoDqGcjBYv	\N	127.0.0.1	python-requests/2.32.3	YToyOntzOjY6Il90b2tlbiI7czo0MDoiN01kU05IM3ZmTFhlaHlsaWs1QzJUSWsxME1iOVlablhnUUZvOFcwdCI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304707
gdQJ0Ozf6kgEr9C8w331L4ksNDvRkHdNfBGcusUA	\N	127.0.0.1	python-requests/2.32.3	YToyOntzOjY6Il90b2tlbiI7czo0MDoic2NycVBzdXlnSFA2VXhxeEtkV0lLWjNPejRnVDZkMjBvcllQYkdQYSI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304716
bEhPG8jlcvVtVglNocKtIakM58czwVJK4jc8jyJF	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiUXNsdFUwU3RhTlUzQ1JkZDNQaklHNVJXTnMyNzlMYlVqNU54dEVPMiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzQ6Imh0dHA6Ly8xMjcuMC4wLjEubmlwLmlvOjgwMDAvbG9naW4iO3M6NToicm91dGUiO3M6NToibG9naW4iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304724
faijHLB3J5al8KOvBNJ7ZX05s4dTpW4KaTO8BjdO	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiSGhSR05PeWMzTmlPQlpnOWRuaTdwZm82bkxzS3FxRjl0U2tnSWJCVSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzQ6Imh0dHA6Ly8xMjcuMC4wLjEubmlwLmlvOjgwMDAvbG9naW4iO3M6NToicm91dGUiO3M6NToibG9naW4iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304727
xoX6cdruDaiLZB7WDT1ZqsUIpPmmsw5PV6XhQDND	\N	127.0.0.1	python-requests/2.32.3	YToyOntzOjY6Il90b2tlbiI7czo0MDoiSWh4Z2JBbFlnSnJwWGxXdHFxTWlkeHloRmhBQVhFb1V5c3R0WXM1QyI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304729
i8ndiJYwG6LWwSLTq2EW40jRF7UUMy105RpB3P0P	\N	127.0.0.1	python-requests/2.32.3	YToyOntzOjY6Il90b2tlbiI7czo0MDoieVlDMDVjalpqNWUxbjFqbUxpZXc4VUp2RERzTWdvbXpGUUJiUWZpSiI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304730
mqnAOo8A5kuVNe7EUCDgOHpUcnrLOWTAaOARC6pT	\N	127.0.0.1	python-requests/2.32.3	YToyOntzOjY6Il90b2tlbiI7czo0MDoiUFc2NlcxY1FvS0ZjdzlvV2JIdW12M3MxU2ZvMWxpb3hOYUFxSVl3eSI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304733
lUgfpsCeRbeQmHFslesB4cSxZT4l8kB2bfq2fq66	\N	127.0.0.1	python-requests/2.32.3	YToyOntzOjY6Il90b2tlbiI7czo0MDoiYlZ0b2N6Ukw0UkFKak43UkdVZ3ZwNGdyRkF1dU4yMmVVQWVna2ZCUiI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304735
4ALZXgm8tHAdt8p0vQTERbuN8cCWcPDYBEA0SjNT	\N	127.0.0.1	python-requests/2.32.3	YToyOntzOjY6Il90b2tlbiI7czo0MDoiVlJoNTZpdW05Zlo1dllqUjg0Z2ZWRXdCelhsMVZzUHZQTDVOQjZOWiI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304737
bKMXYXfQ57dDPtEXSmloTOjgOljVBdoIcgaP6NdI	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiQXRsRXdvaFVSVmdRV1BaSFF6ckhiTGlpcFBjSWJrNTJDY3pNUG54MSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzQ6Imh0dHA6Ly8xMjcuMC4wLjEubmlwLmlvOjgwMDAvbG9naW4iO3M6NToicm91dGUiO3M6NToibG9naW4iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304739
tRSS2RXPyh2emT74UAVzmuwKxTGyBMfccuTgeRNf	\N	127.0.0.1	python-requests/2.32.3	YToyOntzOjY6Il90b2tlbiI7czo0MDoiMEgwYjBLVGRoWmliNDE1YWRFZnl0d0tCYURrdEh6SEV3WmhqYWVjViI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304741
MB3HRQgGuizOpYwCtvZbSHMOsnJuPIBpTKPc46BB	\N	127.0.0.1	python-requests/2.32.3	YToyOntzOjY6Il90b2tlbiI7czo0MDoiaHVTUEp2UE1kVVFJM2RlZUtOaDV1UXJ5MGxNMjhjZ0k3WXVRQTJweiI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304745
MAMDPWNznbqozAQrQTxVLEUAQhEH201RzcQlH4i3	\N	127.0.0.1	python-requests/2.32.3	YToyOntzOjY6Il90b2tlbiI7czo0MDoiWWtxaGY3d0lIU2hLd0lnWERoeGZqMHJSQVBmMXg4THJkdFZ4bm91UyI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304761
am6fzkgl2somZjcfaIq9ZVqqMw0i0QvFrS7XQlwV	\N	127.0.0.1	python-requests/2.32.3	YToyOntzOjY6Il90b2tlbiI7czo0MDoialAwQUY4SGdYZXU4Rm4ybkx3TXYzMTZ2a0FUSjFwTmdNMVVKempzbyI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304765
aaQ9zLid8dQXkfkq8LzOZ94bKLy5egf00K0vZCLC	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiaUJ5OUlyWmc0WWtCazJIcnhiNXY3NnRPMVVZTUlvVWVYdXJQMnJ1UCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzQ6Imh0dHA6Ly8xMjcuMC4wLjEubmlwLmlvOjgwMDAvbG9naW4iO3M6NToicm91dGUiO3M6NToibG9naW4iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304768
Zr33PHZujxjFLVSFM4dlgMsjr1oJAMuvFqiCAJrD	\N	127.0.0.1	python-requests/2.32.3	YToyOntzOjY6Il90b2tlbiI7czo0MDoiZVY4elRWRDdXOURBUGhSd1hBMjB0VzRpSUQ3MmxYUDFsbU16Y2o3ZiI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304772
3Nb8G6z03okFRTGG5aXD5eewalTOBaxqbLnGj9Iw	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiRFdIQkprQ1c2RU83cWxWWFFiMmtGaWs5ZnJ0VVpRV3FnelhnZzRBRCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzQ6Imh0dHA6Ly8xMjcuMC4wLjEubmlwLmlvOjgwMDAvbG9naW4iO3M6NToicm91dGUiO3M6NToibG9naW4iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304783
CkqWSEMO4iZ7Du8jBAmbMxfH4GBChXQ2C2pa5Yux	\N	127.0.0.1	python-requests/2.32.3	YToyOntzOjY6Il90b2tlbiI7czo0MDoianEwTHRzYWhMUmZDTnY0YnRmaGx6cEdEaDh5YU9QYnpGU3NLZFB3QSI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1772304785
lnOFgvPpKP26m1zr4s6vfWilycksTsgXbIAGpKgx	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiR2FpM0Z3VDBEelA1YUJRdndPQ0ZYZkRENU1kSmRodTJ5YXh2RXdGeCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzQ6Imh0dHA6Ly8xMjcuMC4wLjEubmlwLmlvOjgwMDAvbG9naW4iO3M6NToicm91dGUiO3M6NToibG9naW4iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304800
suzvgFTnqKvtdKKY2vtqDLNqr3dOIlK7XG4dl0qa	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiRGROeUZNVmpVNEZGMGEza2g4U0lVMVJKT1BEWHZkdzBiM0g5TFg5bSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzQ6Imh0dHA6Ly8xMjcuMC4wLjEubmlwLmlvOjgwMDAvbG9naW4iO3M6NToicm91dGUiO3M6NToibG9naW4iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304815
bU8ynxWDp25X6MTr217UklofCio0l7TlSqHu5XE2	\N	127.0.0.1	python-requests/2.32.3	YTozOntzOjY6Il90b2tlbiI7czo0MDoiNXZ3RlJyZ05nYUR6U1E5S0REcjU0a2xLSW1ad3FpdzQ2OVRFVlk4MyI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzQ6Imh0dHA6Ly8xMjcuMC4wLjEubmlwLmlvOjgwMDAvbG9naW4iO3M6NToicm91dGUiO3M6NToibG9naW4iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1772304834
FoHlKzLnft8OWAN0ryk6BUQaKrhuAkplRjh9loEc	9	127.0.0.1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	YTo0OntzOjY6Il90b2tlbiI7czo0MDoieG5sU0FzMkZNQ3NmNFcyeEdyUndIU2xRR0dvVExwenZwNmh1cjQxUiI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6OTtzOjk6Il9wcmV2aW91cyI7YToyOntzOjM6InVybCI7czozMToiaHR0cDovLzEyNy4wLjAuMTo4MDAwL2Rhc2hib2FyZCI7czo1OiJyb3V0ZSI7czo5OiJkYXNoYm9hcmQiO319	1773285329
\.


--
-- Data for Name: student_health_records; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.student_health_records (id, student_id, blood_type, height, weight, medical_history, allergies, special_needs, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: student_mutations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.student_mutations (id, student_id, type, from_class_id, to_class_id, date, reason, reference_number, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: students; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.students (id, nis, nisn, name, gender, birth_place, birth_date, religion, address, parent_name, parent_phone, email, class_id, status, photo_url, created_at, updated_at, family_card_number, nik) FROM stdin;
\.


--
-- Data for Name: subjects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subjects (id, code, name, education_level, grade_level, kkm, category, description, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: submission_attachments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.submission_attachments (id, submission_id, file_path, file_name, file_type, file_size, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: task_scores; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.task_scores (id, task_id, student_id, score, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: tasks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tasks (id, class_id, subject_id, semester_id, teacher_id, title, description, task_date, due_date, max_score, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: teachers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.teachers (id, nip, nuptk, name, gender, birth_place, birth_date, email, phone, address, is_homeroom, photo_url, status, user_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: teaching_assignments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.teaching_assignments (id, teacher_id, subject_id, class_id, academic_year_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, name, email, email_verified_at, password, role, avatar_url, is_active, remember_token, created_at, updated_at) FROM stdin;
1	Admin Sekolah	admin@smp01.com	\N	$2y$12$yyKgMxUoCF0eqUuX.51mjOmq6A1kAQQ/tU1bU0T8axlF8hixOANj2	school_admin	https://ui-avatars.com/api/?name=Admin+Sekolah&background=random	t	\N	2026-02-21 01:22:56	2026-02-21 01:22:56
2	Drs. H. Sugeng Riyadi, M.Pd	kepsek@smp01.com	\N	$2y$12$yyKgMxUoCF0eqUuX.51mjOmq6A1kAQQ/tU1bU0T8axlF8hixOANj2	teacher	https://ui-avatars.com/api/?name=Sugeng+Riyadi&background=random	t	\N	2026-02-21 01:22:56	2026-02-21 01:22:56
3	Guru VII A Zulfa Mandasari	guru1@smp01.com	\N	$2y$12$yyKgMxUoCF0eqUuX.51mjOmq6A1kAQQ/tU1bU0T8axlF8hixOANj2	teacher	https://ui-avatars.com/api/?name=Guru+VII+A&background=random	t	\N	2026-02-21 01:22:56	2026-02-21 01:22:56
4	Guru VIII A Eva Haryanti	guru2@smp01.com	\N	$2y$12$yyKgMxUoCF0eqUuX.51mjOmq6A1kAQQ/tU1bU0T8axlF8hixOANj2	teacher	https://ui-avatars.com/api/?name=Guru+VIII+A&background=random	t	\N	2026-02-21 01:22:56	2026-02-21 01:22:56
5	Guru IX A Karya Mahendra	guru3@smp01.com	\N	$2y$12$yyKgMxUoCF0eqUuX.51mjOmq6A1kAQQ/tU1bU0T8axlF8hixOANj2	teacher	https://ui-avatars.com/api/?name=Guru+IX+A&background=random	t	\N	2026-02-21 01:22:56	2026-02-21 01:22:56
6	Jane Permata	guru_mapel0@smp01.com	\N	$2y$12$yyKgMxUoCF0eqUuX.51mjOmq6A1kAQQ/tU1bU0T8axlF8hixOANj2	teacher	https://ui-avatars.com/api/?name=Jane+Permata&background=random	t	\N	2026-02-21 01:22:56	2026-02-21 01:22:56
7	Jaiman Nashiruddin	guru_mapel1@smp01.com	\N	$2y$12$yyKgMxUoCF0eqUuX.51mjOmq6A1kAQQ/tU1bU0T8axlF8hixOANj2	teacher	https://ui-avatars.com/api/?name=Jaiman+Nashiruddin&background=random	t	\N	2026-02-21 01:22:56	2026-02-21 01:22:56
8	Darmanto Bagiya Prakasa M.M.	guru_mapel2@smp01.com	\N	$2y$12$yyKgMxUoCF0eqUuX.51mjOmq6A1kAQQ/tU1bU0T8axlF8hixOANj2	teacher	https://ui-avatars.com/api/?name=Darmanto+Bagiya+Prakasa+M.M.&background=random	t	\N	2026-02-21 01:22:56	2026-02-21 01:22:56
9	Samiah Kamaria Halimah	samiahkamariahalimah@siswa.smp01.com	\N	$2y$12$yyKgMxUoCF0eqUuX.51mjOmq6A1kAQQ/tU1bU0T8axlF8hixOANj2	student	https://ui-avatars.com/api/?name=Samiah+Kamaria+Halimah&background=random	t	\N	2026-02-21 01:22:56	2026-02-21 01:22:56
10	Bagas Hardiansyah	bagashardiansyah@siswa.smp01.com	\N	$2y$12$yyKgMxUoCF0eqUuX.51mjOmq6A1kAQQ/tU1bU0T8axlF8hixOANj2	student	https://ui-avatars.com/api/?name=Bagas+Hardiansyah&background=random	t	\N	2026-02-21 01:22:56	2026-02-21 01:22:56
11	Purwanto Galih Pradipta S.H.	purwantogalihpradiptash@siswa.smp01.com	\N	$2y$12$yyKgMxUoCF0eqUuX.51mjOmq6A1kAQQ/tU1bU0T8axlF8hixOANj2	student	https://ui-avatars.com/api/?name=Purwanto+Galih+Pradipta+S.H.&background=random	t	\N	2026-02-21 01:22:56	2026-02-21 01:22:56
12	Endah Ophelia Wahyuni	endahopheliawahyuni@siswa.smp01.com	\N	$2y$12$yyKgMxUoCF0eqUuX.51mjOmq6A1kAQQ/tU1bU0T8axlF8hixOANj2	student	https://ui-avatars.com/api/?name=Endah+Ophelia+Wahyuni&background=random	t	\N	2026-02-21 01:22:56	2026-02-21 01:22:56
13	Lantar Dagel Jailani	lantardageljailani@siswa.smp01.com	\N	$2y$12$yyKgMxUoCF0eqUuX.51mjOmq6A1kAQQ/tU1bU0T8axlF8hixOANj2	student	https://ui-avatars.com/api/?name=Lantar+Dagel+Jailani&background=random	t	\N	2026-02-21 01:22:56	2026-02-21 01:22:56
14	Shania Pertiwi	shaniapertiwi@siswa.smp01.com	\N	$2y$12$yyKgMxUoCF0eqUuX.51mjOmq6A1kAQQ/tU1bU0T8axlF8hixOANj2	student	https://ui-avatars.com/api/?name=Shania+Pertiwi&background=random	t	\N	2026-02-21 01:22:56	2026-02-21 01:22:56
15	Darsirah Harimurti Budiman S.H.	darsirahharimurtibudimansh@siswa.smp01.com	\N	$2y$12$yyKgMxUoCF0eqUuX.51mjOmq6A1kAQQ/tU1bU0T8axlF8hixOANj2	student	https://ui-avatars.com/api/?name=Darsirah+Harimurti+Budiman+S.H.&background=random	t	\N	2026-02-21 01:22:56	2026-02-21 01:22:56
16	Rachel Pertiwi	rachelpertiwi@siswa.smp01.com	\N	$2y$12$yyKgMxUoCF0eqUuX.51mjOmq6A1kAQQ/tU1bU0T8axlF8hixOANj2	student	https://ui-avatars.com/api/?name=Rachel+Pertiwi&background=random	t	\N	2026-02-21 01:22:56	2026-02-21 01:22:56
17	Prayogo Mansur	prayogomansur@siswa.smp01.com	\N	$2y$12$yyKgMxUoCF0eqUuX.51mjOmq6A1kAQQ/tU1bU0T8axlF8hixOANj2	student	https://ui-avatars.com/api/?name=Prayogo+Mansur&background=random	t	\N	2026-02-21 01:22:56	2026-02-21 01:22:56
18	Murti Kusumo	murtikusumo@siswa.smp01.com	\N	$2y$12$yyKgMxUoCF0eqUuX.51mjOmq6A1kAQQ/tU1bU0T8axlF8hixOANj2	student	https://ui-avatars.com/api/?name=Murti+Kusumo&background=random	t	\N	2026-02-21 01:22:56	2026-02-21 01:22:56
19	Estiono Hari Januar S.Gz	estionoharijanuarsgz@siswa.smp01.com	\N	$2y$12$yyKgMxUoCF0eqUuX.51mjOmq6A1kAQQ/tU1bU0T8axlF8hixOANj2	student	https://ui-avatars.com/api/?name=Estiono+Hari+Januar+S.Gz&background=random	t	\N	2026-02-21 01:22:56	2026-02-21 01:22:56
20	Uchita Wulan Wastuti M.Ak	uchitawulanwastutimak@siswa.smp01.com	\N	$2y$12$yyKgMxUoCF0eqUuX.51mjOmq6A1kAQQ/tU1bU0T8axlF8hixOANj2	student	https://ui-avatars.com/api/?name=Uchita+Wulan+Wastuti+M.Ak&background=random	t	\N	2026-02-21 01:22:56	2026-02-21 01:22:56
21	Mariadi Lazuardi S.E.I	mariadilazuardisei@siswa.smp01.com	\N	$2y$12$yyKgMxUoCF0eqUuX.51mjOmq6A1kAQQ/tU1bU0T8axlF8hixOANj2	student	https://ui-avatars.com/api/?name=Mariadi+Lazuardi+S.E.I&background=random	t	\N	2026-02-21 01:22:56	2026-02-21 01:22:56
22	Alika Ana Yulianti	alikaanayulianti@siswa.smp01.com	\N	$2y$12$yyKgMxUoCF0eqUuX.51mjOmq6A1kAQQ/tU1bU0T8axlF8hixOANj2	student	https://ui-avatars.com/api/?name=Alika+Ana+Yulianti&background=random	t	\N	2026-02-21 01:22:56	2026-02-21 01:22:56
23	Malika Elvina Wahyuni	malikaelvinawahyuni@siswa.smp01.com	\N	$2y$12$yyKgMxUoCF0eqUuX.51mjOmq6A1kAQQ/tU1bU0T8axlF8hixOANj2	student	https://ui-avatars.com/api/?name=Malika+Elvina+Wahyuni&background=random	t	\N	2026-02-21 01:22:56	2026-02-21 01:22:56
\.


--
-- Name: academic_years_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.academic_years_id_seq', 1, false);


--
-- Name: announcements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.announcements_id_seq', 1, false);


--
-- Name: assignment_attachments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.assignment_attachments_id_seq', 1, false);


--
-- Name: assignment_submissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.assignment_submissions_id_seq', 1, false);


--
-- Name: assignments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.assignments_id_seq', 1, false);


--
-- Name: attendance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.attendance_id_seq', 1, false);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.audit_logs_id_seq', 1, false);


--
-- Name: classes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.classes_id_seq', 1, false);


--
-- Name: counseling_notes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.counseling_notes_id_seq', 1, false);


--
-- Name: exam_scores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.exam_scores_id_seq', 1, false);


--
-- Name: exams_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.exams_id_seq', 1, false);


--
-- Name: failed_jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.failed_jobs_id_seq', 1, false);


--
-- Name: grades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.grades_id_seq', 1, false);


--
-- Name: jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.jobs_id_seq', 1, false);


--
-- Name: meeting_materials_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.meeting_materials_id_seq', 1, false);


--
-- Name: meetings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.meetings_id_seq', 1, false);


--
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.migrations_id_seq', 35, true);


--
-- Name: offline_assignment_answers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.offline_assignment_answers_id_seq', 1, false);


--
-- Name: offline_assignment_classes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.offline_assignment_classes_id_seq', 1, false);


--
-- Name: offline_assignment_files_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.offline_assignment_files_id_seq', 1, false);


--
-- Name: offline_assignment_questions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.offline_assignment_questions_id_seq', 1, false);


--
-- Name: offline_assignment_submissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.offline_assignment_submissions_id_seq', 1, false);


--
-- Name: offline_assignments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.offline_assignments_id_seq', 1, false);


--
-- Name: offline_submission_files_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.offline_submission_files_id_seq', 1, false);


--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.personal_access_tokens_id_seq', 1, false);


--
-- Name: report_cards_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.report_cards_id_seq', 1, false);


--
-- Name: semesters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.semesters_id_seq', 1, false);


--
-- Name: student_health_records_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.student_health_records_id_seq', 1, false);


--
-- Name: student_mutations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.student_mutations_id_seq', 1, false);


--
-- Name: students_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.students_id_seq', 1, false);


--
-- Name: subjects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.subjects_id_seq', 1, false);


--
-- Name: submission_attachments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.submission_attachments_id_seq', 1, false);


--
-- Name: task_scores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.task_scores_id_seq', 1, false);


--
-- Name: tasks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tasks_id_seq', 1, false);


--
-- Name: teachers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.teachers_id_seq', 1, false);


--
-- Name: teaching_assignments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.teaching_assignments_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 2, true);


--
-- Name: academic_years academic_years_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_years
    ADD CONSTRAINT academic_years_pkey PRIMARY KEY (id);


--
-- Name: announcements announcements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_pkey PRIMARY KEY (id);


--
-- Name: assignment_attachments assignment_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignment_attachments
    ADD CONSTRAINT assignment_attachments_pkey PRIMARY KEY (id);


--
-- Name: assignment_submissions assignment_submissions_assignment_id_student_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignment_submissions
    ADD CONSTRAINT assignment_submissions_assignment_id_student_id_unique UNIQUE (assignment_id, student_id);


--
-- Name: assignment_submissions assignment_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignment_submissions
    ADD CONSTRAINT assignment_submissions_pkey PRIMARY KEY (id);


--
-- Name: assignments assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_pkey PRIMARY KEY (id);


--
-- Name: attendance attendance_meeting_student_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_meeting_student_unique UNIQUE (class_id, semester_id, meeting_number, student_id);


--
-- Name: attendance attendance_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: cache_locks cache_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cache_locks
    ADD CONSTRAINT cache_locks_pkey PRIMARY KEY (key);


--
-- Name: cache cache_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cache
    ADD CONSTRAINT cache_pkey PRIMARY KEY (key);


--
-- Name: classes classes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.classes
    ADD CONSTRAINT classes_pkey PRIMARY KEY (id);


--
-- Name: counseling_notes counseling_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.counseling_notes
    ADD CONSTRAINT counseling_notes_pkey PRIMARY KEY (id);


--
-- Name: exam_scores exam_scores_exam_id_student_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_scores
    ADD CONSTRAINT exam_scores_exam_id_student_id_unique UNIQUE (exam_id, student_id);


--
-- Name: exam_scores exam_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_scores
    ADD CONSTRAINT exam_scores_pkey PRIMARY KEY (id);


--
-- Name: exams exams_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT exams_pkey PRIMARY KEY (id);


--
-- Name: failed_jobs failed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- Name: failed_jobs failed_jobs_uuid_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);


--
-- Name: grades grades_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT grades_pkey PRIMARY KEY (id);


--
-- Name: grades grades_student_id_subject_id_semester_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT grades_student_id_subject_id_semester_id_unique UNIQUE (student_id, subject_id, semester_id);


--
-- Name: job_batches job_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_batches
    ADD CONSTRAINT job_batches_pkey PRIMARY KEY (id);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: meeting_materials meeting_materials_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meeting_materials
    ADD CONSTRAINT meeting_materials_pkey PRIMARY KEY (id);


--
-- Name: meetings meetings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meetings
    ADD CONSTRAINT meetings_pkey PRIMARY KEY (id);


--
-- Name: meetings meetings_ta_number_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meetings
    ADD CONSTRAINT meetings_ta_number_unique UNIQUE (teaching_assignment_id, meeting_number);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: offline_assignment_answers oa_answer_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignment_answers
    ADD CONSTRAINT oa_answer_unique UNIQUE (submission_id, question_id);


--
-- Name: offline_assignment_classes oa_classes_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignment_classes
    ADD CONSTRAINT oa_classes_unique UNIQUE (offline_assignment_id, class_id);


--
-- Name: offline_assignment_submissions oa_submissions_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignment_submissions
    ADD CONSTRAINT oa_submissions_unique UNIQUE (offline_assignment_id, student_id);


--
-- Name: offline_assignment_answers offline_assignment_answers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignment_answers
    ADD CONSTRAINT offline_assignment_answers_pkey PRIMARY KEY (id);


--
-- Name: offline_assignment_classes offline_assignment_classes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignment_classes
    ADD CONSTRAINT offline_assignment_classes_pkey PRIMARY KEY (id);


--
-- Name: offline_assignment_files offline_assignment_files_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignment_files
    ADD CONSTRAINT offline_assignment_files_pkey PRIMARY KEY (id);


--
-- Name: offline_assignment_questions offline_assignment_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignment_questions
    ADD CONSTRAINT offline_assignment_questions_pkey PRIMARY KEY (id);


--
-- Name: offline_assignment_submissions offline_assignment_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignment_submissions
    ADD CONSTRAINT offline_assignment_submissions_pkey PRIMARY KEY (id);


--
-- Name: offline_assignments offline_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignments
    ADD CONSTRAINT offline_assignments_pkey PRIMARY KEY (id);


--
-- Name: offline_submission_files offline_submission_files_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_submission_files
    ADD CONSTRAINT offline_submission_files_pkey PRIMARY KEY (id);


--
-- Name: password_reset_tokens password_reset_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (email);


--
-- Name: personal_access_tokens personal_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: personal_access_tokens personal_access_tokens_token_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_token_unique UNIQUE (token);


--
-- Name: report_cards report_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_cards
    ADD CONSTRAINT report_cards_pkey PRIMARY KEY (id);


--
-- Name: report_cards report_cards_student_id_semester_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_cards
    ADD CONSTRAINT report_cards_student_id_semester_id_unique UNIQUE (student_id, semester_id);


--
-- Name: schedules schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedules
    ADD CONSTRAINT schedules_pkey PRIMARY KEY (id);


--
-- Name: semesters semesters_academic_year_id_semester_number_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.semesters
    ADD CONSTRAINT semesters_academic_year_id_semester_number_unique UNIQUE (academic_year_id, semester_number);


--
-- Name: semesters semesters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.semesters
    ADD CONSTRAINT semesters_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: student_health_records student_health_records_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_health_records
    ADD CONSTRAINT student_health_records_pkey PRIMARY KEY (id);


--
-- Name: student_mutations student_mutations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_mutations
    ADD CONSTRAINT student_mutations_pkey PRIMARY KEY (id);


--
-- Name: students students_nik_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_nik_unique UNIQUE (nik);


--
-- Name: students students_nis_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_nis_unique UNIQUE (nis);


--
-- Name: students students_nisn_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_nisn_unique UNIQUE (nisn);


--
-- Name: students students_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_pkey PRIMARY KEY (id);


--
-- Name: subjects subjects_code_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT subjects_code_unique UNIQUE (code);


--
-- Name: subjects subjects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT subjects_pkey PRIMARY KEY (id);


--
-- Name: submission_attachments submission_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.submission_attachments
    ADD CONSTRAINT submission_attachments_pkey PRIMARY KEY (id);


--
-- Name: task_scores task_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_scores
    ADD CONSTRAINT task_scores_pkey PRIMARY KEY (id);


--
-- Name: task_scores task_scores_task_id_student_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_scores
    ADD CONSTRAINT task_scores_task_id_student_id_unique UNIQUE (task_id, student_id);


--
-- Name: tasks tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: teachers teachers_email_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teachers
    ADD CONSTRAINT teachers_email_unique UNIQUE (email);


--
-- Name: teachers teachers_nip_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teachers
    ADD CONSTRAINT teachers_nip_unique UNIQUE (nip);


--
-- Name: teachers teachers_nuptk_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teachers
    ADD CONSTRAINT teachers_nuptk_unique UNIQUE (nuptk);


--
-- Name: teachers teachers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teachers
    ADD CONSTRAINT teachers_pkey PRIMARY KEY (id);


--
-- Name: teaching_assignments teaching_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teaching_assignments
    ADD CONSTRAINT teaching_assignments_pkey PRIMARY KEY (id);


--
-- Name: teaching_assignments teaching_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teaching_assignments
    ADD CONSTRAINT teaching_unique UNIQUE (teacher_id, subject_id, class_id, academic_year_id);


--
-- Name: users users_email_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_unique UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: attendance_date_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX attendance_date_index ON public.attendance USING btree (date);


--
-- Name: audit_logs_auditable_type_auditable_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX audit_logs_auditable_type_auditable_id_index ON public.audit_logs USING btree (auditable_type, auditable_id);


--
-- Name: cache_expiration_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cache_expiration_index ON public.cache USING btree (expiration);


--
-- Name: cache_locks_expiration_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cache_locks_expiration_index ON public.cache_locks USING btree (expiration);


--
-- Name: classes_academic_year_id_grade_level_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX classes_academic_year_id_grade_level_index ON public.classes USING btree (academic_year_id, grade_level);


--
-- Name: grades_class_id_semester_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX grades_class_id_semester_id_index ON public.grades USING btree (class_id, semester_id);


--
-- Name: jobs_queue_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX jobs_queue_index ON public.jobs USING btree (queue);


--
-- Name: notifications_notifiable_type_notifiable_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX notifications_notifiable_type_notifiable_id_index ON public.notifications USING btree (notifiable_type, notifiable_id);


--
-- Name: personal_access_tokens_tokenable_type_tokenable_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX personal_access_tokens_tokenable_type_tokenable_id_index ON public.personal_access_tokens USING btree (tokenable_type, tokenable_id);


--
-- Name: report_cards_class_id_semester_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX report_cards_class_id_semester_id_index ON public.report_cards USING btree (class_id, semester_id);


--
-- Name: schedules_teaching_assignment_id_day_of_week_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX schedules_teaching_assignment_id_day_of_week_index ON public.schedules USING btree (teaching_assignment_id, day_of_week);


--
-- Name: sessions_last_activity_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX sessions_last_activity_index ON public.sessions USING btree (last_activity);


--
-- Name: sessions_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX sessions_user_id_index ON public.sessions USING btree (user_id);


--
-- Name: students_class_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX students_class_id_index ON public.students USING btree (class_id);


--
-- Name: students_status_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX students_status_index ON public.students USING btree (status);


--
-- Name: subjects_education_level_grade_level_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX subjects_education_level_grade_level_index ON public.subjects USING btree (education_level, grade_level);


--
-- Name: teachers_status_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX teachers_status_index ON public.teachers USING btree (status);


--
-- Name: teaching_assignments_academic_year_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX teaching_assignments_academic_year_id_index ON public.teaching_assignments USING btree (academic_year_id);


--
-- Name: users_role_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX users_role_index ON public.users USING btree (role);


--
-- Name: announcements announcements_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: assignment_attachments assignment_attachments_assignment_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignment_attachments
    ADD CONSTRAINT assignment_attachments_assignment_id_foreign FOREIGN KEY (assignment_id) REFERENCES public.assignments(id) ON DELETE CASCADE;


--
-- Name: assignment_submissions assignment_submissions_assignment_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignment_submissions
    ADD CONSTRAINT assignment_submissions_assignment_id_foreign FOREIGN KEY (assignment_id) REFERENCES public.assignments(id) ON DELETE CASCADE;


--
-- Name: assignment_submissions assignment_submissions_student_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignment_submissions
    ADD CONSTRAINT assignment_submissions_student_id_foreign FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: assignments assignments_created_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_created_by_foreign FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: assignments assignments_subject_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_subject_id_foreign FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE CASCADE;


--
-- Name: assignments assignments_teacher_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_teacher_id_foreign FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON DELETE CASCADE;


--
-- Name: attendance attendance_class_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_class_id_foreign FOREIGN KEY (class_id) REFERENCES public.classes(id) ON DELETE CASCADE;


--
-- Name: attendance attendance_recorded_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_recorded_by_foreign FOREIGN KEY (recorded_by) REFERENCES public.teachers(id) ON DELETE SET NULL;


--
-- Name: attendance attendance_semester_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_semester_id_foreign FOREIGN KEY (semester_id) REFERENCES public.semesters(id) ON DELETE CASCADE;


--
-- Name: attendance attendance_student_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_student_id_foreign FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: attendance attendance_subject_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_subject_id_foreign FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE SET NULL;


--
-- Name: audit_logs audit_logs_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: classes classes_academic_year_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.classes
    ADD CONSTRAINT classes_academic_year_id_foreign FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id) ON DELETE CASCADE;


--
-- Name: classes classes_homeroom_teacher_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.classes
    ADD CONSTRAINT classes_homeroom_teacher_id_foreign FOREIGN KEY (homeroom_teacher_id) REFERENCES public.teachers(id) ON DELETE SET NULL;


--
-- Name: counseling_notes counseling_notes_counselor_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.counseling_notes
    ADD CONSTRAINT counseling_notes_counselor_id_foreign FOREIGN KEY (counselor_id) REFERENCES public.teachers(id) ON DELETE SET NULL;


--
-- Name: counseling_notes counseling_notes_student_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.counseling_notes
    ADD CONSTRAINT counseling_notes_student_id_foreign FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: exam_scores exam_scores_exam_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_scores
    ADD CONSTRAINT exam_scores_exam_id_foreign FOREIGN KEY (exam_id) REFERENCES public.exams(id) ON DELETE CASCADE;


--
-- Name: exam_scores exam_scores_student_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_scores
    ADD CONSTRAINT exam_scores_student_id_foreign FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: exams exams_class_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT exams_class_id_foreign FOREIGN KEY (class_id) REFERENCES public.classes(id) ON DELETE CASCADE;


--
-- Name: exams exams_semester_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT exams_semester_id_foreign FOREIGN KEY (semester_id) REFERENCES public.semesters(id) ON DELETE CASCADE;


--
-- Name: exams exams_subject_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT exams_subject_id_foreign FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE CASCADE;


--
-- Name: exams exams_teacher_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT exams_teacher_id_foreign FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON DELETE SET NULL;


--
-- Name: grades grades_class_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT grades_class_id_foreign FOREIGN KEY (class_id) REFERENCES public.classes(id) ON DELETE CASCADE;


--
-- Name: grades grades_semester_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT grades_semester_id_foreign FOREIGN KEY (semester_id) REFERENCES public.semesters(id) ON DELETE CASCADE;


--
-- Name: grades grades_student_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT grades_student_id_foreign FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: grades grades_subject_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT grades_subject_id_foreign FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE CASCADE;


--
-- Name: grades grades_teacher_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT grades_teacher_id_foreign FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON DELETE SET NULL;


--
-- Name: meeting_materials meeting_materials_meeting_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meeting_materials
    ADD CONSTRAINT meeting_materials_meeting_id_foreign FOREIGN KEY (meeting_id) REFERENCES public.meetings(id) ON DELETE CASCADE;


--
-- Name: meetings meetings_teaching_assignment_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meetings
    ADD CONSTRAINT meetings_teaching_assignment_id_foreign FOREIGN KEY (teaching_assignment_id) REFERENCES public.teaching_assignments(id) ON DELETE CASCADE;


--
-- Name: offline_assignment_answers offline_assignment_answers_question_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignment_answers
    ADD CONSTRAINT offline_assignment_answers_question_id_foreign FOREIGN KEY (question_id) REFERENCES public.offline_assignment_questions(id) ON DELETE CASCADE;


--
-- Name: offline_assignment_answers offline_assignment_answers_submission_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignment_answers
    ADD CONSTRAINT offline_assignment_answers_submission_id_foreign FOREIGN KEY (submission_id) REFERENCES public.offline_assignment_submissions(id) ON DELETE CASCADE;


--
-- Name: offline_assignment_classes offline_assignment_classes_class_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignment_classes
    ADD CONSTRAINT offline_assignment_classes_class_id_foreign FOREIGN KEY (class_id) REFERENCES public.classes(id) ON DELETE CASCADE;


--
-- Name: offline_assignment_classes offline_assignment_classes_offline_assignment_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignment_classes
    ADD CONSTRAINT offline_assignment_classes_offline_assignment_id_foreign FOREIGN KEY (offline_assignment_id) REFERENCES public.offline_assignments(id) ON DELETE CASCADE;


--
-- Name: offline_assignment_files offline_assignment_files_offline_assignment_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignment_files
    ADD CONSTRAINT offline_assignment_files_offline_assignment_id_foreign FOREIGN KEY (offline_assignment_id) REFERENCES public.offline_assignments(id) ON DELETE CASCADE;


--
-- Name: offline_assignment_questions offline_assignment_questions_offline_assignment_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignment_questions
    ADD CONSTRAINT offline_assignment_questions_offline_assignment_id_foreign FOREIGN KEY (offline_assignment_id) REFERENCES public.offline_assignments(id) ON DELETE CASCADE;


--
-- Name: offline_assignment_submissions offline_assignment_submissions_offline_assignment_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignment_submissions
    ADD CONSTRAINT offline_assignment_submissions_offline_assignment_id_foreign FOREIGN KEY (offline_assignment_id) REFERENCES public.offline_assignments(id) ON DELETE CASCADE;


--
-- Name: offline_assignment_submissions offline_assignment_submissions_student_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignment_submissions
    ADD CONSTRAINT offline_assignment_submissions_student_id_foreign FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: offline_assignments offline_assignments_created_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignments
    ADD CONSTRAINT offline_assignments_created_by_foreign FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: offline_assignments offline_assignments_meeting_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignments
    ADD CONSTRAINT offline_assignments_meeting_id_foreign FOREIGN KEY (meeting_id) REFERENCES public.meetings(id) ON DELETE SET NULL;


--
-- Name: offline_assignments offline_assignments_subject_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignments
    ADD CONSTRAINT offline_assignments_subject_id_foreign FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE CASCADE;


--
-- Name: offline_assignments offline_assignments_teacher_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_assignments
    ADD CONSTRAINT offline_assignments_teacher_id_foreign FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON DELETE CASCADE;


--
-- Name: offline_submission_files offline_submission_files_submission_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_submission_files
    ADD CONSTRAINT offline_submission_files_submission_id_foreign FOREIGN KEY (submission_id) REFERENCES public.offline_assignment_submissions(id) ON DELETE CASCADE;


--
-- Name: report_cards report_cards_class_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_cards
    ADD CONSTRAINT report_cards_class_id_foreign FOREIGN KEY (class_id) REFERENCES public.classes(id) ON DELETE CASCADE;


--
-- Name: report_cards report_cards_semester_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_cards
    ADD CONSTRAINT report_cards_semester_id_foreign FOREIGN KEY (semester_id) REFERENCES public.semesters(id) ON DELETE CASCADE;


--
-- Name: report_cards report_cards_student_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_cards
    ADD CONSTRAINT report_cards_student_id_foreign FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: schedules schedules_teaching_assignment_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedules
    ADD CONSTRAINT schedules_teaching_assignment_id_foreign FOREIGN KEY (teaching_assignment_id) REFERENCES public.teaching_assignments(id) ON DELETE CASCADE;


--
-- Name: semesters semesters_academic_year_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.semesters
    ADD CONSTRAINT semesters_academic_year_id_foreign FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id) ON DELETE CASCADE;


--
-- Name: student_health_records student_health_records_student_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_health_records
    ADD CONSTRAINT student_health_records_student_id_foreign FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: student_mutations student_mutations_from_class_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_mutations
    ADD CONSTRAINT student_mutations_from_class_id_foreign FOREIGN KEY (from_class_id) REFERENCES public.classes(id) ON DELETE SET NULL;


--
-- Name: student_mutations student_mutations_student_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_mutations
    ADD CONSTRAINT student_mutations_student_id_foreign FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: student_mutations student_mutations_to_class_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_mutations
    ADD CONSTRAINT student_mutations_to_class_id_foreign FOREIGN KEY (to_class_id) REFERENCES public.classes(id) ON DELETE SET NULL;


--
-- Name: students students_class_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_class_id_foreign FOREIGN KEY (class_id) REFERENCES public.classes(id) ON DELETE SET NULL;


--
-- Name: submission_attachments submission_attachments_submission_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.submission_attachments
    ADD CONSTRAINT submission_attachments_submission_id_foreign FOREIGN KEY (submission_id) REFERENCES public.assignment_submissions(id) ON DELETE CASCADE;


--
-- Name: task_scores task_scores_student_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_scores
    ADD CONSTRAINT task_scores_student_id_foreign FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: task_scores task_scores_task_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_scores
    ADD CONSTRAINT task_scores_task_id_foreign FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE;


--
-- Name: tasks tasks_class_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_class_id_foreign FOREIGN KEY (class_id) REFERENCES public.classes(id) ON DELETE CASCADE;


--
-- Name: tasks tasks_semester_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_semester_id_foreign FOREIGN KEY (semester_id) REFERENCES public.semesters(id) ON DELETE CASCADE;


--
-- Name: tasks tasks_subject_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_subject_id_foreign FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE CASCADE;


--
-- Name: tasks tasks_teacher_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_teacher_id_foreign FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON DELETE SET NULL;


--
-- Name: teachers teachers_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teachers
    ADD CONSTRAINT teachers_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: teaching_assignments teaching_assignments_academic_year_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teaching_assignments
    ADD CONSTRAINT teaching_assignments_academic_year_id_foreign FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id) ON DELETE CASCADE;


--
-- Name: teaching_assignments teaching_assignments_class_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teaching_assignments
    ADD CONSTRAINT teaching_assignments_class_id_foreign FOREIGN KEY (class_id) REFERENCES public.classes(id) ON DELETE CASCADE;


--
-- Name: teaching_assignments teaching_assignments_subject_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teaching_assignments
    ADD CONSTRAINT teaching_assignments_subject_id_foreign FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE CASCADE;


--
-- Name: teaching_assignments teaching_assignments_teacher_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teaching_assignments
    ADD CONSTRAINT teaching_assignments_teacher_id_foreign FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict gITsSpfmi0HtksOltAf4cW81frM8pU5fKrXyVmgt5WIgjFlN5fngzldHguA1c2O

