
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
--add columns for: PositionOrder, Laps, time, milliseconds, fastetLap, fastedLapTime, fastestLapSpeed


--get merge table setup--
--MERGE INTO RaceResults AS mytarget
--USING (SELECT kaggle.raceId, races.RaceID, kaggle.driverId, drivers.DriverID , kaggle.constructorId, teams.TeamID, kaggle.number, kaggle.grid, kaggle.position, kaggle.laps, kaggle.time, kaggle.milliseconds, kaggle.fastestLap, kaggle.fastestLapTime, kaggle.fastestLapSpeed
--	FROM F1Kaggle.dbo.results as kaggle
--		JOIN Drivers as drivers
--		ON kaggle.driverId = drivers.tempDriverID
--		JOIN Teams as teams
--		ON kaggle.constructorId = teams.ConstructorID
--		JOIN Races as races
--		ON kaggle.raceId = races.tempRaceID
--	) as source
--ON mytarget.DriverID = source.DriverID AND mytarget.RaceID = source.RaceID
--WHEN MATCHED THEN
--    UPDATE SET 
--		  mytarget.classifiedfinishposition = source.positionOrder
--        mytarget.laps = source.laps
--		  mytarget.overalltime = source.time
--		  mytarget.milliseconds = source.milliseconds
--		  mytarget.fastestlap = source.fastestLap
--		  mytarget.fastestlaptime = source.fastestLapTime
--		  mytarget.fastestlapspeed = source.fastestLapSpeed
--WHEN NOT MATCHED BY TARGET THEN(literally needs to be everything that needs inserted into table)
--    INSERT (DriverID, TeamID, RaceID, StartPosition, FinishPosition, CarNumber, laps, overalltime, milliseconds, fastestlap, fastestlaptime, fastestlapspeed)
--    VALUES (source.DriverID, source.TeamID, source.RaceID, source.grid, source.position, source.number, source.laps, source.time, source.milliseconds, source.fastestLap, source.fastestLapTime, source.fastestLapSpeed);


-----Kaggle grid equals your StartPosition in RaceResults--
-----Kaggle position equals your FinishPosition in RaceResults--

---figure out what needs to go in merge statement; add columns to your race table for extra info; positionOrder is classification even for those who DNF'd; check for online table of quali positions before running--

select * from RaceResults;
SELECT kaggle.raceId, races.RaceID, kaggle.driverId, drivers.DriverID , kaggle.constructorId, teams.TeamID, kaggle.number, kaggle.grid, kaggle.position, kaggle.positionOrder, kaggle.laps, kaggle.time, kaggle.milliseconds, kaggle.fastestLap, kaggle.fastestLapTime, kaggle.fastestLapSpeed
FROM F1Kaggle.dbo.results as kaggle
JOIN Drivers as drivers
ON kaggle.driverId = drivers.tempDriverID
JOIN Teams as teams
ON kaggle.constructorId = teams.ConstructorID
JOIN Races as races
ON kaggle.raceId = races.tempRaceID;


---below is work but not as to how data was created/made---

exec sp_help 'RaceResults';

SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'RaceResults';


SELECT CONSTRAINT_NAME, CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_NAME='RaceResults';

ALTER TABLE Races NOCHECK CONSTRAINT TrackRef;