//
//  StatementTests.m
//  Odbc
//
//  Created by Mikael Hakman on 2013-10-01.
//  Copyright (c) 2013 Mikael Hakman. All rights reserved.
//

#import "StatementTests.h"

#import <Odbc/Odbc.h>

@implementation StatementTests

- (void) setUp {
    
    [super setUp];
}

- (void) tearDown {
    
    [super tearDown];
}

- (NSDate *) dateYear : (int) year month : (int) month day : (int) day {
    
    NSDateComponents * dateComps = [NSDateComponents new];
    
    dateComps.year = year;
    
    dateComps.month = month;
    
    dateComps.day = day;
    
    NSCalendar * gregorian = [[NSCalendar alloc] initWithCalendarIdentifier : NSGregorianCalendar];
    
    gregorian.timeZone = [NSTimeZone timeZoneForSecondsFromGMT : 0];
    
    NSDate * date = [gregorian dateFromComponents: dateComps];
    
    return date;
}

- (NSDate *) timeHour : (int) hour minute : (int) minute second : (int) second {
    
    NSCalendar * gregorian = [[NSCalendar alloc] initWithCalendarIdentifier : NSGregorianCalendar];
    
    NSDateComponents * dateComps;
    
    NSString * dbms = self->connection.dbmsName;
    
    if ([dbms hasPrefix : @"Oracle"]) {
        
        NSDate * curDate = [NSDate new];
        
        unsigned flags = NSYearCalendarUnit | NSMonthCalendarUnit  | NSDayCalendarUnit |
                         NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
        
        dateComps = [gregorian components : flags fromDate : curDate];
        
        dateComps.day = 1;
        
    } else {
        
        dateComps = [NSDateComponents new];
    }
    
    dateComps.hour = hour;
    
    dateComps.minute = minute;
    
    dateComps.second = second;
        
    //gregorian.timeZone = [NSTimeZone timeZoneForSecondsFromGMT : 0];
    
    NSDate * date = [gregorian dateFromComponents: dateComps];
    
    return date;
}

- (NSDate *) timestampYear : (int) year
                     month : (int) month
                       day : (int) day
                      hour : (int) hour
                    minute : (int) minute
                    second : (int) second {
    
    NSDateComponents * dateComps = [NSDateComponents new];
    
    dateComps.year = year;
    
    dateComps.month = month;
    
    dateComps.day = day;
    
    dateComps.hour = hour;
    
    dateComps.minute = minute;
    
    dateComps.second = second;
    
    NSCalendar * gregorian = [[NSCalendar alloc] initWithCalendarIdentifier : NSGregorianCalendar];
    
    //gregorian.timeZone = [NSTimeZone timeZoneForSecondsFromGMT : 0];
    
    NSDate * date = [gregorian dateFromComponents: dateComps];
    
    return date;
}

- (void) testStatementWithConnection {
    
    OdbcStatement * stmt = [OdbcStatement statementWithConnection : self->connection];
        
    STAssertEqualObjects (stmt.connection,self->connection,@"");
}

- (void) testInitWithConnection {
    
    OdbcStatement * stmt = [[OdbcStatement alloc] initWithConnection : self->connection];

    STAssertEqualObjects (stmt.connection,self->connection,@"");
}

- (void) testExecDirect {
    
    [self->statement execDirect : @"select * from testtab"];
    
    int rowCount = 0;
    
    while ([self->statement fetch]) {
        
        rowCount ++;
    }
    
    STAssertEquals (rowCount,4,@"");
    
    [self->statement closeCursor];
    
    [self->connection commit];
}

- (void) testFetch {

    [self->statement execDirect : @"select * from testtab"];
    
    int rowCount = 0;
    
    while ([self->statement fetch]) {
        
        rowCount ++;
    }
    
    STAssertEquals (rowCount,4,@"");
    
    [self->statement closeCursor];
    
    [self->connection commit];
}

- (void) testCloseCursor {
    
    [self->statement execDirect : @"select * from testtab"];
    
    [self->statement closeCursor];

    [self->statement execDirect : @"select * from testtab"];

    [self->statement closeCursor];

    [self->connection commit];
}

