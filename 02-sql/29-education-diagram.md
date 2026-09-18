# Education Database Diagram

This entity-relationship diagram models courses, class sections, enrollments,
assignments, and student submissions. Enrollments connect students to sections,
allowing each student to take many classes.

```mermaid
erDiagram
    INSTRUCTORS ||--o{ SECTIONS : teaches
    COURSES ||--o{ SECTIONS : offers
    STUDENTS ||--o{ ENROLLMENTS : has
    SECTIONS ||--o{ ENROLLMENTS : includes
    SECTIONS ||--o{ ASSIGNMENTS : contains
    ASSIGNMENTS ||--o{ SUBMISSIONS : receives
    STUDENTS ||--o{ SUBMISSIONS : creates

    INSTRUCTORS {
        bigint id PK
        string full_name
        string email UK
        date hired_at
    }
    STUDENTS {
        bigint id PK
        string student_number UK
        string full_name
        string email UK
        date enrolled_at
    }
    COURSES {
        bigint id PK
        string course_code UK
        string title
        string description
        int credit_hours
    }
    SECTIONS {
        bigint id PK
        bigint course_id FK
        bigint instructor_id FK
        string term
        int academic_year
        string room
        int capacity
    }
    ENROLLMENTS {
        bigint student_id PK, FK
        bigint section_id PK, FK
        timestamp enrolled_at
        decimal final_grade
    }
    ASSIGNMENTS {
        bigint id PK
        bigint section_id FK
        string title
        string instructions
        timestamp due_at
        decimal maximum_score
    }
    SUBMISSIONS {
        bigint id PK
        bigint assignment_id FK
        bigint student_id FK
        timestamp submitted_at
        string content
        decimal score
        string feedback
    }
```
