
---create a new Tracks Table--
CREATE TABLE TrackInformation
(TrackID int NOT NULL,
ShortName varchar(50) NOT NULL,
TrackFullName varchar(50) NOT NULL,
City varchar(50) NOT NULL,
Country varchar(50) NOT NULL, 
Altitude int NULL,
PRIMARY KEY (TrackID)
);

INSERT INTO TrackInformation
SELECT tempCircuitID, TrackName, full_track_name, city_location, country_location, altitude
FROM Tracks
---use of the above table instead of Tracks (still need to delete Tracks)---


----you updated your Races table column TrackID to match the tempTrackIDs from Tracks--
--this matches the new table you created--
UPDATE Races
SET TrackID = tracks.tempCircuitID
FROM Tracks as tracks
WHERE Races.TrackID = tracks.TrackID

--need to create a new RACE table for updated RACEID--
CREATE TABLE RaceInformation
(RaceID int NOT NULL,
SeasonID int NOT NULL,
TrackID int NOT NULL, 
RaceDay date NULL,
RaceStartTime nvarchar(50) NULL,
PRIMARY KEY (RaceID)
)

INSERT INTO RaceInformation
SELECT tempRaceID, SeasonID, TrackID, RaceDay, RaceStartTime FROM Races


--dropped the TeamID from Drivers as drivers can be associated with multiple teams over time--
--needed to drop foreign key constraint on RaceResults first--
alter table RaceResults
drop constraint FK__RaceResul__TeamI__66603565;

alter table Drivers
drop column TeamID

--changed Teams to have Kaggle ids instead of yours--
--dropped any foregin constraints first--
alter table Teams
drop constraint PK__Teams__123AE7B9EA4D465E

alter table Teams
drop column TeamID

alter table Teams
add ConstructorID int;

UPDATE Teams
SET ConstructorID = kaggle.constructorId
FROM F1Kaggle.dbo.constructors as kaggle
WHERE tempConstID = kaggle.constructorId AND TeamName = kaggle.name

alter table Teams
drop column tempConstID

--found mistyped data in RaceResults, updated CarNumber--
--Pierre Gasly number mistyped--
select * from RaceResults where DriverID = 19

update RaceResults
set CarNumber = 10
where DriverID = 19 AND CarNumber = 12

--Daniel Riccardio mistyped carnumber--
update RaceResults
set CarNumber = 3
where DriverID = 4 AND CarNumber = 31

--Daniel Riccardio mistyped TeamID--
update RaceResults
set TeamID = 8
where DriverID = 4 AND TeamID = 1


--dumb of me to drop TeamID previously--
--needed to add it back in to the Teams table--

--added new TeamID column--
alter table Teams
add TeamID int;

--confirmed row numbers were equal to what TeamID previously was--
select ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as RowNum, *
from Teams

--update the TeamID column with row numbers--
WITH TeamRowNum AS (
	SELECT
		ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum,
		ConstructorID
	FROM Teams
)
UPDATE Teams
SET TeamID = rn.RowNum
FROM Teams
JOIN TeamRowNum as rn
ON Teams.ConstructorID = rn.ConstructorID

----merging tables to your big RaceResults table---
--start by getting your select statement as it needs to be--
SELECT kaggle.raceId, races.RaceID, kaggle.driverId, drivers.DriverID , kaggle.constructorId, teams.TeamID, kaggle.number, kaggle.grid, kaggle.position, kaggle.laps, kaggle.time, kaggle.milliseconds, kaggle.fastestLap, kaggle.fastestLapTime, kaggle.fastestLapSpeed
FROM F1Kaggle.dbo.results as kaggle
JOIN Drivers as drivers
ON kaggle.driverId = drivers.tempDriverID
JOIN Teams as teams
ON kaggle.constructorId = teams.ConstructorID
JOIN Races as races
ON kaggle.raceId = races.tempRaceID


--once the select merge statement is set, need to update any of my exisitng columns to allow nulls if the kaggle table/column has nulls
--found only one column needs updated: my FinishPosition needs to allow nulls as the kaggle table has nulls
alter table RaceResults
alter column FinishPosition int NULL

--need to add columns for extra info want from kaggle tables
--add columns for: PositionOrder, Laps, milliseconds, fastetLap, fastedLapTime, fastestLapSpeed
alter table RaceResults
add ClassifiedFinishPosition tinyint,
CompletedLaps tinyint,
Milliseconds int,
FastestLapNumber tinyint,
FastestLapTime time,
FastestLapSpeed float

--received errors when tried to do full merge, needed to update data types and/or allow NULLS
alter table RaceResults
alter column FastestLapTime nvarchar(50)

alter table RaceResults
alter column QualiPosition int NULL

alter table RaceResults
alter column CarNumber tinyint NULL

--another error occured during the full merge due to the constraint TeamRaceID where a driver had the same configuration twice (due to finishing twice-read wiki)
---decided to alter/delete the constraint and add a new one that includes a unique constraint with car number
alter table RaceResults
drop constraint TeamRacesID

alter table RaceResults
add constraint TeamRacesID unique (DriverID, TeamID, RaceID, CarNumber)