- (void) testPrepare {
    
    NSString * dbms = self->connection.dbmsName;
    
    NSString * sql;
    
    if ([dbms hasPrefix : @"Oracle"]) {
        
        sql = @"select * from testtab where id = ? and name = ? and price = ? and \"DATE\" = ? and \"TIME\" = ? and ts = ?";
    
    } else {
        
        sql = @"select * from testtab where id = ? and name = ? and price = ? and date = ? and time = ? and ts = ?";
    }
    
    [self->statement prepare : sql];
    
    [self->statement setLong : 1 value : 1];
    
    [self->statement setString : 2 value : @"Name 1"];
    
    [self->statement setDouble : 3 value : 1.1];
    
    NSDate * date = [self dateYear : 2001 month : 1 day:1];
    
    [self->statement setDate : 4 value : date];
    
    NSDate * time = [self timeHour : 1 minute : 1 second : 1];
    
    if ([dbms hasPrefix : @"Oracle"]) {
        
        [self->statement setTimestamp : 5 value : time];
        
    } else {
        
        [self->statement setTime : 5 value : time];
    }
    
    NSDate * ts = [self timestampYear : 2001 month : 1 day : 1 hour : 1 minute : 1 second : 1];
    
    if ([dbms hasPrefix : @"SQLite"]) {
        
        [self->statement setString : 6 value : @"2001-01-01 01:01:01"];
        
    } else {
    
        [self->statement setTimestamp : 6 value : ts];
    }
    
    [self->statement execute];
    
    bool found = [self->statement fetch];
    
    STAssertTrue (found,@"");
    
    if (! found) return;
    
    long objId = [self->statement getLongByName : @"id"];
    
    STAssertEquals (objId,1L,@"");
    
    [self->statement closeCursor];
    
    [self->statement setLong : 1 value : 2];
    
    [self->statement setString : 2 value : @"Name 2"];
    
    [self->statement setDouble : 3 value : 2.2];
    
    date = [self dateYear : 2002 month : 2 day:2];
    
    [self->statement setDate : 4 value : date];
    
    time = [self timeHour : 2 minute : 2 second : 2];
    
    if ([dbms hasPrefix : @"Oracle"]) {
        
        [self->statement setTimestamp : 5 value : time];
        
    } else {
        
        [self->statement setTime : 5 value : time];
    }
    
    ts = [self timestampYear : 2002 month : 2 day : 2 hour : 2 minute : 2 second : 2];
    
    if ([dbms hasPrefix : @"SQLite"]) {
        
        [self->statement setString : 6 value : @"2002-02-02 02:02:02"];
        
    } else {
        
        [self->statement setTimestamp : 6 value : ts];
    }
    
    [self->statement execute];
    
    found = [self->statement fetch];
    
    STAssertTrue (found,@"");
    
    if (! found) return;
    
    objId = [self->statement getLongByName : @"id"];
    
    STAssertEquals(objId,2L,@"");
    
    [self->statement closeCursor];
    
    [self->connection commit];
}

