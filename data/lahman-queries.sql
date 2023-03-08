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
		when pos in ('OF') then 'Outfield'
		when pos in ('SS', '1B', '2B', '3B') then 'Infield'
		when pos in ('P', 'C') then 'Battery'
	end as position_group,
	sum(po) as putouts_by_position_group
from fielding
where yearid = 2016
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
-- 	concat(floor(yearID/10)*10,'s')
	round(sum(so)::numeric(10,2) / (sum(g)::numeric(10,2) / 2), 2) as strikeouts_per_game,
	round(sum(hr)::numeric(10,2) / (sum(g)::numeric(10,2) / 2), 2) as homeruns_per_game
from teams
where yearid >= '1920'
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

-- Chris Owings!

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

-- Look at win percentage - 26.67 should be 26.1

select
	sum(did_ws_winner_win_most_games) as number_of_times_winningest_team_won_ws,
	round((sum(did_ws_winner_win_most_games)::numeric / count(*)::numeric) * 100, 2) as winningest_team_win_ws_percentage
from (
	select
		teams_with_most_wins_per_year.yearid,
		teams_with_most_wins_per_year.teamid as team_with_most_wins,
		team_that_won_ws.teamid as team_that_won_ws,
		case
			when teams_with_most_wins_per_year.teamid = team_that_won_ws.teamid then 1 else 0
		end as did_ws_winner_win_most_games
	from (
		select
			distinct on (yearid)
			teamid,
			yearid,
			w
		from teams
		where (
			yearid between 1970 and 1980
			or yearid between 1982 and 2016
		)
		order by yearid, w desc
	) as teams_with_most_wins_per_year
	inner join (
		select
			teamid,
			yearid,
			wswin
		from teams
		where (
			yearid between 1970 and 1980
			or yearid between 1982 and 2016
		)
		and wswin = 'Y'
	) as team_that_won_ws
	on teams_with_most_wins_per_year.yearid = team_that_won_ws.yearid
) as v_winning_teams;


-- 7 EXAMPLE 
WITH cte as (SELECT name, yearid, w, WSwin
				FROM teams
				WHERE w IN (SELECT MAX(w) OVER (PARTITION BY yearid) as w
							FROM teams as sub
							WHERE (yearid BETWEEN '1970' AND '1980' OR yearid BETWEEN '1982' AND '2016') 
							AND teams.yearid = sub.yearid))
			 
SELECT 
	COUNT(*) as best_team_ws, 
	CONCAT(ROUND((100 * COUNT(*)::float / (SELECT COUNT( DISTINCT yearid)
											FROM teams
											WHERE (yearid BETWEEN '1970' AND '1980' 
												   OR yearid BETWEEN '1982' AND '2016'))::float)::numeric, 1),'%') 
											as pct_ws_highest_w
FROM cte
WHERE wswin = 'Y';


-- The 2001 Seattle Mariners won the most games (116) without winning the World Series between 1970-2016.
-- The 1981 LA Dodgers won the WS with the smallest number of wins due to the 1981 MLB strike that resulted in cutting regular season games.
-- After removing the 1981 season from the equation, the 2006 St. Louis Cardinals won only 83 games en route to a World Series victory.
-- 12 times from 1970 to 2016 the winningest team won the World Series in the same season. This comes out to 26.67% of the time.

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

select
	parks.park_name,
	v_teams.name as team_name,
	(homegames.attendance / homegames.games) as avg_attendance
from homegames
inner join parks
on homegames.park = parks.park
inner join (
	select distinct teamid, name
	from teams
	where yearid = 2016
) as v_teams
on homegames.team = v_teams.teamid
where year = 2016
and homegames.games >= 10
order by avg_attendance desc
limit 5;

select
	parks.park_name,
	v_teams.name as team_name,
	(homegames.attendance / homegames.games) as avg_attendance
from homegames
inner join parks
on homegames.park = parks.park
inner join (
	select distinct teamid, name
	from teams
	where yearid = 2016
) as v_teams
on homegames.team = v_teams.teamid
where year = 2016
and homegames.games >= 10
order by avg_attendance
limit 5;

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

