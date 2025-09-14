
CREATE TABLE 
(
  modify_at    timestamp NOT NULL,
  created_at   timestamp NOT NULL,
  id           int       NOT NULL,
  user_id      int       NOT NULL,
  character_id int       NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE Character
(
  id        int       NOT NULL,
  age       int       NOT NULL,
  sex       char      NOT NULL,
  type      text      NOT NULL,
  img_url   text      NOT NULL,
  create_at timestamp NOT NULL,
  modify_at timestamp NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE Goal
(
  id       int  NOT NULL,
  contents text NOT NULL,
  status   char NOT NULL DEFAULT P,
  user_id  int  NOT NULL,
  PRIMARY KEY (id)
);

COMMENT ON COLUMN Goal.status IS 'SFP(success,fail,progress)';

CREATE TABLE Sports
(
  id         int       NOT NULL,
  name       text      NOT NULL,
  created_at timestamp NOT NULL,
  modify_at  timestamp NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE User
(
  id         int       NOT NULL,
  email      text      NOT NULL,
  nickname   text      NOT NULL,
  password   text      NOT NULL,
  sex        char     ,
  age        int      ,
  created_at timestamp NOT NULL,
  modify_at  timestamp NOT NULL,
  PRIMARY KEY (id)
);

COMMENT ON TABLE User IS 'tlqkf';

CREATE TABLE UserLog
(
  id         int              NOT NULL,
  weight     double precision NOT NULL,
  height     double precision NOT NULL,
  created_at timestamp        NOT NULL,
  user_id    int              NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE Workout
(
  id         int       NOT NULL,
  durations  int       NOT NULL,
  workout_at timestamp NOT NULL,
  create_at  timestamp NOT NULL,
  modify_at  timestamp NOT NULL,
  user_id    int       NOT NULL,
  sports_id  int       NOT NULL,
  PRIMARY KEY (id)
);

ALTER TABLE UserLog
  ADD CONSTRAINT FK_User_TO_UserLog
    FOREIGN KEY (user_id)
    REFERENCES User (id);

ALTER TABLE Workout
  ADD CONSTRAINT FK_User_TO_Workout
    FOREIGN KEY (user_id)
    REFERENCES User (id);

ALTER TABLE Workout
  ADD CONSTRAINT FK_Sports_TO_Workout
    FOREIGN KEY (sports_id)
    REFERENCES Sports (id);

ALTER TABLE Goal
  ADD CONSTRAINT FK_User_TO_Goal
    FOREIGN KEY (user_id)
    REFERENCES User (id);

ALTER TABLE 
  ADD CONSTRAINT FK_User_TO_
    FOREIGN KEY (user_id)
    REFERENCES User (id);

ALTER TABLE 
  ADD CONSTRAINT FK_Character_TO_
    FOREIGN KEY (character_id)
    REFERENCES Character (id);