- (void) testExecute {
    
    NSString * dbms = self->connection.dbmsName;
    
    NSString * sql;
    
    if ([dbms hasPrefix : @"Oracle"]) {
        
        sql = @"select * from testtab where id = ? and name = ? and price = ? and \"DATE\" = ? and \"TIME\" = ? and ts = ?";
        
    } else {
        
        sql = @"select * from testtab where id = ? and name = ? and price = ? and date = ? and time = ? and ts = ?";
    }
    
    [self->statement prepare : sql];
    
    [self->statement setLong : 1 value : 1];
    
    [self->statement setString : 2 value : @"Name 1"];
    
    [self->statement setDouble : 3 value : 1.1];
    
    NSDate * date = [self dateYear : 2001 month : 1 day:1];
    
    [self->statement setDate : 4 value : date];
    
    NSDate * time = [self timeHour : 1 minute : 1 second : 1];
    
    if ([dbms hasPrefix : @"Oracle"]) {
        
        [self->statement setTimestamp : 5 value : time];
    
    } else {
    
        [self->statement setTime : 5 value : time];
    }
    
    NSDate * ts = [self timestampYear : 2001 month : 1 day : 1 hour : 1 minute : 1 second : 1];
    
    if ([dbms hasPrefix : @"SQLite"]) {
        
        [self->statement setString : 6 value : @"2001-01-01 01:01:01"];
        
    } else {
        
        [self->statement setTimestamp : 6 value : ts];
    }
    
    [self->statement execute];
    
    bool found = [self->statement fetch];
    
    STAssertTrue (found,@"");
    
    if (! found) return;
    
    long objId = [self->statement getLongByName : @"id"];
    
    STAssertEquals (objId,1L,@"");
    
    [self->statement closeCursor];
    
    [self->statement setLong : 1 value : 2];
    
    [self->statement setString : 2 value : @"Name 2"];
    
    [self->statement setDouble : 3 value : 2.2];
    
    date = [self dateYear : 2002 month : 2 day:2];
    
    [self->statement setDate : 4 value : date];
    
    time = [self timeHour : 2 minute : 2 second : 2];
    
    if ([dbms hasPrefix : @"Oracle"]) {
        
        [self->statement setTimestamp : 5 value : time];
    
    } else {
    
        [self->statement setTime : 5 value : time];
    }
    
    ts = [self timestampYear : 2002 month : 2 day : 2 hour : 2 minute : 2 second : 2];
    
    if ([dbms hasPrefix : @"SQLite"]) {
        
        [self->statement setString : 6 value : @"2002-02-02 02:02:02"];
        
    } else {
        
        [self->statement setTimestamp : 6 value : ts];
    }
    
    [self->statement execute];
    
    found = [self->statement fetch];
    
    STAssertTrue (found,@"");
    
    if (! found) return;
    
    objId = [self->statement getLongByName : @"id"];
    
    STAssertEquals(objId,2L,@"");
    
    [self->statement closeCursor];
    
    [self->connection commit];
}

- (void) testGetData {
    
    NSString * dbms = self->connection.dbmsName;
    
    [self->statement execDirect : @"select * from testtab order by id"];
    
    int rowCount = 0;
    
    while ([self->statement fetch]) {
        
        rowCount ++;
        
        if (rowCount != 3) continue;
        
        long objId = [self->statement getLong : 1];
        
        STAssertEquals (objId,3L,@"");
        
        NSString * name = [self->statement getString : 2];
        
        STAssertEqualObjects (name,@"Name 3",@"");
        
        double price = [self->statement getDouble : 3];
        
        STAssertEquals (price,3.3,@"");
        
        NSDate * date1 = [self->statement getDate : 4];
        
        NSDate * date2 = [self dateYear : 2003 month : 3 day : 3];
        
        STAssertEqualObjects (date1,date2,@"");

        NSDate * time1;
        
        if ([dbms hasPrefix : @"Oracle"]) {
            
            time1 = [self->statement getTimestamp : 5];
            
        } else {
            
            time1 = [self->statement getTime : 5];
        }
        
        NSDate * time2 = [self timeHour : 3 minute : 3 second : 3];
        
        STAssertEqualObjects(time1,time2,@"");
        
        NSDate * ts1 = [self->statement getTimestamp : 6];
        
        NSDate * ts2 = [self timestampYear:2003 month:3 day:3 hour : 3 minute : 3 second : 3];
        
        STAssertEqualObjects (ts1,ts2,@"");
    }
    
    STAssertEquals(rowCount,4,@"");
    
    [self->statement closeCursor];
    
    [self->connection commit];
}