--when tried to run after above alteration, got another error to do with FinishResultsiD constraint
---becuase not putting in qualiposition, a lot of errors will occur; update constraint to remove quali position and instead add in driverid(driverid, startposi, finispo, raceid)
alter table RaceResults
drop constraint FinishResultsID

alter table RaceResults
add constraint FinDriResultsID unique (DriverID, StartPosition, FinishPosition, RaceiD)

--another error occured as a driver qualified twice so needed to update the constraint (again) to include carnumber((driverid, startposi, finispo, raceid)
alter table RaceResults
drop constraint FinDriResultsID

alter table RaceResults
add constraint FinDrResultsID unique (DriverID, StartPosition, FinishPosition, RaceiD, CarNumber)

--get merge table setup--
MERGE INTO RaceResults AS mytarget
USING (
    SELECT 
        kaggle.raceId AS KaggleRaceID,
        races.RaceID AS RaceID, 
        kaggle.driverId AS KaggledriverId, 
        drivers.DriverID AS DriverID,
        kaggle.constructorId, 
        teams.TeamID, 
        kaggle.number, 
        kaggle.grid, 
        kaggle.position, 
        kaggle.PositionOrder, 
        kaggle.laps, 
        kaggle.milliseconds, 
        kaggle.fastestLap, 
        kaggle.fastestLapTime, 
        kaggle.fastestLapSpeed
    FROM F1Kaggle.dbo.results AS kaggle
    JOIN Drivers AS drivers
        ON kaggle.driverId = drivers.tempDriverID
    JOIN Teams AS teams
        ON kaggle.constructorId = teams.ConstructorID
    JOIN Races AS races
        ON kaggle.raceId = races.tempRaceID
) AS source
ON mytarget.DriverID = source.DriverID AND mytarget.RaceID = source.RaceID
WHEN MATCHED THEN
    UPDATE SET 
        mytarget.ClassifiedFinishPosition = source.PositionOrder,
        mytarget.FinishPosition = source.position,
        mytarget.CompletedLaps = source.laps,
        mytarget.Milliseconds = source.milliseconds,
        mytarget.FastestLapNumber = source.fastestLap,
        mytarget.FastestLapTime = source.fastestLapTime,
        mytarget.FastestLapSpeed = source.fastestLapSpeed
WHEN NOT MATCHED BY TARGET THEN
    INSERT (DriverID, TeamID, RaceID, StartPosition, FinishPosition, CarNumber, ClassifiedFinishPosition, CompletedLaps, Milliseconds, FastestLapNumber, FastestLapTime, FastestLapSpeed)
    VALUES (source.DriverID, source.TeamID, source.RaceID, source.grid, source.position, source.number, source.PositionOrder, source.laps, source.milliseconds, source.fastestLap, source.fastestLapTime, source.fastestLapSpeed);


--do double checks of error on RaceID, DriverID, TeamID--
 SELECT 
        kaggle.raceId AS KaggleRaceID,
        races.RaceID AS RaceID, 
        kaggle.driverId AS KaggledriverId, 
        drivers.DriverID AS DriverID,
        kaggle.constructorId, 
        teams.TeamID, 
        kaggle.number, 
        kaggle.grid, 
        kaggle.position, 
        kaggle.PositionOrder, 
        kaggle.laps, 
        kaggle.milliseconds, 
        kaggle.fastestLap, 
        kaggle.fastestLapTime, 
        kaggle.fastestLapSpeed,
		seasons.SeasonID,
		seasons.Year,
		track.ShortName
    FROM F1Kaggle.dbo.results AS kaggle
    JOIN Drivers AS drivers
        ON kaggle.driverId = drivers.tempDriverID
    JOIN Teams AS teams
        ON kaggle.constructorId = teams.ConstructorID
    JOIN Races AS races
        ON kaggle.raceId = races.tempRaceID
	JOIN Seasons AS seasons
		ON seasons.SeasonID = races.SeasonID
	JOIN TrackInformation AS track
		ON races.TrackID = track.TrackID
WHERE races.RaceID = 7015
--WHERE races.RaceID = 10 AND milliseconds IS NULL
ORDER By DriverID


----below is work to chech data integrity and the merge results from above---
select * from Races where RaceID = 10
select * from TrackInformation where TrackID = 4
select * from Seasons where SeasonID = 2
select * from Drivers where DriverID IN (1, 4, 6, 9, 10, 21, 22, 868, 870)
select * from Drivers where DriverID IN (2, 3, 5, 8, 11, 12, 14, 15, 868, 839, 832, 870)

select * from RaceResults order by RaceID Desc

--join tables below to verify results (season, track info)
select Drivers.DriverFullName, Drivers.DriverID
	from RaceResults 
		join Drivers ON RaceResults.DriverID = Drivers.DriverID
		where RaceID = 7731


---below is work but not as to how data was created/made---

exec sp_help 'RaceResults';

SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'RaceResults';


SELECT CONSTRAINT_NAME, CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_NAME='RaceResults';

ALTER TABLE Races NOCHECK CONSTRAINT TrackRef;