-----create 1to1 table and key reference----
--Table create: Tracks
CREATE TABLE Tracks
(TrackID int NOT NULL IDENTITY(1, 1),
TrackName varchar(50) NOT NULL,
PRIMARY KEY (TrackID))

SELECT TrackName FROM F1_Data.dbo.TrackNumberAssoc

--Table create: Seasons
CREATE TABLE Seasons
(SeasonID int NOT NULL IDENTITY(1, 1),
CalendarYear tinyint NOT NULL,
PRIMARY KEY (SeasonID),
UNIQUE (CalendarYear)
);

--manually entered Seasons data--

--Table create: Teams
CREATE TABLE Teams
(TeamID int NOT NULL IDENTITY(1,1),
TeamName varchar(50) NOT NULL UNIQUE,
PRIMARY KEY (TeamID)
);

INSERT INTO Teams
SELECT DISTINCT Team_Assoc FROM F1_Data.DBO.Driver_Team_Info
WHERE Team_Assoc != 'Null'

--Table create: EngineManufacturer
CREATE TABLE EngineManufacturer
(EngineManID int NOT NULL IDENTITY(1,1),
ManufacName varchar(50) NOT NULL UNIQUE,
PRIMARY KEY (EngineManID)
);


--manually entered values--
--also tested unique value insertion--
INSERT INTO EngineManufacturer VALUES
('Renault'),
('Mercedes'),
('Ferrari'),
('Honda');


--Table create: Positions
CREATE TABLE Positions
(PositionID int NOT NULL IDENTITY(1, 1),
FinishPointsAward tinyint NOT NULL
PRIMARY KEY (PositionID)
);

INSERT INTO Positions
SELECT Points_Awarded FROM F1_Data.dbo.SpainTrack_Info WHERE Points_Awarded != 0 ORDER BY Points_Awarded DESC

--needed to update referenced points--
UPDATE Positions
SET FinishPointsAward = 18
WHERE FinishPointsAward = 19


-------create tables with two key references----
--Table create: Drivers
CREATE TABLE Drivers
(DriverID int NOT NULL IDENTITY(1, 1),
DriverFullName varchar(50) NOT NULL,
TeamID int,
PRIMARY KEY (DriverID)
);

INSERT INTO Drivers (DriverFullName)
SELECT DISTINCT(Driver_Full_Name) FROM F1_Data.dbo.Driver_Team_Info WHERE Driver_Full_Name != ''

-----Updated the TeamID [entered manually]----
UPDATE Drivers
SET TeamID = 4
WHERE DriverID IN (9, 16)

INSERT INTO Drivers VALUES
('Oliver Bearman', 4) 

--REFERENCE KEYS START HERE--
--Table create: Races
CREATE TABLE Races
(RaceID int NOT NULL IDENTITY(1, 1),
SeasonID int NOT NULL,
TrackID int NOT NULL, 
RaceDay date,
PRIMARY KEY (RaceID),
CONSTRAINT SeasonTrackID UNIQUE (SeasonID, TrackID)
);

--Table create: TeamEngineSeason
CREATE TABLE TeamEngineBySeason
(TeamEngineID int NOT NULL IDENTITY(1, 1),
SeasonID int NOT NULL,
TeamID int NOT NULL, 
EngineManID int NOT NULL,
PRIMARY KEY (TeamEngineID),
CONSTRAINT TeamEngManID UNIQUE (SeasonID, TeamID, EngineManID)
);


--Table create: RaceResults
CREATE TABLE RaceResults
(RaceResultsID INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
DriverID int NOT NULL,
TeamID int NOT NULL, 
RaceID int NOT NULL,
QualiPosition int NOT NULL,
StartPosition int NOT NULL,
FinishPosition int NOT NULL,
CarNumber tinyint NOT NULL,
FOREIGN KEY (DriverID) REFERENCES Drivers(DriverID),
FOREIGN KEY (TeamID) REFERENCES Teams(TeamID),
FOREIGN KEY (RaceID) REFERENCES Races(RaceID),
CONSTRAINT FinishResultsID UNIQUE (QualiPosition, StartPosition, FinishPosition, RaceID),
CONSTRAINT TeamRacesID UNIQUE (DriverID, TeamID, RaceID)
);


----results of each drivers average qualifying position-----
CREATE VIEW AvgDriverQuali AS
(
SELECT AVG(results.QualiPosition) AS Avg_Quali, COUNT(results.DriverID) as DriverStarts, driver.DriverFullName, results.DriverID 
	FROM RaceResults as results
	INNER JOIN Drivers as driver
	ON driver.DriverID = results.DriverID
	GROUP BY driver.DriverFullName, results.DriverID
); 


--number of races started by each driver---
--counts how many times DRIVERID is in table, means driver started but does not mean they didnt finish--
SELECT COUNT(results.DriverID) AS DriverStarts, driver.DriverFullName 
	FROM RaceResults as results
	INNER JOIN Drivers as driver
	ON driver.DriverID = results.DriverID
	GROUP BY driver.DriverFullName
	Order By DriverStarts DESC


---finish position per driver per race--
SELECT results.RaceID, results.FinishPosition, driver.DriverFullName 
	FROM RaceResults as results
	INNER JOIN Drivers as driver
	ON driver.DriverID = results.DriverID
	ORDER BY RaceID ASC



--create CTE
--gathered driver count of how many times in a points position finish---
With PointsAchieved as
(
Select race.RaceID,  race.FinishPosition, positions.FinishPointsAward, race.DriverID
From Positions as positions
Inner Join RaceResults as race
On race.FinishPosition = positions.PositionID
Where race.FinishPosition = positions.PositionID

)
Select dri.DriverID, dri.DriverFullName, COUNT(dri.DriverID) as DriverCount
From PointsAchieved as points
Inner Join Drivers as dri
On points.DriverID = dri.DriverID
Group By dri.DriverID, dri.DriverFullName


---results in top ten positions and their points per race----
--results in teams grouped by their achieved points over season--
Create View TeamPointsAchieved as
Select team.TeamID, team.TeamName, SUM(pos.FinishPointsAward) as Total
	From RaceResults as race
	INNER JOIN Positions as pos
		ON race.FinishPosition = pos.PositionID
	INNER JOIN Teams as team
		ON race.TeamID = team.TeamID
		Where race.FinishPosition = pos.PositionID
		Group By team.TeamName, team.TeamID
		--Order By Total DESC


---find points total per driver---
----groups them by DriverID---
Create View DriverPointsAchieved as
Select race.DriverID, dri.DriverFullName, SUM(pos.FinishPointsAward) as Total, race.TeamID
	From RaceResults as race
	INNER JOIN Positions as pos
		ON race.FinishPosition = pos.PositionID
	INNER JOIN Drivers as dri
		ON race.DriverID = dri.DriverID
		Where race.FinishPosition = pos.PositionID
		Group By race.DriverID, dri.DriverFullName, race.TeamID
		--Order By Total DESC