- (void) testGetDataByName {
    
    NSString * dbms = self->connection.dbmsName;
    
    [self->statement execDirect : @"select * from testtab order by id"];
    
    int rowCount = 0;
    
    while ([self->statement fetch]) {
        
        rowCount ++;
        
        if (rowCount != 3) continue;
        
        long objId = [self->statement getLongByName : @"id"];
        
        STAssertEquals (objId,3L,@"");
        
        NSString * name = [self->statement getStringByName : @"name"];
        
        STAssertEqualObjects (name,@"Name 3",@"");
        
        double price = [self->statement getDoubleByName : @"price"];
        
        STAssertEquals (price,3.3,@"");
        
        NSDate * date1 = [self->statement getDateByName : @"date"];
                
        NSDate * date2 = [self dateYear : 2003 month : 3 day : 3];

        STAssertEqualObjects (date1,date2,@"");
        
        NSDate * time1;
        
        if ([dbms hasPrefix : @"Oracle"]) {
            
            time1 = [self->statement getTimestamp : 5];
            
        } else {
            
            time1 = [self->statement getTime : 5];
        }
        
        NSDate * time2 = [self timeHour : 3 minute : 3 second : 3];
        
        STAssertEqualObjects(time1,time2,@"");
        
        NSDate * ts1 = [self->statement getTimestampByName : @"ts"];
        
        NSDate * ts2 = [self timestampYear:2003 month:3 day:3 hour : 3 minute : 3 second : 3];
        
        STAssertEqualObjects (ts1,ts2,@"");
    }
    
    STAssertEquals (rowCount,4,@"");
    
    [self->statement closeCursor];
    
    [self->connection commit];
}
/*
- (void) testGetData {
    
    [self->statement execDirect : @"select * from testtab order by id"];
    
    int rowCount = 0;
    
    while ([self->statement fetch]) {
        
        rowCount ++;
        
        if (rowCount < 3) continue;
        
        long objId = [self->statement getLong : 1];
        
        STAssertEquals (objId,3L,@"");
        
        NSString * name = [self->statement getString : 2];
        
        STAssertEqualObjects (name,@"Name 3",@"");
        
        double price = [self->statement getDouble : 3];
        
        STAssertEquals (price,3.3,@"");
        
        NSDate * date1 = [self->statement getDate : 4];
        
        NSDate * date2 = [self dateYear : 2003 month : 3 day : 3];
        
        STAssertEqualObjects (date1,date2,@"");
        
        NSDate * time1 = [self->statement getTime : 5];
        
        NSDate * time2 = [self timeHour : 3 minute : 3 second : 3];
        
        STAssertEqualObjects(time1,time2,@"");
        
        NSDate * ts1 = [self->statement getTimestamp : 6];
        
        NSDate * ts2 = [self timestampYear:2003 month:3 day:3 hour : 3 minute : 3 second : 3];
        
        STAssertEqualObjects (ts1,ts2,@"");
    }
    
    STAssertEquals(rowCount,3,@"");
    
    [self->statement closeCursor];
    
    [self->connection commit];
}
*/
- (void) testGetObjectByName {
    
    NSString * dbms = self->connection.dbmsName;
    
    NSString * sql;
    
    if ([dbms hasPrefix : @"Oracle"]) {
        
        sql = @"select * from testtab where id = ? and name = ? and price = ? and \"DATE\" = ? and \"TIME\" = ? and ts = ?";
        
    } else {
        
        sql = @"select * from testtab where id = ? and name = ? and price = ? and date = ? and time = ? and ts = ?";
    }
    
    [self->statement prepare : sql];
    
    [self->statement setLong : 1 value : 1];
    
    [self->statement setString : 2 value : @"Name 1"];
    
    [self->statement setDouble : 3 value : 1.1];
    
    NSDate * date = [self dateYear : 2001 month : 1 day:1];
    
    [self->statement setDate : 4 value : date];
    
    NSDate * time = [self timeHour : 1 minute : 1 second : 1];
    
    if ([dbms hasPrefix : @"Oracle"]) {
        
        [self->statement setTimestamp : 5 value : time];
        
    } else {
        
        [self->statement setTime : 5 value : time];
    }
    
    NSDate * ts = [self timestampYear : 2001 month : 1 day : 1 hour : 1 minute : 1 second : 1];
    
    if ([dbms hasPrefix : @"SQLite"]) {
        
        [self->statement setString : 6 value : @"2001-01-01 01:01:01"];
        
    } else {
        
        [self->statement setTimestamp : 6 value : ts];
    }

    [self->statement execute];
    
    bool found = [self->statement fetch];
    
    STAssertTrue (found,@"");
    
    if (! found) return;
    
    NSNumber * objId1 = [self->statement getObjectByName : @"id"];
    
    NSNumber * objId2 = [NSNumber numberWithLong : 1L];
    
    STAssertEqualObjects (objId1,objId2,@"");
    
    NSString * name1 = [self->statement getObjectByName : @"name"];
    
    NSString * name2 = @"Name 1";
    
    STAssertEqualObjects(name1,name2,@"");
    
    NSNumber * price1 = [self->statement getObjectByName : @"price"];
    
    NSNumber * price2 = @(1.1);
    
    STAssertEquals(price1.doubleValue,price2.doubleValue,@"");
    
    NSDate * date1 = [self->statement getObjectByName : @"date"];
    
    NSDate * date2 = [self dateYear : 2001 month : 1 day : 1];
    
    STAssertEqualObjects(date1,date2,@"");
    
    NSDate * time1 = [self->statement getObjectByName : @"time"];
    
    NSDate * time2 = [self timeHour : 1 minute : 1 second : 1];
    
    STAssertEqualObjects(time1,time2,@"");
    
    NSDate * ts1 = [self->statement getObjectByName : @"ts"];
    
    NSDate * ts2 = [self timestampYear : 2001 month : 1 day : 1 hour : 1 minute : 1 second : 1];
    
    STAssertEqualObjects(ts1,ts2,@"");
    
    [self->statement closeCursor];
    
    [self->statement setLong : 1 value : 2];
    
    [self->statement setString : 2 value : @"Name 2"];
    
    [self->statement setDouble : 3 value : 2.2];
    
    date = [self dateYear : 2002 month : 2 day:2];
    
    [self->statement setDate : 4 value : date];
    
    time = [self timeHour : 2 minute : 2 second : 2];
    
    if ([dbms hasPrefix : @"Oracle"]) {
        
        [self->statement setTimestamp : 5 value : time];
        
    } else {
        
        [self->statement setTime : 5 value : time];
    }
    
    ts = [self timestampYear : 2002 month : 2 day : 2 hour : 2 minute : 2 second : 2];
    
    if ([dbms hasPrefix : @"SQLite"]) {
        
        [self->statement setString : 6 value : @"2002-02-02 02:02:02"];
        
    } else {
        
        [self->statement setTimestamp : 6 value : ts];
    }
    
    [self->statement execute];
    
    found = [self->statement fetch];
    
    STAssertTrue (found,@"");
    
    if (! found) return;
    
    objId1 = [self->statement getObjectByName : @"id"];
    
    objId2 = [NSNumber numberWithLong : 2L];
    
    STAssertEqualObjects (objId1,objId2,@"");
    
    [self->statement closeCursor];
    
    [self->connection commit];
}

