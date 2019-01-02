--CREATE EXTENSION postgis;
CREATE SCHEMA IF NOT EXISTS {!schema!};

drop table if exists {!schema!}.agency;
drop table if exists {!schema!}.stops;
drop table if exists {!schema!}.routes;
drop table if exists {!schema!}.route_types;
drop table if exists {!schema!}.directions;
drop table if exists {!schema!}.trips;
drop table if exists {!schema!}.stop_times;
drop table if exists {!schema!}.calendar;
drop table if exists {!schema!}.pickup_dropoff_types;
drop table if exists {!schema!}.calendar_dates;
drop table if exists {!schema!}.fare_attributes;
drop table if exists {!schema!}.fare_rules;
drop table if exists {!schema!}.shapes;
drop table if exists {!schema!}.frequencies;
drop table if exists {!schema!}.transfer_types;
drop table if exists {!schema!}.transfers;
drop table if exists {!schema!}.feed_info;
drop table if exists {!schema!}.payment_methods;


create table {!schema!}.agency (
  agency_id    varchar(255) PRIMARY KEY,
  agency_name  varchar(255),
  agency_url   varchar(255),
  agency_timezone    varchar(255),
  agency_lang  varchar(255),
  agency_phone varchar(255),
  agency_fare_url varchar(255)
);

create table {!schema!}.stops (
  stop_id    varchar(255) PRIMARY KEY,
  stop_code  varchar(255), 
  stop_name  varchar(255), 
  stop_desc  varchar(255),
  stop_lat   numeric,
  stop_lon   numeric,
  zone_id    varchar(255),
  stop_url   varchar(255),
  location_type varchar(255),
  parent_station varchar(255),
  stop_timezone varchar(255),
  wheelchair_boarding varchar(255)
);

create table {!schema!}.route_types (
  route_type int PRIMARY KEY,
  description text
);

create table {!schema!}.routes (
  route_id    text PRIMARY KEY,
  agency_id   text ,
  route_short_name text,
  route_long_name text,
  route_desc  text,
  route_type  int , 
  route_url   text,
  route_color text,
  route_text_color  text
);

create table {!schema!}.directions (
  direction_id int PRIMARY KEY,
  description text
);

create table {!schema!}.trips (
  route_id text , 
  service_id    text , 
  trip_id text PRIMARY KEY,
  trip_headsign text,
  direction_id  int, 
  block_id text,
  shape_id text,
  wheelchair_accessible int,
  bikes_allowed int
);

create table {!schema!}.pickup_dropoff_types (
  type_id int PRIMARY KEY,
  description text
);

create table {!schema!}.stop_times (
  trip_id text , 
  arrival_time text, 
  departure_time text, 
  stop_id text , 
  stop_sequence int , 
  stop_headsign text,
  pickup_type   text , 
  drop_off_type text , 
  shape_dist_traveled double precision,
  arrival_time_seconds int, 
  departure_time_seconds int
);

create table {!schema!}.calendar (
  service_id   text PRIMARY KEY,
  monday int , 
  tuesday int , 
  wednesday    int , 
  thursday     int, 
  friday int, 
  saturday     int, 
  sunday int, 
  start_date   date, 
  end_date     date
);

create table {!schema!}.calendar_dates (
  service_id  text,
  "date"    date , 
  exception_type int
   );
   
 create table {!schema!}.payment_methods (
   payment_method int PRIMARY KEY,
   description text
 );

 create table {!schema!}.fare_attributes (
   fare_id     text PRIMARY KEY,
   price double precision , 
   currency_type     text , 
   payment_method    int , 
   transfers   int,
   transfer_duration int,
   agency_id text
 );

 create table {!schema!}.fare_rules (
   fare_id     text , 
   route_id    text ,
   origin_id   int ,
   destination_id int ,
   contains_id int
 );

  create table {!schema!}.shapes (
  shape_id    text , 
   shape_pt_lat double precision , 
   shape_pt_lon double precision , 
   shape_pt_sequence int , 
   shape_dist_traveled double precision
 );



 create table {!schema!}.frequencies (
   trip_id     text , 
   start_time  text , 
   end_time    text , 
   headway_secs int , 
   start_time_seconds int,
   end_time_seconds int
);

 create table {!schema!}.transfer_types (
   transfer_type int PRIMARY KEY,
   description text
 );

 create table {!schema!}.transfers (
   from_stop_id text,
   to_stop_id text, 
   transfer_type text, 
   min_transfer_time int,
   from_route_id text, 
   to_route_id text, 
   service_id text 
 );
 
 create table {!schema!}.feed_info (
   feed_id text,
   feed_info text, 
   feed_publisher_name text,
   feed_publisher_url text,
   feed_timezone text,
   feed_lang text,
   feed_version text
 );

--Ajout de la géométrie dans les 2 tables stops et shapes
SELECT AddGeometryColumn ('{!schema!}','stops','geom',4326,'POINT',2);
SELECT AddGeometryColumn ('{!schema!}','shapes','geom',4326,'POINT',2);

--trigger pour peupler les géométries
CREATE OR REPLACE FUNCTION {!schema!}.stopUpdateGeom() RETURNS trigger AS $upstpoint$
    BEGIN
        NEW.geom = ST_SetSRID(ST_MakePoint(NEW.stop_lon, NEW.stop_lat),4326);
        RETURN NEW;
    END;
$upstpoint$ LANGUAGE plpgsql;

CREATE TRIGGER stopUpdateGeom BEFORE INSERT OR UPDATE ON {!schema!}.stops
    FOR EACH ROW EXECUTE PROCEDURE {!schema!}.stopUpdateGeom();
	
---
	
CREATE OR REPLACE FUNCTION {!schema!}.shapesUpdateGeom() RETURNS trigger AS $upstpoint$
    BEGIN
        NEW.geom = ST_SetSRID(ST_MakePoint(NEW.shape_pt_lon, NEW.shape_pt_lat),4326);
        RETURN NEW;
    END;
$upstpoint$ LANGUAGE plpgsql;

CREATE TRIGGER shapesUpdateGeom BEFORE INSERT OR UPDATE ON {!schema!}.shapes
    FOR EACH ROW EXECUTE PROCEDURE {!schema!}.shapesUpdateGeom();
    
--INDEX
CREATE INDEX idx_stop_times_trip_id ON {!schema!}.stop_times (trip_id);




