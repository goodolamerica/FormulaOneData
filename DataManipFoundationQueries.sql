---FOUNDATION QUERIES

--pulling information into tables to see what it produces--
----these are your ACTIVE tales: Races, Drivers, RaceResults, Seasons, Teams, Tracks

----this produces the race schedule per year along with track name and country---
select Seasons.Year, RaceDay, Races.RaceStartTime, Tracks.country_location
	from Races
	inner join Seasons ON Races.SeasonID = Seasons.SeasonID
	inner join Tracks ON Races.TrackID = Tracks.TrackID

----driver posiitions at each race with Team Name, track location, and year
select Drivers.DriverFullName, QualiPosition, StartPosition, FinishPosition, CarNUmber, ClassifiedFinishPosition, Teams.TeamName, Seasons.Year, RaceResults.RaceID, Tracks.country_location
	from RaceResults
		inner join Drivers ON RaceResults.DriverID = Drivers.DriverID
		inner join Races ON RaceResults.RaceID = Races.RaceID
		inner join Tracks ON Races.TrackID = Tracks.TrackID
		inner join Seasons ON Races.SeasonID = Seasons.SeasonID
		inner join Teams ON RaceResults.TeamID = Teams.TeamID
order by Seasons.Year, RaceResults.RaceID DESC;

---FIND AVG STARTPOSITION FOR DRIVERS SINCE 2019
select AVG(StartPosition) AS AVGStart, DriverFullName, TrackName
		from RaceResults AS results
	inner join Drivers AS drivers ON results.DriverID = drivers.DriverID
	inner join Races As race ON results.RaceID = race.RaceID
	inner join Tracks AS track ON race.TrackID = track.TrackID
		where RaceDay >= '2019-01-01'
group by DriverFullName, TrackName;

