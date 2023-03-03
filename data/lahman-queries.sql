-- 1. What range of years for baseball games played does the provided database cover? 
select
	min(year) as first_year,
	max(year) as last_year
from homegames;

-- The games range from 1871-2016.

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
with shortest_player as (
	select
		playerid,
		namefirst,
		namelast,
		height,
		debut,
		finalgame,
		date_part('year', finalgame::date) as year_played
	from people
	order by height
	limit 1
)
select
	shortest_player.namefirst as first_name,
	shortest_player.namelast as last_name,
	shortest_player.height as height_inches,
	t.name as team_name,
	count(a.*) as number_of_appearances
from shortest_player
inner join appearances as a
on shortest_player.playerid = a.playerid
inner join teams as t
on a.teamid = t.teamid
where t.yearid = shortest_player.year_played
group by
	shortest_player.namefirst,
	shortest_player.namelast,
	shortest_player.height,
	t.name;

-- Eddie Gaedel, standing at 43 inches, was the shortest player. He appeared in only 1 game, and he played for the St. Louis Browns.

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

with vanderbilt_players as (
	select
		distinct p.playerid,
		p.namefirst,
		p.namelast
	from collegeplaying as cp
	inner join schools as s
	on cp.schoolid = s.schoolid
	inner join people as p
	on cp.playerid = p.playerid
	where s.schoolid = (
		select schoolid
		from schools
		where schoolname = 'Vanderbilt University'
	)
)
select
	vanderbilt_players.namefirst as first_name,
	vanderbilt_players.namelast as last_name,
	coalesce(sum(salary)::numeric::money, 0::money) as total_salary_earned
from vanderbilt_players
left join salaries as s
on vanderbilt_players.playerid = s.playerid
group by
	first_name,
	last_name
order by total_salary_earned desc;

-- David Price has earned the most money ($81,851,296.00) compared to the other Vanderbilt University graduates in the majors.

-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

select
	case
		when pos = 'OF' then 'Outfield'
		when pos in ('SS', '1B', '2B', '3B') then 'Infield'
		when pos in ('P', 'C') then 'Battery'
	end as position_group,
	sum(po) as putouts_by_position_group
from fielding
group by position_group;
   
-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

select
	case
		when yearid between 1870 and 1879 then '1870s'
		when yearid between 1880 and 1889 then '1880s'
		when yearid between 1890 and 1899 then '1890s'
		when yearid between 1900 and 1909 then '1900s'
		when yearid between 1910 and 1919 then '1910s'
		when yearid between 1920 and 1929 then '1920s'
		when yearid between 1930 and 1939 then '1930s'
		when yearid between 1940 and 1949 then '1940s'
		when yearid between 1950 and 1959 then '1950s'
		when yearid between 1960 and 1969 then '1960s'
		when yearid between 1970 and 1979 then '1970s'
		when yearid between 1980 and 1989 then '1980s'
		when yearid between 1990 and 1999 then '1990s'
		when yearid between 2000 and 2009 then '2000s'
		when yearid between 2010 and 2019 then '2010s'
	end as decade,
	round(sum(so)::numeric(10,2) / (sum(g)::numeric(10,2) / 2), 2) as strikeouts_per_game,
	round(sum(hr)::numeric(10,2) / (sum(g)::numeric(10,2) / 2), 2) as homeruns_per_game
from teams
group by decade
order by decade;

-- Both strikeouts and homeruns are increasing over time; however, strikeouts appear to be still on the rise while homeruns appear to be starting to stagnate or drop based on recent decades.

-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

select
	p.namefirst,
	p.namelast,
	round((b.sb::numeric(10,2) / (b.sb::numeric(10,2) + b.cs::numeric(10,2))) * 100, 2) as steal_success_rate
from batting as b
inner join people as p
on b.playerid = p.playerid
where (b.sb + b.cs) >= 20
and b.yearid = 2016
order by steal_success_rate desc
limit 1;

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

select
	teamid,
	name as team_name,
	yearid,
	w as wins
from teams
where yearid between 1970 and 2016
and (
	wswin is null
	or wswin = 'N'
)
order by w desc
limit 1;

select
	teamid,
	name as team_name,
	yearid,
	w as wins
from teams
where yearid between 1970 and 2016
and yearid <> 1981
and wswin = 'Y'
order by w
limit 1;

-- Retrieve the team that won the most games and the team that won the world series grouped by year
select
	yearid,
	teamid
from teams
where yearid between 1970 and 2016
order by yearid;

-- The 2001 Seattle Mariners won the most games (116) without winning the World Series between 1970-2016.
-- The 1981 LA Dodgers won the WS with the smallest number of wins due to the 1981 MLB strike that resulted in cutting regular season games.
-- After removing the 1981 season from the equation, the 2006 St. Louis Cardinals won only 83 games en route to a World Series victory.

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.


-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.