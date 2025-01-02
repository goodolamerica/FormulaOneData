--pulling information into tables to see what it produces--

----this produces the race schedule per year along with track name and country---
select s.Year, r.RaceDay, r.RaceStartTime, t.TrackFullName, t.Country
from Seasons as s
inner join RaceInformation as r
on s.SeasonID = r.SeasonID
inner join TrackInformation as t
on r.TrackID = t.TrackID
where s.Year >= 2019
order by s.Year, r.RaceDay