- (void) testGetObject {
    
    NSString * dbms = self->connection.dbmsName;
    
    NSString * sql;
    
    if ([dbms hasPrefix : @"Oracle"]) {
        
        sql = @"select * from testtab where id = ? and name = ? and price = ? and \"DATE\" = ? and \"TIME\" = ? and ts = ?";
    
    } else {
        
        sql = @"select * from testtab where id = ? and name = ? and price = ? and date = ? and time = ? and ts = ?";
    }
    
    [self->statement prepare : sql];
    
    [self->statement setLong : 1 value : 1];
    
    [self->statement setString : 2 value : @"Name 1"];
    
    [self->statement setDouble : 3 value : 1.1];
    
    NSDate * date = [self dateYear : 2001 month : 1 day:1];
    
    [self->statement setDate : 4 value : date];
    
    NSDate * time = [self timeHour : 1 minute : 1 second : 1];
    
    if ([dbms hasPrefix : @"Oracle"]) {
        
        [self->statement setTimestamp : 5 value : time];
    
    } else {
    
        [self->statement setTime : 5 value : time];
    }
    
    NSDate * ts = [self timestampYear : 2001 month : 1 day : 1 hour : 1 minute : 1 second : 1];
    
    if ([dbms hasPrefix : @"SQLite"]) {
        
        [self->statement setString : 6 value : @"2001-01-01 01:01:01"];
        
    } else {
        
        [self->statement setTimestamp : 6 value : ts];
    }
    
    [self->statement execute];
    
    bool found = [self->statement fetch];
    
    STAssertTrue (found,@"");
    
    if (! found) return;
    
    NSNumber * objId1 = [self->statement getObject : 1];
    
    NSNumber * objId2 = [NSNumber numberWithLong : 1L];
    
    STAssertEqualObjects (objId1,objId2,@"");
    
    NSString * name1 = [self->statement getObject : 2];
    
    NSString * name2 = @"Name 1";
    
    STAssertEqualObjects(name1,name2,@"");
    
    NSNumber * price1 = [self->statement getObject : 3];
    
    NSNumber * price2 = @(1.1);
    
    STAssertEquals(price1.doubleValue,price2.doubleValue,@"");
    
    NSDate * date1 = [self->statement getObject : 4];
    
    NSDate * date2 = [self dateYear : 2001 month : 1 day : 1];
    
    STAssertEqualObjects(date1,date2,@"");
    
    NSDate * time1 = [self->statement getObject : 5];
    
    NSDate * time2 = [self timeHour : 1 minute : 1 second : 1];
    
    STAssertEqualObjects(time1,time2,@"");
    
    NSDate * ts1 = [self->statement getObject : 6];
    
    NSDate * ts2 = [self timestampYear : 2001 month : 1 day : 1 hour : 1 minute : 1 second : 1];
    
    STAssertEqualObjects(ts1,ts2,@"");
    
    [self->statement closeCursor];
    
    [self->statement setLong : 1 value : 2];
    
    [self->statement setString : 2 value : @"Name 2"];
    
    [self->statement setDouble : 3 value : 2.2];
    
    date = [self dateYear : 2002 month : 2 day:2];
    
    [self->statement setDate : 4 value : date];
    
    time = [self timeHour : 2 minute : 2 second : 2];
    
    if ([dbms hasPrefix : @"Oracle"]) {
        
        [self->statement setTimestamp : 5 value : time];
        
    } else {
        
        [self->statement setTime : 5 value : time];
    }
    
    ts = [self timestampYear : 2002 month : 2 day : 2 hour : 2 minute : 2 second : 2];
    
    if ([dbms hasPrefix : @"SQLite"]) {
        
        [self->statement setString : 6 value : @"2002-02-02 02:02:02"];
        
    } else {
        
        [self->statement setTimestamp : 6 value : ts];
    }
    
    [self->statement execute];
    
    found = [self->statement fetch];
    
    STAssertTrue (found,@"");
    
    if (! found) return;
    
    objId1 = [self->statement getObjectByName : @"id"];
    
    objId2 = [NSNumber numberWithLong : 2L];
    
    STAssertEqualObjects (objId1,objId2,@"");
    
    [self->statement closeCursor];
    
    [self->connection commit];
}