with managers_won_both_league_awards as (
	select playerid
	from awardsmanagers
	where awardid = 'TSN Manager of the Year'
	and lgid <> 'ML'
	group by playerid
	having count(distinct lgid) > 1
)
select
	am.yearid,
	concat(p.namegiven, ' ', p.namelast),
	v_teams.name as team_name
from managers_won_both_league_awards as mwbla
inner join people as p
on mwbla.playerid = p.playerid
inner join awardsmanagers as am
on mwbla.playerid = am.playerid
and 'TSN Manager of the Year' = am.awardid
inner join managers as m
on am.yearid = m.yearid
and am.playerid = m.playerid
inner join (
	select
		distinct teamid,
		name,
		yearid
	from teams
) as v_teams
on m.teamid = v_teams.teamid
and m.yearid = v_teams.yearid
order by am.yearid;

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

-- Jordan's query provided the best data
WITH cte as (
	SELECT playerid, yearid, hrs
	FROM (
		SELECT playerid, yearid, SUM(hr) as hrs
		FROM batting
		GROUP BY playerid, yearid
	) as sub
	WHERE hrs in (
		SELECT MAX(hrs) OVER (PARTITION BY playerid)
		FROM (
			SELECT
				playerid,
				yearid, 
				SUM(hr) as hrs
			FROM batting as bb
			GROUP BY playerid, yearid
		) as bsub
		WHERE bsub.playerid = sub.playerid
	) 
	AND hrs >= 1
	AND playerid IN (
		SELECT playerid
		FROM batting
		GROUP BY playerid
		HAVING COUNT(DISTINCT yearid) >= 10
	)
)		
SELECT CONCAT(p.namefirst, ' ', p.namelast), hrs
FROM cte
INNER JOIN people as p
USING (playerid)
WHERE yearid = '2016'
ORDER BY hrs DESC;

-- 11.

-- Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question.
-- As you do this analysis, keep in mind that salaries across the whole league tend to increase together,
-- so you may want to look on a year-by-year basis.

-- MAIN QUERY
select corr(twas.wins, twas.total_team_salary) as correlation_coefficient_wins_and_salary
from (
	select
		team_wins.yearid,
		team_wins.teamid,
		team_wins.wins,
		team_salary.total_team_salary
	from (
		select
			yearid,
			teamid,
			sum(w) as wins
		from teams
		where yearid >= 2000
		group by teamid, yearid
		order by yearid
	) as team_wins
	inner join (
		select
			yearid,
			teamid,
			sum(salary) as total_team_salary
		from salaries
		where yearid >= 2000
		group by yearid, teamid
		order by yearid
	) as team_salary
	on team_wins.yearid = team_salary.yearid
	and team_wins.teamid = team_salary.teamid
) as twas;

-- There is a 0.342 correlation between a team's wins and total salary, so I would call this a low-moderate correlation.


-- 12.

-- In this question, you will explore the connection between number of wins and attendance.

-- Does there appear to be any correlation between attendance at home games and number of wins?
-- Do teams that win the world series see a boost in attendance the following year?
-- What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.
select corr(waa.num_of_wins, waa.total_attendance) as correlation_coefficient_wins_and_attendance
from (
	select
		yearid,
		teamid,
		w as num_of_wins,
		attendance as total_attendance
	from teams
	where attendance is not null
-- 	group by yearid, teamid
	order by yearid, teamid
) as waa;

-- There is a 0.3990 correlation, essentially .4. This is a low-moderate correlation between number of wins and attendance.

-- Finding difference in attendance for WS winners the following year
with teams_that_won_ws as (
	select
		yearid,
		teamid,
		w,
		attendance
	from teams
	where wswin = 'Y'
	and attendance is not null
	order by yearid
)
select floor(avg(t.attendance - ttww.attendance)) as attendance_diff
from teams_that_won_ws as ttww
inner join teams as t
on ttww.yearid + 1 = t.yearid
and ttww.teamid = t.teamid;

