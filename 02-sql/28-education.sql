-- ============================================================
-- Bright Path Education Database
-- PostgreSQL
--
-- The system manages instructors, students, courses, class sections,
-- enrollments, and assignments. A course may run many sections, and
-- students may enroll in many sections.
-- ============================================================

DROP TABLE IF EXISTS submissions CASCADE;
DROP TABLE IF EXISTS assignments CASCADE;
DROP TABLE IF EXISTS enrollments CASCADE;
DROP TABLE IF EXISTS sections CASCADE;
DROP TABLE IF EXISTS courses CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS instructors CASCADE;

CREATE TABLE instructors (
    id BIGSERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    hired_at DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE students (
    id BIGSERIAL PRIMARY KEY,
    student_number VARCHAR(30) NOT NULL UNIQUE,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    enrolled_at DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE courses (
    id BIGSERIAL PRIMARY KEY,
    course_code VARCHAR(20) NOT NULL UNIQUE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    credit_hours SMALLINT NOT NULL CHECK (credit_hours > 0)
);

CREATE TABLE sections (
    id BIGSERIAL PRIMARY KEY,
    course_id BIGINT NOT NULL REFERENCES courses(id) ON DELETE RESTRICT,
    instructor_id BIGINT NOT NULL REFERENCES instructors(id) ON DELETE RESTRICT,
    term VARCHAR(30) NOT NULL,
    academic_year INTEGER NOT NULL CHECK (academic_year >= 2000),
    room VARCHAR(50),
    capacity INTEGER NOT NULL CHECK (capacity > 0),
    UNIQUE (course_id, term, academic_year)
);

CREATE TABLE enrollments (
    student_id BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    section_id BIGINT NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
    enrolled_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    final_grade NUMERIC(5, 2) CHECK (final_grade BETWEEN 0 AND 100),
    PRIMARY KEY (student_id, section_id)
);

CREATE TABLE assignments (
    id BIGSERIAL PRIMARY KEY,
    section_id BIGINT NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    instructions TEXT,
    due_at TIMESTAMP NOT NULL,
    maximum_score NUMERIC(6, 2) NOT NULL CHECK (maximum_score > 0)
);

CREATE TABLE submissions (
    id BIGSERIAL PRIMARY KEY,
    assignment_id BIGINT NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
    student_id BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    content TEXT,
    score NUMERIC(6, 2) CHECK (score >= 0),
    feedback TEXT,
    UNIQUE (assignment_id, student_id)
);

INSERT INTO instructors (full_name, email, hired_at) VALUES
    ('Dr. Anika Rao', 'anika.rao@example.edu', '2021-08-15'),
    ('James Wilson', 'james.wilson@example.edu', '2023-01-10');

INSERT INTO students (student_number, full_name, email) VALUES
    ('STU-1001', 'Mia Chen', 'mia.chen@example.edu'),
    ('STU-1002', 'Noah Williams', 'noah.williams@example.edu'),
    ('STU-1003', 'Sofia Garcia', 'sofia.garcia@example.edu');

INSERT INTO courses (course_code, title, description, credit_hours) VALUES
    ('DB101', 'Introduction to Databases', 'Relational design and foundational SQL.', 3),
    ('WEB201', 'Web Application Development', 'Building accessible, data-driven websites.', 4);

INSERT INTO sections
    (course_id, instructor_id, term, academic_year, room, capacity)
VALUES
    (1, 1, 'Fall', 2026, 'B-204', 30),
    (2, 2, 'Fall', 2026, 'Lab-3', 24);

INSERT INTO enrollments (student_id, section_id, final_grade) VALUES
    (1, 1, 92.50), (2, 1, 86.00), (3, 1, 95.00),
    (1, 2, 90.00), (3, 2, 88.50);

INSERT INTO assignments
    (section_id, title, instructions, due_at, maximum_score)
VALUES
    (1, 'Design a Library Schema', 'Create a normalized schema and ER diagram.', '2026-10-05 23:59:00', 100),
    (2, 'Build a Course Page', 'Build a responsive and accessible course page.', '2026-10-12 23:59:00', 100);

INSERT INTO submissions
    (assignment_id, student_id, submitted_at, content, score, feedback)
VALUES
    (1, 1, '2026-10-04 18:30:00', 'Submission URL: example.com/mia-db', 94, 'Clear structure and sensible constraints.'),
    (1, 2, '2026-10-05 21:15:00', 'Submission URL: example.com/noah-db', 85, 'Good work; review many-to-many relationships.'),
    (2, 1, '2026-10-11 17:45:00', 'Submission URL: example.com/mia-web', 91, 'Responsive and easy to navigate.');

CREATE INDEX idx_sections_course_id ON sections(course_id);
CREATE INDEX idx_sections_instructor_id ON sections(instructor_id);
CREATE INDEX idx_enrollments_section_id ON enrollments(section_id);
CREATE INDEX idx_assignments_section_id ON assignments(section_id);
CREATE INDEX idx_submissions_student_id ON submissions(student_id);

-- Display every section and its enrollment count.
SELECT
    c.course_code,
    c.title,
    s.term,
    s.academic_year,
    COUNT(e.student_id) AS enrolled_students,
    s.capacity
FROM sections s
JOIN courses c ON c.id = s.course_id
LEFT JOIN enrollments e ON e.section_id = s.id
GROUP BY s.id, c.course_code, c.title
ORDER BY s.academic_year, s.term, c.course_code;

-- Display assignment results, including students who have not submitted work.
SELECT
    a.title AS assignment,
    st.full_name AS student,
    sub.submitted_at,
    sub.score,
    a.maximum_score
FROM assignments a
JOIN sections sec ON sec.id = a.section_id
JOIN enrollments e ON e.section_id = sec.id
JOIN students st ON st.id = e.student_id
LEFT JOIN submissions sub
    ON sub.assignment_id = a.id AND sub.student_id = st.id
ORDER BY a.id, st.full_name;
