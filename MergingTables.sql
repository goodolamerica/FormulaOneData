----is this start of merging data?

--needed to add unuqie for track names so no duplicates when merging data--
alter table Tracks add unique (TrackName)


--update your table to include additional information about Tracks--
alter table Tracks 
add tempCircuitID int,
full_track_name varchar(50),
city_location varchar(50),
country_location varchar(50),
altitude int


--temp table to insert Kaggle data into--
create table #tempTrackTbl
  (circuitid tinyint NOT NULL,
  circuit_slang_name varchar(50),
  full_track_name varchar(50),
  city_location varchar(50),
  country_location varchar(50),
  altitude int

  insert into #tempTrackTbl
  select circuitRef, name, location, country, alt from F1Kaggle.dbo.TrackSpecifics


  --merging the two tables based on the short track name--
MERGE INTO Tracks AS target
USING #tempTrackTbl AS source
ON target.TrackName = source.circuit_slang_track
WHEN MATCHED THEN
    UPDATE SET 
        target.tempCircuitID = source.circuitid,
        target.full_track_name = source.full_track_name,
        target.city_location = source.city_location,
        target.country_location = source.country_location,
        target.altitude = source.altitude
WHEN NOT MATCHED BY TARGET THEN
    INSERT (TrackName, tempCircuitID, full_track_Name, city_location, country_location, altitude)
    VALUES (source.circuit_slang_track, source.circuitid, source.full_track_name, source.city_location, source.country_location, source.altitude);


--same merging steps for Driver table--
  create table #tempTbl1
  (driverID int,
  number nvarchar(50),
  fullname varchar(50),
  nationality varchar(50));

  alter table Drivers
  alter column number nvarchar(50)

  insert into #tempTbl1
  select driverID, number, CONCAT(forename, ' ', surname), nationality
  from F1Kaggle.dbo.drivers


--combine the data--
MERGE INTO Drivers AS target
USING #tempTbl AS source
ON target.DriverFullName = source.fullname
WHEN MATCHED THEN
    UPDATE SET 
        target.tempDriverID = source.driverID,
        target.number = source.number,
        target.nationality = source.nationality
WHEN NOT MATCHED BY TARGET THEN
    INSERT (DriverFullName, tempDriverID, number, nationality)
    VALUES (source.fullname, source.driverID, source.number, source.nationality);

--do some verifying--
select distinct(DriverFullName), count(DriverFullName)
from Drivers
group by DriverFullName



--update your race table with historical data--
--temp table created to hold columns you want from kaggle--
create table #temp1
(myTrackID int,
tempCircuitID int,
fulltrackname varchar(50),
tempRaceID int,
raceyear int,
racedate date)

insert into #temp1
select t.TrackID, t.tempcircuitID, t.full_track_name, race.raceId, race.year, race.date
from Tracks as t
INNER JOIN F1Kaggle.dbo.races as race
ON t.tempCircuitID = race.circuitId
where t.tempCircuitID = race.circuitId

--needed the seasonID from Seasons table in order to correctly find Race data to match/merge and not overwrite--
--new temp table--
create table #temp2
(mytrackID int,
tempcirID int,
trackname varchar(50),
tempraceID int,
raceyear int,
racedate date,
seasonID int)

insert into #temp2
select temp.myTrackID, temp.tempCircuitID, temp.fulltrackname, temp.tempRaceID, temp.raceyear, temp.racedate, sea.SeasonID
from #temp1 as temp
INNER JOIN Seasons as sea
ON sea.Year = temp.raceyear
where sea.Year = temp.raceyear

--when first ran, found duplicates, needed to update downloaded data to correct races--
--races held at same track but used different layouts; all in same season--
select * from #temp2 where seasonID = 6
select * from Tracks where full_track_name LIKE '%Silver%'

insert into Tracks Values
('70th Anniversary', 102, 'Silverstone Circiut', 'Silverstone', 'UK', 153)

update #temp2
set mytrackID = 96
where tempcirID = 9 AND racedate = '2020-08-09'

--all duplicates updated, merge tables--
MERGE INTO Races AS target
USING #temp2 AS source
ON target.SeasonID = source.seasonID AND target.TrackID = source.mytrackID
WHEN MATCHED THEN
    UPDATE SET 
        target.RaceDay = source.racedate
WHEN NOT MATCHED BY TARGET THEN
    INSERT (SeasonID, TrackID, RaceDay)
    VALUES (source.seasonID, source.mytrackID, source.racedate);

--forgot to add the tempRaceID--
create table #temp2
(tempRaceID int,
racedate date,
racetime time)

alter table Races
alter column RaceStartTime nvarchar(50)


MERGE INTO Races AS target
USING #temp2 AS source
ON target.RaceDay = source.racedate
WHEN MATCHED THEN
    UPDATE SET 
        target.tempRaceID = source.tempRaceID,
		target.RaceStartTime = source.racetime
WHEN NOT MATCHED BY TARGET THEN
    INSERT (tempRaceID)
    VALUES (source.tempRaceID);


--follow same merge templates to update Team/Constructor table--
 create table #temp5
 (construcID tinyint,
 construcName nvarchar(50),
 constNation nvarchar(50))

 insert into #temp5
 select constructorID, name, nationality
 from F1Kaggle.dbo.constructors

 alter table Teams
 add nationality nvarchar(50), tempConstID tinyint


 MERGE INTO Teams AS target
USING #temp5 AS source
ON target.TeamName = source.construcName
WHEN MATCHED THEN
    UPDATE SET 
        target.tempConstID = source.construcId,
		target.nationality = source.constNation
WHEN NOT MATCHED BY TARGET THEN
    INSERT (TeamName, tempConstID, nationality)
    VALUES (source.construcName, source.construcId, source.constNation);


--learned more about primary/foreign keys--
---update your tables to have cascading keys---
alter table Races
add constraint SeasonRef
foreign key (SeasonID)
references Seasons (SeasonID)
on update cascade

alter table Races
add constraint TrackRef
foreign key (TrackID)
references Tracks (TrackID)
on update cascade