- (void) testSetData {
    
    NSString * dbms = self->connection.dbmsName;
    
    [self->statement prepare : @"select * from testtab where id = ? and name = ? and price = ? and ts = ?"];
    
    [self->statement setLong : 1 value : 1];
    
    [self->statement setString : 2 value : @"Name 1"];
    
    [self->statement setDouble : 3 value : 1.1];
    
    NSDate * ts = [self timestampYear : 2001 month : 1 day : 1 hour : 1 minute : 1 second : 1];
    
    if ([dbms hasPrefix : @"SQLite"]) {
        
        [self->statement setString : 4 value : @"2001-01-01 01:01:01"];
        
    } else {
        
        [self->statement setTimestamp : 4 value : ts];
    }
    
    [self->statement execute];
    
    bool found = [self->statement fetch];
    
    STAssertTrue (found,@"");
    
    if (! found) return;
    
    long objId = [self->statement getLongByName : @"id"];
    
    STAssertEquals (objId,1L,@"");
    
    [self->statement closeCursor];
    
    [self->statement setLong : 1 value : 4];
    
    [self->statement setString : 2 value : @"N4"];
    
    [self->statement setDouble : 3 value : 4.4];
    
    ts = [self timestampYear : 2004 month : 4 day : 4 hour : 4 minute : 4 second : 4];
    
    if ([dbms hasPrefix : @"SQLite"]) {
        
        [self->statement setString : 4 value : @"2004-04-04 04:04:04"];
        
    } else {
        
        [self->statement setTimestamp : 4 value : ts];
    }
    
    [self->statement execute];
    
    found = [self->statement fetch];
    
    STAssertTrue (found,@"");
    
    if (! found) return;
    
    objId = [self->statement getLongByName : @"id"];
    
    STAssertEquals (objId,4L,@"");
    
    [self->statement closeCursor];
    
    [self->statement setLong : 1 value : 2];
    
    [self->statement setString : 2 value : @"Name 2"];
    
    [self->statement setDouble : 3 value : 2.2];
    
    ts = [self timestampYear : 2002 month : 2 day : 2 hour : 2 minute : 2 second : 2];
    
    if ([dbms hasPrefix : @"SQLite"]) {
        
        [self->statement setString : 4 value : @"2002-02-02 02:02:02"];
        
    } else {
        
        [self->statement setTimestamp : 4 value : ts];
    }
    
    [self->statement execute];
    
    found = [self->statement fetch];
    
    STAssertTrue (found,@"");
    
    [self->statement closeCursor];

    [self->connection commit];
}

