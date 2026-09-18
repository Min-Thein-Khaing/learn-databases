-- ============================================================
-- Silver Screen Movie Website Database
-- PostgreSQL
--
-- The website catalogs movies, genres, and cast members. Registered
-- users can rate and review movies. A movie can have many genres and
-- cast members, so junction tables model both many-to-many relationships.
-- ============================================================

DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS movie_cast CASCADE;
DROP TABLE IF EXISTS movie_genres CASCADE;
DROP TABLE IF EXISTS people CASCADE;
DROP TABLE IF EXISTS genres CASCADE;
DROP TABLE IF EXISTS movies CASCADE;
DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE movies (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    synopsis TEXT,
    release_date DATE,
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
    age_rating VARCHAR(20),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (title, release_date)
);

CREATE TABLE genres (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE movie_genres (
    movie_id BIGINT NOT NULL REFERENCES movies(id) ON DELETE CASCADE,
    genre_id BIGINT NOT NULL REFERENCES genres(id) ON DELETE RESTRICT,
    PRIMARY KEY (movie_id, genre_id)
);

CREATE TABLE people (
    id BIGSERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    date_of_birth DATE
);

CREATE TABLE movie_cast (
    movie_id BIGINT NOT NULL REFERENCES movies(id) ON DELETE CASCADE,
    person_id BIGINT NOT NULL REFERENCES people(id) ON DELETE RESTRICT,
    character_name VARCHAR(255) NOT NULL,
    billing_order INTEGER NOT NULL CHECK (billing_order > 0),
    PRIMARY KEY (movie_id, person_id, character_name)
);

CREATE TABLE reviews (
    id BIGSERIAL PRIMARY KEY,
    movie_id BIGINT NOT NULL REFERENCES movies(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 10),
    review_text TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (movie_id, user_id)
);

INSERT INTO users (username, email) VALUES
    ('film_fan', 'film.fan@example.com'),
    ('maya_reviews', 'maya.reviews@example.com'),
    ('cinema_club', 'cinema.club@example.com');

INSERT INTO movies (title, synopsis, release_date, duration_minutes, age_rating) VALUES
    ('The Last Signal', 'An engineer follows a mysterious transmission from deep space.', '2025-03-14', 128, 'PG-13'),
    ('River of Stars', 'Two siblings travel across their country to reunite their family.', '2024-11-08', 112, 'PG'),
    ('Midnight Kitchen', 'A chef rebuilds her life through a small late-night restaurant.', '2025-06-20', 104, 'PG-13');

INSERT INTO genres (name) VALUES
    ('Science Fiction'), ('Drama'), ('Adventure'), ('Comedy');

INSERT INTO movie_genres (movie_id, genre_id) VALUES
    (1, 1), (1, 2), (2, 2), (2, 3), (3, 2), (3, 4);

INSERT INTO people (full_name, date_of_birth) VALUES
    ('Elena Park', '1990-04-18'),
    ('Marcus Reed', '1986-09-02'),
    ('Nora Patel', '1994-01-27');

INSERT INTO movie_cast (movie_id, person_id, character_name, billing_order) VALUES
    (1, 1, 'Dr. Mina Cho', 1),
    (1, 2, 'Commander Hayes', 2),
    (2, 3, 'Leela', 1),
    (3, 1, 'Sora', 1);

INSERT INTO reviews (movie_id, user_id, rating, review_text) VALUES
    (1, 1, 9, 'Thoughtful science fiction with a strong ending.'),
    (1, 2, 8, 'Beautifully filmed and well acted.'),
    (2, 3, 9, 'A warm and memorable family story.'),
    (3, 1, 7, 'Charming, funny, and easy to enjoy.');

CREATE INDEX idx_reviews_movie_id ON reviews(movie_id);
CREATE INDEX idx_movie_cast_person_id ON movie_cast(person_id);
CREATE INDEX idx_movie_genres_genre_id ON movie_genres(genre_id);

-- Display every movie with its average rating and number of reviews.
SELECT
    m.title,
    ROUND(AVG(r.rating), 1) AS average_rating,
    COUNT(r.id) AS review_count
FROM movies m
LEFT JOIN reviews r ON r.movie_id = m.id
GROUP BY m.id, m.title
ORDER BY average_rating DESC NULLS LAST, m.title;

-- Display each movie's cast in billing order.
SELECT m.title, p.full_name, mc.character_name, mc.billing_order
FROM movie_cast mc
JOIN movies m ON m.id = mc.movie_id
JOIN people p ON p.id = mc.person_id
ORDER BY m.title, mc.billing_order;
