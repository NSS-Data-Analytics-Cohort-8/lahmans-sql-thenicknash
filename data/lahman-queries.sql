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

with total_strikeouts_per_year as (
	select
		yearid,
		sum(so) as total_strikeouts
	from pitching
	group by yearid
	order by yearid
),
total_games_played_per_year as (
	select
		yearid,
		sum(g) as games_played
	from teams
	group by yearid
	order by yearid
)
select
	case
		when total_games_played_per_year.yearid between 1870 and 1879 then '1870s'
		when total_games_played_per_year.yearid between 1880 and 1889 then '1880s'
		when total_games_played_per_year.yearid between 1890 and 1899 then '1890s'
		when total_games_played_per_year.yearid between 1900 and 1909 then '1900s'
		when total_games_played_per_year.yearid between 1910 and 1919 then '1910s'
		when total_games_played_per_year.yearid between 1920 and 1929 then '1920s'
		when total_games_played_per_year.yearid between 1930 and 1939 then '1930s'
		when total_games_played_per_year.yearid between 1940 and 1949 then '1940s'
		when total_games_played_per_year.yearid between 1950 and 1959 then '1950s'
		when total_games_played_per_year.yearid between 1960 and 1969 then '1960s'
		when total_games_played_per_year.yearid between 1970 and 1979 then '1970s'
		when total_games_played_per_year.yearid between 1980 and 1989 then '1980s'
		when total_games_played_per_year.yearid between 1990 and 1999 then '1990s'
		when total_games_played_per_year.yearid between 2000 and 2009 then '2000s'
		when total_games_played_per_year.yearid between 2010 and 2019 then '2010s'
	end as decade,
	round(avg(total_strikeouts_per_year.total_strikeouts / total_games_played_per_year.games_played), 2) as strikeouts_per_game
from total_games_played_per_year
inner join total_strikeouts_per_year
on total_games_played_per_year.yearid = total_strikeouts_per_year.yearid
group by decade
order by decade;

with total_homeruns_per_year as (
	select
		yearid,
		sum(hr) as total_homeruns
	from pitching
	group by yearid
	order by yearid
),
total_games_played_per_year as (
	select
		yearid,
		sum(g) as games_played
	from teams
	group by yearid
	order by yearid
)
select
	case
		when total_games_played_per_year.yearid between 1870 and 1879 then '1870s'
		when total_games_played_per_year.yearid between 1880 and 1889 then '1880s'
		when total_games_played_per_year.yearid between 1890 and 1899 then '1890s'
		when total_games_played_per_year.yearid between 1900 and 1909 then '1900s'
		when total_games_played_per_year.yearid between 1910 and 1919 then '1910s'
		when total_games_played_per_year.yearid between 1920 and 1929 then '1920s'
		when total_games_played_per_year.yearid between 1930 and 1939 then '1930s'
		when total_games_played_per_year.yearid between 1940 and 1949 then '1940s'
		when total_games_played_per_year.yearid between 1950 and 1959 then '1950s'
		when total_games_played_per_year.yearid between 1960 and 1969 then '1960s'
		when total_games_played_per_year.yearid between 1970 and 1979 then '1970s'
		when total_games_played_per_year.yearid between 1980 and 1989 then '1980s'
		when total_games_played_per_year.yearid between 1990 and 1999 then '1990s'
		when total_games_played_per_year.yearid between 2000 and 2009 then '2000s'
		when total_games_played_per_year.yearid between 2010 and 2019 then '2010s'
	end as decade,
	round(avg(total_homeruns_per_year.total_homeruns / total_games_played_per_year.games_played), 2) as homeruns_per_game
from total_games_played_per_year
inner join total_homeruns_per_year
on total_games_played_per_year.yearid = total_homeruns_per_year.yearid
group by decade
order by decade;

-- Both strikeouts and homeruns are increasing over time; however, strikeouts appear to be still on the rise while homeruns appear to be starting to stagnate or drop based on recent decades.

-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.
	

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?


-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.


-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.