- (void) testSetObject {
    
    NSString * dbms = self->connection.dbmsName;
    
    [self->statement prepare : @"select * from testtab where id = ? and name = ? and price = ? and ts = ?"];
    
    [self->statement setObject : 1 value : @1];
    
    [self->statement setObject : 2 value : @"Name 1"];
    
    [self->statement setObject : 3 value : @1.1];
    
    NSDate * ts = [self timestampYear:2001 month:1 day:1 hour:1 minute:1 second:1];
    
    if ([dbms hasPrefix : @"SQLite"]) {
        
        [self->statement setObject : 4 value : @"2001-01-01 01:01:01"];
    
    } else {

        [self->statement setObject : 4 value : ts];
    }
    
    [self->statement execute];
    
    bool found = [self->statement fetch];
    
    STAssertTrue (found,@"");
    
    if (! found) return;
    
    long objId = [self->statement getLongByName : @"id"];
    
    STAssertEquals (objId,1L,@"");
    
    [self->statement closeCursor];
    
    [self->statement setObject : 1 value : @2];
    
    [self->statement setObject : 2 value : @"Name 2"];
    
    [self->statement setObject : 3 value : @2.2];
    
    ts = [self timestampYear:2002 month:2 day:2 hour:2 minute:2 second:2];
    
    if ([dbms hasPrefix : @"SQLite"]) {
        
        [self->statement setObject : 4 value : @"2002-02-02 02:02:02"];
        
    } else {
        
        [self->statement setObject : 4 value : ts];
    }
    
    [self->statement execute];
    
    found = [self->statement fetch];
    
    STAssertTrue (found,@"");
    
    if (! found) return;
    
    objId = [self->statement getLongByName : @"id"];
    
    STAssertEquals (objId,2L,@"");
    
    [self->statement closeCursor];
    
    [self->connection commit];
}

- (void) testHstmt {
    
    STAssertTrue (self->statement.hstmt != 0,@"");
}

- (void) testConnection {
    
    STAssertEqualObjects (self->statement.connection,self->connection,@"");
}

- (void) testWasNull {
    
    [self->statement execDirect : @"insert into testtab (id,name) values (10,'Name 10')"];
    
    [self->statement execDirect : @"select * from testtab order by id"];
    
    int rowCount = 0;
    
    while ([self->statement fetch]) {
        
        rowCount ++;
        
        long objId = [self->statement getLongByName : @"id"];
        
        double price = [self->statement getDoubleByName : @"price"];
        
        bool wasNull = [self->statement wasNull];
        
        if (objId < 10) {
            
            STAssertFalse (wasNull,@"");
            
        } else {
            
            STAssertTrue (wasNull,@"");
            
            STAssertEquals (price,0.0,@"");
        }
    }
    
    STAssertEquals (rowCount,5,@"");
    
    [self->statement closeCursor];
    
    [self->connection rollback];
}

- (void) testConcurency {
    
    unsigned long concurency = self->statement.concurrency;
        
    STAssertTrue (concurency > 0,@"");
}
/*
- (void) testSetConcurency {
    
    NSString * dbmsName = self->connection.dbmsName;
    
    [self setAndTestConcurency : SQL_CONCUR_READ_ONLY];
    
    if (! [[dbmsName lowercaseString] hasPrefix : @"mimer"]) {
    
        [self setAndTestConcurency : SQL_CONCUR_LOCK];
        
        if (! [[dbmsName lowercaseString] hasPrefix : @"db2"]) {
    
            [self setAndTestConcurency : SQL_CONCUR_ROWVER];
    
            [self setAndTestConcurency : SQL_CONCUR_VALUES];
        }
    }
}
*/
- (void) setAndTestConcurency : (unsigned long) concurency {
    
    self->statement.concurrency = concurency;
    
    [self->statement execDirect :@"select * from testtab"];
    
    while ([self->statement fetch]) {}
    
    [self->statement closeCursor];
        
    [self->statement execDirect : @"update testtab set name = 'test' where id = 1"];
    
    [self->connection commit];
}

@end