-- There is an average increase of 16,482 in attendance after a team wins the World Series the following year.

-- Finding difference in attendance for teams that made the playoffs
with teams_that_made_playoffs as (
	select
		yearid,
		teamid,
		w,
		attendance
	from teams
	where (
		divwin = 'Y'
		or wcwin = 'Y'
	)
	and attendance is not null
	order by yearid
)
select
	floor(avg(t.attendance - ttmp.attendance)) as attendance_diff
-- 	(avg(t.attendance - ttmp.attendance) / (t.attendance - ttmp.attendance)) as attendance_diff_pct
from teams_that_made_playoffs as ttmp
inner join teams as t
on ttmp.yearid + 1 = t.yearid
and ttmp.teamid = t.teamid;

-- There is an average increase of 50,289 in attendance after a team wins the World Series the following year.


-- ## Question 1: Rankings
-- #### Question 1a: Warmup Question
-- Write a query which retrieves each teamid and number of wins (w) for the 2016 season. Apply three window functions to the number of wins (ordered in descending order) - ROW_NUMBER, RANK, AND DENSE_RANK. Compare the output from these three functions. What do you notice?

-- #### Question 1b: 
-- Which team has finished in last place in its division (i.e. with the least number of wins) the most number of times? A team's division is indicated by the divid column in the teams table.

-- ## Question 2: Cumulative Sums
-- #### Question 2a: 
-- Barry Bonds has the record for the highest career home runs, with 762. Write a query which returns, for each season of Bonds' career the total number of seasons he had played and his total career home runs at the end of that season. (Barry Bonds' playerid is bondsba01.)

-- #### Question 2b:
-- How many players at the end of the 2016 season were on pace to beat Barry Bonds' record? For this question, we will consider a player to be on pace to beat Bonds' record if they have more home runs than Barry Bonds had the same number of seasons into his career. 

-- #### Question 2c: 
-- Were there any players who 20 years into their career who had hit more home runs at that point into their career than Barry Bonds had hit 20 years into his career? 

-- ## Question 3: Anomalous Seasons
-- Find the player who had the most anomalous season in terms of number of home runs hit. To do this, find the player who has the largest gap between the number of home runs hit in a season and the 5-year moving average number of home runs if we consider the 5-year window centered at that year (the window should include that year, the two years prior and the two years after).

-- ## Question 4: Players Playing for one Team
-- For this question, we'll just consider players that appear in the batting table.
-- #### Question 4a: 
-- Warmup: How many players played at least 10 years in the league and played for exactly one team? (For this question, exclude any players who played in the 2016 season). Who had the longest career with a single team? (You can probably answer this question without needing to use a window function.)

-- #### Question 4b: 
-- Some players start and end their careers with the same team but play for other teams in between. For example, Barry Zito started his career with the Oakland Athletics, moved to the San Francisco Giants for 7 seasons before returning to the Oakland Athletics for his final season. How many players played at least 10 years in the league and start and end their careers with the same team but played for at least one other team during their career? For this question, exclude any players who played in the 2016 season.

-- ## Question 5: Streaks
-- #### Question 5a: 
-- How many times did a team win the World Series in consecutive years?

-- #### Question 5b: 
-- What is the longest steak of a team winning the World Series? Write a query that produces this result rather than scanning the output of your previous answer.

-- #### Question 5c: 
-- A team made the playoffs in a year if either divwin, wcwin, or lgwin will are equal to 'Y'. Which team has the longest streak of making the playoffs? 

-- #### Question 5d: 
-- The 1994 season was shortened due to a strike. If we don't count a streak as being broken by this season, does this change your answer for the previous part?

-- ## Question 6: Manager Effectiveness
-- Which manager had the most positive effect on a team's winning percentage? To determine this, calculate the average winning percentage in the three years before the manager's first full season and compare it to the average winning percentage for that manager's 2nd through 4th full season. Consider only managers who managed at least 4 full years at the new team and teams that had been in existence for at least 3 years prior to the manager's first full season.