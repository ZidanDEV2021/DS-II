SELECT * FROM STUDENT;
/*
Created: 8/10/2022
Model: NHL statistics, game_play and game_play_player are reduced to years 2000 - 2005
Company: FEI VSB-TU Ostrava
Author: Radim Baca
Database: Oracle
Source: https://www.kaggle.com/datasets/martinellis/nhl-game-data
*/

drop table game_officials;
drop table game_teams_stats;
drop table game_plays_players;
drop table game_goalie_stats;
drop table game_skater_stats;
drop table game_plays;
drop table game;
drop table team_info;
drop table player_info;

----------------------------- table team_info
drop table team_info;
create table team_info (
	team_id int primary key,
	franchiseId int,
	shortName varchar(20),
	teamName varchar(20),
	abbreviation char(3),
	link varchar(40)
);

insert into team_info
select * from dbII_test.team_info;
commit;
----------------------------- table player_info
drop table player_info;
create table player_info (
	player_id int primary key,
	firstName varchar(100),
	lastName varchar(50),
	nationality char(3),
	birthCity varchar(100),
	primaryPosition varchar(10),
	birthDate date,
	birthStateProvince char(2),
	height varchar(20),
	height_cm float,
	weight int,
	shootsCatches char(2)
);

insert into player_info
select * from dbII_test.player_info;
commit;
----------------------------- table game
drop table game;
create table game (
	game_id int primary key,
	season int,
	type varchar(2),
	date_time_GMT date,
	away_team_id int references team_info,
	home_team_id int references team_info,
	away_goals int,
	home_goals int,
	outcome  varchar(20),
	home_rink_side_start varchar(10),
	venue varchar(100),
	venue_link  varchar(50),
	venue_time_zone_id varchar(20),
	venue_time_zone_offset int,
	venue_time_zone_tz  varchar(10)
);

insert into game
select * from dbII_test.game;
commit;
----------------------------- table game_plays
drop table game_plays;
create table game_plays (
	play_id varchar(15) primary key,
	game_id int references game,
	team_id_for int references team_info, 
	team_id_against int references team_info,
	event varchar(30),
	secondaryType varchar(50),
	x int null,
	y int null,
	period int,
	periodType varchar(15) ,
	periodTime int,
	periodTimeRemaining int,
	dateTime varchar(15),
	goals_away int,
	goals_home int,
	description varchar(200),
	st_x int null,
	st_y int null
);

insert into game_plays
select * from dbII_test.game_plays;
commit;
----------------------------- table game_plays_players

drop table game_plays_players;
create table game_plays_players (
	play_id varchar(15) references game_plays,
	player_id int references player_info,
	playerType varchar(20)
);

insert into game_plays_players
select * from dbII_test.game_plays_players;
commit;
----------------------------- table game_goalie_stats

drop table game_goalie_stats;
create table game_goalie_stats (
	game_id int not null references game,
	player_id int not null references player_info,
	team_id int references team_info,
	timeOnIce int,
	assists int,
	goals int,
	pim int,
	shots int,
	saves int,
	powerPlaySaves int,
	shortHandedSaves int,
	evenSaves int,
	shortHandedShotsAgainst int,
	evenShotsAgainst int,
	powerPlayShotsAgainst int,
	decision char(2),
	savePercentage float,
	powerPlaySavePercentage float,
	evenStrengthSavePercentage float
);

insert into game_goalie_stats
select * from dbII_test.game_goalie_stats;
commit;
----------------------------- table game_skater_stats

drop table game_skater_stats;
create table game_skater_stats (
	game_id int NOT NULL,
    player_id int NOT NULL,
	team_id int references team_info,
	timeOnIce int,
	assists int,
	goals int,
	shots int,
	hits int,
	powerPlayGoals int,
	powerPlayAssists int,
	penaltyMinutes int,
	faceOffWins int,
	faceoffTaken int,
	takeaways int,
	giveaways int,
	shortHandedGoals int,
	shortHandedAssists int,
	blocked int,
	plusMinus int,
	evenTimeOnIce int,
	shortHandedTimeOnIce int,
	powerPlayTimeOnIce int,
	primary key (game_id, player_id),
    FOREIGN KEY (game_id) REFERENCES game(game_id), 
    FOREIGN KEY (player_id) REFERENCES player_info(player_id)  
);

insert into game_skater_stats
select * from dbII_test.game_skater_stats;
commit;
----------------------------- table game_teams_stats

drop table game_teams_stats;
create table game_teams_stats (
	  game_id int references game,
	  team_id int references team_info,
	  HoA char(4),
	  won char(5),
	  settled_in varchar(5),
	  head_coach varchar(100),
	  goals int,
	  shots int,
	  hits int,
	  pim int,
	  powerPlayOpportunities int,
	  powerPlayGoals int,
	  faceOffWinPercentage float,
	  giveaways int,
	  takeaways int,
	  blocked int,
	  startRinkSide varchar(10) 
);

insert into game_teams_stats
select * from dbII_test.game_teams_stats;
commit;
----------------------------- table game_officials
drop table game_officials;
create table game_officials (
	game_id int ,
	official_name varchar(100),
	official_type varchar(20) 
);

insert into game_officials
select * from dbII_test.game_officials;
commit;

